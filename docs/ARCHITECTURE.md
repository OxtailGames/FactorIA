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
  core/            fa_core     types, math, log, json, fs (VFS; sources: the project folder, Android APK assets, a game pack: pack.h), image, reflection, commands, json schema, child processes (process.h), SHA-1/SHA-256 (hash.h), crash reports (crash.h), UTF-8 decoding and encoding (utf8.h), string tables, plural rules and language matching (i18n.h)
  scene/           fa_scene    World (ECS), built-in components, scene/prefab JSON, 2D bounds of visuals (bounds.h), glTF skeletons and clips (skeleton.h) and the Animator system (animation.h), GPU-free model reader for colliders (mesh_geometry.h)
  platform/        fa_platform window/app loop (sokol_app), headless GPU, input + actions, gamepads, the system languages
  render/          fa_render   2D + 3D renderer, text (HarfBuzz shaping, SheenBidi bidi), particles, debug draw, capture, KTX2 textures (Basis Universal transcoder)
  physics/         fa_physics  Box2D v3 (2D) + simple 3D (spheres, oriented boxes, capsules, convex hulls, static triangle meshes, rigid-body rotation, hinge/ball/fixed joints, character controller, continuous collision, shape casts)
  audio/           fa_audio    mixer, wav/ogg/mp3, null device + recording
  ui/              fa_ui       game UI behaviour: Panel/ScrollList layout, focus + keyboard/gamepad/mouse navigation, widget values, `ui.*` events
  services/        fa_services store and platform services: the `"platform"` catalog, the request dispatcher (`PlatformServices`), the fake and "none" backends, the `platform.*` commands
  script/          fa_script   QuickJS bindings, behaviours, JS tools, test runner, scripts compiled to bytecode for game packs (bytecode.h)
  runtime/         fa_runtime  Engine (game loop), project file, built-in commands
player/            factoria_player — minimal runtime for exported games
tools/             developer tools (desktop only)
  common/          fa_tooling  scaffolding, validation, ENGINE_FEEDBACK, embedded docs, API export, export (platform settings, icons, exe icon patcher, texture compression with the Basis Universal encoder, atlas packing), setup (one-click install of the JDK, Android SDK, players, CMake), palette lock, AI-content disclosure
  mcp/             fa_mcp      Model Context Protocol server (stdio; loopback HTTP for the editor)
  ai/              fa_ai       AI providers (API keys + Claude Code / Codex CLIs), agent loop, roles; asset providers (images, sounds, 3D models) and the assets.generate_* commands
  editor/          fa_editor   Dear ImGui editor with AI assistant panel
  cli/             factoria    the single developer binary
  vscode/          the VS Code extension of the script debugger (plain JS, no build step): embedded in fa_tooling and installed by `factoria setup vscode`; it starts `factoria dap` (docs/DEBUGGING.md)
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

Versions: `tools/common/api_since.json` says which release added each component, field (`Component.field`) and
command, and the generated reference prints it. A new component, field or command needs an `"unreleased"` entry there
(not in the registration call); the test `api_since` in `tools/common/tests` lists the exact lines to add. A release
renames `## Unreleased` in CHANGELOG.md to the version, and the same test then tells you to replace every
`"unreleased"` with it and regenerate `docs/COMPONENTS.md` and the browsable pages in `docs/reference/` (`factoria call
docs.write_reference '{"out":"docs"}'` from the repository root, checked by the test `api_reference`; plus
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

### Files: `fa::fs`
Everything the engine reads of a game (scenes, prefabs, textures, sounds, fonts, scripts, `factoria.json`) goes through
`fa::fs` (`core/fs.h`), by project-relative path (forward slashes, no `..`). The paths are answered from one of three
sources: the project folder on disk (`set_project_root`), the APK's assets on Android, or a **game pack**: one read-only
archive (`core/pack.h`) that `fa::fs::mount_pack` mounts, which is how a `--release` desktop export ships a game
([EXPORTING.md](EXPORTING.md#release-build-gamepak)). While a pack is mounted it answers every project-relative path alone
(`read_*`, `exists`, `is_directory`, `file_size`, `modified_time`, `list`); absolute paths and writes still go to the host.
So engine code must not open a game file with `std::ifstream` or `std::filesystem` on a path it built from the project
folder: use `fs::`, or the file will be missing from a packed game. The pack reads positionally (no shared file offset), so
it is safe from any thread. `script/bytecode.h` compiles scripts for the pack; the module loader reads a compiled script from
the same `.js` path.

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
HUD pass loads it again, so the HUD is multisampled too. `Camera.colorFilter` is the last post-process
(`Renderer::Impl::apply_color_filter`, `shaders/colorfilter.glsl`): a pass cannot read what it writes, so the filter
draws the finished target into a second image of the same size, and `present()`, `capture()` (screenshots, video) and
the editor viewport read that image while a filter is on; `none` skips the pass and the image. The colour-blind
CHECK (`simulate` of `game.screenshot`) is separate: `simulate_color_vision()` in `fa/core/image.h` on the captured
pixels. Shaders are GLSL annotated for
`sokol-shdc`; generated headers are committed (`tools/shaders/compile_shaders.sh`). Every mesh program (`mesh`,
`mesh_skin`, `shadow`, `shadow_skin`) comes from one template, `shaders/mesh_common.glsl`: a top file defines the
`@block fa_user` (a `surface()` snippet, plus `vertex()` with `FA_HAS_VERTEX`), `@include`s the template and declares
the programs. `mesh.glsl` is that top file with an empty `surface()`; a custom material is the same with its own
snippet, so the engine and the materials share one source of truth (an empty `surface()` renders pixel-identical to a
`MeshRenderer` without a material). Engine identifiers in the template start with `fa_`; `fa_time` (vertex and
fragment) is `World::time()`, the engine clock. The template is embedded in `fa_tooling`.

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
- **What the renderer reads:** `Animator::palette` (components.h), a runtime-only vector with one matrix per joint of skin 0,
  `jointGlobal * inverseBind` in the glTF's model space (vertices of a skinned mesh are not transformed by their node). The renderer
  (`renderer.cpp`) packs it into the `fa_skin` uniform (64 joints x 3 rows of a 3x4 matrix) and draws with the
  skinned programs of the mesh template (`mesh_skin`, `shadow_skin`: only the vertex stage differs, the lighting code is
  shared). Skinned items carry the Animator pointer in their material key so they never join an instanced batch, and their
  culling box is `skinned_bounds` (the bind box carried by every joint, joined).
- The tween module (`tween`, `ease`) is JavaScript (`factoria.js`), advanced by the script system's update with the scaled `dt`,
  so it shares the game clock with timers.
Game-maker docs: [ANIMATION.md](ANIMATION.md).

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
