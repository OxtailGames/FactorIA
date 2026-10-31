// Web: the browser's fetch (CORS applies: the server has to allow the page the game runs in). The request is handed to
// JavaScript, which keeps the result in a table; when fetch settles it calls fa_web_http_done(id) and the C++ side pulls
// the pieces out one by one (strings are measured, then copied into a buffer C++ owns). Everything runs on the browser's
// main thread, and `done` is called from fetch's callback, never from inside send().
// UNTESTED here: only compiled by CI (web job).
#include <emscripten.h>

#include <map>
#include <string>

#include "fa/platform/http.h"

EM_JS(void, fa_web_http_start, (int id, const char* method, const char* url, const char* headersJson, const char* body, int hasBody,
                                double timeoutSec, int maxBytes), {
    const results = (Module.faHttp = Module.faHttp || { results: {} }).results;
    const finish = (r) => {
        results[id] = r;
        Module._fa_web_http_done(id);
    };
    const fail = (error, hint, timedOut) => finish({ ok: false, error: error, hint: hint || '', timedOut: !!timedOut });
    const urlText = UTF8ToString(url);
    let host = urlText;
    try { host = new URL(urlText).host; } catch (e) {}
    if (typeof fetch !== 'function') { fail('this browser has no fetch', ''); return; }
    const controller = typeof AbortController === 'function' ? new AbortController() : null;
    let timedOut = false;
    const timer = controller ? setTimeout(() => { timedOut = true; controller.abort(); }, Math.max(1, timeoutSec * 1000)) : 0;
    const init = { method: UTF8ToString(method), headers: JSON.parse(UTF8ToString(headersJson)), redirect: 'follow',
                   credentials: 'omit', cache: 'no-store' };
    if (hasBody) init.body = UTF8ToString(body);
    if (controller) init.signal = controller.signal;
    fetch(urlText, init).then(async (response) => {
        const headers = [];
        response.headers.forEach((value, name) => headers.push([name.toLowerCase(), value]));
        const bytes = new Uint8Array(await response.arrayBuffer());
        if (timer) clearTimeout(timer);
        if (bytes.length > maxBytes) {
            fail('the response from ' + host + ' is longer than ' + Math.floor(maxBytes / 1024) + ' KB',
                 'http.fetch is for small texts (JSON, configuration); ask the server for less data.');
            return;
        }
        // Redirects only to https: the response says where it ended up.
        if (response.redirected && response.url && response.url.indexOf('https://') !== 0) {
            fail('the request to ' + host + ' was redirected to a URL that is not https://', 'Redirects are only followed to https:// addresses.');
            return;
        }
        finish({ ok: true, status: response.status, headers: headers, text: new TextDecoder('utf-8').decode(bytes) });
    }).catch((e) => {
        if (timer) clearTimeout(timer);
        if (timedOut) fail('the request to ' + host + ' timed out after ' + Math.round(timeoutSec) + ' s', 'Check the connection, or raise the timeout option of http.fetch.', true);
        else fail('the request to ' + host + ' failed' + (e && e.message ? ': ' + e.message : ''),
                  'The browser gives no detail on purpose. Check the connection, the address, and that the server allows this page (CORS).');
    });
});

EM_JS(int, fa_web_http_ok, (int id), { return Module.faHttp.results[id].ok ? 1 : 0; });
EM_JS(int, fa_web_http_status, (int id), { return Module.faHttp.results[id].status | 0; });
EM_JS(int, fa_web_http_timed_out, (int id), { return Module.faHttp.results[id].timedOut ? 1 : 0; });
EM_JS(int, fa_web_http_header_count, (int id), { return Module.faHttp.results[id].headers.length; });
// which: 0 body, 1 error, 2 hint, 3 header name #index, 4 header value #index.
EM_JS(int, fa_web_http_string_length, (int id, int which, int index), {
    const r = Module.faHttp.results[id];
    const s = which === 0 ? r.text : which === 1 ? r.error : which === 2 ? r.hint : which === 3 ? r.headers[index][0] : r.headers[index][1];
    return lengthBytesUTF8(s || '');
});
EM_JS(void, fa_web_http_string_copy, (int id, int which, int index, char* out, int capacity), {
    const r = Module.faHttp.results[id];
    const s = which === 0 ? r.text : which === 1 ? r.error : which === 2 ? r.hint : which === 3 ? r.headers[index][0] : r.headers[index][1];
    stringToUTF8(s || '', out, capacity);
});
EM_JS(void, fa_web_http_release, (int id), { delete Module.faHttp.results[id]; });

namespace fa {

namespace {

class WebHttpClient final : public HttpClient {
public:
    WebHttpClient();
    ~WebHttpClient() override;
    std::string name() const override { return "fetch"; }
    bool available() const override { return true; }
    void send(HttpRequest request, HttpDone done) override {
        const int id = ++lastId_;
        pending_[id] = std::move(done);
        std::string headers = "{";
        for (std::size_t i = 0; i < request.headers.size(); ++i) {
            if (i) headers += ",";
            headers += quote(request.headers[i].first) + ":" + quote(request.headers[i].second);
        }
        headers += "}";
        fa_web_http_start(id, request.method.c_str(), request.url.c_str(), headers.c_str(), request.body.c_str(),
                          request.body.empty() ? 0 : 1, request.timeoutSec, static_cast<int>(request.maxResponseBytes));
    }

    void finish(int id) {
        auto it = pending_.find(id);
        if (it == pending_.end()) {
            fa_web_http_release(id);
            return;
        }
        HttpDone done = std::move(it->second);
        pending_.erase(it);
        HttpResponse r;
        r.ok = fa_web_http_ok(id) != 0;
        if (r.ok) {
            r.status = fa_web_http_status(id);
            const int count = fa_web_http_header_count(id);
            for (int i = 0; i < count; ++i) r.headers.emplace_back(text(id, 3, i), text(id, 4, i));
            r.body = text(id, 0, 0);
        } else {
            r.error = text(id, 1, 0);
            r.hint = text(id, 2, 0);
            r.timedOut = fa_web_http_timed_out(id) != 0;
        }
        fa_web_http_release(id);
        done(std::move(r));
    }

private:
    static std::string text(int id, int which, int index) {
        const int length = fa_web_http_string_length(id, which, index);
        std::string out(static_cast<std::size_t>(length) + 1, '\0');
        fa_web_http_string_copy(id, which, index, out.data(), length + 1);
        out.resize(static_cast<std::size_t>(length));
        return out;
    }
    // A JSON string literal (the header table is handed to JavaScript as JSON text).
    static std::string quote(const std::string& s) {
        std::string out = "\"";
        for (unsigned char c : s) {
            if (c == '"' || c == '\\') {
                out += '\\';
                out += static_cast<char>(c);
            } else if (c < 0x20) {
                static const char* hex = "0123456789abcdef";
                out += "\\u00";
                out += hex[c >> 4];
                out += hex[c & 15];
            } else {
                out += static_cast<char>(c);
            }
        }
        return out + "\"";
    }

    int lastId_ = 0;
    std::map<int, HttpDone> pending_;
};

WebHttpClient* g_client = nullptr;

WebHttpClient::WebHttpClient() { g_client = this; }
WebHttpClient::~WebHttpClient() {
    if (g_client == this) g_client = nullptr;
}

}  // namespace

std::unique_ptr<HttpClient> make_system_http_client() { return std::make_unique<WebHttpClient>(); }

static void web_http_finish(int id) {
    if (g_client) g_client->finish(id);
}

}  // namespace fa

extern "C" EMSCRIPTEN_KEEPALIVE void fa_web_http_done(int id) { fa::web_http_finish(id); }
