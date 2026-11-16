// What every WebSocket client shares (fa/platform/websocket.h): the event queue, the "not available" client and the memory
// client of headless runs and tests.
#include "fa/platform/websocket.h"

#include <algorithm>
#include <string>
#include <utility>

#include "fa/core/strings.h"
#include "fa/platform/websocket_codec.h"

namespace fa {

const char* websocket_state_name(WebSocketState state) {
    switch (state) {
        case WebSocketState::Connecting: return "connecting";
        case WebSocketState::Open: return "open";
        case WebSocketState::Closing: return "closing";
        case WebSocketState::Closed: return "closed";
    }
    return "closed";
}

WebSocketEvent WebSocketEvent::open(std::string chosenSubprotocol) {
    WebSocketEvent e;
    e.type = Type::Open;
    e.subprotocol = std::move(chosenSubprotocol);
    return e;
}
WebSocketEvent WebSocketEvent::text(std::string message) {
    WebSocketEvent e;
    e.type = Type::Text;
    e.data = std::move(message);
    return e;
}
WebSocketEvent WebSocketEvent::binary(std::string message) {
    WebSocketEvent e;
    e.type = Type::Binary;
    e.data = std::move(message);
    return e;
}
WebSocketEvent WebSocketEvent::failure(std::string what, std::string advice, int status) {
    WebSocketEvent e;
    e.type = Type::Error;
    e.error = std::move(what);
    e.hint = std::move(advice);
    e.httpStatus = status;
    return e;
}
WebSocketEvent WebSocketEvent::close(int closeCode, std::string closeReason, bool clean) {
    WebSocketEvent e;
    e.type = Type::Close;
    e.code = closeCode;
    e.reason = std::move(closeReason);
    e.wasClean = clean;
    return e;
}

// ------------------------------------------------------------------------------------------------------ the queue ---
namespace {

// "32 MB", or bytes under 1 MB ("1000 bytes", never "0 MB").
std::string size_text(std::size_t bytes) {
    if (bytes < 1024 * 1024) return std::to_string(bytes) + " bytes";
    return std::to_string(bytes / (1024 * 1024)) + " MB";
}

const char* const kClosedBeforeOpenHint =
    "close() was called before the connection opened; wait for the 'open' event, or ignore this error.";

}  // namespace

bool WebSocketEventQueue::push(WebSocketEvent event) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (ended_) return false;
    const bool message = event.type == WebSocketEvent::Type::Text || event.type == WebSocketEvent::Type::Binary;
    if (message) {
        // 64-bit saturating: a message never wraps the counter.
        const std::size_t size = event.data.size();
        if (size > maxPendingBytes_ || pendingBytes_ > maxPendingBytes_ - size) {
            events_.clear();
            pendingBytes_ = 0;
            events_.push_back(WebSocketEvent::failure("the game did not read the messages that arrived (more than " +
                                                          size_text(maxPendingBytes_) + " waiting)",
                                                      "Read messages every frame, and ask the server to send less."));
            events_.push_back(
                WebSocketEvent::close(ws::close_code::kPolicyViolation, "too many unread messages", false));
            ended_ = true;
            return false;
        }
        pendingBytes_ += size;
    }
    if (event.type == WebSocketEvent::Type::Close) ended_ = true;
    events_.push_back(std::move(event));
    return true;
}

std::size_t WebSocketEventQueue::drain(std::vector<WebSocketEvent>& out) {
    std::lock_guard<std::mutex> lock(mutex_);
    const std::size_t n = events_.size();
    for (WebSocketEvent& e : events_) out.push_back(std::move(e));
    events_.clear();
    pendingBytes_ = 0;
    return n;
}

bool WebSocketEventQueue::ended() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return ended_;
}

void WebSocketEventQueue::abandon() {
    std::lock_guard<std::mutex> lock(mutex_);
    ended_ = true;
    events_.clear();
    pendingBytes_ = 0;
}

// ----------------------------------------------------------------------------------------------- not available ---
namespace {

class UnavailableWebSocketClient final : public WebSocketClient {
public:
    UnavailableWebSocketClient(std::string name, std::string reason)
        : name_(std::move(name)), reason_(std::move(reason)) {}
    std::string name() const override { return name_; }
    bool available() const override { return false; }
    std::string unavailable_reason() const override { return reason_; }
    Result<std::unique_ptr<WebSocket>> connect(WebSocketRequest) override {
        return make_error("WebSocket is not available: " + reason_,
                          "Check websocket.supported before connecting, and let the game carry on offline.");
    }

private:
    std::string name_, reason_;
};

}  // namespace

std::unique_ptr<WebSocketClient> make_unavailable_websocket_client(std::string name, std::string reason) {
    return std::make_unique<UnavailableWebSocketClient>(std::move(name), std::move(reason));
}

// -------------------------------------------------------------------------------------------------------- memory ---
struct MemoryWebSocketClient::Peer::Link {
    std::shared_ptr<WebSocketEventQueue> queue = std::make_shared<WebSocketEventQueue>();
    WebSocketState state = WebSocketState::Connecting;
    bool abandoned =
        false;  // close() came while Connecting: Closing until poll() hands over Error and Close, then Closed
    std::vector<std::string> offered;
};

class MemoryWebSocketConnection final : public WebSocket {
public:
    MemoryWebSocketConnection(std::shared_ptr<MemoryWebSocketClient::Peer> peer, std::size_t maxMessageBytes)
        : peer_(std::move(peer)), max_(maxMessageBytes) {}
    ~MemoryWebSocketConnection() override {
        auto& link = *peer_->link_;
        link.queue->abandon();  // nothing the peer pushes from now on reaches the (gone) connection
        if (link.state != WebSocketState::Closed) {
            link.state = WebSocketState::Closed;
            peer_->open = false;
            peer_->closed = true;
            peer_->clientClosed = true;  // destroyed while open: the close frame (1001) that a real client sends
            peer_->clientCloseCode = 1001;
        }
    }
    WebSocketState state() const override { return peer_->link_->state; }
    Result<void> send_text(std::string_view text) override {
        if (auto r = check(text.size()); !r.ok()) return r;
        if (!is_valid_utf8(text)) return make_error("the text is not valid UTF-8", "Send other data with send_binary.");
        peer_->received.push_back({false, std::string(text)});
        return {};
    }
    Result<void> send_binary(const void* data, std::size_t size) override {
        if (auto r = check(size); !r.ok()) return r;
        peer_->received.push_back({true, std::string(static_cast<const char*>(data), size)});
        return {};
    }
    Result<void> close(int code, std::string_view reason) override {
        if (auto r = ws::check_close_request(code, reason); !r.ok()) return r;
        auto& link = *peer_->link_;
        if (link.state == WebSocketState::Closed || link.state == WebSocketState::Closing) return {};
        peer_->clientClosed = true;
        peer_->clientCloseCode = code;
        peer_->clientCloseReason = std::string(reason);
        if (link.state == WebSocketState::Connecting) {
            link.queue->push(
                WebSocketEvent::failure("the connection was closed before it was open", kClosedBeforeOpenHint));
            link.queue->push(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
            link.state = WebSocketState::Closing;  // Closed when poll() delivers the Close
            link.abandoned = true;
            peer_->closed = true;
            return {};
        }
        if (peer_->autoCloseReply) {
            link.queue->push(
                WebSocketEvent::close(code == 0 ? ws::close_code::kNoStatus : code, std::string(reason), true));
            link.state = WebSocketState::Closed;
            peer_->open = false;
            peer_->closed = true;
        } else {
            link.state = WebSocketState::Closing;
        }
        return {};
    }
    std::size_t buffered_amount() const override { return 0; }
    std::size_t poll(std::vector<WebSocketEvent>& out) override {
        auto& link = *peer_->link_;
        const std::size_t n = link.queue->drain(out);
        if (link.abandoned && link.state == WebSocketState::Closing) link.state = WebSocketState::Closed;
        return n;
    }

private:
    Result<void> check(std::size_t size) const {
        if (state() == WebSocketState::Connecting)
            return make_error("the connection is not open yet", "Wait for the \"open\" event before sending.");
        if (state() != WebSocketState::Open)
            return make_error("the connection is closing or closed", "Connect again to send.");
        if (size > max_)
            return make_error("the message is " + std::to_string(size) + " bytes; the most is " + std::to_string(max_),
                              "Split the data into smaller messages.");
        return {};
    }
    std::shared_ptr<MemoryWebSocketClient::Peer> peer_;
    std::size_t max_;
};

bool MemoryWebSocketClient::Peer::accept(std::string subprotocol) {
    if (link_->state != WebSocketState::Connecting) return false;
    if (!subprotocol.empty() &&
        std::find(link_->offered.begin(), link_->offered.end(), subprotocol) == link_->offered.end())
        return false;
    link_->state = WebSocketState::Open;
    open = true;
    link_->queue->push(WebSocketEvent::open(std::move(subprotocol)));
    return true;
}

void MemoryWebSocketClient::Peer::refuse(std::string message, int httpStatus) {
    if (link_->state == WebSocketState::Closed || link_->abandoned) return;
    link_->queue->push(WebSocketEvent::failure(std::move(message), "", httpStatus));
    link_->queue->push(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
    link_->state = WebSocketState::Closed;
    open = false;
    closed = true;
}

void MemoryWebSocketClient::Peer::send_text(std::string text) {
    if ((link_->state == WebSocketState::Open || link_->state == WebSocketState::Closing) && !link_->abandoned)
        deliver(WebSocketEvent::text(std::move(text)));
}

void MemoryWebSocketClient::Peer::send_binary(std::string data) {
    if ((link_->state == WebSocketState::Open || link_->state == WebSocketState::Closing) && !link_->abandoned)
        deliver(WebSocketEvent::binary(std::move(data)));
}

// A message the queue could not take (the game did not read): the queue holds [Error, Close 1008], the connection is over.
void MemoryWebSocketClient::Peer::deliver(WebSocketEvent event) {
    if (link_->queue->push(std::move(event))) return;
    link_->state = WebSocketState::Closed;
    open = false;
    closed = true;
}

void MemoryWebSocketClient::Peer::close(int code, std::string reason) {
    if (link_->state == WebSocketState::Closed || link_->abandoned) return;
    if (link_->state == WebSocketState::Connecting) {
        refuse("the server closed the connection during the handshake");
        return;
    }
    link_->queue->push(WebSocketEvent::close(code, std::move(reason), true));
    link_->state = WebSocketState::Closed;
    open = false;
    closed = true;
}

void MemoryWebSocketClient::Peer::drop(std::string message) {
    if (link_->state == WebSocketState::Closed || link_->abandoned) return;
    link_->queue->push(WebSocketEvent::failure(std::move(message), "Check the connection; the game can reconnect."));
    link_->queue->push(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
    link_->state = WebSocketState::Closed;
    open = false;
    closed = true;
}

Result<std::unique_ptr<WebSocket>> MemoryWebSocketClient::connect(WebSocketRequest request) {
    if (auto url = ws::parse_url(request.url); !url.ok()) return url.error();
    auto peer = std::make_shared<Peer>();
    peer->url = request.url;
    peer->subprotocols = request.subprotocols;
    peer->headers = request.headers;
    peer->link_ = std::make_shared<Peer::Link>();
    peer->link_->queue = std::make_shared<WebSocketEventQueue>(WebSocketEventQueue::limit_for(request.maxMessageBytes));
    peer->link_->offered = request.subprotocols;
    peers_.push_back(peer);
    auto connection = std::make_unique<MemoryWebSocketConnection>(peer, request.maxMessageBytes);
    if (refuseCount_ > 0) {
        --refuseCount_;
        peer->refuse(refuseMessage_);
    } else if (autoAccept_) {
        peer->accept();
    }
    return std::unique_ptr<WebSocket>(std::move(connection));
}

}  // namespace fa
