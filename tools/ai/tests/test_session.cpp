#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {

struct Harness {
    CommandRegistry registry = make_registry();
    std::shared_ptr<FakeProvider> provider = std::make_shared<FakeProvider>();
    TempDir dir;
    AiConfig cfg = default_config();
    std::vector<AgentEvent> events;

    SessionResult run(const std::string& task, SessionOptions so = {}) {
        so.projectDir = dir.str();
        AgentSession s(registry, cfg, so);
        s.set_provider_factory([this](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(provider);
        });
        s.set_event_handler([this](const AgentEvent& e) { events.push_back(e); });
        return s.run(task);
    }
};

ToolCall call(const std::string& id, const std::string& name, Json input = Json::object()) {
    ToolCall c;
    c.id = id;
    c.name = name;
    c.input = std::move(input);
    return c;
}

}  // namespace

TEST_CASE("tools come from the registry: dots become underscores, sorted, ai.* hidden") {
    CommandRegistry reg = make_registry();
    auto tools = tools_from_registry(reg, true);
    std::vector<std::string> names;
    for (auto& t : tools) names.push_back(t.name);
    CHECK(names == std::vector<std::string>{"agent_delegate", "game_screenshot", "project_validate", "scene_list_entities"});
    CHECK(tools_from_registry(reg, false).size() == 3);
    CHECK(tool_name_for_command("scene.list_entities") == "scene_list_entities");
}

TEST_CASE("tool loop: batched results, errors flagged, append-only history") {
    Harness h;
    h.provider->script = {
        tool_response({call("t1", "scene_list_entities", Json::object({{"limit", 3}})), call("t2", "project_validate"),
                       call("t3", "no_such_tool"), call("t4", "game_screenshot")},
                      "Checking."),
        text_response("All done."),
    };
    auto r = h.run("Build a game");
    REQUIRE(r.ok);
    CHECK(r.finalText == "All done.");
    CHECK(r.stopReason == "end_turn");
    REQUIRE(h.provider->requests.size() == 2);

    const ChatRequest& first = h.provider->requests[0];
    const ChatRequest& second = h.provider->requests[1];
    // same model/effort for the orchestrator role
    CHECK(first.model == "claude-opus-5-5");
    CHECK(first.effort == "xhigh");
    // system prompt + tools are byte-stable between turns
    CHECK(first.system == second.system);
    CHECK(first.system.find("feedback_report") != std::string::npos);
    REQUIRE(first.tools.size() == second.tools.size());
    for (std::size_t i = 0; i < first.tools.size(); ++i) CHECK(first.tools[i].name == second.tools[i].name);

    // append-only: second request = first request's messages + assistant + ONE user results message
    REQUIRE(first.messages.size() == 1);
    REQUIRE(second.messages.size() == 3);
    CHECK(second.messages[0].text == first.messages[0].text);
    CHECK(second.messages[1].role == Role::Assistant);
    CHECK(second.messages[1].raw == h.provider->script[0].message.raw);  // incl. thinking block, unchanged
    const Message& results = second.messages[2];
    CHECK(results.role == Role::User);
    REQUIRE(results.toolResults.size() == 4);  // ALL results in a single user message
    CHECK(results.toolResults[0].toolUseId == "t1");
    CHECK_FALSE(results.toolResults[0].isError);
    CHECK(Json::parse(results.toolResults[0].content)["limit"] == 3);
    CHECK(results.toolResults[1].isError);  // handler threw CommandError
    CHECK(results.toolResults[1].content.find("scene main is broken") != std::string::npos);
    CHECK(results.toolResults[1].content.find("Fix scenes/main.scene.json") != std::string::npos);
    CHECK(results.toolResults[2].isError);  // unknown tool
    CHECK(results.toolResults[2].content.find("unknown_tool") != std::string::npos);
    CHECK_FALSE(results.toolResults[3].isError);
    REQUIRE(results.toolResults[3].images.size() == 1);  // screenshot attached as an image
    CHECK(results.toolResults[3].images[0].base64 == "QUJD");
    CHECK(results.toolResults[3].content.find("QUJD") == std::string::npos);

    // events
    int starts = 0, ends = 0, usage = 0, done = 0;
    for (auto& e : h.events) {
        starts += e.type == AgentEvent::Type::ToolStart;
        ends += e.type == AgentEvent::Type::ToolEnd;
        usage += e.type == AgentEvent::Type::Usage;
        done += e.type == AgentEvent::Type::Done;
    }
    CHECK(starts == 4);
    CHECK(ends == 4);
    CHECK(usage == 2);
    CHECK(done == 1);
    CHECK(r.usage.inputTokens == 200);
    CHECK(r.costUsd > 0);
    CHECK(r.turns == 2);

    // transcript saved under <project>/.factoria/ai/sessions
    REQUIRE_FALSE(r.transcriptPath.empty());
    CHECK(r.transcriptPath.find(".factoria/ai/sessions") != std::string::npos);
    std::string tr = read_file(r.transcriptPath);
    CHECK(tr.find("\"kind\":\"tool_results\"") != std::string::npos);
    std::size_t lines = std::count(tr.begin(), tr.end(), '\n');
    CHECK(lines >= 5);
    for (std::size_t pos = 0; pos < tr.size();) {
        auto nl = tr.find('\n', pos);
        Json line = Json::parse(tr.substr(pos, nl - pos), nullptr, false);
        CHECK_FALSE(line.is_discarded());
        CHECK_MESSAGE(line.contains("t"), "every transcript line has a time");
        if (line.value("kind", "") == "assistant") CHECK(line.contains("ms"));
        if (line.value("kind", "") == "tool_results") {
            for (const auto& entry : line["results"]) CHECK(entry.contains("ms"));
        }
        pos = nl + 1;
    }
}

TEST_CASE("invalid tool input JSON is reported back to the model") {
    Harness h;
    ToolCall bad = call("t1", "scene_list_entities");
    bad.inputError = "arguments are not a valid JSON object: {oops";
    h.provider->script = {tool_response({bad}), text_response("ok")};
    auto r = h.run("x");
    REQUIRE(r.ok);
    const auto& res = h.provider->requests[1].messages[2].toolResults[0];
    CHECK(res.isError);
    CHECK(res.content.find("invalid_arguments") != std::string::npos);
}

TEST_CASE("agent_delegate runs a sub-session with the worker model") {
    Harness h;
    h.provider->script = {
        tool_response({call("d1", "agent_delegate", Json::object({{"role", "worker"}, {"task", "Implement the pause menu."}})),
                       call("d2", "agent_delegate", Json::object({{"role", "fast"}, {"task", "Rename a file."}}))}),
        text_response("Pause menu implemented."),   // worker's final report
        text_response("Renamed."),                   // fast's final report
        text_response("Everything is done."),        // orchestrator final
    };
    auto r = h.run("Add a pause menu");
    REQUIRE(r.ok);
    REQUIRE(h.provider->requests.size() == 4);
    CHECK(h.provider->requests[0].model == "claude-opus-5-5");
    CHECK(h.provider->requests[0].effort == "xhigh");
    CHECK(h.provider->requests[1].model == "claude-sonnet-5-5");
    CHECK(h.provider->requests[1].effort == "medium");
    CHECK(h.provider->requests[1].messages[0].text == "Implement the pause menu.");
    CHECK(h.provider->requests[2].model == "claude-haiku-5-5");
    CHECK(h.provider->requests[2].effort == "max");
    // sub-agents cannot delegate again
    for (auto& t : h.provider->requests[1].tools) CHECK(t.name != "agent_delegate");
    bool orchestratorHas = false;
    for (auto& t : h.provider->requests[0].tools) orchestratorHas = orchestratorHas || t.name == "agent_delegate";
    CHECK(orchestratorHas);
    // results returned to the orchestrator in ONE user message
    const Message& back = h.provider->requests[3].messages.back();
    REQUIRE(back.toolResults.size() == 2);
    CHECK(back.toolResults[0].content == "Pause menu implemented.");
    CHECK(back.toolResults[1].content == "Renamed.");
    CHECK(r.usage.inputTokens == 400);  // usage aggregated across sub-sessions
    // depth marks sub-session events
    bool sawDepth1 = false;
    for (auto& e : h.events) sawDepth1 = sawDepth1 || (e.depth == 1 && e.role == "worker");
    CHECK(sawDepth1);

    // invalid delegation args are reported, not crashed
    Harness h2;
    h2.provider->script = {tool_response({call("d1", "agent_delegate", Json::object({{"role", "orchestrator"}, {"task", "x"}}))}), text_response("fine")};
    REQUIRE(h2.run("x").ok);
    CHECK(h2.provider->requests[1].messages[2].toolResults[0].isError);
}

TEST_CASE("max_tokens continues, pause_turn resends, refusal surfaces details") {
    {
        Harness h;
        h.provider->script = {text_response("part one", StopReason::MaxTokens), text_response("part two")};
        auto r = h.run("x");
        REQUIRE(r.ok);
        REQUIRE(h.provider->requests.size() == 2);
        CHECK(h.provider->requests[1].messages.size() == 3);  // user, assistant(cut), user(continue)
        CHECK(h.provider->requests[1].messages[2].text.find("Continue") != std::string::npos);
    }
    {
        Harness h;
        h.provider->script = {text_response("paused", StopReason::PauseTurn), text_response("finished")};
        auto r = h.run("x");
        REQUIRE(r.ok);
        REQUIRE(h.provider->requests.size() == 2);
        // resent with the assistant turn last, no extra user message
        CHECK(h.provider->requests[1].messages.size() == 2);
        CHECK(h.provider->requests[1].messages.back().role == Role::Assistant);
        CHECK(r.finalText == "finished");
    }
    {
        Harness h;
        ChatResponse ref = text_response("no", StopReason::Refusal);
        ref.refusalCategory = "cyber";
        ref.refusalExplanation = "malware request";
        h.provider->script = {ref};
        auto r = h.run("x");
        CHECK_FALSE(r.ok);
        CHECK(r.stopReason == "refusal");
        CHECK(r.error.find("cyber") != std::string::npos);
        CHECK(r.error.find("malware request") != std::string::npos);
    }
    {
        // truncated tool call is answered with an error, never executed
        Harness h;
        auto cut = tool_response({call("t1", "scene_list_entities")});
        cut.stopReason = StopReason::MaxTokens;
        h.provider->script = {cut, text_response("ok")};
        REQUIRE(h.run("x").ok);
        const auto& res = h.provider->requests[1].messages[2].toolResults[0];
        CHECK(res.isError);
        CHECK(res.content.find("truncated") != std::string::npos);
    }
}

TEST_CASE("limits: max turns, cost budget, cancellation, provider errors") {
    {
        Harness h;
        for (int i = 0; i < 10; ++i) h.provider->script.push_back(tool_response({call("t" + std::to_string(i), "scene_list_entities")}));
        SessionOptions so;
        so.maxTurns = 3;
        auto r = h.run("loop forever", so);
        CHECK_FALSE(r.ok);
        CHECK(r.stopReason == "max_turns");
        CHECK(h.provider->calls == 3);
    }
    {
        Harness h;
        for (int i = 0; i < 10; ++i) {
            auto t = tool_response({call("t" + std::to_string(i), "scene_list_entities")});
            t.usage.inputTokens = 1'000'000;  // opus: $4 per call
            h.provider->script.push_back(t);
        }
        SessionOptions so;
        so.maxCostUsd = 5;
        auto r = h.run("expensive", so);
        CHECK_FALSE(r.ok);
        CHECK(r.stopReason == "budget");
        CHECK(h.provider->calls == 2);
        CHECK(r.costUsd == doctest::Approx(8.0).epsilon(0.01));
    }
    {
        Harness h;
        h.provider->script = {text_response("never")};
        CancelFlag cancel{true};
        h.dir.path = h.dir.path;
        SessionOptions so;
        so.projectDir = h.dir.str();
        AgentSession s(h.registry, h.cfg, so);
        s.set_provider_factory([&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(h.provider);
        });
        s.set_cancel_flag(&cancel);
        auto r = s.run("x");
        CHECK_FALSE(r.ok);
        CHECK(r.stopReason == "cancelled");
        CHECK(h.provider->calls == 0);
    }
    {  // the cause of a cancel reaches the result, the error text and the transcript's end event
        Harness h;
        h.provider->script = {text_response("never")};
        CancelFlag cancel{true};
        SessionOptions so;
        so.projectDir = h.dir.str();
        AgentSession s(h.registry, h.cfg, so);
        s.set_provider_factory([&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(h.provider);
        });
        s.set_cancel_flag(&cancel);
        s.set_cancel_cause([] { return std::string("watchdog_process_gone"); });
        auto r = s.run("x");
        CHECK(r.stopReason == "cancelled");
        CHECK(r.cancelCause == "watchdog_process_gone");
        CHECK(r.error == "cancelled: the editor's watchdog thought the agent process was gone");
        REQUIRE_FALSE(r.transcriptPath.empty());
        std::ifstream in(r.transcriptPath);
        std::string line, last;
        while (std::getline(in, line))
            if (!line.empty()) last = line;
        const Json end = Json::parse(last);
        CHECK(end["kind"].get<std::string>() == "end");
        CHECK(end["cause"].get<std::string>() == "watchdog_process_gone");
        CHECK(end["error"].get<std::string>() == r.error);
    }
    CHECK(cancelled_message("") == "cancelled");
    CHECK(cancelled_message("user_stop") == "cancelled: the user pressed Stop");
    {
        Harness h;  // script exhausted -> provider error propagates with message
        auto r = h.run("x");
        CHECK_FALSE(r.ok);
        CHECK(r.stopReason == "error");
        CHECK(r.error == "script exhausted");
    }
    {
        Harness h;  // placeholder model must be changed by the user
        h.cfg = parse_config(Json::parse(R"({"defaultProvider":"openrouter"})"), "x").value();
        auto r = h.run("x");
        CHECK_FALSE(r.ok);
        CHECK(r.error.find("No model configured") != std::string::npos);
        CHECK(r.hint.find("roles.orchestrator.model") != std::string::npos);
    }
}

TEST_CASE("provider/model overrides apply to the main role only") {
    Harness h;
    h.cfg = parse_config(Json::parse(R"({"providers":{"local":{"type":"openai-compatible","baseUrl":"http://x/v1"}}})"), "x").value();
    h.provider->script = {text_response("done")};
    SessionOptions so;
    so.providerOverride = "local";
    so.modelOverride = "llama3";
    so.allowDelegation = false;
    auto r = h.run("x", so);
    REQUIRE(r.ok);
    CHECK(h.provider->requests[0].model == "llama3");
    for (auto& t : h.provider->requests[0].tools) CHECK(t.name != "agent_delegate");
}

TEST_CASE("a role's context limit reaches the request and is reported as the window") {
    Harness h;
    h.cfg.roles["orchestrator"].maxContextTokens = 400000;
    h.provider->script = {text_response("done")};
    REQUIRE(h.run("x").ok);
    CHECK(h.provider->requests[0].maxContextTokens == 400000);
    bool sawWindow = false;
    for (const auto& e : h.events) sawWindow = sawWindow || (e.type == AgentEvent::Type::Usage && e.contextWindow == 400000);
    CHECK(sawWindow);
}

TEST_CASE("system prompt: guide, rules, project context, feedback summary") {
    TempDir dir;
    std::ofstream(dir.path / "factoria.json") << R"({"name":"space-dodge","version":"0.1.0"})";
    std::filesystem::create_directories(dir.path / "scenes");
    std::ofstream(dir.path / "scenes" / "main.scene.json") << "{}";
    std::ofstream(dir.path / "ENGINE_FEEDBACK.json")
        << R"({"format":"factoria.feedback/1","entries":[{"id":"FB-0001","severity":"major","title":"No one-way platforms","status":"open"},{"id":"FB-0002","title":"Done thing","status":"fixed"}]})";
    PromptContext ctx{dir.str(), "orchestrator", true, ""};
    std::string p = build_system_prompt(ctx);
    CHECK(p.find("space-dodge") != std::string::npos);
    CHECK(p.find("scenes/main.scene.json") != std::string::npos);
    CHECK(p.find("1 open") != std::string::npos);
    CHECK(p.find("No one-way platforms") != std::string::npos);
    CHECK(p.find("Done thing") == std::string::npos);
    CHECK(p.find("project_validate") != std::string::npos);
    CHECK(p.find("screenshot") != std::string::npos);
    CHECK(p.find("feedback_report") != std::string::npos);
    CHECK(p.find("agent_delegate") != std::string::npos);
    CHECK(p == build_system_prompt(ctx));  // deterministic
}
