# FactorIA

**English** | [Español](README.es.md)

A 2D/3D game engine in C++20, built so that AIs can create games.

## What it is

FactorIA is designed so that an AI agent (Claude, ChatGPT or another) can create,
test and tune a game without depending on a graphical editor:

- **Everything is text.** Projects, scenes, prefabs and input maps are JSON files
  with a schema. Game logic is written in JavaScript (QuickJS), with no compilation
  step.
- **Tools are commands.** Each engine capability is registered once and becomes
  available as an MCP tool, a CLI command, an editor command and a JavaScript
  function. The documentation is built into the binary.
- **Headless mode.** Deterministic runs without a window, with screenshots, JSON
  state dumps and JavaScript tests.
- **Existing AI accounts.** You can use your Claude or ChatGPT subscription through
  their official CLIs (Claude Code and Codex), or API keys. Keys are stored in the
  user's configuration, never in projects.
- **The engine learns from use.** Each game has an `ENGINE_FEEDBACK.json` where the
  AI notes what the engine was missing and how it worked around it. The development
  tools aggregate those files to decide what to improve.

It builds for Windows, macOS, Linux, iOS and Android from a single codebase.

## Status

Version 0.34 (CHANGELOG.md says what each version added). The engine modules, the `factoria` CLI, the MCP server, the AI
hub and the editor work, and the 11 example games in `examples/` (counted on 2026-11-09) were built by AI agents through
the public interface; their tests run with the test suite on a Release build (`ctest -L example`). Six are reference
games: Lantern Keep (a 2D platformer with menus, save slots, store services, accessibility options and four languages),
Clockwork Courier (a 3D game made for phones first), Burrow Brigade (2D couch co-op for up to four players, for desktop
and Steam), Tidewater Market (an isometric management game for the web and desktop), Larkspur Lodge (a 3D narrative
adventure) and Kindlewatch (a small 3D game whose every asset was made with the engine's own commands). The others are
smaller: Block Push, Ember Descent, Gem Roller, Neon Swarm and Sky Hopper. Each example's README says what it shows.

CI builds and tests every pull request and every push to `main` on Linux, Windows
(MSVC) and macOS, builds the iOS Simulator app and the Android library and APK, and runs them on the iOS Simulator and
an Android emulator (not on real devices; see [docs/MOBILE.md](docs/MOBILE.md)). Open gaps and next milestones:
[feedback/ROADMAP.md](feedback/ROADMAP.md).

## Try it

### Download

No compiler or dev tools needed. Download the latest version for your system once:
[Windows installer](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-windows-x64-setup.exe)
(or the [zip](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-windows-x64.zip)),
[macOS](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-macos-universal.tar.gz)
(Apple Silicon and Intel) or Linux ([tar.gz](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-linux-x64.tar.gz)
or [AppImage](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-linux-x64.AppImage)). Run the
installer, or unpack the zip / tar.gz into a folder of your choice, such as `C:\FactorIA` or `~/FactorIA`, and open the
editor:

- **Windows:** Start menu > **FactorIA Editor** (installer), or double-click `FactorIA-Editor.exe`. The Windows
  downloads are not code-signed yet (no certificate), so SmartScreen may stop them: click **More info > Run anyway**.
- **macOS:** run `./factoria editor` in Terminal from the unzipped folder. Releases after 0.1.3 are signed and
  notarized and open without a warning. Gatekeeper blocks 0.1.3 and earlier the first time: remove the download
  quarantine once, `xattr -dr com.apple.quarantine <folder>`, or allow
  `factoria` in System Settings > Privacy & Security > **Open Anyway** (details in docs/GETTING_STARTED.md).
- **Linux:** run `./factoria editor` from the unpacked folder, or `./FactorIA-linux-x64.AppImage` (after
  `chmod +x`; with arguments it is the `factoria` command).

You do not download it again: when a new version is out, the editor shows its release notes as it opens and asks
whether to update. **Update** installs it in the same folder and reopens the editor; **Not now** keeps your version.

The AI assistant needs [Claude Code](https://claude.com/claude-code) installed and signed in, or an API key. To use
Claude Code from a terminal outside the editor, add the folder to your PATH (the Windows installer does). Desktop,
Android (JDK and Android SDK only) and iOS (macOS package, Xcode) export all work from the download, with no engine
source. Details: [Download in GETTING_STARTED](docs/GETTING_STARTED.md#download-no-build-tools).

### Your first game

Open the editor, create a project, and ask the AI for a game: [docs/FIRST_GAME_WITH_AI.md](docs/FIRST_GAME_WITH_AI.md)
walks a person through it step by step, and [docs/MAKE_BY_HAND.md](docs/MAKE_BY_HAND.md) makes a small one by editing
the files yourself, to see what the AI does for you. From a terminal: `factoria new my-game`, then `factoria run
my-game` ([docs/GETTING_STARTED.md](docs/GETTING_STARTED.md)).

### Build from source (engine developers)

Linux (Debian or Ubuntu) and macOS, from the repository root:

```bash
./scripts/bootstrap-linux.sh      # on macOS: ./scripts/bootstrap-macos.sh
./scripts/build.sh debug --test   # configures, builds and runs the tests
```

Windows, in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Test
```

iOS (simulator) and Android (arm64):

```bash
./scripts/build-ios.sh --simulator
./scripts/build-android.sh
```

Platform requirements, presets and troubleshooting: [docs/design/BUILDING.md](docs/design/BUILDING.md).

Then create and run a game with the `factoria` CLI (built into `build/<preset>/tools/cli/`):

```bash
factoria new my-game --template 2d-platformer   # creates a project from a template
factoria run my-game                             # runs the game in a window
factoria test my-game                            # runs the game's JS tests headless
factoria mcp --project my-game                   # MCP server: exposes the commands to AI agents
```

Full walkthrough: [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md).

## Repository layout

```
engine/      engine modules: core, scene, platform, render, physics, audio, script, runtime
player/      factoria_player: minimal runtime that exported games ship with
tools/       development tools (desktop): CLI, MCP server, AI agent, editor
cmake/       CMake functions and platform selection
external/    bundled third-party dependencies (do not edit)
docs/        documentation in English (built into the binary; AIs read it through MCP); docs/design/ is for engine developers and stays out
scripts/     build, test, CI and packaging scripts for each operating system
templates/   project templates for `factoria new`
skills/      the engine's AI skills, baked into the binary
schemas/     JSON schemas for the project, ENGINE_FEEDBACK and AI configuration
examples/    example games made by AI agents, also used as integration tests
feedback/    roadmap built from the examples' ENGINE_FEEDBACK.json files
platforms/   packaging for Android (Gradle), iOS and the web, the store and ads backend plugins,
             the Windows installer and the AppImage files
```

## Documentation

Every page of `docs/` and `docs/design/` is linked here (a test checks it). The ones in `docs/` are built into the
binary, so an AI reads them with `factoria docs list` / `docs read` or the MCP `docs_*` tools; `docs/design/` is for people
working on the engine and stays out of the binary. The translations are in `docs/i18n/`.

### Making a game with an AI

Start with the first three; the AI guide is what an agent reads first.

- [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md): install, create a game, connect an AI.
- [docs/FIRST_GAME_WITH_AI.md](docs/FIRST_GAME_WITH_AI.md): tutorial for a person: your first game with an AI in the editor, step by step.
- [docs/MAKE_BY_HAND.md](docs/MAKE_BY_HAND.md): tutorial: make a small game by hand (scene, script, test, export) to see what the AI does for you.
- [docs/AI_GUIDE.md](docs/AI_GUIDE.md): how to build a game with FactorIA (for AI agents): the loop, the project layout, recipes by genre.
- [docs/SCRIPTING.md](docs/SCRIPTING.md): JavaScript scripting: behaviours, tools and tests.
- [docs/CLI.md](docs/CLI.md) and [docs/MCP.md](docs/MCP.md): the `factoria` CLI and the MCP server.
- [docs/reference/README.md](docs/reference/README.md): browsable API reference, one page per component and command category (generated).
- [docs/COMPONENTS.md](docs/COMPONENTS.md): every component and field in one file (generated, 1.8 MB, not in the binary: `docs.components` serves it per component).
- [docs/DEBUGGING.md](docs/DEBUGGING.md): debug scripts: breakpoints and stepping in VS Code (F5), `script.trace` for AIs.
- [docs/ENGINE_FEEDBACK.md](docs/ENGINE_FEEDBACK.md): how AIs record what the engine is missing.
- [docs/SKILLS.md](docs/SKILLS.md): Agent Skills: topic guides an AI loads when the work needs them.
- [docs/HOOKS.md](docs/HOOKS.md): hooks: programs or JavaScript modules that run before and after the AI's tool calls and the engine's commands, for every provider.
- [docs/EXTENDING.md](docs/EXTENDING.md): project tools (`tools/*.js`), native plugins, and (for engine developers) commands, components and systems.

Topics, one page each:

- 2D and 3D art: [docs/ASSETS.md](docs/ASSETS.md) (generate, import and ship art, sound and models; import settings and provenance), [docs/IMAGES.md](docs/IMAGES.md) (layered images), [docs/VECTOR.md](docs/VECTOR.md) (vector illustration and SVG import), [docs/MODELING.md](docs/MODELING.md) (3D models as data), [docs/RIGGING.md](docs/RIGGING.md) (skeletons for 3D models), [docs/ANIMATION.md](docs/ANIMATION.md) (skeletal and 2D clips, state machines, tweens).
- Look and feel: [docs/PARTICLES.md](docs/PARTICLES.md) (particle effects), [docs/EFFECTS.md](docs/EFFECTS.md) (visual and audio effects), [docs/GAME_FEEL.md](docs/GAME_FEEL.md) (shake, hit-stop, flash, knockback, squash and stretch), [docs/SHADERS.md](docs/SHADERS.md) (custom shaders per material), [docs/RENDERING.md](docs/RENDERING.md) (cameras that draw into textures, photographs of the world).
- Sound: [docs/SOUND.md](docs/SOUND.md) (sound patches and audio documents), [docs/MUSIC.md](docs/MUSIC.md) (songs as data).
- Text and menus: [docs/TEXT.md](docs/TEXT.md) (fonts, fallback, shaping, right-to-left text, text size), [docs/LOCALIZATION.md](docs/LOCALIZATION.md) (string tables, `key` fields, the `i18n` API), [docs/MENUS.md](docs/MENUS.md) (main menu, options, credits, loading screen, pause).
- World and services: [docs/NAVIGATION.md](docs/NAVIGATION.md) (navmeshes and agents), [docs/NETWORKING.md](docs/NETWORKING.md) (`http.fetch`), [docs/PLATFORM.md](docs/PLATFORM.md) (achievements, stats, leaderboards, cloud saves, purchases), [docs/ANALYTICS.md](docs/ANALYTICS.md) (events and remote config).

### Finishing and shipping a game

- [docs/FINISHING.md](docs/FINISHING.md): finish your game: menus, options, saves, languages, accessibility, store services, credits, tests, and a checklist.
- [docs/PERFORMANCE.md](docs/PERFORMANCE.md): frame time, memory and draw-call budgets: measure a game, keep a baseline per machine, fail CI on a regression.
- [docs/EXPORTING.md](docs/EXPORTING.md) and [docs/MOBILE.md](docs/MOBILE.md): exporting games, and iOS/Android.
- [docs/PUBLISHING.md](docs/PUBLISHING.md): publishing guide with one checklist per store (Steam, Epic, GOG, Microsoft Store, Google Play, App Store, itch.io, web).
- [docs/LEGAL.md](docs/LEGAL.md): privacy policy and EULA templates for a shipped game, and what the engine itself sends (nothing).

### Using the editor

- [docs/EDITOR.md](docs/EDITOR.md): the AI-first visual editor: viewport, AI chat, picking, audio log.
- [docs/AI_PROVIDERS.md](docs/AI_PROVIDERS.md): AI providers (Claude Code, Codex, API keys) and roles.
- [docs/AI_COSTS.md](docs/AI_COSTS.md): what making a game with AI costs (measured on a real game), what drives it, how to cap and check it.
- The tutorials above ([docs/FIRST_GAME_WITH_AI.md](docs/FIRST_GAME_WITH_AI.md)), [docs/HOOKS.md](docs/HOOKS.md) and [docs/SKILLS.md](docs/SKILLS.md) are for editor users too.

### Engine development

Read [CLAUDE.md](CLAUDE.md) and [docs/design/ARCHITECTURE.md](docs/design/ARCHITECTURE.md) first. These pages are not in the binary.

- [docs/design/ARCHITECTURE.md](docs/design/ARCHITECTURE.md): design, modules, conventions, commands, reflection, threads, loading, rendering, testing (split into pages: the file lists them).
- [docs/design/BUILDING.md](docs/design/BUILDING.md): platform requirements, presets, CI, tests, releases and troubleshooting (split into pages: the file lists them).
- [docs/EXTENDING.md](docs/EXTENDING.md): adding commands, components and systems (sections B to F, in docs/design/EXTENDING_*.md; A and G are for games).
- [docs/ENGINE_FEEDBACK.md](docs/ENGINE_FEEDBACK.md): "Collecting" and "Triage loop" are for engine developers.
- [docs/design/CUSTOM_SHADERS.md](docs/design/CUSTOM_SHADERS.md), [docs/design/CUSTOM_SHADERS_KINDS.md](docs/design/CUSTOM_SHADERS_KINDS.md), [docs/design/CUSTOM_SHADERS_FULL.md](docs/design/CUSTOM_SHADERS_FULL.md) and [docs/design/CUSTOM_SHADERS_PACKAGES.md](docs/design/CUSTOM_SHADERS_PACKAGES.md): design of custom shaders per material, of its sprite and sky kinds, of full shaders and passes for meshes, and its work packages.
- [docs/design/FEEDBACK_SHARING.md](docs/design/FEEDBACK_SHARING.md): design of sharing feedback with the engine developer.
- [docs/design/SCRIPT_DEBUGGER.md](docs/design/SCRIPT_DEBUGGER.md): design of the script debugger and its VS Code extension.
- [feedback/ROADMAP.md](feedback/ROADMAP.md) (open gaps and next milestones) and [CHANGELOG.md](CHANGELOG.md).

## License

FactorIA is open source under the [MIT License](LICENSE): use it, change it and ship games with it, free or
commercial, as long as the copyright notice and the license travel with the engine code.

- **Your games are yours.** The files `factoria new` puts in a project are [MIT-0](templates/LICENSE) (no notice
  needed). An exported game contains the FactorIA runtime, so `factoria export` writes `FACTORIA_NOTICES.txt` with the
  licenses of the engine and the third-party code inside it; keep it in what you ship
  ([docs/EXPORTING.md](docs/exporting/EXPORTING_CONTENTS.md#license-notices)).
- **Third-party code** in `external/` keeps its own license ([external/VERSIONS.md](external/VERSIONS.md) lists each
  one): mostly MIT, zlib or public domain, and also Apache-2.0 (Basis Universal, SheenBidi, Manifold), BSL-1.0
  (Clipper2) and BSD-3-Clause (V-HACD, and the encoder extras of Basis Universal). `factoria docs licenses` prints every
  notice; the downloads ship them as `THIRD_PARTY_NOTICES.txt`.
- **The name.** The license covers the code, not the FactorIA name or logo. Say that your game is "made with FactorIA";
  a modified or redistributed engine must not present itself as FactorIA, or as endorsed by it, without permission.
- **Conduct.** Issues, pull requests, discussions and the feedback server follow the
  [code of conduct](CODE_OF_CONDUCT.md).
