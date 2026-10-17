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
  core/            fa_core     types, math, log, json, fs (VFS), image, reflection, commands, json schema, child processes (process.h), SHA-1/SHA-256 (hash.h)
  scene/           fa_scene    World (ECS), built-in components, scene/prefab JSON, 2D bounds of visuals (bounds.h)
  platform/        fa_platform window/app loop (sokol_app), headless GPU, input + actions, gamepads
  render/          fa_render   2D + 3D renderer, text, particles, debug draw, capture, KTX2 textures (Basis Universal transcoder)
  physics/         fa_physics  Box2D v3 (2D) + simple 3D (spheres, oriented boxes with rigid-body rotation, continuous collision, shape casts)
  audio/           fa_audio    mixer, wav/ogg/mp3, null device + recording
  ui/              fa_ui       game UI behaviour: Panel/ScrollList layout, focus + keyboard/gamepad/mouse navigation, widget values, `ui.*` events
  services/        fa_services store and platform services: the `"platform"` catalog, the request dispatcher (`PlatformServices`), the fake and "none" backends, the `platform.*` commands
  script/          fa_script   QuickJS bindings, behaviours, JS tools, test runner
  runtime/         fa_runtime  Engine (game loop), project file, built-in commands
player/            factoria_player — minimal runtime for exported games
tools/             developer tools (desktop only)
  common/          fa_tooling  scaffolding, validation, ENGINE_FEEDBACK, embedded docs, API export, export (platform settings, icons, exe icon patcher, texture compression with the Basis Universal encoder, atlas packing), setup (one-click install of the JDK, Android SDK, players, CMake), palette lock, AI-content disclosure
  mcp/             fa_mcp      Model Context Protocol server (stdio; loopback HTTP for the editor)
  ai/              fa_ai       AI providers (API keys + Claude Code / Codex CLIs), agent loop, roles; asset providers (images, sounds, 3D models) and the assets.generate_* commands
  editor/          fa_editor   Dear ImGui editor with AI assistant panel
  cli/             factoria    the single developer binary
templates/         project templates used by `factoria new`
schemas/           JSON Schemas (project, feedback, AI config); scene schema is generated
docs/              documentation in English (embedded into the binary); translations in docs/i18n/<lang>/
examples/          sample games (also used as integration tests)
platforms/         android/ (Gradle) and ios/ packaging; windows/ (installer script) and linux/ (AppImage files) for the downloads
external/          vendored third-party code (do not edit)
```

Module dependency order (a module may only include modules above it):

```
core -> scene -> platform -> render, physics, audio, ui, services -> script -> runtime -> tooling -> mcp, ai -> editor -> cli
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

### Reflection
`fa::TypeRegistry::global()` (core/reflect.h) holds every component type with
documented fields. From it we derive: JSON load/save, `scene.set_component`, script
property access, JSON Schemas, Markdown docs and TypeScript declarations.

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

### Game loop
See `engine/runtime/include/fa/runtime/engine.h`. Fixed-step simulation
(default 60 Hz) + variable render. Headless `Engine::step(n)` advances exactly
`n` fixed frames — deterministic given seed + input.

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
`shaders/bloom.glsl`), so screenshots include it. With `Camera.bloomScreenSpace = false`
the frame is split: world pass, bloom, then a second pass that draws the screen-space
groups (HUD) on top; with MSAA the glow is added to the multisampled image and the
HUD pass loads it again, so the HUD is multisampled too. Shaders are GLSL annotated for
`sokol-shdc`; generated headers are committed (`tools/shaders/`).

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

### UI
Menus and settings screens are components (`Panel`, `Button`, `Toggle`, `Slider`, `TextField`, `ScrollList` in
`scene/components.h`, category "UI"), screen space only. The work is split three ways so nobody depends on a sibling:
- **Where a widget is** has ONE definition, `fa/scene/ui_rect.h` (`ui_rect`, `ui_clip_rect`, `ui_slider_track`); layout, hit-testing, drawing and
  the editor's picking (`bounds.h`) all call it.
- **How it behaves** is `fa_ui` (`UiSystem`, `fa/ui/ui.h`): layout of Panel and ScrollList children, focus rules
  (nothing takes focus except `autoFocus`), navigation and auto-repeat over the `ui_*` actions, pointer hover / press /
  drag / wheel, widget values, and the `ui.*` game events (`world.events().game`, which scripts receive through
  `world.on` and `ui.on`). It reads `Input`, writes components and events, never draws. The runtime calls `update`
  every frame before `scripts.update` and `layout` before drawing; `ui.state` is its read-only command.
- **How it looks** is `fa_render` (`render/src/ui2d.cpp`): 9-slice backgrounds, labels, focus ring, drawn into the screen quad
  list. A ScrollList's descendants (widgets and every other screen-space item) carry a clip rectangle that `draw_group` applies as a scissor;
  batches only merge with an equal clip.

### Platform services
Achievements, stats, leaderboards, cloud saves, purchases, the store overlay, rich presence and integrity tokens are
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
- **Commands** `platform.state`, `platform.reset`, `platform.respond`, `platform.emit`, `platform.set_fake`
  (`platform_commands.h`, registered by the runtime): `game.platform` of `factoria:test` is a view of them.
Docs: [PLATFORM.md](PLATFORM.md).

### Headless
`HeadlessGpu` creates a window-less device: EGL (Linux; Mesa llvmpipe works
without a GPU), Metal (macOS), D3D11 with WARP fallback (Windows). Used by
`factoria run --headless`, tests, the MCP server and CI.

## AI integration

- **External agents** (Claude Code, Codex, any MCP client) connect to
  `factoria mcp --project <dir>` and get every command as a tool, docs as
  resources, and screenshots as images. Users keep using their own Claude /
  ChatGPT subscriptions through those official CLIs.
- **Built-in agent** (`factoria ai`, editor AI panel): providers
  `anthropic` (API key or `ant` CLI profile), `openai-compatible`
  (OpenAI, OpenRouter, Gemini, Groq, Ollama, LM Studio...), and CLI agents
  `claude-code`, `codex`, `generic-cli` (spawned with the FactorIA MCP server
  attached; in the editor, Claude Code attaches the editor's own MCP endpoint,
  so it edits the open scene). API keys live in the user config (`~/.factoria/ai.json`) or env
  vars — never in projects.
- **Roles**: `orchestrator` plans and delegates, `worker` implements, `fast`
  handles small mechanical tasks. Defaults: Claude Opus 5.5 (effort `xhigh`),
  Claude Sonnet 5.5 (`medium`), Claude Haiku 5.5 (`max`); configurable per role.

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
      "title": "No one-way platforms",
      "missing": "Collider2D has no one-way option, so the player cannot jump up through platforms.",
      "workaround": "scripts/one_way.js disables the platform collider while the player moves upward.",
      "workaroundFiles": ["scripts/one_way.js"],
      "suggestion": "Add Collider2D.oneWay (bool) with a configurable direction.",
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
- `status`: open, fixed-in-engine, wont-fix, duplicate.

Ways to write it: MCP/AI/CLI command `feedback.report`, `factoria feedback add`,
the editor's Feedback panel, or editing the JSON directly (schema:
`schemas/engine-feedback.schema.json`). Engine developers run
`factoria feedback collect <dirs...>` to merge many projects' files into a
ranked report (similar titles grouped, ranked by count × severity) that
becomes the engine roadmap.

## Testing

- C++ unit tests: doctest, one `fa_test_<module>` per module (`ctest`).
- Rendering: headless golden images (`tests/golden/*.png`, tolerance-based).
- Game tests: `factoria test` runs `tests/*.test.js` headless.
- Examples are smoke-tested headless in CI on every platform that can.
