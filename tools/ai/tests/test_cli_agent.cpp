#include <atomic>
#include <chrono>
#include <thread>

#include "fa/ai/cli_agent.h"
#include "fa/ai/process.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

#ifndef _WIN32

static std::string script(const char* name) { return std::string(FA_AI_FIXTURES) + "/" + name; }

static ProviderConfig claude_cfg() {
    ProviderConfig c = default_config().providers["claude-code"];
    c.command = script("fake_claude.sh");
    return c;
}

TEST_CASE("process runner: lines, stderr, exit code, env, cwd") {
    TempDir dir;
    ProcessOptions po;
    po.argv = {"sh", "-c", "echo one; echo two >&2; echo \"$FA_TEST_VAR\"; pwd; printf partial; exit 3"};
    po.env["FA_TEST_VAR"] = "hello";
    po.workingDir = dir.str();
    std::vector<std::string> lines, errs;
    po.onStdoutLine = [&](std::string_view l) { lines.emplace_back(l); };
    po.onStderrLine = [&](std::string_view l) { errs.emplace_back(l); };
    auto r = run_process(po);
    REQUIRE(r);
    CHECK(r->exitCode == 3);
    REQUIRE(lines.size() == 4);
    CHECK(lines[0] == "one");
    CHECK(lines[1] == "hello");
    CHECK(std::filesystem::equivalent(lines[2], dir.path));
    CHECK(lines[3] == "partial");  // trailing line without newline is flushed
    REQUIRE(errs.size() == 1);
    CHECK(errs[0] == "two");
    CHECK(r->stderrText == "two\n");
}

TEST_CASE("process runner: unset env, missing executable, which") {
    ProcessOptions po;
    po.argv = {"sh", "-c", "echo \"[${HOME-unset}]\""};
    po.unsetEnv = {"HOME"};
    auto r = run_process(po);
    REQUIRE(r);
    CHECK(r->stdoutText == "[unset]\n");

    ProcessOptions bad;
    bad.argv = {"definitely-not-a-real-program-xyz"};
    auto b = run_process(bad);
    REQUIRE_FALSE(b.ok());
    CHECK(b.error().message.find("definitely-not-a-real-program-xyz") != std::string::npos);
    CHECK_FALSE(b.error().hint.empty());

    CHECK_FALSE(which("sh").empty());
    CHECK(which("definitely-not-a-real-program-xyz").empty());
    CHECK(which("/bin/sh") == "/bin/sh");
}

TEST_CASE("process runner: lines arrive incrementally and cancel kills the process tree") {
    CancelFlag cancel{false};
    ProcessOptions po;
    po.argv = {"sh", "-c", "echo first; sleep 30; echo never"};
    po.cancel = &cancel;
    std::vector<std::string> lines;
    po.onStdoutLine = [&](std::string_view l) {
        lines.emplace_back(l);
        cancel = true;  // cancel as soon as the first line is seen
    };
    auto t0 = std::chrono::steady_clock::now();
    auto r = run_process(po);
    auto secs = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    REQUIRE(r);
    CHECK(r->cancelled);
    CHECK(lines == std::vector<std::string>{"first"});
    CHECK(secs < 10);
}

TEST_CASE("process runner: stdin text") {
    ProcessOptions po;
    po.argv = {"sh", "-c", "cat"};
    po.stdinText = "line one\nline two & \"quoted\" $HOME\n";
    auto r = run_process(po);
    REQUIRE(r);
    CHECK(r->stdoutText == po.stdinText);
}

TEST_CASE("process runner: timeout") {
    ProcessOptions po;
    po.argv = {"sh", "-c", "sleep 30"};
    po.timeoutSeconds = 0.3;
    auto r = run_process(po);
    REQUIRE(r);
    CHECK(r->timedOut);
}

TEST_CASE("argv template expansion") {
    CliRunRequest req{"do it", "sonnet", "/proj dir"};
    auto a = expand_cli_argv(default_cli_argv(ProviderKind::ClaudeCode), req, "/proj dir/mcp.json", "factoria");
    std::vector<std::string> expected{"-p", "--output-format", "stream-json", "--verbose", "--model", "sonnet",
                                      "--mcp-config", "/proj dir/mcp.json", "--allowedTools", "mcp__factoria",
                                      "--permission-mode", "acceptEdits"};
    CHECK(a == expected);

    auto c = expand_cli_argv(default_cli_argv(ProviderKind::Codex), req, "", "factoria");
    std::vector<std::string> cx{"exec", "--json", "-m", "sonnet", "-c", "mcp_servers.factoria.command=\"factoria\"",
                                "-c", "mcp_servers.factoria.args=[\"mcp\",\"--project\",\"/proj dir\"]", "-"};
    CHECK(c == cx);

    // no model => "-m" and its value disappear
    CliRunRequest nomodel{"x", "", "/p"};
    auto d = expand_cli_argv(default_cli_argv(ProviderKind::Codex), nomodel, "", "factoria");
    CHECK(std::find(d.begin(), d.end(), "-m") == d.end());
    CHECK(d.size() == 7);

    auto g = expand_cli_argv({"--ask", "{prompt}", "--dir", "{project}", "--m={model}"}, req, "", "f");
    CHECK(g == std::vector<std::string>{"--ask", "do it", "--dir", "/proj dir", "--m=sonnet"});
}

TEST_CASE("claude-code agent: stream-json events, usage, MCP config, argv") {
    TempDir dir;
    TempDir scratch;
    std::string argvFile = (scratch.path / "argv.txt").string();
    ProviderConfig cfg = claude_cfg();
    cfg.env["FAKE_ARGV_FILE"] = argvFile;
    std::vector<AgentEvent> events;
    CliAgent agent(cfg);
    auto r = agent.run({"Make a game", "sonnet", dir.str()}, [&](const AgentEvent& e) { events.push_back(e); }, nullptr);
    REQUIRE(r);
    CHECK(r->ok);
    CHECK(r->finalText == "Done: project is valid.");
    CHECK(r->costUsd == doctest::Approx(0.0123));
    CHECK(r->usage.inputTokens == 100);
    CHECK(r->usage.outputTokens == 20);
    CHECK(r->usage.cacheReadTokens == 50);
    CHECK(r->turns == 2);
    CHECK(r->sessionId == "sess-1");

    std::string text, tools, toolEnds, infos;
    for (auto& e : events) {
        if (e.type == AgentEvent::Type::TextDelta) text += e.text + "|";
        if (e.type == AgentEvent::Type::ToolStart) tools += e.toolName + ";";
        if (e.type == AgentEvent::Type::ToolEnd) toolEnds += e.toolName + (e.isError ? "!" : "") + ":" + e.toolResult.get<std::string>() + ";";
        if (e.type == AgentEvent::Type::Info) infos += e.text;
    }
    CHECK(text.find("Looking at the project.|") != std::string::npos);
    CHECK(text.find("All good.|") != std::string::npos);
    CHECK(text.find("plain warning line that is not json\n|") != std::string::npos);  // unknown lines pass through
    CHECK(tools == "mcp__factoria__project_validate;");
    CHECK(toolEnds == "mcp__factoria__project_validate:{\"ok\":true};");
    CHECK(infos.find("MCP server 'other' is failed") != std::string::npos);

    std::string argv = read_file(argvFile);
    CHECK(argv.find("-p\n--output-format\n") == 0);
    CHECK(argv.rfind("stdin:Make a game\n") == argv.size() - std::string("stdin:Make a game\n").size());
    CHECK(argv.find("--output-format\nstream-json\n") != std::string::npos);
    CHECK(argv.find("--model\nsonnet\n") != std::string::npos);
    CHECK(argv.find("--permission-mode\nacceptEdits\n") != std::string::npos);

    // generated MCP config
    auto mcpPath = dir.path / ".factoria" / "ai" / "mcp-claude-code.json";
    REQUIRE(std::filesystem::exists(mcpPath));
    Json mcp = Json::parse(read_file(mcpPath.string()));
    CHECK(mcp["mcpServers"]["factoria"]["command"] == "factoria");
    CHECK(mcp["mcpServers"]["factoria"]["args"] == Json::parse(R"(["mcp","--project",")" + dir.str() + R"("])"));
    CHECK(argv.find("--mcp-config\n" + mcpPath.string() + "\n") != std::string::npos);
}

TEST_CASE("claude-code agent: argv template is overridable from the config") {
    TempDir dir, scratch;
    std::string argvFile = (scratch.path / "argv.txt").string();
    ProviderConfig cfg = claude_cfg();
    cfg.env["FAKE_ARGV_FILE"] = argvFile;
    cfg.argv = {"--print", "{prompt}", "--output-format", "stream-json"};
    CliAgent agent(cfg);
    auto r = agent.run({"hi", "m", dir.str()}, nullptr, nullptr);
    REQUIRE(r);
    CHECK(r->ok);
    CHECK(read_file(argvFile) == "--print\nhi\n--output-format\nstream-json\n");
}

TEST_CASE("claude-code agent: not logged in gives an actionable error") {
    TempDir dir;
    ProviderConfig cfg = claude_cfg();
    cfg.env["FAKE_MODE"] = "notloggedin";
    auto r = CliAgent(cfg).run({"x", "", dir.str()}, nullptr, nullptr);
    REQUIRE(r);
    CHECK_FALSE(r->ok);
    CHECK(r->error.find("not logged in") != std::string::npos);
    CHECK(r->hint.find("claude") != std::string::npos);
    CHECK(r->hint.find("npm i -g @anthropic-ai/claude-code") != std::string::npos);
}

TEST_CASE("claude-code agent: crash surfaces stderr, missing CLI explains how to install") {
    TempDir dir;
    ProviderConfig cfg = claude_cfg();
    cfg.env["FAKE_MODE"] = "crash";
    auto r = CliAgent(cfg).run({"x", "", dir.str()}, nullptr, nullptr);
    REQUIRE(r);
    CHECK_FALSE(r->ok);
    CHECK(r->exitCode == 3);
    CHECK(r->error.find("boom: something exploded") != std::string::npos);

    ProviderConfig missing = default_config().providers["claude-code"];
    missing.command = "definitely-not-installed-claude";
    auto m = CliAgent(missing).run({"x", "", dir.str()}, nullptr, nullptr);
    REQUIRE_FALSE(m.ok());
    CHECK(m.error().message.find("not found") != std::string::npos);
    CHECK(m.error().hint.find("npm i -g @anthropic-ai/claude-code") != std::string::npos);
    CHECK(m.error().hint.find("log in") != std::string::npos);
    ProviderConfig codex = default_config().providers["codex"];
    codex.command = "definitely-not-installed-codex";
    auto c = CliAgent(codex).run({"x", "", dir.str()}, nullptr, nullptr);
    REQUIRE_FALSE(c.ok());
    CHECK(c.error().hint.find("@openai/codex") != std::string::npos);
}

TEST_CASE("claude-code agent: cancellation kills the CLI") {
    TempDir dir;
    ProviderConfig cfg = claude_cfg();
    cfg.env["FAKE_MODE"] = "slow";
    CancelFlag cancel{false};
    std::thread t([&] {
        std::this_thread::sleep_for(std::chrono::milliseconds(400));
        cancel = true;
    });
    auto t0 = std::chrono::steady_clock::now();
    auto r = CliAgent(cfg).run({"x", "", dir.str()}, nullptr, &cancel);
    t.join();
    REQUIRE(r);
    CHECK(r->cancelled);
    CHECK_FALSE(r->ok);
    CHECK(std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < 15);
}

TEST_CASE("codex agent: JSON events and codex argv") {
    TempDir dir, scratch;
    std::string argvFile = (scratch.path / "argv.txt").string();
    ProviderConfig cfg = default_config().providers["codex"];
    cfg.command = script("fake_codex.sh");
    cfg.env["FAKE_ARGV_FILE"] = argvFile;
    std::vector<AgentEvent> events;
    auto r = CliAgent(cfg).run({"Fix bug", "gpt-x", dir.str()}, [&](const AgentEvent& e) { events.push_back(e); }, nullptr);
    REQUIRE(r);
    CHECK(r->ok);
    CHECK(r->finalText == "Validated the project.");
    CHECK(r->usage.outputTokens == 40);
    CHECK(r->usage.cacheReadTokens == 100);
    CHECK(r->usage.inputTokens == 200);
    std::string tools;
    for (auto& e : events) if (e.type == AgentEvent::Type::ToolStart) tools += e.toolName;
    CHECK(tools == "project_validate");
    std::string argv = read_file(argvFile);
    CHECK(argv.find("exec\n--json\n-m\ngpt-x\n-c\nmcp_servers.factoria.command=\"factoria\"\n-c\n") == 0);
    CHECK(argv.find("mcp_servers.factoria.args=[\"mcp\",\"--project\",\"" + dir.str() + "\"]") != std::string::npos);
    CHECK(argv.rfind("-\nstdin:Fix bug\n") == argv.size() - std::string("-\nstdin:Fix bug\n").size());
}

TEST_CASE("generic-cli: placeholders, raw text passthrough") {
    TempDir dir, scratch;
    std::string argvFile = (scratch.path / "argv.txt").string();
    ProviderConfig cfg;
    cfg.name = "my-agent";
    cfg.kind = ProviderKind::GenericCli;
    cfg.command = "sh";
    cfg.argv = {"-c", "echo \"got: $1 in $2\"; echo second", "sh", "{prompt}", "{project}"};
    std::vector<AgentEvent> events;
    auto r = CliAgent(cfg).run({"do thing", "", dir.str()}, [&](const AgentEvent& e) { events.push_back(e); }, nullptr);
    REQUIRE(r);
    CHECK(r->ok);
    CHECK(r->finalText == "got: do thing in " + dir.str() + "\nsecond\n");
    (void)argvFile;
}

#include "fa/ai/session.h"

TEST_CASE("AgentSession with a CLI provider forwards the CLI's events") {
    TempDir dir;
    CommandRegistry registry = make_registry();
    AiConfig cfg = default_config();
    cfg.providers["claude-code"].command = script("fake_claude.sh");
    cfg.roles["orchestrator"] = {"claude-code", "sonnet", "", 0};
    SessionOptions so;
    so.projectDir = dir.str();
    AgentSession session(registry, cfg, so);
    std::vector<AgentEvent> events;
    session.set_event_handler([&](const AgentEvent& e) { events.push_back(e); });
    auto r = session.run("Do it");
    CHECK(r.ok);
    CHECK(r.finalText == "Done: project is valid.");
    CHECK(r.costUsd == doctest::Approx(0.0123));
    CHECK(r.usage.outputTokens == 20);
    bool sawTool = false, sawDone = false;
    for (auto& e : events) {
        sawTool = sawTool || (e.type == AgentEvent::Type::ToolStart && e.toolName == "mcp__factoria__project_validate");
        sawDone = sawDone || e.type == AgentEvent::Type::Done;
    }
    CHECK(sawTool);
    CHECK(sawDone);
    REQUIRE_FALSE(r.transcriptPath.empty());

    // login problem is reported through the session with the hint
    cfg.providers["claude-code"].env["FAKE_MODE"] = "notloggedin";
    AgentSession s2(registry, cfg, so);
    auto bad = s2.run("Do it");
    CHECK_FALSE(bad.ok);
    CHECK(bad.hint.find("claude") != std::string::npos);
}

#endif  // !_WIN32

#ifdef _WIN32

// npm installs claude and codex as .cmd files, which run through cmd.exe.
TEST_CASE("process runner: .cmd in a path with spaces, multi-line stdin, unsafe arguments refused") {
    TempDir dir;
    std::filesystem::create_directories(dir.path / "npm dir");
    std::string cmd = (dir.path / "npm dir" / "fake cli.cmd").string();
    std::ofstream(cmd) << "@echo arg:%~1\r\n@findstr \"^\"\r\n";

    ProcessOptions po;
    po.argv = {cmd, "two words"};
    po.stdinText = "line one\nline two & \"quoted\" %PATH%\n";
    std::vector<std::string> lines;
    po.onStdoutLine = [&](std::string_view l) { lines.emplace_back(l); };
    auto r = run_process(po);
    REQUIRE(r);
    CHECK(r->exitCode == 0);
    CHECK(lines == std::vector<std::string>{"arg:two words", "line one", "line two & \"quoted\" %PATH%"});

    for (const char* arg : {"line one\nline two", "100%", "a & calc"}) {
        ProcessOptions bad;
        bad.argv = {cmd, arg};
        auto b = run_process(bad);
        REQUIRE_FALSE(b.ok());
        CHECK(b.error().message.find(".cmd/.bat") != std::string::npos);
        CHECK(b.error().hint.find("{prompt}") != std::string::npos);
    }
}

#endif  // _WIN32
