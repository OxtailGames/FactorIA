// The system WebSocket client of macOS and iOS (NSURLSessionWebSocketTask, websocket_apple.mm) against the loopback server of
// ws_test_server.h: the same cases as the tcp client (websocket_tests.cpp) wherever the contract of fa/platform/websocket.h
// is the same, and the places where NSURLSession differs are said in the comments. Nothing here reaches another machine.
#if defined(__APPLE__)

#include <doctest.h>

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

#include <atomic>
#include <chrono>
#include <thread>

#include "fa/core/json.h"
#include "fa/platform/websocket_codec.h"
#include "fa/platform/websocket.h"
#include "ws_test_server.h"

using namespace fa;

namespace {

std::vector<WebSocketEvent> sys_collect(WebSocket& ws, std::size_t want, int maxMs = 30000) {
    std::vector<WebSocketEvent> events;
    const auto end = std::chrono::steady_clock::now() + std::chrono::milliseconds(maxMs);
    while (events.size() < want && std::chrono::steady_clock::now() < end) {
        if (ws.poll(events) == 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
    }
    return events;
}

// Until a Close event arrives (what is before it is kept).
std::vector<WebSocketEvent> sys_collect_until_close(WebSocket& ws, int maxMs = 30000) {
    std::vector<WebSocketEvent> events;
    const auto end = std::chrono::steady_clock::now() + std::chrono::milliseconds(maxMs);
    while (std::chrono::steady_clock::now() < end) {
        if (ws.poll(events) == 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        if (!events.empty() && events.back().type == WebSocketEvent::Type::Close) break;
    }
    return events;
}

// The close codes the server has read, once it has read one (or after 30 s): NSURLSession reports the Close event when it has
// sent the frame, which may be before the server reads it.
std::vector<int> sys_wait_close_codes(const fa::test::WsTestServer& server) {
    const auto until = std::chrono::steady_clock::now() + std::chrono::seconds(30);
    while (server.client_close_codes().empty() && std::chrono::steady_clock::now() < until)
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    return server.client_close_codes();
}

std::unique_ptr<WebSocket> sys_connect(WebSocketClient& client, const std::string& url,
                                       std::vector<std::string> sub = {},
                                       std::vector<std::pair<std::string, std::string>> headers = {}) {
    WebSocketRequest r;
    r.url = url;
    r.subprotocols = std::move(sub);
    r.headers = std::move(headers);
    auto ws = client.connect(r);
    REQUIRE(ws.ok());
    return std::move(ws.value());
}

// What every failed connection ends with: [..., Error, Close 1006 wasClean false], and state() Closed.
void check_failed(WebSocket& ws, const std::vector<WebSocketEvent>& events) {
    REQUIRE(events.size() >= 2);
    CHECK(events[events.size() - 2].type == WebSocketEvent::Type::Error);
    CHECK_FALSE(events[events.size() - 2].error.empty());
    CHECK_FALSE(events[events.size() - 2].hint.empty());
    CHECK(events.back().type == WebSocketEvent::Type::Close);
    CHECK(events.back().code == 1006);
    CHECK_FALSE(events.back().wasClean);
    CHECK(ws.state() == WebSocketState::Closed);
}

// A server that does the handshake and then never reads or answers anything (a stuck peer). It ends by itself when the
// test object goes.
class StuckServer {
public:
    StuckServer() {
        listener_ = ::socket(AF_INET, SOCK_STREAM, 0);
        if (listener_ < 0) return;
        sockaddr_in addr{};
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
        addr.sin_port = 0;
        if (::bind(listener_, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0 || ::listen(listener_, 4) != 0)
            return;
        socklen_t length = sizeof(addr);
        ::getsockname(listener_, reinterpret_cast<sockaddr*>(&addr), &length);
        port_ = ntohs(addr.sin_port);
        thread_ = std::thread([this] {
            const int c = ::accept(listener_, nullptr, nullptr);
            if (c < 0) return;
            std::string head;
            char buffer[1024];
            while (ws::find_head_end(head) == std::string::npos) {
                const auto n = ::recv(c, buffer, sizeof(buffer), 0);
                if (n <= 0) {
                    ::close(c);
                    return;
                }
                head.append(buffer, static_cast<std::size_t>(n));
            }
            auto request = ws::parse_client_request(head.substr(0, ws::find_head_end(head)));
            if (request.ok()) {
                const std::string response = ws::build_server_response(request.value(), "");
                static_cast<void>(::send(c, response.data(), response.size(), 0));
                handshaken_ = true;
            }
            while (!stop_) std::this_thread::sleep_for(std::chrono::milliseconds(10));  // never reads, never answers
            ::close(c);
        });
    }
    ~StuckServer() {
        stop_ = true;
        if (listener_ >= 0) ::shutdown(listener_, SHUT_RDWR);
        if (thread_.joinable()) {
            // accept() may still wait (nobody connected): connect once to let it return
            if (port_ != 0 && !handshaken_) {
                const int s = ::socket(AF_INET, SOCK_STREAM, 0);
                sockaddr_in addr{};
                addr.sin_family = AF_INET;
                addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
                addr.sin_port = htons(static_cast<std::uint16_t>(port_));
                ::connect(s, reinterpret_cast<sockaddr*>(&addr), sizeof(addr));
                ::close(s);
            }
            thread_.join();
        }
        if (listener_ >= 0) ::close(listener_);
    }
    int port() const { return port_; }
    std::string url() const { return "ws://127.0.0.1:" + std::to_string(port_) + "/"; }

private:
    int listener_ = -1;
    int port_ = 0;
    std::thread thread_;
    std::atomic<bool> stop_{false}, handshaken_{false};
};

}  // namespace

TEST_CASE("websocket system: echo, binary, greeting, subprotocol and headers against the loopback server") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_system_websocket_client();
    REQUIRE(client->available());
    CHECK(client->name() == "nsurlsession");

    {
        auto ws = sys_connect(*client, server.url("/echo"));
        CHECK(ws->state() == WebSocketState::Connecting);
        auto events = sys_collect(*ws, 1);
        REQUIRE(events.size() == 1);
        CHECK(events[0].type == WebSocketEvent::Type::Open);
        CHECK(events[0].subprotocol.empty());
        CHECK(ws->state() == WebSocketState::Open);
        REQUIRE(ws->send_text("hello").ok());
        REQUIRE(ws->send_binary("\x00\x01\xff", 3).ok());
        CHECK_FALSE(ws->send_text("\xff").ok());  // not UTF-8
        events = sys_collect(*ws, 2);
        REQUIRE(events.size() == 2);
        CHECK(events[0].type == WebSocketEvent::Type::Text);
        CHECK(events[0].data == "hello");
        CHECK(events[1].type == WebSocketEvent::Type::Binary);
        CHECK(events[1].data == std::string("\x00\x01\xff", 3));
        // A text with an embedded NUL survives.
        REQUIRE(ws->send_text(std::string("a\0b", 3)).ok());
        events = sys_collect(*ws, 1);
        REQUIRE(events.size() == 1);
        CHECK(events[0].data == std::string("a\0b", 3));
        CHECK(ws->close(1000, "bye").ok());
        CHECK(ws->state() == WebSocketState::Closing);
        CHECK_FALSE(ws->send_text("late").ok());
        events = sys_collect_until_close(*ws);
        REQUIRE_FALSE(events.empty());
        CHECK(events.back().type == WebSocketEvent::Type::Close);
        CHECK(events.back().code == 1000);
        CHECK(events.back().wasClean);
        CHECK(ws->state() == WebSocketState::Closed);
        // The system's completion handlers may run just after the close was reported: wait for them, bounded.
        const auto settle = std::chrono::steady_clock::now() + std::chrono::seconds(30);
        while (ws->buffered_amount() != 0 && std::chrono::steady_clock::now() < settle)
            std::this_thread::sleep_for(std::chrono::milliseconds(5));
        CHECK(ws->buffered_amount() == 0);
    }
    {
        auto ws = sys_connect(*client, server.url("/greet"));
        auto events = sys_collect(*ws, 3);
        REQUIRE(events.size() == 3);
        CHECK(events[1].data == "hello");
        CHECK(events[2].data == std::string("\x01\x02\x03", 3));
    }
    {
        auto ws = sys_connect(*client, server.url("/protocol"), {"one", "two"});
        auto events = sys_collect(*ws, 2);
        REQUIRE(events.size() == 2);
        CHECK(events[0].subprotocol == "one");
        CHECK(events[1].data == "one");
    }
    {
        auto ws = sys_connect(*client, server.url("/headers"), {}, {{"X-Game-Token", "abc"}});
        auto events = sys_collect(*ws, 2);
        REQUIRE(events.size() == 2);
        auto json = parse_json(events[1].data);
        REQUIRE(json.ok());
        CHECK(json.value().value("x-game-token", std::string()) == "abc");
        CHECK(json.value().value("upgrade", std::string()) == "websocket");
    }
}

TEST_CASE("websocket system: the server closes, drops, refuses, answers wrong or says nothing") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_system_websocket_client();
    {
        auto ws = sys_connect(*client, server.url("/close?code=4001&reason=bye"));
        auto events = sys_collect_until_close(*ws);
        REQUIRE(events.size() == 2);
        CHECK(events[0].type == WebSocketEvent::Type::Open);
        CHECK(events[1].code == 4001);
        CHECK(events[1].reason == "bye");
        CHECK(events[1].wasClean);
        CHECK(ws->state() == WebSocketState::Closed);
    }
    {
        auto ws = sys_connect(*client, server.url("/drop"));
        check_failed(*ws, sys_collect_until_close(*ws));
    }
    {
        auto ws = sys_connect(*client, server.url("/refuse?status=403"));
        auto events = sys_collect_until_close(*ws);
        REQUIRE(events.size() == 2);
        CHECK(events[0].type == WebSocketEvent::Type::Error);
        CHECK(events[0].httpStatus == 403);
        CHECK_FALSE(events[0].hint.empty());
        CHECK(events[1].code == 1006);
        CHECK_FALSE(events[1].wasClean);
    }
    {
        auto ws = sys_connect(*client, server.url("/badaccept"));
        auto events = sys_collect_until_close(*ws);
        REQUIRE(events.size() == 2);  // never opened
        check_failed(*ws, events);
    }
    {
        // A redirect is not followed: the attempt ends with the redirect's status.
        auto ws = sys_connect(*client, server.url("/redirect"));
        auto events = sys_collect_until_close(*ws);
        check_failed(*ws, events);
        REQUIRE(events.size() == 2);
        CHECK(events[0].httpStatus == 302);
        CHECK(events[0].hint.find("redirect") != std::string::npos);
    }
    {
        auto ws = sys_connect(*client, server.url("/nothing-here"));
        auto events = sys_collect_until_close(*ws);
        REQUIRE(events.size() == 2);
        CHECK(events[0].httpStatus == 404);
    }
}

TEST_CASE("websocket system: fragments, a big message, pings and bad frames") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_system_websocket_client();
    {
        auto ws = sys_connect(*client, server.url("/fragments"));
        auto events = sys_collect(*ws, 2);
        REQUIRE(events.size() == 2);
        CHECK(events[1].data == "Hello");
    }
    {
        auto ws = sys_connect(*client, server.url("/big?n=300000"));
        auto events = sys_collect(*ws, 2);
        REQUIRE(events.size() == 2);
        CHECK(events[1].data.size() == 300000);
        // A message above the limit of this request fails the connection: Error, then Close 1006 (the server is sent 1009).
        WebSocketRequest r;
        r.url = server.url("/big?n=5000");
        r.maxMessageBytes = 1000;
        auto small = client->connect(r).value();
        events = sys_collect_until_close(*small);
        check_failed(*small, events);
        CHECK(events.size() <= 3);  // [Open,] Error, Close: the message itself is never delivered
        for (const WebSocketEvent& e : events) CHECK(e.type != WebSocketEvent::Type::Text);
        // The server is sent 1009 (the system's own close frame for a message above maximumMessageSize).
        bool sawTooBig = false;
        const auto until = std::chrono::steady_clock::now() + std::chrono::seconds(30);
        while (!sawTooBig && std::chrono::steady_clock::now() < until) {
            for (int code : server.client_close_codes()) sawTooBig = sawTooBig || code == 1009;
            if (!sawTooBig) std::this_thread::sleep_for(std::chrono::milliseconds(5));
        }
        CHECK_MESSAGE(sawTooBig, server.diagnostics());
    }
    {
        // The system answers the server's ping by itself.
        fa::test::WsTestServer pinger;
        REQUIRE(pinger.ok());
        auto ws = sys_connect(*client, pinger.url("/ping"));
        auto events = sys_collect(*ws, 1);
        const auto end = std::chrono::steady_clock::now() + std::chrono::seconds(30);
        while (pinger.pongs() == 0 && std::chrono::steady_clock::now() < end) {
            ws->poll(events);
            std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        CHECK(pinger.pongs() == 1);
    }
    {
        auto ws = sys_connect(*client, server.url("/badutf8"));
        check_failed(*ws, sys_collect_until_close(*ws));
    }
    {
        auto ws = sys_connect(*client, server.url("/badrsv"));
        check_failed(*ws, sys_collect_until_close(*ws));
    }
}

TEST_CASE("websocket system: addresses it cannot open say why") {
    auto client = make_system_websocket_client();
    WebSocketRequest r;
    r.url = "http://example.com/";
    CHECK_FALSE(client->connect(r).ok());
    r.url = "ws://127.0.0.1:1/";  // nothing listens on port 1: refused at once, no wait for a timeout
    auto ws = client->connect(r);
    REQUIRE(ws.ok());
    auto events = sys_collect_until_close(*ws.value());
    check_failed(*ws.value(), events);
    CHECK(events.size() == 2);
    // A header that would break the handshake is refused before anything is sent.
    r.headers = {{"X-A", "a\r\nb"}};
    CHECK_FALSE(client->connect(r).ok());
    r.headers = {{"Sec-WebSocket-Key", "x"}};
    CHECK_FALSE(client->connect(r).ok());
    r.headers.clear();
    r.subprotocols = {"bad protocol"};
    CHECK_FALSE(client->connect(r).ok());
}

TEST_CASE("websocket system: a server that never answers the handshake times out") {
    // A socket that listens (the kernel completes the TCP handshake) and never reads: only the connect timeout ends this.
    const int listener = ::socket(AF_INET, SOCK_STREAM, 0);
    REQUIRE(listener >= 0);
    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = 0;
    REQUIRE(::bind(listener, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) == 0);
    REQUIRE(::listen(listener, 4) == 0);
    socklen_t length = sizeof(addr);
    ::getsockname(listener, reinterpret_cast<sockaddr*>(&addr), &length);
    auto client = make_system_websocket_client();
    WebSocketRequest r;
    r.url = "ws://127.0.0.1:" + std::to_string(ntohs(addr.sin_port)) + "/";
    r.connectTimeoutSec = 1.0;
    auto ws = client->connect(r).value();
    const auto start = std::chrono::steady_clock::now();
    auto events = sys_collect_until_close(*ws, 30000);
    check_failed(*ws, events);
    CHECK(events.size() == 2);
    CHECK(events[0].error.find("timed out") != std::string::npos);
    CHECK(std::chrono::steady_clock::now() - start < std::chrono::seconds(20));
    ::close(listener);
}

TEST_CASE("websocket system: an idle open connection outlives the connect timeout") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_system_websocket_client();
    WebSocketRequest r;
    r.url = server.url("/echo");
    // The timeout is generous so that a loaded machine opens the connection well inside it; the test then lets 1.5 times the
    // timeout pass, polling (it ends at once if the connection fails).
    r.connectTimeoutSec = 3.0;
    auto ws = client->connect(r).value();
    const auto started = std::chrono::steady_clock::now();
    REQUIRE(sys_collect(*ws, 1).size() == 1);
    const auto until = started + std::chrono::milliseconds(4500);
    std::vector<WebSocketEvent> idle;
    while (std::chrono::steady_clock::now() < until && ws->state() == WebSocketState::Open) {
        ws->poll(idle);
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    CHECK(idle.empty());
    CHECK(ws->state() == WebSocketState::Open);
    REQUIRE(ws->send_text("still here").ok());
    auto events = sys_collect(*ws, 1);
    REQUIRE(events.size() == 1);
    CHECK(events[0].data == "still here");
}

TEST_CASE("websocket system: close while connecting is Closing, then Error and Close 1006") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_system_websocket_client();
    // /hang reads the handshake and never answers it: the connection is still Connecting whenever close() comes.
    auto ws = sys_connect(*client, server.url("/hang"));
    CHECK(ws->state() == WebSocketState::Connecting);
    CHECK(ws->close(1000, "").ok());
    CHECK(ws->state() == WebSocketState::Closing);
    auto events = sys_collect_until_close(*ws);
    check_failed(*ws, events);
    CHECK(events.size() == 2);  // never opened
    CHECK(events[0].error.find("before it was open") != std::string::npos);
    CHECK(ws->close(1000, "").ok());  // closing twice is not an error
}

TEST_CASE("websocket system: a close the server does not answer is reported at once (NSURLSession does not wait)") {
    // The one difference from the tcp client that a game can see (fa/platform/websocket.h, docs/NETWORKING.md): after close()
    // NSURLSession reports the close as soon as it has sent the frame, so the Close event (the code and reason that were
    // asked for, wasClean true) does not wait for the server's answer and there is no Error and Close 1006 after 5 s.
    StuckServer server;
    REQUIRE(server.port() != 0);
    auto client = make_system_websocket_client();
    auto ws = sys_connect(*client, server.url());
    REQUIRE(sys_collect(*ws, 1).size() == 1);
    REQUIRE(ws->close(3000, "bye").ok());
    CHECK(ws->state() == WebSocketState::Closing);
    const auto start = std::chrono::steady_clock::now();
    auto events = sys_collect_until_close(*ws, 60000);
    REQUIRE(events.size() == 1);
    CHECK(events[0].type == WebSocketEvent::Type::Close);
    CHECK(events[0].code == 3000);
    CHECK(events[0].reason == "bye");
    CHECK(events[0].wasClean);
    CHECK(ws->state() == WebSocketState::Closed);
    CHECK(std::chrono::steady_clock::now() - start < std::chrono::seconds(4));
}

TEST_CASE("websocket system: close without a code is sent as 1000 (NSURLSession cannot send a frame with no code)") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_system_websocket_client();
    auto ws = sys_connect(*client, server.url("/echo"));
    REQUIRE(sys_collect(*ws, 1).size() == 1);
    REQUIRE(ws->close(0, "").ok());
    auto events = sys_collect_until_close(*ws);
    REQUIRE_FALSE(events.empty());
    CHECK(events.back().type == WebSocketEvent::Type::Close);
    CHECK(ws->state() == WebSocketState::Closed);
    CHECK(events.back().code == 1000);
    CHECK(events.back().wasClean);
    const auto codes = sys_wait_close_codes(server);
    REQUIRE_MESSAGE(codes.size() == 1, server.diagnostics());
    CHECK(codes[0] == 1000);
}

TEST_CASE("websocket system: close() refuses a code and a reason it cannot send, and changes nothing") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_system_websocket_client();
    auto ws = sys_connect(*client, server.url("/echo"));
    REQUIRE(sys_collect(*ws, 1).size() == 1);
    CHECK_FALSE(ws->close(1005, "").ok());
    CHECK_FALSE(ws->close(1000, std::string(124, 'x')).ok());
    CHECK_FALSE(ws->close(2999, "").ok());
    CHECK(ws->state() == WebSocketState::Open);
    CHECK(ws->close(1000, "").ok());
}

TEST_CASE("websocket system: destroying an open connection says goodbye and leaves nothing behind") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_system_websocket_client();
    const auto end = std::chrono::steady_clock::now() + std::chrono::seconds(30);
    {
        auto ws = sys_connect(*client, server.url("/silent"));
        REQUIRE(sys_collect(*ws, 1).size() == 1);
    }
    {
        // Destroyed while connecting: the attempt may or may not reach the server, and the destructor does not wait for it.
        auto ws = sys_connect(*client, server.url("/echo"));
    }
    bool goodbye = false;
    while (!goodbye && std::chrono::steady_clock::now() < end) {
        for (int code : server.client_close_codes()) goodbye = goodbye || code == 1001;
        if (!goodbye) std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    CHECK_MESSAGE(goodbye, server.diagnostics());
    while (server.finished_connections() < 1 && std::chrono::steady_clock::now() < end)
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    CHECK(server.finished_connections() >= 1);
}

TEST_CASE("websocket system: destroying a connection does not wait for the network") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_system_websocket_client();
    auto ws = sys_connect(*client, server.url("/silent"));
    REQUIRE(sys_collect(*ws, 1).size() == 1);
    const auto start = std::chrono::steady_clock::now();
    ws.reset();
    CHECK(std::chrono::steady_clock::now() - start < std::chrono::seconds(2));
    // And while it is still connecting, even to an address nobody answers.
    WebSocketRequest r;
    r.url = "ws://127.0.0.1:1/";
    auto refused = client->connect(r).value();
    const auto start2 = std::chrono::steady_clock::now();
    refused.reset();
    CHECK(std::chrono::steady_clock::now() - start2 < std::chrono::seconds(2));
}

TEST_CASE("websocket system: a client closes with an application code") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_system_websocket_client();
    auto ws = sys_connect(*client, server.url("/echo"));
    sys_collect(*ws, 1);
    CHECK(ws->close(4242, "custom").ok());
    auto events = sys_collect_until_close(*ws);
    REQUIRE_FALSE(events.empty());
    CHECK(events.back().code == 4242);
    CHECK(events.back().reason == "custom");
    // The Close event comes when the frame is sent, not when the server has read it.
    const auto codes = sys_wait_close_codes(server);
    REQUIRE_MESSAGE(codes.size() == 1, server.diagnostics());
    CHECK(codes[0] == 4242);
}

TEST_CASE("websocket system: a message above maxMessageBytes is refused by send") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_system_websocket_client();
    WebSocketRequest r;
    r.url = server.url("/echo");
    r.maxMessageBytes = 16;
    auto ws = client->connect(r).value();
    REQUIRE(sys_collect(*ws, 1).size() == 1);
    auto big = ws->send_text(std::string(17, 'a'));
    REQUIRE_FALSE(big.ok());
    CHECK_FALSE(big.error().hint.empty());
    CHECK(ws->send_text(std::string(16, 'a')).ok());
}

#endif  // __APPLE__
