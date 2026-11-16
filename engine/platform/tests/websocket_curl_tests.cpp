// The libcurl WebSocket client (make_curl_websocket_client, Linux's client) against the loopback server of ws_test_server.h.
// It runs wherever libcurl can be loaded (Linux CI, macOS's own libcurl); without one every case says so and passes.
// Nothing here reaches another machine.
#include <doctest.h>

#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

#include <chrono>
#include <cstdint>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#include "fa/core/json.h"
#include "fa/platform/websocket.h"
#include "ws_test_server.h"

using namespace fa;

namespace {

using Clock = std::chrono::steady_clock;

// The client, or null (with a message) on a machine whose libcurl cannot open WebSockets.
std::unique_ptr<WebSocketClient> curl_client() {
    auto client = make_curl_websocket_client();
    REQUIRE(client);
    CHECK(client->name() == "curl");
    if (!client->available()) {
        CHECK_FALSE(client->unavailable_reason().empty());
        WebSocketRequest r;
        r.url = "ws://127.0.0.1:1/";
        auto ws = client->connect(r);
        REQUIRE_FALSE(ws.ok());
        CHECK_FALSE(ws.error().hint.empty());
        MESSAGE("skipped: the curl WebSocket client is not available here: " << client->unavailable_reason());
        return nullptr;
    }
    return client;
}

// Polls until `want` events have arrived or the safety net (30 s, far above a loopback round trip) ends.
std::vector<WebSocketEvent> collect(WebSocket& ws, std::size_t want, int maxMs = 30000) {
    std::vector<WebSocketEvent> events;
    const auto end = Clock::now() + std::chrono::milliseconds(maxMs);
    while (events.size() < want && Clock::now() < end) {
        if (ws.poll(events) == 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
    }
    return events;
}

// Until a Close event arrives (what is before it is kept).
std::vector<WebSocketEvent> collect_until_close(WebSocket& ws, int maxMs = 30000) {
    std::vector<WebSocketEvent> events;
    const auto end = Clock::now() + std::chrono::milliseconds(maxMs);
    while (Clock::now() < end) {
        if (ws.poll(events) == 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        if (!events.empty() && events.back().type == WebSocketEvent::Type::Close) break;
    }
    return events;
}

std::unique_ptr<WebSocket> open(WebSocketClient& client, const std::string& url, std::vector<std::string> sub = {},
                                std::vector<std::pair<std::string, std::string>> headers = {}) {
    WebSocketRequest r;
    r.url = url;
    r.subprotocols = std::move(sub);
    r.headers = std::move(headers);
    auto ws = client.connect(r);
    REQUIRE(ws.ok());
    return std::move(ws.value());
}

// A loopback port whose kernel completes TCP connections that nobody accepts or answers: a server stuck in the handshake.
class SilentListener {
public:
    SilentListener() {
        fd_ = ::socket(AF_INET, SOCK_STREAM, 0);
        if (fd_ < 0) return;
        sockaddr_in addr{};
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
        if (::bind(fd_, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0 || ::listen(fd_, 8) != 0) {
            ::close(fd_);
            fd_ = -1;
            return;
        }
        socklen_t length = sizeof(addr);
        ::getsockname(fd_, reinterpret_cast<sockaddr*>(&addr), &length);
        port_ = ntohs(addr.sin_port);
    }
    ~SilentListener() {
        if (fd_ >= 0) ::close(fd_);
    }
    SilentListener(const SilentListener&) = delete;
    SilentListener& operator=(const SilentListener&) = delete;
    bool ok() const { return port_ != 0; }
    std::string url() const { return "ws://127.0.0.1:" + std::to_string(port_) + "/"; }

private:
    int fd_ = -1;
    int port_ = 0;
};

}  // namespace

TEST_CASE("websocket curl: echo, binary, greeting, subprotocol and headers against the loopback server") {
    auto client = curl_client();
    if (!client) return;
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    {
        auto ws = open(*client, server.url("/echo"));
        auto events = collect(*ws, 1);
        REQUIRE(events.size() == 1);
        CHECK(events[0].type == WebSocketEvent::Type::Open);
        CHECK(ws->state() == WebSocketState::Open);
        REQUIRE(ws->send_text("hello").ok());
        REQUIRE(ws->send_binary("\x00\x01\xff", 3).ok());
        CHECK_FALSE(ws->send_text("\xff").ok());  // not UTF-8
        events = collect(*ws, 2);
        REQUIRE(events.size() == 2);
        CHECK(events[0].type == WebSocketEvent::Type::Text);
        CHECK(events[0].data == "hello");
        CHECK(events[1].type == WebSocketEvent::Type::Binary);
        CHECK(events[1].data == std::string("\x00\x01\xff", 3));
        CHECK(ws->close(1000, "bye").ok());
        CHECK(ws->close(1000, "twice").ok());  // closing twice is not an error
        events = collect_until_close(*ws);
        REQUIRE_FALSE(events.empty());
        CHECK(events.back().type == WebSocketEvent::Type::Close);
        CHECK(events.back().code == 1000);
        CHECK(events.back().wasClean);
        CHECK(ws->state() == WebSocketState::Closed);
        CHECK_FALSE(ws->send_text("late").ok());
    }
    {
        auto ws = open(*client, server.url("/greet"));
        auto events = collect(*ws, 3);
        REQUIRE(events.size() == 3);
        CHECK(events[1].data == "hello");
        CHECK(events[2].data == std::string("\x01\x02\x03", 3));
    }
    {
        auto ws = open(*client, server.url("/protocol"), {"one", "two"});
        auto events = collect(*ws, 2);
        REQUIRE(events.size() == 2);
        CHECK(events[0].subprotocol == "one");
        CHECK(events[1].data == "one");
    }
    {
        auto ws = open(*client, server.url("/headers"), {}, {{"X-Game-Token", "abc"}});
        auto events = collect(*ws, 2);
        REQUIRE(events.size() == 2);
        auto json = parse_json(events[1].data);
        REQUIRE(json.ok());
        CHECK(json.value().value("x-game-token", std::string()) == "abc");
        CHECK(json.value().value("upgrade", std::string()) == "websocket");
    }
}

TEST_CASE("websocket curl: close codes both ways, a dropped line, a refused or wrong handshake") {
    auto client = curl_client();
    if (!client) return;
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    {
        auto ws = open(*client, server.url("/close?code=4001&reason=bye"));
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() == 2);
        CHECK(events[1].code == 4001);
        CHECK(events[1].reason == "bye");
        CHECK(events[1].wasClean);
        CHECK(ws->state() == WebSocketState::Closed);
    }
    {
        auto ws = open(*client, server.url("/echo"));
        REQUIRE(collect(*ws, 1).size() == 1);
        CHECK(ws->close(4242, "custom").ok());
        CHECK(ws->state() == WebSocketState::Closing);
        auto events = collect_until_close(*ws);
        REQUIRE_FALSE(events.empty());
        CHECK(events.back().code == 4242);
        CHECK(events.back().reason == "custom");
        CHECK(events.back().wasClean);
        bool seen = false;
        for (int code : server.client_close_codes()) seen = seen || code == 4242;
        CHECK(seen);
    }
    {
        auto ws = open(*client, server.url("/drop"));
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() >= 2);
        CHECK(events[events.size() - 2].type == WebSocketEvent::Type::Error);
        CHECK(events.back().code == 1006);
        CHECK_FALSE(events.back().wasClean);
    }
    {
        auto ws = open(*client, server.url("/refuse?status=403"));
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() == 2);
        CHECK(events[0].type == WebSocketEvent::Type::Error);
        CHECK(events[0].httpStatus == 403);
        CHECK_FALSE(events[0].hint.empty());
        CHECK(events[1].code == 1006);
        CHECK(ws->state() == WebSocketState::Closed);
    }
    {
        auto ws = open(*client, server.url("/badaccept"));
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() == 2);
        CHECK(events[0].error.find("Sec-WebSocket-Accept") != std::string::npos);
    }
    {
        auto ws = open(*client, server.url("/nothing-here"));
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() == 2);
        CHECK(events[0].httpStatus == 404);
    }
}

TEST_CASE("websocket curl: fragments, big and too big messages, pings and bad frames") {
    auto client = curl_client();
    if (!client) return;
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    {
        auto ws = open(*client, server.url("/fragments"));
        auto events = collect(*ws, 2);
        REQUIRE(events.size() == 2);
        CHECK(events[1].data == "Hello");
    }
    {
        auto ws = open(*client, server.url("/big?n=300000"));
        auto events = collect(*ws, 2);
        REQUIRE(events.size() == 2);
        CHECK(events[1].data.size() == 300000);
        // The same message back: a send larger than one curl_easy_send call.
        REQUIRE(ws->send_text(events[1].data).ok());
        events = collect(*ws, 1);
        REQUIRE(events.size() == 1);
        CHECK(events[0].data.size() == 300000);
    }
    {
        // A message above the limit of this request fails the connection: Error, then Close 1006; the server is sent 1009.
        WebSocketRequest r;
        r.url = server.url("/big?n=5000");
        r.maxMessageBytes = 1000;
        auto small = client->connect(r).value();
        auto events = collect_until_close(*small);
        REQUIRE(events.size() >= 3);
        CHECK(events[events.size() - 2].type == WebSocketEvent::Type::Error);
        CHECK(events.back().code == 1006);
        CHECK_FALSE(events.back().wasClean);
        const auto end = Clock::now() + std::chrono::seconds(30);
        bool tooBig = false;
        while (!tooBig && Clock::now() < end) {
            for (int code : server.client_close_codes()) tooBig = tooBig || code == 1009;
            if (!tooBig) std::this_thread::sleep_for(std::chrono::milliseconds(5));
        }
        CHECK(tooBig);
    }
    {
        fa::test::WsTestServer pinger;  // its own server: /fragments also sends a ping
        REQUIRE(pinger.ok());
        auto ws = open(*client, pinger.url("/ping"));
        auto events = collect(*ws, 1);
        const auto end = Clock::now() + std::chrono::seconds(30);
        while (pinger.pongs() == 0 && Clock::now() < end) {
            ws->poll(events);
            std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        CHECK(pinger.pongs() == 1);  // answered once, by the client itself
    }
    {
        auto ws = open(*client, server.url("/badutf8"));
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() >= 3);
        CHECK(events[events.size() - 2].type == WebSocketEvent::Type::Error);
        CHECK(events.back().code == 1006);
    }
    {
        auto ws = open(*client, server.url("/badrsv"));
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() >= 3);
        CHECK(events.back().code == 1006);
    }
}

TEST_CASE("websocket curl: destroying a connection, open or connecting, does not wait and says goodbye") {
    auto client = curl_client();
    if (!client) return;
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    {
        auto ws = open(*client, server.url("/silent"));
        REQUIRE(collect(*ws, 1).size() == 1);
        const auto start = Clock::now();
        ws.reset();
        // Far above a few milliseconds so that a loaded VM passes, far below the 5 s close wait or a join on a stuck thread.
        CHECK(Clock::now() - start < std::chrono::seconds(2));
    }
    {
        SilentListener stuck;
        REQUIRE(stuck.ok());
        auto ws = open(*client, stuck.url());
        std::this_thread::sleep_for(std::chrono::milliseconds(50));  // most likely waiting for the handshake's answer
        const auto start = Clock::now();
        ws.reset();
        CHECK(Clock::now() - start < std::chrono::seconds(2));
    }
    // The open one said goodbye with 1001 (the server's own threads end by themselves).
    const auto end = Clock::now() + std::chrono::seconds(30);
    bool goodbye = false;
    while (!goodbye && Clock::now() < end) {
        for (int code : server.client_close_codes()) goodbye = goodbye || code == 1001;
        if (!goodbye) std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    CHECK(goodbye);
}

TEST_CASE("websocket curl: close() while connecting, the handshake timeout, and addresses it cannot reach") {
    auto client = curl_client();
    if (!client) return;
    SilentListener stuck;
    REQUIRE(stuck.ok());
    {
        auto ws = open(*client, stuck.url());
        CHECK(ws->state() == WebSocketState::Connecting);
        CHECK_FALSE(ws->send_text("early").ok());
        CHECK(ws->close(1000, "").ok());
        CHECK(ws->state() == WebSocketState::Closing);
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() == 2);
        CHECK(events[0].type == WebSocketEvent::Type::Error);
        CHECK_FALSE(events[0].hint.empty());
        CHECK(events[1].code == 1006);
        CHECK_FALSE(events[1].wasClean);
        CHECK(ws->state() == WebSocketState::Closed);
    }
    {
        WebSocketRequest r;
        r.url = stuck.url();
        r.connectTimeoutSec = 0.5;  // the server never answers the handshake
        auto ws = client->connect(r).value();
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() == 2);
        CHECK(events[0].error.find("timed out") != std::string::npos);
        CHECK(events[1].code == 1006);
    }
    {
        auto ws = open(*client, "ws://127.0.0.1:1/");  // nothing listens on port 1: refused at once
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() == 2);
        CHECK(events[0].type == WebSocketEvent::Type::Error);
        CHECK_FALSE(events[0].hint.empty());
        CHECK(events.back().code == 1006);
    }
    {
        // wss:// to a server without TLS: the secure connection fails, and says so.
        fa::test::WsTestServer server;
        REQUIRE(server.ok());
        WebSocketRequest r;
        r.url = "wss://127.0.0.1:" + std::to_string(server.port()) + "/echo";
        r.connectTimeoutSec = 2;
        auto made = client->connect(r);
        if (made.ok()) {
            auto events = collect_until_close(*made.value());
            REQUIRE(events.size() == 2);
            CHECK(events[0].type == WebSocketEvent::Type::Error);
            CHECK(events[1].code == 1006);
        } else {
            CHECK(made.error().message.find("TLS") != std::string::npos);  // a libcurl built without TLS
        }
    }
    WebSocketRequest r;
    r.url = "http://example.com/";
    CHECK_FALSE(client->connect(r).ok());
    // A header that would break the handshake is refused before anything is sent.
    r.url = "ws://127.0.0.1:1/";
    r.headers = {{"X-A", "a\r\nb"}};
    CHECK_FALSE(client->connect(r).ok());
}

#endif
