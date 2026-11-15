// A WebSocket server for the tests of the clients (fa/platform/websocket.h), on the loopback address only (127.0.0.1, an
// ephemeral port): it never accepts a connection from another machine. It is built on the codec of
// fa/platform/websocket_codec.h, one thread per connection, and ends by itself: the destructor stops the accept loop, every
// connection thread notices within 100 ms and is joined, so no thread or socket outlives the test.
//
// Routes (the path of the address; "?x=1" arguments where listed):
//   /echo              answers every text and binary message with the same message; pings are answered, a close is answered
//   /greet             sends the text "hello" and the binary 01 02 03 right after the handshake, then echoes
//   /protocol          chooses the first subprotocol the client offered, then sends it as a text message ("none" when none)
//   /headers           sends the request's headers as a JSON text {"name": "value"} (lower-case names), then echoes
//   /close?code=4001&reason=bye   sends a close frame at once and waits for the client's answer
//   /drop              closes the TCP connection right after the handshake, with no close frame
//   /refuse?status=403 answers the handshake with that HTTP status (default 403) and closes
//   /badaccept         answers 101 with a wrong Sec-WebSocket-Accept
//   /silent            completes the handshake and then says nothing at all (keeps reading and ignoring)
//   /fragments         sends "Hello" as the text fragments "Hel" + ping + "lo", then echoes
//   /big?n=100000      sends one text message of n 'x' characters, then echoes
//   /badutf8           sends a text frame that is not valid UTF-8
//   /badrsv            sends a frame with a reserved bit set
//   /ping              sends a ping "hi" after the handshake; pongs received are counted (pongs())
//   anything else      404 and closes
#pragma once

#include <atomic>
#include <cerrno>
#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <map>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/json.h"
#include "fa/platform/websocket_codec.h"

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <arpa/inet.h>
#include <netinet/in.h>
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

    WsTestServer() {
#ifdef _WIN32
        WSADATA data;
        WSAStartup(MAKEWORD(2, 2), &data);
#endif
        listener_ = ::socket(AF_INET, SOCK_STREAM, 0);
        if (listener_ == kBad) return;
        sockaddr_in addr{};
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);  // loopback only
        addr.sin_port = 0;
        if (::bind(listener_, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0 || ::listen(listener_, 16) != 0) {
            close_socket(listener_);
            listener_ = kBad;
            return;
        }
        socklen_t length = sizeof(addr);
        ::getsockname(listener_, reinterpret_cast<sockaddr*>(&addr), &length);
        port_ = ntohs(addr.sin_port);
        thread_ = std::thread([this] { accept_loop(); });
    }
    ~WsTestServer() {
        stop_ = true;
        if (listener_ != kBad) {
            Socket s = ::socket(AF_INET, SOCK_STREAM, 0);  // wake accept(): connect to ourselves once
            if (s != kBad) {
                sockaddr_in addr{};
                addr.sin_family = AF_INET;
                addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
                addr.sin_port = htons(static_cast<std::uint16_t>(port_));
                ::connect(s, reinterpret_cast<sockaddr*>(&addr), sizeof(addr));
                close_socket(s);
            }
        }
        if (thread_.joinable()) thread_.join();
        {
            std::lock_guard<std::mutex> lock(mutex_);
            for (std::thread& t : workers_)
                if (t.joinable()) t.join();
        }
        if (listener_ != kBad) close_socket(listener_);
#ifdef _WIN32
        WSACleanup();
#endif
    }
    WsTestServer(const WsTestServer&) = delete;
    WsTestServer& operator=(const WsTestServer&) = delete;

    bool ok() const { return port_ != 0; }
    int port() const { return port_; }
    std::string url(const std::string& path, const std::string& host = "127.0.0.1") const {
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

private:
    static void close_socket(Socket s) {
#ifdef _WIN32
        ::closesocket(s);
#else
        ::close(s);
#endif
    }

    void accept_loop() {
        while (!stop_) {
            Socket c = ::accept(listener_, nullptr, nullptr);
            if (c == kBad) continue;
            if (stop_) {
                close_socket(c);
                break;
            }
            ++connections_;
            // A short receive timeout lets every thread look at stop_ and end by itself.
#ifdef _WIN32
            DWORD ms = 100;
            ::setsockopt(c, SOL_SOCKET, SO_RCVTIMEO, reinterpret_cast<const char*>(&ms), sizeof(ms));
#else
            timeval tv{0, 100 * 1000};
            ::setsockopt(c, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
#ifdef SO_NOSIGPIPE
            const int one = 1;
            ::setsockopt(c, SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof(one));
#endif
#endif
            std::lock_guard<std::mutex> lock(mutex_);
            workers_.emplace_back([this, c] {
                serve(c);
                close_socket(c);
                ++finished_;
            });
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

    // -1: the peer closed or an error; 0: timeout (nothing yet); n > 0: bytes
    static int read_some(Socket c, char* buffer, int size) {
        const auto n = ::recv(c, buffer, size, 0);
        if (n > 0) return static_cast<int>(n);
        if (n == 0) return -1;
#ifdef _WIN32
        const int err = WSAGetLastError();
        return (err == WSAETIMEDOUT || err == WSAEWOULDBLOCK) ? 0 : -1;
#else
        return (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) ? 0 : -1;
#endif
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

    void serve(Socket c) {
        // The head of the request.
        std::string data;
        std::size_t headEnd = std::string::npos;
        char buffer[4096];
        while (headEnd == std::string::npos && !stop_) {
            const int n = read_some(c, buffer, sizeof(buffer));
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

        if (route == "/refuse") {
            const int status = query.count("status") ? std::atoi(query.at("status").c_str()) : 403;
            write_all(c, ws::build_reject_response(status, status == 403 ? "Forbidden" : "Refused"));
            return;
        }
        if (route != "/echo" && route != "/greet" && route != "/protocol" && route != "/headers" && route != "/close" &&
            route != "/drop" && route != "/badaccept" && route != "/silent" && route != "/fragments" &&
            route != "/big" && route != "/badutf8" && route != "/badrsv" && route != "/ping") {
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
        if (!write_all(c, response)) return;
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
            if (!write_all(c, out)) return;
        } else if (route == "/big") {
            const std::size_t n = query.count("n") ? static_cast<std::size_t>(std::atoll(query.at("n").c_str())) : 1000;
            static_cast<void>(session.send_text(std::string(n, 'x')));
        } else if (route == "/badutf8") {
            if (!write_all(c, ws::encode_frame(ws::Opcode::Text, "\xff\xfe", true, nullptr))) return;
        } else if (route == "/badrsv") {
            std::string frame = ws::encode_frame(ws::Opcode::Text, "x", true, nullptr);
            frame[0] = static_cast<char>(frame[0] | 0x40);
            if (!write_all(c, frame)) return;
        } else if (route == "/ping") {
            static_cast<void>(session.send_ping("hi"));
        }
        if (!flush()) return;

        std::vector<ws::Event> events;
        if (!leftover.empty()) session.feed(leftover.data(), leftover.size(), events);
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
            if (!flush()) return;
            if (session.done()) return;
            const int n = read_some(c, buffer, sizeof(buffer));
            if (n < 0) return;
            if (n > 0) session.feed(buffer, static_cast<std::size_t>(n), events);
        }
    }

    Socket listener_ = kBad;
    int port_ = 0;
    std::atomic<bool> stop_{false};
    std::atomic<int> connections_{0}, handshakes_{0}, pongs_{0}, finished_{0};
    mutable std::mutex mutex_;
    std::vector<std::thread> workers_;
    std::vector<int> closeCodes_;
    std::map<std::string, std::string> lastHeaders_;
    std::thread thread_;
};

}  // namespace fa::test
