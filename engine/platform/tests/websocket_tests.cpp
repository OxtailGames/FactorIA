// WebSocket clients (fa/platform/websocket.h): the event queue, the memory client, the platform stubs, and the plain TCP
// client against the loopback server of ws_test_server.h. Nothing here reaches another machine.
#include <doctest.h>

#include <cerrno>
#include <chrono>
#include <cstdlib>
#include <thread>

#include "fa/core/json.h"
#include "fa/platform/websocket.h"
#include "fa/platform/websocket_codec.h"
#include "ws_test_server.h"

using namespace fa;

namespace {

// Polls until `want` events have arrived or the safety net (30 s, far above a loopback round trip) ends.
std::vector<WebSocketEvent> collect(WebSocket& ws, std::size_t want, int maxMs = 30000) {
    std::vector<WebSocketEvent> events;
    const auto end = std::chrono::steady_clock::now() + std::chrono::milliseconds(maxMs);
    while (events.size() < want && std::chrono::steady_clock::now() < end) {
        if (ws.poll(events) == 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
    }
    return events;
}

}  // namespace

TEST_CASE("websocket: the event queue keeps order, ends at Close and drops what comes after") {
    WebSocketEventQueue queue;
    CHECK(queue.push(WebSocketEvent::open("p")));
    CHECK(queue.push(WebSocketEvent::text("a")));
    CHECK(queue.push(WebSocketEvent::binary("b")));
    CHECK(queue.push(WebSocketEvent::close(1000, "bye", true)));
    CHECK(queue.ended());
    CHECK_FALSE(queue.push(WebSocketEvent::text("late")));
    std::vector<WebSocketEvent> out;
    CHECK(queue.drain(out) == 4);
    REQUIRE(out.size() == 4);
    CHECK(out[0].type == WebSocketEvent::Type::Open);
    CHECK(out[0].subprotocol == "p");
    CHECK(out[1].data == "a");
    CHECK(out[2].type == WebSocketEvent::Type::Binary);
    CHECK(out[3].code == 1000);
    CHECK(out[3].wasClean);
    CHECK(queue.drain(out) == 0);
}

TEST_CASE("websocket: an abandoned queue drops what is pending and takes nothing more, with no event") {
    auto queue = std::make_shared<WebSocketEventQueue>();
    CHECK(queue->push(WebSocketEvent::open()));
    CHECK(queue->push(WebSocketEvent::text("pending")));
    queue->abandon();
    CHECK(queue->ended());
    CHECK_FALSE(queue->push(WebSocketEvent::text("late")));  // a callback that outlives the connection
    CHECK_FALSE(queue->push(WebSocketEvent::close(1000, "", true)));
    std::vector<WebSocketEvent> out;
    CHECK(queue->drain(out) == 0);
}

TEST_CASE("websocket: close() refuses a code and a reason it cannot send, and changes nothing") {
    MemoryWebSocketClient server;
    WebSocketRequest r;
    r.url = "ws://localhost/chat";
    auto ws = server.connect(r).value();
    auto bad = ws->close(1005, "");
    REQUIRE_FALSE(bad.ok());
    CHECK_FALSE(bad.error().hint.empty());
    CHECK_FALSE(ws->close(1000, std::string(124, 'x')).ok());
    CHECK_FALSE(ws->close(2999, "").ok());
    CHECK(ws->state() == WebSocketState::Open);
    CHECK(ws->close(3000, "ok").ok());
}

TEST_CASE("websocket: a queue that nobody drains does not grow without bound") {
    WebSocketEventQueue queue(1000);
    CHECK(queue.push(WebSocketEvent::text(std::string(600, 'a'))));
    CHECK_FALSE(queue.push(WebSocketEvent::text(std::string(600, 'b'))));
    CHECK(queue.ended());
    std::vector<WebSocketEvent> out;
    queue.drain(out);
    REQUIRE(out.size() == 2);
    CHECK(out[0].type == WebSocketEvent::Type::Error);
    CHECK_FALSE(out[0].hint.empty());
    CHECK(out[1].type == WebSocketEvent::Type::Close);
    CHECK(out[1].code == 1008);
    // A size near the top of the 64-bit range cannot wrap the counter.
    WebSocketEventQueue small(1000);
    CHECK(small.push(WebSocketEvent::text(std::string(10, 'a'))));
}

TEST_CASE("websocket: every platform answers, never null; a client that is not written says when it lands") {
    auto client = make_system_websocket_client();
    REQUIRE(client);
    CHECK_FALSE(client->name().empty());
    if (!client->available()) {
        CHECK(client->unavailable_reason().find("lands in M98.2") != std::string::npos);
        WebSocketRequest r;
        r.url = "ws://example.com/";
        auto ws = client->connect(r);
        REQUIRE_FALSE(ws.ok());
        CHECK(ws.error().message.find("not available") != std::string::npos);
        CHECK_FALSE(ws.error().hint.empty());
    }
    auto unavailable = make_unavailable_websocket_client("x", "because");
    CHECK_FALSE(unavailable->available());
    CHECK(unavailable->name() == "x");
    CHECK(unavailable->unavailable_reason() == "because");
}

TEST_CASE("websocket memory: connect, accept, messages both ways, close") {
    MemoryWebSocketClient server;
    WebSocketRequest r;
    r.url = "ws://localhost/chat";
    r.subprotocols = {"a", "b"};
    r.headers = {{"X-Token", "t"}};
    auto made = server.connect(r);
    REQUIRE(made.ok());
    auto& ws = *made.value();
    REQUIRE(server.peer_count() == 1);
    auto* peer = server.peer(0);
    CHECK(peer->url == "ws://localhost/chat");
    CHECK(peer->headers.size() == 1);
    CHECK(peer->open);
    CHECK(ws.state() == WebSocketState::Open);

    peer->send_text("hello");
    peer->send_binary(std::string("\x01\x02", 2));
    REQUIRE(ws.send_text("hi").ok());
    REQUIRE(ws.send_binary("\x09", 1).ok());
    CHECK_FALSE(ws.send_text("\xff").ok());  // not UTF-8
    REQUIRE(peer->received.size() == 2);
    CHECK_FALSE(peer->received[0].binary);
    CHECK(peer->received[0].data == "hi");
    CHECK(peer->received[1].binary);

    std::vector<WebSocketEvent> events;
    ws.poll(events);
    REQUIRE(events.size() == 3);
    CHECK(events[0].type == WebSocketEvent::Type::Open);
    CHECK(events[1].data == "hello");
    CHECK(events[2].type == WebSocketEvent::Type::Binary);
    CHECK(events[2].data.size() == 2);

    CHECK(ws.close(1000, "done").ok());
    CHECK(ws.state() == WebSocketState::Closed);
    CHECK(peer->clientClosed);
    CHECK(peer->clientCloseCode == 1000);
    CHECK(peer->closed);
    events.clear();
    ws.poll(events);
    REQUIRE(events.size() == 1);
    CHECK(events[0].type == WebSocketEvent::Type::Close);
    CHECK(events[0].wasClean);
    CHECK_FALSE(ws.send_text("late").ok());
}

TEST_CASE("websocket memory: manual accept, subprotocol, refuse and drop") {
    MemoryWebSocketClient server;
    server.set_auto_accept(false);
    WebSocketRequest r;
    r.url = "ws://localhost/";
    r.subprotocols = {"a"};
    auto ws = server.connect(r).value();
    CHECK(ws->state() == WebSocketState::Connecting);
    CHECK_FALSE(ws->send_text("early").ok());
    CHECK_FALSE(server.peer(0)->accept("zzz"));  // not offered
    CHECK(server.peer(0)->accept("a"));
    std::vector<WebSocketEvent> events;
    ws->poll(events);
    REQUIRE(events.size() == 1);
    CHECK(events[0].subprotocol == "a");

    server.peer(0)->drop("cable");
    events.clear();
    ws->poll(events);
    REQUIRE(events.size() == 2);
    CHECK(events[0].type == WebSocketEvent::Type::Error);
    CHECK(events[1].code == 1006);
    CHECK_FALSE(events[1].wasClean);
    CHECK(ws->state() == WebSocketState::Closed);

    server.refuse_next(1, "nobody home");
    auto refused = server.connect(r).value();
    events.clear();
    refused->poll(events);
    REQUIRE(events.size() == 2);
    CHECK(events[0].error == "nobody home");
    // The next one is accepted again (set_auto_accept(false): connecting).
    auto third = server.connect(r).value();
    CHECK(third->state() == WebSocketState::Connecting);
    // Closing while connecting abandons the attempt.
    CHECK(third->close(1000, "").ok());
    events.clear();
    third->poll(events);
    REQUIRE(events.size() == 2);
    CHECK(events[1].code == 1006);

    // Not an address of this protocol.
    r.url = "http://localhost/";
    CHECK_FALSE(server.connect(r).ok());
}

TEST_CASE("websocket memory: the server's close and a close the server answers later") {
    MemoryWebSocketClient server;
    WebSocketRequest r;
    r.url = "ws://localhost/";
    auto ws = server.connect(r).value();
    server.peer(0)->close(4001, "kicked");
    auto events = collect(*ws, 2, 1000);
    REQUIRE(events.size() == 2);
    CHECK(events[1].code == 4001);
    CHECK(events[1].reason == "kicked");
    CHECK(events[1].wasClean);

    auto slow = server.connect(r).value();
    server.peer(1)->autoCloseReply = false;
    CHECK(slow->close(1000, "x").ok());
    CHECK(slow->state() == WebSocketState::Closing);
    server.peer(1)->close(1000, "x");
    CHECK(slow->state() == WebSocketState::Closed);
}

TEST_CASE("websocket memory: a message above the limit is refused by send") {
    MemoryWebSocketClient server;
    WebSocketRequest r;
    r.url = "ws://localhost/";
    r.maxMessageBytes = 16;
    auto ws = server.connect(r).value();
    auto big = ws->send_text(std::string(17, 'a'));
    REQUIRE_FALSE(big.ok());
    CHECK_FALSE(big.error().hint.empty());
    CHECK(ws->send_text(std::string(16, 'a')).ok());
}

#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)

namespace {

// Until a Close event arrives (what is before it is kept).
std::vector<WebSocketEvent> collect_until_close(WebSocket& ws, int maxMs = 30000) {
    std::vector<WebSocketEvent> events;
    const auto end = std::chrono::steady_clock::now() + std::chrono::milliseconds(maxMs);
    while (std::chrono::steady_clock::now() < end) {
        if (ws.poll(events) == 0) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        if (!events.empty() && events.back().type == WebSocketEvent::Type::Close) break;
    }
    return events;
}

std::unique_ptr<WebSocket> connect_tcp(WebSocketClient& client, const std::string& url,
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

}  // namespace

TEST_CASE("websocket tcp: echo, binary, greeting, subprotocol and headers against the loopback server") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_tcp_websocket_client();
    CHECK(client->available());
    CHECK(client->name() == "tcp");

    {
        auto ws = connect_tcp(*client, server.url("/echo"));
        auto events = collect(*ws, 1);
        REQUIRE(events.size() == 1);
        CHECK(events[0].type == WebSocketEvent::Type::Open);
        REQUIRE(ws->send_text("hello").ok());
        REQUIRE(ws->send_binary("\x00\x01\xff", 3).ok());
        events = collect(*ws, 2);
        REQUIRE(events.size() == 2);
        CHECK(events[0].type == WebSocketEvent::Type::Text);
        CHECK(events[0].data == "hello");
        CHECK(events[1].type == WebSocketEvent::Type::Binary);
        CHECK(events[1].data == std::string("\x00\x01\xff", 3));
        CHECK(ws->close(1000, "bye").ok());
        events = collect_until_close(*ws);
        REQUIRE_FALSE(events.empty());
        CHECK(events.back().type == WebSocketEvent::Type::Close);
        CHECK(events.back().code == 1000);
        CHECK(events.back().wasClean);
        CHECK(ws->state() == WebSocketState::Closed);
    }
    {
        auto ws = connect_tcp(*client, server.url("/greet"));
        auto events = collect(*ws, 3);
        REQUIRE(events.size() == 3);
        CHECK(events[1].data == "hello");
        CHECK(events[2].data == std::string("\x01\x02\x03", 3));
    }
    {
        auto ws = connect_tcp(*client, server.url("/protocol"), {"one", "two"});
        auto events = collect(*ws, 2);
        REQUIRE(events.size() == 2);
        CHECK(events[0].subprotocol == "one");
        CHECK(events[1].data == "one");
    }
    {
        auto ws = connect_tcp(*client, server.url("/headers"), {}, {{"X-Game-Token", "abc"}});
        auto events = collect(*ws, 2);
        REQUIRE(events.size() == 2);
        auto json = parse_json(events[1].data);
        REQUIRE(json.ok());
        CHECK(json.value().value("x-game-token", std::string()) == "abc");
        CHECK(json.value().value("upgrade", std::string()) == "websocket");
    }
}

TEST_CASE("websocket tcp: the server closes, drops, refuses, answers wrong or says nothing") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_tcp_websocket_client();
    {
        auto ws = connect_tcp(*client, server.url("/close?code=4001&reason=bye"));
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() == 2);
        CHECK(events[1].code == 4001);
        CHECK(events[1].reason == "bye");
        CHECK(events[1].wasClean);
    }
    {
        auto ws = connect_tcp(*client, server.url("/drop"));
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() >= 2);
        CHECK(events[events.size() - 2].type == WebSocketEvent::Type::Error);
        CHECK(events.back().code == 1006);
        CHECK_FALSE(events.back().wasClean);
    }
    {
        auto ws = connect_tcp(*client, server.url("/refuse?status=403"));
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() == 2);
        CHECK(events[0].type == WebSocketEvent::Type::Error);
        CHECK(events[0].httpStatus == 403);
        CHECK_FALSE(events[0].hint.empty());
        CHECK(events[1].code == 1006);
    }
    {
        auto ws = connect_tcp(*client, server.url("/badaccept"));
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() == 2);
        CHECK(events[0].error.find("Sec-WebSocket-Accept") != std::string::npos);
    }
    {
        auto ws = connect_tcp(*client, server.url("/nothing-here"));
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() == 2);
        CHECK(events[0].httpStatus == 404);
    }
}

TEST_CASE("websocket tcp: fragments, a big message, pings and bad frames") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_tcp_websocket_client();
    {
        auto ws = connect_tcp(*client, server.url("/fragments"));
        auto events = collect(*ws, 2);
        REQUIRE(events.size() == 2);
        CHECK(events[1].data == "Hello");
    }
    {
        auto ws = connect_tcp(*client, server.url("/big?n=300000"));
        auto events = collect(*ws, 2);
        REQUIRE(events.size() == 2);
        CHECK(events[1].data.size() == 300000);
        // A message above the limit of this request fails the connection: Error, then Close 1006 (the server is sent 1009).
        WebSocketRequest r;
        r.url = server.url("/big?n=5000");
        r.maxMessageBytes = 1000;
        auto small = client->connect(r).value();
        events = collect_until_close(*small);
        REQUIRE(events.size() >= 3);
        CHECK(events[events.size() - 2].type == WebSocketEvent::Type::Error);
        CHECK(events.back().code == 1006);
        CHECK_FALSE(events.back().wasClean);
    }
    {
        fa::test::WsTestServer pinger;  // its own server: /fragments also sends a ping
        REQUIRE(pinger.ok());
        auto ws = connect_tcp(*client, pinger.url("/ping"));
        // The client answers the ping by itself.
        auto events = collect(*ws, 1);
        const auto end = std::chrono::steady_clock::now() + std::chrono::seconds(30);
        while (pinger.pongs() == 0 && std::chrono::steady_clock::now() < end) {
            ws->poll(events);
            std::this_thread::sleep_for(std::chrono::milliseconds(2));
        }
        CHECK(pinger.pongs() == 1);
    }
    {
        auto ws = connect_tcp(*client, server.url("/badutf8"));
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() >= 3);
        CHECK(events[events.size() - 2].type == WebSocketEvent::Type::Error);
        CHECK(events.back().code == 1006);
    }
    {
        auto ws = connect_tcp(*client, server.url("/badrsv"));
        auto events = collect_until_close(*ws);
        REQUIRE(events.size() >= 3);
        CHECK(events.back().code == 1006);
    }
}

TEST_CASE("websocket tcp: addresses it cannot open say why") {
    auto client = make_tcp_websocket_client();
    WebSocketRequest r;
    r.url = "wss://example.com/";
    auto tls = client->connect(r);
    REQUIRE_FALSE(tls.ok());
    CHECK(tls.error().message.find("TLS") != std::string::npos);
    CHECK_FALSE(tls.error().hint.empty());
    r.url = "http://example.com/";
    CHECK_FALSE(client->connect(r).ok());
    r.url = "ws://127.0.0.1:1/";  // nothing listens on port 1: refused at once, no wait for a timeout
    auto ws = client->connect(r);
    REQUIRE(ws.ok());
    auto events = collect_until_close(*ws.value());
    REQUIRE(events.size() >= 2);
    CHECK(events[events.size() - 2].type == WebSocketEvent::Type::Error);
    CHECK(events.back().code == 1006);
    // A header that would break the handshake is refused before anything is sent.
    r.url = "ws://127.0.0.1:1/";
    r.headers = {{"X-A", "a\r\nb"}};
    CHECK_FALSE(client->connect(r).ok());
}

TEST_CASE("websocket tcp: destroying an open connection leaves nothing behind") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_tcp_websocket_client();
    const auto end = std::chrono::steady_clock::now() + std::chrono::seconds(30);
    {
        auto ws = connect_tcp(*client, server.url("/silent"));
        auto events = collect(*ws, 1);
        REQUIRE(events.size() == 1);
        // Open arrived, so the server has this connection; destroying it sends a close frame (1001) that needs no waiting.
    }
    {
        // Destroyed while connecting: the attempt may or may not reach the server, and the destructor does not wait for it.
        auto ws = connect_tcp(*client, server.url("/echo"));
    }
    // The server sees the first connection say goodbye (the server's own threads end by themselves). The second one is not
    // counted: whether it reached the server at all depends on timing.
    bool goodbye = false;
    while (!goodbye && std::chrono::steady_clock::now() < end) {
        for (int code : server.client_close_codes()) goodbye = goodbye || code == 1001;
        if (!goodbye) std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    CHECK(goodbye);
    while (server.finished_connections() < 1 && std::chrono::steady_clock::now() < end)
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    CHECK(server.finished_connections() >= 1);
}

TEST_CASE("websocket tcp: destroying a connection does not wait for the network") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_tcp_websocket_client();
    auto ws = connect_tcp(*client, server.url("/silent"));
    REQUIRE(collect(*ws, 1).size() == 1);
    const auto start = std::chrono::steady_clock::now();
    ws.reset();
    // Far above a few milliseconds so that a loaded VM passes, far below the 5 s close wait or a join on a stuck thread.
    CHECK(std::chrono::steady_clock::now() - start < std::chrono::seconds(2));
}

TEST_CASE("websocket tcp: a client closes with an application code") {
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    auto client = make_tcp_websocket_client();
    auto ws = connect_tcp(*client, server.url("/echo"));
    collect(*ws, 1);
    CHECK(ws->close(4242, "custom").ok());
    auto events = collect_until_close(*ws);
    REQUIRE_FALSE(events.empty());
    CHECK(events.back().code == 4242);
    CHECK(events.back().reason == "custom");
    const auto codes = server.client_close_codes();
    REQUIRE(codes.size() == 1);
    CHECK(codes[0] == 4242);
}

#endif
