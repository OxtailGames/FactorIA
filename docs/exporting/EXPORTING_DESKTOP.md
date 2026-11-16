# Exporting a game, page 3 of 6

Part of [Exporting a game](../EXPORTING.md) (the entry page lists every page).

## Desktop (Linux, Windows, macOS)

The `factoria_player` binary is copied next to the game. By default it is taken
from the folder of the running `factoria` binary (or the build tree layout
`<build>/player/`). Exporting for another OS than the one you run on needs a
player of that OS: `factoria setup players` downloads the ones of the release ([Setting up this computer](EXPORTING_SETUP.md#setting-up-this-computer)),
or pass `--player path/to/factoria_player[.exe]` for one built there.

**The player must come from the same build as `factoria`.** Both carry a build fingerprint (the commit they were built from,
with `-dirty` when tracked files had uncommitted changes; `factoria version` prints it). The export reads the player's
bytes, so it checks the player of another OS too, and the web player (`factoria_player.wasm`) and the prebuilt Android
(`libfactoria_player.so`) and iOS (`libfactoria_player_main.a`) libraries; an Android or iOS export that compiles the engine
from a checkout has no prebuilt player to check. A player from another
build stops the export with an error that names both builds: it may lack the components or the script API the game uses, or
fail to start. Fix it by building both from one checkout, or with `factoria setup players` when this `factoria` is the
release those players belong to (for the web: `factoria setup webplayer`, or `factoria setup players --platforms web` on a release;
for Android and iOS: `factoria setup players`, `--mobile-dir`, or `--engine-root` to compile the engine from a checkout).
To bundle that player anyway, pass `--allow-player-mismatch` (the `export` command's
`allowPlayerMismatch` argument): the export goes on and `warnings` says which builds differ. A `factoria` or a player built
outside a git checkout carries `unknown` and is not compared. The same commit with `-dirty` on one side only is a warning,
not an error; the fingerprint does not see which edits a `-dirty` build had, so rebuild both after editing the engine.

#### A development build: players from the checkout

A `factoria` built from a commit after the last release (its version has no release on GitHub) has no players to download:
the players of any release carry another fingerprint. What each player needs:

- **Web.** `factoria setup webplayer` builds it from the checkout `factoria` was built from: it looks for an Emscripten SDK
  (`$EMSDK`, an `emcc` on `PATH`, the checkout's `.cache/emsdk`, `~/emsdk`), fetches the pinned one (Emscripten 6.0.10, the
  version CI uses; about 1 GB, it needs Python 3.10+ and network access) into the checkout's `.cache/emsdk` when there is none,
  and runs the `web-release` preset (CMake 3.24+ and Ninja on `PATH`) through a shell that loads the SDK's own environment. The
  player lands in `build/web-release/player/`, which the web export prefers over an installed one, so the next
  `factoria export --platform web` finds it with no flag. A first build takes several minutes; an up-to-date player is not built
  again (`--force` does). Build `factoria` from the same commit: the fingerprint of an uncommitted checkout ends in `-dirty`
  and the setup says when the two differ. By hand, the same is `source emsdk_env.sh; cmake --preset web-release; cmake --build
  --preset web-release` ([BUILDING.md](../design/BUILDING.md), "Web"; repository only, not in the binary).
- **Windows, Linux, macOS, Android and iOS.** `factoria setup players` does not fail: when `v<version>` has no release it takes
  the players of the newest release, installs them under this version's folder and warns that their fingerprint will not
  match this `factoria`. They run the game when the release is close enough, but an export that uses them stops on the
  mismatch until you pass `--allow-player-mismatch` (`allowPlayerMismatch`). Only when even the newest release cannot be read
  does it fail (`no_release`); then build the player on that OS (docs/design/BUILDING.md, repository only, not in the binary) and pass `--player`.

**A player with no fingerprint** is one from a release older than the check (v0.2.0 and earlier). `factoria setup players`
installs the players of *this factoria's version*, so on a newer `factoria` built from source it would put the same old
player back: the error then says the player predates fingerprints, and the ways on are a player from a newer release (once
one is published and your `factoria` matches it), a player built from your checkout (`--player`), or
`--allow-player-mismatch` when you know the old player runs your game (it lacks whatever the engine gained since; the
warning says so). The check is not relaxed to compare engine versions: only the fingerprint tells two builds apart.

```
linux/windows:  my-game-linux/
                  my-game            (my-game.exe on Windows)
                  my-game.png  my-game.desktop      (Linux only: the icon and the application-menu entry)
                  my-game-x86_64.AppImage            (Linux only, with --format appimage: the whole game as one file)
                  FACTORIA_NOTICES.txt
                  AI_CONTENT_DISCLOSURE.md           (only when assets are made with AI)
                  game/              factoria.json, scenes/, scripts/, assets/ ...
macOS:          my-game-macos/My Game.app/Contents/
                  Info.plist  MacOS/my-game  Resources/AppIcon.icns  Resources/game/...  Resources/FACTORIA_NOTICES.txt
```

With `--release` the `game/` folder is one file, [`game.pak`](#release-build-gamepak), in the same place (next to the
executable; `Contents/Resources` in the `.app`).

The executable is named after the game's slug (`Space Dodge` -> `space-dodge`). A game called `Game`, or whose name has no
letter or digit, has the slug `game`: on Linux its executable is `game-bin`, so it does not sit on the `game/` folder
(`game.desktop` and `game.png` keep the slug; Windows `game.exe` and macOS `Contents/MacOS/game` cannot collide).

The player starts the game found in `game/` next to the executable (inside the
`.app`: `Contents/Resources/game`), else the pack `game.pak` next to it. Command line:

```
my-game [projectDir | game.pak] [--scene scenes/level2.scene.json] [--fullscreen] [--version]
```

`--version` prints the engine version and build the player belongs to (`factoria_player 0.2.0 (build 1a2b3c4d5e6f)`,
what `factoria version` prints after `factoria`) and exits.

**Linux requirements.** The Linux player is built in Valve's Steam Runtime "sniper" container (libstdc++ and libgcc
linked in), so a Linux game needs glibc 2.31 or newer and the usual desktop libraries (`libX11`, `libXi`, `libXcursor`,
`libGL.so.1`, `libEGL.so.1`, `libasound.so.2`): it runs in Steam's Linux runtime (Steam Deck included), on Ubuntu 20.04
and newer, Debian 11 and newer, Fedora and Arch. A player you build yourself with `linux-release` needs at least the glibc
of the machine that built it; `scripts/build-sniper.sh` makes the portable one ([BUILDING.md](../design/BUILDING.md), repository only, not in the binary).

**Native plugins** ([EXTENDING.md](../EXTENDING.md), section G). The export copies the build of every plugin declared for
the platform next to the executable: the contents of the plugin's `windows/` or `linux/` folder (its library and the
ones it needs), or of `macos/` into `Contents/Frameworks` (the ad hoc signature below covers them, with `--deep`). The
player loads them from there. An export for a platform the plugin is declared for but not built for fails and says
which file is missing; `factoria validate` lists those problems for every platform (a warning for each platform other
than this computer's). A plugin is built only for the computer it is built on (`platform.add_backend` and CMake), but the
export of every platform needs its build: get the other platforms' builds from CI or from the other computer (the same
command there) and copy each platform's folder next to the plugin. Without them, pass `--allow-missing-plugins` (the
`export` command's `allowMissingPlugins`): the export leaves out each plugin whose build is missing, with a warning that
names it, and the report lists them in `pluginsLeftOut`. It applies to plugins declared `optional` and to those that are
not (the game then starts, but scripts that call the missing plugin fail, and the warning says so): use it for a build you
test or send to a tester, and build every plugin before the one you publish. A Steam game exported this way has no Steam:
it runs with no platform services (`platform.backend` is `none`). A `plugin.json` in the plugin's `macos/` folder (the entitlements it needs, EXTENDING.md section G)
does not ship in the app: the export writes the entitlements to `<game>.entitlements` next to it, for the signing step
with your Apple developer certificate (the ad hoc signature cannot carry Game Center or iCloud).

Save games go to the OS per-user data folder (`~/.local/share/<id>`,
`%APPDATA%\<id>`, `~/Library/Application Support/<id>`).

Every run writes its log to `log.txt` in that folder (rewritten on each start): it is the file to ask a player for with a
bug report. On Windows the exe is a GUI program, so the game opens no console window. Started from a terminal it still
prints its log there, but the terminal does not wait for it (`start /wait my-game.exe` does); output redirected to a
file or a pipe works as with any program. If the game cannot start at all (no `game/` folder and no `game.pak` next to the exe, or a
pack that is damaged or from another FactorIA version), a double-clicked exe shows the error in a message box.

**Crash reports.** When the game crashes (a fault such as a write through a null pointer or a stack overflow,
`abort()`, an uncaught C++ exception), the player writes a report next to `log.txt` before it ends, into the `crashes`
folder of the save folder. The newest five are kept.

```
<save folder>/log.txt
<save folder>/crashes/crash-20261017T143052Z.txt     the readable report (the UTC time is in the name)
<save folder>/crashes/crash-20261017T143052Z.dmp     Windows only: a minidump
```

The next start of the game logs one line, "the previous run crashed; the report is ...". Ask a player for the
`crashes` folder together with `log.txt`; nothing is sent anywhere by itself. The `.txt` holds the engine and game
versions, the time, the signal or exception (`access violation, write to 0x0`; for an uncaught C++ exception also its
message), the last log lines, and the stack, innermost call first:

```
exception: 0xc0000005 access violation, write to 0x0
stack (innermost first):
#0  factoria_player.exe!fa::Foo::update + 0x2a  (foo.cpp:51)  [0x7ff75d9d83e2]
#1  factoria_player.exe!fa::Engine::step + 0x1c  (engine.cpp:310)  [0x7ff75d9d889e]
```

A frame shows its function, file and line when the symbols of that build are found (on Windows the `.pdb` next to the
exe or in the symbol path), else only `module+offset`. To read a `.dmp`, open it in Visual Studio (File > Open, then
"Debug with Native Only") or WinDbg (File > Open Crash Dump, then `!analyze -v` and `k`) with the `.pdb` and the source of
the exact build that crashed. On Linux and macOS the stack lines read `module(symbol+0xoffset) [address]` (the address
of a caller is shown one byte back, so that it lies inside the call); `addr2line -f -C -e factoria_player <offset>`
(Linux) or `atos -o <binary> -l <load address> <address>` (macOS) turns an offset into a function and line when the
binary has symbols. The system still does what it did on a crash (exit status, core file, its own crash dialog), and a
stack overflow is reported only on the main thread. Android and iOS write their own crash logs (`adb logcat` and
tombstones; Xcode Organizer), so the player does not install the reporter there. Sending reports to a server is not part
of the engine yet.

**Long paths on Windows.** A macOS `.app` nests four folders, so an export into a deep folder easily passes the
260-character limit of Windows paths (MAX_PATH). The export (and every file the engine reads or writes) uses the `\\?\`
form of a path that long, so it works whether or not long paths are enabled on the machine. Explorer, zip tools and
some other programs still cannot open such files: export into a short folder (`--out C:\exports`) when you can.

On macOS the export signs the finished `.app` ad hoc (`codesign --force --deep --sign -`), last, so the signature
covers its `Info.plist`, the game files and the native plugins in `Contents/Frameworks`. The player of a signed release carries FactorIA's Developer ID signature, which covers
the executable alone: copied into a bundle unchanged it fails `codesign --verify` ("code has no resources but signature
indicates they must be present"), and a Mac that downloads such an app calls it damaged. The ad hoc app runs on your
Mac; a copy someone else downloads is stopped by Gatekeeper like any app that is not notarized (with Open Anyway).
Exporting for macOS on Windows or Linux cannot sign: the report warns, and `codesign --force --sign -` on a Mac fixes
it. To distribute the game, sign it with your own Developer ID and notarize it (Apple Developer Program): the command
`sign.macos` does it ([Signing and notarizing for macOS](#signing-and-notarizing-for-macos)). The player of the macOS download
is universal (Apple Silicon and Intel).

### Signing and notarizing for macOS

The ad hoc signature above runs on your Mac. To hand the game to other people you sign it with your Developer ID
Application certificate and have Apple notarize it (Apple Developer Program). The command `sign.macos` does every step on
the exported app (MCP tool `sign_macos`, `factoria call sign.macos`, the editor console, `fa.call`; C++:
`fa/tooling/sign.h`, `fa::sign_macos`):

```bash
factoria export --platform macos
factoria call sign.macos '{"identity":"Developer ID Application: Ada Lovelace (ABCDE12345)","keychainProfile":"factoria-notary"}'
factoria call sign.macos '{"dryRun":true}'      # every command line it would run, on any computer
```

1. `codesign` of every piece of native code in `Contents/Frameworks` (the native plugins: frameworks, bundles, helper apps,
   `.dylib` and `.so` files and other Mach-O files), the deepest first, then of the app: `--force --options runtime
   --timestamp --sign <identity>` (the hardened runtime and a secure timestamp are what Apple asks for).
2. With `provisioningProfile`: the profile is copied to `Contents/embedded.provisionprofile` first, and the app is signed with
   the export's `<game>.entitlements` (below).
3. `codesign --verify --deep --strict`.
4. Notarization: the app is zipped with `ditto`, `xcrun notarytool submit --wait` uploads it and waits for Apple's verdict.
   When Apple refuses the app the error quotes `notarytool log` (typically a library that is not signed with the hardened
   runtime and a timestamp, or a file changed after signing).
5. `xcrun stapler staple` and `validate` (the ticket goes into the app, so it opens offline), then `spctl --assess`:
   Gatekeeper's own verdict.
6. `ditto` writes the stapled app to `<out>/<game-slug>-macos.zip`, next to the export folder: the file to share.

Arguments, all optional (`app` and `out` default to the export of this game, `build/export/<game-slug>-macos/<Name>.app`;
`app`, `out` and `zip` stay inside the project like the `fs.*` commands, the files you point the other arguments at may be
anywhere):

| Argument | Meaning |
|---|---|
| `identity` | The certificate: its name (`Developer ID Application: Your Name (TEAMID)`; `security find-identity -v -p codesigning` lists them) or its SHA-1. `"-"` signs ad hoc (no certificate; the app runs on this Mac only and is never notarized). Default: `FACTORIA_MACOS_SIGN_IDENTITY`, then `sign.macos.identity` of `~/.factoria/export.json`; with none the error says so. |
| `keychain` | A keychain file that holds the certificate (and the notary profile). Default: `FACTORIA_MACOS_KEYCHAIN`, then `sign.macos.keychain`, then the user's keychains. |
| `notarize` | Unset: notarize when there are credentials and the identity is a Developer ID Application certificate, else only sign, with a warning that says why. `true`: that is an error instead of a warning. `false`: only sign. |
| `keychainProfile` | A notarytool profile saved once with `xcrun notarytool store-credentials <name>`. Default: `FACTORIA_NOTARY_PROFILE`, then `sign.macos.notaryProfile`. |
| `apiKey`, `apiKeyId`, `apiIssuer` | An App Store Connect API key instead: the `AuthKey_<id>.p8` file, its key id and, for a team key, the issuer id. Defaults: `FACTORIA_NOTARY_API_KEY`, `FACTORIA_NOTARY_API_KEY_ID`, `FACTORIA_NOTARY_API_ISSUER`. |
| `appleId`, `teamId` | An Apple ID instead. Defaults: `FACTORIA_APPLE_ID` / `FACTORIA_APPLE_TEAM_ID` (also `APPLE_ID` / `APPLE_TEAM_ID`). The app-specific password is read from `FACTORIA_APPLE_APP_PASSWORD` (or `APPLE_APP_PASSWORD`) **only**. |
| `provisioningProfile`, `entitlements` | See below. |
| `distribution` | `developerId` (default): the steps above. `appStore`: sign for the Mac App Store and build the `.pkg` ([Mac App Store](#mac-app-store)); never notarized. |
| `installerIdentity` | `appStore` only: the certificate that signs the `.pkg`. Default: `FACTORIA_MACOS_INSTALLER_IDENTITY`, then `sign.macos.installerIdentity`. |
| `pkg` | `appStore` only: where the `.pkg` goes (default: `<game-slug>-macos.pkg` next to the export folder). |
| `zip` | Where the zip to share goes (default: next to the export folder). |
| `dryRun` | Check everything and return the command lines in `steps[]`; sign and send nothing. |

The login for notarytool is the first of: a keychain profile, an API key, an Apple ID. The result is `{app, dryRun,
identity, identityFrom, credentials, signed, verified, notarized, stapled, notarizationId, zip, distribution, pkg,
steps[], warnings[], nextSteps[]}` (`distribution: "appStore"` adds `installerIdentity`, `pkgSigned`, `entitlements` and `profile`); each step is `{title, command, commandLine, ran, exitCode}`. Nothing secret is ever an argument, is in
`factoria.json`, in a result or in a log: the only secret there is, the app-specific password, comes from the environment,
goes to `notarytool` on its standard input (a step with `stdinSecret: true`; `env` lists the NAMES of the variables a step sets) and is replaced by `<redacted>` in every step and every line of output. A key file or a keychain profile holds its secret
where Apple's tools keep it.

`~/.factoria/export.json` (this computer only, [Machine settings](EXPORTING_SETUP.md#machine-settings-factoriaexportjson)) may carry the
identity, the keychain and the profile name, which are not secrets:

```json
{ "sign": { "macos": { "identity": "Developer ID Application: Ada Lovelace (ABCDE12345)", "notaryProfile": "factoria-notary" } } }
```

**Needs a Mac.** `codesign`, `notarytool` and `stapler` exist only on macOS. Anywhere else a real run is an error that says
so and what to do (copy the export folder to a Mac, or let a macOS CI runner do it: [CI for your game](../EXPORTING.md#ci-for-your-game));
`dryRun: true` always works and prints the commands a Mac would run, with this computer's paths. Export on the Mac too (or
on a macOS CI runner): the export seals the app there, and the files keep their permissions.

**Capabilities that need a profile (Game Center, iCloud).** A native plugin that asks for them makes the export write
`<game>.entitlements` next to the app, with a `TEAMID` placeholder. macOS kills an app that claims such an entitlement
without a provisioning profile for its App ID, so `sign.macos` applies that file **only** together with `provisioningProfile`
(the `.provisionprofile` you create in the Apple Developer portal for the App ID, with the same capabilities). Without a profile
the app is signed without them and the result warns that those services will answer "unavailable". Replace `TEAMID` with your
10-character Team ID first (or set `export.ios.teamId` in `factoria.json` and export again): `sign.macos` refuses a file that
still has the placeholder. `entitlements` signs the app with a file of your own instead.

**Every export replaces the app**: sign again after each `project.export`. An app that is changed after it is signed
(a file added to the bundle) is no longer valid; export and sign again instead of editing it.

### Mac App Store

To sell the game on the Mac App Store the app is signed another way: with the **App Sandbox**, with a distribution
certificate instead of Developer ID, with a provisioning profile, and wrapped in a signed installer `.pkg` that
[`publish.appstore`](EXPORTING_STORES.md#app-store-connect-testflight) uploads. `sign.macos` does it with `distribution: "appStore"`
(Apple Developer Program):

```bash
factoria export --platform macos --release
factoria call sign.macos '{"distribution":"appStore","identity":"Apple Distribution: Ada Lovelace (ABCDE12345)","installerIdentity":"3rd Party Mac Developer Installer: Ada Lovelace (ABCDE12345)","provisioningProfile":"keys/MyGame_MAS.provisionprofile"}'
factoria call publish.appstore '{"platforms":["macos"]}'
```

What you set up by hand first, in the Apple Developer portal (the commands cannot): the App ID of the game (`id` of
`factoria.json`) with its capabilities, an **Apple Distribution** (or "3rd Party Mac Developer Application") certificate, a
**Mac Installer Distribution** (or "3rd Party Mac Developer Installer") certificate, both in your keychain, and a **Mac App
Store provisioning profile** for the App ID (download the `.provisionprofile`). Create the app in App Store Connect too.

The steps (`factoria call sign.macos '{"distribution":"appStore","dryRun":true}'` lists them on any computer):

1. The provisioning profile is read (`security cms -D`): `sign.macos` refuses it when it is expired, does not cover the
   bundle id of `Info.plist`, or does not hold the sandbox's identifiers, and warns when it is not a Mac App Store profile.
2. `lipo -archs` of the executables: a warning when the game is `x86_64` only (App Store Connect expects arm64 to be
   there) or a plugin lacks an architecture of the app.
3. The entitlements are written next to the export folder (`<game-slug>-macos.appstore.entitlements`, and
   `-appstore-inherit.entitlements` for helpers): `com.apple.security.app-sandbox`, those that native plugins ask for,
   the `export.macos.entitlements` extras (`com.apple.security.network.client` for online games,
   `com.apple.security.files.user-selected.read-write` for saves the player chooses, ...), and the identifiers taken from
   the profile (`com.apple.application-identifier`, `com.apple.developer.team-identifier`). The sandbox is mandatory:
   an `entitlements` file of your own without it is refused.
4. Everything in `Contents/Frameworks` is signed with the same identity and `--timestamp`, but **without** the hardened
   runtime (the store does not use it): a helper app, XPC service or tool gets the inherit entitlements
   (`app-sandbox` + `inherit`) so it runs inside the sandbox of the app.
5. The profile is embedded as `Contents/embedded.provisionprofile` and the app is signed with the entitlements.
6. `codesign --verify --deep --strict`, then the entitlements are read back from the signature (`codesign -d
   --entitlements`) and the sandbox must be there.
7. `productbuild --component <app> /Applications --sign <installer identity> <game-slug>-macos.pkg`, then
   `pkgutil --check-signature`.

There is no notarization (the store reviews the app) and no zip. A real run needs a Mac with `codesign`,
`productbuild` and `lipo`. The identity comes from the `identity` argument, then `FACTORIA_MACOS_APPSTORE_IDENTITY`,
then `sign.macos.appStoreIdentity`; a Developer ID certificate is an error here (the store refuses it), and so is a
distribution certificate without `distribution: "appStore"`. The installer certificate comes from `installerIdentity`,
`FACTORIA_MACOS_INSTALLER_IDENTITY`, `sign.macos.installerIdentity`; without it the `.pkg` is built **unsigned** with a
warning (it can be signed later with `productsign`). `provisioningProfile` is required except for `identity: "-"`.

**Trying it here.** `{"distribution":"appStore","identity":"-"}` signs ad hoc with the sandbox: no certificate or profile,
so the app is not accepted by the store and the entitlements that need a profile (plugins') are left out, but the app
**runs sandboxed on this Mac** (its files go to `~/Library/Containers/<bundle id>`), which is the way to find what the
sandbox breaks: saving beside the executable, opening arbitrary paths, network (needs `network.client`). The engine's own
test does exactly that and runs the signed export.

**Other stores.** The sandboxed build is meant for the Mac App Store. Steam and itch.io take the `developerId` build (a
sandboxed game cannot use the Steam client's libraries); `sign.macos` warns when the app carries the Steam, Epic or GOG
plugin, which do not belong in a Mac App Store build.

`publish.appstore` takes the `.pkg` as an artifact: `{"platforms":["macos"]}` or `{"artifact":"build/export/mygame-macos.pkg"}`
(`.ipa` and `.pkg` both present: say which), through `xcrun altool --upload-package <pkg> --type macos --apple-id ...
--bundle-id ... --bundle-version <build> --bundle-short-version-string <version>`, with the same API key as for iOS.
**Not tested against a real upload** (it needs a paid account), and `--type macos` is not verified on the newest Xcode:
if `altool` refuses it, upload the `.pkg` with Apple's Transporter app.

### Linux: AppImage

`--format appimage` also builds the game as **one file** that runs on most Linux desktops without installing anything: the
folder of the Linux export stays, and `<out>/<game-slug>-linux/<game-slug>-x86_64.AppImage` is added next to its files
(reported as `artifact`).

```bash
factoria setup appimage                                    # once: appimagetool and the AppImage runtime (about 16 MB)
factoria export --platform linux --format appimage         # the command: project.export {"platform":"linux","format":"appimage"}
./build/export/my-game-linux/my-game-x86_64.AppImage       # or with --appimage-extract-and-run on a computer without FUSE
```

- **Where it can be built.** On Linux x86_64, or in WSL (Ubuntu) on Windows: `appimagetool` is an x86_64 Linux program. On a Mac,
  Windows or an ARM Linux the export refuses before it writes anything, with an error that says to export on Linux or in WSL;
  without `--format` the Linux export works from any computer and writes the folder (`tar czf` it to share). A CI job can
  build it too ([CI for your game](../EXPORTING.md#ci-for-your-game) exports the folder; add a `factoria setup appimage` step and
  `--format appimage` to its Linux export step).
- **The tools come from `factoria setup appimage`**, never from the export (it downloads nothing): appimagetool 1.9.1 and the
  type 2 runtime 20251108 from `github.com/AppImage`, each checked against a SHA-256 that is compiled into FactorIA (the same
  files and hashes `scripts/package-appimage.sh` packs FactorIA's own AppImage with). They live in
  `<FactorIA home>/tools/appimage/`. Without them the export says to run the setup; `setup.status` lists the component as
  `appimage` (`unsupported` away from Linux x86_64).
- **The AppDir.** Beside the export folder (and removed again, whatever happens) the export builds
  `.<game-slug>-linux.AppDir/` with `AppRun` (starts `usr/bin/<game-slug>`), `<game-slug>.desktop` (the export's entry with
  `Icon=<game-slug>` and `X-AppImage-Version` from the game's `version`), `<game-slug>.png` and `.DirIcon` (the game's icon; a
  plain placeholder and a warning when the game has none) and `usr/bin/` holding the export folder as it is: the player, `game/`,
  `FACTORIA_NOTICES.txt` and the native plugins' libraries. The player finds `game/` and the plugins next to its executable, so
  the layout needs no change. Then it runs
  `ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 appimagetool --no-appstream --runtime-file <runtime> <AppDir> <AppImage>`
  (`APPIMAGE_EXTRACT_AND_RUN` lets the tool run where FUSE is missing: CI, containers, WSL).
- **Running it.** `chmod +x` (the export already does), or **Allow executing as a program** once in a file manager. A
  computer without FUSE 2 starts it with `--appimage-extract-and-run`. The game uses the system's X11, OpenGL and ALSA, and
  needs a glibc at least as new as the player's: the FactorIA download is built on Ubuntu 24.04, so an older distribution may
  refuse it. Save games and `log.txt` go where the folder export puts them.
- **If appimagetool fails** the error quotes what it printed (often a `.desktop` validation: `export.linux.categories`) and the
  export folder stays, complete without the AppImage; fix it and export again.
- **Flatpak is not generated.** An AppImage needs nothing but the file; Flatpak needs a manifest, a runtime and a store
  review. A game that wants it can wrap the folder export.

### Release build (`game.pak`)

`factoria export --release` (or `project_export {"release": true}`) for Linux, Windows and macOS ships the game as ONE
read-only file instead of a `game/` folder of loose files:

```
linux/windows:  my-game-windows/            my-game.exe  game.pak  FACTORIA_NOTICES.txt
macOS:          My Game.app/Contents/       MacOS/my-game  Resources/game.pak  Info.plist ...
```

Every file listed under [What is shipped](EXPORTING_CONTENTS.md#what-is-shipped-and-what-is-not) goes into the pack, compressed with the codec of
its type ([below](#compression-and-pack-order)), and the scripts can be compiled ([below](#scripts-as-bytecode)). Nothing of the
game is left loose: a game of thousands of small files is copied, zipped and installed as one file, and the player of the game
cannot swap a texture or edit a script by opening a folder. (This is packaging, not protection: anyone who knows the format can
read the pack, and the bytecode of a script can be decompiled.) The report has `pack` (`game.pak`), `packed` (every path inside
it) and `packStats` (below); its `files` lists what is on disk.

**How the player uses it.** It looks for `game/` next to the executable first (so a folder always wins, which makes it easy to
try a changed file), then for `game.pak`; `factoria_player path/to/game.pak` runs a pack from anywhere. It mounts the pack into
the virtual file system the whole engine reads through (`fa::fs::mount_pack`, [ARCHITECTURE_FILES.md](../design/ARCHITECTURE_FILES.md), repository only, not in the binary): `factoria.json`, scenes,
prefabs, textures, sounds, fonts, scripts, `import`s and the window icon all come out of it, and a game that works from the folder
works from the pack. Only the index (the list of paths with their offsets) is read at start; a file is read when the game asks
for it, and any number of threads can read at once, so a large pack starts as fast as a small one. On a 64-bit desktop
the pack is memory-mapped once (`mmap`, `MapViewOfFile`): a read is a copy or a decode out of the mapping and the operating
system pages the bytes in; a 32-bit build, the web player (whose pack is in browser memory) and `FA_PACK_MAP=0` read with
positional reads instead, with the same results. While a pack is mounted, a project-relative path that is not in it is "File
not found" with a "did you mean" taken from the pack, whatever lies on disk. Absolute paths and everything the game writes are
not affected: save games go to the per-user data folder as always, and a file written with a project-relative path lands in
the (absent) `game/` folder next to the pack.

**Format** (version 2, integers little-endian; `fa/core/pack.h` is the reference: its top comment has every field, and it holds
the `fa::PackWriter` and `fa::PackReader`): a 16-byte header (`FAPACK\r\n`, `u32` version, `u32` flags), the files' data, an
index and a 24-byte footer (`u64` index offset, `u64` index size, `FAPKEND!`). Each file is cut into blocks of 256 KiB (decoded
size), each block compressed on its own with the file's codec, so reading part of a big file decodes only the blocks that hold
it. The index lists every file sorted by path (path, codec, size, offset, stored size, first block) and then every block
(stored size, an XXH32 checksum), and ends with the checksum of the index itself. The reader checks the index when it opens
the pack and each block when it reads it: a pack cut short (an interrupted download, a full disk) or damaged on the drive is
refused with a message that names the file and the block and says to export again, never read as wrong bytes. Format 1 (the
packs of FactorIA 0.18 and before: files stored as they are, no checksums) is still read; a pack of any other version says
which version it has and which ones this FactorIA reads.

The writer builds `game.pak.tmp` and renames it over `game.pak` once it is complete, so an export never leaves a half-written
pack under the real name, and the same files and settings always give a byte-identical pack (on every platform). A pack is
never changed in place: a game running from the old pack on macOS or Linux keeps its mapped bytes after the rename (writing
into a mapped file would crash that game with `SIGBUS`). On Windows a game that is running from the export folder holds
its exe and the mapped `game.pak` open, and the export stops before it deletes anything, with nothing changed
([Replacing an earlier export](EXPORTING_CONTENTS.md#replacing-an-earlier-export)).

A pack also refuses a file bigger than 64 times the pack's own size (and never less than 256 MiB): a reader treats such an
entry as a damaged pack, so a tampered index cannot make the game allocate gigabytes, and the writer refuses to pack one
(only a file that compresses more than 64 times in a small pack can reach it: give its extension the codec `store`).

#### Compression and pack order

Each file type has a codec (`fa/core/compress.h`, FactorIA's own implementations of the two formats):

| Codec | Files | Why |
|---|---|---|
| `store` | `.png` `.jpg` `.webp` `.gif` `.avif` `.basis`, `.ktx2` with supercompression, `.ogg` `.opus` `.mp3` `.qoa` `.flac` `.m4a` `.aac`, `.mp4` `.webm` `.mov`, `.woff` `.woff2`, archives (`.zip` `.gz` `.zst` `.lz4` `.7z` `.xz` `.bz2` `.pak`) | already compressed: a second pass saves nothing and costs load time |
| `zstd` | fonts (`.ttf` `.otf` `.ttc` `.fnt`), `.txt` `.md` `.csv` `.tsv` `.xml` `.svg` `.html`, shaders (`.glsl` `.wgsl` `.hlsl` `.metal`), `.po` `.pot` `.yaml` `.yml` `.ini` | text read once that compresses well: zstd packs it smallest |
| `lz4` | everything else: `factoria.json`, scenes, prefabs and other JSON, scripts and their bytecode, meshes, `.ktx2` without supercompression, `.wav`, any other data | read on the hot path of a load: lz4 decodes at GB/s |

A block keeps its compressed form only when that saves at least 1/32 of its bytes, else it is stored as it is, so a file
that does not compress costs nothing to decode. Choose another codec for an extension in `factoria.json`:

```json
"export": { "pack": { "codecs": { ".json": "zstd", ".bin": "store" }, "useLoadOrder": true } }
```

`export.pack.codecs` maps an extension (with its dot; `a.scene.json` counts as `.json`; any case) to `store`, `lz4` or `zstd`.
`export.pack.useLoadOrder` (default `true`) writes the files in the order the game first read them. Every play session (the
editor's Play, `factoria run`, `play.auto`) records the files read before its first scene (the group `(start-up)`: what
the engine and the scripts read after `factoria.json`, which is read by its full path and is not listed) and, per scene,
the project files first read while that scene was the current one, and merges them into `.factoria/cache/load-order.json` under the project's lock (a session whose lock is
busy logs a `loadorder` warning and changes nothing; the next one records again). Which session wins: a `factoria run` or a
`play.auto` starts a fresh engine that reads every file it needs itself, so it sets the order of each scene it played (its files
first, in the order it read them, then the ones earlier sessions listed and it did not read), and the scene is marked
`"source": "run"`. The editor's Play has most files cached from Edit mode already, so it never reorders a scene: it only adds
the files the scene did not list yet, at its end. Nothing is recorded for an exported game (a folder inside an export,
found by its `.factoria-export` marker, or any game running from a pack), so `factoria run` on an export never writes into
it. The export then writes the start-up files first, then the main scene's, then each other scene's in the order they were
first played, and the files no session read after them by path: a scene's files lie next to each other and a load reads the
drive mostly forward. The file is a cache; deleting it, or `"useLoadOrder": false`, packs by path. Both keys are edited in `factoria.json` only (the editor's export
window leaves them as they are), and a wrong value is an error with its JSON pointer
(`factoria.json#/export/pack/codecs/.png: ...`, with a "did you mean").

The export prints what the pack holds (an example; the numbers are those of one game):

```
Game pack: 41.2 MB for 63.0 MB of files (65%)
  store  212 files, 38.1 MB
  lz4  140 files, 9.4 MB -> 2.1 MB
  zstd  6 files, 15.5 MB -> 1.0 MB
Pack order: first use in play sessions for 301 of 358 files (the rest by path)
```

and the JSON report has the same in `packStats`: `bytes` (the pack), `fileBytes` (the files it holds), `codecs`
(`[{codec, files, bytes, storedBytes}]`), `order` (`"firstUse"` or `"path"`) and `orderedFiles`. A block the codec could not
compress is stored as it is, and the report has a warning that counts them (the game reads them fine).

#### Scripts as bytecode

With `export.scriptBytecode` on (the default; set `"export": { "scriptBytecode": false }` in `factoria.json` to turn it off), the
`.js` and `.mjs` files go into the pack compiled to QuickJS bytecode, with the QuickJS of the player that ships with the game. They keep
their paths (`scripts/player.js`), so `Script` components, `import`s between scripts and JSON imports are unchanged, and a pack can
mix compiled and plain scripts. The source text is not shipped, but the file names and line numbers are: an error in the
shipped game still reads `scripts/player.js:12:7: TypeError: ...` and the log and `script.errors` give the same file and line as in
development. Loading a compiled script skips parsing, so large scripts start faster.

Bytecode only runs on the FactorIA that wrote it. Each compiled script carries the FactorIA and QuickJS versions, and a game that
meets a script from another one says so instead of crashing:

```
'scripts/player.js' was compiled by FactorIA 0.1.5; QuickJS 0.17.0, but this game runs FactorIA 0.1.6; QuickJS 0.17.0, and compiled
scripts only run on the version that wrote them (hint: Export the game again with this FactorIA version (`factoria export --release`);
export.scriptBytecode: false in factoria.json ships the scripts as plain source instead.)
```

The export copies the player of its own FactorIA, so a pack and its player always match; a mismatch happens when you pass another
`--player`, or put a pack next to a player of another version. `false` packs the scripts as the source they are (readable, and
independent of the player's version). A script that has a syntax error is packed as source with a warning that names the file and
line, so the game behaves as it does from the folder: the error shows when something loads that script (`factoria validate` lists
them before you export). Without `--release`, and on Android and iOS, the setting changes nothing.

Not shipped, so not compiled: `tools/` (JS tool modules, which are for development) and `tests/`. The player never reloads
files while it runs (hot reload belongs to `factoria run` and the editor, which work on the project folder), and a compiled module keeps
the name it was compiled under, so a pack is a fixed game: change a script, export again.

### Icon and settings per platform

What each desktop export takes from [Platform settings](EXPORTING_SETUP.md#platform-settings):

- **macOS.** `Contents/Resources/AppIcon.icns` is generated from the icon (16 to 1024 px, PNG payloads, plus the @2x
  sizes) and `Info.plist` names it with `CFBundleIconFile`. `category`, `minimumSystemVersion` and `copyright` become
  `LSApplicationCategoryType`, `LSMinimumSystemVersion` and `NSHumanReadableCopyright` (the last only when set). All of
  it is written before the ad hoc signature, so `codesign --verify --deep --strict` passes.
- **Windows.** The exe is a copy of `factoria_player.exe`, whose icon resource is a neutral placeholder
  (`player/windows/factoria_player.ico`, compiled in by `factoria_player.rc`). The export replaces the placeholder's
  images (16, 24, 32, 48, 64, 128 and 256 px) with the game's icon in place, so the exe keeps its size and its
  structure, and recomputes the PE checksum. This works on any host: no Windows tools are needed to export for Windows
  from a Mac or Linux. A player without the placeholder (an older player, or another binary passed to `--player`) is copied
  unchanged and the report says so: the exe shows the player's own icon, and the game window still shows the game's
  icon at run time (above). The version information (Explorer's Details tab; Task Manager shows the description) is
  filled in the same way, with or without an icon: `FileDescription` and `ProductName` are the game's `name`,
  `FileVersion`, `ProductVersion` and the version numbers its `version`, `InternalName` and `OriginalFilename` the exe's
  name. The placeholder leaves 79 characters for a name and 31 for a version; a longer one is cut, with a warning.
- **Linux.** `<name>.png` (256 px) and `<name>.desktop` are written next to the game, with `Name`, `Exec`, `Icon`,
  `Type=Application`, `Terminal=false` and `Categories` (from `categories`; the default is `Game;`). Both
  `Exec=` and `Icon=` are bare names: the report prints the one command that installs the entry for the folder
  the game lives in (it rewrites them to absolute paths and copies the file to `~/.local/share/applications`). The
  [AppImage](#linux-appimage) carries the same entry, with `Icon=<name>` and the game's version.

Windows: the player of a release download would carry FactorIA's signature if the release were signed, but the
Windows releases are not signed yet ([BUILDING.md](../design/BUILDING.md), "Code signing"; repository only, not in the binary), and one built from source never is.
Writing the game's icon and version
information edits the exe, which invalidates a signature, so the export removes it (the certificate table at the end of
the file) and says so in the report: an exe with the wrong signature is worse than an unsigned one. Only a player
without the placeholders is copied byte for byte, signature included. SmartScreen may warn about an unsigned exe; sign
the exported exe with `signtool` to publish under your own name:

```
signtool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /a my-game.exe
```
