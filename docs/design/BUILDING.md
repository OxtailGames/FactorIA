# Building FactorIA

FactorIA builds with CMake from one repository on Windows, macOS, Linux, iOS and
Android. Every third-party library is vendored in `external/`, so the only
downloads are the platform SDKs (Visual Studio, Xcode, the Android NDK) and the
packages listed below.

## Pages

This page has the quick start, the requirements, what the agents cost and the troubleshooting list. The rest is split by
topic (each page stays under 60 KB):

- [Build scripts and presets](BUILDING_SCRIPTS.md): one command per platform (`scripts/build.sh`, `build.ps1`, `agent-build.sh`, `agent-build.ps1`, `build-sniper.sh`, iOS, Android), presets, strict builds, the web player.
- [Tests, sanitizers, fuzzing, coverage, golden images](BUILDING_TESTS.md): running tests, sanitizers, fuzzing, coverage, golden images.
- [Releasing, signing and size budgets](BUILDING_RELEASE.md): headless and GPU notes, releasing, code signing, player size budgets.
- [Formatting, before a push, CI](BUILDING_CI.md): formatting and lint, before a push, continuous integration (local, no GitHub minutes), checking Windows from the Mac.

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
- A short checkout path, such as `C:\src\FactorIA` (see "Long paths" in [BUILDING_SCRIPTS.md](BUILDING_SCRIPTS.md)).
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
  (`platforms/web/smoke.mjs` does it headless, "Web" under "Presets" in [BUILDING_SCRIPTS.md](BUILDING_SCRIPTS.md)).

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
repository to a short path such as `C:\src\FactorIA` and build there ("Long paths" in [BUILDING_SCRIPTS.md](BUILDING_SCRIPTS.md)).

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
Run the tests under Xvfb as shown in [Headless and GPU notes](BUILDING_RELEASE.md#headless-and-gpu-notes),
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
