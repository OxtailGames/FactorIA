// list_models: which models a provider offers (docs/AI_PROVIDERS.md, "Choosing models").
#include <algorithm>

#include "fa/ai/anthropic.h"
#include "fa/ai/cli_agent.h"
#include "fa/ai/process.h"
#include "provider_util.h"
#include "util.h"

namespace fa::ai {

using namespace util;

namespace {

// GET `hr.url`; the "data" array of the reply. One try: the caller shows the error and the user can ask again.
Result<Json> get_model_list(std::string_view provider, HttpRequest hr, const ProviderRuntime& rt) {
    hr.method = "GET";
    HttpResponse resp = send_with_retry(rt, hr, 0, nullptr);
    if (!resp.ok()) {
        return make_error(describe_http_error(provider, resp),
                          resp.status == 404 ? "This server does not list its models at " + hr.url + ": type the model name."
                                             : http_error_hint(provider, resp.status));
    }
    Json body = parse(resp.body);
    const Json* data = child(body, "data");
    if (!data || !data->is_array()) {
        return make_error(std::string(provider) + " answered without a \"data\" list of models",
                          "Reply: " + resp.body.substr(0, 200));
    }
    return *data;
}

Result<std::vector<ModelInfo>> list_anthropic(const ProviderConfig& cfg, const ProviderRuntime& rt) {
    auto auth = anthropic::resolve_auth(cfg, rt);
    if (!auth) return auth.error();
    HttpRequest hr;
    hr.url = trim_slashes(cfg.baseUrl.empty() ? "https://api.anthropic.com" : cfg.baseUrl) + "/v1/models?limit=1000";
    hr.headers = anthropic::build_headers(ChatRequest{}, *auth, cfg);
    hr.timeoutSeconds = 30;
    hr.connectTimeoutSeconds = 10;
    auto data = get_model_list("Anthropic", hr, rt);
    if (!data) return data.error();
    std::vector<ModelInfo> models;
    for (const Json& m : *data) {
        if (!str(m, "id").empty()) models.push_back({str(m, "id"), str(m, "display_name"), "", ""});
    }
    return models;
}

Result<std::vector<ModelInfo>> list_openai(const ProviderConfig& cfg, const ProviderRuntime& rt) {
    const std::string keyEnv = default_key_env(cfg);
    auto key = resolve_api_key(cfg, rt.env);
    if (!key.found() && !keyEnv.empty()) {
        return make_error("No API key for provider '" + cfg.name + "'",
                          "Set the " + keyEnv + " environment variable, or \"apiKeyEnv\"/\"apiKey\" for this provider in "
                          "~/.factoria/ai.json.");
    }
    HttpRequest hr;
    hr.url = trim_slashes(cfg.baseUrl) + "/models";
    if (key.found()) hr.headers.emplace_back("Authorization", "Bearer " + key.key);
    for (const auto& kv : cfg.headers) hr.headers.push_back(kv);
    hr.timeoutSeconds = 30;
    hr.connectTimeoutSeconds = keyEnv.empty() ? 3 : 10;  // a local server (ollama, lmstudio) that is not running fails fast
    auto data = get_model_list(cfg.name, hr, rt);
    if (!data) return data.error();
    std::vector<ModelInfo> models;
    for (const Json& m : *data) {
        if (!str(m, "id").empty()) models.push_back({str(m, "id"), "", "", ""});
    }
    std::sort(models.begin(), models.end(), [](const ModelInfo& a, const ModelInfo& b) { return a.id < b.id; });
    return models;
}

// Claude Code answers its `initialize` control request with the models it offers (aliases first): no model call, no usage.
Result<std::vector<ModelInfo>> list_claude(const ProviderConfig& cfg) {
    auto po = cli_process_options(cfg);
    if (!po) return po.error();
    for (const char* a : {"-p", "--input-format", "stream-json", "--output-format", "stream-json", "--verbose"}) {
        po->argv.push_back(a);
    }
    po->stdinText = R"({"type":"control_request","request_id":"fa-models","request":{"subtype":"initialize"}})";
    po->timeoutSeconds = 60;
    CancelFlag gotReply{false};  // the CLI would wait for more input: stop it as soon as it has answered
    po->cancel = &gotReply;
    Json reply;
    po->onStdoutLine = [&](std::string_view line) {  // system and hook events come first
        Json j = reply.is_null() ? parse(line) : Json();
        if (str(j, "type") == "control_response") {
            reply = std::move(j);
            gotReply = true;
        }
    };
    auto pr = run_process(*po);
    if (!pr) return make_error(pr.error().message, pr.error().hint.empty() ? cli_install_hint(cfg) : pr.error().hint);
    const std::string update = "Update Claude Code (npm i -g @anthropic-ai/claude-code): older versions cannot list models. "
                               "Or type the model name.";
    if (reply.is_null()) {
        if (looks_like_auth_failure(pr->stdoutText) || looks_like_auth_failure(pr->stderrText)) {
            return make_error("Provider '" + cfg.name + "' is not logged in or its credentials were rejected",
                              "Run `claude` once in a terminal and log in (or `claude setup-token`), then ask again. " +
                                  cli_install_hint(cfg));
        }
        return make_error("Provider '" + cfg.name + "' did not list its models: " +
                              (pr->timedOut ? std::string("no answer in 60 s")
                                            : "the CLI exited (code " + std::to_string(pr->exitCode) + ") without answering. " +
                                                  pr->stderrText.substr(0, 300)),
                          update);
    }
    const Json* outer = child(reply, "response");
    if (outer && str(*outer, "subtype") == "error") {
        return make_error("Provider '" + cfg.name + "' could not list its models: " + str(*outer, "error"), update);
    }
    const Json* inner = outer ? child(*outer, "response") : nullptr;
    const Json* list = inner ? child(*inner, "models") : nullptr;
    if (!list || !list->is_array()) {
        return make_error("Provider '" + cfg.name + "' answered without a list of models", update);
    }
    std::vector<ModelInfo> models;
    for (const Json& m : *list) {
        const std::string id = str(m, "value"), resolved = str(m, "resolvedModel");
        if (!id.empty()) models.push_back({id, str(m, "displayName"), str(m, "description"), resolved == id ? "" : resolved});
    }
    return models;
}

}  // namespace

Result<std::vector<ModelInfo>> list_models(const ProviderConfig& cfg, ProviderRuntime rt) {
    switch (cfg.kind) {
        case ProviderKind::ClaudeCode: return list_claude(cfg);
        case ProviderKind::Anthropic: return list_anthropic(cfg, rt);
        case ProviderKind::OpenAICompatible: return list_openai(cfg, rt);
        case ProviderKind::ElevenLabs:
        case ProviderKind::Meshy:
        case ProviderKind::Fake:
        case ProviderKind::AssetCommand:
            return make_error("Provider '" + cfg.name + "' (" + provider_kind_name(cfg.kind) +
                                  ") generates assets, it has no chat models",
                              "Use it under \"assets\" in ai.json (docs/AI_PROVIDERS.md, Asset providers); its model is "
                              "assets.<kind>.model.");
        default:
            return make_error("Provider '" + cfg.name + "' (" + provider_kind_name(cfg.kind) + ") does not list its models",
                              "Type the model name; the CLI's own documentation lists the ones it accepts.");
    }
}

}  // namespace fa::ai
