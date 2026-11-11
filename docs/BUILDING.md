# Building FactorIA

FactorIA builds with CMake from one repository on Windows, macOS, Linux, iOS and
Android. Every third-party library is vendored in `external/`, so the only
downloads are the platform SDKs (Visual Studio, Xcode, the Android NDK) and the
packages listed below.

## Quick start

| Platform | Once | Build and test |
|---|---|---|
| Linux (Debian, Ubuntu) | `./scripts/bootstrap-linux.sh` | `./scripts/build.sh debug --test` |
| macOS | `./scripts/bootstrap-macos.sh` | `./scripts/build.sh debug --test` |
| Windows | Visual Studio 2022, workload "Desktop development with C++" | `powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Test` |
| iOS (Simulator) | Full Xcode | `./scripts/build-ios.sh --simulator` |
| Android (arm64 device) | Android NDK r27 or newer | `./scripts/build-android.sh` |
| Web (WebAssembly, WebGL2) | Emscripten SDK 6.0.10 | `cmake --preset web-release && cmake --build --preset web-release` ("Web" below) |

Each build writes to `build/<preset>/`. The `build/` folder is git-ignored.

## Requirements

Everywhere: CMake 3.24 or newer and a C++20 compiler. Ninja is needed on Linux
and macOS, where the presets use it.

### Linux

`./scripts/bootstrap-linux.sh` installs the packages below with apt, using sudo
when you are not root. It is safe to run again.

- Compiler and tools: `build-essential cmake ninja-build ccache`
- Engine link dependencies: `libx11-dev libxi-dev libxcursor-dev libxrandr-dev
  libgl-dev libopengl-dev libegl-dev libgles-dev libasound2-dev
  libcurl4-openssl-dev`
- Headless GPU and tests: `libgl1-mesa-dri libegl-mesa0 mesa-utils xvfb`

The script prints the Fedora and Arch equivalents. Other distributions: install
the same components with your package manager.

### macOS

- Xcode command line tools: `xcode-select --install`
- Homebrew, then `cmake ninja ccache`. `./scripts/bootstrap-macos.sh` checks the
  first two and installs the last three.
- Full Xcode (from the App Store) only for iOS builds.

### Windows

- Visual Studio 2022 (Community works, and so do the Build Tools) with the workload **Desktop development
  with C++**. It provides MSVC and CMake. That CMake is not on `PATH`: `scripts/build.ps1` finds it with `vswhere`
  (see below), so no separate CMake install is needed.
- A short checkout path, such as `C:\src\FactorIA` (see "Long paths" below).
- Ninja, only for `windows-ninja-debug`: `winget install Ninja-build.Ninja`.
- Windows PowerShell 5.1 (built in) or PowerShell 7.

### iOS

- macOS with full Xcode and its iOS platform components.
- The deployment target is iOS 16.3 (the first release with floating-point std::to_chars, which std::format needs). The builds run without code signing.

### Android

- Android NDK r27 or newer (Android Studio: SDK Manager, SDK Tools, "NDK (Side by side)").
- CMake 3.24+ and Ninja on the host. `build-android.sh` runs on Linux and macOS.
- `ANDROID_NDK_HOME` set to the NDK folder, the one that contains
  `build/cmake/android.toolchain.cmake`. If it is not set, `build-android.sh`
  also looks at `ANDROID_NDK_ROOT`, `ANDROID_NDK_LATEST_HOME`, and then the
  newest NDK under `$ANDROID_HOME/ndk` (or `$ANDROID_SDK_ROOT/ndk`).

### Web

- The Emscripten SDK, **pinned to 6.0.10** (CI and the release packages use the same version; newer ones are likely fine but untested):

  ```bash
  git clone https://github.com/emscripten-core/emsdk && cd emsdk
  ./emsdk install 6.0.10 && ./emsdk activate 6.0.10     # emsdk.bat on Windows
  source ./emsdk_env.sh                                  # emsdk_env.bat on Windows: sets EMSDK and puts emcc on PATH
  ```

- `factoria setup webplayer` does the two steps above and the build for you: it uses an SDK it finds (`$EMSDK`, `emcc` on
  `PATH`, `.cache/emsdk` of the checkout, `~/emsdk`) or fetches the pinned one into `.cache/emsdk`, then runs the `web-release`
  preset (docs/EXPORTING.md, "A development build"). `emsdk` needs Python 3.10+ (`EMSDK_PYTHON` names one; a Mac's system Python is older).
- CMake 3.24+ and Ninja on the host (any host OS). The presets read the toolchain file from `$EMSDK`
  (`$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake`), so `EMSDK` must be set (`emsdk_env` does it).
- No Python, Node or browser is needed to build. To look at the result you serve the folder and open it in a browser
  (`platforms/web/smoke.mjs` does it headless, "Web" under "Presets" below).

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
([EXPORTING.md](EXPORTING.md#icon-and-settings-per-platform)), so the file must keep its seven BMP images (16, 24, 32, 48,
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
Release build of `factoria` in `<build dir>-release` and `ctest -L example` (the example games, see "Running tests");
`-Test -Examples` is the full check before a push, `-ExamplesOnly` skips the Debug part.

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

**The Debug tree is compiled with `-O1 -g1`** instead of CMake's `-g` (`FA_AGENT_DEBUG_FLAGS`, read when the directory
is first configured). Assertions stay on and a crash still names functions and lines. Measured on a MacBook Air M5,
all 64 tests passing either way:

| Debug flags | Full build, empty compiler cache | Debug suite (`ctest -j3`) | `tooling` test | Build tree |
|---|---|---|---|---|
| `-g` (CMake's default) | 348 s | 414 s | 315 s | 8.0 GB |
| `-O1 -g1` | 449 s | 188 s | 92 s | 2.6 GB |
| `-O2 -g1` | 530 s | 176 s | 86 s | 2.6 GB |

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
| `agent-build: RUNNING (<step>: <last line of its log>)` | 3 | Still working: run `scripts/agent-build.sh <build dir> --wait` again until it says `DONE`. |

`--status` reports without waiting and `--stop` ends the job with everything it started. One job runs per build
directory: the same command again waits for the job that is running, a different one is refused until it ends.
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
| `macos-debug` | macOS | Ninja (Apple Clang) | Debug | yes | Default on macOS |
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

## Running tests

- `ctest --preset <name>` runs every test and prints the output of failing tests.
- One module: `cmake --build --preset linux-debug --target fa_test_core`, then
  `ctest --preset linux-debug -R core`. Test targets are named `fa_test_<module>`.
- GPU tests carry the CTest label `gpu`, and `ctest --preset <name> -LE gpu` skips
  them, for example on machines without a GPU.
- Tests run with the repository root as their working directory, so fixture
  paths are relative to the root.
- **The example games run on an optimized build.** `example_<name>_test` (their JS tests), `example_<name>_validate` and
  the perf budgets (`example_*_perf`) carry the CTest label `example`. The games' tests run the whole engine for minutes
  (the biggest take ten minutes in Debug under load, about a tenth of that in Release), so the cache variable
  `FA_EXAMPLE_TESTS` (`AUTO`, `ON`, `OFF`) decides whether they run: `AUTO`, the default, runs them in Release,
  RelWithDebInfo, MinSizeRel and multi-config builds (Visual Studio, Xcode), and registers `_test` and `_perf` as
  `DISABLED` in a Debug build (`ctest` prints them as "Not Run (Disabled)"; CMake says so while configuring; the
  validations still run). `ctest -L example` selects them, `ctest -LE example` leaves them out.
- **Before a push, one command:** `scripts/test-all.sh` (Windows: `scripts\agent-build.ps1 <dir> -Test -Examples`). It builds
  every target in Debug and runs the whole Debug suite, then builds `factoria` in Release (`build/release`) and runs
  `ctest -L example`. `--debug-only` and `--examples-only` run one half; `FA_TEST_DEBUG_DIR`, `FA_TEST_RELEASE_DIR`,
  `FA_TEST_JOBS` and `FA_TEST_CTEST_JOBS` (default 3) tune it; ccache is used when installed. CI already builds Release,
  so its `ctest` runs the examples with no extra job. An AI agent runs that check as
  `scripts/agent-build.sh <dir> --test --examples`, which prints only what failed, never blocks for more than 100 s and
  builds its Debug tree with `-O1 -g1` (the suite takes less than half the time; see the script's section above).
- **A scratch shader cache in tests.** `add_test` also gives every test `FA_CACHE_DIR=<build dir>/test-cache`, so a test run never
  reads or writes your real per-user cache folder (`fs::cache_dir()`, docs/PERFORMANCE.md "Startup"); delete the folder for a cold-cache run.
- **Windows file rules in tests (macOS and Linux).** Two Windows behaviours broke the engine and only the Windows CI job
  found them: a file open for reading cannot be replaced or deleted (every `std::ifstream` opens without
  `FILE_SHARE_DELETE`, so the atomic rename of `fs::write_bytes` fails while another thread reads the file), and a file's
  modification time moves in steps of 15.625 ms, so a write right after a read keeps the time the read saw. On macOS and
  Linux `ctest` runs every test with `fa::fs` emulating both (`FA_FS_WINDOWS_RULES_DEFAULT=1`, set by `add_test` in
  `cmake/FactoriaHelpers.cmake`; `scripts/test-all.sh` too): a replace, rename or delete of a file held open through
  `fs::ReadStream` (or `fs::read_bytes`) fails with a sharing violation after the same retries as on Windows, a folder
  with such a file inside loses everything else and reports the violation, paths compare case-insensitively, and
  `fs::modified_time` / `fs::host_modified_time` round down to 15.625 ms. A test that fails only with the mode on found a
  real Windows bug: read the file with `fs::ReadStream` (not a bare `std::ifstream`, which the registry cannot see), and
  never rely on a time change smaller than 16 ms. Details and limits: `core/fs.h`, "Windows file rules".
  Switch it off for one run with `FA_FS_WINDOWS_RULES=0 ctest ...` (any value other than `0`, `false`, `off`, `no` turns
  it on, also for a program run by hand: `FA_FS_WINDOWS_RULES=1 factoria test ...`), or for a build directory with
  `cmake -DFA_TEST_WINDOWS_FILE_RULES=OFF`. A test that sets its own `ENVIRONMENT` property must `APPEND` to it
  (`set_property(TEST <name> APPEND PROPERTY ENVIRONMENT ...)`); `set_tests_properties(... ENVIRONMENT ...)` replaces the
  mode's variable.
- **Time limits count CPU time.** The 60 s of one test of `factoria test`, the 5 s of `script.eval`, the 2 s of a callback
  and the like measure the CPU time the script thread spent (`CLOCK_THREAD_CPUTIME_ID`, `GetThreadTimes`), not the wall
  clock, so a loaded machine or a build running next to the tests cannot fail them. A script blocked for good (a native that
  never returns) is still stopped by a hard cap of 8 times the limit on the wall clock. The messages say which one ran out:
  `(> 60 s of CPU time)` or `(> 480 s on the clock)`.

## Golden images

Rendering tests compare a headless picture with a committed PNG: `engine/render/tests/golden/*.png` (`expect_golden`), and
`tools/cli/tests/golden/` for the menus and the mobile-export tests. There is one file per picture for every backend (Metal,
Direct3D 11, GL on Mesa llvmpipe). The render tests (`fa_test_render`) need a GPU and fail without one, so a host with none runs
`ctest -LE gpu`; the CLI golden tests (menus, mobile export) skip with a message when there is no GPU.

- **A missing golden fails the test.** The message names the file and says how to create it. A test never writes its own
  reference: that compared the picture with itself and passed. To make or change a golden, run the test with
  `FA_UPDATE_GOLDENS=1` (the old spelling `FA_UPDATE_GOLDEN=1` still works), look at the PNG it wrote, and commit it with
  the change that explains it. In that mode the test passes after writing, so a run that updates also hides a regression:
  review `git diff --stat` of the golden folders. On a Mac, Linux and Windows the pictures differ a little (below), so
  update a golden only for a change you meant, and run the test on the other hosts' CI afterwards.
- **Three limits, all of which must hold** (`engine/core/tests/golden_check.h`): the mean absolute error over all channels
  (0.004), the share of pixels with a channel more than 4/255 off (8 %) and the largest single-channel error (0.6). The mean
  alone lets one wrong region pass on a big picture: a missing sprite changes under 1 % of the pixels. The share catches a
  wrong region and the largest error catches one wrong pixel, except in goldens with text, thin lines or nearest-sampled edges
  (single pixels flip between ink and background from one GPU to the next): those use `expect_golden_edges`, which allows a
  largest error of 1.0 and keeps the other two, so there only the mean and the share guard against a missing glyph or edge. The header says where each number
  comes from; raise a limit only with a measurement of a backend, written there.
- **Measure on a backend:** `FA_GOLDEN_REPORT=1 fa_test_render` (or `fa_test_cli`) prints `GOLDEN <file> mean=... share=... max=...` for every
  golden compared. The numbers measured on Metal, llvmpipe and Direct3D 11 (WARP and hardware) are in the header of `golden_check.h`; add a new backend's there.
- **A failing comparison** writes the picture it got next to the golden as `<name>.actual.png`, or in the temp folder when
  that folder cannot be written (a read-only checkout); the failure message gives the path. Those files are git-ignored;
  delete them when done.

## Headless and GPU notes

FactorIA renders into an offscreen target, so the tests can run without a window.

- **Linux.** Headless rendering uses EGL with Mesa's software renderer
  (llvmpipe). Install `libgl1-mesa-dri` (the bootstrap script does). Windowed
  code needs an X display, so run the tests under a virtual one:
  `xvfb-run -a -s "-screen 0 1280x720x24" ctest --preset linux-debug`.
- **Windows.** Headless rendering uses Direct3D 11. If the machine has no
  hardware adapter, it falls back to WARP, the software rasterizer. Nothing to install. The editor autotests
  (`editor_autotest_1` to `_4`, `editor_autotest_welcome`) open a real editor window and read its swap chain back, so they
  need the logged-in desktop session (hosted runners have one). The hosted Windows runner's desktop is 1024x768, which
  shrinks the autotest's 1600x900 window and pushes widgets it clicks off screen, so CI raises it to 1920x1080 first.
- **macOS.** Headless rendering uses Metal. The whole suite runs, GPU tests included, here and in CI. The editor
  autotests (`editor_autotest_1` to `_4`, `editor_autotest_welcome`) open a real editor window for a few seconds, so they
  need the logged-in desktop session (hosted runners have one). `ctest -j` runs them at the same time, each in its own
  window; while you work on one part of the editor, `FA_EDITOR_AUTOTEST_SECTIONS` runs only its sections (docs/EDITOR.md,
  "Run only some sections").
- **CI.** The workflow in `.github/workflows/ci.yml` runs the same presets on
  each platform. It uploads test output (`Testing` folders and `test-output/**/*.png`
  screenshots) when a job fails.
- **Release packages.** `.github/workflows/release.yml` builds the release presets on Windows, macOS and Linux and
  packages `factoria`, `factoria_player` and (Windows) `FactorIA-Editor.exe` as `FactorIA-<os>.zip` (`.tar.gz` on
  macOS and Linux), one `FactorIA/` folder inside. The Linux programs are built in the Steam Runtime sniper container
  (`scripts/build-sniper.sh`, "Linux release" above) and run on glibc 2.31 and newer. The jobs `mobile-android` (NDK, `arm64-v8a` and `x86_64`) and
  `mobile-ios` (device, simulator `arm64;x86_64`) build the mobile runtime first; every package gets
  `FactorIA/mobile/android/jniLibs/<abi>/libfactoria_player.so` and the macOS one also `FactorIA/mobile/ios/<sdk>/*.a`,
  so `factoria export --platform android|ios` works from the download without engine source (docs/EXPORTING.md).
  Each package is smoke-tested from a temp folder outside the checkout (`version`, `new`, `test`, `export`); Linux also
  exports an Android game and builds its APK with Gradle (the NDK and CMake hidden from the SDK), macOS exports an iOS
  game and builds it for the simulator. A `v*` tag publishes a GitHub Release; "Run workflow" keeps the packages as
  artifacts. Bump `project(VERSION)` in `CMakeLists.txt` before tagging: the job fails when the tag and
  `factoria version` differ. The installer, the AppImage, the universal macOS package and code signing are in
  [Releasing](#releasing).
- **Updates.** The packages are configured with `-DFA_UPDATE_REPO=<owner/repo>`, so their editor offers each newer
  release (with its release notes, which you can edit on the release page) and installs it in place
  (`tools/editor/src/update.cpp`, docs/GETTING_STARTED.md "Updates"). It is empty by default: builds from source
  never update.

## Releasing

1. Bump `project(VERSION)` in `CMakeLists.txt` and add a `## <version>` section at the top of `CHANGELOG.md`, merge
   both, then tag that commit `v<version>` and push the tag. The section is the release notes: editors that update
   themselves show them, so write them for people who make games (what they can do now, what was fixed), not for
   engine developers (no pull request numbers, authors, CI or internal names). The section stays in `CHANGELOG.md`
   (the release workflow reads it there); the sections of the previous minor version move to `changelog/0.<minor>.md`
   (one file per minor version, patches inside) and the index line at the top of `CHANGELOG.md` links it.
2. `.github/workflows/release.yml` builds and smoke-tests the packages and publishes them as a GitHub Release with that
   section as its notes; without the section it fails before publishing.
   The same workflow runs, without publishing, on a pull request that changes it and on "Run workflow".

A release holds these files (the header of `release.yml` says the same):

| File | What it is | How CI checks it |
|---|---|---|
| `FactorIA-windows-x64.zip` | Windows package; what the editor's updater downloads, also for a copy made by the installer | `version`, `docs read` and `docs.read` with no carriage return, `new`, `test`, `export` from a temp folder |
| `FactorIA-windows-x64-setup.exe` | Installer of the same files, built with Inno Setup from `platforms/windows/FactorIA.iss`: per user (no administrator prompt) into `%LOCALAPPDATA%\Programs\FactorIA`, Start menu entry, folder on the user PATH (once), uninstaller | Silent install, PATH entry read from the registry, `factoria version/new/test` from the installed copy, a second install (no second PATH entry), silent uninstall (PATH entry, shortcut, files and the updater's leftovers gone) |
| `FactorIA-macos-universal.tar.gz` | arm64 + x86_64 in one binary (`CMAKE_OSX_ARCHITECTURES="arm64;x86_64"`); what the editor's updater downloads | `lipo -archs` lists both; the Intel half runs through Rosetta when the runner has it |
| `FactorIA-macos-arm64.tar.gz` | The same file, only because editors up to 0.1.2 download this name. Remove the `publish` step that copies it once nobody runs them | none (a copy) |
| `FactorIA-linux-x64.tar.gz` | Linux package; what the editor's updater downloads. Built in the Steam Runtime sniper container: needs glibc 2.31 or newer | `build-sniper.sh all` (symbol versions, then `--version`, `new` and a headless frame inside the sniper runtime), then as the zip |
| `FactorIA-linux-x64.AppImage` | The same files in one file (`scripts/package-appimage.sh`, `platforms/linux/`): no arguments open the editor, arguments are the `factoria` command, a link named `factoria` is the CLI. No self-update. Like the tar.gz it uses the system's X11, OpenGL and ALSA and needs glibc 2.31 or newer (built in the sniper container) | `--appimage-extract-and-run` (the runner has no FUSE): `version`, `new`, `test`, `export`, the `factoria` link prints the help, and with no arguments the editor stays open under Xvfb |

Every package (and so the installer and the AppImage) carries sokol-shdc, the shader compiler of custom materials, next to
`factoria`. `scripts/bundle-sokol-shdc.sh` downloads it with the commit and SHA-256 that `fa/tooling/setup.h` pins for
`factoria setup shaders` (a file that does not match fails the release; a doctest keeps the lines the script reads in
shape): the pinned file itself on Windows and Linux, the pinned x86_64 and arm64 files joined with `lipo` into one universal
file on macOS (each half checked). The smoke tests check it is in the package and in the AppImage, that `factoria setup`
reports it `found next to factoria` with an empty `FACTORIA_HOME`, and compile a material with it; the licences of sokol-shdc
and what it links are in `THIRD_PARTY_NOTICES.txt`.

The names carry no version, so `releases/latest/download/<name>` is always the newest. The AppImage tool and its
runtime are pinned by version and SHA-256 in `scripts/package-appimage.sh`; to upgrade, change both together. Locally:
`scripts/package-appimage.sh <unpacked FactorIA folder> out.AppImage` on Linux; on Windows, with Inno Setup 6.3 or newer,
set `FA_INSTALLER_VERSION` and `FA_INSTALLER_SOURCE` and run `ISCC /O<dir> platforms\windows\FactorIA.iss` (the top of the
`.iss` file has the example).

### Code signing

Both are optional and each one is on only while its repository secrets exist (Settings > Secrets and variables >
Actions): without them the signing step prints a notice (`::notice`) and the packages come out unsigned.
`scripts/sign-windows.sh` and `scripts/sign-macos.sh` do the work and can be read for the exact commands.

State on 2026-11-09 (`gh secret list`, and the logs of the v0.19.0 release run): the five Apple secrets below are set
(since 2026-10-16), so the macOS `factoria`, `factoria_player` and `sokol-shdc` are signed and notarized in every
release from 0.1.4 on; the two Windows secrets are NOT set, so the Windows executables, the zip and the installer are
unsigned and SmartScreen warns. Linux packages are not signed. The release log says which of the two happened.

**Windows** (signtool, SHA-256, timestamped with DigiCert's server; signs `factoria.exe`, `FactorIA-Editor.exe`,
`factoria_player.exe` before they go into the zip and the installer, then `FactorIA-windows-x64-setup.exe`; the
uninstaller inside the installer stays unsigned, and so does `sokol-shdc.exe`, which is not FactorIA's program and keeps
the pinned SHA-256 that docs/EXPORTING.md prints):

| Secret | Value |
|---|---|
| `WINDOWS_CERT_PFX_BASE64` | The code signing certificate with its private key as a `.pfx`, base64 encoded: `base64 -w0 cert.pfx`, or in PowerShell `[Convert]::ToBase64String([IO.File]::ReadAllBytes('cert.pfx'))` |
| `WINDOWS_CERT_PASSWORD` | The password of the `.pfx` |

**macOS** (hardened runtime, timestamped; signs `factoria`, `factoria_player` and the universal `sokol-shdc`, which
Gatekeeper would otherwise block when `factoria` starts it from a downloaded package; the executables go to Apple in a
temporary zip, because `notarytool` takes zip, pkg or dmg and not a bare executable):

| Secret | Value |
|---|---|
| `APPLE_CERT_P12_BASE64` | The **Developer ID Application** certificate with its private key, exported from Keychain Access as `.p12`, base64 encoded: `base64 -i cert.p12` |
| `APPLE_CERT_PASSWORD` | The password chosen when exporting the `.p12` |
| `APPLE_ID` | The Apple ID (email) of the developer account |
| `APPLE_TEAM_ID` | The 10-character Team ID (developer.apple.com > Membership details) |
| `APPLE_APP_PASSWORD` | An app-specific password (appleid.apple.com > Sign-In and Security), not the account password |

With the certificate but without the three Apple ID secrets the macOS step signs but does not notarize (and says so).
Bare executables cannot be stapled (only `.app`, `.pkg` and `.dmg` carry a ticket): Gatekeeper looks the notarization
up online the first time a downloaded executable runs, so the very first launch needs internet. Updates installed by
the editor are not quarantined and never show the prompt.

**What to buy**

- Windows: a code signing certificate from a certificate authority (OV or EV Authenticode), or Azure Trusted Signing
  (Microsoft's cloud signing service). Since June 2023 the certificate authorities issue new code signing certificates
  only with the key on a hardware token or in their cloud HSM, so a downloadable `.pfx` exists only for older
  certificates. For a new one, use the CA's cloud signing, or Azure Trusted Signing, and replace the call to
  `scripts/sign-windows.sh` in `release.yml` with the signing action of that service (the signed files and their order
  stay the same). Either way SmartScreen's warning disappears as the publisher builds reputation (sooner with an EV
  certificate or Trusted Signing).
- macOS: the Apple Developer Program (US$99 a year). It gives the Developer ID Application certificate and the
  notarization service.

**What changes for users**

- Windows: the publisher shows as the certificate's name, not "Unknown publisher", and SmartScreen stops blocking
  once the certificate has reputation.
- macOS: Gatekeeper accepts the executables without the "cannot be opened" dialog (so no right-click > Open, **Open
  Anyway** or `xattr`).
- Gatekeeper: `README.md` and `docs/GETTING_STARTED.md` keep the quarantine workaround only for 0.1.3 and earlier,
  which stay on the Releases page unsigned. SmartScreen: when the first Windows release is signed, drop its warning
  from `README.md` and `docs/GETTING_STARTED.md` (and the translation of the latter).
- Games exported from the download copy the signed `factoria_player` (see [EXPORTING.md](EXPORTING.md)).

Pull requests from forks never receive the secrets. A pull request from a branch of this repository does, and the
workflow runs on the ones that change `release.yml`: review those like any change that can read the secrets (a GitHub
Environment with required reviewers is the stricter option).

## Before a push

`scripts/ci-preflight.sh` is the one command to run before every push, so the PR passes GitHub CI the first time. It
covers what CI exercises and a developer machine does not (Windows file semantics, waits and budgets on loaded 4-vCPU VMs,
compilers other than yours, other platforms):

1. **Risk scan.** The lines the branch adds (`git diff <base>...HEAD`, base `origin/main`) are checked against a table of
   patterns that failed CI before: `std::ofstream` or `rename`/`remove` on files others may hold open, `sleep_for`, wall-clock
   time and timeouts in tests and editor autotests, perf/memory budget files, platform `#if` branches, `.glsl` edits without
   regenerated headers, render-backend code, headers using `std::format`/`<ranges>`/`<thread>`/`<chrono>`/`<cstring>` without
   the include, `long`/`%ld` formats, text parsing that may see CRLF, case-only path clashes and workflow changes. It prints
   file:line, why it matters and what to check. The table is the `RULES` block of the script: add a line to add a pattern.
   The scan reads commits only, and never fails the run unless `--strict`.
2. **`scripts/test-all.sh`**, with the same environment variables.
3. **Stress.** The editor autotests (`editor_autotest_*`, in the Debug dir) and the example tests (`example_<name>_*`, in the
   Release dir) the diff touches run with `ctest --repeat until-fail:N` while one CPU burner per core keeps the machine busy.
   `tools/editor/**` selects the editor autotests, `examples/<name>/**` that example's tests, `engine/**`, `tools/cli/**`,
   `tools/common/**`, `external/**` and the CMake files all of both; docs and scripts select nothing. The example tests get twice their
   ctest limit (`FA_EXAMPLE_TEST_TIMEOUT`) in this pass, since the burners halve their CPU; it is put back afterwards. The
   burners are killed when the script ends, fails or is interrupted. `--plan` prints the selection only.
4. **Other platforms.** The `scripts/ci-local.sh` jobs this host supports (Mac: `macos ios web android`; Linux: `linux windows
   android web`; a job without its tooling skips itself), then on a Mac `scripts/ci-docker.sh linux` (the Linux job in
   Docker; its MinGW + Wine Windows job is not a reference on a Mac, see below) and `scripts/ci-remote-windows.sh`, the
   native Windows check on a PC (exit 0 pass, 1 fail, 77 not set up, PC off or nobody logged in: reported as SKIP).

It ends with a PASS/FAIL/SKIP table with the time of each step and exits 1 if any step failed. Logs:
`build/ci-logs/preflight-<step>.log`.

```bash
scripts/ci-preflight.sh                      # everything
scripts/ci-preflight.sh --quick              # risk scan + test-all only
scripts/ci-preflight.sh --no-stress --no-platforms
scripts/ci-preflight.sh --repeat 5 --base origin/main --strict
scripts/ci-preflight.sh --scan-only          # the risk scan alone (seconds)
scripts/ci-preflight.sh --no-test --no-platforms  # stress only, on the build dirs of an earlier run
```

On a Windows host the script (Git Bash) runs the risk scan and then points to `scripts\agent-build.ps1 build\agent-<name>
-Test -Examples`, the Windows build and test path.

## Continuous integration (local, no GitHub minutes)

CI runs on your own machine with one script. It runs every job the host can run
and reports the others as skipped, with the reason:

```bash
./scripts/ci-local.sh            # all jobs this machine supports
./scripts/ci-local.sh linux      # just one job
```

| Job | Runs on | What it checks |
|---|---|---|
| `linux` | Linux, or a Mac with Docker (see below) | full build + every ctest suite (GPU tests through Xvfb + Mesa llvmpipe) |
| `windows` | Linux with `g++-mingw-w64-x86-64-posix` (+ `wine64 wine` to run tests), or a Mac with Docker (see below) | Windows x64 cross-build (D3D11 backend), every unit-test `.exe` under Wine, and a CLI smoke test that creates, validates, tests and renders a game through D3D11 |
| `android` | any host with `ANDROID_NDK_HOME` (NDK r27+) | `factoria_player` for arm64-v8a |
| `macos` | a Mac | macOS build + ctest |
| `ios` | a Mac with Xcode | iOS Simulator app bundle with a demo game |
| `web` | any host with `EMSDK` set (Emscripten 6.0.10), Node 22+ and Chrome or Chromium (`CHROME_BIN`) | the web player (`web-release`), the `factoria` CLI, a template game exported with `--platform web`, the zip checked as itch.io takes it (`index.html` at the root, at most 1000 files and 500 MB) and the export run in headless Chrome until `player: 60 frames rendered` (`scripts/web-smoke.sh`) |
| `sniper` | Linux with Docker or Podman, or a Mac with Docker; only when named (`./scripts/ci-local.sh sniper`) | the Linux release programs built in the Steam Runtime sniper container, their symbol versions checked, and run in the sniper runtime (`scripts/build-sniper.sh all`) |

Logs go to `build/ci-logs/`. The exit code is non-zero if any job that ran failed.

**Linux and Windows jobs on a Mac (Docker).** Run `./scripts/setup-docker-macos.sh` once: it installs Colima and the
Docker CLI with Homebrew and starts a Colima VM (Apple Virtualization.framework with Rosetta, 6 CPUs, 8 GiB, 100 GiB
disk; `FA_DOCKER_CPUS`, `FA_DOCKER_MEMORY` and `FA_DOCKER_DISK` change them). It is safe to run again. After that
`./scripts/ci-local.sh` runs the `linux`, `windows` and `sniper` jobs through `./scripts/ci-docker.sh`, which you can
also run on its own (`./scripts/ci-docker.sh linux windows`; exit code 77 means Docker is not set up, and `ci-local.sh`
then skips those jobs). The jobs run in an Ubuntu 24.04 `linux/amd64` container (`tools/ci/docker/Dockerfile`, the
GitHub runner's OS, built the first time) with the checkout mounted at `/src`. The Linux build trees, ccache, the Wine
prefix and `~/.factoria` in the container live in Docker volumes (`factoria-ci-home` for ccache, the Wine prefix and
`~/.factoria`; `factoria-ci-linux-<hash>` and `factoria-ci-windows-<hash>` for the build trees), so the second run is
warm and your macOS build directories never see a Linux object. Each checkout and git worktree has its own build-tree
volumes, named by a hash of its path: a tree shared by two checkouts would keep objects newer than the other branch's
sources and link them; the shared ccache keeps a new worktree's first build fast. `FA_CI_DOCKER_RESET=1` deletes
this checkout's volumes and the shared one; the volumes of a removed worktree stay until `docker volume prune`. A worktree's git directory is mounted read-only at its host path, so the
build has an identity in the container.

What the container does not reproduce. The `linux` job is the reliable one: the same Ubuntu 24.04 and GCC as the
runner, with three differences. The `*_perf` budget tests are not run (the numbers are the runner's; emulated x86-64
uses about 30% more memory and twice the CPU time; `FA_CI_DOCKER_PERF=1` runs them), and an example game's test may
run 900 s instead of 300 (`FA_EXAMPLE_TEST_TIMEOUT`; the longest takes ~170 s on the runner and over 300 s emulated). The image has Node 22 like the
runner, so the feedback server's tests run. The `windows` job (MinGW-w64 under
Wine) is not a reference on a Mac: Ubuntu's Wine 9.0 under Rosetta has no `atan2` in its HLSL compiler, so every
test that renders through D3D11 fails, some Windows file and process tests fail on the bind mount, and a hung
program is stopped after `FA_CI_WINE_TIMEOUT` seconds (600). The build half of that job (the MinGW cross-compile)
does catch Windows compile and link errors. For the Windows tests use a Windows host (`scripts/ci-remote-windows.sh`
or the native MSVC build). Neither job reproduces MSVC, WARP, or the GitHub runner's CPU and ccache state.

**The shader compiler.** Custom materials (`*.material.json`) are compiled with sokol-shdc, a separate program the
build does not make (the release downloads carry it next to `factoria`, see Releasing). Install the pinned one with the CLI you just built: `factoria setup shaders` (about 10 MB, SHA-256
checked, into `~/.factoria/tools/sokol-shdc/<commit>/`; `SOKOL_SHDC=/path/to/sokol-shdc` or a sokol-shdc next to
`factoria` also works). Without it the doctests that run the real compiler (`real sokol-shdc: ...` in `fa_test_tooling`,
the exports of materials) skip themselves and `factoria validate` only warns, so a change to the shaders can look green
while untested. The CI jobs that run ctest on a desktop (Linux, Windows, macOS) and `ci-local.sh linux` therefore run
`factoria setup shaders` right after the build (it fails when the install does) and run ctest with
`FA_REQUIRE_SHDC=1`: with it those doctests FAIL when no compiler is found instead of skipping, so a broken install
cannot turn into silent skips (the variable is not set locally, where skipping is the right answer on a machine without the
compiler). On Windows, Windows Defender flags the pinned `sokol-shdc.exe` by mistake and may remove it (the setup says so
when it sees it go); if it happens on a runner, the job fails at that step or at the tests, never skips. The `Linux (Steam
Runtime sniper)` job builds release programs and runs no ctest, so it does not install the compiler; the Windows (MinGW +
Wine) job of `ci-local.sh` runs the unit-test programs without it, and the MSVC run of `ci-local.sh` (`build.ps1`) does
not set `FA_REQUIRE_SHDC`.
MinGW is not MSVC: Visual Studio-only issues still need `scripts/build.ps1` on a
Windows PC.

`.github/workflows/ci.yml` runs the full five-platform matrix (Linux, Windows/MSVC,
macOS, iOS Simulator, Android) on GitHub-hosted runners; standard hosted runners
are free for public repositories. It runs once per change:

- **Pull requests**: every push to a branch with an open pull request.
- **`main`**: every push (including merged pull requests).
- **`v*` tags**: every job, whatever changed.
- **Other branches**: no automatic run, so a PR branch is not built twice. Start
  one by hand from the Actions tab ("Run workflow"; every job) or open a pull request.

A run only builds what the change can break (the `changes` job compares it with its
base): a change to docs only (`docs/`, `feedback/`, top-level `*.md`) builds nothing,
and the iOS and Android jobs run only when the change touches what they build or run
(`engine/`, `player/`, `platforms/`, `external/`, `cmake/`, `templates/`,
`tools/common/`, `tools/cli/`, `scripts/`, the top-level CMake files or `ci.yml`).
The job `Linux (Steam Runtime sniper)` builds the Linux release programs as `release.yml` does and runs them in Valve's
sniper runtime image (`scripts/build-sniper.sh`, "Linux release" above), with its own ccache. The last job,
`CI result`, fails if any job that ran failed. It is the only check that
the branch protection of `main` requires, so a pull request with auto-merge on
(`gh pr merge <n> --auto --merge`) merges itself when it passes, and GitHub then
deletes its branch. `release.yml` is not part of `CI result`: a pull request that
changes it is merged by hand once its Release run is green.

The Linux and macOS test steps run `ctest --parallel` with the runner's vCPUs (4 on Linux, 3 on macOS). Windows runs
one test at a time: its editor autotests draw with the software D3D11 renderer (WARP), which already fills the runner's
4 vCPUs, so running tests side by side made the step slower and its timing-sensitive tests fail. Instead the Windows job is a
matrix of three machines (`Windows (... tests 1/3)` to `3/3`): each builds (with a warm ccache that takes about a
minute) and runs a third of the tests, chosen by `scripts/ctest_shard.py`. Every machine lists the same tests and
splits them the same way, balancing the expected time of each third with the times measured on the runner (the table
in the script; a test not listed counts 2 s), so a new test runs in exactly one shard. Only shard 1 saves the ccache
and prints the physics replay hash. `python scripts/ctest_shard.py --preset <preset> --shard 1 --of 3` runs one third
on your machine too. The performance
budgets have the `RUN_SERIAL` property, so `ctest` runs each of them alone and the other tests cannot skew their times.
A newer push to the same pull request or branch cancels the older run (not a manual "Perf baselines" run
of that ref: the event and the `perfBaselines` tick are part of the concurrency group). A `_perf` test that passes inside
the warning band is invisible to ctest; the step "Performance warnings" of the Linux, Windows and macOS jobs lists those
in the job summary (`scripts/ci-perf-warnings.sh`, docs/PERFORMANCE.md "The band").
Each job that compiles restores a ccache and saves it again with only the entries its build used, right after the build,
so a run whose tests fail still leaves the next run a warm cache; `CI result` then
deletes the older ccaches of the same branch or pull request. That keeps the repository's 10 GB of caches holding
`main`'s, which every pull request starts from.
`./scripts/ci-local.sh` runs the same kind of checks on your own machine before
you push.

The job `Web (Emscripten, headless Chrome)` installs the Emscripten SDK (cached), builds the web player and the CLI,
exports a game with `factoria export --platform web` and runs `scripts/web-smoke.sh`: the zip check and the export opened
in the runner's Chrome until the player has rendered its first frames. On failure it uploads the screenshot and the
export. It runs when the mobile jobs do. `release.yml` builds the web player once and every release package carries it in
`FactorIA/web/` (`factoria_player.js` and `.wasm`), like the Android libraries in `FactorIA/mobile/`.

The mobile jobs also RUN the app: `ios` boots an iPhone simulator and builds the touch UI test while `ios-build` builds
the app, then runs it (`scripts/ios-smoke.sh`), and `android-emulator` boots an API 34 `x86_64` emulator with KVM,
installs the debug APK that `android-apk` built and starts it (`scripts/android-smoke.sh`). Both assert that the process
stays alive, the player logged `player: 60 frames rendered`, an audio device is open and being pulled, the app survives being sent to the
background and back and renders again, a tap in the middle of the screen reaches the player at the middle of the design
(on iOS a UI test taps, `platforms/ios/touch-test`), nothing crashed and the screenshot shows a picture (Android also
changes the font size), and upload their logs, the screenshot and crash reports as the artifacts `ios-smoke` and
`android-smoke` (look there when one of them fails). The `ios` job asks for the conclusion of `ios-build` while it
waits for the app, so a build that ended without one (failed, or cancelled because GitHub found no macOS runner) fails
the step at once with that message instead of timing out. The Android game also carries a native plugin (built by
`android-apk` with the NDK, outside the game's folder through `FA_CI_PLUGINS`), and the emulator job checks that its
script got the plugin's answers. What they cover and what not is in [MOBILE.md](MOBILE.md).

### Checking Windows from the Mac

GitHub's Windows job (MSVC) is the one that fails most, and a Mac cannot build with MSVC. If you also have a Windows PC
on the same home network, the Mac can run the native check on it over SSH before a push: the commit checked out on the
Mac is pushed to a repository the check owns on the PC (to the ref `refs/heads/preflight/<branch>`), built in a
worktree of it, and checked with
`scripts\agent-build.ps1 build\agent-preflight -Test -Examples` (Debug build and ctest, then the Release build and the
example games' tests). The output streams to the Mac terminal. The PC needs no clone of FactorIA: the check works in its
own folder `%USERPROFILE%\FactorIA-remote` (a bare repository `repo.git` and the worktree `work`, whose `build\` is kept
between runs) and never touches any other folder. A folder that is a git repository of its own, or holds anything else, is
refused (`--repo` on the Mac, `-RemoteDir` on the PC pick another one).

**Setup, once** (two commands, one on each machine):

1. On the Mac: `scripts/setup-windows-remote.sh`. It creates the key `~/.ssh/factoria_windows` if missing and prints (and
   copies to the clipboard) one PowerShell line that carries `scripts/setup-windows-remote.ps1` and the public key.
2. On the PC: open PowerShell **as administrator** and paste that line (or, from a clone that has the script, run
   `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\setup-windows-remote.ps1 -PublicKey '<key>' [-RemoteDir C:\path\FactorIA-remote]`).
   It installs and starts the OpenSSH Server, opens port 22 on **private networks only** (the rule Windows creates itself
   is turned off; if the home network is set to "Public" it warns and gives the command to change it), makes PowerShell
   the SSH shell, authorizes the key (`C:\ProgramData\ssh\administrators_authorized_keys` with the ACL sshd requires for
   an administrator, `~\.ssh\authorized_keys` otherwise), creates the check's folder, checks git,
   Visual Studio 2022 with the C++ tools and its CMake and Ninja (what `agent-build.ps1` uses), prints what is missing with
   the `winget` / installer command to add it (it installs none of them), and ends by printing the command for the Mac.
   Running it again changes nothing that is already right.
3. On the Mac: run the command the PC printed, `scripts/setup-windows-remote.sh --host <ip> --user <name>` (with `--repo` only if the PC folder is not the default).
   It shows the `Host factoria-windows` block it will write to `~/.ssh/config` and asks first (a rerun replaces the
   block between its marker comments), stores the PC folder in `build/windows-remote.conf` of the main checkout and tests
   the connection (`scripts/ci-remote-windows.sh --check`).

**Every time:**

```bash
scripts/ci-remote-windows.sh              # Windows: Debug build + ctest + Release example games
scripts/ci-remote-windows.sh --no-examples
scripts/ci-remote-windows.sh --wsl        # also scripts/ci-local.sh linux android in the PC's WSL Ubuntu-24.04
```

Exit status: 0 = passed, 1 = a build or a test failed, 77 = the check could not be done or finished, which is not a
failure (`scripts/ci-preflight.sh` records it as a skip): not set up (the message names the setup script), the PC is off
or unreachable, the connection was lost halfway, or the windowed tests were skipped because nobody is logged in.

**The PC is often off, and the script never switches it on or puts it to sleep.** It first checks that the PC answers
(5 s at most). If it does not: in a terminal it asks "Can you switch it on?" and Enter means "I am switching it on, wait
for it" (it waits for sshd, up to `--wait-timeout SECONDS`, default 300, with a note every 15 s), `s` skips (exit 77). Without a
terminal (an AI agent runs it) it exits 77 at once saying so, and the agent asks you; once you say you are switching the
PC on, it runs the script again with `--wait`. While the PC is off, the MinGW cross-compile of the Docker `windows`
job and the Windows file rules that `ctest` turns on (see "Running tests") still cover part of what the MSVC check finds.
If the connection drops during the run (the PC went to sleep or off, the network failed) the script says which part had
run, that this is not a build or test failure, and exits 77; a dead PC is noticed after about a minute.
Only committed work is tested: uncommitted changes to tracked files are listed in a warning and not sent. The first run
builds everything cold on the PC; later runs reuse `build\agent-preflight` and `build\agent-preflight-release` in the
worktree. Do not start two runs at once (they share that worktree). The logs come back to `build/ci-logs/windows-remote/`.
**Windowed tests.** An SSH session on Windows has no desktop, so a D3D11 swap chain cannot be created there. The tests
that open a window carry the ctest label `window` (`editor_autotest_*`, `cli_player_frames`, `cli_plugin`, which exports
and runs a game) and are left out of the SSH run (`agent-build.ps1 -NoWindowTests`). The script then runs them in the desktop
session of the user logged in on the PC (`scripts\windows-run-interactive.ps1`, `agent-build.ps1 -WindowTestsOnly`): a
one-shot scheduled task with an interactive logon for that user, whose output and exit code come back through the SSH
session, and which is deleted afterwards even if the run is stopped (nothing persistent is left, and power and sleep
settings are not touched). While it runs, windows may flash on that desktop. If nobody is logged in, those tests are
reported as `SKIPPED` (not passed) in the summary and the exit status is 77; the one-line fix is to log in to the PC (it
can be locked afterwards) and run the script again.

**Timing checks in tests.** A test that asserts a speed budget scales it with `fa::test_speed_budget_scale()`
(`fa/core/perf.h`): 4 on an MSVC Debug build, whose unoptimized code ran `script_instrument`'s 1000 ms check in 2.1 s,
and 1 everywhere else, so an optimized build keeps the tight budget.

`--wsl` fetches the commit into its own clone `~/FactorIA-preflight` in WSL (made by the first run, from the PC's
`repo.git`); your `~/FactorIA` there is not used. It needs the WSL set-up of "Continuous integration" above, with
`ANDROID_NDK_HOME` exported in `~/.profile` for the android job. The linux job runs its tests under `xvfb-run` whenever it is
installed (WSL sets `DISPLAY=:0` in an SSH session where no X server answers) and with `LP_NUM_THREADS=4`, like the CI job's
4 vCPUs: llvmpipe's memory grows with its threads, and the examples' `peakMemoryMB` baselines were measured with four.
The perf budget tests (`*_perf`) are left out of the WSL run, as in `scripts/ci-docker.sh`: WSL on the PC measures about
10% more peak memory than GitHub's runner with the same commit, so they would fail without a regression
(`FA_CI_WSL_PERF=1` runs them). The CI job on GitHub's runner checks them, and `scripts/test-all.sh` runs them on this host.

## What the agents cost

The engine is developed with Claude Code: a main session (the orchestrator) that hands packages to subagents (workers
and reviewers; CLAUDE.md, "Agent work"). `scripts/agent-usage.py` adds up what each of them really used, from the
transcripts Claude Code keeps on this machine (`~/.claude/projects/`); nothing is sent anywhere.

```bash
python3 scripts/agent-usage.py                 # the 5 sessions of this checkout that changed last
python3 scripts/agent-usage.py --agents 24b6   # one session (the start of its id), one line per subagent
```

Every model call sends the whole context again, so an agent costs its calls times its context, not the tokens it
wrote: the token count the Agent tool reports for a subagent is not its cost. The script prints, for the main session,
for all its subagents and for each kind and model of subagent:

- `calls`: model calls, one per turn of the agent. `ctx`: the context of a call, median and largest.
- `in`, `write`, `read`, `out`: new input tokens, tokens written to the prompt cache, tokens read from it, output.
- `units`: one number for the row, in input tokens of its model: input + 1.25 x cache writes (2 x for the one-hour
  cache) + 0.1 x cache reads + 5 x output. A unit of a bigger model costs more: compare rows of the same model.
- `compact`: how many times the context filled up and was summarized. Each time the agent loses details and reads
  files again. `rewrites`: calls that wrote most of their context to the cache again (after a summary, or after a pause
  longer than the cache keeps it).

What three milestones (M70, M90, M91) showed, and what the rules in CLAUDE.md and `.claude/agents/` come from:

- The subagents are about four fifths of a milestone: the workers two thirds to three quarters, the reviewers an
  eighth. The orchestrator is the rest, in tokens of the biggest model.
- A worker made 243 calls on average with a context near 90,000 tokens, and 94% of its messages carried one tool call.
  Independent calls in one message (three files, two searches) are the cheapest saving there is.
- A package that ends within about 150 calls fills its context once at most. One that filled it again and again (534
  calls, 19 summaries) used five times what an average worker does. Split packages until none is large.
- That worker ran on a bigger model and used more than half of what the eight workers on the middle model used
  together, in tokens that cost more; a bigger model did not save review rounds either (M70). The bigger model is for
  code this machine cannot test, not for big packages.
- One tool call in ten was a wait or a look at a build that the harness had moved to the background:
  `scripts/agent-build.sh` above exists for that.
- An agent whose file in `.claude/agents/` has a `tools:` list starts with about 12,000 tokens of context. A
  `general-purpose` agent starts with 52,000 and an `Explore` one with 36,000: they carry the definition of every tool
  of the session, and every call sends it again. Audits, triage and research go to the `researcher` agent for that
  reason (those runs were 8% of all the subagents' units, about a third of it tool definitions they never used).
- A one-hour prompt cache would cost more than it saves here (a one-hour write costs 2 x, a five-minute one 1.25 x,
  and most rewrites follow a summary or a pause of hours).

## Troubleshooting

**`CMake Error: Could not use disabled preset "windows-release"`**
The preset is for another operating system. Run `cmake --list-presets` and pick
one for your system, or use the script for your platform.

**`CMake Error: No such preset in ...`**
Check the spelling. The names are in `CMakePresets.json` and `cmake --list-presets`.

**`Does not match the generator used previously: Ninja`**
The build directory was configured with another generator, for example after
switching `-G`. Delete it and configure again: `rm -rf build/<preset>` (Windows:
`rmdir /s /q build\<preset>`). The build scripts do not do this for you.

**`CMake was unable to find a build program corresponding to "Ninja"`**
Install Ninja: `sudo apt-get install ninja-build`, `brew install ninja`, or
`winget install Ninja-build.Ninja`.

**CMake is too old**
FactorIA needs CMake 3.24 or newer. Install a newer CMake from
[cmake.org](https://cmake.org/download/) or the Kitware APT repository. The
scripts print the installed version when it is too old.

**`Could NOT find X11` or `Could NOT find OpenGL` (Linux)**
A development package is missing. Run `./scripts/bootstrap-linux.sh`.

**`ALSA not found: audio output disabled (install libasound2-dev)` (Linux)**
A warning, not an error. The build continues without audio output. Install
`libasound2-dev` and configure again.

**`Could not find toolchain file: .../build/cmake/android.toolchain.cmake`**
`ANDROID_NDK_HOME` is unset or points to the wrong folder. It must be the NDK
folder itself (the one that contains `build/cmake/`). `build-android.sh` checks
this and prints the fix.

**xcodebuild fails: it needs the full Xcode app, not only the command line tools**
Install Xcode from the App Store, open it once, then run
`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.

**`cl.exe not found` (Windows, `windows-ninja-debug`)**
Run from "Developer PowerShell for VS 2022". The Visual Studio generator
(`windows-debug`, `windows-release`) does not need this.

**`cmake not found` (Windows, `build.ps1`)**
Neither `PATH` nor Visual Studio has a CMake 3.24 or newer. Open the Visual Studio Installer, modify the installation
and tick "C++ CMake tools for Windows" (it is part of "Desktop development with C++"), or run
`winget install Kitware.CMake`. `build.ps1` finds Visual Studio's CMake by itself (`vswhere`), no `PATH` change needed.

**`No CMAKE_C_COMPILER could be found`, `FTK1011` or `C1083` with Visual Studio (Windows)**
The checkout is in a folder too deep for Windows' 259-character path limit (`build.ps1` warns about it first). Clone the
repository to a short path such as `C:\src\FactorIA` and build there ("Long paths" above).

**`libOpenGL.so.0: cannot open shared object file`, or `GLIBC_2.38 not found` / `GLIBCXX_3.4.31 not found` (Linux)**
A program built on a newer Linux than the one it runs on. The releases are built in the Steam Runtime sniper container
(`scripts/build-sniper.sh`) so they run on glibc 2.31 and newer; build your own copy the same way.

**CMake cannot find Visual Studio 2022 (Windows)**
Install Visual Studio 2022 with the workload "Desktop development with C++".
Visual Studio 2019 or earlier is not supported by the presets.

**`running scripts is disabled on this system` (Windows)**
Start the script with `powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1`,
or allow local scripts once: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

**Headless tests fail with display, GLX or EGL errors (Linux)**
Run the tests under Xvfb as shown in [Headless and GPU notes](#headless-and-gpu-notes),
and make sure `libgl1-mesa-dri` is installed.

**The build runs out of memory or the machine stops responding**
Limit the parallel jobs: `cmake --build --preset <name> -- -j 2` (or
`cmake --build build/<dir> -j 2`).

**Rebuilds are slow**
Install `ccache` (4.8 or newer; on Windows 4.13 or newer, from its GitHub releases). CMake uses it automatically when
it is on the path (`-DFA_CCACHE=OFF` turns it off; `ccache -s` shows the hit rate). With GCC and Clang, paths inside
the checkout are hashed relative to the build directory, so every checkout and git worktree of the repository shares one
cache: a new worktree reuses what another checkout already compiled (a debugger may then ask where a source file is,
because the recorded paths are relative). With MSVC each checkout keeps its own entries: on a cache hit ccache replays
`cl /showIncludes` with the header paths of the checkout that filled the cache, so Ninja would watch another worktree's
headers and miss changes to its own (stale objects). An MSVC that prints its messages in another language (Spanish:
`Nota: inclusión del archivo:`) gets no ccache at all, and CMake says so when it configures: ccache replays those lines
in UTF-8 while Ninja matches them in the console's code page, so a cache hit would leave the object with no header
dependencies. English messages (`VSLANG=1033` with Visual Studio's English language pack) keep it. With MSVC, Debug objects also carry their own debug information
(`/Z7`) instead of one `.pdb` per target, which ccache needs. Tests find the checkout through the generated
`fa_test_paths.h` (`FA_REPO_ROOT`...); include it only where a test needs a path, so the other tests keep sharing the
cache.
ccache's default size, 5 GB, is too small for this repository once several build trees exist (Debug, Release, the
players, one tree per agent worktree): the cache evicts what the next build needs and half the compiles miss
(`ccache -s` shows it: a cache size at its limit, thousands of cleanups and a hit rate near 50%). Give it room once
per machine: `ccache -M 20G`.
Do not pass `-DCMAKE_CXX_COMPILER_LAUNCHER=ccache` yourself: CMake then uses ccache without the settings that make the
checkouts share the cache, and that build tree compiles everything again.
The engine version lives in a generated header (`fa/core/engine_version.h`, written by `configure_file` only when the
version changes), not in a compile definition, so a version bump only recompiles the files that include it instead of
missing the whole cache.

With the Visual Studio presets CMake cannot launch ccache: copy `ccache.exe` (not a Chocolatey or Scoop shim) as
`cl.exe` into an empty folder and set the environment variables `CLToolPath=<that folder>` and `UseMultiToolTask=true`
before building, as the Windows CI job does.
