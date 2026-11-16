// What the WebSocket clients that own their byte stream share (fa/platform/websocket.h): the plain tcp client
// (websocket_tcp_posix.cpp) and Android's TLS client over a JNI socket (websocket_android.cpp). Private to fa_platform.
//
// StreamCore holds everything one connection's threads and the game thread share: the event queue, the fa::ws::Session
// (handshake, framing, masking, UTF-8, limits), the bytes waiting to be written, the state and the flags that stop the
// threads. A transport derives from it and supplies run() (its thread: connect, handshake, read and write) and wake() /
// interrupt() (how the game thread reaches that thread). The threads own a shared_ptr to the core, so it may outlive the
// StreamWebSocket handle the game holds: destroying the handle abandons the queue, sets stop_, calls interrupt() and returns.
#pragma once

#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)

#include <atomic>
#include <chrono>
#include <cstddef>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <vector>

#include "fa/platform/websocket.h"
#include "fa/platform/websocket_codec.h"

namespace fa::ws_stream {

using Clock = std::chrono::steady_clock;

// The most the game may have queued and not yet sent: send_* fails above it (the script reads bufferedAmount).
inline constexpr std::size_t kMaxBuffered = 16u * 1024 * 1024;
// How long a closing handshake waits for the peer's close frame before the connection is dropped (the shared constant).
inline constexpr auto kCloseWait =
    std::chrono::duration_cast<Clock::duration>(std::chrono::duration<double>(kWebSocketCloseWaitSec));
// The longest answer to the opening handshake a server may send before its empty line.
inline constexpr std::size_t kMaxHandshakeBytes = 64u * 1024;

// How the reading part of a connection ended; finish() turns it into the last events.
struct Ending {
    int closeCode = ws::close_code::kAbnormal;
    std::string closeReason;
    bool peerClosed = false;  // the peer's close frame arrived
    bool failed = false;      // the peer broke the protocol (the codec reported a Failure)
    bool lost = false;        // the stream broke or timed out without a close frame
};

class StreamCore : public std::enable_shared_from_this<StreamCore> {
public:
    StreamCore(WebSocketRequest request, ws::Url url);
    virtual ~StreamCore() = default;
    StreamCore(const StreamCore&) = delete;
    StreamCore& operator=(const StreamCore&) = delete;

    // Runs run() on a detached thread that owns a shared_ptr to this core. No thread to be had: Error and Close 1006.
    void start();
    // The game let go of the connection: nothing it reports is delivered, and the thread ends without being waited for.
    void release();

    WebSocketState state() const { return state_.load(); }
    Result<void> send_text(std::string_view text);
    Result<void> send_binary(const void* data, std::size_t size);
    Result<void> close(int code, std::string_view reason);
    std::size_t buffered_amount() const;
    std::size_t poll(std::vector<WebSocketEvent>& out);

protected:
    // The connection's thread: connect, handshake, then read and write until the end.
    virtual void run() = 0;
    // Output was queued, or a close was asked: the thread looks again. May be called with mutex_ held.
    virtual void wake() = 0;
    // The game stops the connection (destroyed, or closed while connecting): a blocking call of the thread must end.
    // Called WITHOUT mutex_ held. Default: wake().
    virtual void interrupt() { wake(); }
    // Called by poll() on the game thread, once per frame, before the events are drained. Default: nothing.
    virtual void tick() {}

    bool stopping() const { return stop_ || abort_ || dead_; }
    // When connecting and the handshake must be over: now + connectTimeoutSec (clamped to 0 .. one day).
    Clock::time_point connect_deadline() const;
    // Pushes an event; false (the queue overflowed or the game let go) sets dead_: the caller closes the transport.
    bool emit(WebSocketEvent event);
    // A connection that never opened: state Closed, then Error and Close 1006.
    void fail_connect(const std::string& error, const std::string& hint, int status = 0);
    // The connecting part stopped: the game closed it (Error and Close 1006), or it was destroyed or its queue ended (silent).
    // Does nothing when the failure was already reported. Always leaves the state Closed.
    void finish_aborted();

    // The key and the request of the opening handshake; false after reporting.
    bool begin_handshake(std::string& key, std::string& request);
    // `data` is what the server answered so far: 1 the answer is complete and right (`leftover` gets the bytes after it,
    // subprotocol_ the choice), 0 more is needed, -1 it is wrong (reported).
    int check_handshake(const std::string& data, const std::string& key, std::string& leftover);
    // Connecting -> Open unless the connection was closed, destroyed or ended meanwhile, then the Open event. false: the
    // caller closes the transport and calls finish_aborted().
    bool open_connection();

    // Bytes read from the peer: through the session, then the events they completed. Wakes the thread when the session
    // queued an answer (a pong, the answer to a close).
    void feed(const void* data, std::size_t size, Ending& ending);
    // Destroyed (stop_) or the queue ended (dead_) while open: queue the close frame (1001 or 1008).
    void queue_goodbye();
    // The end of a connection that opened: state Closed, then the last events (nothing when stop_ or dead_).
    void finish(const Ending& ending);

    void take_session_output() { outgoing_ += session_.take_output(); }  // mutex_ held
    std::size_t pending_bytes() const {
        return outgoing_.size() - sent_ + session_.pending_output_bytes();
    }  // mutex_ held

    WebSocketRequest request_;
    ws::Url url_;
    std::shared_ptr<WebSocketEventQueue> queue_;
    // Guards session_, outgoing_, sent_, closeAsked_ and the transitions out of Connecting and Open.
    mutable std::mutex mutex_;
    ws::Session session_;
    std::string outgoing_;  // bytes taken from the session, from sent_ on not yet written
    std::size_t sent_ = 0;
    std::atomic<WebSocketState> state_{WebSocketState::Connecting};
    std::atomic<bool> stop_{false}, abort_{false};
    std::atomic<bool> dead_{false};  // the queue ended under the thread (push answered false)
    Clock::time_point closeAsked_;   // when close() turned Open into Closing
    std::string subprotocol_;

private:
    Result<void> can_send() const;  // mutex_ held
    void handle(std::vector<ws::Event>& events, Ending& ending);
};

// What the game holds: forwards to the core and lets go of it on destruction without waiting for its threads.
class StreamWebSocket final : public WebSocket {
public:
    explicit StreamWebSocket(std::shared_ptr<StreamCore> core) : core_(std::move(core)) { core_->start(); }
    ~StreamWebSocket() override { core_->release(); }
    WebSocketState state() const override { return core_->state(); }
    Result<void> send_text(std::string_view text) override { return core_->send_text(text); }
    Result<void> send_binary(const void* data, std::size_t size) override { return core_->send_binary(data, size); }
    Result<void> close(int code, std::string_view reason) override { return core_->close(code, reason); }
    std::size_t buffered_amount() const override { return core_->buffered_amount(); }
    std::size_t poll(std::vector<WebSocketEvent>& out) override { return core_->poll(out); }

private:
    std::shared_ptr<StreamCore> core_;
};

// The checks connect() makes before it starts anything: the address parses, and the handshake accepts the headers and
// subprotocols. An error teaches; it is what connect() returns.
Result<ws::Url> check_request(const WebSocketRequest& request);

// Plain ws:// over a POSIX socket (websocket_tcp_posix.cpp): what make_tcp_websocket_client() connects with, and what
// Android's client uses for its ws:// addresses. `url` passed check_request and is not secure.
std::shared_ptr<StreamCore> make_tcp_core(WebSocketRequest request, ws::Url url);

}  // namespace fa::ws_stream

#endif
