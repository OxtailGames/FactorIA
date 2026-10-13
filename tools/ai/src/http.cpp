#include "fa/ai/http.h"

#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <random>

#ifdef FA_HAVE_CURL
#include <curl/curl.h>
#endif

#include "fa/ai/process.h"
#include "fa/core/strings.h"

namespace fa::ai {

std::string HttpResponse::header(std::string_view lowerName) const {
    auto it = headers.find(std::string(lowerName));
    return it == headers.end() ? std::string() : it->second;
}

double parse_retry_after(std::string_view v) {
    v = fa::trim(v);
    if (v.empty()) return 0;
    char* end = nullptr;
    std::string s(v);
    double d = std::strtod(s.c_str(), &end);
    if (end == s.c_str() || d < 0) return 0;
    return d;
}

bool http_has_libcurl() {
#ifdef FA_HAVE_CURL
    return true;
#else
    return false;
#endif
}

namespace {

std::string lower_copy(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return s;
}

void add_header_line(HttpResponse& r, std::string_view line) {
    auto colon = line.find(':');
    if (colon == std::string_view::npos) return;
    std::string name = lower_copy(std::string(fa::trim(line.substr(0, colon))));
    std::string value(fa::trim(line.substr(colon + 1)));
    if (!name.empty()) r.headers[name] = value;
}

#ifdef FA_HAVE_CURL

struct CurlState {
    const HttpRequest* req = nullptr;
    HttpResponse* resp = nullptr;
    CURL* curl = nullptr;
    bool aborted = false;
};

size_t write_cb(char* ptr, size_t size, size_t nmemb, void* user) {
    auto* st = static_cast<CurlState*>(user);
    size_t n = size * nmemb;
    long code = 0;
    curl_easy_getinfo(st->curl, CURLINFO_RESPONSE_CODE, &code);
    if (st->req->onData && code >= 200 && code < 300) {
        if (!st->req->onData(std::string_view(ptr, n))) {
            st->aborted = true;
            return 0;
        }
    } else {
        st->resp->body.append(ptr, n);
    }
    return n;
}

size_t header_cb(char* ptr, size_t size, size_t nmemb, void* user) {
    auto* st = static_cast<CurlState*>(user);
    size_t n = size * nmemb;
    std::string_view line(ptr, n);
    if (line.rfind("HTTP/", 0) == 0) st->resp->headers.clear();  // new response (redirect / 100-continue)
    else add_header_line(*st->resp, line);
    return n;
}

int progress_cb(void* user, curl_off_t, curl_off_t, curl_off_t, curl_off_t) {
    auto* st = static_cast<CurlState*>(user);
    return is_cancelled(st->req->cancel) ? 1 : 0;
}

void curl_global_once() {
    static std::once_flag once;
    std::call_once(once, [] { curl_global_init(CURL_GLOBAL_DEFAULT); });
}

HttpResponse curl_request(const HttpRequest& req) {
    curl_global_once();
    HttpResponse resp;
    CURL* curl = curl_easy_init();
    if (!curl) {
        resp.error = "curl_easy_init failed";
        return resp;
    }
    CurlState st{&req, &resp, curl, false};
    curl_slist* headers = nullptr;
    for (const auto& [k, v] : req.headers) headers = curl_slist_append(headers, (k + ": " + v).c_str());
    headers = curl_slist_append(headers, "Expect:");  // no 100-continue round trip

    curl_easy_setopt(curl, CURLOPT_URL, req.url.c_str());
    if (req.method == "GET") {
        curl_easy_setopt(curl, CURLOPT_HTTPGET, 1L);
    } else {
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, req.method.c_str());
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, req.body.data());
        curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE_LARGE, static_cast<curl_off_t>(req.body.size()));
    }
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &st);
    curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, header_cb);
    curl_easy_setopt(curl, CURLOPT_HEADERDATA, &st);
    curl_easy_setopt(curl, CURLOPT_XFERINFOFUNCTION, progress_cb);
    curl_easy_setopt(curl, CURLOPT_XFERINFODATA, &st);
    curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);
    curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_MAXREDIRS, 5L);
    curl_easy_setopt(curl, CURLOPT_USERAGENT, "factoria-ai/0.1");
    curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT_MS, static_cast<long>(req.connectTimeoutSeconds * 1000));
    if (req.timeoutSeconds > 0) curl_easy_setopt(curl, CURLOPT_TIMEOUT_MS, static_cast<long>(req.timeoutSeconds * 1000));
    // Loopback never goes through a proxy; keep the user's NO_PROXY entries too.
    {
        std::string np = "localhost,127.0.0.1,::1";
        if (const char* e = std::getenv("NO_PROXY")) np += std::string(",") + e;
        else if (const char* e2 = std::getenv("no_proxy")) np += std::string(",") + e2;
        curl_easy_setopt(curl, CURLOPT_NOPROXY, np.c_str());
    }
    // HTTPS_PROXY etc. are read by libcurl itself.

    char errbuf[CURL_ERROR_SIZE] = {0};
    curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, errbuf);
    CURLcode rc = curl_easy_perform(curl);
    long code = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &code);
    resp.status = static_cast<int>(code);
    if (rc != CURLE_OK) {
        if (is_cancelled(req.cancel)) {
            resp.cancelled = true;
            resp.error = "cancelled";
        } else if (st.aborted) {
            resp.error = "aborted by caller";
        } else {
            resp.error = errbuf[0] ? errbuf : curl_easy_strerror(rc);
            if (rc == CURLE_OPERATION_TIMEDOUT) resp.error = "timed out: " + resp.error;
            if (resp.status < 200 || resp.status >= 300) resp.status = resp.status ? resp.status : 0;
        }
    }
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    return resp;
}

#endif  // FA_HAVE_CURL

}  // namespace

HttpResponse http_request_curl_exe(const HttpRequest& req) {
    namespace fsys = std::filesystem;
    HttpResponse resp;
    if (which("curl").empty()) {
        resp.error = "The 'curl' executable was not found in PATH (and FactorIA was built without libcurl). "
                     "Install curl.";
        return resp;
    }
    // Headers (which carry API keys) and body go through 0600 temp files, never argv.
    std::error_code ec;
    static std::atomic<unsigned> counter{0};
    std::random_device rd;
    fsys::path dir = fsys::temp_directory_path(ec) / ("factoria-curl-" + std::to_string(rd()) + "-" + std::to_string(counter++));
    fsys::create_directories(dir, ec);
    fsys::path cfg = dir / "curl.cfg", bodyFile = dir / "body.json";
    auto cleanup = [&] { fsys::remove_all(dir, ec); };
    auto quote = [](const std::string& s) {
        std::string o = "\"";
        for (char c : s) {
            if (c == '\\' || c == '"') o.push_back('\\');
            if (c == '\n') { o += "\\n"; continue; }
            if (c == '\r') { o += "\\r"; continue; }
            o.push_back(c);
        }
        return o + "\"";
    };
    {
        std::ofstream f(cfg, std::ios::binary);
        f << "url = " << quote(req.url) << "\n";
        for (const auto& [k, v] : req.headers) f << "header = " << quote(k + ": " + v) << "\n";
        f << "header = \"Expect:\"\n";
        f << "request = " << quote(req.method) << "\n";
        f << "user-agent = \"factoria-ai/0.1\"\n";
        if (!f) { resp.error = "cannot write temp curl config"; cleanup(); return resp; }
    }
    fsys::permissions(cfg, fsys::perms::owner_read | fsys::perms::owner_write, ec);
    if (req.method != "GET") {
        std::ofstream f(bodyFile, std::ios::binary);
        f.write(req.body.data(), static_cast<std::streamsize>(req.body.size()));
    }
    ProcessOptions po;
    po.argv = {"curl", "--silent", "--show-error", "--no-buffer", "--include", "--config", cfg.string(),
               "--connect-timeout", std::to_string(static_cast<int>(req.connectTimeoutSeconds)),
               "--max-redirs", "5"};
    if (req.timeoutSeconds > 0) { po.argv.push_back("--max-time"); po.argv.push_back(std::to_string(static_cast<int>(req.timeoutSeconds))); }
    {
        std::string np = "localhost,127.0.0.1,::1";
        if (const char* e = std::getenv("NO_PROXY")) np += std::string(",") + e;
        po.argv.push_back("--noproxy");
        po.argv.push_back(np);
    }
    if (req.method != "GET") { po.argv.push_back("--data-binary"); po.argv.push_back("@" + bodyFile.string()); }
    po.cancel = req.cancel;
    po.captureStdout = false;

    // Parse "--include" output: header block(s), blank line, body. A 1xx/proxy
    // CONNECT block can precede the final one, so reset on each new status line.
    enum class Phase { Headers, Body } phase = Phase::Headers;
    std::string pending;
    bool aborted = false, proxyBlock = false;
    po.onStdoutChunk = [&](std::string_view chunk) {
        if (aborted) return;
        auto deliver = [&](std::string_view data) {
            if (data.empty()) return;
            if (req.onData && resp.status >= 200 && resp.status < 300) {
                if (!req.onData(data)) aborted = true;
            } else {
                resp.body.append(data);
            }
        };
        if (phase == Phase::Body) { deliver(chunk); return; }
        pending.append(chunk);
        for (;;) {
            auto nl = pending.find('\n');
            if (nl == std::string::npos) return;
            std::string line = pending.substr(0, nl);
            pending.erase(0, nl + 1);
            if (!line.empty() && line.back() == '\r') line.pop_back();
            if (line.rfind("HTTP/", 0) == 0) {
                resp.headers.clear();
                proxyBlock = line.find("Connection established") != std::string::npos;
                auto sp = line.find(' ');
                resp.status = sp == std::string::npos ? 0 : std::atoi(line.c_str() + sp + 1);
            } else if (line.empty()) {
                if (resp.status >= 100 && resp.status < 200) continue;  // 100-continue: next block follows
                if (proxyBlock) { proxyBlock = false; continue; }       // proxy CONNECT reply: real response follows
                phase = Phase::Body;
                std::string rest = std::move(pending);
                pending.clear();
                deliver(rest);
                return;
            } else {
                add_header_line(resp, line);
            }
        }
    };
    std::string errText;
    po.onStderrLine = [&](std::string_view l) { errText += std::string(l) + "\n"; };
    auto run = run_process(po);
    cleanup();
    if (!run) { resp.error = run.error().message; return resp; }
    if (run->cancelled) { resp.cancelled = true; resp.error = "cancelled"; return resp; }
    if (aborted) { resp.error = "aborted by caller"; return resp; }
    if (run->exitCode != 0 && resp.status == 0) {
        resp.error = std::string(fa::trim(errText));
        if (resp.error.empty()) resp.error = "curl exited with code " + std::to_string(run->exitCode);
    }
    return resp;
}

HttpResponse http_request(const HttpRequest& request) {
#ifdef FA_HAVE_CURL
    return curl_request(request);
#else
    return http_request_curl_exe(request);
#endif
}

}  // namespace fa::ai
