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
  `notifications/message` for logs (`logging/setLevel`); `notifications/resources/list_changed` and a log message after the
  server restarted itself because FactorIA was updated (see [After an update](#after-an-update)). Project tools are also
  hot-reloaded while the client is silent, not only when a request arrives.
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
- **Read-only mode**: `factoria mcp --read-only` serves only the commands that look and play (reading, `game_step`,
  `game_input`, `game_click`, `game_screenshot`, `scene_load`, UI scale checks, ...). The others are not listed and a call
  to one is refused. `ai_run`, `ai_review` and everything that edits the project are among the hidden ones. FactorIA starts
  Codex's server this way for the `artCritic` and `reviewer` roles (`docs/AI_PROVIDERS.md`, Reviews).
- **Roles of `ai_run`**: `ai_run {role, task}` runs the `worker`, `fast`, `artist` or `audio` role (and `orchestrator`, the default of the
  command). The art critics and the game reviewers are not available through it: the user asks for them.
- **Instructions**: the server sends a short engine guide on `initialize`, including the rule to call
  `feedback_report` whenever the engine lacks something.

Protocol versions: 2025-11-25, 2025-06-18, 2025-03-26, 2024-11-05.

## After an update

`factoria mcp` runs for as long as the AI client does, so a FactorIA that was copied over the old one (without the in-app
updater) would leave it running the old code, and a `.mcp.json` edited after the client started is not read by it. The server
notices both by itself, without waiting for a request: besides every message it wakes up every 250 ms, and looks at the
`factoria` file (size and modification time, a stat) every 2 seconds, and also once as soon as the client has initialized. A changed file is read for its build identity only once
it has stayed the same for two looks, so a copy that is still going on is never read half way. The identity is the version
and the commit fingerprint written in the binary (`factoria version` prints both); a file with the same fingerprint (a rebuild
of the same commit) or with none (a build outside git says `unknown`) is never counted as an update.

**Linux and macOS: it restarts itself in place.** Between two messages, when nothing is handled and no input is held back, the
server executes the new file with `exec`, keeping the same stdin and stdout, so the client keeps talking to the same
process id and never sees a disconnect. The old process hands over what the client negotiated (protocol version, client
info, capabilities, log level) in the hidden option `--resume-session <json>` (never pass it by hand), so the client needs no
new `initialize`. What the client wrote while the swap happened stays in the pipe, which the new process inherits: no request
is lost. The new process sends `notifications/tools/list_changed` and `notifications/resources/list_changed` (the tools may
differ) and a `notifications/message`, and the first `tools/call` result after it carries a last text block:

```
[FactorIA notice] FactorIA was updated to 0.4.0 build 1a2b3c4d5e6f (the server was running 0.3.0 build f530fda3e543); the MCP
server restarted itself in place, so the connection to the client was kept ... Nothing the client may count on was lost.
```

What is lost in a restart is said in that notice, and it decides whether the server restarts at once or waits:

- The headless engine behind the `game_*`, `scene_*` and `project_*` tools lives in the process, so a restart starts it again
  from the project's start scene. When it had run (any frames stepped), the server restarts anyway and says so in the
  notice: "Lost in the restart: the game session (it had run 120 frames) starts again from the project's start scene, so any
  scene edit that was not saved to disk (scene_save) and the frames stepped are gone". Staying on the old code for hours seemed
  worse than that, and the notice tells the AI what to redo. Everything that is on disk (scenes, scripts, assets) is untouched.
- A tool call that is running is never cut off: the server only restarts between messages, so a long `ai_run` or
  `project_test` finishes (and is answered by the old process) first; the restart follows right after its answer. The hook for
  work that must not be cut off is `McpUpdateOptions::busy` (`engine_update_status` shows its reason in `mcp.deferredBy`);
  `factoria mcp` itself has no background work, so there it is empty.
- A restart that fails (the new file cannot start) leaves the old process serving and tells the AI to reconnect instead; after
  5 restarts in a row it stops restarting, so a broken new file cannot loop.

**Windows: no restart.** A running program cannot be replaced there and the client owns the process's stdio, so the server
does not restart. It adds a notice to the next tool result and sends a `notifications/message` (warning) that says FactorIA was
updated on disk, that this server still runs the old code, and asks the user to reconnect the `factoria` server (in Claude
Code: `/mcp`) or restart the client. Once per update.

**A client with an older `.mcp.json`.** A client reads `.mcp.json` only when it starts. For a client that reads it (Claude Code),
the server compares the file's modification time with the time its own first process started (kept across restarts in place):
a file edited later is reported once in a tool result, asking the AI to have the user restart the client or reconnect (`/mcp`).
If the project's file has no `timeout` for the factoria server, the server adds `"timeout": 14400000` to it (the rest of the
file is kept) and says so in that notice; a file it cannot write is reported with the line to add by hand. A `timeout` that is
there, whatever its value, is the user's and is left alone.

`engine_update_status` (read-only) says all of it on demand: `running` and `onDisk` build ids, `restartDue`,
`state` (`current`, `updated_on_disk`, `unidentified`, `settling`) and, under `mcp`, `canRestartInPlace`, `restartPending`,
`deferredBy`, `restartsInARow`, `client` and `projectConfig` (the `.mcp.json` state: `hasTimeout`, `clientReadsIt`,
`changedAfterClientStarted`, `timeoutAddedByFactoria`, `advice`). Run it first when tools seem to behave as in an older
version. Inside the editor the same command has an `editor` part (`noticeShown`, `restartAllowed`, `restartBlockedBy`).

## Embedding (C++)

```cpp
fa::SimpleMcpHost host(registry, projectDir);   // or subclass fa::McpHost
fa::McpServer server(host);
fa::run_stdio(server);                          // blocking; server.handle_message(line) for other transports
// after tools change:
server.notify_tools_changed();
```
