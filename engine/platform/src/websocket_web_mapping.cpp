// See websocket_web_mapping.h. Compiled on every platform (it is plain C++) so that the platform tests can run it; only the
// web player uses it.
#include "websocket_web_mapping.h"

#include <cstdio>
#include <utility>

#include "fa/platform/websocket_codec.h"

namespace fa::web_ws {

namespace {

std::string seconds_text(double seconds) {
    char buf[32];
    std::snprintf(buf, sizeof(buf), "%g", seconds);
    return buf;
}

}  // namespace

Text problem_text(Problem problem, const std::string& host, bool secureAddress, bool pageHttps, double timeoutSec) {
    Text t;
    switch (problem) {
        case Problem::CouldNotConnect:
            t.message = "could not connect to " + host;
            t.hint =
                "The browser gives no reason for a failed WebSocket on purpose, so check each of these. (1) The "
                "address and "
                "the port are right and the server is running. (2) A page loaded over https:// may only open wss:// "
                "addresses (mixed content)" +
                std::string(pageHttps && !secureAddress
                                ? ": this page is https:// and the address is ws://, use wss://. "
                                : ". ") +
                "(3) The browser always sends the page's Origin header, and a server may refuse origins it does not "
                "know (the handshake then fails with a 403 the page cannot see): allow this game's origin in the "
                "server. "
                "(4) For wss:// the server needs a certificate the browser trusts.";
            break;
        case Problem::ConnectionLost:
            t.message = "the connection to " + host + " was lost";
            t.hint =
                "The server closed the connection without a closing handshake, or the network dropped. The browser "
                "gives no more detail; use reconnect: true to connect again.";
            break;
        case Problem::ConnectTimeout:
            t.message = "connecting to " + host + " took longer than " + seconds_text(timeoutSec) + " s";
            t.hint =
                "The browser has no timeout of its own, so the engine ended the attempt. Check the address and the "
                "server, or raise the timeout option of websocket.connect.";
            break;
        case Problem::CloseTimeout:
            t.message = "the server at " + host + " did not answer the close within " +
                        seconds_text(kWebSocketCloseWaitSec) + " s";
            t.hint = "The connection was dropped without a closing handshake.";
            break;
        case Problem::ClosedBeforeOpen:
            t.message = "the connection was closed before it was open";
            t.hint =
                "close() was called before the connection opened; wait for the 'open' event, or ignore this error.";
            break;
    }
    return t;
}

Text constructor_failure_text(const std::string& name, const std::string& message, const std::string& url,
                              bool pageHttps) {
    Text t;
    if (name == "SecurityError") {
        t.message = "the browser refused to open " + url + " from this page";
        t.hint =
            std::string(pageHttps ? "This page was loaded over https://, and a browser blocks ws:// from it (mixed "
                                    "content; only localhost is exempt in some browsers). Use a wss:// address."
                                  : "The browser's security rules refuse this address from this page. ") +
            (message.empty() ? "" : std::string(" Browser: ") + message);
    } else if (name == "SyntaxError") {
        t.message = "the browser does not accept this address or these subprotocols: " + message;
        t.hint =
            "A subprotocol is a name without spaces or commas, offered once; the address is ws:// or wss:// with no "
            "fragment (#).";
    } else {
        t.message = "the browser could not start the WebSocket" + (message.empty() ? std::string() : ": " + message);
        t.hint = "Check the address; the browser gives no more detail.";
    }
    return t;
}

Result<void> check_request(const WebSocketRequest& request) {
    if (request.headers.empty()) return {};
    std::string names;
    for (const auto& h : request.headers) {
        if (!names.empty()) names += ", ";
        names += h.first;
    }
    return make_error("the browser's WebSocket cannot send handshake headers (" + names + ")",
                      "A game for the web puts what the server needs in the URL (a query string) or in the first "
                      "message, and leaves the headers option out.");
}

Result<void> check_send(WebSocketState state, std::size_t size, std::size_t maxMessageBytes, std::size_t buffered) {
    if (state == WebSocketState::Connecting)
        return make_error("the connection is not open yet", "Wait for the \"open\" event before sending.");
    if (state != WebSocketState::Open)
        return make_error("the connection is closing or closed", "Connect again to send.");
    if (size > maxMessageBytes)
        return make_error("the message is " + std::to_string(size) + " bytes; the most is " +
                              std::to_string(maxMessageBytes),
                          "Split the data into smaller messages.");
    if (buffered > kMaxBuffered)
        return make_error("more than " + std::to_string(kMaxBuffered / (1024 * 1024)) + " MB wait to be sent",
                          "Send less, or wait until bufferedAmount drops.");
    return {};
}

std::string json_quote(const std::string& s) {
    static const char* hex = "0123456789abcdef";
    std::string out = "\"";
    for (unsigned char c : s) {
        if (c == '"' || c == '\\') {
            out += '\\';
            out += static_cast<char>(c);
        } else if (c < 0x20) {
            out += "\\u00";
            out += hex[c >> 4];
            out += hex[c & 15];
        } else {
            out += static_cast<char>(c);
        }
    }
    return out + "\"";
}

std::string json_string_array(const std::vector<std::string>& items) {
    std::string out = "[";
    for (std::size_t i = 0; i < items.size(); ++i) {
        if (i) out += ",";
        out += json_quote(items[i]);
    }
    return out + "]";
}

Mapper::Mapper(std::string host, bool secureAddress, bool pageHttps, std::size_t maxMessageBytes,
               double connectTimeoutSec)
    : host_(std::move(host)), secure_(secureAddress), pageHttps_(pageHttps), max_(maxMessageBytes),
      timeoutSec_(connectTimeoutSec) {}

bool Mapper::wants_payload(BrowserEvent::Kind kind, std::size_t size) const {
    if (finished_) return false;
    if (kind == BrowserEvent::Kind::Text || kind == BrowserEvent::Kind::Binary) return size <= max_;
    return true;
}

Reaction Mapper::fail(Problem problem, bool stopBrowser, bool abandoned) {
    Reaction r;
    if (!errored_) {
        Text t = problem_text(problem, host_, secure_, pageHttps_, timeoutSec_);
        r.events.push_back(WebSocketEvent::failure(std::move(t.message), std::move(t.hint)));
    }
    r.events.push_back(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
    errored_ = true;
    finished_ = true;
    abandoned_ = abandoned;
    state_ = abandoned ? WebSocketState::Closing : WebSocketState::Closed;
    r.stopBrowser = stopBrowser;
    return r;
}

Reaction Mapper::on_browser(BrowserEvent e) {
    using Kind = BrowserEvent::Kind;
    Reaction r;
    if (finished_) return r;
    switch (e.kind) {
        case Kind::Open:
            if (state_ != WebSocketState::Connecting) return r;
            opened_ = true;
            state_ = WebSocketState::Open;  // before the event, as the contract says
            r.events.push_back(WebSocketEvent::open(std::move(e.data)));
            return r;
        case Kind::Text:
        case Kind::Binary:
            if (state_ != WebSocketState::Open && state_ != WebSocketState::Closing) return r;
            if (e.size > max_) {
                // The browser buffered the whole message already; it cannot send 1009, so it closes normally.
                Reaction f;
                f.events.push_back(WebSocketEvent::failure("a message of " + std::to_string(e.size) +
                                                               " bytes arrived; the most is " + std::to_string(max_),
                                                           "Raise maxMessageBytes in websocket.connect (up to 64 MB), "
                                                           "or ask the server for smaller messages."));
                f.events.push_back(WebSocketEvent::close(ws::close_code::kAbnormal, "", false));
                errored_ = finished_ = true;
                state_ = WebSocketState::Closed;
                f.stopBrowser = true;
                f.closeCode = ws::close_code::kNormal;
                f.closeReason = "message too big";
                return f;
            }
            r.events.push_back(e.kind == Kind::Text ? WebSocketEvent::text(std::move(e.data))
                                                    : WebSocketEvent::binary(std::move(e.data)));
            return r;
        case Kind::Error:
            if (errored_) return r;
            errored_ = true;
            {
                Text t = problem_text(opened_ ? Problem::ConnectionLost : Problem::CouldNotConnect, host_, secure_,
                                      pageHttps_, timeoutSec_);
                r.events.push_back(WebSocketEvent::failure(std::move(t.message), std::move(t.hint)));
            }
            return r;
        case Kind::Close:
            if (e.wasClean && opened_ && !errored_) {
                state_ = WebSocketState::Closed;  // before the event
                finished_ = true;
                r.events.push_back(WebSocketEvent::close(e.code, std::move(e.reason), true));
                return r;
            }
            return fail(opened_ ? Problem::ConnectionLost : Problem::CouldNotConnect, false);
        case Kind::ConnectTimeout:
            if (state_ != WebSocketState::Connecting) return r;
            return fail(Problem::ConnectTimeout, true);
        case Kind::CloseTimeout:
            if (state_ != WebSocketState::Closing) return r;
            return fail(Problem::CloseTimeout, true);
    }
    return r;
}

Reaction Mapper::on_close_requested(int code, const std::string& reason) {
    Reaction r;
    if (state_ == WebSocketState::Closing || state_ == WebSocketState::Closed) return r;
    if (state_ == WebSocketState::Connecting) return fail(Problem::ClosedBeforeOpen, true, true);
    state_ = WebSocketState::Closing;
    r.startClosing = true;
    r.closeCode = code;
    r.closeReason = reason;
    return r;
}

Reaction Mapper::on_queue_ended() {
    Reaction r;
    if (!finished_) {
        finished_ = true;
        state_ = WebSocketState::Closed;
        r.stopBrowser = true;
        r.closeCode = ws::close_code::kNormal;
        r.closeReason = "too many unread messages";
    }
    return r;
}

void Mapper::after_poll() {
    if (abandoned_ && state_ == WebSocketState::Closing) state_ = WebSocketState::Closed;
}

}  // namespace fa::web_ws
