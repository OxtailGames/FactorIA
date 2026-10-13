#include "fa/ai/anthropic.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

static ChatRequest base_request(const std::string& model, const std::string& effort) {
    ChatRequest r;
    r.model = model;
    r.effort = effort;
    r.system = "You are a game engineer.";
    r.messages.push_back(Message::user("Make a game."));
    ToolDef b;
    b.name = "scene_spawn";
    b.description = "Spawn.";
    b.inputSchema = Json::parse(R"({"type":"object","properties":{}})");
    ToolDef a = b;
    a.name = "game_step";
    r.tools = {b, a};  // deliberately unsorted
    return r;
}

TEST_CASE("anthropic request: opus has effort, cache_control, fallbacks; no forbidden fields") {
    Json body = anthropic::build_request(base_request("claude-opus-5-5", "xhigh"));
    CHECK(body["model"] == "claude-opus-5-5");
    CHECK(body["output_config"]["effort"] == "xhigh");
    CHECK(body["cache_control"]["type"] == "ephemeral");
    CHECK(body["fallbacks"] == "default");
    CHECK(body["max_tokens"] == 16000);
    CHECK(body["system"].is_array());
    CHECK(body["system"][0]["text"] == "You are a game engineer.");
    for (const char* k : {"thinking", "temperature", "top_p", "tool_choice", "stream"}) CHECK_FALSE(body.contains(k));
    // deterministic tool order
    CHECK(body["tools"][0]["name"] == "game_step");
    CHECK(body["tools"][1]["name"] == "scene_spawn");
    CHECK(body["tools"][0].contains("input_schema"));
    // byte-stable
    CHECK(body.dump() == anthropic::build_request(base_request("claude-opus-5-5", "xhigh")).dump());
}

TEST_CASE("anthropic request: sonnet fallbacks, haiku none, streaming max_tokens") {
    CHECK(anthropic::build_request(base_request("claude-sonnet-5-5", "medium"))["fallbacks"] == "default");
    Json haiku = anthropic::build_request(base_request("claude-haiku-5-5", "max"));
    CHECK_FALSE(haiku.contains("fallbacks"));
    CHECK(haiku["output_config"]["effort"] == "max");
    ChatRequest s = base_request("claude-sonnet-5-5", "medium");
    s.stream = true;
    Json sb = anthropic::build_request(s);
    CHECK(sb["max_tokens"] == 64000);
    CHECK(sb["stream"] == true);
    s.maxTokens = 1234;
    CHECK(anthropic::build_request(s)["max_tokens"] == 1234);
}

TEST_CASE("anthropic headers") {
    ProviderConfig cfg;
    cfg.name = "anthropic";
    auto find = [](const auto& h, const std::string& k) -> std::string {
        for (auto& [a, b] : h) if (a == k) return b;
        return "<none>";
    };
    ChatRequest opus = base_request("claude-opus-5-5", "high");
    auto h = anthropic::build_headers(opus, {"sk-test", ""}, cfg);
    CHECK(find(h, "x-api-key") == "sk-test");
    CHECK(find(h, "anthropic-version") == "2023-06-01");
    CHECK(find(h, "content-type") == "application/json");
    CHECK(find(h, "anthropic-beta") == "server-side-fallback-2026-07-01");
    CHECK(find(h, "Authorization") == "<none>");

    auto ht = anthropic::build_headers(opus, {"", "tok123"}, cfg);
    CHECK(find(ht, "Authorization") == "Bearer tok123");
    CHECK(find(ht, "x-api-key") == "<none>");
    CHECK(find(ht, "anthropic-beta") == "oauth-2025-04-20,server-side-fallback-2026-07-01");

    auto hh = anthropic::build_headers(base_request("claude-haiku-5-5", "max"), {"", "tok"}, cfg);
    CHECK(find(hh, "anthropic-beta") == "oauth-2025-04-20");
    auto hk = anthropic::build_headers(base_request("claude-haiku-5-5", "max"), {"k", ""}, cfg);
    CHECK(find(hk, "anthropic-beta") == "<none>");
}

TEST_CASE("anthropic request: history is replayed verbatim; tool results are one user message") {
    ChatRequest r = base_request("claude-sonnet-5-5", "medium");
    Json fixtureBody = fixture_json("anthropic_tool_use.json");
    auto resp = anthropic::parse_response(fixtureBody);
    REQUIRE(resp);
    r.messages.push_back(resp->message);
    ToolResult ok{"toolu_01", "{\"count\":2}", false, {}};
    ToolResult bad{"toolu_02", "{\"code\":\"failed\"}", true, {}};
    r.messages.push_back(Message::tool_results({ok, bad}));
    Json body = anthropic::build_request(r);
    REQUIRE(body["messages"].size() == 3);
    // assistant content identical (thinking block with signature included)
    CHECK(body["messages"][1]["content"] == fixtureBody["content"]);
    const Json& user = body["messages"][2];
    CHECK(user["role"] == "user");
    REQUIRE(user["content"].size() == 2);
    CHECK(user["content"][0]["type"] == "tool_result");
    CHECK(user["content"][0]["tool_use_id"] == "toolu_01");
    CHECK_FALSE(user["content"][0].contains("is_error"));
    CHECK(user["content"][1]["tool_use_id"] == "toolu_02");
    CHECK(user["content"][1]["is_error"] == true);
}

TEST_CASE("anthropic request: images inside tool results") {
    ChatRequest r = base_request("claude-sonnet-5-5", "medium");
    ToolResult shot{"t1", "{\"w\":4}", false, {{"image/png", "QUJD"}}};
    r.messages.push_back(Message::tool_results({shot}));
    Json body = anthropic::build_request(r);
    const Json& c = body["messages"][1]["content"][0]["content"];
    CHECK(c[0]["type"] == "text");
    CHECK(c[1]["type"] == "image");
    CHECK(c[1]["source"]["media_type"] == "image/png");
    CHECK(c[1]["source"]["data"] == "QUJD");
}

TEST_CASE("anthropic response parsing (fixture)") {
    auto r = anthropic::parse_response(fixture_json("anthropic_tool_use.json"));
    REQUIRE(r);
    CHECK(r->stopReason == StopReason::ToolUse);
    CHECK(r->message.text == "Let me inspect the scene.");
    REQUIRE(r->message.toolCalls.size() == 2);
    CHECK(r->message.toolCalls[0].id == "toolu_01");
    CHECK(r->message.toolCalls[0].name == "scene_list_entities");
    CHECK(r->message.toolCalls[0].input["limit"] == 5);  // parsed as JSON
    CHECK(r->message.toolCalls[0].input["filter"] == "enemy");
    CHECK(r->message.raw.size() == 4);  // full content incl. thinking
    CHECK(r->usage.inputTokens == 1200);
    CHECK(r->usage.outputTokens == 85);
    CHECK(r->usage.cacheCreationTokens == 300);
    CHECK(r->usage.cacheReadTokens == 4000);
    CHECK(r->model == "claude-sonnet-5-5");
}

TEST_CASE("anthropic refusal reads stop_details only for refusals") {
    auto r = anthropic::parse_response(fixture_json("anthropic_refusal.json"));
    REQUIRE(r);
    CHECK(r->stopReason == StopReason::Refusal);
    CHECK(r->refusalCategory == "cyber");
    CHECK(r->refusalExplanation.find("malware") != std::string::npos);
    Json other = fixture_json("anthropic_tool_use.json");
    other["stop_details"] = Json::object({{"category", "x"}});
    auto o = anthropic::parse_response(other);
    REQUIRE(o);
    CHECK(o->refusalCategory.empty());
}

TEST_CASE("anthropic stop reasons map") {
    for (auto [raw, expected] : std::vector<std::pair<std::string, StopReason>>{
             {"end_turn", StopReason::EndTurn}, {"max_tokens", StopReason::MaxTokens}, {"pause_turn", StopReason::PauseTurn},
             {"tool_use", StopReason::ToolUse}, {"refusal", StopReason::Refusal}}) {
        Json b = Json::object({{"content", Json::array()}, {"stop_reason", raw}});
        auto r = anthropic::parse_response(b);
        REQUIRE(r);
        CHECK(r->stopReason == expected);
    }
    auto err = anthropic::parse_response(Json::parse(R"({"type":"error","error":{"type":"invalid_request_error","message":"bad"}})"));
    CHECK_FALSE(err.ok());
}

TEST_CASE("anthropic SSE reconstructs the same message as non-streaming") {
    std::string sse = fixture("anthropic_stream_tool_use.sse");
    std::string text, thinking, toolStart;
    ChatHooks hooks;
    hooks.onText = [&](std::string_view t) { text += t; };
    hooks.onThinking = [&](std::string_view t) { thinking += t; };
    hooks.onToolUseStart = [&](const std::string& n) { toolStart += n + ";"; };
    for (std::size_t chunk : {std::size_t(7), std::size_t(64), sse.size()}) {
        text.clear(); thinking.clear(); toolStart.clear();
        anthropic::StreamAssembler as(hooks);
        for (std::size_t i = 0; i < sse.size(); i += chunk) as.feed(std::string_view(sse).substr(i, chunk));
        as.finish();
        REQUIRE(as.done());
        REQUIRE_FALSE(as.has_error());
        auto streamed = anthropic::parse_response(as.message());
        auto direct = anthropic::parse_response(fixture_json("anthropic_tool_use.json"));
        REQUIRE(streamed);
        REQUIRE(direct);
        CHECK(streamed->message.raw == direct->message.raw);
        CHECK(streamed->message.text == direct->message.text);
        CHECK(streamed->stopReason == direct->stopReason);
        CHECK(streamed->usage.inputTokens == direct->usage.inputTokens);
        CHECK(streamed->usage.outputTokens == direct->usage.outputTokens);
        CHECK(streamed->usage.cacheReadTokens == direct->usage.cacheReadTokens);
        CHECK(streamed->usage.cacheCreationTokens == direct->usage.cacheCreationTokens);
        CHECK(text == "Let me inspect the scene.");
        CHECK(thinking == "I should look at the scene first.");
        CHECK(toolStart == "scene_list_entities;project_validate;");
    }
}

TEST_CASE("anthropic SSE error event") {
    anthropic::StreamAssembler as;
    as.feed(fixture("anthropic_stream_error.sse"));
    as.finish();
    CHECK(as.has_error());
    CHECK(as.error_type() == "overloaded_error");
}

// ---- Provider over a fake transport -------------------------------------

static ProviderRuntime fake_runtime(std::function<HttpResponse(const HttpRequest&)> t, std::vector<double>* sleeps = nullptr) {
    ProviderRuntime rt;
    rt.transport = std::move(t);
    rt.env = fake_env({{"ANTHROPIC_API_KEY", "sk-ant-test-key-0000000000"}});
    rt.sleep = [sleeps](double s) { if (sleeps) sleeps->push_back(s); };
    rt.antToken = [] { return std::string("ant-token"); };
    return rt;
}

TEST_CASE("anthropic provider: request wiring, retries honour retry-after") {
    ProviderConfig cfg = default_config().providers["anthropic"];
    int calls = 0;
    std::vector<double> sleeps;
    HttpRequest seen;
    auto rt = fake_runtime(
        [&](const HttpRequest& req) {
            ++calls;
            seen = req;
            HttpResponse r;
            if (calls == 1) { r.status = 429; r.headers["retry-after"] = "7"; r.body = R"({"type":"error","error":{"type":"rate_limit_error","message":"slow down"}})"; return r; }
            if (calls == 2) { r.status = 529; r.body = R"({"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}})"; return r; }
            r.status = 200;
            r.body = fixture("anthropic_tool_use.json");
            return r;
        },
        &sleeps);
    auto p = anthropic::make_provider(cfg, rt);
    ChatRequest req = base_request("claude-opus-5-5", "xhigh");
    auto resp = p->chat(req, {}, nullptr);
    REQUIRE(resp);
    CHECK(calls == 3);
    REQUIRE(sleeps.size() == 2);
    CHECK(sleeps[0] == 7.0);   // retry-after
    CHECK(sleeps[1] == 2.0);   // exponential backoff
    CHECK(seen.url == "https://api.anthropic.com/v1/messages");
    CHECK(seen.method == "POST");
    bool hasKey = false;
    for (auto& [k, v] : seen.headers) if (k == "x-api-key" && v == "sk-ant-test-key-0000000000") hasKey = true;
    CHECK(hasKey);
    Json sent = Json::parse(seen.body);
    CHECK(sent["output_config"]["effort"] == "xhigh");
    CHECK(resp->message.toolCalls.size() == 2);
}

TEST_CASE("anthropic provider: errors teach; no retry on 400") {
    ProviderConfig cfg = default_config().providers["anthropic"];
    int calls = 0;
    auto rt = fake_runtime([&](const HttpRequest&) {
        ++calls;
        HttpResponse r;
        r.status = 400;
        r.body = R"({"type":"error","error":{"type":"invalid_request_error","message":"max_tokens too large"}})";
        return r;
    });
    auto p = anthropic::make_provider(cfg, rt);
    auto resp = p->chat(base_request("claude-sonnet-5-5", "medium"), {}, nullptr);
    CHECK(calls == 1);
    REQUIRE_FALSE(resp.ok());
    CHECK(resp.error().message.find("invalid_request_error") != std::string::npos);
    CHECK(resp.error().message.find("max_tokens too large") != std::string::npos);
}

TEST_CASE("anthropic provider: ant CLI token fallback and missing credentials") {
    ProviderConfig cfg = default_config().providers["anthropic"];
    HttpRequest seen;
    auto rt = fake_runtime([&](const HttpRequest& req) {
        seen = req;
        HttpResponse r;
        r.status = 200;
        r.body = fixture("anthropic_refusal.json");
        return r;
    });
    rt.env = fake_env({});
    auto p = anthropic::make_provider(cfg, rt);
    auto resp = p->chat(base_request("claude-opus-5-5", "high"), {}, nullptr);
    REQUIRE(resp);
    std::string auth, beta;
    for (auto& [k, v] : seen.headers) { if (k == "Authorization") auth = v; if (k == "anthropic-beta") beta = v; }
    CHECK(auth == "Bearer ant-token");
    CHECK(beta.find("oauth-2025-04-20") != std::string::npos);

    rt.antToken = [] { return std::string(); };
    auto p2 = anthropic::make_provider(cfg, rt);
    auto bad = p2->chat(base_request("claude-opus-5-5", "high"), {}, nullptr);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().hint.find("ANTHROPIC_API_KEY") != std::string::npos);
    CHECK(bad.error().hint.find("claude-code") != std::string::npos);
}

TEST_CASE("anthropic provider: streaming through the transport") {
    ProviderConfig cfg = default_config().providers["anthropic"];
    std::string sse = fixture("anthropic_stream_tool_use.sse");
    Json sentBody;
    auto rt = fake_runtime([&](const HttpRequest& req) {
        sentBody = Json::parse(req.body);
        REQUIRE(req.onData);
        for (std::size_t i = 0; i < sse.size(); i += 33) req.onData(std::string_view(sse).substr(i, 33));
        HttpResponse r;
        r.status = 200;
        return r;
    });
    auto p = anthropic::make_provider(cfg, rt);
    ChatRequest req = base_request("claude-sonnet-5-5", "medium");
    req.stream = true;
    std::string text;
    ChatHooks hooks;
    hooks.onText = [&](std::string_view t) { text += t; };
    auto resp = p->chat(req, hooks, nullptr);
    REQUIRE(resp);
    CHECK(sentBody["stream"] == true);
    CHECK(sentBody["max_tokens"] == 64000);
    CHECK(text == "Let me inspect the scene.");
    CHECK(resp->message.toolCalls.size() == 2);
    CHECK(resp->message.toolCalls[0].input["limit"] == 5);
}

TEST_CASE("pricing and cost estimates") {
    Usage u;
    u.inputTokens = 1'000'000;
    u.outputTokens = 100'000;
    u.cacheReadTokens = 1'000'000;
    CHECK(estimate_cost(u, builtin_pricing("claude-opus-5-5")) == doctest::Approx(4.0 + 2.0 + 0.2));
    CHECK(estimate_cost(u, builtin_pricing("claude-sonnet-5-5")) == doctest::Approx(2.0 + 1.0 + 0.2));
    CHECK(estimate_cost(u, builtin_pricing("claude-haiku-5-5")) == doctest::Approx(0.1 + 0.05 + 0.01));
    CHECK(estimate_cost(u, builtin_pricing("gpt-whatever")) == 0.0);
}
