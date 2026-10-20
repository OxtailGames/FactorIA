[Back to the index](../README.md)

# Commands: setup

## `setup.install` (modifies state)

Since 0.1.4.

Install what an export needs: the Android JDK + SDK, the players of other platforms, CMake, the AppImage tools, sokol-shdc (or open Xcode's App Store page).

Downloads and installs one component into $FACTORIA_HOME (default ~/.factoria) and returns {component, changed, steps[], paths, nextSteps[], warnings[], seconds}; every step says whether it was installed or skipped because it was already there. It downloads hundreds of megabytes (setup.status says how many: installSizeMb) and can take minutes: ask the user before calling it. `android`: JDK 21 (Eclipse Temurin) and the Android SDK command-line tools, platform-tools, platform 36 and build-tools 35.0.0 (the SDK found on this computer is reused, except Unity Hub's), saved in ~/.factoria/export.json so `project.export` finds them. It REFUSES with error code `license_required` until acceptLicenses is true: the Android SDK license is a legal agreement between the user and Google, so show the user the text from setup.status (components[].licenses[].text) and set acceptLicenses ONLY after they have read it and said yes; never set it on your own. `players`: the factoria_player of the other desktop OSes plus the prebuilt mobile libraries, for exports to other platforms without building anything; from the GitHub release of this factoria's version (a development build ahead of the last release fails with code `no_release`); platforms narrows it (windows, linux, macos, mobile). `cmake`: CMake 3.31 from Kitware (macOS only, for iOS exports) unless 3.24+ is found; force installs it anyway. `xcode` (macOS): cannot be installed by a program: it opens Xcode's App Store page and returns the steps the user must do (some need their password). `appimage` (Linux x86_64): appimagetool 1.9.1 and the AppImage runtime from github.com/AppImage, about 16 MB, into $FACTORIA_HOME/tools/appimage. `shaders`: the pinned sokol-shdc (github.com/floooh/sokol-tools-bin, 8-12 MB depending on the computer) into $FACTORIA_HOME/tools/sokol-shdc/<commit>/, for source builds and editor-less setups; downloads of factoria carry it. Every download is checked against the publisher's checksum (error code `checksum_mismatch` installs nothing). Other error codes: network, cancelled, unsupported, invalid_argument, failed; the data of the error holds the steps done so far. Example: {"component":"android","acceptLicenses":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `component` | string ["android","players","cmake","xcode","appimage","shaders"] | yes | What to install: android (JDK + Android SDK), players (other platforms' factoria_player + mobile libraries), cmake (iOS export), xcode (guidance only), appimage (appimagetool + runtime for the Linux AppImage export; Linux x86_64 only), shaders (sokol-shdc, compiles custom materials). |
| `acceptLicenses` | boolean | no | android: the user has read the Android SDK license (setup.status components[].licenses) and agreed to it. Without it the install refuses with license_required. Never set it without asking the user. Default false. |
| `platforms` | array | no | players: which players to install (default: every desktop OS but this one, plus the mobile libraries when this factoria has none next to it). "web" installs the web export's player (factoria_player.js + .wasm); every download carries it next to factoria, so it is only fetched when asked for. |
| `force` | boolean | no | android, cmake, players: install again even when it is found (a JDK or CMake that is already there is used otherwise). Default false. |

## `setup.status`

Since 0.1.4.

Check what this computer has for exporting: the Android JDK and SDK, the players of other platforms, CMake, Xcode, the AppImage tools, sokol-shdc.

Returns {home, host, components[]}; each component is {id, title, state, details, paths, problems[], installSizeMb, licenses[], canInstall}. Components: `android` (JDK + Android SDK for APK/AAB exports), `players` (the factoria_player of the other desktop OSes and the prebuilt Android/iOS libraries, from the GitHub release of this factoria's version), `cmake` (3.24+, for the iOS export on a Mac), `xcode` (macOS: status only, it cannot be installed by a program) and `appimage` (appimagetool and the AppImage runtime, Linux x86_64 only: what `project.export` {platform: linux, format: appimage} builds an AppImage with) and `shaders` (sokol-shdc, the shader compiler of custom materials: $SOKOL_SHDC, the one next to factoria or the pinned one under home/tools/sokol-shdc/). state is installed | missing | partial | unsupported (nothing to do on this computer). problems[] says what is missing and how to fix it; `setup.install` fixes everything except Xcode. `licenses` (android only, only while the Android SDK license is not accepted yet) holds {id, title, text}: the full license the user must read and agree to before `setup.install` with acceptLicenses. The only network request is the fetch of that license text (fetchLicenses false skips it). Everything installed lives under `home` ($FACTORIA_HOME, default ~/.factoria). Details: docs_read {"name":"exporting"}. Example: {"component":"android"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `component` | string ["android","players","cmake","xcode","appimage","shaders"] | no | Only this component (default: all of them). |
| `fetchLicenses` | boolean | no | Download the Android SDK license text when the license is not accepted yet (a network request). false = skip it (a polling UI). Default true. |

