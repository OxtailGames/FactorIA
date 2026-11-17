// WebSocket connections of a running game (`websocket.connect` in scripts, docs/NETWORKING.md): one client per platform,
// each wrapping what the system already has, so that the player carries no network library of its own.
//
//   Windows    WinHTTP's WebSocket API                 ("winhttp"; see "Windows" below)
//   macOS/iOS  Network.framework (TCP, TLS) as the transport and fa/platform/websocket_codec.h ("network")
//   Linux      libcurl (dlopen'ed) as the transport and fa/platform/websocket_codec.h; missing = not available
//   Android    fa/platform/websocket_codec.h over Java's SSLSocket through JNI (wss://), over the tcp client (ws://)
//   web        the browser's WebSocket                 (M98.2d)
//   memory     MemoryWebSocketClient below: no network, a script of a server that a test drives (headless runs and tests)
//   tcp        make_tcp_websocket_client(): plain ws:// over a POSIX socket, for the tests of the codec and the test server
//
// Threads. A client may be asked to connect, and a connection to send or close, from the GAME thread only. What happens on
// the network is reported through events that the connection QUEUES (any thread may push them: an OS callback, a reader
// thread) and the game thread DRAINS with poll() once per frame. No callback of an OS thread ever reaches a script or the
// World. WebSocketEventQueue is the thread-safe queue every implementation uses.
//
// The pattern every client follows (the four native clients of M98.2b/c/d and the tcp client do):
//   1. The connection owns its queue through a std::shared_ptr (std::make_shared<WebSocketEventQueue>()); every OS callback,
//      completion handler, JNI call and reader thread captures THAT shared_ptr (and whatever else it touches) by value, never
//      `this` or a reference to a member of the connection: a callback may run after the connection is gone.
//   2. When push() answers false the queue ended (overflow, or the connection was abandoned): the callback closes the
//      transport and stops. It pushes nothing more and never retries.
//   3. The connection's destructor calls queue->abandon() FIRST (what the callbacks push from then on is dropped), then
//      asks the transport to stop (cancel the task, close with 1001 when that takes no waiting) and returns.
// Destroying a WebSocket runs on the game thread (the script layer's wsRelease, a scene change), so it takes a few
// milliseconds at most: it never joins a thread that may sit in a blocking call, never waits for the network or a DNS lookup.
//
// Windows. WinHTTP keeps part of the protocol to itself, so its client differs from the tcp one in what the tests can see:
// it answers pings by itself and sends keep-alive frames of its own on an open connection (every 30 s, which the client asks for), a
// wrong Sec-WebSocket-Accept may fail inside WinHttpWebSocketCompleteUpgrade with a message that does not name the header,
// and connect() refuses a header value that is not ASCII (WinHTTP sends header values as 8-bit text). A connection destroyed
// while a send is in flight (WinHTTP allows one at a time) sends 1001 once that send has gone out; a send still stuck after
// kWebSocketCloseWaitSec (a server that does not read) ends with the handle closed and no close frame.
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
// fails reports Error (what went wrong) and then Close with code 1006 and wasClean false, whatever the failure was (could not
// connect, a frame that breaks the protocol, a message above maxMessageBytes, the line dropped): that is the browser's
// rule, and every client follows it. The close frame a client sends to the server in those cases (1002, 1007, 1009) is its
// own business and never reaches the game. The one other code a failure can carry is 1008, from the event queue below.
// If the queue overflows before the game drained its first events, those are dropped with the rest: the connection then
// reports only [Error, Close 1008], without the Open (or the messages) that came before.
//
// State and events agree: state() shows Open no later than the moment poll() can deliver the Open event, and when poll()
// delivers the Close event state() is already Closed (a client sets the state BEFORE it pushes the event, never after).
// A game that checks state() right after it read Close sees Closed on every platform.
struct WebSocketEvent {
    enum class Type {
        Open,    // the handshake is done; `subprotocol` is the one the server chose ("" = none)
        Text,    // a whole text message in `data` (valid UTF-8)
        Binary,  // a whole binary message in `data`
        Error,  // `error` says what went wrong and `hint` what to try; `httpStatus` is the answer of a refused handshake (0 = none)
        Close,  // the end: `code`, `reason`, `wasClean` (the closing handshake completed)
    };
    Type type = Type::Close;
    std::string data;
    std::string subprotocol;
    int code = 0;
    std::string reason;
    bool wasClean = false;
    std::string error, hint;
    int httpStatus = 0;

    static WebSocketEvent open(std::string chosenSubprotocol = {});
    static WebSocketEvent text(std::string message);
    static WebSocketEvent binary(std::string message);
    static WebSocketEvent failure(std::string what, std::string advice = {}, int status = 0);
    static WebSocketEvent close(int closeCode, std::string closeReason, bool clean);
};

// A thread-safe queue of events: any thread push()es, the game thread drain()s. After a Close event is pushed the queue
// takes nothing more (what an OS thread reports late is dropped). It holds at most `maxPendingBytes` of messages: a game
// that stops draining while the server keeps sending does not grow without bound; when the limit is reached the pending
// events (an Open the game did not read yet included) are dropped and the queue holds [Error, Close 1008] instead, and
// push() answers false so that the implementation closes the transport.
//
// Lifetime: allocate it with std::make_shared and let every callback capture the shared_ptr (see the pattern above); the
// connection's destructor calls abandon(). The queue is not copyable and never lives as a plain member of a connection.
//
// Size it for the connection: std::make_shared<WebSocketEventQueue>(WebSocketEventQueue::limit_for(request.maxMessageBytes)).
// The default limit (32 MB) is below the longest message a request may allow (64 MB), and a legal message must never end in
// "too many unread messages".
class WebSocketEventQueue {
public:
    explicit WebSocketEventQueue(std::size_t maxPendingBytes = 32u * 1024 * 1024) : maxPendingBytes_(maxPendingBytes) {}
    // What every client passes to the constructor: the larger of 32 MB and two messages of `maxMessageBytes` (saturating).
    static std::size_t limit_for(std::size_t maxMessageBytes) {
        constexpr std::size_t kFloor = 32u * 1024 * 1024;
        constexpr std::size_t kMax = static_cast<std::size_t>(-1);
        const std::size_t twice = maxMessageBytes > kMax / 2 ? kMax : maxMessageBytes * 2;
        return twice > kFloor ? twice : kFloor;
    }
    WebSocketEventQueue(const WebSocketEventQueue&) = delete;
    WebSocketEventQueue& operator=(const WebSocketEventQueue&) = delete;
    // false: the queue overflowed, ended or was abandoned; the caller closes the transport, stops and pushes nothing more.
    bool push(WebSocketEvent event);
    // Moves the pending events to the end of `out` (in order) and returns how many.
    std::size_t drain(std::vector<WebSocketEvent>& out);
    bool ended() const;  // a Close event was pushed, the queue overflowed, or it was abandoned
    // The connection is gone: drops what is pending and ends the queue WITHOUT an event; every later push() answers false.
    void abandon();

private:
    mutable std::mutex mutex_;
    std::deque<WebSocketEvent> events_;
    std::size_t pendingBytes_ = 0;
    std::size_t maxPendingBytes_;
    bool ended_ = false;
};

// How long a closing handshake waits for the server's close frame before the connection is dropped (Close 1006, wasClean
// false). One value for every client that does its own waiting (the tcp, curl, Android and macOS/iOS clients, and the
// WinHTTP one for its close wait and a send stuck at destruction).
inline constexpr double kWebSocketCloseWaitSec = 5.0;

// What connect() needs. The address is absolute ws:// or wss://, already checked against the game's declared hosts.
struct WebSocketRequest {
    std::string url;
    std::vector<std::string> subprotocols;  // offered to the server, in order
    std::vector<std::pair<std::string, std::string>>
        headers;                      // extra handshake headers (the web cannot send any: it fails)
    double connectTimeoutSec = 15.0;  // connecting and the handshake together
    // A message longer than this fails the connection (Error, then Close 1006; the server is sent 1009); also the longest
    // message send accepts. A client that reads frame by frame checks it as the bytes arrive; where the platform buffers a
    // whole message before it hands it over (the browser) it is checked on arrival.
    std::size_t maxMessageBytes = 4u * 1024 * 1024;
    // There is no keep-alive field: pings and the answers to the server's pings are the platform's own. Every client answers
    // the server's pings; WinHTTP also sends its own keep-alive frames, and the others (the macOS/iOS, tcp, curl
    // and Android clients) send none, and the browser does what it likes, so a connection that must survive idle time needs a
    // message from the game now and then.
};

// One connection. Game thread only, including destruction (the script layer drops it in wsRelease and on a scene change).
// Destroying a connection takes a few milliseconds at most and never delivers an event: it follows the pattern above (abandon
// the queue first, ask the transport to stop, return), sends a close frame (1001) only when that takes no waiting, and does
// not join a thread that may be in a blocking call (a DNS lookup, a read): such a thread ends by itself.
class WebSocket {
public:
    virtual ~WebSocket() = default;
    virtual WebSocketState state() const = 0;
    // Queue a message. An error (never an exception) says why it was not queued: not open yet, closing, too long, too much
    // unsent data. The text must be valid UTF-8.
    virtual Result<void> send_text(std::string_view text) = 0;
    virtual Result<void> send_binary(const void* data, std::size_t size) = 0;
    // Starts the closing handshake: `code` is 1000 or 3000-4999 (0: none), `reason` valid UTF-8 up to 123 bytes
    // (ws::check_close_request). Anything else is an error that says so, and nothing happens. The Close event follows when
    // the peer answers, or after kWebSocketCloseWaitSec without an answer (Error, then Close 1006, wasClean false). Closing
    // twice, or a closed connection, is not an error.
    //
    // Closing while the connection is still Connecting abandons the attempt: state() is Closing at once (a client may
    // already have ended the attempt by then, and say Closed), and Closed from the moment its Error and Close 1006
    // (wasClean false) are in the queue, so before poll() delivers them. The Error says close() was called before the
    // connection opened.
    virtual Result<void> close(int code, std::string_view reason) = 0;
    // Bytes accepted by send_* and not yet handed to the network.
    virtual std::size_t buffered_amount() const = 0;
    // Appends the events queued since the last call to `out`, in order; returns how many.
    virtual std::size_t poll(std::vector<WebSocketEvent>& out) = 0;
};

// One platform's WebSocket stack.
class WebSocketClient {
public:
    virtual ~WebSocketClient() = default;
    // "winhttp", "network" (macOS, iOS), "curl", "socket" (Android), "browser", "memory", "tcp", or "unavailable"
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

// The client of this platform; never null. Windows: WinHTTP ("winhttp"). Linux: the libcurl client
// (make_curl_websocket_client), available when libcurl 7.45 or newer can be loaded.
std::unique_ptr<WebSocketClient> make_system_websocket_client();

// A client that is never available, with this reason (what the platform stubs return).
std::unique_ptr<WebSocketClient> make_unavailable_websocket_client(std::string name, std::string reason);

#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)
// Plain ws:// over a POSIX socket and fa/platform/websocket_codec.h, one reader thread per connection. No TLS: wss:// is
// an error that says so. It is what the tests of the codec and the test server run against, and what Android's client opens
// its ws:// addresses with; no other player uses it.
std::unique_ptr<WebSocketClient> make_tcp_websocket_client();
// Linux's client: libcurl, loaded with dlopen, opens the connection (proxy, TCP, TLS) and fa/platform/websocket_codec.h speaks
// the protocol over curl_easy_send/curl_easy_recv, so any libcurl from 7.45 works, with or without its own WebSocket support.
// Unavailable (with the reason) where libcurl is missing or older. macOS builds it too, so its tests run there.
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
        bool open = false;    // accepted and not closed
        bool closed = false;  // the connection is over (either side)
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
        void deliver(WebSocketEvent event);
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
