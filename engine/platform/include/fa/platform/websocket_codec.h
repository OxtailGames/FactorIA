// RFC 6455 (the WebSocket protocol) as pure functions and one state machine, with no socket, no thread and no clock: bytes
// go in, frames, messages and bytes come out. Every client that talks WebSocket over a stream it owns uses it (the plain
// TCP client of the tests, Android's client over a JNI socket, the Apple client over Network.framework) and so does the loopback server of the tests
// (engine/platform/tests/ws_test_server.h). Clients that the system provides (WinHTTP, libcurl, the
// browser) do their own framing; WinHTTP's client uses only the handshake checks (check_server_response, with the same
// messages as the other clients, and build_client_request to refuse a bad header before anything is sent).
//
//   handshake   make_client_key, accept_key, build_client_request, check_server_response (client side);
//               parse_client_request, build_server_response, build_reject_response (server side).
//   frames      encode_frame builds one frame (masked or not, any opcode, fin or not, 7/16/64-bit length).
//   session     Session reads frames from a byte stream (fragmented in any way) and gives whole messages: it answers pings,
//               answers a close with a close, joins fragments, validates UTF-8 and the close codes, refuses a message over
//               the size limit before it buffers it, and turns every protocol violation into a Failure event plus the close
//               frame RFC 6455 asks for (1002, 1007, 1009).
//
// Limits: no extensions (RSV bits must be 0, no Sec-WebSocket-Extensions) and no compression. A text message is checked
// for UTF-8 when it is complete (not byte by byte as it arrives).
#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <random>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "fa/core/types.h"

namespace fa::ws {

enum class Opcode : std::uint8_t { Continuation = 0, Text = 1, Binary = 2, Close = 8, Ping = 9, Pong = 10 };

// Close codes (RFC 6455 7.4.1).
namespace close_code {
inline constexpr int kNormal = 1000;
inline constexpr int kGoingAway = 1001;
inline constexpr int kProtocolError = 1002;
inline constexpr int kUnsupportedData = 1003;
inline constexpr int kNoStatus = 1005;  // never on the wire: "the close frame had no code"
inline constexpr int kAbnormal = 1006;  // never on the wire: "the connection broke without a close frame"
inline constexpr int kInvalidData = 1007;
inline constexpr int kPolicyViolation = 1008;
inline constexpr int kMessageTooBig = 1009;
inline constexpr int kMandatoryExtension = 1010;
inline constexpr int kInternalError = 1011;
inline constexpr int kServiceRestart = 1012;
inline constexpr int kTryAgainLater = 1013;
inline constexpr int kBadGateway = 1014;
inline constexpr int kTlsFailure = 1015;  // never on the wire
}  // namespace close_code

inline constexpr std::size_t kMaxControlPayload = 125;  // ping, pong, close
inline constexpr std::size_t kMaxCloseReasonBytes = 123;
inline constexpr std::size_t kDefaultMaxMessageBytes = 4u * 1024 * 1024;

// Codes that may appear in a close frame (1000-1003, 1007-1014, 3000-4999).
bool close_code_valid_on_wire(int code);
// Codes a script may ask for, like the browser's close(): 1000 or 3000-4999.
bool close_code_app_may_send(int code);
// What WebSocket::close() accepts: code 0 (none) or close_code_app_may_send, a reason of valid UTF-8 up to
// kMaxCloseReasonBytes. Otherwise an error with a hint; every client and the script layer use this one check.
Result<void> check_close_request(int code, std::string_view reason);

// One frame. `payload` is written as is and masked when `maskKey` is not null (4 bytes: clients mask, servers do not). The
// length uses the shortest form (7, 16 or 64 bits), as the RFC requires.
std::string encode_frame(Opcode opcode, std::string_view payload, bool fin, const std::uint8_t* maskKey);
// The payload of a close frame: the code in 2 bytes and the reason. A code of 0 gives an empty payload.
std::string close_payload(int code, std::string_view reason);

// ------------------------------------------------------------------------------------------------------ handshake ---
// A ws:// or wss:// address taken apart. The address has already passed fa/services/network.h; this parser is only strict
// enough to build a request from it.
struct Url {
    bool secure = false;              // wss
    std::string host;                 // lower case, IPv6 without brackets
    int port = 0;                     // the real port (80 or 443 when the address has none)
    std::string path;                 // path and query, always starts with "/"
    std::string host_header() const;  // "host" or "host:port" (port only when it is not the default), IPv6 in brackets
    // The host as an address writes it: IPv6 in brackets ("[::1]"), any other host as it is. What WinHttpConnect takes.
    std::string host_in_brackets() const;
};
// Relies on check_ws_url (fa/services/network.h), which the script layer runs first: it does not decide which hosts a game may
// open, and it accepts what it can build a request from (any ws:// or wss:// address with a valid host and port).
Result<Url> parse_url(std::string_view url);

// Sec-WebSocket-Key: base64 of 16 random bytes (the caller supplies the randomness).
std::string make_client_key(const std::uint8_t random16[16]);
// Sec-WebSocket-Accept for a key: base64(SHA-1(key + the GUID of the RFC)).
std::string accept_key(std::string_view clientKey);

// The "GET / HTTP/1.1 ... Upgrade: websocket" request, ending with the empty line. Fails on a header with a line break or
// a name that is not a token, on a header the handshake sets itself, or on a subprotocol that is not a token.
Result<std::string> build_client_request(const Url& url, std::string_view key,
                                         const std::vector<std::string>& subprotocols,
                                         const std::vector<std::pair<std::string, std::string>>& headers);

// The index just after the empty line that ends an HTTP head ("\r\n\r\n"), or npos while it has not all arrived.
std::size_t find_head_end(std::string_view data);

struct HandshakeResult {
    bool ok = false;
    int status = 0;           // the HTTP status line's code (0 when the answer is not HTTP)
    std::string subprotocol;  // the one the server chose ("" when none)
    std::string error, hint;  // when !ok: what is wrong and what to try
};
// Checks the server's answer to build_client_request: status 101, Upgrade, Connection, the right Sec-WebSocket-Accept, a
// subprotocol that the client offered, no extension. `head` is the text up to and including the empty line.
HandshakeResult check_server_response(std::string_view head, std::string_view key,
                                      const std::vector<std::string>& offeredSubprotocols);

struct ClientRequest {
    std::string path;                                          // "/chat?room=1"
    std::string key;                                           // Sec-WebSocket-Key
    std::vector<std::string> subprotocols;                     // offered, in order
    std::vector<std::pair<std::string, std::string>> headers;  // every header, names in lower case
    std::string header(const std::string& lowerName) const;    // "" when absent
};
// The server side: the request that a client sent. Fails (with what is wrong) when it is not a WebSocket upgrade.
Result<ClientRequest> parse_client_request(std::string_view head);
// "HTTP/1.1 101 Switching Protocols" with the accept key and the chosen subprotocol ("" = none).
std::string build_server_response(const ClientRequest& request, std::string_view subprotocol);
// A plain HTTP answer that refuses the upgrade, e.g. (403, "Forbidden"); Connection: close, empty body.
std::string build_reject_response(int status, std::string_view reason);

// ------------------------------------------------------------------------------------------------------ session ---
enum class Role { Client, Server };

struct Event {
    enum class Type {
        Text,     // a whole text message (valid UTF-8) in `data`
        Binary,   // a whole binary message in `data`
        Ping,     // `data`: the payload; the pong is already queued in take_output()
        Pong,     // `data`: the payload
        Close,    // the peer's close frame: `code` (1005 when it had none) and `reason`; the answer is queued
        Failure,  // the peer broke the protocol: `error` and `hint` say how; the close frame (`code`) is queued
    };
    Type type = Type::Text;
    std::string data;
    int code = 0;
    std::string reason;
    std::string error, hint;
};

struct SessionOptions {
    Role role = Role::Client;
    // A message (all its fragments together) longer than this is a failure with code 1009; a frame that announces more is
    // refused before one byte of it is buffered. It is also the longest message send_text and send_binary accept.
    std::size_t maxMessageBytes = kDefaultMaxMessageBytes;
    // A client must mask every frame with a fresh unpredictable key. Called once per frame; null = std::random_device,
    // made when the first frame is masked (a server, or a client with this function, never makes one). A server never masks.
    std::function<std::uint32_t()> maskKey;
};

// One connection after the handshake. Not thread safe: a transport that reads and writes on different threads locks around
// it. Memory: the input buffer holds at most one frame header; a data message is built in place and never exceeds the limit.
class Session {
public:
    explicit Session(SessionOptions options = {});

    // Bytes read from the peer, in any chunks (even a byte at a time). Appends what they completed to `events`. After a
    // Failure or after the closing handshake is over, further input is ignored.
    void feed(const void* data, std::size_t size, std::vector<Event>& events);

    // The bytes to write to the peer (pongs, close answers, the frames of send_*); empties the queue.
    std::string take_output();
    bool has_output() const { return !out_.empty(); }
    std::size_t pending_output_bytes() const { return out_.size(); }

    Result<void> send_text(std::string_view text);
    Result<void> send_binary(const void* data, std::size_t size);
    Result<void> send_ping(std::string_view payload = {});
    // Starts the closing handshake (RFC 6455 5.5.1). Sending close twice, or after the peer's close, does nothing.
    Result<void> close(int code, std::string_view reason = {});

    bool close_sent() const { return closeSent_; }
    bool close_received() const { return closeReceived_; }
    // True once the closing handshake is complete (close sent and received) or the session failed: the transport may close.
    bool done() const { return failed_ || (closeSent_ && closeReceived_); }
    bool failed() const { return failed_; }

private:
    enum class Stage { Header, Payload };
    void queue(Opcode op, std::string_view payload, bool fin = true);
    void fail(int code, std::string error, std::string hint, std::vector<Event>& events);
    void finish_frame(std::vector<Event>& events);
    std::uint32_t next_mask();

    SessionOptions options_;
    std::unique_ptr<std::random_device> random_;  // made by next_mask() for a client without options_.maskKey
    std::uint64_t fallback_ = 0;                  // the keys when this system has no std::random_device
    std::string in_;                              // header bytes not parsed yet
    std::string out_;
    std::string message_;  // the data message being joined
    std::string control_;  // the control frame being read
    Stage stage_ = Stage::Header;
    Opcode opcode_ = Opcode::Text;  // of the frame being read
    bool fin_ = true;
    bool masked_ = false;
    std::uint8_t mask_[4] = {0, 0, 0, 0};
    std::uint64_t remaining_ = 0;  // payload bytes still to come
    std::uint64_t index_ = 0;      // payload bytes of this frame already read (for the mask)
    bool inMessage_ = false;
    bool messageIsText_ = false;
    bool closeSent_ = false, closeReceived_ = false, failed_ = false;
};

}  // namespace fa::ws
