// CLI agents: the user's own subscription through an official CLI that runs its
// OWN agent loop (Claude Code, Codex, any other CLI). FactorIA spawns it with
// the FactorIA MCP server attached (`factoria mcp --project <dir>`, or the
// editor's own endpoint, CliRunRequest::mcpUrl) and forwards its events.
// FactorIA never touches subscription credentials.
#pragma once

#include <functional>
#include "fa/ai/config.h"
#include "fa/ai/process.h"
#include "fa/ai/types.h"
#include "fa/tooling/mcp_config.h"

namespace fa::ai {

// Where a CLI agent's executable is: PATH first, then the folders its installers use (~/.local/bin, ~/.claude/local,
// npm / bun / volta / nvm bins, Homebrew, %APPDATA%\npm). An editor opened from Finder or the Dock gets a short PATH
// without them, so a CLI that works in a terminal would look missing. `home` is $HOME (%USERPROFILE% on Windows);
// "" when not found. A command with a slash is a path and is only checked as given.
std::string find_cli(const std::string& command, const EnvLookup& env = system_env());

struct CliRunRequest {
    std::string prompt;      // full prompt (task + rules), or just the task when resuming a session
    std::string model;       // may be empty (CLI default)
    std::string projectDir;  // working directory and MCP project
    std::string sessionId;   // CLI session to continue ({session}); empty = start a new one
    std::vector<ImageData> images;          // images attached to the prompt (sent inline when the CLI reads stream-json)
    std::vector<std::string> imagePaths;    // the same images as absolute file paths (the text fallback names them)
    // An MCP endpoint already serving this project (the editor's, fa/mcp/http_server.h): the {mcp_config} file points
    // there, so the CLI's tool calls run on that process's world. Empty = the config starts `factoria mcp --project`.
    std::string mcpUrl;
    // Tools to switch off, Claude Code names (`--disallowedTools`, appended to the argv of a claude-code provider): its own
    // sub-agent tools so that it delegates only through ai_run, and for the read-only roles the tools that edit.
    std::vector<std::string> disallowedTools;
    // A read-only role (artCritic, reviewer). Claude Code is covered by disallowedTools. Codex (default argv): its read-only
    // sandbox (`--sandbox read-only`) and the FactorIA MCP server started with `--read-only`, which offers only
    // is_read_only_tool commands.
    bool readOnly = false;
    // Called once with the CLI process's pid when it started (ProcessOptions::onStart).
    std::function<void(long long pid)> onStart;
    // Asked after every parsed line with the usage so far (tokens, cost and whether the cost is an estimate); true kills
    // the CLI (the run's budget is spent). The result is `cancelled`.
    std::function<bool(const Usage& usage, double costUsd, bool costIsEstimate)> stopWhen;
};

struct CliRunResult {
    bool ok = false;
    std::string finalText;
    Usage usage;             // tokens of THIS run
    double costUsd = 0;      // when the CLI reports it. Claude Code reports the running total of a resumed session.
    bool costIsEstimate = false;  // the CLI never reported a total (cancelled, crashed): costUsd is the engine's estimate
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

// Adds what `req` restricts to an expanded argv: Claude Code gets `--disallowedTools <comma separated>`; Codex with its
// built-in argv and a read-only role gets `--sandbox read-only` and `--read-only` for the FactorIA MCP server it starts.
// Other CLIs are left alone.
void apply_role_restrictions(ProviderKind kind, bool builtInArgv, const CliRunRequest& req, std::vector<std::string>& argv);

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

// JSON for `claude --mcp-config`: {"type": "http", "url": mcpUrl} when there is one, else a `factoria mcp --project`
// stdio server. Both carry "timeout": kMcpToolTimeoutMs, Claude Code's per-server limit (milliseconds) on one tool call.
// Without it Claude Code aborts a call that sends no sign of life for 300 s; an ai_run that hands a whole task to
// the worker runs far longer. The server also sends progress while such a call runs (notifications/progress), so this
// is only the ceiling for a call that really never ends.
inline constexpr long long kMcpToolTimeoutMs = kClaudeCodeMcpToolTimeoutMs;  // 4 hours
Json make_mcp_config(const std::string& projectDir, const std::string& factoriaCommand, const std::string& mcpUrl = {});

// Install/login instructions per CLI.
std::string cli_install_hint(const ProviderConfig& cfg);

// The provider's CLI found in PATH, ready to run: argv = {its path}, plus the provider's env and unsetEnv. The caller adds
// the arguments. An Error (with the install hint) when the provider has no command or it is not installed.
Result<ProcessOptions> cli_process_options(const ProviderConfig& cfg);

// Incremental parser for the CLI's line output -> AgentEvents.
class CliStreamParser {
public:
    explicit CliStreamParser(ProviderKind kind) : kind_(kind) {}
    void feed_line(std::string_view line, std::vector<AgentEvent>& out);

    const std::string& final_text() const { return finalText_; }
    const Usage& usage() const { return usage_; }
    // Tokens and cost are live: every assistant message adds its usage (also a sub-agent's), the cost is estimated with
    // the price table until the `result` brings the CLI's own totals, which replace them.
    double cost_usd() const { return costUsd_; }
    bool cost_is_estimate() const { return !costFinal_; }
    // The price of a model that has none in the table (ProviderConfig::pricing); the model of each message is looked up first.
    void set_pricing(Pricing p) { pricing_ = p; }
    bool saw_result() const { return sawResult_; }
    bool result_is_error() const { return resultIsError_; }
    const std::string& error_text() const { return errorText_; }
    int turns() const { return turns_; }
    const std::string& session_id() const { return sessionId_; }

private:
    void feed_claude(const Json& j, std::vector<AgentEvent>& out);
    void feed_codex(const Json& j, std::vector<AgentEvent>& out);
    ProviderKind kind_;
    std::string finalText_, errorText_, sessionId_;
    Usage usage_;
    double costUsd_ = 0;
    bool costFinal_ = false;  // costUsd_ is the CLI's total
    Pricing pricing_;
    struct MessageUsage { Usage usage; u64 cacheWrite1h = 0; double cost = 0; bool seen = false; };
    std::map<std::string, MessageUsage> messages_;  // Claude: by message id (one assistant event per content block)
    int anonMessages_ = 0;
    bool count_message(const Json& msg);  // true when the totals changed
    int turns_ = 0;
    bool sawResult_ = false, resultIsError_ = false;
    std::map<std::string, std::string> toolNames_;  // tool_use id -> name
    u64 contextTokens_ = 0, contextWindow_ = 0;  // after the last model call / the model's window (0 = unknown)
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
