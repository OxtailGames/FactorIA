#include "fa/ai/anthropic.h"

#include <algorithm>

#include "fa/ai/process.h"
#include "fa/core/strings.h"
#include "provider_util.h"
#include "util.h"

namespace fa::ai::anthropic {

using namespace util;

namespace {

constexpr const char* kApiVersion = "2023-06-01";
constexpr const char* kOauthBeta = "oauth-2025-04-20";
constexpr const char* kFallbackBeta = "server-side-fallback-2026-07-01";
constexpr int kDefaultMaxTokens = 16000;
constexpr int kStreamMaxTokens = 64000;

Json image_block(const ImageData& img) {
    return Json::object({{"type", "image"},
                         {"source", Json::object({{"type", "base64"}, {"media_type", img.mediaType}, {"data", img.base64}})}});
}

Json message_to_json(const Message& m) {
    Json out = Json::object();
    if (m.role == Role::Assistant) {
        out["role"] = "assistant";
        if (m.raw.is_array()) {
            out["content"] = m.raw;  // resent UNCHANGED (thinking blocks included)
            return out;
        }
        Json content = Json::array();
        if (!m.text.empty()) content.push_back(Json::object({{"type", "text"}, {"text", m.text}}));
        for (const auto& c : m.toolCalls)
            content.push_back(Json::object({{"type", "tool_use"}, {"id", c.id}, {"name", c.name}, {"input", c.input}}));
        out["content"] = content;
        return out;
    }
    out["role"] = "user";
    if (m.toolResults.empty()) {
        if (m.images.empty()) {
            out["content"] = m.text;
            return out;
        }
        Json parts = Json::array();  // images first, the question after them (the recommended order)
        for (const auto& img : m.images) parts.push_back(image_block(img));
        if (!m.text.empty()) parts.push_back(Json::object({{"type", "text"}, {"text", m.text}}));
        out["content"] = std::move(parts);
        return out;
    }
    // All tool_result blocks of one assistant turn go into ONE user message, first.
    Json content = Json::array();
    for (const auto& r : m.toolResults) {
        Json b = Json::object({{"type", "tool_result"}, {"tool_use_id", r.toolUseId}});
        if (r.images.empty()) {
            b["content"] = r.content;
        } else {
            Json parts = Json::array();
            if (!r.content.empty()) parts.push_back(Json::object({{"type", "text"}, {"text", r.content}}));
            for (const auto& img : r.images) parts.push_back(image_block(img));
            b["content"] = parts;
        }
        if (r.isError) b["is_error"] = true;
        content.push_back(std::move(b));
    }
    if (!m.text.empty()) content.push_back(Json::object({{"type", "text"}, {"text", m.text}}));
    out["content"] = content;
    return out;
}

}  // namespace

bool supports_fallbacks(std::string_view model) {
    auto has = [&](std::string_view s) { return model.find(s) != std::string_view::npos; };
    return (has("opus") || has("sonnet")) && !has("haiku");
}

Json build_request(const ChatRequest& req) {
    Json body = Json::object();
    body["model"] = req.model;
    int maxTokens = req.maxTokens > 0 ? req.maxTokens : (req.stream ? kStreamMaxTokens : kDefaultMaxTokens);
    body["max_tokens"] = maxTokens;
    if (!req.system.empty()) {
        body["system"] = Json::array({Json::object({{"type", "text"}, {"text", req.system}})});
    }
    Json messages = Json::array();
    for (const auto& m : req.messages) messages.push_back(message_to_json(m));
    body["messages"] = std::move(messages);
    if (!req.tools.empty()) {
        std::vector<const ToolDef*> sorted;
        for (const auto& t : req.tools) sorted.push_back(&t);
        std::stable_sort(sorted.begin(), sorted.end(), [](auto* a, auto* b) { return a->name < b->name; });
        Json tools = Json::array();
        for (const auto* t : sorted) {
            tools.push_back(Json::object({{"name", t->name},
                                          {"description", t->description},
                                          {"input_schema", t->inputSchema.is_object() ? t->inputSchema
                                                                                      : Json::object({{"type", "object"}})}}));
        }
        body["tools"] = std::move(tools);
    }
    if (!req.effort.empty()) body["output_config"] = Json::object({{"effort", req.effort}});
    body["cache_control"] = Json::object({{"type", "ephemeral"}});
    if (supports_fallbacks(req.model)) body["fallbacks"] = "default";
    if (req.stream) body["stream"] = true;
    return body;
}

std::vector<std::pair<std::string, std::string>> build_headers(const ChatRequest& req, const Auth& auth,
                                                               const ProviderConfig& cfg) {
    std::vector<std::pair<std::string, std::string>> h;
    h.emplace_back("content-type", "application/json");
    h.emplace_back("anthropic-version", kApiVersion);
    std::vector<std::string> betas;
    if (!auth.apiKey.empty()) {
        h.emplace_back("x-api-key", auth.apiKey);
    } else if (!auth.bearerToken.empty()) {
        h.emplace_back("Authorization", "Bearer " + auth.bearerToken);
        betas.push_back(kOauthBeta);
    }
    if (supports_fallbacks(req.model)) betas.push_back(kFallbackBeta);
    if (!betas.empty()) h.emplace_back("anthropic-beta", fa::join(betas, ","));
    if (req.stream) h.emplace_back("accept", "text/event-stream");
    for (const auto& kv : cfg.headers) h.push_back(kv);
    return h;
}

static StopReason map_stop(const std::string& s) {
    if (s == "end_turn" || s == "stop_sequence") return StopReason::EndTurn;
    if (s == "tool_use") return StopReason::ToolUse;
    if (s == "max_tokens") return StopReason::MaxTokens;
    if (s == "pause_turn") return StopReason::PauseTurn;
    if (s == "refusal") return StopReason::Refusal;
    return StopReason::Other;
}

static Usage parse_usage(const Json& body) {
    Usage u;
    if (const Json* uj = child(body, "usage")) {
        u.inputTokens = static_cast<u64>(num(*uj, "input_tokens"));
        u.outputTokens = static_cast<u64>(num(*uj, "output_tokens"));
        u.cacheCreationTokens = static_cast<u64>(num(*uj, "cache_creation_input_tokens"));
        u.cacheReadTokens = static_cast<u64>(num(*uj, "cache_read_input_tokens"));
    }
    return u;
}

Result<ChatResponse> parse_response(const Json& body) {
    if (!body.is_object()) return make_error("Anthropic response is not a JSON object");
    if (str(body, "type") == "error") {
        const Json* e = child(body, "error");
        return make_error("Anthropic API error (" + (e ? str(*e, "type") : std::string("unknown")) +
                          "): " + (e ? str(*e, "message") : std::string()));
    }
    const Json* content = child(body, "content");
    if (!content || !content->is_array()) {
        return make_error("Anthropic response has no content array", "Raw: " + dump(body).substr(0, 300));
    }
    ChatResponse r;
    r.message.role = Role::Assistant;
    r.message.raw = *content;
    for (const auto& b : *content) {
        std::string type = str(b, "type");
        if (type == "text") {
            r.message.text += str(b, "text");
        } else if (type == "tool_use") {
            ToolCall c;
            c.id = str(b, "id");
            c.name = str(b, "name");
            if (const Json* in = child(b, "input")) {
                if (in->is_object()) c.input = *in;
                else if (in->is_string()) {
                    Json parsed = parse(in->get<std::string>());
                    if (parsed.is_object()) c.input = parsed;
                    else c.inputError = "tool input is not a JSON object";
                } else c.inputError = "tool input is not a JSON object";
            }
            r.message.toolCalls.push_back(std::move(c));
        }
    }
    r.rawStopReason = str(body, "stop_reason");
    r.stopReason = map_stop(r.rawStopReason);
    if (r.stopReason == StopReason::EndTurn && !r.message.toolCalls.empty() && r.rawStopReason.empty())
        r.stopReason = StopReason::ToolUse;
    r.usage = parse_usage(body);
    r.model = str(body, "model");
    if (r.stopReason == StopReason::Refusal) {
        // stop_details is only read for refusals.
        if (const Json* sd = child(body, "stop_details")) {
            r.refusalCategory = str(*sd, "category");
            r.refusalExplanation = str(*sd, "explanation");
        }
    }
    return r;
}

// ---------------------------------------------------------------------------
// Streaming

void StreamAssembler::handle_event(const std::string& event, const std::string& data) {
    if (data.empty()) return;
    Json j = parse(data);
    if (j.is_discarded()) return;
    std::string type = str(j, "type", event);
    if (type == "message_start") {
        started_ = true;
        if (const Json* m = child(j, "message"); m && m->is_object()) message_ = *m;
        message_["content"] = Json::array();
    } else if (type == "content_block_start") {
        auto idx = static_cast<std::size_t>(num(j, "index"));
        const Json* cb = child(j, "content_block");
        if (!cb) return;
        Json& content = message_["content"];
        while (content.size() <= idx) content.push_back(Json());
        content[idx] = *cb;
        if (partialJson_.size() <= idx) partialJson_.resize(idx + 1);
        partialJson_[idx].clear();
        if (str(*cb, "type") == "tool_use" && hooks_.onToolUseStart) hooks_.onToolUseStart(str(*cb, "name"));
    } else if (type == "content_block_delta") {
        auto idx = static_cast<std::size_t>(num(j, "index"));
        const Json* d = child(j, "delta");
        Json& content = message_["content"];
        if (!d || idx >= content.size() || !content[idx].is_object()) return;
        Json& block = content[idx];
        std::string dt = str(*d, "type");
        if (dt == "text_delta") {
            std::string t = str(*d, "text");
            block["text"] = str(block, "text") + t;
            if (hooks_.onText) hooks_.onText(t);
        } else if (dt == "input_json_delta") {
            if (partialJson_.size() <= idx) partialJson_.resize(idx + 1);
            partialJson_[idx] += str(*d, "partial_json");
        } else if (dt == "thinking_delta") {
            std::string t = str(*d, "thinking");
            block["thinking"] = str(block, "thinking") + t;
            if (hooks_.onThinking) hooks_.onThinking(t);
        } else if (dt == "signature_delta") {
            block["signature"] = str(block, "signature") + str(*d, "signature");
        }
    } else if (type == "content_block_stop") {
        auto idx = static_cast<std::size_t>(num(j, "index"));
        Json& content = message_["content"];
        if (idx < content.size() && content[idx].is_object() && str(content[idx], "type") == "tool_use") {
            const std::string& pj = idx < partialJson_.size() ? partialJson_[idx] : std::string();
            if (pj.empty()) {
                if (!content[idx].contains("input")) content[idx]["input"] = Json::object();
            } else {
                Json parsed = parse(pj);
                // Parse tool inputs as JSON; a truncated stream leaves the string for the caller to reject.
                content[idx]["input"] = parsed.is_discarded() ? Json(pj) : parsed;
            }
        }
    } else if (type == "message_delta") {
        if (const Json* d = child(j, "delta")) {
            if (d->contains("stop_reason")) message_["stop_reason"] = (*d)["stop_reason"];
            if (d->contains("stop_details")) message_["stop_details"] = (*d)["stop_details"];
            if (d->contains("stop_sequence")) message_["stop_sequence"] = (*d)["stop_sequence"];
        }
        if (const Json* u = child(j, "usage"); u && u->is_object()) {
            Json& mu = message_["usage"];
            if (!mu.is_object()) mu = Json::object();
            for (auto it = u->begin(); it != u->end(); ++it) mu[it.key()] = it.value();
        }
    } else if (type == "message_stop") {
        done_ = true;
    } else if (type == "error") {
        if (const Json* e = child(j, "error")) {
            errorType_ = str(*e, "type", "error");
            error_ = str(*e, "message", "stream error");
        } else {
            errorType_ = "error";
            error_ = "stream error";
        }
        done_ = true;
    }  // ping and unknown events: ignored
}

// ---------------------------------------------------------------------------
// Provider

namespace {

class AnthropicProvider : public ChatProvider {
public:
    AnthropicProvider(ProviderConfig cfg, ProviderRuntime rt) : cfg_(std::move(cfg)), rt_(std::move(rt)) {
        if (!rt_.antToken) rt_.antToken = [] { return fetch_ant_token(); };
    }
    std::string name() const override { return cfg_.name.empty() ? "anthropic" : cfg_.name; }

    static std::string fetch_ant_token() {
        if (which("ant").empty()) return {};
        ProcessOptions po;
        po.argv = {"ant", "auth", "print-credentials", "--access-token"};
        po.timeoutSeconds = 20;
        auto r = run_process(po);
        if (!r || r->exitCode != 0) return {};
        return std::string(fa::trim(r->stdoutText));
    }

    Result<ChatResponse> chat(const ChatRequest& req, const ChatHooks& hooks, const CancelFlag* cancel) override {
        Auth auth;
        auto key = resolve_api_key(cfg_, rt_.env);
        bool usingToken = false;
        if (key.found()) auth.apiKey = key.key;
        else if (cfg_.useAntCli) {
            auth.bearerToken = rt_.antToken();
            usingToken = true;
        }
        if (auth.apiKey.empty() && auth.bearerToken.empty()) {
            return make_error(
                "No Anthropic credentials found",
                "Set ANTHROPIC_API_KEY (or \"apiKeyEnv\"/\"apiKey\" in ~/.factoria/ai.json), or install the `ant` CLI "
                "and run `ant auth login`. To use a Claude subscription instead, pick the claude-code provider.");
        }
        std::string base = cfg_.baseUrl.empty() ? "https://api.anthropic.com" : cfg_.baseUrl;
        while (!base.empty() && base.back() == '/') base.pop_back();

        for (int authAttempt = 0; authAttempt < 2; ++authAttempt) {
            HttpRequest hr;
            hr.url = base + "/v1/messages";
            hr.headers = build_headers(req, auth, cfg_);
            hr.body = dump(build_request(req));
            hr.timeoutSeconds = cfg_.timeoutSeconds;
            StreamAssembler assembler(hooks);
            if (req.stream) hr.onData = [&](std::string_view c) {
                assembler.feed(c);
                return !assembler.done();
            };
            HttpResponse resp = send_with_retry(rt_, hr, cfg_.maxRetries, cancel, hooks.onRetry);
            if (resp.cancelled) return make_error("cancelled");
            if (resp.status == 401 && usingToken && authAttempt == 0) {
                auth.bearerToken = rt_.antToken();  // token may have expired: refresh once
                if (!auth.bearerToken.empty()) continue;
            }
            if (resp.ok() && !resp.error.empty() && !(req.stream && assembler.done())) {
                return make_error("Anthropic transfer interrupted: " + resp.error, http_error_hint("Anthropic", 0));
            }
            if (!resp.ok()) {
                if (resp.status == 0 && req.stream && assembler.done()) {
                    // Aborted by us after message_stop: fine.
                } else {
                    return make_error(describe_http_error("Anthropic", resp),
                                      resp.status == 401 && usingToken
                                          ? "The `ant` token was rejected. Run `ant auth login` again, or set ANTHROPIC_API_KEY."
                                          : http_error_hint("Anthropic", resp.status));
                }
            }
            if (req.stream) {
                assembler.finish();
                if (assembler.has_error()) {
                    return make_error("Anthropic stream error (" + assembler.error_type() + "): " + assembler.error(),
                                      assembler.error_type() == "overloaded_error" ? "The API is overloaded; retry in a moment." : "");
                }
                if (!assembler.started()) return make_error("Anthropic stream ended before message_start", dump(Json(resp.body.substr(0, 200))));
                return parse_response(assembler.message());
            }
            Json body = parse(resp.body);
            if (body.is_discarded()) {
                return make_error("Anthropic returned a non-JSON body", resp.body.substr(0, 300));
            }
            auto r = parse_response(body);
            if (r && hooks.onText && !r->message.text.empty()) hooks.onText(r->message.text);
            return r;
        }
        return make_error("Anthropic authentication failed");
    }

private:
    ProviderConfig cfg_;
    ProviderRuntime rt_;
};

}  // namespace

std::shared_ptr<ChatProvider> make_provider(const ProviderConfig& cfg, ProviderRuntime rt) {
    return std::make_shared<AnthropicProvider>(cfg, std::move(rt));
}

}  // namespace fa::ai::anthropic
