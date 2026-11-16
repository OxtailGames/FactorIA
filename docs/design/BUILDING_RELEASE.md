# Building FactorIA: releasing, signing and size budgets

Part of [Building FactorIA](BUILDING.md) (the entry page lists every page).

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
  (`scripts/build-sniper.sh`, "Linux release" in [BUILDING_SCRIPTS.md](BUILDING_SCRIPTS.md#linux-release-scriptsbuild-snipersh)) and run on glibc 2.31 and newer. The jobs `mobile-android` (NDK, `arm64-v8a` and `x86_64`) and
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
| `<name>.zip` (one per example game, `block-push.zip`, ...) and `examples-manifest.json` | The example games of `examples/`, which the download does not carry, and the list that says what each is and what its zip's size and SHA-256 are. `project.create {example}` and the start window's Examples tab download them (see "Example games in the release") | the Linux leg of `package` packs them with its own `factoria` and checks every zip against the manifest |

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

### Example games in the release

The download carries no `examples/` folder (only a clone of the repository has it), so every release publishes each example
game as its own asset, plus one manifest. The pieces and where they live:

- `examples/examples.json` is the **source manifest**, kept in the repository (format `factoria.examples-source/1`): per
  example its `name` (the folder), `title`, `shows` (one line: what the example shows) and `readFirst` (docs to read
  first, as `docs/<NAME>.md` paths). A doctest (`examples_test.cpp`) fails when a folder of `examples/` has no entry, an
  entry has no folder, a doc does not exist or the entries are not sorted by name. **A new example game needs its entry
  here**, or the release job stops.
- `factoria call project.package_examples '{"examples":"examples","out":"dist/examples"}'` (`fa/tooling/examples.h`) writes
  `<name>.zip` per example and `examples-manifest.json`. A zip is the project without `.factoria/`, any other hidden
  folder, `node_modules/`, a top-level `build/`, `.DS_Store`, `Thumbs.db` and `*.actual.png`; entries are sorted by name,
  stored with the DOS date 1980-01-01 and no extra fields, so the same files give the same zip and the same hash.
- The Linux leg of the `package` job of `.github/workflows/release.yml` runs that command with the `factoria` it just
  packed (so it also runs on a pull request that changes the workflow). It packs twice and compares the manifests,
  checks every zip against the manifest with `sha256sum`, `stat` and `unzip -t` (tools that share no code with the
  packer), validates the unpacked `block-push`, and uploads the files as the artifact `FactorIA-examples`; the `publish`
  job attaches them to the release with the packages.
- The **release manifest** `examples-manifest.json` (format `factoria.examples/1`):

  ```json
  {
    "format": "factoria.examples/1",
    "engineVersion": "0.30.0",
    "examples": [
      {
        "name": "block-push",
        "title": "Block Push",
        "shows": "A Sokoban puzzle: ...",
        "readFirst": ["docs/GETTING_STARTED.md", "docs/SCRIPTING.md"],
        "file": "block-push.zip",
        "size": 123456,
        "sha256": "<64 lowercase hex digits of the zip>"
      }
    ]
  }
  ```

  A reader that finds another format number (`factoria.examples/2`) refuses the file and says to update FactorIA: change
  the number only when a field changes meaning or goes away; adding a field a reader may ignore does not need it.
- The assets of the release `v<version>` are at `https://github.com/OxtailGames/FactorIA/releases/download/v<version>/<file>`.
  `examples_asset_url(version, file)` and `examples_manifest_url(version)` build that and nothing else builds it: a client
  needs only the installed version. It refuses a file name with a folder, `..`, `?` or `#`, and every URL it returns passes
  `is_trusted_download_url`. `verify_example_bytes` and `verify_example_file` check a download's size and SHA-256 against
  its manifest entry before anything is unpacked.

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
- Games exported from the download copy the signed `factoria_player` (see [EXPORTING.md](../EXPORTING.md)).

Pull requests from forks never receive the secrets. A pull request from a branch of this repository does, and the
workflow runs on the ones that change `release.yml`: review those like any change that can read the secrets (a GitHub
Environment with required reviewers is the stricter option).

## Player size budgets

Every game ships the same `factoria_player`, so its size is part of every game's size. CI measures it on each platform and
fails when it goes over a budget, so a module that moves into `fa_runtime` or a new dependency shows up in the pull request
that adds it. [EXPORTING.md](../exporting/EXPORTING_CONTENTS.md#size-of-the-player) says what the linker already drops.

- **What is measured.** The file a package ships, from a Release build (a Debug player's size means nothing): a stripped
  copy of `factoria_player` (Linux `strip --strip-all`, macOS `strip -x`, Android `llvm-strip --strip-unneeded`; the build's
  own file is left alone), `factoria_player.exe` as built (its symbols are in the `.pdb`), `factoria_player.js` +
  `.wasm` uncompressed, and for iOS the sum of the device archives the release package carries (`libfactoria_player_main.a`
  and every engine archive it links; no job links a Release app, so there is no linked size, and the archives are larger
  than the app).
- **Where.** `scripts/player-size.sh measure --platform <key>` after the build: `ci.yml` jobs `Linux (Steam Runtime sniper)`
  (`linux-x64`, the build that ships), `macOS` (`macos-arm64`), `Windows` (`windows-x64`, shard 1), `Web` (`web-wasm`) and
  `Android` (`android-arm64-v8a`; this job builds Release since a Debug size is meaningless), and `release.yml`: the Android
  ABIs, `ios-arm64`, `web-wasm` and the three packages (`macos-universal` among them). iOS is measured by `release.yml` only:
  `ci.yml` builds a Debug simulator app. In `ci.yml` the step is the last of its job, after the tests, and runs also when a
  test failed, so one round shows both (in `release.yml` the package job fails at its end for a player over its budget, after
  signing and packaging). The budgets are in `tools/size/player_size_budget.json` (`factoria.size-budget/1`):
  per platform `maxBytes` (what fails), `baselineBytes`, `baselineLibraries` and the files measured.
  `maxBytes: null` means no budget is set yet: the platform is measured and reported and nothing fails.
- **The report.** Each run writes `player-size-<platform>.json` and `.md` (artifact `player-size-<platform>`) and puts the
  markdown in the job summary: the size against the baseline and the budget, and a table of what each library adds. The
  per-library numbers come from the link map the build writes with `-DFA_PLAYER_LINK_MAP=ON` (the jobs that measure set it;
  `player/factoria_player.map`; GNU ld, lld, ld64 and MSVC `/MAP` are read; MSVC's has no sizes, so a library's size is the
  gaps between its public symbols). The map counts what the linker places (no `.bss`, no debug sections), so its total is
  not the file size. The universal macOS player is linked once per architecture and both links write the same map file, so
  its per-library numbers are of one slice (about half of the file): use them to see what grew, not to add up. Where there
  is no map the numbers are the sizes of archives, which are larger than what the linker keeps of them: for the web player
  (its linker's map is not read) the archives the player links (`player/player_libs-<config>.txt`, also written by the
  option), and for iOS the measured archives themselves. A map the script cannot read (an unknown format, a binary file)
  never fails the step: the report's `note` says why, the numbers fall back to the archive list or to none, and only the
  comparison with `maxBytes` can fail. The report says which source it used.
  Input sections that belong to no file (lld's `<internal>` and `lto.tmp` with LTO) are counted under `(lto)`, so the table
  still adds up to the map's total. The artifact is uploaded when the size step ran, also when it failed; when the build
  failed the step is skipped and there is no report (the build's log says why).
- **When a budget fails.** The step prints the platform, the file, the size and the budget, the libraries that grew most
  against `baselineLibraries`, and what to do. If the player should not have grown, find what the change pulled in. If the
  growth is intended, take `player-size-<platform>.json` from the run's artifacts and run
  `scripts/player-size.sh update player-size-<platform>.json` (baseline = that size, `maxBytes` = baseline + 10%, `--percent`
  changes it), commit the budget file and say in the commit message why the player grew. The same command fills a platform
  whose budget is null from its first CI run. After a change that makes the player smaller, update the budget too, so the
  gain is kept (the step prints a notice when the player is 5% under its baseline).
- **Locally.** Build a Release player (`cmake -S . -B build/rel -G Ninja -DCMAKE_BUILD_TYPE=Release -DFA_PLAYER_LINK_MAP=ON
  && cmake --build build/rel --target factoria_player`), then `scripts/player-size.sh measure --platform macos-arm64
  --build-dir build/rel` (the platform key names the budget entry; a Windows build adds `--config Release`).
  `ctest -L size` runs `player_size_script`, the test of the script (schema of the budget file, the four map readers on
  sample maps (a demangled symbol line is not an input section), `measure` on a fake binary over, under and with no budget,
  with an unreadable map, and on archives, `update`). `cmake_check_not_linked` (same label) configures a small project
  where a target reaches `fa_authoring` directly, through a chain and inside generator expressions: every way must fail
  the configure. The script is Python 3 (standard library only); the `.sh` only finds the interpreter, also in Git Bash
  on Windows.

