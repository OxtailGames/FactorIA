// The RFC 6455 codec (fa/platform/websocket_codec.h): the examples of the RFC, fragmentation, control frames, close codes,
// UTF-8, limits and bad frames. No socket: bytes in, events out.
#include <doctest.h>

#include <cstring>
#include <string>
#include <vector>

#include "fa/platform/websocket_codec.h"

using namespace fa;
using namespace fa::ws;

namespace {

std::string bytes(std::initializer_list<int> values) {
    std::string s;
    for (int v : values) s += static_cast<char>(v);
    return s;
}

std::vector<Event> feed_all(Session& session, const std::string& data) {
    std::vector<Event> events;
    session.feed(data.data(), data.size(), events);
    return events;
}

Session make_server(std::size_t max = kDefaultMaxMessageBytes) {
    SessionOptions o;
    o.role = Role::Server;
    o.maxMessageBytes = max;
    return Session(o);
}

Session make_client(std::size_t max = kDefaultMaxMessageBytes) {
    SessionOptions o;
    o.role = Role::Client;
    o.maxMessageBytes = max;
    o.maskKey = [] { return 0x12345678u; };
    return Session(o);
}

const std::uint8_t kMask[4] = {0x37, 0xfa, 0x21, 0x3d};

}  // namespace

TEST_CASE("ws codec: the single-frame examples of RFC 6455 section 5.7") {
    // An unmasked text "Hello" (server to client).
    CHECK(encode_frame(Opcode::Text, "Hello", true, nullptr) == bytes({0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f}));
    // A masked text "Hello" with the key 37 fa 21 3d (client to server).
    CHECK(encode_frame(Opcode::Text, "Hello", true, kMask) ==
          bytes({0x81, 0x85, 0x37, 0xfa, 0x21, 0x3d, 0x7f, 0x9f, 0x4d, 0x51, 0x58}));
    // Fragmented "Hel" + "lo".
    CHECK(encode_frame(Opcode::Text, "Hel", false, nullptr) == bytes({0x01, 0x03, 0x48, 0x65, 0x6c}));
    CHECK(encode_frame(Opcode::Continuation, "lo", true, nullptr) == bytes({0x80, 0x02, 0x6c, 0x6f}));
    // Unmasked ping and masked pong, both "Hello".
    CHECK(encode_frame(Opcode::Ping, "Hello", true, nullptr) == bytes({0x89, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f}));
    CHECK(encode_frame(Opcode::Pong, "Hello", true, kMask) ==
          bytes({0x8a, 0x85, 0x37, 0xfa, 0x21, 0x3d, 0x7f, 0x9f, 0x4d, 0x51, 0x58}));
}

TEST_CASE("ws codec: lengths of 7, 16 and 64 bits use the shortest form") {
    const std::string b125(125, 'a'), b126(126, 'a'), b256(256, 'a'), b65535(65535, 'a'), b65536(65536, 'a');
    CHECK(encode_frame(Opcode::Binary, b125, true, nullptr).substr(0, 2) == bytes({0x82, 125}));
    CHECK(encode_frame(Opcode::Binary, b126, true, nullptr).substr(0, 4) == bytes({0x82, 126, 0x00, 126}));
    // RFC 5.7: 256 bytes of binary: 82 7E 01 00.
    CHECK(encode_frame(Opcode::Binary, b256, true, nullptr).substr(0, 4) == bytes({0x82, 0x7e, 0x01, 0x00}));
    CHECK(encode_frame(Opcode::Binary, b65535, true, nullptr).substr(0, 4) == bytes({0x82, 0x7e, 0xff, 0xff}));
    // RFC 5.7: 64 KiB of binary: 82 7F 00 00 00 00 00 01 00 00.
    CHECK(encode_frame(Opcode::Binary, b65536, true, nullptr).substr(0, 10) ==
          bytes({0x82, 0x7f, 0, 0, 0, 0, 0, 0x01, 0, 0}));
    CHECK(encode_frame(Opcode::Binary, b65536, true, nullptr).size() == 10 + 65536);
}

TEST_CASE("ws codec: a session reads the frames of the RFC") {
    Session client = make_client();
    auto events = feed_all(client, bytes({0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f}));
    REQUIRE(events.size() == 1);
    CHECK(events[0].type == Event::Type::Text);
    CHECK(events[0].data == "Hello");

    // Fragmented.
    events = feed_all(client, bytes({0x01, 0x03, 0x48, 0x65, 0x6c}) + bytes({0x80, 0x02, 0x6c, 0x6f}));
    REQUIRE(events.size() == 1);
    CHECK(events[0].data == "Hello");

    // A masked frame to a server.
    Session server = make_server();
    events = feed_all(server, bytes({0x81, 0x85, 0x37, 0xfa, 0x21, 0x3d, 0x7f, 0x9f, 0x4d, 0x51, 0x58}));
    REQUIRE(events.size() == 1);
    CHECK(events[0].data == "Hello");

    // A 256-byte and a 64 KiB binary message.
    events = feed_all(client, encode_frame(Opcode::Binary, std::string(256, '\x07'), true, nullptr));
    REQUIRE(events.size() == 1);
    CHECK(events[0].type == Event::Type::Binary);
    CHECK(events[0].data.size() == 256);
    events = feed_all(client, encode_frame(Opcode::Binary, std::string(65536, '\x01'), true, nullptr));
    REQUIRE(events.size() == 1);
    CHECK(events[0].data.size() == 65536);
}

TEST_CASE("ws codec: the same bytes fed one at a time give the same events") {
    std::string stream = encode_frame(Opcode::Text, "one", true, nullptr);
    stream += encode_frame(Opcode::Binary, std::string(300, 'b'), true, nullptr);
    stream += encode_frame(Opcode::Text, "fr", false, nullptr);
    stream += encode_frame(Opcode::Ping, "p", true, nullptr);
    stream += encode_frame(Opcode::Continuation, "ag", true, nullptr);
    Session session = make_client();
    std::vector<Event> events;
    for (char c : stream) session.feed(&c, 1, events);
    REQUIRE(events.size() == 4);
    CHECK(events[0].data == "one");
    CHECK(events[1].type == Event::Type::Binary);
    CHECK(events[1].data.size() == 300);
    CHECK(events[2].type == Event::Type::Ping);
    CHECK(events[2].data == "p");
    CHECK(events[3].data == "frag");
    // The ping was answered.
    CHECK(session.take_output().size() > 0);
}

TEST_CASE("ws codec: a ping is answered with a pong that carries the same payload, masked by a client") {
    Session client = make_client();
    auto events = feed_all(client, encode_frame(Opcode::Ping, "abc", true, nullptr));
    REQUIRE(events.size() == 1);
    CHECK(events[0].type == Event::Type::Ping);
    const std::string out = client.take_output();
    REQUIRE(out.size() == 2 + 4 + 3);
    CHECK(static_cast<unsigned char>(out[0]) == 0x8a);
    CHECK((static_cast<unsigned char>(out[1]) & 0x80) != 0);  // masked
    // Unmask it with the key of the test.
    Session server = make_server();
    auto back = feed_all(server, out);
    REQUIRE(back.size() == 1);
    CHECK(back[0].type == Event::Type::Pong);
    CHECK(back[0].data == "abc");
}

TEST_CASE("ws codec: a client masks, a server does not") {
    Session client = make_client();
    REQUIRE(client.send_text("Hello").ok());
    const std::string out = client.take_output();
    CHECK((static_cast<unsigned char>(out[1]) & 0x80) != 0);
    CHECK(out.find("Hello") == std::string::npos);

    Session server = make_server();
    REQUIRE(server.send_text("Hello").ok());
    CHECK(server.take_output() == bytes({0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f}));
}

TEST_CASE("ws codec: the closing handshake") {
    Session client = make_client();
    Session server = make_server();
    REQUIRE(client.close(1000, "bye").ok());
    CHECK(client.close_sent());
    CHECK_FALSE(client.done());
    auto atServer = feed_all(server, client.take_output());
    REQUIRE(atServer.size() == 1);
    CHECK(atServer[0].type == Event::Type::Close);
    CHECK(atServer[0].code == 1000);
    CHECK(atServer[0].reason == "bye");
    CHECK(server.done());  // it answered at once
    auto atClient = feed_all(client, server.take_output());
    REQUIRE(atClient.size() == 1);
    CHECK(atClient[0].type == Event::Type::Close);
    CHECK(atClient[0].code == 1000);
    CHECK(client.done());
    // Closing twice does nothing.
    CHECK(client.close(1000).ok());
    CHECK_FALSE(client.has_output());
    // Sending after close is an error.
    CHECK_FALSE(client.send_text("late").ok());
}

TEST_CASE("ws codec: a close frame without a code reports 1005") {
    Session client = make_client();
    auto events = feed_all(client, encode_frame(Opcode::Close, "", true, nullptr));
    REQUIRE(events.size() == 1);
    CHECK(events[0].type == Event::Type::Close);
    CHECK(events[0].code == 1005);
}

TEST_CASE("ws codec: close codes") {
    for (int ok : {1000, 1001, 1002, 1003, 1007, 1008, 1009, 1010, 1011, 1012, 1013, 1014, 3000, 4000, 4999})
        CHECK(close_code_valid_on_wire(ok));
    for (int bad : {0, 999, 1004, 1005, 1006, 1015, 1016, 2000, 2999, 5000, 65535, -1})
        CHECK_FALSE(close_code_valid_on_wire(bad));
    CHECK(close_code_app_may_send(1000));
    CHECK(close_code_app_may_send(3000));
    CHECK(close_code_app_may_send(4999));
    CHECK_FALSE(close_code_app_may_send(1001));
    CHECK_FALSE(close_code_app_may_send(1006));
    CHECK_FALSE(close_code_app_may_send(2999));
    CHECK_FALSE(close_code_app_may_send(5000));

    CHECK(close_payload(1000, "ok") == bytes({0x03, 0xe8, 'o', 'k'}));
    CHECK(close_payload(0, "ignored").empty());
}

TEST_CASE("ws codec: a close with an invalid code or reason is a protocol failure") {
    Session client = make_client();
    auto events =
        feed_all(client, encode_frame(Opcode::Close, bytes({0x03, 0xed}), true, nullptr));  // 1005 on the wire
    REQUIRE(events.size() == 1);
    CHECK(events[0].type == Event::Type::Failure);
    CHECK(events[0].code == 1002);
    CHECK(client.failed());
    CHECK(client.done());

    Session c2 = make_client();
    events = feed_all(c2, encode_frame(Opcode::Close, bytes({0x03}), true, nullptr));  // one byte
    REQUIRE(events.size() == 1);
    CHECK(events[0].type == Event::Type::Failure);

    Session c3 = make_client();
    events =
        feed_all(c3, encode_frame(Opcode::Close, bytes({0x03, 0xe8, 0xff, 0xfe}), true, nullptr));  // reason not UTF-8
    REQUIRE(events.size() == 1);
    CHECK(events[0].type == Event::Type::Failure);
    CHECK(events[0].code == 1007);
}

TEST_CASE("ws codec: UTF-8 in text messages") {
    Session client = make_client();
    auto events =
        feed_all(client, encode_frame(Opcode::Text, "caf\xc3\xa9 \xe2\x82\xac \xf0\x9f\x98\x80", true, nullptr));
    REQUIRE(events.size() == 1);
    CHECK(events[0].type == Event::Type::Text);

    for (const char* bad : {"\xff", "\xc0\xaf", "\xed\xa0\x80", "\xe2\x82", "\xf4\x90\x80\x80"}) {
        Session s = make_client();
        auto e = feed_all(s, encode_frame(Opcode::Text, bad, true, nullptr));
        REQUIRE(e.size() == 1);
        CHECK(e[0].type == Event::Type::Failure);
        CHECK(e[0].code == 1007);
        CHECK_FALSE(e[0].error.empty());
        CHECK_FALSE(e[0].hint.empty());
        // The close frame with 1007 is queued.
        CHECK(s.has_output());
    }
    // Binary is not checked.
    Session s = make_client();
    auto e = feed_all(s, encode_frame(Opcode::Binary, "\xff\xfe", true, nullptr));
    REQUIRE(e.size() == 1);
    CHECK(e[0].type == Event::Type::Binary);
    // A character split across two fragments is fine: the message is checked when it is complete.
    Session f = make_client();
    std::string stream =
        encode_frame(Opcode::Text, "\xc3", false, nullptr) + encode_frame(Opcode::Continuation, "\xa9", true, nullptr);
    e = feed_all(f, stream);
    REQUIRE(e.size() == 1);
    CHECK(e[0].type == Event::Type::Text);
    CHECK(e[0].data == "\xc3\xa9");
    // send_text refuses invalid UTF-8.
    CHECK_FALSE(f.send_text("\xff").ok());
}

TEST_CASE("ws codec: protocol violations") {
    auto expect_failure = [](const std::string& data, Role role, int code, const char* what) {
        SessionOptions o;
        o.role = role;
        Session s(o);
        auto events = feed_all(s, data);
        INFO(what);
        REQUIRE(!events.empty());
        CHECK(events.back().type == Event::Type::Failure);
        CHECK(events.back().code == code);
        CHECK_FALSE(events.back().error.empty());
        CHECK_FALSE(events.back().hint.empty());
        CHECK(s.failed());
        CHECK(s.has_output());  // the close frame
    };
    // Reserved bits.
    expect_failure(bytes({0xc1, 0x00}), Role::Client, 1002, "RSV1");
    expect_failure(bytes({0xa1, 0x00}), Role::Client, 1002, "RSV2");
    expect_failure(bytes({0x91, 0x00}), Role::Client, 1002, "RSV3");
    // Unknown opcodes.
    expect_failure(bytes({0x83, 0x00}), Role::Client, 1002, "opcode 3");
    expect_failure(bytes({0x8b, 0x00}), Role::Client, 1002, "opcode 11");
    // A server frame that is masked.
    expect_failure(encode_frame(Opcode::Text, "x", true, kMask), Role::Client, 1002, "masked frame to a client");
    // A client frame that is not masked.
    expect_failure(encode_frame(Opcode::Text, "x", true, nullptr), Role::Server, 1002, "unmasked frame to a server");
    // A fragmented control frame.
    expect_failure(encode_frame(Opcode::Ping, "x", false, nullptr), Role::Client, 1002, "fragmented ping");
    // A control frame longer than 125 bytes.
    expect_failure(bytes({0x89, 126, 0x00, 200}) + std::string(200, 'x'), Role::Client, 1002, "long ping");
    // A continuation with nothing to continue.
    expect_failure(encode_frame(Opcode::Continuation, "x", true, nullptr), Role::Client, 1002, "orphan continuation");
    // A new data frame while a fragmented message is open.
    expect_failure(encode_frame(Opcode::Text, "a", false, nullptr) + encode_frame(Opcode::Text, "b", true, nullptr),
                   Role::Client, 1002, "text inside a message");
    // A length that is not minimal (126 with a value below 126) and a 64-bit length with the top bit set.
    expect_failure(bytes({0x82, 126, 0x00, 0x05}) + "abcde", Role::Client, 1002, "non minimal 16-bit length");
    expect_failure(bytes({0x82, 127, 0, 0, 0, 0, 0, 0, 0x01, 0x00}) + std::string(256, 'a'), Role::Client, 1002,
                   "non minimal 64-bit length");
    expect_failure(bytes({0x82, 127, 0x80, 0, 0, 0, 0, 0, 0, 0}), Role::Client, 1002, "length with the top bit");
}

TEST_CASE("ws codec: control frames may come inside a fragmented message") {
    Session s = make_client();
    std::string stream =
        encode_frame(Opcode::Text, "ab", false, nullptr) + encode_frame(Opcode::Pong, "", true, nullptr) +
        encode_frame(Opcode::Continuation, "c", false, nullptr) + encode_frame(Opcode::Ping, "q", true, nullptr) +
        encode_frame(Opcode::Continuation, "d", true, nullptr);
    auto events = feed_all(s, stream);
    REQUIRE(events.size() == 3);
    CHECK(events[0].type == Event::Type::Pong);
    CHECK(events[1].type == Event::Type::Ping);
    CHECK(events[2].type == Event::Type::Text);
    CHECK(events[2].data == "abcd");
}

TEST_CASE("ws codec: the size limit is checked before the data is buffered") {
    // A header that announces 1 GiB is refused as soon as the header is read, with no payload yet.
    Session s = make_client(1024);
    auto events = feed_all(s, bytes({0x82, 127, 0, 0, 0, 0, 0x40, 0, 0, 0}));
    REQUIRE(events.size() == 1);
    CHECK(events[0].type == Event::Type::Failure);
    CHECK(events[0].code == 1009);
    CHECK(s.failed());

    // The sum of the fragments counts, not each fragment.
    Session f = make_client(10);
    std::string stream = encode_frame(Opcode::Binary, "123456", false, nullptr) +
                         encode_frame(Opcode::Continuation, "78901", true, nullptr);
    events = feed_all(f, stream);
    REQUIRE(!events.empty());
    CHECK(events.back().type == Event::Type::Failure);
    CHECK(events.back().code == 1009);

    // A message of exactly the limit passes.
    Session g = make_client(10);
    events = feed_all(g, encode_frame(Opcode::Binary, "1234567890", true, nullptr));
    REQUIRE(events.size() == 1);
    CHECK(events[0].type == Event::Type::Binary);

    // A 64-bit length near the top of the range does not wrap.
    Session h = make_client(4u * 1024 * 1024);
    events = feed_all(h, bytes({0x82, 127, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}));
    REQUIRE(events.size() == 1);
    CHECK(events[0].code == 1009);

    // send_* refuses what exceeds the limit.
    Session t = make_client(8);
    CHECK_FALSE(t.send_text("123456789").ok());
    CHECK(t.send_text("12345678").ok());
}

TEST_CASE("ws codec: input after a failure or the end of the close handshake is ignored") {
    Session s = make_client();
    auto events = feed_all(s, bytes({0xc1, 0x00}));
    REQUIRE(events.size() == 1);
    events = feed_all(s, encode_frame(Opcode::Text, "late", true, nullptr));
    CHECK(events.empty());
}

TEST_CASE("ws codec: the handshake of RFC 6455 section 1.3") {
    CHECK(accept_key("dGhlIHNhbXBsZSBub25jZQ==") == "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=");
    const std::uint8_t random[16] = {0x74, 0x68, 0x65, 0x20, 0x73, 0x61, 0x6d, 0x70,
                                     0x6c, 0x65, 0x20, 0x6e, 0x6f, 0x6e, 0x63, 0x65};
    CHECK(make_client_key(random) == "dGhlIHNhbXBsZSBub25jZQ==");
}

TEST_CASE("ws codec: addresses") {
    auto u = parse_url("ws://Example.com/chat?room=1");
    REQUIRE(u.ok());
    CHECK_FALSE(u.value().secure);
    CHECK(u.value().host == "example.com");
    CHECK(u.value().port == 80);
    CHECK(u.value().path == "/chat?room=1");
    CHECK(u.value().host_header() == "example.com");

    u = parse_url("wss://example.com:8443");
    REQUIRE(u.ok());
    CHECK(u.value().secure);
    CHECK(u.value().port == 8443);
    CHECK(u.value().path == "/");
    CHECK(u.value().host_header() == "example.com:8443");

    u = parse_url("wss://[::1]:443/x");
    REQUIRE(u.ok());
    CHECK(u.value().host == "::1");
    CHECK(u.value().host_header() == "[::1]");

    for (const char* bad :
         {"http://example.com/", "ws://", "ws://host:99999/", "ws://host:0/", "example.com", "ws://a b/", ""}) {
        INFO(bad);
        auto r = parse_url(bad);
        CHECK_FALSE(r.ok());
        if (!r.ok()) CHECK_FALSE(r.error().hint.empty());
    }
}

TEST_CASE("ws codec: the client request and the server's answer") {
    auto url = parse_url("ws://example.com:9000/chat?x=1").value();
    auto request =
        build_client_request(url, "dGhlIHNhbXBsZSBub25jZQ==", {"chat", "v2.chat"}, {{"Authorization", "Bearer t"}});
    REQUIRE(request.ok());
    const std::string& text = request.value();
    CHECK(text.rfind("GET /chat?x=1 HTTP/1.1\r\n", 0) == 0);
    CHECK(text.find("Host: example.com:9000\r\n") != std::string::npos);
    CHECK(text.find("Upgrade: websocket\r\n") != std::string::npos);
    CHECK(text.find("Connection: Upgrade\r\n") != std::string::npos);
    CHECK(text.find("Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n") != std::string::npos);
    CHECK(text.find("Sec-WebSocket-Version: 13\r\n") != std::string::npos);
    CHECK(text.find("Sec-WebSocket-Protocol: chat, v2.chat\r\n") != std::string::npos);
    CHECK(text.find("Authorization: Bearer t\r\n") != std::string::npos);
    CHECK(text.size() >= 4);
    CHECK(text.substr(text.size() - 4) == "\r\n\r\n");
    CHECK(find_head_end(text) == text.size());
    CHECK(find_head_end(text.substr(0, text.size() - 2)) == std::string::npos);

    // The server side reads it back and answers.
    auto parsed = parse_client_request(text);
    REQUIRE(parsed.ok());
    CHECK(parsed.value().path == "/chat?x=1");
    CHECK(parsed.value().key == "dGhlIHNhbXBsZSBub25jZQ==");
    REQUIRE(parsed.value().subprotocols.size() == 2);
    CHECK(parsed.value().subprotocols[1] == "v2.chat");
    CHECK(parsed.value().header("authorization") == "Bearer t");

    const std::string response = build_server_response(parsed.value(), "v2.chat");
    CHECK(response.rfind("HTTP/1.1 101", 0) == 0);
    auto checked = check_server_response(response, "dGhlIHNhbXBsZSBub25jZQ==", {"chat", "v2.chat"});
    CHECK(checked.ok);
    CHECK(checked.status == 101);
    CHECK(checked.subprotocol == "v2.chat");

    // A subprotocol that was not offered, a wrong accept, a refusal.
    auto notOffered =
        check_server_response(build_server_response(parsed.value(), "other"), "dGhlIHNhbXBsZSBub25jZQ==", {"chat"});
    CHECK_FALSE(notOffered.ok);
    CHECK_FALSE(notOffered.error.empty());
    CHECK_FALSE(notOffered.hint.empty());
    auto wrong = check_server_response(response, "AAAAAAAAAAAAAAAAAAAAAA==", {"chat", "v2.chat"});
    CHECK_FALSE(wrong.ok);
    CHECK(wrong.error.find("Sec-WebSocket-Accept") != std::string::npos);
    for (int status : {400, 401, 403, 404, 429, 500, 503}) {
        auto refused = check_server_response(build_reject_response(status, "No"), "dGhlIHNhbXBsZSBub25jZQ==", {});
        INFO(status);
        CHECK_FALSE(refused.ok);
        CHECK(refused.status == status);
        CHECK_FALSE(refused.error.empty());
        CHECK_FALSE(refused.hint.empty());
    }
    auto notHttp = check_server_response("garbage\r\n\r\n", "k", {});
    CHECK_FALSE(notHttp.ok);
    CHECK(notHttp.status == 0);
}

TEST_CASE("ws codec: the request refuses headers that would break or hijack the handshake") {
    auto url = parse_url("ws://example.com/").value();
    CHECK_FALSE(build_client_request(url, "k", {}, {{"X-A", "line\r\nInjected: 1"}}).ok());
    CHECK_FALSE(build_client_request(url, "k", {}, {{"Bad Name", "v"}}).ok());
    CHECK_FALSE(build_client_request(url, "k", {}, {{"", "v"}}).ok());
    for (const char* own : {"Host", "upgrade", "Connection", "Sec-WebSocket-Key", "sec-websocket-version",
                            "Sec-WebSocket-Protocol", "Sec-WebSocket-Extensions"}) {
        INFO(own);
        auto r = build_client_request(url, "k", {}, {{own, "x"}});
        CHECK_FALSE(r.ok());
        if (!r.ok()) CHECK_FALSE(r.error().hint.empty());
    }
    CHECK_FALSE(build_client_request(url, "k", {"bad protocol"}, {}).ok());
    CHECK_FALSE(build_client_request(url, "k", {"a,b"}, {}).ok());
}

TEST_CASE("ws codec: a server that is not a WebSocket server") {
    CHECK_FALSE(parse_client_request("GET / HTTP/1.1\r\nHost: x\r\n\r\n").ok());
    CHECK_FALSE(parse_client_request("POST / HTTP/1.1\r\nUpgrade: websocket\r\n\r\n").ok());
    // An extension the client did not ask for.
    auto url = parse_url("ws://example.com/").value();
    auto req = parse_client_request(build_client_request(url, "dGhlIHNhbXBsZSBub25jZQ==", {}, {}).value()).value();
    std::string response = build_server_response(req, "");
    response.insert(response.size() - 2, "Sec-WebSocket-Extensions: permessage-deflate\r\n");
    auto r = check_server_response(response, "dGhlIHNhbXBsZSBub25jZQ==", {});
    CHECK_FALSE(r.ok);
    CHECK(r.error.find("xtension") != std::string::npos);
}
