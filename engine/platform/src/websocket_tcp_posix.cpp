// Plain ws:// over a POSIX socket with fa/platform/websocket_codec.h (fa/platform/websocket.h, make_tcp_websocket_client).
// It exists so that the codec and the loopback test server run against a real stream on every POSIX machine; a player never
// uses it (no TLS: wss:// is an error that says so). One thread per connection resolves, connects, does the handshake and
// reads; the game thread only queues bytes and wakes it through a pipe. Everything the network does reaches the game as
// events in a WebSocketEventQueue.
#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)

#include <arpa/inet.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <poll.h>
#include <sys/socket.h>
#include <unistd.h>

#include <algorithm>
#include <atomic>
#include <cerrno>
#include <chrono>
#include <cstring>
#include <mutex>
#include <random>
#include <thread>

#include "fa/core/strings.h"
#include "fa/platform/websocket.h"
#include "fa/platform/websocket_codec.h"

namespace fa {

namespace {

using Clock = std::chrono::steady_clock;

// The most the game may have queued and not yet sent: send_* fails above it (the script reads bufferedAmount).
constexpr std::size_t kMaxBuffered = 16u * 1024 * 1024;
// How long a closing handshake waits for the peer's close frame before the connection is dropped.
constexpr std::chrono::seconds kCloseWait{5};

#ifdef MSG_NOSIGNAL
constexpr int kSendFlags = MSG_NOSIGNAL;
#else
constexpr int kSendFlags = 0;
#endif

class TcpWebSocket final : public WebSocket {
public:
    TcpWebSocket(WebSocketRequest request, ws::Url url)
        : request_(std::move(request)), url_(std::move(url)), session_(make_options(request_.maxMessageBytes)) {
        if (::pipe(wake_) != 0) wake_[0] = wake_[1] = -1;
        for (int fd : wake_)
            if (fd >= 0) ::fcntl(fd, F_SETFL, ::fcntl(fd, F_GETFL, 0) | O_NONBLOCK);
        thread_ = std::thread([this] { run(); });
    }

    ~TcpWebSocket() override {
        stop_ = true;
        wake();
        if (thread_.joinable()) thread_.join();
        for (int fd : wake_)
            if (fd >= 0) ::close(fd);
    }

    WebSocketState state() const override { return state_.load(); }

    Result<void> send_text(std::string_view text) override {
        std::lock_guard<std::mutex> lock(mutex_);
        if (auto r = can_send(); !r.ok()) return r;
        if (!is_valid_utf8(text)) return make_error("the text is not valid UTF-8", "Send other data with send_binary.");
        auto r = session_.send_text(text);
        if (r.ok()) wake();
        return r;
    }

    Result<void> send_binary(const void* data, std::size_t size) override {
        std::lock_guard<std::mutex> lock(mutex_);
        if (auto r = can_send(); !r.ok()) return r;
        auto r = session_.send_binary(data, size);
        if (r.ok()) wake();
        return r;
    }

    void close(int code, std::string_view reason) override {
        std::lock_guard<std::mutex> lock(mutex_);
        const WebSocketState s = state_.load();
        if (s == WebSocketState::Closing || s == WebSocketState::Closed) return;
        if (s == WebSocketState::Connecting) {
            abort_ = true;
        } else if (session_.close(code, reason).ok()) {
            state_ = WebSocketState::Closing;
            closeAsked_ = Clock::now();
        }
        wake();
    }

    std::size_t buffered_amount() const override {
        std::lock_guard<std::mutex> lock(mutex_);
        return pending_bytes();
    }

    std::size_t poll(std::vector<WebSocketEvent>& out) override { return queue_.drain(out); }

private:
    static ws::SessionOptions make_options(std::size_t max) {
        ws::SessionOptions o;
        o.role = ws::Role::Client;
        o.maxMessageBytes = max;
        return o;
    }

    // mutex_ held
    std::size_t pending_bytes() const { return outgoing_.size() - sent_ + session_.pending_output_bytes(); }

    Result<void> can_send() const {
        const WebSocketState s = state_.load();
        if (s == WebSocketState::Connecting)
            return make_error("the connection is not open yet", "Wait for the \"open\" event before sending.");
        if (s != WebSocketState::Open) return make_error("the connection is closing or closed", "Connect again to send.");
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

    // Waits until `fd` is ready for `events` (1), the deadline passes (0), or the connection must stop (-1).
    int wait_for(int fd, short events, Clock::time_point deadline) {
        for (;;) {
            if (stop_ || abort_) return -1;
            const auto left = std::chrono::duration_cast<std::chrono::milliseconds>(deadline - Clock::now()).count();
            if (left <= 0) return 0;
            pollfd fds[2] = {{fd, events, 0}, {wake_[0], POLLIN, 0}};
            const int n = ::poll(fds, 2, static_cast<int>(std::min<long long>(left, 1000)));
            if (n < 0 && errno != EINTR) return 0;
            if (n > 0 && (fds[1].revents & POLLIN)) drain_wake();
            if (n > 0 && (fds[0].revents & (events | POLLERR | POLLHUP))) return 1;
        }
    }

    void fail_connect(const std::string& error, const std::string& hint, int status = 0) {
        queue_.push(WebSocketEvent::failure(error, hint, status));
        queue_.push(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
        state_ = WebSocketState::Closed;
    }

    int connect_socket(Clock::time_point deadline) {
        addrinfo hints{};
        hints.ai_family = AF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;
        addrinfo* list = nullptr;
        const int rc = ::getaddrinfo(url_.host.c_str(), std::to_string(url_.port).c_str(), &hints, &list);
        if (rc != 0 || !list) {
            fail_connect("could not find the server " + url_.host + " (" + ::gai_strerror(rc) + ")",
                         "Check the address and the connection.");
            return -1;
        }
        int fd = -1;
        int lastErrno = 0;
        bool timedOut = false;
        for (addrinfo* a = list; a && fd < 0; a = a->ai_next) {
            const int s = ::socket(a->ai_family, a->ai_socktype, a->ai_protocol);
            if (s < 0) {
                lastErrno = errno;
                continue;
            }
            ::fcntl(s, F_SETFL, ::fcntl(s, F_GETFL, 0) | O_NONBLOCK);
#ifdef SO_NOSIGPIPE
            const int one = 1;
            ::setsockopt(s, SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof(one));
#endif
            if (::connect(s, a->ai_addr, a->ai_addrlen) != 0 && errno != EINPROGRESS) {
                lastErrno = errno;
                ::close(s);
                continue;
            }
            const int ready = wait_for(s, POLLOUT, deadline);
            if (ready < 0) {
                ::close(s);
                ::freeaddrinfo(list);
                return -1;
            }
            int err = 0;
            socklen_t len = sizeof(err);
            if (ready == 0) {
                timedOut = true;
                ::close(s);
                break;
            }
            ::getsockopt(s, SOL_SOCKET, SO_ERROR, &err, &len);
            if (err != 0) {
                lastErrno = err;
                ::close(s);
                continue;
            }
            fd = s;
        }
        ::freeaddrinfo(list);
        if (fd < 0) {
            fail_connect(timedOut ? "timed out connecting to " + url_.host
                                  : "could not connect to " + url_.host + ":" + std::to_string(url_.port) + " (" +
                                        std::strerror(lastErrno) + ")",
                         "Check that the server is running and that the address and port are right.");
            return -1;
        }
        const int one = 1;
        ::setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one));
        return fd;
    }

    // Writes as much of the queue as the socket takes; false when the connection is broken.
    bool flush(int fd) {
        std::lock_guard<std::mutex> lock(mutex_);
        take_session_output();
        while (sent_ < outgoing_.size()) {
            const auto n = ::send(fd, outgoing_.data() + sent_, outgoing_.size() - sent_, kSendFlags);
            if (n < 0) {
                if (errno == EAGAIN || errno == EWOULDBLOCK) return true;
                if (errno == EINTR) continue;
                return false;
            }
            sent_ += static_cast<std::size_t>(n);
        }
        outgoing_.clear();
        sent_ = 0;
        return true;
    }

    void take_session_output() { outgoing_ += session_.take_output(); }  // mutex_ held

    bool send_all_blocking(int fd, const std::string& bytes, Clock::time_point deadline) {
        std::size_t at = 0;
        while (at < bytes.size()) {
            const auto n = ::send(fd, bytes.data() + at, bytes.size() - at, kSendFlags);
            if (n > 0) {
                at += static_cast<std::size_t>(n);
                continue;
            }
            if (n < 0 && errno == EINTR) continue;
            if (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK) return false;
            if (wait_for(fd, POLLOUT, deadline) != 1) return false;
        }
        return true;
    }

    // Reads the head of the server's answer; returns false (after reporting) when it fails.
    bool handshake(int fd, Clock::time_point deadline, std::string& leftover) {
        std::uint8_t random[16];
        std::random_device rd;
        for (std::uint8_t& b : random) b = static_cast<std::uint8_t>(rd());
        const std::string key = ws::make_client_key(random);
        auto req = ws::build_client_request(url_, key, request_.subprotocols, request_.headers);
        if (!req.ok()) {
            fail_connect(req.error().message, req.error().hint);
            return false;
        }
        if (!send_all_blocking(fd, req.value(), deadline)) {
            if (!stop_ && !abort_) fail_connect("the connection broke while sending the handshake", "Check the connection.");
            return false;
        }
        std::string data;
        std::size_t end = std::string::npos;
        while (end == std::string::npos) {
            const int ready = wait_for(fd, POLLIN, deadline);
            if (ready < 0) return false;
            if (ready == 0) {
                fail_connect("timed out waiting for the server's answer to the handshake",
                             "Check that the address is a WebSocket server and not a web page.");
                return false;
            }
            char buf[4096];
            const auto n = ::recv(fd, buf, sizeof(buf), 0);
            if (n == 0 || (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR)) {
                fail_connect("the server closed the connection during the handshake",
                             "Check the address and the port; the server may need wss://.");
                return false;
            }
            if (n > 0) data.append(buf, static_cast<std::size_t>(n));
            end = ws::find_head_end(data);
            if (end == std::string::npos && data.size() > 64 * 1024) {
                fail_connect("the server's answer to the handshake is longer than 64 KB", "The address is not a WebSocket server.");
                return false;
            }
        }
        const ws::HandshakeResult r = ws::check_server_response(std::string_view(data).substr(0, end), key, request_.subprotocols);
        if (!r.ok) {
            fail_connect(r.error, r.hint, r.status == 101 ? 0 : r.status);
            return false;
        }
        leftover = data.substr(end);
        subprotocol_ = r.subprotocol;
        return true;
    }

    void run() {
        const auto deadline = Clock::now() + std::chrono::milliseconds(static_cast<long long>(request_.connectTimeoutSec * 1000));
        int fd = connect_socket(deadline);
        if (fd < 0) {
            finish_aborted();
            return;
        }
        std::string leftover;
        if (!handshake(fd, deadline, leftover)) {
            ::close(fd);
            finish_aborted();
            return;
        }
        state_ = WebSocketState::Open;
        queue_.push(WebSocketEvent::open(subprotocol_));
        serve(fd, leftover);
        ::close(fd);
    }

    // The game closed (or destroyed) the connection while it was connecting: the attempt ends with Error and Close 1006.
    void finish_aborted() {
        if (state_.load() != WebSocketState::Closed && !stop_) fail_connect("the connection was closed before it was open", "");
        state_ = WebSocketState::Closed;
    }

    void handle(std::vector<ws::Event>& events, int& closeCode, std::string& closeReason, bool& peerClosed, bool& failed) {
        for (ws::Event& e : events) {
            switch (e.type) {
                case ws::Event::Type::Text: queue_.push(WebSocketEvent::text(std::move(e.data))); break;
                case ws::Event::Type::Binary: queue_.push(WebSocketEvent::binary(std::move(e.data))); break;
                case ws::Event::Type::Ping:
                case ws::Event::Type::Pong: break;
                case ws::Event::Type::Close:
                    peerClosed = true;
                    closeCode = e.code;
                    closeReason = std::move(e.reason);
                    state_ = WebSocketState::Closing;
                    break;
                case ws::Event::Type::Failure:
                    failed = true;
                    closeCode = e.code;
                    queue_.push(WebSocketEvent::failure(e.error, e.hint));
                    break;
            }
        }
        events.clear();
    }

    void serve(int fd, const std::string& leftover) {
        std::vector<ws::Event> events;
        int closeCode = ws::close_code::kAbnormal;
        std::string closeReason;
        bool peerClosed = false, failed = false, lost = false;
        if (!leftover.empty()) {
            std::lock_guard<std::mutex> lock(mutex_);
            session_.feed(leftover.data(), leftover.size(), events);
        }
        handle(events, closeCode, closeReason, peerClosed, failed);
        std::vector<char> buf(64 * 1024);
        while (!stop_) {
            bool done, needWrite;
            if (!flush(fd)) {  // also moves what the session queued (pongs, close answers) to the output
                lost = true;
                break;
            }
            {
                std::lock_guard<std::mutex> lock(mutex_);
                done = session_.done();
                needWrite = sent_ < outgoing_.size();
            }
            if (done && !needWrite) break;
            if (state_.load() == WebSocketState::Closing && !peerClosed && Clock::now() - closeAsked_ > kCloseWait) {
                lost = true;
                break;
            }
            pollfd fds[2] = {{fd, static_cast<short>(POLLIN | (needWrite ? POLLOUT : 0)), 0}, {wake_[0], POLLIN, 0}};
            const int n = ::poll(fds, 2, 500);
            if (n < 0 && errno != EINTR) {
                lost = true;
                break;
            }
            if (n <= 0) continue;
            if (fds[1].revents & POLLIN) drain_wake();
            if (fds[0].revents & (POLLIN | POLLHUP | POLLERR)) {
                const auto got = ::recv(fd, buf.data(), buf.size(), 0);
                if (got == 0 || (got < 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR)) {
                    lost = true;
                    break;
                }
                if (got > 0) {
                    {
                        std::lock_guard<std::mutex> lock(mutex_);
                        session_.feed(buf.data(), static_cast<std::size_t>(got), events);
                    }
                    handle(events, closeCode, closeReason, peerClosed, failed);
                }
            }
        }
        if (stop_) {  // destroyed: say goodbye if that takes no waiting, deliver nothing
            {
                std::lock_guard<std::mutex> lock(mutex_);
                if (state_.load() == WebSocketState::Open) static_cast<void>(session_.close(ws::close_code::kGoingAway, {}));
            }
            flush(fd);
            state_ = WebSocketState::Closed;
            return;
        }
        if (lost && !peerClosed && !failed) {
            queue_.push(WebSocketEvent::failure("the connection to " + url_.host + " was lost", "Check the connection; try again."));
            queue_.push(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
        } else if (failed) {
            queue_.push(WebSocketEvent::close(closeCode, "", false));
        } else {
            queue_.push(WebSocketEvent::close(closeCode == ws::close_code::kAbnormal ? ws::close_code::kNoStatus : closeCode,
                                              closeReason, peerClosed));
        }
        state_ = WebSocketState::Closed;
    }

    WebSocketRequest request_;
    ws::Url url_;
    WebSocketEventQueue queue_;
    mutable std::mutex mutex_;  // guards session_, outgoing_ and sent_
    ws::Session session_;
    std::string outgoing_;
    std::size_t sent_ = 0;
    std::atomic<WebSocketState> state_{WebSocketState::Connecting};
    std::atomic<bool> stop_{false}, abort_{false};
    Clock::time_point closeAsked_;
    std::string subprotocol_;
    int wake_[2] = {-1, -1};
    std::thread thread_;
};

class TcpWebSocketClient final : public WebSocketClient {
public:
    std::string name() const override { return "tcp"; }
    bool available() const override { return true; }
    Result<std::unique_ptr<WebSocket>> connect(WebSocketRequest request) override {
        auto url = ws::parse_url(request.url);
        if (!url.ok()) return url.error();
        if (url->secure)
            return make_error("this client has no TLS, so it cannot open " + request.url,
                              "Use ws:// for a server on your own computer; real games use the system's client.");
        // A header or subprotocol the handshake refuses is an error now, not a failed connection later.
        const std::uint8_t zeros[16] = {};
        if (auto head = ws::build_client_request(url.value(), ws::make_client_key(zeros), request.subprotocols, request.headers);
            !head.ok())
            return head.error();
        return std::unique_ptr<WebSocket>(std::make_unique<TcpWebSocket>(std::move(request), std::move(url.value())));
    }
};

}  // namespace

std::unique_ptr<WebSocketClient> make_tcp_websocket_client() { return std::make_unique<TcpWebSocketClient>(); }

}  // namespace fa

#endif
