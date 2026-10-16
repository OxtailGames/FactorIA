#include "fa/ai/provider.h"

#include <algorithm>
#include <chrono>
#include <thread>

#include "fa/ai/anthropic.h"
#include "fa/ai/openai.h"
#include "provider_util.h"
#include "util.h"

namespace fa::ai {

bool is_retryable_status(int s) { return s == 429 || s == 500 || s == 502 || s == 503 || s == 504 || s == 529; }

void default_sleep(double seconds, const CancelFlag* cancel) {
    using namespace std::chrono;
    auto end = steady_clock::now() + duration<double>(seconds);
    while (steady_clock::now() < end && !is_cancelled(cancel)) {
        std::this_thread::sleep_for(milliseconds(50));
    }
}

HttpResponse send_with_retry(const ProviderRuntime& rt, HttpRequest request, int maxRetries, const CancelFlag* cancel,
                             const std::function<void(const std::string&)>& onRetry) {
    HttpTransport transport = rt.transport ? rt.transport : HttpTransport(http_request);
    request.cancel = cancel;
    bool dataStarted = false;
    if (request.onData) {
        auto inner = request.onData;
        request.onData = [&dataStarted, inner](std::string_view c) {
            dataStarted = true;
            return inner(c);
        };
    }
    HttpResponse resp;
    for (int attempt = 0;; ++attempt) {
        resp = transport(request);
        if (resp.cancelled || is_cancelled(cancel)) return resp;
        const bool transient = is_retryable_status(resp.status) || (resp.status == 0 && !resp.error.empty());
        if (!transient || attempt >= maxRetries || dataStarted) return resp;
        double delay = std::min(30.0, static_cast<double>(1 << std::min(attempt, 5)));
        if (double ra = parse_retry_after(resp.header("retry-after")); ra > 0) delay = std::min(ra, 120.0);
        if (onRetry) {
            onRetry("HTTP " + std::to_string(resp.status) + (resp.error.empty() ? "" : " (" + resp.error + ")") +
                    ", retrying in " + std::to_string(static_cast<int>(delay)) + "s (attempt " +
                    std::to_string(attempt + 1) + "/" + std::to_string(maxRetries) + ")");
        }
        if (rt.sleep) rt.sleep(delay);
        else default_sleep(delay, cancel);
        if (is_cancelled(cancel)) { resp.cancelled = true; return resp; }
    }
}

std::string describe_http_error(std::string_view provider, const HttpResponse& resp) {
    if (resp.status == 0) {
        return std::string(provider) + " request failed: " + (resp.error.empty() ? "no response" : resp.error);
    }
    std::string msg = std::string(provider) + " API error " + std::to_string(resp.status);
    Json j = util::parse(resp.body);
    if (!j.is_discarded()) {
        const Json* e = util::child(j, "error");
        if (e && e->is_object()) {
            std::string type = util::str(*e, "type");
            if (type.empty()) type = util::str(*e, "code");
            if (!type.empty()) msg += " (" + type + ")";
            std::string m = util::str(*e, "message");
            if (!m.empty()) msg += ": " + m;
            return msg;
        }
        if (e && e->is_string()) return msg + ": " + e->get<std::string>();
        if (j.is_array() && !j.empty()) {
            if (const Json* e0 = util::child(j[0], "error")) {
                std::string m = util::str(*e0, "message");
                if (!m.empty()) return msg + ": " + m;
            }
        }
        // ElevenLabs: {"detail": {"status": ..., "message": ...}} or {"detail": [{"loc": ..., "msg": ...}]}; Meshy: {"message": ...}
        if (const Json* d = util::child(j, "detail")) {
            const Json* first = d->is_array() && !d->empty() ? &(*d)[0] : d;
            std::string m = d->is_string() ? d->get<std::string>() : util::str(*first, "message", util::str(*first, "msg"));
            if (!m.empty()) return msg + ": " + m;
        }
        if (std::string m = util::str(j, "message"); !m.empty()) return msg + ": " + m;
    }
    std::string body = resp.body.substr(0, 300);
    if (!body.empty()) msg += ": " + body;
    return msg;
}

std::string http_error_hint(std::string_view provider, int status) {
    switch (status) {
        case 0: return "Check your internet connection / proxy (HTTPS_PROXY) and the baseUrl.";
        case 401:
        case 403: return "The key was rejected. Check the key for " + std::string(provider) + " (docs/AI_PROVIDERS.md).";
        case 404: return "Check the model name and baseUrl in ~/.factoria/ai.json.";
        case 429: return "Rate limited or out of credits. Wait and retry, or check your plan/credits.";
        case 529: return "The provider is overloaded. Retry in a moment.";
        default: return {};
    }
}

Result<std::shared_ptr<ChatProvider>> make_chat_provider(const ProviderConfig& cfg, ProviderRuntime rt) {
    switch (cfg.kind) {
        case ProviderKind::Anthropic: return anthropic::make_provider(cfg, std::move(rt));
        case ProviderKind::OpenAICompatible: return openai::make_provider(cfg, std::move(rt));
        case ProviderKind::ElevenLabs:
        case ProviderKind::Meshy:
        case ProviderKind::Fake:
        case ProviderKind::AssetCommand:
            return make_error("Provider '" + cfg.name + "' (" + provider_kind_name(cfg.kind) + ") only generates assets",
                              "A role needs a chat provider (anthropic, claude-code, openai...). Asset providers go under "
                              "\"assets\" in ai.json.");
        default:
            return make_error("Provider '" + cfg.name + "' is a CLI agent (" + provider_kind_name(cfg.kind) +
                                  "), not a chat API provider",
                              "CLI agents run their own loop: use make_cli_agent().");
    }
}

}  // namespace fa::ai
