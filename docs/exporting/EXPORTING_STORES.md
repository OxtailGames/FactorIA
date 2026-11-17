# Exporting a game, page 6 of 6

Part of [Exporting a game](../EXPORTING.md) (the entry page lists every page).

## Uploading to stores

Seven commands upload a build to a store with the store's own uploader: four for the desktop exports, three for the packages
(mobile builds and the MSIX). They are commands like `project.export` (MCP tools `publish_steam`, `publish_itch`, `publish_epic`, `publish_gog`,
`publish_appstore`, `publish_googleplay`, `publish_microsoft`; also `factoria call publish.steam '{"dryRun":true}'` and the editor console), so an
AI can ship a build. FactorIA writes the
build files and runs the tool; it never downloads or installs the tool, never takes a password, and never writes a secret
to a file of the project.

| Command | Uploader | One upload per platform goes to |
|---|---|---|
| `publish.steam` | `steamcmd` | a depot of your Steam app (all depots in one build) |
| `publish.itch` | `butler` | a channel of your itch.io page |
| `publish.epic` | `BuildPatchTool` (`-mode=UploadBinary`) | an artifact of your Epic product |
| `publish.gog` | `GOGGalaxyPipelineBuilder build-game` | a GOG build of your product |
| `publish.appstore` | `xcrun altool --upload-package` (macOS only) | App Store Connect / TestFlight: the one `.ipa` |
| `publish.googleplay` | `fastlane supply` | a track of your app in Google Play: the one `.aab` |
| `publish.microsoft` | `msstore` (Microsoft Store Developer CLI) | a submission of your app in Partner Center: the one `.msix` |

The first four upload the folders `project.export` wrote: `<project>/build/export/<game-slug>-<platform>` for `windows`,
`macos` and `linux`. Export every platform first (`project_export {"platform":"windows"}`, ...). The mobile builds are one
file each, not a folder: see [App Store Connect (TestFlight)](#app-store-connect-testflight) and
[Google Play](#google-play) below. Everything in a desktop export is uploaded (the game, `FACTORIA_NOTICES.txt`, which must stay) except `.factoria-export` and `AI_CONTENT_DISCLOSURE.md`,
which belong to the export, not to the game. Show the AI content disclosure on the store page by hand when the game needs
it ([AI content disclosure](EXPORTING_CONTENTS.md#ai-content-disclosure)).

Arguments (all optional; every command has `dryRun`):

| Argument | Meaning |
|---|---|
| `platforms` | `["windows","macos","linux"]` (`win`, `mac`, `osx` also work). Default: every platform that has an export folder and is set up for this store in `factoria.json`; the others are skipped with a warning. Naming one that is not ready is an error. |
| `out` | Parent folder of the exports, inside the project (default `build/export`, the `out` of `project.export`). |
| `folders` | `{"windows": "dist/win"}`: upload another folder (inside the project) for a platform. Wins over `out`. |
| `dryRun` | `true`: write the build files and return the exact command lines and what would be uploaded where. Nothing is started or sent. A missing uploader, secret, account or id (the Steam app id, the Epic ids...) is a warning, not an error: the plan is returned with the missing value shown as a placeholder (`MISSING_...`, and the tool's bare name), so you see the steps before you set anything up. |
| `account`, `appId`, `branch` | `publish.steam` only: the Steam account (default `publish.steam.account`), the app id (default the number in `steam_appid.txt`) and the beta branch to set live (default `publish.steam.branch`). |
| `branch` | `publish.gog` only: the GOG branch to put the build on (Pipeline Builder `--branch`). |
| `artifact` | `publish.appstore`, `publish.googleplay` and `publish.microsoft` only: the `.ipa` / `.aab` / `.msix` to upload, inside the project (the MSIX default is `<out>/<slug>-windows.msix`). They take no `platforms` or `folders`. |
| `track`, `releaseStatus` | `publish.googleplay` only: the release track (`internal`, `alpha`, `beta`, `production`, or a closed testing track) and `draft` or `completed` (default `publish.googleplay.track` / `.releaseStatus`, else `internal` and `draft`). |

The result is `{store, dryRun, uploaded, version, tool, toolFrom, uploads, steps, files, warnings, nextSteps}` plus, after
a real run, `exitCode` and `log`. `uploads` has one entry per platform: `{platform, folder, destination, files, bytes,
uploaded}`: what goes where. `steps` has one entry per run of the uploader: `{title, command, commandLine, files, ran,
exitCode}` (the command line with every secret replaced by `<redacted>`). `files` are the build files written. The
version is the game's `version` of `factoria.json` (`0.1.0` when it has none). While a tool runs, every line of its output
is written to the engine log as it comes (category `publish.<store>`: stderr of `factoria call` and `factoria mcp`, the editor
console) and kept in `<project>/.factoria/publish/<store>.log`, with secrets replaced by `<redacted>`. A tool that exits with an error is not a crash: the command fails with the exit code,
the last lines of its output, the log path and what to check, and the error's `data` is the same report, so the AI can see
which platforms were uploaded before the failure (the run stops at the first failing upload).

```
publish_itch {"dryRun":true}
publish_steam {"platforms":["windows","linux"],"branch":"beta"}
publish_epic {"platforms":["windows"]}
publish_gog {"branch":"testing"}
publish_appstore {"dryRun":true}
publish_googleplay {"track":"internal","releaseStatus":"draft"}
publish_microsoft {"dryRun":true}
```

Always run the dry run first; it also checks the tool, the ids and the exports, and it shows the files written to
`<project>/.factoria/publish/<store>/` (the Steam `.vdf` scripts, the GOG project files, the ignore list of Epic and GOG). The build
files are rewritten on every call; do not commit `.factoria/`. (Epic's `cloud` folder there is the tool's chunk cache: keep it between uploads.)

### What you set up by hand first

FactorIA cannot create your pages, products or credentials. Each store has something to do once on its partner site:

- **Steam**: a Steamworks account and an app with an app id; one depot per platform (App Admin > SteamPipe > Depots) and the
  depots added to a package of the app; a build account with the *Edit App Metadata* permission for the app
  (Users & Permissions; the Steamworks upload page names it); the launch options of each depot (App Admin > Installation > General) after the first upload.
  Put the app id in `steam_appid.txt` (`platform.add_backend {"backend":"steam","appId":<id>}` writes it). Docs:
  <https://partner.steamgames.com/doc/sdk/uploading>.
- **itch.io**: an account and a page for the game (the address `mystudio.itch.io/space-dodge` makes the game
  `mystudio/space-dodge`); the page can stay a draft. Docs: <https://itch.io/docs/butler/>.
- **Epic Games Store**: a Dev Portal organization and product, one artifact per platform (Artifacts and Binaries), and a
  Build Patch Tool client with its secret (Product Settings > General). Docs:
  <https://dev.epicgames.com/docs/epic-games-store/publishing-tools/uploading-binaries/bpt-instructions-160>.
- **GOG**: a product with its product id in the GOG Developer Portal, and Pipeline Builder access for your account. Docs:
  <https://docs.gog.com/pb-quick-start/> and <https://docs.gog.com/pb-build-game/>.
- **App Store Connect**: an Apple Developer Program membership, the app (My Apps > +, with the bundle id of the game's `id`),
  and an App Store Connect API key ([App Store Connect (TestFlight)](#app-store-connect-testflight)).
- **Google Play**: a Play Console developer account, the app (with the game's `id` as its package name), the **first bundle
  uploaded by hand**, and a service account with access to the app ([Google Play](#google-play)).

### Store ids: `publish` in `factoria.json`

The ids of the game in the stores go in the `publish` object of `factoria.json` (checked by `factoria validate`, like
`export`). None of them is a secret. Every wrong value is an error naming the JSON pointer and the fix; an unknown key is a
warning with a "did you mean".

```json
"publish": {
  "steam": { "account": "mystudio_build", "depots": { "windows": 1234561, "macos": 1234562, "linux": 1234563 }, "branch": "beta" },
  "itch": { "game": "mystudio/space-dodge", "channels": { "windows": "windows", "macos": "mac", "linux": "linux" } },
  "epic": { "organizationId": "o-abc123", "productId": "0123abcd", "clientId": "xyz",
            "artifacts": { "windows": "<artifact id>", "macos": "<artifact id>", "linux": "<artifact id>" } },
  "gog": { "productId": "1234567890", "clientId": "5555", "languages": ["en-US", "fr-FR"] },
  "appstore": { "appleId": "6448277777" },
  "googleplay": { "track": "internal", "releaseStatus": "draft", "changelogs": { "en-US": "store/whats-new-en.txt" } }
}
```

| Field | Meaning |
|---|---|
| `steam.account` | Name of the Steam build account that uploads. Its password is not stored anywhere in the project. |
| `steam.depots` | `{platform: depot id}`. A platform without a depot is not uploaded. |
| `steam.branch` | Beta branch the build is set live on after the upload. Optional; `default` is refused: make a build default by hand in Steamworks. Without a branch the build is uploaded but not live. |
| `itch.game` | `user/game` of the page, lower case, as in its address. |
| `itch.channels` | `{platform: channel}`. Default `windows`, `mac`, `linux`. itch.io tags a channel's download by its name (`windows`, `osx` or `mac`, `linux`); add suffixes such as `windows-beta` for a test channel. |
| `epic.organizationId`, `epic.productId`, `epic.clientId` | From the Dev Portal. The client is the Build Patch Tool credential. |
| `epic.artifacts` | `{platform: artifact id}`. A platform without an artifact is not uploaded. |
| `gog.productId` | The product id of the game in the GOG Developer Portal. |
| `gog.clientId` | GALAXY client id of the product (optional). |
| `gog.languages` | Locale codes of the game's languages. Default `["en-US"]`. |
| `appstore.appleId` | The app's Apple ID: the number under App Store Connect > your app > App Information > General Information (about ten digits; not the e-mail of your account). The bundle id is the game's `id`. |
| `googleplay.track` | `internal` (default), `alpha`, `beta`, `production`, or the name of a closed testing track. The package name is the game's `id`. |
| `googleplay.releaseStatus` | `draft` (default: the release waits in the Play Console until you roll it out) or `completed` (it rolls out at once). |
| `googleplay.changelogs` | `{Play language: file}`, e.g. `{"en-US": "store/whats-new-en.txt"}`: the release notes, plain text files of the project, 1 to 500 characters each. Default: none uploaded. |

Store ids are copied from the partner sites as text or numbers. Unknown platforms are rejected with a "did you mean"
(`windws` -> `windows`), and `android` and `ios` with the reason.

### Secrets and the process list

The command line of a running program is readable by every user of the computer (`ps`, Task Manager). So FactorIA gives each
tool its secret by the safest route the tool has: the environment of the process (Gradle, `butler`, BuildPatchTool, `openssl
-passin env:`, `keytool -storepass:env`, `signtool` through the certificate store), a file or key path (altool, `notarytool --key`, fastlane
`--json_key`, `notarytool --keychain-profile`) or its standard input (`osslsigncode -readpass -`, `notarytool` for an Apple ID
password: with no `--password` and no terminal it reads the password from stdin, and `sign.macos` starts it in a session of its own, so
without a controlling terminal: `ProcessOptions::newSession`; a cancel still stops notarytool and everything it started). Reports and `dryRun` list only the NAMES of the environment variables a step sets (`env`) and say
when a secret goes on stdin (`stdinSecret`). Two uploaders leave no other way, and FactorIA warns about them in the plan: GOG Pipeline
Builder (`--password`) and the Microsoft Store CLI (`msstore reconfigure --clientSecret`).

### Secrets: environment variables and `~/.factoria/`

A secret is never read from `factoria.json`, never written to a file of the project, never shown in a result, a progress line
or a log (the value is replaced by `<redacted>`), and never placed on a command line unless the uploader leaves no other way. Two
uploaders leave none: the GOG password (`GOGGalaxyPipelineBuilder --password`) and the Microsoft Store client secret (`msstore
reconfigure --clientSecret`) are arguments while that program runs, whatever the other lines of this section say.

| Store | Secret | Where it comes from |
|---|---|---|
| Steam | the account password and the Steam Guard approval | not given to FactorIA: run `steamcmd +login <account>` once in a terminal; steamcmd keeps the login (`config/config.vdf`) and the next run needs no password. |
| itch.io | the API key | `butler login` once (butler keeps it in its own config folder), or the environment variable `BUTLER_API_KEY`. |
| Epic | the client secret | the environment variable `FACTORIA_EPIC_CLIENT_SECRET`. It reaches the tool in its environment and the command line only names the variable (`-ClientSecretEnvVar=FACTORIA_EPIC_CLIENT_SECRET`). |
| App Store Connect | the API key | a `.p8` file outside the project: `FACTORIA_APPSTORE_API_KEY` is its path, `FACTORIA_APPSTORE_API_KEY_ID` its Key ID and `FACTORIA_APPSTORE_API_ISSUER` the Issuer ID (`FACTORIA_NOTARY_API_KEY`, `_KEY_ID`, `_ISSUER` of [`sign.macos`](EXPORTING_DESKTOP.md#signing-and-notarizing-for-macos) work too). The file is never read, copied or shown: altool finds it in the folder named by its own `API_PRIVATE_KEYS_DIR`. |
| Google Play | the service account key | a JSON file outside the project: `FACTORIA_GOOGLEPLAY_JSON_KEY` (or fastlane's `SUPPLY_JSON_KEY`) is its path. FactorIA checks that it is a service account key and passes the path to fastlane; the content is never shown. |
| GOG | the GOG account | the sign-in Pipeline Builder cached (run it once by hand: then no password is on any command line), or `FACTORIA_GOG_USERNAME` and `FACTORIA_GOG_PASSWORD` (both or neither). Pipeline Builder only accepts the password as the argument `--password`, so it is visible in the process list while the upload runs; the shown command line has it replaced by `<redacted>` and the plan carries a warning saying so. |

### Finding the tools

FactorIA looks for each uploader, in this order: the environment variable (the executable, or the folder that holds it), the
`publish` object of `~/.factoria/export.json` ([Machine settings](EXPORTING_SETUP.md#machine-settings-factoriaexportjson)), then `PATH`. When it
finds none the command fails with the store's download page, the variable and the key to set; nothing is downloaded.

| Tool | Environment variable | Key in `~/.factoria/export.json` `publish` | Download |
|---|---|---|---|
| steamcmd | `FACTORIA_STEAMCMD` | `steamcmd` | <https://developer.valvesoftware.com/wiki/SteamCMD> |
| butler | `FACTORIA_BUTLER` | `butler` | <https://itch.io/docs/butler/installing.html> |
| BuildPatchTool | `FACTORIA_BUILDPATCHTOOL` | `buildPatchTool` | the Dev Portal (Build Patch Tool page of the docs above) |
| GOGGalaxyPipelineBuilder | `FACTORIA_GOG_PIPELINE_BUILDER` | `galaxyPipelineBuilder` | <https://docs.gog.com/pb-quick-start/> |
| xcrun (Xcode; altool is part of it) | `FACTORIA_XCRUN` | `xcrun` | Xcode from the Mac App Store, then `xcode-select --install` |
| fastlane | `FACTORIA_FASTLANE` | `fastlane` | <https://docs.fastlane.tools/getting-started/android/setup/> (`gem install fastlane` or `brew install fastlane`) |

```json
{ "format": "factoria.export-config/1", "publish": { "steamcmd": "C:/Tools/steamcmd/steamcmd.exe", "butler": "~/butler" } }
```

### Steam

`publish.steam` writes `app_build_<appid>.vdf` and one `depot_build_<depot>.vdf` per platform into
`.factoria/publish/steam/`, then runs `steamcmd +login <account> +run_app_build <app_build.vdf> +quit`. A depot's content
root is the export folder of its platform, mapped as `"*"` to the depot's root, recursively, without the two export marker
files. The build description is `<name> <version>`. With a `branch` the app script has `SetLive` and the build becomes the
current build of that beta branch; without one the build is only uploaded.

Things to know:

- Steam keeps the executable bit of a file only when the upload runs on macOS or Linux: upload the `macos` and `linux` depots
  from that OS. An export made on Windows has no executable bit to keep. This is a Steamworks rule, not FactorIA's.
- After the first upload set each depot's launch option in Steamworks (the result's `nextSteps` lists the file for each platform).
- The app id 480 (Valve's test app, Spacewar) is refused in a real upload. A dry run accepts it and warns, so you can see the plan before you have your own id. If `steam_appid.txt` is missing the error says how to write it.

```
publish_steam {"dryRun":true}
-> steps[0].commandLine: steamcmd +login mystudio_build +run_app_build C:/games/space/.factoria/publish/steam/app_build_1234560.vdf +quit
-> uploads: windows -> Steam app 1234560, depot 1234561 (windows), 41 files, 12.4 MB
```

### itch.io

`publish.itch` runs `butler push <export folder> <user>/<game>:<channel> --userversion <version> --ignore .factoria-export
--ignore AI_CONTENT_DISCLOSURE.md` once per platform: `windows`, `mac` and `linux` channels unless `publish.itch.channels` says
otherwise. butler only sends what changed since the last push of the channel, so repeated uploads are quick. No build files are
written. The dry run warns when neither `BUTLER_API_KEY` is set nor a `butler login` exists.

### Epic Games Store

`publish.epic` runs `BuildPatchTool -OrganizationId=... -ProductId=... -ArtifactId=<artifact of the platform> -ClientId=...
-ClientSecretEnvVar=FACTORIA_EPIC_CLIENT_SECRET -mode=UploadBinary -BuildRoot=<export folder> -CloudDir=<work folder>/cloud/<platform>
-BuildVersion=<version> -AppLaunch=<the game's executable> -AppArgs= -FileIgnoreList=<ignore list>` once per platform.
`-AppLaunch` is `<slug>.exe`, `<Name>.app/Contents/MacOS/<slug>` or `<slug>` (`game-bin` on Linux for the slug `game`, see
[Desktop](EXPORTING_DESKTOP.md#desktop-linux-windows-macos)), relative to the export folder: the export must
contain it. The cloud folder holds the tool's chunks for later patches and is kept between uploads (`.factoria/publish/epic/cloud`);
the tool needs it to be different from the build root.

An Epic `BuildVersion` can be used once per artifact and may contain letters, digits and `. + - _` only (1 to 100
characters): raise `version` in `factoria.json` before every upload. After the upload, assign the build to a platform label
and publish the product in the Dev Portal.

### GOG

`publish.gog` writes `gog-<platform>.json` (a Pipeline Builder project: the export folder as the depot of the product, the
game's executable as the primary file task) and `ignore.txt` into `.factoria/publish/gog/`, then runs
`GOGGalaxyPipelineBuilder build-game <json> --ignore_list <ignore.txt> --version <version> [--branch <branch>]` once per platform
(macOS is `osx` for GOG). A build is not live until you publish it from the Developer Portal (Builds & Branches); Pipeline Builder
cannot publish to the *master* branch, so `branch: "master"` is refused.

### App Store Connect (TestFlight)

`publish.appstore` uploads the `.ipa` of your iOS build with `xcrun altool --upload-package <ipa> --type ios --apple-id
<appleId> --bundle-id <id> --bundle-version <export.ios.buildNumber> --bundle-short-version-string <version> --apiKey
<Key ID> --apiIssuer <Issuer ID>`. It runs on **macOS with Xcode only**; on another computer a real run is refused with the
reason, and `dryRun` still shows the plan.

**The Mac App Store.** The same command uploads the `.pkg` that [`sign.macos` with `distribution: "appStore"`](EXPORTING_DESKTOP.md#mac-app-store)
writes (`build/export/<game-slug>-macos.pkg`), with `--type macos` and `export.macos.buildNumber`. Say which file with
`platforms` (`["ios"]` or `["macos"]`) or `artifact` (a `.pkg` extension means macOS); with no hint it uploads the one that
exists, and with both an `.ipa` and a `.pkg` it asks you to choose.

**The `.ipa` is yours to make.** `factoria export --platform ios` writes an Xcode project (`build_ios.sh`), not an `.ipa`.
Build it once per release:

1. `./build_ios.sh` and open `build/FactorIA.xcodeproj` (or `FA_IOS_DEVELOPMENT_TEAM=<team> ./build_ios.sh`).
2. In Xcode: set Signing & Capabilities > Team, pick **Any iOS Device (arm64)**, then Product > Archive.
3. In the Organizer: Distribute App > **App Store Connect** > Export (not Upload: FactorIA uploads it). Save the `.ipa` as
   `build/export/<game-slug>.ipa` (inside the project, next to the exports; the newest `.ipa` of `build/export` is used when
   that name is missing), or pass `artifact`.

The version and build number must be the ones in the `.ipa`: they come from `factoria.json` (`version`, `export.ios.buildNumber`;
the bundle id is `id`), so export, archive and publish with the same `factoria.json`. App Store Connect takes each build
number once per version: raise `export.ios.buildNumber` for every upload.

**The API key** (once, in App Store Connect > Users and Access > Integrations > App Store Connect API > Team Keys): generate a
key with the **App Manager** role, download `AuthKey_<Key ID>.p8` (Apple lets you download it once; keep it outside the
project and do not rename it), and note the Key ID and the Issuer ID of that page. Then:

```
export FACTORIA_APPSTORE_API_KEY=~/keys/AuthKey_ABCDE12345.p8
export FACTORIA_APPSTORE_API_KEY_ID=ABCDE12345
export FACTORIA_APPSTORE_API_ISSUER=11111111-2222-3333-4444-555555555555
```

Add `"publish": {"appstore": {"appleId": "6448277777"}}` to `factoria.json` (the app must exist in App Store Connect first,
with the same bundle id), run `publish_appstore {"dryRun":true}`, then `publish_appstore {}`.

**After the upload** App Store Connect *processes* the build: it takes a few minutes to an hour, you get an e-mail if it is
rejected (a missing `ITSAppUsesNonExemptEncryption`, an icon with transparency, an unsupported architecture...), and then the
build appears under your app > TestFlight. Internal testers get it once you add them to a group; external testers need
Apple's beta review. To release to the store, pick the build on the version page of the App Store tab and submit it. None
of this is done by FactorIA.

### Google Play

`publish.googleplay` uploads the release bundle with `fastlane supply --aab <aab> --track <track> --release_status
<draft|completed> --package_name <id> --json_key <service account key>`. The bundle is the one `factoria export --platform
android --format aab --release` writes (`build/export/<game-slug>-android/<game-slug>.aab`), or `artifact`. It runs on any
computer that has fastlane.

- **A debug-signed bundle is refused.** Google Play rejects it, so `publish.googleplay` fails before anything is sent when
  the file is a `-debug.aab`, or when `export.android.signing.keystore` is not set in `factoria.json` (the release export
  then fell back to the debug key). Create the keystore ([MOBILE.md](../mobile/MOBILE_ANDROID.md#signing-and-release)) and export again. A bundle you
  signed some other way can be passed as `artifact`; FactorIA only warns, because it cannot see how a file was signed.
- **The first bundle of a new app is uploaded by hand.** Google Play requires it: in the Play Console create the app (its
  package name is the game's `id`), complete the app setup, and upload the first `.aab` yourself under Testing > Internal
  testing > Create new release. The API works from the second bundle on. Until the app is published it accepts only
  `"releaseStatus": "draft"` (the default).
- **The service account** (once): in the Play Console > Users and permissions, invite a service account with permission to
  release to the tracks you use (create it in Google Cloud: IAM > Service accounts, enable the *Google Play Android Developer
  API* in that project, and add a JSON key). Keep the key file outside the project and set `FACTORIA_GOOGLEPLAY_JSON_KEY` to
  its path. Access takes a while to apply after the invitation.
- **Draft or completed.** `draft` (the default) leaves a release in the Play Console that you review and roll out;
  `completed` rolls it out right away. `track: "production"` with `completed` publishes to everyone: the dry run warns.
- **Release notes.** `publish.googleplay.changelogs` maps a Play language to a text file of the project; the files are
  copied to `.factoria/publish/googleplay/metadata/<language>/changelogs/default.txt` on every call and uploaded with the
  release. Only the release notes are uploaded: the listing text, images and screenshots stay as they are in the Play Console.
  Each language must already be added to the store listing.
- **Version codes.** Google Play takes each `versionCode` once: raise `version` (or `export.android.versionCode`) in
  `factoria.json` before every release export. The data safety form and the other store forms stay in the Play Console.

```
publish_googleplay {"dryRun":true}
-> steps[0].commandLine: fastlane supply --aab .../space-dodge.aab --track internal --release_status draft --package_name com.mystudio.spacedodge --json_key ~/keys/play.json ...
-> uploads: android -> Google Play com.mystudio.spacedodge, track internal (draft, version code 10203), 1 file, 24.1 MB
```

### Microsoft Store

`factoria export --platform windows --format msix` (or `export.windows.format: "msix"`) writes the Windows folder as usual and,
next to it, `<out>/<slug>-windows.msix`: the package of the Microsoft Store and of `Add-AppxPackage`. It is built on any
computer (macOS, Linux, Windows) by FactorIA itself, with no Windows SDK: the same game folder is the package payload,
with `AppxManifest.xml`, `AppxBlockMap.xml` (SHA-256 per 64 KiB block), `[Content_Types].xml` and the logos. The package is
deterministic (same game, same bytes) and unsigned. The report has `format: "msix"` and the package among its `artifacts`.

```
factoria export --platform windows --format msix --release
```

**Identity.** Reserve the app name in Partner Center, then copy from its Product identity page into `factoria.json`:

```json
"export": { "windows": { "format": "msix", "msix": {
    "identityName": "12345Studio.MyGame",
    "publisher": "CN=0123ABCD-4567-89EF-0123-456789ABCDEF",
    "publisherDisplayName": "My Studio" } } }
```

Without them the package gets a placeholder identity (`FactorIA.<slug>`, `CN=FactorIA Developer`): it installs on your own
PC once signed, but the Store rejects it. `project.validate` and the export warn about it. The other fields
(`displayName`, `description`, `backgroundColor`, `version`, `minVersion`, `languages`) are in the
[settings table](EXPORTING_DESKTOP.md#icon-and-settings-per-platform). The version is the game's `version` plus `.0`: the Store reserves the fourth number.

**Logos.** The manifest's `StoreLogo`, `Square44x44Logo`, `Square150x150Logo`, `Wide310x150Logo` and `Square310x310Logo`
(and the scale and target-size variants Windows looks for) are cut from the game's icon (`export.windows.icon`, else `icon`)
and written as PNG into `Assets/`. The package has no `resources.pri`; whether every Windows version finds the qualified
files without one has not been checked on a real PC. Replace the icon with a square picture of at least 400x400.

**Upload to the Store, unsigned.** Upload the `.msix` as it is: Microsoft signs it after certification, with the publisher
of your account. Create the submission by hand in Partner Center (pricing, age rating, privacy policy URL, listing and
screenshots; see [AI content disclosure](EXPORTING_CONTENTS.md#ai-content-disclosure) for the content questions) and upload the package, or, once
the app and a first submission exist, `publish.microsoft` (below) uploads later versions. An update raises `version`.

**Try it on a PC without the Store.** Windows only installs signed packages, and the certificate subject must equal the
manifest `Publisher`.

- With a certificate: `sign.windows {"pfx":"signing.pfx"}` signs the package (`signtool` on Windows, `osslsigncode` on the
  other computers; `FACTORIA_SIGNTOOL` and `FACTORIA_OSSLSIGNCODE` point at the tool). The password is only read from
  `FACTORIA_WINDOWS_PFX_PASSWORD`, never from `factoria.json` or an argument, and no program gets it on its command line:
  on Windows `signtool` has no other way to read a `.pfx` password than `/p`, so the `.pfx` is imported into your user
  certificate store (`Cert:\CurrentUser\My`) by PowerShell, which reads the password from its environment, `signtool` signs with
  `/sha1 <thumbprint> /s My`, and the imported certificate is removed again afterwards (also when signing fails or is cancelled; a
  certificate that was in the store before, with its private key, is left alone, and then the file is not even loaded a second
  time; one that was there WITHOUT its private key is completed by the import and removed with it afterwards). Up to three
  PowerShell steps: read the thumbprint of the certificate that has a private key (imports nothing and leaves no key on disk; only a PowerShell killed while it holds the file open can leave a temporary key container),
  import only that certificate (not the chain certificates of the file, which would bring up Windows' root-store question; the
  keys of the chain certificates are deleted again), skipped when the store has the certificate with its key, and remove it.
  The import looks in the store first and loads the file only right before adding the certificate, and it deletes the key it
  loaded when the certificate does not get into the store (a PowerShell killed at that very moment cannot clean up). Steps two and three hold a named mutex (per Windows user, shared by
  all the user's logon sessions; when a PowerShell run as administrator created it and this run cannot open it, the error says to close that PowerShell and run again), so two `sign.windows` runs of one user do not change the store at the same time; the mutex
  does not span the signing, so do not sign with the same `.pfx` in two runs at once (the first to finish removes the
  certificate). `osslsigncode` reads the password on its standard input (`-readpass -`). The pfx can also be `FACTORIA_WINDOWS_PFX` or
  `sign.windows.pfx` of `~/.factoria/export.json`. The command checks the certificate subject (with `openssl`, when present)
  against the manifest `Publisher` and refuses when they differ. `exe: true` also signs the game's exe, for a game shared
  as a folder or a zip. `dryRun` shows the four steps (read the thumbprint, import, sign, remove; a real run skips the import when the store has the certificate already) and the NAMES of the variables each one sets, never a value.
- Without one, on Windows: `sign.windows {"testCertificate":true}` creates a self-signed certificate with the right subject,
  signs the package and writes its public part (`<slug>-windows-test-certificate.cer`) next to it. Install the certificate once, in an
  administrator PowerShell: `Import-Certificate -FilePath <slug>-windows-test-certificate.cer -CertStoreLocation Cert:\LocalMachine\TrustedPeople`;
  then `Add-AppxPackage <slug>-windows.msix`. In PowerShell, pipe the arguments in (`'{"testCertificate":true}' | factoria call
  sign.windows -`): Windows PowerShell 5.1 drops the inner quotes of `factoria call sign.windows '{"testCertificate":true}'`.
- With Developer Mode on, `Add-AppxPackage -AllowUnsigned <file>` installs an unsigned package for testing (Windows 11 and
  recent Windows 10); such a package has no verified identity and cannot be updated by the Store.

The engine could not install a package on a real Windows PC while writing this: the byte layout is checked in the tests, and
the first install of a game is yours to confirm. Report a failure in `ENGINE_FEEDBACK.json`.

**`publish.microsoft`.** Runs the Microsoft Store Developer CLI (`msstore`, installed by you: `winget install "Microsoft Store Developer CLI"`
or the .NET tool; `FACTORIA_MSSTORE` points at it): `msstore reconfigure --tenantId ... --sellerId ... --clientId ... --clientSecret ...`
and then `msstore publish <folder> --inputFile <msix> --appId <productId> --noCommit`. `publish.microsoft.productId` of
`factoria.json` is the 12-character Store ID (Partner Center > your app > Product identity). The credentials come from an Azure AD
application you associate with Partner Center (Account settings > Tenants > Azure AD applications) and only from the environment:
`FACTORIA_MSSTORE_TENANT_ID`, `FACTORIA_MSSTORE_SELLER_ID`, `FACTORIA_MSSTORE_CLIENT_ID` and `FACTORIA_MSSTORE_CLIENT_SECRET`
(the secret is never shown: `<redacted>`). `msstore reconfigure` takes the client secret only as the argument `--clientSecret`, so it is visible in the process list for a few seconds; the plan carries a warning saying so (use an Azure AD application whose secret you can revoke). `releaseStatus: "draft"` (default) leaves the submission waiting in Partner
Center (`--noCommit`); `completed` sends it to certification. The first submission of a new app is always by hand.
FactorIA ran `msstore` only against a fake in its tests; a real upload needs a Partner Center account.

### Testing without a store

The tests of these commands run against a fake uploader (`tools/common/test_tools/fake_store_tool.cpp`) that records its arguments:
point the environment variable of a tool at any program to see exactly how it is called. `dryRun` needs no account.

## Store page material

Every store wants images at its own sizes and, for the page, a gameplay video. FactorIA makes both without an image
tool: screenshots at the stores' sizes, capsules cut from one piece of key art, and a video recorded from an input replay.

### Screenshots

Screenshots are the real game drawn natively larger, not enlarged. A game designed at 1280x720 gives Steam's, Epic's and
Microsoft's 1920x1080 with `--render-scale 1.5` (same HUD, camera and visible area, sharp text):

```
factoria run --headless --input replays/tour.json --frames 600 --screenshot-at 120,300,540 \
  --render-scale 1.5 --screenshot-pattern store/shot_{frame}.png
```

From a script or an AI, `game.screenshot {path, scale: 1.5}` does the same. Pick the frames with `--screenshot-at` after
looking at a few; Steam wants at least five screenshots of the game only (no logo, text or awards on them), Google Play and
the App Store take theirs from the table below (`assets.draw_capsules` cuts those from a screenshot too).

### Capsules and covers: `assets.draw_capsules`

`assets.draw_capsules` cuts one key art (a screenshot, or any image in the project) to every image of the stores you name
and writes `store/capsules/<store>/<name>_<w>x<h>.png`. The art is cover-cropped around `focus` (a point `[x, y]` as
fractions of the art, default the middle); the `logo` is an image (`{"image": "assets/logo.png"}`, a PNG with a
transparent background) or the title drawn with the same rasterizer as [`assets.draw_icon`](../assets/ASSETS_REVIEW.md#the-game-icon-without-a-provider-assetsdraw_icon)
(`{"text": "Lantern Keep", "font": "assets/fonts/Title.ttf", "fill": "#fff4d0"}`). The logo goes where the asset's rule puts
it: centred on capsules and covers, in the upper part for Microsoft (the bottom third is overlaid), none on heroes, page
backgrounds and screenshots (Steam's library hero must have no text), and alone on a transparent canvas for the logo-only
assets (Steam's library logo, Epic's logo). Assets with the same size in one store are one file.

Three arguments frame the logo:

- `safeArea`: the margin the logo keeps from the edges, as fractions of the image (0 to 0.45 each). A number is every side,
  `{"left": 0.05, "top": 0.05, "right": 0.05, "bottom": 0.3}` names sides (the others keep 0.05), and
  `{"default": 0.08, "microsoft": {"bottom": 0.4}}` differs per store (a store not named uses `default`, or the asset's
  own default). Without it every capsule keeps 0.05 on each side, and the Microsoft poster and box art also keep their bottom
  third, which the store overlays with text. The logo is made smaller to fit inside the area and is never placed outside it.
- `logoAnchor`: where the logo sits in the safe area instead of the asset's rule: `center`, `top`, `bottom`, `left`, `right`,
  `topLeft`, `topRight`, `bottomLeft`, `bottomRight`, or a point `[x, y]` (`[0, 0]` puts the logo's corner on the area's
  top-left corner, `[1, 1]` on the bottom-right one, `[0.5, 0.5]` is the middle). It applies to every asset that carries a
  logo, but not to the logo-only assets (Steam's library logo, Epic's logo): those stay centred.
- `focus` also moves the logo when the key art already has the capsule's proportions (within 1%): the crop then has nothing
  to choose, so the logo moves by how far `focus` is from `[0.5, 0.5]` (a focus of `[0.3, 0.5]` moves it a fifth of the width to
  the left of where the rule or `logoAnchor` put it), kept inside the safe area. On art of another shape `focus` only decides
  the crop.

```
factoria screenshot --frames 120 --render-scale 1.5 --out store/keyart.png
factoria call assets.draw_capsules '{"keyArt":"store/keyart.png","focus":[0.5,0.45],"logo":{"text":"My Game"},"stores":["steam","itch"]}'
```

`orientation: "portrait"` turns the phone and tablet screenshot sizes of Google Play and the App Store (landscape by default).
Look at the PNGs: change `focus` or the logo and call again (files are replaced). Use 1920x1080 key art or bigger; the
biggest image (Steam's 3840x1240 hero) is enlarged from it.

### Sizes (as of 2026-10)

These are the sizes in the code (`tools/common/src/store_assets.cpp`), checked against each store's documentation in
October 2026. Stores change them: check the store's page before uploading, and tell us in `ENGINE_FEEDBACK.json` when one moved.
"Logo" says whether `assets.draw_capsules` puts the logo on it; where the store has no rule the placement is our choice.

**Steam** ([standard assets](https://partner.steamgames.com/doc/store/assets/standard), [library assets](https://partner.steamgames.com/doc/store/assets/libraryassets))

| Image | Size | Logo |
|---|---|---|
| Header capsule | 920x430 | yes |
| Small capsule | 462x174 | yes (fills it) |
| Main capsule | 1232x706 | yes |
| Vertical capsule | 748x896 | yes |
| Page background | 1438x810 | no (ambient) |
| Library capsule | 600x900 | yes, low |
| Library header | 920x430 | yes |
| Library hero | 3840x1240 | no text at all; keep the subject inside the centred 860x380 |
| Library logo | 1280x720 (or 1280 wide / 720 tall) | alone, transparent PNG |
| Screenshots | 1920x1080 minimum, 16:9, at least 5 | no |

**Epic Games Store** ([Storefront Media Guide](https://dev.epicgames.com/docs/epic-games-store/sales-and-marketing/marketing/storefront-media-guide))

| Image | Size | Logo |
|---|---|---|
| Product logo | 960x540 | alone |
| Offer image, landscape | 2560x1440 | yes |
| Offer image, portrait | 1200x1600 | yes |
| Social preview | 1200x1200 | yes |
| Screenshots / media carousel images | 1920x1080 | no |

**GOG** ([essentials checklist](https://docs.gog.com/basic-game-assets/)): GOG publishes the sizes of its store images only in
the templates of the developer portal. The key art (at least 1920x1080, layered .psd with the logo for GOG's team) is
documented; the vertical cover 342x482 and the background 1600x670 come from GOG's support article and are **not verified**:
check them against the templates.

| Image | Size | Logo |
|---|---|---|
| Key art | 1920x1080 or more | no |
| Vertical cover | 342x482 (unverified) | yes, low |
| Background | 1600x670 (unverified) | no |

**Microsoft Store** ([screenshots and images](https://learn.microsoft.com/windows/apps/publish/publish-your-app/msix/screenshots-and-images))

| Image | Size | Logo |
|---|---|---|
| Poster art 2:3 | 720x1080 | yes, in the upper two thirds |
| Box art 1:1 | 1080x1080 | yes, in the upper two thirds |
| App tile icon | 300x300 | yes |
| Super hero art 16:9 | 1920x1080 | no (no text allowed) |
| Screenshots, trailer thumbnail | 1920x1080 (screenshots: 1366x768 or more) | no |

**Google Play** ([graphic assets](https://support.google.com/googleplay/android-developer/answer/9866151))

| Image | Size | Logo |
|---|---|---|
| Feature graphic | 1024x500, no alpha | yes |
| App icon | 512x512 (the real icon: `assets.draw_icon`) | yes |
| Phone / tablet screenshots | 320 to 3840 px a side, long side at most twice the short one; 1920x1080 (or 1080x1920) also qualifies for large-screen recommendations | no |

**App Store** ([screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/)), no alpha, landscape here (`orientation: "portrait"` swaps):

| Image | Size | Logo |
|---|---|---|
| iPhone 6.9" | 2868x1320 | no |
| iPhone 6.5" | 2778x1284 (required when there are no 6.9" ones) | no |
| iPhone 6.3" | 2622x1206 (at least one iPhone size is required) | no |
| iPad 13" | 2752x2064 (required if the app runs on iPad) | no |

**itch.io**: the cover image upload form asks for 630x500 (minimum 315x250); itch.io's docs do not print the size, so it
is **not verified** against documentation. The logo is centred.

| Image | Size | Logo |
|---|---|---|
| Cover image | 630x500 | yes |

### Gameplay video from a replay

`factoria run --headless --input replay.json --frames N --record-video out.avi` plays the replay and writes a video of it:
every frame is drawn at `--render-scale` (1.5 on 1280x720 = 1920x1080) at the project's `fixedHz` frames per second, and the
audio mix of the run is its sound track (none when the run is silent). The same replay and seed always give the same file.
Record a replay with the editor (play session recorder) or write it by hand ([CLI.md](../CLI.md), AI_GUIDE 11.2).

```
factoria run --headless --input replays/trailer.json --frames 900 --render-scale 1.5 --record-video store/trailer.avi
```

- `.avi` needs nothing else: Motion-JPEG video and 16-bit PCM audio. Every player and editor reads it; it is large (about
  10 MB a second at 1080p, so do not commit it; ffmpeg makes the small .mp4). **Limit:** an AVI file cannot pass about
  2 GB, which is roughly 3 minutes of 1080p at 60 fps (twice that at 720p). When the video reaches it, recording stops at that
  frame, the run goes on, and the report lists the reason in `problems` (exit code 2). Record a shorter replay
  (`--frames`) or use a smaller `--render-scale`.
  The frames are written to a spool file next to the output as they are drawn, so the memory of the run stays flat however long
  the recording is (a 1480-frame recording at 1080p once peaked at 4.4 GB on macOS, because every frame read back from the GPU
  was kept until the end of the run; `video_tests.cpp` watches for it). The disk needs the size of the video twice while the
  file is being finished.
- `.mp4` (H.264 + AAC, what Steam, Google Play and the App Store accept for previews) is made by
  [ffmpeg](https://ffmpeg.org/download.html), found like the store tools of [Finding the tools](#finding-the-tools):
  `FACTORIA_FFMPEG` (the executable or its folder), `"publish": {"ffmpeg": "<path>"}` in `~/.factoria/export.json`, `PATH`,
  then the copy `factoria setup ffmpeg` installs under `$FACTORIA_HOME/tools/ffmpeg/` (`setup.status` lists the `ffmpeg`
  component; the user installs it with `factoria setup ffmpeg` or the editor's setup window, one download of 19-28 MB). FactorIA records the AVI and ffmpeg converts it (even sizes, `yuv420p`, `+faststart`). Without ffmpeg the request fails
  before the replay runs, with this advice: run `factoria setup ffmpeg`, install ffmpeg yourself, or record `.avi` and convert it yourself:
  `ffmpeg -i trailer.avi -c:v libx264 -pix_fmt yuv420p -c:a aac trailer.mp4`.
- Stores want the video at their own sizes and rates (Microsoft: 1920x1080 MP4, under 2 GB, 60 s or less recommended);
  pick `--frames` and `--render-scale` for it. A video needs a GPU like screenshots do (headless EGL with Mesa works).
