// Images in messages, usage / plan-limit events, and conversations that continue across messages. Everything here is
// pure (no child process), so it runs on every OS; the tests that spawn the fake CLIs are in test_cli_agent.cpp.
#include <algorithm>
#include <memory>

#include "fa/ai/cli_agent.h"
#include "fa/ai/openai.h"
#include "fa/core/strings.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {

// A 1x1 PNG.
constexpr const char* kPngBase64 =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==";

std::string write_png(const std::filesystem::path& file) {
    auto bytes = fa::base64_decode(kPngBase64);
    std::ofstream(file, std::ios::binary).write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
    return file.string();
}

const AgentEvent* find_usage(const std::vector<AgentEvent>& events, const std::function<bool(const AgentEvent&)>& pred) {
    for (const auto& e : events) {
        if (e.type == AgentEvent::Type::Usage && pred(e)) return &e;
    }
    return nullptr;
}

}  // namespace

TEST_CASE("argv template: {session} adds --resume, an empty one removes it") {
    CliRunRequest req{"do it", "sonnet", "/proj dir"};
    auto first = expand_cli_argv(default_cli_argv(ProviderKind::ClaudeCode), req, "/proj dir/mcp.json", "factoria");
    CHECK(first == std::vector<std::string>{"-p", "--output-format", "stream-json", "--input-format", "stream-json", "--verbose",
                                            "--model", "sonnet", "--mcp-config", "/proj dir/mcp.json", "--allowedTools",
                                            "mcp__factoria", "--permission-mode", "acceptEdits"});

    req.sessionId = "abc-123";
    auto follow = expand_cli_argv(default_cli_argv(ProviderKind::ClaudeCode), req, "/proj dir/mcp.json", "factoria");
    CHECK(follow == std::vector<std::string>{"-p", "--output-format", "stream-json", "--input-format", "stream-json", "--verbose",
                                             "--model", "sonnet", "--resume", "abc-123", "--mcp-config", "/proj dir/mcp.json",
                                             "--allowedTools", "mcp__factoria", "--permission-mode", "acceptEdits"});

    // user templates: an element with an empty {session} goes away, and so does a bare flag right before it
    CliRunRequest none{"x", "", "/p"};
    CHECK(expand_cli_argv({"run", "--session={session}", "-r", "{session}", "--keep"}, none, "", "f") ==
          std::vector<std::string>{"run", "--keep"});

    CHECK(cli_supports_resume(default_config().providers["claude-code"]));
    CHECK_FALSE(cli_supports_resume(default_config().providers["codex"]));  // a fresh Codex session per message
    ProviderConfig custom = default_config().providers["claude-code"];
    custom.argv = {"-p", "--output-format", "stream-json"};
    CHECK_FALSE(cli_supports_resume(custom));

    // the rest of the placeholders keep working
    auto c = expand_cli_argv(default_cli_argv(ProviderKind::Codex), req, "", "factoria");
    CHECK(c == std::vector<std::string>{"exec", "--json", "-m", "sonnet", "-c", "mcp_servers.factoria.command=\"factoria\"", "-c",
                                        "mcp_servers.factoria.args=[\"mcp\",\"--project\",\"/proj dir\"]", "-"});
    CliRunRequest nomodel{"x", "", "/p"};
    auto d = expand_cli_argv(default_cli_argv(ProviderKind::Codex), nomodel, "", "factoria");
    CHECK(std::find(d.begin(), d.end(), "-m") == d.end());
    CHECK(d.size() == 7);
    CHECK(expand_cli_argv({"--ask", "{prompt}", "--dir", "{project}", "--m={model}"}, req, "", "f") ==
          std::vector<std::string>{"--ask", "do it", "--dir", "/proj dir", "--m=sonnet"});
}

TEST_CASE("stream-json stdin: one JSON line with the text and the images; the text fallback names the files") {
    const std::string line = make_stream_json_input("Look at \"this\"\nplease", {{"image/png", kPngBase64}, {"image/jpeg", "QUJD"}});
    CHECK(line.find('\n') == std::string::npos);  // ONE line, whatever the text holds
    Json j = Json::parse(line);
    CHECK(j["type"] == "user");
    CHECK(j["message"]["role"] == "user");
    const Json& content = j["message"]["content"];
    REQUIRE(content.size() == 3);
    // (raw strings stay out of CHECK(...): MSVC mangles them in macro arguments)
    const Json expectedText = Json::parse(R"({"type":"text","text":"Look at \"this\"\nplease"})");
    CHECK(content[0] == expectedText);
    CHECK(content[1]["type"] == "image");
    const Json expectedSource = Json::parse(std::string(R"({"type":"base64","media_type":"image/png","data":")") + kPngBase64 + "\"}");
    CHECK(content[1]["source"] == expectedSource);
    CHECK(content[2]["source"]["media_type"] == "image/jpeg");
    CHECK(Json::parse(make_stream_json_input("just text", {}))["message"]["content"].size() == 1);

    CHECK(prompt_with_image_paths("Task", {"/a/b.png", "/c/d.jpg"}) == "Task\n\nAttached images (read them): /a/b.png, /c/d.jpg");
    CHECK(prompt_with_image_paths("Task", {}) == "Task");

    CHECK(argv_wants_stream_json_input({"-p", "--input-format", "stream-json", "--verbose"}));
    CHECK(argv_wants_stream_json_input({"--input-format=stream-json"}));
    CHECK_FALSE(argv_wants_stream_json_input({"--input-format", "text"}));
    CHECK_FALSE(argv_wants_stream_json_input({"--output-format", "stream-json"}));
    CHECK_FALSE(argv_wants_stream_json_input({"--input-format"}));
}

TEST_CASE("image helpers: accepted types and loading") {
    CHECK(image_media_type_for_path("a/b/shot.PNG") == "image/png");
    CHECK(image_media_type_for_path("x.jpg") == "image/jpeg");
    CHECK(image_media_type_for_path("x.JPEG") == "image/jpeg");
    CHECK(image_media_type_for_path("x.gif") == "image/gif");
    CHECK(image_media_type_for_path("x.webp") == "image/webp");
    CHECK(image_media_type_for_path("x.bmp").empty());
    CHECK(image_media_type_for_path("noextension").empty());
    CHECK(image_media_type_for_path("archive.png.zip").empty());

    TempDir dir;
    auto img = load_image_data(write_png(dir.path / "pic.png"));
    REQUIRE(img);
    CHECK(img->mediaType == "image/png");
    CHECK(img->base64 == kPngBase64);

    auto missing = load_image_data((dir.path / "gone.png").string());
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().message.find("gone.png") != std::string::npos);
    auto wrongType = load_image_data((dir.path / "notes.txt").string());
    REQUIRE_FALSE(wrongType.ok());
    CHECK(wrongType.error().hint.find(".webp") != std::string::npos);
}

TEST_CASE("claude stream: plan windows, context tokens and window size") {
    CliStreamParser p(ProviderKind::ClaudeCode);
    std::vector<AgentEvent> ev;
    p.feed_line(R"({"type":"system","subtype":"init","session_id":"s-1","model":"claude-haiku-5-5"})", ev);
    ev.clear();

    // context = input + cache creation + cache read of the model's last call
    p.feed_line(R"({"type":"assistant","message":{"content":[{"type":"text","text":"OK"}],"usage":{"input_tokens":2,"cache_creation_input_tokens":19156,"cache_read_input_tokens":27810,"output_tokens":5}},"parent_tool_use_id":null})", ev);
    const AgentEvent* ctx = find_usage(ev, [](const AgentEvent& e) { return e.contextTokens > 0; });
    REQUIRE(ctx);
    CHECK(ctx->contextTokens == 46968);
    CHECK(ctx->limits.empty());
    CHECK(ctx->contextWindow == 0);  // only the final result says
    ev.clear();
    // a sub-agent's call has its own context: ignored
    p.feed_line(R"({"type":"assistant","message":{"content":[],"usage":{"input_tokens":9,"cache_read_input_tokens":99999}},"parent_tool_use_id":"toolu_1"})", ev);
    CHECK_FALSE(find_usage(ev, [](const AgentEvent&) { return true; }));
    ev.clear();

    // every entry of unifiedWindows is taken, whatever its name
    p.feed_line(R"({"type":"rate_limit_event","rate_limit_info":{"status":"allowed","resetsAt":1792021800,"rateLimitType":"five_hour","overageStatus":"rejected","isUsingOverage":false,"unifiedWindows":{"five_hour":{"utilization":0.06,"resetsAt":1792021800},"seven_day":{"utilization":0.07,"resetsAt":1792584000},"seven_day_opus":{"utilization":0.5,"resetsAt":1792584001}}},"session_id":"s-1"})", ev);
    const AgentEvent* lim = find_usage(ev, [](const AgentEvent& e) { return !e.limits.empty(); });
    REQUIRE(lim);
    REQUIRE(lim->limits.size() == 3);
    CHECK(lim->limits[0].name == "five_hour");
    CHECK(lim->limits[0].usedFraction == doctest::Approx(0.06));
    CHECK(lim->limits[0].resetsAt == 1792021800);
    CHECK(lim->limits[1].name == "seven_day");
    CHECK(lim->limits[1].usedFraction == doctest::Approx(0.07));
    CHECK(lim->limits[2].name == "seven_day_opus");
    CHECK(lim->contextTokens == 46968);  // the snapshot keeps what is known
    ev.clear();
    // a newer event carries only the windows it reports (the consumer merges them by name: merge_limit_windows)
    p.feed_line(R"({"type":"rate_limit_event","rate_limit_info":{"unifiedWindows":{"five_hour":{"utilization":0.1,"resetsAt":1792021800}}}})", ev);
    const AgentEvent* newer = find_usage(ev, [](const AgentEvent& e) { return !e.limits.empty(); });
    REQUIRE(newer);
    REQUIRE(newer->limits.size() == 1);
    CHECK(newer->limits[0].usedFraction == doctest::Approx(0.1));
    ev.clear();
    // old shape: only the window that applies, with no utilization
    CliStreamParser old(ProviderKind::ClaudeCode);
    old.feed_line(R"({"type":"rate_limit_event","rate_limit_info":{"status":"allowed","resetsAt":1792021800,"rateLimitType":"five_hour"}})", ev);
    const AgentEvent* oldLim = find_usage(ev, [](const AgentEvent& e) { return !e.limits.empty(); });
    REQUIRE(oldLim);
    REQUIRE(oldLim->limits.size() == 1);
    CHECK(oldLim->limits[0].name == "five_hour");
    CHECK(oldLim->limits[0].usedFraction < 0);
    CHECK(oldLim->limits[0].resetsAt == 1792021800);
    ev.clear();

    // the context window arrives with the result (the model that used the most tokens is the main one)
    p.feed_line(R"({"type":"result","subtype":"success","is_error":false,"result":"OK","total_cost_usd":0.004112,"num_turns":1,"session_id":"s-1","usage":{"input_tokens":2,"output_tokens":5,"cache_creation_input_tokens":19156,"cache_read_input_tokens":27810},"modelUsage":{"claude-haiku-5-5":{"inputTokens":2,"outputTokens":5,"cacheReadInputTokens":27810,"cacheCreationInputTokens":19156,"costUSD":0.004112,"contextWindow":1000000,"maxOutputTokens":128000},"claude-tiny":{"inputTokens":1,"outputTokens":1,"contextWindow":200000}}})", ev);
    CHECK(p.cost_usd() == doctest::Approx(0.004112));
    const AgentEvent* done = find_usage(ev, [](const AgentEvent& e) { return e.contextWindow > 0; });
    REQUIRE(done);
    CHECK(done->contextWindow == 1000000);
    CHECK(done->contextTokens == 46968);
    CHECK(done->usage.cacheReadTokens == 27810);
    CHECK(done->costUsd == doctest::Approx(0.004112));
}

TEST_CASE("claude stream: an error result without `result` explains itself through `errors`") {
    CliStreamParser p(ProviderKind::ClaudeCode);
    std::vector<AgentEvent> ev;
    p.feed_line(R"({"type":"result","subtype":"error_during_execution","is_error":true,"num_turns":0,"session_id":"x","total_cost_usd":0,"usage":{},"modelUsage":{},"errors":["No conversation found with session ID: x"]})", ev);
    CHECK(p.result_is_error());
    CHECK(p.error_text() == "No conversation found with session ID: x");
}

TEST_CASE("codex rate limits: windows are named by their length") {
    const Json rl = Json::parse(R"({"primary":{"used_percent":6.5,"window_minutes":300,"resets_in_seconds":3600},
        "secondary":{"used_percent":12,"window_minutes":10080,"resets_at":1792584000}})");
    auto w = parse_codex_rate_limits(rl, 1000);
    REQUIRE(w.size() == 2);
    CHECK(w[0].name == "five_hour");
    CHECK(w[0].usedFraction == doctest::Approx(0.065));
    CHECK(w[0].resetsAt == 4600);  // now + resets_in_seconds
    CHECK(w[1].name == "seven_day");
    CHECK(w[1].usedFraction == doctest::Approx(0.12));
    CHECK(w[1].resetsAt == 1792584000);

    auto other = parse_codex_rate_limits(Json::parse(R"({"primary":{"used_percent":1,"window_minutes":60},"secondary":{"window_minutes":1440},"tertiary":{"used_percent":250}})"), 0);
    REQUIRE(other.size() == 3);
    CHECK(other[0].name == "primary");  // other lengths than 5 h / 7 days: the key names the window
    CHECK(other[1].name == "secondary");
    CHECK(other[1].usedFraction < 0);  // no used_percent
    CHECK(other[2].name == "tertiary");  // no window_minutes: the key stays
    CHECK(other[2].usedFraction == 1.0);  // clamped
    CHECK(parse_codex_rate_limits(Json::parse("[]"), 0).empty());

    // on the stream: the legacy token_count event, and the same object on newer events
    CliStreamParser legacy(ProviderKind::Codex);
    std::vector<AgentEvent> ev;
    legacy.feed_line(R"({"id":"1","msg":{"type":"token_count","input_tokens":10,"output_tokens":2,"rate_limits":{"primary":{"used_percent":3,"window_minutes":300,"resets_at":1792021800}}}})", ev);
    const AgentEvent* lim = find_usage(ev, [](const AgentEvent& e) { return !e.limits.empty(); });
    REQUIRE(lim);
    CHECK(lim->limits[0].name == "five_hour");
    CHECK(lim->limits[0].usedFraction == doctest::Approx(0.03));
    CHECK(lim->limits.size() == 1);

    for (const char* line : {R"({"type":"turn.completed","usage":{"input_tokens":5,"output_tokens":1},"rate_limits":{"secondary":{"used_percent":40,"window_minutes":10080,"resets_at":1792584000}}})",
                             R"({"type":"event_msg","payload":{"type":"token_count","rate_limits":{"secondary":{"used_percent":40,"window_minutes":10080,"resets_at":1792584000}}}})"}) {
        CliStreamParser modern(ProviderKind::Codex);
        ev.clear();
        modern.feed_line(line, ev);
        const AgentEvent* m = find_usage(ev, [](const AgentEvent& e) { return !e.limits.empty(); });
        REQUIRE(m);
        REQUIRE(m->limits.size() == 1);
        CHECK(m->limits[0].name == "seven_day");
        CHECK(m->limits[0].usedFraction == doctest::Approx(0.4));
    }
}

TEST_CASE("merge_limit_windows replaces by name and appends new windows") {
    std::vector<LimitWindow> have{{"five_hour", 0.1, 5}, {"seven_day", 0.2, 6}};
    merge_limit_windows(have, {{"seven_day", 0.3, 9}, {"seven_day_opus", 0.4, 10}});
    REQUIRE(have.size() == 3);
    CHECK(have[0].usedFraction == 0.1);
    CHECK(have[1].usedFraction == 0.3);
    CHECK(have[1].resetsAt == 9);
    CHECK(have[2].name == "seven_day_opus");
}

TEST_CASE("user images are serialised for Anthropic and OpenAI") {
    ChatRequest r;
    r.model = "claude-opus-5-5";
    r.messages = {Message::user("what is this?", {{"image/png", "QUJD"}, {"image/webp", "REVG"}}), Message::user("plain")};

    Json a = anthropic::build_request(r);
    const Json& parts = a["messages"][0]["content"];
    REQUIRE(parts.is_array());
    REQUIRE(parts.size() == 3);
    const Json imageBlock = Json::parse(R"({"type":"image","source":{"type":"base64","media_type":"image/png","data":"QUJD"}})");
    const Json textBlock = Json::parse(R"({"type":"text","text":"what is this?"})");
    CHECK(parts[0] == imageBlock);
    CHECK(parts[1]["source"]["media_type"] == "image/webp");
    CHECK(parts[2] == textBlock);  // the question follows the pictures
    CHECK(a["messages"][1]["content"] == "plain");  // no image: still a plain string

    ProviderConfig cfg;
    Json o = openai::build_request(r, cfg);
    const Json& op = o["messages"][0]["content"];
    REQUIRE(op.is_array());
    REQUIRE(op.size() == 3);
    const Json urlPart = Json::parse(R"({"type":"image_url","image_url":{"url":"data:image/png;base64,QUJD"}})");
    CHECK(op[0] == textBlock);
    CHECK(op[1] == urlPart);
    CHECK(op[2]["image_url"]["url"] == "data:image/webp;base64,REVG");
    CHECK(o["messages"][1]["content"] == "plain");
}

TEST_CASE("message JSON: the saved form keeps the history but not the base64 pictures") {
    Message user = Message::user("see this", {{"image/png", "QUJD"}});
    Message assistant;
    assistant.role = Role::Assistant;
    assistant.text = "I see";
    assistant.raw = Json::array({Json::object({{"type", "thinking"}, {"signature", "sig"}}), Json::object({{"type", "text"}, {"text", "I see"}})});
    ToolCall tc;
    tc.id = "t1";
    tc.name = "scene_list_entities";
    tc.input = Json::object({{"limit", 3}});
    assistant.toolCalls.push_back(tc);
    ToolResult tr;
    tr.toolUseId = "t1";
    tr.content = "{\"count\":2}";
    tr.isError = true;
    tr.images.push_back({"image/png", "REVG"});
    Message results = Message::tool_results({tr});

    // round trip of what is kept
    Message backA = message_from_json(saved_message_json(assistant));
    CHECK(backA.role == Role::Assistant);
    CHECK(backA.raw == assistant.raw);  // resent unchanged
    REQUIRE(backA.toolCalls.size() == 1);
    CHECK(backA.toolCalls[0].name == "scene_list_entities");
    CHECK(backA.toolCalls[0].input["limit"] == 3);
    Message backR = message_from_json(saved_message_json(results));
    REQUIRE(backR.toolResults.size() == 1);
    CHECK(backR.toolResults[0].isError);

    // no base64: the text says pictures were there
    Json small = saved_message_json(user);
    CHECK_FALSE(small.contains("images"));
    CHECK(small["text"].get<std::string>().find("1 image(s)") != std::string::npos);
    CHECK(small.dump().find("QUJD") == std::string::npos);
    Json smallR = saved_message_json(results);
    CHECK(smallR.dump().find("REVG") == std::string::npos);
    CHECK(smallR["toolResults"][0]["content"].get<std::string>().find("1 image(s)") != std::string::npos);
}

TEST_CASE("API chat conversation: a follow-up continues the history, another model starts fresh") {
    CommandRegistry reg = make_registry();
    auto provider = std::make_shared<FakeProvider>();
    provider->script = {text_response("first answer"), text_response("second answer"), text_response("third answer"),
                        text_response("fourth answer")};
    TempDir dir;
    AiConfig cfg = default_config();
    std::vector<AgentEvent> events;
    auto run = [&](const std::string& task, const Conversation& conv, const std::vector<std::string>& images = {},
                   const std::string& model = {}) {
        SessionOptions so;
        so.projectDir = dir.str();
        so.conversation = conv;
        so.modelOverride = model;
        AgentSession s(reg, cfg, so);
        s.set_provider_factory([&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(provider);
        });
        s.set_event_handler([&](const AgentEvent& e) { events.push_back(e); });
        return s.run(task, images);
    };

    SessionResult r1 = run("hello", {});
    REQUIRE(r1.ok);
    CHECK(r1.conversation.key == "anthropic/claude-opus-5-5");
    CHECK(r1.conversation.history.size() == 2);  // user + assistant
    CHECK(provider->requests[0].messages.size() == 1);
    const AgentEvent* ctx = find_usage(events, [](const AgentEvent& e) { return e.contextTokens > 0; });
    REQUIRE(ctx);
    CHECK(ctx->contextTokens == 100);  // the fake response used 100 input tokens

    SessionResult r2 = run("and then?", r1.conversation);
    REQUIRE(r2.ok);
    const ChatRequest& second = provider->requests[1];
    REQUIRE(second.messages.size() == 3);  // hello, first answer, and then?
    CHECK(second.messages[0].text == "hello");
    CHECK(second.messages[1].role == Role::Assistant);
    CHECK(second.messages[1].raw == provider->script[0].message.raw);
    CHECK(second.messages[2].text == "and then?");
    CHECK(r2.conversation.history.size() == 4);

    // another model never gets this model's assistant payloads
    SessionResult r3 = run("fresh", r2.conversation, {}, "claude-sonnet-5-5");
    REQUIRE(r3.ok);
    CHECK(provider->requests[2].messages.size() == 1);
    CHECK(r3.conversation.key == "anthropic/claude-sonnet-5-5");
    CHECK(r3.conversation.history.size() == 2);

    // the attached picture reaches the model
    SessionResult r4 = run("look", r3.conversation, {write_png(dir.path / "pic.png")}, "claude-sonnet-5-5");
    REQUIRE(r4.ok);
    const Message& sent = provider->requests[3].messages.back();
    REQUIRE(sent.images.size() == 1);
    CHECK(sent.images[0].mediaType == "image/png");
    CHECK(sent.images[0].base64 == kPngBase64);

    // an unreadable picture fails before anything is sent, and the conversation is untouched
    const std::size_t sentBefore = provider->requests.size();
    SessionResult bad = run("x", r4.conversation, {(dir.path / "gone.png").string()}, "claude-sonnet-5-5");
    CHECK_FALSE(bad.ok);
    CHECK(bad.error.find("gone.png") != std::string::npos);
    CHECK(provider->requests.size() == sentBefore);
    CHECK(bad.conversation.history.size() == r4.conversation.history.size());
    CHECK(bad.conversation.key == r4.conversation.key);
}

TEST_CASE("Conversation JSON round trip") {
    Conversation c;
    c.key = "claude-code";
    c.cliSessionId = "sess-9";
    c.cliCostUsd = 0.25;
    c.history.push_back(Message::user("hi", {{"image/png", "QUJD"}}));
    Json j = c.to_json();  // saved form: no base64
    Conversation back = Conversation::from_json(j);
    CHECK(back.key == "claude-code");
    CHECK(back.cliSessionId == "sess-9");
    CHECK(back.cliCostUsd == 0.25);
    REQUIRE(back.history.size() == 1);
    CHECK(back.history[0].images.empty());
    CHECK(back.history[0].text.find("hi") == 0);
    CHECK_FALSE(back.empty());
    CHECK(Conversation{}.empty());
}
