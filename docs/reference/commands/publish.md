[Back to the index](../README.md)

# Commands: publish

## `publish.appstore` (modifies state)

Since 0.2.0.

Upload the iOS build (.ipa) to App Store Connect / TestFlight (xcrun altool, macOS only).

Runs `xcrun altool --upload-package <ipa> --type ios --apple-id <id> --bundle-id <id of factoria.json> --bundle-version <export.ios.buildNumber> --bundle-short-version-string <version> --apiKey <key id> --apiIssuer <issuer id>`. The .ipa is NOT made by `factoria export --platform ios` (that writes an Xcode project): archive it in Xcode (Product > Archive, Distribute App > App Store Connect > Export) and save it as build/export/<game-slug>.ipa, or pass `artifact`. Needs: factoria.json publish.appstore {appleId} (the number of the app in App Store Connect) and id (the bundle id), Xcode (xcrun: PATH, FACTORIA_XCRUN, or publish.xcrun of ~/.factoria/export.json), macOS (other computers get a teaching error; dryRun works anywhere), and an App Store Connect API key (role App Manager): FACTORIA_APPSTORE_API_KEY = path of AuthKey_<KeyID>.p8, FACTORIA_APPSTORE_API_KEY_ID, FACTORIA_APPSTORE_API_ISSUER (FACTORIA_NOTARY_API_KEY / _KEY_ID / _ISSUER of sign.macos also work). The key stays a file outside the project: nothing of it is written, shown or logged. After the upload App Store Connect processes the build, then it shows in TestFlight. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed altool is an error whose data is that report. Examples: {"dryRun":true}, {"artifact":"build/export/space-dodge.ipa"}. Details: docs_read {"name":"exporting"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `artifact` | string | no | The .ipa to upload, relative to the project. Default: build/export/<game-slug>.ipa, else the newest .ipa in build/export. Xcode writes it (Product > Archive, Distribute App > App Store Connect > Export); `factoria export --platform ios` only writes the Xcode project. |
| `out` | string | no | Folder that holds the build, relative to the project (the `out` of project.export). Default: build/export. |
| `dryRun` | boolean | no | Write the build files into .factoria/publish/<store>/ and return the exact command line, what would be uploaded where and the warnings; start nothing and send nothing. A missing uploader, secret or id is a warning and the plan is still returned. Secrets are never in the result. Default false. |

## `publish.epic` (modifies state)

Since 0.2.0.

Upload the desktop exports to the Epic Games Store (BuildPatchTool UploadBinary, one artifact per platform).

Runs BuildPatchTool -mode=UploadBinary once per platform with -BuildRoot the export folder, -CloudDir under .factoria/publish/epic/cloud, -BuildVersion the game's version and -AppLaunch the game's executable. Needs factoria.json publish.epic {organizationId, productId, clientId, artifacts: {windows: <artifact id>, ...}}, BuildPatchTool (PATH, FACTORIA_BUILDPATCHTOOL, or publish.buildPatchTool of ~/.factoria/export.json) and the client secret in the environment variable FACTORIA_EPIC_CLIENT_SECRET: it is passed by name (-ClientSecretEnvVar), so it is never on a command line, in the result or in the log. Epic accepts each BuildVersion once per artifact: raise the version for every upload. The export's .factoria-export and AI_CONTENT_DISCLOSURE.md are not uploaded. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed BuildPatchTool is an error whose data is that report. Examples: {"dryRun":true}, {"platforms":["windows"]}. Details: docs_read {"name":"exporting"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `platforms` | array | no | Which exports to upload: windows, macos, linux (aliases win, mac, osx also work). Default: every one that has an export folder and is set up for this store in factoria.json; the ones without are skipped with a warning. |
| `out` | string | no | Parent folder of the exports, relative to the project (the `out` of project.export). Default: build/export, where the exports are <game-slug>-<platform>. |
| `folders` | object | no | Upload another folder for a platform, relative to the project: {"windows": "dist/win"}. Takes precedence over `out`. |
| `dryRun` | boolean | no | Write the build files into .factoria/publish/<store>/ and return the exact command lines, what would be uploaded where and the warnings; start nothing and send nothing. A missing uploader, secret or id is a warning and the plan is still returned. Secrets are never in the result. Default false. |

## `publish.gog` (modifies state)

Since 0.2.0.

Upload the desktop exports to GOG (Galaxy Pipeline Builder build-game, one project file per platform).

Writes gog-<platform>.json (the Pipeline Builder project: the export folder as the depot, the game's executable as the primary task) into .factoria/publish/gog/ and runs `GOGGalaxyPipelineBuilder build-game <json> --ignore_list <file> --version <version>` once per platform. Needs factoria.json publish.gog {productId, clientId?, languages?}, Pipeline Builder (PATH, FACTORIA_GOG_PIPELINE_BUILDER, or publish.galaxyPipelineBuilder of ~/.factoria/export.json) and a sign-in: the credentials it cached, or FACTORIA_GOG_USERNAME and FACTORIA_GOG_PASSWORD (the password is then an argument of the process while it runs; it is redacted everywhere FactorIA shows anything). The upload is not published: do that in the GOG Developer Portal. The export's .factoria-export and AI_CONTENT_DISCLOSURE.md are not uploaded. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed run is an error whose data is that report. Examples: {"dryRun":true}, {"platforms":["windows"],"branch":"testing"}. Details: docs_read {"name":"exporting"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `platforms` | array | no | Which exports to upload: windows, macos, linux (aliases win, mac, osx also work). Default: every one that has an export folder and is set up for this store in factoria.json; the ones without are skipped with a warning. |
| `out` | string | no | Parent folder of the exports, relative to the project (the `out` of project.export). Default: build/export, where the exports are <game-slug>-<platform>. |
| `folders` | object | no | Upload another folder for a platform, relative to the project: {"windows": "dist/win"}. Takes precedence over `out`. |
| `dryRun` | boolean | no | Write the build files into .factoria/publish/<store>/ and return the exact command lines, what would be uploaded where and the warnings; start nothing and send nothing. A missing uploader, secret or id is a warning and the plan is still returned. Secrets are never in the result. Default false. |
| `branch` | string | no | GOG branch to put the build on (Pipeline Builder --branch). Default: none, the build is only uploaded. 'master' is refused: Pipeline Builder cannot publish to it. |

## `publish.googleplay` (modifies state)

Since 0.2.0.

Upload the release Android App Bundle (.aab) to Google Play (fastlane supply).

Runs `fastlane supply --aab <aab> --track <track> --release_status <draft|completed> --package_name <id of factoria.json> --json_key <service account key>` on the bundle `factoria export --platform android --format aab --release` writes (build/export/<game-slug>-android/<game-slug>.aab), or on `artifact`. A bundle signed with the debug key (no export.android.signing keystore, or a -debug.aab) is refused: Google Play rejects it. Needs: id (the package name), optionally factoria.json publish.googleplay {track (default internal), releaseStatus (draft, the default, or completed), changelogs: {"en-US": "store/whats-new-en.txt"} (files of up to 500 characters, uploaded as the release notes)}, fastlane (PATH, FACTORIA_FASTLANE, or publish.fastlane of ~/.factoria/export.json), and a Google Cloud service account JSON key with access to the app in the Play Console: its path in FACTORIA_GOOGLEPLAY_JSON_KEY (SUPPLY_JSON_KEY also works); the key is never copied, written, shown or logged. The first bundle of a new app must be uploaded by hand in the Play Console; this command works from the second one. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed fastlane is an error whose data is that report. Examples: {"dryRun":true}, {"track":"beta","releaseStatus":"completed"}. Details: docs_read {"name":"exporting"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `artifact` | string | no | The .aab to upload, relative to the project. Default: build/export/<game-slug>-android/<game-slug>.aab, which `factoria export --platform android --format aab --release` writes. |
| `out` | string | no | Folder that holds the build, relative to the project (the `out` of project.export). Default: build/export. |
| `dryRun` | boolean | no | Write the build files into .factoria/publish/<store>/ and return the exact command line, what would be uploaded where and the warnings; start nothing and send nothing. A missing uploader, secret or id is a warning and the plan is still returned. Secrets are never in the result. Default false. |
| `track` | string | no | Release track: internal, alpha, beta, production or the name of a closed testing track. Default: publish.googleplay.track, else internal. |
| `releaseStatus` | string ["draft","completed"] | no | draft: the release waits in the Play Console until you roll it out; completed: it rolls out at once. Default: publish.googleplay.releaseStatus, else draft. A new app that was never published accepts only draft. |

## `publish.itch` (modifies state)

Since 0.2.0.

Upload the desktop exports to itch.io (butler push, one channel per platform).

Runs `butler push <export folder> <user>/<game>:<channel> --userversion <version>` once per platform; the user/game comes from factoria.json publish.itch.game, the channel from publish.itch.channels (default windows, mac, linux) and the version from the game's version. Needs butler (PATH, FACTORIA_BUTLER, or publish.butler of ~/.factoria/export.json) signed in: run `butler login` once, or set BUTLER_API_KEY (never put it in the project). The export's .factoria-export and AI_CONTENT_DISCLOSURE.md are not uploaded. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed butler is an error whose data is that report (platforms before it were uploaded). Examples: {"dryRun":true}, {"platforms":["windows","linux"]}. Details: docs_read {"name":"exporting"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `platforms` | array | no | Which exports to upload: windows, macos, linux (aliases win, mac, osx also work). Default: every one that has an export folder and is set up for this store in factoria.json; the ones without are skipped with a warning. |
| `out` | string | no | Parent folder of the exports, relative to the project (the `out` of project.export). Default: build/export, where the exports are <game-slug>-<platform>. |
| `folders` | object | no | Upload another folder for a platform, relative to the project: {"windows": "dist/win"}. Takes precedence over `out`. |
| `dryRun` | boolean | no | Write the build files into .factoria/publish/<store>/ and return the exact command lines, what would be uploaded where and the warnings; start nothing and send nothing. A missing uploader, secret or id is a warning and the plan is still returned. Secrets are never in the result. Default false. |

## `publish.steam` (modifies state)

Since 0.2.0.

Upload the desktop exports to Steam (steamcmd, one depot per platform).

Uploads the folders project.export wrote (build/export/<game-slug>-windows, -macos, -linux) as a SteamPipe build: writes app_build_<appid>.vdf and one depot_build_<depot>.vdf per platform (the content root is the export folder) into .factoria/publish/steam/ and runs `steamcmd +login <account> +run_app_build <vdf> +quit`. Needs: the game's app id in steam_appid.txt, factoria.json publish.steam {account, depots: {windows: <id>, ...}}, steamcmd (PATH, FACTORIA_STEAMCMD, or publish.steamcmd of ~/.factoria/export.json), and a steamcmd login done once by hand (it keeps the password and the Steam Guard approval; this command never takes or stores a password). `branch` sets the build live on a beta branch; the default branch is never touched. The build description is the game's name and its factoria.json version. The export's .factoria-export and AI_CONTENT_DISCLOSURE.md are not uploaded. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed steamcmd is an error whose data is that report. Examples: {"dryRun":true}, {"platforms":["windows"],"branch":"beta"}. Details: docs_read {"name":"exporting"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `platforms` | array | no | Which exports to upload: windows, macos, linux (aliases win, mac, osx also work). Default: every one that has an export folder and is set up for this store in factoria.json; the ones without are skipped with a warning. |
| `out` | string | no | Parent folder of the exports, relative to the project (the `out` of project.export). Default: build/export, where the exports are <game-slug>-<platform>. |
| `folders` | object | no | Upload another folder for a platform, relative to the project: {"windows": "dist/win"}. Takes precedence over `out`. |
| `dryRun` | boolean | no | Write the build files into .factoria/publish/<store>/ and return the exact command lines, what would be uploaded where and the warnings; start nothing and send nothing. A missing uploader, secret or id is a warning and the plan is still returned. Secrets are never in the result. Default false. |
| `account` | string | no | Steam account that uploads (the builder account, with the 'Edit App Metadata' permission). Default: publish.steam.account of factoria.json. Its password is never stored: steamcmd keeps the login. |
| `appId` | integer | no | Steam app id. Default: the number in steam_appid.txt of the project (not 480, Valve's test app). |
| `branch` | string | no | Beta branch to set the build live on after the upload. Default: publish.steam.branch, else none. 'default' is refused: Steam sets that one by hand. |

