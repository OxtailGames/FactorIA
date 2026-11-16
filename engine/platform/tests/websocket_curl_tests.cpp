// The libcurl WebSocket client (make_curl_websocket_client, Linux's client) against the loopback server of ws_test_server.h.
// It runs wherever libcurl can be loaded (Linux CI, macOS's own libcurl); without one every case says so and passes, except on
// Linux, where a missing libcurl fails the case (the CI image has one: otherwise a broken loader would pass silently); a Linux
// machine without libcurl runs the tests with FA_ALLOW_NO_CURL=1.
// Nothing here reaches another machine.
#include <doctest.h>

#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

#include <poll.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <iterator>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#include "fa/core/json.h"
#include "fa/platform/websocket.h"
#include "fa/platform/websocket_codec.h"
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
#if defined(__linux__) && !defined(__ANDROID__)
        const char* allow = std::getenv("FA_ALLOW_NO_CURL");
        CHECK_MESSAGE(allow != nullptr && allow[0] != '\0' && allow[0] != '0',
                      "libcurl cannot be loaded on this Linux machine (" << client->unavailable_reason()
                                                                         << "); install libcurl 7.45 or newer, or set "
                                                                            "FA_ALLOW_NO_CURL=1 to skip these cases");
#endif
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

// The byte at `offset` of message `index` in the burst of the backpressure case: a reordered or a lost chunk shows.
char burst_byte(int index, std::size_t offset) {
    return static_cast<char>((static_cast<std::size_t>(index) * 131u + offset * 7u) & 0xffu);
}

// A WebSocket server for one connection that reads slowly (a small receive buffer, a pause after every 8 KB), so the
// client's writes stall and curl_easy_send answers CURLE_AGAIN again and again. It checks that `count` binary messages of
// `size` bytes (burst_byte) arrive whole and in order, then sends "ok <count>" (or what went wrong) and closes with 1000.
class SlowReader {
public:
    SlowReader(int count, std::size_t size) : count_(count), size_(size) {
        listen_ = ::socket(AF_INET, SOCK_STREAM, 0);
        if (listen_ < 0) return;
        const int small = 8 * 1024;  // inherited by the accepted socket
        ::setsockopt(listen_, SOL_SOCKET, SO_RCVBUF, &small, sizeof(small));
        sockaddr_in addr{};
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
        if (::bind(listen_, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0 || ::listen(listen_, 4) != 0) {
            ::close(listen_);
            listen_ = -1;
            return;
        }
        socklen_t length = sizeof(addr);
        ::getsockname(listen_, reinterpret_cast<sockaddr*>(&addr), &length);
        port_ = ntohs(addr.sin_port);
        thread_ = std::thread([this] { serve(); });
    }
    ~SlowReader() {
        stop_ = true;
        if (thread_.joinable()) thread_.join();
        if (listen_ >= 0) ::close(listen_);
    }
    SlowReader(const SlowReader&) = delete;
    SlowReader& operator=(const SlowReader&) = delete;
    bool ok() const { return port_ != 0; }
    std::string url() const { return "ws://127.0.0.1:" + std::to_string(port_) + "/burst"; }

private:
    // Waits up to 50 ms for `events` on `fd`: true when it is ready.
    static bool ready(int fd, short events) {
        pollfd p{fd, events, 0};
        return ::poll(&p, 1, 50) > 0;
    }

    bool write_all(int c, const std::string& bytes) {
        std::size_t at = 0;
        while (at < bytes.size() && !stop_) {
            if (!ready(c, POLLOUT)) continue;
#if defined(MSG_NOSIGNAL)
            const ssize_t n = ::send(c, bytes.data() + at, bytes.size() - at, MSG_NOSIGNAL);
#else
            const ssize_t n = ::send(c, bytes.data() + at, bytes.size() - at, 0);
#endif
            if (n <= 0) return false;
            at += static_cast<std::size_t>(n);
        }
        return at == bytes.size();
    }

    void serve() {
        const auto end = Clock::now() + std::chrono::seconds(60);  // safety net, far above the second the burst takes
        int c = -1;
        while (c < 0 && !stop_ && Clock::now() < end) {
            if (ready(listen_, POLLIN)) c = ::accept(listen_, nullptr, nullptr);
        }
        if (c < 0) return;
#if defined(SO_NOSIGPIPE)
        const int one = 1;
        ::setsockopt(c, SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof(one));
#endif
        ws::SessionOptions options;
        options.role = ws::Role::Server;
        options.maxMessageBytes = size_ * 2;
        ws::Session session(options);
        std::string head;
        bool upgraded = false, closing = false;
        int got = 0;
        std::vector<ws::Event> events;
        char buffer[8 * 1024];
        while (!stop_ && Clock::now() < end) {
            if (!ready(c, POLLIN)) continue;
            const ssize_t n = ::recv(c, buffer, sizeof(buffer), 0);
            if (n <= 0) break;
            events.clear();
            if (!upgraded) {
                head.append(buffer, static_cast<std::size_t>(n));
                const std::size_t headEnd = ws::find_head_end(head);
                if (headEnd == std::string::npos) continue;
                auto request = ws::parse_client_request(std::string_view(head).substr(0, headEnd));
                if (!request.ok() || !write_all(c, ws::build_server_response(request.value(), ""))) break;
                upgraded = true;
                session.feed(head.data() + headEnd, head.size() - headEnd, events);
            } else {
                session.feed(buffer, static_cast<std::size_t>(n), events);
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
            }
            std::string verdict;
            for (const ws::Event& e : events) {
                if (closing || e.type != ws::Event::Type::Binary) continue;
                bool whole = e.data.size() == size_;
                for (std::size_t k = 0; whole && k < size_; ++k) whole = e.data[k] == burst_byte(got, k);
                if (!whole) {
                    verdict = "message " + std::to_string(got) + " arrived broken or out of order";
                    break;
                }
                if (++got == count_) verdict = "ok " + std::to_string(count_);
            }
            if (!verdict.empty() && !closing) {
                static_cast<void>(session.send_text(verdict));
                static_cast<void>(session.close(1000));
                closing = true;
            }
            if (session.has_output() && !write_all(c, session.take_output())) break;
            if (session.done()) break;
        }
        ::close(c);
    }

    int count_;
    std::size_t size_;
    int listen_ = -1;
    int port_ = 0;
    std::atomic<bool> stop_{false};
    std::thread thread_;
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
        // An address that never answers (a black hole, or unreachable at once where the network says so): close() during
        // the TCP connect ends the attempt well before curl's own connect timeout, because the progress callback runs while
        // curl waits for the connection. The connect timeout of the request is the safety net far above it.
        WebSocketRequest blackhole;
        blackhole.url = "ws://10.255.255.1/";
        blackhole.connectTimeoutSec = 60;
        auto ws = client->connect(blackhole).value();
        std::vector<WebSocketEvent> early;
        const auto settle = Clock::now() + std::chrono::milliseconds(300);
        while (Clock::now() < settle) {
            ws->poll(early);
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
        CHECK(ws->close(1000, "").ok());
        // The Close may already have arrived while the 300 ms ran (a network that refuses at once): do not wait 20 s more.
        const bool closed = !early.empty() && early.back().type == WebSocketEvent::Type::Close;
        auto events = closed ? std::vector<WebSocketEvent>{} : collect_until_close(*ws, 20000);
        early.insert(early.end(), std::make_move_iterator(events.begin()), std::make_move_iterator(events.end()));
        REQUIRE(early.size() >= 2);
        CHECK(early[early.size() - 2].type == WebSocketEvent::Type::Error);
        CHECK(early.back().type == WebSocketEvent::Type::Close);
        CHECK(early.back().code == 1006);
        CHECK(ws->state() == WebSocketState::Closed);
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

TEST_CASE("websocket curl: a queue that overflows reads Closed as soon as the Close event can be read") {
    auto client = curl_client();
    if (!client) return;
    fa::test::WsTestServer server;
    REQUIRE(server.ok());
    // 48 MB of messages that the game does not read: over the 32 MB the queue holds (WebSocketEventQueue::limit_for:
    // max(32 MB, 2 * maxMessageBytes), 4 MB by default), so the 33rd 1 MB message overflows. Raise both if that limit grows.
    auto ws = open(*client, server.url("/flood?n=1000000&count=48"));
    const auto end = Clock::now() + std::chrono::seconds(30);
    while (ws->state() != WebSocketState::Closed && Clock::now() < end)
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    CHECK(ws->state() == WebSocketState::Closed);
    CHECK_FALSE(ws->send_text("late").ok());
    std::vector<WebSocketEvent> events;
    ws->poll(events);
    REQUIRE(events.size() == 2);
    CHECK(events[0].type == WebSocketEvent::Type::Error);
    CHECK(events[1].type == WebSocketEvent::Type::Close);
    CHECK(events[1].code == 1008);
    CHECK(ws->state() == WebSocketState::Closed);
}

TEST_CASE("websocket curl: a burst of sends to a server that reads slowly arrives whole and in order") {
    // The client's writes stall (CURLE_AGAIN) while more messages queue behind them; the bytes being written must not move
    // or change meanwhile (a TLS library retries the same buffer), and nothing may be lost or reordered.
    auto client = curl_client();
    if (!client) return;
    constexpr int kCount = 160;
    constexpr std::size_t kSize =
        64 * 1024;  // 10 MB in all (below the 16 MB the client queues): more than any socket buffer
                    // holds, even a Linux one that tuned itself up to 4 MB
    SlowReader server(kCount, kSize);
    REQUIRE(server.ok());
    auto ws = open(*client, server.url());
    auto events = collect(*ws, 1);
    REQUIRE(events.size() == 1);
    REQUIRE(events[0].type == WebSocketEvent::Type::Open);
    std::string message(kSize, '\0');
    std::size_t maxBuffered = 0;
    for (int i = 0; i < kCount; ++i) {
        for (std::size_t k = 0; k < kSize; ++k) message[k] = burst_byte(i, k);
        REQUIRE(ws->send_binary(message.data(), message.size()).ok());
        maxBuffered = std::max<std::size_t>(maxBuffered, static_cast<std::size_t>(ws->buffered_amount()));
    }
    // The server takes 8 KB a millisecond at most, so while the burst is queued some of it is waiting: the writes did stall
    // (CURLE_AGAIN), which is what this case is about. The largest value seen inside the loop does not depend on how fast
    // the transfer thread drains the queue after the last send.
    CHECK(maxBuffered > 0);
    events = collect_until_close(*ws);
    REQUIRE(events.size() == 2);
    CHECK(events[0].type == WebSocketEvent::Type::Text);
    CHECK(events[0].data == "ok " + std::to_string(kCount));
    CHECK(events[1].type == WebSocketEvent::Type::Close);
    CHECK(events[1].code == 1000);
    CHECK(events[1].wasClean);
}

#endif
