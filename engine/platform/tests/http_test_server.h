// A tiny HTTP/1.1 server that listens on the loopback address only (127.0.0.1, an ephemeral port), for the tests of the system
// HTTP clients. It never accepts a connection from another machine and the tests never leave the computer.
//
// Routes (every response carries "Connection: close"):
//   GET  /hello            200  "hello"            headers X-Test: yes, Set-Cookie twice
//   HEAD /hello            200  no body            Content-Length: 5
//   *    /echo             200  JSON {method, path, headers{lower-case}, body} of what arrived
//   GET  /status/<n>       <n>  "status <n>"
//   GET  /redirect-http    302  Location: http://127.0.0.1:<port>/hello (a redirect to plain http: clients refuse it)
//   GET  /chunked          200  "abcdef" as chunked transfer encoding
//   GET  /big              200  200000 bytes of 'x'
//   GET  /slow             200  "late", after 1.5 seconds
//   GET  /binary           200  the bytes 'a' 0xFF 'b' (not UTF-8)
//   anything else          404
#pragma once

#include <atomic>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <map>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/json.h"

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

class HttpTestServer {
public:
#ifdef _WIN32
    using Socket = SOCKET;
    static constexpr Socket kBad = INVALID_SOCKET;
#else
    using Socket = int;
    static constexpr Socket kBad = -1;
#endif

    HttpTestServer() {
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
    ~HttpTestServer() {
        stop_ = true;
        if (listener_ != kBad) {
            // Wake accept(): connect to ourselves once.
            Socket s = ::socket(AF_INET, SOCK_STREAM, 0);
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
    HttpTestServer(const HttpTestServer&) = delete;
    HttpTestServer& operator=(const HttpTestServer&) = delete;

    bool ok() const { return port_ != 0; }
    int port() const { return port_; }
    std::string url(const std::string& path, const std::string& host = "127.0.0.1") const { return "http://" + host + ":" + std::to_string(port_) + path; }
    int requests() const { return requests_.load(); }

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
            std::lock_guard<std::mutex> lock(mutex_);
            workers_.emplace_back([this, c] { serve(c); });
        }
    }

    struct Request {
        std::string method, path, body;
        std::map<std::string, std::string> headers;  // lower-case names
    };

    static std::string lower(std::string s) {
        for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        return s;
    }

    bool read_request(Socket c, Request& out) {
        std::string data;
        char buffer[4096];
        std::size_t headerEnd = std::string::npos;
        while (headerEnd == std::string::npos) {
            const auto n = ::recv(c, buffer, sizeof(buffer), 0);
            if (n <= 0) return false;
            data.append(buffer, static_cast<std::size_t>(n));
            headerEnd = data.find("\r\n\r\n");
            if (data.size() > 1 << 20) return false;
        }
        const std::string head = data.substr(0, headerEnd);
        std::string body = data.substr(headerEnd + 4);
        std::size_t lineEnd = head.find("\r\n");
        const std::string first = head.substr(0, lineEnd);
        const std::size_t sp1 = first.find(' '), sp2 = first.find(' ', sp1 + 1);
        if (sp1 == std::string::npos || sp2 == std::string::npos) return false;
        out.method = first.substr(0, sp1);
        out.path = first.substr(sp1 + 1, sp2 - sp1 - 1);
        while (lineEnd != std::string::npos) {
            const std::size_t start = lineEnd + 2;
            lineEnd = head.find("\r\n", start);
            const std::string line = head.substr(start, lineEnd == std::string::npos ? std::string::npos : lineEnd - start);
            const std::size_t colon = line.find(':');
            if (colon == std::string::npos) continue;
            std::string value = line.substr(colon + 1);
            while (!value.empty() && value.front() == ' ') value.erase(value.begin());
            out.headers[lower(line.substr(0, colon))] = value;
        }
        std::size_t want = 0;
        if (auto it = out.headers.find("content-length"); it != out.headers.end()) want = static_cast<std::size_t>(std::stoul(it->second));
        while (body.size() < want) {
            const auto n = ::recv(c, buffer, sizeof(buffer), 0);
            if (n <= 0) return false;
            body.append(buffer, static_cast<std::size_t>(n));
        }
        out.body = body.substr(0, want);
        return true;
    }

    static void send_all(Socket c, const std::string& data) {
        std::size_t sent = 0;
        while (sent < data.size()) {
            const auto n = ::send(c, data.data() + sent, static_cast<int>(data.size() - sent), 0);
            if (n <= 0) return;
            sent += static_cast<std::size_t>(n);
        }
    }

    static std::string response(int status, const std::string& reason, const std::string& body, const std::string& extra = {}, bool length = true) {
        std::string r = "HTTP/1.1 " + std::to_string(status) + " " + reason + "\r\n" + extra + "Connection: close\r\n";
        if (length) r += "Content-Length: " + std::to_string(body.size()) + "\r\n";
        return r + "\r\n" + body;
    }

    void serve(Socket c) {
        Request req;
        if (read_request(c, req)) {
            ++requests_;
            std::string out;
            const std::string full = req.path;  // with the query: /echo answers it
            req.path = full.substr(0, full.find('?'));
            if (req.path == "/hello" && req.method == "GET") {
                out = response(200, "OK", "hello", "X-Test: yes\r\nContent-Type: text/plain; charset=utf-8\r\nSet-Cookie: a=1\r\nSet-Cookie: b=2\r\n");
            } else if (req.path == "/hello" && req.method == "HEAD") {
                out = "HTTP/1.1 200 OK\r\nContent-Length: 5\r\nConnection: close\r\n\r\n";
            } else if (req.path == "/echo") {
                Json headers = Json::object();
                for (const auto& [k, v] : req.headers) headers[k] = v;
                const Json body = Json::object({{"method", req.method}, {"path", full}, {"headers", headers}, {"body", req.body}});
                out = response(200, "OK", body.dump(), "Content-Type: application/json\r\n");
            } else if (req.path.rfind("/status/", 0) == 0) {
                const int status = std::stoi(req.path.substr(8));
                out = response(status, "Status", "status " + std::to_string(status));
            } else if (req.path == "/redirect-http") {
                out = response(302, "Found", "", "Location: http://127.0.0.1:" + std::to_string(port_) + "/hello\r\n");
            } else if (req.path == "/chunked") {
                out = response(200, "OK", "3\r\nabc\r\n3\r\ndef\r\n0\r\n\r\n", "Transfer-Encoding: chunked\r\n", false);
            } else if (req.path == "/big") {
                out = response(200, "OK", std::string(200000, 'x'));
            } else if (req.path == "/slow") {
                std::this_thread::sleep_for(std::chrono::milliseconds(1500));
                out = response(200, "OK", "late");
            } else if (req.path == "/binary") {
                out = response(200, "OK", std::string("a\xFF" "b"));
            } else {
                out = response(404, "Not Found", "no route");
            }
            send_all(c, out);
        }
        close_socket(c);
    }

    Socket listener_ = kBad;
    int port_ = 0;
    std::atomic<bool> stop_{false};
    std::atomic<int> requests_{0};
    std::thread thread_;
    std::mutex mutex_;
    std::vector<std::thread> workers_;
};

}  // namespace fa::test
