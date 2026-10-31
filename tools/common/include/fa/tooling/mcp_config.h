// Configuration snippets that connect external AI clients to `factoria mcp`.
#pragma once

#include <cstdint>
#include <string>
#include <string_view>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

struct McpClientOptions {
    std::string command = "factoria";  // executable (absolute path if not on PATH)
    std::string projectDir = ".";      // passed as `--project`
    std::string serverName = "factoria";
};

// How long one MCP tool call may take at most. A call that hands a whole task to a sub-agent (ai_run) runs for
// many minutes; without a generous limit Claude Code gives up on a call after 5 minutes without a sign of life and
// Codex after 60 s. The server also sends progress notifications while such a call runs.
inline constexpr long long kClaudeCodeMcpToolTimeoutMs = 4LL * 60 * 60 * 1000;  // Claude Code's `timeout`, milliseconds
inline constexpr int kCodexMcpToolTimeoutSec = 4 * 60 * 60;                      // Codex's `tool_timeout_sec`

// Claude Code project file `.mcp.json`:
//   {"mcpServers":{"factoria":{"command":"factoria","args":["mcp","--project","."],"timeout":14400000}}}
Json claude_code_mcp_config(const McpClientOptions& opts = {});
// Codex `config.toml` table:
//   [mcp_servers.factoria]
//   command = "factoria"
//   args = ["mcp", "--project", "."]
//   tool_timeout_sec = 14400
std::string codex_mcp_toml(const McpClientOptions& opts = {});

// Writes (or merges into) `<path>` (a .mcp.json). Other servers in the file are kept.
Result<void> write_claude_code_mcp_config(const std::string& path, const McpClientOptions& opts = {});
// Writes (or replaces the [mcp_servers.<name>] table in) a Codex config.toml; other content is kept.
Result<void> write_codex_mcp_config(const std::string& path, const McpClientOptions& opts = {});

// What a project's `.mcp.json` says about the factoria server, read to tell an AI client that started with an older file
// (docs/MCP.md, "A client with an older .mcp.json").
struct ClaudeCodeMcpState {
    std::string path;                // <project>/.mcp.json
    bool exists = false;
    bool hasServer = false;          // an entry that runs `factoria mcp` (named `serverName`, or any other that runs it)
    std::string serverName;          // the key of that entry
    bool hasTimeout = false;         // the entry has a `timeout`
    long long timeoutMs = 0;         // its value (0 = none)
    std::int64_t modifiedMs = 0;     // modification time of the file, ms since 1970 UTC (0 = no file)
    Json to_json() const;
};
ClaudeCodeMcpState read_claude_code_mcp_state(const std::string& projectDir, const std::string& serverName = "factoria");
// Adds the missing `timeout` (kClaudeCodeMcpToolTimeoutMs) to the factoria entry of <project>/.mcp.json and keeps everything
// else in the file (command, args, other servers, key order). Returns true when it wrote the file, false when there was
// nothing to do (no file, no factoria entry, or it already has a timeout).
Result<bool> ensure_claude_code_mcp_timeout(const std::string& projectDir, const std::string& serverName = "factoria");

}  // namespace fa
