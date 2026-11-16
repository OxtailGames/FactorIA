# FactorIA architecture

FactorIA is a 2D/3D game engine designed so that **AI agents can build games
with it reliably** and **anyone (human or AI) can add tools easily**. It targets
Windows, macOS, Linux, iOS and Android from one codebase.

## Pages

The architecture is split by topic (each page stays under 60 KB). This page holds the design principles, the repository
layout, the AI integration, the feedback loop and the testing rules; the rest is in:

- [The world and reflection](ARCHITECTURE_CORE.md): World, entities, components, the hierarchy cache, Reflection.
- [Commands](ARCHITECTURE_COMMANDS.md): the command (tool) system, capabilities.
- [Files and block codecs](ARCHITECTURE_FILES.md): `fa::fs`, the file rules, block codecs.
- [Game loop, jobs and loading](ARCHITECTURE_THREADS.md): the game loop, jobs and threads, systems that run as jobs, background loading.
- [Rendering](ARCHITECTURE_RENDERING.md): coordinates and units, rendering, start-up order and the shader cache, textures, bounds.
- [Animation, UI, platform, localization, docs](ARCHITECTURE_RUNTIME.md): animation, UI, platform services, localization, headless, docs.

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
  core/            fa_core     types, math, log, json, fs (VFS; sources: the project folder, Android APK assets, a game pack: pack.h), image, reflection, commands, json schema, child processes (process.h), SHA-1/SHA-256 (hash.h), authenticated encryption for files: HMAC, HKDF, ChaCha20-Poly1305, sealed blobs, OS random bytes (crypto.h), crash reports (crash.h), UTF-8 decoding and encoding (utf8.h), MPEG-1 video + MP2 audio decoding (video.h, pl_mpeg), string tables, plural rules and language matching (i18n.h)
  scene/           fa_scene    World (ECS), built-in components, scene/prefab JSON, 2D bounds of visuals (bounds.h), glTF skeletons and clips (skeleton.h) and the Animator system (animation.h), GPU-free model reader for colliders (mesh_geometry.h), the Video system (video.h: plays the Video components from the game clock)
  platform/        fa_platform window/app loop (sokol_app), headless GPU, input + actions, gamepads, the system languages
  render/          fa_render   2D + 3D renderer, text (HarfBuzz shaping, SheenBidi bidi), particles, debug draw, capture, KTX2 textures (Basis Universal transcoder), the picture of Video components
  physics/         fa_physics  Box2D v3 (2D) + simple 3D (spheres, oriented boxes, capsules, convex hulls, static triangle meshes, rigid-body rotation, hinge/ball/fixed joints, character controller, continuous collision, shape casts)
  audio/           fa_audio    mixer with a bus table (built-in plus project buses) with per-bus effects (low-pass, reverb, ducking) and snapshots, wav/ogg/mp3, null device + recording, the sound of Video components; the device callback takes no lock and allocates nothing (lock-free command and return rings, streams decoded on jobs, docs/SOUND.md "The audio callback")
  ui/              fa_ui       game UI behaviour: Panel/ScrollList layout, focus + keyboard/gamepad/mouse navigation, widget values, `ui.*` events
  services/        fa_services store and platform services: the `"platform"` catalog, the request dispatcher (`PlatformServices`), the fake and "none" backends, the `platform.*` commands
  script/          fa_script   QuickJS bindings, behaviours, JS tools, test runner, scripts compiled to bytecode for game packs (bytecode.h), the script debugger runtime (debugger.h, docs/design/SCRIPT_DEBUGGER.md)
  runtime/         fa_runtime  Engine (game loop), project file, built-in commands, the command extension hook (command_extension.h); fa/runtime/internal/ is the engine's private state for engine tools (not for games or plugins)
player/            factoria_player — minimal runtime for exported games; it links fa_runtime and never fa_authoring (the configure fails otherwise)
tools/             developer tools (desktop only)
  authoring/       fa_authoring the commands only developer tools use (the scene file commands `prefab.save` and `scene.format`; `anim.*`, `skin.*` and `bones.*` editing and viewing (`anim.pose`, `anim.filmstrip`, `anim.list`); the vfx review commands `vfx.check`, `vfx.budget`, `vfx.filmstrip`; the `mesh.*` tools including `mesh.save`; `scene.import_ascii` and `scene.ascii_edit`); registered into every Engine by `fa::authoring::install()` (the CLI, editor and tests call it), not in the player
  common/          fa_tooling  scaffolding, validation, ENGINE_FEEDBACK, embedded docs, API export, export (platform settings, icons, exe icon patcher, texture compression with the Basis Universal encoder, atlas packing), setup (one-click install of the JDK, Android SDK, players, CMake), palette lock, AI-content disclosure
  mcp/             fa_mcp      Model Context Protocol server (stdio; loopback HTTP for the editor)
  dap/             fa_dap      Debug Adapter Protocol server of the script debugger (framing, launch validation, DapServer); `factoria dap` runs it
  ai/              fa_ai       AI providers (API keys + Claude Code / Codex CLIs), agent loop, roles; asset providers (images, sounds, 3D models) and the assets.generate_* commands
  editor/          fa_editor   Dear ImGui editor with AI assistant panel
  cli/             factoria    the single developer binary
  vscode/          the VS Code extension of the script debugger (plain JS, no build step): embedded in fa_tooling and installed by `factoria setup vscode`; it starts `factoria dap` (docs/DEBUGGING.md)
  bench/           fa_bench    the engine's microbenchmarks (ECS queries, hierarchy, physics, render gather, command dispatch, script bridge, audio mix) with a baseline per machine kind (docs/PERFORMANCE.md, "Microbenchmarks")
  fuzz/            fuzz targets of the loaders and decoders (libFuzzer with `FA_FUZZ`, a corpus replay ctest otherwise; docs/design/BUILDING_TESTS.md, "Fuzzing")
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
scripts/           build, test, CI and packaging scripts for each operating system (docs/design/BUILDING.md)
feedback/          ROADMAP.md, done/ (one file per finished milestone) and the feedback collected from the examples
external/          vendored third-party code (do not edit)
```

Module dependency order (a module may only include modules above it):

```
core -> scene -> platform -> render, physics, audio, ui, services -> script -> runtime -> authoring -> tooling -> mcp, dap, ai -> editor -> cli
```

(`platform` is the OS layer: window, input, gamepads. `services` is the stores' side: achievements, purchases.
`authoring` is the commands of the developer tools: `engine/` ships in every game, `tools/authoring` only in the factoria CLI,
the editor and the servers.)

#### Where a command goes

A command that an exported game's player does not need (it writes project files, bakes or imports assets, edits animations
or levels) goes to `tools/authoring/src/`, not to `engine/runtime/src/`: the player has no code for it, and a game script
cannot see it. The command file registers itself from `register_<area>_commands(Engine&, Engine::Impl&)` (declared in
`tools/authoring/src/authoring_internal.h`, called from `src/authoring.cpp`) and includes
`fa/runtime/internal/engine_impl.h` (`Engine::Impl`; for engine tools only, never a game or plugin). The commands arrive in an
Engine through a process-wide extension list (`fa/runtime/command_extension.h`): `fa::authoring::install()`
(`fa/authoring/authoring.h`) adds the extension, and every `Engine::init` after it runs the extensions right after the built-in
commands and the plugins' commands. A program that creates engines calls `install()` once at start-up (the mains of the
`factoria` binary and of `fa_editor_autotest`; the test executables of every module at or above `fa_authoring` get it from
`cmake/doctest_main.cpp`, the runtime's tests do not). `Engine::runtime_command_names()` is what the player has: the
commands registered before plugins and extensions. The root `CMakeLists.txt` fails the configure when `factoria_player`
reaches `fa_authoring` through any chain of links (`fa_check_not_linked`). When an authoring command shares code with one the
player keeps, the shared part stays in the runtime and is declared in an internal header for the authoring file to use (never
copied): `scene.import_ascii` (authoring, can write a scene file) and `scene.place_ascii` (player, running world only) share
`fa/runtime/internal/ascii_level.h`.

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
- **Roles** (seven; the table is in [AI_PROVIDERS.md](../ai-providers/AI_PROVIDERS_CONFIG.md#roles)): `orchestrator` plans and delegates,
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

- C++ unit tests: doctest, one `fa_test_<module>` per module (`ctest`). The test main (`cmake/doctest_main.cpp`) calls
  `fa::authoring::install()` when the executable sees `fa/authoring/authoring.h` (fa_authoring and every module above it), so
  their engines have the authoring commands; `fa_test_runtime` does not link it and tests what the player has.
- A module whose tests take minutes is split into several ctest entries that `ctest -j` runs at the same time, each its
  own process of the same executable. `fa_test_tooling` is `tooling_1` ... `tooling_5` (label `tooling`):
  `tools/common/CMakeLists.txt` names the heavy test files of the first four, balanced by seconds, and the fifth runs every
  other file, so a new test file needs no edit. The files are picked by name with `--fa-files=a_test.cpp,b_test.cpp` and
  `--fa-files-exclude=...` (`cmake/doctest_main.cpp`, every doctest executable has them; doctest's own `--source-file` would
  match the raw `__FILE__`, which has slashes on Ninja and backslashes under MSBuild). The ctest entry `tooling_split_check`
  (`cmake/fa_doctest_split_check.cmake`, plain CMake) fails unless the entries together list exactly the test cases of the
  whole executable, each once. Entries run at the same time, so two test cases never share a fixed name outside their
  process: temp folders come from `fa::fs::make_temp_dir` (they carry the process id) and servers bind port 0. The one
  fixed name is `~/Library/Containers/com.factoria.sandboxprobe`, the container of `sign.macos`'s sandboxed app: one
  test case uses it, so one entry. `ctest -L tooling` runs the five entries and the check.
- Rendering: headless golden images (`engine/render/tests/golden/*.png`, plus the menus and export goldens in
  `tools/cli/tests/golden/`). One golden serves every backend (Metal, D3D11, GL on llvmpipe). A picture matches when its
  mean error, the share of pixels more than 4/255 off and its largest error are all within the limits of
  `engine/core/tests/golden_check.h`. A golden that does not exist FAILS the test; `FA_UPDATE_GOLDENS=1` writes it
  (docs/design/BUILDING_TESTS.md, "Golden images").
- Game tests: `factoria test` runs `tests/*.test.js` headless.
- Examples: each has `example_<name>_validate` and `example_<name>_test` ctest tests, and some also an autoplay and a
  perf budget (label `example`; they run in Release builds, see docs/design/BUILDING.md).
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
