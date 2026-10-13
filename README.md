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
MCP server, the AI hub and the editor work, and four example games built by AI
agents through the public interface are part of the test suite.

CI builds and tests every pull request and every push to `main` on Linux, Windows
(MSVC) and macOS, and builds the iOS Simulator app and the Android library and APK. iOS and Android are not run on
devices or emulators in CI yet. Open gaps and next milestones:
[feedback/ROADMAP.md](feedback/ROADMAP.md).

## Quick start

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
- [docs/COMPONENTS.md](docs/COMPONENTS.md): every component and field (generated).
- [docs/EXTENDING.md](docs/EXTENDING.md): creating tools, commands, components and systems.
- [docs/CLI.md](docs/CLI.md) and [docs/MCP.md](docs/MCP.md): the `factoria` CLI and the MCP server.
- [docs/AI_PROVIDERS.md](docs/AI_PROVIDERS.md): AI providers (Claude Code, Codex, API keys) and roles.
- [docs/ENGINE_FEEDBACK.md](docs/ENGINE_FEEDBACK.md): how AIs record what the engine is missing.
- [docs/BUILDING.md](docs/BUILDING.md): platform requirements, presets, CI, tests and troubleshooting.
- [docs/MOBILE.md](docs/MOBILE.md) and [docs/EXPORTING.md](docs/EXPORTING.md): iOS/Android and exporting games.

If you are going to modify the engine, read [CLAUDE.md](CLAUDE.md) and
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) first.
