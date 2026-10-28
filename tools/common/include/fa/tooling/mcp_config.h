// Configuration snippets that connect external AI clients to `factoria mcp`.
#pragma once

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

}  // namespace fa
