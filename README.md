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

Version 0.1, first milestone complete. All engine modules, the `factoria` CLI, the
MCP server, the AI hub and the editor work, and seven example games built by AI
agents through the public interface are part of the test suite. Three of them are complete games. Lantern Keep, a 2D
desktop platformer: menus, save slots, store services, accessibility options, four languages and store-ready settings.
Clockwork Courier, a 3D game made for phones first: touch controls, imported CC0 models and sounds, achievements,
purchases and a rewarded ad, comfort and accessibility options, English, Spanish and Japanese, and exports run on the
iOS Simulator, an Android emulator, a browser and macOS. Burrow Brigade, a 2D couch co-op game for up to four players
on the desktop and Steam: mines generated from a seed, enemies that chase through the dug tunnels, versioned save
slots, leaderboards and online features on test services, English, Russian and Thai, and Windows, Linux and macOS
exports.

CI builds and tests every pull request and every push to `main` on Linux, Windows
(MSVC) and macOS, builds the iOS Simulator app and the Android library and APK, and runs them on the iOS Simulator and
an Android emulator (not on real devices; see [docs/MOBILE.md](docs/MOBILE.md)). Open gaps and next milestones:
[feedback/ROADMAP.md](feedback/ROADMAP.md).

## Download

No compiler or dev tools needed. Download the latest version for your system once:
[Windows installer](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-windows-x64-setup.exe)
(or the [zip](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-windows-x64.zip)),
[macOS](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-macos-universal.tar.gz)
(Apple Silicon and Intel) or Linux ([tar.gz](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-linux-x64.tar.gz)
or [AppImage](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-linux-x64.AppImage)). Run the
installer, or unpack the zip / tar.gz into a folder of your choice, such as `C:\FactorIA` or `~/FactorIA`, and open the
editor:

- **Windows:** Start menu > **FactorIA Editor** (installer), or double-click `FactorIA-Editor.exe`. SmartScreen may
  stop it (always for an unsigned release): click **More info > Run anyway**.
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

## Quick start (build from source)

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

Platform requirements, presets and troubleshooting: [docs/BUILDING.md](docs/BUILDING.md).

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
docs/        documentation in English (included in the binary; AIs read it through MCP)
scripts/     build and environment setup for each operating system
templates/   project templates for `factoria new`
schemas/     JSON schemas for the project, ENGINE_FEEDBACK and AI configuration
examples/    example games made by AI agents, also used as integration tests
feedback/    roadmap built from the examples' ENGINE_FEEDBACK.json files
platforms/   packaging for Android (Gradle) and iOS
```

## Documentation

- [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md): build, create a game, connect an AI.
- [docs/AI_GUIDE.md](docs/AI_GUIDE.md): how to build a game with FactorIA (for AI agents).
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): design, modules, conventions, commands and reflection.
- [docs/SCRIPTING.md](docs/SCRIPTING.md): JavaScript scripting: behaviours, tools and tests.
- [docs/reference/README.md](docs/reference/README.md): browsable API reference, one page per component and command category (generated).
- [docs/COMPONENTS.md](docs/COMPONENTS.md): every component and field in one file (generated).
- [docs/DEBUGGING.md](docs/DEBUGGING.md): debug scripts: breakpoints and stepping in VS Code (F5), `script.trace` for AIs.
- [docs/RENDERING.md](docs/RENDERING.md): cameras that draw into textures (a screen on a model, a mirror, a book page whose buttons work) and off-screen photographs of the world at a pixel scale.
- [docs/SHADERS.md](docs/SHADERS.md): custom shaders per material: the material file, the GLSL snippet contract, five worked examples.
- [docs/EXTENDING.md](docs/EXTENDING.md): creating tools, commands, components and systems.
- [docs/CLI.md](docs/CLI.md) and [docs/MCP.md](docs/MCP.md): the `factoria` CLI and the MCP server.
- [docs/EDITOR.md](docs/EDITOR.md): the AI-first visual editor: viewport, AI chat, picking, audio log.
- [docs/AI_PROVIDERS.md](docs/AI_PROVIDERS.md): AI providers (Claude Code, Codex, API keys) and roles.
- [docs/ASSETS.md](docs/ASSETS.md): generating and importing art, sound and models; import settings and provenance.
- [docs/TEXT.md](docs/TEXT.md): fonts per language, fallback fonts, shaping, right-to-left text, wrapping and the text size option.
- [docs/ENGINE_FEEDBACK.md](docs/ENGINE_FEEDBACK.md): how AIs record what the engine is missing.
- [docs/BUILDING.md](docs/BUILDING.md): platform requirements, presets, CI, tests and troubleshooting.
- [docs/MOBILE.md](docs/MOBILE.md) and [docs/EXPORTING.md](docs/EXPORTING.md): iOS/Android and exporting games.
- [docs/FIRST_GAME_WITH_AI.md](docs/FIRST_GAME_WITH_AI.md): tutorial for a person: your first game with an AI in the editor, step by step.
- [docs/MAKE_BY_HAND.md](docs/MAKE_BY_HAND.md): tutorial: make a small game by hand (scene, script, test, export) to see what the AI does for you.
- [docs/PUBLISHING.md](docs/PUBLISHING.md): publishing guide with one checklist per store (Steam, Epic, GOG, Microsoft Store, Google Play, App Store, itch.io, web).
- [docs/LEGAL.md](docs/LEGAL.md): privacy policy and EULA templates for a shipped game, and what the engine itself sends (nothing).
- [docs/LOCALIZATION.md](docs/LOCALIZATION.md): several languages: string tables, `key` fields, the `i18n` script API.
- [docs/AI_COSTS.md](docs/AI_COSTS.md): what making a game with AI costs (measured on a real game), what drives it, how to cap and check it.
- [docs/PERFORMANCE.md](docs/PERFORMANCE.md): frame time, memory and draw-call budgets: measure a game, keep a baseline per machine, fail CI on a regression.
- [docs/FINISHING.md](docs/FINISHING.md): finish your game: menus, options, saves, languages, accessibility, store services, credits, tests, and a checklist.

If you are going to modify the engine, read [CLAUDE.md](CLAUDE.md) and
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) first.

## License

FactorIA is open source under the [MIT License](LICENSE): use it, change it and ship games with it, free or
commercial, as long as the copyright notice and the license travel with the engine code.

- **Your games are yours.** The files `factoria new` puts in a project are [MIT-0](templates/LICENSE) (no notice
  needed). An exported game contains the FactorIA runtime, so `factoria export` writes `FACTORIA_NOTICES.txt` with the
  licenses of the engine and the third-party code inside it; keep it in what you ship
  ([docs/EXPORTING.md](docs/EXPORTING.md#license-notices)).
- **Third-party code** in `external/` keeps its own license ([external/VERSIONS.md](external/VERSIONS.md); all MIT,
  zlib or public domain). `factoria docs licenses` prints every notice; the downloads ship them as
  `THIRD_PARTY_NOTICES.txt`.
- **The name.** The license covers the code, not the FactorIA name or logo. Say that your game is "made with FactorIA";
  a modified or redistributed engine must not present itself as FactorIA, or as endorsed by it, without permission.
