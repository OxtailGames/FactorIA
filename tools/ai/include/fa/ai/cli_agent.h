// CLI agents: the user's own subscription through an official CLI that runs its
// OWN agent loop (Claude Code, Codex, any other CLI). FactorIA spawns it with
// the FactorIA MCP server attached (`factoria mcp --project <dir>`) and
// forwards its events. FactorIA never touches subscription credentials.
#pragma once

#include "fa/ai/config.h"
#include "fa/ai/process.h"
#include "fa/ai/types.h"

namespace fa::ai {

struct CliRunRequest {
    std::string prompt;      // full prompt (task + rules), or just the task when resuming a session
    std::string model;       // may be empty (CLI default)
    std::string projectDir;  // working directory and MCP project
    std::string sessionId;   // CLI session to continue ({session}); empty = start a new one
    std::vector<ImageData> images;          // images attached to the prompt (sent inline when the CLI reads stream-json)
    std::vector<std::string> imagePaths;    // the same images as absolute file paths (the text fallback names them)
};

struct CliRunResult {
    bool ok = false;
    std::string finalText;
    Usage usage;             // tokens of THIS run
    double costUsd = 0;      // when the CLI reports it. Claude Code reports the running total of a resumed session.
    int exitCode = 0;
    int turns = 0;
    std::string sessionId;
    std::string error;       // set when !ok
    std::string hint;
    bool cancelled = false;
};

// {prompt} {model} {project} {mcp_config} {session} {project_json} {factoria} {factoria_json}.
// Elements whose placeholder expands to an empty string are dropped together with
// a preceding bare flag ("-m", "{model}" disappears when no model is set; "--resume", "{session}" when
// there is no session to continue yet).
// A template without {prompt} gets the prompt on standard input (the built-in ones do).
std::vector<std::string> expand_cli_argv(const std::vector<std::string>& tmpl, const CliRunRequest& req,
                                         const std::string& mcpConfigPath, const std::string& factoriaCommand);

// True when the template of this provider (its "argv", else the built-in one) has a {session} placeholder: the CLI can
// continue an earlier session, so a follow-up message needs only the new task.
bool cli_supports_resume(const ProviderConfig& cfg);

// True when argv asks the CLI to read stream-json on standard input (`--input-format stream-json`, or `=stream-json`).
// Then stdin is ONE JSON line (make_stream_json_input) instead of plain text.
bool argv_wants_stream_json_input(const std::vector<std::string>& argv);
// `{"type":"user","message":{"role":"user","content":[{"type":"text",...},{"type":"image","source":{...base64...}}]}}`
std::string make_stream_json_input(const std::string& text, const std::vector<ImageData>& images);
// CLIs without stream-json input get the pictures as files to read: `prompt` + "Attached images (read them): <paths>".
std::string prompt_with_image_paths(const std::string& prompt, const std::vector<std::string>& paths);

// Plan windows from a Codex `rate_limits` object ({"primary": {"used_percent", "window_minutes", "resets_at" |
// "resets_in_seconds"}, "secondary": {...}}). Windows are named by their length: 300 minutes = "five_hour",
// 10080 = "seven_day". `now` (epoch seconds) turns resets_in_seconds into a time.
std::vector<LimitWindow> parse_codex_rate_limits(const Json& rateLimits, i64 now);
// Updates `into` with `from`: a window with the same name is replaced, a new one is appended.
void merge_limit_windows(std::vector<LimitWindow>& into, const std::vector<LimitWindow>& from);

// JSON for `claude --mcp-config`.
Json make_mcp_config(const std::string& projectDir, const std::string& factoriaCommand);

// Install/login instructions per CLI.
std::string cli_install_hint(const ProviderConfig& cfg);

// Incremental parser for the CLI's line output -> AgentEvents.
class CliStreamParser {
public:
    explicit CliStreamParser(ProviderKind kind) : kind_(kind) {}
    void feed_line(std::string_view line, std::vector<AgentEvent>& out);

    const std::string& final_text() const { return finalText_; }
    const Usage& usage() const { return usage_; }
    double cost_usd() const { return costUsd_; }
    bool saw_result() const { return sawResult_; }
    bool result_is_error() const { return resultIsError_; }
    const std::string& error_text() const { return errorText_; }
    int turns() const { return turns_; }
    const std::string& session_id() const { return sessionId_; }
    const std::vector<LimitWindow>& limits() const { return limits_; }   // latest of each window the CLI reported
    u64 context_tokens() const { return contextTokens_; }                // after the last model call (0 = unknown)
    u64 context_window() const { return contextWindow_; }                // 0 until the CLI says

private:
    void feed_claude(const Json& j, std::vector<AgentEvent>& out);
    void feed_codex(const Json& j, std::vector<AgentEvent>& out);
    ProviderKind kind_;
    std::string finalText_, errorText_, sessionId_;
    Usage usage_;
    double costUsd_ = 0;
    int turns_ = 0;
    bool sawResult_ = false, resultIsError_ = false;
    std::map<std::string, std::string> toolNames_;  // tool_use id -> name
    std::vector<LimitWindow> limits_;
    u64 contextTokens_ = 0, contextWindow_ = 0;
    void usage_event(std::vector<AgentEvent>& out, std::vector<LimitWindow> limits = {}) const;
};

// True when text looks like "not logged in / invalid credentials".
bool looks_like_auth_failure(std::string_view text);

class CliAgent {
public:
    explicit CliAgent(ProviderConfig cfg) : cfg_(std::move(cfg)) {}
    // Runs to completion, calling `onEvent` for each parsed event.
    Result<CliRunResult> run(const CliRunRequest& req, const EventHandler& onEvent, const CancelFlag* cancel) const;
    const ProviderConfig& config() const { return cfg_; }

private:
    ProviderConfig cfg_;
};

}  // namespace fa::ai
