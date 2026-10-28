# MCP server (`factoria mcp`)

`factoria mcp --project <dir>` runs a Model Context Protocol server over stdio (newline-delimited
JSON-RPC 2.0; stdout carries protocol messages only, logs go to stderr). Any MCP client (Claude Code,
Codex, editors) gets the whole engine as tools.

## Connect a client

Claude Code: put `.mcp.json` in the project (created by `factoria new`):

```json
{ "mcpServers": { "factoria": { "command": "factoria", "args": ["mcp", "--project", "."], "timeout": 14400000 } } }
```

Codex (`~/.codex/config.toml`):

```toml
[mcp_servers.factoria]
command = "factoria"
args = ["mcp", "--project", "/path/to/game"]
tool_timeout_sec = 14400
```

`timeout` (Claude Code, milliseconds) and `tool_timeout_sec` (Codex, seconds) are the client's hard limit on ONE tool call:
four hours here. A call that hands a whole task to a sub-agent (`ai_run`) runs for many minutes, so the limit is set
explicitly instead of left to the client's default. `factoria new` and the editor write it; add it by hand to a config you
wrote earlier. (Claude Code also gives up on a call that is silent for 5 minutes; the progress notifications below prevent
that.)

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
- **Progress**: a call that takes more than a few seconds (`ai_run`, `project_test`, a long `game_step`) reports progress.
  A client that sends `_meta.progressToken` with `tools/call` gets `notifications/progress` for it: a message saying what the
  command is doing (for `ai_run`: what the sub-agent just did, such as "worker: edit scene.set_component"), at most one every
  3 seconds, and a heartbeat every 15 seconds while nothing changes, so a client that counts silence as a timeout keeps
  waiting. Over stdio the notifications are lines on stdout before the reply. Over HTTP (the editor's endpoint, below) the
  call is answered as an event stream (`text/event-stream`) that carries them, and the reply is its last event; a call
  that finishes quickly is a plain `application/json` reply. Claude Code sends a progress token with every call and
  treats a progress notification as a sign of life (it resets its 5 minute idle timeout); it does not show the message, so
  the editor's AI panel and `factoria ai run` get their live view from other paths (see `docs/EDITOR.md`).
  A command written in C++ reports progress with `CommandContext::progress` (`engine/core/include/fa/core/command.h`).
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
