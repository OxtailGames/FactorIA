// project.serve_web: see fa/tooling/serve_web.h. Three kinds of threads: one accepts connections, a fixed pool answers them (one
// request per connection, "Connection: close"), and one watches the project and exports the web build. The UI never waits on
// any of them: status() copies a few strings under a mutex that nothing holds while it exports or sends.
#include "fa/tooling/serve_web.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <cstdlib>
#include <deque>
#include <filesystem>
#include <mutex>
#include <optional>
#include <set>
#include <thread>

#include "export_internal.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/tooling/export.h"
#include "fa/tooling/net.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

constexpr std::size_t kMaxHead = 8 * 1024;          // the request line and headers
constexpr std::size_t kMaxLogBody = 16 * 1024;      // POST __fa/log
constexpr int kWorkers = 8;                         // connections answered at the same time
constexpr std::size_t kMaxWaiting = 32;             // accepted connections waiting for a worker; more are closed
constexpr int kRecvTimeoutMs = 5000;                // a connection that sends nothing for this long is closed
constexpr int kSendTimeoutMs = 30000;               // a phone that takes this long for one chunk is gone
constexpr int kHeadDeadlineMs = 10000;              // the whole request head must arrive within this (safety net against a trickle)
constexpr std::size_t kMaxLogLine = 1000;           // bytes of one log line
constexpr std::size_t kMaxLinesPerPost = 20;
constexpr int kReaderWaitMs = 120000;               // safety net: waiting for the downloads of the folder the next export replaces

using Clock = std::chrono::steady_clock;

// 128 bits from the operating system's generator; "" when it has none (the server then does not start: a guessable token is no token).
std::string random_token() {
    unsigned char bytes[16];
    if (!net::secure_random(bytes, sizeof bytes)) return {};
    static const char* const hex = "0123456789abcdef";
    std::string t;
    for (unsigned char b : bytes) {
        t += hex[b >> 4];
        t += hex[b & 15];
    }
    return t;
}

stdfs::path path_from_utf8(std::string_view s) {
    return stdfs::path(std::u8string(reinterpret_cast<const char8_t*>(s.data()), s.size()));
}

std::string lower(std::string_view s) {
    std::string out(s);
    for (char& c : out) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return out;
}

std::string html_escape(std::string_view s) {
    std::string out;
    for (char c : s) {
        switch (c) {
            case '&': out += "&amp;"; break;
            case '<': out += "&lt;"; break;
            case '>': out += "&gt;"; break;
            case '"': out += "&quot;"; break;
            default: out += c;
        }
    }
    return out;
}

// Cuts `s` to at most `max` bytes without splitting a UTF-8 sequence.
std::string truncate_utf8(std::string s, std::size_t max) {
    if (s.size() <= max) return s;
    std::size_t cut = max;
    while (cut > 0 && (static_cast<unsigned char>(s[cut]) & 0xC0) == 0x80) --cut;
    s.resize(cut);
    return s + "...";
}

// The script the served index.html loads: the reload poll, the "rebuilding" banner and the console/error forwarding. It is
// small on purpose (a literal over 16 KB does not compile with MSVC).
const char* const kClientScript = R"JS((function () {
  'use strict';
  var base = location.pathname.replace(/[^\/]*$/, '');
  var loaded = window.__faServe ? window.__faServe.version : null;
  var q = [], timer = 0, dropped = 0, banner = null;
  function text(a) {
    if (a instanceof Error) return a.stack || a.message;
    if (a !== null && typeof a === 'object') { try { return JSON.stringify(a); } catch (e) { return String(a); } }
    return String(a);
  }
  function push(level, parts) {
    try {
      var t = Array.prototype.map.call(parts, text).join(' ');
      if (t.length > 900) t = t.slice(0, 900) + '...';
      if (q.length < 100) q.push({ l: level, t: t }); else dropped++;
      if (!timer) timer = setTimeout(flush, 400);
    } catch (e) {}
  }
  function flush() {
    timer = 0;
    if (!q.length) return;
    var batch = q.splice(0, 20);
    if (dropped) { batch.push({ l: 'warn', t: dropped + ' log lines of this page were dropped (too many at once)' }); dropped = 0; }
    try {
      fetch(base + '__fa/log', { method: 'POST', body: JSON.stringify(batch), headers: { 'Content-Type': 'text/plain' }, keepalive: true }).catch(function () {});
    } catch (e) {}
    if (q.length) timer = setTimeout(flush, 400);
  }
  ['log', 'info', 'warn', 'error'].forEach(function (name) {
    var original = console[name];
    console[name] = function () { push(name, arguments); return original.apply(console, arguments); };
  });
  window.addEventListener('error', function (e) { push('error', ['Uncaught ' + e.message + ' (' + e.filename + ':' + e.lineno + ')']); });
  window.addEventListener('unhandledrejection', function (e) { push('error', ['Unhandled promise rejection: ' + text(e.reason)]); });
  function show(message) {
    if (!message) { if (banner) { banner.remove(); banner = null; } return; }
    if (!banner) {
      banner = document.createElement('div');
      banner.style.cssText = 'position:fixed;left:8px;right:8px;bottom:8px;z-index:2147483647;padding:8px 12px;border-radius:6px;' +
        'background:#1c2a44;color:#fff;font:14px system-ui,sans-serif;pointer-events:none;opacity:.92';
      (document.body || document.documentElement).appendChild(banner);
    }
    banner.textContent = message;
  }
  function poll() {
    fetch(base + '__fa/version', { cache: 'no-store' }).then(function (r) { return r.json(); }).then(function (j) {
      if (loaded === null) loaded = j.version;
      if (j.version !== loaded) { location.reload(); return; }
      show(j.state === 'exporting' ? 'Rebuilding the game...' : j.state === 'failed' ? 'The last export failed: ' + j.error : '');
    }).catch(function () {}).then(function () { setTimeout(poll, 1000); });
  }
  push('info', ['phone page loaded: ' + navigator.userAgent + ', ' + innerWidth + 'x' + innerHeight + ' @' + (window.devicePixelRatio || 1)]);
  poll();
})();
)JS";

}  // namespace

// ---- pure helpers ----------------------------------------------------------------------------------------------------

namespace serve_web_detail {

std::string mime_type(std::string_view fileName) {
    const std::size_t dot = fileName.rfind('.');
    const std::string ext = dot == std::string_view::npos ? std::string() : lower(fileName.substr(dot + 1));
    static const std::pair<const char*, const char*> table[] = {
        {"html", "text/html; charset=utf-8"}, {"htm", "text/html; charset=utf-8"}, {"js", "text/javascript; charset=utf-8"},
        {"mjs", "text/javascript; charset=utf-8"}, {"wasm", "application/wasm"}, {"json", "application/json"},
        {"map", "application/json"}, {"css", "text/css; charset=utf-8"}, {"txt", "text/plain; charset=utf-8"},
        {"md", "text/plain; charset=utf-8"}, {"png", "image/png"}, {"jpg", "image/jpeg"}, {"jpeg", "image/jpeg"},
        {"gif", "image/gif"}, {"webp", "image/webp"}, {"svg", "image/svg+xml"}, {"ico", "image/x-icon"}, {"ogg", "audio/ogg"},
        {"oga", "audio/ogg"}, {"wav", "audio/wav"}, {"mp3", "audio/mpeg"}, {"mp4", "video/mp4"}, {"webm", "video/webm"},
        {"woff", "font/woff"}, {"woff2", "font/woff2"}, {"ttf", "font/ttf"}, {"otf", "font/otf"}, {"glb", "model/gltf-binary"},
        {"xml", "application/xml"}};
    for (const auto& [e, type] : table)
        if (ext == e) return type;
    return "application/octet-stream";  // game.pak and anything unknown
}

bool is_valid_utf8(std::string_view s) { return fa::is_valid_utf8(s); }

// CON, PRN, AUX, NUL, COM1-9, LPT1-9 (and the superscript digits; also CONIN$ and CONOUT$), with or without an extension, in any case: Windows opens a device
// instead of a file of that name, so they are refused on every platform (a game cannot ship such a file name there anyway).
bool is_reserved_device_name(std::string_view segment) {
    const std::size_t dot = segment.find('.');
    std::string base = lower(segment.substr(0, dot));
    while (!base.empty() && base.back() == ' ') base.pop_back();  // "con .txt" is the device too
    if (base == "con" || base == "prn" || base == "aux" || base == "nul" || base == "conin$" || base == "conout$") return true;
    if (base.rfind("com", 0) != 0 && base.rfind("lpt", 0) != 0) return false;
    if (base.size() == 4) return base[3] >= '1' && base[3] <= '9';  // COM0 and LPT0 are ordinary names
    // COM and LPT followed by the superscript digits 1, 2, 3 (U+00B9, U+00B2, U+00B3) are devices too.
    return base.size() == 5 && static_cast<unsigned char>(base[3]) == 0xC2 &&
           (static_cast<unsigned char>(base[4]) == 0xB9 || static_cast<unsigned char>(base[4]) == 0xB2 || static_cast<unsigned char>(base[4]) == 0xB3);
}

std::optional<std::string> safe_relative_path(std::string_view urlPath, bool* badEncoding) {
    if (badEncoding) *badEncoding = false;
    std::string decoded;
    for (std::size_t i = 0; i < urlPath.size(); ++i) {
        const char c = urlPath[i];
        if (c == '%') {
            auto hexval = [](char h) { return h >= '0' && h <= '9' ? h - '0' : h >= 'a' && h <= 'f' ? h - 'a' + 10 : h >= 'A' && h <= 'F' ? h - 'A' + 10 : -1; };
            if (i + 2 >= urlPath.size()) return std::nullopt;  // "%" needs two hex digits after it
            const int hi = hexval(urlPath[i + 1]), lo = hexval(urlPath[i + 2]);
            if (hi < 0 || lo < 0) return std::nullopt;
            decoded += static_cast<char>(hi * 16 + lo);
            i += 2;
        } else {
            decoded += c;
        }
    }
    if (decoded.empty()) return std::nullopt;
    if (!is_valid_utf8(decoded)) {  // before any path is built from it: std::filesystem throws on invalid UTF-8 (MSVC)
        if (badEncoding) *badEncoding = true;
        return std::nullopt;
    }
    // What is left after ONE decoding must be a plain relative path.
    for (char c : decoded) {
        const unsigned char u = static_cast<unsigned char>(c);
        if (u < 0x20 || u == 0x7F) return std::nullopt;
        if (c == '\\' || c == ':' || c == '%' || c == '*' || c == '?' || c == '"' || c == '<' || c == '>' || c == '|') return std::nullopt;
    }
    std::string out;
    std::size_t start = 0;
    while (start <= decoded.size()) {
        std::size_t slash = decoded.find('/', start);
        if (slash == std::string::npos) slash = decoded.size();
        const std::string seg = decoded.substr(start, slash - start);
        if (seg.empty() || seg[0] == '.') return std::nullopt;  // "", ".", "..", hidden files (.factoria-export)
        if (seg.back() == ' ') return std::nullopt;             // Windows drops trailing spaces and dots: "a. " names "a"
        if (seg.back() == '.') return std::nullopt;
        if (is_reserved_device_name(seg)) return std::nullopt;
        if (!out.empty()) out += '/';
        out += seg;
        if (slash == decoded.size()) break;
        start = slash + 1;
    }
    return out;
}

}  // namespace serve_web_detail

// ---- status ----------------------------------------------------------------------------------------------------------

Json ServeWebStatus::to_json() const {
    Json j = Json::object();
    j["running"] = running;
    j["state"] = state;
    if (!running) return j;
    j["url"] = localUrl;
    Json urls = Json::array();
    urls.push_back(localUrl);
    for (const std::string& u : lanUrls) urls.push_back(u);
    j["urls"] = urls;
    if (!lanUrls.empty()) j["lanUrl"] = lanUrls.front();
    j["lan"] = lan;
    j["port"] = port;
    j["projectDir"] = projectDir;
    if (!outputDir.empty()) j["outputDir"] = outputDir;
    j["version"] = version;
    j["requests"] = requests;
    j["phoneLogLines"] = phoneLogLines;
    if (!error.empty()) {
        j["error"] = error;
        if (!hint.empty()) j["hint"] = hint;
    }
    j["warnings"] = warnings;
    j["note"] = "The server runs inside this process and stops with it, or with project.serve_web {\"stop\":true}. Change a script or asset and the "
                "page reloads by itself; what the page logs shows up in the log (category phone).";
    return j;
}

// ---- the server ------------------------------------------------------------------------------------------------------

struct WebServer::Impl {
    ServeWebOptions opts;
    stdfs::path projectPath;
    std::string feedbackFile = "ENGINE_FEEDBACK.json";
    net::SocketRuntime sockets;
    net::Listener listener;
    std::string token;
    std::vector<std::string> lanIps;
    std::string noLanWarning;

    std::mutex m;
    std::condition_variable cv;      // state changes, stop, refresh requests, readers leaving
    std::condition_variable workCv;  // the queue of accepted connections
    bool stopping = false;
    bool refreshRequested = false;
    std::string state = "exporting", error, hint;
    std::vector<std::string> warnings;
    std::uint64_t version = 0, requests = 0, phoneLines = 0;
    // Phone log lines are rate limited: at most opts.phoneLinesPerWindow per opts.phoneWindowMs, the rest dropped and counted.
    Clock::time_point phoneWindowStart{};
    std::uint64_t phoneWindowCount = 0, phoneWindowDropped = 0;

    struct Slot {
        stdfs::path root;  // the export folder served from this slot (<project>/build/serve-web/<a|b>/<slug>-web)
        int readers = 0;   // requests reading files of it right now
        bool valid = false;
    };
    Slot slots[2];
    int active = -1;

    std::deque<net::Socket> queue;
    std::set<net::Socket> live;  // sockets a worker owns right now (stop() shuts them down)
    std::thread acceptor, exporter;
    std::vector<std::thread> workers;

    // ---- threads ----

    void accept_main() {
        while (true) {
            const net::Socket s = net::accept_connection(listener.socket);
            {
                std::lock_guard<std::mutex> lock(m);
                if (stopping) {
                    if (s != net::kNoSocket) net::close_socket(s);
                    return;
                }
            }
            if (s == net::kNoSocket) {
                std::this_thread::sleep_for(std::chrono::milliseconds(10));  // a failed accept (e.g. out of descriptors): do not spin
                continue;
            }
            net::set_io_timeouts(s, kRecvTimeoutMs, kSendTimeoutMs);
            std::unique_lock<std::mutex> lock(m);
            if (stopping || queue.size() >= kMaxWaiting) {
                lock.unlock();
                net::close_socket(s);
                continue;
            }
            queue.push_back(s);
            lock.unlock();
            workCv.notify_one();
        }
    }

    void worker_main() {
        while (true) {
            net::Socket s;
            {
                std::unique_lock<std::mutex> lock(m);
                workCv.wait(lock, [&] { return stopping || !queue.empty(); });
                if (stopping) return;
                s = queue.front();
                queue.pop_front();
                live.insert(s);
            }
            sentAny() = false;
            lingerAfter() = false;
            try {
                handle(s);
            } catch (...) {
                // Nothing may escape a worker thread (std::terminate would end the editor): bad_alloc, a filesystem_error, a Json type error...
                if (!sentAny()) respond_text(s, 500, "Internal error");
                lingerAfter() = true;
            }
            if (lingerAfter()) net::linger_close(s);  // after an error answer: no RST over the answer (see net::linger_close)
            {
                std::lock_guard<std::mutex> lock(m);
                live.erase(s);  // before the close: stop() only shuts down sockets that are still in the set
            }
            net::close_socket(s);
        }
    }

    // ---- responses ----

    // Per worker thread: did this connection get any bytes, and does it end with a lingering close (an error answer).
    static bool& sentAny() {
        thread_local bool v = false;
        return v;
    }
    static bool& lingerAfter() {
        thread_local bool v = false;
        return v;
    }
    static bool send_out(net::Socket s, std::string_view data) {
        sentAny() = true;
        return net::send_all(s, data);
    }

    static std::string status_text(int code) {
        switch (code) {
            case 200: return "OK";
            case 204: return "No Content";
            case 301: return "Moved Permanently";
            case 400: return "Bad Request";
            case 404: return "Not Found";
            case 405: return "Method Not Allowed";
            case 413: return "Payload Too Large";
            case 431: return "Request Header Fields Too Large";
            case 500: return "Internal Server Error";
            case 503: return "Service Unavailable";
            default: return "Error";
        }
    }

    static std::string head(int code, const std::string& contentType, std::uint64_t length, const std::string& extra = {}) {
        std::string h = "HTTP/1.1 " + std::to_string(code) + " " + status_text(code) + "\r\n";
        if (!contentType.empty()) h += "Content-Type: " + contentType + "\r\n";
        h += "Content-Length: " + std::to_string(length) + "\r\n";
        h += "Cache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nReferrer-Policy: no-referrer\r\nConnection: close\r\n";
        h += extra;
        return h + "\r\n";
    }

    static void respond(net::Socket s, int code, const std::string& contentType, const std::string& body, bool headOnly, const std::string& extra = {}) {
        std::string out = head(code, contentType, body.size(), extra);
        if (!headOnly) out += body;
        // Only where the request may not have been read to its end (a bad request, an oversized head or body): the system would answer the
        // unread input of a plain close with an RST that can wipe the answer. A 404 or 405 for a GET/HEAD read in full needs no wait.
        if (code == 400 || code == 413 || code == 431) lingerAfter() = true;
        send_out(s, out);
    }

    static void respond_text(net::Socket s, int code, const std::string& text, bool headOnly = false, const std::string& extra = {}) {
        respond(s, code, "text/plain; charset=utf-8", text + "\n", headOnly, extra);
    }

    // ---- one request ----

    struct Request {
        std::string method, target, path, query;
        std::size_t contentLength = 0;
        std::string body;  // POST: the bytes after the head, up to contentLength
    };

    // 0 = read, otherwise the status to answer with (0 bytes sent for a peer that left).
    int read_request(net::Socket s, Request& req) {
        std::string buf;
        const auto deadline = Clock::now() + std::chrono::milliseconds(kHeadDeadlineMs);
        std::size_t headEnd = std::string::npos;
        char chunk[2048];
        while ((headEnd = buf.find("\r\n\r\n")) == std::string::npos) {
            if (buf.size() > kMaxHead) return 431;
            if (Clock::now() > deadline) return -1;
            const std::ptrdiff_t n = net::recv_some(s, chunk, sizeof(chunk));
            if (n <= 0) return -1;
            buf.append(chunk, static_cast<std::size_t>(n));
        }
        if (headEnd > kMaxHead) return 431;
        const std::string headText = buf.substr(0, headEnd);
        std::string rest = buf.substr(headEnd + 4);
        // Request line: METHOD SP target SP HTTP/1.x
        const std::size_t eol = headText.find("\r\n");
        const std::string line = headText.substr(0, eol);
        const std::size_t sp1 = line.find(' '), sp2 = sp1 == std::string::npos ? sp1 : line.find(' ', sp1 + 1);
        if (sp1 == std::string::npos || sp2 == std::string::npos || !starts_with(std::string_view(line).substr(sp2 + 1), "HTTP/1.")) return 400;
        req.method = line.substr(0, sp1);
        req.target = line.substr(sp1 + 1, sp2 - sp1 - 1);
        if (req.target.empty() || req.target[0] != '/') return 400;
        const std::size_t q = req.target.find('?');
        req.path = req.target.substr(0, q);
        if (q != std::string::npos) req.query = req.target.substr(q + 1);
        // Headers: only Content-Length matters.
        std::size_t at = eol == std::string::npos ? headText.size() : eol + 2;
        while (at < headText.size()) {
            std::size_t next = headText.find("\r\n", at);
            if (next == std::string::npos) next = headText.size();
            const std::string h = headText.substr(at, next - at);
            const std::size_t colon = h.find(':');
            if (colon != std::string::npos && lower(h.substr(0, colon)) == "content-length") {
                const std::string v = std::string(trim(h.substr(colon + 1)));
                if (v.empty() || v.size() > 9 || v.find_first_not_of("0123456789") != std::string::npos) return 400;
                req.contentLength = static_cast<std::size_t>(std::stoul(v));
            }
            at = next + 2;
        }
        if (req.method == "POST") {
            if (req.contentLength > kMaxLogBody) return 413;
            req.body = std::move(rest);
            if (req.body.size() > req.contentLength) req.body.resize(req.contentLength);
            const auto bodyDeadline = Clock::now() + std::chrono::milliseconds(kHeadDeadlineMs);
            while (req.body.size() < req.contentLength) {
                if (Clock::now() > bodyDeadline) return -1;
                const std::ptrdiff_t n = net::recv_some(s, chunk, std::min(sizeof(chunk), req.contentLength - req.body.size()));
                if (n <= 0) return -1;
                req.body.append(chunk, static_cast<std::size_t>(n));
            }
        }
        return 0;
    }

    void handle(net::Socket s) {
        Request req;
        const int rc = read_request(s, req);
        if (rc < 0) return;
        if (rc > 0) {
            respond_text(s, rc, status_text(rc));
            return;
        }
        const bool headOnly = req.method == "HEAD";
        if (req.method != "GET" && !headOnly && req.method != "POST") {
            respond_text(s, 405, "Method not allowed", false, "Allow: GET, HEAD, POST\r\n");
            return;
        }
        // The token is the only door in: everything else is the same 404, so nothing tells a guess from a miss.
        const std::string prefix = "/" + token;
        const bool tokenOk = req.path.size() >= prefix.size() && (req.path.size() == prefix.size() || req.path[prefix.size()] == '/') &&
                             net::constant_time_equal(std::string_view(req.path).substr(1, token.size()), token);
        if (!tokenOk) {
            respond_text(s, 404, "Not found", headOnly);
            return;
        }
        {
            std::lock_guard<std::mutex> lock(m);
            ++requests;
        }
        if (req.path == prefix) {
            respond_text(s, 301, "Moved", headOnly, "Location: " + prefix + "/\r\n");
            return;
        }
        const std::string rest = req.path.substr(prefix.size() + 1);
        if (starts_with(rest, "__fa/")) {
            handle_control(s, req, rest.substr(5), headOnly);
            return;
        }
        if (req.method == "POST") {
            respond_text(s, 405, "Method not allowed", false, "Allow: GET, HEAD\r\n");
            return;
        }
        std::string file = "index.html";
        if (!rest.empty()) {
            bool badEncoding = false;
            auto safe = serve_web_detail::safe_relative_path(rest, &badEncoding);
            if (!safe) {
                if (badEncoding) respond_text(s, 400, "Bad request: the path is not valid UTF-8", headOnly);
                else respond_text(s, 404, "Not found", headOnly);
                return;
            }
            file = *safe;
        }
        serve_file(s, file, headOnly);
    }

    void handle_control(net::Socket s, const Request& req, const std::string& what, bool headOnly) {
        if (what == "version" && req.method != "POST") {
            flush_phone_notice();
            Json j;
            {
                std::lock_guard<std::mutex> lock(m);  // copy under the lock, send after it: a slow phone must not hold up the export thread
                j = Json::object({{"version", version}, {"state", state}, {"error", error}});
            }
            respond(s, 200, "application/json", j.dump(-1, ' ', false, Json::error_handler_t::replace), headOnly);
            return;
        }
        if (what == "client.js" && req.method != "POST") {
            respond(s, 200, "text/javascript; charset=utf-8", kClientScript, headOnly);
            return;
        }
        if (what == "log" && req.method == "POST") {
            accept_phone_log(s, req.body);
            return;
        }
        respond_text(s, 404, "Not found", headOnly);
    }

    // The window of phone log lines is over: start a new one on the next line, and return how many lines it dropped (to report outside the
    // lock). `m` is held.
    std::uint64_t close_phone_window_locked(Clock::time_point now) {
        if (phoneWindowStart == Clock::time_point{} || now - phoneWindowStart < std::chrono::milliseconds(opts.phoneWindowMs)) return 0;
        const std::uint64_t dropped = phoneWindowDropped;
        phoneWindowStart = Clock::time_point{};
        phoneWindowCount = 0;
        phoneWindowDropped = 0;
        return dropped;
    }
    void report_dropped_lines(std::uint64_t dropped) const {
        if (dropped > 0)  // never under `m`: the log has its own locks and sinks
            FA_WARN("phone", "{} log lines from the page were dropped (more than {} in {} s); the page may be logging in a loop", dropped,
                    opts.phoneLinesPerWindow, opts.phoneWindowMs / 1000.0);
    }
    // Called by status() and the version endpoint: a window that dropped lines reports them once it is over, also when the page sends no more.
    void flush_phone_notice() {
        std::uint64_t dropped;
        {
            std::lock_guard<std::mutex> lock(m);
            dropped = close_phone_window_locked(Clock::now());
        }
        report_dropped_lines(dropped);
    }

    // One phone log line is allowed or not: at most opts.phoneLinesPerWindow in each opts.phoneWindowMs, the rest are dropped, and
    // the end of a window that dropped some says how many (so a page that logs in a loop cannot fill the log or the console).
    bool phone_line_allowed() {
        std::uint64_t dropped;
        bool allowed = true;
        {
            std::lock_guard<std::mutex> lock(m);
            const auto now = Clock::now();
            dropped = close_phone_window_locked(now);
            if (phoneWindowStart == Clock::time_point{}) phoneWindowStart = now;
            if (phoneWindowCount >= static_cast<std::uint64_t>(opts.phoneLinesPerWindow)) {
                ++phoneWindowDropped;
                allowed = false;
            } else {
                ++phoneWindowCount;
                ++phoneLines;
            }
        }
        report_dropped_lines(dropped);
        return allowed;
    }

    void accept_phone_log(net::Socket s, const std::string& body) {
        auto parsed = parse_json(body, "<phone log>");
        if (!parsed.ok() || !parsed->is_array()) {
            respond_text(s, 400, "Expected a JSON array of {l, t}");
            return;
        }
        std::size_t taken = 0;
        for (const Json& e : *parsed) {
            if (taken >= kMaxLinesPerPost) break;
            if (!e.is_object()) continue;
            // Whatever the page sends: a field of another type is skipped, never read as a string (that throws).
            std::string level = "log", text;
            if (auto it = e.find("l"); it != e.end() && it->is_string()) level = it->get<std::string>();
            if (auto it = e.find("t"); it != e.end() && it->is_string()) text = it->get<std::string>();
            if (text.empty()) continue;
            if (!phone_line_allowed()) continue;  // dropped and counted
            ++taken;
            std::string clean;
            for (char c : truncate_utf8(text, kMaxLogLine)) clean += (static_cast<unsigned char>(c) < 0x20 && c != '\t') ? ' ' : c;
            const LogLevel lv = level == "error" ? LogLevel::Error : level == "warn" ? LogLevel::Warn : LogLevel::Info;
            log(lv, "phone", clean);
        }
        send_out(s, head(204, "", 0));
    }

    // The slot to read files from, with its reader count raised; -1 when no export has finished yet.
    int acquire(stdfs::path& root) {
        std::lock_guard<std::mutex> lock(m);
        if (active < 0) return -1;
        ++slots[active].readers;
        root = slots[active].root;
        return active;
    }
    void release(int slot) {
        {
            std::lock_guard<std::mutex> lock(m);
            --slots[slot].readers;
        }
        cv.notify_all();
    }

    void serve_file(net::Socket s, const std::string& file, bool headOnly) {
        stdfs::path root;
        const int slot = acquire(root);
        if (slot < 0) {
            std::string st, err;
            {
                std::lock_guard<std::mutex> lock(m);
                st = state;
                err = error;
            }
            const bool failed = st == "failed";
            std::string page = "<!doctype html><meta charset=utf-8><meta name=viewport content=\"width=device-width,initial-scale=1\">";
            if (!failed) page += "<meta http-equiv=refresh content=2>";
            page += "<body style=\"font:16px system-ui,sans-serif;background:#0f1115;color:#e8eaf0;padding:24px\">";
            page += failed ? "<h2>The game could not be exported</h2><pre style=\"white-space:pre-wrap\">" + html_escape(err) + "</pre><p>Fix it and this page updates by itself on the next try.</p><script>setTimeout(function(){location.reload()},5000)</script>"
                           : "<h2>Exporting the game...</h2><p>This page reloads by itself.</p>";
            respond(s, 503, "text/html; charset=utf-8", page, headOnly, "Retry-After: 2\r\n");
            return;
        }
        struct Release {
            Impl* self;
            int slot;
            ~Release() { self->release(slot); }
        } releaser{this, slot};

        std::error_code ec;
        const stdfs::path full = fs::os_path(root / path_from_utf8(file));
        const stdfs::path canonRoot = stdfs::weakly_canonical(fs::os_path(root), ec);
        const stdfs::path canonFull = stdfs::weakly_canonical(full, ec);
        const stdfs::path rel = canonFull.lexically_relative(canonRoot);
        if (ec || rel.empty() || *rel.begin() == ".." || !stdfs::is_regular_file(canonFull, ec)) {
            respond_text(s, 404, "Not found", headOnly);
            return;
        }
        const std::uint64_t size = static_cast<std::uint64_t>(stdfs::file_size(canonFull, ec));
        if (ec) {
            respond_text(s, 404, "Not found", headOnly);
            return;
        }
        fs::ReadStream in(canonFull, std::ios::binary);
        if (!in) {
            respond_text(s, 404, "Not found", headOnly);
            return;
        }
        const std::string type = serve_web_detail::mime_type(file);
        if (file == "index.html") {  // the page gets the reload/log script (the file on disk stays as the export wrote it)
            std::string html((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
            std::uint64_t v;
            {
                std::lock_guard<std::mutex> lock(m);
                v = version;
            }
            const std::string inject = "<script>window.__faServe={version:" + std::to_string(v) + "};</script><script src=\"__fa/client.js\"></script>";
            const std::size_t headTag = html.find("<head>");
            if (headTag != std::string::npos) html.insert(headTag + 6, inject);
            else html = inject + html;
            respond(s, 200, type, html, headOnly);
            return;
        }
        if (!send_out(s, head(200, type, size))) return;
        if (headOnly) return;
        std::string buf(64 * 1024, '\0');
        std::uint64_t sent = 0;
        while (sent < size && in) {
            in.read(buf.data(), static_cast<std::streamsize>(std::min<std::uint64_t>(buf.size(), size - sent)));
            const std::streamsize got = in.gcount();
            if (got <= 0) break;
            if (!send_out(s, std::string_view(buf.data(), static_cast<std::size_t>(got)))) return;
            sent += static_cast<std::uint64_t>(got);
        }
        // A file shorter than announced: the connection closes, so the client sees a truncated download, not a wrong file.
    }

    // ---- the export thread ----

    // A hash of everything that decides what the web build holds: the files that ship (path, size, time) and the explicit player.
    std::uint64_t fingerprint() const {
        std::uint64_t h = 1469598103934665603ull;
        auto mix = [&h](std::uint64_t v) {
            for (int i = 0; i < 8; ++i, v >>= 8) h = (h ^ (v & 0xFF)) * 1099511628211ull;
        };
        auto mix_text = [&](const std::string& t) {
            for (unsigned char c : t) h = (h ^ c) * 1099511628211ull;
            mix(t.size());
        };
        auto mix_file = [&](const stdfs::path& f) {
            std::error_code ec;
            const std::uintmax_t size = stdfs::file_size(fs::os_path(f), ec);
            mix(ec ? ~0ull : static_cast<std::uint64_t>(size));
            mix(static_cast<std::uint64_t>(fs::host_modified_time(f)));
        };
        for (const std::string& rel : export_detail::list_game_files(projectPath, feedbackFile)) {
            mix_text(rel);
            mix_file(projectPath / stdfs::path(rel));  // list_game_files returns native strings (generic_string())
        }
        if (!opts.playerBinary.empty()) {
            stdfs::path dir(opts.playerBinary);  // a native string (ExportOptions::playerBinary)
            std::error_code ec;
            if (stdfs::is_regular_file(fs::os_path(dir), ec)) dir = dir.parent_path();
            mix_file(dir / "factoria_player.js");
            mix_file(dir / "factoria_player.wasm");
        }
        return h;
    }

    // Waits (with the lock) until nobody reads the folder the next export replaces. False when stopping or after the safety net.
    bool wait_no_readers(std::unique_lock<std::mutex>& lock, int slot) {
        return cv.wait_for(lock, std::chrono::milliseconds(kReaderWaitMs), [&] { return stopping || slots[slot].readers == 0; }) && !stopping;
    }

    void do_export() {
        int target;
        {
            std::unique_lock<std::mutex> lock(m);
            state = "exporting";
            target = active == 0 ? 1 : 0;
            cv.notify_all();
            if (!wait_no_readers(lock, target)) {
                if (!stopping) {
                    state = "failed";
                    error = "A browser is still downloading the previous build, so the next one cannot be written yet.";
                    hint = "It is tried again on the next check; close the page that is loading, or stop and start project.serve_web.";
                }
                cv.notify_all();
                return;
            }
            slots[target].valid = false;  // nobody reads it now, and nobody will until the export is done and switched to
        }
        ExportOptions eo;
        eo.projectDir = projectPath.generic_string();
        eo.platform = "web";
        eo.outDir = (projectPath / "build" / "serve-web" / (target == 0 ? "a" : "b")).generic_string();
        eo.playerBinary = opts.playerBinary;
        eo.allowPlayerMismatch = opts.allowPlayerMismatch;
        eo.buildSourceRoot = opts.buildSourceRoot;
        auto r = export_project(eo);
        std::unique_lock<std::mutex> lock(m);
        if (stopping) return;
        if (r.ok()) {
            slots[target].root = stdfs::path(r->outputDir);  // native, like every path string the export returns
            slots[target].valid = true;
            active = target;
            ++version;
            state = "ready";
            error.clear();
            hint.clear();
            warnings = r->warnings;
            if (!noLanWarning.empty()) warnings.push_back(noLanWarning);
            FA_INFO("serve", "web build exported ({} files); the pages reload", r->files.size());
        } else {
            const bool changed = error != r.error().message;
            state = "failed";
            error = r.error().message;
            hint = r.error().hint;
            if (changed) FA_WARN("serve", "web export failed: {}", r.error().to_string());
        }
        cv.notify_all();
    }

    void export_main() {
        std::uint64_t lastFp = 0, candidate = 0;
        bool haveFp = false, haveCandidate = false;
        int failedPolls = 0;
        while (true) {
            const std::uint64_t fp = fingerprint();
            bool doExport = false;
            if (!haveFp) {
                doExport = true;
            } else if (fp != lastFp) {
                // Wait until the files stopped changing (an editor saving several files, a build writing assets).
                if (haveCandidate && candidate == fp) doExport = true;
                else {
                    candidate = fp;
                    haveCandidate = true;
                }
            } else {
                haveCandidate = false;
                std::lock_guard<std::mutex> lock(m);
                if (state == "failed" && ++failedPolls >= 10) doExport = true;  // the player may have been installed since
            }
            if (doExport) {
                do_export();
                haveFp = true;
                lastFp = fp;  // taken before the export: a file the export itself rewrote (a baked image) shows as a change next time
                haveCandidate = false;
                failedPolls = 0;
            }
            std::unique_lock<std::mutex> lock(m);
            if (stopping) return;
            const int wait = std::max(20, haveCandidate ? opts.pollMs / 3 : opts.pollMs);
            cv.wait_for(lock, std::chrono::milliseconds(wait), [&] { return stopping || refreshRequested; });
            if (stopping) return;
            refreshRequested = false;
        }
    }
};

WebServer::WebServer() = default;

WebServer::~WebServer() { stop(); }

std::shared_ptr<WebServer::Impl> WebServer::current() const {
    std::lock_guard<std::mutex> lock(ptrMutex_);
    return impl_;
}

Result<void> WebServer::start(const ServeWebOptions& options) {
    std::lock_guard<std::mutex> lifecycle(lifecycleMutex_);
    stop_locked();
    auto impl = std::make_shared<Impl>();
    if (!impl->sockets.ok())
        return make_error("project.serve_web: the network could not be started (Winsock)", "check that no security software blocks this program from using the network");
    std::error_code ec;
    impl->projectPath = stdfs::absolute(stdfs::path(options.projectDir), ec);  // projectDir is a native string (ANSI code page on Windows), not UTF-8
    if (options.projectDir.empty() || !stdfs::is_regular_file(fs::os_path(impl->projectPath / "factoria.json"), ec))
        return make_error("project.serve_web: '" + options.projectDir + "' is not a FactorIA project (factoria.json not found)",
                          "open a project (or pass --project <folder with factoria.json>); a scratch session has nothing to serve");
    impl->opts = options;
    impl->opts.pollMs = std::clamp(options.pollMs, 20, 60000);
    if (auto text = tooling_detail::read_file(impl->projectPath / "factoria.json"))
        if (auto j = parse_json(*text, "factoria.json"); j.ok() && j->is_object() && j->contains("feedbackFile") && (*j)["feedbackFile"].is_string())
            impl->feedbackFile = (*j)["feedbackFile"].get<std::string>();
    // A plan first: a missing web player is reported now, with how to get it, not as a page that never loads.
    {
        ExportOptions eo;
        eo.projectDir = impl->projectPath.generic_string();
        eo.platform = "web";
        eo.playerBinary = options.playerBinary;
        eo.allowPlayerMismatch = options.allowPlayerMismatch;
        eo.buildSourceRoot = options.buildSourceRoot;
        eo.outDir = (impl->projectPath / "build" / "serve-web" / "a").generic_string();
        if (auto plan = plan_export(eo); !plan.ok()) return plan.error();
    }
    auto listener = net::listen_tcp(options.lan);
    if (!listener.ok()) return listener.error();
    impl->listener = *listener;
    impl->token = random_token();
    if (impl->token.empty()) {
        net::close_socket(impl->listener.socket);
        return make_error("project.serve_web: the operating system gave no random numbers for the address token",
                          "restart the program; if it keeps happening, the system's random number generator is broken");
    }
    if (options.lan) {
        impl->lanIps = net::lan_addresses();
        if (impl->lanIps.empty())
            impl->noLanWarning = "No private network address (192.168.x.x, 10.x.x.x, 172.16-31.x.x) was found on this computer, so there is no LAN URL: "
                                 "connect to Wi-Fi or Ethernet, then restart the server. The server is listening on every interface, port " +
                                 std::to_string(impl->listener.port) + ".";
    }
    Impl* raw = impl.get();
    for (int i = 0; i < kWorkers; ++i) raw->workers.emplace_back([raw] { raw->worker_main(); });
    raw->acceptor = std::thread([raw] { raw->accept_main(); });
    raw->exporter = std::thread([raw] { raw->export_main(); });
    {
        std::lock_guard<std::mutex> lock(ptrMutex_);
        impl_ = std::move(impl);
    }
    FA_INFO("serve", "serving the web build of {} on port {} ({})", options.projectDir, listener->port, options.lan ? "LAN" : "this computer only");
    return {};
}

void WebServer::stop() {
    std::lock_guard<std::mutex> lifecycle(lifecycleMutex_);
    stop_locked();
}

void WebServer::stop_locked() {
    std::shared_ptr<Impl> impl;
    {
        std::lock_guard<std::mutex> lock(ptrMutex_);
        impl = std::move(impl_);
    }
    if (!impl) return;
    {
        std::lock_guard<std::mutex> lock(impl->m);
        impl->stopping = true;
        for (net::Socket s : impl->live) net::shutdown_socket(s);
        for (net::Socket s : impl->queue) net::close_socket(s);
        impl->queue.clear();
    }
    impl->cv.notify_all();
    impl->workCv.notify_all();
    net::shutdown_socket(impl->listener.socket);
    net::close_socket(net::connect_loopback(impl->listener.port));  // wakes an accept() that shutdown() did not (macOS)
    if (impl->acceptor.joinable()) impl->acceptor.join();
    net::close_socket(impl->listener.socket);
    for (std::thread& t : impl->workers)
        if (t.joinable()) t.join();
    if (impl->exporter.joinable()) impl->exporter.join();
    // A connection accepted between the flag and the join is closed by the accept thread (it checks the flag), one that a worker
    // never took was closed above.
}

bool WebServer::running() const { return current() != nullptr; }

ServeWebStatus WebServer::status() const {
    ServeWebStatus st;
    const std::shared_ptr<Impl> impl = current();
    if (!impl) return st;
    Impl* self = impl.get();
    self->flush_phone_notice();
    std::lock_guard<std::mutex> lock(self->m);
    st.running = true;
    st.state = self->state;
    st.projectDir = self->projectPath.generic_string();
    if (self->active >= 0) st.outputDir = self->slots[self->active].root.generic_string();
    st.lan = self->opts.lan;
    st.port = self->listener.port;
    const std::string tail = ":" + std::to_string(st.port) + "/" + self->token + "/";
    st.localUrl = "http://127.0.0.1" + tail;
    for (const std::string& ip : self->lanIps) st.lanUrls.push_back("http://" + ip + tail);
    st.error = self->error;
    st.hint = self->hint;
    st.warnings = self->warnings;
    if (self->state != "ready" && !self->noLanWarning.empty() && std::find(st.warnings.begin(), st.warnings.end(), self->noLanWarning) == st.warnings.end())
        st.warnings.push_back(self->noLanWarning);
    st.version = self->version;
    st.requests = self->requests;
    st.phoneLogLines = self->phoneLines;
    return st;
}

ServeWebStatus WebServer::wait_ready(int timeoutMs) {
    const std::shared_ptr<Impl> impl = current();
    if (!impl) return status();
    {
        std::unique_lock<std::mutex> lock(impl->m);
        impl->cv.wait_for(lock, std::chrono::milliseconds(std::max(timeoutMs, 0)), [&] { return impl->stopping || impl->state != "exporting"; });
    }
    return status();
}

void WebServer::refresh() {
    const std::shared_ptr<Impl> impl = current();
    if (!impl) return;
    {
        std::lock_guard<std::mutex> lock(impl->m);
        impl->refreshRequested = true;
    }
    impl->cv.notify_all();
}

WebServer& web_server() {
    static WebServer server;
    return server;
}

// ---- the command without waiting (the editor) ------------------------------------------------------------------------

namespace {

std::atomic<bool> g_blocking{true};

// The helper thread of the non-waiting command: one job at a time (a start, or a stop). Everything but `thread` is guarded by `mu`.
struct AsyncJob {
    enum class Kind { Start, Stop };
    std::mutex mu;
    std::thread thread;
    bool busy = false;
    Kind kind = Kind::Start;
    bool stopRequested = false;  // {stop:true} came while a start ran: the start job stops the server it just started, when it ends
    std::optional<std::pair<std::string, std::string>> error;  // why the last start failed: message, hint (reported once)
};

AsyncJob& async_job() {
    static AsyncJob job;
    return job;
}

bool serves_this(const ServeWebStatus& now, const ServeWebOptions& o, const std::string& projectDir) {
    std::error_code ec;
    return now.running && now.lan == o.lan &&
           stdfs::weakly_canonical(stdfs::absolute(stdfs::path(projectDir), ec), ec) == stdfs::weakly_canonical(stdfs::path(now.projectDir), ec);  // both native
}

// Runs a stop on the helper thread. `job.mu` is held by the caller; no job is running.
void spawn_stop_job(AsyncJob& job) {
    if (job.thread.joinable()) job.thread.join();  // finished (busy was false)
    job.error.reset();
    job.stopRequested = false;
    job.busy = true;
    job.kind = AsyncJob::Kind::Stop;
    job.thread = std::thread([&job] {
        web_server().stop();
        std::lock_guard<std::mutex> lock(job.mu);
        job.busy = false;
    });
}

// {stop:true} without waiting. Stopping waits for a running export (seconds), so it is not done on the caller's thread; while a start is
// still running the stop is recorded and the start job honours it when it ends (the server must not come up after "stopped").
Json stop_without_waiting() {
    AsyncJob& job = async_job();
    const bool was = web_server().running();
    std::lock_guard<std::mutex> lock(job.mu);
    bool stopping = was;
    if (job.busy) {
        if (job.kind == AsyncJob::Kind::Start) job.stopRequested = true;
        stopping = true;
    } else if (was) {
        spawn_stop_job(job);
    } else {
        if (job.thread.joinable()) job.thread.join();
        job.error.reset();  // a failed start nobody asked about is not reported to a call that stops
    }
    return Json::object({{"running", was}, {"stopping", stopping}, {"state", stopping ? "stopping" : "stopped"},
                         {"note", stopping ? "The server is stopping on a helper thread; project.serve_web again to see that it is gone."
                                           : "The server was not running."}});
}

Json serve_without_waiting(const ServeWebOptions& o, const std::string& projectDir) {
    AsyncJob& job = async_job();
    WebServer& server = web_server();
    std::lock_guard<std::mutex> lock(job.mu);
    if (job.busy) {
        if (job.kind == AsyncJob::Kind::Stop || job.stopRequested)
            return Json::object({{"running", server.running()}, {"state", "stopping"},
                                 {"note", "The server is stopping on a helper thread: call project.serve_web again in a moment to start it."}});
        return Json::object({{"running", server.running()}, {"state", "starting"},
                             {"note", "A start is in progress on a helper thread: call project.serve_web again in a moment."}});
    }
    if (job.thread.joinable()) job.thread.join();  // finished (busy is false)
    if (job.error) {
        const auto err = *job.error;
        job.error.reset();
        throw CommandError("failed", err.first, err.second);
    }
    const ServeWebStatus now = server.status();
    if (serves_this(now, o, projectDir)) {
        if (now.state == "failed" && now.version == 0) {  // like the waiting form: nothing worth serving, no listener left behind
            spawn_stop_job(job);
            throw CommandError("failed", now.error, now.hint);
        }
        Json j = now.to_json();
        if (now.state == "exporting") j["note"] = "The web build is being exported: call project.serve_web again until state is \"ready\".";
        return j;
    }
    job.busy = true;
    job.kind = AsyncJob::Kind::Start;
    job.stopRequested = false;
    job.thread = std::thread([&job, o] {
        auto r = web_server().start(o);
        {
            std::lock_guard<std::mutex> lk(job.mu);
            if (!r.ok()) job.error = std::make_pair(r.error().message, r.error().hint);
        }
        while (true) {
            {
                std::lock_guard<std::mutex> lk(job.mu);
                if (!job.stopRequested) {
                    job.busy = false;  // under the lock that records a stop request: none is lost between the check and this line
                    return;
                }
                job.stopRequested = false;
                job.error.reset();  // asked to stop: a failed start is not worth reporting
            }
            web_server().stop();
        }
    });
    return Json::object({{"running", false}, {"state", "starting"},
                         {"note", "The server starts and exports the web build on a helper thread (the first export takes seconds): call project.serve_web "
                                  "again with the same arguments until state is \"ready\"; a start that fails is reported by that call."}});
}

}  // namespace

void set_serve_web_blocking(bool blocking) { g_blocking = blocking; }

void serve_web_shutdown() {
    AsyncJob& job = async_job();
    std::thread t;
    {
        std::lock_guard<std::mutex> lock(job.mu);
        job.stopRequested = false;
        t = std::move(job.thread);
    }
    if (t.joinable()) t.join();
    {
        std::lock_guard<std::mutex> lock(job.mu);
        job.busy = false;
        job.stopRequested = false;
        job.error.reset();
    }
    web_server().stop();
}

// ---- the command -----------------------------------------------------------------------------------------------------

void register_serve_web_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "project.serve_web";
    info.category = "project";
    info.readOnly = false;
    info.summary = "Serve the game's web build on this computer, or on the Wi-Fi to try it on a phone; it reloads when the project changes.";
    info.description =
        "Exports the web build (the same as project.export {platform:\"web\"}, into build/serve-web/, so the "
        "real export folder is not touched; the web player must be installed: `factoria setup players "
        "--platforms web`) and serves it from a small HTTP server inside this process. It listens on "
        "127.0.0.1 (this computer only) unless `lan` is true, on a random port, and the URL has a random "
        "token in its path: http://<address>:<port>/<token>/ (a request without the token is a 404). Returns "
        "{running, state, url (this computer), lanUrl and urls[] (lan), port, version, warnings[]}. While "
        "the server runs, a changed script, scene, asset or factoria.json exports the build again and every "
        "open page reloads itself (a banner on the page says when it is rebuilding or when the export "
        "failed); what the page logs (console.log/warn/error and uncaught errors) comes back to the log with "
        "category \"phone\" (read it with game.logs or in the editor console). With lan, open the URL on a "
        "phone on the same Wi-Fi; the editor's File > Play on Phone... window shows it as a QR code."
        FA_COMMAND_DETAILS
        "The server stops with the process or with {\"stop\":true}; it lives in the process that runs it: "
        "the editor, `factoria mcp` and `factoria session` keep it, a one-shot `factoria call` ends it when "
        "the call returns. Calling it again with the same project and `lan` returns the current status; with "
        "another `lan` it restarts the server (new port and token). In the editor the call never waits: it "
        "answers {running:false, state:\"starting\"} while the server starts and exports on a helper thread; "
        "call it again (same arguments) until state is \"ready\" (a start that failed is reported as an "
        "error by that call). Elsewhere (CLI, MCP, session) it waits for the first export. Limits: 8 "
        "connections answered at a time (32 waiting), requests bounded to 8 KB. Details: docs_read "
        "{\"name\":\"exporting\"}, section Web, and MOBILE.md.";
    info.inputSchema = Json::parse(R"({
      "type":"object",
      "additionalProperties":false,
      "properties":{
        "lan":{"type":"boolean","description":"Listen on every network interface so a phone or another computer on the same Wi-Fi or Ethernet can open the URL (lanUrl). Default false: only this computer (127.0.0.1) can connect. The first time, Windows and macOS ask whether this program may accept connections from the network: allow it for private networks. A guest Wi-Fi that isolates devices cannot reach this computer.","default":false},
        "stop":{"type":"boolean","description":"Stop the server and close its connections (instead of starting it). Cannot be combined with the other arguments. The server also stops when the process ends.","default":false},
        "player":{"type":"string","description":"The folder with factoria_player.js and factoria_player.wasm to serve instead of the installed web player, relative to the project folder or absolute (like project.export).","default":""},
        "allowPlayerMismatch":{"type":"boolean","description":"Serve a web player built from another commit than this factoria (like project.export).","default":false}
      }})");
    registry.add(info, [projectDir](const Json& args) {
        const bool stop = tooling_detail::arg_bool(args, "stop", false);
        if (stop) {
            // The registry fills in the schema defaults, so "given" means "different from the default".
            const char* given = tooling_detail::arg_bool(args, "lan", false)                  ? "lan"
                                : !tooling_detail::arg_string(args, "player", false).empty()  ? "player"
                                : tooling_detail::arg_bool(args, "allowPlayerMismatch", false) ? "allowPlayerMismatch"
                                                                                               : nullptr;
            if (given)
                throw CommandError("invalid_argument", std::string("/stop cannot be combined with /") + given + ": stopping takes no other argument.",
                                   std::string("call project.serve_web {\"stop\":true} alone, or remove \"stop\" to start the server"));
            WebServer& server = web_server();
            const bool was = server.running();
            if (!g_blocking.load()) return stop_without_waiting();
            server.stop();
            return Json::object({{"running", false}, {"stopped", was}});
        }
        ServeWebOptions o;
        o.projectDir = projectDir;
        o.lan = tooling_detail::arg_bool(args, "lan", false);
        o.allowPlayerMismatch = tooling_detail::arg_bool(args, "allowPlayerMismatch", false);
        if (std::string player = tooling_detail::arg_string(args, "player", false); !player.empty()) {
            const stdfs::path p(player);
            o.playerBinary = (p.is_absolute() ? p : stdfs::path(projectDir) / p).lexically_normal().generic_string();
        }
        WebServer& server = web_server();
        if (!g_blocking.load()) return serve_without_waiting(o, projectDir);
        const ServeWebStatus now = server.status();
        const bool same = serves_this(now, o, projectDir);
        if (!same) {
            if (auto r = server.start(o); !r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
        }
        const ServeWebStatus st = server.wait_ready(120000);  // a safety net: an export takes seconds; past it the state says "exporting"
        if (st.state == "failed" && st.version == 0) {
            server.stop();  // nothing worth serving: do not leave a listener behind
            throw CommandError("failed", st.error, st.hint);
        }
        if (st.state == "failed") throw CommandError("failed", st.error + " (the previous build is still served at " + st.localUrl + ")", st.hint);
        return st.to_json();
    });
}

}  // namespace fa
