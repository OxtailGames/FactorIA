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

- Visual Studio 2022 (Community works) with the workload **Desktop development
  with C++**. It provides MSVC and CMake.
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
| `macos-debug` | macOS | Ninja (Apple Clang) | Debug | yes | Default on macOS |
| `macos-release` | macOS | Ninja | Release | yes | |
| `windows-debug` | Windows | Visual Studio 17 2022, x64 | Debug | yes | Default on Windows |
| `windows-release` | Windows | Visual Studio 17 2022, x64 | Release | yes | |
| `windows-ninja-debug` | Windows | Ninja with `cl` | Debug | yes | Run from a VS Developer prompt |
| `ios` | macOS | Xcode | Debug (`--config Release` to change) | no | iOS devices (arm64), deployment target 16.3 |
| `ios-simulator` | macOS | Xcode | Debug (`--config Release` to change) | no | iOS Simulator SDK |
| `android-arm64` | any host with the NDK | Ninja | Debug | no | `ANDROID_NDK_HOME`, ABI arm64-v8a, API 26 |
| `android-x86_64` | any host with the NDK | Ninja | Debug | no | Android emulator, ABI x86_64, API 26 |

Desktop presets build the tools (`factoria` CLI, MCP server, AI agent, editor)
and the unit tests. Mobile presets build the engine libraries and `factoria_player`.

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

## Headless and GPU notes

FactorIA renders into an offscreen target, so the tests can run without a window.

- **Linux.** Headless rendering uses EGL with Mesa's software renderer
  (llvmpipe). Install `libgl1-mesa-dri` (the bootstrap script does). Windowed
  code needs an X display, so run the tests under a virtual one:
  `xvfb-run -a -s "-screen 0 1280x720x24" ctest --preset linux-debug`.
- **Windows.** Headless rendering uses Direct3D 11. If the machine has no
  hardware adapter, it falls back to WARP, the software rasterizer. Nothing to install.
- **macOS.** Headless rendering uses Metal. CI excludes GPU tests on macOS with
  `-LE gpu`, because hosted runners may not provide a usable GPU.
- **CI.** The workflow in `.github/workflows/ci.yml` runs the same presets on
  each platform. It uploads test output (`Testing` folders and `test-output/**/*.png`
  screenshots) when a job fails.
- **Release packages.** `.github/workflows/release.yml` builds the release presets on Windows, macOS and Linux and
  packages `factoria`, `factoria_player` and (Windows) `FactorIA-Editor.exe` as `FactorIA-<os>.zip` (`.tar.gz` on
  macOS and Linux), one `FactorIA/` folder inside. The jobs `mobile-android` (NDK, `arm64-v8a` and `x86_64`) and
  `mobile-ios` (device, simulator `arm64;x86_64`) build the mobile runtime first; every package gets
  `FactorIA/mobile/android/jniLibs/<abi>/libfactoria_player.so` and the macOS one also `FactorIA/mobile/ios/<sdk>/*.a`,
  so `factoria export --platform android|ios` works from the download without engine source (docs/EXPORTING.md).
  Each package is smoke-tested from a temp folder outside the checkout (`version`, `new`, `test`, `export`); Linux also
  exports an Android game and builds its APK with Gradle (the NDK and CMake hidden from the SDK), macOS exports an iOS
  game and builds it for the simulator. A `v*` tag publishes a GitHub Release; "Run workflow" keeps the packages as
  artifacts. Bump `project(VERSION)` in `CMakeLists.txt` before tagging: the job fails when the tag and
  `factoria version` differ.
- **Updates.** The packages are configured with `-DFA_UPDATE_REPO=<owner/repo>`, so their editor offers each newer
  release (with its release notes, which you can edit on the release page) and installs it in place
  (`tools/editor/src/update.cpp`, docs/GETTING_STARTED.md "Updates"). It is empty by default: builds from source
  never update.

## Continuous integration (local, no GitHub minutes)

CI runs on your own machine with one script. It runs every job the host can run
and reports the others as skipped, with the reason:

```bash
./scripts/ci-local.sh            # all jobs this machine supports
./scripts/ci-local.sh linux      # just one job
```

| Job | Runs on | What it checks |
|---|---|---|
| `linux` | Linux | full build + every ctest suite (GPU tests through Xvfb + Mesa llvmpipe) |
| `windows` | Linux with `g++-mingw-w64-x86-64-posix` (+ `wine64 wine` to run tests) | Windows x64 cross-build (D3D11 backend), every unit-test `.exe` under Wine, and a CLI smoke test that creates, validates, tests and renders a game through D3D11 |
| `android` | any host with `ANDROID_NDK_HOME` (NDK r27+) | `factoria_player` for arm64-v8a |
| `macos` | a Mac | macOS build + ctest |
| `ios` | a Mac with Xcode | iOS Simulator app bundle with a demo game |

Logs go to `build/ci-logs/`. The exit code is non-zero if any job that ran failed.
MinGW is not MSVC: Visual Studio-only issues still need `scripts/build.ps1` on a
Windows PC.

`.github/workflows/ci.yml` runs the full five-platform matrix (Linux, Windows/MSVC,
macOS, iOS Simulator, Android) on GitHub-hosted runners; standard hosted runners
are free for public repositories. It runs once per change:

- **Pull requests**: every push to a branch with an open pull request.
- **`main`**: every push (including merged pull requests).
- **Other branches**: no automatic run, so a PR branch is not built twice. Start
  one by hand from the Actions tab ("Run workflow") or open a pull request.

A newer push to the same pull request or branch cancels the older run.
`./scripts/ci-local.sh` runs the same kind of checks on your own machine before
you push.

The mobile jobs also RUN the app: `ios` boots an iPhone simulator while `ios-build` builds the app, then runs it
(`scripts/ios-smoke.sh`), and `android-emulator` boots an API 34 `x86_64` emulator with KVM, installs the debug APK
that `android-apk` built and starts it (`scripts/android-smoke.sh`). Both assert that the process stays alive, the
player logged `player: 60 frames rendered`, nothing crashed and the screenshot shows a picture, and upload their logs,
the screenshot and crash reports as the artifacts `ios-smoke` and `android-smoke` (look there when one of them fails).
What they cover is in [MOBILE.md](MOBILE.md).

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
Install `ccache`. CMake uses it automatically when it is on the path, except with the Visual Studio presets: there,
copy `ccache.exe` (4.13 or newer, not a Chocolatey or Scoop shim) as `cl.exe` into an empty folder and set the
environment variables `CLToolPath=<that folder>` and `UseMultiToolTask=true` before building, as the Windows CI job
does.
