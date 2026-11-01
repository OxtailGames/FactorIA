// Hooks for every provider: the events and the decisions in the built-in loop (fake provider), JavaScript hook modules, the project
// trust gate, timeouts and failing hooks, the beforeCommand / afterCommand hooks around registry commands for a caller that is not an
// AI, the ai.hooks / ai.hooks_test commands and the Claude Code settings made from the same entries.
#include <algorithm>
#include <cstdlib>
#include <fstream>

#include "fa/ai/command_hooks.h"
#include "fa/ai/commands.h"
#include "fa/ai/extension_plan.h"
#include "fa/ai/extensions.h"
#include "fa/ai/hooks.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;
namespace fsys = std::filesystem;

namespace {

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

void write_file(const fsys::path& path, const std::string& text) {
    fsys::create_directories(path.parent_path());
    std::ofstream(path, std::ios::binary) << text;
}


ToolCall call(const std::string& id, const std::string& name, Json input = Json::object()) {
    ToolCall c;
    c.id = id;
    c.name = name;
    c.input = std::move(input);
    return c;
}

// {"PreToolUse":[{"matcher":m,"hooks":[{"type":"command","command":c}]}]}
Json command_hook(const std::string& event, const std::string& matcher, const std::string& command, double timeout = 0) {
    Json h = Json::object({{"type", "command"}, {"command", command}});
    if (timeout > 0) h["timeout"] = timeout;
    Json group = Json::object({{"hooks", Json::array({h})}});
    if (!matcher.empty()) group["matcher"] = matcher;
    return Json::object({{event, Json::array({group})}});
}
Json js_hook(const std::string& event, const std::string& matcher, const std::string& module) {
    Json group = Json::object({{"hooks", Json::array({Json::object({{"type", "js"}, {"module", module}})})}});
    if (!matcher.empty()) group["matcher"] = matcher;
    return Json::object({{event, Json::array({group})}});
}
// Two hooks objects in one; groups of the same event are put one after the other.
Json merged(Json a, const Json& b) {
    for (auto it = b.begin(); it != b.end(); ++it) {
        if (a.contains(it.key())) {
            for (const Json& g : it.value()) a[it.key()].push_back(g);
        } else {
            a[it.key()] = it.value();
        }
    }
    return a;
}

Extension hooks_entry(const std::string& name, Json hooks, const std::string& source = "user") {
    Extension e;
    e.kind = ExtensionKind::Hooks;
    e.name = name;
    e.source = source;
    e.hooks = std::move(hooks);
    return e;
}

std::vector<Json> transcript_lines(const std::string& path, const std::string& kind) {
    std::vector<Json> out;
    std::ifstream f(path);
    std::string line;
    while (std::getline(f, line)) {
        Json j = Json::parse(line, nullptr, false);
        if (j.is_object() && j.value("kind", std::string()) == kind) out.push_back(j);
    }
    return out;
}

struct HookHarness {
    TempDir proj, home;
    CommandRegistry registry = make_registry();
    std::shared_ptr<FakeProvider> provider = std::make_shared<FakeProvider>();
    AiConfig cfg = default_config();
    std::vector<AgentEvent> events;
    int touched = 0;  // how often the command test.touch ran

    HookHarness() {
        cfg.sourcePath = (home.path / "ai.json").string();
        CommandInfo t;
        t.name = "test.touch";
        t.summary = "Counts its calls.";
        registry.add(t, [this](const Json&) {
            ++touched;
            return Json::object({{"touched", touched}});
        });
    }
    void add(const std::string& name, Json hooks, const std::string& source = "user") {
        cfg.extensions.entries.push_back(hooks_entry(name, std::move(hooks), source));
    }
    SessionResult run(const std::string& task) {
        SessionOptions so;
        so.projectDir = proj.str();
        so.toolCatalog = false;
        so.env = fake_env({{"HOME", home.str()}});
        so.extensionsTrustPath = (home.path / "ai-trust.json").string();
        AgentSession s(registry, cfg, so);
        s.set_provider_factory([this](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(provider);
        });
        s.set_event_handler([this](const AgentEvent& e) { events.push_back(e); });
        return s.run(task);
    }
    bool said(const std::string& part) const {
        for (const auto& e : events)
            if (e.type == AgentEvent::Type::Info && has(e.text, part)) return true;
        return false;
    }
    // The content of the tool result the model got in request `n` (the last message).
    std::string tool_result_text(std::size_t request) const {
        const Message& m = provider->requests.at(request).messages.back();
        std::string all;
        for (const ToolResult& r : m.toolResults) all += r.content + "\n";
        return all;
    }
    std::string last_user_text(std::size_t request) const {
        const auto& ms = provider->requests.at(request).messages;
        for (auto it = ms.rbegin(); it != ms.rend(); ++it)
            if (it->role == Role::User && it->toolResults.empty()) return it->text;
        return "";
    }
};

}  // namespace

// --- events, matchers, decisions (no process) ---------------------------------------------------------------------------------

TEST_CASE("hooks: event names, matchers for tools and for dotted command names") {
    CHECK(std::string(hook_event_name(HookEvent::PostToolUseFailure)) == "PostToolUseFailure");
    CHECK(parse_hook_event("beforeCommand") == HookEvent::BeforeCommand);
    CHECK_FALSE(parse_hook_event("PreCompact").has_value());
    CHECK(is_command_hook_event(HookEvent::AfterCommand));
    CHECK_FALSE(is_command_hook_event(HookEvent::Stop));
    CHECK(hook_event_can_block(HookEvent::PreToolUse));
    CHECK_FALSE(hook_event_can_block(HookEvent::PostToolUse));

    CHECK(hook_matches(HookEvent::PreToolUse, "", "anything"));
    CHECK(hook_matches(HookEvent::PreToolUse, "*", "anything"));
    CHECK(hook_matches(HookEvent::PreToolUse, "Edit|Write", "Write"));
    CHECK_FALSE(hook_matches(HookEvent::PreToolUse, "Edit|Write", "Read"));
    CHECK(hook_matches(HookEvent::PreToolUse, "scene_.*", "scene_spawn"));  // a regular expression
    CHECK(hook_matches(HookEvent::PreToolUse, "mcp__.*__spawn", "mcp__factoria__spawn"));
    CHECK(hook_matches(HookEvent::BeforeCommand, "scene.*", "scene.spawn"));
    CHECK_FALSE(hook_matches(HookEvent::BeforeCommand, "scene.*", "scenes.spawn"));
    CHECK(hook_matches(HookEvent::BeforeCommand, "assets.generate_*|game.screenshot", "assets.generate_image"));
    CHECK(hook_matches(HookEvent::BeforeCommand, "game.screenshot", "game.screenshot"));
    CHECK_FALSE(hook_matches(HookEvent::BeforeCommand, "game.screenshot", "game_screenshot"));  // the dot is a dot
    CHECK(hook_matcher_problem("Edit|Write").empty());
    CHECK(has(hook_matcher_problem("(unclosed"), "regular expression"));
}

TEST_CASE("hooks: how an answer is read for each decision") {
    auto read = [](HookEvent event, const std::string& json) {
        HookOutcome out;
        HookRunRecord rec;
        apply_hook_answer(event, Json::parse(json), "h: x", out, rec);
        return out;
    };
    HookOutcome pre = read(HookEvent::PreToolUse,
                           R"({"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"no rm"}})");
    CHECK(pre.blocked);
    CHECK(pre.reason == "no rm");
    CHECK(pre.blockedBy == "h: x");
    CHECK(read(HookEvent::PreToolUse, R"({"decision":"block","reason":"old style"})").blocked);  // the deprecated spelling still works
    CHECK(read(HookEvent::PreToolUse, R"({"hookSpecificOutput":{"permissionDecision":"allow"}})").allowed);
    HookOutcome upd = read(HookEvent::PreToolUse, R"({"hookSpecificOutput":{"updatedInput":{"limit":9}}})");
    REQUIRE(upd.updatedInput);
    CHECK((*upd.updatedInput)["limit"] == 9);

    HookOutcome ctx = read(HookEvent::UserPromptSubmit, R"({"hookSpecificOutput":{"additionalContext":"today is monday"}})");
    CHECK_FALSE(ctx.blocked);
    CHECK(ctx.context == std::vector<std::string>{"today is monday"});
    HookOutcome stop = read(HookEvent::PostToolUse, R"({"continue":false,"stopReason":"enough","systemMessage":"hello"})");
    CHECK(stop.stop);
    CHECK(stop.stopReason == "enough");
    CHECK(stop.systemMessages == std::vector<std::string>{"hello"});
    HookOutcome fb = read(HookEvent::PostToolUse, R"({"decision":"block","reason":"lint failed"})");
    CHECK_FALSE(fb.blocked);  // the tool already ran: the reason is feedback next to the result
    CHECK(fb.feedback == std::vector<std::string>{"lint failed"});
    CHECK(read(HookEvent::Stop, R"({"decision":"block","reason":"run the tests"})").blocked);
}

TEST_CASE("validate_hooks: js handlers, timeouts, the engine events and the match alias; Claude Code gets no engine events") {
    CHECK(validate_hooks(js_hook("PreToolUse", "", "hooks/guard.js"), "/hooks"));
    CHECK(validate_hooks(command_hook("beforeCommand", "scene.*", "echo", 5), "/hooks"));
    Json alias = command_hook("beforeCommand", "", "echo");
    alias["beforeCommand"][0]["match"] = "scene.*";
    CHECK(validate_hooks(alias, "/hooks"));

    auto bad_module = validate_hooks(js_hook("PreToolUse", "", "../x.js"), "/hooks");
    REQUIRE_FALSE(bad_module);
    CHECK(has(bad_module.error().message, "hooks/"));
    auto no_module = validate_hooks(Json::parse(R"({"Stop":[{"hooks":[{"type":"js"}]}]})"), "/hooks");
    REQUIRE_FALSE(no_module);
    CHECK(has(no_module.error().message, "module"));
    auto bad_timeout = validate_hooks(command_hook("Stop", "", "echo", 9999999), "/hooks");
    REQUIRE_FALSE(bad_timeout);
    CHECK(has(bad_timeout.error().message, "timeout"));
    auto bad_matcher = validate_hooks(command_hook("PreToolUse", "(oops", "echo"), "/hooks");
    REQUIRE_FALSE(bad_matcher);
    CHECK(has(bad_matcher.error().message + bad_matcher.error().hint, "regular expression"));

    Json both = merged(command_hook("beforeCommand", "scene.*", "echo a"), js_hook("PreToolUse", "scene_*", "hooks/g.js"));
    both["beforeCommand"][0]["match"] = both["beforeCommand"][0]["matcher"];
    both["beforeCommand"][0].erase("matcher");
    Json cc = hooks_for_claude_code(both, "/bin/factoria", "/proj");
    CHECK_FALSE(cc.contains("beforeCommand"));
    REQUIRE(cc.contains("PreToolUse"));
    const Json& handler = cc["PreToolUse"][0]["hooks"][0];
    CHECK(handler["type"] == "command");
    CHECK(has(handler["command"].get<std::string>(), "hooks run hooks/g.js --project /proj"));
    CHECK(hooks_for_claude_code(command_hook("afterCommand", "", "echo"), "f", "/p").empty());
}

// --- JavaScript hooks (every platform) ---------------------------------------------------------------------------------------

TEST_CASE("JS hook module: blocks a tool, adds context, runs without trust and is sandboxed") {
    HookHarness h;
    write_file(h.proj.path / "hooks" / "guard.js",
               "export function PreToolUse(input) {\n"
               "  if (input.tool_name === 'project_validate') return { decision: 'block', reason: 'js says no to ' + input.tool_name };\n"
               "}\n"
               "export function SessionStart() { return { hookSpecificOutput: { additionalContext: 'js context' } }; }\n");
    // from a project's extensions file: a JS hook starts no program, so it needs no trust
    write_file(h.proj.path / ".factoria" / "extensions.json",
               Json::object({{"hooks", Json::object({{"guard", Json::object({{"hooks", merged(js_hook("PreToolUse", "", "hooks/guard.js"),
                                                                                              js_hook("SessionStart", "", "hooks/guard.js"))}})}})}})
                   .dump());
    h.provider->script = {tool_response({call("t1", "project_validate"), call("t2", "scene_list_entities")}), text_response("done")};
    auto r = h.run("go");
    REQUIRE(r.ok);
    const std::string results = h.tool_result_text(1);
    CHECK(has(results, "blocked_by_hook"));
    CHECK(has(results, "js says no to project_validate"));
    CHECK(has(results, "\"count\":2"));  // the other call went ahead
    CHECK(has(h.last_user_text(0), "js context"));
    auto lines = transcript_lines(r.transcriptPath, "hook");
    REQUIRE(lines.size() >= 3);
    CHECK(lines[0]["type"] == "js");
    CHECK(lines[0]["event"] == "SessionStart");
    CHECK(lines[0]["failed"] == false);
}

TEST_CASE("JS hook module: a module that throws, one that never ends and one that reaches outside are reported, not silent") {
    HookHarness h;
    write_file(h.proj.path / "hooks" / "boom.js", "export function PreToolUse() { throw new Error('exploded'); }\n");
    write_file(h.proj.path / "hooks" / "loop.js", "export function PostToolUse() { while (true) {} }\n");
    write_file(h.proj.path / "hooks" / "peek.js", "import x from '../secret.js';\nexport function Stop() {}\n");
    Json setup = js_hook("PreToolUse", "", "hooks/boom.js");
    Json loop = js_hook("PostToolUse", "", "hooks/loop.js");
    loop["PostToolUse"][0]["hooks"][0]["timeout"] = 0.5;
    h.add("boom", merged(merged(setup, loop), js_hook("Stop", "", "hooks/peek.js")));
    h.provider->script = {tool_response({call("t1", "scene_list_entities")}), text_response("done")};
    auto r = h.run("go");
    REQUIRE(r.ok);  // a failing hook never stops the run by itself
    CHECK(has(h.tool_result_text(1), "\"count\":2"));
    auto lines = transcript_lines(r.transcriptPath, "hook");
    int failed = 0;
    bool timedOut = false, exploded = false;
    for (const Json& l : lines) {
        if (l.value("failed", false)) ++failed;
        timedOut = timedOut || l.value("timedOut", false);
        exploded = exploded || has(l.value("error", std::string()), "exploded");
    }
    CHECK(failed == 3);
    CHECK(timedOut);
    CHECK(exploded);
    CHECK(h.said("Hook failed (PreToolUse"));
    CHECK(h.said("Hook failed (PostToolUse"));
    CHECK(h.said("Hook failed (Stop"));
}

TEST_CASE("hook_js: a module outside hooks/ and a missing handler teach") {
    TempDir proj;
    write_file(proj.path / "hooks" / "empty.js", "export const x = 1;\n");
    auto bad = hook_module_problem("scripts/x.js");
    CHECK(has(bad, "hooks/"));
    CHECK(hook_module_problem("hooks/a.js").empty());
    CHECK(has(hook_module_problem("hooks/a.txt"), ".js"));
}

// --- the built-in loop, hooks that start programs (POSIX shell) ---------------------------------------------------------------
#ifndef _WIN32

TEST_CASE("session: SessionStart and UserPromptSubmit add context to the first message; SessionEnd runs at the end") {
    HookHarness h;
    h.add("ctx", merged(merged(command_hook("SessionStart", "startup", R"(echo '{"hookSpecificOutput":{"additionalContext":"branch is main"}}')"),
                               command_hook("UserPromptSubmit", "", "echo the date is fixed")),
                        command_hook("SessionEnd", "", R"(cat > "$FACTORIA_PROJECT_DIR/end.json")")));
    h.provider->script = {text_response("hi")};
    auto r = h.run("Hello model");
    REQUIRE(r.ok);
    const std::string sent = h.last_user_text(0);
    CHECK(has(sent, "Hello model"));
    CHECK(has(sent, "branch is main"));
    CHECK(has(sent, "the date is fixed"));  // plain stdout of UserPromptSubmit is context
    REQUIRE(fsys::exists(h.proj.path / "end.json"));
    const Json end = Json::parse(read_file((h.proj.path / "end.json").string()));
    CHECK(end["hook_event_name"] == "SessionEnd");
    CHECK(end["reason"] == "end_turn");
    CHECK(end.contains("session_id"));
    CHECK(end.contains("transcript_path"));
    CHECK(end["cwd"] == h.proj.str());
    auto lines = transcript_lines(r.transcriptPath, "hook");
    CHECK(lines.size() == 3);
    const auto user = transcript_lines(r.transcriptPath, "user");
    REQUIRE_FALSE(user.empty());
    CHECK(user[0]["text"] == "Hello model");           // the log keeps what the user wrote
    CHECK(has(user[0].value("hookContext", std::string()), "branch is main"));
}

TEST_CASE("session: a UserPromptSubmit hook that blocks ends the run before the model is asked") {
    HookHarness h;
    h.add("guard", command_hook("UserPromptSubmit", "", R"(echo '{"decision":"block","reason":"no secrets in prompts"}')"));
    h.provider->script = {text_response("never")};
    auto r = h.run("my password is hunter2");
    REQUIRE_FALSE(r.ok);
    CHECK(r.stopReason == "hook_blocked");
    CHECK(has(r.error, "no secrets in prompts"));
    CHECK(h.provider->requests.empty());
}

TEST_CASE("session: PreToolUse block (JSON and exit 2) with the reason, updatedInput, and a matcher that spares other tools") {
    HookHarness h;
    h.add("pre", merged(merged(merged(command_hook("PreToolUse", "project_validate",
                                                   R"(echo '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"not now"}}')"),
                                   command_hook("PreToolUse", "game_screenshot", "echo 'screenshots are off' >&2; exit 2")),
                               command_hook("PreToolUse", "scene_list_entities", R"(echo '{"hookSpecificOutput":{"updatedInput":{"limit":7}}}')")),
                        Json::object()));
    h.provider->script = {tool_response({call("a", "project_validate"), call("b", "game_screenshot"),
                                         call("c", "scene_list_entities", Json::object({{"limit", 1}})), call("d", "test_touch")}),
                          text_response("ok")};
    auto r = h.run("go");
    REQUIRE(r.ok);
    const std::string results = h.tool_result_text(1);
    CHECK(has(results, "blocked_by_hook"));
    CHECK(has(results, "not now"));
    CHECK(has(results, "screenshots are off"));
    CHECK(has(results, "\"limit\":7"));  // updatedInput replaced the arguments
    CHECK(h.touched == 1);               // the matchers did not catch test_touch
    int errors = 0;
    for (const ToolResult& tr : h.provider->requests[1].messages.back().toolResults) errors += tr.isError ? 1 : 0;
    CHECK(errors == 2);
}

TEST_CASE("session: PreToolUse sees the command a tool_call wrapper names") {
    HookHarness h;
    h.add("pre", command_hook("PreToolUse", "scene_list_entities", R"(echo '{"decision":"block","reason":"wrapped"}')"));
    h.provider->script = {tool_response({call("a", "tool_call", Json::object({{"command", "scene.list_entities"}, {"arguments", Json::object()}}))}),
                          text_response("ok")};
    CommandInfo big;  // enough deferred definitions for the catalog to pay off
    big.name = "zzz.big";
    big.summary = "A command with a long description.";
    big.description = std::string(8000, 'x');
    h.registry.add(big, [](const Json&) { return Json::object(); });
    SessionOptions so;
    // the catalog is on by default: the model calls commands through tool_call
    so.projectDir = h.proj.str();
    so.env = fake_env({{"HOME", h.home.str()}});
    so.extensionsTrustPath = (h.home.path / "ai-trust.json").string();
    AgentSession s(h.registry, h.cfg, so);
    s.set_provider_factory([&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> { return std::static_pointer_cast<ChatProvider>(h.provider); });
    REQUIRE(s.run("go").ok);
    CHECK(has(h.tool_result_text(1), "wrapped"));
}

TEST_CASE("session: PostToolUse adds context and feedback to the result, PostToolUseFailure sees the error") {
    HookHarness h;
    h.add("post", merged(command_hook("PostToolUse", "scene_list_entities", R"(echo '{"decision":"block","reason":"too few entities","hookSpecificOutput":{"additionalContext":"remember the limit"}}')"),
                         command_hook("PostToolUseFailure", "", R"(cat > "$FACTORIA_PROJECT_DIR/failure.json")")));
    h.provider->script = {tool_response({call("a", "scene_list_entities"), call("b", "project_validate")}), text_response("ok")};
    auto r = h.run("go");
    REQUIRE(r.ok);
    const std::string results = h.tool_result_text(1);
    CHECK(has(results, "[Hook feedback]"));
    CHECK(has(results, "too few entities"));
    CHECK(has(results, "remember the limit"));
    REQUIRE(fsys::exists(h.proj.path / "failure.json"));
    const Json f = Json::parse(read_file((h.proj.path / "failure.json").string()));
    CHECK(f["hook_event_name"] == "PostToolUseFailure");
    CHECK(f["tool_name"] == "project_validate");
    CHECK(has(f["error"].get<std::string>(), "scene main is broken"));
}

TEST_CASE("session: a Stop hook that blocks makes the model continue (capped); continue:false ends the run") {
    {
        HookHarness h;
        // refuses the first end only
        h.add("stop", command_hook("Stop", "", R"(if [ -f "$FACTORIA_PROJECT_DIR/once" ]; then exit 0; fi; touch "$FACTORIA_PROJECT_DIR/once"; echo '{"decision":"block","reason":"run the tests first"}')"));
        h.provider->script = {text_response("done"), text_response("tests run")};
        auto r = h.run("go");
        REQUIRE(r.ok);
        CHECK(r.finalText == "tests run");
        REQUIRE(h.provider->requests.size() == 2);
        CHECK(has(h.last_user_text(1), "[Stop hook] run the tests first"));
        CHECK(h.said("A Stop hook asked the model to continue"));
    }
    {
        HookHarness h;
        h.add("stop", command_hook("Stop", "", R"(echo '{"decision":"block","reason":"again"}')"));  // never satisfied
        for (int i = 0; i < 12; ++i) h.provider->script.push_back(text_response("done"));
        auto r = h.run("go");
        REQUIRE(r.ok);
        CHECK(h.provider->requests.size() == 9);  // 8 continuations, then the run ends anyway
        CHECK(h.said("kept refusing"));
    }
    {
        HookHarness h;
        h.add("halt", command_hook("PostToolUse", "", R"(echo '{"continue":false,"stopReason":"budget guard"}')"));
        h.provider->script = {tool_response({call("a", "scene_list_entities")}), text_response("never")};
        auto r = h.run("go");
        REQUIRE_FALSE(r.ok);
        CHECK(r.stopReason == "hook_stop");
        CHECK(has(r.error, "budget guard"));
        CHECK(h.provider->requests.size() == 1);
    }
}

TEST_CASE("session: a hook that times out or exits with another code is reported with what to do, and the run goes on") {
    HookHarness h;
    h.add("slow", command_hook("PreToolUse", "scene_list_entities", "sleep 5", 0.3));
    h.add("broken", command_hook("PostToolUse", "", "echo 'bad config' >&2; exit 1"));
    h.provider->script = {tool_response({call("a", "scene_list_entities")}), text_response("ok")};
    auto r = h.run("go");
    REQUIRE(r.ok);
    CHECK(has(h.tool_result_text(1), "\"count\":2"));
    auto lines = transcript_lines(r.transcriptPath, "hook");
    REQUIRE(lines.size() == 2);
    CHECK(lines[0]["timedOut"] == true);
    CHECK(lines[0]["failed"] == true);
    CHECK(has(lines[0]["error"].get<std::string>(), "timeout"));
    CHECK(lines[0]["ms"].get<double>() < 3000);
    CHECK(lines[1]["failed"] == true);
    CHECK(lines[1]["exitCode"] == 1);
    CHECK(has(lines[1]["error"].get<std::string>(), "bad config"));
    CHECK(h.said("Hook failed (PreToolUse"));
    CHECK(h.said("Hook failed (PostToolUse"));
    // the recent runs the editor shows
    bool seen = false;
    for (const HookRunRecord& rec : recent_hook_runs(300)) seen = seen || (rec.failed && rec.extension == "broken");
    CHECK(seen);
}

TEST_CASE("session: hook runs appear in ai.session_timeline") {
    HookHarness h;
    h.add("slow", command_hook("PostToolUse", "", "sleep 1.2"));
    h.provider->script = {tool_response({call("a", "scene_list_entities")}), text_response("ok")};
    auto r = h.run("go");
    REQUIRE(r.ok);
    Json tl = session_timeline_from_text(read_file(r.transcriptPath), 0.5);
    REQUIRE(tl["hasTimes"] == true);
    CHECK(tl["totals"]["hook"]["count"] == 1);
    CHECK(tl["totals"]["hook"]["seconds"].get<double>() >= 1.0);
    CHECK(tl["totals"]["hook"]["byHook"][0]["hook"] == "PostToolUse slow");
}

TEST_CASE("the trust gate: a project's hook program runs only after the user trusts the project; a JS hook needs no trust") {
    HookHarness h;
    const Json hooks = merged(command_hook("PreToolUse", "project_validate", R"(echo '{"decision":"block","reason":"program"}')"),
                              Json::object());
    write_file(h.proj.path / ".factoria" / "extensions.json", Json::object({{"hooks", Json::object({{"proj", Json::object({{"hooks", hooks}})}})}}).dump());
    h.provider->script = {tool_response({call("a", "project_validate")}), text_response("ok")};
    REQUIRE(h.run("go").ok);
    CHECK_FALSE(has(h.tool_result_text(1), "program"));  // untrusted: it did not run
    CHECK(h.said("not trusted"));

    const ProjectExtensions file = load_project_extensions(h.proj.str());
    REQUIRE(trust_project_extensions((h.home.path / "ai-trust.json").string(), h.proj.str(), file.hash));
    h.provider->script = {tool_response({call("a", "project_validate")}), text_response("ok")};
    h.provider->calls = 0;
    h.provider->requests.clear();
    REQUIRE(h.run("again").ok);
    CHECK(has(h.tool_result_text(1), "program"));  // trusted: it ran
}

// --- beforeCommand / afterCommand: any caller of the registry ---------------------------------------------------------------

namespace {

struct CommandHookHarness {
    TempDir proj, home;
    CommandRegistry registry = make_registry();
    AiConfig cfg = default_config();
    int touched = 0;
    CommandHookHarness() {
        cfg.sourcePath = (home.path / "ai.json").string();
        CommandInfo t;
        t.name = "test.touch";
        t.summary = "Counts its calls.";
        registry.add(t, [this](const Json&) {
            ++touched;
            return Json::object({{"touched", touched}});
        });
    }
    void install() {
        AiCommandOptions options;
        options.loadConfig = [this]() -> Result<AiConfig> { return cfg; };
        options.projectDir = [this]() { return proj.str(); };
        options.runtime.env = fake_env({{"HOME", home.str()}});
        register_ai_commands(registry, options);
    }
};

}  // namespace

TEST_CASE("beforeCommand blocks a command for a caller that is not an AI; afterCommand sees what it returned") {
    CommandHookHarness h;
    h.cfg.extensions.entries.push_back(hooks_entry(
        "cmd", merged(merged(command_hook("beforeCommand", "project.*", R"(echo '{"decision":"block","reason":"freeze"}')"),
                             command_hook("afterCommand", "scene.list_entities", R"(cat > "$FACTORIA_PROJECT_DIR/after.json")")),
                      command_hook("beforeCommand", "test.touch", R"(echo '{"hookSpecificOutput":{"updatedInput":{"x":1}}}')"))));
    h.install();

    auto blocked = h.registry.call("project.validate");
    REQUIRE_FALSE(blocked.ok);
    CHECK(blocked.error["code"] == "blocked_by_hook");
    CHECK(has(blocked.error["message"].get<std::string>(), "freeze"));
    CHECK(has(blocked.error["hint"].get<std::string>(), "ai.hooks"));

    auto listed = h.registry.call("scene.list_entities", Json::object({{"limit", 4}}));
    REQUIRE(listed.ok);
    CHECK(listed.result["limit"] == 4);
    REQUIRE(fsys::exists(h.proj.path / "after.json"));
    const Json after = Json::parse(read_file((h.proj.path / "after.json").string()));
    CHECK(after["hook_event_name"] == "afterCommand");
    CHECK(after["command"] == "scene.list_entities");
    CHECK(after["args"]["limit"] == 4);
    CHECK(after["ok"] == true);
    CHECK(after["result"]["count"] == 2);
    CHECK(after.contains("durationMs"));

    // a command no hook names is untouched
    auto plain = h.registry.call("test.touch");
    REQUIRE(plain.ok);
    CHECK(h.touched == 1);
}

TEST_CASE("command hooks: a failing hook is reported on the result and never silent; none configured means no interceptor work") {
    {
        CommandHookHarness h;
        h.cfg.extensions.entries.push_back(hooks_entry("bad", command_hook("afterCommand", "scene.*", "echo oops >&2; exit 3")));
        h.install();
        auto r = h.registry.call("scene.list_entities");
        REQUIRE(r.ok);  // the command itself succeeded
        REQUIRE(r.result.contains("hookWarnings"));
        CHECK(has(r.result["hookWarnings"].dump(), "oops"));
    }
    {
        CommandHookHarness h;
        h.install();
        auto r = h.registry.call("scene.list_entities");
        REQUIRE(r.ok);
        CHECK_FALSE(r.result.contains("hookWarnings"));
        CHECK(h.registry.has_interceptor());
    }
    {
        // a program that a hook starts runs no hooks of its own
        CommandHookHarness h;
        ::setenv("FACTORIA_IN_HOOK", "1", 1);
        h.install();
        ::unsetenv("FACTORIA_IN_HOOK");
        CHECK_FALSE(h.registry.has_interceptor());
    }
}

TEST_CASE("command hooks: a JS module hooks beforeCommand, and a project's program hook waits for trust") {
    CommandHookHarness h;
    write_file(h.proj.path / "hooks" / "gate.js",
               "export function beforeCommand(input) { if (input.command === 'project.validate') return { decision: 'block', reason: 'js gate' }; }\n");
    write_file(h.proj.path / ".factoria" / "extensions.json",
               Json::object({{"hooks", Json::object({{"gate", Json::object({{"hooks", js_hook("beforeCommand", "project.*", "hooks/gate.js")}})},
                                                     {"prog", Json::object({{"hooks", command_hook("beforeCommand", "test.touch", R"(echo '{"decision":"block","reason":"prog"}')")}})}})}})
                   .dump());
    h.install();
    auto js = h.registry.call("project.validate");
    REQUIRE_FALSE(js.ok);
    CHECK(has(js.error["message"].get<std::string>(), "js gate"));
    auto prog = h.registry.call("test.touch");
    CHECK(prog.ok);  // the project's program is not trusted
}

TEST_CASE("ai.hooks and ai.hooks_test: the report, a sample run, and the teaching errors") {
    CommandHookHarness h;
    h.cfg.extensions.entries.push_back(hooks_entry(
        "guard", merged(command_hook("PreToolUse", "scene_spawn", R"(echo '{"decision":"block","reason":"no spawning"}')"),
                        Json::parse(R"({"PreCompact":[{"hooks":[{"type":"command","command":"echo x"}]}],"Stop":[{"hooks":[{"type":"http","url":"http://localhost/x"}]}]})"))));
    h.install();
    const CommandInfo* info = h.registry.info("ai.hooks");
    REQUIRE(info);
    CHECK(info->readOnly);
    CHECK_FALSE(info->description.empty());

    auto test = h.registry.call("ai.hooks_test", Json::object({{"event", "PreToolUse"}, {"match", "scene_spawn"},
                                                                {"input", Json::object({{"tool_name", "scene_spawn"}})}}));
    REQUIRE(test.ok);
    CHECK(test.result["groups"] == 1);
    CHECK(test.result["outcome"]["blocked"] == true);
    CHECK(has(test.result["outcome"]["reason"].get<std::string>(), "no spawning"));

    auto report = h.registry.call("ai.hooks");
    REQUIRE(report.ok);
    REQUIRE(report.result["entries"].size() == 1);
    CHECK(report.result["entries"][0]["name"] == "guard");
    CHECK(report.result["entries"][0]["events"].contains("PreToolUse"));
    CHECK_FALSE(report.result["recentRuns"].empty());
    CHECK_FALSE(report.result["notRun"].empty());  // the http hook is Claude Code's

    auto none = h.registry.call("ai.hooks_test", Json::object({{"event", "PreToolUse"}, {"match", "other"}}));
    REQUIRE(none.ok);
    CHECK(has(none.result["note"].get<std::string>(), "No hook is configured"));

    auto bad = h.registry.call("ai.hooks_test", Json::object({{"event", "PreToolUsee"}}));
    REQUIRE_FALSE(bad.ok);
    CHECK(has(bad.error.dump(), "Did you mean 'PreToolUse'"));
}

#endif  // !_WIN32
