// HTTP client: libcurl when built with FA_HAVE_CURL, otherwise the `curl`
// executable (spawned through the process runner). Proxies from the standard
// environment variables (HTTPS_PROXY, HTTP_PROXY, NO_PROXY) are honoured;
// loopback hosts (Ollama, LM Studio) always bypass the proxy.
#pragma once

#include <functional>
#include <map>
#include <string>
#include <string_view>
#include <vector>

#include "fa/ai/types.h"

namespace fa::ai {

struct HttpRequest {
    std::string method = "POST";
    std::string url;
    std::vector<std::pair<std::string, std::string>> headers;
    std::string body;
    double timeoutSeconds = 600;        // whole transfer
    double connectTimeoutSeconds = 30;
    const CancelFlag* cancel = nullptr;
    // Streaming: called with raw body chunks of a SUCCESSFUL (2xx) response as
    // they arrive; return false to abort. When set, the body is not buffered
    // (HttpResponse::body stays empty for 2xx). Error bodies are always buffered.
    std::function<bool(std::string_view chunk)> onData;
};

struct HttpResponse {
    int status = 0;          // 0 = transport failure (see `error`)
    std::map<std::string, std::string> headers;  // lowercase names
    std::string body;
    std::string error;       // transport error text ("Could not resolve host...")
    bool cancelled = false;
    bool ok() const { return status >= 200 && status < 300; }
    std::string header(std::string_view lowerName) const;
};

// Pluggable transport (tests inject fakes; providers take one).
using HttpTransport = std::function<HttpResponse(const HttpRequest&)>;

// Best available backend (libcurl, else curl executable).
HttpResponse http_request(const HttpRequest& request);
// Always the curl executable (used as fallback and in tests).
HttpResponse http_request_curl_exe(const HttpRequest& request);
// True when built with libcurl.
bool http_has_libcurl();

// Parses "Retry-After" (seconds or HTTP-date not supported -> 0) in seconds.
double parse_retry_after(std::string_view value);

}  // namespace fa::ai
