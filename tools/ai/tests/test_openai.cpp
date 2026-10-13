#include "fa/ai/openai.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

static ChatRequest req_with_tools() {
    ChatRequest r;
    r.model = "my-model";
    r.system = "sys";
    r.messages.push_back(Message::user("go"));
    ToolDef t;
    t.name = "scene_spawn";
    t.description = "Spawn";
    t.inputSchema = Json::parse(R"({"type":"object","properties":{"name":{"type":"string"}}})");
    r.tools = {t};
    return r;
}

TEST_CASE("openai request building") {
    ProviderConfig cfg = default_config().providers["openrouter"];
    ChatRequest r = req_with_tools();
    r.effort = "xhigh";
    Json b = openai::build_request(r, cfg);
    CHECK(b["model"] == "my-model");
    CHECK(b["messages"][0]["role"] == "system");
    CHECK(b["messages"][1]["content"] == "go");
    CHECK(b["tools"][0]["type"] == "function");
    CHECK(b["tools"][0]["function"]["name"] == "scene_spawn");
    CHECK(b["tools"][0]["function"]["parameters"]["type"] == "object");
    CHECK_FALSE(b.contains("reasoning_effort"));
    CHECK_FALSE(b.contains("stream"));
    cfg.sendReasoningEffort = true;
    CHECK(openai::build_request(r, cfg)["reasoning_effort"] == "high");
    r.stream = true;
    r.maxTokens = 500;
    Json s = openai::build_request(r, cfg);
    CHECK(s["stream"] == true);
    CHECK(s["stream_options"]["include_usage"] == true);
    CHECK(s["max_tokens"] == 500);
    ProviderConfig oa = default_config().providers["openai"];
    CHECK(openai::build_request(r, oa).contains("max_completion_tokens"));
}

TEST_CASE("openai tool results become role=tool messages, images in a follow-up user message") {
    ProviderConfig cfg = default_config().providers["groq"];
    ChatRequest r = req_with_tools();
    auto resp = openai::parse_response(fixture_json("openai_tool_calls.json"));
    REQUIRE(resp);
    r.messages.push_back(resp->message);
    ToolResult a{"call_1", "{\"n\":1}", false, {{"image/png", "QUJD"}}};
    ToolResult b{"call_2", "{\"error\":1}", true, {}};
    r.messages.push_back(Message::tool_results({a, b}));
    Json body = openai::build_request(r, cfg);
    const Json& msgs = body["messages"];
    REQUIRE(msgs.size() == 6);  // system, user, assistant, tool, tool, user(images)
    CHECK(msgs[2]["role"] == "assistant");
    CHECK(msgs[2]["tool_calls"].size() == 2);
    CHECK_FALSE(msgs[2].contains("annotations"));  // only the minimal native fields are replayed
    CHECK(msgs[3]["role"] == "tool");
    CHECK(msgs[3]["tool_call_id"] == "call_1");
    CHECK(msgs[4]["tool_call_id"] == "call_2");
    CHECK(msgs[5]["role"] == "user");
    CHECK(msgs[5]["content"][1]["type"] == "image_url");
}

TEST_CASE("openai response parsing") {
    auto r = openai::parse_response(fixture_json("openai_tool_calls.json"));
    REQUIRE(r);
    CHECK(r->stopReason == StopReason::ToolUse);
    REQUIRE(r->message.toolCalls.size() == 2);
    CHECK(r->message.toolCalls[0].input["limit"] == 3);
    CHECK(r->message.toolCalls[1].input.is_object());
    CHECK(r->usage.inputTokens == 400);
    CHECK(r->usage.cacheReadTokens == 100);
    CHECK(r->usage.outputTokens == 40);

    Json bad = fixture_json("openai_tool_calls.json");
    bad["choices"][0]["message"]["tool_calls"][0]["function"]["arguments"] = "{not json";
    auto rb = openai::parse_response(bad);
    REQUIRE(rb);
    CHECK_FALSE(rb->message.toolCalls[0].inputError.empty());

    Json len = Json::parse(R"({"choices":[{"message":{"role":"assistant","content":"abc"},"finish_reason":"length"}]})");
    CHECK(openai::parse_response(len)->stopReason == StopReason::MaxTokens);
    Json filt = Json::parse(R"({"choices":[{"message":{"role":"assistant","content":""},"finish_reason":"content_filter"}]})");
    CHECK(openai::parse_response(filt)->stopReason == StopReason::Refusal);
}

TEST_CASE("openai SSE stream equals non-streaming result") {
    std::string sse = fixture("openai_stream.sse");
    std::string text;
    ChatHooks hooks;
    hooks.onText = [&](std::string_view t) { text += t; };
    openai::StreamAssembler as(hooks);
    for (std::size_t i = 0; i < sse.size(); i += 11) as.feed(std::string_view(sse).substr(i, 11));
    as.finish();
    REQUIRE(as.done());
    auto r = openai::parse_response(as.body());
    REQUIRE(r);
    CHECK(text == "Checking now.");
    CHECK(r->message.text == "Checking now.");
    REQUIRE(r->message.toolCalls.size() == 2);
    CHECK(r->message.toolCalls[0].name == "scene_list_entities");
    CHECK(r->message.toolCalls[0].input["limit"] == 3);
    CHECK(r->message.toolCalls[1].id == "call_2");
    CHECK(r->stopReason == StopReason::ToolUse);
    CHECK(r->usage.inputTokens == 500);
    CHECK(r->usage.outputTokens == 40);
}

TEST_CASE("openai provider: URL, bearer header, missing key, local presets need none") {
    ProviderConfig cfg = default_config().providers["openrouter"];
    CHECK(openai::chat_completions_url(cfg) == "https://openrouter.ai/api/v1/chat/completions");
    CHECK(openai::chat_completions_url(default_config().providers["ollama"]) == "http://localhost:11434/v1/chat/completions");
    CHECK(openai::chat_completions_url(default_config().providers["lmstudio"]) == "http://localhost:1234/v1/chat/completions");
    CHECK(openai::chat_completions_url(default_config().providers["gemini"]) ==
          "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions");

    HttpRequest seen;
    ProviderRuntime rt;
    rt.transport = [&](const HttpRequest& q) {
        seen = q;
        HttpResponse r;
        r.status = 200;
        r.body = fixture("openai_tool_calls.json");
        return r;
    };
    rt.sleep = [](double) {};
    rt.env = fake_env({{"OPENROUTER_API_KEY", "or-key"}});
    auto p = openai::make_provider(cfg, rt);
    auto resp = p->chat(req_with_tools(), {}, nullptr);
    REQUIRE(resp);
    std::string auth;
    for (auto& [k, v] : seen.headers) if (k == "Authorization") auth = v;
    CHECK(auth == "Bearer or-key");

    rt.env = fake_env({});
    auto nokey = openai::make_provider(cfg, rt)->chat(req_with_tools(), {}, nullptr);
    REQUIRE_FALSE(nokey.ok());
    CHECK(nokey.error().hint.find("OPENROUTER_API_KEY") != std::string::npos);

    seen = {};
    auto local = openai::make_provider(default_config().providers["ollama"], rt)->chat(req_with_tools(), {}, nullptr);
    REQUIRE(local);
    for (auto& [k, v] : seen.headers) CHECK(k != "Authorization");
}
