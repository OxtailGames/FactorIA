# FactorIA architecture

FactorIA is a 2D/3D game engine designed so that **AI agents can build games
with it reliably** and **anyone (human or AI) can add tools easily**. It targets
Windows, macOS, Linux, iOS and Android from one codebase.

## Design principles

1. **Everything an AI needs is text.** Projects, scenes, prefabs and input maps
   are JSON with schemas; gameplay is JavaScript; docs ship inside the binary.
2. **One registration, every surface.** A component is reflected once and is
   then loadable from JSON, editable by commands, scriptable, documented and
   type-checked. A command is registered once and is then an MCP tool, an AI
   tool, a CLI subcommand, an editor console command and a JS function.
3. **AIs must be able to see and test.** Headless deterministic runs, input
   replays, screenshots, JSON state dumps and a JS test runner work without a
   display or GPU drivers beyond Mesa.
4. **Errors teach.** Every error says *where* (file + JSON pointer or line),
   *what*, and *how to fix it* (hint, "did you mean ...?").
5. **The engine learns from its users.** Every game keeps an
   `ENGINE_FEEDBACK.json` where AIs record what the engine lacked and how they
   worked around it; tools aggregate those files to drive engine work.
6. **Builds anywhere, offline.** All dependencies are vendored; CMake is the
   only build tool; one preset per platform.

## Languages and why

| Layer | Language | Why |
|---|---|---|
| Engine runtime, tools | C++20 | Native toolchains on all 5 OSes (MSVC, Xcode, NDK, GCC/Clang), no runtime, huge AI training corpus for engines |
| Gameplay scripts, project tools | JavaScript (QuickJS-ng, ES2023) | The language AIs write best; no compile step (hot reload); `.d.ts` typings for type-checking; interpreter is pure C so it runs on iOS (no JIT allowed) |
| Data | JSON (+ JSON Schema) | Universally readable/writable by AIs, diff-friendly |
| Build | CMake ≥ 3.24 | Generates Ninja / Visual Studio / Xcode; Android Gradle consumes it natively |

## Repository layout

```
engine/            runtime modules (ship inside every game)
  core/            fa_core     types, math, log, json, fs (VFS; sources: the project folder, Android APK assets, a game pack: pack.h), image, reflection, commands, json schema, child processes (process.h), SHA-1/SHA-256 (hash.h), crash reports (crash.h), UTF-8 decoding and encoding (utf8.h), MPEG-1 video + MP2 audio decoding (video.h, pl_mpeg), string tables, plural rules and language matching (i18n.h)
  scene/           fa_scene    World (ECS), built-in components, scene/prefab JSON, 2D bounds of visuals (bounds.h), glTF skeletons and clips (skeleton.h) and the Animator system (animation.h), GPU-free model reader for colliders (mesh_geometry.h), the Video system (video.h: plays the Video components from the game clock)
  platform/        fa_platform window/app loop (sokol_app), headless GPU, input + actions, gamepads, the system languages
  render/          fa_render   2D + 3D renderer, text (HarfBuzz shaping, SheenBidi bidi), particles, debug draw, capture, KTX2 textures (Basis Universal transcoder), the picture of Video components
  physics/         fa_physics  Box2D v3 (2D) + simple 3D (spheres, oriented boxes, capsules, convex hulls, static triangle meshes, rigid-body rotation, hinge/ball/fixed joints, character controller, continuous collision, shape casts)
  audio/           fa_audio    mixer with a bus table (built-in plus project buses) with per-bus effects (low-pass, reverb, ducking) and snapshots, wav/ogg/mp3, null device + recording, the sound of Video components; the device callback takes no lock and allocates nothing (lock-free command and return rings, streams decoded on jobs, docs/SOUND.md "The audio callback")
  ui/              fa_ui       game UI behaviour: Panel/ScrollList layout, focus + keyboard/gamepad/mouse navigation, widget values, `ui.*` events
  services/        fa_services store and platform services: the `"platform"` catalog, the request dispatcher (`PlatformServices`), the fake and "none" backends, the `platform.*` commands
  script/          fa_script   QuickJS bindings, behaviours, JS tools, test runner, scripts compiled to bytecode for game packs (bytecode.h), the script debugger runtime (debugger.h, docs/design/SCRIPT_DEBUGGER.md)
  runtime/         fa_runtime  Engine (game loop), project file, built-in commands
player/            factoria_player — minimal runtime for exported games
tools/             developer tools (desktop only)
  common/          fa_tooling  scaffolding, validation, ENGINE_FEEDBACK, embedded docs, API export, export (platform settings, icons, exe icon patcher, texture compression with the Basis Universal encoder, atlas packing), setup (one-click install of the JDK, Android SDK, players, CMake), palette lock, AI-content disclosure
  mcp/             fa_mcp      Model Context Protocol server (stdio; loopback HTTP for the editor)
  dap/             fa_dap      Debug Adapter Protocol server of the script debugger (framing, launch validation, DapServer); `factoria dap` runs it
  ai/              fa_ai       AI providers (API keys + Claude Code / Codex CLIs), agent loop, roles; asset providers (images, sounds, 3D models) and the assets.generate_* commands
  editor/          fa_editor   Dear ImGui editor with AI assistant panel
  cli/             factoria    the single developer binary
  vscode/          the VS Code extension of the script debugger (plain JS, no build step): embedded in fa_tooling and installed by `factoria setup vscode`; it starts `factoria dap` (docs/DEBUGGING.md)
  bench/           fa_bench    the engine's microbenchmarks (ECS queries, hierarchy, physics, render gather, command dispatch, script bridge, audio mix) with a baseline per machine kind (docs/PERFORMANCE.md, "Microbenchmarks")
  fuzz/            fuzz targets of the loaders and decoders (libFuzzer with `FA_FUZZ`, a corpus replay ctest otherwise; docs/BUILDING.md, "Fuzzing")
  shaders/         compile_shaders.sh: regenerates the engine's shader headers with sokol-shdc
  feedback-server/ the Cloudflare Worker behind feedback sharing (JavaScript, its own npm tooling; docs/design/FEEDBACK_SHARING.md)
  ci/              docker/: the image of the local Linux CI job (scripts/ci-local.sh)
templates/         project templates used by `factoria new`
skills/            the engine's AI skills (one SKILL.md per folder), baked into the binary (docs/SKILLS.md)
schemas/           JSON Schemas (project, feedback, AI config); scene schema is generated
docs/              documentation in English (embedded into the binary); translations in docs/i18n/<lang>/ (some are behind the English text: each says so at its top)
examples/          sample games (also used as integration tests: the `example_*` ctest tests, run in Release builds)
platforms/         android/ (Gradle), ios/, web/ and plugins/ (the store and ads backend plugins) packaging; windows/ (installer script) and linux/ (AppImage files) for the downloads
cmake/             CMake functions, platform selection and toolchain files
scripts/           build, test, CI and packaging scripts for each operating system (docs/BUILDING.md)
feedback/          ROADMAP.md, done/ (one file per finished milestone) and the feedback collected from the examples
external/          vendored third-party code (do not edit)
```

Module dependency order (a module may only include modules above it):

```
core -> scene -> platform -> render, physics, audio, ui, services -> script -> runtime -> tooling -> mcp, dap, ai -> editor -> cli
```

(`platform` is the OS layer: window, input, gamepads. `services` is the stores' side: achievements, purchases.)

## Core concepts

### World, entities, components
`fa::World` (engine/scene/include/fa/scene/world.h) stores entities (handles)
and reflected components in type-erased pools. Every entity has `EntityInfo`
(stable string `id`, `name`, `tags`, `active`) and `Transform`. Components are
plain data; systems in other modules read them. Pointers to components are
stable until removal. `destroy()` is deferred to the end of the frame (physics treats a
pending-destroy entity as gone at once: no body, no collisions, no query hits).

#### The hierarchy cache
`World::world_matrix`, `world_position`, `active_in_hierarchy` and `pending_destroy` are answered from a cache kept per
entity, instead of walking the parent chain on every call (`engine/scene/src/world.cpp`, `World::Impl`):

- **What is cached**: the world matrix (the parent's world matrix times the local TRS, from the root down: the one
  definition of `world_matrix`, cached or not) and "active in hierarchy" (own `EntityInfo.active` and every ancestor's).
  `pending_destroy` is a flag `destroy()` sets on the whole subtree (a pending subtree takes no new child, so it stays true
  until the flush). `drawn_matrix` is the same product with the game feel poses and is not cached while one runs.
- **Invalidation**: every MUTABLE access to a `Transform` or an `EntityInfo` drops the entity's entry and, below it, the
  entries that are valid: `get<T>(e)` / `get(e, type)` / `add` / `info(e)` on a non-const `World`, each callback of
  `each<Transform, ...>` / `each<EntityInfo, ...>`, `set_parent` (the child's subtree), `set_world_position`,
  `set_active`. No setter of `Transform` is involved, so any way of writing (C++, scripts, reflection, commands, the
  inspector, animation) is seen. The cost of a write is one flag when the entry was already dropped. `create()` resets the
  entry of a reused entity index.
- **Rules for code**: read through a `const World&` (or `std::as_const(world).get<Transform>(e)`): a read through a mutable
  `World` counts as a write and throws the cache away for nothing (`resolve_obj` in the script bridge, the UI and render
  passes already read through const). A `Transform&` or `EntityInfo&` KEPT from an earlier `get` and written after a
  `world_matrix` call is not seen: get the reference again after the read (the engine does not do it anywhere; the tests
  of `test_hierarchy_cache.cpp` check every write path against a walk up the chain, bit for bit).
- **Threads**: jobs may read (the render gather does, `world_matrix` from several threads at once): a valid entry is read
  with an acquire load and no lock, a missing one is filled under a small spin lock and published with a release store.
  Nothing may write while jobs read (the rule of every job), so an entry never changes under a reader.
  `World::hierarchy_version()` counts the invalidations that dropped a valid entry (one per write that found its entry valid,
  not one per entry of the subtree below it; `create` / `destroy` do not move it): tests use it to see that a read did not
  write, and a system can compare it with the value it saw to know that no entry was dropped since.
- **Same results on every run**: the matrices are the same bits however the entries were filled (the order of reads, the
  threads), and `game.state_hash` does not read them. Since M94.1c the product is `parent * local` from the root down
  (before it was grouped from the leaf up), which can differ in the last bit of a float from earlier versions of the
  engine for an entity two or more levels deep.

### Reflection
`fa::TypeRegistry::global()` (core/reflect.h) holds every component type with
documented fields. From it we derive: JSON load/save, `scene.set_component`, script
property access, JSON Schemas, Markdown docs and TypeScript declarations.

Versions: `tools/common/api_since.json` says which release added each component, field (`Component.field`), command
and script export, and the generated reference prints it. A new component, field, command or script export needs an
`"unreleased"` entry there (not in the registration call); the `"script"` section is keyed by the name of each export of
`engine/script/src/js/api.json` (`tween`, `NavAPI`; the object `nav` is of type `NavAPI`, so the version of
`nav.findTilePath` is the one of `NavAPI.findTilePath`), `Type.member` for each member or static of a class or interface
(`NavAPI.findTilePath`), and the same with a `test:` prefix for the `factoria:test` module (`test:TestGame.setDate`);
the generated `types/factoria.d.ts` gets an `@since` tag from it. The test `api_since` in `tools/common/tests` lists
the exact lines to add. A release renames `## Unreleased` in CHANGELOG.md to the version (CHANGELOG.md keeps `## Unreleased` and the newest minor version with its patches, because
`.github/workflows/release.yml` reads the tag's section from it; when a release is published, the previous minor version's sections move to
`changelog/0.<minor>.md`, one file per minor version with its patches, and the index line at the top of CHANGELOG.md gets the link; the test `changelog_split` fails while CHANGELOG.md holds two minor versions (the
patches of the newest stay); the README's "Version x.y" line and the Spanish README's "al día en la versión x.y" note
change to the new minor too, checked by `readme_version`), and the same test then tells you to replace every
`"unreleased"` with it and regenerate `docs/COMPONENTS.md` and the browsable pages in `docs/reference/` (`factoria call
docs.write_reference '{"out":"docs"}'` from the repository root, checked by the test `api_reference`; the same call also
rewrites the tools table of docs/AI_GUIDE.md section 4, the block between `<!-- generated: tools table ... -->` and
`<!-- end generated -->` (one row per command category: its tool names and a one-line purpose from
`tools/common/src/ai_guide_export.cpp`, checked by the test `ai_guide_tools_table`, which also fails on a category without
a purpose; a guide without the markers gives a `warnings` entry in the result and is left alone); plus
`factoria api --dts --project examples/<name>` for the committed typings).

### Commands (the tool system)
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

#### Capabilities
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

A command that writes a file only when the caller passes a `path` (`game.screenshot`, `anim.filmstrip`, `vfx.filmstrip`)
declares the capabilities of its default behaviour (`{read, state}`: the picture goes under `.factoria/`) and its handler
calls `resolve_caller_write_path` for the `path`: it needs `writeProject` (`require_capability`) and keeps the file inside
the project (`fs::resolve_for_write`; an absolute path needs `writeAnywhere`); the schema property carries `"x-fa-path": "write"`.
`resolve_caller_project_path` is the same check returning the path in the project's own spelling (relative to the project when
the file is inside it): the runtime's file commands use it for the path they also read back or report, so `scene.save`,
`scene.import_ascii` (`path`), `scene.ascii_edit` (`file`), `input.record` (`path`), `anim.*` (`path`), `mesh.save`
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

### Files: `fa::fs`
Everything the engine reads of a game (scenes, prefabs, textures, sounds, fonts, scripts, `factoria.json`) goes through
`fa::fs` (`core/fs.h`), by project-relative path (forward slashes, no `..`). The paths are answered from one of three
sources: the project folder on disk (`set_project_root`), the APK's assets on Android, or a **game pack**: one read-only
archive (`core/pack.h`) that `fa::fs::mount_pack` mounts, which is how a `--release` desktop export ships a game
([EXPORTING.md](EXPORTING.md#release-build-gamepak)). While a pack is mounted it answers every project-relative path alone
(`read_*`, `exists`, `is_directory`, `file_size`, `modified_time`, `list`); absolute paths and writes still go to the host.
So engine code must not open a game file with `std::ifstream` or `std::filesystem` on a path it built from the project
folder: use `fs::`, or the file will be missing from a packed game. A pack (format 2) holds each file in checksummed blocks of
256 KiB, each compressed with the file type's codec (`core/compress.h`: store, lz4, zstd). On 64-bit desktops it is
memory-mapped once; elsewhere (32-bit, web, `FA_PACK_MAP=0`) it reads positionally (no shared file offset), so it is safe from
any thread either way. `fs::read_view(path)` answers an `fs::FileView` instead of a vector: no copy for a file of a mapped
pack stored as it is (the view keeps the pack mapped while it lives, also after `unmount_pack`), a warm file or an Android
APK asset (`AAsset_getBuffer`), and an owned buffer otherwise; the background loader's texture, model and font reads use it,
and the other loaders still read vectors. A play session's `fa::LoadTrace` (`core/load_trace.h`) hooks into these reads to record each scene's
first-use order and the `loading` section of `play.report`; with no trace alive the hooks cost one atomic load. A trace
belongs to its engine, not to a thread: `Engine` marks its entry points with `LoadTrace::ReadingFor(this)`, so two engines in
one process (the editor's and an in-process `play.auto`) never record each other's reads, the editor's own reads (panels,
the asset browser, tools) are left out of a Play's trace, and work handed to another thread takes
`LoadTrace::current_owner()` with it (the music loader does; the M70.3 loader will, per job). `script/bytecode.h` compiles scripts
for the pack; the module loader reads a compiled script from the same `.js` path.

`fs::cache_dir()` / `fs::set_cache_dir()` is the per-user folder for files the engine can always rebuild (the shader
cache, [below](#start-up-order-and-the-shader-cache)); the game folder and the save folder never hold them.

**Paths a caller gives to a command that writes.** `fs::resolve(path)` accepts any absolute path, so a command that writes
a file named by its caller never uses it: it calls `fs::resolve_for_write(path, root, allowAnywhere, managed)`
(`core/fs.h`), the one place where such a path is confined. `root` is `WriteRoot::Project` (`project_root()`), `Save`
(`user_dir()`, the game's save folder) or `Export` (`fs::export_dir()`, `set_export_dir`; default
`<project>/build/export`, where `project.export` writes; created by the writer, not by the resolution). A relative path is
joined to the root: `a/../b` is fine, a `..` that leaves the root is `path_outside_root`, and after resolving symlinks
(`weakly_canonical`) the result must still be inside, so a link pointing out, or pointing nowhere, is refused too (for every caller, `allowAnywhere` included: a shared asset folder linked
into the project cannot be written through the link, only by its absolute path from the command line; `project_spelling` also
returns the symlink-resolved form of a path). An
absolute path (`/x`, `C:\x`, drive-relative `C:x`, UNC, `\\?\`, `~`) is `absolute_path_denied` unless `allowAnywhere`,
which only a caller that owns the machine (the command-line user) is given, never an agent. With `WriteRoot::Project` the
project's managed folders (`.git`, `.factoria/` except `.factoria/tmp/`: `check_writable`'s rule) are closed to a relative
path and to an absolute one alike (`managed_path_denied`): a path is refused when EITHER its normalized spelling OR its
canonical form (after symlinks) is managed, so a link `meta -> .factoria` and a link `.factoria -> data` both fail; names
are folded to lower case on every system (a case-insensitive volume makes `.GIT` the same folder on Linux too) and lose a
trailing dot or space (Windows strips it: `.git.` is `.git`); a command that picks such a target itself (selections,
previews, review files under `.factoria/`) passes `ManagedFolders::Allow`. A NUL byte, a drive in the first segment of a
relative path and, on Windows, a `:` in any segment are `invalid_path`; so is, on every system (a project must move
between them), a name Windows cannot create: a device name (`CON`, `PRN`, `AUX`, `NUL`, `CONIN$`, `CONOUT$`,
`COM1`-`COM9`, `LPT1`-`LPT9`, and `COM`/`LPT` with a superscript 1, 2 or 3, with or without an extension) or a name ending
in a dot or a space. That rule is about CREATING a name: on Linux and macOS it applies to every segment that is not an
existing regular file, folder or link, so a file that already has such a name (made on Linux) can still be read, and
deleted. On Windows it applies to every segment, as such a file cannot be there (`NUL` exists in every folder, with an
extension too, and `scenes.` is `scenes`). Other names compare without regard to case on Windows and macOS; on Linux they
compare byte for byte, so a name that is not UTF-8 stays what it is. Errors say which form was given, what the root
accepts, the root's real path and the fix, and end with `(code: ...)` (`fs::path_error_code`). In tooling there are three
entry points: `resolve_write_path(projectDir, path, root, managed)` for a path the caller names (the caller's right to
write anywhere decides `allowAnywhere`; managed folders refused unless `ManagedFolders::Allow`),
`project_write_file(projectDir, rel)` for the assets commands, which record project-relative paths and so stay inside the
project for everyone, and `fs.write`, `fs.edit` and `fs.delete`, which refuse the managed folders on the real path.
`resolve_project_path` (`resolve_for_write_in` with `allowAnywhere` false and `ManagedFolders::Allow`) is the reader's and
the tools' own: selections, previews, reads. The checks resolve the path and the caller opens it afterwards: a link
swapped in between is out of scope (it takes a local attacker with write access to the project).

**Windows file rules.** Windows refuses to replace or delete a file another thread has open for reading and moves a file's
time in steps of about 15.6 ms; POSIX does neither, so bugs that follow from them only showed in the Windows CI job. On
macOS and Linux the environment variable `FA_FS_WINDOWS_RULES=1` (ctest sets it for every test: docs/BUILDING.md, "Running
tests") makes `fa::fs` follow both rules: `fs::ReadStream` (a `std::ifstream` that registers its file while open; `fs::read_*`
use it) makes `fs::replace_file`, `fs::remove_file`, `fs::remove_tree` and `fs::write_bytes` fail on that file the way Windows
does, and `fs::modified_time` / `fs::host_modified_time` round down to 15.625 ms. Code that reads a file another thread or
process writes uses `fs::ReadStream` (or `fs::read_*`) instead of `std::ifstream`; code that replaces or deletes a file
that may be read uses `fs::replace_file` / `fs::remove_file` (they wait for readers, as `write_bytes` does) instead of
`std::filesystem::rename` / `remove`; a change detector uses `fs::modified_time` / `host_modified_time` instead of
`std::filesystem::last_write_time`, and still reads once more after a change (a time that did not move does not prove the
file did not change). With the mode off, the registry costs one atomic load per call.

**Private files** (`core/private_file.h`): `fs::write_private(path, bytes)` writes a file only its owner can open (secrets: the
AI config with a key, the feedback admin token) and `fs::make_private(path)` restricts a file another program made (the Android
keystore). The file is created restricted from its first byte (`open` with 0600 on POSIX; on Windows a protected DACL whose only
entry is the current user, set in `CreateFileW`) and replaces the old one with `fs::replace_file`, so no reader sees a
half-written or a world-readable file. Do not write a secret with `fs::write_text` plus a later `chmod`.

**Child environment** (`core/process.h`, `core/child_process.h`): by default a child inherits the whole environment. A child that
runs text from a prompt, a project or a stranger (hooks, AI agents, tool servers) sets `ProcessOptions::inheritEnv` /
`ChildOptions::inheritEnv`, an allow-list of names (or `PREFIX*`; case-insensitive on Windows): only those variables of the parent
reach it, then `env` is added and `unsetEnv` removed. `fa::base_child_env()` is the list every child needs (`PATH`, `HOME`, the
locale, temp folders, `SystemRoot`/`ComSpec`... on Windows) and `fa::child_env_allow(extra)` joins it with more names. tools/ai
builds each provider's list (`tools/ai/src/ai_env.h`) and the user extends it with `inheritEnv` in ai.json
(docs/AI_PROVIDERS.md, "Environment of the programs the AI starts"). An unset `inheritEnv` keeps the old behaviour. The list is a
floor against leaking a secret by accident, not a barrier: a child that runs with no sandbox (a shell, an agent in a permission
mode without checks) runs as the user and can read `ai.json`, the keychain and the files itself. A signed export run through the
stdio `factoria mcp` gets no `FACTORIA_*_PASSWORD` for the same reason: signing passwords are not in any allow-list.

### Block codecs: LZ4 and Zstandard (`core/compress.h`)
`fa::compress` / `fa::decompress` / `fa::decompress_into` (`Codec::Store`, `Lz4`, `Zstd`) are the engine's own
implementations of two public formats, with no outside library: the LZ4 **block** format (no frame; levels 1 to 12) and
the Zstandard frame format of RFC 8878 (levels 1 to 19). They are for the game pack (M70.4); `zlib_compress` stays for
`storage` and the PNG and PSD code. Their files are private (`engine/core/src/`): `lz4_codec.cpp`, `zstd_decode.cpp`
(every frame the reference tool writes except dictionaries: any window up to 128 MiB, Huffman with 1 or 4 streams and
treeless literals, predefined, RLE, compressed and repeated FSE tables, skippable and concatenated frames, the XXH64
checksum), `zstd_encode.cpp` (frames with the content size, Huffman literals, FSE sequences, raw and RLE fallbacks; levels
1-2 use one hash table, 3-19 hash chains with repeat offsets and lazy matching whose search depth grows with the level),
`xxh64.cpp`. Both formats are byte-compatible with the reference tools in both directions: `zstd -d` and `lz4 -d` read what
the engine writes (an LZ4 block wrapped in a frame), and the engine reads what they write (committed fixtures in
`engine/core/tests/data/codecs/`, README there). Rules the code follows: the output of `compress` is a pure function of
input and level (integer decisions only, explicit little-endian, no dependence on the width of `size_t`, so a pack built on
Windows equals one built on macOS); a decoder never trusts its input (every read and write is bounds-checked, memory is
the caller's `expectedSize` plus one 128 KiB literal buffer, `decompress` refuses a size no block of that length could hold
before it allocates, a window over 128 MiB or a dictionary is an error that says so); nothing is global, so every call is
thread-safe. The tests round-trip many inputs at many levels, decode the reference fixtures, cut and flip bits of valid
blocks and feed garbage (also run under ASan and UBSan while writing them).

### Game loop
See `engine/runtime/include/fa/runtime/engine.h`. Fixed-step simulation
(default 60 Hz) + variable render. Headless `Engine::step(n)` advances exactly
`n` fixed frames — deterministic given seed + input.

Input has two views (`engine/platform/include/fa/platform/input.h`, "TWO VIEWS"): the frame's (UI, `onUpdate`,
`onLateUpdate`, timers, Back) and the fixed step's (`onFixedUpdate` and what a step dispatches). Holds are shared; an edge
(press, release, wheel, mouse motion, text, Back, paste) is kept for each view until it has been read: a frame closes
the first with `begin_frame()`, and every fixed step closes the second with `end_fixed_step()` (`Engine::run_frame` opens
an `Input::FixedScope` per step). So an edge is taken by one step whether the frame ran 0, 1 or 5, and one that
arrives in a frame with no step waits for the next. Every writer (`on_key`, `on_mouse_*`, `on_touch_*`, replays,
`game.input`) marks both views, so the recorder and replays need no change (`timing` still records `[dt, steps]`).
A paused engine only redraws and keeps the edges (`discard_idle_motion` drops wheel, motion and text, not presses). A new
system that runs inside a fixed step and reads input needs nothing: it answers for the step's view.

### Jobs and threads
See `engine/core/include/fa/core/jobs.h`. One process-wide pool of worker threads (`fa::jobs`) that engine code hands
pieces of work to: `submit(name, fn, deps)` returns a `Handle` to `wait` for, `Group` waits for several,
`parallel_for(name, count, grain, fn, seed)` splits `[0, count)` into chunks, `parallel_map_chunks` and
`parallel_reduce` merge per-chunk results, `post_main` hands a task back to the main thread (the engine runs those at
the start of the next frame). The Engine starts the pool in `init()` and stops it in `shutdown()`; the pool is
reference counted, so a second engine in the same process (the editor) shares it, with the first one's setting, and
the last `stop()` joins the workers. `start()` returns a `Result`: it is refused from a thread other than the one that
started the pool and from inside a job, so an `Engine::init` on another thread fails while the pool runs: create and
run every engine on the main thread. A second `Engine::init` of the same engine fails without touching the pool.

- **Owners**: each Engine has a `jobs::Owner`. The jobs and main-thread tasks queued while its `OwnerScope` is open
  (init, each frame, each scene load, each command call) or by one of its jobs belong to it. `Engine::shutdown` waits
  for its own jobs before its scripts and systems go away and drops its main-thread tasks still queued; a frame runs
  only its own engine's tasks (and the shared ones, posted with no owner), so the editor and a preview never run each
  other's results. `Owner::wait` (shutdown) runs only its owner's queued jobs and what they depend on. With several
  engines, the first one to end a frame closes the job statistics (`jobs.info`), until it closes or its engine stops
  drawing frames (8 frames of the others without one of its own hand them over).

- **How many threads**: `runtime.jobThreads` in factoria.json: `"auto"` (the default: hardware threads - 1, at most 8
  on desktop and 4 on phones), an integer 0..32, or `"inline"`, exactly (lowercase, the count not in quotes).
  `FA_JOB_THREADS` overrides it and `EngineConfig::jobThreads` overrides both; those two are text and accept any case,
  spaces around and the count as digits. With 0 workers a job runs on the main thread when something waits for it,
  or at the end of the frame. `"inline"` runs every job at once on the thread that submits it, in submission order: use
  it to debug a job with a plain call stack. Before the pool starts (tools, tests) jobs also run inline. The web build
  has no threads (compiled without `-pthread`): every setting gives 0 workers there.
- **Determinism (the rule every job follows)**: threads never change what the game computes. A job reads shared data
  and writes only its own slot; it never touches `world.rng()` or the World's entity list. Random numbers come from a
  seed drawn on the main thread and `Chunk::rng()` (a stream that depends only on the seed and the chunk index). Chunk
  bounds depend only on `count` and `grain`, and results are merged in chunk order, never in the order chunks finish.
  `game.state_hash` (one 64-bit hash of every entity, component, field, the clock and the random generator) is how a
  test checks it: the same game with 0, 1, N threads and inline gives the same hash every frame
  (engine/runtime/tests/jobs_engine_tests.cpp).
- **Waiting**: `wait()` on the main thread (or in a job) runs only what the job needs: the job itself and its
  dependencies (and theirs) while they are still queued; while those run on other threads it sleeps. It never picks up
  an unrelated job, and `parallel_for` runs only its own chunks on the calling thread (and never returns while one of
  its chunks still runs elsewhere), so a long background load never lands in the middle of the main thread's frame.
  With 0 workers a wait still ends (it runs what it needs itself). A wait that can never end returns an error instead
  of hanging: the job (or one it needs) is running on this thread under the wait, or on another thread that waits,
  directly or through more waits, for a job running on this thread.
  Only waits through `wait`, `Group`, `parallel_for` are seen: a job that blocks on its own mutex, condition variable or
  future can still hang. A job that throws is caught and logged with its name; `wait()` returns the error, and jobs
  that depend on it do not run and report it.
- **Logging from jobs**: `FA_LOG` and friends work on any thread. A log sink (`add_log_sink`) runs on the thread that
  logs, a worker too, and may still run once just after `remove_log_sink`: it locks what it writes and owns it (a
  `shared_ptr` captured by value), never a reference to a local.
- **Cost**: idle workers sleep on a condition variable (no CPU while nothing is queued). Each worker has its own queue
  of ready jobs: it runs the jobs it queues itself (and the first dependent a finished job releases) in order, and an
  idle worker steals the oldest job of another worker's queue; the main thread deals its jobs out to the workers in
  turn. A job costs one allocation and a short lock of one queue; the dependency graph's lock (`Pool::mu`) is taken by a
  job that has dependencies or dependents (or that a `wait` or a `parallel_for` join looked at), by a `submit` whose
  dependency is still running, by a wait that has to sleep (`wait`, `Owner::wait`, `parallel_for`'s join), by the end
  of an owner's last job when an `Owner::wait` sleeps for it, by a thread's first lane lookup after a start or stop,
  and by `start`, `stop` and `settings`; a job nobody looks at and a wait for a job still queued never take it. A wait
  for a job still queued runs it at once, and a wait that took a job drops its queue entry, so with 0 workers the
  entries do not pile up until the frame ends. A worker that is told a job is queued and finds none (the thread that
  took it has not counted it yet) looks again 64 times and then naps for about 200 microseconds (at least the timer resolution on Windows; a new job ends the nap at once). Give a parallel_for a grain of at least a few hundred cheap items. The design is described at the
  top of `engine/core/src/jobs.cpp`. Each worker thread is named (`fa-job-1`..)
  in debuggers and profilers; its stack is the platform default (512 KB on macOS and iOS, 1 MB on Windows, 8 MB on
  Linux): keep big buffers on the heap.
- **What it reports**: `jobs.info` (workers, mode, the setting and where it came from, jobs run and queued last frame,
  how busy each thread was, threads waiting now, this engine's unfinished jobs) and, with the profiler on, a `threads` section per thread in `perf.profile` and
  `play.report` (docs/PERFORMANCE.md) and the Threads tab of the editor's Profiler panel.
- **Physics, navigation and audio on jobs (M70.2b)**: the results are the same inline and with any number
  of workers (tests hash a whole simulation with `inline`/1/2/8 threads; `game.state_hash` is the check for a game). All of
  it is skipped when the work is small (a job costs a few microseconds), by a count of items, never by the clock, so
  which path runs is the same on every machine.
  - *2D physics* (`engine/physics/src/physics2d_tasks.cpp`): Box2D's task system (`enqueueTaskCallback`) runs on
    `fa::jobs`. A step is "wide" when it has at least 1536 awake bodies or 4096 contacts (`physics_job_thresholds()`,
    measured: below that the jobs cost more than they gain); only then its tasks (broad-phase pairs, contact update, constraint solver, finalize, sensors) are
    queued; any other step, a step outside the main thread and the `inline` mode run them on the calling thread. The world
    is always made with the fixed `B2JobTasks::kWorkers = 4`, so a task is cut into at most 4 pieces by item count and
    minimum range only, never by the pool's size: more than 4 threads are not used by 2D physics. A wide step cuts every task into
    the same pieces whatever runs them (a stopped pool, `inline`, no workers or a step off the main thread run the pieces one
    after the other on the calling thread, each with its own worker index), because what each worker finds is merged in
    worker order: Box2D picks the island to split next among the candidates of the workers, and when two have the same
    sleep time the winner depends on how the task was cut. A step below the thresholds is one piece, as before. So a world
    this big (1536 or more awake bodies or 4096 or more contacts) can settle differently than the engine did before M70
    when islands tie; smaller worlds are unchanged. Box2D merges what its
    pieces wrote in bit sets (OR), and its solver colours constraints so that no two pieces touch the same body, so the
    merge order is fixed by the data, not by who finishes first. Joints, the sleeping rules, the callbacks into scripts and
    the write-back to the components stay on the main thread.
  - *3D physics* (`physics3d.cpp`): the pair loops are sequential, because a contact changes the bodies the next
    pair sees, and each row of a pair loop asks the broad phase (`broadphase3d.h`, "3D broad phase" below) for its
    partners. Two read-only scans run as `parallel_for` jobs when they have 64 or more rows (`kMinParallelRows`, chunks of 16
    rows): the rigid-body contact test that builds the manifolds before the solver, and the contact-event pass. A chunk only
    reads positions and the tree and writes its own slots; the main thread then replays the slots in `(chunk, row, k)`
    order, which is the order of the sequential loop. The iterative solver, the time-of-impact islands, waking, sleeping, joints and
    character controllers stay sequential (the islands of a sub-step are still built on one thread, but from the tree).
  - *3D contact manifolds* (`physics3d.cpp`, `physics3d_shapes.cpp`): a rigid contact has up to `kMaxPts` = 4 points, each with a
    depth and a feature id. Two boxes that are not aligned go through `box_box_sat` (15 axes; a face axis wins over an edge axis unless the edge
    axis is clearly shallower, and a face of the first body over one of the second unless that one is clearly shallower, so a
    pair keeps its reference face from step to step); a face contact (`face_manifold`) clips the incident face against the side planes of
    the reference face and keeps the corners not more than `kManifoldGap` (3 mm) above the reference plane, and two crossing
    edges give one point. `reduce_manifold` merges points closer than 0.1 mm and keeps at most 4: the deepest, the
    one farthest from it and the two that span the largest triangles, with every comparison tolerant and falling back to the
    lowest index, so the choice depends on the geometry and not on float noise or thread order. A capsule lying flat (on a box,
    a mesh or another capsule) gets one point per end, a box on a mesh one per low corner. The id (`mix_id`, an FNV-style hash of
    the reference face, the incident face and the corner or edge crossing that made the point) is the same while the corner
    keeps touching, and the warm start gives each point the impulses its id carried in the previous sub-step (`WarmEntry`), or,
    for an id that is new, those of the nearest unmatched point within `kWarmRadius` (5 cm).
  - *3D contact solver, stacking* (`solve_manifold`, M94.4h): the contacts are SOFT, as in Box2D v3's soft step. Each
    sub-step (h = dt / 4) builds the contacts at the current poses (`held`), runs `kBiasIterations` (2) velocity passes
    whose normal constraint is a spring of `kContactHertz` (60 Hz; 2x against a static body) with damping ratio
    `kContactDamping` (10), pushing a penetration out at up to `kPushOut` (3 m/s) and letting a gap close exactly, then
    the sub-step's motion (turning the push-out speed into a position change, swept for impacts as before), then a relax
    pass (`iterate(held, true)`) with the same constraints and no push-out, which takes that speed out again, the simple
    pairs and the joints. A point's depth follows the bodies' motion since the build (its anchors live in each body's
    frame), so no position projection is needed for resting contacts. A soft contact sags under load by weight / stiffness
    (about 1.5 cm per joint at the bottom of a column of 100 boxes, 0.8% of its height), which is what lets a stack settle
    without bouncing. The points of one manifold are solved together (Jacobi: every point from the same velocities, applied
    at once) with each update scaled by 1 / the Gershgorin bound of the manifold's coupling matrix (`RigidContact::omega`),
    so the result does not depend on the order of the points: a column of boxes is an inverted pendulum (a lean grows by e
    every ~1.7 s), and the one-point-after-another order of a Gauss-Seidel pass leaned every stack to the side of its first
    corner. A time-of-impact stop (`resolve(false)`) still solves hard (the speeds only), and a sub-step that had impacts
    ends with the old position pass (`correct_position`, per point, at most `kMaxCorrection` = 0.2 m, two passes) because
    a body that spins fast can overlap at the end of a sub-step by what its last sweep missed. A rotating
    rigid body that presses (normal impulse) on another dynamic body and whose centre is slower than `kRestSpeed`
    (0.5 m/s) loses speed at `kRestDamping` (1/s), so a capsule rolling on a pile comes to rest. A body alone on the
    ground is not damped (a frictionless puck keeps its speed, a ball rolls down a gentle slope, a spin goes on): damping
    those too made the pit never sleep. Sleeping: a body is calm below `kSleepSpeed` (an
    arcade sphere, `rollWithMotion`, counts only its linear speed), an island sleeps when all its bodies were calm for
    `kTimeToSleep`, EXCEPT that in a big pile up to N / `kStragglers` (64) bodies may still creep, each slower than
    `kStragglerSpeed` (0.3 m/s), because a pile of a thousand spheres, capsules and boxes never stops completely. A
    world with nothing awake skips the sub-steps and the broad phase (a step costs the sync only, about 0.4 ms for the
    pit of 1000); a static or kinematic body that gameplay created or teleported in this step counts as awake for that
    check, because only the contact build wakes the sleeping bodies its new place touches. (`Body::Sig`, the "was this body edited" signature that wakes a body, compares the capsule's `segHalf`
    with a tolerance like the other sizes: its last bits wobble when a body turns a hair, and each wobble used to reset
    the sleep timer of every slowly rotating capsule.) Measured on the scale tests: the column of 100 sleeps after 240
    steps and the column of 50 after 140, neither leans (drift 0.000), and the walled pit of 1000 bodies is asleep after
    about 1600 steps (how long a pile creeps depends on the scene: 800 to 1600 steps measured).
    Sleeping bodies cost almost nothing while other bodies are awake (M94.4e). Before the sub-steps a classification
    pass lists the awake bodies, the moved static or kinematic ones, the platforms and the characters (`Rows`); every
    loop of the step (integration, the time-of-impact sweep, contact build, solver, settling, rolling, sleep checks,
    write-back) walks those lists and not all the bodies, and a pair loop walks the rows of the awake bodies, asking
    the tree for the partners (an awake body sees every partner except an awake one with a lower index, whose row finds
    the pair; the records are replayed sorted by (i, k), so the order of the Gauss-Seidel passes and of the warm-start
    lookups is that of a loop over every body). A pair of two bodies at rest (asleep or static) is not visited at all:
    its state moves from `touching_` to `frozen_` and comes back when a body wakes, is edited, or a body is created or
    destroyed. A sleeping body keeps a tight, still-margin box in the tree. In the solver's position pass a sleeping or
    static body below an awake one is an extra row only to find the awake dynamic bodies near it (a floor under a big
    sleeping pile does not return the pile). A sleeping pile an awake body touches takes part in the step as a unit
    (its sleep group wakes together, as before); a pile nothing awake is near is not an island mover.
    What differs from before (every other world gives the same bits; `kReferenceHash` and `determinism_expected.txt`
    did not change, none of their scenes has these cases):
    1. The position pass after a time-of-impact stop (`correct_position`, then the relax pass) now runs only for the
       bodies of the islands that had a stop in the sub-step. Before it ran for every body whenever any body had one,
       so a ball hitting a wall far away also re-solved the contacts of a box resting on the ground, and a resting
       pile was nudged. This changes any world that has two independent groups of bodies in contact and a stop in one
       of them, also when nothing sleeps (the test "a far time-of-impact stop does not move an awake box" pins it).
    2. Inside such an island, the pairs of a body with a static or sleeping body of a LOWER index are visited in
       global (lower index, higher index) order (`replay_sorted`); the old loop visited them with the row of the
       higher body, so the order of the passes differs for an island that touches a static body with a lower index.
    3. A sleeping body that `wake_touched` wakes is a row only from the next phase or sub-step, not in the same call.
    4. A force applied to a disabled body is dropped (and the force a body had when it was disabled is cleared) instead
       of waiting for it to be enabled.
    What is still O(number of bodies) per step is `sync`, which reads every body's components (pose, enabled state,
    shape signature) to see what gameplay edited: about 0.15 ms for 1000 bodies. Measured (Release, macOS, inline jobs):
    1000 asleep + 20 awake steps in 0.23 ms, 10 000 asleep + 20 awake in 1.7 ms (the sync), against 0.05 ms for the 20
    awake alone and 8.3 ms with 1000 asleep before (`physics.step3d_mostly_asleep`).
  - *3D broad phase* (`broadphase3d.h`): the 3D solver keeps a dynamic AABB tree with one leaf per enabled collider with a
    shape (created, removed and renumbered after every `sync`). A leaf holds a FAT box: the collider's bounds plus a margin
    (0.1 m when it moves, 0.02 m at rest) and, for a body in motion, its velocity over two steps; the leaf stays where it is
    while the boxes a phase asks about fit inside it. Before each phase that looks for pairs (the time-of-impact sweep,
    the contact test, the position pass of the solver, the contact events and the wake-up check) the solver makes
    every fat box contain the box that phase asks about (`cover`: for the sweep the bounds of the whole move, a turning
    body as its bounding sphere; elsewhere the body's bounds), and the position pass also puts a body back in the tree the
    moment a contact pushes it out of its box. A row of a pair loop then asks the tree for the bodies whose fat box overlaps
    its own box grown by the phase's reach (0 for contacts, the 0.05 m end margin for events, `kRiderGap` for waking) and
    takes the answer sorted by index. A body the tree does not return is further than the reach, so the narrow phase would
    have said no: the partners and the order are those of the old all-pairs loop, whatever the shape of the tree, the
    order bodies were added in or the number of threads, and the simulation result did not change. Pairs that keep their
    state because both bodies are asleep or static are not geometry: they stay in `frozen_` (see Sleeping) until a
    body wakes. Besides the pair loops, the tree answers which bodies are near
    a platform (the riders it carries) and which movers are close enough to share a time-of-impact island; a mover whose
    reach is over 2 m, or whose centre is outside its box, is tried against every mover instead, and a platform finds the
    characters it carries among the few that can be carried.
    The scene queries use it too (M94.4c2): `raycast3d`, `raycast3d_all`, `shape_cast3d`, `overlap_sphere3d`, `is_touching`
    and the character controller's sweeps and depenetration no longer walk every body. A ray goes down the tree with a slab
    test against each fat box (the nearer child first, the ray clipped to the best hit so far, so a subtree beyond it is
    skipped); the other queries take the bodies whose fat box overlaps the query's box (the swept bounds of a shape cast or
    of a character's move, the sphere's box) sorted by index, and run the old per-body tests on them. Equal distances keep
    the old order (`raycast`: the highest body index wins, as the last one of the old loop; `raycast_all`: distance, then
    index; `overlap_sphere`: index order), so the answers are the same bits whatever the tree looks like. The queries run
    between steps, called by scripts and commands after `Physics::sync`, so the tree has to be complete by then: `sync`
    itself creates the leaves of new bodies, renumbers the payloads and covers the box of every body it marked stale
    (teleported, resized, enabled), a character move covers the capsule where it ended, and the end of each step covers every
    body that can have moved since its last cover (position corrections and joints run after the last phase). A sleeping body
    keeps a box at least as big as its bounds (the fat box shrinks to the bounds plus 0.02 m, never below them), triggers
    have leaves like any collider (the options filter them), a disabled body has none and is not a candidate. The queries only
    read the tree and the bodies, like before (they are called from the thread that steps the world, never during a step).
    Measured (Release, macOS, 15 runs): `physics.raycast3d_1000` (10 000 rays in a settled pile of 1000 bodies)
    318 ms before, 13.4 ms after; `physics.overlap3d_1000` (2000 spheres) 21.8 ms before, 3.9 ms after.
  - *3D heightfield* (`heightfield3d.h`, `physics3d_heightfield.cpp`, M94.4f): `Collider3D.shape = heightfield` with a
    `Heightfield3D` on the same entity (rows x columns samples, `cellSize`, `heightScale`/`heightOffset`, `heights` and
    optional `holes` as typed arrays, `fa/core/typed_array.h`; plain arrays in scene files) is one static body of kind
    `Heightfield`. Model space has the grid centred on the entity origin: sample (r, c) is at x = x0 + c dx, z = z0 + r dz,
    y = raw * heightScale + heightOffset, and cell (r, c) is the triangles (r,c) (r+1,c) (r+1,c+1) and (r,c) (r+1,c+1) (r,c+1),
    both facing up; a hole cell has neither. The body keeps its own scaled copy of the heights, so the solver and the
    queries never read the component that gameplay writes, and 16 x 16-cell blocks keep the lowest and highest sample (the
    field's bounds come from them). `update_heightfield` brings the copy in line: if the arrays have the id and version it
    built from it costs two integer compares; otherwise it asks each array `dirty_since(version it built from)` (the array keeps the last 8 writes; more than that, or
    a copy of another array, means "compare everything"), copies only the samples whose value differs, recomputes the
    blocks they touch and reports the edited cells and the heights they span (old and new). A changed size, spacing,
    scale or array object rebuilds all of it (the first sync of a field and every full rebuild read all N samples).
    Nothing is acknowledged or consumed: the copy remembers the version it took, so any other reader of the arrays (a
    renderer, a nav cache) keeps its own last-seen version and never hides an edit from physics, or the other way round.
    The collider's bounds are the field's, extended `kHeightfieldSolidDepth` (8 m) below its lowest sample so the ground is
    solid there (`boxStale` only when the lowest or highest sample moved, so the tree leaf is kept for most edits), and the `Sig` of the
    body leaves out the height of the box, so an edit does not wake the contacts of the whole field. After the tree is
    updated, `wake_near_edit` turns the edited cells and heights (+0.1 m) into a world box, asks the tree for the bodies
    whose box overlaps it and wakes the sleeping ones that really do; contacts elsewhere keep their state. Contacts
    (`heightfield_contact`, called by `collide_general` like a mesh): the other shape's bounds, in model space, pick the
    cells (blocks and cells whose height range misses the bounds are skipped); each triangle is tested with GJK and the
    deepest result wins. A face contact is kept; a contact on an edge or
    corner counts only when its normal lies in the cone of the normals of the triangles that share it (an open border or a
    hole beside it always counts), so a shape sliding over a seam of a flat or planar field sees only the face normal and
    cannot bump. A shape that sank below a triangle with its closest point inside it is pushed up (solid ground). A body
    wholly below the lowest sample of the cell under its centre touches none of the cells above (they are skipped as
    out of range), so when nothing else hit, the rule is: the centre is inside the grid's x and z extent, the cell under it
    is not a hole, and the body's lowest bound is at most `kHeightfieldSolidDepth` (8 m, world units) below the surface at
    the centre; then the contact is the triangle over the centre's own (normal = its up, depth = how far the body's deepest
    point is under its plane). A body under a hole cell, outside the extent or deeper keeps falling: that is how a body that
    fell through a hole is told from one the terrain rose over (one that fell and then slid sideways under solid cells within
    8 m of the surface is pushed back up too). Boxes and
    hulls get one point per low corner, probed onto the field with `ray_heightfield` (up to four points, feature ids
    like the mesh manifolds). `ray_heightfield` walks the cells along the ray (Amanatides-Woo, bounded by rows + cols + 8
    steps, testing the triangles of a cell only when the ray's height inside the cell overlaps the cell's samples) so its
    cost follows the ray's length and not the grid; `ray_body`, `shape_cast3d` (which uses `collide`), `overlap_sphere3d` and `move_character` use
    these through the tree, where the field is one leaf. The NavMesh bake treats a field like a ground plate (one ray down per
    column) and its signature includes the field's `revision`. A grid that cannot be used (the messages are in
    `update_heightfield`; rows or columns outside 2..4096; a heightfield on a dynamic or kinematic body; no `Heightfield3D`)
    is a problem like a mesh on a moving body: logged once, listed in `Physics::problems3d()`, no collider. Determinism: the
    block order, the cell order and the triangle order are fixed, and nothing depends on the thread count (the hash with
    0, 1, 2 and 8 job threads is tested). Measured (Release, macOS): `physics.heightfield_step` (200 bodies on 256 x 256
    samples, 20 steps) 19.3 ms, `physics.heightfield_edit` (40 one-sample edits, 100 bodies asleep) 3.8 ms; one edit and
    `sync` in a 1025 x 1025 field: about 0.003 ms.
  - *Navigation*: `nav.find_paths` and `nav.find_tile_paths` (and the script calls) answer many queries at once. With 8 or
    more queries (`kNavBatchMinQueries`) they run as `parallel_for` with 4 queries per chunk; each chunk owns a
    `NavGrid::Scratch` (its open list and visited marks; a search never writes the grid), writes only its own slots of the
    result, so the answer list is in request order. The NavMesh is picked per query on the main thread first, so every
    error (with its query number and JSON pointer) comes before any search starts. At most 10000 queries per call.
    Single `nav.find_path` calls stay on the calling thread.
  - *Audio*: `render_sfx` renders each layer of a patch as a job when the patch has at least 2 layers and at least 24000
    samples (`kSfxJobMinSamples`; about half a second at 48 kHz) and the layer buffers fit in 64 MB; the layers are
    summed in layer order afterwards, so the samples are identical. A noise oscillator draws from a stream keyed by
    `(seed, layer, oscillator)` rather than `Chunk::rng()`, so the sound does not change with how layers are grouped.
    The device callback never waits for a job and starts none; the mixer of live voices and `song_preview` stay on their
    own thread.
  - What this does not promise: the same results are checked on one machine across thread settings. Floating point can
    still differ in the last digit between CPU architectures, as it did before jobs.

#### Systems that run as jobs

The per-frame work of these systems is split over the pool with the helpers of `engine/render/src/render_jobs.h`
(`rjobs::split`, `rjobs::run`, `rjobs::stable_sort`) or `jobs::parallel_for` / `jobs::weighted_ranges` (`fa/core/jobs.h`, shared
with the particle step of `fa_scene`). Each pass
below its threshold, and every pass while the pool has no worker thread (stopped, `"inline"`, 0 workers), is one chunk
on the calling thread: the reference path. The thresholds are counts of items, never times, so where the line falls
does not depend on the machine:

| Job name | What a chunk does | Runs as jobs from | Chunk |
| --- | --- | --- | --- |
| `render.gather_sprites` | the quads of its sprites (matrix, anchor, 9-slice, grid meshes, skinned meshes, flash, parallax repeat) | 512 sprites | 128 sprites |
| `render.gather_tilemap` | the visible cells of a band of rows of one Tilemap | 16384 visible cells | ~4096 cells |
| `scene.particles` | steps its emitters (each `ParticleSim` owns its particles and its Rng) | 2048 particles | emitters of ~1024 particles |
| `render.gather_particles` | the quads of its emitters (particles, trails) | 2048 particles | emitters of ~1024 particles |
| `render.sort_quads`, `render.flatten_quads` | stable sort of the 2D items; copy of their vertices into the stream | 4096 items; 16384 vertices | 1024 items; 8192 vertices |
| `render.mesh_matrices`, `render.mesh_cull` | a mesh's matrix, flash and distance; its bounds (skinned too), frustum test and blend flag | 256 meshes | 64 meshes |
| `render.sort_blended`, `render.sort_meshes` | stable sorts of the blended meshes (back to front) and of the batches (by material) | 1024 items | 256 items |
| `render.shadow_bounds`, `render.shadow_cull` | the shadow casters' bounds; the test against the light's volume | 256 casters | 64 casters |
| `scene.animation_poses` | every clip channel sampled, the fade blended, the skinning palettes of its animators | 512 skeleton nodes | 2 animators |

What stays on the main thread: everything that may load or create a GPU resource (`Assets::texture`, `mesh`,
`material`, fonts), the animator sheets, the camera tag mask cache, the warnings that fire once, the statistics, and
every sokol_gfx call (the passes build CPU data; the submission comes after them, on the main thread).

The determinism rule, on top of the one for every job: chunk bounds depend only on item counts (and, for particles, on
particle counts), each chunk writes its own `QuadList` or its own slot of a vector, and the parts are joined in chunk
order (`QuadList::append` renumbers the items so their order is kept; `add_quads_of` joins the bands of one tilemap
item). A stable sort has exactly one result, so the chunked sort (each chunk sorted, then pairwise `std::merge`) gives
the order of `std::stable_sort`, as long as the comparison is a strict weak order: every float a render sort compares
goes through `rjobs::order_float` (NaN, from a NaN transform or colour, sorts as +infinity). The 3D batches are
ordered by asset names and entities, never by addresses, which differ from one process to the next. The frame is
therefore byte-identical with any thread count. engine/render/tests/render_jobs_tests.cpp draws scenes far above every
threshold (3000 sprites, a 400x200 tilemap, more than 2048 live particles, 820 meshes with shadows and skinned rigs;
5000 sprites and 2400 meshes with NaN positions and colours) stopped, inline and with 1, 2 and 8 workers, compares
the pictures and the statistics, and checks on the profiler that each pass was cut into the same chunks with every
worker count (which thread ran a chunk depends on timing, so the test only reports it).
engine/scene/tests/test_animation.cpp does the same for 300 animators, and the ctest `example_jobs_same_frames`
compares example scenes drawn by two processes with `FA_JOB_THREADS=inline` and `8`.

### Background loading
`scene.preload`, `assets.preload` and `scene.load {async: true}` (docs/PERFORMANCE.md, "Background loading") read and decode
files while frames run. The pieces and who owns what:

- **`fa::IoQueue`** (`core/background_io.h`): each Engine owns one, made with its `jobs::Owner` and its `LoadTrace` owner. One
  **IO thread for the whole process** serves every queue in turn (round robin, one file at a time), so two engines that load
  at once both move on and never see each other's items. It starts with the first item of a threaded queue (the pool has at
  least one worker) and ends with the last queue; a game that never loads in the background has no IO thread. An item is a
  READ (on the IO thread, through `fa::fs`) then a DECODE (a job of the queue's owner). Its result waits until the main
  thread `take()`s it; `take()` of an item the IO thread has not started does it at once on the calling thread, so it never
  waits behind other files and never deadlocks, also with 0 workers. Without workers there is no IO thread and `take()`
  does the read and the decode itself: the result is the same either way.
- **`fa::BackgroundLoader`** (`runtime/src/background_loader.h`, main thread only): the jobs of one Engine. A job's first
  item (the SCAN) reads the scene and the text files it names into `fs`'s warm set and lists the binary files; then one item
  per binary file: the renderer decodes a texture, model or font off the main thread (`Renderer::background_*`) and the
  main thread uploads it; audio decodes a sound (`Audio::decode_clip`) and the main thread adopts it. `tick()` runs once per
  frame, before the scripts' platform callbacks, and takes items in a fixed order (round after round, one item of each job
  in start order) within the frame's budget: exactly N items (tests, headless runs, the editor, replays: the same frames on
  any machine and any pool), or the items that are ready within `loadBudgetMs`/`uploadBudgetMB` (a game with a window: a
  prefix of the same order, whose length a recording keeps as `"loadUnits"`). An async scene load whose files are ready
  becomes the frame's pending scene change (`apply_scene_change` at the end of the frame); a scene change asked meanwhile
  cancels it.
- **Lifetime**: a cancelled job's queued items become orphans the loader frees once the IO thread let go of them; a decode
  still running finishes on its worker and is dropped. `Engine::shutdown` stops the loader (`cancel_all`: the IO thread lets
  go of this engine's files), then waits for its jobs owner (the decodes still running), then destroys the loader; nothing
  of a load outlives its engine.
- **The warm set is the process's** (`fs::warm`, keyed by path), and the loaders of every engine count their references
  to each file in one registry (`background_loader.cpp`): a reference per item that read the file (taken before it is
  warmed), then one per job or finished load that holds it. `fs::unwarm` runs when the last reference goes, so two engines
  that load the same file share one copy and one engine's cancel, finish or `background_loads_reset` (a script test file
  starting afresh) never drops a file the other read ahead.
- **Script loads die with their context**: `ScriptHost::drop_script_background_loads` (called with `drop_script_jobs` when
  the JavaScript context is created or closed) cancels the loads a script started, an async scene load's pending switch
  included, and drops their updates, so none reaches a handle that is gone. A cancel in the frame a load's files became
  ready still stops its switch: the pending scene change keeps the load's id.
- **Load trace**: reads run in `LoadTrace::ReadingFor(owner, tag)`, which counts them in the totals and the async load's
  entry but enters a file into the first-use order only at `LoadTrace::file_used` (a warm file read through `fs`, or the
  renderer and audio adopting a prepared asset on first use), so an async load records what a sync load records.

### Coordinates & units
Right-handed, +Y up, angles in degrees, colors 0..1. 2D world units = design
pixels (a default 2D camera shows exactly the design resolution, origin at the
center). Screen-space UI: design pixels, origin top-left, +Y down. 3D units =
meters. Details in `core/math.h` and `scene/components.h`.

### Rendering
sokol_gfx backends: D3D11 (Windows), Metal (macOS/iOS), GL 4.3 core (Linux),
GLES3 (Android). The game always renders into an offscreen target at design
resolution; `present()` letterboxes it to the window. Screenshots read that
target, so headless and windowed images match. `Camera.bloom` is a post-process
that adds its glow INTO that same target (`engine/render/src/bloom.cpp`,
`shaders/bloom.glsl`), so screenshots include it. The target is RGBA16F (`Gpu::scene_format()`) when the GPU renders to
it with blending, filtering and the requested MSAA, else RGBA8 (`FA_SCENE_FORMAT=rgba8` forces the fallback;
`Renderer::hdr_scene()` says which; when the GPU lists RGBA16F but `Impl::create_targets`, the first time it makes the targets,
finds the game target's images or views not VALID, as GLES3/WebGL2 with MSAA and no `EXT_color_buffer_float` can, and the
same size works in RGBA8, the format becomes RGBA8, `Gpu::drop_pipelines()` drops the cached pipelines and the game is drawn
in RGBA8, on every backend. A later resize or render scale that fails never changes the format. Only the game target falls
back: a CameraView, a bloom level or the colour filter image that cannot be made keeps the format and its own warning, so
`hdr_scene()` can stay true with one of them invalid. `FA_SCENE_FORMAT=rgba16f_invalid` forces the fall-back in tests): a float target keeps a colour above white (`MeshRenderer.emissive` times
`emissiveStrength`), and the bright pass hands bloom that excess, so it glows more. The screen, screenshots and video stay
8-bit: `Impl::read_rgba8` copies a float target into an RGBA8 image (the `blit_keep` program, which keeps alpha) before
reading it, and the colour filter clamps its input for every mode but `none`. With `Camera.bloomScreenSpace = false`
the frame is split: world pass, bloom, then a second pass that draws the screen-space
groups (HUD) on top; with MSAA the glow is added to the multisampled image and the
HUD pass loads it again, so the HUD is multisampled too. `Camera.colorFilter` is the last post-process
(`Renderer::Impl::apply_color_filter`, `shaders/colorfilter.glsl`): a pass cannot read what it writes, so the filter
draws the finished target into a second image of the same size, and `present()`, `capture()` (screenshots, video) and
the editor viewport read that image while a filter is on; `none` skips the pass and the image. The colour-blind
CHECK (`simulate` of `game.screenshot`) is separate: `simulate_color_vision()` in `fa/core/image.h` on the captured
pixels. `game.screenshot` (whole view, `region` + `zoom` via `Engine::capture_region`, filmstrip), `render.inspect` and `render.pick` are in
`runtime/src/shot_commands.cpp`; pixel work (crop, contact sheet, line profile) is `fa/core/image_tools.h`, and which files a screenshot
may leave behind (temporary ones, pruning) is `fa/core/screenshot_files.h`. Shaders are GLSL annotated for
`sokol-shdc`; generated headers are committed (`tools/shaders/compile_shaders.sh`). Every mesh program (`mesh`,
`mesh_skin`, `shadow`, `shadow_skin`) comes from one template, `shaders/mesh_common.glsl`: a top file defines the
`@block fa_user` (a `surface()` snippet, plus `vertex()` with `FA_HAS_VERTEX`), `@include`s the template and declares
the programs. `mesh.glsl` is that top file with an empty `surface()`; a custom material is the same with its own
snippet, so the engine and the materials share one source of truth (an empty `surface()` renders pixel-identical to a
`MeshRenderer` without a material). Engine identifiers in the template start with `fa_`; `fa_time` (vertex and
fragment) is `World::time()`, the engine clock. The template is embedded in `fa_tooling`.

**Cameras and viewports.** Every active `Camera` with `primary` draws, in ascending `depth`, into its `Camera.viewport`
(normalized `[x, y, w, h]` of the target, top-left origin, at most 8 cameras; the loader and `camera_viewport_problem` in
`scene/components.h` reject a bad rectangle). One camera over the whole target is ONE job, world and screen space together, exactly
the path there was before. Otherwise `Renderer::render` makes one world job per camera (own viewport and scissor, own culling, own
2D and 3D lights, own clear of its rectangle) and one more job for the screen-space groups, drawn once over the whole target after
them. The 2D light buffer is built per camera job, from the lights that reach that camera. Bloom, `bloomScreenSpace` and
`colorFilter` run once, on the finished target, with the lowest-`depth` camera's settings. `RenderStats` is per frame and adds up
over the cameras. `world_to_screen`, `screen_to_world` and `screen_ray` take an optional camera; without one they use
`camera_at(point)` (the camera whose viewport contains the point, else the first drawn), and `cameras()` lists those drawn. The
audio listener without an `AudioListener` is the first camera drawn. Known limit: a screen-space visual with `lit: true` is lit
by the scene's ambient light only when the frame has several cameras (the screen job gathers no `Light2D`). The editor viewport
shows the whole frame: its picking uses the camera under the pointer, but its outlines and gizmos project through the first
camera drawn, so in a split frame they line up with the first view only.

**Cameras inside the UI.** A `CameraView` (a UiBox widget) names a Camera. The UI gather (`draw_camera_view` in `ui2d.cpp`)
asks the renderer for an image of the widget's size (`Frame::viewImage`; `Impl::viewTargets` caches one per widget, same formats
and sample count as the game target so the pipelines fit, freed at the end of a frame that did not ask for it) and registers a
`ViewRequest`; the widget's quad samples that image at `layer + 1`, so clipping, layers, the modal Panel and the mirroring are the
UI's own. `Renderer::render` gathers one extra world frame per request (`build_camera` with the widget's size: the viewport
forced to the whole image, always cleared, no screen space, no post effects, no debug draw, no 2D light buffer) and draws those
jobs before the frame's own (`draw_view_job` swaps the target members of `Impl` for the image's). `Camera.lighting = studio`
replaces the scene's directional/point lights, ambient, sky and fog on the CPU, in `draw_job`, with a camera-relative key, fill and
rim, so it needs no shader change. `Camera.viewportSpace = design` converts the viewport fractions of the design area to the
target's in `build_camera`. The pointer side is `fa_ui` (`view.cpp`): the topmost widget under the pointer (`ui_widget_at`)
decides, and the game event `ui.viewPointer` goes out like the other ui.* events.

**Custom materials** ([guide for game makers](SHADERS.md), [design](design/CUSTOM_SHADERS.md)):

- *Template and hook points.* `mesh_common.glsl` defines the contract structs (`SurfaceInput`, `Surface`, `VertexData`)
  and calls `vertex(v)` (with `FA_HAS_VERTEX`) inside `fa_shade_vertex`, after the instance and skin matrices, and
  `surface(i, s)` in the fragment `main` after `fa_standard_surface`, before lighting. `FA_ALPHA_CLIP` makes the
  fragment `discard` below `alphaCutoff` and makes `shadow_fs` run `surface()` too. Uniform bindings: vertex 0 params,
  3 skin, 4 the material's vertex-stage block; fragment 1 params, 2 lights, 5 the material block; material textures use
  views 6-9 and samplers 2-5.
- *Generator* (`tools/common/src/shaders_generate.cpp`). `generate_material_shader` writes the sokol-shdc top file: the
  params as one alphabetical block (each padded to a `vec4`), the textures, the snippet verbatim with a line table, then
  `@include mesh_common.glsl` and the programs (`mesh`, `mesh_skin`, plus `shadow`, `shadow_skin` with `vertex()` or
  `"clip"`). `shaders_compile.cpp` runs sokol-shdc through the injectable `SetupContext::run`, maps its errors back to
  the snippet's lines and adds hints, and reads the YAML reflection (`shaders_yaml.cpp`).
- *Twins and cache.* Each dialect becomes a `factoria.shader/1` JSON document, the *twin*
  `<material>.json.<slang>.shader` (cross-compiled source per program plus binding reflection, stamped with the engine
  version and the template hash). The cache `.factoria/shader-cache/<sha256>.<slang>.shader` is keyed by the generated
  top file, the snippet, the template, the dialect and the sokol-shdc pin, so an unchanged material starts no process.
- *Runtime flow.* `Assets` keeps a `MaterialAsset` per `.material.json` (`render/src/custom_shader.cpp`): the twin comes
  from `fa::fs` (an exported game) or from `EngineConfig::shaderCompiler` (the CLI and editor inject
  `make_engine_shader_compiler`, because `fa_runtime` may not depend on `fa_tooling`; host dialect only), and becomes
  `sg_shader`s. Pipelines are keyed by shader; the batch key holds the material and a hash of the entity's
  `materialParams`, so equal overrides batch together. A failed build draws the unlit magenta error material and is
  listed in `RenderStats::materialFallbacks` and `asset_report`.
- *Hot reload.* `Engine::poll_hot_reload` sees a changed `.material.json` or snippet, `Assets::reload` rebuilds the
  material in place; a failed rebuild keeps the previous programs and logs once.
- *Exports.* `convert_shaders` (`tools/common/src/export_shaders.cpp`) runs in `prepare_game_assets`: it compiles the
  platform's dialects (Windows `hlsl5`, Linux `glsl430`, macOS `metal_macos`, iOS `metal_ios` + `metal_sim`, Android and
  web `glsl300es`), adds the twins, drops the snippets, and fails the export on a compile error. The player has no
  compiler. `factoria validate` compiles every dialect of every material.

### Start-up order and the shader cache
A window host (`run_windowed` in `runtime/src/runners.cpp`: the player and a windowed `factoria run`) starts in this order, decided by
`StartupSequence` (`runtime/startup_sequence.h`, one `on_frame()` per window frame):

1. *Frame 1.* The window and the graphics context exist (sokol_app opens them before the first frame callback). The frame
   presents a clear frame: `Renderer::present_clear`, black = the letterbox colour. `StartupTimeline` records `WindowReady` and
   `FirstPresent`. sokol_app presents when the callback returns, so this cannot happen inside the init callback: the first
   frame has to be a frame of its own.
2. *Frame 2.* `Engine::init` reads the game (scenes, scripts, textures, shaders). It adopts the context frame 1 opened
   (`EngineConfig::adoptGraphicsContext` -> `RendererDesc::adoptContext`: the renderer does not call `sg_setup` again, does
   not `sg_shutdown` it, and the runner calls `Renderer::close_context` at the end). A clear frame is presented again.
3. *Frames 3+.* `Engine::warm_step` -> `Renderer::warm_step` makes pipelines in groups (blit; the 2D quad pipelines; the blend
   variants; the 3D mesh, sky, skinned and shadow ones when a `MeshRenderer` exists), as many groups per window frame as fit in
   about 8 ms of wall time (at least one; the time only decides how many frames the warm-up takes, never what it makes: on GL,
   GLES and WebGL a pipeline links in the driver and costs milliseconds, on Metal microseconds), each frame presenting a clear
   frame. The groups are fixed lists, not a scan of what the scene draws, so the warm-up also makes pipelines a game may
   never use (Additive and Multiply sprites, the wire/lines variant, the mesh variants of a scene with one mesh). That is
   cheap: a pipeline is a small state object (a few KB) made once, the driver's own cache makes a repeat cheap, and the
   group is skipped for 3D when the scene has no `MeshRenderer`. A frame that draws before the warm-up finished makes a missing pipeline
   when it needs it, exactly as without the warm-up: pipelines are keyed through `Gpu::find_or_make`, so what is drawn never
   depends on the warm-up, and `state_hash`, recordings, replays and goldens are the same.
4. *Then* one game frame per window frame; the first one clamps its `dt` to 1/60 s (the start took longer than the 100 ms the
   frame-time filter allows).

A host without a window (headless, `perf.measure`, tests) runs none of this: `Engine::init` makes its own context and no
frame is presented (`firstPresentMs` is `null`). The timeline is recorded in `Engine::startup_timeline()`; the editor sets
`adoptGraphicsContext = false` (its context is its own).

**The shader cache** (`render/src/shader_cache.cpp`, `core/blob_cache.h`). `sokol-shdc` writes shader SOURCE (HLSL, MSL,
GLSL) into the committed headers, not compiled code, and sokol_gfx accepts a compiled program only on Direct3D 11
(`sg_shader_function.bytecode`). So only D3D11 has an engine cache: `make_shader` compiles each stage with `D3DCompile`
(`d3dcompiler_47.dll` loaded with `LoadLibrary`), stores the DXBC and hands sokol the bytecode next time. The key is
`d3d11|<engine version>|<flags>|src:<sha-256 of the source>` (DXBC is the same on every driver and card; the driver compiles
it to machine code), the files are `<cache_dir>/shaders/shader-<program>-<hash>-<stage>-<keyhash>.facache`, where `keyhash` is the first 8 hex characters of the hash of the whole key, so two engine versions or two games with a material of the same path keep separate files (the folder grows by one small file per shader per version; deleting it is safe). GL, GLES and Metal link or build from
source inside the driver or the OS, which keep their own caches; web has no folder. `BlobCache` is generic: magic `FABC`,
format version, key, payload size, SHA-256, payload; an unreadable file is reported as `Stale` (other key) or `Damaged`
(other magic or version, short, too big, bad checksum), logged once under category `cache`, ignored and rebuilt. A store goes
to a temporary file that `fs::replace_file` renames over the target. The folder is `fs::cache_dir()`, per user and never the game
folder (`FA_CACHE_DIR` overrides; the Android and iOS players call `fs::set_cache_dir`; empty means no cache). The renderer
creates all its programs through `make_shader`, which times them: `Renderer::startup_report` gives the counters.

### Textures
An export replaces a texture `x.png` by its twin `x.png.ktx2` (Basis Universal, written by `fa_tooling`'s
`export_textures.cpp`) and packs atlas groups into `assets/atlases/*.png`, recording each packed texture's rectangle
as `packed` in the shipped `assets.json`. The renderer (`render/src/ktx2.cpp`, `assets.cpp`) loads the twin in place of
the name scenes and scripts use, transcodes it to the best format `sg_query_pixelformat` reports (ASTC, BC7, ETC2,
else RGBA8; `FA_TEXTURE_FORMAT` forces one), and a packed texture borrows the atlas image with a sub-rectangle
(`TextureAsset::uv`). Only the Basis *transcoder* is in the runtime (`fa_render`, outputs the game never uses are
compiled out); the encoder is in `fa_tooling`. `core/image.h` (`texture_size`) is the one place that answers "how big is
this picture" whatever form it ships in.

### Bounds
Where a 2D entity is and how big it is has ONE definition, `fa/scene/bounds.h` (`visual_footprints`, `entity_world_rect`): Tilemap, Sprite,
Shape2D and Text from size, pivot and the world matrix. `entity.bounds()` in scripts and the editor's picking and selection outline
both call it, so what a script measures is what the editor outlines. File sizes and font layout are injected (`VisualMeasure`).

Text has ONE layout too: `Fonts::layout` (`render/src/fonts.cpp`) draws screen and world `Text`, UI labels and debug text, and
`Renderer::measure_text` returns its size. `text_shaper.cpp` is the GPU-free part (font chain per character, HarfBuzz shaping,
SheenBidi reordering, line breaking), so tests can look at glyph ids and positions; `fa/render/fonts.h` is its coverage check
for tools. Fallback fonts and the text size option live on the `Renderer` (`set_fallback_fonts`, `set_text_scale`). Details for
game makers: [TEXT.md](TEXT.md).

### Animation
Skeletal animation is GPU-free and lives in `fa_scene`, so simulation and tests never need a renderer:
- `skeleton.h` (`load_skeleton`, cached per path + modification time) reads a glTF with cgltf through `fa::fs`: the node
  hierarchy with rest poses, skins (joints, inverse bind matrices), animation clips (translation / rotation / scale channels;
  LINEAR, STEP, CUBICSPLINE) and the `JOINTS_0` / `WEIGHTS_0` of skinned primitives (`SkinVertices`, matched to the renderer's
  loader by node and primitive index). The renderer loader ignores the transform of a skinned node (glTF spec) and keeps
  each skinned part's joints/weights in vertex buffer 2 (`SubMesh::skinVb`, `SkinVertex`, at most `kMaxSkinJoints` = 64).
- `animation.h` samples clips into a `Pose`, blends poses and builds the skinning palette. `update_animators(world, dt)` runs
  every `Animator`: state machine, clip time, cross-fade, clip events (pushed to `world.events().game`), then the palette.
- **When it runs:** the runtime calls it once per FIXED step, after `physics.step` and before `scripts.dispatch_events`, with
  `fixedDt * time.scale` (not at all while the scale is 0). Events therefore reach `world.on` in the step that produced them and
  headless runs are deterministic. The variable-rate render step never advances animation.
- **What the renderer reads:** `Animator::skinPalettes` (components.h), a runtime-only vector with one palette per skin (`palette` is skin 0; the importer adds "rigid" skins for meshes that follow animated nodes), one matrix per joint,
  `jointGlobal * inverseBind` in the glTF's model space (vertices of a skinned mesh are not transformed by their node). The renderer
  (`renderer.cpp`) packs it into the `fa_skin` uniform (64 joints x 3 rows of a 3x4 matrix) and draws with the
  skinned programs of the mesh template (`mesh_skin`, `shadow_skin`: only the vertex stage differs, the lighting code is
  shared). Skinned items carry the Animator pointer in their material key so they never join an instanced batch, and their
  culling box is `skinned_bounds` (the bind box carried by every joint, joined).
- The tween module (`tween`, `ease`) is JavaScript (`factoria.js`), advanced by the script system's update with the scaled `dt`,
  so it shares the game clock with timers.
- **Sprite animators and particles are simulation too.** `update_sprite_animators(world, dt)` (`fa/scene/sprite_animator.h`) advances
  every `SpriteAnimator` (frame, `clipEnded`, frame events, `Sprite.region`) and `World::particles().update(world, dt)`
  (`fa/scene/particle_store.h`) steps every `ParticleEmitter`, runs its `autoDestroy` and spawns the bursts queued by
  `emitBurst`. Both run in the fixed step right after `update_vfx`, with `fixedDt * time.scale`, and again with `dt` 0 before a
  picture is drawn (`Engine::Impl::settle_visuals`: a clip a script changed this frame, or a burst, shows in this frame's
  picture and never advances time). A `SpriteAnimator` reads the size of its sheet from the image file or the packed atlas
  (`texture_size`, cached by file name and looked at again once per frame: the end of the `dt` 0 pass starts the next epoch, so the
  steps of a frame and its settle pass look at a file once. On a platform whose files have no modification time,
  like an Android APK asset, each picture is read once), never from a GPU texture, so a run with `graphics=false` and one that draws
  give the same `Sprite.region`; the renderer only repeats the region for a texture that exists on the GPU alone
  (`runtime:`, `target:`). The particle state is a `ParticleStore` owned by the `World` and keyed by entity: two worlds (the
  editor's scene and its Play session) never share it, and `World::clear()` and every scene load empty it. The renderer
  (`renderer.h`) keeps only camera and parallax in `Renderer::update`; `render_world` draws what the world holds.
- **Text and cameras without a renderer (M91.1b).** Nothing the simulation reads depends on a GPU. Text is shaped and measured by
  `FontSet` (render/src/font_set.h: fonts, the fallback chain, HarfBuzz shaping, wrapping, rich text, `textScale`/`uiScale`,
  `maxTextScale`/`autoShrink`), which has no GPU in it: the renderer's `Fonts::layout` places glyphs on the atlas with what it
  returns, `Renderer::measure_text` and `fa::TextMeasurer` (`fa/render/text_measure.h`, what the engine owns when there is no
  renderer, handed to scripts, the UI and `bounds()` as `VisualMeasure.textSize`) only take the size. One implementation, so the
  sizes are the same numbers with and without a window; `approx_text_size` is left for a built-in font that cannot be loaded, with
  one warning. The cameras are `fa/scene/camera_geometry.h`: `camera_geometry` builds the view, projection and viewport of a
  `Camera` for a render target size, `CameraSet` keeps the cameras of the last frame (`refresh`, the renderer's snapshot: queries
  before the first `render()` see the default camera) and answers `world_to_screen`, `screen_to_world`, `screen_ray` and
  `camera_at`; `update_parallax` writes `Parallax.offset` from it. The offset the world keeps is always the one for the FIRST
  camera (with a renderer too: while it draws, each camera, render target or `CameraView` shifts the layers for itself, and the
  first camera's offset is put back when the gathers are done). A scene load refreshes the `CameraSet`, and the script natives
  fall back to the live orthographic maths while it has no camera. The renderer builds its `CameraInfo` from the same function and
  `Engine::render()` without a renderer refreshes the `CameraSet` from the design size, so `input.mouse.world`,
  `camera.worldToScreen` and Parallax give the same floats either way (the queries always use the OpenGL depth range, whatever the
  backend). `world_state_hash` includes the live particles (`ParticleStore`: positions, ages, the emitter clocks, random sequences and
  emission accumulators).
  The ctests `example_<name>_graphics_same_hash` (one per example) compare `game.state_hash` of the WHOLE world of every scene
  after 40 frames with a renderer that draws and with `--no-graphics` (first the Sprite, SpriteAnimator and ParticleEmitter
  components alone, so a failure says whether the animators differ), and
  engine/runtime/tests/sim_without_renderer_tests.cpp does it frame by frame for a small project with a moving camera, a Parallax
  layer, a fitted panel and wrapped Japanese text. engine/render/tests/text_measure_tests.cpp compares `TextMeasurer` with the
  renderer (Latin, CJK, Arabic, the missing-glyph fallback, wrapping, rich text, the text and interface scales) with `==`, and
  one test with no renderer at all checks fixed sizes of the bundled font (4% tolerance) so it also runs where there is no GPU. The
  `TextMeasurer` is kept in step with the project settings only while there is no renderer.
Game-maker docs: [ANIMATION.md](ANIMATION.md).

### UI
Menus and settings screens are components (`Panel`, `Button`, `Toggle`, `Slider`, `TextField`, `ScrollList` in
`scene/components.h`, category "UI"), screen space only; `Interactable` is the exception (below). The work is split three ways so nobody depends on a sibling:
- **Where a widget is** has ONE definition, `fa/scene/ui_rect.h` (`ui_rect`, `ui_clip_rect`, `ui_slider_track`); layout, hit-testing, drawing and
  the editor's picking (`bounds.h`) all call it.
- **How it behaves** is `fa_ui` (`UiSystem`, `fa/ui/ui.h`): layout of Panel and ScrollList children, focus rules
  (nothing takes focus except `autoFocus`), navigation and auto-repeat over the `ui_*` actions, pointer hover / press /
  drag / wheel, widget values, and the `ui.*` game events (`world.events().game`, which scripts receive through
  `world.on` and `ui.on`). It reads `Input`, writes components and events, never draws. The runtime calls `update`
  every frame before `scripts.update` and `layout` before drawing; `ui.state` is its read-only command.
- **Any entity as a widget.** The `Interactable` component (`scene/components.h`) makes a composition of sprites, shapes, text and
  children a widget of the same focus, navigation and event system, with no second system next to it: `fa_ui` keeps one list of
  items in which a Button and an Interactable differ only in where the rectangle comes from (`ui/src/interactable.cpp`: the bounds of the
  entity and its children, projected through a camera for a world-space one, or screen-space rectangles). `UiSystem` gets the camera as
  an injected `UiProjectFn` (`set_world_projection`; the runtime installs the renderer's `world_to_screen`/`camera_at`, because `fa_ui` is below
  `fa_render`; without it `scene/camera_query.h` does the orthographic maths, which headless runs use). `InteractableVisual` children
  show, hide or tint by state; hover, blur, press and release events come from Interactables only.
- **How it looks** is `fa_render` (`render/src/ui2d.cpp`): 9-slice backgrounds, labels, focus ring, drawn into the screen quad
  list. A ScrollList's descendants (widgets and every other screen-space item) carry a clip rectangle that `draw_group` applies as a scissor;
  batches only merge with an equal clip.

### Platform services
Achievements, stats, leaderboards, cloud saves, purchases, the store overlay, rich presence, integrity tokens and ads are
ONE request interface, `fa_services` (`fa/services/platform.h`), so a game is written once and a backend decides what answers. A
request is `(method, args)` and gets one answer, a result or `{code, message, hint}`:
- **The catalog** is the `"platform"` section of factoria.json. `PlatformServices::start` checks every id against it
  and adds the store's own id (`storeId`) before the backend sees the request; a mistake is a teaching error there,
  never inside an SDK.
- **A backend** is a `PlatformBackend`: the fake (`fake_platform.h`, in memory, deterministic, the reference of every
  method), "none" (exported games without a store), or the adapter in `fa_runtime` (`platform_backend.h`) that turns a
  native plugin's `FaBackendDesc` (plugin ABI v2, `fa_plugin.h`) into one. `choose_platform_backend` picks which runs.
- **Answers** may come later and from any thread (`PlatformSink`, a weak handle: an answer after the engine is gone is
  ignored). The game thread takes them once per frame (`Engine` calls `PlatformServices::frame()` and
  `ScriptSystem::dispatch_platform()` first thing), which settles the scripts' Promises and calls `platform.on` listeners.
- **Commands** `platform.state`, `platform.reset`, `platform.respond`, `platform.emit`, `platform.revoke`, `platform.set_fake`
  (`platform_commands.h`, registered by the runtime): `game.platform` of `factoria:test` is a view of them.
- **`http.fetch`** is a method of the same pipeline with a backend slot of its own (`set_http_backend`, next to the store and
  ads backends). `PlatformServices::prepare` checks the URL against the `"network"` hosts of factoria.json
  (`fa/services/network.h`) and shapes the arguments; the runtime's `HttpBackend` (`http_backend.cpp`) hands them to
  an `HttpClient` of `fa_platform` (`fa/platform/http.h`: WinHTTP, `NSURLSession`, libcurl loaded with dlopen, Android's
  `HttpURLConnection` through JNI, the browser's `fetch`; one `http_<platform>` file each). Headless runs and tests ask for
  the fake backend, which never touches the network. A plugin cannot offer the "http" service.
- **`analytics` and `remoteConfig`** are script services in `factoria.js`, not platform services: they call `http.fetch`
  (so the same host check and fake apply) and keep their state in `storage` under the engine's own `factoria.*` keys.
  `fa/services/network.h` parses their `factoria.json` sections (`parse_analytics`, `parse_remote_config`) and `factoria
  validate` checks them. The script system ticks them with the unscaled frame time, and runs `app.suspend` and the quit
  flush (`request_quit` and `close_requested` wait up to 3 seconds for a pending request) through hooks of the prelude.
Docs: [PLATFORM.md](PLATFORM.md), [NETWORKING.md](NETWORKING.md), [ANALYTICS.md](ANALYTICS.md).

### Localization
Text lives in string tables, `locales/<language>.json`, and the engine shows the player's language (docs:
[LOCALIZATION.md](LOCALIZATION.md)).
- **Pure logic** is `fa_core` (`fa/core/i18n.h`): BCP 47 tags and best match, CLDR plural rules, `{placeholder}`
  formatting, table parsing with JSON-pointer errors, and `I18n` (current language, fallback chain current -> base ->
  default, warn once per missing key). It reads files through `fa::fs`.
- **The system language** is `fa_platform` (`system_languages()`, one `system_language_<platform>` file each).
- **The pass** is `fa_scene` (`localize_world`, `localize_entity`): it writes `t(key)` into `Text.text`, `Button.text`,
  `Toggle.label`, `Slider.label` and `TextField.placeholder` for components with a `key`, only when the string differs.
  The runtime runs it after every scene load, each frame and on a language change; scripts run it for what they spawn.
- **The engine** (`fa_runtime`, `localization.cpp`) owns the `I18n`: it reads `project.localization`, chooses the start
  language (`choose_start_language`: `EngineConfig::language`, `FA_LANGUAGE`, the system language of a windowed game,
  else the default language), switches language (`ScriptHost::set_language`, the `i18n.change` game event) and registers
  `i18n.state` / `i18n.set_language`. It also hands `project.localization.fallback_fonts_for(language)` to
  `Renderer::set_fallback_fonts` when the renderer starts and at every switch (`apply_fallback_fonts`). Scripts see it as
  the `i18n` object (`ScriptHost::i18n()`).
- **The tools** (`fa_tooling`) check the tables and fonts in `factoria validate` (`validate_localization.cpp`, with
  `FontCoverage` from `fa_render`) and register `i18n.export` / `i18n.import` (`translations.cpp`: CSV and XLIFF 1.2 in
  `translations_formats.cpp`). Both read the tables through the same `read_table` (`localization_tables.cpp`).

### Headless
`HeadlessGpu` creates a window-less device: EGL (Linux; Mesa llvmpipe works
without a GPU), Metal (macOS), D3D11 with WARP fallback (Windows). Used by
`factoria run --headless`, tests, the MCP server and CI.

## AI integration

- **External agents** (Claude Code, Codex, any MCP client) connect to
  `factoria mcp --project <dir>` and get every command as a tool, docs as
  resources, and screenshots as images. Users keep using their own Claude /
  ChatGPT subscriptions through those official CLIs. The server and the editor notice when the `factoria` file was replaced
  under them (`fa/tooling/self_update.h`: stat, then the build identity written in the binary; `fa/mcp/update_monitor.h`): the
  server re-executes itself between two messages (POSIX; `docs/MCP.md`, "After an update"), the editor offers a Restart notice
  (`docs/EDITOR.md`, "Updates"), and `engine.update_status` says it.
- **Built-in agent** (`factoria ai`, editor AI panel): providers
  `anthropic` (API key or `ant` CLI profile), `openai-compatible`
  (OpenAI, OpenRouter, Gemini, Groq, Ollama, LM Studio...), and CLI agents
  `claude-code`, `codex`, `generic-cli` (spawned with the FactorIA MCP server
  attached; in the editor, Claude Code attaches the editor's own MCP endpoint,
  so it edits the open scene). API keys live in the user config (`~/.factoria/ai.json`) or env
  vars — never in projects.
- **Roles** (seven; the table is in [AI_PROVIDERS.md](AI_PROVIDERS.md#roles)): `orchestrator` plans and delegates,
  `worker` implements, `fast` handles small mechanical tasks, `artist` makes the art, `audio` makes sound and music, and
  `artCritic` and `reviewer` are read-only critics of the art and of the game. Defaults: Claude Opus 5.5 (`orchestrator`
  `xhigh`; `artist`, `artCritic` and `reviewer` `high`), Claude Sonnet 5.5 (`worker` and `audio`, `medium`), Claude
  Haiku 5.5 (`fast`, `max`); configurable per role.

## ENGINE_FEEDBACK.json (the improvement loop)

Every project has `ENGINE_FEEDBACK.json` at its root (created by
`factoria new`, required by `factoria validate`). AIs append an entry whenever
the engine lacked something and they had to work around it:

```json
{
  "format": "factoria.feedback/1",
  "project": "space-dodge",
  "engineVersion": "0.1.0",
  "entries": [
    {
      "id": "FB-0001",
      "date": "2026-10-13",
      "reporter": { "kind": "ai", "agent": "claude-code", "model": "claude-sonnet-5-5" },
      "category": "physics",
      "severity": "major",
      "title": "No fluid simulation",
      "missing": "There is no liquid solver, so water cannot flow around bodies and fill a container.",
      "workaround": "scripts/water.js moves sprites to fake a water surface.",
      "workaroundFiles": ["scripts/water.js"],
      "suggestion": "Add a particle-based Fluid2D component.",
      "occurrences": 1,
      "status": "open"
    }
  ]
}
```

- `category`: rendering-2d, rendering-3d, physics, audio, input, ui, scripting,
  scene, assets, animation, tooling, ai-integration, docs, platform,
  performance, networking, other.
- `severity`: blocker, major, minor, nice-to-have.
- `status`: open, fixed-in-engine, wont-fix, duplicate, rejected (with `statusReason` and `statusBy`).

Ways to write it: MCP/AI/CLI command `feedback.report`, `factoria feedback add`,
the editor's Feedback panel, or editing the JSON directly (schema:
`schemas/engine-feedback.schema.json`). Engine developers run
`factoria feedback collect <dirs...>` to merge many projects' files into a
ranked report (similar titles grouped, ranked by count × severity) that
becomes the engine roadmap.

## Testing

- C++ unit tests: doctest, one `fa_test_<module>` per module (`ctest`).
- Rendering: headless golden images (`engine/render/tests/golden/*.png`, plus the menus and export goldens in
  `tools/cli/tests/golden/`). One golden serves every backend (Metal, D3D11, GL on llvmpipe). A picture matches when its
  mean error, the share of pixels more than 4/255 off and its largest error are all within the limits of
  `engine/core/tests/golden_check.h`. A golden that does not exist FAILS the test; `FA_UPDATE_GOLDENS=1` writes it
  (docs/BUILDING.md, "Golden images").
- Game tests: `factoria test` runs `tests/*.test.js` headless.
- Examples: each has `example_<name>_validate` and `example_<name>_test` ctest tests, and some also an autoplay and a
  perf budget (label `example`; they run in Release builds, see docs/BUILDING.md).
- Determinism: the maths of the simulation and the replay hashes, below.

### Determinism of the maths

The simulation (everything that changes the state a game, a test or a replay can see) gives the same bits on every
platform, so replays, `game.state_hash`, lockstep play and `factoria test` results do not depend on the machine. The rules:

- **Build flags.** No floating-point contraction (`-ffp-contract=off`, `/fp:precise` on MSVC), so `a * b + c` is never
  fused on arm64 or CPUs with FMA. `+ - * /`, `sqrt`, `floor`, `ceil`, `fmod`, `fabs`, `ldexp` are exact in IEEE 754 and
  are used as they are.
- **No C library transcendentals in the simulation.** `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `exp`, `exp2`,
  `expm1`, `log`, `log2`, `log10`, `log1p`, `pow`, `sinh`, `cosh`, `tanh`, `asinh`, `acosh`, `atanh`, `cbrt` and `hypot`
  of glibc, Apple's libm, the MSVC CRT and musl (wasm) are each within an ulp of the exact result but round differently.
  `fa/core/det_math.h` has them for `float` (`fa::det::exp(x)`, a frozen API: the float results never change) and for
  `double` (`fa::det::f64::exp(x)`). Both are built only from `+ - * / sqrt` on doubles, and are tested for accuracy against
  the C library (2 ulp for `exp`/`log`, 3 for `sin`/`cos`, up to 6 for `tan`, `atan`, `atan2`, `expm1`, `log1p` and the hyperbolics, a few for `pow` of a large result; `10^n` is the double nearest to the power for `n` from -307 to 308, and `log10` of it is exactly `n`) and against a table of bit patterns
  (`engine/core/tests/test_det_math_f64.cpp`: a platform that rounds differently fails with the input that differs). The
  float functions compute in double and round to float once.
- **Game scripts.** QuickJS's `Math.*` calls the C library, so the engine builds QuickJS with a force-included header
  (`engine/script/quickjs_det/quickjs_det_math.h`, `-include` / `/FI`, C sources only) that redirects those calls to
  `fa::det::f64` through a C++ shim (`quickjs_det_shim.cpp`). There is one QuickJS in the process, so tests, script tools and
  editor scripts get the same `Math`; none keeps the native one. `external/` is untouched. The test
  `engine/script/tests/test_det_math_script.cpp` compares `Math.*` with `f64` bit for bit.
- **The source scan.** `engine/core/tests/test_det_scan.cpp` reads the sources of the simulation and fails on `std::exp`,
  `std::pow`, `std::sin`, `std::cos`, ... and on the unqualified and C forms (`pow(`, `sinf(`), ignoring comments and string
  literals. The file set is explicit, at the top of the test: `kSimulationDirs` (directories, every `.cpp`/`.h` below them),
  `kSimulationFiles` (single files, for simulation code that lives in a directory the scan does not read as a whole) and
  `kExempt` (a file that really needs the C library, with the reason). To cover new simulation code (SpriteAnimator and the
  particle step when they move into the engine's step, M91.1a): put its path (from the repository root, forward slashes) in
  `kSimulationFiles` or its directory in `kSimulationDirs`, run the test, and replace each call it flags with `fa::det::`.
  Rendering, audio, the editor, tools and tests are not scanned: what they compute is never read back by the simulation.
- **Replay hashes.** A replay feeds the exact bits of every number to a hash and compares the first 16 hex digits with a
  value COMMITTED in the repository, on every CI platform. A hash that differs on one platform is a determinism bug of
  that platform; one that differs on all of them is a change of the simulation, and the new value is copied from the log
  (the line `FA_DET_HASH` / `FA_PHYSICS_REPLAY_HASH` of `ctest -V`). The replays: physics 2D and 3D (`test_determinism.cpp`,
  `physics_determinism`), particles and feel (`engine/scene/tests/test_det_replay.cpp`, `det_replay_hashes`), and the scripts'
  `Math` in a seeded loop, 2D and 3D physics bodies and the nav bake and search driven by a script
  (`tools/cli/tests/determinism_probe.js`, expected values in `tools/cli/tests/determinism_expected.txt`;
  `engine/runtime/tests/det_probe_tests.cpp`, `det_probe_hashes`). The Linux, Windows and macOS jobs run all three.
  The script probe also runs on the Android emulator (`scripts/android-smoke.sh`), the iOS simulator
  (`scripts/ios-smoke.sh`) and in headless Chrome for the web export (`scripts/web-smoke.sh`); each prints the line and
  `scripts/det-hash-check.sh` compares it with the expected file. The particle and feel replays are desktop only (a script
  cannot reach them). New scenes for a replay go in `test_det_replay.cpp` or the probe.
- **The watchdog.** A script callback cut by the watchdog (more than 2 s of CPU time) skips the rest of its code at a point that depends
  on the machine, so the run is invalid: `ScriptSystem::watchdog_cut_count()` / `watchdog_cuts()` expose the cuts,
  `run_headless` reports `replayValid: false` and exits 1 (`HeadlessRunOptions::failOnWatchdogCut`, off only for
  `script.trace`), and `factoria test` fails the test that ran with a cut (docs/SCRIPTING.md, "Runtime notes").
