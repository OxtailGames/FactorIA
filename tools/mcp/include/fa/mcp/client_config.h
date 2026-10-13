// Helpers that produce MCP client configuration for FactorIA (implemented in
// fa_tooling because `factoria new` needs them too).
//   claude_code_mcp_config()        -> {"mcpServers":{"factoria":{"command":"factoria","args":["mcp","--project","."]}}}
//   codex_mcp_toml()                -> "[mcp_servers.factoria]\ncommand = ...\nargs = [...]\n"
//   write_claude_code_mcp_config()  -> writes/merges a .mcp.json
//   write_codex_mcp_config()        -> writes/replaces the table in a Codex config.toml
#pragma once

#include "fa/tooling/mcp_config.h"
