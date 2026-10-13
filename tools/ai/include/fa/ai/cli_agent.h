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
    std::string prompt;      // full prompt (task + rules)
    std::string model;       // may be empty (CLI default)
    std::string projectDir;  // working directory and MCP project
};

struct CliRunResult {
    bool ok = false;
    std::string finalText;
    Usage usage;
    double costUsd = 0;      // when the CLI reports it
    int exitCode = 0;
    int turns = 0;
    std::string sessionId;
    std::string error;       // set when !ok
    std::string hint;
    bool cancelled = false;
};

// {prompt} {model} {project} {mcp_config} {project_json} {factoria} {factoria_json}.
// Elements whose placeholder expands to an empty string are dropped together with
// a preceding bare flag ("-m", "{model}" disappears when no model is set).
std::vector<std::string> expand_cli_argv(const std::vector<std::string>& tmpl, const CliRunRequest& req,
                                         const std::string& mcpConfigPath, const std::string& factoriaCommand);

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
