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

// Claude Code project file `.mcp.json`:
//   {"mcpServers":{"factoria":{"command":"factoria","args":["mcp","--project","."]}}}
Json claude_code_mcp_config(const McpClientOptions& opts = {});
// Codex `config.toml` table:
//   [mcp_servers.factoria]
//   command = "factoria"
//   args = ["mcp", "--project", "."]
std::string codex_mcp_toml(const McpClientOptions& opts = {});

// Writes (or merges into) `<path>` (a .mcp.json). Other servers in the file are kept.
Result<void> write_claude_code_mcp_config(const std::string& path, const McpClientOptions& opts = {});
// Writes (or replaces the [mcp_servers.<name>] table in) a Codex config.toml; other content is kept.
Result<void> write_codex_mcp_config(const std::string& path, const McpClientOptions& opts = {});

}  // namespace fa
