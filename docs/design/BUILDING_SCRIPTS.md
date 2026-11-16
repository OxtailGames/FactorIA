# Building FactorIA: build scripts and presets

Part of [Building FactorIA](BUILDING.md) (the entry page lists every page).

## One command per platform

### Linux and macOS: `scripts/build.sh`

```bash
./scripts/build.sh [debug|release] [--test] [--preset NAME]
```

- `debug` is the default. `release` builds the optimized configuration.
- `--test` runs the test suite (ctest) after the build.
- `--preset NAME` uses a different preset, for example `ios-simulator` on a Mac.

The script picks `linux-<config>` or `macos-<config>` from the host, configures,
builds, and tests. When a step fails, it prints an `error:` line that names the
step and the preset, then exits with status 1.

### Windows: `scripts/build.ps1`

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 [debug|release] [-Test] [-Preset NAME]
```

The default preset is `windows-debug` or `windows-release` (Visual Studio 2022,
x64). Use `-Preset windows-ninja-debug` from "Developer PowerShell for VS 2022",
which puts `cl.exe` on the path.

**CMake.** The script uses the `cmake` on `PATH` when it is 3.24 or newer. Otherwise it asks `vswhere` (installed with
Visual Studio and its Build Tools) for the CMake that Visual Studio carries
(`Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe`, from the component "C++ CMake tools for Windows",
part of the workload "Desktop development with C++"; Visual Studio 2022 first), puts its folder first on `PATH` for the
script's own commands (`cmake` and `ctest`), and prints which one it uses:
`==> cmake: C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\...\cmake.exe (CMake 3.31.6, installed by Visual Studio, found with vswhere)`.
So a machine whose only CMake is Visual Studio's builds with no setup. With none at all it stops and names the two
ways to get one (the Visual Studio workload, or `winget install Kitware.CMake`).

**Long paths.** Windows tools stop at 259 characters per path (MAX_PATH), and a Visual Studio build writes files as
deep as `build\windows-debug\platforms\plugins\steam\tests\fa_steam_mock_current.dir\Debug\fa_steam.B4D08805.tlog\...`:
143 characters below the repository root in Release, 141 in Debug. The script warns (and builds anyway) when the
checkout's own path is longer than 114 characters, because MSBuild fails then, with `FTK1011` ("The specified path, file
name, or both are too long"), with `C1083` from the compiler, or already while CMake identifies the compiler
(`No CMAKE_C_COMPILER could be found`). Clone to a short path such as `C:\src\FactorIA`. Enabling Windows long paths
(`LongPathsEnabled=1` under `HKLM\SYSTEM\CurrentControlSet\Control\FileSystem`, and `git config --system
core.longpaths true`) helps the tools that support it, but not all of them do: a 207-character checkout path failed at
the compiler identification on a machine that had it enabled, so a short path is the fix that always works.

`factoria_player.exe` carries a placeholder icon (`player/windows/factoria_player.rc` and `.ico`, compiled in by MSVC's
`rc` or MinGW's `windres`, both found by CMake with no setup). A game export overwrites its images with the game's icon
([EXPORTING.md](../exporting/EXPORTING_DESKTOP.md#icon-and-settings-per-platform)), so the file must keep its seven BMP images (16, 24, 32, 48,
64, 128 and 256 px). To change the drawing, edit `draw_placeholder_icon` in `tools/common/tests/placeholder_icon_test.cpp`
and regenerate the committed file on any OS:
`FA_REGEN_PLACEHOLDER_ICON=1 build/<preset>/tools/common/fa_test_tooling -tc="placeholder icon*"`.

### Windows, short output: `scripts/agent-build.ps1`

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\agent-build.ps1 <build dir> [-Target t1,t2] [-Test] [-Tests REGEX] [-Examples | -ExamplesOnly] [-Jobs 8]
```

Made for AI agents, and handy for anyone who wants a Debug build from any shell (PowerShell, cmd, Git Bash). It loads
the Visual Studio 2022 C++ environment when `cl.exe` is not on the path, configures the directory with the
`windows-ninja-debug` preset the first time, builds it (`-Jobs`, default 8) and, with `-Test` (every test) or `-Tests`
(`ctest -R`), runs the tests serially as CI does. The full output goes to `agent-configure.log`, `agent-build.log` and
`agent-ctest.log` in the build directory; the console shows only the errors, each distinct warning once, every failing
test with its output, and the summary. Exit status 0 means everything passed. `-Examples` adds, after the Debug part, a
Release build of `factoria` in `<build dir>-release` and `ctest -L example` (the example games, see "Running tests" in [BUILDING_TESTS.md](BUILDING_TESTS.md#running-tests));
`-Test -Examples` is the full check before a push, `-ExamplesOnly` skips the Debug part.

Like `agent-build.sh` below, at most three jobs build or test at once on one machine, counting every checkout and worktree
of the user (`FA_AGENT_MAX_JOBS`, default 3). A job past the limit prints `waiting for a build slot (3 jobs at most;
running: <build dirs>)` once (the build dirs are relative to the repository root when they are inside it), polls every
five seconds and, once it has a slot, prints `waited N s for a build slot (3 jobs at most)` (N is the whole seconds
waited). A slot is the file `slot-<n>.lock` in `%LOCALAPPDATA%\factoria\agent-build-slots` (`$HOME\.cache\factoria\agent-build-slots`
when `LOCALAPPDATA` is not set; `FA_AGENT_SLOTS_DIR` replaces either, and a relative one is taken from the repository
root), held open without sharing for the whole run. Windows closes it when the process ends, however it ends, so a
killed or crashed job never leaves a slot taken. Killing only the PowerShell process leaves `cmd`, `ninja` and `cl`
running while the slot is already free, so the limit can be exceeded for a while: stop the whole process tree.
The script waits synchronously, so the wait counts against the timeout of whoever started it (`-TimeoutSeconds` of
`windows-run-interactive.ps1`, the timeout of a tool): with all slots busy a job may be stopped before it began.
The Linux and Android jobs in WSL run `agent-build.sh`, which keeps its own count in `~/.cache` of the WSL distribution,
apart from this pool: one PC can run the limit in each of them. `-Jobs` is not divided by the limit (default 8).

### Linux and macOS, short output: `scripts/agent-build.sh`

```bash
scripts/agent-build.sh <build dir> [--target t1,t2] [--test | --tests REGEX] [--examples | --examples-only] [--jobs 8]
scripts/agent-build.sh <build dir> --wait | --status | --stop
```

The same idea for Linux and macOS, made for AI agents. It configures the directory the first time (Ninja, Debug; CMake
finds ccache itself), builds it and, with `--test` (every test) or `--tests` (`ctest -R`), runs the tests three at a
time (`--ctest-jobs`). The full output goes to `agent-configure.log`, `agent-build.log` and `agent-ctest.log` in the
build directory. The console shows, with paths relative to the checkout:

- the errors of a failed configure or build (at most 40 lines);
- each distinct warning of the files the branch changes compared with `origin/main` (committed or not), and one line
  with the count of the warnings in the rest of the tree, so a new warning is not lost among the old ones;
- every failing test with its output: at most 80 lines, and without the engine's log lines when it is a doctest program
  (the cases that provoke an error on purpose fill the output with them);
- ctest's summary and the time of each step.

`--examples` adds a Release build of `factoria` in `<build dir>-release` and `ctest -L example`; `--test --examples` is
the full check before a push, `--examples-only` skips the Debug part.

At most three jobs build or test at once on one machine, counting every checkout and worktree of the user
(`FA_AGENT_MAX_JOBS`, default 3): twelve agents building side by side once left a 10-core Mac unusable until it was
restarted. A job past the limit waits for a free slot and `--wait` shows `RUNNING (waiting for a build slot ...)` with
the build dirs that hold them. A slot is a directory in `~/.cache/factoria/agent-build-slots` (`FA_AGENT_SLOTS_DIR`)
naming its job; one whose job no longer runs (killed, machine restarted) is taken over. The default `-j` is the job's
share of the cores (CPU count / `FA_AGENT_MAX_JOBS`, 2 to 8). `--jobs` and `--ctest-jobs` still override it.

**The Debug tree is compiled with `-O1 -g1`** instead of CMake's `-g` (`FA_AGENT_DEBUG_FLAGS`, read when the directory
is first configured). Assertions stay on and a crash still names functions and lines. Measured on a MacBook Air M5,
all 64 tests passing either way:

| Debug flags | Full build, empty compiler cache | Debug suite (`ctest -j3`) | `tooling` test | Build tree |
|---|---|---|---|---|
| `-g` (CMake's default) | 348 s | 414 s | 315 s | 8.0 GB |
| `-O1 -g1` | 449 s | 188 s | 92 s | 2.6 GB |
| `-O2 -g1` | 530 s | 176 s | 86 s | 2.6 GB |

The `tooling` column is from when that test was one process; it is now the entries `tooling_1` ... `tooling_5`, which
`ctest -j` runs at the same time (docs/design/ARCHITECTURE.md, "Testing").

An agent seldom builds everything from an empty cache and runs tests after every change, so the tests are what counts.
A debugger does not show local variables in such a tree: for a debugging session use a plain Debug tree (the presets,
`scripts/test-all.sh`) or a new directory with `FA_AGENT_DEBUG_FLAGS=-g`. A directory keeps the flags it was
configured with, and trees with different flags do not share compiler-cache entries, so agents keep the default.

**It never runs longer than 100 seconds.** An agent's harness stops a command, or moves it to the background, after two
or three minutes, and the agent then spends a turn on every look at it (measured over three milestones: one tool call
in ten was a wait or a look at a build). So the work runs as a job of its own, detached from the shell, and the command
waits for it for at most `--wait-s` seconds (default 100). The last line tells what happened:

| Last line | Exit status | Meaning |
|---|---|---|
| `agent-build: DONE ok` | 0 | Everything asked for passed. |
| `agent-build: DONE FAILED` | 1 | The lines above say what failed. |
| `agent-build: DONE INCOMPLETE` | 77 | Nothing failed, but what is listed as `SKIPPED` did not run (see below). |
| `agent-build: RUNNING (<step>: <last line of its log>)` | 3 | Still working: run `scripts/agent-build.sh <build dir> --wait` again until it says `DONE`. |

`--status` reports without waiting and `--stop` ends the job with everything it started. One job runs per build
directory: the same command again waits for the job that is running, a different one is refused until it ends.

**A Mac with its displays asleep.** When the lid is closed, or the Mac has been idle for longer than its display sleep
time, no window gets a frame, and every test that opens one (ctest label `window`: `editor_autotest_*`,
`cli_player_frames`, `cli_plugin`) waits until its time limit: five minutes each, at least twelve minutes of a full run,
for failures that say nothing about the code. The script checks before it runs the tests (`system_profiler
SPDisplaysDataType`: every display reports `Display Asleep: Yes`), leaves those tests out, lists them as `SKIPPED` (not
passed) and ends as `DONE INCOMPLETE` when nothing else failed. It also sets `FA_TEST_NO_WINDOW=1` for the tests that
do run: a test case that starts a windowed program (the sandboxed app of `sign.macos`, in a `tooling` entry) skips that
step with a `MESSAGE`, and the script lists it by file and line in the same `SKIPPED` note, so a run of `--tests
tooling` alone ends as `DONE INCOMPLETE` too. Wake the display and run the listed tests (the note gives the `--tests`
regex), or say in the report that only CI ran them; a push still needs them green somewhere.
`FA_AGENT_WINDOW_TESTS=run` runs them whatever the display says. Nothing wakes the display or changes a power setting.
A Mac with no display connected lists none, asleep or awake, so the check does not apply to it: the tests that open a
window run there as before.

`FA_AGENT_JOBS`, `FA_AGENT_CTEST_JOBS` and `FA_AGENT_WAIT_S` set the defaults of `--jobs`, `--ctest-jobs` and
`--wait-s`.

### Linux release: `scripts/build-sniper.sh`

```bash
./scripts/build-sniper.sh [build|check|smoke|all] [-- <cmake configure arguments>]
```

The Linux download (`FactorIA-linux-x64.tar.gz` and the AppImage), and with it the `factoria_player` that every exported
Linux game carries, is built here and not with `linux-release`. A build on the runner's Ubuntu 24.04 needs glibc 2.38
and GLIBCXX 3.4.31, so it does not start in the Steam Linux Runtime 3.0 "sniper" (what Steam runs Linux games in,
also on the Steam Deck: glibc 2.31, a libstdc++ from GCC 10), Ubuntu 22.04 or Debian 12. The script builds inside
Valve's sniper SDK container instead, `registry.gitlab.steamos.cloud/steamrt/sniper/sdk` (Debian 11, glibc 2.31, GCC 14
installed as `g++-14` next to its default GCC 10, CMake 3.25, Ninja, ccache and the X11, GL, EGL and ALSA development
files), so the programs need glibc 2.31 or newer and nothing else but the usual desktop libraries
(`libX11`, `libXi`, `libXcursor`, `libGL.so.1`, `libEGL.so.1`, `libasound.so.2`): Steam's sniper runtime, Ubuntu 20.04
and newer, Debian 11 and newer, and any distribution with glibc 2.31 or newer (Fedora, Arch...).

The build uses the preset `linux-sniper`, which is `linux-release` plus:

- `FA_LINUX_STATIC_LIBSTDCXX=ON`: libstdc++ and libgcc are linked into the programs (`-static-libstdc++ -static-libgcc`).
  The engine uses `std::format`, which needs GCC 13 or newer, but the sniper runtime has the libstdc++ of GCC 10, so the
  compiler's own libstdc++ travels with the programs. glibc stays dynamic: it is the one library that cannot be linked
  in, and the container's glibc is what sets the oldest system the programs run on.
- `OpenGL_GL_PREFERENCE=LEGACY`: link `libGL.so.1`. GLVND's `libOpenGL.so.0`, which the default picks, is not in the
  sniper runtime (and not on every desktop either).
- `CMAKE_DISABLE_FIND_PACKAGE_CURL=ON`: no `libcurl` (the SDK has only the GnuTLS flavour, whose `libcurl-gnutls.so.4`
  other distributions do not have). The AI features call the `curl` program, as on Windows (`fa_ai`, `tools/ai/src/http.cpp`).
  The game's `http.fetch` and `websocket` are not affected: they never link libcurl but load it at run time
  (`libcurl.so.4`, then `libcurl-gnutls.so.4`, the runtime's flavour; `engine/platform/src/curl_library.cpp`), and the
  WebSocket client needs only libcurl 7.45 or newer, not one built with WebSocket support.
- `FA_BUILD_TESTS=OFF`. The `linux` job of CI runs the tests with a normal build.

The steps (default `all`; each one starts the right container with Docker, or Podman if there is no Docker, and mounts
this checkout at `/src`):

| Step | Container | What it does |
|---|---|---|
| `build` | SDK | Configures and builds `linux-sniper` into `build/linux-sniper/` (`tools/cli/factoria`, `player/factoria_player`). Arguments after `--` go to `cmake --preset`; the release adds `-DFA_UPDATE_REPO=...`. ccache keeps its cache in `~/.cache/ccache` (`FA_CCACHE_DIR` changes it), so the next build is fast. |
| `check` | SDK | `objdump -T` on both programs: fails when one imports a glibc, `GLIBCXX`, `CXXABI` or `GCC_` symbol version newer than the sniper runtime defines (read from the container's own `libc.so.6`, `libstdc++.so.6` and `libgcc_s.so.1`, which are the runtime's), and says which symbols and how to fix it. In GitHub Actions the message is an `::error::` annotation. |
| `smoke` | sniper **runtime** (`.../sniper/platform`: the image games run in, with no compilers and nothing installed) | `ldd` finds every library, `factoria_player --version`, `factoria version` (the same version and build), `factoria new --template 2d-empty` and `factoria run --headless --frames 1` with a screenshot (EGL surfaceless on Mesa's llvmpipe). |

The first run pulls two images (the SDK is about 1.2 GB). The tag is pinned (`SNIPER_TAG` in the script), so a build is
reproducible; Valve publishes a new one about monthly (the tags are listed at
`https://gitlab.steamos.cloud/steamrt/sniper/sdk`). To upgrade: change the tag, run `all`, and fix what it reports.
`FA_SNIPER_TAG=latest ./scripts/build-sniper.sh` tries the newest without editing the script. Inside a sniper
container already (a CI job with `container:`, a distrobox made from the SDK image) the steps run in place without
Docker. On Windows run it in WSL with Docker; the script is Linux-only.

CI runs the same three steps in the job `Linux (Steam Runtime sniper)` of `ci.yml`, and `release.yml` builds the
`linux-x64` package with `build-sniper.sh all`.

### iOS: `scripts/build-ios.sh`

```bash
./scripts/build-ios.sh [debug|release] [--simulator]
```

Configures the `ios` preset (device) or `ios-simulator`, then builds the
`factoria_player` target with `-sdk iphoneos` or `-sdk iphonesimulator` and
`CODE_SIGNING_ALLOWED=NO`. The script checks that full Xcode is active and that
the SDK exists.

### Android: `scripts/build-android.sh`

```bash
./scripts/build-android.sh [debug|release] [--emulator]
```

Configures the `android-arm64` preset (or `android-x86_64` with `--emulator`) and
builds `factoria_player`. The output is `build/android-arm64/player/libfactoria_player.so`,
the native library an Android app loads. If you switch NDK versions, the script
starts that build directory over, because CMake would otherwise keep using the old NDK.

## Presets

`CMakePresets.json` defines these presets. Build trees go to `build/<preset>`.

| Preset | Host | Generator | Configuration | Test preset | Notes |
|---|---|---|---|---|---|
| `linux-debug` | Linux | Ninja (GCC or Clang) | Debug | yes | Default on Linux |
| `linux-release` | Linux | Ninja | Release | yes | |
| `linux-sniper` | Linux, inside the Steam Runtime sniper SDK container | Ninja (GCC 14) | Release | no | Static libstdc++, no tests: what `scripts/build-sniper.sh` builds (see "Linux release" above) |
| `linux-asan` | Linux | Ninja (Clang) | Debug (`-O1 -g1`) | yes | AddressSanitizer + UBSan + LeakSanitizer, the CI job `linux-asan` (see "Sanitizers" in [BUILDING_TESTS.md](BUILDING_TESTS.md#sanitizers)) |
| `linux-tsan` | Linux | Ninja (Clang) | Debug (`-O1 -g1`) | yes | ThreadSanitizer, the CI job `linux-tsan`; run `ctest -L tsan` |
| `macos-debug` | macOS | Ninja (Apple Clang) | Debug | yes | Default on macOS |
| `macos-asan` | macOS | Ninja (Apple Clang) | Debug (`-O1 -g1`) | yes | ASan + UBSan for local runs (no leak detection on macOS) |
| `macos-release` | macOS | Ninja | Release | yes | |
| `windows-debug` | Windows | Visual Studio 17 2022, x64 | Debug | yes | Default on Windows |
| `windows-release` | Windows | Visual Studio 17 2022, x64 | Release | yes | |
| `windows-ninja-debug` | Windows | Ninja with `cl` | Debug | yes | Run from a VS Developer prompt |
| `ios` | macOS | Xcode | Debug (`--config Release` to change) | no | iOS devices (arm64), deployment target 16.3 |
| `ios-simulator` | macOS | Xcode | Debug (`--config Release` to change) | no | iOS Simulator SDK |
| `android-arm64` | any host with the NDK | Ninja | Debug | no | `ANDROID_NDK_HOME`, ABI arm64-v8a, API 26 |
| `android-x86_64` | any host with the NDK | Ninja | Debug | no | Android emulator, ABI x86_64, API 26 |
| `web-debug` | any host with the Emscripten SDK | Ninja | Debug | no | `EMSDK` set; WebAssembly, WebGL2; assertions on |
| `web-release` | any host with the Emscripten SDK | Ninja | Release (`-O3`) | no | The web player: `build/web-release/player/factoria_player.{js,wasm}` |

Desktop presets build the tools (`factoria` CLI, MCP server, AI agent, editor)
and the unit tests. Mobile and web presets build the engine libraries and `factoria_player`.

### Strict builds (warnings as errors)

CI builds with `-DFA_WARNINGS_AS_ERRORS=ON`: a compiler warning in FactorIA's own code (the engine, the tools, the player,
the plugins and test programs that are built here) fails the build on GCC and Clang (`-Werror`) and on MSVC (`/WX`). The
warning set does not change (`-Wall -Wextra`, `/W4`); the option only makes it fatal. Code under `external/` is never
strict: its targets do not link `fa_warnings` and its headers are `SYSTEM` includes. Every first-party target links the
`fa_warnings` interface target (cmake/FactoriaHelpers.cmake); `fa_add_module` and `fa_add_tests` do it themselves, a target
declared by hand (a tool, a test program, a plugin) must add `fa_warnings` to its `target_link_libraries`, or it escapes
the strict build.

The option is OFF in the presets and in a plain `cmake -S . -B build/dev`, so a local build stays tolerant of the
warnings of a compiler newer than CI's. CI turns it on in `.github/workflows/ci.yml` (and `scripts/ci-local.sh`, which
mirrors it), by passing `-DFA_WARNINGS_AS_ERRORS=ON` to each `cmake --preset ...` and `scripts/build-sniper.sh build --`
step, not in `CMakePresets.json`: `release.yml` configures the same presets, and a release must not fail because a new
compiler release warns about code CI already built. To build strict yourself:

```bash
cmake --preset macos-debug -DFA_WARNINGS_AS_ERRORS=ON      # or: cmake -S . -B build/strict -G Ninja -DFA_WARNINGS_AS_ERRORS=ON
cmake --build --preset macos-debug -- -k 0                 # -k 0: list every warning, not only the first
```

The option is cached: to go back, configure again with `-DFA_WARNINGS_AS_ERRORS=OFF`. Fix a warning in the code. A
`#pragma` that silences one is only for a warning raised inside an external header that `SYSTEM` does not cover, with a
comment that names the header and the warning.

### Web player

```bash
source emsdk/emsdk_env.sh                  # once per shell (emsdk_env.bat on Windows)
cmake --preset web-release
cmake --build --preset web-release         # build/web-release/player/factoria_player.js + .wasm
```

or `factoria setup webplayer`, which finds or fetches the SDK and runs the two presets (the export prefers this folder).

The result is the two files `platforms/web/shell.html` loads (`factoria export --platform web` copies them next to the page
and the game's `game.pak`; docs/EXPORTING.md). A release build was about 8 MB of wasm (about 3 MB gzipped, which is what
a web server sends) and 150 KB of JS when this was measured (2026-10-26; the sizes table in EXPORTING.md, "Size of the
player", is dated too). To try a game by hand, put `factoria_player.js`, `factoria_player.wasm`, a `game.pak`
and the page (`shell.html` with `{{title}}`, `{{wasmBytes}}` and `{{pakBytes}}` filled in, and `{{favicon}}` replaced by `data:,`, saved as `index.html`) in one
folder, serve it (`python -m http.server`; no special headers, the player uses no threads) and open it in a browser. To
check it headless, with a software WebGL2: `node platforms/web/smoke.mjs <folder>` (Node 22+, Chrome, Chromium or Edge; it
waits for the player's `60 frames rendered` line and fails on a page error or `console.error`).

What is different from the other platforms (details in docs/MOBILE.md, "Web"): no threads, WebAssembly exceptions
(`-fwasm-exceptions`), Box2D without SIMD, no native plugins, no `log.txt`, and the save folder in IndexedDB.

Use the presets directly when you do not need the scripts:

```bash
cmake --preset linux-debug                  # configure
cmake --build --preset linux-debug          # build
ctest --preset linux-debug                  # test
```

List the presets that work on this machine with `cmake --list-presets`.

Several builds from one checkout (for example, two agents or a Debug and a
Release build at once) need separate build directories:

```bash
cmake --preset linux-debug -B build/my-build
cmake --build build/my-build -j 2
```

