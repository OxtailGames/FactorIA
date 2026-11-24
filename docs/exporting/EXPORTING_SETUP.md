# Exporting a game, page 2 of 6

Part of [Exporting a game](../EXPORTING.md) (the entry page lists every page).

## Setting up this computer

An export needs things that are not part of FactorIA: a JDK and the Android SDK for an APK or AAB, the `factoria_player`
of the other operating systems, CMake and Xcode for iOS. FactorIA installs what it can instead of only telling you what to
install:

```bash
factoria setup                                     # what this computer has and what is missing (writes and downloads nothing)
factoria setup android                             # JDK 21 + Android SDK; shows the Android SDK license and asks first
factoria setup android --accept-licenses           # you have read the license and accept it (scripts)
factoria setup players                             # the players of the other desktop OSes + the Android/iOS libraries, for this version
factoria setup players --platforms windows,linux   # only these (windows, linux, macos, mobile, web)
factoria setup webplayer                           # a development build: builds the web player from the engine checkout (Emscripten, preset web-release)
factoria setup cmake                               # CMake 3.31 for the iOS export, unless a CMake 3.24+ is found
factoria setup xcode                               # macOS: checks Xcode, opens its App Store page when it is missing
factoria setup appimage                            # Linux x86_64 (and WSL): appimagetool + the AppImage runtime, for --format appimage
factoria setup shaders                             # sokol-shdc, the shader compiler of custom materials (the factoria downloads already have it next to factoria)
factoria setup ffmpeg                              # ffmpeg, so --record-video trailer.mp4 works without installing it by hand
factoria setup launcher                            # macOS/Linux: an app that opens the editor with the FactorIA icon (Dock, Launchpad, app menu)
factoria setup directstorage                       # the DirectStorage DLLs a Windows export with export.pack.directStorage ships with the game
```

| Component | What it installs | Download | The export that needs it |
|---|---|---|---|
| `android` | Eclipse Temurin JDK 21, the Android command-line tools (revision 22.0, the classic Java `sdkmanager`), `platform-tools`, `platforms;android-36`, `build-tools;35.0.0`, the Android SDK license | about 500 MB (0.9 GB on disk) | `--platform android` (APK/AAB through Gradle) |
| `players` | `factoria_player` of every desktop OS but this one, and `mobile/` (the Android and iOS libraries, from the macOS package, on any OS), from the GitHub release of this factoria's version | about 60 MB | `--platform windows\|linux\|macos` for another OS; Android and iOS without the engine source |
| `players` with `--platforms web` | `web/` (`factoria_player.js` + `factoria_player.wasm`), from the download of this machine's own OS. Every download has `web/` next to `factoria`, so this is only for a factoria without it | about 15-33 MB | `--platform web` ([Web](EXPORTING_WEB.md#web)) |
| `webplayer` | the web player built from the engine checkout this factoria was built from (`cmake --preset web-release`), into `build/web-release/player/`, with the Emscripten SDK it finds or the pinned 6.0.10 fetched into the checkout's `.cache/emsdk`. `unsupported` for a factoria without its checkout (a download) | about 1 GB for Emscripten when none is found, then several minutes of build | `--platform web` of a development build ([A development build](EXPORTING_DESKTOP.md#a-development-build-players-from-the-checkout)) |
| `cmake` | CMake 3.31 from Kitware, only when no CMake 3.24+ is found (`--force` installs it anyway) | about 75 MB | `--platform ios` (`build_ios.sh`) |
| `xcode` | nothing: Xcode comes from the App Store and needs your Apple ID and password, so this only checks it, opens its page and lists the steps | - | `--platform ios` |
| `shaders` | sokol-shdc, the shader compiler of custom materials, at a pinned commit of `github.com/floooh/sokol-tools-bin`: the one file for this computer (Windows, Linux or macOS, x64 or arm64), checked against a SHA-256 compiled into FactorIA. The factoria downloads carry the same file next to `factoria`, so this is for a factoria built from source, or when that copy is gone | about 8-12 MB | compiling `*.material.json` (`factoria validate`, `run`, `export`); see below |
| `ffmpeg` | ffmpeg 6.0, the static GPL build of `github.com/eugeneware/ffmpeg-static` (release `b6.0`, with libx264 and AAC): the one gzip file for this computer (Windows x64, Linux and macOS x64 or arm64), checked against a SHA-256 compiled into FactorIA and unpacked to `$FACTORIA_HOME/tools/ffmpeg/b6.0/`. Skipped when an ffmpeg is already found | about 19-28 MB | `factoria run --record-video trailer.mp4` ([Recording a replay as a video](EXPORTING_STORES.md#gameplay-video-from-a-replay)) |
| `appimage` | appimagetool 1.9.1 and the type 2 AppImage runtime 20251108 from `github.com/AppImage`, each checked against a SHA-256 compiled into FactorIA. Only on Linux x86_64 (`unsupported` elsewhere) | about 16 MB | `--platform linux --format appimage` ([Linux: AppImage](EXPORTING_DESKTOP.md#linux-appimage)) |
| `launcher` | nothing is downloaded: an app that opens this factoria's editor with the FactorIA icon. macOS: `~/Applications/FactorIA.app` (for the Dock, Launchpad and Spotlight; the editor's output goes to `~/Library/Logs/FactorIA/editor.log`), registered with Launch Services so the Dock shows the new icon. Linux: `factoria.desktop` and its 256 px icon under `~/.local/share` (or `$XDG_DATA_HOME`). `partial` when it opens another factoria, was not written by FactorIA, or carries an older version or icon; the editor rewrites, at start, one that opens it but is out of date (after an update or a reinstall). `unsupported` on Windows, where the installer adds the Start menu entry | - | none: it is how a person opens the editor |
| `directstorage` | the NuGet package Microsoft.Direct3D.DirectStorage 1.3.0 (a zip), checked against a SHA-256 compiled into FactorIA; only its x64 `dstorage.dll` and `dstoragecore.dll` (redistributable) and its `LICENSE.txt` are kept, in `$FACTORIA_HOME/tools/directstorage/1.3.0/`. Any computer can install it: the DLLs are copied, never run here | about 3 MB | `--release --platform windows` with `export.pack.directStorage` ([Compression and pack order](EXPORTING_DESKTOP.md#compression-and-pack-order)); without it that export warns and the game decodes on the CPU |

Everything lands under `$FACTORIA_HOME` (default `~/.factoria`, `%USERPROFILE%\.factoria` on Windows):

```
~/.factoria/
  android/jdk/          Eclipse Temurin 21
  android/sdk/          cmdline-tools/22.0, platform-tools, platforms/android-36, build-tools/35.0.0, licenses/
  android/user/         what Google's tools keep for themselves ($ANDROID_USER_HOME): about 4 MB (sdkmanager's package-list cache) with the pinned tools, about 250 MB if the fallback below applies
  players/<version>/    windows/factoria_player.exe, linux/factoria_player, macos/factoria_player, mobile/, web/ (only when asked for)
  tools/cmake/          CMake (CMake.app on macOS)
  (the checkout)        build/web-release/player/ and .cache/emsdk/: what `setup webplayer` builds and fetches, inside the engine checkout, not here
  tools/appimage/       appimagetool-<version>-x86_64.AppImage and runtime-<version>-x86_64 (Linux x86_64 only)
  tools/sokol-shdc/     <commit>/sokol-shdc[.exe] (folders of older commits are removed by the next install)
  export.json           machine settings: learns where the JDK and the SDK are (below)
```

Nothing else on the computer changes: no `sudo`, no `PATH`, no registry. A JDK or SDK that is found already (`android.jdk`,
`JAVA_HOME`, `ANDROID_HOME`, Android Studio's) is used and only completed with what is missing, never replaced; Unity Hub's
belongs to Unity and is never touched (FactorIA sets up its own next to it). Only what was installed here is written to
`export.json`. Running a setup again is safe: it skips what is there and says so.

**From the editor.** File > Set Up This Computer... opens a window with the components, their state, what is missing
and an **Install** button each, with a progress bar, **Cancel** and a log while it runs and the report (steps, warnings, next
steps) when it finishes. The Export window and the Platform settings tabs show the button that fixes what their row
lacks, in plain words (**Install Android build tools**, **Download Windows player**, **Download mobile libraries**, **Install CMake**,
**Open App Store (Xcode)**). A button calls `fa::setup_install`, the function behind `factoria setup` and `setup.install`, on a
worker thread: nothing is installed any other way. See [the editor](../editor/EDITOR_SETUP.md#setting-up-this-computer).

**The Android SDK license** is a legal agreement between you and Google. In a terminal `factoria setup android` prints the
text and asks `[y/N]`; without a terminal it refuses (code `license_required`) until `--accept-licenses` says you have read
it (`factoria setup --json` prints the text). In the editor, **Install Android build tools** shows the full text in a dialog
whose **I accept** button stays disabled until you tick that you have read it and accept. The refusal comes before anything
is downloaded. After you agree, the install
records exactly that license (`android/sdk/licenses/android-sdk-license`, the line Google's tools write for it) and nothing
else: it does not run `sdkmanager --licenses`, which would also accept every other license Google lists (previews, Google TV,
system images...).

**The shader compiler.** Custom materials are compiled with sokol-shdc. The factoria downloads (zip, installer, tar.gz,
AppImage) carry it next to `factoria` (`sokol-shdc.exe` on Windows), so a downloaded FactorIA needs no setup for it.
FactorIA looks for it in this order: the file named by `$SOKOL_SHDC`, a `sokol-shdc` next to the `factoria` program (the
downloads), then `$FACTORIA_HOME/tools/sokol-shdc/<commit>/` (what `factoria setup shaders` installs; `<commit>` is the pinned
sokol-tools-bin commit, and the file is checked against its SHA-256 before it is kept). `setup.status` shows which one was
found (`found next to factoria` for the one of the download); a `$SOKOL_SHDC` that names nothing is reported as a problem rather
than ignored. The release checks the file it bundles against the same pin: on Windows and Linux it is the pinned file byte for
byte (unsigned, so its SHA-256 is the one below); on macOS the pinned x86_64 and arm64 files are joined into one universal file
and signed with `factoria`, so only its two halves match the pin. `tools/shaders/compile_shaders.sh` (engine developers) uses the
same pin and the same folder. **Windows Defender may remove `sokol-shdc.exe`.** It has flagged the pinned file as a threat by
mistake (a false positive, `Trojan:Win32/Bearfoos.B!ml`, a guess of Defender's machine-learning model; the file is an unsigned
command-line compiler, and the SHA-256 of the pinned Windows build is
`43d42c2e477bcc5012420f8d9ff641fedc41d552d165397fff4f2e60ba0d2ebb`, so you can check that a file is the one FactorIA pins:
`certutil -hashfile sokol-shdc.exe SHA256` or PowerShell's `Get-FileHash`). If the file vanishes or cannot be read,
`setup.status` says `missing` and the install says why. Restore it from Windows Security > Virus & threat protection > Protection
history (or allow it there), run `factoria setup shaders` to download the pinned file again into `~/.factoria`, or point
`SOKOL_SHDC` at a copy you trust; FactorIA never changes your antivirus settings. A false positive can be reported to Microsoft at
microsoft.com/wdsi/filesubmission. Games never contain sokol-shdc, only the developer's computer needs it: exported games hold
the compiled shaders, and its licences (and those of what it links) are in `factoria docs licenses` and in the
`THIRD_PARTY_NOTICES.txt` of the downloads.

**Which command-line tools.** The install pins revision 22.0 (`kSetupAndroidCmdlineTools` in `fa/tooling/setup.h`), the
newest whose `sdkmanager` is still the classic Java program: `bin/sdkmanager` starts `SdkManagerCli` from `lib/*.jar`, it
fetches only the packages it is asked for and keeps nothing but its package-list cache (about 4 MB) in `android/user`. The
newest revision (23, which Google's list calls `cmdline-tools;latest`) turned `sdkmanager` into a shell script in front of
Google's "Android CLI": it unpacks itself into `android/user` (about 250 MB) on first use, shows Google's terms and sends
Google usage statistics under Google's privacy policy, and `sdkmanager` has no switch for that (the `android` program next to
it has `--no-metrics`). Only when Google's list no longer offers the pinned revision (missing or marked obsolete) does the
install fall back to `cmdline-tools;latest`; it then says so in the `warnings` of its report, and that note, the 250 MB and
the statistics apply. Update FactorIA to get a build that pins a revision that still exists. An SDK you already have (Android
Studio's, `ANDROID_HOME`) keeps the tools it has (`--force` adds the pinned revision next to them, and that one is used);
Google's tools always run with `ANDROID_USER_HOME` inside the FactorIA folder.

**What is trusted.** Downloads come only from `api.adoptium.net` and `github.com/adoptium` (JDK), `dl.google.com` (SDK),
`api.github.com` and `github.com/OxtailGames/FactorIA/releases` (players), `github.com/Kitware/CMake` (CMake) and
`github.com/AppImage` (appimagetool and the runtime; two pinned releases) and `raw.githubusercontent.com/floooh/sokol-tools-bin` (sokol-shdc; one pinned commit); a listing
that points anywhere else is refused. Every file is checked against the checksum its publisher lists (SHA-256 from Adoptium,
GitHub and Kitware, SHA-1 from Google's package list, a SHA-256 compiled into FactorIA for the two AppImage files and for sokol-shdc) before it is unpacked, and a mismatch (code `checksum_mismatch`)
installs nothing. Archives are unpacked next to their destination and moved into place only when complete, so an
interrupted install never looks installed. The programs used are `curl` (macOS, Windows 10+ and most Linux have it;
`HTTPS_PROXY` is honored), `tar` (macOS, Windows) and `tar` or `unzip` (Linux).

**`players` needs a release.** It downloads the packages of release `v<version>` of `OxtailGames/FactorIA`, the version that
`factoria version` prints. A development build ahead of the last release fails with code `no_release` and names the newest
release; build the player on the other OS (docs/design/BUILDING.md, repository only, not in the binary) and pass it with `--player`, or use a downloaded factoria. A
player has to match the factoria that copies it into a game, which is why the folder carries the version.

**The export uses what was installed.** `--player` and `--mobile-dir` still win; then the `mobile/` folder next to
`factoria`; then `players/<version>/` of the FactorIA home (`fa::installed_player`, `fa::installed_mobile_dir`). The Android
toolchain is read from `export.json` (below) and CMake is `fa::find_cmake`: `PATH`, Homebrew, `/Applications/CMake.app`, then
`tools/cmake` (`build_ios.sh` runs `FACTORIA_CMAKE` when it is set, else the CMake the export found, else `cmake` from `PATH`).

**From an AI.** An AI checks, the user installs. `setup.status {"component":"android"}` (MCP tool `setup_status`; it runs
the tools it probes and may fetch the Android license text, so it is not a pure read) returns each component's `state`
(`installed`, `missing`, `partial`, `unsupported`), `problems[]`, `installSizeMb` and, while the Android license is not
accepted, `licenses[]` with its full text. An AI reads that and tells the user what to do: press the editor's **File > Set Up
This Computer...** button for the component or run `factoria setup <component>`. `setup.install` installs software outside the
project and accepts licenses, which is the user's call: it needs `writeAnywhere`, so an MCP client or an AI agent gets
`capability_denied`; only the command line (`factoria setup`, `factoria call setup.install`) and the editor's buttons run it. Its
result is the `steps[]` (each `installed`, `skipped` or `guidance`), `paths`, `nextSteps` and `warnings`; errors carry a `code`
(`license_required`, `checksum_mismatch`, `network`, `no_release`, `cancelled`, `unsupported`, `invalid_argument`, `failed`) and the
steps done before the failure. An install downloads hundreds of megabytes, and `acceptLicenses` is set only by the user who has
read the license text. C++: `fa/tooling/setup.h` (`fa::setup_status`, `fa::setup_install`); the editor's Export window builds its
buttons on it.

Tests: `FACTORIA_SETUP_ONLINE_TESTS=1 ctest -R tooling` also reads the real Google, Adoptium and GitHub listings (a few
hundred KB, nothing is installed) to catch a changed format, or Google dropping the pinned command-line tools revision.

## Platform settings

What an export needs besides the game itself (an icon, the Android version code, a Mac app category, a signing key...)
is set in two places:

- **`factoria.json`** (committed with the game): a top-level `icon` and an `export` object with one object per
  platform. Everything is optional and every field has a default; the file is documented field by field in
  `schemas/project.schema.json` (`factoria api --schema project` prints it; its descriptions are the reference for AIs).
  The editor's [Platform settings window](../editor/EDITOR_SETUP.md#platform-settings) edits exactly these keys.
- **`~/.factoria/export.json`** (this computer only, never in a project): where the Android SDK and JDK are, and the
  keystore passwords.

The desktop and iOS exports read every field that concerns them (the Desktop and iOS sections below say where each one
goes). Until another platform's export reads a field, setting it changes nothing in that export. `factoria validate`
checks all of them, and the C++ API (`fa/tooling/export_settings.h`, `fa/tooling/icons.h`) reads, writes and applies them.

### Icon

One square image, `"icon": "assets/icon.png"` (project-relative path, forward slashes, inside the project; PNG or JPG;
1024x1024 recommended, at least 512x512). Each platform's export generates what that platform needs from it: the `.icns`
of a macOS app (16 to 1024 px and the @2x sizes), the icon resource of the Windows exe (16 to 256 px), the launcher icons
of Android (mipmaps from 48 to 192 px, a round variant and the adaptive icon), the App Store icon of iOS (1024x1024 with
no transparency) and the PNG of a Linux build. `export.<platform>.icon` replaces it for one platform. No icon at all
means the platform's default icon (and a warning from the export).

No image tool or provider? `assets.draw_icon` draws the icon and the Android foreground from shapes and text
([ASSETS.md](../assets/ASSETS_REVIEW.md#the-game-icon-without-a-provider-assetsdraw_icon)).

The same image is the window icon of the running game on Windows and Linux (title bar and taskbar, also when the game
is started from `factoria run`): the player reads `icon`, or `export.<this platform>.icon`, from `factoria.json` and hands
it to the window in 16 to 256 px. On macOS the Dock icon comes from the `.app`; mobile has no window. A missing or
unreadable icon is a warning in the log, never an error at run time (the export and `factoria validate` do report it).

A smaller or non-square image is accepted with a warning (`factoria validate` shows it); a non-square one is centered on a
transparent square of its longer side. Scaling averages the pixels (premultiplied by alpha, so transparent edges do not
darken) when it shrinks the image, and is bilinear when it enlarges it.

### `export.<platform>`

```json
{
  "icon": "assets/icon.png",
  "export": {
    "macos":   { "category": "public.app-category.games", "minimumSystemVersion": "11.0", "copyright": "Copyright 2026 My Studio",
                 "buildNumber": "7", "entitlements": { "com.apple.security.network.client": true } },
    "linux":   { "categories": ["Game", "ArcadeGame"] },
    "android": { "format": "aab", "minSdk": 26, "targetSdk": 36, "versionCode": 10203,
                 "adaptiveIcon": { "foreground": "assets/icon_fg.png", "background": "#202020" },
                 "permissions": ["android.permission.VIBRATE"],
                 "signing": { "keystore": "keys/upload.keystore", "alias": "upload" } },
    "ios":     { "iconBackground": "#FFFFFF", "teamId": "ABCDE12345", "buildNumber": "7" }
  }
}
```

| Platform | Field | Default | Meaning |
|---|---|---|---|
| all | `icon` | the project's `icon` | Icon of this platform only. |
| macOS | `category` | `public.app-category.games` | `LSApplicationCategoryType` of `Info.plist`. |
| macOS | `minimumSystemVersion` | `11.0` | `LSMinimumSystemVersion`; `major.minor`, 11.0 or newer (the player needs it). |
| macOS | `copyright` | none | `NSHumanReadableCopyright`. |
| macOS | `buildNumber` | the project's `version` | `CFBundleVersion` (`version` stays `CFBundleShortVersionString`): up to three whole numbers separated by dots. App Store Connect wants it to grow with every upload of the Mac App Store package. |
| macOS | `usesNonExemptEncryption` | `false` | `ITSAppUsesNonExemptEncryption` in `Info.plist` (always written, so App Store Connect does not ask about export compliance on every upload). `true` only when the game uses encryption beyond what macOS provides. |
| macOS | `entitlements` | none | Extra entitlements of the Mac App Store signature (`{"com.apple.security.network.client": true}`), merged into the sandbox, plugin and profile entitlements by `sign.macos` with `distribution: "appStore"` ([Mac App Store](EXPORTING_DESKTOP.md#mac-app-store)). Reverse-DNS keys with boolean, string or array values; the sandbox and the identifiers (`com.apple.application-identifier`, `com.apple.developer.team-identifier`, `com.apple.security.inherit`) are not yours to set (the profile gives them). A misspelt well-known key is a warning with a "did you mean". |
| Linux | `categories` | `["Game"]` | `Categories=` of the `.desktop` file (the entries are joined with `;`). |
| Android | `format` | `apk` | `apk`, `aab` (Google Play bundle) or `gradle` (only the Gradle project). |
| Android | `adaptiveIcon.foreground` | the icon scaled into the safe zone | A 108dp layer (432x432 px recommended): only the inner 66dp circle always stays visible. The default shrinks the icon to 66/108 of the layer over transparency. |
| Android | `adaptiveIcon.background` | `#FFFFFF` | `"#RRGGBB"`, or the path of an image that fills the layer. |
| Android | `adaptiveIcon.monochrome` | none | Single-colour PNG with transparency; Android 13 tints it for themed icons. |
| Android | `versionCode` | from `version`: `1.2.3` is `10203` | Whole number that grows with every Google Play upload. |
| Android | `minSdk` / `targetSdk` | `26` / `36` | API levels; `26 <= minSdk <= targetSdk`. |
| Android | `permissions` | none | Extra `<uses-permission>` names such as `android.permission.INTERNET`. `android.permission.VIBRATE` (for `input.vibrate`) is always in the manifest. |
| Android | `signing.keystore` / `signing.alias` | none | Release signing key: the keystore file (project-relative or absolute; keystores are better kept outside the repository) and the key's alias. The passwords are never in the project (below). |
| iOS | `iconBackground` | `#FFFFFF` | The App Store icon cannot be transparent: transparent pixels take this colour, and the PNG is written without an alpha channel. |
| iOS | `teamId` | none | 10-character Apple Team ID for device builds. It is the default of `FA_IOS_DEVELOPMENT_TEAM`: that environment variable, when set, wins. |
| iOS | `buildNumber` | the project's `version` | `CFBundleVersion` (`version` stays `CFBundleShortVersionString`): up to three whole numbers separated by dots. App Store Connect wants it to grow with every upload. |
| iOS | `usesNonExemptEncryption` | `false` | `ITSAppUsesNonExemptEncryption` in `Info.plist`. `true` only when the game uses encryption beyond what iOS provides (HTTPS and other system encryption are exempt). |
| iOS | `privacy` | the engine's entries only | What the game adds to `PrivacyInfo.xcprivacy`: `tracking`, `trackingDomains`, `accessedApis` (`[{"category": "DiskSpace", "reasons": ["E174.1"]}]`), `collectedData` (`[{"type": "PurchaseHistory", "linked": true, "purposes": ["AppFunctionality"]}]`). The categories, reason codes, data types and purposes are in [MOBILE.md](../mobile/MOBILE_PRIVACY.md#store-privacy-forms). Edited in `factoria.json` only (the editor's window leaves it as it is). |
| Windows | `format` | `folder` | `folder`: only `<slug>-windows/`. `msix`: also `<slug>-windows.msix` next to it, the package of the Microsoft Store (`--format msix` wins over it). See [Microsoft Store](EXPORTING_STORES.md#microsoft-store). |
| Windows | `msix.identityName`, `msix.publisher`, `msix.publisherDisplayName` | empty (a placeholder identity) | The package identity, copied from Partner Center > Product identity: `Package/Identity/Name` (like `12345Studio.MyGame`), `Package/Identity/Publisher` (`CN=...`) and the publisher name players see. Without them the package installs on your PC but the Store rejects it. |
| Windows | `msix.displayName`, `msix.description` | the game's name | The name and short description Windows shows. |
| Windows | `msix.backgroundColor` | `transparent` | Tile background: `#RRGGBB` or `transparent`. |
| Windows | `msix.version` | the project's `version` plus `.0` | Four numbers (`1.2.3.0`); the Store needs the fourth to be 0. |
| Windows | `msix.minVersion` | `10.0.17763.0` | Oldest Windows 10 build (version 1809). |
| Windows | `msix.languages` | the project's `localization.languages`, else `["en-us"]` | Language tags the Store lists for the app. |
| All | `export.exclude` (directly in `export`) | `[]` | Project-relative globs no export ships, see [What is shipped](EXPORTING_CONTENTS.md#what-is-shipped-and-what-is-not). |
| Desktop | `export.scriptBytecode` (directly in `export`, not per platform) | `true` | A `--release` export of Linux, Windows or macOS compiles the scripts to bytecode inside `game.pak`; `false` packs them as plain source. See [Scripts as bytecode](EXPORTING_DESKTOP.md#scripts-as-bytecode). |
| Desktop, Web | `export.pack.codecs` (directly in `export`) | `{}` (each type's default) | The codec of an extension inside `game.pak`: `{".json": "zstd", ".bin": "store"}`. Edited in `factoria.json` only. See [Compression and pack order](EXPORTING_DESKTOP.md#compression-and-pack-order). |
| Desktop, Web | `export.pack.codec` | `"auto"` | `"auto"`, `"lz4"`, `"zstd"` or `"gdeflate"`: the codec of every file `game.pak` would compress (a type stored by default, and an extension in `export.pack.codecs`, keep theirs). `"auto"` keeps each type's default, and packs `gdeflate` for a Windows export with `export.pack.directStorage` on. |
| Windows | `export.pack.directStorage` | `false` | With `export.pack.codec` `"auto"` a Windows export packs its compressed files as `gdeflate`, and a `--release` export copies the DirectStorage DLLs of `factoria setup directstorage` next to the game, which reads those files through DirectStorage (a warning when they are not installed: the game then decodes them on the CPU). See [Compression and pack order](EXPORTING_DESKTOP.md#compression-and-pack-order). |
| Desktop, Web | `export.pack.useLoadOrder` | `true` | Writes `game.pak` in the order play sessions first read the files (`.factoria/cache/load-order.json`); `false` packs by path. |

Wrong types or values are errors that name the JSON pointer and the fix
(`factoria.json#/export/android/minSdk: minSdk (34) is higher than targetSdk (30) ...`). An unknown key inside
`export` or a platform object is only a warning, with a "did you mean" (`categroy` -> `category`), because a newer engine
may know keys an older one does not. `fa::save_export_settings` patches the text of `icon` and `export` in
`factoria.json` and nothing else: every other key, the key order, the indentation, the array style and the line
endings stay as they are, fields equal to their default are removed, and a save with no change does not touch the file.

### Machine settings: `~/.factoria/export.json`

`%USERPROFILE%\.factoria\export.json` on Windows; `FACTORIA_HOME` moves it into that folder (`$FACTORIA_HOME/export.json`,
where `factoria setup` installs too) and `FACTORIA_EXPORT_CONFIG` names another file, winning over both. Keys this version
does not know are kept when the file is saved. `factoria setup android` fills in `android.jdk` and `android.sdk` for what it installs.

```json
{
  "format": "factoria.export-config/1",
  "android": { "sdk": "/Users/me/Library/Android/sdk", "jdk": "/path/to/jdk", "keystorePassword": "...", "keyPassword": "..." },
  "sign": { "macos": { "identity": "Developer ID Application: Ada Lovelace (ABCDE12345)", "notaryProfile": "factoria-notary" } }
}
```

| Key | Meaning |
|---|---|
| `android.sdk` | Folder of the Android SDK. Empty = look for it (below). `~/` is the home folder. |
| `android.jdk` | Folder of a JDK 17 or newer (the one that contains `bin/java` and `release`). Empty = look for it. |
| `android.keystorePassword` | Password of the keystore. `FACTORIA_ANDROID_KEYSTORE_PASSWORD` wins over it. |
| `android.keyPassword` | Password of the signing key. `FACTORIA_ANDROID_KEY_PASSWORD` wins over it; when neither is set the keystore password is used. |
| `sign.macos.identity` | The certificate `sign.macos` signs with (`Developer ID Application: Your Name (TEAMID)`). The `identity` argument and `FACTORIA_MACOS_SIGN_IDENTITY` win over it. Not a secret. |
| `sign.windows.pfx` | The code-signing certificate (`.pfx`) `sign.windows` signs with. The `pfx` argument and `FACTORIA_WINDOWS_PFX` win over it. The password is only read from `FACTORIA_WINDOWS_PFX_PASSWORD`. |
| `sign.macos.keychain` | A keychain file that holds the certificate. `FACTORIA_MACOS_KEYCHAIN` and the `keychain` argument win over it. |
| `sign.macos.notaryProfile` | The notarytool keychain profile (`xcrun notarytool store-credentials <name>`). `FACTORIA_NOTARY_PROFILE` and the `keychainProfile` argument win over it. |
| `sign.macos.appStoreIdentity` | The certificate of `distribution: "appStore"` (`Apple Distribution: ...` or `3rd Party Mac Developer Application: ...`). The `identity` argument and `FACTORIA_MACOS_APPSTORE_IDENTITY` win over it. |
| `sign.macos.installerIdentity` | The certificate that signs the `.pkg` (`3rd Party Mac Developer Installer: ...` or `Mac Installer Distribution: ...`). The `installerIdentity` argument and `FACTORIA_MACOS_INSTALLER_IDENTITY` win over it. |

The file is written with owner-only permissions on macOS and Linux because it can hold passwords (loading it warns when
other users can read it). Passwords never go in `factoria.json` or in the files of an export. The Apple ID password of
notarization is the one secret `sign.macos` takes, and only from the environment (`FACTORIA_APPLE_APP_PASSWORD`), never from this file. A secret is also never an
argument of a program FactorIA starts (the process list shows those): see [Secrets and the process list](EXPORTING_STORES.md#secrets-and-the-process-list).

### Finding the Android toolchain

`fa::find_android_toolchain` (it only looks at folders; it starts no process) picks, in order, the first folder that
qualifies:

| | Order | A folder qualifies when |
|---|---|---|
| JDK | `android.jdk`, `JAVA_HOME`, the JDK of `factoria setup android` (`<FactorIA home>/android/jdk`), Android Studio's bundled JDK (macOS `/Applications/Android Studio.app/Contents/jbr/Contents/Home`, Windows `%ProgramFiles%\Android\Android Studio\jbr`, Linux `/opt/android-studio/jbr`, `~/android-studio/jbr`), then Unity Hub's Android JDK (`.../Unity/Hub/Editor/<newest version first>/.../AndroidPlayer/OpenJDK`) | it has `bin/java` and `bin/javac`, and its `release` file says Java 17 or newer (`JAVA_VERSION="17.0.9"`) |
| SDK | `android.sdk`, `ANDROID_HOME`, `ANDROID_SDK_ROOT`, the SDK of `factoria setup android` (`<FactorIA home>/android/sdk`), the usual folder (macOS `~/Library/Android/sdk`, Windows `%LOCALAPPDATA%\Android\Sdk`, Linux `~/Android/Sdk`), then Unity Hub's `AndroidPlayer/SDK` | it has `platform-tools/`, `platforms/` or `licenses/` |

A folder you named (in the file or an environment variable) that does not qualify is skipped with a warning when a later
one does, and is reported as the problem when none does. A missing JDK or SDK is a *problem* that says what to run
(`factoria setup android` installs both; otherwise Android Studio, or a JDK 17+ from adoptium.net, or the command-line tools) and where to set the folder (Platform settings >
Android in the editor, `~/.factoria/export.json`, or the environment variable). An SDK without accepted licenses
(`licenses/android-sdk-license`) only gets a warning: Gradle cannot download a missing SDK platform until you run
`sdkmanager --licenses`.
