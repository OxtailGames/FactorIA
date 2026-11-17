// macOS and iOS: Network.framework opens the connection (nw_connection: DNS, TCP and, for wss://, TLS with the system's
// certificates) and fa/platform/websocket_codec.h speaks the protocol over it, like the tcp client (websocket_tcp_posix.cpp)
// and Android's (websocket_android.cpp): the handshake, the framing, the answers to the server's pings, the size limit
// checked as the bytes arrive, and the closing handshake are the engine's own (websocket_stream.h), so a close sends a real
// close frame with its code and reason and waits up to kWebSocketCloseWaitSec for the server's. Network.framework is not
// subject to App Transport Security (that is NSURLSession's), so a plain ws:// address works wherever the script layer
// allows one (localhost).
//
// NSURLSessionWebSocketTask did this before; on the macOS 26 CI runners it ended the TCP connection with a FIN and no close
// frame, whatever queue the close was asked from, so a server never learned the code. Nothing here asks the system for a
// WebSocket: it only moves bytes.
//
// Threads. One thread per connection (StreamCore::start, detached) connects, does the handshake, and then hands the
// session's output to the network and feeds it what arrives, like the tcp client's poll loop. Network.framework calls back
// on a serial dispatch queue of the connection; those callbacks touch only the members under ioMutex_ (what arrived, the
// state, the sends that completed) and wake the thread through cv_, and they hold a weak_ptr to the core, never a strong one,
// so the connection's handlers keep nothing alive and a callback that runs after the core is gone does nothing. The game's
// calls take StreamCore's mutex_ and wake() takes ioMutex_ (always in that order; a callback never takes mutex_), so neither
// side waits for the other while holding the lock it needs. Destroying the game's handle abandons the queue, sets stop_ and
// wakes the thread, and returns at once: the thread then sends 1001, waits up to kWebSocketCloseWaitSec for the server's
// answer (the events go nowhere), cancels the connection and waits (bounded) for its cancelled state before it lets go of
// the core.
#import <Foundation/Foundation.h>
#import <Network/Network.h>

#include <algorithm>
#include <cerrno>
#include <chrono>
#include <condition_variable>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <utility>

#include "fa/core/engine_version.h"
#include "fa/core/strings.h"
#include "fa/platform/websocket.h"
#include "fa/platform/websocket_codec.h"
#include "websocket_stream.h"

namespace fa {

namespace {

using ws_stream::Clock;
using ws_stream::kCloseWait;

// The most bytes handed to one nw_connection_send: one send is in flight at a time, and what it holds still counts in
// bufferedAmount until the system has taken it.
constexpr std::size_t kSendChunk = 1024 * 1024;
// The most one read asks for.
constexpr std::uint32_t kReadChunk = 64 * 1024;
// How long the thread waits for the cancelled state once it cancelled the connection (it is detached: nobody waits for it).
constexpr auto kCancelWait = std::chrono::seconds(2);
// The longest the thread sleeps between two looks at its deadlines.
constexpr auto kTurn = std::chrono::milliseconds(500);

std::string to_std(NSString* s) { return s ? std::string([s UTF8String]) : std::string(); }

// The system's own words for an error ("" for none).
std::string error_text(nw_error_t error) {
    if (!error) return {};
    CFErrorRef cf = nw_error_copy_cf_error(error);
    if (!cf) return {};
    NSError* ns = CFBridgingRelease(cf);
    return to_std(ns.localizedDescription);
}

// The TLS errors (OSStatus, Security/SecureTransport.h) that mean the server's certificate is not trusted.
bool is_certificate_error(int code) {
    switch (code) {
        case -9807:  // errSSLXCertChainInvalid
        case -9808:  // errSSLBadCert
        case -9812:  // errSSLUnknownRootCert
        case -9813:  // errSSLNoRootCert
        case -9814:  // errSSLCertExpired
        case -9815:  // errSSLCertNotYetValid
        case -9825:  // errSSLPeerBadCert
        case -9827:  // errSSLPeerCertRevoked
        case -9828:  // errSSLPeerCertExpired
        case -9829:  // errSSLPeerCertUnknown
        case -9843:  // errSSLHostNameMismatch
        case -67843:  // errSecNotTrusted
            return true;
        default: return false;
    }
}

class AppleCore final : public ws_stream::StreamCore {
public:
    AppleCore(WebSocketRequest request, ws::Url url) : StreamCore(std::move(request), std::move(url)) {}

private:
    // --- what Network.framework's callbacks report (its queue), under ioMutex_ ---------------------------------------

    void on_state(nw_connection_state_t state, nw_error_t error) {
        {
            std::lock_guard<std::mutex> lock(ioMutex_);
            nwState_ = state;
            if (error && !nwError_) nwError_ = error;
            // The thread sees only the latest state: a waiting-with-an-error that a preparing follows before it wakes
            // would be missed, so the failure stays.
            if (state == nw_connection_state_waiting && error) waitingFailed_ = true;
            stateChanged_ = true;
        }
        cv_.notify_all();
    }

    void on_received(dispatch_data_t content, nw_content_context_t context, bool complete, nw_error_t error) {
        {
            std::lock_guard<std::mutex> lock(ioMutex_);
            receiving_ = false;
            if (content) {
                dispatch_data_apply(content, ^bool(dispatch_data_t, size_t, const void* buffer, size_t size) {
                    inbox_.append(static_cast<const char*>(buffer), size);
                    return true;
                });
            }
            // A stream has one context, the final one: complete means the server closed its side (a FIN).
            if (error || (complete && (!context || nw_content_context_get_is_final(context)))) readEnded_ = true;
            if (error && !nwError_) nwError_ = error;
        }
        cv_.notify_all();
    }

    void on_sent(nw_error_t error) {
        {
            std::lock_guard<std::mutex> lock(ioMutex_);
            ++sendsDone_;
            if (error) sendFailed_ = true;
        }
        cv_.notify_all();
    }

    // --- the game thread (StreamCore) --------------------------------------------------------------------------------

    void wake() override {
        {
            std::lock_guard<std::mutex> lock(ioMutex_);
            woken_ = true;
        }
        cv_.notify_all();
    }

    // --- the connection's thread -------------------------------------------------------------------------------------

    std::weak_ptr<AppleCore> weak_self() { return std::static_pointer_cast<AppleCore>(shared_from_this()); }

    // Asks for the next bytes unless a read is outstanding or the stream ended.
    void arm_receive(nw_connection_t connection) {
        {
            std::lock_guard<std::mutex> lock(ioMutex_);
            if (receiving_ || readEnded_) return;
            receiving_ = true;
        }
        std::weak_ptr<AppleCore> weak = weak_self();
        nw_connection_receive(connection, 1, kReadChunk,
                              ^(dispatch_data_t content, nw_content_context_t context, bool complete, nw_error_t error) {
                                  if (auto self = weak.lock()) self->on_received(content, context, complete, error);
                              });
    }

    // Moves the session's output to outgoing_ and, when no send is in flight, hands the next chunk to the network.
    void flush(nw_connection_t connection) {
        dispatch_data_t chunk = nil;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            take_session_output();
            if (inFlight_ == 0 && sent_ < outgoing_.size()) {
                inFlight_ = std::min(outgoing_.size() - sent_, kSendChunk);
                chunk = dispatch_data_create(outgoing_.data() + sent_, inFlight_, nullptr, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
            }
        }
        if (!chunk) return;
        std::weak_ptr<AppleCore> weak = weak_self();
        nw_connection_send(connection, chunk, NW_CONNECTION_DEFAULT_MESSAGE_CONTEXT, true, ^(nw_error_t error) {
            if (auto self = weak.lock()) self->on_sent(error);
        });
    }

    // The send in flight completed: its bytes leave the buffer.
    void sent_one() {
        std::lock_guard<std::mutex> lock(mutex_);
        sent_ += inFlight_;
        inFlight_ = 0;
        if (sent_ >= outgoing_.size()) {
            outgoing_.clear();
            sent_ = 0;
        } else if (sent_ >= kSendChunk && sent_ * 2 >= outgoing_.size()) {
            // a game that keeps sending never lets the buffer empty: trim it, but only once half of it is sent (every chunk
            // would copy the rest again)
            outgoing_.erase(0, sent_);
            sent_ = 0;
        }
    }

    // One turn: hands what is queued to the network, waits until something happens or `until`, and appends what arrived to
    // `got`. false: the connection broke (a send or a read failed, the server closed the stream, the connection failed).
    bool pump(nw_connection_t connection, Clock::time_point until, std::string& got) {
        flush(connection);
        int done = 0;
        bool ended = false, failed = false;
        {
            std::unique_lock<std::mutex> lock(ioMutex_);
            cv_.wait_until(lock, until, [this] {
                return woken_ || stateChanged_ || !inbox_.empty() || readEnded_ || sendsDone_ > 0 || sendFailed_;
            });
            woken_ = false;
            stateChanged_ = false;
            got += inbox_;
            inbox_.clear();
            done = sendsDone_;
            sendsDone_ = 0;
            failed = sendFailed_;
            ended = readEnded_ || nwState_ == nw_connection_state_failed || nwState_ == nw_connection_state_cancelled;
        }
        if (done > 0) sent_one();
        if (failed || ended) return false;
        arm_receive(connection);
        return true;
    }

    // What went wrong while connecting, in words that teach.
    void describe(nw_error_t error, std::string& message, std::string& hint) const {
        const std::string where = url_.host_in_brackets() + ":" + std::to_string(url_.port);
        const std::string text = error_text(error);
        const int code = error ? nw_error_get_error_code(error) : 0;
        switch (error ? nw_error_get_error_domain(error) : nw_error_domain_invalid) {
            case nw_error_domain_dns:
                message = "could not find the server " + url_.host + (text.empty() ? "" : " (" + text + ")");
                hint = "Check the address and the connection.";
                return;
            case nw_error_domain_tls:
                message = "the secure connection to " + url_.host + " failed" + (text.empty() ? "" : ": " + text);
                hint = is_certificate_error(code)
                           ? "The server's certificate is not trusted by this computer (an expired certificate, a wrong "
                             "clock, a certificate for another name, or a proxy that rewrites traffic)."
                           : "The TLS handshake did not complete: check that the port speaks TLS (wss://) and that the "
                             "server supports a current TLS version.";
                return;
            case nw_error_domain_posix:
                if (code == ETIMEDOUT) {
                    message = "timed out connecting to " + where;
                    hint = "Check that the server is running and that the address is right, or raise the timeout of "
                           "websocket.connect.";
                } else if (code == ENETDOWN || code == ENETUNREACH || code == EHOSTUNREACH) {
                    message = "could not reach " + where + " (" + std::strerror(code) + ")";
                    hint = "Check the connection.";
                } else {
                    message = "could not connect to " + where + " (" + std::strerror(code) + ")";
                    hint = "Check that the server is running and that the address and port are right.";
                }
                return;
            default:
                message = "could not connect to " + where + (text.empty() ? "" : " (" + text + ")");
                hint = "Check that the server is running and that the address and port are right.";
        }
    }

    // Connecting: until the connection is ready (true), or it failed, timed out or was stopped (false, reported).
    bool wait_ready(Clock::time_point deadline) {
        for (;;) {
            if (stopping()) return false;
            nw_connection_state_t state;
            nw_error_t error = nil;
            bool waitingFailed;
            {
                std::unique_lock<std::mutex> lock(ioMutex_);
                cv_.wait_until(lock, std::min(deadline, Clock::now() + kTurn), [this] { return woken_ || stateChanged_; });
                woken_ = false;
                stateChanged_ = false;
                state = nwState_;
                error = nwError_;
                waitingFailed = waitingFailed_;
            }
            if (stopping()) return false;
            if (state == nw_connection_state_ready) return true;
            // Waiting: the system could not connect now and would try again when the network changes (a refused port, no
            // route, a name that does not resolve). A game asked to connect now, so that is a failure.
            if (state == nw_connection_state_failed || state == nw_connection_state_cancelled ||
                waitingFailed) {
                std::string message, hint;
                describe(error, message, hint);
                fail_connect(message, hint);
                return false;
            }
            if (Clock::now() >= deadline) {
                fail_connect("timed out connecting to " + url_.host_in_brackets() + ":" + std::to_string(url_.port),
                             "Check that the server is running and that the address is right, or raise the timeout of "
                             "websocket.connect.");
                return false;
            }
        }
    }

    // Sends the request and reads the head of the server's answer; false (after reporting) when it fails.
    bool handshake(nw_connection_t connection, Clock::time_point deadline, std::string& leftover) {
        std::string key, request;
        if (!begin_handshake(key, request)) return false;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            outgoing_ = std::move(request);  // nothing else is queued before the connection opens
            sent_ = 0;
        }
        std::string data;
        arm_receive(connection);
        for (;;) {
            if (stopping()) return false;
            if (Clock::now() >= deadline) {
                fail_connect("timed out waiting for the server's answer to the handshake",
                             "Check that the address is a WebSocket server and not a web page.");
                return false;
            }
            const bool ok = pump(connection, std::min(deadline, Clock::now() + kTurn), data);
            if (stopping()) return false;
            if (!data.empty()) {
                const int checked = check_handshake(data, key, leftover);
                if (checked < 0) return false;
                if (checked > 0) return true;
            }
            if (!ok) {
                fail_connect("the server closed the connection during the handshake",
                             "Check the address and the port; the server may need wss://, or ws:// if it has no TLS.");
                return false;
            }
        }
    }

    // The open connection, until the closing handshake is over, the protocol fails, the stream ends or the connection is
    // destroyed (the same rules as the tcp client's).
    void serve(nw_connection_t connection, const std::string& leftover, ws_stream::Ending& ending) {
        bool failedSeen = false;
        Clock::time_point failedAt;
        if (!leftover.empty()) feed(leftover.data(), leftover.size(), ending);
        while (!stop_ && !dead_) {
            bool done, needWrite, waitingForPeer;
            Clock::time_point asked;
            {
                std::lock_guard<std::mutex> lock(mutex_);
                take_session_output();
                done = session_.done();
                needWrite = sent_ < outgoing_.size();
                waitingForPeer = state_.load() == WebSocketState::Closing && !ending.peerClosed;
                asked = closeAsked_;
            }
            if (done && !needWrite) break;
            if (ending.failed && !failedSeen) {
                failedSeen = true;
                failedAt = Clock::now();
            }
            const auto now = Clock::now();
            // The server does not answer our close frame, or (after a failure) does not read the one we sent: give up.
            if (waitingForPeer && !ending.failed && now - asked > kCloseWait) {
                ending.lost = true;
                ending.closeTimedOut = true;
                break;
            }
            if (failedSeen && now - failedAt > kCloseWait) {
                ending.lost = true;
                break;
            }
            Clock::time_point until = now + kTurn;
            if (waitingForPeer) until = std::min(until, asked + kCloseWait + std::chrono::milliseconds(1));
            std::string got;
            const bool ok = pump(connection, until, got);
            if (!got.empty()) feed(got.data(), got.size(), ending);
            if (!ok) {
                ending.lost = true;
                break;
            }
        }
    }

    // Destroyed (stop_) or the queue ended (dead_) while open: send the goodbye (1001 or 1008) and let the closing handshake
    // finish for up to kCloseWait, so the frame is not cut off by the cancel. Nothing it reads is reported.
    void say_goodbye(nw_connection_t connection) {
        queue_goodbye();
        const auto deadline = Clock::now() + kCloseWait;
        ws_stream::Ending ignored;
        while (Clock::now() < deadline) {
            {
                std::lock_guard<std::mutex> lock(mutex_);
                take_session_output();
                const bool written = sent_ >= outgoing_.size();
                if (written && (session_.done() || !session_.close_sent())) break;
            }
            std::string got;
            const bool ok = pump(connection, std::min(deadline, Clock::now() + kTurn), got);
            if (!got.empty()) feed(got.data(), got.size(), ignored);
            if (!ok) break;
        }
    }

    // Cancels the connection and waits (bounded) for its last callback, the cancelled state.
    void shut(nw_connection_t connection) {
        nw_connection_cancel(connection);
        std::unique_lock<std::mutex> lock(ioMutex_);
        cv_.wait_for(lock, kCancelWait, [this] { return nwState_ == nw_connection_state_cancelled; });
    }

    nw_parameters_t make_parameters() const {
        nw_parameters_configure_protocol_block_t tls = NW_PARAMETERS_DISABLE_PROTOCOL;
        if (url_.secure) {
            tls = ^(nw_protocol_options_t options) {
                sec_protocol_options_t sec = nw_tls_copy_sec_protocol_options(options);
                // The upgrade is an HTTP/1.1 request: a server that also speaks HTTP/2 must not choose it.
                sec_protocol_options_add_tls_application_protocol(sec, "http/1.1");
            };
        }
        // Proxies: nw_parameters_set_prefer_no_proxy stays at its default (false), so Network.framework applies the system's
        // proxy configuration (HTTP CONNECT, SOCKS, PAC) as it does to any connection to a host name; the engine adds no
        // proxy of its own (nw_proxy_config_* needs iOS 17, above the 16.3 target).
        return nw_parameters_create_secure_tcp(tls, ^(nw_protocol_options_t options) {
            nw_tcp_options_set_no_delay(options, true);
        });
    }

    void run() override {
        @autoreleasepool {
            const auto deadline = connect_deadline();
            nw_endpoint_t endpoint = nw_endpoint_create_host(url_.host.c_str(), std::to_string(url_.port).c_str());
            nw_connection_t connection = endpoint ? nw_connection_create(endpoint, make_parameters()) : nil;
            if (!connection) {
                fail_connect("could not start a connection to " + url_.host_in_brackets(),
                             "Check the address of websocket.connect.");
                finish_aborted();
                return;
            }
            dispatch_queue_t queue = dispatch_queue_create("fa.websocket", DISPATCH_QUEUE_SERIAL);
            nw_connection_set_queue(connection, queue);
            std::weak_ptr<AppleCore> weak = weak_self();
            nw_connection_set_state_changed_handler(connection, ^(nw_connection_state_t state, nw_error_t error) {
                if (auto self = weak.lock()) self->on_state(state, error);
            });
            nw_connection_start(connection);

            std::string leftover;
            if (!wait_ready(deadline) || !handshake(connection, deadline, leftover) || !open_connection()) {
                finish_aborted();
                shut(connection);
                return;
            }
            ws_stream::Ending ending;
            serve(connection, leftover, ending);
            if (stop_ || dead_) say_goodbye(connection);
            finish(ending);
            shut(connection);
        }
    }

    std::mutex ioMutex_;           // guards what follows, down to sendFailed_; never held while taking mutex_
    std::condition_variable cv_;   // with ioMutex_: the thread waits for the network or the game
    bool woken_ = false;           // the game queued output, closed, or let go
    bool stateChanged_ = false;    // the state handler ran since the thread last looked
    nw_connection_state_t nwState_ = nw_connection_state_invalid;
    nw_error_t nwError_ = nil;     // the first error the connection reported
    bool waitingFailed_ = false;   // it went waiting with an error (cannot connect now): sticky, the state may move on
    std::string inbox_;            // bytes read and not yet fed
    bool receiving_ = false;       // a read is outstanding
    bool readEnded_ = false;       // the server closed its side, or a read failed
    int sendsDone_ = 0;            // sends that completed since the thread last looked
    bool sendFailed_ = false;
    std::size_t inFlight_ = 0;     // the connection's thread only: the bytes of outgoing_ (from sent_) in the send in flight
};

class AppleWebSocketClient final : public WebSocketClient {
public:
    std::string name() const override { return "network"; }
    bool available() const override { return true; }

    Result<std::unique_ptr<WebSocket>> connect(WebSocketRequest request) override {
        bool hasAgent = false;
        for (const auto& [name, value] : request.headers) hasAgent = hasAgent || iequals(name, "User-Agent");
        if (!hasAgent) request.headers.emplace_back("User-Agent", "FactorIA/" FA_ENGINE_VERSION);
        auto url = ws_stream::check_request(request);
        if (!url.ok()) return url.error();
        auto core = std::make_shared<AppleCore>(std::move(request), std::move(url.value()));
        return std::unique_ptr<WebSocket>(std::make_unique<ws_stream::StreamWebSocket>(std::move(core)));
    }
};

}  // namespace

std::unique_ptr<WebSocketClient> make_system_websocket_client() { return std::make_unique<AppleWebSocketClient>(); }

}  // namespace fa
