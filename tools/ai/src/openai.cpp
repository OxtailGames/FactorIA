#include "fa/ai/openai.h"

#include <algorithm>

#include "provider_util.h"
#include "util.h"

namespace fa::ai::openai {

using namespace util;

std::string chat_completions_url(const ProviderConfig& cfg) {
    std::string base = cfg.baseUrl;
    while (!base.empty() && base.back() == '/') base.pop_back();
    return base + "/chat/completions";
}

namespace {

Json assistant_to_json(const Message& m) {
    if (m.raw.is_object()) return m.raw;  // resent unchanged
    Json out = Json::object({{"role", "assistant"}});
    out["content"] = m.text.empty() ? Json(nullptr) : Json(m.text);
    if (!m.toolCalls.empty()) {
        Json calls = Json::array();
        for (const auto& c : m.toolCalls) {
            calls.push_back(Json::object(
                {{"id", c.id},
                 {"type", "function"},
                 {"function", Json::object({{"name", c.name}, {"arguments", dump(c.input)}})}}));
        }
        out["tool_calls"] = calls;
    }
    return out;
}

bool trim_empty(const std::string& s) {
    return s.find_first_not_of(" \t\r\n") == std::string::npos;
}

const char* map_effort(const std::string& e) {
    if (e == "low") return "low";
    if (e == "medium") return "medium";
    return "high";
}

}  // namespace

Json build_request(const ChatRequest& req, const ProviderConfig& cfg) {
    Json body = Json::object();
    body["model"] = req.model;
    Json messages = Json::array();
    if (!req.system.empty()) messages.push_back(Json::object({{"role", "system"}, {"content", req.system}}));
    for (const auto& m : req.messages) {
        if (m.role == Role::Assistant) {
            messages.push_back(assistant_to_json(m));
            continue;
        }
        if (m.toolResults.empty()) {
            if (m.images.empty()) {
                messages.push_back(Json::object({{"role", "user"}, {"content", m.text}}));
                continue;
            }
            Json parts = Json::array();
            if (!m.text.empty()) parts.push_back(Json::object({{"type", "text"}, {"text", m.text}}));
            for (const auto& img : m.images) {
                parts.push_back(Json::object(
                    {{"type", "image_url"},
                     {"image_url", Json::object({{"url", "data:" + img.mediaType + ";base64," + img.base64}})}}));
            }
            messages.push_back(Json::object({{"role", "user"}, {"content", std::move(parts)}}));
            continue;
        }
        // One "tool" message per result (all answered before any other message),
        // images (not allowed in tool messages) follow in a single user message.
        Json imageParts = Json::array();
        for (const auto& r : m.toolResults) {
            messages.push_back(
                Json::object({{"role", "tool"}, {"tool_call_id", r.toolUseId}, {"content", r.content}}));
            for (const auto& img : r.images) {
                imageParts.push_back(Json::object(
                    {{"type", "image_url"},
                     {"image_url", Json::object({{"url", "data:" + img.mediaType + ";base64," + img.base64}})}}));
            }
        }
        if (!imageParts.empty() || !m.text.empty()) {
            Json parts = Json::array();
            parts.push_back(Json::object({{"type", "text"},
                                          {"text", m.text.empty() ? "Images returned by the tools above." : m.text}}));
            for (auto& p : imageParts) parts.push_back(std::move(p));
            messages.push_back(Json::object({{"role", "user"}, {"content", parts}}));
        }
    }
    body["messages"] = std::move(messages);
    if (!req.tools.empty()) {
        std::vector<const ToolDef*> sorted;
        for (const auto& t : req.tools) sorted.push_back(&t);
        std::stable_sort(sorted.begin(), sorted.end(), [](auto* a, auto* b) { return a->name < b->name; });
        Json tools = Json::array();
        for (const auto* t : sorted) {
            tools.push_back(Json::object(
                {{"type", "function"},
                 {"function", Json::object({{"name", t->name},
                                            {"description", t->description},
                                            {"parameters", t->inputSchema.is_object() ? t->inputSchema
                                                                                      : Json::object({{"type", "object"}})}})}}));
        }
        body["tools"] = std::move(tools);
    }
    if (req.maxTokens > 0) body[cfg.preset == "openai" ? "max_completion_tokens" : "max_tokens"] = req.maxTokens;
    if (cfg.sendReasoningEffort && !req.effort.empty()) body["reasoning_effort"] = map_effort(req.effort);
    if (req.stream) {
        body["stream"] = true;
        body["stream_options"] = Json::object({{"include_usage", true}});
    }
    return body;
}

namespace {

StopReason map_finish(const std::string& f, bool hasCalls) {
    if (hasCalls) return StopReason::ToolUse;
    if (f == "stop" || f.empty()) return StopReason::EndTurn;
    if (f == "tool_calls" || f == "function_call") return StopReason::ToolUse;
    if (f == "length") return StopReason::MaxTokens;
    if (f == "content_filter") return StopReason::Refusal;
    return StopReason::Other;
}

Usage parse_usage(const Json& body) {
    Usage u;
    if (const Json* uj = child(body, "usage"); uj && uj->is_object()) {
        u64 prompt = static_cast<u64>(num(*uj, "prompt_tokens"));
        u.outputTokens = static_cast<u64>(num(*uj, "completion_tokens"));
        u64 cached = 0;
        if (const Json* d = child(*uj, "prompt_tokens_details")) cached = static_cast<u64>(num(*d, "cached_tokens"));
        if (cached == 0) cached = static_cast<u64>(num(*uj, "prompt_cache_hit_tokens"));  // DeepSeek
        u.cacheReadTokens = std::min(cached, prompt);
        u.inputTokens = prompt - u.cacheReadTokens;
    }
    return u;
}

}  // namespace

Result<ChatResponse> parse_response(const Json& body) {
    if (!body.is_object()) return make_error("Response is not a JSON object");
    if (const Json* e = child(body, "error"); e && !e->is_null()) {
        std::string msg = e->is_object() ? str(*e, "message") : (e->is_string() ? e->get<std::string>() : dump(*e));
        return make_error("API error: " + msg);
    }
    const Json* choices = child(body, "choices");
    if (!choices || !choices->is_array() || choices->empty()) {
        return make_error("Response has no choices", "Raw: " + dump(body).substr(0, 300));
    }
    const Json& choice = (*choices)[0];
    const Json* msg = child(choice, "message");
    if (!msg || !msg->is_object()) return make_error("Response choice has no message");
    ChatResponse r;
    r.message.role = Role::Assistant;
    if (const Json* c = child(*msg, "content"); c && c->is_string()) r.message.text = c->get<std::string>();
    // Keep the provider-native assistant message (minimal fields) for resending.
    Json raw = Json::object({{"role", "assistant"}});
    raw["content"] = r.message.text.empty() ? Json(nullptr) : Json(r.message.text);
    if (const Json* calls = child(*msg, "tool_calls"); calls && calls->is_array() && !calls->empty()) {
        raw["tool_calls"] = *calls;
        for (const auto& c : *calls) {
            ToolCall tc;
            tc.id = str(c, "id");
            if (const Json* f = child(c, "function")) {
                tc.name = str(*f, "name");
                const Json* a = child(*f, "arguments");
                if (a && a->is_string()) {
                    std::string s = a->get<std::string>();
                    if (trim_empty(s)) tc.input = Json::object();
                    else {
                        Json parsed = parse(s);
                        if (parsed.is_object()) tc.input = parsed;
                        else tc.inputError = "arguments are not a valid JSON object: " + s.substr(0, 200);
                    }
                } else if (a && a->is_object()) {
                    tc.input = *a;
                }
            }
            r.message.toolCalls.push_back(std::move(tc));
        }
    }
    if (const Json* ec = child(*msg, "extra_content")) raw["extra_content"] = *ec;
    r.message.raw = std::move(raw);
    r.rawStopReason = str(choice, "finish_reason");
    r.stopReason = map_finish(r.rawStopReason, !r.message.toolCalls.empty());
    if (r.stopReason == StopReason::Refusal) {
        r.refusalCategory = "content_filter";
        r.refusalExplanation = "The provider's content filter stopped the response.";
    }
    if (const Json* rf = child(*msg, "refusal"); rf && rf->is_string() && !rf->get<std::string>().empty()) {
        r.stopReason = StopReason::Refusal;
        r.refusalCategory = "refusal";
        r.refusalExplanation = rf->get<std::string>();
    }
    r.usage = parse_usage(body);
    r.model = str(body, "model");
    return r;
}

// ---------------------------------------------------------------------------

void StreamAssembler::handle_data(const std::string& data) {
    if (data == "[DONE]") { done_ = true; return; }
    Json j = parse(data);
    if (j.is_discarded()) return;
    if (const Json* e = child(j, "error"); e && !e->is_null()) {
        error_ = e->is_object() ? str(*e, "message", "stream error") : (e->is_string() ? e->get<std::string>() : "stream error");
        done_ = true;
        return;
    }
    if (model_.empty()) model_ = str(j, "model");
    if (const Json* u = child(j, "usage"); u && u->is_object()) usage_ = *u;
    const Json* choices = child(j, "choices");
    if (!choices || !choices->is_array() || choices->empty()) return;
    const Json& ch = (*choices)[0];
    if (std::string f = str(ch, "finish_reason"); !f.empty()) finish_ = f;
    const Json* d = child(ch, "delta");
    if (!d || !d->is_object()) return;
    if (std::string t = str(*d, "content"); !t.empty()) {
        content_ += t;
        if (hooks_.onText) hooks_.onText(t);
    }
    std::string rc = str(*d, "reasoning_content");
    if (rc.empty()) rc = str(*d, "reasoning");
    if (!rc.empty()) {
        reasoning_ += rc;
        if (hooks_.onThinking) hooks_.onThinking(rc);
    }
    if (const Json* tcs = child(*d, "tool_calls"); tcs && tcs->is_array()) {
        for (const auto& tc : *tcs) {
            auto idx = static_cast<std::size_t>(num(tc, "index"));
            if (idx > 64) continue;
            if (calls_.size() <= idx) calls_.resize(idx + 1);
            Tc& c = calls_[idx];
            bool fresh = c.name.empty();
            if (std::string id = str(tc, "id"); !id.empty()) c.id = id;
            if (const Json* f = child(tc, "function")) {
                if (std::string n = str(*f, "name"); !n.empty()) c.name += n;
                c.args += str(*f, "arguments");
            }
            if (fresh && !c.name.empty() && hooks_.onToolUseStart) hooks_.onToolUseStart(c.name);
        }
    }
}

Json StreamAssembler::body() const {
    Json msg = Json::object({{"role", "assistant"}});
    msg["content"] = content_.empty() ? Json(nullptr) : Json(content_);
    if (!calls_.empty()) {
        Json calls = Json::array();
        for (const auto& c : calls_) {
            if (c.name.empty() && c.args.empty()) continue;
            calls.push_back(Json::object({{"id", c.id},
                                          {"type", "function"},
                                          {"function", Json::object({{"name", c.name}, {"arguments", c.args}})}}));
        }
        if (!calls.empty()) msg["tool_calls"] = calls;
    }
    Json out = Json::object();
    out["model"] = model_;
    out["choices"] = Json::array({Json::object({{"index", 0}, {"message", msg}, {"finish_reason", finish_}})});
    if (!usage_.is_null()) out["usage"] = usage_;
    return out;
}

// ---------------------------------------------------------------------------

namespace {

class OpenAiProvider : public ChatProvider {
public:
    OpenAiProvider(ProviderConfig cfg, ProviderRuntime rt) : cfg_(std::move(cfg)), rt_(std::move(rt)) {}
    std::string name() const override { return cfg_.name; }

    Result<ChatResponse> chat(const ChatRequest& req, const ChatHooks& hooks, const CancelFlag* cancel) override {
        auto key = resolve_api_key(cfg_, rt_.env);
        const bool local = cfg_.preset == "ollama" || cfg_.preset == "lmstudio";
        if (!key.found() && !local && cfg_.preset != "") {
            std::string env = default_key_env(cfg_);
            return make_error("No API key for provider '" + cfg_.name + "'",
                              "Set the " + (env.empty() ? std::string("API key environment variable") : env) +
                                  " environment variable, or \"apiKeyEnv\"/\"apiKey\" for this provider in ~/.factoria/ai.json.");
        }
        HttpRequest hr;
        hr.url = chat_completions_url(cfg_);
        hr.headers.emplace_back("content-type", "application/json");
        if (key.found()) hr.headers.emplace_back("Authorization", "Bearer " + key.key);
        if (req.stream) hr.headers.emplace_back("accept", "text/event-stream");
        for (const auto& kv : cfg_.headers) hr.headers.push_back(kv);
        hr.body = dump(build_request(req, cfg_));
        hr.timeoutSeconds = cfg_.timeoutSeconds;
        StreamAssembler assembler(hooks);
        if (req.stream) hr.onData = [&](std::string_view c) {
            assembler.feed(c);
            return !assembler.done();
        };
        HttpResponse resp = send_with_retry(rt_, hr, cfg_.maxRetries, cancel, hooks.onRetry);
        if (resp.cancelled) return make_error("cancelled");
        if (resp.ok() && !resp.error.empty() && !(req.stream && assembler.done())) {
            return make_error(cfg_.name + " transfer interrupted: " + resp.error, http_error_hint(cfg_.name, 0));
        }
        if (!resp.ok()) {
            return make_error(describe_http_error(cfg_.name, resp), http_error_hint(cfg_.name, resp.status));
        }
        if (req.stream) {
            assembler.finish();
            if (assembler.has_error()) return make_error(cfg_.name + " stream error: " + assembler.error());
            auto r = parse_response(assembler.body());
            if (r && r->usage.total() == 0) { /* some servers omit usage when streaming */ }
            return r;
        }
        Json body = parse(resp.body);
        if (body.is_discarded()) return make_error(cfg_.name + " returned a non-JSON body", resp.body.substr(0, 300));
        auto r = parse_response(body);
        if (r && hooks.onText && !r->message.text.empty()) hooks.onText(r->message.text);
        return r;
    }

private:
    ProviderConfig cfg_;
    ProviderRuntime rt_;
};

}  // namespace

std::shared_ptr<ChatProvider> make_provider(const ProviderConfig& cfg, ProviderRuntime rt) {
    return std::make_shared<OpenAiProvider>(cfg, std::move(rt));
}

}  // namespace fa::ai::openai
