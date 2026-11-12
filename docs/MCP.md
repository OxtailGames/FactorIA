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

- **Tools**: every registered command (or, with `--tools core` or a group list, the core set and those groups plus
  `tool_load` / `tool_describe` / `tool_call`: [Tool profiles](#tool-profiles)). `scene.list_entities` becomes `scene_list_entities` (characters
  other than letters, digits, `_`, `-` become `_`; at most 64 characters). The description is the
  command's summary + details; `readOnlyHint` / `destructiveHint` come from the command's `readOnly`
  flag. A result is sent once, as the whole JSON in a text block, on every protocol version (no `structuredContent`:
  every client reads the text, so none misses part of the result). A result with an
  `"$image": {"path"|"base64", "mimeType"}` key gets an image block after the text, so screenshots are visible. When
  the image has `"temporary": true` (a `game_screenshot` without `path`) the server deletes the file after it has read
  it: the reply names no path (it says "Attached to this reply as an image; the temporary file was deleted. Pass `path`
  to keep a screenshot.") and the disk does not fill up over a long session. A client that cannot show images asks for
  `path`, and then the file stays. The engine also removes old engine-named shots (`frame_*.png` in
  `.factoria/screenshots/`) when a project opens: those older than 3 days, then the oldest beyond the newest 200.
  Failures are `isError` results: `code: message` and `hint: ...`.
  **Size cap**: a result over 80 KiB of JSON is cut down before it is sent, since a client puts it into its model's context
  (Claude Code refuses one over about 25k tokens, and JSON runs about 3 bytes a token). The heaviest part goes first: an array or an object keeps its first items
  or keys, a long string its start (never in the middle of a UTF-8 character), and what is sent is always valid JSON. An
  object result gets a `_truncated: {"note": ...}` field (any other result is sent as `{"result": ..., "_truncated": ...}`)
  that says what was cut (`` `/entities` keeps the first 812 of 4000 items``) and how to get the rest: the paging
  arguments the tool's own `inputSchema` declares when it has some (`offset`, `limit`, `startLine`, or a camelCase name of
  its own that starts or ends with the word offset, limit, cursor or page and takes an integer or a string, such as
  `pageToken` or `entityLimit`), else the arguments that ask for less (`filter`,
  `path`...), else to ask for a smaller part. A picture is not counted: the cap is for the JSON.
  A tool's `inputSchema` is closed: `tools/call` with an argument the tool does not declare fails with `invalid_arguments`
  (`/frame: unknown property 'frame'`, the hint offers the closest declared name and lists the accepted ones) and runs nothing, so
  an ignored typo cannot look like a success. An object that takes open-ended keys says `additionalProperties: true` in its
  schema. `_meta` is the protocol's own key: it normally sits in `params`, and a client that puts it in `arguments` is not
  refused (the server drops it before checking).
- **Resources**: `factoria://docs/<file>` (embedded docs, `factoria://docs/components` generated),
  `factoria://project/factoria.json`, `.../ENGINE_FEEDBACK.json`, `.../AGENTS.md`.
- **Prompts**: `make-game` (idea), `add-feature` (feature), `fix-bug` (description), `report-engine-gap`. They tell the AI to read by section, not whole: the guide's index first
  (`docs_read {"name":"ai-guide","heading":"Index"}`), then only the sections the task needs, `docs_list` (a summary and
  an `audience` per doc, filter `{"audience":"gameAi"}`) to find other docs, and components or commands one at a time
  (`docs_components {"name":"Sprite"}`), never with `full`.
- **Notifications**: `notifications/tools/list_changed` when project tools (`tools/*.js`) change;
  `notifications/message` for logs (`logging/setLevel`); `notifications/resources/list_changed` and a log message after the
  server restarted itself because FactorIA was updated (see [After an update](#after-an-update)). Project tools are also
  hot-reloaded while the client is silent, and the files are checked again before every request, so a tool file written a moment
  ago (in a `tools/` folder that did not exist at start too) is already in the answer to the next `tools/list` or call.
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
- **Cancellation**: `notifications/cancelled {requestId}` takes back a request that is still running. The command stops
  at its next step (a compound command or an agent stops before its next command, with code `cancelled`; `ai_run` stops
  its sub-agent) and the request gets no response, as the protocol says. A cancel for a request that is unknown or already
  answered is ignored. Over stdio the server reads its input all the time on a thread of its own, so a cancel reaches it at
  once: a request that runs stops, and one still waiting behind another (requests run one at a time) is skipped and never
  runs; every other message waits for its turn. When the client closes stdin (the protocol's way to shut a stdio server
  down) the messages read before it are still handled, but a request still running or waiting 10 seconds later is
  cancelled, so a long `ai_run` does not go on for a client that is gone. Over HTTP the cancel is a POST of its own (answered 202, and let in even
  when every connection is taken: the endpoint keeps a spare one) that reaches the call running on another connection of
  the same client; the cancelled call's POST gets no JSON-RPC response: its event stream ends empty, or a client that does
  not accept event streams gets `204 No Content`. In the editor, a command that an agent's call runs on the editor's main
  thread (a scene edit) is dropped if the cancel comes while it still waits for its turn there; one that already runs
  there finishes, and its result is not sent.
- **Malformed messages**: nothing a client sends stops the server. Text that is not JSON gets a Parse error (`-32700`);
  a message of the wrong shape (`"jsonrpc"` that is not the string `"2.0"`, a `method` that is not a string, an `id` that
  is not a string or a number, `params` that are not an object, an item of a batch that is not an object) gets an
  Invalid Request (`-32600`) that carries its id when it has a valid one (`null` otherwise); the messages around it are
  answered as usual. A request that fails inside the server gets an Internal error (`-32603`); a notification that fails
  is dropped and logged.
- **Read-only mode**: `factoria mcp --read-only` serves only the commands that look and play (reading, `game_step`,
  `game_input`, `game_click`, `game_screenshot`, `scene_load`, UI scale checks, ...). The others are not listed and a call
  to one is refused. `ai_run`, `ai_review` and everything that edits the project are among the hidden ones. FactorIA starts
  Codex's server this way for the `artCritic` and `reviewer` roles (`docs/AI_PROVIDERS.md`, Reviews).
- **User-only commands**: `ai_plugin_install` (it installs a Claude Code plugin on the user's computer) is never listed or run by any MCP
  server, read-only or not: the user starts it from the editor's AI settings or the CLI (`docs/AI_PROVIDERS.md`, "Installing a plugin").
- **Roles of `ai_run`**: `ai_run {role, task}` runs the `worker`, `fast`, `artist` or `audio` role (and `orchestrator`, the default of the
  command). The art critics and the game reviewers are not available through it: the user asks for them. The roles are those of the
  project the server serves (`--project`, or the project containing its folder): its `.factoria/ai/settings.json` applies once the
  user accepted it, and a role the project turned off is refused with `role_off`, naming the project setting and how to change it
  (`ai_settings_set`, see below).
- **AI settings**: `ai_settings_get {scope: resolved|project|user}` shows each setting with where it comes from (`project`, `you`,
  `default`); `ai_settings_set {scope, pointer, value}` changes one. A project change is written but never accepted: it applies only
  after the user accepts the file in the editor, and the result says `needsAcceptance` (`docs/AI_PROVIDERS.md`, "Per project"). Scope `user`
  (the user's own `ai.json` defaults) is refused to every MCP client with `user_only`: ask the user to change it in the editor's AI
  settings window. (A client with file access to `~/.factoria/ai.json` can still edit it by hand: the refusal is not a sandbox.)
- **Instructions**: the server sends a short engine guide on `initialize`, including the rule to call
  `feedback_report` whenever the engine lacks something.

### Tool definitions and Claude Code

The server lists every command (404 tools, about 1 MB of definitions, in a new `2d-empty` project of the 0.19.0 engine,
counted on 2026-11-09; `factoria commands` prints the list of your version, and the number grows with each one). Claude Code 2.1.312 does not put them all in the
model's context: it defers the tools of MCP servers behind its own tool search, so the model sees their names and loads a
definition when it needs it. Checked on 2.1.312 with the FactorIA server and a one-word prompt: the context after the first
message was 39,920 tokens by default and 78,425 with `ENABLE_TOOL_SEARCH=false` (tool search off, every definition loaded).
So the default profile (`all`) changes nothing for it: `claude-code` roles already get this saving.
If an agent keeps missing a tool of the server, `"alwaysLoad": true` on the server's entry in the client's MCP config opts
that server out of deferral. This is Claude Code's own behaviour and can change in its next versions; check it with the
`ENABLE_TOOL_SEARCH` comparison above before relying on a figure. A client that has no tool search and is billed per token
should pick a profile (next section); `factoria mcp --read-only` also gives a smaller set.

### Tool profiles

`factoria mcp --tools <profile>` chooses what `tools/list` offers (the same core set and group rules as the built-in agent's
catalog, [AI_PROVIDERS.md](AI_PROVIDERS.md#tool-groups-and-the-catalog); `fa/tooling/tool_groups.h`):

| Profile | `tools/list` | Size (0.23, `2d-empty`, about) | Pick it when |
|---|---|---|---|
| `all` (default) | every command | several hundred tools, ~1 MB of definitions | the client defers MCP tools (Claude Code), or tokens do not matter |
| `core` | the core commands (about 40: files, docs, the scene, running and looking at the game, validating, scripts; `factoria mcp --help` gives the exact count) plus `tool_load`, `tool_describe`, `tool_call` | a few dozen tools, ~55 KB | the client loads every definition into the model's context and the work is the usual edit-run-look loop |
| `core,anim,physics` | the core set plus the commands of those groups (a group is a command category, an exact command name such as `assets.slice_sheet`, `core` or `all`) | core plus the groups | you know which areas the session needs |

An unknown group is refused at start (`--tools: Tool group 'phyiscs' matches no command category and no command. Did you
mean 'physics'?`). Nothing is hidden for good: with a profile other than `all` the client still reaches every command (minus
the user-only ones, and minus the writes when `--read-only` is set; both apply to everything below):

- `tool_load` `{"groups": ["anim"]}` adds the groups to the session's list and sends `notifications/tools/list_changed`
  (the server declares `tools.listChanged`). Its description names the categories with their command counts; without
  `groups` it returns all of them with how many of their commands are listed.
- `tool_describe` `{"commands": ["assets.slice_sheet"]}` returns the full definition (description and input schema) of any
  command, loaded or not; `tool_call` `{"command": "assets.slice_sheet", "arguments": {...}}` runs any command with the
  result of its own tool (progress, images and size cap included). Use them with a client that ignores `list_changed`.
  Calling a command's own tool name directly also works while it is not listed.

The groups loaded with `tool_load` last as long as the server process; a server that restarts itself in place after an
update starts again from the `--tools` profile.

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
