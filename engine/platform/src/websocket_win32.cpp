// Windows: WinHTTP's WebSocket API (fa/platform/websocket.h), with the system's certificate store and the user's proxy
// settings, like http_win32.cpp.
//
// Synchronous WinHTTP calls on two threads per connection, chosen over the asynchronous callbacks because every state change
// then happens in plain code under one mutex, and no WinHTTP callback can arrive after the connection is gone:
//   io        connects, does the handshake (WinHttpSendRequest, WinHttpReceiveResponse, WinHttpWebSocketCompleteUpgrade),
//             then sits in WinHttpWebSocketReceive and reports what arrives.
//   control   enforces the connect timeout (closing the request handle ends a pending synchronous call), then sends what the
//             game queued (WinHttpWebSocketSend) and the close frames (WinHttpWebSocketShutdown), waits at most
//             kWebSocketCloseWaitSec for the server's answer to a close, and at the end closes the WebSocket handle.
// WinHTTP allows one send and one receive in flight on a WebSocket handle at once, from different threads: the control thread
// is the only one that sends, the io thread the only one that receives.
//
// It follows the pattern of fa/platform/websocket.h: both threads hold a shared_ptr to the connection's state (Core), and so
// to its queue, and are detached. Destroying the connection abandons the queue and wakes the control thread, which sends a
// close frame 1001 and closes the WebSocket handle (closing the handle is how WinHTTP ends the pending receive of the io
// thread). When the control thread is itself inside a send that may block (a server that does not read), the destructor
// closes the handle instead, which ends both calls at once and sends no close frame. The game thread never waits for the
// network.
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
#include <deque>
#include <exception>
#include <memory>
#include <mutex>
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

// The connect timeout in milliseconds, clamped to what a DWORD timeout and an int take.
int timeout_ms(double seconds) { return static_cast<int>(std::min(std::max(seconds * 1000.0, 1.0), 2147483647.0)); }

// The session every connection shares (WinHTTP handles are thread safe); null when WinHTTP cannot start.
HINTERNET websocket_session() {
    static HINTERNET s = [] {
        const std::wstring agent = widen(std::string("FactorIA/") + FA_ENGINE_VERSION);
        HINTERNET opened = WinHttpOpen(agent.c_str(), WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY, WINHTTP_NO_PROXY_NAME,
                                       WINHTTP_NO_PROXY_BYPASS, 0);
        if (!opened)  // Windows before 8.1 has no automatic proxy: the default proxy settings
            opened = WinHttpOpen(agent.c_str(), WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, WINHTTP_NO_PROXY_NAME,
                                 WINHTTP_NO_PROXY_BYPASS, 0);
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
    return "timed out connecting to " + url.host + ":" + std::to_string(url.port) + " after " + seconds + " s";
}

// What a failed WinHTTP call while connecting means for the game.
Failure connect_failure(DWORD code, const ws::Url& url, double timeoutSec) {
    const std::string where = url.host + ":" + std::to_string(url.port);
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

// Everything the two threads and the game thread share. The threads keep it alive (a shared_ptr each), so it may outlive the
// WinHttpConnection the game holds. The fields below mutex_ are guarded by it. No WinHTTP call is made while it is held.
class Core : public std::enable_shared_from_this<Core> {
public:
    Core(WebSocketRequest request, ws::Url url) : options_(std::move(request)), url_(std::move(url)) {}

    void start() {
        try {
            std::thread([self = shared_from_this()] { self->control(); }).detach();
        } catch (const std::exception& e) {  // no thread to be had (std::system_error)
            std::lock_guard<std::mutex> lock(mutex_);
            fail_locked(std::string("could not start the connection (") + e.what() + ")",
                        "Close other connections or programs and try again.");
        }
    }

    // The game let go of the connection: nothing more is delivered, and no thread is waited for.
    void release() {
        HINTERNET closeNow = nullptr;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            queue_->abandon();
            stop_ = true;
            finished_ = true;
            // The control thread is in a send that may block: closing the handle ends it (and the pending receive).
            if (writerBusy_) closeNow = take(socket_);
            wake_.notify_all();
        }
        if (closeNow) WinHttpCloseHandle(closeNow);
    }

    WebSocketState state() const { return state_.load(); }

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
            // Closing at once. The control thread closes the request handle, which ends the pending WinHTTP call, and the
            // io thread ends the attempt with Error and Close 1006; then it is Closed.
            abort_ = true;
        } else {
            closeAsked_ = true;
            closeCode_ = code;
            closeReason_ = std::string(reason);
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

private:
    static HINTERNET take(HINTERNET& slot) {
        HINTERNET h = slot;
        slot = nullptr;
        return h;
    }

    // mutex_ held. The end of the connection: state() is Closed BEFORE the events are pushed. Only the first end reports.
    void finish_locked(std::vector<WebSocketEvent> events) {
        if (finished_) return;
        finished_ = true;
        state_ = WebSocketState::Closed;
        for (WebSocketEvent& e : events)
            if (!queue_->push(std::move(e))) break;
        wake_.notify_all();
    }

    // mutex_ held. Every failure ends with Error and then Close 1006, wasClean false.
    void fail_locked(std::string error, std::string hint, int httpStatus = 0) {
        std::vector<WebSocketEvent> events;
        events.push_back(WebSocketEvent::failure(std::move(error), std::move(hint), httpStatus));
        events.push_back(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
        finish_locked(std::move(events));
    }

    // mutex_ held. Open, Text, Binary. False when the connection is over, or the queue ended under it (it overflowed and
    // holds [Error, Close 1008]): the connection then stops, and the server is sent 1008.
    bool deliver_locked(WebSocketEvent event, HINTERNET& closeNow) {
        if (finished_) return false;
        if (queue_->push(std::move(event))) return true;
        finished_ = true;
        state_ = WebSocketState::Closed;
        ask_shutdown_locked(ws::close_code::kPolicyViolation, closeNow);
        return false;
    }

    // mutex_ held. The connection failed: the control thread sends this close frame and closes the handle. When it is in a
    // send that may block, the handle comes back in `closeNow`, to be closed at once once the mutex is released.
    void ask_shutdown_locked(int code, HINTERNET& closeNow) {
        if (writerBusy_)
            closeNow = take(socket_);
        else if (shutdownCode_ == 0)
            shutdownCode_ = code;
        wake_.notify_all();
    }

    // ------------------------------------------------------------------------------------------------ io thread ---
    void io() {
        HINTERNET connection = nullptr;
        std::string subprotocol;
        DWORD code = 0;  // the WinHTTP error that ended the attempt (0: see `failure`)
        Failure failure;
        int httpStatus = 0;
        const bool upgraded = handshake(connection, subprotocol, code, failure, httpStatus);
        HINTERNET request = nullptr, upgradedSocket = nullptr, closeNow = nullptr;
        bool open = false;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            request = take(requestHandle_);
            upgradedSocket = take(upgradedHandle_);
            connectDone_ = true;
            if (stop_) {
                // destroyed: nothing to report
            } else if (abort_) {
                fail_locked("the connection was closed before it was open",
                            "close() was called before the connection opened; wait for the 'open' event, or ignore "
                            "this error.");
            } else if (timedOut_) {
                fail_locked(timed_out_text(url_, options_.connectTimeoutSec),
                            "Check the connection, or raise the timeout option of websocket.connect.");
            } else if (!upgraded) {
                if (code != 0) failure = connect_failure(code, url_, options_.connectTimeoutSec);
                fail_locked(failure.error, failure.hint, httpStatus);
            } else {
                socket_ = take(upgradedSocket);
                connection_ = take(connection);
                opened_ = true;
                state_ = WebSocketState::Open;  // before the event: when the game reads Open, state() is Open
                open = deliver_locked(WebSocketEvent::open(subprotocol), closeNow);
            }
            wake_.notify_all();
        }
        if (closeNow) WinHttpCloseHandle(closeNow);
        if (request) WinHttpCloseHandle(request);  // after the upgrade the WebSocket handle lives on without it
        if (upgradedSocket) WinHttpCloseHandle(upgradedSocket);
        if (connection) WinHttpCloseHandle(connection);
        if (open) receive();
        std::lock_guard<std::mutex> lock(mutex_);
        readerDone_ = true;
        wake_.notify_all();
    }

    // Connects and upgrades. True with the WebSocket handle in upgradedHandle_; false with `code` (a WinHTTP error) or
    // `failure` set. The request handle is kept in requestHandle_, where the control thread may close it to end the attempt.
    bool handshake(HINTERNET& connection, std::string& subprotocol, DWORD& code, Failure& failure, int& httpStatus) {
        HINTERNET session = websocket_session();
        if (!session) {
            failure = {"WinHTTP could not start",
                       "Restart the game; if it keeps failing, Windows' networking is not working."};
            return false;
        }
        const std::wstring host = widen(url_.host);
        connection = WinHttpConnect(session, host.c_str(), static_cast<INTERNET_PORT>(url_.port), 0);
        if (!connection) {
            code = GetLastError();
            return false;
        }
        const std::wstring path = widen(url_.path.empty() ? std::string("/") : url_.path);
        HINTERNET request = WinHttpOpenRequest(connection, L"GET", path.c_str(), nullptr, WINHTTP_NO_REFERER,
                                               WINHTTP_DEFAULT_ACCEPT_TYPES, url_.secure ? WINHTTP_FLAG_SECURE : 0);
        if (!request) {
            code = GetLastError();
            return false;
        }
        {
            std::lock_guard<std::mutex> lock(mutex_);
            requestHandle_ = request;
            if (stop_ || abort_ || timedOut_) return false;  // io() reports it and closes the handle
        }
        const int timeoutMs = timeout_ms(options_.connectTimeoutSec);
        WinHttpSetTimeouts(request, timeoutMs, timeoutMs, timeoutMs, timeoutMs);
        DWORD headersTimeout = static_cast<DWORD>(timeoutMs);
        WinHttpSetOption(request, WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT, &headersTimeout, sizeof(headersTimeout));
        // A WebSocket handshake does not follow redirects: a 3xx is reported with its status, as the browser does.
        DWORD policy = WINHTTP_OPTION_REDIRECT_POLICY_NEVER;
        WinHttpSetOption(request, WINHTTP_OPTION_REDIRECT_POLICY, &policy, sizeof(policy));
        DWORD disable = WINHTTP_DISABLE_COOKIES | WINHTTP_DISABLE_AUTHENTICATION;  // only what the game put in headers
        WinHttpSetOption(request, WINHTTP_OPTION_DISABLE_FEATURE, &disable, sizeof(disable));
        if (!WinHttpSetOption(request, WINHTTP_OPTION_UPGRADE_TO_WEB_SOCKET, nullptr, 0)) {
            code = GetLastError();
            return false;
        }

        std::wstring headers;
        if (!options_.subprotocols.empty()) {
            std::string offered;
            for (const std::string& p : options_.subprotocols) offered += (offered.empty() ? "" : ", ") + p;
            headers += L"Sec-WebSocket-Protocol: " + widen(offered) + L"\r\n";
        }
        for (const auto& [name, value] : options_.headers) headers += widen(name) + L": " + widen(value) + L"\r\n";
        if (!WinHttpSendRequest(request, headers.empty() ? WINHTTP_NO_ADDITIONAL_HEADERS : headers.c_str(),
                                headers.empty() ? 0 : static_cast<DWORD>(-1), WINHTTP_NO_REQUEST_DATA, 0, 0, 0) ||
            !WinHttpReceiveResponse(request, nullptr)) {
            code = GetLastError();
            return false;
        }

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
        // as long as it lives (0 = no timeout). Set on the request, which the WebSocket handle is made from, and on the
        // WebSocket handle; a handle that does not take it keeps WinHTTP's own.
        WinHttpSetTimeouts(request, timeoutMs, timeoutMs, 0, 0);
        HINTERNET upgraded = WinHttpWebSocketCompleteUpgrade(request, 0);
        if (!upgraded) {
            code = GetLastError();
            if (code == 0) code = ERROR_WINHTTP_INVALID_SERVER_RESPONSE;
            return false;
        }
        WinHttpSetTimeouts(upgraded, 0, 0, 0, 0);
        std::lock_guard<std::mutex> lock(mutex_);
        upgradedHandle_ = upgraded;
        return true;
    }

    // The io thread, once Open: one WinHttpWebSocketReceive after the other until the connection ends.
    void receive() {
        std::vector<char> chunk(64 * 1024);
        std::string message;
        bool messageIsText = false, inMessage = false;
        for (;;) {
            HINTERNET socket = nullptr;
            {
                std::lock_guard<std::mutex> lock(mutex_);
                if (finished_ || !socket_) return;
                socket = socket_;
            }
            DWORD got = 0;
            WINHTTP_WEB_SOCKET_BUFFER_TYPE type = WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE;
            const DWORD rc =
                WinHttpWebSocketReceive(socket, chunk.data(), static_cast<DWORD>(chunk.size()), &got, &type);
            HINTERNET closeNow = nullptr;
            std::unique_lock<std::mutex> lock(mutex_);
            if (finished_) return;
            if (rc != NO_ERROR) {
                if (rc == static_cast<DWORD>(ERROR_WINHTTP_INVALID_SERVER_RESPONSE))
                    fail_locked("the server sent data that breaks the WebSocket protocol (Windows error " +
                                    std::to_string(rc) + ")",
                                "Check the server: it does not follow RFC 6455.");
                else
                    fail_locked("the connection to " + url_.host + " was lost (Windows error " + std::to_string(rc) +
                                    ")",
                                "Check the connection; try again.");
                return;
            }
            if (type == WINHTTP_WEB_SOCKET_CLOSE_BUFFER_TYPE) {
                lock.unlock();
                USHORT status = 0;
                char reason[128] = {};
                DWORD reasonBytes = 0;
                const DWORD qrc =
                    WinHttpWebSocketQueryCloseStatus(socket, &status, reason, sizeof(reason), &reasonBytes);
                lock.lock();
                if (finished_) return;
                int peerCode = ws::close_code::kNoStatus;
                std::string peerReason;
                if (qrc == NO_ERROR) {
                    peerCode = status;
                    peerReason.assign(reason, std::min<std::size_t>(reasonBytes, sizeof(reason)));
                    if (!is_valid_utf8(peerReason)) peerReason.clear();
                }
                // The control thread answers with the same code (unless our close went out first) and closes the handle.
                peerClosed_ = true;
                peerCode_ = peerCode;
                std::vector<WebSocketEvent> events;
                events.push_back(WebSocketEvent::close(peerCode, std::move(peerReason), true));
                finish_locked(std::move(events));
                return;
            }
            const bool text = type == WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE ||
                              type == WINHTTP_WEB_SOCKET_UTF8_FRAGMENT_BUFFER_TYPE;
            const bool last = type == WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE ||
                              type == WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE;
            if (!inMessage) {
                inMessage = true;
                messageIsText = text;
            }
            // Checked as the fragments arrive, before they are kept (message.size() never exceeds the limit).
            if (got > options_.maxMessageBytes - message.size()) {
                fail_locked("a message from the server is longer than " + std::to_string(options_.maxMessageBytes) +
                                " bytes (the maxMessageBytes option)",
                            "Raise the maxMessageBytes option of websocket.connect, or ask the server to send smaller "
                            "messages.");
                ask_shutdown_locked(ws::close_code::kMessageTooBig, closeNow);
                lock.unlock();
                if (closeNow) WinHttpCloseHandle(closeNow);
                return;
            }
            message.append(chunk.data(), got);
            if (!last) continue;
            bool delivered = false;
            if (messageIsText && !is_valid_utf8(message)) {
                fail_locked("the server sent a text message that is not valid UTF-8",
                            "Check the server: binary data goes in binary messages.");
                ask_shutdown_locked(ws::close_code::kInvalidData, closeNow);
            } else {
                delivered = deliver_locked(messageIsText ? WebSocketEvent::text(std::move(message))
                                                         : WebSocketEvent::binary(std::move(message)),
                                           closeNow);
            }
            lock.unlock();
            if (closeNow) WinHttpCloseHandle(closeNow);
            if (!delivered) return;
            message.clear();
            inMessage = false;
        }
    }

    // ------------------------------------------------------------------------------------------- control thread ---
    void control() {
        try {
            std::thread([self = shared_from_this()] { self->io(); }).detach();
        } catch (const std::exception& e) {
            std::lock_guard<std::mutex> lock(mutex_);
            fail_locked(std::string("could not start the connection (") + e.what() + ")",
                        "Close other connections or programs and try again.");
            return;
        }
        std::unique_lock<std::mutex> lock(mutex_);
        // Connecting: wait for the io thread, and end its attempt (close the request handle) on the timeout, a close() or
        // the destruction. The io thread reports how it ended.
        const auto deadline = Clock::now() + std::chrono::milliseconds(timeout_ms(options_.connectTimeoutSec));
        while (!opened_ && !connectDone_ && !stop_ && !abort_) {
            if (Clock::now() >= deadline) {
                timedOut_ = true;
                break;
            }
            wake_.wait_until(lock, deadline);
        }
        if (!opened_) {
            HINTERNET request = take(requestHandle_);
            lock.unlock();
            if (request) WinHttpCloseHandle(request);
            return;
        }
        serve(lock);
        HINTERNET socket = take(socket_);
        HINTERNET connection = take(connection_);
        lock.unlock();
        if (socket) WinHttpCloseHandle(socket);  // also ends the io thread's pending receive
        if (connection) WinHttpCloseHandle(connection);
    }

    // mutex_ held (through `lock`) except around each WinHTTP call. Returns when there is nothing more to send.
    void serve(std::unique_lock<std::mutex>& lock) {
        Clock::time_point closeDeadline{};
        for (;;) {
            if (stop_) {  // destroyed: the goodbye (1001), unless a close frame went out already or the server closed
                if (!closeSent_ && !peerClosed_) shutdown(lock, ws::close_code::kGoingAway, {});
                return;
            }
            if (shutdownCode_ != 0) {  // a failure (1007, 1008, 1009): its close frame, then the end
                if (!closeSent_ && !peerClosed_) shutdown(lock, shutdownCode_, {});
                return;
            }
            if (peerClosed_) {  // the server closed: answer with its code, then the end
                if (!closeSent_) shutdown(lock, ws::close_code_valid_on_wire(peerCode_) ? peerCode_ : 0, {});
                return;
            }
            if (readerDone_) return;  // the connection was lost; the io thread reported it
            if (!outgoing_.empty() && !closeSent_) {
                Outgoing message = std::move(outgoing_.front());
                outgoing_.pop_front();
                HINTERNET socket = socket_;
                writerBusy_ = true;
                lock.unlock();
                const WINHTTP_WEB_SOCKET_BUFFER_TYPE type = message.binary
                                                                ? WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE
                                                                : WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE;
                const DWORD rc = socket ? WinHttpWebSocketSend(socket, type, message.data.data(),
                                                               static_cast<DWORD>(message.data.size()))
                                        : static_cast<DWORD>(ERROR_INVALID_HANDLE);
                lock.lock();
                writerBusy_ = false;
                buffered_ -= std::min(buffered_, message.data.size());
                if (rc != NO_ERROR) {
                    fail_locked("the connection to " + url_.host + " was lost while sending (Windows error " +
                                    std::to_string(rc) + ")",
                                "Check the connection; try again.");
                    return;
                }
                continue;
            }
            if (closeAsked_ && !closeSent_) {
                if (!shutdown(lock, closeCode_, closeReason_)) {
                    fail_locked("the connection to " + url_.host + " was lost while closing", "Check the connection.");
                    return;
                }
                closeDeadline = Clock::now() + kCloseWait;
                continue;
            }
            if (closeSent_) {  // waiting for the server's answer to our close frame
                if (Clock::now() >= closeDeadline) {
                    fail_locked("the server did not answer the close within " +
                                    std::to_string(static_cast<int>(kWebSocketCloseWaitSec)) + " s",
                                "The connection was dropped instead; the server may be busy or gone.");
                    return;
                }
                wake_.wait_until(lock, closeDeadline);
                continue;
            }
            wake_.wait(lock);
        }
    }

    // mutex_ held (through `lock`) except during the call. Sends a close frame (code 0: one with no code and no reason);
    // true when it went out.
    bool shutdown(std::unique_lock<std::mutex>& lock, int code, const std::string& reason) {
        closeSent_ = true;
        HINTERNET socket = socket_;
        if (!socket) return false;
        writerBusy_ = true;
        std::string why = code == 0 ? std::string() : reason;
        const USHORT status = code == 0 ? kEmptyCloseStatus : static_cast<USHORT>(code);
        lock.unlock();
        const DWORD rc = WinHttpWebSocketShutdown(socket, status, why.empty() ? nullptr : why.data(),
                                                  static_cast<DWORD>(why.size()));
        lock.lock();
        writerBusy_ = false;
        return rc == NO_ERROR;
    }

    const WebSocketRequest options_;
    const ws::Url url_;
    std::shared_ptr<WebSocketEventQueue> queue_ =
        std::make_shared<WebSocketEventQueue>(WebSocketEventQueue::limit_for(options_.maxMessageBytes));
    std::atomic<WebSocketState> state_{WebSocketState::Connecting};  // written under mutex_, read without it

    mutable std::mutex mutex_;
    std::condition_variable wake_;        // the control thread waits on it
    HINTERNET requestHandle_ = nullptr;   // while connecting
    HINTERNET upgradedHandle_ = nullptr;  // between the upgrade and the Open
    HINTERNET socket_ = nullptr;          // the WebSocket handle once Open; null once closed
    HINTERNET connection_ = nullptr;      // the parent of socket_, closed after it
    bool stop_ = false;                   // the game destroyed the connection
    bool abort_ = false;                  // close() while connecting
    bool timedOut_ = false;               // the connect timeout passed
    bool connectDone_ = false;            // the io thread finished connecting (open or not)
    bool opened_ = false;
    bool finished_ =
        false;  // the Close event was pushed, or the queue ended or was abandoned: nothing more is delivered
    bool readerDone_ = false;
    bool writerBusy_ = false;  // the control thread is inside WinHttpWebSocketSend or WinHttpWebSocketShutdown
    bool closeAsked_ = false, closeSent_ = false, peerClosed_ = false;
    int closeCode_ = 0, peerCode_ = 0, shutdownCode_ = 0;
    std::string closeReason_;
    std::deque<Outgoing> outgoing_;
    std::size_t buffered_ = 0;
};

// What the game holds: forwards to the Core and lets go of it on destruction without waiting for a thread.
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
        return std::unique_ptr<WebSocket>(
            std::make_unique<WinHttpConnection>(std::make_shared<Core>(std::move(request), std::move(url.value()))));
    }
};

}  // namespace

std::unique_ptr<WebSocketClient> make_system_websocket_client() { return std::make_unique<WinHttpWebSocketClient>(); }

}  // namespace fa
