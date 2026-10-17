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
| `smoke` | sniper **runtime** (`.../sniper/platform`: the image games run in, with no compilers and nothing installed) | `ldd` finds every library, `factoria_player --version`, `factoria version` (the same version), `factoria new --template 2d-empty` and `factoria run --headless --frames 1` with a screenshot (EGL surfaceless on Mesa's llvmpipe). |

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
- **macOS.** Headless rendering uses Metal. The whole suite runs, GPU tests included, here and in CI. The editor
  autotests (`editor_autotest`, `editor_autotest_welcome`) open a real editor window for a few seconds, so they need the
  logged-in desktop session (hosted runners have one).
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
   engine developers (no pull request numbers, authors, CI or internal names).
2. `.github/workflows/release.yml` builds and smoke-tests the packages and publishes them as a GitHub Release with that
   section as its notes; without the section it fails before publishing.
   The same workflow runs, without publishing, on a pull request that changes it and on "Run workflow".

A release holds these files (the header of `release.yml` says the same):

| File | What it is | How CI checks it |
|---|---|---|
| `FactorIA-windows-x64.zip` | Windows package; what the editor's updater downloads, also for a copy made by the installer | `version`, `new`, `test`, `export` from a temp folder |
| `FactorIA-windows-x64-setup.exe` | Installer of the same files, built with Inno Setup from `platforms/windows/FactorIA.iss`: per user (no administrator prompt) into `%LOCALAPPDATA%\Programs\FactorIA`, Start menu entry, folder on the user PATH (once), uninstaller | Silent install, PATH entry read from the registry, `factoria version/new/test` from the installed copy, a second install (no second PATH entry), silent uninstall (PATH entry, shortcut, files and the updater's leftovers gone) |
| `FactorIA-macos-universal.tar.gz` | arm64 + x86_64 in one binary (`CMAKE_OSX_ARCHITECTURES="arm64;x86_64"`); what the editor's updater downloads | `lipo -archs` lists both; the Intel half runs through Rosetta when the runner has it |
| `FactorIA-macos-arm64.tar.gz` | The same file, only because editors up to 0.1.2 download this name. Remove the `publish` step that copies it once nobody runs them | none (a copy) |
| `FactorIA-linux-x64.tar.gz` | Linux package; what the editor's updater downloads. Built in the Steam Runtime sniper container: needs glibc 2.31 or newer | `build-sniper.sh all` (symbol versions, then `--version`, `new` and a headless frame inside the sniper runtime), then as the zip |
| `FactorIA-linux-x64.AppImage` | The same files in one file (`scripts/package-appimage.sh`, `platforms/linux/`): no arguments open the editor, arguments are the `factoria` command, a link named `factoria` is the CLI. No self-update. Like the tar.gz it uses the system's X11, OpenGL and ALSA and needs glibc 2.31 or newer (built in the sniper container) | `--appimage-extract-and-run` (the runner has no FUSE): `version`, `new`, `test`, `export`, the `factoria` link prints the help, and with no arguments the editor stays open under Xvfb |

The names carry no version, so `releases/latest/download/<name>` is always the newest. The AppImage tool and its
runtime are pinned by version and SHA-256 in `scripts/package-appimage.sh`; to upgrade, change both together. Locally:
`scripts/package-appimage.sh <unpacked FactorIA folder> out.AppImage` on Linux; on Windows, with Inno Setup 6.3 or newer,
set `FA_INSTALLER_VERSION` and `FA_INSTALLER_SOURCE` and run `ISCC /O<dir> platforms\windows\FactorIA.iss` (the top of the
`.iss` file has the example).

### Code signing

Both are optional and off until the repository secrets exist (Settings > Secrets and variables > Actions): without them
the signing steps print a notice (`::notice`) and the packages come out unsigned, as before. `scripts/sign-windows.sh`
and `scripts/sign-macos.sh` do the work and can be read for the exact commands.

**Windows** (signtool, SHA-256, timestamped with DigiCert's server; signs `factoria.exe`, `FactorIA-Editor.exe`,
`factoria_player.exe` before they go into the zip and the installer, then `FactorIA-windows-x64-setup.exe`; the
uninstaller inside the installer stays unsigned):

| Secret | Value |
|---|---|
| `WINDOWS_CERT_PFX_BASE64` | The code signing certificate with its private key as a `.pfx`, base64 encoded: `base64 -w0 cert.pfx`, or in PowerShell `[Convert]::ToBase64String([IO.File]::ReadAllBytes('cert.pfx'))` |
| `WINDOWS_CERT_PASSWORD` | The password of the `.pfx` |

**macOS** (hardened runtime, timestamped; the executables go to Apple in a temporary zip, because `notarytool` takes
zip, pkg or dmg and not a bare executable):

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
- When the first signed release is out, drop the SmartScreen and Gatekeeper workarounds from `README.md`, `docs/GETTING_STARTED.md`
  (and their `i18n` translations).
- Games exported from the download copy the signed `factoria_player` (see [EXPORTING.md](EXPORTING.md)).

Pull requests from forks never receive the secrets. A pull request from a branch of this repository does, and the
workflow runs on the ones that change `release.yml`: review those like any change that can read the secrets (a GitHub
Environment with required reviewers is the stricter option).

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
| `sniper` | Linux with Docker or Podman; only when named (`./scripts/ci-local.sh sniper`) | the Linux release programs built in the Steam Runtime sniper container, their symbol versions checked, and run in the sniper runtime (`scripts/build-sniper.sh all`) |

Logs go to `build/ci-logs/`. The exit code is non-zero if any job that ran failed.
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

A newer push to the same pull request or branch cancels the older run.
`./scripts/ci-local.sh` runs the same kind of checks on your own machine before
you push.

The mobile jobs also RUN the app: `ios` boots an iPhone simulator while `ios-build` builds the app, then runs it
(`scripts/ios-smoke.sh`), and `android-emulator` boots an API 34 `x86_64` emulator with KVM, installs the debug APK
that `android-apk` built and starts it (`scripts/android-smoke.sh`). Both assert that the process stays alive, the
player logged `player: 60 frames rendered`, an audio device is open and being pulled, the app survives being sent to the
background and back and renders again, a tap in the middle of the screen reaches the player at the middle of the design
(on iOS a UI test taps, `platforms/ios/touch-test`), nothing crashed and the screenshot shows a picture (Android also
changes the font size), and upload their logs, the screenshot and crash reports as the artifacts `ios-smoke` and
`android-smoke` (look there when one of them fails). The Android game also carries a native plugin (built by
`android-apk` with the NDK, outside the game's folder through `FA_CI_PLUGINS`), and the emulator job checks that its
script got the plugin's answers. What they cover and what not is in [MOBILE.md](MOBILE.md).

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
it is on the path (`-DFA_CCACHE=OFF` turns it off; `ccache -s` shows the hit rate). Paths inside the checkout are hashed
relative to the build directory, so every checkout and git worktree of the repository shares one cache: a new worktree
reuses what another checkout already compiled. The price: with MSVC, Debug objects carry their own debug
information (`/Z7`) instead of one `.pdb` per target, and a debugger may ask where a source file is, because the
recorded paths are relative. Tests find the checkout through the generated `fa_test_paths.h` (`FA_REPO_ROOT`...);
include it only where a test needs a path, so the other tests keep sharing the cache.

With the Visual Studio presets CMake cannot launch ccache: copy `ccache.exe` (not a Chocolatey or Scoop shim) as
`cl.exe` into an empty folder and set the environment variables `CLToolPath=<that folder>` and `UseMultiToolTask=true`
before building, as the Windows CI job does.
