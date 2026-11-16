# FactorIA architecture: commands

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page).

## Commands (the tool system)
`fa::CommandRegistry` (core/command.h) maps `"area.verb"` names to
`JSON -> JSON` handlers with a JSON Schema and docs. Commands come from:
- C++ (`registry.add({...}, handler)`) — engine built-ins, tooling;
- JavaScript tool modules — `tools/*.js` in a project (and built-in JS tools),
  registered as `project.<name>` without recompiling anything:

```js
// <project>/tools/spawn_wave.js
import { world } from "factoria";

export default {
  name: "spawn_wave",                         // -> command "project.spawn_wave", MCP tool "project_spawn_wave"
  summary: "Spawn a wave of enemies around the player.",
  input: { type: "object", properties: { count: { type: "integer", default: 5 } } },
  readOnly: false,
  run({ count }) {
    for (let i = 0; i < count; i++) world.spawnPrefab("prefabs/enemy.prefab.json");
    return { spawned: count };
  },
};
```

Every command is automatically exposed through MCP (`factoria mcp`), the
built-in AI agent, the CLI (`factoria call <name> '<json>'`), the editor console
and scripts (`fa.call(name, args)`).

**Arguments are closed by default.** A command's `inputSchema` is the contract, and a key it does not declare is an
error, never silently dropped: `CommandRegistry::add` closes every object schema that has `properties` and no
`additionalProperties` (it adds `additionalProperties: false`, at the root and in nested objects, array items and
`anyOf`/`oneOf`/`$defs` branches; `fa::close_object_schemas`, core/json_schema.h). So `describe` and `tools/list` show
what is enforced, and re-adding a command (the editor's AI panel does) changes nothing. A call with an unknown key fails
with code `invalid_arguments`; the message names the key and its JSON pointer (`/frame: unknown property 'frame'`), and the
hint is `fa::did_you_mean` plus the accepted keys. A command with no declared `properties` takes no arguments. The opt-out
is explicit: `"additionalProperties": true` (any key) or a schema (every extra key must match it), for an object whose keys
are really open-ended; only then can the handler read keys the schema does not list. Nothing in the engine's own command set
uses it (`tools/cli/tests/command_schema_test.cpp` walks the whole registry and fails on a root that is open without being
listed). The one key the registry removes before validating is `_meta`, the MCP transport's metadata, unless the command
declares a property of that name. Defaults are applied first, then the check. When you add a command, declare every key
the handler reads, with a `description`; the same rule applies to `project.<name>` tools (their `input`).

**The schema is compiled once, at registration.** `CommandRegistry::add` builds a `fa::CompiledSchema` (core/json_schema.h)
from the closed `inputSchema` and keeps it in the command's entry; `call` validates and fills defaults against it instead
of walking the Json: `$ref`s are already resolved (a recursive one too), the keywords are read out, the defaults are
collected and each `pattern` is a compiled regex. It reports exactly what `validate_json(const Json&, ...)` reports (same
message, JSON pointer and hint, an invalid `pattern` at the same point, when a string is checked against it), and the
unit tests and the `json_schema` fuzz target run both and compare. `call` copies the arguments only when it has to (a `_meta`
key to remove, or a schema with defaults to fill); otherwise the handler receives the caller's Json. A schema that is
parsed for one validation (a project file, a config) keeps using the Json overloads: compiling costs more than one walk.

**A path argument says what the command does with it: `"x-fa-path": "read" | "write"`.** An annotation on a string property
(or on an object whose values are paths, such as `publish`'s `folders`) in the `inputSchema`. The validator ignores `x-`
keys (an unknown keyword is not an error, and `close_object_schemas` keeps them), so the annotation changes nothing at
run time: it is documentation the schema carries to `describe`, `tools/list` and the docs reference, and what a review or a
test greps for to find every place a caller can name a file. `write` marks an argument the command writes to: its handler
must resolve it with `fa::fs::resolve_for_write` or, in tooling, `resolve_write_path` (it passes
`allowAnywhere = caller_capabilities().has(Capability::WriteAnywhere)` and the project folder the command was registered
with, and refuses the managed folders), never with `std::filesystem` directly; see "Files". `resolve_project_path` is not
for such an argument: it never allows an absolute path and leaves the managed folders open, because it also serves reads
and the tools' own files. `read` marks a file the command reads (annotated where obvious;
reads are not confined by this rule).

**A description stays under 1.5 KB.** MCP's `tools/list` sends every command's summary and description with every
request, so `tools/list` costs the sum of them. `tools/cli/tests/mcp_description_budget_test.cpp` walks the real registry and
fails, naming the command and its size, when the description as MCP sends it (JSON escaped: a quote or a newline
counts two bytes) passes 1536 bytes. What does not fit goes in `CommandInfo::details` (the last member, or after
`FA_COMMAND_DETAILS` inside the description, for commands a helper builds from a summary and a description; set one of
the two, not both: when `details` is set the marker is removed with a warning): the first part is a complete statement
of what the command does and its essentials, the
rest is what a reader needs only once working with it. `details` is printed after the description in the docs reference
(`docs/reference/commands/<category>.md`, `docs_commands {"name": ...}`, `factoria commands <name>`, `commands.describe`), and
the description MCP and the built-in agent send ends with a sentence that names that section (`command_details_pointer`).
So nothing is lost: the arguments table of the reference has always carried each argument's own description.

### Capabilities
A command says what it can do outside the engine's memory with `CommandInfo::capabilities` (`core/capability.h`), a set of
these (JSON names are camelCase):

| Capability | Meaning |
|---|---|
| `read` | reads project or engine state |
| `state` | changes the running game or the open scene in memory only, writes no file |
| `writeProject` | writes files inside the project, including the game's own save folder (`storage.clear` needs it) |
| `writeAnywhere` | writes outside the project (absolute paths, the user's folders and settings) |
| `network` | talks to a remote service |
| `process` | starts an external program |
| `spend` | can cost money (paid APIs, store fees) |
| `publish` | makes something public or uploads a build to a store |

A command that declares nothing gets a set derived from `readOnly` when it is added: `{read}` if read-only, otherwise
`{read, state, writeProject}` (never one of the dangerous four, so a command that needs one must declare it);
`CommandInfo::capabilitiesDeclared` tells which. A command declares its own set in one of two ways: a module that registers many
commands calls `declare_command_capabilities(registry, {{"name", set}, ...})` once with a table right after its `add()` calls (it
logs an error for a row naming a command that is not registered), and `CommandRegistry::declare_capabilities(name, set)` does
it for one command. Both flag the command as declared and **recompute `readOnly` from the set** (`readOnly` is true only for
`{read}`, whatever `add()` was given), so the flag and the set never disagree. A JS tool (`capabilities: [...]` in its default
export) and a native plugin (`set_command_capabilities`) do the same; if a JS tool also says `readOnly: true` next to more than
`{read}`, the engine logs one warning that names the tool, since `readOnly` is derived. An empty set is refused everywhere
(`capabilities: []`, `[]` from a plugin, an empty set in a table): a command needs at least `read`, and the error says so; the
command keeps what it had. `process` is for a program the command itself runs; a platform helper behind a game feature (the
speech helper `spd-say` that `ui.speak` starts on Linux) counts as `state`. A command that runs a child `factoria call` of the
same engine to render for itself (`assets.contact_sheet` on a .glb, `assets.bake_sheet`) does not declare `process` either: the child is
this engine, not an external program, and the command judges every path it passes on before it starts the child. `describe()` lists them under `capabilities` (camelCase names) and `capabilitiesDeclared` (bool). The same two fields appear in
`api.commands`, `factoria commands [--json]`, `factoria api --json` (api.json); every command page of the generated reference
has a "Capabilities:" line ("not declared yet" while `capabilitiesDeclared` is false); an MCP tool carries them in its
`_meta` (`factoria/capabilities`, `factoria/capabilitiesDeclared`) and `tool_describe` returns them per command.

A command that writes a file only when the caller passes a `path` (`game.screenshot`; the authoring commands `anim.filmstrip` and `vfx.filmstrip` too)
declares the capabilities of its default behaviour (`{read, state}`: the picture goes under `.factoria/`) and its handler
calls `resolve_caller_write_path` for the `path`: it needs `writeProject` (`require_capability`) and keeps the file inside
the project (`fs::resolve_for_write`; an absolute path needs `writeAnywhere`); the schema property carries `"x-fa-path": "write"`.
`resolve_caller_project_path` is the same check returning the path in the project's own spelling (relative to the project when
the file is inside it): the runtime's file commands use it for the path they also read back or report, so `scene.save`,
`input.record` (`path`) and, in fa_authoring (developer tools only), `scene.import_ascii` (`path`), `scene.ascii_edit` (`file`), `anim.*` (`path`), `mesh.save`
(`save_mesh_glb(data, path, allowAnywhere)`; a game script's `mesh.save` is always confined to the project) refuse `..`, absolute paths, `.git/` and `.factoria/` (except `.factoria/tmp/`) for an MCP client
or an agent and check the path before any other work (`input.record` keeps its recording when the path is refused).
`prefab.save` (`path`) and `scene.format` (`paths`) are confined the same way, and so is the editor's own `scene.save`.
`scene.import_ascii` and `scene.ascii_edit` declare `{read, state}` because their `dryRun` only reads: the handler asks for
`writeProject` (`require_capability`) as soon as the call would write (a `path` or `file`, or `save`), so `dryRun: true` works
for a read-only MCP client. `require_capability` words the refusal as the dispatcher does (the caller's hint, the game's
`{read, state}` floor).
The registry is walked by `tools/cli/tests/command_paths_test.cpp`: every command declares its capabilities, and every
schema property marked `"x-fa-path": "write"` refuses `../outside.txt` and an absolute path for an MCP client without creating
anything outside the project; a new command that writes a caller's path is covered by marking its property.

What a caller may do is a `CapabilitySet` (`caller_capabilities()`). The named sets are `fa::capability_sets::`
`cli_user` (all), `mcp` (all but `writeAnywhere`), `mcp_read_only` (`{read, state}`: the play commands that the `--read-only` filter serves change the game; the filter
keeps the editing commands out, and `McpServer::set_capabilities` installs the set on every tools/call),
`agent` (all but `writeAnywhere` and `publish`), `game_player`, `editor_play` and `test_script` (`{read, state}` each). A `CommandCaller` starts from its set (User:
`cli_user`, Mcp: `mcp`, Agent: `agent`). **A scope only narrows**: `CommandCapabilityScope` (and `CommandCallerScope`)
intersects with the set of the thread, so nothing nested inside a call can widen it; the consequence is that a nested
call cannot run with "the tool's own set", a handler that needs more than its caller has is refused. Code that hops threads
(job queues, the editor's main-thread queue) captures `command_context()` (caller and set) and installs it on the other
thread with a `CommandContextScope`; the context also carries the hint provider that words a refusal (below). The editor's main-thread queue
(`MainThreadQueue`) does this for every command a worker thread queues, so a command an MCP client or an AI role asks for runs
on the main thread with that caller's set, not with the user's. A job or pool task that runs a command *for a caller* must do the
same; the editor's background jobs only run the user's own subprocesses, so they need nothing.

**Per AI role** (`fa::ai::role_capabilities`, declared in `tools/ai/include/fa/ai/config.h` next to the role definitions): the
builder roles (orchestrator, worker, fast, artist, audio) get `capability_sets::agent()`; the critics (`artCritic`, `reviewer`)
get `{read, state}` (`capability_sets::mcp_read_only()`; an unknown role too) and only the commands of `is_read_only_tool`,
never `writeProject`, `writeAnywhere`, `network`, `process`, `spend` or `publish`. Two barriers hold: the tool list, and the
set, which refuses a forced `scene.save` with `capability_denied`. The play tools fit the set (`game.screenshot`,
`anim.filmstrip`, `vfx.filmstrip` and `play.auto` are `{read, state}`); their optional `path` argument needs `writeProject`
(`resolve_caller_write_path`), so a critic gets its pictures without a `path` and a `path` is refused. `AgentSession` runs each tool call inside a `CommandCallerScope(Agent)` and a
`CommandCapabilityScope(role set)`, and does not offer (nor accept) a command the set does not cover. A CLI agent gets the set in
its environment (`FACTORIA_CAPABILITIES`, `FACTORIA_ROLE`; also in the `env` of the stdio `factoria` server of its MCP config
and, for Codex, `-c mcp_servers.factoria.env=...`), and `factoria` installs a `CommandCapabilityFloor` from it: on every
thread of that process `caller_capabilities()` is never wider than the role's. An unparsable value is the empty set. The
variables are in `base_child_env()`, so a program an agent starts passes them on. For a review role `factoria call`,
`session`, `ai` and `mcp` also drop every command that is not an `is_read_only_tool` (`mcp` gets `--read-only`), so a reviewer
that runs `factoria` from its own shell sees what its tool list shows. The editor's per-run MCP endpoint applies the role's
set itself (`endpointRole`) and, for a review role, serves only the `is_read_only_tool` commands: the `ai.*` commands it
registers for builders (`ai.run`, `ai.settings.set`...) are neither listed nor callable.

`CommandRegistry::call` checks it right after the lookup, before the arguments are validated (a bitmask AND) and **before a
command interceptor** (the AI hooks) sees the call: a command whose capabilities are not all granted fails with code
`capability_denied`, and a denied call never reaches `before` or `after` of an interceptor (the one exception is a
command that only exists after the `beforeCall_` reload, which `before` may see before the second check refuses it).
The message names the command, each missing capability
with its meaning, the caller and the granted set; the hint says where each caller gets what (the CLI user has all, `factoria mcp`
without `--read-only` all but `writeAnywhere`, a game script `{read, state}`, a test can ask for more with `capabilities` in
its test options); `error.data` has `command`, `missing`, `needs` and `granted`. The default hint is generic; a caller that
knows better installs a `CapabilityHintProvider` (`CommandCapabilityScope`'s second argument, carried by `command_context()` so
it follows the work to other threads) and its words replace it: that is how a game script, the editor's Play and a test
each get their own pointer, without core matching strings.

**Scripts as callers (M92.1d).** The script host (`ScriptSystem`, per instance, never a global: two engines in one process
do not mix) knows its role: `GameRole::Player` (`factoria run`, an exported game) or `EditorPlay` (the editor's engine,
`EngineConfig::editorMode`), both `{read, state}`. `Impl::run_command` is the only door from JS to the registry and wraps
the call by mode: *Game* (every entry from C++ into JS: callbacks, events, timers, promises, `game.step`, module top levels)
installs the game's set and hint; *Test* (the body of a test while `run_tests` runs) installs `test_script` plus the test's
`capabilities` option; *Caller* (a project tool's handler, `script.eval`) installs nothing, so the thread's set, the caller's,
applies. A scope only narrows, so a tool a game script calls through `fa.call` runs with the game's set, and a test's set is
the intersection with whoever runs the tests. The engine library is checked against the declarations: each `fa.call` a
`factoria` helper makes is `{read, state}` (`tilemap.generate`'s `place` uses `scene.place_ascii`, the in-memory twin of
`scene.import_ascii`). If a path dispatches commands on another thread or job, carry `command_context()` there.

