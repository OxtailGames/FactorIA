// The "http" backend: serves http.fetch with an HttpClient (fa/platform/http.h), the system's HTTP stack of this platform.
// PlatformServices has already checked the request against factoria.json "network" and shaped its arguments; this class
// sends them and turns the response into the answer scripts get: {status, headers, text}.
#include <atomic>
#include <memory>

#include "fa/platform/http.h"
#include "fa/runtime/platform_backend.h"

namespace fa {

namespace {

// At most this many requests in flight: a script that loops over fetch cannot open hundreds of connections.
constexpr int kMaxInFlight = 8;

// `s` as valid UTF-8: every invalid byte becomes U+FFFD (a JSON string must be UTF-8, a server's text need not be).
std::string valid_utf8(const std::string& s) {
    std::string out;
    out.reserve(s.size());
    std::size_t i = 0;
    while (i < s.size()) {
        const unsigned char c = static_cast<unsigned char>(s[i]);
        std::size_t length = 0;
        char32_t cp = 0;
        if (c < 0x80) {
            length = 1;
            cp = c;
        } else if (c >= 0xC2 && c <= 0xDF) {
            length = 2;
            cp = c & 0x1F;
        } else if (c >= 0xE0 && c <= 0xEF) {
            length = 3;
            cp = c & 0x0F;
        } else if (c >= 0xF0 && c <= 0xF4) {
            length = 4;
            cp = c & 0x07;
        }
        bool ok = length != 0 && i + length <= s.size();
        for (std::size_t k = 1; ok && k < length; ++k) {
            const unsigned char cc = static_cast<unsigned char>(s[i + k]);
            if ((cc & 0xC0) != 0x80) ok = false;
            else cp = (cp << 6) | (cc & 0x3F);
        }
        if (ok && ((length == 3 && (cp < 0x800 || (cp >= 0xD800 && cp <= 0xDFFF))) || (length == 4 && (cp < 0x10000 || cp > 0x10FFFF)))) ok = false;
        if (ok) {
            out.append(s, i, length);
            i += length;
        } else {
            out += "\xEF\xBF\xBD";
            ++i;
        }
    }
    return out;
}

class HttpBackend final : public PlatformBackend {
public:
    explicit HttpBackend(std::unique_ptr<HttpClient> client) : client_(std::move(client)), inFlight_(std::make_shared<std::atomic<int>>(0)) {}

    std::string name() const override { return client_->name(); }
    std::vector<std::string> services() const override {
        return client_->available() ? std::vector<std::string>{"http"} : std::vector<std::string>{};
    }

    void request(std::uint64_t id, const std::string& method, const Json& args, const PlatformSink& sink) override {
        if (method != "http.fetch") {
            sink.fail(id, {"unavailable", "the http backend answers http.fetch only, not " + method, {}});
            return;
        }
        if (!client_->available()) {
            sink.fail(id, {"unavailable", "http.fetch is not available: " + client_->unavailable_reason(), "Let the game carry on offline."});
            return;
        }
        if (inFlight_->load() >= kMaxInFlight) {
            sink.fail(id, {"failed", "http.fetch has " + std::to_string(kMaxInFlight) + " requests in flight already",
                           "Wait for the earlier requests to finish before sending more."});
            return;
        }
        HttpRequest request;
        request.method = args.value("method", std::string("GET"));
        request.url = args.value("url", std::string());
        request.body = args.value("body", std::string());
        request.timeoutSec = args.value("timeout", 15.0);
        if (auto it = args.find("headers"); it != args.end() && it->is_object())
            for (auto h = it->begin(); h != it->end(); ++h)
                if (h.value().is_string()) request.headers.emplace_back(h.key(), h.value().get<std::string>());
        ++*inFlight_;
        client_->send(std::move(request), [sink, id, counter = inFlight_](HttpResponse response) {
            --*counter;
            if (!response.ok) {
                sink.fail(id, {"network", response.error.empty() ? "the request failed" : response.error, response.hint});
                return;
            }
            Json headers = Json::object();
            for (const auto& [name, value] : response.headers) {  // repeated headers are joined, as fetch does
                const std::string text = valid_utf8(value);
                if (auto it = headers.find(name); it != headers.end()) it->get_ref<std::string&>() += ", " + text;
                else headers[name] = text;
            }
            sink.complete(id, Json::object({{"status", response.status}, {"headers", std::move(headers)}, {"text", valid_utf8(response.body)}}));
        });
    }

private:
    std::unique_ptr<HttpClient> client_;
    std::shared_ptr<std::atomic<int>> inFlight_;
};

}  // namespace

std::unique_ptr<PlatformBackend> make_http_backend(std::unique_ptr<HttpClient> client) {
    if (!client) client = make_system_http_client();
    return std::make_unique<HttpBackend>(std::move(client));
}

}  // namespace fa
