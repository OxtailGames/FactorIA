[Back to the index](../README.md)

# Commands: sign

## `sign.macos` (modifies state)

Since 0.2.0.

Sign, notarize and staple the exported macOS app (Developer ID), and zip it for sharing.

Takes the app `project.export` wrote for macOS (build/export/<game-slug>-macos/<Name>.app) and makes it open on any Mac without Gatekeeper warnings: codesign of every native plugin library in Contents/Frameworks (deepest first) and then the app, with the hardened runtime and a secure timestamp (the export's <slug>.entitlements when `provisioningProfile` is given; the profile is embedded), codesign --verify --deep --strict, then `xcrun notarytool submit --wait` on a zip of the app (Apple's notary log is quoted when it refuses the app), `xcrun stapler staple`, spctl --assess, and finally a zip to share next to the export folder (<game-slug>-macos.zip). Needs a Mac (codesign, notarytool and stapler exist nowhere else): on another computer only `dryRun` works and a real run is an error that says so. `dryRun: true` checks everything and returns the exact command lines in steps[]. Identity: `identity` ("Developer ID Application: Your Name (TEAMID)"; `security find-identity -v -p codesigning` lists them), else FACTORIA_MACOS_SIGN_IDENTITY, else sign.macos.identity of ~/.factoria/export.json; "-" signs ad hoc (this Mac only, no notarization). Notarization logs in with the first of: a keychain profile (`keychainProfile`, FACTORIA_NOTARY_PROFILE, sign.macos.notaryProfile; saved once with `xcrun notarytool store-credentials`), an App Store Connect API key (`apiKey` file, `apiKeyId`, `apiIssuer`; or FACTORIA_NOTARY_API_KEY / _KEY_ID / _ISSUER), or an Apple ID (`appleId` + `teamId` or FACTORIA_APPLE_ID / FACTORIA_APPLE_TEAM_ID, and the app-specific password in FACTORIA_APPLE_APP_PASSWORD only). No password is ever an argument of this command, in factoria.json, in a result or in a log. `notarize` unset notarizes when there are credentials and a Developer ID identity (else only signs, with a warning); true makes missing credentials an error; false only signs. Returns {app, dryRun, identity, identityFrom, credentials, signed, verified, notarized, stapled, notarizationId, zip, steps[{title, command, commandLine, ran, exitCode}], warnings[], nextSteps[]}. The export is replaced by the next project.export: sign again after every export. Details: docs_read {"name":"exporting"}. Examples: {"dryRun":true}, {"identity":"Developer ID Application: Ada Lovelace (ABCDE12345)","keychainProfile":"factoria-notary"}, {"identity":"-"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `app` | string | no | The .app to sign, relative to the project. Default: build/export/<game-slug>-macos/<Name>.app (the export of this game). |
| `out` | string | no | Parent folder of the export, relative to the project (the `out` of project.export). Default: build/export. |
| `identity` | string | no | The signing identity: the name of a 'Developer ID Application' certificate or its SHA-1 hash; "-" = ad hoc. Default: FACTORIA_MACOS_SIGN_IDENTITY, else sign.macos.identity of ~/.factoria/export.json. |
| `keychain` | string | no | A keychain file that holds the certificate (or the notary profile). Default: FACTORIA_MACOS_KEYCHAIN, else the user's keychains. |
| `provisioningProfile` | string | no | A .provisionprofile to embed in the app (needed for the capabilities the plugins ask for: Game Center, iCloud). With it the export's <slug>.entitlements are applied. Absolute path, or relative to the project. |
| `entitlements` | string | no | An entitlements file for the app. Default: the export's <slug>.entitlements, used only with a provisioningProfile. Absolute path, or relative to the project. |
| `notarize` | boolean | no | true = notarize (an error without a Developer ID identity and credentials); false = only sign; unset = notarize when credentials are found. |
| `keychainProfile` | string | no | notarytool keychain profile, saved with `xcrun notarytool store-credentials <name>`. Default: FACTORIA_NOTARY_PROFILE, else sign.macos.notaryProfile of ~/.factoria/export.json. |
| `apiKey` | string | no | App Store Connect API key file (AuthKey_<id>.p8), absolute or relative to the project. Default: FACTORIA_NOTARY_API_KEY. |
| `apiKeyId` | string | no | Key id of the API key. Default: FACTORIA_NOTARY_API_KEY_ID. |
| `apiIssuer` | string | no | Issuer id of a team API key (not needed for an individual key). Default: FACTORIA_NOTARY_API_ISSUER. |
| `appleId` | string | no | Apple ID for notarization. Default: FACTORIA_APPLE_ID (or APPLE_ID). The app-specific password is read from FACTORIA_APPLE_APP_PASSWORD only. |
| `teamId` | string | no | Apple Team ID (10 characters) for notarization with an Apple ID. Default: FACTORIA_APPLE_TEAM_ID (or APPLE_TEAM_ID). |
| `zip` | string | no | Where the zip to share goes, relative to the project. Default: next to the export folder, <game-slug>-macos.zip. |
| `dryRun` | boolean | no | Check everything and return the exact command lines in steps[]; sign and send nothing. Works on any computer. Default false. |

