// Linux's WebSocket client (fa/platform/websocket.h, make_curl_websocket_client): libcurl, loaded with dlopen
// (curl_library.h, shared with http_curl.cpp), is the transport, and fa/platform/websocket_codec.h speaks the protocol.
// libcurl resolves the name, opens the TCP connection (through the proxy of the environment, tunnelled with CONNECT as browsers
// do for WebSockets) and does TLS with the system's certificates: CURLOPT_CONNECT_ONLY = 1 on the http:// or https:// address
// of the server, HTTP/1.1 in ALPN. The handshake and the frames then go through curl_easy_send and curl_easy_recv.
//
// Why not libcurl's own WebSocket API (CURLOPT_CONNECT_ONLY = 2, curl_ws_recv): it is a build option that distributions
// turned on late (on by default from 8.11), and the libcurl of Ubuntu 24.04 (8.5) does not report whether a frame is the last
// of a fragmented message (continuations carry CURLWS_CONT whatever their FIN bit), does not answer the server's close frame
// and ignores the reserved bits. The codec does all of that the same way as Android's client and the tcp client, and needs
// nothing newer than libcurl 7.45 (CURLINFO_ACTIVESOCKET).
//
// Threads follow the pattern of fa/platform/websocket.h, as in websocket_tcp_posix.cpp: one detached thread per connection
// owns the easy handle and a shared_ptr to the connection's state (Core); the game thread only queues bytes and wakes it
// through a pipe. Destroying the connection abandons the queue, tells the thread to stop and returns. A connection attempt
// ends the next time libcurl calls the progress callback; a step of libcurl that does not call it is bounded by the
// connect timeout. A connected thread stops within one poll() round.
#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)

#include <fcntl.h>
#include <poll.h>
#include <unistd.h>

#include <algorithm>
#include <atomic>
#include <cerrno>
#include <chrono>
#include <cstdint>
#include <exception>
#include <memory>
#include <mutex>
#include <random>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#include "curl_library.h"
#include "fa/core/strings.h"
#include "fa/platform/websocket.h"
#include "fa/platform/websocket_codec.h"

namespace fa {

namespace {

namespace lc = fa::libcurl;
using Clock = std::chrono::steady_clock;

// The most the game may have queued and not yet sent: send_* fails above it (the script reads bufferedAmount).
constexpr std::size_t kMaxBuffered = 16u * 1024 * 1024;
// How long a closing handshake waits for the peer's close frame before the connection is dropped (the shared constant).
constexpr auto kCloseWait =
    std::chrono::duration_cast<Clock::duration>(std::chrono::duration<double>(kWebSocketCloseWaitSec));
// One curl_easy_send call at most: a TLS write that has to be retried is retried with the same bytes or more, never fewer.
constexpr std::size_t kSendChunk = 64u * 1024;
// What the thread reads before it sends and looks at the state again.
constexpr std::size_t kReadPerTurn = 1024u * 1024;
// The capacity inflight_ keeps between two messages: after a message above this (up to 16 MB queued) its memory is given back.
constexpr std::size_t kKeepCapacity = 1024u * 1024;

std::string compute_unavailable_reason() {
    const lc::Library& c = lc::library();
    if (!c.ok()) return c.reason + " (install libcurl, e.g. `sudo apt install libcurl4`)";
    const lc::VersionInfo* v = c.version_info ? c.version_info(0) : nullptr;
    if (!c.easy_send || !c.easy_recv || !v || v->version_num < lc::kVersionNum7_45) {
        const std::string version = lc::version_text(c);
        return "the libcurl on this computer" + (version.empty() ? std::string() : " (" + version + ")") +
               " is older than 7.45, the first one WebSocket connections can use (install a newer libcurl, e.g. "
               "`sudo apt install libcurl4`)";
    }
    return {};
}

// "" when this machine can open WebSockets through libcurl.
const std::string& curl_unavailable_reason() {
    static const std::string reason = compute_unavailable_reason();
    return reason;
}

bool curl_has_tls() {
    const lc::Library& c = lc::library();
    const lc::VersionInfo* v = c.version_info ? c.version_info(0) : nullptr;
    return v && (v->features & lc::kFeatureSsl) != 0;
}

// libcurl calls it while it resolves, connects and does TLS; non-zero ends curl_easy_perform (CURLE_ABORTED_BY_CALLBACK).
extern "C" int fa_ws_curl_progress(void* user, lc::curl_off_t, lc::curl_off_t, lc::curl_off_t, lc::curl_off_t);

// Everything one connection's thread and the game thread share. The thread keeps it alive (a shared_ptr it captured), so it
// may outlive the CurlWebSocket handle that the game holds.
class Core : public std::enable_shared_from_this<Core> {
public:
    Core(WebSocketRequest request, ws::Url url)
        : request_(std::move(request)), url_(std::move(url)), session_(make_options(request_.maxMessageBytes)) {
#if defined(__linux__)
        if (::pipe2(wake_, O_CLOEXEC | O_NONBLOCK) != 0) wake_[0] = wake_[1] = -1;
#else
        if (::pipe(wake_) != 0) wake_[0] = wake_[1] = -1;
        for (int fd : wake_)
            if (fd >= 0) {
                ::fcntl(fd, F_SETFL, ::fcntl(fd, F_GETFL, 0) | O_NONBLOCK);
                ::fcntl(fd, F_SETFD, ::fcntl(fd, F_GETFD, 0) | FD_CLOEXEC);
            }
#endif
    }

    ~Core() {
        for (int fd : wake_)
            if (fd >= 0) ::close(fd);
    }

    Core(const Core&) = delete;
    Core& operator=(const Core&) = delete;

    void start() {
        try {
            std::thread([self = shared_from_this()] { self->run(); }).detach();
        } catch (const std::exception& e) {  // no thread to be had (std::system_error)
            fail_connect(std::string("could not start the connection (") + e.what() + ")",
                         "Close other connections or programs and try again.");
        }
    }

    // The game let go of the connection: nothing it reports is delivered, and the thread ends without being waited for.
    void release() {
        queue_->abandon();
        stop_ = true;
        wake();
    }

    // Asked by the progress callback while libcurl connects.
    bool connect_cancelled() const { return stop_.load() || abort_.load(); }

    // Closed as soon as the queue holds its last event (a queue that overflowed holds [Error, Close 1008] before the thread
    // has turned state_ into Closed): when the game reads the Close event, state() is Closed.
    WebSocketState state() const { return queue_->ended() ? WebSocketState::Closed : state_.load(); }

    Result<void> send_text(std::string_view text) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (auto r = can_send(); !r.ok()) return r;
        if (!is_valid_utf8(text)) return make_error("the text is not valid UTF-8", "Send other data with send_binary.");
        auto r = session_.send_text(text);
        if (r.ok()) wake();
        return r;
    }

    Result<void> send_binary(const void* data, std::size_t size) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (auto r = can_send(); !r.ok()) return r;
        auto r = session_.send_binary(data, size);
        if (r.ok()) wake();
        return r;
    }

    Result<void> close(int code, std::string_view reason) {
        if (auto r = ws::check_close_request(code, reason); !r.ok()) return r;
        std::lock_guard<std::mutex> lock(mutex_);
        const WebSocketState s = state();
        if (s == WebSocketState::Closing || s == WebSocketState::Closed) return {};
        if (s == WebSocketState::Connecting) {
            // Closing at once; the thread ends the attempt with Error and Close 1006, and then it is Closed.
            abort_ = true;
            WebSocketState expected = WebSocketState::Connecting;
            state_.compare_exchange_strong(expected, WebSocketState::Closing);
        } else if (session_.close(code, reason).ok()) {
            // The thread may have ended the connection meanwhile: only Open becomes Closing.
            WebSocketState expected = WebSocketState::Open;
            if (state_.compare_exchange_strong(expected, WebSocketState::Closing)) closeAsked_ = Clock::now();
        }
        wake();
        return {};
    }

    std::size_t buffered_amount() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return pending_bytes();
    }

    std::size_t poll(std::vector<WebSocketEvent>& out) { return queue_->drain(out); }

private:
    static ws::SessionOptions make_options(std::size_t max) {
        ws::SessionOptions o;
        o.role = ws::Role::Client;
        o.maxMessageBytes = max;
        return o;
    }

    // mutex_ held
    std::size_t pending_bytes() const {
        return inflight_.size() - sent_ + outgoing_.size() + session_.pending_output_bytes();
    }

    Result<void> can_send() const {
        const WebSocketState s = state();
        if (s == WebSocketState::Connecting)
            return make_error("the connection is not open yet", "Wait for the \"open\" event before sending.");
        if (s != WebSocketState::Open)
            return make_error("the connection is closing or closed", "Connect again to send.");
        if (pending_bytes() > kMaxBuffered)
            return make_error("more than " + std::to_string(kMaxBuffered / (1024 * 1024)) + " MB wait to be sent",
                              "Send less, or wait until bufferedAmount drops.");
        return {};
    }

    void wake() {
        if (wake_[1] >= 0) {
            const char b = 1;
            [[maybe_unused]] const auto n = ::write(wake_[1], &b, 1);
        }
    }

    void drain_wake() {
        char buf[64];
        while (wake_[0] >= 0 && ::read(wake_[0], buf, sizeof(buf)) > 0) {
        }
    }

    // Waits until `fd` is ready for `events` (1), the deadline passes (0), the connection must stop (-1), or poll() fails
    // (-2: the connection is broken).
    int wait_for(int fd, short events, Clock::time_point deadline) {
        for (;;) {
            if (stop_ || abort_ || dead_) return -1;
            const auto left = std::chrono::duration_cast<std::chrono::milliseconds>(deadline - Clock::now()).count();
            if (left <= 0) return 0;
            pollfd fds[2] = {{fd, events, 0}, {wake_[0], POLLIN, 0}};
            const int n = ::poll(fds, 2, static_cast<int>(std::min<long long>(left, 1000)));
            if (n < 0 && errno != EINTR) return -2;
            if (n > 0 && (fds[1].revents & POLLIN)) drain_wake();
            if (n > 0 && (fds[0].revents & (events | POLLERR | POLLHUP | POLLNVAL))) return 1;
        }
    }

    // Pushes an event; false (the queue overflowed or the game let go) ends the thread's work: it closes the transport.
    bool emit(WebSocketEvent event) {
        if (queue_->push(std::move(event))) return true;
        dead_ = true;
        return false;
    }

    void fail_connect(const std::string& error, const std::string& hint, int status = 0) {
        state_ = WebSocketState::Closed;  // before the events: when the game reads Close, state() is Closed
        emit(WebSocketEvent::failure(error, hint, status));
        emit(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
    }

    // What a failed curl_easy_perform means to a player.
    void fail_transport(lc::CURLcode code, const std::string& detail) {
        const std::string& host = url_.host;
        switch (code) {
            case lc::kCurlTimedOut:
                fail_connect("timed out connecting to " + host, "Check the connection, and that the server is up.");
                return;
            case lc::kCurlCouldntResolveHost:
                fail_connect("could not find the server " + host, "Check the address, and that the player is online.");
                return;
            case lc::kCurlCouldntResolveProxy:
                fail_connect("could not find the proxy server: " + detail,
                             "Check the proxy settings of this computer (https_proxy, http_proxy, all_proxy).");
                return;
            case lc::kCurlCouldntConnect:
                fail_connect("could not connect to " + host + ":" + std::to_string(url_.port) + " (" + detail + ")",
                             "Check that the server is running and that the address and port are right.");
                return;
            case lc::kCurlSslConnectError:
            case lc::kCurlSslPeerCertificate:
            case lc::kCurlSslCertProblem:
            case lc::kCurlSslCipher:
            case lc::kCurlPeerFailedVerification:
            case lc::kCurlSslCacertBadfile:
            case lc::kCurlSslIssuerError:
                fail_connect(
                    "the secure connection to " + host + " failed: " + detail,
                    "The server's certificate is not trusted by this computer (an expired certificate, a wrong "
                    "clock, a proxy that rewrites traffic), or the server does not speak TLS on this port (a "
                    "server without TLS needs ws://).");
                return;
            default: break;
        }
        fail_connect("could not connect to " + host + ": " + detail,
                     "Check the connection, and that the server is up.");
    }

    // Opens the connection through libcurl (name, proxy tunnel, TCP, TLS). Returns the handle and sets `fd` to its socket,
    // or returns null: after reporting the failure, or without a word when the game closed or dropped the connection.
    lc::CURL* open_transport(Clock::time_point deadline, int& fd) {
        const lc::Library& c = lc::library();
        lc::CURL* h = c.easy_init();
        if (!h) {
            fail_connect("libcurl could not start a connection", "Try again; if it keeps failing, restart the game.");
            return nullptr;
        }
        const std::string address = std::string(url_.secure ? "https://" : "http://") + url_.host_header() + "/";
        const auto leftMs = std::chrono::duration_cast<std::chrono::milliseconds>(deadline - Clock::now()).count();
        c.easy_setopt(h, lc::kOptUrl, address.c_str());
        c.easy_setopt(h, lc::kOptErrorBuffer, errbuf_);
        c.easy_setopt(h, lc::kOptNoSignal, 1L);  // never SIGALRM from a worker thread
        c.easy_setopt(h, lc::kOptConnectOnly, 1L);
        c.easy_setopt(h, lc::kOptConnectTimeoutMs, static_cast<long>(std::max<long long>(1, leftMs)));
        // TLS offers http/1.1 only (ALPN): the upgrade is an HTTP/1.1 request.
        c.easy_setopt(h, lc::kOptHttpVersion, lc::kHttpVersion1_1);
        c.easy_setopt(h, lc::kOptHttpProxyTunnel,
                      1L);  // through a proxy, ws:// is tunnelled too (CONNECT), like wss://
        if (c.easy_setopt(h, lc::kOptProtocolsStr, "http,https") == lc::kCurlUnknownOption)
            c.easy_setopt(h, lc::kOptProtocols, lc::kProtoHttp | lc::kProtoHttps);
        c.easy_setopt(h, lc::kOptNoProgress, 0L);
        c.easy_setopt(h, lc::kOptXferInfoFunction, &fa_ws_curl_progress);
        c.easy_setopt(h, lc::kOptXferInfoData, static_cast<void*>(this));
        const lc::CURLcode code = c.easy_perform(h);
        if (code != lc::kCurlOk) {
            const std::string detail = errbuf_[0] ? std::string(errbuf_) : std::string(c.easy_strerror(code));
            c.easy_cleanup(h);
            if (!connect_cancelled()) fail_transport(code, detail);
            return nullptr;
        }
        int sock = -1;  // curl_socket_t
        if (c.easy_getinfo(h, lc::kInfoActiveSocket, &sock) != lc::kCurlOk || sock < 0) {
            c.easy_cleanup(h);
            fail_connect("libcurl did not hand over the connection to " + url_.host, "Try again.");
            return nullptr;
        }
        fd = sock;
        return h;
    }

    // One curl_easy_recv: 1 bytes arrived (`got`), 0 nothing for now, -1 the connection ended (closed or broken).
    static int receive(lc::CURL* h, char* buf, std::size_t size, std::size_t& got) {
        got = 0;
        const lc::CURLcode rc = lc::library().easy_recv(h, buf, size, &got);
        if (rc == lc::kCurlAgain) return 0;
        if (rc != lc::kCurlOk || got == 0) return -1;
        return 1;
    }

    // Writes as much of the output as the connection takes; false when it is broken.
    // The bytes in flight never move: after CURLE_AGAIN the TLS library retries the record it could not finish and wants
    // the same buffer again (OpenSSL fails a moved one with SSL_R_BAD_WRITE_RETRY unless the TLS backend set
    // SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER), so inflight_ is never appended to until all of it is sent; new output waits in
    // outgoing_ and the two swap. A retry thus passes the same pointer and the same length.
    bool flush(lc::CURL* h) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (session_.has_output()) outgoing_ += session_.take_output();
        for (;;) {
            if (sent_ == inflight_.size()) {
                inflight_.clear();
                sent_ = 0;
                if (inflight_.capacity() > kKeepCapacity)
                    std::string().swap(inflight_);  // outgoing_ takes its turn below
                if (outgoing_.empty()) return true;
                inflight_.swap(outgoing_);
            }
            std::size_t n = 0;
            const lc::CURLcode rc = lc::library().easy_send(h, inflight_.data() + sent_,
                                                            std::min(kSendChunk, inflight_.size() - sent_), &n);
            sent_ += n;
            if (rc == lc::kCurlAgain || (rc == lc::kCurlOk && n == 0)) return true;
            if (rc != lc::kCurlOk) return false;
        }
    }

    bool send_all_blocking(lc::CURL* h, int fd, const std::string& bytes, Clock::time_point deadline) {
        std::size_t at = 0;
        while (at < bytes.size()) {
            std::size_t n = 0;
            const lc::CURLcode rc =
                lc::library().easy_send(h, bytes.data() + at, std::min(kSendChunk, bytes.size() - at), &n);
            at += n;
            if (rc == lc::kCurlOk && n > 0) continue;
            if (rc != lc::kCurlOk && rc != lc::kCurlAgain) return false;
            if (wait_for(fd, POLLOUT, deadline) != 1) return false;
        }
        return true;
    }

    // Sends the upgrade request and reads the head of the server's answer; returns false (after reporting) when it fails.
    bool handshake(lc::CURL* h, int fd, Clock::time_point deadline, std::string& leftover) {
        std::uint8_t random[16];
        try {
            std::random_device rd;
            for (std::uint8_t& b : random) b = static_cast<std::uint8_t>(rd());
        } catch (const std::exception& e) {  // no entropy source
            fail_connect(std::string("could not make the handshake key (") + e.what() + ")", "Try again.");
            return false;
        }
        const std::string key = ws::make_client_key(random);
        auto req = ws::build_client_request(url_, key, request_.subprotocols, request_.headers);
        if (!req.ok()) {
            fail_connect(req.error().message, req.error().hint);
            return false;
        }
        if (!send_all_blocking(h, fd, req.value(), deadline)) {
            if (!stop_ && !abort_ && !dead_) {
                if (Clock::now() >= deadline)
                    fail_connect("timed out sending the handshake to " + url_.host, "Check the connection.");
                else
                    fail_connect("the connection broke while sending the handshake", "Check the connection.");
            }
            return false;
        }
        std::string data;
        std::size_t end = std::string::npos;
        char buf[4096];
        while (end == std::string::npos) {
            // Read first: TLS may already hold bytes that poll() does not see.
            std::size_t got = 0;
            const int r = receive(h, buf, sizeof(buf), got);
            if (r < 0) {
                fail_connect("the server closed the connection during the handshake",
                             "Check the address and the port; the server may need wss://.");
                return false;
            }
            if (r > 0) {
                data.append(buf, got);
                end = ws::find_head_end(data);
                if (end == std::string::npos && data.size() > 64 * 1024) {
                    fail_connect("the server's answer to the handshake is longer than 64 KB",
                                 "The address is not a WebSocket server.");
                    return false;
                }
                continue;
            }
            const int ready = wait_for(fd, POLLIN, deadline);
            if (ready == -1) return false;
            if (ready == -2) {
                fail_connect("the connection broke while waiting for the server's answer to the handshake",
                             "Check the connection; try again.");
                return false;
            }
            if (ready == 0) {
                fail_connect("timed out waiting for the server's answer to the handshake",
                             "Check that the address is a WebSocket server and not a web page.");
                return false;
            }
        }
        const ws::HandshakeResult result =
            ws::check_server_response(std::string_view(data).substr(0, end), key, request_.subprotocols);
        if (!result.ok) {
            fail_connect(result.error, result.hint, result.status == 101 ? 0 : result.status);
            return false;
        }
        leftover = data.substr(end);
        subprotocol_ = result.subprotocol;
        return true;
    }

    void run() {
        const auto deadline =
            Clock::now() + std::chrono::milliseconds(static_cast<long long>(request_.connectTimeoutSec * 1000));
        int fd = -1;
        lc::CURL* h = open_transport(deadline, fd);
        if (!h) {
            finish_aborted();
            return;
        }
        std::string leftover;
        if (!handshake(h, fd, deadline, leftover)) {
            lc::library().easy_cleanup(h);
            finish_aborted();
            return;
        }
        bool aborted;
        {
            // close() and this transition are both under the mutex, so a close that came first is not lost.
            std::lock_guard<std::mutex> lock(mutex_);
            aborted = abort_ || stop_ || dead_;
            if (!aborted) state_ = WebSocketState::Open;
        }
        if (aborted) {
            lc::library().easy_cleanup(h);
            finish_aborted();
            return;
        }
        if (emit(WebSocketEvent::open(subprotocol_))) serve(h, fd, leftover);
        state_ = WebSocketState::Closed;
        lc::library().easy_cleanup(h);
    }

    // The game closed the connection while it was connecting: the attempt ends with Error and Close 1006. A destroyed
    // connection (stop_) or an ended queue (dead_) says nothing.
    void finish_aborted() {
        if (state_.load() != WebSocketState::Closed && !stop_ && !dead_)
            fail_connect(
                "the connection was closed before it was open",
                "close() was called before the connection opened; wait for the 'open' event, or ignore this error.");
        state_ = WebSocketState::Closed;
    }

    void handle(std::vector<ws::Event>& events, int& closeCode, std::string& closeReason, bool& peerClosed,
                bool& failed) {
        for (ws::Event& e : events) {
            switch (e.type) {
                case ws::Event::Type::Text:
                    if (!emit(WebSocketEvent::text(std::move(e.data)))) return;
                    break;
                case ws::Event::Type::Binary:
                    if (!emit(WebSocketEvent::binary(std::move(e.data)))) return;
                    break;
                case ws::Event::Type::Ping:  // the codec queued the pong
                case ws::Event::Type::Pong: break;
                case ws::Event::Type::Close:
                    peerClosed = true;
                    closeCode = e.code;
                    closeReason = std::move(e.reason);
                    {
                        std::lock_guard<std::mutex> lock(mutex_);
                        WebSocketState expected = WebSocketState::Open;
                        state_.compare_exchange_strong(expected, WebSocketState::Closing);
                    }
                    break;
                case ws::Event::Type::Failure:
                    failed = true;
                    closeCode = e.code;
                    if (!emit(WebSocketEvent::failure(e.error, e.hint))) return;
                    break;
            }
        }
        events.clear();
    }

    void serve(lc::CURL* h, int fd, const std::string& leftover) {
        std::vector<ws::Event> events;
        int closeCode = ws::close_code::kAbnormal;
        std::string closeReason;
        bool peerClosed = false, failed = false, lost = false, failedSeen = false;
        Clock::time_point failedAt;
        if (!leftover.empty()) {
            std::lock_guard<std::mutex> lock(mutex_);
            session_.feed(leftover.data(), leftover.size(), events);
        }
        handle(events, closeCode, closeReason, peerClosed, failed);
        std::vector<char> buf(64 * 1024);
        while (!stop_ && !dead_) {
            bool done, needWrite, waitingForPeer = false;
            Clock::time_point asked;
            if (!flush(h)) {  // also moves what the session queued (pongs, close answers) to the output
                lost = true;
                break;
            }
            {
                std::lock_guard<std::mutex> lock(mutex_);
                done = session_.done();
                needWrite = sent_ < inflight_.size() || !outgoing_.empty();
                waitingForPeer = state_.load() == WebSocketState::Closing && !peerClosed;
                asked = closeAsked_;
            }
            if (done && !needWrite) break;
            if (failed && !failedSeen) {
                failedSeen = true;
                failedAt = Clock::now();
            }
            // The server does not answer our close frame, or (after a failure) does not read the one we sent: give up.
            if ((waitingForPeer && Clock::now() - asked > kCloseWait) ||
                (failedSeen && Clock::now() - failedAt > kCloseWait)) {
                lost = true;
                break;
            }
            // Read what libcurl has before waiting: TLS may hold decrypted bytes that poll() does not see, so read until it
            // says "again" (or kReadPerTurn, to send and look at the state in between). After the peer's close or a failure
            // the codec ignores the input, so nothing more is read.
            std::size_t readThisTurn = 0;
            while (!peerClosed && !failed && !stop_ && !dead_ && readThisTurn < kReadPerTurn) {
                std::size_t got = 0;
                const int r = receive(h, buf.data(), buf.size(), got);
                if (r < 0) {
                    lost = true;
                    break;
                }
                if (r == 0) break;
                {
                    std::lock_guard<std::mutex> lock(mutex_);
                    session_.feed(buf.data(), got, events);
                }
                handle(events, closeCode, closeReason, peerClosed, failed);
                readThisTurn += got;
            }
            if (lost) break;
            if (readThisTurn > 0) continue;  // send the answers (pongs, a close) and look at the state before waiting
            // Once reading has stopped, POLLIN is left out: a socket that stays readable would end every poll() at once (a
            // busy loop until kCloseWait). A hang-up or an error is reported anyway, and then the line is gone.
            const bool reading = !peerClosed && !failed;
            // `want` is never 0: not reading means the peer's close or a failure, and then session_.done() is true (the codec
            // has answered the close, or failed_ is set), so with nothing left to write the loop ended above (done &&
            // !needWrite); what is left to write sets POLLOUT.
            const short want = static_cast<short>((reading ? POLLIN : 0) | (needWrite ? POLLOUT : 0));
            pollfd fds[2] = {{fd, want, 0}, {wake_[0], POLLIN, 0}};
            const int n = ::poll(fds, 2, 500);
            if (n < 0 && errno != EINTR) {
                lost = true;
                break;
            }
            if (n > 0 && (fds[1].revents & POLLIN)) drain_wake();
            if (n > 0 && !reading && (fds[0].revents & (POLLERR | POLLHUP | POLLNVAL))) {
                lost = true;
                break;
            }
        }
        if (stop_ ||
            dead_) {  // destroyed, or the queue ended: say goodbye if that takes no waiting, report nothing more
            {
                std::lock_guard<std::mutex> lock(mutex_);
                if (state_.load() == WebSocketState::Open)
                    static_cast<void>(
                        session_.close(stop_ ? ws::close_code::kGoingAway : ws::close_code::kPolicyViolation, {}));
            }
            flush(h);
            state_ = WebSocketState::Closed;
            return;
        }
        state_ = WebSocketState::Closed;  // before the Close event: when the game reads it, state() is Closed
        if (lost && !peerClosed && !failed) {
            emit(WebSocketEvent::failure("the connection to " + url_.host + " was lost",
                                         "Check the connection; try again."));
            emit(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
        } else if (failed) {
            // A failed connection ends with 1006 whatever the codec sent the server (1002, 1007, 1009): the browser's rule.
            emit(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
        } else {
            emit(WebSocketEvent::close(closeCode == ws::close_code::kAbnormal ? ws::close_code::kNoStatus : closeCode,
                                       closeReason, peerClosed));
        }
    }

    WebSocketRequest request_;
    ws::Url url_;
    std::shared_ptr<WebSocketEventQueue> queue_ =
        std::make_shared<WebSocketEventQueue>(WebSocketEventQueue::limit_for(request_.maxMessageBytes));
    mutable std::mutex
        mutex_;  // guards session_, inflight_, outgoing_, sent_, closeAsked_ and the transitions out of Connecting and Open
    ws::Session session_;
    std::string inflight_;  // being written: never changed until sent_ reaches its end (see flush)
    std::string outgoing_;  // queued behind inflight_
    std::size_t sent_ = 0;  // bytes of inflight_ written
    std::atomic<WebSocketState> state_{WebSocketState::Connecting};
    std::atomic<bool> stop_{false}, abort_{false};
    bool dead_ = false;  // the queue ended under the thread (push answered false); only the thread reads and writes it
    Clock::time_point closeAsked_;
    std::string subprotocol_;  // only the thread
    char errbuf_[256] = {0};   // CURLOPT_ERRORBUFFER: libcurl writes it on the thread, for the handle's life
    int wake_[2] = {-1, -1};
};

extern "C" int fa_ws_curl_progress(void* user, lc::curl_off_t, lc::curl_off_t, lc::curl_off_t, lc::curl_off_t) {
    return static_cast<const Core*>(user)->connect_cancelled() ? 1 : 0;
}

// What the game holds: forwards to the Core and lets go of it on destruction without waiting for the thread.
class CurlWebSocket final : public WebSocket {
public:
    explicit CurlWebSocket(std::shared_ptr<Core> core) : core_(std::move(core)) { core_->start(); }
    ~CurlWebSocket() override { core_->release(); }
    CurlWebSocket(const CurlWebSocket&) = delete;
    CurlWebSocket& operator=(const CurlWebSocket&) = delete;
    WebSocketState state() const override { return core_->state(); }
    Result<void> send_text(std::string_view text) override { return core_->send_text(text); }
    Result<void> send_binary(const void* data, std::size_t size) override { return core_->send_binary(data, size); }
    Result<void> close(int code, std::string_view reason) override { return core_->close(code, reason); }
    std::size_t buffered_amount() const override { return core_->buffered_amount(); }
    std::size_t poll(std::vector<WebSocketEvent>& out) override { return core_->poll(out); }

private:
    std::shared_ptr<Core> core_;
};

class CurlWebSocketClient final : public WebSocketClient {
public:
    std::string name() const override { return "curl"; }
    bool available() const override { return curl_unavailable_reason().empty(); }
    std::string unavailable_reason() const override { return curl_unavailable_reason(); }
    Result<std::unique_ptr<WebSocket>> connect(WebSocketRequest request) override {
        if (!available())
            return make_error("WebSocket is not available: " + curl_unavailable_reason(),
                              "Check websocket.supported before connecting, and let the game carry on offline.");
        auto url = ws::parse_url(request.url);
        if (!url.ok()) return url.error();
        if (url->secure && !curl_has_tls())
            return make_error("the libcurl on this computer has no TLS, so it cannot open " + request.url,
                              "Install a libcurl built with TLS (e.g. `sudo apt install libcurl4`), or use ws:// for a "
                              "server on your own computer.");
        // A header or subprotocol the handshake refuses is an error now, not a failed connection later.
        const std::uint8_t zeros[16] = {};
        if (auto head = ws::build_client_request(url.value(), ws::make_client_key(zeros), request.subprotocols,
                                                 request.headers);
            !head.ok())
            return head.error();
        return std::unique_ptr<WebSocket>(
            std::make_unique<CurlWebSocket>(std::make_shared<Core>(std::move(request), std::move(url.value()))));
    }
};

}  // namespace

std::unique_ptr<WebSocketClient> make_curl_websocket_client() { return std::make_unique<CurlWebSocketClient>(); }

}  // namespace fa

#endif
