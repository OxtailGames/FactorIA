# Getting started with FactorIA

**English** | [Español](i18n/es/GETTING_STARTED.md)

> AI agents: read [AI_GUIDE.md](AI_GUIDE.md) first, the complete English guide for building a game (also available as `factoria docs read ai-guide`).

FactorIA is a 2D and 3D game engine in C++20 designed so that an AI can create games without depending on a graphical editor. Scenes are JSON, game logic is written in JavaScript, and each engine capability is a command the AI can invoke. This guide explains how to install the engine (download it or build it), create a game and connect an AI.

> **Project status.** It is in early development. On Linux the full workflow works: create a project, validate it, test it, simulate it without a window with screenshots, export it and connect an AI over MCP. CI builds and tests the engine on Windows (MSVC) and macOS (Metal, the editor included), and runs the iOS app on the iOS Simulator and an exported Android APK on an x86_64 emulator on every push; the mobile builds have not run on a real device yet (see `docs/MOBILE.md`). Section 8 summarizes what works and what is missing.

## 1. Requirements and installation

### Download (no build tools)

Download the package for your desktop system once; the editor keeps it up to date (see [Updates](#updates)). These
links always give the newest release; the [Releases page](https://github.com/OxtailGames/FactorIA/releases) has every
version.

| System | Download | What it is |
|---|---|---|
| Windows | [FactorIA-windows-x64-setup.exe](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-windows-x64-setup.exe) | Installer: for your user only (no administrator password), adds a Start menu entry and puts `factoria` on your PATH. |
| Windows | [FactorIA-windows-x64.zip](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-windows-x64.zip) | The same files to unzip anywhere. |
| macOS | [FactorIA-macos-universal.tar.gz](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-macos-universal.tar.gz) | Apple Silicon and Intel Macs. |
| Linux | [FactorIA-linux-x64.tar.gz](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-linux-x64.tar.gz) | The files to unpack anywhere. |
| Linux | [FactorIA-linux-x64.AppImage](https://github.com/OxtailGames/FactorIA/releases/latest/download/FactorIA-linux-x64.AppImage) | The same files in one executable file. |

The package holds one folder, `FactorIA`, with `factoria` (CLI, editor, MCP server and AI), `factoria_player` (the
runtime that `factoria export` copies into your game), `mobile/` (the ready-made Android runtime in every package, the
iOS libraries in the macOS one; see item 5), `LICENSE` and `THIRD_PARTY_NOTICES.txt` (FactorIA is MIT-licensed; your
games are yours, see README, "License") and, on Windows, `FactorIA-Editor.exe`. The docs, templates and schemas are
built into `factoria`, and on Windows the C++ runtime is too, so a fresh PC needs nothing else.

1. Install it:
   - **Windows installer:** run `FactorIA-windows-x64-setup.exe`. It installs into
     `%LOCALAPPDATA%\Programs\FactorIA` (a folder you can write to, which the updater needs), adds **FactorIA Editor**
     to the Start menu and adds the folder to your user PATH. Uninstall it from Settings > Apps.
   - **Zip or tar.gz:** unpack the package into a folder of your choice, for example `C:\FactorIA` or `~/FactorIA`.
   - **AppImage:** `chmod +x FactorIA-linux-x64.AppImage`. It runs where the tar.gz does.
2. Open the editor:
   - **Windows:** Start menu > **FactorIA Editor** (installer), or double-click `FactorIA-Editor.exe`. Windows
     SmartScreen may show "Windows protected your PC": it always does for an unsigned release, and for a signed one
     until enough people have downloaded it. Click **More info**, then **Run anyway**.
   - **macOS:** open Terminal in the folder and run `./factoria editor`. Releases after 0.1.3 are signed and notarized
     by Apple and open without a warning (the very first run needs internet: Gatekeeper looks the notarization up).
     0.1.3 and earlier are not notarized: your browser quarantines the download (unpacking it in Finder or with `tar`
     keeps the quarantine), so Gatekeeper stops each of its programs the first time. Quickest: remove the quarantine from the whole folder once, before the first
     run: `xattr -dr com.apple.quarantine ~/FactorIA`. Or allow `factoria` alone: when macOS says it could not verify
     it, click **Done**, open System Settings > Privacy & Security, click **Open Anyway** next to the message about
     `factoria`, run it again and confirm **Open Anyway** (macOS 14 and earlier: right-click `factoria` in Finder >
     **Open**). The games `factoria` exports then run without asking; `factoria_player` itself would need the same
     approval, but you never run it directly.
   - **Linux:** run `./factoria editor` in the folder. It needs X11 and OpenGL, which desktop distributions include,
     and glibc 2.31 or newer: Ubuntu 20.04 and newer, Debian 11 and newer, Fedora, Arch... and the Steam Linux
     Runtime "sniper" (the programs are built in it, so the games you export run in Steam too, also on the Steam Deck).
     The AI assistant and AI asset generation also need the `curl` program, which most distributions install.
   - **Linux AppImage:** run `./FactorIA-linux-x64.AppImage`. Without arguments it opens the editor; with arguments it
     is the `factoria` command (`./FactorIA-linux-x64.AppImage new my-game`; `editor my-game` opens that project).
     If it cannot mount itself (no FUSE), run it as `./FactorIA-linux-x64.AppImage --appimage-extract-and-run`. It does
     not update itself: download the newer one.
3. The AI assistant needs Claude Code (or Codex) installed and signed in, or an API key: see
   [section 6](#6-connect-an-ai). Inside the editor nothing else is needed, because the editor serves the MCP tools
   itself.
4. To use Claude Code from a terminal outside the editor, put `factoria` on your PATH. The `.mcp.json` that
   `factoria new` writes starts the bare `factoria` command, so the terminal has to find it. The Windows installer
   already did it. Otherwise add the folder, then open a new terminal:
   - Windows (PowerShell):
     `[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';C:\FactorIA', 'User')`
   - macOS (zsh) or Linux (bash): `echo 'export PATH="$HOME/FactorIA:$PATH"' >> ~/.zshrc` (Linux: `~/.bashrc`)
   - AppImage: a link named `factoria` is the command itself:
     `ln -s ~/Downloads/FactorIA-linux-x64.AppImage ~/.local/bin/factoria`
5. Export (`factoria export`) works from the download for desktop and mobile. Android needs the JDK 17 and the
   Android SDK (no NDK, no CMake, no separate Gradle): the `mobile/` folder next to `factoria` holds the engine's Android
   runtime, so the export only packages it and builds the APK itself (`factoria export --platform android`). iOS (on a Mac, with Xcode and CMake) uses the iOS libraries of the macOS
   package the same way. No engine source is involved; see [EXPORTING.md](EXPORTING.md#mobile-exports-prebuilt-or-source)
   and [MOBILE.md](MOBILE.md). Build from source if you want to change the engine itself.

#### Updates

When the editor opens, it asks GitHub whether a newer release is out. If one is, a window shows the release notes of
every version newer than yours, and the editor waits for your answer:

- **Update** downloads the package for your system, replaces the files in the FactorIA folder and reopens the editor
  on the project you had open (if the scene has unsaved changes, it asks first). The replaced files stay as
  `<name>.old` until the next start, which deletes them.
- **Not now** keeps your version. The editor asks again the next time it opens.

Offline, or when GitHub does not answer, the editor opens as usual and the Console says why. The FactorIA folder must
be one you can write to (not `C:\Program Files`). To go back to an older version, download it from the Releases page.
Builds from source never update: pull and rebuild instead.

- A copy made by the Windows installer updates like an unzipped one, in its own folder. The uninstaller keeps working
  (the update only replaces the files of the package), but Settings > Apps keeps showing the version you installed.
  Running a newer installer over it also works.
- The Linux AppImage never checks for updates: its files are a read-only mount that cannot be replaced. Download the
  newer AppImage instead.
- On macOS the package is `FactorIA-macos-universal.tar.gz` (Apple Silicon and Intel). The Releases page also has the
  same file as `FactorIA-macos-arm64.tar.gz`, the name that editors up to 0.1.2 look for, so they can still update.

### Build from source

You need CMake 3.24 or later and a C++20 compiler. On Linux and macOS the presets use Ninja. Third-party libraries are bundled in `external/`, so there are no separate dependencies to download, except the SDKs for each platform.

### Linux (Debian or Ubuntu)

```bash
./scripts/bootstrap-linux.sh      # installs the compiler, CMake, Ninja and the required libraries (can be run again)
./scripts/build.sh debug --test   # configures, builds and runs the tests
```

The script only works on systems with `apt` (Debian and Ubuntu) and uses `sudo` if you are not root. On other distributions it stops and prints the equivalent packages for Fedora and Arch; install those same components with your package manager, then run `./scripts/build.sh debug --test`.

### macOS

```bash
./scripts/bootstrap-macos.sh
./scripts/build.sh debug --test
```

You need the Xcode Command Line Tools (`xcode-select --install`). For iOS, the full Xcode is required.

### Windows

1. Install Visual Studio 2022 with the *Desktop development with C++* workload. The Community edition works, and so do
   the Build Tools. CMake comes with it: the script finds it even though it is not on your PATH.
2. Clone the repository into a short folder, such as `C:\src\FactorIA`: Windows stops at 259 characters per path, and the
   script warns when the folder is too deep for a build to fit.
3. From the repository root, in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Test
```

To build with Ninja (`windows-ninja-debug`), install Ninja and run the script from *Developer PowerShell for VS 2022*, which puts `cl.exe` on the PATH:

```powershell
winget install Ninja-build.Ninja
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Preset windows-ninja-debug -Test
```

### iOS and Android

```bash
./scripts/build-ios.sh --simulator    # iOS Simulator; requires full Xcode
./scripts/build-android.sh            # Android arm64; requires NDK r26 or later and ANDROID_NDK_HOME
```

### Presets

Each build goes to `build/<preset>/`. To see the presets that work on your machine, run `cmake --list-presets`.

| Preset | System | Use |
|---|---|---|
| `linux-debug`, `linux-release` | Linux | Development and release |
| `macos-debug`, `macos-release` | macOS | Development and release |
| `windows-debug`, `windows-release` | Windows (Visual Studio 2022) | Development and release |
| `windows-ninja-debug` | Windows (Ninja with `cl`) | From Developer PowerShell |
| `ios`, `ios-simulator` | macOS with Xcode | Device and simulator |
| `android-arm64`, `android-x86_64` | Any machine with the NDK | Device and emulator |

To build without the scripts:

```bash
cmake --preset linux-debug
cmake --build --preset linux-debug
ctest --preset linux-debug
```

If the machine runs out of memory, limit the number of parallel jobs: `cmake --build --preset linux-debug -- -j 2`.

### Common problems

- **`Could not use disabled preset`**: the preset belongs to another operating system. Use `cmake --list-presets`.
- **`Does not match the generator used previously: Ninja`**: delete `build/<preset>` and configure again.
- **CMake too old**: install CMake 3.24 or later from cmake.org.
- **`Could NOT find X11` or `OpenGL` (Linux)**: run `./scripts/bootstrap-linux.sh`.
- **Headless tests fail without a display (Linux)**: run them with a virtual display server: `xvfb-run -a -s "-screen 0 1280x720x24" ctest --preset linux-debug`.
- **`cl.exe not found`**: use *Developer PowerShell for VS 2022*.
- **`running scripts is disabled on this system`**: run the script with `-ExecutionPolicy Bypass`.

More details in `docs/BUILDING.md`.

## 2. Create your first game

With the `factoria` CLI, you create a project from a template:

```bash
factoria new my-game --template 2d-platformer
cd my-game
```

Available templates:

- `2d-empty`: an empty 2D scene with only a camera. Start from scratch.
- `2d-platformer`: platforms with physics, coins, a score counter and a camera that follows the player.
- `3d-empty`: an empty 3D scene with only a perspective camera.

`factoria templates` lists the available templates with their descriptions.

The project contains:

- `factoria.json`: display, physics and control settings.
- `scenes/`: levels in JSON.
- `scripts/`: behaviors in JavaScript.
- `tools/`: project tools the AI can invoke.
- `tests/`: headless tests.
- `types/factoria.d.ts`: types for the scripting API, generated by the engine.
- `AGENTS.md`: a short guide for the AI.
- `ENGINE_FEEDBACK.json`: what the engine was missing (section 7).
- `.mcp.json`: connection to Claude Code.
- `jsconfig.json`: type checking for the JavaScript.

## 3. Run the game

```bash
factoria run
```

A window opens with the game. The controls are defined in `factoria.json`, under `input.actions`:

- `2d-empty`: nothing moves yet; the actions `move_left/right/up/down` (A, D, W, S or the arrows) and `action` are ready.
- `2d-platformer`: A and D or the arrow keys to move; Space, W or the up arrow to jump.
- `3d-empty`: nothing moves yet; the actions for W/S, A/D, E/Space and Q/LeftShift (`move_forward`, `move_back`, `move_left`, `move_right`, `move_up`, `move_down`) are ready.

## 4. Headless mode and screenshots

In headless mode the game advances without opening any window. It only draws the screenshots you ask for and the last frame, so it is fast. The result is deterministic: the same seed and the same inputs produce the same frames.

```bash
factoria run --headless --frames 120 --screenshot-at 119
```

- Simulates 120 frames, that is, 2 seconds of gameplay at 60 frames per second.
- Saves a screenshot in `.factoria/screenshots/`, by default `frame_119.png`. Open it and check that it shows what you expected.
- Frames start at 0, and the screenshot of frame N is taken after simulating it. That is why, with 120 frames, the screenshot is frame 119.
- `--state-out out.json` saves the world state as JSON: entities, components, logs and errors.
- `--record-audio out.wav` saves the mixed sound, so you can check that the game has sound.
- `--input replay.json` applies a sequence of presses frame by frame (actions, keys, mouse, gamepad and touch), for example `{"frames": {"0": {"press": ["jump"]}, "30": {"release": ["jump"]}}}`.
- For a single screenshot, `factoria screenshot --frames 120 --out shot.png` simulates the given frames and saves the image.
- `--json` prints the report as JSON, including the screenshot paths.

## 5. Validation and tests

```bash
factoria validate    # checks the project: JSON, scenes, assets, controls and scripts
factoria test        # runs tests/*.test.js without a window
```

`factoria validate --fix-types` regenerates `types/factoria.d.ts` from the engine's API.

A test looks like this (it assumes a scene with an entity `player` that moves with `move_right`):

```js
import { test, expect, game } from "factoria:test";

test("player moves right while move_right is held", () => {
  game.load("scenes/main.scene.json");
  const player = game.find("player");
  const x0 = player.position.x;
  game.press("move_right");
  game.step(30); // 0.5 s at 60 Hz
  game.release("move_right");
  expect(player.position.x).toBeGreaterThan(x0 + 100);
});
```

Each test file runs in a fresh engine with the project's seed, so the results are reproducible.

## 6. Connect an AI

There are two ways to work with an AI inside FactorIA. You can combine them.

| | Subscription via the official CLI | API key |
|---|---|---|
| What you use | Claude Code (Claude) or Codex (ChatGPT) | The built-in AI of `factoria ai` (Anthropic or other providers) |
| Who runs the agent loop | The CLI itself | FactorIA |
| What you pay | Your current Claude or ChatGPT plan | Tokens, billed by the provider |
| Where credentials live | In the CLI, under your sign-in | In an environment variable or in `~/.factoria/ai.json` |

FactorIA never reads, stores or forwards the credentials of your subscription. It only launches the official CLI that you install and connects its MCP server to it.

### Option A: Claude Code or Codex with your subscription (MCP)

**Claude Code**

1. Install the CLI and sign in once:

```bash
npm i -g @anthropic-ai/claude-code
claude
```

2. `factoria new` creates a `.mcp.json` file in the project with this configuration:

```json
{ "mcpServers": { "factoria": { "command": "factoria", "args": ["mcp", "--project", "."] } } }
```

If your project does not have a `.mcp.json`, add the same server with:

```bash
claude mcp add factoria -- factoria mcp --project .
```

3. Open `claude` inside the game folder. The first time, it may ask you to approve the `factoria` server.
4. Ask for the work in natural language, for example: "Read AGENTS.md and add an enemy that chases the player."

**Codex**

1. Install the CLI and sign in with your ChatGPT account:

```bash
npm i -g @openai/codex
codex login
```

2. Add the server to `~/.codex/config.toml`:

```toml
[mcp_servers.factoria]
command = "factoria"
args = ["mcp", "--project", "/path/to/my-game"]
```

The MCP server exposes each command as a tool, the documentation as `factoria://docs/...` resources, and screenshots as images. It also includes the prompts `make-game`, `add-feature`, `fix-bug` and `report-engine-gap`, which guide the AI step by step. The client usually starts it for you. To debug it, you can start it by hand with `factoria mcp --project my-game`.

### Option B: Built-in AI with an API key

`factoria ai doctor` and `factoria ai providers` do not need a key: they show which providers are ready on your machine.

1. Store your key in an environment variable. Never put it inside a project:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
```

If you have the `ant` CLI installed and have signed in with `ant auth login`, FactorIA can also use it.

2. Optional: create `~/.factoria/ai.json` to set the limits for each run. On Windows, the path is `%APPDATA%\factoria\ai.json`:

```json
{
  "limits": { "maxTurns": 40, "maxCostUsd": 5 }
}
```

Without this file, Anthropic's default values are used.

3. Check what is available. The command shows the CLIs and keys it finds, without printing any key:

```bash
factoria ai doctor
```

4. Ask for a task:

```bash
factoria ai run "Add a coin counter on screen"
```

Each task uses a role. In `~/.factoria/ai.json` you can assign a provider and a model to each one (in the editor: the
**Roles...** button of the AI panel). Your requests go to the orchestrator, which hands work to the other two by itself:

| Role (key in the file) | What it is for | Default (Anthropic) |
|---|---|---|
| Orchestrator (`orchestrator`) | Plans, reviews and delegates | `claude-opus-5-5`, effort `xhigh` |
| Worker (`worker`) | Implements features and fixes | `claude-sonnet-5-5`, effort `medium` |
| Fast (`fast`) | Small, mechanical changes | `claude-haiku-5-5`, effort `max` |

`factoria ai run` uses the orchestrator role unless you pass another one with `--role orchestrator|worker|fast`. You can also choose the provider and model with `--provider` and `--model`, and limit the run with `--max-turns` and `--max-cost` (in dollars).

The `maxTurns` (number of steps) and `maxCostUsd` (maximum cost in dollars) limits stop a run when they are reached. Cost figures are estimates: the provider's invoice is what counts.

FactorIA only reads keys from environment variables or from `~/.factoria/ai.json`. If it finds something that looks like a key inside a project, it warns you. To use a local model, such as Ollama or LM Studio, configure an OpenAI-compatible provider (see `docs/AI_PROVIDERS.md`). That way, the content never leaves your machine.

## 7. ENGINE_FEEDBACK.json in plain words

Each game has an `ENGINE_FEEDBACK.json` file at its root. In it, the AI notes what the engine was missing (a function, a command or a piece of documentation) and how it worked around it.

- **What it is for.** The FactorIA team collects these files from many games. Whatever keeps appearing moves up the list of things to build. That is how the engine improves through real use.
- **What the AI does.** As soon as something is missing, it calls the `feedback_report` tool (MCP). Without MCP, it uses `factoria feedback add` or edits the file by hand. If the same gap comes up again, the entry is not duplicated: a case is added to it.
- **What you have to do.** Nothing. You can read it whenever you want. It is plain text, and you can edit it or delete entries.
- **Privacy.** The file is not sent anywhere on its own. When you use the built-in AI with an API, the titles of these entries are part of what is sent to the provider (see `docs/AI_PROVIDERS.md`).

Example entry:

```json
{
  "category": "input",
  "severity": "minor",
  "title": "No gamepad rumble",
  "missing": "The game wants to vibrate the controller when the player is hit, but scripts have no rumble API.",
  "workaround": "none: feature dropped. A hit is shown with a screen shake only.",
  "workaroundFiles": [],
  "suggestion": "Add input.gamepad(i).rumble(strong, weak, seconds) that vibrates the pad.",
  "effort": "small"
}
```

What each field means:

- `category`: the engine area affected, for example `physics`, `audio` or `scene`.
- `severity`: `blocker` (the game could not be built), `major` (a large or fragile workaround), `minor` (a small workaround) or `nice-to-have` (would be more convenient).
- `title`: a short name for the gap. Always use the same words for the same gap.
- `missing`: what was missing.
- `workaround`: how it was worked around, and in which files.
- `suggestion`: what the engine should do.

Keys and fixed values (`category`, `severity`) are in English, as in the example. Free text can be written in any language. `factoria validate` fails if the file is missing or does not match the `schemas/engine-feedback.schema.json` schema.

## 8. What works and what is missing

| Part | Status |
|---|---|
| Build on Linux (`./scripts/build.sh`) | Tested |
| Build on Windows, macOS, iOS and Android | Built by CI on every push. Windows (MSVC) and macOS run the test suite (macOS includes the GPU tests on Metal and the editor autotests); the iOS app runs on the iOS Simulator and the Android APK on an x86_64 emulator, and each must render the game; not yet run on a real device (`docs/MOBILE.md`) |
| Engine: scenes, JavaScript scripts, 2D and 3D rendering, physics (including one-way platforms and tilemaps), particles and screenshots | Works on Linux, Windows (Direct3D 11) and macOS (Metal). Text draws Latin, Greek, Cyrillic, Hebrew and Arabic with the built-in font, shaped and right to left where needed; other scripts need a font the game ships (`docs/TEXT.md`). Games can be translated into several languages (`docs/LOCALIZATION.md`). Audio has not been tested in the documentation environment |
| `factoria` CLI: `new`, `templates`, `run`, `screenshot`, `test`, `validate`, `call`, `session`, `commands`, `api`, `mcp`, `ai`, `feedback`, `docs`, `export`, `setup` | Works on Linux, Windows and macOS |
| `factoria editor` (visual editor) | Included in the desktop builds (`docs/EDITOR.md`). Needs a display. The ctest entries `editor_autotest` drive it end to end on Linux (under `xvfb-run`) and macOS |
| Project templates (`factoria new`): `2d-empty`, `2d-platformer`, `3d-empty` | Works |
| MCP server for Claude Code and Codex (`factoria mcp`) | Works |
| Built-in AI with an API key (`factoria ai`) | `doctor`, `providers` and `config` work. `ai run` needs an API key or an installed CLI (Claude Code or Codex) |
| Exporting games (`factoria export`) | Linux tested (`--platform linux`); CI exports an Android game and builds its APK. Windows, macOS, Android and iOS: see `docs/EXPORTING.md` and `docs/MOBILE.md` |
| Documentation for AI | In English: `docs/AI_GUIDE.md`, `factoria docs read ai-guide` |
| Gamepads | Bindings (`GamepadA`, `GamepadLeftStickLeft`, ...), `input.gamepad(i)` and `game.gamepad(i)` in tests. Real pads: Windows (XInput), Linux (joystick API; the Linux lines of SDL's GameControllerDB are built in, extra lines go in `SDL_GAMECONTROLLERCONFIG` or a `gamecontrollerdb.txt` next to `factoria.json`), macOS/iOS (GameController) and Android; all compiled by CI, none tested with a physical pad yet. The web build has none (`docs/MOBILE.md`, `docs/SCRIPTING.md`) |

## 9. Where to read next

- `factoria help <command>` shows the help and examples for each command. `docs/CLI.md` describes all commands and options.
- `docs/AI_GUIDE.md` (in English): the complete guide for an AI that builds a game. If you are an AI, read it before touching a game. It is also available with `factoria docs read ai-guide`.
- `docs/ARCHITECTURE.md`: design, modules and conventions.
- `docs/SCRIPTING.md`: the JavaScript API: behaviors, tools and tests.
- `docs/EXTENDING.md`: how to add project tools and engine commands.
- `docs/MCP.md`, `docs/AI_PROVIDERS.md` and `docs/ENGINE_FEEDBACK.md`: connecting AI and recording what the engine is missing.
- `docs/BUILDING.md`: requirements and builds per platform.
- `docs/EXPORTING.md` and `docs/MOBILE.md`: exporting games and building them for mobile.
