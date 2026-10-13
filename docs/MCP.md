# MCP server (`factoria mcp`)

`factoria mcp --project <dir>` runs a Model Context Protocol server over stdio (newline-delimited
JSON-RPC 2.0; stdout carries protocol messages only, logs go to stderr). Any MCP client (Claude Code,
Codex, editors) gets the whole engine as tools.

## Connect a client

Claude Code: put `.mcp.json` in the project (created by `factoria new`):

```json
{ "mcpServers": { "factoria": { "command": "factoria", "args": ["mcp", "--project", "."] } } }
```

Codex (`~/.codex/config.toml`):

```toml
[mcp_servers.factoria]
command = "factoria"
args = ["mcp", "--project", "/path/to/game"]
```

## What it exposes

- **Tools**: every registered command. `scene.list_entities` becomes `scene_list_entities` (characters
  other than letters, digits, `_`, `-` become `_`; at most 64 characters). The description is the
  command's summary + details; `readOnlyHint` / `destructiveHint` come from the command's `readOnly`
  flag. Results are pretty JSON text plus `structuredContent` for objects. A result with an
  `"$image": {"path"|"base64", "mimeType"}` key also carries an image block, so screenshots are visible.
  Failures are `isError` results: `code: message` and `hint: ...`.
- **Resources**: `factoria://docs/<file>` (embedded docs, `factoria://docs/components` generated),
  `factoria://project/factoria.json`, `.../ENGINE_FEEDBACK.json`, `.../AGENTS.md`.
- **Prompts**: `make-game` (idea), `add-feature` (feature), `fix-bug` (description), `report-engine-gap`.
- **Notifications**: `notifications/tools/list_changed` when project tools (`tools/*.js`) change;
  `notifications/message` for logs (`logging/setLevel`).
- **Instructions**: the server sends a short engine guide on `initialize`, including the rule to call
  `feedback_report` whenever the engine lacks something.

Protocol versions: 2025-11-25, 2025-06-18, 2025-03-26, 2024-11-05.

## Embedding (C++)

```cpp
fa::SimpleMcpHost host(registry, projectDir);   // or subclass fa::McpHost
fa::McpServer server(host);
fa::run_stdio(server);                          // blocking; server.handle_message(line) for other transports
// after tools change:
server.notify_tools_changed();
```
