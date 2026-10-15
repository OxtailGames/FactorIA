// HTTP client tests against a loopback server (no external network).
#ifndef _WIN32
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

#include <atomic>
#include <chrono>
#include <thread>

#include "fa/ai/http.h"
#include "fa/ai/process.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {

// One-connection-at-a-time HTTP server: records the raw request, replies with a canned response.
class LoopbackServer {
public:
    explicit LoopbackServer(std::vector<std::string> chunks, int sleepMs = 0) : chunks_(std::move(chunks)), sleepMs_(sleepMs) {
        fd_ = ::socket(AF_INET, SOCK_STREAM, 0);
        int one = 1;
        setsockopt(fd_, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
        sockaddr_in addr{};
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
        addr.sin_port = 0;
        REQUIRE(::bind(fd_, reinterpret_cast<sockaddr*>(&addr), sizeof addr) == 0);
        socklen_t len = sizeof addr;
        getsockname(fd_, reinterpret_cast<sockaddr*>(&addr), &len);
        port_ = ntohs(addr.sin_port);
        REQUIRE(::listen(fd_, 4) == 0);
        thread_ = std::thread([this] { serve(); });
    }
    ~LoopbackServer() {
        stop_ = true;
        ::shutdown(fd_, SHUT_RDWR);
        ::close(fd_);
        if (thread_.joinable()) thread_.join();
    }
    std::string url(const std::string& path = "/v1/messages") const { return "http://127.0.0.1:" + std::to_string(port_) + path; }
    std::string request() {
        std::lock_guard<std::mutex> l(m_);
        return request_;
    }

private:
    void serve() {
        while (!stop_) {
            int c = ::accept(fd_, nullptr, nullptr);
            if (c < 0) return;
            std::string req;
            char buf[4096];
            std::size_t headerEnd = std::string::npos, want = 0;
            while (true) {
                ssize_t n = ::recv(c, buf, sizeof buf, 0);
                if (n <= 0) break;
                req.append(buf, static_cast<std::size_t>(n));
                if (headerEnd == std::string::npos) {
                    headerEnd = req.find("\r\n\r\n");
                    if (headerEnd != std::string::npos) {
                        auto cl = req.find("ontent-Length: ");
                        std::size_t len = cl == std::string::npos ? 0 : std::stoul(req.substr(cl + 15));
                        want = headerEnd + 4 + len;
                    }
                }
                if (headerEnd != std::string::npos && req.size() >= want) break;
            }
            { std::lock_guard<std::mutex> l(m_); request_ = req; }
            for (std::size_t i = 0; i < chunks_.size(); ++i) {
                ::send(c, chunks_[i].data(), chunks_[i].size(), MSG_NOSIGNAL);
                if (sleepMs_ > 0 && i + 1 < chunks_.size()) std::this_thread::sleep_for(std::chrono::milliseconds(sleepMs_));
            }
            ::close(c);
        }
    }
    int fd_ = -1;
    int port_ = 0;
    std::vector<std::string> chunks_;
    int sleepMs_;
    std::atomic<bool> stop_{false};
    std::thread thread_;
    std::mutex m_;
    std::string request_;
};

HttpRequest post(const std::string& url) {
    HttpRequest r;
    r.url = url;
    r.headers = {{"content-type", "application/json"}, {"x-api-key", "secret-key"}, {"anthropic-version", "2023-06-01"}};
    r.body = R"({"hello":"world"})";
    r.timeoutSeconds = 20;
    r.connectTimeoutSeconds = 5;
    return r;
}

using Backend = HttpResponse (*)(const HttpRequest&);

void check_backend(Backend send, const char* name) {
    INFO("backend: " << name);
    {  // plain JSON response + request fidelity
        std::string body = R"({"ok":true})";
        LoopbackServer srv({"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nX-Test: yes\r\nContent-Length: " +
                            std::to_string(body.size()) + "\r\nConnection: close\r\n\r\n" + body});
        auto resp = send(post(srv.url()));
        CHECK(resp.status == 200);
        CHECK(resp.body == body);
        CHECK(resp.header("x-test") == "yes");
        std::string req = srv.request();
        CHECK(req.rfind("POST /v1/messages HTTP/1.1", 0) == 0);
        CHECK(req.find("x-api-key: secret-key") != std::string::npos);
        CHECK(req.find("anthropic-version: 2023-06-01") != std::string::npos);
        CHECK(req.find(R"({"hello":"world"})") != std::string::npos);
    }
    {  // error status keeps the body and headers
        std::string body = R"({"error":{"type":"rate_limit_error"}})";
        LoopbackServer srv({"HTTP/1.1 429 Too Many Requests\r\nRetry-After: 3\r\nContent-Length: " + std::to_string(body.size()) +
                            "\r\nConnection: close\r\n\r\n" + body});
        HttpRequest rq = post(srv.url());
        std::string streamed;
        rq.onData = [&](std::string_view c) { streamed += c; return true; };  // not called for non-2xx
        auto resp = send(rq);
        CHECK(resp.status == 429);
        CHECK(resp.body == body);
        CHECK(streamed.empty());
        CHECK(parse_retry_after(resp.header("retry-after")) == 3.0);
    }
    {  // streaming body delivered incrementally
        std::string head = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nConnection: close\r\n\r\n";
        LoopbackServer srv({head, "data: one\n\n", "data: two\n\n", "data: three\n\n"}, 80);
        HttpRequest rq = post(srv.url());
        std::vector<std::string> chunks;
        rq.onData = [&](std::string_view c) { chunks.emplace_back(c); return true; };
        auto resp = send(rq);
        CHECK(resp.status == 200);
        CHECK(resp.body.empty());
        std::string all;
        for (auto& c : chunks) all += c;
        CHECK(all == "data: one\n\ndata: two\n\ndata: three\n\n");
        CHECK(chunks.size() >= 2);
    }
    {  // cancellation
        std::string head = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nConnection: close\r\n\r\n";
        LoopbackServer srv({head, "data: one\n\n", "data: two\n\n", "data: three\n\n", "data: four\n\n"}, 400);
        CancelFlag cancel{false};
        HttpRequest rq = post(srv.url());
        rq.cancel = &cancel;
        rq.onData = [&](std::string_view) { cancel = true; return true; };
        auto t0 = std::chrono::steady_clock::now();
        auto resp = send(rq);
        CHECK(resp.cancelled);
        CHECK(std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < 5);
    }
    {  // redirects are followed (release downloads redirect to a CDN)
        std::string body = "package bytes";
        LoopbackServer target({"HTTP/1.1 200 OK\r\nContent-Length: " + std::to_string(body.size()) +
                               "\r\nConnection: close\r\n\r\n" + body});
        LoopbackServer srv({"HTTP/1.1 302 Found\r\nLocation: " + target.url("/pkg") +
                            "\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"});
        HttpRequest rq;
        rq.method = "GET";
        rq.url = srv.url("/latest");
        rq.timeoutSeconds = 20;
        std::string streamed;
        rq.onData = [&](std::string_view c) { streamed += c; return true; };
        auto resp = send(rq);
        CHECK(resp.status == 200);
        CHECK(streamed == body);
        CHECK(target.request().rfind("GET /pkg HTTP/1.1", 0) == 0);
    }
    {  // connection refused is a transport error with a message
        HttpRequest rq = post("http://127.0.0.1:1/x");
        rq.connectTimeoutSeconds = 2;
        auto resp = send(rq);
        CHECK(resp.status == 0);
        CHECK_FALSE(resp.error.empty());
    }
}

}  // namespace

TEST_CASE("http client (default backend) against a loopback server") { check_backend(http_request, "default"); }

TEST_CASE("http client (curl executable fallback) against a loopback server") {
    if (which("curl").empty()) { MESSAGE("curl executable not installed; skipped"); return; }
    check_backend(http_request_curl_exe, "curl-exe");
}

TEST_CASE("retry-after parsing") {
    CHECK(parse_retry_after("7") == 7.0);
    CHECK(parse_retry_after(" 2.5 ") == 2.5);
    CHECK(parse_retry_after("Wed, 21 Oct 2026 07:28:00 GMT") == 0.0);
    CHECK(parse_retry_after("") == 0.0);
}
#endif
