// What every WebSocket client shares (fa/platform/websocket.h): the event queue, the "not available" client and the memory
// client of headless runs and tests.
#include "fa/platform/websocket.h"

#include <algorithm>

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

WebSocketEvent WebSocketEvent::open(std::string subprotocol) {
    WebSocketEvent e;
    e.type = Type::Open;
    e.subprotocol = std::move(subprotocol);
    return e;
}
WebSocketEvent WebSocketEvent::text(std::string data) {
    WebSocketEvent e;
    e.type = Type::Text;
    e.data = std::move(data);
    return e;
}
WebSocketEvent WebSocketEvent::binary(std::string data) {
    WebSocketEvent e;
    e.type = Type::Binary;
    e.data = std::move(data);
    return e;
}
WebSocketEvent WebSocketEvent::failure(std::string error, std::string hint, int httpStatus) {
    WebSocketEvent e;
    e.type = Type::Error;
    e.error = std::move(error);
    e.hint = std::move(hint);
    e.httpStatus = httpStatus;
    return e;
}
WebSocketEvent WebSocketEvent::close(int code, std::string reason, bool wasClean) {
    WebSocketEvent e;
    e.type = Type::Close;
    e.code = code;
    e.reason = std::move(reason);
    e.wasClean = wasClean;
    return e;
}

// ------------------------------------------------------------------------------------------------------ the queue ---
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
            events_.push_back(WebSocketEvent::failure(
                "the game did not read the messages that arrived (more than " + std::to_string(maxPendingBytes_ / (1024 * 1024)) +
                    " MB waiting)",
                "Read messages every frame, and ask the server to send less."));
            events_.push_back(WebSocketEvent::close(ws::close_code::kPolicyViolation, "too many unread messages", false));
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

// ----------------------------------------------------------------------------------------------- not available ---
namespace {

class UnavailableWebSocketClient final : public WebSocketClient {
public:
    UnavailableWebSocketClient(std::string name, std::string reason) : name_(std::move(name)), reason_(std::move(reason)) {}
    std::string name() const override { return name_; }
    bool available() const override { return false; }
    std::string unavailable_reason() const override { return reason_; }
    Result<std::unique_ptr<WebSocket>> connect(WebSocketRequest) override {
        return make_error("WebSocket is not available: " + reason_, "Check websocket.supported before connecting, and let the game carry on offline.");
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
    WebSocketEventQueue queue;
    WebSocketState state = WebSocketState::Connecting;
    std::vector<std::string> offered;
};

class MemoryWebSocketConnection final : public WebSocket {
public:
    MemoryWebSocketConnection(std::shared_ptr<MemoryWebSocketClient::Peer> peer, std::size_t maxMessageBytes)
        : peer_(std::move(peer)), max_(maxMessageBytes) {}
    ~MemoryWebSocketConnection() override {
        auto& link = *peer_->link_;
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
    void close(int code, std::string_view reason) override {
        auto& link = *peer_->link_;
        if (link.state == WebSocketState::Closed || link.state == WebSocketState::Closing) return;
        peer_->clientClosed = true;
        peer_->clientCloseCode = code;
        peer_->clientCloseReason = std::string(reason);
        if (link.state == WebSocketState::Connecting) {
            link.queue.push(WebSocketEvent::failure("the connection was closed before it was open"));
            link.queue.push(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
            link.state = WebSocketState::Closed;
            peer_->closed = true;
            return;
        }
        if (peer_->autoCloseReply) {
            link.queue.push(WebSocketEvent::close(code == 0 ? ws::close_code::kNoStatus : code, std::string(reason), true));
            link.state = WebSocketState::Closed;
            peer_->open = false;
            peer_->closed = true;
        } else {
            link.state = WebSocketState::Closing;
        }
    }
    std::size_t buffered_amount() const override { return 0; }
    std::size_t poll(std::vector<WebSocketEvent>& out) override { return peer_->link_->queue.drain(out); }

private:
    Result<void> check(std::size_t size) const {
        if (state() == WebSocketState::Connecting)
            return make_error("the connection is not open yet", "Wait for the \"open\" event before sending.");
        if (state() != WebSocketState::Open) return make_error("the connection is closing or closed", "Connect again to send.");
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
    if (!subprotocol.empty() && std::find(link_->offered.begin(), link_->offered.end(), subprotocol) == link_->offered.end())
        return false;
    link_->state = WebSocketState::Open;
    open = true;
    link_->queue.push(WebSocketEvent::open(std::move(subprotocol)));
    return true;
}

void MemoryWebSocketClient::Peer::refuse(std::string message, int httpStatus) {
    if (link_->state == WebSocketState::Closed) return;
    link_->queue.push(WebSocketEvent::failure(std::move(message), "", httpStatus));
    link_->queue.push(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
    link_->state = WebSocketState::Closed;
    open = false;
    closed = true;
}

void MemoryWebSocketClient::Peer::send_text(std::string text) {
    if (link_->state == WebSocketState::Open || link_->state == WebSocketState::Closing)
        link_->queue.push(WebSocketEvent::text(std::move(text)));
}

void MemoryWebSocketClient::Peer::send_binary(std::string data) {
    if (link_->state == WebSocketState::Open || link_->state == WebSocketState::Closing)
        link_->queue.push(WebSocketEvent::binary(std::move(data)));
}

void MemoryWebSocketClient::Peer::close(int code, std::string reason) {
    if (link_->state == WebSocketState::Closed) return;
    if (link_->state == WebSocketState::Connecting) {
        refuse("the server closed the connection during the handshake");
        return;
    }
    link_->queue.push(WebSocketEvent::close(code, std::move(reason), true));
    link_->state = WebSocketState::Closed;
    open = false;
    closed = true;
}

void MemoryWebSocketClient::Peer::drop(std::string message) {
    if (link_->state == WebSocketState::Closed) return;
    link_->queue.push(WebSocketEvent::failure(std::move(message), "Check the connection; the game can reconnect."));
    link_->queue.push(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
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
