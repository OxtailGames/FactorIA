// Windows: WinHTTP's WebSocket API (fa/platform/websocket.h), with the system's certificate store and the user's proxy
// settings, like http_win32.cpp.
//
// WinHTTP in its asynchronous mode (WINHTTP_FLAG_ASYNC), on a session of its own (http_win32.cpp's is synchronous). Only an
// asynchronous request may be cancelled by closing its handle, and closing the handle is how the connect timeout, a close()
// while connecting and the destruction end what is in flight: a synchronous WinHTTP call must never have its handle closed
// under it.
//
// One "driver" thread per connection is the only thread that calls WinHTTP for it: it opens and sends the request, completes
// the upgrade, keeps one WinHttpWebSocketReceive and at most one WinHttpWebSocketSend in flight (what WinHTTP allows), sends
// the close frames and closes the handles. The game thread (send, close, the destruction) only queues work under the mutex
// and wakes the driver. WinHTTP's status callback, on WinHTTP's threads or inline inside a call of the driver, only records
// what completed and pushes the events, under the same mutex; it never calls WinHTTP. The driver never holds the mutex during
// a WinHTTP call, so a completion that runs inline never finds it taken.
//
// Each handle that gets callbacks (the request, then the WebSocket handle) has as its context a heap Holder with a shared_ptr
// to the connection's state (Core), deleted on WINHTTP_CALLBACK_STATUS_HANDLE_CLOSING, a handle's last callback: a
// completion that arrives after WinHttpCloseHandle, even once the driver has ended, finds the Core alive with finished_ set,
// and changes nothing. The driver holds a shared_ptr too and is detached. Destroying the connection abandons the queue and
// wakes it: it sends the close frame 1001 once a send in flight has gone out, waits at most kWebSocketCloseWaitSec for that
// and for the server's answer (discarding the messages the server still sends before it; destroyed while Closing, never past
// the close() deadline), and closes the handle. The game thread never waits for the network.
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <winhttp.h>

#include <algorithm>
#include <atomic>
#include <cctype>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <cstring>
#include <deque>
#include <exception>
#include <memory>
#include <mutex>
#include <new>
#include <string>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

#include "fa/core/engine_version.h"
#include "fa/core/strings.h"
#include "fa/platform/websocket.h"
#include "fa/platform/websocket_codec.h"

#ifndef WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT
#define WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT 7
#endif

namespace fa {

namespace {

using Clock = std::chrono::steady_clock;

// The most the game may have queued and not yet sent: send_* fails above it (the script reads bufferedAmount).
constexpr std::size_t kMaxBuffered = 16u * 1024 * 1024;
constexpr auto kCloseWait =
    std::chrono::duration_cast<Clock::duration>(std::chrono::duration<double>(kWebSocketCloseWaitSec));
// WINHTTP_WEB_SOCKET_EMPTY_CLOSE_STATUS: a close frame with no code (and then no reason).
constexpr USHORT kEmptyCloseStatus = 1005;
// The interval of WinHTTP's keep-alive frames on an open connection, in milliseconds: WinHTTP's own default, asked for
// explicitly so that a machine's registry value (HKLM\SOFTWARE\Microsoft\WebSocket\KeepaliveInterval) need not change it.
// WinHTTP refuses less than 15000. Whether a given Windows version honours the option on these handles is not checked: where
// it does not, its own default (the same 30 s) or the registry value applies.
constexpr DWORD kKeepAliveMs = 30000;
// What the asynchronous WinHttpWebSocket* calls may answer besides NO_ERROR: the completion follows as a callback.
constexpr DWORD kIoPending = ERROR_IO_PENDING;
// One WinHttpWebSocketReceive fills at most this much; a longer message arrives as fragments.
constexpr std::size_t kReceiveChunk = 64 * 1024;
// The most WinHttpWebSocketSend takes in one message (its length is a DWORD).
constexpr std::uint64_t kMaxSendBytes = 0xFFFFFFFFull;

std::wstring widen(const std::string& s) {
    if (s.empty()) return {};
    const int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), nullptr, 0);
    std::wstring out(static_cast<std::size_t>(std::max(n, 0)), L'\0');
    if (n > 0) MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), out.data(), n);
    return out;
}

std::string narrow(const std::wstring& s) {
    if (s.empty()) return {};
    const int n = WideCharToMultiByte(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), nullptr, 0, nullptr, nullptr);
    std::string out(static_cast<std::size_t>(std::max(n, 0)), '\0');
    if (n > 0) WideCharToMultiByte(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), out.data(), n, nullptr, nullptr);
    return out;
}

std::string lower(std::string s) {
    for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

bool ends_with(const std::string& s, std::string_view tail) {
    return s.size() >= tail.size() && s.compare(s.size() - tail.size(), tail.size(), tail) == 0;
}

bool is_ascii(std::string_view s) {
    return std::all_of(s.begin(), s.end(), [](char c) { return static_cast<unsigned char>(c) < 0x80; });
}

// The connect timeout in milliseconds, clamped to what a DWORD timeout and an int take.
int timeout_ms(double seconds) { return static_cast<int>(std::min(std::max(seconds * 1000.0, 1.0), 2147483647.0)); }

bool set_dword(HINTERNET handle, DWORD option, DWORD value) {
    return WinHttpSetOption(handle, option, &value, sizeof(value)) != FALSE;
}

void CALLBACK winhttp_status_callback(HINTERNET handle, DWORD_PTR context, DWORD status, LPVOID info, DWORD length);

// The asynchronous session every connection shares (WinHTTP handles are thread safe), with winhttp_status_callback as the callback its
// handles inherit; null when WinHTTP cannot start.
HINTERNET websocket_session() {
    static HINTERNET s = [] {
        const std::wstring agent = widen(std::string("FactorIA/") + FA_ENGINE_VERSION);
        HINTERNET opened = WinHttpOpen(agent.c_str(), WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY, WINHTTP_NO_PROXY_NAME,
                                       WINHTTP_NO_PROXY_BYPASS, WINHTTP_FLAG_ASYNC);
        if (!opened)  // Windows before 8.1 has no automatic proxy: the default proxy settings
            opened = WinHttpOpen(agent.c_str(), WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, WINHTTP_NO_PROXY_NAME,
                                 WINHTTP_NO_PROXY_BYPASS, WINHTTP_FLAG_ASYNC);
        if (opened && WinHttpSetStatusCallback(opened, winhttp_status_callback, WINHTTP_CALLBACK_FLAG_ALL_NOTIFICATIONS,
                                               0) == WINHTTP_INVALID_STATUS_CALLBACK) {
            WinHttpCloseHandle(opened);
            opened = nullptr;
        }
        return opened;
    }();
    return s;
}

// A WinHttpQueryHeaders query as UTF-8 ("" when there is none). `name` is the header of WINHTTP_QUERY_CUSTOM, else null.
std::string query_header(HINTERNET request, DWORD level, const wchar_t* name) {
    const wchar_t* headerName = name ? name : WINHTTP_HEADER_NAME_BY_INDEX;
    DWORD bytes = 0;
    WinHttpQueryHeaders(request, level, headerName, WINHTTP_NO_OUTPUT_BUFFER, &bytes, WINHTTP_NO_HEADER_INDEX);
    if (bytes == 0) return {};
    std::wstring value(bytes / sizeof(wchar_t) + 1, L'\0');
    DWORD size = static_cast<DWORD>(value.size() * sizeof(wchar_t));
    if (!WinHttpQueryHeaders(request, level, headerName, value.data(), &size, WINHTTP_NO_HEADER_INDEX)) return {};
    value.resize(std::min<std::size_t>(value.size(), size / sizeof(wchar_t)));
    while (!value.empty() && value.back() == L'\0') value.pop_back();
    return narrow(value);
}

// The value of `lowerName` in a raw head ("Name: value\r\n" lines), "" when absent.
std::string header_in(const std::string& head, const std::string& lowerName) {
    std::size_t pos = 0;
    while (pos < head.size()) {
        std::size_t end = head.find("\r\n", pos);
        if (end == std::string::npos) end = head.size();
        const std::string line = head.substr(pos, end - pos);
        pos = end + 2;
        const std::size_t colon = line.find(':');
        if (colon == std::string::npos || lower(line.substr(0, colon)) != lowerName) continue;
        std::string value = line.substr(colon + 1);
        while (!value.empty() && (value.front() == ' ' || value.front() == '\t')) value.erase(value.begin());
        while (!value.empty() && (value.back() == ' ' || value.back() == '\t')) value.pop_back();
        return value;
    }
    return {};
}

struct Failure {
    std::string error, hint;
};

std::string timed_out_text(const ws::Url& url, double timeoutSec) {
    // Tenths of a second, so that 0.5 does not read "0 s"; the option is at most 120 s, so the int does not overflow.
    const int tenths = static_cast<int>(std::min(std::max(timeoutSec, 0.0), 100000.0) * 10.0 + 0.5);
    std::string seconds = std::to_string(tenths / 10);
    if (tenths % 10 != 0) seconds += "." + std::to_string(tenths % 10);
    return "timed out connecting to " + url.host_in_brackets() + ":" + std::to_string(url.port) + " after " + seconds +
           " s";
}

// What a failed WinHTTP call while connecting means for the game.
Failure connect_failure(DWORD code, const ws::Url& url, double timeoutSec) {
    const std::string where = url.host_in_brackets() + ":" + std::to_string(url.port);  // "[::1]:9000", not "::1:9000"
    switch (code) {
        case ERROR_WINHTTP_TIMEOUT:
            return {timed_out_text(url, timeoutSec),
                    "Check the connection, or raise the timeout option of websocket.connect."};
        case ERROR_WINHTTP_NAME_NOT_RESOLVED:
            return {"could not find the server " + url.host, "Check the address and the connection."};
        case ERROR_WINHTTP_CANNOT_CONNECT:
            return {"could not connect to " + where,
                    "Check that the server is running and that the address and port are right."};
        case ERROR_WINHTTP_CONNECTION_ERROR:
            return {"the connection to " + where + " broke during the handshake",
                    "Check the address and the port; the server may need wss://."};
        case ERROR_WINHTTP_SECURE_FAILURE:
        case ERROR_WINHTTP_SECURE_CERT_DATE_INVALID:
        case ERROR_WINHTTP_SECURE_CERT_CN_INVALID:
        case ERROR_WINHTTP_SECURE_INVALID_CA:
        case ERROR_WINHTTP_SECURE_CERT_REV_FAILED:
        case ERROR_WINHTTP_SECURE_INVALID_CERT:
        case ERROR_WINHTTP_SECURE_CERT_REVOKED:
            return {
                "the secure connection to " + where + " failed",
                "The server's certificate is not trusted by this computer (an expired certificate, a wrong clock, or "
                "a proxy that rewrites traffic); a server without TLS needs a ws:// address."};
        case ERROR_WINHTTP_INVALID_SERVER_RESPONSE:
            return {
                "the server's answer to the WebSocket handshake is not valid (a wrong Sec-WebSocket-Accept, Upgrade "
                "or Connection header)",
                "The address is not served by a WebSocket server that follows RFC 6455 (a proxy may be in the way)."};
        default: break;
    }
    return {"could not connect to " + where + " (Windows error " + std::to_string(code) + ")",
            "Check the connection, and that the server is up."};
}

struct Outgoing {
    bool binary = false;
    std::string data;
};

class Core;

enum class HandleKind { Request, Socket };

// The context of a WinHTTP handle: keeps the Core alive until the handle's HANDLE_CLOSING, which deletes it.
struct Holder {
    std::shared_ptr<Core> core;
    HandleKind kind;
};

// Everything the driver thread, WinHTTP's callbacks and the game thread share. The driver and the Holders keep it alive (a
// shared_ptr each), so it may outlive the WinHttpConnection the game holds. The fields below mutex_ are guarded by it. No
// WinHTTP call is made while it is held.
class Core : public std::enable_shared_from_this<Core> {
public:
    Core(WebSocketRequest request, ws::Url url) : options_(std::move(request)), url_(std::move(url)) {}

    void start() {
        try {
            std::thread([self = shared_from_this()] { self->drive(); }).detach();
        } catch (const std::exception& e) {  // no thread to be had (std::system_error)
            std::lock_guard<std::mutex> lock(mutex_);
            fail_locked(std::string("could not start the connection (") + e.what() + ")",
                        "Close other connections or programs and try again.");
        }
    }

    // The game let go of the connection: nothing more is delivered, and nothing is waited for. The driver says goodbye
    // (1001) and closes the handles.
    void release() {
        std::lock_guard<std::mutex> lock(mutex_);
        queue_->abandon();
        stop_ = true;
        finished_ = true;
        wake_.notify_all();
    }

    // Closed as soon as the queue holds its last event: a queue that overflowed holds [Error, Close 1008] before
    // deliver_locked has set state_.
    WebSocketState state() const { return queue_->ended() ? WebSocketState::Closed : state_.load(); }

    Result<void> send(bool binary, const void* data, std::size_t size) {
        std::lock_guard<std::mutex> lock(mutex_);
        const WebSocketState s = state_.load();
        if (s == WebSocketState::Connecting)
            return make_error("the connection is not open yet", "Wait for the \"open\" event before sending.");
        if (s != WebSocketState::Open)
            return make_error("the connection is closing or closed", "Connect again to send.");
        if (size > options_.maxMessageBytes)
            return make_error("the message is " + std::to_string(size) + " bytes; the most is " +
                                  std::to_string(options_.maxMessageBytes),
                              "Split the data into smaller messages, or raise the maxMessageBytes option.");
        if (static_cast<std::uint64_t>(size) > kMaxSendBytes)
            return make_error("the message is " + std::to_string(size) + " bytes; WinHTTP sends at most " +
                                  std::to_string(kMaxSendBytes) + " bytes in one message",
                              "Split the data into smaller messages.");
        if (buffered_ > kMaxBuffered)
            return make_error("more than " + std::to_string(kMaxBuffered / (1024 * 1024)) + " MB wait to be sent",
                              "Send less, or wait until bufferedAmount drops.");
        Outgoing message;
        message.binary = binary;
        if (size > 0) message.data.assign(static_cast<const char*>(data), size);
        if (!binary && !is_valid_utf8(message.data))
            return make_error("the text is not valid UTF-8", "Send other data with send_binary.");
        outgoing_.push_back(std::move(message));
        buffered_ += size;
        wake_.notify_all();
        return {};
    }

    Result<void> close(int code, std::string_view reason) {
        if (auto r = ws::check_close_request(code, reason); !r.ok()) return r;
        std::lock_guard<std::mutex> lock(mutex_);
        const WebSocketState s = state_.load();
        if (s == WebSocketState::Closing || s == WebSocketState::Closed) return {};
        if (s == WebSocketState::Connecting) {
            // Closing at once. The driver ends the attempt with Error and Close 1006 and closes the request handle, which
            // cancels what WinHTTP has in flight; then it is Closed.
            abort_ = true;
        } else {
            closeAsked_ = true;
            closeCode_ = code;
            closeReason_ = std::string(reason);
            closeDeadline_ = Clock::now() + kCloseWait;  // queued sends, our close frame and the server's answer
        }
        state_ = WebSocketState::Closing;
        wake_.notify_all();
        return {};
    }

    std::size_t buffered_amount() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return buffered_;
    }

    std::size_t poll(std::vector<WebSocketEvent>& out) { return queue_->drain(out); }

    // WinHTTP's callback for a handle of this connection (not HANDLE_CLOSING, which winhttp_status_callback handles). It only records
    // what completed: it may run inline inside a WinHTTP call of the driver, which does not hold the mutex then.
    void on_status(HandleKind kind, DWORD status, const void* info, DWORD length) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (kind == HandleKind::Request)
            request_status_locked(status, info, length);
        else
            socket_status_locked(status, info, length);
        wake_.notify_all();
    }

private:
    // -------------------------------------------------------------------------------------- shared, mutex_ held ---
    // The end of the connection: state() is Closed BEFORE the events are pushed. Only the first end reports.
    void finish_locked(std::vector<WebSocketEvent> events) {
        if (finished_) return;
        finished_ = true;
        state_ = WebSocketState::Closed;
        for (WebSocketEvent& e : events)
            if (!queue_->push(std::move(e))) break;
        wake_.notify_all();
    }

    // Every failure ends with Error and then Close 1006, wasClean false.
    void fail_locked(std::string error, std::string hint, int httpStatus = 0) {
        std::vector<WebSocketEvent> events;
        events.push_back(WebSocketEvent::failure(std::move(error), std::move(hint), httpStatus));
        events.push_back(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
        finish_locked(std::move(events));
    }

    void lost_locked(DWORD code, const char* during) {
        if (code == static_cast<DWORD>(ERROR_WINHTTP_INVALID_SERVER_RESPONSE))
            fail_locked("the server sent data that breaks the WebSocket protocol (Windows error " +
                            std::to_string(code) + ")",
                        "Check the server: it does not follow RFC 6455.");
        else
            fail_locked("the connection to " + url_.host + " was lost" + during + " (Windows error " +
                            std::to_string(code) + ")",
                        "Check the connection; try again.");
    }

    // A failure the server is told about with a close frame (1007, 1008, 1009): the driver sends it, then closes.
    void owe_close_frame_locked(int code) {
        if (goodbyeCode_ == 0) goodbyeCode_ = code;
    }

    // Open, Text, Binary. When the queue ended under it (it overflowed and holds [Error, Close 1008]) the connection stops,
    // and the server is sent 1008.
    void deliver_locked(WebSocketEvent event) {
        if (finished_) return;
        if (queue_->push(std::move(event))) return;
        finished_ = true;
        state_ = WebSocketState::Closed;
        owe_close_frame_locked(ws::close_code::kPolicyViolation);
    }

    void request_status_locked(DWORD status, const void* info, DWORD length) {
        switch (status) {
            case WINHTTP_CALLBACK_STATUS_SENDREQUEST_COMPLETE: sendRequestDone_ = true; break;
            case WINHTTP_CALLBACK_STATUS_HEADERS_AVAILABLE: headersAvailable_ = true; break;
            case WINHTTP_CALLBACK_STATUS_REQUEST_ERROR: {
                DWORD code = ERROR_WINHTTP_CONNECTION_ERROR;
                WINHTTP_ASYNC_RESULT result{};
                if (info && length >= sizeof(result)) {
                    std::memcpy(&result, info, sizeof(result));
                    if (result.dwError != 0) code = result.dwError;
                }
                if (requestError_ == 0) requestError_ = code;
                break;
            }
            default: break;
        }
    }

    void socket_status_locked(DWORD status, const void* info, DWORD length) {
        switch (status) {
            case WINHTTP_CALLBACK_STATUS_READ_COMPLETE: {
                recvPending_ = false;
                WINHTTP_WEB_SOCKET_STATUS got{};
                if (!info || length < sizeof(got)) {
                    socketBroken_ = true;
                    if (!finished_)
                        fail_locked("WinHTTP finished a receive without saying what arrived",
                                    "Try again; if it keeps happening, report it with the Windows version.");
                    return;
                }
                std::memcpy(&got, info, sizeof(got));
                received_locked(got.dwBytesTransferred, got.eBufferType);
                break;
            }
            case WINHTTP_CALLBACK_STATUS_WRITE_COMPLETE:
                if (!sendPending_) break;  // nothing of ours was in flight
                sendPending_ = false;
                buffered_ -= std::min(buffered_, sending_.data.size());
                break;
            case WINHTTP_CALLBACK_STATUS_SHUTDOWN_COMPLETE: shutdownPending_ = false; break;
            case WINHTTP_CALLBACK_STATUS_CLOSE_COMPLETE: closePending_ = false; break;
            case WINHTTP_CALLBACK_STATUS_REQUEST_ERROR: {
                WINHTTP_WEB_SOCKET_ASYNC_RESULT result{};
                const bool described = info && length >= sizeof(result);
                if (described) std::memcpy(&result, info, sizeof(result));
                // The handle is closed next, which ends whatever else is in flight.
                socketBroken_ = true;
                sendPending_ = recvPending_ = shutdownPending_ = closePending_ = false;
                if (!finished_) {
                    const char* during = "";
                    if (described && result.Operation == WINHTTP_WEB_SOCKET_SEND_OPERATION) during = " while sending";
                    if (described && result.Operation == WINHTTP_WEB_SOCKET_SHUTDOWN_OPERATION)
                        during = " while closing";
                    lost_locked(described ? result.AsyncResult.dwError
                                          : static_cast<DWORD>(ERROR_WINHTTP_CONNECTION_ERROR),
                                during);
                }
                break;
            }
            default: break;
        }
    }

    // What one WinHttpWebSocketReceive brought.
    void received_locked(DWORD bytes, WINHTTP_WEB_SOCKET_BUFFER_TYPE type) {
        // Also once over: the server's answer to our last close frame ends the driver's wait for it (open_phase).
        if (type == WINHTTP_WEB_SOCKET_CLOSE_BUFFER_TYPE) closeFrameReceived_ = true;
        if (finished_) {
            // What the driver reads and discards while it waits for the close answer. A read of 0 bytes that is neither
            // a close frame nor a whole message (an empty message is something the server sent, like any other) is an
            // empty read: they are counted in a row, so that the wait does not arm receives for ever on a peer that
            // answers with nothing. The server that keeps sending empty messages is bounded by the deadline.
            if (type != WINHTTP_WEB_SOCKET_CLOSE_BUFFER_TYPE) {
                const bool wholeMessage = type == WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE ||
                                          type == WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE;
                emptyReadsOver_ = bytes == 0 && !wholeMessage ? emptyReadsOver_ + 1 : 0;
            }
            return;
        }
        if (type == WINHTTP_WEB_SOCKET_CLOSE_BUFFER_TYPE) {
            peerCloseSeen_ = true;  // the driver reads its code and reason, and answers
            return;
        }
        const std::size_t got = std::min<std::size_t>(bytes, receiveBuffer_.size());
        const bool text =
            type == WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE || type == WINHTTP_WEB_SOCKET_UTF8_FRAGMENT_BUFFER_TYPE;
        const bool last = type == WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE ||
                          type == WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE;
        if (!inMessage_) {
            inMessage_ = true;
            messageIsText_ = text;
        }
        // Checked as the fragments arrive, before they are kept (message_.size() never exceeds the limit).
        if (got > options_.maxMessageBytes - message_.size()) {
            fail_locked("a message from the server is longer than " + std::to_string(options_.maxMessageBytes) +
                            " bytes (the maxMessageBytes option)",
                        "Raise the maxMessageBytes option of websocket.connect, or ask the server to send smaller "
                        "messages.");
            owe_close_frame_locked(ws::close_code::kMessageTooBig);
            return;
        }
        message_.append(receiveBuffer_.data(), got);
        if (!last) return;
        std::string data = std::move(message_);
        message_.clear();
        inMessage_ = false;
        if (messageIsText_ && !is_valid_utf8(data)) {
            fail_locked("the server sent a text message that is not valid UTF-8",
                        "Check the server: binary data goes in binary messages.");
            owe_close_frame_locked(ws::close_code::kInvalidData);
            return;
        }
        deliver_locked(messageIsText_ ? WebSocketEvent::text(std::move(data))
                                      : WebSocketEvent::binary(std::move(data)));
    }

    // ------------------------------------------------------------------------------------------------ the driver ---
    void drive() {
        HINTERNET connect = nullptr, request = nullptr, socket = nullptr;
        try {
            if (connect_phase(connect, request, socket)) open_phase(socket);
        } catch (const std::exception& e) {  // std::bad_alloc
            std::lock_guard<std::mutex> lock(mutex_);
            fail_locked(std::string("the connection failed (") + e.what() + ")", "Try again.");
        }
        // Children first. Closing an asynchronous handle ends what is in flight on it; its last callbacks may still come
        // after this, and find the Core kept alive by the handle's Holder.
        if (socket) WinHttpCloseHandle(socket);
        if (request) WinHttpCloseHandle(request);
        if (connect) WinHttpCloseHandle(connect);
    }

    // Connects and upgrades. True when the connection is open (`socket` is the WebSocket handle, the Open event is
    // delivered); false when it ended, reported unless it was destroyed. The handles it leaves are closed by drive().
    bool connect_phase(HINTERNET& connect, HINTERNET& request, HINTERNET& socket) {
        const auto deadline = Clock::now() + std::chrono::milliseconds(timeout_ms(options_.connectTimeoutSec));
        DWORD code = 0;  // the WinHTTP error that ended the attempt (0: see `failure`)
        Failure failure;
        int httpStatus = 0;
        std::string subprotocol;
        const bool upgraded = open_request(connect, request, code, failure) &&
                              wait_connect(
                                  deadline, [this] { return sendRequestDone_; }, code) &&
                              receive_response(request, code) &&
                              wait_connect(
                                  deadline, [this] { return headersAvailable_; }, code) &&
                              upgrade(request, socket, subprotocol, code, failure, httpStatus);
        std::lock_guard<std::mutex> lock(mutex_);
        if (stop_) return false;  // destroyed: nothing to report
        // The timeout first: a close() that came after the deadline passed (wait_connect stops at the first of them) must
        // not hide that the attempt had timed out.
        if (timedOut_) {
            fail_locked(timed_out_text(url_, options_.connectTimeoutSec),
                        "Check the connection, or raise the timeout option of websocket.connect.");
            return false;
        }
        if (abort_) {
            fail_locked("the connection was closed before it was open",
                        "close() was called before the connection opened; wait for the 'open' event, or ignore this "
                        "error.");
            return false;
        }
        if (!upgraded) {
            if (code != 0) failure = connect_failure(code, url_, options_.connectTimeoutSec);
            fail_locked(failure.error, failure.hint, httpStatus);
            return false;
        }
        state_ = WebSocketState::Open;  // before the event: when the game reads Open, state() is Open
        deliver_locked(WebSocketEvent::open(subprotocol));
        return true;
    }

    // Until `done` (set by a callback), a request error, the deadline, a close() or the destruction.
    template <class Done>
    bool wait_connect(Clock::time_point deadline, Done done, DWORD& code) {
        std::unique_lock<std::mutex> lock(mutex_);
        for (;;) {
            if (stop_ || abort_) return false;
            if (requestError_ != 0) {
                code = requestError_;
                return false;
            }
            if (done()) return true;
            if (Clock::now() >= deadline) {
                timedOut_ = true;
                return false;
            }
            wake_.wait_until(lock, deadline);
        }
    }

    // The request, its options and its context, then WinHttpSendRequest (asynchronous: SENDREQUEST_COMPLETE follows).
    bool open_request(HINTERNET& connect, HINTERNET& request, DWORD& code, Failure& failure) {
        HINTERNET session = websocket_session();
        if (!session) {
            failure = {"WinHTTP could not start",
                       "Restart the game; if it keeps failing, Windows' networking is not working."};
            return false;
        }
        // WinHttpConnect takes an IPv6 address in brackets ("[::1]"); ws::Url keeps it without.
        const std::wstring host = widen(url_.host_in_brackets());
        connect = WinHttpConnect(session, host.c_str(), static_cast<INTERNET_PORT>(url_.port), 0);
        if (!connect) {
            code = GetLastError();
            return false;
        }
        const std::wstring path = widen(url_.path.empty() ? std::string("/") : url_.path);
        request = WinHttpOpenRequest(connect, L"GET", path.c_str(), nullptr, WINHTTP_NO_REFERER,
                                     WINHTTP_DEFAULT_ACCEPT_TYPES, url_.secure ? WINHTTP_FLAG_SECURE : 0);
        if (!request) {
            code = GetLastError();
            return false;
        }
        auto* holder = new Holder{shared_from_this(), HandleKind::Request};
        DWORD_PTR context = reinterpret_cast<DWORD_PTR>(holder);
        if (!WinHttpSetOption(request, WINHTTP_OPTION_CONTEXT_VALUE, &context, sizeof(context))) {
            code = GetLastError();
            delete holder;  // a handle without a context gets no HANDLE_CLOSING
            return false;
        }
        // From here the Holder belongs to the handle. The callback is the session's; set again so it does not depend on
        // inheritance.
        if (WinHttpSetStatusCallback(request, winhttp_status_callback, WINHTTP_CALLBACK_FLAG_ALL_NOTIFICATIONS, 0) ==
            WINHTTP_INVALID_STATUS_CALLBACK) {
            code = GetLastError();
            return false;
        }
        const int timeoutMs = timeout_ms(options_.connectTimeoutSec);
        if (!WinHttpSetTimeouts(request, timeoutMs, timeoutMs, timeoutMs, timeoutMs)) {
            code = GetLastError();
            return false;
        }
        // Older WinHTTP does not know this option: WinHttpSetTimeouts' receive timeout and the driver's own deadline still
        // bound the wait for the answer.
        set_dword(request, WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT, static_cast<DWORD>(timeoutMs));
        // A WebSocket handshake does not follow redirects: a 3xx is reported with its status, as the browser does. Cookies
        // and authentication stay off: only what the game put in headers is sent.
        if (!set_dword(request, WINHTTP_OPTION_REDIRECT_POLICY, WINHTTP_OPTION_REDIRECT_POLICY_NEVER) ||
            !set_dword(request, WINHTTP_OPTION_DISABLE_FEATURE,
                       WINHTTP_DISABLE_COOKIES | WINHTTP_DISABLE_AUTHENTICATION) ||
            !WinHttpSetOption(request, WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET, nullptr, 0)) {
            code = GetLastError();
            return false;
        }
        // The keep-alive interval, asked for on the request so the WebSocket handle may start with it; where WinHTTP takes
        // it only on the WebSocket handle, upgrade() asks there. WinHTTP may accept the option and ignore it: the keep-alive
        // is then WinHTTP's own default.
        keepAliveSet_ = set_dword(request, WINHTTP_OPTION_WEB_SOCKET_KEEPALIVE_INTERVAL, kKeepAliveMs);

        std::wstring headers;
        if (!options_.subprotocols.empty()) {
            std::string offered;
            for (const std::string& p : options_.subprotocols) offered += (offered.empty() ? "" : ", ") + p;
            headers += L"Sec-WebSocket-Protocol: " + widen(offered) + L"\r\n";
        }
        for (const auto& [name, value] : options_.headers) headers += widen(name) + L": " + widen(value) + L"\r\n";
        if (!WinHttpSendRequest(request, headers.empty() ? WINHTTP_NO_ADDITIONAL_HEADERS : headers.c_str(),
                                headers.empty() ? 0 : static_cast<DWORD>(-1), WINHTTP_NO_REQUEST_DATA, 0, 0, context)) {
            code = GetLastError();
            return false;
        }
        return true;
    }

    // Asynchronous: HEADERS_AVAILABLE follows.
    static bool receive_response(HINTERNET request, DWORD& code) {
        if (WinHttpReceiveResponse(request, nullptr)) return true;
        code = GetLastError();
        return false;
    }

    // The server's answer, checked; then the WebSocket handle. On success the request handle is closed (and null).
    bool upgrade(HINTERNET& request, HINTERNET& socket, std::string& subprotocol, DWORD& code, Failure& failure,
                 int& httpStatus) {
        DWORD status = 0, size = sizeof(status);
        if (!WinHttpQueryHeaders(request, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
                                 WINHTTP_HEADER_NAME_BY_INDEX, &status, &size, WINHTTP_NO_HEADER_INDEX)) {
            code = GetLastError();
            return false;
        }
        // The server's head, checked by the same code as the other clients (status, Upgrade, Connection, the accept key,
        // the subprotocol), so that a refused handshake reads the same on every platform.
        std::string head = query_header(request, WINHTTP_QUERY_RAW_HEADERS_CRLF, nullptr);
        if (!head.empty() && !ends_with(head, "\r\n\r\n")) head += ends_with(head, "\r\n") ? "\r\n" : "\r\n\r\n";
        // The key WinHTTP sent, to check the server's Sec-WebSocket-Accept here. When WinHTTP does not show it, the check
        // is WinHttpWebSocketCompleteUpgrade's own.
        const std::string key = header_in(
            query_header(request, WINHTTP_QUERY_RAW_HEADERS_CRLF | WINHTTP_QUERY_FLAG_REQUEST_HEADERS, nullptr),
            "sec-websocket-key");
        if (status != 101) {
            httpStatus = static_cast<int>(status);
            const ws::HandshakeResult refused = ws::check_server_response(head, key, options_.subprotocols);
            if (!head.empty() && !refused.ok && refused.status == httpStatus)
                failure = {refused.error, refused.hint};
            else
                failure = {"the server refused the WebSocket upgrade with HTTP " + std::to_string(status),
                           "Check the address and what the server expects."};
            return false;
        }
        subprotocol = query_header(request, WINHTTP_QUERY_CUSTOM, L"Sec-WebSocket-Protocol");
        if (!key.empty() && !head.empty()) {
            const ws::HandshakeResult checked = ws::check_server_response(head, key, options_.subprotocols);
            if (!checked.ok) {
                failure = {checked.error, checked.hint};
                return false;
            }
            subprotocol = checked.subprotocol;
        } else if (!subprotocol.empty() && std::find(options_.subprotocols.begin(), options_.subprotocols.end(),
                                                     subprotocol) == options_.subprotocols.end()) {
            failure = {"the server chose the subprotocol \"" + subprotocol + "\", which was not offered",
                       options_.subprotocols.empty() ? "The game offered no subprotocol: pass the protocols option."
                                                     : "Check the protocols option and what the server supports."};
            return false;
        }

        // The connect timeout is for the handshake only: an open connection waits for messages, and for a send to go out,
        // as long as it lives (0 = no timeout). Set on the request, which the WebSocket handle is made from
        // (WinHttpSetTimeouts is documented for session and request handles only).
        const int timeoutMs = timeout_ms(options_.connectTimeoutSec);
        if (!WinHttpSetTimeouts(request, timeoutMs, timeoutMs, 0, 0)) {
            code = GetLastError();
            return false;
        }
        auto* holder = new Holder{shared_from_this(), HandleKind::Socket};
        socket = WinHttpWebSocketCompleteUpgrade(request, reinterpret_cast<DWORD_PTR>(holder));
        if (!socket) {
            code = GetLastError();
            if (code == 0) code = ERROR_WINHTTP_INVALID_SERVER_RESPONSE;
            delete holder;  // no handle, no HANDLE_CLOSING
            return false;
        }
        // From here the Holder belongs to the WebSocket handle: WinHttpWebSocketCompleteUpgrade associates its pContext
        // with the new handle (the request keeps its own Holder). The callback is another matter. WinHttpSetStatusCallback
        // says "a callback function can be set on any handle and is inherited by derived handles", so the new handle
        // should have the request's callback (the same function) already, and the call below only makes sure. If it
        // fails, the Holder is not deleted here: with the callback inherited, the handle gets its HANDLE_CLOSING when
        // drive() closes it and the callback deletes the Holder there, so deleting it now would be a second delete. If
        // the handle had not inherited it, it would get no HANDLE_CLOSING and the Holder would leak (a few bytes and a
        // reference to the Core, once per failed connection), never be deleted twice.
        if (WinHttpSetStatusCallback(socket, winhttp_status_callback, WINHTTP_CALLBACK_FLAG_ALL_NOTIFICATIONS, 0) ==
            WINHTTP_INVALID_STATUS_CALLBACK) {
            code = GetLastError();
            return false;
        }
        // Where neither handle takes it, WinHTTP keeps its default (30 s, like kKeepAliveMs).
        if (!keepAliveSet_) set_dword(socket, WINHTTP_OPTION_WEB_SOCKET_KEEPALIVE_INTERVAL, kKeepAliveMs);
        WinHttpCloseHandle(request);  // the WebSocket handle lives on without it
        request = nullptr;
        return true;
    }

    // Open (or Closing at the game's request) until the connection ends; then the close frame that is owed, if any.
    void open_phase(HINTERNET socket) {
        std::unique_lock<std::mutex> lock(mutex_);
        Clock::time_point endDeadline{};
        bool ending = false;
        for (;;) {
            if (socketBroken_) return;  // a REQUEST_ERROR reported it (unless it was over already)
            if (peerCloseSeen_ && !peerCloseRead_) {
                peerCloseRead_ = true;
                lock.unlock();
                USHORT status = 0;
                char reason[128] = {};
                DWORD reasonBytes = 0;
                const DWORD rc =
                    WinHttpWebSocketQueryCloseStatus(socket, &status, reason, sizeof(reason), &reasonBytes);
                lock.lock();
                if (rc != NO_ERROR) {
                    // The server's close frame arrived but WinHTTP cannot say what is in it (an empty close frame is
                    // NO_ERROR with status 1005): report a failure, not a clean 1005. The server still gets its answer,
                    // a close frame without a status (1005), so that it does not see the connection drop (1006): the
                    // loop goes on to the part that sends what is owed.
                    if (!closeFrameSent_) {
                        echoOwed_ = true;
                        echoCode_ = kEmptyCloseStatus;
                    }
                    if (!finished_)
                        fail_locked("the server closed the connection, but Windows could not read its close status "
                                    "(Windows error " +
                                        std::to_string(rc) + ")",
                                    "Check the server; try again.");
                    continue;
                }
                const int peerCode = status;
                std::string peerReason(reason, std::min<std::size_t>(reasonBytes, sizeof(reason)));
                if (!is_valid_utf8(peerReason)) peerReason.clear();
                // Our close went out first: this is its answer, and the handshake is done. Else WinHttpWebSocketClose
                // answers with the server's code.
                if (!closeFrameSent_) {
                    echoOwed_ = true;
                    echoCode_ =
                        ws::close_code_valid_on_wire(peerCode) ? static_cast<USHORT>(peerCode) : kEmptyCloseStatus;
                }
                std::vector<WebSocketEvent> events;
                events.push_back(WebSocketEvent::close(peerCode, std::move(peerReason), true));
                finish_locked(std::move(events));
                continue;
            }

            if (finished_) {
                // Over (closed, failed or destroyed): the close frame that is owed, then the handle is closed. Bounded by
                // kWebSocketCloseWaitSec from here, and never past the deadline of a close() asked before (destroyed while
                // Closing): a send stuck against a server that does not read ends with the handle.
                if (!ending) {
                    ending = true;
                    endDeadline = Clock::now() + kCloseWait;
                    if (closeAsked_) endDeadline = std::min(endDeadline, closeDeadline_);
                }
                const bool goodbyeOwed = !closeFrameSent_ && !peerCloseSeen_ && (stop_ || goodbyeCode_ != 0);
                const bool busy = sendPending_ || shutdownPending_ || closePending_;
                if (echoOwed_ && !busy) {
                    echoOwed_ = false;
                    closeFrameSent_ = true;
                    closePending_ = true;
                    const USHORT code = echoCode_;
                    lock.unlock();
                    const DWORD rc = WinHttpWebSocketClose(socket, code, nullptr, 0);
                    lock.lock();
                    // NO_ERROR or ERROR_IO_PENDING: the close handshake goes on, CLOSE_COMPLETE follows. Any other
                    // answer means the connection is gone; the game has its Close event already.
                    if (rc != NO_ERROR && rc != kIoPending) return;
                    continue;
                }
                if (goodbyeOwed && !busy) {
                    closeFrameSent_ = true;
                    const USHORT code =
                        static_cast<USHORT>(goodbyeCode_ != 0 ? goodbyeCode_ : ws::close_code::kGoingAway);
                    if (!shutdown(lock, socket, code, nullptr, 0)) return;
                    continue;
                }
                // Our close frame went out and the server has not answered: one receive stays in flight until its close
                // frame arrives or the deadline passes. What the server still sends before that is read and discarded
                // (received_locked keeps nothing once over), so a server that keeps talking does not get the handle
                // closed on its first message. Only the driver arms a receive, and only when none is in flight
                // (READ_COMPLETE clears recvPending_ under the mutex once it is done with receiveBuffer_).
                // An empty read that is not a close frame is armed again once; a second one in a row ends the wait (a
                // peer that answers with nothing would otherwise keep this loop busy until the deadline).
                if (closeFrameSent_ && !closeFrameReceived_ && !recvPending_ && emptyReadsOver_ < 2 &&
                    Clock::now() < endDeadline) {
                    // False: the connection is gone, and the game has its Close event already.
                    if (!arm_receive(lock, socket)) return;
                    continue;
                }
                // The handle stays open until the server answers (RFC 6455 7.1.1, the server ends the TCP connection
                // first), within the same deadline. Closed at once, the connection is reset right behind the frame, and a
                // server on Windows loses what it had not read yet when a reset arrives: the close frame with it (the
                // server saw the connection drop, never the 1001).
                const bool answerAwaited = closeFrameSent_ && recvPending_ && !closeFrameReceived_;
                if (!echoOwed_ && !goodbyeOwed && !shutdownPending_ && !closePending_ && !answerAwaited) return;
                if (Clock::now() >= endDeadline) return;
                wake_.wait_until(lock, endDeadline);
                continue;
            }

            // Open, or Closing at the game's request.
            if (!recvPending_) {
                if (!arm_receive(lock, socket)) return;
                continue;
            }
            if (!sendPending_ && !closeFrameSent_ && !outgoing_.empty()) {
                sending_ = std::move(outgoing_.front());
                outgoing_.pop_front();
                sendPending_ = true;
                const WINHTTP_WEB_SOCKET_BUFFER_TYPE type = sending_.binary
                                                                ? WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE
                                                                : WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE;
                // sending_ stays as it is until WRITE_COMPLETE: WinHTTP reads it while the send is in flight.
                void* data = sending_.data.data();
                const DWORD bytes = static_cast<DWORD>(sending_.data.size());  // send() kept it within a DWORD
                lock.unlock();
                const DWORD rc = WinHttpWebSocketSend(socket, type, data, bytes);
                lock.lock();
                if (rc != NO_ERROR && rc != kIoPending) {
                    sendPending_ = false;
                    if (!finished_) lost_locked(rc, " while sending");
                    return;
                }
                continue;
            }
            if (closeAsked_ && !closeFrameSent_ && outgoing_.empty() && !sendPending_) {
                closeFrameSent_ = true;
                // closeReason_ does not change after close() (a second close() returns at Closing).
                if (!shutdown(lock, socket, static_cast<USHORT>(closeCode_),
                              closeReason_.empty() ? nullptr : closeReason_.data(),
                              static_cast<DWORD>(closeReason_.size())))
                    return;
                continue;
            }
            if (closeAsked_) {  // queued sends, our close frame, then the server's answer: at most kWebSocketCloseWaitSec
                if (Clock::now() >= closeDeadline_) {
                    fail_locked("the server did not answer the close within " +
                                    std::to_string(static_cast<int>(kWebSocketCloseWaitSec)) + " s",
                                "The connection was dropped instead; the server may be busy or gone.");
                    return;
                }
                wake_.wait_until(lock, closeDeadline_);
                continue;
            }
            wake_.wait(lock);
        }
    }

    // mutex_ held (through `lock`) except during the call; the caller checked that no receive is in flight. Arms one
    // receive. False when the connection is gone: reported to the game as a failure unless the connection was over
    // already (finished_, as in the drain after our close frame), where the caller reports nothing and ends.
    bool arm_receive(std::unique_lock<std::mutex>& lock, HINTERNET socket) {
        recvPending_ = true;
        lock.unlock();
        // In asynchronous mode the size and the type come with READ_COMPLETE; the out parameters are members nobody
        // reads, in case WinHTTP writes them anyway.
        const DWORD rc =
            WinHttpWebSocketReceive(socket, receiveBuffer_.data(), static_cast<DWORD>(receiveBuffer_.size()),
                                    &receiveBytesOut_, &receiveTypeOut_);
        lock.lock();
        if (rc != NO_ERROR && rc != kIoPending) {  // the asynchronous API may answer either
            recvPending_ = false;
            if (!finished_) lost_locked(rc, "");
            return false;
        }
        return true;
    }

    // mutex_ held (through `lock`) except during the call. WinHttpWebSocketShutdown: our close frame, the receive side stays
    // open for the server's answer. False when the connection is gone (reported unless it was over already).
    bool shutdown(std::unique_lock<std::mutex>& lock, HINTERNET socket, USHORT code, void* reason, DWORD reasonBytes) {
        shutdownPending_ = true;
        lock.unlock();
        const DWORD rc = WinHttpWebSocketShutdown(socket, code, reason, reasonBytes);
        lock.lock();
        if (rc == kIoPending) return true;  // SHUTDOWN_COMPLETE follows
        shutdownPending_ = false;
        if (rc == NO_ERROR) return true;  // done already
        if (!finished_) lost_locked(rc, " while closing");
        return false;
    }

    const WebSocketRequest options_;
    const ws::Url url_;
    std::shared_ptr<WebSocketEventQueue> queue_ =
        std::make_shared<WebSocketEventQueue>(WebSocketEventQueue::limit_for(options_.maxMessageBytes));
    std::atomic<WebSocketState> state_{WebSocketState::Connecting};  // written under mutex_, read without it
    // Written by WinHTTP while a receive is in flight, read by the READ_COMPLETE callback; the driver never touches them.
    std::vector<char> receiveBuffer_ = std::vector<char>(kReceiveChunk);
    DWORD receiveBytesOut_ = 0;
    WINHTTP_WEB_SOCKET_BUFFER_TYPE receiveTypeOut_ = WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE;
    bool keepAliveSet_ = false;  // the driver's only

    mutable std::mutex mutex_;
    std::condition_variable wake_;  // the driver waits on it
    bool stop_ = false;             // the game destroyed the connection
    bool abort_ = false;            // close() while connecting
    bool timedOut_ = false;         // the connect timeout passed
    bool sendRequestDone_ = false, headersAvailable_ = false;
    DWORD requestError_ = 0;  // a REQUEST_ERROR on the request handle
    // The Close event was pushed, or the queue ended or was abandoned: nothing more is delivered.
    bool finished_ = false;
    bool socketBroken_ = false;  // a REQUEST_ERROR on the WebSocket handle: it is closed next
    bool recvPending_ = false, sendPending_ = false, shutdownPending_ = false, closePending_ = false;
    bool closeAsked_ = false, closeFrameSent_ = false;
    bool peerCloseSeen_ = false, peerCloseRead_ = false, echoOwed_ = false;
    bool closeFrameReceived_ = false;  // a close frame arrived, even after the connection was over (received_locked)
    // Empty reads in a row once over (no bytes, not a close frame or a whole message; received_locked): two end the drain.
    int emptyReadsOver_ = 0;
    USHORT echoCode_ = kEmptyCloseStatus;
    int closeCode_ = 0, goodbyeCode_ = 0;
    std::string closeReason_;
    Clock::time_point closeDeadline_{};
    std::deque<Outgoing> outgoing_;
    Outgoing sending_;  // the message in flight (sendPending_)
    std::size_t buffered_ = 0;
    std::string message_;  // the fragments of the message being received
    bool inMessage_ = false, messageIsText_ = false;
};

// Every handle of the session gets here. The session and connect handles carry no context. HANDLE_CLOSING is a handle's
// last callback, never concurrent with another one for it: the Holder goes then.
void CALLBACK winhttp_status_callback(HINTERNET, DWORD_PTR context, DWORD status, LPVOID info, DWORD length) {
    if (context == 0) return;
    auto* holder = reinterpret_cast<Holder*>(context);
    if (status == WINHTTP_CALLBACK_STATUS_HANDLE_CLOSING) {
        delete holder;
        return;
    }
    try {
        holder->core->on_status(holder->kind, status, info, length);
    } catch (...) {  // nothing may unwind into WinHTTP (an allocation that fails while pushing an event)
    }
}

// What the game holds: forwards to the Core and lets go of it on destruction without waiting for the network.
class WinHttpConnection final : public WebSocket {
public:
    explicit WinHttpConnection(std::shared_ptr<Core> core) : core_(std::move(core)) { core_->start(); }
    ~WinHttpConnection() override { core_->release(); }
    WebSocketState state() const override { return core_->state(); }
    Result<void> send_text(std::string_view text) override { return core_->send(false, text.data(), text.size()); }
    Result<void> send_binary(const void* data, std::size_t size) override { return core_->send(true, data, size); }
    Result<void> close(int code, std::string_view reason) override { return core_->close(code, reason); }
    std::size_t buffered_amount() const override { return core_->buffered_amount(); }
    std::size_t poll(std::vector<WebSocketEvent>& out) override { return core_->poll(out); }

private:
    std::shared_ptr<Core> core_;
};

class WinHttpWebSocketClient final : public WebSocketClient {
public:
    std::string name() const override { return "winhttp"; }
    bool available() const override { return websocket_session() != nullptr; }
    std::string unavailable_reason() const override {
        return websocket_session() ? std::string() : "WinHTTP could not start";
    }
    Result<std::unique_ptr<WebSocket>> connect(WebSocketRequest request) override {
        if (!websocket_session())
            return make_error("WebSocket is not available: WinHTTP could not start",
                              "Check websocket.supported before connecting, and let the game carry on offline.");
        auto url = ws::parse_url(request.url);
        if (!url.ok()) return url.error();
        // A header or subprotocol the handshake refuses is an error now, not a failed connection later.
        const std::uint8_t zeros[16] = {};
        if (auto head = ws::build_client_request(url.value(), ws::make_client_key(zeros), request.subprotocols,
                                                 request.headers);
            !head.ok())
            return head.error();
        // WinHTTP sends header values as 8-bit text: what is not ASCII would not reach the server as the game wrote it.
        for (const auto& [name, value] : request.headers)
            if (!is_ascii(name) || !is_ascii(value))
                return make_error("the header \"" + name +
                                      "\" has characters that are not ASCII, which Windows' WebSocket client cannot "
                                      "send as written (WinHTTP sends header values as 8-bit text)",
                                  "Percent-encode the value (encodeURIComponent) or base64 it, or send it in the "
                                  "first message after \"open\" instead.");
        return std::unique_ptr<WebSocket>(
            std::make_unique<WinHttpConnection>(std::make_shared<Core>(std::move(request), std::move(url.value()))));
    }
};

}  // namespace

std::unique_ptr<WebSocketClient> make_system_websocket_client() { return std::make_unique<WinHttpWebSocketClient>(); }

}  // namespace fa
