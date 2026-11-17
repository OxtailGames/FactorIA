# Store and platform services: achievements, stats, leaderboards, cloud saves, purchases

One script API, `platform`, for what a store gives a game: **achievements**, **stats**, **leaderboards**, **cloud
saves**, **in-app purchases**, the store **overlay**, **rich presence** and the guests of **Remote Play Together**. A game is written once against it; a backend
decides what answers: the **fake** store (development and every test), **none** (an exported game that has no store
plugin), or a store SDK that a native plugin wraps (Steam: [below](platform/PLATFORM_BACKENDS.md#steam-steamworks); Apple: [section
6](platform/PLATFORM_APPLE_GOOGLE.md#6-apple-storekit-2-game-center-and-icloud); Google Play: [section 7](platform/PLATFORM_APPLE_GOOGLE.md#7-google-play-billing-play-games-services-and-play-integrity)).

```js
import { platform } from "factoria";

if (platform.has("achievements")) platform.achievements.unlock("first_win").catch(() => {}); // best effort
const bought = await platform.purchases.buy("gems_100"); // a Promise: the store answers when it answers
if (bought.status === "purchased") {
  addGems(100);
  await platform.purchases.finish(bought.transactionId); // grant first, finish after
}
```

[MENUS.md](MENUS.md) has a shop built on it, and `tests/platform.test.js` of that kit drives it against the fake store.
Do not confuse `platform` (this API) with `game.platform` of the `factoria` module (the operating system's name:
`"windows"`, `"ios"`...) and with `game.platform` of `factoria:test` (the fake store's test hooks, below).

A game's own web requests (`http.fetch`) go through the same machinery (a Promise, `platform.has("http")`, the fake in
tests, `game.platform.respond`) but are **not** a store service: they are served by the system's HTTP client in a running
game, need hosts declared in `factoria.json` and are written up in [NETWORKING.md](NETWORKING.md). The same goes for the two
services built on it, `analytics` (events sent after the player consents) and `remoteConfig` (values read from your server,
cached for offline play): [ANALYTICS.md](ANALYTICS.md). They are not store services either, and a store backend never
sees them.

## Pages

- [The script API and the fake store](platform/PLATFORM_API.md): The script API of the store services and the fake store used to test with.
- [Backends and backend plugins](platform/PLATFORM_BACKENDS.md): Which backend runs, and how to write a backend plugin.
- [Apple and Google Play](platform/PLATFORM_APPLE_GOOGLE.md): Apple (StoreKit 2, Game Center, iCloud) and Google Play (Billing, Play Games, Play Integrity).
- [Ads and consent](platform/PLATFORM_ADS.md): Ads: Google AdMob and consent on Android and iOS.

## 1. The catalog: `"platform"` in factoria.json

A game declares what it uses. The engine checks every id against it before a request leaves the game, so a typo is an
error with a "did you mean", not a silent failure inside a store SDK. Every section is optional.

```json
"platform": {
  "achievements": [
    { "id": "first_win", "name": "First win", "description": "Win one match.", "hidden": false,
      "ids": { "steam": "ACH_WIN_ONE_GAME", "apple": "com.studio.game.first_win" } }
  ],
  "stats": [ { "id": "wins", "type": "int", "ids": { "steam": "NumWins" } } ],
  "leaderboards": [
    { "id": "high_score", "name": "High score", "order": "descending", "ids": { "apple": "high_score_v2" } },
    { "id": "daily_route", "name": "Daily route", "order": "ascending", "period": "daily" }
  ],
  "products": [
    { "id": "gems_100", "type": "consumable", "title": "100 gems", "price": 0.99, "currency": "USD",
      "ids": { "apple": "com.studio.game.gems100" } },
    { "id": "remove_ads", "type": "nonConsumable", "title": "Remove ads", "price": 2.99 }
  ],
  "ads": { "placements": [ { "id": "more_time", "type": "rewarded", "description": "Watch to get 20 s more.",
                              "ids": { "admob": "ca-app-pub-1234567890123456/1234567890" } } ] },
  "backend": "auto"
}
```

| Field | Meaning |
|---|---|
| `id` | What scripts pass to `platform.*`: `A-Z a-z 0-9 _ . -`, 1 to 64 characters, unique in its section. |
| `ids` | The id each store uses for the same thing: `{"steam": "ACH_WIN_ONE_GAME"}`. The key is the backend's name; without an entry the store id is `id`. |
| achievements | `name` (required unless `nameKey`), `nameKey`, `description`, `descriptionKey`, `hidden` (default false). |
| stats | `type`: `"int"` (default) or `"float"`. An int stat takes whole numbers. |
| leaderboards | `name` (required unless `nameKey`), `nameKey`, `order`: `"descending"` (higher is better, default) or `"ascending"` (lower is better: times), `period`: `"allTime"` (default), `"daily"` or `"weekly"` (below). |
| `ads.placements` | `id` (where the game offers an ad), `type`: `"rewarded"` (the only kind so far), `description` (for you), `ids` (the ad unit id per network and platform: `{"admob": "ca-app-pub-1234567890123456/1234567890", "admob_ios": "ca-app-pub-1234567890123456/0987654321"}`, Android's and iOS's units are different ones). [Ads](platform/PLATFORM_API.md#ads). |
| `ads.appIds` | The ad network's app id per platform: `{"android": "ca-app-pub-1234567890123456~1234567890", "ios": "ca-app-pub-1234567890123456~0987654321"}` (AdMob's, with a tilde; an app on each platform has its own). A release export writes it into the Android manifest or the iOS Info.plist (`GADApplicationIdentifier`). [Section 8](platform/PLATFORM_ADS.md#8-ads-google-admob-and-consent-on-android-and-ios). |
| `ads.trackingPrompt` | `true` to ask for Apple's App Tracking Transparency (the "Allow tracking" sheet) on iOS; default `false`. The sheet comes after the consent form, never for a game for children. [Ads on iOS](platform/PLATFORM_ADS.md#ads-on-ios). |
| `ads.trackingDescription`, `ads.trackingDescriptionKey` | The sentence of that sheet (`NSUserTrackingUsageDescription`), plain or as a key of the string tables (translated per language like the other texts of the Info.plist). Default: "This identifier will be used to deliver personalized ads to you." Apple reviews it. |
| `ads.audience` | Who plays: `"general"` (default), `"children"` (the whole game is for children) or `"mixed"` (children and adults: the game asks the age). [Children and consent](platform/PLATFORM_ADS.md#children-and-consent). |
| `ads.backend` | Which ads plugin to use when the game has several: its plugin name. `"auto"` or absent: the only one, or the first by name with a warning. |
| products | `type`: `"consumable"`, `"nonConsumable"` or `"subscription"` (required), `title` (required unless `titleKey`), `titleKey`, `description`, `descriptionKey`, `price` (a number, `currency` default `"USD"`). Only the fake store uses `price`: real stores give their own, localized. |
| `backend` | Which backend plugin to use: `"auto"` (default), a plugin's name, or one per platform: `{"windows": "steam", "macos": "steam", "linux": "steam", "ios": "apple", "android": "googleplay"}`. See section 5. |

### The catalog from scripts

`game.project.platform` is the section as written in factoria.json, read only: `game.project.platform.products`
(`{ id, type, title, titleKey, price... }`), `.achievements`, `.stats`, `.leaderboards` (`{ id, name, nameKey, order, period }`) and `.ads.placements`.
Use it instead of a second table of ids and product types in the code (is `remove_ads` a consumable?), and translate a
`nameKey` with `i18n.t(entry.nameKey)` for a screen of your own. It is absent when the game declares no `"platform"`.
`platform.state()` in tests lists only the ids.

`factoria validate` reports every problem of the section (`factoria.json#/platform/products/1/type: "consumable " is
not a product type; use one of "consumable", "nonConsumable", "subscription" (did you mean "consumable"?)`), and a
`backend` that names a plugin the project does not declare. At run time a section with errors counts as empty (each
call then says its id is not declared) and the engine logs why.

### Translated texts

A game with `locales/*.json` (docs/LOCALIZATION.md) keeps its texts in one place: `nameKey` (achievements and leaderboards), `descriptionKey` and
`titleKey` name a key of the string tables instead of writing the text in the catalog.

```json
{ "id": "first_win", "nameKey": "achievements.first_win.name", "descriptionKey": "achievements.first_win.description" },
{ "id": "gems_100", "type": "consumable", "titleKey": "shop.product.gems_100", "price": 0.99 }
```

- `platform.achievements.list()` returns `name` and `description`, and `platform.purchases.products()` (fake store)
  `title` and `description`, in the current language (`i18n.set_language` changes the next answer). A key that no table
  has falls back to the plain `name` / `title` / `description` if the entry has one, else shows the key.
- A leaderboard's `nameKey` works the same way: the request the backend gets (`name`, in the fake's request log
  `game.platform.calls()`) carries the board's name in the current language. The game's own board screen reads the
  catalog itself, see "The catalog from scripts" below.
- The plain text may stay next to the key: it is what the store console and `factoria validate` see when a language
  has no table.
- `factoria validate` reports a key the default language's table lacks, at its JSON pointer
  (`factoria.json#/platform/achievements/0/nameKey`), with the closest key as "did you mean".
- Real stores: the catalog does **not** translate what the player sees in the store's own screens. Steam, the App Store
  (Game Center, StoreKit) and Google Play each keep the localized names, descriptions and prices of achievements and
  products in their console (Steamworks, App Store Connect, Play Console): translate them there. The catalog's texts are
  used by the fake store (`products()`), and by `achievements.list()` on every backend whose store answers without
  texts (Steam, Game Center, Play Games), so the game's own achievements screen can show them in the game's language.
  `purchases.products()` on a real store returns that store's title, description and price, localized by the store for
  the player's country, not by the game's language setting.
