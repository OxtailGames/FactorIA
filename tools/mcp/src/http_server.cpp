#include "fa/mcp/http_server.h"

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX  // MinGW: winsock2.h includes windows.h, whose min/max macros break std::min
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
#endif

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <future>
#include <map>
#include <mutex>
#include <random>
#include <thread>
#include <vector>

#include "fa/core/strings.h"

namespace fa {

namespace {

#ifdef _WIN32
using Socket = SOCKET;
using IoLen = int;
constexpr Socket kNoSocket = INVALID_SOCKET;
constexpr int kShutBoth = SD_BOTH;
void close_socket(Socket s) { ::closesocket(s); }
#else
using Socket = int;
using IoLen = std::size_t;
constexpr Socket kNoSocket = -1;
constexpr int kShutBoth = SHUT_RDWR;
void close_socket(Socket s) { ::close(s); }
#endif
#ifdef MSG_NOSIGNAL
constexpr int kSendFlags = MSG_NOSIGNAL;  // a closed peer must not raise SIGPIPE (macOS sets SO_NOSIGPIPE instead)
#else
constexpr int kSendFlags = 0;
#endif

constexpr std::size_t kMaxHeader = 64 * 1024;
constexpr std::size_t kMaxBody = 64 * 1024 * 1024;  // a tool call carrying a whole file or picture still fits

bool send_all(Socket s, std::string_view data) {
    while (!data.empty()) {
        const auto n = ::send(s, data.data(), static_cast<IoLen>(std::min<std::size_t>(data.size(), 1 << 20)), kSendFlags);
        if (n <= 0) return false;
        data.remove_prefix(static_cast<std::size_t>(n));
    }
    return true;
}

bool receive(Socket s, std::string& buf) {  // false when the peer closed, or stop() shut the socket
    char chunk[16384];
    const auto n = ::recv(s, chunk, static_cast<IoLen>(sizeof chunk), 0);
    if (n <= 0) return false;
    buf.append(chunk, static_cast<std::size_t>(n));
    return true;
}

// Sends one response; returns whether the connection stays open.
bool reply(Socket s, int status, const char* reason, const std::string& body, bool keepAlive, const char* extra = "") {
    std::string out = "HTTP/1.1 " + std::to_string(status) + " " + reason + "\r\n";
    if (!body.empty()) out += "Content-Type: application/json\r\n";
    out += "Content-Length: " + std::to_string(body.size()) + "\r\n";
    out += extra;
    if (!keepAlive) out += "Connection: close\r\n";
    out += "\r\n" + body;
    return send_all(s, out) && keepAlive;
}

std::string random_token() {
    std::random_device rd;  // not simulation state: a secret for the endpoint's path
    char hex[33];
    for (int i = 0; i < 4; ++i) std::snprintf(hex + i * 8, 9, "%08x", static_cast<unsigned>(rd()));
    return std::string(hex, 32);
}

}  // namespace

struct McpHttpServer::Impl {
    Handler handler;
    std::chrono::milliseconds streamAfter{};
    std::string url, path;
    Socket listener = kNoSocket;
    sockaddr_in addr{};
    std::thread acceptThread;
    std::mutex mu;  // guards everything below
    bool stopping = false;
    std::vector<Socket> clients;
    std::vector<std::thread> threads;

    void accept_loop() {
        for (;;) {
            Socket c = ::accept(listener, nullptr, nullptr);
            std::unique_lock<std::mutex> lock(mu);
            if (stopping) {
                if (c != kNoSocket) close_socket(c);
                return;
            }
            if (c == kNoSocket) {  // e.g. out of file descriptors: try again shortly
                lock.unlock();
                std::this_thread::sleep_for(std::chrono::milliseconds(50));
                continue;
            }
#ifdef SO_NOSIGPIPE
            int one = 1;
            setsockopt(c, SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof one);
#endif
            clients.push_back(c);
            // ponytail: one thread per connection, joined at stop(); a CLI keeps a few connections alive per run.
            threads.emplace_back([this, c] {
                std::string buf;
                while (serve_one(c, buf)) {
                }
                {
                    std::lock_guard<std::mutex> lock(mu);
                    clients.erase(std::find(clients.begin(), clients.end(), c));  // stop() must not touch it any more
                }
                close_socket(c);
            });
        }
    }

    // Reads and answers one request (HTTP/1.1, keep-alive); false when the connection is done.
    bool serve_one(Socket c, std::string& buf) {
        std::size_t headEnd;
        while ((headEnd = buf.find("\r\n\r\n")) == std::string::npos) {
            if (buf.size() > kMaxHeader) return reply(c, 431, "Request Header Fields Too Large", "", false);
            if (!receive(c, buf)) return false;
        }
        const std::vector<std::string> lines = split(std::string_view(buf).substr(0, headEnd), '\n');
        const std::vector<std::string> request = lines.empty() ? std::vector<std::string>{} : split(trim(lines[0]), ' ');
        if (request.size() != 3) return reply(c, 400, "Bad Request", "", false);
        std::map<std::string, std::string> headers;  // lowercase names
        for (std::size_t i = 1; i < lines.size(); ++i) {
            if (const auto colon = lines[i].find(':'); colon != std::string::npos)
                headers[to_lower(lines[i].substr(0, colon))] = std::string(trim(std::string_view(lines[i]).substr(colon + 1)));
        }
        const std::string& method = request[0];
        if (request[1] != path) return reply(c, 404, "Not Found", "", false);
        if (method != "POST") return reply(c, 405, "Method Not Allowed", "", false, "Allow: POST\r\n");  // no SSE stream, no session
        const auto len = headers.find("content-length");
        if (len == headers.end()) return reply(c, 411, "Length Required", "", false);
        const std::size_t size = std::strtoull(len->second.c_str(), nullptr, 10);
        if (size > kMaxBody) return reply(c, 413, "Content Too Large", "", false);
        if (iequals(headers["expect"], "100-continue") && !send_all(c, "HTTP/1.1 100 Continue\r\n\r\n")) return false;
        const std::size_t bodyAt = headEnd + 4;
        while (buf.size() < bodyAt + size) {
            if (!receive(c, buf)) return false;
        }
        const std::string body = buf.substr(bodyAt, size);
        buf.erase(0, bodyAt + size);
        const bool keepAlive = !iequals(headers["connection"], "close");
        // A tool call can run for minutes (ai_run hands a whole task to the worker), longer than an HTTP client waits
        // for an answer (fetch gives up after 5 idle minutes). So a call still running after `streamAfter` is answered
        // as an event stream at once, kept alive with a comment line every 15 s until its reply is ready.
        auto pending = std::async(std::launch::async, [&] { return handler(body); });
        if (pending.wait_for(streamAfter) == std::future_status::timeout &&
            headers["accept"].find("text/event-stream") != std::string::npos) {
            bool open = send_all(c, "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache\r\n"
                                    "Connection: close\r\n\r\n");
            while (open && pending.wait_for(std::chrono::seconds(15)) == std::future_status::timeout)
                open = send_all(c, ": working\n\n");
            const std::optional<std::string> response = pending.get();  // stop() needs the handler done anyway
            if (open && response) send_all(c, "event: message\ndata: " + std::string(trim(*response)) + "\n\n");
            return false;  // the stream ends with the connection
        }
        const std::optional<std::string> response = pending.get();
        if (!response) return reply(c, 202, "Accepted", "", keepAlive);
        return reply(c, 200, "OK", *response, keepAlive);
    }
};

McpHttpServer::McpHttpServer() : impl_(std::make_unique<Impl>()) {}
McpHttpServer::~McpHttpServer() { stop(); }

const std::string& McpHttpServer::url() const { return impl_->url; }

Result<std::string> McpHttpServer::start(Handler handler, std::chrono::milliseconds streamAfter) {
    stop();
#ifdef _WIN32
    WSADATA wsa;
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0)
        return make_error("Cannot start the editor's MCP endpoint: Windows sockets (WSAStartup) are unavailable.",
                          "Restart the editor; if it keeps failing, check that the network stack is installed.");
#endif
    auto fail = [this](const std::string& what) -> Result<std::string> {
        if (impl_->listener != kNoSocket) close_socket(impl_->listener);
        impl_->listener = kNoSocket;
#ifdef _WIN32
        WSACleanup();
#endif
        return make_error("Cannot start the editor's MCP endpoint on 127.0.0.1: " + what + " failed.",
                          "Another program may be blocking local connections (firewall, security software). "
                          "Allow loopback connections for the editor, then send the message again.");
    };
    Impl& m = *impl_;
    m.listener = ::socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (m.listener == kNoSocket) return fail("socket()");
    m.addr = {};
    m.addr.sin_family = AF_INET;
    m.addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    m.addr.sin_port = 0;  // any free port
    if (::bind(m.listener, reinterpret_cast<sockaddr*>(&m.addr), sizeof m.addr) != 0) return fail("bind()");
    socklen_t addrLen = sizeof m.addr;
    if (::getsockname(m.listener, reinterpret_cast<sockaddr*>(&m.addr), &addrLen) != 0) return fail("getsockname()");
    if (::listen(m.listener, 16) != 0) return fail("listen()");
    m.handler = std::move(handler);
    m.streamAfter = streamAfter;
    m.path = "/mcp/" + random_token();
    m.url = "http://127.0.0.1:" + std::to_string(ntohs(m.addr.sin_port)) + m.path;
    m.stopping = false;
    m.acceptThread = std::thread([&m] { m.accept_loop(); });
    return m.url;
}

void McpHttpServer::stop() {
    Impl& m = *impl_;
    if (!m.acceptThread.joinable()) return;
    {
        std::lock_guard<std::mutex> lock(m.mu);
        m.stopping = true;
        for (Socket c : m.clients) ::shutdown(c, kShutBoth);  // wakes the connection threads blocked in recv()
    }
    // Wake accept(): shutdown() does on Linux, a connection does everywhere (it sees `stopping` and returns).
    ::shutdown(m.listener, kShutBoth);
    if (Socket wake = ::socket(AF_INET, SOCK_STREAM, IPPROTO_TCP); wake != kNoSocket) {
        (void)::connect(wake, reinterpret_cast<sockaddr*>(&m.addr), sizeof m.addr);
        close_socket(wake);
    }
    m.acceptThread.join();
    for (std::thread& t : m.threads) t.join();  // each closes its own socket
    close_socket(m.listener);
    m.listener = kNoSocket;
    m.threads.clear();
    m.url.clear();
    m.path.clear();
    m.handler = nullptr;
#ifdef _WIN32
    WSACleanup();
#endif
}

}  // namespace fa
