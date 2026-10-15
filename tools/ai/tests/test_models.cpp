// list_models for the API providers and the providers that cannot list. (Claude Code through its CLI: test_cli_agent.cpp.)
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

static std::string header_of(const HttpRequest& req, const std::string& name) {
    for (const auto& [k, v] : req.headers) {
        if (k == name) return v;
    }
    return {};
}

static ProviderRuntime models_runtime(HttpTransport transport, std::map<std::string, std::string> env = {}) {
    ProviderRuntime rt;
    rt.transport = std::move(transport);
    rt.env = fake_env(std::move(env));
    rt.antToken = [] { return std::string(); };
    return rt;
}

static HttpResponse json_response(int status, const std::string& body) {
    HttpResponse r;
    r.status = status;
    r.body = body;
    return r;
}

TEST_CASE("list_models: Anthropic GET /v1/models with the API key") {
    HttpRequest seen;
    auto rt = models_runtime(
        [&](const HttpRequest& req) {
            seen = req;
            return json_response(
                200, R"({"data":[{"type":"model","id":"claude-opus-5-5","display_name":"Claude Opus 5.5","created_at":"2026-01-01T00:00:00Z"},
                        {"type":"model","id":"claude-haiku-4-5-20251001","display_name":"Claude Haiku 4.5"},{"type":"model"}],
                        "has_more":false,"first_id":"claude-opus-5-5","last_id":"claude-haiku-4-5-20251001"})");
        },
        {{"ANTHROPIC_API_KEY", "sk-ant-test-key-0000000000"}});
    auto models = list_models(default_config().providers["anthropic"], rt);
    REQUIRE(models);
    REQUIRE(models->size() == 2);  // the entry without an id is skipped
    CHECK((*models)[0].id == "claude-opus-5-5");
    CHECK((*models)[0].name == "Claude Opus 5.5");
    CHECK((*models)[0].resolved.empty());
    CHECK((*models)[1].id == "claude-haiku-4-5-20251001");
    CHECK(seen.method == "GET");
    CHECK(seen.url == "https://api.anthropic.com/v1/models?limit=1000");
    CHECK(header_of(seen, "x-api-key") == "sk-ant-test-key-0000000000");
    CHECK(header_of(seen, "anthropic-version") == "2023-06-01");
}

TEST_CASE("list_models: Anthropic falls back to the ant token; no credentials teaches") {
    HttpRequest seen;
    int calls = 0;
    auto rt = models_runtime([&](const HttpRequest& req) {
        seen = req;
        ++calls;
        return json_response(200, R"({"data":[{"id":"claude-sonnet-5","display_name":"Claude Sonnet 5"}]})");
    });
    rt.antToken = [] { return std::string("ant-token"); };
    auto models = list_models(default_config().providers["anthropic"], rt);
    REQUIRE(models);
    CHECK(header_of(seen, "Authorization") == "Bearer ant-token");
    CHECK(header_of(seen, "x-api-key").empty());
    CHECK(header_of(seen, "anthropic-beta").find("oauth-2025-04-20") != std::string::npos);

    rt.antToken = [] { return std::string(); };
    calls = 0;
    auto none = list_models(default_config().providers["anthropic"], rt);
    REQUIRE_FALSE(none.ok());
    CHECK(none.error().message == "No Anthropic credentials found");
    CHECK(none.error().hint.find("ANTHROPIC_API_KEY") != std::string::npos);
    CHECK(calls == 0);  // nothing is sent without credentials
}

TEST_CASE("list_models: a rejected key and a reply without models are errors that say what to do") {
    ProviderConfig cfg = default_config().providers["anthropic"];
    auto rejected = list_models(cfg, models_runtime(
        [](const HttpRequest&) {
            return json_response(401, R"({"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}})");
        },
        {{"ANTHROPIC_API_KEY", "sk-ant-test-key-0000000000"}}));
    REQUIRE_FALSE(rejected.ok());
    CHECK(rejected.error().message.find("authentication_error") != std::string::npos);
    CHECK(rejected.error().hint.find("key") != std::string::npos);

    auto odd = list_models(cfg, models_runtime([](const HttpRequest&) { return json_response(200, "<html>proxy</html>"); },
                                               {{"ANTHROPIC_API_KEY", "sk-ant-test-key-0000000000"}}));
    REQUIRE_FALSE(odd.ok());
    CHECK(odd.error().message.find("\"data\"") != std::string::npos);
}

TEST_CASE("list_models: OpenAI-compatible GET /models, sorted, with the key when there is one") {
    HttpRequest seen;
    auto rt = models_runtime(
        [&](const HttpRequest& req) {
            seen = req;
            return json_response(200, R"({"object":"list","data":[{"id":"openai/gpt-5","object":"model"},{"id":"anthropic/claude-opus-5"}]})");
        },
        {{"OPENROUTER_API_KEY", "sk-or-test-key-0000000000"}});
    auto models = list_models(default_config().providers["openrouter"], rt);
    REQUIRE(models);
    REQUIRE(models->size() == 2);
    CHECK((*models)[0].id == "anthropic/claude-opus-5");
    CHECK((*models)[1].id == "openai/gpt-5");
    CHECK((*models)[1].name.empty());
    CHECK(seen.method == "GET");
    CHECK(seen.url == "https://openrouter.ai/api/v1/models");
    CHECK(header_of(seen, "Authorization") == "Bearer sk-or-test-key-0000000000");

    // A local server needs no key and must fail fast when it is not running.
    HttpRequest local;
    auto ollama = list_models(default_config().providers["ollama"], models_runtime([&](const HttpRequest& req) {
        local = req;
        return json_response(200, R"({"data":[{"id":"llama3.2:latest"}]})");
    }));
    REQUIRE(ollama);
    CHECK((*ollama)[0].id == "llama3.2:latest");
    CHECK(local.url == "http://localhost:11434/v1/models");
    CHECK(header_of(local, "Authorization").empty());
    CHECK(local.connectTimeoutSeconds <= 5);
}

TEST_CASE("list_models: OpenAI-compatible errors teach") {
    int calls = 0;
    auto count = [&](const HttpRequest&) {
        ++calls;
        return json_response(200, "{}");
    };
    auto nokey = list_models(default_config().providers["openrouter"], models_runtime(count));
    REQUIRE_FALSE(nokey.ok());
    CHECK(nokey.error().hint.find("OPENROUTER_API_KEY") != std::string::npos);
    CHECK(calls == 0);

    HttpResponse refused;
    refused.error = "Could not connect to server";
    auto down = list_models(default_config().providers["lmstudio"], models_runtime([&](const HttpRequest&) { return refused; }));
    REQUIRE_FALSE(down.ok());
    CHECK(down.error().message.find("Could not connect") != std::string::npos);

    auto missing = list_models(default_config().providers["lmstudio"],
                               models_runtime([](const HttpRequest&) { return json_response(404, "not found"); }));
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().hint.find("type the model name") != std::string::npos);
}

TEST_CASE("list_models: Codex and generic CLIs cannot list their models") {
    auto codex = list_models(default_config().providers["codex"]);
    REQUIRE_FALSE(codex.ok());
    CHECK(codex.error().message.find("does not list its models") != std::string::npos);
    CHECK(codex.error().hint.find("Type the model name") != std::string::npos);
    ProviderConfig custom;
    custom.name = "mycli";
    custom.kind = ProviderKind::GenericCli;
    custom.command = "mycli";
    CHECK_FALSE(list_models(custom).ok());
}
