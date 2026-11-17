// Web: the browser's WebSocket (fa/platform/websocket.h). Everything runs on the browser's main thread, like http_web.cpp:
// the JavaScript handlers (onopen, onmessage, onerror, onclose and two timers) put what happened in a list that JavaScript
// keeps per connection and call fa_web_ws_ready(id); the C++ side pulls the records one by one (strings are measured, then
// copied into a buffer C++ owns), gives them to a Mapper (websocket_web_mapping.h: the contract's rules, tested on every
// host) and pushes the events it answers into the connection's WebSocketEventQueue. poll() drains that queue, so the game
// still sees the events once per frame, never in the middle of a script.
//
// Destroying a connection abandons the queue, removes the connection from the table (a late call of fa_web_ws_ready finds
// nothing), and JavaScript removes the handlers and closes the socket. The browser cannot send a close code of 1001, so the
// server sees a close frame without a status.
// Checked by the Mapper's tests (every host) and by the web smoke test (scripts/web-smoke.sh, headless Chrome in CI).
#include <emscripten.h>

#include <map>
#include <memory>
#include <string>
#include <string_view>
#include <utility>

#include "fa/core/strings.h"
#include "fa/platform/websocket.h"
#include "fa/platform/websocket_codec.h"
#include "websocket_web_mapping.h"

// The JavaScript of EM_JS is not C++: clang-format must not touch it. Write the empty string as "" here: emscripten's clang
// warns "empty character constant" at a `''`.
// clang-format off
// Opens the socket. 1: started (events follow through fa_web_ws_ready); 0: the constructor threw (name and message in
// fa_web_ws_failure_*).
EM_JS(int, fa_web_ws_open, (int id, const char* url, const char* protocolsJson, double timeoutSec), {
    const w = (Module.faWs = Module.faWs || { sockets: {}, failure: { name: "", message: "" } });
    if (typeof WebSocket !== 'function') { w.failure = { name: 'NotSupported', message: 'this browser has no WebSocket' }; return 0; }
    let ws;
    try {
        const protocols = JSON.parse(UTF8ToString(protocolsJson));
        ws = protocols.length ? new WebSocket(UTF8ToString(url), protocols) : new WebSocket(UTF8ToString(url));
    } catch (e) {
        w.failure = { name: (e && e.name) || "", message: (e && e.message) || String(e) };
        return 0;
    }
    ws.binaryType = 'arraybuffer';
    const s = { ws: ws, queue: [], current: null, connectTimer: 0, closeTimer: 0 };
    w.sockets[id] = s;
    // kinds: 1 open, 2 text, 3 binary, 4 error, 5 close, 6 connect timeout, 7 close timeout
    const push = (record) => { s.queue.push(record); Module._fa_web_ws_ready(id); };
    ws.onopen = () => { clearTimeout(s.connectTimer); push({ kind: 1, text: ws.protocol || "", size: 0 }); };
    ws.onmessage = (event) => {
        if (typeof event.data === 'string') push({ kind: 2, text: event.data, size: lengthBytesUTF8(event.data) });
        else push({ kind: 3, buffer: event.data, size: event.data.byteLength });
    };
    ws.onerror = () => push({ kind: 4, size: 0 });
    ws.onclose = (event) => {
        clearTimeout(s.connectTimer); clearTimeout(s.closeTimer);
        push({ kind: 5, code: event.code | 0, text: event.reason || "", clean: !!event.wasClean, size: 0 });
    };
    s.connectTimer = setTimeout(() => { if (ws.readyState === 0) push({ kind: 6, size: 0 }); }, Math.max(1, timeoutSec * 1000));
    return 1;
});
EM_JS(int, fa_web_ws_failure_length, (int which), {
    const f = Module.faWs.failure;
    return lengthBytesUTF8(which === 0 ? f.name : f.message);
});
EM_JS(void, fa_web_ws_failure_copy, (int which, char* out, int capacity), {
    const f = Module.faWs.failure;
    stringToUTF8(which === 0 ? f.name : f.message, out, capacity);
});
// The page came over https (a browser then refuses ws:// addresses).
EM_JS(int, fa_web_ws_page_https, (), { return (typeof location === 'object' && location.protocol === 'https:') ? 1 : 0; });
// Takes the next record of the connection; returns its kind, 0 when the list is empty.
EM_JS(int, fa_web_ws_next, (int id), {
    const s = Module.faWs.sockets[id];
    if (!s) return 0;
    s.current = s.queue.shift() || null;
    return s.current ? s.current.kind : 0;
});
EM_JS(double, fa_web_ws_current_size, (int id), { return Module.faWs.sockets[id].current.size; });
EM_JS(int, fa_web_ws_current_code, (int id), { return Module.faWs.sockets[id].current.code | 0; });
EM_JS(int, fa_web_ws_current_clean, (int id), { return Module.faWs.sockets[id].current.clean ? 1 : 0; });
EM_JS(void, fa_web_ws_current_text_copy, (int id, char* out, int capacity), {
    stringToUTF8(Module.faWs.sockets[id].current.text || "", out, capacity);
});
EM_JS(int, fa_web_ws_current_text_length, (int id), { return lengthBytesUTF8(Module.faWs.sockets[id].current.text || ""); });
EM_JS(void, fa_web_ws_current_binary_copy, (int id, char* out), {
    HEAPU8.set(new Uint8Array(Module.faWs.sockets[id].current.buffer), out);
});
// Drops the record that was just read (a message that is too long is never copied).
EM_JS(void, fa_web_ws_current_drop, (int id), { Module.faWs.sockets[id].current = null; });
EM_JS(int, fa_web_ws_send_text, (int id, const char* data, int length), {
    const s = Module.faWs.sockets[id];
    try { s.ws.send(new TextDecoder('utf-8').decode(HEAPU8.subarray(data, data + length))); return 1; } catch (e) { return 0; }
});
EM_JS(int, fa_web_ws_send_binary, (int id, const char* data, int length), {
    const s = Module.faWs.sockets[id];
    try { s.ws.send(HEAPU8.slice(data, data + length)); return 1; } catch (e) { return 0; }
});
EM_JS(double, fa_web_ws_buffered, (int id), { return Module.faWs.sockets[id].ws.bufferedAmount; });
// close(code, reason) of the browser and the timer that ends a closing handshake the server never answers.
EM_JS(void, fa_web_ws_close, (int id, int code, const char* reason, double waitSec), {
    const s = Module.faWs.sockets[id];
    const text = UTF8ToString(reason);
    try { if (code) s.ws.close(code, text); else if (text) s.ws.close(1000, text); else s.ws.close(); } catch (e) {}
    if (s.ws.readyState !== 3) s.closeTimer = setTimeout(() => { s.queue.push({ kind: 7, size: 0 }); Module._fa_web_ws_ready(id); }, waitSec * 1000);
});
// Removes the handlers and the timers and closes the socket (a code of 0: none). The record of the connection stays until
// fa_web_ws_release.
EM_JS(void, fa_web_ws_stop, (int id, int code, const char* reason), {
    const s = Module.faWs && Module.faWs.sockets[id];
    if (!s) return;
    clearTimeout(s.connectTimer); clearTimeout(s.closeTimer);
    const ws = s.ws;
    ws.onopen = ws.onmessage = ws.onerror = ws.onclose = null;
    const text = UTF8ToString(reason);
    try { if (ws.readyState === 0 || ws.readyState === 1) { if (code) ws.close(code, text); else ws.close(); } } catch (e) {}
    s.queue = []; s.current = null;
});
EM_JS(void, fa_web_ws_release, (int id), { if (Module.faWs) delete Module.faWs.sockets[id]; });
// clang-format on

namespace fa {

namespace {

// Everything one connection's callbacks touch. The connection keeps it alive; the table below only looks at it.
class Core {
public:
    Core(int id, const WebSocketRequest& request, std::string host, bool secure, bool pageHttps)
        : id_(id), maxMessageBytes_(request.maxMessageBytes),
          queue_(std::make_shared<WebSocketEventQueue>(WebSocketEventQueue::limit_for(request.maxMessageBytes))),
          mapper_(std::move(host), secure, pageHttps, request.maxMessageBytes, request.connectTimeoutSec) {}

    int id() const { return id_; }
    WebSocketState state() const { return mapper_.state(); }
    std::size_t poll(std::vector<WebSocketEvent>& out) {
        const std::size_t n = queue_->drain(out);
        mapper_.after_poll();
        return n;
    }
    void abandon() { queue_->abandon(); }

    Result<void> send(bool binary, const void* data, std::size_t size) {
        auto r = web_ws::check_send(mapper_.state(), size, maxMessageBytes_, buffered());
        if (!r.ok()) return r;
        const char* bytes = static_cast<const char*>(data);
        if (!binary && !is_valid_utf8(std::string_view(bytes, size)))
            return make_error("the text is not valid UTF-8", "Send other data with send_binary.");
        const int length = static_cast<int>(size);  // at most 64 MB (maxMessageBytes)
        const bool sent =
            binary ? fa_web_ws_send_binary(id_, bytes, length) != 0 : fa_web_ws_send_text(id_, bytes, length) != 0;
        if (!sent)
            return make_error("the browser refused the message", "The connection may be closing; check readyState.");
        return {};
    }

    Result<void> close(int code, std::string_view reason) {
        if (auto r = ws::check_close_request(code, reason); !r.ok()) return r;
        apply(mapper_.on_close_requested(code, std::string(reason)));
        return {};
    }

    std::size_t buffered() const {
        if (mapper_.finished()) return 0;
        const double b = fa_web_ws_buffered(id_);
        return b > 0 ? static_cast<std::size_t>(b) : 0;
    }

    // fa_web_ws_ready: takes every record JavaScript has queued for this connection.
    void pump() {
        using Kind = web_ws::BrowserEvent::Kind;
        while (const int kind = fa_web_ws_next(id_)) {
            web_ws::BrowserEvent e;
            e.size = static_cast<std::size_t>(fa_web_ws_current_size(id_));
            switch (kind) {
                case 1: e.kind = Kind::Open; break;
                case 2: e.kind = Kind::Text; break;
                case 3: e.kind = Kind::Binary; break;
                case 4: e.kind = Kind::Error; break;
                case 5: e.kind = Kind::Close; break;
                case 6: e.kind = Kind::ConnectTimeout; break;
                default: e.kind = Kind::CloseTimeout; break;
            }
            if (mapper_.wants_payload(e.kind, e.size)) {
                if (kind == 3) {
                    e.data.resize(e.size);
                    if (e.size) fa_web_ws_current_binary_copy(id_, e.data.data());
                } else if (kind == 1 || kind == 2 || kind == 5) {
                    const int length = fa_web_ws_current_text_length(id_);
                    std::string text(static_cast<std::size_t>(length) + 1, '\0');
                    fa_web_ws_current_text_copy(id_, text.data(), length + 1);
                    text.resize(static_cast<std::size_t>(length));
                    (kind == 5 ? e.reason : e.data) = std::move(text);
                }
                if (kind == 5) {
                    e.code = fa_web_ws_current_code(id_);
                    e.wasClean = fa_web_ws_current_clean(id_) != 0;
                }
            }
            fa_web_ws_current_drop(id_);
            apply(mapper_.on_browser(std::move(e)));
        }
    }

private:
    void apply(web_ws::Reaction r) {
        bool overflow = false;
        for (auto& e : r.events) {
            if (!queue_->push(std::move(e))) {
                overflow = true;  // the queue holds [Error, Close 1008] and takes nothing more
                break;
            }
        }
        if (overflow) r = mapper_.on_queue_ended();
        if (r.startClosing)
            fa_web_ws_close(id_, r.closeCode, r.closeReason.c_str(), kWebSocketCloseWaitSec);
        else if (r.stopBrowser)
            fa_web_ws_stop(id_, r.closeCode, r.closeReason.c_str());
    }

    int id_;
    std::size_t maxMessageBytes_;
    std::shared_ptr<WebSocketEventQueue> queue_;
    web_ws::Mapper mapper_;
};

// The connections by id: what fa_web_ws_ready looks up. A connection removes itself, so a late call finds nothing.
std::map<int, Core*>& table() {
    static std::map<int, Core*> t;
    return t;
}
int g_lastId = 0;

class BrowserWebSocket final : public WebSocket {
public:
    explicit BrowserWebSocket(std::unique_ptr<Core> core) : core_(std::move(core)) {
        table()[core_->id()] = core_.get();
    }
    ~BrowserWebSocket() override {
        core_->abandon();  // what is pushed from now on is dropped
        table().erase(core_->id());
        fa_web_ws_stop(core_->id(), 0, "");
        fa_web_ws_release(core_->id());
    }
    WebSocketState state() const override { return core_->state(); }
    Result<void> send_text(std::string_view text) override { return core_->send(false, text.data(), text.size()); }
    Result<void> send_binary(const void* data, std::size_t size) override { return core_->send(true, data, size); }
    Result<void> close(int code, std::string_view reason) override { return core_->close(code, reason); }
    std::size_t buffered_amount() const override { return core_->buffered(); }
    std::size_t poll(std::vector<WebSocketEvent>& out) override { return core_->poll(out); }

private:
    std::unique_ptr<Core> core_;
};

std::string failure_text(int which) {
    const int length = fa_web_ws_failure_length(which);
    std::string out(static_cast<std::size_t>(length) + 1, '\0');
    fa_web_ws_failure_copy(which, out.data(), length + 1);
    out.resize(static_cast<std::size_t>(length));
    return out;
}

class BrowserWebSocketClient final : public WebSocketClient {
public:
    std::string name() const override { return "browser"; }
    bool available() const override { return true; }
    Result<std::unique_ptr<WebSocket>> connect(WebSocketRequest request) override {
        if (auto r = web_ws::check_request(request); !r.ok()) return r.error();
        auto url = ws::parse_url(request.url);
        if (!url.ok()) return url.error();
        const bool pageHttps = fa_web_ws_page_https() != 0;
        const int id = ++g_lastId;
        const std::string protocols = web_ws::json_string_array(request.subprotocols);
        if (!fa_web_ws_open(id, request.url.c_str(), protocols.c_str(), request.connectTimeoutSec)) {
            web_ws::Text t = web_ws::constructor_failure_text(failure_text(0), failure_text(1), request.url, pageHttps);
            return make_error(std::move(t.message), std::move(t.hint));
        }
        auto core = std::make_unique<Core>(id, request, url.value().host_header(), url.value().secure, pageHttps);
        std::unique_ptr<WebSocket> connection = std::make_unique<BrowserWebSocket>(std::move(core));
        return connection;
    }
};

}  // namespace

std::unique_ptr<WebSocketClient> make_system_websocket_client() { return std::make_unique<BrowserWebSocketClient>(); }

static void web_ws_ready(int id) {
    auto it = table().find(id);
    if (it == table().end()) {
        fa_web_ws_stop(id, 0, "");
        fa_web_ws_release(id);
        return;
    }
    it->second->pump();
}

}  // namespace fa

extern "C" EMSCRIPTEN_KEEPALIVE void fa_web_ws_ready(int id) { fa::web_ws_ready(id); }
