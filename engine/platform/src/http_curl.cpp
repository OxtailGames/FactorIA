// libcurl loaded at run time (fa/platform/http.h). Nothing is linked: the Linux player and the Steam Runtime keep working on a
// machine without libcurl, where the client reports itself unavailable. The few pieces of curl.h used here are declared below
// (the option numbers and the C ABI are stable since 7.x). Each request runs on its own short-lived thread with its own easy
// handle; the library is initialised once.
//
// Compiled on every POSIX platform; Linux uses it, macOS exercises it in the tests (its own client is NSURLSession).
#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)

#include <dlfcn.h>

#include <algorithm>
#include <cctype>
#include <cstring>
#include <mutex>
#include <system_error>
#include <thread>

#include "fa/platform/http.h"

namespace fa {

namespace {

using CURL = void;
struct curl_slist;
using CURLcode = int;

// The CURLOPT_ numbers: type base (LONG 0, OBJECTPOINT 10000, FUNCTIONPOINT 20000, OFF_T 30000) plus the option's number.
constexpr int kOptWriteData = 10001, kOptUrl = 10002, kOptErrorBuffer = 10010, kOptPostFields = 10015, kOptUserAgent = 10018,
              kOptHttpHeader = 10023, kOptHeaderData = 10029, kOptCustomRequest = 10036, kOptWriteFunction = 20011,
              kOptHeaderFunction = 20079, kOptNoBody = 44, kOptPost = 47, kOptFollowLocation = 52, kOptPostFieldSize = 60,
              kOptMaxRedirs = 68, kOptNoSignal = 99, kOptTimeoutMs = 155, kOptConnectTimeoutMs = 156, kOptAcceptEncoding = 10102,
              kOptProtocols = 181, kOptRedirProtocols = 182, kOptProtocolsStr = 10318, kOptRedirProtocolsStr = 10319;
constexpr int kInfoResponseCode = 0x200000 + 2;
constexpr int kCurlOk = 0, kCurlUnsupportedProtocol = 1, kCurlCouldntResolveHost = 6, kCurlCouldntConnect = 7,
              kCurlTimedOut = 28, kCurlSslConnectError = 35, kCurlTooManyRedirects = 47, kCurlUnknownOption = 48,
              kCurlSslPeerCertificate = 51, kCurlSslCertProblem = 58, kCurlSslCipher = 59, kCurlPeerFailedVerification = 60,
              kCurlSslCacertBadfile = 77, kCurlSslIssuerError = 83;
constexpr long kProtoHttp = 1, kProtoHttps = 2;

struct Curl {
    void* lib = nullptr;
    int (*global_init)(long) = nullptr;
    CURL* (*easy_init)() = nullptr;
    void (*easy_cleanup)(CURL*) = nullptr;
    CURLcode (*easy_setopt)(CURL*, int, ...) = nullptr;
    CURLcode (*easy_perform)(CURL*) = nullptr;
    CURLcode (*easy_getinfo)(CURL*, int, ...) = nullptr;
    const char* (*easy_strerror)(CURLcode) = nullptr;
    curl_slist* (*slist_append)(curl_slist*, const char*) = nullptr;
    void (*slist_free_all)(curl_slist*) = nullptr;
    std::string reason;  // why there is no library
    bool ok() const { return lib != nullptr; }
};

const Curl& curl() {
    static const Curl c = [] {
        Curl k;
        const char* names[] = {
#if defined(__APPLE__)
            "libcurl.4.dylib", "libcurl.dylib",
#else
            "libcurl.so.4", "libcurl-gnutls.so.4", "libcurl-nss.so.4", "libcurl.so",
#endif
        };
        for (const char* name : names)
            if ((k.lib = dlopen(name, RTLD_NOW | RTLD_LOCAL))) break;
        if (!k.lib) {
            k.reason = "libcurl is not installed on this computer";
            return k;
        }
        auto sym = [&](const char* name) { return dlsym(k.lib, name); };
        k.global_init = reinterpret_cast<int (*)(long)>(sym("curl_global_init"));
        k.easy_init = reinterpret_cast<CURL* (*)()>(sym("curl_easy_init"));
        k.easy_cleanup = reinterpret_cast<void (*)(CURL*)>(sym("curl_easy_cleanup"));
        k.easy_setopt = reinterpret_cast<CURLcode (*)(CURL*, int, ...)>(sym("curl_easy_setopt"));
        k.easy_perform = reinterpret_cast<CURLcode (*)(CURL*)>(sym("curl_easy_perform"));
        k.easy_getinfo = reinterpret_cast<CURLcode (*)(CURL*, int, ...)>(sym("curl_easy_getinfo"));
        k.easy_strerror = reinterpret_cast<const char* (*)(CURLcode)>(sym("curl_easy_strerror"));
        k.slist_append = reinterpret_cast<curl_slist* (*)(curl_slist*, const char*)>(sym("curl_slist_append"));
        k.slist_free_all = reinterpret_cast<void (*)(curl_slist*)>(sym("curl_slist_free_all"));
        if (!k.global_init || !k.easy_init || !k.easy_cleanup || !k.easy_setopt || !k.easy_perform || !k.easy_getinfo || !k.easy_strerror ||
            !k.slist_append || !k.slist_free_all) {
            dlclose(k.lib);
            k = Curl{};
            k.reason = "the libcurl on this computer lacks functions the engine needs";
            return k;
        }
        k.global_init(3);  // CURL_GLOBAL_DEFAULT: once, before any thread uses curl
        return k;
    }();
    return c;
}

struct Transfer {
    std::string body;
    std::size_t maxBytes = 0;
    bool tooLarge = false;
    std::vector<std::pair<std::string, std::string>> headers;
};

std::string lower(std::string s) {
    for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

std::string trim(std::string_view s) {
    while (!s.empty() && (s.front() == ' ' || s.front() == '\t')) s.remove_prefix(1);
    while (!s.empty() && (s.back() == ' ' || s.back() == '\t' || s.back() == '\r' || s.back() == '\n')) s.remove_suffix(1);
    return std::string(s);
}

extern "C" std::size_t fa_curl_write(char* data, std::size_t size, std::size_t count, void* user) {
    auto* t = static_cast<Transfer*>(user);
    const std::size_t n = size * count;
    if (t->body.size() + n > t->maxBytes) {
        t->tooLarge = true;
        return 0;  // curl stops with CURLE_WRITE_ERROR
    }
    t->body.append(data, n);
    return n;
}

extern "C" std::size_t fa_curl_header(char* data, std::size_t size, std::size_t count, void* user) {
    auto* t = static_cast<Transfer*>(user);
    const std::size_t n = size * count;
    const std::string_view line(data, n);
    if (line.rfind("HTTP/", 0) == 0) {  // a new response (a redirect's, then the final one): its headers replace the earlier ones
        t->headers.clear();
        return n;
    }
    const std::size_t colon = line.find(':');
    if (colon == std::string_view::npos || colon == 0) return n;  // the blank line that ends the headers
    t->headers.emplace_back(lower(trim(line.substr(0, colon))), trim(line.substr(colon + 1)));
    return n;
}

HttpResponse failure(std::string error, std::string hint, bool timedOut = false) {
    HttpResponse r;
    r.error = std::move(error);
    r.hint = std::move(hint);
    r.timedOut = timedOut;
    return r;
}

std::string host_of(const std::string& url) {
    std::size_t start = url.find("://");
    start = start == std::string::npos ? 0 : start + 3;
    std::size_t end = url.find_first_of("/?#", start);
    std::string authority = url.substr(start, end == std::string::npos ? std::string::npos : end - start);
    if (!authority.empty() && authority[0] == '[') {
        const std::size_t close = authority.find(']');
        return authority.substr(1, close == std::string::npos ? std::string::npos : close - 1);
    }
    const std::size_t colon = authority.rfind(':');
    return colon == std::string::npos ? authority : authority.substr(0, colon);
}

HttpResponse perform(const Curl& c, const HttpRequest& req) {
    CURL* h = c.easy_init();
    if (!h) return failure("libcurl could not start a request", "Try again; if it keeps failing, restart the game.");
    Transfer transfer;
    transfer.maxBytes = req.maxResponseBytes;
    char errbuf[256] = {0};
    curl_slist* headerList = nullptr;
    for (const auto& [name, value] : req.headers) headerList = c.slist_append(headerList, (name + ": " + value).c_str());
    headerList = c.slist_append(headerList, "Expect:");  // no 100-continue round trip for bodies over 1 MB

    const long timeoutMs = static_cast<long>(std::max(1.0, req.timeoutSec * 1000.0));
    c.easy_setopt(h, kOptUrl, req.url.c_str());
    c.easy_setopt(h, kOptErrorBuffer, errbuf);
    c.easy_setopt(h, kOptNoSignal, 1L);  // never SIGALRM from a worker thread
    c.easy_setopt(h, kOptTimeoutMs, timeoutMs);
    c.easy_setopt(h, kOptConnectTimeoutMs, timeoutMs);
    c.easy_setopt(h, kOptFollowLocation, 1L);
    c.easy_setopt(h, kOptMaxRedirs, static_cast<long>(kHttpMaxRedirects));
    // Only http(s) at all, and redirects only to https://; the first request is whatever the game's URL says (http:// only for loopback: checked by the caller).
    if (c.easy_setopt(h, kOptProtocolsStr, "http,https") == kCurlUnknownOption) c.easy_setopt(h, kOptProtocols, kProtoHttp | kProtoHttps);
    if (c.easy_setopt(h, kOptRedirProtocolsStr, "https") == kCurlUnknownOption) c.easy_setopt(h, kOptRedirProtocols, kProtoHttps);
    c.easy_setopt(h, kOptAcceptEncoding, "");  // every encoding libcurl can undo
    c.easy_setopt(h, kOptUserAgent, "FactorIA/" FA_ENGINE_VERSION);
    c.easy_setopt(h, kOptHttpHeader, headerList);
    c.easy_setopt(h, kOptWriteFunction, &fa_curl_write);
    c.easy_setopt(h, kOptWriteData, &transfer);
    c.easy_setopt(h, kOptHeaderFunction, &fa_curl_header);
    c.easy_setopt(h, kOptHeaderData, &transfer);
    if (req.method == "HEAD") {
        c.easy_setopt(h, kOptNoBody, 1L);
    } else if (req.method == "POST") {
        c.easy_setopt(h, kOptPost, 1L);
        c.easy_setopt(h, kOptPostFieldSize, static_cast<long>(req.body.size()));
        c.easy_setopt(h, kOptPostFields, req.body.c_str());
    } else if (req.method != "GET") {
        c.easy_setopt(h, kOptCustomRequest, req.method.c_str());
        if (!req.body.empty()) {
            c.easy_setopt(h, kOptPostFieldSize, static_cast<long>(req.body.size()));
            c.easy_setopt(h, kOptPostFields, req.body.c_str());
        }
    }

    const CURLcode code = c.easy_perform(h);
    long status = 0;
    if (code == kCurlOk) c.easy_getinfo(h, kInfoResponseCode, &status);
    const std::string detail = errbuf[0] ? std::string(errbuf) : std::string(c.easy_strerror(code));
    c.easy_cleanup(h);
    c.slist_free_all(headerList);

    if (code == kCurlOk) {
        HttpResponse r;
        r.ok = true;
        r.status = static_cast<int>(status);
        r.headers = std::move(transfer.headers);
        r.body = std::move(transfer.body);
        return r;
    }
    const std::string host = host_of(req.url);
    if (transfer.tooLarge)
        return failure("the response from " + host + " is longer than " + std::to_string(req.maxResponseBytes / 1024) + " KB",
                       "http.fetch is for small texts (JSON, configuration); ask the server for less data.");
    switch (code) {
        case kCurlTimedOut:
            return failure("the request to " + host + " timed out after " + std::to_string(int(req.timeoutSec)) + " s",
                           "Check the connection, or raise the timeout option of http.fetch.", true);
        case kCurlCouldntResolveHost:
            return failure("could not find the server " + host, "Check the address, and that the player is online.");
        case kCurlCouldntConnect:
            return failure("could not connect to " + host, "The server may be down, or the player offline.");
        case kCurlSslConnectError:
        case kCurlSslPeerCertificate:
        case kCurlSslCertProblem:
        case kCurlSslCipher:
        case kCurlPeerFailedVerification:
        case kCurlSslCacertBadfile:
        case kCurlSslIssuerError:
            return failure("the secure connection to " + host + " failed: " + detail,
                           "The server's certificate is not trusted by this computer (an expired certificate, a wrong clock, or a proxy "
                           "that rewrites traffic).");
        case kCurlTooManyRedirects:
            return failure("the request to " + host + " was redirected more than " + std::to_string(kHttpMaxRedirects) + " times", "");
        case kCurlUnsupportedProtocol:
            return failure("the request to " + host + " was redirected to a URL that is not https://: " + detail,
                           "Redirects are only followed to https:// addresses.");
        default:
            break;
    }
    return failure("the request to " + host + " failed: " + detail, "Check the connection, and that the server is up.");
}

class CurlClient final : public HttpClient {
public:
    std::string name() const override { return "curl"; }
    bool available() const override { return curl().ok(); }
    std::string unavailable_reason() const override {
        return curl().ok() ? std::string() : curl().reason + " (install libcurl, e.g. `sudo apt install libcurl4`)";
    }
    void send(HttpRequest request, HttpDone done) override {
        if (!curl().ok()) {
            done(failure("http.fetch is not available: " + unavailable_reason(), "Games that use the network should handle this and carry on offline."));
            return;
        }
        // One thread per request, detached: it holds only copies, so it outlives the client and the engine safely.
        try {
            std::thread([request = std::move(request), done = std::move(done)]() mutable { done(perform(curl(), request)); }).detach();
        } catch (const std::system_error& e) {
            done(failure(std::string("could not start a request thread: ") + e.what(), "Too many requests are running at once."));
        }
    }
};

}  // namespace

std::unique_ptr<HttpClient> make_curl_http_client() { return std::make_unique<CurlClient>(); }

}  // namespace fa

#endif
