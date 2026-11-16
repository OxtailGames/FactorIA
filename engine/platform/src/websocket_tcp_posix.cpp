// Plain ws:// over a POSIX socket with fa/platform/websocket_codec.h (fa/platform/websocket.h, make_tcp_websocket_client).
// The codec and the loopback test server run against a real stream through it on every POSIX machine, and Android's client
// opens its ws:// addresses with it (websocket_android.cpp; wss:// there goes through Java's TLS). No TLS here: wss:// is an
// error that says so. One thread per connection resolves, connects, does the handshake and reads; the game thread only
// queues bytes and wakes it through a pipe. Everything the network does reaches the game as events in a WebSocketEventQueue.
//
// It follows the pattern of fa/platform/websocket.h for every native client: the thread owns a shared_ptr to the connection's
// state (a StreamCore, websocket_stream.h) and so to its queue; destroying the connection abandons the queue, tells the
// thread to stop and DETACHES it, so the game thread never waits for a DNS lookup or a read; a push() that answers false ends
// the thread's work.
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
#include <cerrno>
#include <chrono>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>

#include "fa/platform/websocket.h"
#include "fa/platform/websocket_codec.h"
#include "websocket_stream.h"

namespace fa {

namespace {

using ws_stream::Clock;
using ws_stream::kCloseWait;

// Android refuses sockets and DNS lookups to an app without the INTERNET permission.
#if defined(__ANDROID__)
constexpr const char* kPermissionHint = " On Android the app needs the INTERNET permission: declare the hosts in "
                                        "factoria.json \"network\" and export again.";
#else
constexpr const char* kPermissionHint = "";
#endif

#ifdef MSG_NOSIGNAL
constexpr int kSendFlags = MSG_NOSIGNAL;
#else
constexpr int kSendFlags = 0;
#endif

class TcpCore final : public ws_stream::StreamCore {
public:
    TcpCore(WebSocketRequest request, ws::Url url) : StreamCore(std::move(request), std::move(url)) {
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

    ~TcpCore() override {
        for (int fd : wake_)
            if (fd >= 0) ::close(fd);
    }

private:
    void wake() override {
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
            if (stopping()) return -1;
            const auto left = std::chrono::duration_cast<std::chrono::milliseconds>(deadline - Clock::now()).count();
            if (left <= 0) return 0;
            pollfd fds[2] = {{fd, events, 0}, {wake_[0], POLLIN, 0}};
            const int n = ::poll(fds, 2, static_cast<int>(std::min<long long>(left, 1000)));
            if (n < 0 && errno != EINTR) return 0;
            if (n > 0 && (fds[1].revents & POLLIN)) drain_wake();
            if (n > 0 && (fds[0].revents & (events | POLLERR | POLLHUP))) return 1;
        }
    }

    int connect_socket(Clock::time_point deadline) {
        addrinfo hints{};
        hints.ai_family = AF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;
        addrinfo* list = nullptr;
        const int rc = ::getaddrinfo(url_.host.c_str(), std::to_string(url_.port).c_str(), &hints, &list);
        if (rc != 0 || !list) {
            fail_connect("could not find the server " + url_.host + " (" + ::gai_strerror(rc) + ")",
                         std::string("Check the address and the connection.") + kPermissionHint);
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
            fail_connect(
                timedOut ? "timed out connecting to " + url_.host_in_brackets() + ":" + std::to_string(url_.port)
                         : "could not connect to " + url_.host_in_brackets() + ":" + std::to_string(url_.port) + " (" +
                               std::strerror(lastErrno) + ")",
                lastErrno == EACCES || lastErrno == EPERM
                    ? std::string("The system refused the socket.") + kPermissionHint
                    : std::string("Check that the server is running and that the address and port are right."));
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
                if (errno == EAGAIN || errno == EWOULDBLOCK) {
                    if (sent_ >= 1024 * 1024) {  // a game that keeps sending never lets the buffer empty: trim it
                        outgoing_.erase(0, sent_);
                        sent_ = 0;
                    }
                    return true;
                }
                if (errno == EINTR) continue;
                return false;
            }
            sent_ += static_cast<std::size_t>(n);
        }
        outgoing_.clear();
        sent_ = 0;
        return true;
    }

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

    // Sends the request and reads the head of the server's answer; returns false (after reporting) when it fails.
    bool handshake(int fd, Clock::time_point deadline, std::string& leftover) {
        std::string key, request;
        if (!begin_handshake(key, request)) return false;
        if (!send_all_blocking(fd, request, deadline)) {
            if (!stopping()) fail_connect("the connection broke while sending the handshake", "Check the connection.");
            return false;
        }
        std::string data;
        for (;;) {
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
            if (n <= 0) continue;
            data.append(buf, static_cast<std::size_t>(n));
            const int checked = check_handshake(data, key, leftover);
            if (checked < 0) return false;
            if (checked > 0) return true;
        }
    }

    void run() override {
        const auto deadline = connect_deadline();
        const int fd = connect_socket(deadline);
        if (fd < 0) {
            finish_aborted();
            return;
        }
        std::string leftover;
        if (!handshake(fd, deadline, leftover) || !open_connection()) {
            ::close(fd);
            finish_aborted();
            return;
        }
        serve(fd, leftover);
        state_ = WebSocketState::Closed;
        ::close(fd);
    }

    void serve(int fd, const std::string& leftover) {
        ws_stream::Ending ending;
        bool failedSeen = false;
        Clock::time_point failedAt;
        if (!leftover.empty()) feed(leftover.data(), leftover.size(), ending);
        std::vector<char> buf(64 * 1024);
        while (!stop_ && !dead_) {
            bool done, needWrite, waitingForPeer = false;
            Clock::time_point asked;
            if (!flush(fd)) {  // also moves what the session queued (pongs, close answers) to the output
                ending.lost = true;
                break;
            }
            {
                std::lock_guard<std::mutex> lock(mutex_);
                done = session_.done();
                needWrite = sent_ < outgoing_.size();
                waitingForPeer = state_.load() == WebSocketState::Closing && !ending.peerClosed;
                asked = closeAsked_;
            }
            if (done && !needWrite) break;
            if (ending.failed && !failedSeen) {
                failedSeen = true;
                failedAt = Clock::now();
            }
            // The server does not answer our close frame, or (after a failure) does not read the one we sent: give up.
            if ((waitingForPeer && Clock::now() - asked > kCloseWait) ||
                (failedSeen && Clock::now() - failedAt > kCloseWait)) {
                ending.lost = true;
                break;
            }
            pollfd fds[2] = {{fd, static_cast<short>(POLLIN | (needWrite ? POLLOUT : 0)), 0}, {wake_[0], POLLIN, 0}};
            const int n = ::poll(fds, 2, 500);
            if (n < 0 && errno != EINTR) {
                ending.lost = true;
                break;
            }
            if (n <= 0) continue;
            if (fds[1].revents & POLLIN) drain_wake();
            if (fds[0].revents & (POLLIN | POLLHUP | POLLERR)) {
                const auto got = ::recv(fd, buf.data(), buf.size(), 0);
                if (got == 0 || (got < 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR)) {
                    ending.lost = true;
                    break;
                }
                if (got > 0) feed(buf.data(), static_cast<std::size_t>(got), ending);
            }
        }
        if (stop_ || dead_) {
            // Destroyed, or the queue ended: say goodbye if that takes no waiting, report nothing more.
            queue_goodbye();
            flush(fd);
        }
        finish(ending);
    }

    int wake_[2] = {-1, -1};
};

class TcpWebSocketClient final : public WebSocketClient {
public:
    std::string name() const override { return "tcp"; }
    bool available() const override { return true; }
    Result<std::unique_ptr<WebSocket>> connect(WebSocketRequest request) override {
        auto url = ws_stream::check_request(request);
        if (!url.ok()) return url.error();
        if (url->secure)
            return make_error("this client has no TLS, so it cannot open " + request.url,
                              "Use ws:// for a server on your own computer; real games use the system's client.");
        return std::unique_ptr<WebSocket>(std::make_unique<ws_stream::StreamWebSocket>(
            ws_stream::make_tcp_core(std::move(request), std::move(url.value()))));
    }
};

}  // namespace

namespace ws_stream {

std::shared_ptr<StreamCore> make_tcp_core(WebSocketRequest request, ws::Url url) {
    return std::make_shared<TcpCore>(std::move(request), std::move(url));
}

}  // namespace ws_stream

std::unique_ptr<WebSocketClient> make_tcp_websocket_client() { return std::make_unique<TcpWebSocketClient>(); }

}  // namespace fa

#endif
