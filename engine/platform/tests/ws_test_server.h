// A WebSocket server for the tests of the clients (fa/platform/websocket.h), on the loopback address only (127.0.0.1, or ::1
// when asked; an ephemeral port): it never accepts a connection from another machine. It is built on the codec of
// fa/platform/websocket_codec.h, one thread per connection, on POSIX sockets or Winsock. It ends by itself: every thread
// waits for its socket with poll() (select() on Windows) at most 100 ms at a time and looks at stop_ in between, so the
// destructor only sets stop_ and joins them (no connection to itself to wake an accept(), which a busy machine can refuse or
// delay); finished connection threads are joined while the server runs. No thread or socket outlives the test.
//
// Routes (the path of the address; "?x=1" arguments where listed):
//   /echo              answers every text and binary message with the same message; pings are answered, a close is answered
//   /greet             sends the text "hello" and the binary 01 02 03 right after the handshake, then echoes
//   /protocol          chooses the first subprotocol the client offered, then sends it as a text message ("none" when none)
//   /headers           sends the request's headers as a JSON text {"name": "value"} (lower-case names), then echoes
//   /close?code=4001&reason=bye   sends a close frame at once and waits for the client's answer
//   /drop              closes the TCP connection right after the handshake, with no close frame
//   /refuse?status=403 answers the handshake with that HTTP status (default 403) and closes
//   /redirect          answers the handshake with 302 and a Location of /echo, and closes
//   /badaccept         answers 101 with a wrong Sec-WebSocket-Accept
//   /silent            completes the handshake and then says nothing at all (keeps reading and ignoring)
//   /fragments         sends "Hello" as the text fragments "Hel" + ping + "lo", then echoes
//   /big?n=100000      sends one text message of n 'x' characters, then echoes
//   /badutf8           sends a text frame that is not valid UTF-8
//   /badrsv            sends a frame with a reserved bit set
//   /ping              sends a ping "hi" after the handshake; pongs received are counted (pongs())
//   /hang              reads the handshake request and never answers it (a client stays connecting until its timeout)
//   anything else      404 and closes
#pragma once

#include <algorithm>
#include <atomic>
#include <cerrno>
#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/json.h"
#include "fa/platform/websocket_codec.h"

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <poll.h>
#include <sys/socket.h>
#include <unistd.h>
#endif

namespace fa::test {

class WsTestServer {
public:
#ifdef _WIN32
    using Socket = SOCKET;
    static constexpr Socket kBad = INVALID_SOCKET;
#else
    using Socket = int;
    static constexpr Socket kBad = -1;
#endif

    // `ipv6`: listen on ::1 instead of 127.0.0.1. ok() is false when the machine has no IPv6 loopback (some containers).
    explicit WsTestServer(bool ipv6 = false) : ipv6_(ipv6) {
#ifdef _WIN32
        WSADATA data;
        wsaStarted_ = WSAStartup(MAKEWORD(2, 2), &data) == 0;
        if (!wsaStarted_) return;
#endif
        listener_ = ::socket(ipv6 ? AF_INET6 : AF_INET, SOCK_STREAM, 0);
        if (listener_ == kBad) return;
        sockaddr_in addr4{};
        sockaddr_in6 addr6{};
        addr4.sin_family = AF_INET;
        addr4.sin_addr.s_addr = htonl(INADDR_LOOPBACK);  // loopback only
        addr6.sin6_family = AF_INET6;
        addr6.sin6_addr = in6addr_loopback;
        sockaddr* addr = ipv6 ? reinterpret_cast<sockaddr*>(&addr6) : reinterpret_cast<sockaddr*>(&addr4);
        socklen_t length = ipv6 ? static_cast<socklen_t>(sizeof(addr6)) : static_cast<socklen_t>(sizeof(addr4));
        if (::bind(listener_, addr, length) != 0 || ::listen(listener_, 16) != 0 ||
            ::getsockname(listener_, addr, &length) != 0) {
            close_socket(listener_);
            listener_ = kBad;
            return;
        }
        port_ = ntohs(ipv6 ? addr6.sin6_port : addr4.sin_port);
        thread_ = std::thread([this] { accept_loop(); });
    }
    ~WsTestServer() {
        stop_ = true;  // the accept loop and every connection thread see it within 100 ms
        if (thread_.joinable()) thread_.join();
        std::vector<Worker> workers;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            workers.swap(workers_);
        }
        for (Worker& w : workers)
            if (w.thread.joinable()) w.thread.join();
        if (listener_ != kBad) close_socket(listener_);
#ifdef _WIN32
        if (wsaStarted_) WSACleanup();
#endif
    }
    WsTestServer(const WsTestServer&) = delete;
    WsTestServer& operator=(const WsTestServer&) = delete;

    bool ok() const { return port_ != 0; }
    int port() const { return port_; }
    std::string url(const std::string& path) const { return url(path, ipv6_ ? "[::1]" : "127.0.0.1"); }
    std::string url(const std::string& path, const std::string& host) const {
        return "ws://" + host + ":" + std::to_string(port_) + path;
    }

    int connections() const { return connections_.load(); }  // TCP connections accepted
    int handshakes() const { return handshakes_.load(); }    // upgrades answered with 101
    int pongs() const { return pongs_.load(); }              // pongs received (route /ping)
    // Close codes of the close frames the clients sent, in arrival order (1005 when a frame had no code).
    std::vector<int> client_close_codes() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return closeCodes_;
    }
    // The headers (lower-case names) of the last handshake request.
    std::map<std::string, std::string> last_headers() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return lastHeaders_;
    }
    // True once the server noticed that a connection ended (the client closed it or sent a close).
    int finished_connections() const { return finished_.load(); }

    // What the last connections received, for the message of a failed check: for each one its route, the bytes that came
    // after the handshake (the first ones in hex), the frames they held (opcode, FIN, RSV bits, mask, length, close code), the
    // events of the parser, and how the connection ended (the client's FIN, a reset, the closing handshake, the test's end).
    std::string diagnostics() const {
        std::lock_guard<std::mutex> lock(mutex_);
        if (logs_.empty()) return "the server accepted no connection";
        std::string out;
        for (const auto& log : logs_) {
            out += "connection #" + std::to_string(log->id) + " " + (log->route.empty() ? "(no request)" : log->route) +
                   ": " + std::to_string(log->bytesIn) + " bytes after the handshake";
            if (!log->raw.empty()) {
                static const char* hex = "0123456789abcdef";
                out += " [";
                const std::size_t shown = std::min<std::size_t>(log->raw.size(), kHexBytes);
                for (std::size_t i = 0; i < shown; ++i) {
                    const auto b = static_cast<unsigned char>(log->raw[i]);
                    if (i) out += ' ';
                    out += hex[b >> 4];
                    out += hex[b & 15];
                }
                if (log->raw.size() > shown) out += " ...";
                out += "]";
            }
            out += log->closeFrame ? "; a close frame arrived" : "; NO close frame arrived";
            for (const std::string& note : log->notes) out += "\n    " + note;
            out += "\n    ended: " + (log->end.empty() ? std::string("still open") : log->end) + "\n";
        }
        return out;
    }

private:
    // What one connection received (diagnostics()). Written by its thread, read by the test, both under mutex_.
    struct ConnectionLog {
        int id = 0;
        std::string route;
        std::size_t bytesIn = 0;         // every byte after the handshake
        std::string raw;                 // the first kRawBytes of them
        std::size_t decodedTo = 0;       // how far `raw` was split into frames
        std::vector<std::string> notes;  // frames and parser events, the last kMaxNotes
        bool closeFrame = false;
        std::string end;
    };
    static constexpr std::size_t kRawBytes = 4096, kHexBytes = 64, kMaxNotes = 32;
    static constexpr std::size_t kMaxLogs = 8;

    void note(ConnectionLog& log, std::string text) {
        if (log.notes.size() >= kMaxNotes) log.notes.erase(log.notes.begin());  // the last ones tell how it ended
        log.notes.push_back(std::move(text));
    }

    // Bytes the client sent after the handshake: kept, and each frame they complete described. mutex_ held.
    void log_input(ConnectionLog& log, const char* data, std::size_t size) {
        log.bytesIn += size;
        if (log.raw.size() < kRawBytes) log.raw.append(data, std::min(size, kRawBytes - log.raw.size()));
        const std::string& r = log.raw;
        while (true) {
            const std::size_t at = log.decodedTo;
            if (r.size() - at < 2) return;
            const auto b0 = static_cast<unsigned char>(r[at]);
            const auto b1 = static_cast<unsigned char>(r[at + 1]);
            std::size_t header = 2;
            std::uint64_t length = b1 & 0x7f;
            if (length == 126 || length == 127) {
                const std::size_t extra = length == 126 ? 2 : 8;
                if (r.size() - at < header + extra) return;
                length = 0;
                for (std::size_t i = 0; i < extra; ++i)
                    length = (length << 8) | static_cast<unsigned char>(r[at + 2 + i]);
                header += extra;
            }
            const bool masked = (b1 & 0x80) != 0;
            if (masked) header += 4;
            if (length > kRawBytes || r.size() - at < header + length) return;  // incomplete, or past what is kept
            const int opcode = b0 & 0x0f;
            std::string text = "frame: opcode " + std::to_string(opcode) + " fin " + std::to_string((b0 >> 7) & 1) +
                               " rsv " + std::to_string((b0 >> 4) & 7) + " masked " + std::to_string(masked ? 1 : 0) +
                               " length " + std::to_string(length);
            if (opcode == 8) {
                log.closeFrame = true;
                if (length >= 2) {
                    unsigned char code[2];
                    for (std::size_t i = 0; i < 2; ++i) {
                        const auto key = masked ? static_cast<unsigned char>(r[at + header - 4 + i]) : 0;
                        code[i] = static_cast<unsigned char>(static_cast<unsigned char>(r[at + header + i]) ^ key);
                    }
                    text += " (close, code " + std::to_string((code[0] << 8) | code[1]) + ")";
                } else {
                    text += " (close, no code)";
                }
            }
            note(log, std::move(text));
            log.decodedTo = at + header + static_cast<std::size_t>(length);
        }
    }

    static void close_socket(Socket s) {
#ifdef _WIN32
        ::closesocket(s);
#else
        ::close(s);
#endif
    }

    // 1: `s` is readable (or has an error or hung up: the next call says which), 0: nothing within `ms`, -1: poll failed.
    static int wait_readable(Socket s, int ms) {
#ifdef _WIN32
        // select() rather than WSAPoll, which needs _WIN32_WINNT >= 0x0600 from every includer. The set is filled by hand
        // (Winsock's fd_set is a count and an array), without the FD_SET macros.
        fd_set set{};
        set.fd_count = 1;
        set.fd_array[0] = s;
        timeval tv{};
        tv.tv_sec = ms / 1000;
        tv.tv_usec = (ms % 1000) * 1000;
        const int n = ::select(0, &set, nullptr, nullptr, &tv);
        if (n == SOCKET_ERROR) return -1;
#else
        pollfd p{};
        p.fd = s;
        p.events = POLLIN;
        const int n = ::poll(&p, 1, ms);
        if (n < 0) return errno == EINTR ? 0 : -1;
#endif
        return n > 0 ? 1 : 0;
    }

    // Joins the connection threads that ended, so a long test does not keep them all.
    void reap_finished() {
        std::vector<Worker> done;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            for (auto it = workers_.begin(); it != workers_.end();) {
                if (it->done->load()) {
                    done.push_back(std::move(*it));
                    it = workers_.erase(it);
                } else {
                    ++it;
                }
            }
        }
        for (Worker& w : done)
            if (w.thread.joinable()) w.thread.join();
    }

    void accept_loop() {
        while (!stop_) {
            reap_finished();
            const int ready = wait_readable(listener_, 50);
            if (ready <= 0) {
                // A persistent poll() error must not spin a core.
                if (ready < 0) std::this_thread::sleep_for(std::chrono::milliseconds(10));
                continue;
            }
            Socket c = ::accept(listener_, nullptr, nullptr);
            if (c == kBad) {
                // A persistent accept() error (out of descriptors...) must not spin a core.
                if (!stop_) std::this_thread::sleep_for(std::chrono::milliseconds(10));
                continue;
            }
            if (stop_) {
                close_socket(c);
                break;
            }
            ++connections_;
#ifdef SO_NOSIGPIPE
            const int one = 1;
            ::setsockopt(c, SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof(one));
#endif
            auto log = std::make_shared<ConnectionLog>();
            log->id = connections_.load();
            {
                std::lock_guard<std::mutex> lock(mutex_);
                logs_.push_back(log);
                if (logs_.size() > kMaxLogs) logs_.erase(logs_.begin());
            }
            Worker w;
            w.done = std::make_shared<std::atomic<bool>>(false);
            auto done = w.done;
            w.thread = std::thread([this, c, done, log] {
                serve(c, *log);
                {
                    std::lock_guard<std::mutex> lock(mutex_);
                    if (log->end.empty()) log->end = "the server ended it before the WebSocket session";
                }
                close_socket(c);
                ++finished_;
                done->store(true);
            });
            std::lock_guard<std::mutex> lock(mutex_);
            workers_.push_back(std::move(w));
        }
    }

    static bool write_all(Socket c, const std::string& bytes) {
        std::size_t at = 0;
        while (at < bytes.size()) {
#ifdef MSG_NOSIGNAL
            const int flags = MSG_NOSIGNAL;
#else
            const int flags = 0;
#endif
            const auto n = ::send(c, bytes.data() + at, static_cast<int>(bytes.size() - at), flags);
            if (n <= 0) return false;
            at += static_cast<std::size_t>(n);
        }
        return true;
    }

    // -1: the peer closed or an error; 0: nothing within 100 ms (the caller looks at stop_); n > 0: bytes. The wait is a
    // poll, not SO_RCVTIMEO: on Windows a socket whose receive timed out is in an undefined state.
    // `why`, when given, says what a -1 was: the client's FIN, a reset, another error.
    static int read_some(Socket c, char* buffer, int size, std::string* why = nullptr) {
        const int ready = wait_readable(c, 100);
        if (ready < 0) {
            if (why) *why = "poll failed";
            return -1;
        }
        if (ready == 0) return 0;
        const auto n = ::recv(c, buffer, size, 0);
        if (n > 0) return static_cast<int>(n);
        if (n == 0) {
            if (why) *why = "the client closed the TCP connection (FIN)";
            return -1;
        }
#ifdef _WIN32
        const int error = WSAGetLastError();
        if (error == WSAEWOULDBLOCK) return 0;
        const bool reset = error == WSAECONNRESET;
#else
        const int error = errno;
        if (error == EAGAIN || error == EWOULDBLOCK || error == EINTR) return 0;
        const bool reset = error == ECONNRESET;
#endif
        if (why)
            *why = reset ? "the client reset the TCP connection (RST)" : "recv failed, error " + std::to_string(error);
        return -1;
    }

    static std::map<std::string, std::string> query_of(const std::string& path) {
        std::map<std::string, std::string> q;
        const std::size_t mark = path.find('?');
        if (mark == std::string::npos) return q;
        std::size_t pos = mark + 1;
        while (pos < path.size()) {
            std::size_t end = path.find('&', pos);
            if (end == std::string::npos) end = path.size();
            const std::string pair = path.substr(pos, end - pos);
            const std::size_t eq = pair.find('=');
            q[pair.substr(0, eq)] = eq == std::string::npos ? "" : pair.substr(eq + 1);
            pos = end + 1;
        }
        return q;
    }

    void serve(Socket c, ConnectionLog& log) {
        auto finish = [&](std::string why) {
            std::lock_guard<std::mutex> lock(mutex_);
            log.end = std::move(why);
        };
        // The head of the request.
        std::string data;
        std::size_t headEnd = std::string::npos;
        char buffer[4096];
        constexpr int kBufferSize = static_cast<int>(sizeof(buffer));
        while (headEnd == std::string::npos && !stop_) {
            const int n = read_some(c, buffer, kBufferSize);
            if (n < 0) return;
            data.append(buffer, static_cast<std::size_t>(n));
            headEnd = ws::find_head_end(data);
            if (data.size() > 64 * 1024) return;
        }
        if (headEnd == std::string::npos) return;
        auto request = ws::parse_client_request(std::string_view(data).substr(0, headEnd));
        if (!request.ok()) {
            write_all(c, ws::build_reject_response(400, "Bad Request"));
            return;
        }
        const ws::ClientRequest& req = request.value();
        {
            std::lock_guard<std::mutex> lock(mutex_);
            lastHeaders_.clear();
            for (const auto& [k, v] : req.headers) lastHeaders_[k] = v;
        }
        const std::string route = req.path.substr(0, req.path.find('?'));
        const auto query = query_of(req.path);
        {
            std::lock_guard<std::mutex> lock(mutex_);
            log.route = req.path;
        }

        if (route == "/refuse") {
            const int status = query.count("status") ? std::atoi(query.at("status").c_str()) : 403;
            write_all(c, ws::build_reject_response(status, status == 403 ? "Forbidden" : "Refused"));
            return;
        }
        if (route == "/redirect") {
            write_all(c, "HTTP/1.1 302 Found\r\nLocation: /echo\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
            return;
        }
        if (route == "/hang") {
            // Never answer: wait until the client gives up (closes the connection) or the server stops.
            while (!stop_)
                if (read_some(c, buffer, kBufferSize) < 0) return;
            return;
        }
        if (route != "/echo" && route != "/greet" && route != "/protocol" && route != "/headers" && route != "/close" &&
            route != "/drop" && route != "/badaccept" && route != "/silent" && route != "/fragments" &&
            route != "/big" && route != "/flood" && route != "/badutf8" && route != "/badrsv" && route != "/ping") {
            write_all(c, ws::build_reject_response(404, "Not Found"));
            return;
        }
        std::string chosen;
        if (route == "/protocol" && !req.subprotocols.empty()) chosen = req.subprotocols[0];
        std::string response = ws::build_server_response(req, chosen);
        if (route == "/badaccept") {
            ws::ClientRequest wrong = req;
            wrong.key = "AAAAAAAAAAAAAAAAAAAAAA==";
            response = ws::build_server_response(wrong, "");
        }
        if (!write_all(c, response)) return finish("writing to the client failed");
        ++handshakes_;
        if (route == "/drop" || route == "/badaccept") return;

        ws::SessionOptions options;
        options.role = ws::Role::Server;
        options.maxMessageBytes = 64u * 1024 * 1024;
        ws::Session session(options);
        std::string leftover = data.substr(headEnd);
        auto flush = [&] { return write_all(c, session.take_output()); };

        if (route == "/greet") {
            static_cast<void>(session.send_text("hello"));
            static_cast<void>(session.send_binary("\x01\x02\x03", 3));
        } else if (route == "/protocol") {
            static_cast<void>(session.send_text(chosen.empty() ? "none" : chosen));
        } else if (route == "/headers") {
            Json headers = Json::object();
            for (const auto& [k, v] : req.headers) headers[k] = v;
            static_cast<void>(session.send_text(headers.dump()));
        } else if (route == "/close") {
            const int code = query.count("code") ? std::atoi(query.at("code").c_str()) : 1000;
            static_cast<void>(session.close(code, query.count("reason") ? query.at("reason") : ""));
        } else if (route == "/fragments") {
            std::string out = ws::encode_frame(ws::Opcode::Text, "Hel", false, nullptr);
            out += ws::encode_frame(ws::Opcode::Ping, "mid", true, nullptr);
            out += ws::encode_frame(ws::Opcode::Continuation, "lo", true, nullptr);
            if (!write_all(c, out)) return finish("writing to the client failed");
        } else if (route == "/big") {
            const std::size_t n = query.count("n") ? static_cast<std::size_t>(std::atoll(query.at("n").c_str())) : 1000;
            static_cast<void>(session.send_text(std::string(n, 'x')));
        } else if (route == "/flood") {
            // `count` text messages of `n` bytes at once, which a client that does not read lets pile up.
            const std::size_t n = query.count("n") ? static_cast<std::size_t>(std::atoll(query.at("n").c_str())) : 1000;
            const int count = query.count("count") ? std::atoi(query.at("count").c_str()) : 1;
            for (int i = 0; i < count; ++i) {
                static_cast<void>(session.send_text(std::string(n, 'x')));
                if (!flush()) return finish("writing to the client failed");
            }
        } else if (route == "/badutf8") {
            if (!write_all(c, ws::encode_frame(ws::Opcode::Text, "\xff\xfe", true, nullptr)))
                return finish("writing to the client failed");
        } else if (route == "/badrsv") {
            std::string frame = ws::encode_frame(ws::Opcode::Text, "x", true, nullptr);
            frame[0] = static_cast<char>(frame[0] | 0x40);
            if (!write_all(c, frame)) return finish("writing to the client failed");
        } else if (route == "/ping") {
            static_cast<void>(session.send_ping("hi"));
        }
        if (!flush()) return finish("writing to the client failed");

        std::vector<ws::Event> events;
        auto feed = [&](const char* bytes, std::size_t size) {
            {
                std::lock_guard<std::mutex> lock(mutex_);
                log_input(log, bytes, size);
            }
            session.feed(bytes, size, events);
            std::lock_guard<std::mutex> lock(mutex_);
            for (const ws::Event& e : events) {
                if (e.type == ws::Event::Type::Close) {
                    log.closeFrame =
                        true;  // the parser read it, also past the first kRawBytes that log_input() decodes
                    note(log, "parser: close, code " + std::to_string(e.code) + " reason \"" + e.reason + "\"");
                } else if (e.type == ws::Event::Type::Failure)
                    note(log, "parser: failure \"" + e.error + "\", answered with close " + std::to_string(e.code));
            }
        };
        if (!leftover.empty()) feed(leftover.data(), leftover.size());
        std::string why;
        while (!stop_) {
            for (ws::Event& e : events) {
                switch (e.type) {
                    case ws::Event::Type::Text:
                        if (route == "/echo" || route == "/greet" || route == "/headers" || route == "/fragments" ||
                            route == "/big")
                            static_cast<void>(session.send_text(e.data));
                        break;
                    case ws::Event::Type::Binary:
                        if (route == "/echo" || route == "/greet" || route == "/headers" || route == "/fragments" ||
                            route == "/big")
                            static_cast<void>(session.send_binary(e.data.data(), e.data.size()));
                        break;
                    case ws::Event::Type::Pong: ++pongs_; break;
                    case ws::Event::Type::Close: {
                        std::lock_guard<std::mutex> lock(mutex_);
                        closeCodes_.push_back(e.code);
                        break;
                    }
                    default: break;
                }
            }
            events.clear();
            if (!flush()) return finish("writing to the client failed");
            if (session.done())
                return finish(session.close_received() ? "the closing handshake completed"
                                                       : "the server failed the session (protocol error)");
            const int n = read_some(c, buffer, kBufferSize, &why);
            if (n < 0) return finish(why);
            if (n > 0) feed(buffer, static_cast<std::size_t>(n));
        }
        finish("the test ended with the connection open");
    }

    struct Worker {
        std::thread thread;
        std::shared_ptr<std::atomic<bool>> done;  // set by the thread as its last step: joining it then is quick
    };

    bool ipv6_ = false;
    Socket listener_ = kBad;
    int port_ = 0;
#ifdef _WIN32
    bool wsaStarted_ = false;
#endif
    std::atomic<bool> stop_{false};
    std::atomic<int> connections_{0}, handshakes_{0}, pongs_{0}, finished_{0};
    mutable std::mutex mutex_;
    std::vector<Worker> workers_;
    std::vector<int> closeCodes_;
    std::vector<std::shared_ptr<ConnectionLog>> logs_;  // the last kMaxLogs connections, oldest first
    std::map<std::string, std::string> lastHeaders_;
    std::thread thread_;
};

}  // namespace fa::test
