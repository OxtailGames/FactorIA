# Publishing guide: one checklist per store

How to get a FactorIA game onto Steam, the Epic Games Store, GOG, the Microsoft Store, Google Play, the App Store, itch.io
and your own website. For each store there are two lists: **What FactorIA does** (commands and settings, linked to the
section of [EXPORTING.md](EXPORTING.md) that documents them; they are not repeated here) and **What you still do by hand**
(accounts, forms, store page, review). The engine builds and uploads; it cannot open your accounts, answer legal forms
or press "release".

Store fees, sizes and rules change. Every fact below about a store is **as of 2026-10**, checked against the store's
official documentation where one could be found; confirm it on the store's own page before you pay or plan a date. The
review times are rough experience, not promises.

Vocabulary: "export" is `factoria export --platform <p>` or the command `project.export`
([EXPORTING.md](EXPORTING.md)); "upload" is a `publish.<store>` command
([Uploading to stores](EXPORTING.md#uploading-to-stores)); "dry run" is `"dryRun":true` on any of them: it needs no
account and no tool and prints the plan and what is missing. Run it first.

## Which store first

| Store | Fee (as of 2026-10) | Review before release | Platforms | What the engine automates |
|---|---|---|---|---|
| itch.io | none; you choose the revenue share (default 10%) | none: a page can be live at once | Windows, macOS, Linux, web (HTML5) | full upload (`publish.itch`; the web zip by hand or `butler push`) |
| Your own website | a host and a domain | none | web | build only (`--platform web`) |
| Google Play | 25 USD once | automated and manual checks, from hours to a few days; new personal accounts also need a 14-day closed test | Android | upload from the second bundle (`publish.googleplay`); the first one by hand |
| App Store (iOS) | 99 USD a year (Apple Developer Program) | App Review, usually 1 to 2 days | iOS | upload of an `.ipa` you archive in Xcode (`publish.appstore`, macOS only) |
| Steam | 100 USD per game, recouped after 1,000 USD of sales | store page and build reviews, about 1 to 5 days each; a "coming soon" page and a waiting period come first | Windows, macOS, Linux | full upload (`publish.steam`) |
| Microsoft Store | free for individuals, 99 USD once for a company account | certification, a few days | Windows | the MSIX package (`--format msix`, `sign.windows` to try it); upload from the second submission (`publish.microsoft`) |
| Epic Games Store | check the Developer Portal (a per-product fee has been reported); 0% of your first 1 million USD a year, 12% after | Epic approves the game and its page | Windows, macOS | full upload (`publish.epic`) |
| GOG | none; GOG keeps 30% | GOG accepts games itself, by application | Windows, macOS, Linux | full upload (`publish.gog`) |

A sensible order for a first game: **itch.io** (or your own site) to find out what is broken, with real players and no
review; then **Steam** if you want the biggest PC audience, or **Google Play** and the **App Store** for phones. Epic,
GOG and the Microsoft Store are extra doors once the game sells.

## Before any store

Do these once, in this order. Each is a full section elsewhere.

1. Set `name`, `id` (the bundle id / package name, it cannot change after release), `version` and `icon` in
   `factoria.json` ([Platform settings](EXPORTING.md#platform-settings), [Icon](EXPORTING.md#icon)). No image tool:
   `assets.draw_icon` ([ASSETS.md](ASSETS.md#the-game-icon-without-a-provider-assetsdraw_icon)).
2. Make the machine ready: `factoria setup` lists what is missing ([What each export needs](EXPORTING.md#what-each-export-needs),
   [Setting up this computer](EXPORTING.md#setting-up-this-computer)).
3. Export a release build of each platform you ship (`--release`, one `game.pak`;
   [Release build](EXPORTING.md#release-build-gamepak)). `FACTORIA_NOTICES.txt` stays with the game
   ([License notices](EXPORTING.md#license-notices)).
4. Ask the engine about AI-made content: `assets.disclosure`. Stores ask; the answer comes from the provenance records
   ([AI content disclosure](EXPORTING.md#ai-content-disclosure)).
5. Store page images are made with the tools in [Store page material](EXPORTING.md#store-page-material), which lists
   every store's image sizes. This guide only names which images each store requires.

## Steam

**What FactorIA does**
- Export `windows`, `macos` and `linux` ([Desktop](EXPORTING.md#desktop-linux-windows-macos)); macOS can be signed and
  notarized ([Signing and notarizing](EXPORTING.md#signing-and-notarizing-for-macos)).
- `publish.steam` (MCP `publish_steam`): writes the `.vdf` files and runs `steamcmd`
  ([Steam](EXPORTING.md#steam)). Always `{"dryRun":true}` first.
- `factoria.json`: `publish.steam.account`, `.depots`, `.branch`
  ([Store ids](EXPORTING.md#store-ids-publish-in-factoriajson)). The app id goes in `steam_appid.txt`
  (`platform.add_backend {"backend":"steam","appId":<id>}`).
- Environment: `FACTORIA_STEAMCMD` for the tool ([Finding the tools](EXPORTING.md#finding-the-tools)). The password is
  never given to FactorIA: run `steamcmd +login <account>` once
  ([Secrets](EXPORTING.md#secrets-environment-variables-and-factoria)).
- Upload the `macos` and `linux` depots from a Mac or Linux machine to keep the executable bit.

**What you still do by hand**
- Steamworks account: identity, tax and bank details, and the fee of 100 USD per game (recouped after 1,000 USD of
  adjusted gross revenue). Blocks the release. Setting up the account takes days (identity checks).
- The app, depots, package, build account and launch options
  ([What you set up by hand first](EXPORTING.md#what-you-set-up-by-hand-first)).
- Store page: short and long description, tags, system requirements, trailer, screenshots, and the capsule images
  (header, small, main, vertical, hero, logo; sizes in [Store page material](EXPORTING.md#store-page-material)).
  Blocks the release: Valve reviews the page.
- Content survey (AI-generated content included): Steam rates the game from it (no IARC), and Germany and Indonesia
  hide a game without a rating. The tax/"distribution" agreement.
- Reviews: the store page and then each build are reviewed, about 1 to 5 days each as of 2026-10. Valve also wants the
  page public as "coming soon" for a while and a waiting period after the fee before release; both have been reported
  with different lengths, so read Steamworks' release checklist and plan weeks, not days.
- Pricing, regional prices, release date, press the release button. Make the build live on `default` by hand
  (`publish.steam` refuses `default`).

## Epic Games Store

**What FactorIA does**
- Export `windows` (and `macos`) ([Desktop](EXPORTING.md#desktop-linux-windows-macos)).
- `publish.epic` (MCP `publish_epic`): runs `BuildPatchTool -mode=UploadBinary` once per platform
  ([Epic Games Store](EXPORTING.md#epic-games-store)). Raise `version` before every upload: a version is used once.
- `factoria.json`: `publish.epic.organizationId`, `.productId`, `.clientId`, `.artifacts`
  ([Store ids](EXPORTING.md#store-ids-publish-in-factoriajson)).
- Environment: `FACTORIA_EPIC_CLIENT_SECRET` (the secret), `FACTORIA_BUILDPATCHTOOL` (the tool)
  ([Secrets](EXPORTING.md#secrets-environment-variables-and-factoria),
  [Finding the tools](EXPORTING.md#finding-the-tools)).

**What you still do by hand**
- Epic Developer Portal account and organization; identity, tax and bank forms. Check the fee there (as of 2026-10 Epic
  publishes a revenue share, 0% of the first 1 million USD per product per year and 12% after, and a per-product fee has
  been reported by third parties).
- The product, one artifact per platform, the Build Patch Tool client and its secret
  ([What you set up by hand first](EXPORTING.md#what-you-set-up-by-hand-first)).
- Store page: texts, screenshots, trailer, and the store images (see
  [Store page material](EXPORTING.md#store-page-material)). Ratings: Epic offers an IARC questionnaire in the portal.
- After each upload: assign the build to a platform label and publish in the Dev Portal.
- Approval: Epic reviews the game and the page before it goes live. Blocks the release; allow a week or more.
- Pricing and release date.

## GOG

**What FactorIA does**
- Export `windows` (and `macos`, `linux`) ([Desktop](EXPORTING.md#desktop-linux-windows-macos)).
- `publish.gog` (MCP `publish_gog`): writes the Pipeline Builder project and runs
  `GOGGalaxyPipelineBuilder build-game` ([GOG](EXPORTING.md#gog)). `"branch"` cannot be `master`.
- `factoria.json`: `publish.gog.productId`, `.clientId`, `.languages`
  ([Store ids](EXPORTING.md#store-ids-publish-in-factoriajson)).
- Environment: `FACTORIA_GOG_USERNAME` and `FACTORIA_GOG_PASSWORD` (or a cached sign-in), `FACTORIA_GOG_PIPELINE_BUILDER`
  ([Secrets](EXPORTING.md#secrets-environment-variables-and-factoria)).

**What you still do by hand**
- GOG accepts games by application and review of the game: apply first (blocks everything; can take weeks), then you get
  a Developer Portal product. No fee as of 2026-10.
- Identity, tax and payment details in the Developer Portal.
- Store page: texts, screenshots, trailer, GOG's own art (sizes in
  [Store page material](EXPORTING.md#store-page-material)), system requirements, languages, age rating.
- The game must work without DRM or an online account. GOG builds the offline installers from your files; check the
  result on a clean machine.
- Publish the build from the portal (Builds and Branches); GOG's QA tests it. Blocks the release; days.
- Pricing and release date.

## Microsoft Store

**What FactorIA does**
- Exports `windows` with the game's icon and version information in the exe, and with `--format msix` the MSIX package
  (`<slug>-windows.msix`, unsigned, on any computer): manifest, logos from the icon, block map
  ([Microsoft Store](EXPORTING.md#microsoft-store)).
- `sign.windows` signs the package with your `.pfx` (or, on Windows, a self-signed test certificate) to install it on a PC.
- `publish.microsoft` (MCP `publish_microsoft`) uploads the package with `msstore` once the app and its first
  submission exist.

**What you still do by hand**
- Partner Center account (free for individual developers, about 99 USD once for a company, as of 2026-10), identity
  verification (days for a company).
- Reserve the app name; copy the package identity and publisher from the product identity page.
- Fill `export.windows.msix` with the identity of Partner Center and export with `--format msix`
  ([Microsoft Store](EXPORTING.md#microsoft-store)). Upload the package unsigned: Microsoft signs it after certification.
- For `publish.microsoft`: an Azure AD application associated with Partner Center, and its ids and secret in the environment.
- Store listing: texts, screenshots, optional trailer, store logos (see
  [Store page material](EXPORTING.md#store-page-material)). Privacy policy URL ([LEGAL.md](LEGAL.md)), age rating
  (IARC questionnaire in Partner Center), pricing, markets and availability.
- Certification: Microsoft tests the package; a few days. Blocks the release. An update raises the manifest `Version`.

## Google Play

**What FactorIA does**
- Settings: `export.android` (`format: "aab"`, `versionCode`, `signing.keystore`/`alias`, adaptive icon)
  ([`export.<platform>`](EXPORTING.md#exportplatform)). The `id` of the game is the package name.
- Export: `factoria export --platform android --format aab --release`
  ([Android](EXPORTING.md#android), keystore: [MOBILE.md](MOBILE.md#signing-and-release)). Passwords come from
  `FACTORIA_ANDROID_KEYSTORE_PASSWORD` (and `..._KEY_PASSWORD`) or `~/.factoria/export.json`.
- `publish.googleplay` (MCP `publish_googleplay`): `fastlane supply` uploads the `.aab` and the release notes
  ([Google Play](EXPORTING.md#google-play)). `factoria.json`: `publish.googleplay.track`, `.releaseStatus`, `.changelogs`.
  Environment: `FACTORIA_GOOGLEPLAY_JSON_KEY`, `FACTORIA_FASTLANE`.
- A debug-signed bundle is refused before anything is sent. Raise `version` or `export.android.versionCode` every upload.

**What you still do by hand**
- Play Console account: 25 USD once, identity verification (and, for organizations, a D-U-N-S number). Blocks
  everything; verification takes days.
- Create the app and **upload the first bundle yourself**; the API works from the second one
  ([Google Play](EXPORTING.md#google-play)). Set up Play App Signing.
- New personal accounts (created after 2023-11-13): a closed test with at least 12 testers opted in for 14 days in a row
  before you can apply for production access. Blocks the release by two weeks or more; check Google's current rule.
- Store listing: title, short and long description, icon, feature graphic, phone screenshots, optional trailer (sizes in
  [Store page material](EXPORTING.md#store-page-material)). Only the release notes are uploaded by FactorIA.
- Forms: content rating (IARC questionnaire), target audience, **Data safety**, ads declaration, **privacy policy URL**
  (required on every app), news/health/financial declarations. Store privacy answers for the engine's own behaviour:
  [MOBILE.md](MOBILE.md#store-privacy-forms).
- Review: automated and manual, hours to a few days (longer for new accounts). Pricing, countries, rollout percentage.

## App Store (iOS)

**What FactorIA does**
- Settings: `export.ios` (`teamId`, `buildNumber`, `iconBackground`, `usesNonExemptEncryption`, `privacy`)
  ([`export.<platform>`](EXPORTING.md#exportplatform)). The bundle id is the game's `id`. The export writes
  `PrivacyInfo.xcprivacy` and `Info.plist` ([iOS](EXPORTING.md#ios)).
- Export `factoria export --platform ios`, on a Mac with Xcode: an Xcode project (`build_ios.sh`), not an `.ipa`.
- `publish.appstore` (MCP `publish_appstore`): uploads an `.ipa` you archived and exported in Xcode
  ([App Store Connect](EXPORTING.md#app-store-connect-testflight)). `factoria.json`: `publish.appstore.appleId`.
  Environment: `FACTORIA_APPSTORE_API_KEY`, `FACTORIA_APPSTORE_API_KEY_ID`, `FACTORIA_APPSTORE_API_ISSUER`,
  `FACTORIA_XCRUN`. Raise `export.ios.buildNumber` every upload.

**What you still do by hand**
- Apple Developer Program: 99 USD a year, identity (and a D-U-N-S number for an organization). Blocks everything; days.
- A Mac with Xcode: signing certificate and profile, Product > Archive, Organizer > Distribute > Export the `.ipa`.
- The app record in App Store Connect and the App Store Connect API key.
- App Store page: name, subtitle, description, keywords, screenshots for the required device sizes, optional preview
  video, app icon, support URL (sizes in [Store page material](EXPORTING.md#store-page-material)).
- Forms: age rating questionnaire, App Privacy ("nutrition label"), export compliance (encryption), review notes and a
  demo account if the game needs one, a **privacy policy URL**
  ([MOBILE.md](MOBILE.md#store-privacy-forms)).
- TestFlight: internal testers at once; external testers need Apple's beta review (about a day).
- App Review: usually 1 to 2 days as of 2026-10; a rejection restarts the clock. Blocks the release. Pricing,
  availability, release mode (manual, automatic).

## itch.io

**What FactorIA does**
- Export `windows`, `macos`, `linux` and/or `web` ([Desktop](EXPORTING.md#desktop-linux-windows-macos),
  [Web](EXPORTING.md#web)); the web export also writes the zip itch.io takes as an HTML5 game.
- `publish.itch` (MCP `publish_itch`): `butler push` per platform channel ([itch.io](EXPORTING.md#itchio)).
  `factoria.json`: `publish.itch.game` (`user/game`), `.channels`. Environment: `BUTLER_API_KEY` (or `butler login`),
  `FACTORIA_BUTLER`.
- The web zip is not pushed by `publish.itch` yet: `butler push build/export/<slug>-web.zip <user>/<game>:html5`
  ([Web](EXPORTING.md#web)).

**What you still do by hand**
- An itch.io account (free) and the project page (can stay a draft). No identity or tax form to start; payments need a
  payout setup (PayPal/Stripe) and tax information when you sell.
- Page: title, description, cover image, screenshots, tags, trailer, and for the web build "This file will be played in the
  browser" plus the viewport size (sizes in [Store page material](EXPORTING.md#store-page-material)).
- Pricing (free, paid, pay what you want), revenue share, visibility; age and content tags, and a note on AI-made
  content ([AI content disclosure](EXPORTING.md#ai-content-disclosure)).
- No review before release: nothing blocks you except the above. Release by setting the page public.

## Your own website (web export)

**What FactorIA does**
- `factoria export --platform web` writes a folder any static host serves, and a zip
  ([Web](EXPORTING.md#web)). It needs the web player ([Where the player comes from](EXPORTING.md#web)). No settings, no
  icon: the page title is the game's `name`.

**What you still do by hand**
- A host and a domain; HTTPS; serve `.wasm` as `application/wasm` (almost every host does). Test the page over http,
  not from a file ([Web](EXPORTING.md#web)).
- Test the browsers you care about (WebGL 2 is required), audio after the first click, touch controls on phones,
  first-load size.
- A privacy policy ([LEGAL.md](LEGAL.md)) and, in the EU, a cookie/consent note when you add analytics or ads; the game
  itself collects nothing.
- Payments, accounts and updates are yours: this route has no store behind it.

## Before you release: checklist for every store

- [ ] `id`, `name`, `version` and `icon` are final (the `id` cannot change after release); `version` (and
      `export.android.versionCode`, `export.ios.buildNumber`) is higher than the last upload: every store accepts a
      number once.
- [ ] A release build of each platform, from a downloaded FactorIA (its player is release-built), not a debug build;
      `FACTORIA_NOTICES.txt` is in the folder.
- [ ] `factoria validate` and `factoria test` are clean; the game ran on a real device of each platform (phone: touch,
      safe area, rotation, Back button; PC: a clean machine, a gamepad).
- [ ] Every fake id in `publish` is replaced; secrets are in environment variables, never in the project.
- [ ] `publish.<store>` dry run is clean for each store.
- [ ] AI content answered the same in every store form (`assets.disclosure`).
- [ ] Privacy: what the game collects is known and the same in every form; a privacy policy page exists and its URL is
      ready (Google Play, App Store and Microsoft Store require one); templates and the full checklist are in
      [LEGAL.md](LEGAL.md#checklist).
- [ ] Age rating questionnaires filled (IARC covers Google Play, Microsoft and Epic; Steam and Apple have their own).
- [ ] Store page texts in every language you ship, screenshots made from the real game, store images at each store's sizes
      ([Store page material](EXPORTING.md#store-page-material)), trailer if the store wants one.
- [ ] Support contact (e-mail or URL), a license/credits screen, and the crash log location known
      (`log.txt` in the save folder).
- [ ] Accounts: identity/tax/bank forms accepted (this is the step that takes days; start it first), fees paid.
- [ ] Pricing, regions and release date chosen; for Steam the "coming soon" page is public in time.
- [ ] Plan the first update: how a fix reaches players (new version, same flow), and where players report problems.
