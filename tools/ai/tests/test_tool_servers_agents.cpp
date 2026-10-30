// Tool servers reaching each kind of agent: the config file Claude Code and generic CLIs get, the arguments Codex gets, the
// built-in agent's tool list, and the ai.tool_servers command.
#include "fa/ai/cli_agent.h"
#include "fa/ai/commands.h"
#include "fake_mcp_http.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {

ResolvedToolServer scenario_resolved() {
    ResolvedToolServer s;
    s.name = "scenario";
    s.type = "http";
    s.url = "https://mcp.scenario.com/mcp";
    s.headers = {{"Authorization", "Basic c2VjcmV0LWJhc2U2NA=="}};
    s.timeoutSeconds = 300;
    s.usesKey = true;
    s.keySource = "env:SCENARIO_KEY";
    return s;
}

ResolvedToolServer local_resolved() {
    ResolvedToolServer s;
    s.name = "local-files";
    s.type = "stdio";
    s.command = "npx";
    s.args = {"-y", "files-server", "--root=/work"};
    s.env = {{"FILES_TOKEN", "tok-987"}, {"PATH", "/usr/bin"}};
    s.timeoutSeconds = 45;
    return s;
}

ToolServer scenario_config() {
    ToolServer s;
    s.name = "scenario";
    s.type = "http";
    s.url = "https://mcp.example.com/mcp";
    s.headers = {{"Authorization", "Basic {key}"}};
    s.apiKeyEnv = "SCENARIO_KEY";
    s.note = "AI game art.";
    return s;
}

std::vector<std::string> info_texts(const std::vector<AgentEvent>& events) {
    std::vector<std::string> out;
    for (const auto& e : events)
        if (e.type == AgentEvent::Type::Info) out.push_back(e.text);
    return out;
}

}  // namespace

TEST_CASE("make_mcp_config: the engine's server first, then the user's, each as Claude Code's .mcp.json writes it") {
    const Json plain = make_mcp_config("/p", "factoria");
    CHECK(plain["mcpServers"].size() == 1);

    const Json cfg = make_mcp_config("/p", "factoria", "", {scenario_resolved(), local_resolved()});
    const Json& servers = cfg["mcpServers"];
    REQUIRE(servers.size() == 3);
    CHECK(servers["factoria"]["command"] == "factoria");
    CHECK(servers["factoria"]["timeout"] == kMcpToolTimeoutMs);  // unchanged
    CHECK(servers["scenario"]["type"] == "http");
    CHECK(servers["scenario"]["url"] == "https://mcp.scenario.com/mcp");
    CHECK(servers["scenario"]["headers"]["Authorization"] == "Basic c2VjcmV0LWJhc2U2NA==");
    CHECK(servers["scenario"]["timeout"] == 300000);  // milliseconds
    CHECK(servers["local-files"]["command"] == "npx");
    CHECK(servers["local-files"]["args"] == Json::parse(R"(["-y","files-server","--root=/work"])"));
    CHECK(servers["local-files"]["env"]["FILES_TOKEN"] == "tok-987");
    CHECK(servers["local-files"]["timeout"] == 45000);
    CHECK_FALSE(servers["local-files"].contains("type"));
    CHECK_FALSE(servers["local-files"].contains("headers"));
}

TEST_CASE("codex_tool_server_args: -c arguments, and no secret in the argument list") {
    std::map<std::string, std::string> env;
    const auto args = codex_tool_server_args({scenario_resolved(), local_resolved()}, env);
    REQUIRE(args.size() % 2 == 0);
    for (std::size_t i = 0; i < args.size(); i += 2) CHECK(args[i] == "-c");
    const std::string all = [&] {
        std::string s;
        for (const auto& a : args) s += a + "\n";
        return s;
    }();
    CHECK(has(all, "mcp_servers.scenario.url=\"https://mcp.scenario.com/mcp\"\n"));
    CHECK(has(all, "mcp_servers.scenario.tool_timeout_sec=300\n"));
    CHECK(has(all, "mcp_servers.scenario.env_http_headers={\"Authorization\"=\"FACTORIA_MCP_SCENARIO_H0\"}\n"));
    CHECK(has(all, "mcp_servers.local-files.command=\"npx\"\n"));
    CHECK(has(all, "mcp_servers.local-files.args=[\"-y\",\"files-server\",\"--root=/work\"]\n"));
    CHECK(has(all, "mcp_servers.local-files.env_vars=[\"FILES_TOKEN\"]\n"));
    CHECK(has(all, "mcp_servers.local-files.env={\"PATH\"=\"/usr/bin\"}\n"));
    // the values travel in the environment of the Codex process
    CHECK(env.at("FACTORIA_MCP_SCENARIO_H0") == "Basic c2VjcmV0LWJhc2U2NA==");
    CHECK(env.at("FILES_TOKEN") == "tok-987");
    CHECK_FALSE(has(all, "c2VjcmV0LWJhc2U2NA"));
    CHECK_FALSE(has(all, "tok-987"));
}

TEST_CASE("apply_role_restrictions: Claude Code is allowed each tool server whole, as mcp__<name>") {
    CliRunRequest req{"x", "m", "/p"};
    req.toolServers = {scenario_resolved(), local_resolved()};
    std::vector<std::string> claude = {"-p", "--allowedTools", "mcp__factoria"};
    apply_role_restrictions(ProviderKind::ClaudeCode, true, req, claude);
    std::string joined;
    for (const auto& a : claude) joined += a + "\n";
    CHECK(has(joined, "mcp__scenario"));
    CHECK(has(joined, "mcp__local-files"));
    CHECK(has(joined, "mcp__factoria"));
    // one --allowedTools, not two (a second flag might replace the first)
    CHECK(joined.find("--allowedTools") == joined.rfind("--allowedTools"));

    CliRunRequest none{"x", "m", "/p"};
    std::vector<std::string> same = {"-p", "--allowedTools", "mcp__factoria"};
    apply_role_restrictions(ProviderKind::ClaudeCode, true, none, same);
    CHECK(same == std::vector<std::string>{"-p", "--allowedTools", "mcp__factoria"});
}

#ifndef _WIN32

namespace {

std::string script(const char* name) { return std::string(FA_AI_FIXTURES) + "/" + name; }

AiConfig claude_session_config(const std::string& argvFile, std::vector<std::string> scenarioRoles = {}) {
    AiConfig cfg = default_config();
    cfg.providers["claude-code"].command = script("fake_claude.sh");
    cfg.providers["claude-code"].env["FAKE_ARGV_FILE"] = argvFile;
    for (const char* role : {"orchestrator", "reviewer"}) cfg.roles[role].provider = "claude-code";
    ToolServer s = scenario_config();
    s.roles = std::move(scenarioRoles);
    cfg.toolServers.push_back(s);
    return cfg;
}

}  // namespace

TEST_CASE("AgentSession with Claude Code: the server is allowed, named in the prompt, and its key file is gone after the run") {
    TempDir dir, scratch;
    const std::string argvFile = (scratch.path / "argv.txt").string();
    AiConfig cfg = claude_session_config(argvFile);
    CommandRegistry registry = make_registry();
    SessionOptions so;
    so.projectDir = dir.str();
    so.env = fake_env({{"SCENARIO_KEY", "key-in-env-4242"}});
    AgentSession s(registry, cfg, so);
    REQUIRE(s.run("Make a coin").ok);

    const std::string argv = read_file(argvFile);
    CHECK(has(argv, "mcp__scenario"));
    CHECK(has(argv, "--mcp-config\n"));
    CHECK_FALSE(has(argv, "key-in-env-4242"));  // the key is in the config file, never in the argument list
    CHECK(has(argv, "External tools"));
    CHECK(has(argv, "mcp__scenario__"));
    CHECK(has(argv, "AI game art."));
    // the file with the key is deleted when the run ends
    std::size_t leftovers = 0;
    std::error_code ec;
    for (const auto& e : std::filesystem::directory_iterator(dir.path / ".factoria" / "ai", ec))
        if (has(e.path().filename().string(), "mcp-claude-code-")) ++leftovers;
    CHECK(leftovers == 0);
}

TEST_CASE("AgentSession with Claude Code: a server whose key is missing is skipped with a note, review roles need to be listed") {
    TempDir dir, scratch;
    const std::string argvFile = (scratch.path / "argv.txt").string();
    CommandRegistry registry = make_registry();
    {
        AiConfig cfg = claude_session_config(argvFile);
        SessionOptions so;
        so.projectDir = dir.str();
        so.env = fake_env({});  // SCENARIO_KEY is not set
        std::vector<AgentEvent> events;
        AgentSession s(registry, cfg, so);
        s.set_event_handler([&](const AgentEvent& e) { events.push_back(e); });
        REQUIRE(s.run("Make a coin").ok);
        CHECK_FALSE(has(read_file(argvFile), "mcp__scenario"));
        bool noted = false;
        for (const auto& t : info_texts(events)) noted = noted || (has(t, "'scenario' skipped") && has(t, "SCENARIO_KEY"));
        CHECK(noted);
    }
    for (bool listed : {false, true}) {
        std::filesystem::remove(argvFile);
        AiConfig cfg = claude_session_config(argvFile, listed ? std::vector<std::string>{"reviewer"} : std::vector<std::string>{});
        SessionOptions so;
        so.projectDir = dir.str();
        so.role = "reviewer";
        so.allowDelegation = false;
        so.env = fake_env({{"SCENARIO_KEY", "k"}});
        AgentSession s(registry, cfg, so);
        REQUIRE(s.run("Review the game").ok);
        const std::string argv = read_file(argvFile);
        INFO("reviewer listed: " << listed);
        CHECK((has(argv, "mcp__scenario") == listed));
    }
}

TEST_CASE("AgentSession with Codex: the servers become -c arguments before the stdin marker, the key stays out of them") {
    TempDir dir, scratch;
    const std::string argvFile = (scratch.path / "argv.txt").string();
    AiConfig cfg = default_config();
    cfg.providers["codex"].command = script("fake_codex.sh");
    cfg.providers["codex"].env["FAKE_ARGV_FILE"] = argvFile;
    for (const char* role : {"orchestrator"}) cfg.roles[role].provider = "codex";
    cfg.toolServers.push_back(scenario_config());
    CommandRegistry registry = make_registry();
    SessionOptions so;
    so.projectDir = dir.str();
    so.env = fake_env({{"SCENARIO_KEY", "key-in-env-4242"}});
    AgentSession s(registry, cfg, so);
    REQUIRE(s.run("Make a coin").ok);
    const std::string argv = read_file(argvFile);
    CHECK(has(argv, "mcp_servers.scenario.url=\"https://mcp.example.com/mcp\"\n"));
    CHECK(has(argv, "mcp_servers.scenario.env_http_headers="));
    CHECK_FALSE(has(argv, "key-in-env-4242"));
    CHECK(argv.rfind("-\nstdin:") != std::string::npos);
    CHECK(argv.rfind("mcp_servers.scenario.url") < argv.rfind("-\nstdin:"));
    CHECK(has(argv, "External tools"));
}

TEST_CASE("AgentSession with a generic CLI: {mcp_config} holds the servers during the run; without the placeholder a note says why") {
    TempDir dir, scratch;
    const std::string captured = (scratch.path / "config.json").string();
    AiConfig cfg = default_config();
    ProviderConfig generic;
    generic.name = "my-agent";
    generic.kind = ProviderKind::GenericCli;
    generic.command = "sh";
    generic.argv = {"-c", "cat \"$1\" > \"$2\"; echo done", "sh", "{mcp_config}", captured};
    cfg.providers["my-agent"] = generic;
    cfg.roles["orchestrator"].provider = "my-agent";
    cfg.toolServers.push_back(scenario_config());
    CommandRegistry registry = make_registry();
    SessionOptions so;
    so.projectDir = dir.str();
    so.env = fake_env({{"SCENARIO_KEY", "key-in-env-4242"}});
    {
        AgentSession s(registry, cfg, so);
        REQUIRE(s.run("Make a coin").ok);
        const Json seen = Json::parse(read_file(captured));
        CHECK(seen["mcpServers"].contains("factoria"));
        CHECK(seen["mcpServers"]["scenario"]["url"] == "https://mcp.example.com/mcp");
        CHECK(seen["mcpServers"]["scenario"]["headers"]["Authorization"] == "Basic key-in-env-4242");
    }
    cfg.providers["my-agent"].argv = {"-c", "echo done"};
    std::vector<AgentEvent> events;
    AgentSession s(registry, cfg, so);
    s.set_event_handler([&](const AgentEvent& e) { events.push_back(e); });
    REQUIRE(s.run("Make a coin").ok);
    bool noted = false;
    for (const auto& t : info_texts(events)) noted = noted || has(t, "{mcp_config}");
    CHECK(noted);
}

#endif

namespace {

struct ChatRun {
    CommandRegistry registry = make_registry();
    std::shared_ptr<FakeProvider> provider = std::make_shared<FakeProvider>();
    TempDir dir;
    AiConfig cfg = default_config();
    std::vector<AgentEvent> events;
    FakeHttpServer server;

    SessionResult run(const std::string& role = "orchestrator", EnvLookup env = fake_env({{"SCENARIO_KEY", "k"}})) {
        SessionOptions so;
        so.projectDir = dir.str();
        so.role = role;
        so.env = std::move(env);
        so.toolServerTransport = server.transport();
        AgentSession s(registry, cfg, so);
        s.set_provider_factory([this](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(provider);
        });
        s.set_event_handler([this](const AgentEvent& e) { events.push_back(e); });
        return s.run("Make a coin");
    }
};

bool has_tool(const ChatRequest& req, const std::string& name) {
    for (const auto& t : req.tools)
        if (t.name == name) return true;
    return false;
}

}  // namespace

TEST_CASE("AgentSession with the built-in agent: the server's tools join the list and the model's calls reach the server") {
    ChatRun h;
    h.cfg.toolServers.push_back(scenario_config());
    ToolCall call;
    call.id = "t1";
    call.name = "scenario__tool_0";
    call.input = Json::object({{"prompt", "a coin"}});
    h.provider->script = {tool_response({call}), text_response("Made it.")};
    auto r = h.run();
    REQUIRE(r.ok);
    REQUIRE(h.provider->requests.size() == 2);
    const ChatRequest& first = h.provider->requests[0];
    CHECK(has_tool(first, "scenario__tool_0"));
    CHECK(has_tool(first, "scenario__generate_image"));
    CHECK(has_tool(first, "scene_list_entities"));  // the engine's tools are still there
    for (std::size_t i = 1; i < first.tools.size(); ++i) CHECK(first.tools[i - 1].name < first.tools[i].name);  // byte-stable order
    CHECK(has(first.system, "External tools"));
    CHECK(has(first.system, "scenario__"));
    CHECK(has(first.system, "AI game art."));
    CHECK(header_of(h.server.requests[0], "Authorization") == "Basic k");

    const Message& results = h.provider->requests[1].messages.back();
    REQUIRE(results.toolResults.size() == 1);
    CHECK_FALSE(results.toolResults[0].isError);
    CHECK(has(results.toolResults[0].content, "called tool_0 with {\"prompt\":\"a coin\"}"));
    CHECK(h.server.deletes == 1);  // the session with the server ended with the run
    bool connected = false;
    for (const auto& t : info_texts(h.events)) connected = connected || has(t, "'scenario' connected: 2 tools");
    CHECK(connected);
}

TEST_CASE("AgentSession with the built-in agent: a server that cannot be used only costs a note") {
    {
        ChatRun h;
        h.cfg.toolServers.push_back(scenario_config());
        h.provider->script = {text_response("Done.")};
        auto r = h.run("orchestrator", fake_env({}));  // no key
        REQUIRE(r.ok);
        CHECK_FALSE(has_tool(h.provider->requests[0], "scenario__tool_0"));
        CHECK_FALSE(has(h.provider->requests[0].system, "External tools"));
        bool noted = false;
        for (const auto& t : info_texts(h.events)) noted = noted || has(t, "'scenario' skipped");
        CHECK(noted);
        CHECK(h.server.requests.empty());  // nothing was sent to a server we have no key for
    }
    {
        ChatRun h;
        h.cfg.toolServers.push_back(scenario_config());
        h.server.status = 401;
        h.provider->script = {text_response("Done.")};
        auto r = h.run();
        REQUIRE(r.ok);
        CHECK_FALSE(has_tool(h.provider->requests[0], "scenario__tool_0"));
        bool noted = false;
        for (const auto& t : info_texts(h.events)) noted = noted || (has(t, "'scenario' not available") && has(t, "401"));
        CHECK(noted);
    }
}

TEST_CASE("AgentSession with the built-in agent: roles that are not listed do not get the server") {
    ChatRun h;
    ToolServer s = scenario_config();
    s.roles = {"worker"};
    h.cfg.toolServers.push_back(s);
    h.provider->script = {text_response("Done.")};
    REQUIRE(h.run("worker").ok);
    CHECK(has_tool(h.provider->requests[0], "scenario__tool_0"));
    h.provider->script = {text_response("Done.")};
    h.provider->calls = 0;
    h.provider->requests.clear();
    REQUIRE(h.run("orchestrator").ok);
    CHECK_FALSE(has_tool(h.provider->requests[0], "scenario__tool_0"));
}

TEST_CASE("ai.tool_servers: lists the servers without keys, tests them on request, names the unknown ones") {
    FakeHttpServer server;
    CommandRegistry registry = make_registry();
    AiCommandOptions opt;
    opt.loadConfig = [] {
        AiConfig cfg = default_config();
        ToolServer s = scenario_config();
        s.apiKey = "must-not-be-listed";
        cfg.toolServers.push_back(s);
        ToolServer needsKey = scenario_config();
        needsKey.name = "needskey";
        needsKey.apiKeyEnv = "UNSET_KEY";
        cfg.toolServers.push_back(needsKey);
        ToolServer off = scenario_config();
        off.name = "off";
        off.enabled = false;
        cfg.toolServers.push_back(off);
        return Result<AiConfig>(cfg);
    };
    opt.runtime.env = fake_env({{"SCENARIO_KEY", "env-key-77"}});
    opt.runtime.transport = server.transport();
    register_ai_commands(registry, opt);
    REQUIRE(registry.has("ai.tool_servers"));

    auto list = registry.call("ai.tool_servers", Json::object());
    REQUIRE(list.ok);
    CHECK(list.result["configured"] == 3);
    REQUIRE(list.result["servers"].size() == 3);
    CHECK(list.result["servers"][1]["name"] == "needskey");
    CHECK_FALSE(list.result["servers"][1]["problem"].get<std::string>().empty());
    const Json& scenario = list.result["servers"][0];
    CHECK(scenario["name"] == "scenario");
    CHECK(scenario["keySource"] == "env:SCENARIO_KEY");
    CHECK(scenario["note"] == "AI game art.");
    CHECK_FALSE(scenario.contains("connected"));
    CHECK(server.requests.empty());  // listing contacts nobody
    CHECK_FALSE(has(list.result.dump(), "env-key-77"));
    CHECK_FALSE(has(list.result.dump(), "must-not-be-listed"));

    auto tested = registry.call("ai.tool_servers", Json::object({{"test", true}}));
    REQUIRE(tested.ok);
    const Json& servers = tested.result["servers"];
    CHECK(servers[1]["connected"] == false);  // needskey: the missing key is the error, nothing is sent
    CHECK(servers[2]["connected"] == false);  // off
    CHECK(has(servers[2]["error"].get<std::string>(), "turned off"));
    CHECK(servers[0]["connected"] == true);
    CHECK(servers[0]["server"] == "Fake Scenario 1.2.0");
    CHECK(servers[0]["tools"].size() == 2);
    CHECK(servers[0]["tools"][0]["name"] == "tool_0");
    CHECK(header_of(server.requests[0], "Authorization") == "Basic env-key-77");
    CHECK_FALSE(has(tested.result.dump(), "env-key-77"));

    auto one = registry.call("ai.tool_servers", Json::object({{"name", "scenario"}}));
    REQUIRE(one.ok);
    CHECK(one.result["servers"].size() == 1);
    auto unknown = registry.call("ai.tool_servers", Json::object({{"name", "scenaro"}}));
    CHECK_FALSE(unknown.ok);
    CHECK(unknown.error["code"] == "unknown_tool_server");
    CHECK(has(unknown.error["hint"].get<std::string>(), "scenario"));  // did you mean

    auto providers = registry.call("ai.providers", Json::object());
    REQUIRE(providers.ok);
    CHECK(providers.result["toolServers"].size() == 3);
    CHECK_FALSE(has(providers.result.dump(), "env-key-77"));
}
