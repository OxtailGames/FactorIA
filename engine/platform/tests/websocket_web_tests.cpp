// The rules of the web client (engine/platform/src/websocket_web_mapping.h): what the browser's events become, in which
// order, with which state, and what the teaching messages say. The Mapper is plain C++, so it runs here; the glue to the
// browser (websocket_web.cpp) is checked by the web smoke test of CI.
#include <doctest.h>

#include "../src/websocket_web_mapping.h"
#include "fa/platform/websocket_codec.h"

using namespace fa;
using namespace fa::web_ws;
using Kind = BrowserEvent::Kind;
using Type = WebSocketEvent::Type;

namespace {

BrowserEvent ev(Kind kind, std::string data = {}, std::size_t size = 0) {
    BrowserEvent e;
    e.kind = kind;
    e.data = std::move(data);
    e.size = size;
    return e;
}
BrowserEvent closed(int code, bool clean, std::string reason = {}) {
    BrowserEvent e;
    e.kind = Kind::Close;
    e.code = code;
    e.wasClean = clean;
    e.reason = std::move(reason);
    return e;
}
Mapper make(std::size_t max = 100, bool pageHttps = true, bool secure = true) {
    return Mapper("game.example.com:443", secure, pageHttps, max, 15.0);
}
bool contains(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

}  // namespace

TEST_CASE("websocket web: open, messages and a clean close keep the contract's order, and the state leads the event") {
    Mapper m = make();
    CHECK(m.state() == WebSocketState::Connecting);
    auto r = m.on_browser(ev(Kind::Open, "chat.v1"));
    CHECK(m.state() == WebSocketState::Open);  // already Open when the event is handed out
    REQUIRE(r.events.size() == 1);
    CHECK(r.events[0].type == Type::Open);
    CHECK(r.events[0].subprotocol == "chat.v1");

    r = m.on_browser(ev(Kind::Text, "hello", 5));
    REQUIRE(r.events.size() == 1);
    CHECK(r.events[0].type == Type::Text);
    CHECK(r.events[0].data == "hello");
    r = m.on_browser(ev(Kind::Binary, std::string("\x01\x00\x02", 3), 3));
    REQUIRE(r.events.size() == 1);
    CHECK(r.events[0].type == Type::Binary);
    CHECK(r.events[0].data.size() == 3);

    r = m.on_browser(closed(1000, true, "bye"));
    CHECK(m.state() == WebSocketState::Closed);  // Closed before the Close event is read
    REQUIRE(r.events.size() == 1);
    CHECK(r.events[0].type == Type::Close);
    CHECK(r.events[0].code == 1000);
    CHECK(r.events[0].reason == "bye");
    CHECK(r.events[0].wasClean);
    CHECK(m.finished());
    CHECK(m.on_browser(ev(Kind::Text, "late", 4)).events.empty());  // nothing after the Close
    CHECK(m.on_browser(ev(Kind::Error)).events.empty());
}

TEST_CASE("websocket web: a failure is Error then Close 1006, whatever the browser says") {
    SUBCASE("it never opened: the browser's error, then its close") {
        Mapper m = make();
        auto r = m.on_browser(ev(Kind::Error));
        REQUIRE(r.events.size() == 1);
        CHECK(r.events[0].type == Type::Error);
        CHECK(m.state() == WebSocketState::Connecting);  // the close event ends it
        r = m.on_browser(closed(1006, false));
        CHECK(m.state() == WebSocketState::Closed);
        REQUIRE(r.events.size() == 1);
        CHECK(r.events[0].type == Type::Close);
        CHECK(r.events[0].code == 1006);
        CHECK_FALSE(r.events[0].wasClean);
        CHECK(r.events[0].reason.empty());
    }
    SUBCASE("a close with no error before it still reports one") {
        Mapper m = make();
        m.on_browser(ev(Kind::Open));
        auto r = m.on_browser(closed(1006, false));
        REQUIRE(r.events.size() == 2);
        CHECK(r.events[0].type == Type::Error);
        CHECK(contains(r.events[0].error, "lost"));
        CHECK(r.events[1].type == Type::Close);
        CHECK(r.events[1].code == 1006);
        CHECK_FALSE(r.events[1].wasClean);
    }
    SUBCASE("a clean close that came after an error is still a failure") {
        Mapper m = make();
        m.on_browser(ev(Kind::Open));
        m.on_browser(ev(Kind::Error));
        auto r = m.on_browser(closed(1000, true));
        REQUIRE(r.events.size() == 1);
        CHECK(r.events[0].code == 1006);
        CHECK_FALSE(r.events[0].wasClean);
    }
    SUBCASE("a server code that is not clean is reported as 1006 too") {
        Mapper m = make();
        auto r = m.on_browser(closed(1015, false));
        REQUIRE(r.events.size() == 2);
        CHECK(r.events[0].type == Type::Error);
        CHECK(r.events[1].code == 1006);
    }
}

TEST_CASE("websocket web: the connect error teaches: host, mixed content, the server's Origin policy") {
    Mapper m = make(100, true, false);  // an https page, a ws:// address
    auto r = m.on_browser(ev(Kind::Error));
    REQUIRE(r.events.size() == 1);
    const WebSocketEvent& e = r.events[0];
    CHECK(contains(e.error, "game.example.com:443"));
    CHECK(contains(e.hint, "mixed content"));
    CHECK(contains(e.hint, "use wss://"));
    CHECK(contains(e.hint, "Origin"));
    CHECK(e.httpStatus == 0);

    Text secure = problem_text(Problem::CouldNotConnect, "h", true, true, 15);
    CHECK_FALSE(contains(secure.hint, "use wss://"));  // the page and the address agree: no accusation
    CHECK(contains(secure.hint, "Origin"));
    for (Problem p : {Problem::CouldNotConnect, Problem::ConnectionLost, Problem::ConnectTimeout, Problem::CloseTimeout,
                      Problem::ClosedBeforeOpen}) {
        Text t = problem_text(p, "h:1", true, false, 7.5);
        CHECK_FALSE(t.message.empty());
        CHECK_FALSE(t.hint.empty());
    }
    CHECK(contains(problem_text(Problem::ConnectTimeout, "h", true, false, 7.5).message, "7.5 s"));
}

TEST_CASE("websocket web: a message above maxMessageBytes fails the connection and is never copied") {
    Mapper m = make(10);
    m.on_browser(ev(Kind::Open));
    CHECK(m.wants_payload(Kind::Text, 10));
    CHECK_FALSE(m.wants_payload(Kind::Text, 11));
    CHECK_FALSE(m.wants_payload(Kind::Binary, 1000));
    auto r = m.on_browser(ev(Kind::Binary, {}, 11));
    CHECK(m.state() == WebSocketState::Closed);
    REQUIRE(r.events.size() == 2);
    CHECK(r.events[0].type == Type::Error);
    CHECK(contains(r.events[0].error, "11 bytes"));
    CHECK(contains(r.events[0].hint, "maxMessageBytes"));
    CHECK(r.events[1].type == Type::Close);
    CHECK(r.events[1].code == 1006);
    CHECK_FALSE(r.events[1].wasClean);
    CHECK(r.stopBrowser);
    CHECK(r.closeCode == 1000);  // the browser cannot send 1009
    CHECK_FALSE(m.wants_payload(Kind::Text, 1));
    CHECK(m.on_browser(closed(1000, true)).events.empty());  // the browser's own close is not reported again
}

TEST_CASE("websocket web: the connect timeout and the closing timeout end the attempt, once") {
    SUBCASE("connecting too long") {
        Mapper m = make();
        auto r = m.on_browser(ev(Kind::ConnectTimeout));
        REQUIRE(r.events.size() == 2);
        CHECK(contains(r.events[0].error, "longer than 15 s"));
        CHECK(r.events[1].code == 1006);
        CHECK(r.stopBrowser);
        CHECK(m.state() == WebSocketState::Closed);
        CHECK(m.on_browser(ev(Kind::Error)).events.empty());
        CHECK(m.on_browser(closed(1006, false)).events.empty());
    }
    SUBCASE("a timer that fires after the socket opened does nothing") {
        Mapper m = make();
        m.on_browser(ev(Kind::Open));
        CHECK(m.on_browser(ev(Kind::ConnectTimeout)).events.empty());
        CHECK(m.state() == WebSocketState::Open);
    }
    SUBCASE("the server never answers close()") {
        Mapper m = make();
        m.on_browser(ev(Kind::Open));
        auto c = m.on_close_requested(3000, "bye");
        CHECK(c.startClosing);
        CHECK(c.closeCode == 3000);
        CHECK(c.closeReason == "bye");
        CHECK(c.events.empty());
        CHECK(m.state() == WebSocketState::Closing);
        auto r = m.on_browser(ev(Kind::CloseTimeout));
        REQUIRE(r.events.size() == 2);
        CHECK(r.events[0].type == Type::Error);
        CHECK(r.events[1].code == 1006);
        CHECK_FALSE(r.events[1].wasClean);
        CHECK(r.stopBrowser);
        CHECK(m.state() == WebSocketState::Closed);
    }
    SUBCASE("the server answers: a clean close, and a late timer is ignored") {
        Mapper m = make();
        m.on_browser(ev(Kind::Open));
        m.on_close_requested(0, "");
        auto r = m.on_browser(closed(1005, true));
        REQUIRE(r.events.size() == 1);
        CHECK(r.events[0].wasClean);
        CHECK(r.events[0].code == 1005);
        CHECK(m.on_browser(ev(Kind::CloseTimeout)).events.empty());
    }
}

TEST_CASE("websocket web: close() while connecting is Closing until poll delivered Error and Close 1006") {
    Mapper m = make();
    auto r = m.on_close_requested(1000, "");
    CHECK(m.state() == WebSocketState::Closing);
    REQUIRE(r.events.size() == 2);
    CHECK(r.events[0].type == Type::Error);
    CHECK(contains(r.events[0].error, "before it was open"));
    CHECK(r.events[1].code == 1006);
    CHECK_FALSE(r.events[1].wasClean);
    CHECK(r.stopBrowser);
    CHECK_FALSE(r.startClosing);
    CHECK(m.on_browser(ev(Kind::Open)).events.empty());  // an open that was already on its way is dropped
    CHECK(m.state() == WebSocketState::Closing);
    CHECK(m.on_close_requested(1000, "").events.empty());  // closing twice is not an error
    m.after_poll();
    CHECK(m.state() == WebSocketState::Closed);
}

TEST_CASE("websocket web: close() of a closed or closing connection does nothing; messages still arrive while closing") {
    Mapper m = make();
    m.on_browser(ev(Kind::Open));
    CHECK(m.on_close_requested(1000, "").startClosing);
    CHECK_FALSE(m.on_close_requested(1000, "").startClosing);
    auto r = m.on_browser(ev(Kind::Text, "still", 5));
    CHECK(r.events.size() == 1);
    m.on_browser(closed(1000, true));
    CHECK_FALSE(m.on_close_requested(1000, "").startClosing);
    m.after_poll();
    CHECK(m.state() == WebSocketState::Closed);
}

TEST_CASE("websocket web: a queue that ended before the browser did closes the browser's socket") {
    Mapper m = make();
    m.on_browser(ev(Kind::Open));
    auto r = m.on_queue_ended();
    CHECK(r.stopBrowser);
    CHECK(m.state() == WebSocketState::Closed);
    CHECK(m.on_queue_ended().stopBrowser == false);
    CHECK(m.on_browser(ev(Kind::Text, "x", 1)).events.empty());
}

TEST_CASE("websocket web: headers are refused with a teaching error, sends are checked before the browser sees them") {
    WebSocketRequest request;
    request.url = "wss://game.example.com/";
    CHECK(check_request(request).ok());
    request.headers = {{"X-Token", "abc"}, {"Authorization", "x"}};
    auto r = check_request(request);
    REQUIRE_FALSE(r.ok());
    CHECK(contains(r.error().message, "X-Token, Authorization"));
    CHECK(contains(r.error().hint, "URL"));
    CHECK(contains(r.error().hint, "first message"));

    CHECK(check_send(WebSocketState::Open, 10, 10, 0).ok());
    CHECK(contains(check_send(WebSocketState::Connecting, 1, 10, 0).error().message, "not open yet"));
    CHECK(contains(check_send(WebSocketState::Closing, 1, 10, 0).error().message, "closing or closed"));
    CHECK(contains(check_send(WebSocketState::Closed, 1, 10, 0).error().message, "closing or closed"));
    CHECK(contains(check_send(WebSocketState::Open, 11, 10, 0).error().message, "11 bytes"));
    CHECK(contains(check_send(WebSocketState::Open, 1, 10, kMaxBuffered + 1).error().message, "16 MB"));
}

TEST_CASE("websocket web: the browser's constructor errors become teaching errors") {
    Text mixed = constructor_failure_text("SecurityError", "An insecure WebSocket connection may not be initiated", "ws://x.com/", true);
    CHECK(contains(mixed.message, "ws://x.com/"));
    CHECK(contains(mixed.hint, "wss://"));
    CHECK(contains(mixed.hint, "mixed"));
    Text syntax = constructor_failure_text("SyntaxError", "The subprotocol 'a b' is invalid", "wss://x.com/", true);
    CHECK(contains(syntax.message, "subprotocol 'a b'"));
    CHECK(contains(syntax.hint, "spaces or commas"));
    Text other = constructor_failure_text("", "boom", "wss://x.com/", false);
    CHECK(contains(other.message, "boom"));
    CHECK_FALSE(other.hint.empty());
}

TEST_CASE("websocket web: subprotocols are handed to the browser as a JSON array") {
    CHECK(json_string_array({}) == "[]");
    CHECK(json_string_array({"chat.v1", "chat.v2"}) == "[\"chat.v1\",\"chat.v2\"]");
    CHECK(json_quote("a\"b\\c\n") == "\"a\\\"b\\\\c\\u000a\"");
}
