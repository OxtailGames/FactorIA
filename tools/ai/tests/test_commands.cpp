#include "fa/ai/commands.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

TEST_CASE("ai.providers and ai.run commands") {
    TempDir dir;
    CommandRegistry registry = make_registry();
    auto provider = std::make_shared<FakeProvider>();
    provider->script = {text_response("Task finished.")};
    std::ofstream(dir.path / "leak.js") << "const k='sk-ant-api03-abcdefghijklmnopqrstuvwxyz';\n";

    AiCommandOptions opt;
    opt.loadConfig = [] { return Result<AiConfig>(default_config()); };
    opt.projectDir = [&] { return dir.str(); };
    opt.providerFactory = [&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
        return std::static_pointer_cast<ChatProvider>(provider);
    };
    register_ai_commands(registry, opt);
    REQUIRE(registry.has("ai.providers"));
    REQUIRE(registry.has("ai.run"));

    auto list = registry.call("ai.providers", Json::object());
    REQUIRE(list.ok);
    CHECK(list.result["roles"]["orchestrator"]["model"] == "claude-opus-5-5");
    CHECK(list.result["providers"].size() >= 10);

    auto doctor = registry.call("ai.providers", Json::object({{"action", "doctor"}}));
    REQUIRE(doctor.ok);
    CHECK(doctor.result["report"].get<std::string>().find("Roles:") != std::string::npos);

    // the key never appears in the report
    CHECK(doctor.result.dump().find("sk-ant") == std::string::npos);

    auto run = registry.call("ai.run", Json::object({{"task", "Do something"}, {"role", "worker"}}));
    REQUIRE(run.ok);
    CHECK(run.result["finalText"] == "Task finished.");
    CHECK(provider->requests[0].model == "claude-sonnet-5-5");
    bool warned = false;
    for (auto& w : run.result["warnings"]) warned = warned || w.get<std::string>().find("leak.js:1") != std::string::npos;
    CHECK(warned);
    for (auto& t : provider->requests[0].tools) CHECK(t.name != "ai_run");  // no recursion

    provider->script = {text_response("x", StopReason::Refusal)};
    provider->calls = 0;
    auto bad = registry.call("ai.run", Json::object({{"task", "t"}}));
    CHECK_FALSE(bad.ok);
    CHECK(bad.error["code"] == "refusal");

    auto invalid = registry.call("ai.run", Json::object({{"role", "orchestrator"}}));
    CHECK_FALSE(invalid.ok);  // task is required
}

TEST_CASE("ai.models lists the models of every available provider; one failure stays in its own entry") {
    AiConfig cfg;
    cfg.providers["anthropic"] = default_config().providers["anthropic"];
    cfg.providers["anthropic"].apiKey = "sk-ant-test-key-0000000000";
    cfg.providers["ollama"] = default_config().providers["ollama"];
    cfg.providers["lmstudio"] = default_config().providers["lmstudio"];  // a local server that is not running
    cfg.providers["codex"] = default_config().providers["codex"];
    cfg.providers["codex"].command = "definitely-not-an-installed-codex";  // not available: only listed when asked for

    CommandRegistry registry;
    AiCommandOptions opt;
    opt.loadConfig = [&] { return Result<AiConfig>(cfg); };
    opt.runtime.env = fake_env({});
    opt.runtime.transport = [](const HttpRequest& req) {
        HttpResponse r;
        if (req.url.find("api.anthropic.com") != std::string::npos) {
            r.status = 200;
            r.body = R"({"data":[{"id":"claude-opus-5-5","display_name":"Claude Opus 5.5"}]})";
        } else if (req.url.find("11434") != std::string::npos) {
            r.status = 200;
            r.body = R"({"data":[{"id":"llama3.2:latest"}]})";
        } else {
            r.error = "Could not connect to server";
        }
        return r;
    };
    register_ai_commands(registry, opt);
    const CommandInfo* info = registry.info("ai.models");
    REQUIRE(info);
    CHECK(info->readOnly);
    CHECK(info->category == "ai");
    CHECK_FALSE(info->description.empty());
    CHECK(info->inputSchema["properties"]["provider"]["description"].get<std::string>().size() > 10);

    auto all = registry.call("ai.models", Json::object());
    REQUIRE(all.ok);
    const Json& providers = all.result["providers"];
    REQUIRE(providers.size() == 3);  // anthropic, lmstudio, ollama (codex is not available)
    CHECK(providers[0]["name"] == "anthropic");
    CHECK(providers[0]["models"][0] == Json::parse(R"({"id":"claude-opus-5-5","name":"Claude Opus 5.5","description":"","resolved":""})"));
    CHECK_FALSE(providers[0].contains("error"));
    CHECK(providers[1]["name"] == "lmstudio");
    CHECK(providers[1]["models"].empty());
    CHECK(providers[1]["error"].get<std::string>().find("Could not connect") != std::string::npos);
    CHECK(providers[1].contains("hint"));
    CHECK(providers[2]["name"] == "ollama");
    CHECK(providers[2]["models"][0]["id"] == "llama3.2:latest");

    auto one = registry.call("ai.models", Json::object({{"provider", "codex"}}));
    REQUIRE(one.ok);
    REQUIRE(one.result["providers"].size() == 1);
    CHECK(one.result["providers"][0]["name"] == "codex");
    CHECK(one.result["providers"][0]["error"].get<std::string>().find("does not list its models") != std::string::npos);
    CHECK(one.result["providers"][0]["hint"].get<std::string>().find("Type the model name") != std::string::npos);

    auto unknown = registry.call("ai.models", Json::object({{"provider", "codx"}}));
    REQUIRE_FALSE(unknown.ok);
    CHECK(unknown.error["code"] == "unknown_provider");
    CHECK(unknown.error["hint"].get<std::string>().find("codex") != std::string::npos);
}

TEST_CASE("ai.run reports what the sub-agent does: MCP progress for the caller, callbacks for the host") {
    TempDir dir;
    CommandRegistry registry = make_registry();
    auto provider = std::make_shared<FakeProvider>();
    provider->script = {text_response("All done.")};

    std::vector<std::string> log;
    AiCommandOptions opt;
    opt.loadConfig = [] { return Result<AiConfig>(default_config()); };
    opt.projectDir = [&] { return dir.str(); };
    opt.providerFactory = [&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
        return std::static_pointer_cast<ChatProvider>(provider);
    };
    opt.onRunStart = [&](const AiRunInfo& i) { log.push_back("start " + i.id + " " + i.role + " " + i.task); };
    opt.onRunEvent = [&](const AiRunInfo&, const AgentEvent& e) { log.push_back(std::string("event ") + event_type_name(e.type)); };
    opt.onRunEnd = [&](const AiRunInfo& i, bool ok, const std::string& report, const std::string& error) {
        log.push_back(std::string("end ") + i.role + (ok ? " ok " : " failed ") + report + error);
    };
    register_ai_commands(registry, opt);

    std::vector<std::string> progress;
    {
        CommandProgressScope scope([&](std::string_view m) {
            progress.emplace_back(m);
            return true;
        });
        auto run = registry.call("ai.run", Json::object({{"task", "Do something"}, {"role", "worker"}}));
        REQUIRE(run.ok);
    }
    REQUIRE(log.size() >= 3);
    CHECK(log.front().rfind("start run-", 0) == 0);
    CHECK(log.front().find(" worker Do something") != std::string::npos);
    CHECK(log.back() == "end worker ok All done.");
    CHECK(std::count(log.begin(), log.end(), "event done") == 1);
    REQUIRE_FALSE(progress.empty());
    CHECK(progress.front() == "worker: starting");
    CHECK(std::all_of(progress.begin(), progress.end(), [](const std::string& m) { return m.rfind("worker", 0) == 0; }));

    // A failure ends the run with ok=false and the error.
    log.clear();
    provider->script = {text_response("x", StopReason::Refusal)};
    provider->calls = 0;
    CHECK_FALSE(registry.call("ai.run", Json::object({{"task", "t"}, {"role", "worker"}})).ok);
    REQUIRE_FALSE(log.empty());
    CHECK(log.back().rfind("end worker failed", 0) == 0);
}

TEST_CASE("describe_agent_event: one short line per event worth showing") {
    AgentEvent tool;
    tool.type = AgentEvent::Type::ToolStart;
    tool.toolName = "Bash";
    tool.toolInput = Json::object({{"command", "cmake --build build/dev\n  -j8"}});
    CHECK(describe_agent_event(tool) == "running Bash (cmake --build build/dev   -j8)");
    tool.toolName = "mcp__factoria__scene_spawn";
    tool.toolInput = Json::object({{"name", "Player"}});
    CHECK(describe_agent_event(tool) == "running scene_spawn (Player)");
    tool.toolInput = Json::object({{"command", std::string(200, 'x')}});
    CHECK(describe_agent_event(tool).size() < 90);  // long commands are cut
    tool.toolName = "Read";
    tool.toolInput = Json::object();
    CHECK(describe_agent_event(tool) == "running Read");

    AgentEvent e;
    e.type = AgentEvent::Type::TextDelta;
    CHECK(describe_agent_event(e) == "writing");
    e.type = AgentEvent::Type::ThinkingDelta;
    CHECK(describe_agent_event(e) == "thinking");
    e.type = AgentEvent::Type::Error;
    e.text = "rate limited";
    CHECK(describe_agent_event(e) == "error: rate limited");
    e.type = AgentEvent::Type::ToolEnd;
    CHECK(describe_agent_event(e).empty());
}
