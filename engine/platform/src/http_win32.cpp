// Windows: WinHTTP (system certificate store, the user's proxy settings). Synchronous calls on one short-lived thread per
// request; the session handle is opened once and shared (WinHTTP handles are thread safe). Redirects are followed here,
// only to https:// (WinHTTP's own policy would follow http:// to http://), at most kHttpMaxRedirects. Run by the Windows
// doctest against the loopback test server.
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <winhttp.h>

#include <algorithm>
#include <cctype>
#include <chrono>
#include <future>
#include <memory>
#include <string>
#include <system_error>
#include <thread>

#include "fa/platform/http.h"

#ifndef WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT
#define WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT 7
#endif
#ifndef WINHTTP_OPTION_DECOMPRESSION
#define WINHTTP_OPTION_DECOMPRESSION 118
#endif
#ifndef WINHTTP_DECOMPRESSION_FLAG_ALL
#define WINHTTP_DECOMPRESSION_FLAG_ALL 0x00000003
#endif

namespace fa {

namespace {

std::wstring widen(const std::string& s) {
    if (s.empty()) return {};
    const int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), nullptr, 0);
    std::wstring out(static_cast<std::size_t>(std::max(n, 0)), L'\0');
    if (n > 0) MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), out.data(), n);
    return out;
}

std::string narrow(const std::wstring& s) {
    if (s.empty()) return {};
    const int n = WideCharToMultiByte(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), nullptr, 0, nullptr, nullptr);
    std::string out(static_cast<std::size_t>(std::max(n, 0)), '\0');
    if (n > 0) WideCharToMultiByte(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), out.data(), n, nullptr, nullptr);
    return out;
}

std::string lower(std::string s) {
    for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

HttpResponse failure(std::string error, std::string hint, bool timedOut = false) {
    HttpResponse r;
    r.error = std::move(error);
    r.hint = std::move(hint);
    r.timedOut = timedOut;
    return r;
}

struct Handle {
    HINTERNET h = nullptr;
    Handle() = default;
    explicit Handle(HINTERNET handle) : h(handle) {}
    Handle(const Handle&) = delete;
    Handle& operator=(const Handle&) = delete;
    ~Handle() {
        if (h) WinHttpCloseHandle(h);
    }
    explicit operator bool() const { return h != nullptr; }
};

HINTERNET session() {
    static HINTERNET s = [] {
        const std::wstring agent = widen(std::string("FactorIA/") + FA_ENGINE_VERSION);
        HINTERNET opened = WinHttpOpen(agent.c_str(), WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY, WINHTTP_NO_PROXY_NAME,
                                       WINHTTP_NO_PROXY_BYPASS, 0);
        if (!opened)  // Windows before 8.1 has no automatic proxy: the default proxy settings
            opened = WinHttpOpen(agent.c_str(), WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
        return opened;
    }();
    return s;
}

HttpResponse error_for(DWORD code, const std::string& host, double timeoutSec) {
    switch (code) {
        case ERROR_WINHTTP_TIMEOUT:
            return failure("the request to " + host + " timed out after " + std::to_string(int(timeoutSec)) + " s",
                           "Check the connection, or raise the timeout option of http.fetch.", true);
        case ERROR_WINHTTP_NAME_NOT_RESOLVED:
            return failure("could not find the server " + host, "Check the address, and that the player is online.");
        case ERROR_WINHTTP_CANNOT_CONNECT:
        case ERROR_WINHTTP_CONNECTION_ERROR:
            return failure("could not connect to " + host, "The server may be down, or the player offline.");
        case ERROR_WINHTTP_SECURE_FAILURE:
        case ERROR_WINHTTP_SECURE_CERT_DATE_INVALID:
        case ERROR_WINHTTP_SECURE_CERT_CN_INVALID:
        case ERROR_WINHTTP_SECURE_INVALID_CA:
        case ERROR_WINHTTP_SECURE_CERT_REV_FAILED:
        case ERROR_WINHTTP_SECURE_INVALID_CERT:
        case ERROR_WINHTTP_SECURE_CERT_REVOKED:
            return failure("the secure connection to " + host + " failed",
                           "The server's certificate is not trusted by this computer (an expired certificate, a wrong clock, or a proxy "
                           "that rewrites traffic).");
        case ERROR_WINHTTP_REDIRECT_FAILED:
            return failure("the request to " + host + " was redirected to a URL that cannot be followed",
                           "Redirects are only followed to https:// addresses, at most " + std::to_string(kHttpMaxRedirects) + " times.");
        default:
            break;
    }
    return failure("the request to " + host + " failed (Windows error " + std::to_string(code) + ")",
                   "Check the connection, and that the server is up.");
}

std::string host_of(const std::string& url) {
    const std::wstring wide = widen(url);
    URL_COMPONENTS parts{};
    parts.dwStructSize = sizeof(parts);
    parts.dwHostNameLength = static_cast<DWORD>(-1);
    if (!WinHttpCrackUrl(wide.c_str(), static_cast<DWORD>(wide.size()), 0, &parts)) return url;
    return narrow(std::wstring(parts.lpszHostName, parts.dwHostNameLength));
}

HttpResponse perform(const HttpRequest& req) {
    HINTERNET sess = session();
    if (!sess) return failure("WinHTTP could not start", "Restart the game; if it keeps failing, Windows' networking is not working.");

    const int timeoutMs = static_cast<int>(std::max(1.0, req.timeoutSec * 1000.0));
    const auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(timeoutMs);
    std::string url = req.url, method = req.method;
    bool sendBody = true;
    for (int hop = 0;; ++hop) {
        const std::wstring wideUrl = widen(url);
        URL_COMPONENTS parts{};
        parts.dwStructSize = sizeof(parts);
        parts.dwSchemeLength = parts.dwHostNameLength = parts.dwUrlPathLength = parts.dwExtraInfoLength = static_cast<DWORD>(-1);
        if (!WinHttpCrackUrl(wideUrl.c_str(), static_cast<DWORD>(wideUrl.size()), 0, &parts))
            return failure("the address is not a valid URL: " + url, "Write it as https://host/path.");
        if (parts.nScheme != INTERNET_SCHEME_HTTP && parts.nScheme != INTERNET_SCHEME_HTTPS)
            return failure("the address is not an http:// or https:// URL: " + url, "Write it as https://host/path.");
        const std::wstring wideHost(parts.lpszHostName, parts.dwHostNameLength);
        const std::string host = narrow(wideHost);
        const std::wstring path = std::wstring(parts.lpszUrlPath, parts.dwUrlPathLength) + std::wstring(parts.lpszExtraInfo, parts.dwExtraInfoLength);
        const bool secure = parts.nScheme == INTERNET_SCHEME_HTTPS;

        Handle connection(WinHttpConnect(sess, wideHost.c_str(), parts.nPort, 0));
        if (!connection) return error_for(GetLastError(), host, req.timeoutSec);
        Handle request(WinHttpOpenRequest(connection.h, widen(method).c_str(), path.empty() ? L"/" : path.c_str(), nullptr,
                                          WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES, secure ? WINHTTP_FLAG_SECURE : 0));
        if (!request) return error_for(GetLastError(), host, req.timeoutSec);

        WinHttpSetTimeouts(request.h, timeoutMs, timeoutMs, timeoutMs, timeoutMs);
        DWORD headersTimeout = static_cast<DWORD>(timeoutMs);  // the wait for the headers is not the receive timeout (90 s by default)
        WinHttpSetOption(request.h, WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT, &headersTimeout, sizeof(headersTimeout));
        // Redirects are followed below: WinHTTP's own policy would follow http:// to http://, and only https:// is allowed.
        DWORD policy = WINHTTP_OPTION_REDIRECT_POLICY_NEVER;
        WinHttpSetOption(request.h, WINHTTP_OPTION_REDIRECT_POLICY, &policy, sizeof(policy));
        DWORD disable = WINHTTP_DISABLE_COOKIES | WINHTTP_DISABLE_AUTHENTICATION;  // the request carries what the game put in its headers
        WinHttpSetOption(request.h, WINHTTP_OPTION_DISABLE_FEATURE, &disable, sizeof(disable));
        DWORD decompression = WINHTTP_DECOMPRESSION_FLAG_ALL;
        WinHttpSetOption(request.h, WINHTTP_OPTION_DECOMPRESSION, &decompression, sizeof(decompression));

        std::wstring headers;
        for (const auto& [name, value] : req.headers) headers += widen(name) + L": " + widen(value) + L"\r\n";
        const DWORD bodySize = sendBody ? static_cast<DWORD>(req.body.size()) : 0;
        if (!WinHttpSendRequest(request.h, headers.empty() ? WINHTTP_NO_ADDITIONAL_HEADERS : headers.c_str(),
                                headers.empty() ? 0 : static_cast<DWORD>(-1), bodySize ? const_cast<char*>(req.body.data()) : WINHTTP_NO_REQUEST_DATA,
                                bodySize, bodySize, 0))
            return error_for(GetLastError(), host, req.timeoutSec);
        if (!WinHttpReceiveResponse(request.h, nullptr)) return error_for(GetLastError(), host, req.timeoutSec);

        HttpResponse r;
        DWORD status = 0, size = sizeof(status);
        if (!WinHttpQueryHeaders(request.h, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER, WINHTTP_HEADER_NAME_BY_INDEX, &status, &size,
                                 WINHTTP_NO_HEADER_INDEX))
            return error_for(GetLastError(), host, req.timeoutSec);
        r.status = static_cast<int>(status);

        if (status == 301 || status == 302 || status == 303 || status == 307 || status == 308) {
            DWORD bytes = 0;
            WinHttpQueryHeaders(request.h, WINHTTP_QUERY_LOCATION, WINHTTP_HEADER_NAME_BY_INDEX, WINHTTP_NO_OUTPUT_BUFFER, &bytes, WINHTTP_NO_HEADER_INDEX);
            std::wstring location(bytes / sizeof(wchar_t), L'\0');
            if (bytes > 0 && WinHttpQueryHeaders(request.h, WINHTTP_QUERY_LOCATION, WINHTTP_HEADER_NAME_BY_INDEX, location.data(), &bytes,
                                                 WINHTTP_NO_HEADER_INDEX)) {
                std::string next = narrow(location.c_str());
                if (next.rfind("/", 0) == 0 && next.rfind("//", 0) != 0 && secure)  // a path on the same https:// server
                    next = "https://" + host + ":" + std::to_string(parts.nPort) + next;
                if (lower(next).rfind("https://", 0) != 0)
                    return failure("the request to " + host + " was redirected to a URL that is not https://: " + next,
                                   "Redirects are only followed to https:// addresses.");
                if (hop >= kHttpMaxRedirects)
                    return failure("the request to " + host + " was redirected more than " + std::to_string(kHttpMaxRedirects) + " times",
                                   "The server sends the request around in a loop; check the address.");
                if (status == 303 || ((status == 301 || status == 302) && method == "POST")) method = "GET", sendBody = false;
                url = next;
                continue;
            }
        }

        DWORD rawBytes = 0;
        WinHttpQueryHeaders(request.h, WINHTTP_QUERY_RAW_HEADERS_CRLF, WINHTTP_HEADER_NAME_BY_INDEX, WINHTTP_NO_OUTPUT_BUFFER, &rawBytes,
                            WINHTTP_NO_HEADER_INDEX);
        if (rawBytes > 0) {
            std::wstring raw(rawBytes / sizeof(wchar_t), L'\0');
            if (WinHttpQueryHeaders(request.h, WINHTTP_QUERY_RAW_HEADERS_CRLF, WINHTTP_HEADER_NAME_BY_INDEX, raw.data(), &rawBytes,
                                    WINHTTP_NO_HEADER_INDEX)) {
                const std::string text = narrow(raw.c_str());
                std::size_t pos = 0;
                while (pos < text.size()) {
                    std::size_t end = text.find("\r\n", pos);
                    if (end == std::string::npos) end = text.size();
                    const std::string line = text.substr(pos, end - pos);
                    pos = end + 2;
                    const std::size_t colon = line.find(':');
                    if (colon == std::string::npos || colon == 0 || line.rfind("HTTP/", 0) == 0) continue;
                    std::string value = line.substr(colon + 1);
                    while (!value.empty() && (value.front() == ' ' || value.front() == '\t')) value.erase(value.begin());
                    r.headers.emplace_back(lower(line.substr(0, colon)), std::move(value));
                }
            }
        }

        for (;;) {
            DWORD available = 0;
            if (!WinHttpQueryDataAvailable(request.h, &available)) return error_for(GetLastError(), host, req.timeoutSec);
            if (available == 0) break;
            if (r.body.size() + available > req.maxResponseBytes)
                return failure("the response from " + host + " is longer than " + std::to_string(req.maxResponseBytes / 1024) + " KB",
                               "http.fetch is for small texts (JSON, configuration); ask the server for less data.");
            if (std::chrono::steady_clock::now() > deadline) return error_for(ERROR_WINHTTP_TIMEOUT, host, req.timeoutSec);
            const std::size_t at = r.body.size();
            r.body.resize(at + available);
            DWORD got = 0;
            if (!WinHttpReadData(request.h, r.body.data() + at, available, &got)) return error_for(GetLastError(), host, req.timeoutSec);
            r.body.resize(at + got);
            if (got == 0) break;
        }
        r.ok = true;
        return r;
    }
}

class WinHttpClient final : public HttpClient {
public:
    std::string name() const override { return "winhttp"; }
    bool available() const override { return session() != nullptr; }
    std::string unavailable_reason() const override { return session() ? std::string() : "WinHTTP could not start"; }
    void send(HttpRequest request, HttpDone done) override {
        try {
            // A synchronous WinHttpSendRequest waits for the server's answer and no WinHTTP timeout bounds that wait, so the
            // timeout is kept here: past it the caller gets the timed-out answer and the late one is dropped.
            std::thread([request = std::move(request), done = std::move(done)]() mutable {
                auto answer = std::make_shared<std::promise<HttpResponse>>();
                std::future<HttpResponse> answered = answer->get_future();
                std::thread([answer, request] { answer->set_value(perform(request)); }).detach();
                const auto timeout = std::chrono::milliseconds(static_cast<long long>(std::max(1.0, request.timeoutSec * 1000.0)));
                if (answered.wait_for(timeout) == std::future_status::ready) done(answered.get());
                else done(error_for(ERROR_WINHTTP_TIMEOUT, host_of(request.url), request.timeoutSec));
            }).detach();
        } catch (const std::system_error& e) {
            done(failure(std::string("could not start a request thread: ") + e.what(), "Too many requests are running at once."));
        }
    }
};

}  // namespace

std::unique_ptr<HttpClient> make_system_http_client() { return std::make_unique<WinHttpClient>(); }

}  // namespace fa
