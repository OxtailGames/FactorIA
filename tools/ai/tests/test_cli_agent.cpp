#include <atomic>
#include <chrono>
#include <thread>

#include "fa/ai/cli_agent.h"
#include "fa/ai/process.h"
#include "fa/core/strings.h"
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
    // the built-in argv asks for stream-json on stdin: ONE JSON line holding the prompt
    CHECK(argv.find("--input-format\nstream-json\n") != std::string::npos);
    {
        std::string line = argv.substr(argv.rfind("stdin:") + 6);
        Json msg = Json::parse(line);
        CHECK(msg["type"] == "user");
        CHECK(msg["message"]["content"][0]["text"] == "Make a game");
    }
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

// ---------------------------------------------------------------------------------------------------------------------
// Conversations through the fake claude CLI (fake_claude.sh on POSIX, fake_claude.cmd on Windows): what is sent on
// stdin, what argv a follow-up gets, what the usage events carry. Both fakes record one block per invocation: the argv,
// one argument per line, then "stdin:<what the CLI was sent>".

namespace {

std::string fake_claude_path() {
#ifdef _WIN32
    return std::filesystem::path(std::string(FA_AI_FIXTURES) + "/fake_claude.cmd").make_preferred().string();
#else
    return std::string(FA_AI_FIXTURES) + "/fake_claude.sh";
#endif
}

struct Recorded {
    std::vector<std::string> argv;
    std::string stdinText;
    bool has(const std::string& a) const { return std::find(argv.begin(), argv.end(), a) != argv.end(); }
    bool has_pair(const std::string& a, const std::string& b) const {
        for (std::size_t i = 0; i + 1 < argv.size(); ++i)
            if (argv[i] == a && argv[i + 1] == b) return true;
        return false;
    }
};

// A one-line stdin ends an invocation. (Multi-line text prompts are read with read_file instead.)
std::vector<Recorded> parse_recorded(const std::string& file) {
    std::vector<Recorded> out;
    Recorded cur;
    std::string text = read_file(file);
    std::size_t pos = 0;
    while (pos < text.size()) {
        std::size_t nl = text.find('\n', pos);
        if (nl == std::string::npos) nl = text.size();
        std::string line = text.substr(pos, nl - pos);
        if (!line.empty() && line.back() == '\r') line.pop_back();  // the Windows fake writes CRLF
        pos = nl + 1;
        if (line.rfind("stdin:", 0) == 0) {
            cur.stdinText = line.substr(6);
            out.push_back(std::move(cur));
            cur = {};
        } else {
            cur.argv.push_back(line);
        }
    }
    return out;
}

// 1x1 PNG
constexpr const char* kTinyPng =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==";

std::string write_tiny_png(const std::filesystem::path& file) {
    auto bytes = fa::base64_decode(kTinyPng);
    std::ofstream(file, std::ios::binary).write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
    return file.string();
}

}  // namespace

TEST_CASE("claude-code CLI: stdin is stream-json with the images; a follow-up resumes; usage events") {
    TempDir dir, scratch;
    const std::string argvFile = (scratch.path / "argv.txt").string();
    ProviderConfig cfg = default_config().providers["claude-code"];
    cfg.command = fake_claude_path();
    cfg.env["FAKE_ARGV_FILE"] = argvFile;

    CliRunRequest req;
    req.prompt = "Make a game";
    req.model = "sonnet";
    req.projectDir = dir.str();
    req.images = {{"image/png", "QUJD"}};
    std::vector<AgentEvent> events;
    auto r = CliAgent(cfg).run(req, [&](const AgentEvent& e) { events.push_back(e); }, nullptr);
    REQUIRE(r);
    CHECK(r->ok);
    CHECK(r->sessionId == "sess-1");
    auto recs = parse_recorded(argvFile);
    REQUIRE(recs.size() == 1);
    CHECK(recs[0].has_pair("--input-format", "stream-json"));
    CHECK_FALSE(recs[0].has("--resume"));  // the first message has nothing to resume
    Json msg = Json::parse(recs[0].stdinText);
    CHECK(msg["type"] == "user");
    CHECK(msg["message"]["content"][0]["text"] == "Make a game");
    CHECK(msg["message"]["content"][1]["source"]["media_type"] == "image/png");
    CHECK(msg["message"]["content"][1]["source"]["data"] == "QUJD");

    // plan windows, context in use, and the window size come out as Usage events
    const AgentEvent* limits = nullptr;
    const AgentEvent* context = nullptr;
    u64 window = 0;
    for (const auto& e : events) {
        if (e.type != AgentEvent::Type::Usage) continue;
        if (!e.limits.empty()) limits = &e;
        if (e.contextTokens > 0 && !context) context = &e;
        window = std::max(window, e.contextWindow);
    }
    REQUIRE(limits);
    REQUIRE(limits->limits.size() == 2);
    CHECK(limits->limits[0].name == "five_hour");
    CHECK(limits->limits[0].usedFraction == doctest::Approx(0.06));
    CHECK(limits->limits[1].name == "seven_day");
    REQUIRE(context);
    CHECK(context->contextTokens == 5002);  // 2 + 1000 + 4000
    CHECK(window == 1000000);

    // follow-up: --resume <id>, no picture
    std::filesystem::remove(argvFile);
    req.sessionId = r->sessionId;
    req.images.clear();
    req.prompt = "Now add a coin";
    auto r2 = CliAgent(cfg).run(req, nullptr, nullptr);
    REQUIRE(r2);
    CHECK(r2->ok);
    recs = parse_recorded(argvFile);
    REQUIRE(recs.size() == 1);
    CHECK(recs[0].has_pair("--resume", "sess-1"));
    CHECK(Json::parse(recs[0].stdinText)["message"]["content"].size() == 1);
}

TEST_CASE("AgentSession with the Claude CLI: follow-ups resume and send only the task; each message reports its own cost") {
    TempDir dir, scratch;
    const std::string argvFile = (scratch.path / "argv.txt").string();
    CommandRegistry registry = make_registry();
    AiConfig cfg = default_config();
    cfg.providers["claude-code"].command = fake_claude_path();
    cfg.providers["claude-code"].env["FAKE_ARGV_FILE"] = argvFile;
    cfg.roles["orchestrator"] = {"claude-code", "sonnet", "", 0};
    std::vector<AgentEvent> events;
    auto run = [&](const std::string& task, const Conversation& conv, const std::vector<std::string>& images = {}) {
        SessionOptions so;
        so.projectDir = dir.str();
        so.conversation = conv;
        AgentSession s(registry, cfg, so);
        s.set_event_handler([&](const AgentEvent& e) { events.push_back(e); });
        return s.run(task, images);
    };

    SessionResult r1 = run("Make a game", {});
    REQUIRE(r1.ok);
    CHECK(r1.conversation.key == "claude-code");
    CHECK(r1.conversation.cliSessionId == "sess-1");
    CHECK(r1.conversation.cliCostUsd == doctest::Approx(0.0123));
    CHECK(r1.costUsd == doctest::Approx(0.0123));
    auto recs = parse_recorded(argvFile);
    REQUIRE(recs.size() == 1);
    CHECK_FALSE(recs[0].has("--resume"));
    std::string first = Json::parse(recs[0].stdinText)["message"]["content"][0]["text"].get<std::string>();
    CHECK(first.find("FactorIA engine guide") != std::string::npos);  // the first message carries the system prompt
    CHECK(first.find("# Task\nMake a game") != std::string::npos);
    CHECK(first.find("Use ai_run {role, task}") != std::string::npos);  // the CLI orchestrator delegates over MCP

    // Claude Code reports the running total of a resumed session: this message costs the difference
    std::filesystem::remove(argvFile);
    cfg.providers["claude-code"].env["FAKE_COST"] = "0.0200";
    events.clear();
    SessionResult r2 = run("Add a coin", r1.conversation);
    REQUIRE(r2.ok);
    CHECK(r2.costUsd == doctest::Approx(0.0077));
    CHECK(r2.conversation.cliCostUsd == doctest::Approx(0.02));
    CHECK(r2.conversation.cliSessionId == "sess-1");
    recs = parse_recorded(argvFile);
    REQUIRE(recs.size() == 1);
    CHECK(recs[0].has_pair("--resume", "sess-1"));
    CHECK(Json::parse(recs[0].stdinText)["message"]["content"][0]["text"] == "Add a coin");  // only the task
    const AgentEvent* lastUsage = nullptr;
    for (const auto& e : events) {
        if (e.type == AgentEvent::Type::Usage && e.usage.total() > 0) lastUsage = &e;
    }
    REQUIRE(lastUsage);
    CHECK(lastUsage->costUsd == doctest::Approx(0.0077));  // the event agrees with the result

    // a picture goes with the message
    std::filesystem::remove(argvFile);
    SessionResult r3 = run("Look", r2.conversation, {write_tiny_png(dir.path / "pic.png")});
    REQUIRE(r3.ok);
    recs = parse_recorded(argvFile);
    REQUIRE(recs.size() == 1);
    CHECK(Json::parse(recs[0].stdinText)["message"]["content"][1]["source"]["data"] == kTinyPng);

    // a conversation of another provider is not resumed
    std::filesystem::remove(argvFile);
    Conversation foreign = r3.conversation;
    foreign.key = "codex";
    SessionResult r4 = run("Hello", foreign);
    REQUIRE(r4.ok);
    recs = parse_recorded(argvFile);
    REQUIRE(recs.size() == 1);
    CHECK_FALSE(recs[0].has("--resume"));
    CHECK(Json::parse(recs[0].stdinText)["message"]["content"][0]["text"].get<std::string>().find("# Task\nHello") != std::string::npos);
    CHECK(r4.conversation.key == "claude-code");

    // the CLI forgot the session: carry on in a new one and say so
    std::filesystem::remove(argvFile);
    cfg.providers["claude-code"].env["FAKE_MODE"] = "resume_fails";
    events.clear();
    SessionResult r5 = run("Again", r2.conversation);
    REQUIRE(r5.ok);
    CHECK(r5.conversation.cliSessionId == "sess-1");
    recs = parse_recorded(argvFile);
    REQUIRE(recs.size() == 2);
    CHECK(recs[0].has("--resume"));
    CHECK_FALSE(recs[1].has("--resume"));
    CHECK(Json::parse(recs[1].stdinText)["message"]["content"][0]["text"].get<std::string>().find("# Task\nAgain") != std::string::npos);
    bool told = false;
    for (const auto& e : events) told = told || (e.type == AgentEvent::Type::Info && e.text.find("could not be resumed") != std::string::npos);
    CHECK(told);
    CHECK(r5.costUsd == doctest::Approx(0.02));  // the fresh session's own total
}

TEST_CASE("images reach a CLI without stream-json input as file paths in the prompt") {
    TempDir dir, scratch;
    const std::string argvFile = (scratch.path / "argv.txt").string();
    CommandRegistry registry = make_registry();
    AiConfig cfg = default_config();
    ProviderConfig& cc = cfg.providers["claude-code"];
    cc.command = fake_claude_path();
    cc.env["FAKE_ARGV_FILE"] = argvFile;
    cc.argv = {"-p", "--output-format", "stream-json", "--verbose"};  // no --input-format: stdin is plain text
    cfg.roles["orchestrator"] = {"claude-code", "sonnet", "", 0};
    const std::string pic = write_tiny_png(dir.path / "shot.png");
    SessionOptions so;
    so.projectDir = dir.str();
    AgentSession s(registry, cfg, so);
    auto r = s.run("Fix what the picture shows", {pic});
    REQUIRE(r.ok);
    std::string raw;
    for (char c : read_file(argvFile)) if (c != '\r') raw += c;
    CHECK(raw.find("-p\n--output-format\nstream-json\n--verbose\n") == 0);  // no --input-format, no --resume
    CHECK(raw.find("Fix what the picture shows\n\nAttached images (read them): " + pic) != std::string::npos);
    CHECK(raw.find("\"type\":\"user\"") == std::string::npos);  // plain text, not a JSON message
    CHECK(r.conversation.cliSessionId.empty());  // this template cannot resume
}
