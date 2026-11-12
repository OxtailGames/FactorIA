// Contract tests for the AI CLIs: recorded outputs of each CLI (tests/fixtures/cli/<cli>-<version>/, README.md there says
// how each was recorded) replayed through the SAME code the engine runs on a live CLI (CliStreamParser, list_models,
// detect_providers). A CLI update that changes its output format fails here, with the fixture and the field named, not in a
// user's run. Fixtures of the CLIs that are not installed here ("-docs" folders) are written from their documentation.
#include <string>
#include <vector>

#include "fa/ai/cli_agent.h"
#include "fa/ai/detect.h"
#include "fa/ai/provider.h"
#include "fa/core/strings.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {

const char* const kClaude = "claude-code-2.1.318";
const char* const kCodex = "codex-docs";
const char* const kGeneric = "generic-docs";

// What the engine got out of one fixture.
struct Replay {
    std::string name;  // "<folder>/<file>", for the messages
    std::vector<AgentEvent> events;
    std::string finalText, errorText, sessionId;
    Usage usage;
    double cost = 0;
    bool costIsEstimate = true, sawResult = false, resultIsError = false;
    int turns = 0;

    // The first event of a type, or null.
    const AgentEvent* first(AgentEvent::Type t, const std::string& tool = {}) const {
        for (const auto& e : events) {
            if (e.type == t && (tool.empty() || e.toolName == tool)) return &e;
        }
        return nullptr;
    }
    // The last Usage event that carried the field `pick` reads (non-zero).
    template <class F>
    u64 last_usage(F pick) const {
        u64 v = 0;
        for (const auto& e : events) {
            if (e.type == AgentEvent::Type::Usage && pick(e) != 0) v = pick(e);
        }
        return v;
    }
};

std::string rtext(const Json& result) { return result.is_string() ? result.get<std::string>() : result.dump(); }

std::string fixture_path(const std::string& folder, const std::string& file) {
    return std::string(FA_AI_FIXTURES) + "/cli/" + folder + "/" + file;
}

Replay replay(ProviderKind kind, const std::string& folder, const std::string& file) {
    Replay r;
    r.name = folder + "/" + file;
    const std::string text = read_file(fixture_path(folder, file));
    REQUIRE_MESSAGE(!text.empty(), r.name << ": the fixture is empty");
    CliStreamParser p(kind);
    std::size_t start = 0;
    while (start < text.size()) {  // the engine feeds one stdout line at a time
        std::size_t nl = text.find('\n', start);
        if (nl == std::string::npos) nl = text.size();
        p.feed_line(std::string_view(text).substr(start, nl - start), r.events);
        start = nl + 1;
    }
    r.finalText = p.final_text();
    r.errorText = p.error_text();
    r.sessionId = p.session_id();
    r.usage = p.usage();
    r.cost = p.cost_usd();
    r.costIsEstimate = p.cost_is_estimate();
    r.sawResult = p.saw_result();
    r.resultIsError = p.result_is_error();
    r.turns = p.turns();
    return r;
}

// A failed check names the fixture and the field the engine reads: that is what a CLI update has to fix.
#define NEED(r, cond, field) CHECK_MESSAGE((cond), (r).name << ": " << field)

// The raw JSON line of a Claude Code fixture of this type (and subtype), to check that a field the parser silently defaults
// is still there.
Json raw_event(const Replay& r, const std::string& type, const std::string& subtype = {}) {
    const std::string folder = r.name.substr(0, r.name.find('/')), file = r.name.substr(r.name.find('/') + 1);
    const std::string text = read_file(fixture_path(folder, file));
    for (auto line : fa::split(text, '\n')) {
        Json j = Json::parse(line, nullptr, false);
        if (!j.is_object() || !j.contains("type") || j["type"] != type) continue;
        if (!subtype.empty() && (!j.contains("subtype") || j["subtype"] != subtype)) continue;
        return j;
    }
    return Json();
}

void check_claude_common(const Replay& r) {
    NEED(r, r.sawResult, "no `result` event was read (type \"result\")");
    NEED(r, !r.sessionId.empty(), "no session id (system/init `session_id`, `result.session_id`)");
    NEED(r, r.first(AgentEvent::Type::Info) && r.first(AgentEvent::Type::Info)->text.find("Claude Code started (model claude-") == 0,
         "no Info event from system/init with `model`");
    NEED(r, !r.costIsEstimate, "the cost is still an estimate: `result.total_cost_usd` is missing");
    NEED(r, r.cost > 0, "`result.total_cost_usd` is not read");
    NEED(r, r.usage.outputTokens > 0, "`usage.output_tokens` is not read");
    NEED(r, r.usage.cacheReadTokens + r.usage.cacheCreationTokens + r.usage.inputTokens > 0,
         "`usage.input_tokens` / `cache_read_input_tokens` / `cache_creation_input_tokens` are not read");
    NEED(r, r.turns >= 1, "`result.num_turns` is not read");
    NEED(r, r.last_usage([](const AgentEvent& e) { return e.contextWindow; }) == 200000,
         "`result.modelUsage.<model>.contextWindow` is not read");
    NEED(r, r.last_usage([](const AgentEvent& e) { return e.contextTokens; }) > 0,
         "the context tokens of the last assistant message (`message.usage`) are not read");
    // The keys of the first `assistant` event: the parser needs these to count tokens once per message.
    const Json a = raw_event(r, "assistant");
    NEED(r, a.is_object() && a.contains("message") && a["message"].contains("id") && a["message"].contains("usage") &&
                a["message"].contains("model") && a["message"].contains("content"),
         "assistant events lost `message.id` / `usage` / `model` / `content`");
}

}  // namespace

TEST_CASE("contract Claude Code: a plain answer") {
    const Replay r = replay(ProviderKind::ClaudeCode, kClaude, "plain.jsonl");
    check_claude_common(r);
    NEED(r, r.finalText == "pong", "`result.result` is not the final text (got \"" << r.finalText << "\")");
    NEED(r, !r.resultIsError, "a successful run is read as an error (`is_error` / `subtype`)");
    NEED(r, r.errorText.empty(), "an error text on a successful run");
    const AgentEvent* t = r.first(AgentEvent::Type::TextDelta);
    NEED(r, t && t->text == "pong", "no TextDelta from the assistant `text` block");
    NEED(r, !r.first(AgentEvent::Type::ToolStart), "a tool call that is not in the recording");
    const AgentEvent* rl = nullptr;
    for (const auto& e : r.events) {
        if (e.type == AgentEvent::Type::Usage && !e.limits.empty()) rl = &e;
    }
    NEED(r, rl && rl->limits[0].name == "seven_day" && rl->limits[0].usedFraction > 0 && rl->limits[0].resetsAt > 0,
         "rate_limit_event `rate_limit_info.unifiedWindows.<name>.utilization / resetsAt` are not read");
}

TEST_CASE("contract Claude Code: a tool use") {
    const Replay r = replay(ProviderKind::ClaudeCode, kClaude, "tool_use.jsonl");
    check_claude_common(r);
    NEED(r, r.finalText.find("banana") != std::string::npos, "the final text lost the tool's answer");
    NEED(r, !r.resultIsError, "a successful run is read as an error");
    const AgentEvent* s = r.first(AgentEvent::Type::ToolStart, "Read");
    NEED(r, s != nullptr, "no ToolStart for the assistant `tool_use` block (`name`)");
    if (s) {
        NEED(r, !s->toolId.empty(), "`tool_use.id` is not read");
        NEED(r, s->toolInput.is_object() && s->toolInput.contains("file_path"), "`tool_use.input` is not read");
    }
    const AgentEvent* e = r.first(AgentEvent::Type::ToolEnd, "Read");
    NEED(r, e != nullptr, "no ToolEnd for the user `tool_result` block (`tool_use_id` does not match a ToolStart `id`)");
    if (e && s) {
        NEED(r, e->toolId == s->toolId, "ToolEnd `tool_use_id` differs from the ToolStart id");
        NEED(r, !e->isError, "`tool_result.is_error` is true for a good call");
        NEED(r, rtext(e->toolResult).find("banana") != std::string::npos, "`tool_result.content` is not read");
    }
}

TEST_CASE("contract Claude Code: a tool refused by the permission mode") {
    const Replay r = replay(ProviderKind::ClaudeCode, kClaude, "permission_denied.jsonl");
    check_claude_common(r);
    // The run itself succeeds: the model reads the refusal and answers. The engine sees the refusal as an errored tool result.
    NEED(r, !r.resultIsError, "a refused tool made the whole run an error");
    const AgentEvent* e = r.first(AgentEvent::Type::ToolEnd, "Write");
    NEED(r, e != nullptr, "no ToolEnd for the refused Write call");
    if (e) {
        NEED(r, e->isError, "`tool_result.is_error` is not read: the refusal looks like a success");
        NEED(r, rtext(e->toolResult).find("requested permissions") != std::string::npos,
             "the refusal text (`tool_result.content`, \"Claude requested permissions...\") changed or is not read");
    }
    // `result.permission_denials` and the `permission_denied` system event are the CLI's own report of the refusal.
    const Json res = raw_event(r, "result");
    NEED(r, res.contains("permission_denials") && res["permission_denials"].is_array() && res["permission_denials"].size() == 1 &&
                res["permission_denials"][0].value("tool_name", "") == "Write",
         "`result.permission_denials[].tool_name` changed");
    NEED(r, raw_event(r, "system", "permission_denied").is_object(), "the system/permission_denied event is gone");
}

TEST_CASE("contract Claude Code: the turn limit is an error result") {
    const Replay r = replay(ProviderKind::ClaudeCode, kClaude, "max_turns.jsonl");
    NEED(r, r.sawResult, "no `result` event was read");
    NEED(r, r.resultIsError, "`result.is_error` / `subtype` \"error_max_turns\" is not read as an error");
    NEED(r, r.errorText.find("Reached maximum number of turns") != std::string::npos,
         "`result.errors[]` is not read into the error text (got \"" << r.errorText << "\")");
    NEED(r, !r.sessionId.empty(), "no session id");
    NEED(r, !r.costIsEstimate && r.cost > 0, "`result.total_cost_usd` is not read");
    NEED(r, r.first(AgentEvent::Type::ToolStart) != nullptr, "the tool call before the limit is not read");
}

TEST_CASE("contract Claude Code: --version") {
    CHECK(fa::trim(read_file(fixture_path(kClaude, "version.txt"))) == "2.1.318 (Claude Code)");
    // The version the engine shows is the first line of --version; the recorded init event names the same CLI version.
    const Replay r = replay(ProviderKind::ClaudeCode, kClaude, "plain.jsonl");
    const Json init = raw_event(r, "system", "init");
    NEED(r, init.value("claude_code_version", "") == "2.1.318", "system/init `claude_code_version` changed");
}

TEST_CASE("contract Codex (from the docs): a text answer") {
    const Replay r = replay(ProviderKind::Codex, kCodex, "text_answer.jsonl");
    NEED(r, r.sessionId == "0199a213-81c0-7800-8aa1-bbab2a035a93", "`thread.started.thread_id` is not the session id");
    NEED(r, r.finalText == "pong", "`item.completed` agent_message `text` is not the final text");
    NEED(r, r.sawResult && !r.resultIsError, "`turn.completed` is not the end of the run");
    NEED(r, r.usage.inputTokens == 200 && r.usage.cacheReadTokens == 1000 && r.usage.outputTokens == 20,
         "`turn.completed.usage` (input_tokens minus cached_input_tokens, cached_input_tokens, output_tokens)");
    NEED(r, r.turns == 1, "turns");
    NEED(r, r.first(AgentEvent::Type::ThinkingDelta) != nullptr, "`reasoning` items are not read");
    NEED(r, r.costIsEstimate, "Codex reports no cost: the engine's estimate must stay flagged as an estimate");
}

TEST_CASE("contract Codex (from the docs): tools, the shell and file changes") {
    const Replay r = replay(ProviderKind::Codex, kCodex, "tool_use.jsonl");
    NEED(r, r.finalText == "The secret word is banana.", "agent_message text");
    const AgentEvent* s = r.first(AgentEvent::Type::ToolStart, "shell");
    NEED(r, s && s->toolInput.value("command", "") == "bash -lc cat hello.txt", "`command_execution.command` is not read");
    const AgentEvent* e = r.first(AgentEvent::Type::ToolEnd, "shell");
    NEED(r, e && !e->isError && rtext(e->toolResult).find("banana") != std::string::npos,
         "`command_execution.aggregated_output` / `exit_code` are not read");
    NEED(r, r.first(AgentEvent::Type::ToolStart, "project_validate") != nullptr, "mcp_tool_call `tool` (item.started)");
    const AgentEvent* me = r.first(AgentEvent::Type::ToolEnd, "project_validate");
    NEED(r, me && !me->isError && rtext(me->toolResult).find("ok") != std::string::npos, "mcp_tool_call `result` (item.completed)");
    const AgentEvent* info = r.first(AgentEvent::Type::Info);
    bool changed = false;
    for (const auto& ev : r.events) changed = changed || (ev.type == AgentEvent::Type::Info && ev.text == "Codex changed files");
    NEED(r, info && changed, "`file_change` items are not read");
}

TEST_CASE("contract Codex (from the docs): a command refused by the sandbox") {
    const Replay r = replay(ProviderKind::Codex, kCodex, "sandbox_denied.jsonl");
    const AgentEvent* e = r.first(AgentEvent::Type::ToolEnd, "shell");
    NEED(r, e && e->isError, "a non-zero `command_execution.exit_code` is not read as a failed call");
    NEED(r, e && rtext(e->toolResult).find("sandbox") != std::string::npos, "`aggregated_output` of the refused command");
    NEED(r, !r.resultIsError && r.sawResult, "the run after a refused command still ends with turn.completed");
}

TEST_CASE("contract Codex (from the docs): an error") {
    const Replay r = replay(ProviderKind::Codex, kCodex, "error.jsonl");
    NEED(r, r.resultIsError, "`turn.failed` is not read as an error");
    NEED(r, r.errorText.find("401 Unauthorized") != std::string::npos, "`turn.failed.error.message` / `error.message`");
    NEED(r, looks_like_auth_failure(r.errorText), "the 401 text is no longer recognised as an auth failure");
    const AgentEvent* e = r.first(AgentEvent::Type::Error);
    NEED(r, e && e->isError, "no Error event");
    NEED(r, r.sessionId == "0199a213-81c0-7800-8aa1-bbab2a035a93", "`thread.started.thread_id`");
}

TEST_CASE("contract Codex (from the docs): the older id/msg event format") {
    const Replay r = replay(ProviderKind::Codex, kCodex, "legacy_events.jsonl");
    NEED(r, r.finalText == "Validated the project.", "msg agent_message `message` / task_complete `last_agent_message`");
    NEED(r, r.sawResult, "msg task_complete is not the end of the run");
    NEED(r, r.first(AgentEvent::Type::ToolStart, "project_validate") && r.first(AgentEvent::Type::ToolEnd, "project_validate"),
         "msg mcp_tool_call_begin / mcp_tool_call_end `invocation.tool`");
    NEED(r, r.usage.inputTokens == 300 && r.usage.outputTokens == 40, "msg token_count");
}

TEST_CASE("contract generic CLI (from the format the engine expects)") {
    const Replay text = replay(ProviderKind::GenericCli, kGeneric, "plain_text.txt");
    NEED(text, text.finalText == "Reading the project...\nDone: the project has 3 scenes.\n", "plain stdout lines are the answer");
    NEED(text, text.first(AgentEvent::Type::TextDelta) != nullptr, "no TextDelta per line");
    const Replay json = replay(ProviderKind::GenericCli, kGeneric, "json_lines.jsonl");
    NEED(json, json.finalText == "Looking at the scene.\nThe scene has 3 entities.\n",
         "JSON lines: the first of `text` / `result` / `message` / `content` is the text");
}

#ifndef _WIN32

namespace {

// A stand-in for a CLI executable that prints a recorded file (what `claude --version` or the `initialize` control request
// answer), so list_models and detect_providers run their own code on the recording.
std::string replay_cli(const TempDir& dir, const std::string& name, const std::string& file, bool readStdin) {
    const auto path = dir.path / name;
    std::ofstream(path) << "#!/bin/sh\n" << (readStdin ? "cat > /dev/null\n" : "") << "cat '" << file << "'\n";
    std::filesystem::permissions(path, std::filesystem::perms::owner_all);
    return path.string();
}

}  // namespace

TEST_CASE("contract Claude Code: the model list answered to the initialize request") {
    TempDir dir;
    ProviderConfig cfg = default_config().providers["claude-code"];
    cfg.command = replay_cli(dir, "claude", fixture_path(kClaude, "models.jsonl"), true);
    auto models = list_models(cfg);
    REQUIRE_MESSAGE(models.ok(), "models.jsonl: list_models failed: " << (models.ok() ? "" : models.error().message));
    const std::string n = std::string(kClaude) + "/models.jsonl";
    CHECK_MESSAGE(models->size() >= 3, n << ": `response.response.models[]` yields fewer than 3 models");
    const ModelInfo* haiku = nullptr;
    bool hasDefault = false;
    for (const auto& m : *models) {
        if (m.id == "haiku") haiku = &m;
        hasDefault = hasDefault || m.id == "default";
    }
    CHECK_MESSAGE(hasDefault, n << ": the \"default\" alias (`models[].value`) is gone");
    REQUIRE_MESSAGE(haiku != nullptr, n << ": the \"haiku\" alias (`models[].value`) is gone");
    CHECK_MESSAGE(!haiku->name.empty(), n << ": `models[].displayName` is not read");
    CHECK_MESSAGE(!haiku->description.empty(), n << ": `models[].description` is not read");
    CHECK_MESSAGE(haiku->resolved == "claude-haiku-5-5", n << ": `models[].resolvedModel` is not read");
}

TEST_CASE("contract: the --version line the doctor shows") {
    TempDir dir;
    AiConfig cfg = default_config();
    DetectOptions o;
    o.env = fake_env({});
    const std::string claude = replay_cli(dir, "claude", fixture_path(kClaude, "version.txt"), false);
    const std::string codex = replay_cli(dir, "codex", fixture_path(kCodex, "version.txt"), false);
    o.which = [&](const std::string& n) { return n == "claude" ? claude : n == "codex" ? codex : std::string(); };
    for (const auto& s : detect_providers(cfg, o)) {
        if (s.name == "claude-code") CHECK_MESSAGE(s.version == "2.1.318 (Claude Code)", "claude-code-2.1.318/version.txt: got \"" << s.version << "\"");
        if (s.name == "codex") CHECK_MESSAGE(s.version == "codex-cli 0.46.0", "codex-docs/version.txt: got \"" << s.version << "\"");
    }
}

#endif
