// The part of the stream WebSocket clients that does not touch the stream (websocket_stream.h).
#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)

#include "websocket_stream.h"

#include <algorithm>
#include <exception>
#include <random>
#include <thread>
#include <utility>

#include "fa/core/strings.h"

namespace fa::ws_stream {

namespace {

ws::SessionOptions make_options(std::size_t max) {
    ws::SessionOptions o;
    o.role = ws::Role::Client;
    o.maxMessageBytes = max;
    return o;
}

}  // namespace

Result<ws::Url> check_request(const WebSocketRequest& request) {
    auto url = ws::parse_url(request.url);
    if (!url.ok()) return url.error();
    // A header or subprotocol the handshake refuses is an error now, not a failed connection later.
    const std::uint8_t zeros[16] = {};
    if (auto head =
            ws::build_client_request(url.value(), ws::make_client_key(zeros), request.subprotocols, request.headers);
        !head.ok())
        return head.error();
    return url;
}

StreamCore::StreamCore(WebSocketRequest request, ws::Url url)
    : request_(std::move(request)), url_(std::move(url)),
      queue_(std::make_shared<WebSocketEventQueue>(WebSocketEventQueue::limit_for(request_.maxMessageBytes))),
      session_(make_options(request_.maxMessageBytes)) {}

void StreamCore::start() {
    try {
        std::thread([self = shared_from_this()] { self->run(); }).detach();
    } catch (const std::exception& e) {  // no thread to be had (std::system_error)
        fail_connect(std::string("could not start the connection (") + e.what() + ")",
                     "Close other connections or programs and try again.");
    }
}

void StreamCore::release() {
    queue_->abandon();
    stop_ = true;
    interrupt();
}

Result<void> StreamCore::can_send() const {
    const WebSocketState s = state();
    if (s == WebSocketState::Connecting)
        return make_error("the connection is not open yet", "Wait for the \"open\" event before sending.");
    if (s != WebSocketState::Open) return make_error("the connection is closing or closed", "Connect again to send.");
    if (pending_bytes() > kMaxBuffered)
        return make_error("more than " + std::to_string(kMaxBuffered / (1024 * 1024)) + " MB wait to be sent",
                          "Send less, or wait until bufferedAmount drops.");
    return {};
}

Result<void> StreamCore::send_text(std::string_view text) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (auto r = can_send(); !r.ok()) return r;
    if (!is_valid_utf8(text)) return make_error("the text is not valid UTF-8", "Send other data with send_binary.");
    auto r = session_.send_text(text);
    if (r.ok()) wake();
    return r;
}

Result<void> StreamCore::send_binary(const void* data, std::size_t size) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (auto r = can_send(); !r.ok()) return r;
    auto r = session_.send_binary(data, size);
    if (r.ok()) wake();
    return r;
}

Result<void> StreamCore::close(int code, std::string_view reason) {
    if (auto r = ws::check_close_request(code, reason); !r.ok()) return r;
    bool wasConnecting = false;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        const WebSocketState s = state();
        if (s == WebSocketState::Closing || s == WebSocketState::Closed) return {};
        if (s == WebSocketState::Connecting) {
            // Closing at once; the thread ends the attempt with Error and Close 1006, and then it is Closed.
            abort_ = true;
            WebSocketState expected = WebSocketState::Connecting;
            state_.compare_exchange_strong(expected, WebSocketState::Closing);
            wasConnecting = true;
        } else if (session_.close(code, reason).ok()) {
            // The thread may have ended the connection meanwhile: only Open becomes Closing.
            WebSocketState expected = WebSocketState::Open;
            if (state_.compare_exchange_strong(expected, WebSocketState::Closing)) closeAsked_ = Clock::now();
        }
        if (!wasConnecting) wake();
    }
    if (wasConnecting) interrupt();  // a connect or a handshake read in progress must end
    return {};
}

std::size_t StreamCore::buffered_amount() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return pending_bytes();
}

std::size_t StreamCore::poll(std::vector<WebSocketEvent>& out) {
    tick();
    return queue_->drain(out);
}

Clock::time_point StreamCore::connect_deadline() const {
    const double sec = request_.connectTimeoutSec > 0 ? std::min(request_.connectTimeoutSec, 86400.0) : 0.0;  // NaN: 0
    return Clock::now() + std::chrono::milliseconds(static_cast<long long>(sec * 1000));
}

bool StreamCore::emit(WebSocketEvent event) {
    if (queue_->push(std::move(event))) return true;
    dead_ = true;
    return false;
}

void StreamCore::fail_connect(const std::string& error, const std::string& hint, int status) {
    state_ = WebSocketState::Closed;  // before the events: when the game reads Close, state() is Closed
    emit(WebSocketEvent::failure(error, hint, status));
    emit(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
}

void StreamCore::finish_aborted() {
    if (state_.load() != WebSocketState::Closed && !stop_ && !dead_)
        fail_connect(
            "the connection was closed before it was open",
            "close() was called before the connection opened; wait for the 'open' event, or ignore this error.");
    state_ = WebSocketState::Closed;
}

bool StreamCore::begin_handshake(std::string& key, std::string& request) {
    std::uint8_t random[16];
    try {
        std::random_device rd;
        for (std::uint8_t& b : random) b = static_cast<std::uint8_t>(rd());
    } catch (const std::exception& e) {  // no entropy source
        fail_connect(std::string("could not make the handshake key (") + e.what() + ")", "Try again.");
        return false;
    }
    key = ws::make_client_key(random);
    auto req = ws::build_client_request(url_, key, request_.subprotocols, request_.headers);
    if (!req.ok()) {
        fail_connect(req.error().message, req.error().hint);
        return false;
    }
    request = std::move(req.value());
    return true;
}

int StreamCore::check_handshake(const std::string& data, const std::string& key, std::string& leftover) {
    const std::size_t end = ws::find_head_end(data);
    if (end == std::string::npos) {
        if (data.size() <= kMaxHandshakeBytes) return 0;
        fail_connect("the server's answer to the handshake is longer than 64 KB",
                     "The address is not a WebSocket server.");
        return -1;
    }
    const ws::HandshakeResult r =
        ws::check_server_response(std::string_view(data).substr(0, end), key, request_.subprotocols);
    if (!r.ok) {
        fail_connect(r.error, r.hint, r.status == 101 ? 0 : r.status);
        return -1;
    }
    leftover = data.substr(end);
    subprotocol_ = r.subprotocol;
    return 1;
}

bool StreamCore::open_connection() {
    bool aborted;
    {
        // close() and this transition are both under the mutex, so a close that came first is not lost.
        std::lock_guard<std::mutex> lock(mutex_);
        aborted = stopping();
        if (!aborted) state_ = WebSocketState::Open;
    }
    if (aborted) return false;
    return emit(WebSocketEvent::open(subprotocol_));
}

void StreamCore::feed(const void* data, std::size_t size, Ending& ending) {
    std::vector<ws::Event> events;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        session_.feed(data, size, events);
        if (session_.has_output()) wake();
    }
    handle(events, ending);
}

void StreamCore::handle(std::vector<ws::Event>& events, Ending& ending) {
    for (ws::Event& e : events) {
        switch (e.type) {
            case ws::Event::Type::Text:
                if (!emit(WebSocketEvent::text(std::move(e.data)))) return;
                break;
            case ws::Event::Type::Binary:
                if (!emit(WebSocketEvent::binary(std::move(e.data)))) return;
                break;
            case ws::Event::Type::Ping:
            case ws::Event::Type::Pong: break;
            case ws::Event::Type::Close:
                ending.peerClosed = true;
                ending.closeCode = e.code;
                ending.closeReason = std::move(e.reason);
                {
                    std::lock_guard<std::mutex> lock(mutex_);
                    WebSocketState expected = WebSocketState::Open;
                    state_.compare_exchange_strong(expected, WebSocketState::Closing);
                }
                break;
            case ws::Event::Type::Failure:
                ending.failed = true;
                ending.closeCode = e.code;
                if (!emit(WebSocketEvent::failure(e.error, e.hint))) return;
                break;
        }
    }
    events.clear();
}

void StreamCore::queue_goodbye() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (state_.load() == WebSocketState::Open) {
        static_cast<void>(session_.close(stop_ ? ws::close_code::kGoingAway : ws::close_code::kPolicyViolation, {}));
        wake();
    }
}

void StreamCore::finish(const Ending& ending) {
    state_ = WebSocketState::Closed;  // before the Close event: when the game reads it, state() is Closed
    if (stop_ || dead_) return;       // destroyed, or the queue ended: report nothing more
    if (ending.lost && !ending.peerClosed && !ending.failed) {
        if (ending.closeTimedOut)
            emit(WebSocketEvent::failure("the server did not answer the close within " +
                                             std::to_string(static_cast<int>(kWebSocketCloseWaitSec)) + " seconds",
                                         "The connection was dropped; the server may be stuck or slow to read."));
        else
            emit(WebSocketEvent::failure("the connection to " + url_.host + " was lost",
                                         "Check the connection; try again."));
        emit(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
    } else if (ending.failed) {
        // A failed connection ends with 1006 whatever the codec sent the server (1002, 1007, 1009): the browser's rule.
        emit(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
    } else {
        emit(WebSocketEvent::close(ending.closeCode == ws::close_code::kAbnormal ? ws::close_code::kNoStatus
                                                                                 : ending.closeCode,
                                   ending.closeReason, ending.peerClosed));
    }
}

}  // namespace fa::ws_stream

#endif
