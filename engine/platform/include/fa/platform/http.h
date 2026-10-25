// HTTP requests of a running game (`http.fetch` in scripts, docs/NETWORKING.md): one client per platform, each wrapping what
// the system already has, so that the player carries no network library of its own.
//
//   Windows    WinHTTP (system certificates, system proxy).
//   macOS/iOS  NSURLSession (App Transport Security: HTTPS only unless the app says otherwise).
//   Linux      libcurl, loaded with dlopen (libcurl.so.4 and friends): missing = not available, and nothing is linked, so the
//              Steam Runtime "sniper" build and machines without it keep working.
//   Android    java.net.HttpURLConnection through JNI (the manifest needs the INTERNET permission: the export adds it when
//              factoria.json declares network hosts).
//   web        the browser's fetch (CORS applies: the server must allow the game's page).
//
// A client only sends: it checks nothing about WHICH URL a game may call. That is the job of fa/services/network.h (the
// hosts the game declares in factoria.json) and of PlatformServices (fa/services/platform.h), which hands each request
// here after checking it. Tests and headless runs never reach a client: they get the fake backend.
#pragma once

#include <cstddef>
#include <functional>
#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace fa {

struct HttpRequest {
    std::string method = "GET";  // GET, HEAD, POST, PUT, PATCH or DELETE (upper case)
    std::string url;             // absolute http:// or https:// URL
    std::vector<std::pair<std::string, std::string>> headers;
    std::string body;            // sent as is; empty = no body
    double timeoutSec = 15.0;    // the whole request, connecting included
    // A response longer than this is an error, not a truncated answer.
    std::size_t maxResponseBytes = 4 * 1024 * 1024;
};

struct HttpResponse {
    // false: the request did not complete (no connection, a timeout, a certificate the system does not trust, a too long
    // answer): `error` says why. An HTTP error status (404, 500) is a completed request: ok is true and `status` is it.
    bool ok = false;
    int status = 0;
    // Header names in lower case, in the order they came; the last response of a redirect chain.
    std::vector<std::pair<std::string, std::string>> headers;
    std::string body;
    // When !ok:
    std::string error;       // what went wrong, in a sentence ("could not connect to api.example.com")
    std::string hint;        // how to fix it or what to try
    bool timedOut = false;
};

using HttpDone = std::function<void(HttpResponse)>;

// One platform's HTTP stack. send() may be called from the game thread only; `done` may run on ANY thread (and before send
// returns), exactly once per request.
class HttpClient {
public:
    virtual ~HttpClient() = default;
    virtual std::string name() const = 0;  // "winhttp", "nsurlsession", "curl", "httpurlconnection" or "fetch"
    // False when this machine cannot send requests (Linux without libcurl): send() then answers every request with an error.
    virtual bool available() const = 0;
    virtual std::string unavailable_reason() const { return {}; }
    virtual void send(HttpRequest request, HttpDone done) = 0;
};

// The client of this platform; never null: where the system has no HTTP stack its available() is false.
std::unique_ptr<HttpClient> make_system_http_client();

#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)
// libcurl loaded with dlopen (Linux's client; macOS has it too, which lets the tests exercise this code there). Never null.
std::unique_ptr<HttpClient> make_curl_http_client();
#endif

// Redirects: every client follows at most this many, and only to https:// (an https page never sends the player to plain http).
inline constexpr int kHttpMaxRedirects = 5;

}  // namespace fa
