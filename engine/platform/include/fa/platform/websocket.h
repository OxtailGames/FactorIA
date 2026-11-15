// WebSocket connections of a running game (`websocket.connect` in scripts, docs/NETWORKING.md): one client per platform,
// each wrapping what the system already has, so that the player carries no network library of its own.
//
//   Windows    WinHTTP's WebSocket API                 (M98.2b)
//   macOS/iOS  NSURLSessionWebSocketTask               (M98.2b)
//   Linux      libcurl's WebSocket support, dlopen'ed  (M98.2c); missing = not available
//   Android    a socket stream through JNI with fa/platform/websocket_codec.h (M98.2c)
//   web        the browser's WebSocket                 (M98.2d)
//   memory     MemoryWebSocketClient below: no network, a script of a server that a test drives (headless runs and tests)
//   tcp        make_tcp_websocket_client(): plain ws:// over a POSIX socket, for the tests of the codec and the test server
//
// Threads. A client may be asked to connect, and a connection to send or close, from the GAME thread only. What happens on
// the network is reported through events that the connection QUEUES (any thread may push them: an OS callback, a reader
// thread) and the game thread DRAINS with poll() once per frame. No callback of an OS thread ever reaches a script or the
// World. WebSocketEventQueue is the thread-safe queue every implementation uses.
//
// Like fa/platform/http.h, a client only sends: it does not check WHICH address a game may open. That is fa/services/
// network.h (the hosts the game declares in factoria.json, the same list as http.fetch) and the script layer, which check
// the address before they call connect().
#pragma once

#include <cstddef>
#include <deque>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "fa/core/types.h"

namespace fa {

class MemoryWebSocketConnection;

// The ready states of the browser's WebSocket (0 to 3), by name.
enum class WebSocketState { Connecting, Open, Closing, Closed };
const char* websocket_state_name(WebSocketState state);  // "connecting", "open", "closing", "closed"

// One thing that happened on a connection. A connection's events come in this order and never after its Close:
// Open (once, unless the connection never opens), any number of Text and Binary, then Close (once). A connection that
// fails reports Error (what went wrong) and then Close with code 1006, as the browser does.
struct WebSocketEvent {
    enum class Type {
        Open,    // the handshake is done; `subprotocol` is the one the server chose ("" = none)
        Text,    // a whole text message in `data` (valid UTF-8)
        Binary,  // a whole binary message in `data`
        Error,   // `error` says what went wrong and `hint` what to try; `httpStatus` is the answer of a refused handshake (0 = none)
        Close,   // the end: `code`, `reason`, `wasClean` (the closing handshake completed)
    };
    Type type = Type::Close;
    std::string data;
    std::string subprotocol;
    int code = 0;
    std::string reason;
    bool wasClean = false;
    std::string error, hint;
    int httpStatus = 0;

    static WebSocketEvent open(std::string subprotocol = {});
    static WebSocketEvent text(std::string data);
    static WebSocketEvent binary(std::string data);
    static WebSocketEvent failure(std::string error, std::string hint = {}, int httpStatus = 0);
    static WebSocketEvent close(int code, std::string reason, bool wasClean);
};

// A thread-safe queue of events: any thread push()es, the game thread drain()s. After a Close event is pushed the queue
// takes nothing more (what an OS thread reports late is dropped). It holds at most `maxPendingBytes` of messages: a game
// that stops draining while the server keeps sending does not grow without bound; when the limit is reached the pending
// messages are dropped and the queue holds [Error, Close 1008] instead, and push() answers false so that the
// implementation closes the transport.
class WebSocketEventQueue {
public:
    explicit WebSocketEventQueue(std::size_t maxPendingBytes = 32u * 1024 * 1024) : maxPendingBytes_(maxPendingBytes) {}
    // false: the queue overflowed or already ended; the caller should tear the connection down.
    bool push(WebSocketEvent event);
    // Moves the pending events to the end of `out` (in order) and returns how many.
    std::size_t drain(std::vector<WebSocketEvent>& out);
    bool ended() const;  // a Close event was pushed

private:
    mutable std::mutex mutex_;
    std::deque<WebSocketEvent> events_;
    std::size_t pendingBytes_ = 0;
    std::size_t maxPendingBytes_;
    bool ended_ = false;
};

// What connect() needs. The address is absolute ws:// or wss://, already checked against the game's declared hosts.
struct WebSocketRequest {
    std::string url;
    std::vector<std::string> subprotocols;                      // offered to the server, in order
    std::vector<std::pair<std::string, std::string>> headers;   // extra handshake headers (the web cannot send any: it fails)
    double connectTimeoutSec = 15.0;                            // connecting and the handshake together
    // A message longer than this fails the connection (close code 1009); also the longest message send accepts.
    std::size_t maxMessageBytes = 4u * 1024 * 1024;
};

// One connection. Game thread only, except that destruction may be on any thread that does not hold the game's locks.
// Destroying a connection that is open sends a close frame (1001) when it can without waiting, then drops the transport;
// it never delivers an event and should not wait for the network: an implementation whose thread sits in a blocking call
// lets that thread end by itself instead of joining it (the tcp client of the tests does join, so it may wait for a DNS
// lookup in progress).
class WebSocket {
public:
    virtual ~WebSocket() = default;
    virtual WebSocketState state() const = 0;
    // Queue a message. An error (never an exception) says why it was not queued: not open yet, closing, too long, too much
    // unsent data. The text must be valid UTF-8.
    virtual Result<void> send_text(std::string_view text) = 0;
    virtual Result<void> send_binary(const void* data, std::size_t size) = 0;
    // Starts the closing handshake: code 1000 or 3000-4999 (0: none), reason up to 123 bytes. While connecting it abandons
    // the attempt (Error and Close 1006). The Close event follows when the peer answers, or when the implementation gives up
    // waiting (a few seconds). Closing twice does nothing.
    virtual void close(int code, std::string_view reason) = 0;
    // Bytes accepted by send_* and not yet handed to the network.
    virtual std::size_t buffered_amount() const = 0;
    // Appends the events queued since the last call to `out`, in order; returns how many.
    virtual std::size_t poll(std::vector<WebSocketEvent>& out) = 0;
};

// One platform's WebSocket stack.
class WebSocketClient {
public:
    virtual ~WebSocketClient() = default;
    // "winhttp", "nsurlsession", "curl", "socket" (Android), "browser", "memory", "tcp", or "unavailable"
    virtual std::string name() const = 0;
    // False when this machine cannot open WebSockets (Linux without libcurl, a platform whose client is not written yet):
    // connect() then returns the reason as its error.
    virtual bool available() const = 0;
    virtual std::string unavailable_reason() const { return {}; }
    // Starts connecting and returns at once (the connection is Connecting; Open or Error+Close arrives through poll()).
    // The Result's error is for a request that cannot even start (unavailable client, an address that is not ws:// or
    // wss://, a header the handshake refuses): it has a message and a hint that teach.
    virtual Result<std::unique_ptr<WebSocket>> connect(WebSocketRequest request) = 0;
};

// The client of this platform; never null. Until the native clients of M98.2b/c/d land, every platform answers
// available() == false with "WebSocket client for <platform> lands in M98.2b/c/d".
std::unique_ptr<WebSocketClient> make_system_websocket_client();

// A client that is never available, with this reason (what the platform stubs return).
std::unique_ptr<WebSocketClient> make_unavailable_websocket_client(std::string name, std::string reason);

#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)
// Plain ws:// over a POSIX socket and fa/platform/websocket_codec.h, one reader thread per connection. No TLS: wss:// is
// an error that says so. It is what the tests of the codec and the test server run against; a player does not use it.
std::unique_ptr<WebSocketClient> make_tcp_websocket_client();
// libcurl's WebSocket support, loaded with dlopen (Linux's client, written by M98.2c). Until then: unavailable.
std::unique_ptr<WebSocketClient> make_curl_websocket_client();
#endif

// ---------------------------------------------------------------------------------------------------------- memory ---
// The client of headless runs and tests: nothing touches the network. connect() makes a Peer, which is the server's side of
// the connection: a test (or a test script, game.websocket) accepts it, sends messages through it, reads what the game sent,
// closes it or drops it. Single threaded: the game and the test drive it from the same thread, between frames.
//
//   MemoryWebSocketClient server;
//   auto ws = server.connect({.url = "ws://localhost/chat"}).value();
//   server.peer(0)->send_text("hello");     // the game's next poll() sees Open (auto accept) and then the message
class MemoryWebSocketClient final : public WebSocketClient {
public:
    class Peer {
    public:
        struct Received {
            bool binary = false;
            std::string data;
        };
        // What connect() asked for.
        std::string url;
        std::vector<std::string> subprotocols;
        std::vector<std::pair<std::string, std::string>> headers;
        // What the game sent so far, in order.
        std::vector<Received> received;
        bool open = false;     // accepted and not closed
        bool closed = false;   // the connection is over (either side)
        int clientCloseCode = 0;
        std::string clientCloseReason;
        bool clientClosed = false;  // the game called close()

        // Completes the handshake (picks `subprotocol`, which must be one the game offered, or ""). Does nothing when it
        // already happened. Returns false when it is too late (the game gave up) or the subprotocol was not offered.
        bool accept(std::string subprotocol = {});
        // The handshake fails: Error then Close 1006. `httpStatus` is what the server would have answered (403...).
        void refuse(std::string message = "the server refused the connection", int httpStatus = 0);
        void send_text(std::string text);
        void send_binary(std::string data);
        // The server starts the closing handshake: the game gets Close(code, reason) with wasClean true.
        void close(int code = 1000, std::string reason = {});
        // The connection breaks with no close frame: Error then Close 1006, wasClean false.
        void drop(std::string message = "the connection was lost");
        // When true (default) a close() of the game is answered at once: Close event with the same code. When false the
        // game stays Closing until the test calls close().
        bool autoCloseReply = true;

    private:
        friend class MemoryWebSocketClient;
        friend class MemoryWebSocketConnection;
        struct Link;
        std::shared_ptr<Link> link_;
    };

    std::string name() const override { return "memory"; }
    bool available() const override { return true; }
    Result<std::unique_ptr<WebSocket>> connect(WebSocketRequest request) override;

    // Every connection made so far, in order (closed ones stay, so a test can read what they received).
    std::size_t peer_count() const { return peers_.size(); }
    Peer* peer(std::size_t index) { return index < peers_.size() ? peers_[index].get() : nullptr; }
    // true (default): connect() accepts at once (the Open event is in the first poll). false: the test calls accept().
    void set_auto_accept(bool on) { autoAccept_ = on; }
    // The next `count` connect() calls fail like an unreachable server (Error then Close 1006); a call with count 0 clears it.
    void refuse_next(int count, std::string message = "could not connect to the server") {
        refuseCount_ = count;
        refuseMessage_ = std::move(message);
    }
    // Forgets every peer (the connections already made keep working until they close).
    void clear() { peers_.clear(); }

private:
    std::vector<std::shared_ptr<Peer>> peers_;
    bool autoAccept_ = true;
    int refuseCount_ = 0;
    std::string refuseMessage_;
};

}  // namespace fa
