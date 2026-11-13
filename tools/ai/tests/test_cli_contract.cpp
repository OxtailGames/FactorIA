// Contract tests for the AI CLIs: recorded outputs of each CLI (tests/fixtures/cli/<cli>-<version>/, README.md there says
// how each was recorded) replayed through the SAME code the engine runs on a live CLI (CliStreamParser, list_models,
// detect_providers). A CLI update that changes its output format fails here, with the fixture and the field named, not in a
// user's run. Fixtures of the CLIs that are not installed here ("-docs" folders) are written from their documentation.
#include <algorithm>
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
    NEED(r,
         r.first(AgentEvent::Type::Info) &&
             r.first(AgentEvent::Type::Info)->text.find("Claude Code started (model claude-") == 0,
         "no Info event from system/init with `model`");
    NEED(r, !r.costIsEstimate, "the cost is still an estimate: `result.total_cost_usd` is missing");
    NEED(r, r.cost > 0, "`result.total_cost_usd` is not read");
    NEED(r, r.usage.outputTokens > 0, "`usage.output_tokens` is not read");
    NEED(r, r.usage.cacheReadTokens + r.usage.cacheCreationTokens + r.usage.inputTokens > 0,
         "`usage.input_tokens` / `cache_read_input_tokens` / `cache_creation_input_tokens` are not read");
    NEED(r, r.turns >= 1, "`result.num_turns` is not read");
    // The window the parser reports is the one of the model that used the most tokens in the fixture's own modelUsage.
    u64 expectedWindow = 0;
    double most = -1;
    const Json res = raw_event(r, "result");
    if (res.contains("modelUsage") && res["modelUsage"].is_object()) {
        for (const auto& [model, m] : res["modelUsage"].items()) {
            const double used = m.value("inputTokens", 0.0) + m.value("outputTokens", 0.0) +
                                m.value("cacheReadInputTokens", 0.0) + m.value("cacheCreationInputTokens", 0.0);
            if (used > most) {
                most = used;
                expectedWindow = static_cast<u64>(m.value("contextWindow", 0.0));
            }
        }
    }
    NEED(r, expectedWindow > 0, "the fixture's `result.modelUsage.<model>.contextWindow` is gone");
    NEED(r, r.last_usage([](const AgentEvent& e) { return e.contextWindow; }) == expectedWindow,
         "`result.modelUsage.<model>.contextWindow` is not read (fixture says " << expectedWindow << ")");
    NEED(r, r.last_usage([](const AgentEvent& e) { return e.contextTokens; }) > 0,
         "the context tokens of the last assistant message (`message.usage`) are not read");
    // The keys of the first `assistant` event: the parser needs these to count tokens once per message.
    const Json a = raw_event(r, "assistant");
    NEED(r,
         a.is_object() && a.contains("message") && a["message"].contains("id") && a["message"].contains("usage") &&
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
    NEED(r, r.first(AgentEvent::Type::ThinkingDelta) != nullptr,
         "assistant `thinking` blocks are not read (ThinkingDelta)");
    NEED(r, !r.resultIsError, "a successful run is read as an error");
    const AgentEvent* s = r.first(AgentEvent::Type::ToolStart, "Read");
    NEED(r, s != nullptr, "no ToolStart for the assistant `tool_use` block (`name`)");
    if (s) {
        NEED(r, !s->toolId.empty(), "`tool_use.id` is not read");
        NEED(r, s->toolInput.is_object() && s->toolInput.contains("file_path"), "`tool_use.input` is not read");
    }
    const AgentEvent* e = r.first(AgentEvent::Type::ToolEnd, "Read");
    NEED(r, e != nullptr,
         "no ToolEnd for the user `tool_result` block (`tool_use_id` does not match a ToolStart `id`)");
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
    // `result.permission_denials` and the `system/permission_denied` event are the CLI's own report of the refusal; the parser
    // reads neither (the errored tool_result above is what the engine uses), so they are not checked here (fixtures README).
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

namespace {
// Feeds the given stdout lines to a fresh Claude Code parser.
struct Fed {
    CliStreamParser parser{ProviderKind::ClaudeCode};
    std::vector<AgentEvent> events;
    void feed(const std::string& line) { parser.feed_line(line, events); }
};

// The first line of a fixture that is an event of this type, as the CLI printed it.
std::string raw_line(const std::string& folder, const std::string& file, const std::string& type,
                     const std::string& subtype = {}) {
    for (auto line : fa::split(read_file(fixture_path(folder, file)), '\n')) {
        Json j = Json::parse(line, nullptr, false);
        if (!j.is_object() || j.value("type", "") != type) continue;
        if (!subtype.empty() && j.value("subtype", "") != subtype) continue;
        return std::string(line);
    }
    return {};
}
}  // namespace

TEST_CASE("contract Claude Code: the session id comes from system/init, and result.session_id wins when it has one") {
    const std::string init = raw_line(kClaude, "plain.jsonl", "system", "init");
    const std::string result = raw_line(kClaude, "plain.jsonl", "result");
    REQUIRE(!init.empty());
    REQUIRE(!result.empty());
    const std::string initId = Json::parse(init).value("session_id", "");
    REQUIRE(!initId.empty());
    {
        Fed f;  // init only (a run cut short): the id of init
        f.feed(init);
        CHECK_MESSAGE(f.parser.session_id() == initId, "plain.jsonl: system/init `session_id` is not the session id");
    }
    {
        Fed f;  // a result without an id keeps the id of init
        f.feed(init);
        Json r = Json::parse(result);
        r.erase("session_id");
        f.feed(r.dump());
        CHECK_MESSAGE(f.parser.session_id() == initId,
                      "plain.jsonl: a result without `session_id` lost the id of init");
    }
    {
        Fed f;  // a result with another id: the engine resumes the one of the result
        f.feed(init);
        Json r = Json::parse(result);
        r["session_id"] = "11111111-1111-4111-8111-111111111111";
        f.feed(r.dump());
        CHECK_MESSAGE(f.parser.session_id() == "11111111-1111-4111-8111-111111111111",
                      "plain.jsonl: `result.session_id` is not read");
    }
    {
        Fed f;  // no init at all: the id of the result
        f.feed(result);
        CHECK_MESSAGE(f.parser.session_id() == Json::parse(result).value("session_id", ""),
                      "plain.jsonl: `result.session_id` alone is not read");
    }
}

TEST_CASE("contract Claude Code: cache_creation ephemeral_1h_input_tokens raise the estimated cost") {
    const std::string line = raw_line(kClaude, "plain.jsonl", "assistant");
    REQUIRE(!line.empty());
    const Json a = Json::parse(line);
    const Json* cc =
        a["message"]["usage"].contains("cache_creation") ? &a["message"]["usage"]["cache_creation"] : nullptr;
    const bool has1h = cc && cc->value("ephemeral_1h_input_tokens", 0) > 0;
    REQUIRE_MESSAGE(has1h, "plain.jsonl: the assistant usage lost `cache_creation.ephemeral_1h_input_tokens`");
    Json without = a;
    without["message"]["usage"]["cache_creation"]["ephemeral_1h_input_tokens"] = 0;
    Fed with1h, without1h;
    with1h.feed(line);
    without1h.feed(without.dump());
    CHECK_MESSAGE(
        with1h.parser.cost_usd() > without1h.parser.cost_usd(),
        "plain.jsonl: `message.usage.cache_creation.ephemeral_1h_input_tokens` does not change the estimated cost");
}

TEST_CASE("contract Claude Code: a sub-agent's assistant message (parent_tool_use_id) is not the main context") {
    const std::string line = raw_line(kClaude, "plain.jsonl", "assistant");
    REQUIRE(!line.empty());
    auto context_of = [](const Fed& f) {
        u64 v = 0;
        for (const auto& e : f.events) v = std::max<u64>(v, e.contextTokens);
        return v;
    };
    Fed mainFed;
    mainFed.feed(line);
    CHECK_MESSAGE(context_of(mainFed) > 0, "plain.jsonl: the assistant `message.usage` gives no context tokens");
    Json sub = Json::parse(line);
    sub["parent_tool_use_id"] = "toolu_FIXTURE9999";
    Fed fed;
    fed.feed(sub.dump());
    CHECK_MESSAGE(context_of(fed) == 0,
                  "plain.jsonl: an assistant event with `parent_tool_use_id` counts as the main context");
}

TEST_CASE("contract Claude Code: system/init names an MCP server that is not connected") {
    Json init = Json::parse(raw_line(kClaude, "plain.jsonl", "system", "init"));
    init["mcp_servers"] = Json::array({Json::object({{"name", "factoria"}, {"status", "failed"}}),
                                       Json::object({{"name", "other"}, {"status", "connected"}})});
    Fed f;
    f.feed(init.dump());
    REQUIRE(!f.events.empty());
    CHECK_MESSAGE(f.events[0].text.find("MCP server 'factoria' is failed") != std::string::npos,
                  "plain.jsonl: `system/init.mcp_servers[].status` != connected is not reported");
    CHECK_MESSAGE(f.events[0].text.find("other") == std::string::npos,
                  "a connected MCP server is reported as a problem");
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
    NEED(r, s && s->toolInput.value("command", "") == "bash -lc cat hello.txt",
         "`command_execution.command` is not read");
    const AgentEvent* e = r.first(AgentEvent::Type::ToolEnd, "shell");
    NEED(r, e && !e->isError && rtext(e->toolResult).find("banana") != std::string::npos,
         "`command_execution.aggregated_output` / `exit_code` are not read");
    NEED(r, r.first(AgentEvent::Type::ToolStart, "project_validate") != nullptr, "mcp_tool_call `tool` (item.started)");
    const AgentEvent* me = r.first(AgentEvent::Type::ToolEnd, "project_validate");
    NEED(r, me && !me->isError && rtext(me->toolResult).find("ok") != std::string::npos,
         "mcp_tool_call `result` (item.completed)");
    const AgentEvent* info = r.first(AgentEvent::Type::Info);
    bool changed = false;
    for (const auto& ev : r.events)
        changed = changed || (ev.type == AgentEvent::Type::Info && ev.text == "Codex changed files");
    NEED(r, info && changed, "`file_change` items are not read");
}

TEST_CASE("contract Codex (from the docs): a command refused by the sandbox") {
    const Replay r = replay(ProviderKind::Codex, kCodex, "sandbox_denied.jsonl");
    const AgentEvent* e = r.first(AgentEvent::Type::ToolEnd, "shell");
    NEED(r, e && e->isError,
         "a `command_execution` with status \"declined\" (exit_code null) is not read as a failed call");
    const AgentEvent* me = r.first(AgentEvent::Type::ToolEnd, "project_validate");
    NEED(r, me && me->isError, "an `mcp_tool_call` with status \"failed\" is not read as a failed call");
    NEED(r, me && rtext(me->toolResult).find("tool call refused") != std::string::npos,
         "`mcp_tool_call.error.message` is not read into the tool result");
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
    NEED(r, r.finalText == "Validated the project.",
         "msg agent_message `message` / task_complete `last_agent_message`");
    NEED(r, r.sawResult, "msg task_complete is not the end of the run");
    NEED(r,
         r.first(AgentEvent::Type::ToolStart, "project_validate") &&
             r.first(AgentEvent::Type::ToolEnd, "project_validate"),
         "msg mcp_tool_call_begin / mcp_tool_call_end `invocation.tool`");
    NEED(r, r.usage.inputTokens == 300 && r.usage.outputTokens == 40, "msg token_count");
}

TEST_CASE("contract generic CLI (from the format the engine expects)") {
    const Replay text = replay(ProviderKind::GenericCli, kGeneric, "plain_text.txt");
    NEED(text, text.finalText == "Reading the project...\nDone: the project has 3 scenes.\n",
         "plain stdout lines are the answer");
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
    int matched = 0;
    for (const auto& s : detect_providers(cfg, o)) {
        if (s.name == "claude-code") {
            ++matched;
            CHECK_MESSAGE(s.version == "2.1.318 (Claude Code)",
                          "claude-code-2.1.318/version.txt: got \"" << s.version << "\"");
        }
        if (s.name == "codex") {
            ++matched;
            CHECK_MESSAGE(s.version == "codex-cli 0.46.0", "codex-docs/version.txt: got \"" << s.version << "\"");
        }
    }
    CHECK_MESSAGE(matched == 2,
                  "detect_providers found " << matched << " of the 2 providers the fixtures stand in for");
}

#endif
