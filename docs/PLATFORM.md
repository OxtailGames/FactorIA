# Store and platform services: achievements, stats, leaderboards, cloud saves, purchases

One script API, `platform`, for what a store gives a game: **achievements**, **stats**, **leaderboards**, **cloud
saves**, **in-app purchases**, the store **overlay**, **rich presence** and the guests of **Remote Play Together**. A game is written once against it; a backend
decides what answers: the **fake** store (development and every test), **none** (an exported game that has no store
plugin), or a store SDK that a native plugin wraps (Steam: [below](#steam-steamworks); Apple: [section
6](#6-apple-storekit-2-game-center-and-icloud); Google Play: [section 7](#7-google-play-billing-play-games-services-and-play-integrity)).

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
game, need hosts declared in `factoria.json` and are written up in [NETWORKING.md](NETWORKING.md).

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
| `ads.placements` | `id` (where the game offers an ad), `type`: `"rewarded"` (the only kind so far), `description` (for you), `ids` (the ad unit id per network and platform: `{"admob": "ca-app-pub-1234567890123456/1234567890", "admob_ios": "ca-app-pub-1234567890123456/0987654321"}`, Android's and iOS's units are different ones). [Ads](#ads). |
| `ads.appIds` | The ad network's app id per platform: `{"android": "ca-app-pub-1234567890123456~1234567890", "ios": "ca-app-pub-1234567890123456~0987654321"}` (AdMob's, with a tilde; an app on each platform has its own). A release export writes it into the Android manifest or the iOS Info.plist (`GADApplicationIdentifier`). [Section 8](#8-ads-google-admob-and-consent-on-android-and-ios). |
| `ads.trackingPrompt` | `true` to ask for Apple's App Tracking Transparency (the "Allow tracking" sheet) on iOS; default `false`. The sheet comes after the consent form, never for a game for children. [Ads on iOS](#ads-on-ios). |
| `ads.trackingDescription`, `ads.trackingDescriptionKey` | The sentence of that sheet (`NSUserTrackingUsageDescription`), plain or as a key of the string tables (translated per language like the other texts of the Info.plist). Default: "This identifier will be used to deliver personalized ads to you." Apple reviews it. |
| `ads.audience` | Who plays: `"general"` (default), `"children"` (the whole game is for children) or `"mixed"` (children and adults: the game asks the age). [Children and consent](#children-and-consent). |
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

## 2. The script API

`import { platform } from "factoria"`. **Every call returns a Promise.**

| Call | Resolves with |
|---|---|
| `platform.backend` | The name of the backend that runs: `"fake"`, `"none"`, `"steam"`... (the plugin's name). |
| `platform.has(service)` | Whether the backend offers the service: `"achievements"`, `"stats"`, `"leaderboards"`, `"cloudSave"`, `"purchases"`, `"overlay"`, `"presence"`, `"integrity"`, `"ads"`, `"remotePlay"`, and `"http"` (`http.fetch`, [NETWORKING.md](NETWORKING.md): the system's HTTP client, or the fake in tests). Check it before using a service that a store may not have. |
| `platform.release` | `true` in a shipped game, `false` in development runs (`factoria run`, the editor), tests and the MCP server. Use it to leave out what is only for development (a test-ad stub, a cheat button). |
| `platform.player` | The last known `{ id, name, signedIn }` (empty and signed out until the store tells). |
| `platform.signIn()` | `{ id, name, signedIn }`. Always allowed. |
| `platform.on(event, fn)` | Returns a function that removes the listener. Events: below. |
| `platform.achievements.unlock(id)` | `{ id, unlocked: true, newly }` (`newly` is false when it was unlocked already). |
| `platform.achievements.progress(id, fraction)` | `{ id, progress, unlocked }`. `fraction` is 0 to 1; 1 unlocks. |
| `platform.achievements.list()` | `[{ id, name, description, unlocked, progress }]`, the whole catalog; `name` and `description` are in the current language (see "Translated texts"). |
| `platform.achievements.reset()` | Development: clears every achievement. |
| `platform.stats.get(id)` | The number. |
| `platform.stats.set(id, value)` | The new value. An int stat needs a whole number. |
| `platform.stats.add(id, delta)` | The new value (a get, then a set: not atomic). |
| `platform.leaderboards.submit(id, score)` | `{ id, score, best }` (and `periodStart`, `periodEnd` when the store says; "Leaderboard periods"); `best` is the player's best after this (on a daily or weekly board: today's or this week's). The score is a whole number. |
| `platform.leaderboards.entries(id, { range = "top", count = 10 })` | `[{ rank, name, score, playerId, isPlayer }]` (of the current period). `range`: `"top"`, `"around"` (the player's neighbours) or `"friends"`; `count` 1 to 100. |
| `platform.cloud.save(key, value)` | `{ key, bytes }`. `value` is anything JSON can hold. Keys: `A-Z a-z 0-9 _ . -`, up to 64 characters. |
| `platform.cloud.load(key)` | The value, or `undefined` when there is no such key. |
| `platform.cloud.list()` / `.remove(key)` | `["key", ...]` / nothing. |
| `platform.cloud.stat(key)` | `{ exists: false }` for a key that is not there (that is an answer, not an error), else `{ exists: true, size, modified }`: `size` in bytes of the saved JSON text, `modified` in Unix seconds, or `null` when the store keeps no time. It does not give the text back. See "Which save is newer". |
| `platform.remotePlay.sessions()` | `[{ id, guestName, guestId, deviceName, formFactor, resolution }]`: the guests that are connected through Remote Play Together now (`[]` when nobody is). See "Remote Play guests". |
| `platform.purchases.products(ids?)` | `[{ id, title, description, price, priceValue, currency, type }]` as the store shows them. `price` is text for the player's country (`"$0.99"`). A product the store does not know is left out. |
| `platform.purchases.buy(id)` | `{ status, productId, transactionId, receipt }`. `status` is `"purchased"`, `"pending"` (Ask to Buy: it arrives later as a `purchase` event) or `"cancelled"`. `transactionId` and `receipt` only when purchased. |
| `platform.purchases.finish(transactionId)` | Nothing. Tells the store the game granted the purchase. A `transactionId` the game was not told about (or already finished, or refunded) **rejects** with `unknownId`, like every other store failure: `await platform.purchases.finish(id).catch(...)` catches it. |
| `platform.purchases.restore()` | `[{ productId, transactionId, receipt }]`: what the player owns that does not get used up (non-consumables, active subscriptions). |
| `platform.overlay.open(page, id?)` | Opens the store's own screen: `page` is `"achievements"`, `"leaderboards"`, `"friends"` or `"store"`; `id` narrows it to one achievement, leaderboard or product. |
| `platform.presence.set(text, data?)` | "What the player is doing" for friends. `data`: an object whose values are strings. |
| `platform.ads.available(placement)` | `true` when a rewarded ad is ready at the placement (`false`: no fill, or the consent was refused). |
| `platform.ads.showRewarded(placement)` | `{ rewarded, reason? }` when the ad ends. `rewarded` is true only when the player watched it to the end: pay the reward then. Otherwise `reason` is `"closedEarly"`, `"noFill"` or `"consentRefused"`. A network failure rejects. |
| `platform.ads.consent()` | `{ gdpr, tracking, canShowAds, privacyOptions }`: what the consent sheets answered. `gdpr`: `"granted"`, `"denied"`, `"notRequired"` or `"unknown"`; `tracking` (Apple's App Tracking Transparency): `"authorized"`, `"denied"`, `"notDetermined"`, `"restricted"` or `"notRequired"` (always on Android; on iOS when `ads.trackingPrompt` is off); `canShowAds` is false when the GDPR consent was refused; `privacyOptions`: `"required"` when the game must offer a button that opens the form where the player changes their choices, else `"notRequired"` (or `"unknown"` before the consent flow ended). |
| `platform.ads.setUnderAge(underAge)` | Nothing. Tells the platform whether the player is under the age of consent, after the game asked the age (the menu kit's `ageGate` part does). Required for `audience: "mixed"`. [Children and consent](#children-and-consent). |
| `platform.ads.privacyOptions()` | `{ shown }` when the form closes. Opens the form where the player changes their ad choices; show its button only when `consent().privacyOptions` is `"required"`. |
| `platform.ads.audience`, `platform.ads.underAge` | `"general"`, `"children"` or `"mixed"` from the catalog; and the answer of `setUnderAge` (`true` for a children's game, `null` while the game has not asked). |
| `platform.adsBackend` | Which backend answers `platform.ads`: an ads plugin (`"admob"`), the store backend when it offers ads itself (`"fake"`), or `"none"`. |
| `platform.integrity.token(challenge)` | `{ token }`: a signed token for **your server** to verify (see below). `challenge` is a string your server made: 16 to 500 characters of URL-safe Base64 (`A-Z a-z 0-9 - _ =`); anything else throws at once. |

### Ads

A game with a "watch an ad" button declares its places in `platform.ads.placements` and asks the platform:

```js
if (await platform.ads.available("more_time")) {
  const ad = await platform.ads.showRewarded("more_time");
  if (ad.rewarded) addSeconds(20);              // only a finished ad pays
  else if (ad.reason === "closedEarly") showHint("Watch it to the end to get the time.");
}
```

The placement id is checked against the catalog (a typo throws with a "did you mean"). The consent sheets (Google's UMP
for the GDPR, Apple's App Tracking Transparency) are the platform's job: the game reads their answer with
`platform.ads.consent()` and never needs its own stub. **The fake backend answers with a scripted test ad**, the same
path in development and in tests, so a game has no ad provider of its own. It draws nothing: the ad ends at once (or after
`delayFrames`) the way `game.platform.ad(...)` says, "watched" unless told otherwise. Check `platform.release` to keep a
development-only control out of a shipped build.

Who answers in a shipped game:

| Platform | Ads |
|---|---|
| Android with the `admob` plugin (`platform.add_backend {"backend": "admob"}`) | Google AdMob rewarded ads and Google's consent form (UMP): [section 8](#8-ads-google-admob-and-consent-on-android-and-ios). |
| iOS with the `admob` plugin | Google AdMob rewarded ads, Google's consent form (UMP) and, when the catalog asks, Apple's App Tracking Transparency sheet: [Ads on iOS](#ads-on-ios). |
| Anything else (Windows, macOS, Linux, Steam, a game without the plugin) | No backend offers the `"ads"` service (Google has no AdMob SDK for them), so `platform.has("ads")` is false and every ads call rejects with `unavailable`. |

An ads plugin offers only the `"ads"` service, so it works **next to** the store backend of the game (Steam, Apple, Google
Play): the engine sends `ads.*` to it and everything else to the store backend. Development runs and tests keep the
fake, which serves ads itself, so a test never reaches a real ad network.

### Leaderboard periods

`"period": "daily"` or `"weekly"` in the catalog makes the board start over: `submit` and `entries` address the board of
the current calendar day (or week, Monday to Sunday) of `game.today()` (docs/SCRIPTING.md, "The date"), never of the wall
clock inside a simulation. The fake keeps one board per day or week, so the board is empty again the day after a
`game.setDate` in a test. The backend gets the board in the arguments: `period`, `periodKey` (`"2026-10-23"` for a day, the
Monday's date for a week, `""` for `allTime`) and `date`. Every backend maps the period to what its store has:

- **Steam** has no periods. A daily or weekly board is one Steam board per period, named `<store name> <periodKey>`
  (`Daily Run 2026-10-23`, `Weekly Run 2026-10-19`) and made on first use with the catalog's `order`. The day after, the
  new board is empty and the old one keeps its scores. A board per period piles up in the Steamworks partner site: that is
  the price of a store with no periods.
- **Game Center**: a board whose `ids.apple` names a recurring leaderboard (set up in App Store Connect) is used as it is,
  at its current occurrence, whatever `period` says. A classic board is read with the `.today` (daily) or `.week` (weekly)
  time scope of the same board.
- **Play Games** reads the daily or weekly table of the same board (`TIME_SPAN_DAILY`, `TIME_SPAN_WEEKLY`).

**A board of another day.** `submit(id, score, { day: "2026-10-22" })` and `entries(id, { day })` address the daily board
of that day instead of today's, for "yesterday's best" screens and for a day boundary crossed while the game ran. The
backend gets that day as `periodKey`. Without `day` a daily board is the one of the player's local date
(`game.today().iso`), so players in different time zones write different boards for a few hours; a game that wants one
board for the whole world passes the UTC day (`game.today().utc.iso`) to `submit` and `entries` alike. Only a daily board takes `day` (on
a weekly or allTime board the call throws). The fake and Steam keep one board per day, so they answer for any day; Game
Center and Play Games only have the store's own current day, so they reject a `day` that is neither the local nor the UTC
date of `game.today()` with the code `unsupported`.

Each store starts a period at its own time, not always at the game's `periodKey`:

| Backend | A day starts | A week starts | `periodStart` / `periodEnd` |
|---|---|---|---|
| fake | Midnight of `game.today()` | Monday of `game.today()` | none |
| Steam | Midnight of `game.today()` (the engine names the board) | Monday of `game.today()` | none |
| Game Center, classic board | Game Center's own day (`.today`) | Game Center's own week (`.week`) | none |
| Game Center, recurring board | When App Store Connect says (start date and duration of the occurrence) | the same | the current occurrence |
| Play Games | Midnight Pacific time | Google's week | none |

A store that says when the current period runs adds `periodStart` and `periodEnd` (ISO 8601 UTC text, for example
`"2026-10-23T07:00:00Z"`) to the `submit` answer, and to the array `entries` resolves with, as properties of it
(`rows.periodEnd`). Only Game Center's recurring boards do so today. Do not compute the end of a period from the date when
they are missing: the stores differ, as the table says. A game that shows "resets in..." shows it only when `periodEnd`
is there.

**Purchases: grant, then finish.** A store keeps a purchase "unfinished" until the game calls `finish`, and hands it over
again on the next run. Grant what was bought first, finish after, and remember the `transactionId`s you granted so the
same purchase never pays twice. Consumables (gems) are not remembered by the store after `finish`; non-consumables
(Remove ads) come back from `restore()`, which a "Restore purchases" button must offer on Apple platforms.

**Integrity checks.** `platform.integrity.token(challenge)` asks the platform to vouch for the game: the `token` it
returns is signed and says "this is the genuine, unmodified app, installed from the store, on a genuine device". The
token proves nothing to the game itself: **your server decides**.

```js
if (platform.has("integrity")) {
  const challenge = await myServer.newChallenge(); // made by the server, new for every request
  const { token } = await platform.integrity.token(challenge).catch(() => ({ token: null }));
  await myServer.check(challenge, token);          // the server verifies the token, not the game
}
```

- The **server makes the challenge**: 16 or more random bytes as URL-safe Base64 (a nonce), used once. It sends it to
  the game, gets the token back, **verifies the token with the store's server API** (for Google Play, Google's Play
  Integrity API) and **checks that the decoded token holds the same challenge**. A token without a fresh challenge can
  be replayed by anyone who copied it.
- **Never trust the client's word.** A modified game can claim anything it likes ("the check passed") but cannot
  forge a token; send the token itself and let the server read the verdict.
- **The game must work without it.** Not every store offers the service (Google Play does; Steam and Apple do not, and
  the answer there is `unavailable`), and a request can fail (`network`, `unavailable`). Check
  `platform.has("integrity")`, treat a missing or failed token as "unknown", and let the server choose what that
  means (a limit on a feature, say) instead of locking the player out.
- A challenge that is not a string of 16 to 500 characters from `A-Z a-z 0-9 - _ =` throws before anything is sent,
  naming the bad character and its position. The backend gets `{ challenge }` and must answer `{ token }` with a
  string `token`; any other answer is a `failed` rejection.

### Events

`platform.on(event, fn)`; the listeners run at the start of an engine frame, never in the middle of a script call, and
are cleared when a scene loads (register them in `onStart`).

| Event | Data | When |
|---|---|---|
| `"purchase"` | `{ status, productId, transactionId, receipt }` | A transaction that did not come from a `buy()` call: Ask to Buy approved, an unfinished purchase from an earlier run, a purchase made in the store itself, or `status: "revoked"`: the store took a purchase back (a refund), so take the goods away. Only the fake store sends `"revoked"` so far: the Apple and Google Play backends drop a refunded purchase from `restore()` instead, so also compare the save with `restore()` when the game starts. One that arrives before any listener exists is kept and delivered to the first `platform.on("purchase", ...)`: a paid purchase is never lost. |
| `"overlay"` | `{ open }` | The store's overlay opened or closed. Games pause while it is open (`scripts/store_events.js` in [MENUS.md](MENUS.md)). |
| `"player"` | `{ id, name, signedIn }` | The sign-in state changed. `platform.player` follows it. |
| `"remotePlay"` | `{ status: "connected" \| "disconnected", session }` | A guest joined or left Remote Play Together. `session` is what `remotePlay.sessions()` lists for a guest. |

### Which save is newer

`cloud.stat` lets a game look at a save without downloading it, for a "continue" button that shows when the slot was
saved, or to pick between two slots. `modified` is the store's time for the key: Steam's own time for the file, Play
Games' last-modified time of the snapshot, the fake store's counter, and `null` on Apple (iCloud's key-value store keeps
no time). It is not a good way to decide **which save is newer**. A store's time comes from the clock of the device that
saved (a phone with the wrong date saves "in the future" for good) and Apple gives
none. A **revision counter** is more robust: keep `{ revision: n, ... }` inside the saved value, add one on every save,
read it from `cloud.load` and take the higher one. Use `modified` to show the player a date, not to choose.

### Remote Play guests

`platform.has("remotePlay")` is true on a backend that tells who is playing through **Remote Play Together** (Steam
only today). `remotePlay.sessions()` lists the guests now and the `"remotePlay"` event announces each one that comes or
goes, so a game can say "Ana joined" or change to a split-screen layout:

```js
platform.on("remotePlay", ({ status, session }) => {
  console.log(session.guestName, status, "on a", session.formFactor); // "Ana connected on a phone"
});
const guests = platform.has("remotePlay") ? await platform.remotePlay.sessions() : [];
```

A session is `{ id, guestName, guestId, deviceName, formFactor, resolution }`: `id` is the number of the session while it
lasts (it is not the guest's account), `guestName` the guest's
account name, `guestId` the store's id for the guest (Steam: the SteamID as text), `deviceName` the name of the device
streaming, `formFactor` one of `"phone"`, `"tablet"`, `"computer"`, `"tv"`, `"vr"` or `"unknown"`, and `resolution`
`{ width, height }` of the guest's screen, or `null` when the store does not say. The `"disconnected"` event carries the
session as it was while connected; for a session the plugin never saw it carries only `{ id }`.

**A guest's controls are one more gamepad.** The store feeds the guest's controller (or touch controls) to the game as an
ordinary gamepad, so `input.gamepad(i)` and `game.on("gamepadConnected")` show it like a pad that was plugged in. The
engine does **not** tell which pad is which guest: a session has an `id` and a pad has a slot, and nothing links the two.
A game that must know whose pad it is (to give each guest a colour, say) has to ask, for example with a "press A to
join" step that binds the first pad that presses it to the next guest in `sessions()`. Do not assume that the order of
the sessions is the order of the pads.

### Mistakes throw, store failures reject

- A mistake in the call throws **at once**, before anything is sent: an id the catalog does not declare (with a "did
  you mean" and where to declare it), a wrong argument type, an unknown service or event.
  `platform.achievements.unlock("first_wn"): "first_wn" is not an achievement of this game (did you mean "first_win"?);
  declare it in factoria.json platform.achievements`.
- A failure of the store **rejects** the Promise with an `Error` that has `.code` and `.hint`; the message reads
  `platform.purchases.buy("gems_100") failed: <what> (hint: <how to fix>)`. Handle the rejection, or the engine reports
  it as an unhandled script error.

| `e.code` | Meaning |
|---|---|
| `unavailable` | No backend, or it does not offer that service. Check `platform.has("<service>")` first. |
| `notSignedIn` | The player is not signed in. Every call but `signIn()` needs it. |
| `notAllowed` | Purchases are disabled or restricted (parental controls). |
| `unknownId` | The store does not know the id the catalog maps to, or `purchases.finish()` got a transaction this game was not told about. |
| `network` | The store could not be reached. Offer a retry. |
| `failed` | Anything else; the message says what. |

Achievements, stats and presence are best effort: end those calls with `.catch(() => {})`. Purchases are not: show the
player what happened (`e.hint`) and grant nothing.

## 3. The fake store, and testing with it

The fake backend runs in development and in **every** headless run: `factoria test`, `factoria call`, `factoria
session`, the MCP server. It is deterministic (no clock, no random numbers), keeps everything in memory, offers every
service and `http.fetch` ([NETWORKING.md](NETWORKING.md), "Testing with the fake"), and starts afresh in each test file. The defaults are plausible successes: the player is signed in as
`{ id: "fake-player", name: "Player", signedIn: true }`; `buy` answers `purchased` with the transaction `fake-1`,
`fake-2`... and the receipt `fake-receipt-1`...; the purchase stays unfinished until `finish`; consumables are never
"owned"; `products()` takes title and price from the catalog (`$0.99`, or `2.99 EUR`); a leaderboard shows the player's
own best; `integrity.token` answers `{ token: "fake-integrity-1" }`, then `fake-integrity-2`... (no store
can verify these: a development server has to accept them on purpose); `cloud.stat` answers a `modified` that starts at
`1767225600` (2026-01-01T00:00:00Z) and goes up one second with each `cloud.save` (no wall clock); `remotePlay.sessions`
lists the guests the test connected. `await` works in tests, and an answer is ready at
once, without `game.step()`.

`import { game } from "factoria:test"` gives `game.platform`, the store's controls:

| Call | Does |
|---|---|
| `game.platform.respond(method, answer, times = 1)` | Queues the answer of the next `times` calls of `method` (`"purchases.buy"`; first come, first served). `answer` is `{ error: "network", message?, hint? }` to fail, `{ result: value }` to answer exactly that, or fields merged into the default result: `{ status: "cancelled" }`. A cancelled buy owns nothing. |
| `game.platform.emit(event, data)` | Sends `"purchase"`, `"overlay"` or `"player"` to the `platform.on` listeners at the next `game.step()`. An emitted purchased `purchase` is also an unfinished transaction. (`"remotePlay"` is refused here: use `remotePlayConnect`, which keeps the session that `remotePlay.sessions()` lists.) |
| `game.platform.remotePlayConnect({ guestName, guestId, deviceName, formFactor, resolution })` | A guest joins Remote Play Together. Every field is optional and made up when left out (`"Guest 1"`, `"fake-guest-1"`, `"Fake device"`, `"computer"`, 1920 by 1080); the guests are numbered from 1. It returns the session, `remotePlay.sessions()` lists it, and `platform.on("remotePlay")` listeners get `{ status: "connected", session }` at the next `game.step()`. A field it does not know, or a `formFactor` that is not one of the names above, throws with a "did you mean". Command: `platform.remote_play_connect`. |
| `game.platform.remotePlayDisconnect(id)` | The guest of that session id leaves: listeners get `{ status: "disconnected", session }` at the next `game.step()`. An id that is not connected throws, listing the ones that are. Command: `platform.remote_play_disconnect`. |
| `game.platform.revoke(productId)` | Takes a purchase back, as a refund does: `restore()` no longer lists it, its unfinished transaction is dropped, and `platform.on("purchase")` listeners get `{ status: "revoked", productId, transactionId, receipt }` at the next `game.step()` (take the goods away). A product the player does not own throws, listing the owned ones. Command: `platform.revoke`. |
| `game.platform.ad(outcome, { gdpr, tracking, privacyOptions })` | How the fake's test ad ends from now on: `"watched"` (default, rewarded), `"closedEarly"`, `"noFill"` (no ad: `ads.available()` is false) or `"consentRefused"` (also answers denied in `ads.consent()`). `gdpr`, `tracking` and `privacyOptions` (`"required"`, `"notRequired"`, `"unknown"`) set what `ads.consent()` answers; a denied `gdpr` stops every ad, and with `privacyOptions: "required"` `platform.ads.privacyOptions()` "shows" the form and `state().fake.ads.privacyShown` counts it. `reset()` restores the defaults (and forgets the answer of `setUnderAge`); `state().fake.ads` counts `shown` and `rewarded`. Command: `platform.set_ad`. |
| `game.platform.set({ signedIn, delayFrames, backend, cloudClock })` | `cloudClock: n` sets the time the next `cloud.save` stamps (Unix seconds, not negative), which `cloud.stat` then answers; the one after is a second later. `signedIn: false` makes every call but `signIn()` reject `notSignedIn`. `delayFrames: n` holds every answer for `n` engine frames: a test can see the "waiting" state, then `game.step(n)`. `backend: "none"` makes the fake behave as the none backend (section 4) until `reset()`: `platform.has(...)` is false, every call rejects `unavailable`, `signIn()` answers signed out; use it to test what an exported game without a store plugin does. An unknown option throws with a "did you mean". `platform.*` answers are ready at once (unless delayed), but `emit` events and `world.emit` reach listeners at the next `game.step`. |
| `game.platform.state()` | The backend, services, player, the catalog's ids, the number of pending requests, and `fake`: achievements, stats, leaderboards, cloud, owned, unfinished, presence, and `calls`, the log of every request (`{ seq, frame, method, args }`). |
| `game.platform.calls()` | `state().fake.calls`. |
| `game.platform.reset()` | A fresh fake: signed in, no delay, nothing owned, no guests, no scripted answers, an empty log, the cloud clock at its start; transactions, integrity tokens and guest sessions are numbered from 1 again. |

```js
import { test, expect, game } from "factoria:test";
import { platform } from "factoria";

test("a cancelled purchase grants nothing, a retry works", async () => {
  game.platform.respond("purchases.buy", { status: "cancelled" });
  expect((await platform.purchases.buy("gems_100")).status).toBe("cancelled");
  expect(game.platform.state().fake.unfinished).toEqual([]);

  game.platform.respond("purchases.buy", { error: "network", hint: "Check the connection." }); // once
  await platform.purchases.buy("gems_100").catch((e) => expect(e.code).toBe("network"));

  const ok = await platform.purchases.buy("gems_100");
  expect(ok.transactionId).toBe("fake-1");
  await platform.purchases.finish(ok.transactionId);
  expect((await platform.achievements.unlock("big_spender")).newly).toBe(true);
  expect(game.platform.state().fake.achievements.big_spender.unlocked).toBe(true);
});

test("the store overlay pauses the game", () => {
  game.platform.emit("overlay", { open: true });
  game.step(1);
  // ... your game paused itself in platform.on("overlay", ...)
});
```

The same controls are commands, for MCP clients and `factoria call` (they work on the fake only, and say which backend
runs when it is another): `platform.state`, `platform.reset`, `platform.respond {method, answer, times}`,
`platform.emit {event, data}`, `platform.remote_play_connect {guestName, guestId, deviceName, formFactor, resolution}`, `platform.remote_play_disconnect {id}`, `platform.set_ad {outcome, gdpr, tracking, privacyOptions}`, `platform.set_fake {signedIn, delayFrames, backend, cloudClock}` (an unknown option is refused with a "did you mean").

## 4. Which backend runs

| Run | Backend |
|---|---|
| `factoria run`, the editor's Play | The backend plugin the game declares for this platform. None: the **fake** (an info line in the log says so: purchases are not real). |
| `factoria test`, `factoria call`, `factoria session`, MCP, any headless run | Always the **fake**. Tests never touch a store. |
| An exported game (`factoria_player`) | The backend plugin. None: **none**, so an exported game never gets free purchases from the fake. |

With **none**, `platform.has(...)` is false for every service and every call rejects `unavailable`. `signIn()` answers
signed out.

Choosing a plugin: one loaded plugin that registered a backend is used. Several: `"platform": { "backend": "steam" }`
(or one per platform) picks, otherwise the first by name with a warning that lists them. A `backend` that names a plugin
that did not load falls back as above and logs why. `factoria call platform.state` shows `backend` and `why`.

**Ads have a backend of their own.** A plugin whose backend offers only `["ads"]` is an **ads backend**: it is chosen apart
from the store backend and works next to it. The engine sends `ads.*` to the ads backend and everything else to the store
backend; with no ads plugin, `ads.*` goes to the store backend when that offers ads (the fake does). Several ads plugins:
`"platform": { "ads": { "backend": "admob" } }` picks, otherwise the first by name with a warning. `platform.state` shows
`adsBackend` and `adsWhy` next to `backend` and `why`. A development run or a test never uses an ads plugin: it keeps the fake,
and `adsWhy` says so.

**So does `http.fetch`.** The engine serves it with the system's HTTP client in every run that is not headless, a test,
`factoria call`, `session` or MCP (those use the fake, which never reaches the network); no plugin can offer it, and a
plugin that lists `"http"` among its services is refused with a message that says so. `platform.state` shows
`httpBackend` (`"nsurlsession"`, `"winhttp"`, `"curl"`, `"httpurlconnection"`, `"fetch"` or `"fake"`), `httpWhy` and the declared
`networkHosts`. [NETWORKING.md](NETWORKING.md) has the rest.

| Backend | Status |
|---|---|
| `fake` | Done. Development and tests. |
| `none` | Done. Exported games without a store plugin. |
| Steam (Steamworks) | Done: the `steam` plugin, [below](#steam-steamworks). |
| Apple (StoreKit 2, Game Center, iCloud) | Done: iOS and macOS, `platform.add_backend {"backend": "apple"}`, [section 6](#6-apple-storekit-2-game-center-and-icloud). |
| Google Play (Billing, Play Games Services, Play Integrity) | Done: Android, `platform.add_backend {"backend": "googleplay"}`, [section 7](#7-google-play-billing-play-games-services-and-play-integrity). |
| AdMob (Google's consent form UMP, rewarded ads) | Done: Android and iOS (no ads on macOS), an ads backend, `platform.add_backend {"backend": "admob"}`, [section 8](#8-ads-google-admob-and-consent-on-android-and-ios). |

### Store backends: one command sets them up

`factoria call platform.add_backend '{"backend": "steam"}'` (or `"apple"`, `"googleplay"` or the ads backend `"admob"`) does the setup of a
backend in one call: it writes the backend's plugin from its template (`project.new_plugin` with `"template":
"<backend>"`) unless factoria.json already declares it, builds it for this computer with CMake (the CMake `setup`
installs when there is none; the Google Play and AdMob bridges are built with the Android SDK's NDK instead), and adds what that
store needs. Running it again keeps what is there. It patches factoria.json instead of rewriting it (only `plugins.<backend>` is added; the other keys, their order and the layout stay as they are). `"dryRun": true` writes, builds and copies nothing and lists the `files` and factoria.json `keys` it would write (`wouldDo` has the steps); an argument it does not know is an error with a "did you mean". Its result lists what it did (`done`) and what only a person can do
(`nextSteps`: store dashboards, accounts). Each backend's section says what it adds and which arguments it reads.

### Steam (Steamworks)

The `steam` plugin (`platforms/plugins/steam` in the engine, the `"steam"` template of `project.new_plugin`) answers the
game's `platform.*` calls with Valve's Steamworks API: achievements, stats, leaderboards, Steam Cloud (with the size and
time of a file), DLC purchases, the overlay, rich presence and the guests of Remote Play Together. It holds **no Valve code or header**: it loads Valve's redistributable library at run time and
calls its flat C API.

**Set it up** with one call, then `factoria run`:

```bash
factoria call platform.add_backend '{"backend": "steam", "sdk": "~/Downloads/steamworks_sdk_162.zip"}'
```

It writes `plugins/steam/` from the template and declares it for Windows, macOS and Linux, builds it with CMake for this
computer, copies Valve's three libraries from the SDK next to it, and writes `steam_appid.txt` (see below). Running it
again keeps what is there. The Steamworks SDK is a download from Valve (partner.steamgames.com/downloads/list, a free
Steamworks account); its license does not let FactorIA ship its files, so you supply them.

| Argument | Meaning |
|---|---|
| `sdk` | The SDK as a folder or its `steamworks_sdk_*.zip` (relative paths start in the project folder, `~/` works). Without it the build is made and the libraries are a `nextSteps` item. |
| `appId` | Your game's Steam app id for `steam_appid.txt`. Without it an existing file is kept, else it gets **480**, Valve's test app. |

By hand (what `plugins/steam/README.md` describes): `project.new_plugin {"name": "steam", "template": "steam"}`, build the plugin,
copy the library of each platform next to the plugin's, write `steam_appid.txt`.

| Platform | Plugin (built for it) | Valve's library, in the same folder |
|---|---|---|
| Windows | `windows/steam.dll` | `steam_api64.dll` (SDK: `redistributable_bin/win64/`) |
| macOS | `macos/libsteam.dylib` | `libsteam_api.dylib` (`redistributable_bin/osx/`) |
| Linux | `linux/libsteam.so` | `libsteam_api.so` (`redistributable_bin/linux64/`) |

The plugin was checked against the flat API of **Steamworks SDK 1.58 to 1.64**. It calls the flat functions by name (they do
not change with the interface versions) and finds the interfaces by their versioned accessors (`SteamAPI_SteamUtils_v010`...):
the versions of those SDKs first, then the five versions above the newest it knows. **A newer SDK is used, with one warning**
that names the interfaces newer than the plugin was checked against (and `steam.status` lists them as `newerInterfaces`), as
long as every function the plugin calls is present. That covers **SDK 1.65** (July 2026): it changed ISteamUtils
(`IsRunningOnSteamDeck` gave way to `IsRunningOnSteamHardware`; the plugin calls neither), so its library is expected to
export a newer accessor than 1.64's. Only a library with a function the plugin needs missing (a later SDK renamed or removed it), or with interface
versions more than five above the known ones, or from an SDK older than 1.58, is refused, with a message that lists what was
tried. If a newer SDK misbehaves, put the redistributable of SDK 1.64 next to the plugin, or update the plugin. (The tests use
a mock of Steam's library with a newer accessor for each interface; none ran against a real 1.65 library.) Only the 64-bit
libraries are used. The export copies the plugin's whole folder for the platform, so Valve's library ships next to it.

**steam_appid.txt.** In development Steam learns which game this is from a `steam_appid.txt` (a number) in the project
folder. `add_backend` writes **480** (Spacewar, Valve's test app: any Steam account can run it, and it has achievements,
stats and a leaderboard to try). For your own game put its app id there and sign in to an account that owns it. The
plugin hands the number to Steam; **`factoria export` never copies `steam_appid.txt`**, because a game started from the
Steam client gets its app id from Steam, and a shipped file would make it run as the wrong game. (A shipped game that is
started outside Steam cannot start Steam and runs without platform services.)

**Starting.** When the plugin loads it opens the library, starts Steam (`SteamAPI_InitFlat`, `SteamAPI_Init` on an older
library), and takes over Steam's callbacks (manual dispatch: it calls Steam once per engine frame itself, never
`SteamAPI_RunCallbacks`). `SteamAPI_Shutdown` runs when the process ends (not on Windows, where the DLL's exit handlers run
after Steam's own DLL is gone; Steam notices the process ending, and stats are stored every frame anyway). When Steam
cannot start (it is not running, there is no app id, the library is missing or from another SDK) the plugin **logs why, with
what to do** (a warning, not an error: `project.new_plugin` and `platform.add_backend` declare the plugin `optional`), and the game falls back: the fake backend in a development run, **none** in an exported game.
`factoria call platform.state` shows the backend and `why`; `factoria call steam.status` shows what the plugin found (app id and
where it came from, player, library and interface versions, overlay, Cloud).

Every engine that loads the plugin starts Steam, because a plugin cannot know which backend the engine will pick: that includes
`factoria test`, `factoria call` and the MCP server on a game that declares it. They still answer `platform.*` with the fake
store and never touch Steam's data, but a running Steam client shows you as playing the game, and a computer without Steam
(CI) logs the warning above (only a log line: the run goes on with the fake store).

**Catalog ids** (`ids.steam` of each entry in `factoria.json`, section 1):

| Catalog | `ids.steam` is | Without it |
|---|---|---|
| achievements | the achievement's **API Name** (Steamworks partner site, App Admin > Stats & Achievements), e.g. `ACH_WIN_ONE_GAME` | the catalog `id` |
| stats | the stat's **API Name**; its type there (int or float) must be the catalog's `type` | the catalog `id` |
| leaderboards | the leaderboard's name; created on first use with the catalog's `order` when it does not exist | the catalog `id` |
| products | the **app id of the DLC** (the number in its store page's URL) | not a DLC: the product is left out and a warning says how to fix it |

**What each call does on Steam**

| Call | On Steam |
|---|---|
| `signIn()` | `{ id: SteamID, name: persona name, signedIn: whether Steam is online }`. |
| `achievements.unlock(id)` | `SetAchievement` then `StoreStats`; `newly` is false when Steam had it. |
| `achievements.progress(id, f)` | At `1` unlocks. Below it shows Steam's "n of 100" notice (`IndicateAchievementProgress`); Steam keeps real progress in the stat behind the achievement, so set that stat too. |
| `achievements.list()` | `GetAchievement` for each catalog entry (one Steam does not have shows locked, with a warning). `progress` is 0 or 1. |
| `achievements.reset()` | `ResetAllStats` including achievements: development only. |
| `stats.get / set` | Int and float stats. A set is stored by the next frame (several sets in a frame are one `StoreStats`; Steam limits how often it may be called). Int stats are 32-bit. |
| `leaderboards.submit(id, score)` | Uploads keeping the player's best; `best` is what Steam kept. Scores are 32-bit. A daily or weekly board is the Steam board `<name> <periodKey>` ("Leaderboard periods"). |
| `leaderboards.entries(id, {range, count})` | `top`: ranks 1 to `count`. `around`: the player in the middle. `friends`: the player and friends (Steam gives them all; at most `count` are returned). Names are Steam persona names. |
| `cloud.save / load / list / remove` | Steam Cloud files named `<key>.json`. Needs Cloud enabled for the app (partner site, App Admin > Cloud) and for the account; otherwise `unavailable`, saying which. A file is up to 100 MB; the app's quota applies. |
| `cloud.stat(key)` | The file's size (`GetFileSize`) and Steam's own time for it (`GetFileTimestamp`, Unix seconds); `{ exists: false }` when Steam has no such file. Same `unavailable` as the other cloud calls when Cloud is off. |
| `remotePlay.sessions()` | `ISteamRemotePlay`: the sessions Steam lists now (`GetSessionCount`, `GetSessionID`), each with the guest's SteamID and persona name, the device's name and form factor, and its resolution (`null` when Steam gives none). The service is offered only when the Steam library exports `ISteamRemotePlay` (the plugin tries `SteamAPI_SteamRemotePlay_v002`, then `_v001`): `steam.status` lists `ISteamRemotePlay v00N` among the interfaces when it does. |
| `purchases.products(ids?)` | Steam's DLC list for the app, by the products' `ids.steam`: `title` is the DLC's name; `price` is `""` (Steam gives a DLC's price on its store page, not here), `priceValue` null. |
| `purchases.buy(id)` | Owned already: `purchased` with the transaction `dlc-<appid>`. Not owned: the overlay opens the DLC in a cart and the answer is `pending`; when the player owns it, a `purchase` event follows. A consumable or a subscription is `unavailable` (below). |
| `purchases.restore()` | The non-consumable products whose DLC the player owns. |
| `purchases.finish(txn)` | Nothing to do on Steam: resolves. |
| `overlay.open(page, id?)` | `achievements` and `friends`: that overlay page. `store`: the DLC's store page for a product, else the game's own. `leaderboards`: the game's leaderboards page on Steam Community (Steam has no overlay page for them). `unavailable` when Steam says the overlay is off. |
| `presence.set(text, data?)` | Rich presence: `text` is the key `status`, each `data` key is sent as it is (`connect`, `steam_display`...), and what was shown before is replaced. Steam allows 30 keys of 64 bytes with values of 256. |

**Events**: `overlay` (`{open}`, Steam's `GameOverlayActivated`), `purchase` (a DLC the player got, from the overlay or another
computer: Steam's `DlcInstalled`), `player` (Steam went online or offline), `remotePlay` (a guest connected or disconnected:
Steam's `SteamRemotePlaySessionConnected_t` and `SteamRemotePlaySessionDisconnected_t`). The disconnect callback carries
only the session id, so the plugin keeps the description it read while the guest was connected and puts it in the event;
sessions that were connected before the game started are read at start-up, and no event announces them.

**DLC, not microtransactions.** Steam sells a game's extras as **DLC**, which is what `nonConsumable` products map to. Steam's
other mechanism, microtransactions (`ISteamMicroTxn`), needs your own server calling Valve's web API and cannot start
from the client, so **consumables and subscriptions are `unavailable` on Steam**, with a message that says so. Sell a
consumable as a DLC that grants it once, or keep the shop on the stores that have it. (Steam Inventory, Steam's service for
items, is not wrapped either.)

**Limits worth knowing.** Stat and achievement changes reach Steam when stored (every frame that set one, and at exit on macOS and
Linux); an offline player's are kept by Steam and sent later. There is no `achievements.onUnlocked` event. A Steam Cloud
file holds the JSON text of one key. What is wrapped: sign-in and the persona name, achievements, stats, leaderboards, Steam
Cloud files (save, load, list, remove, stat), DLC, the overlay, rich presence, the Deck keyboard and Deck detection, and
the Remote Play guest list and its connect and disconnect events. Not wrapped: Steam Input, workshop, networking, inventory,
and Remote Play's other half (inviting someone with `BSendRemotePlayTogetherInvite`, the guests' own controller or mouse
settings). Of Remote Play only what the list above says is read.

**Tested against a mock only.** The plugin's tests (`steam_plugin_*`) run against a mock of Steam's library that checks
every call's signature, so the `cloud.stat` and Remote Play code paths are exercised, but no real Steam client, real Cloud
file or real Remote Play session has been tried. The manual check below does not cover them yet: until somebody runs a Remote Play
session (a second computer or the Steam Link app on a phone) and a `cloud.stat` on app 480 and writes down what Steam
answered, treat the `modified` of a Cloud file and the exact `formFactor` and `resolution` of a session as unverified.

**Steam Deck.** The Deck is a Linux machine with the controller as a gamepad (the engine names its buttons like an Xbox pad).
The release `factoria_player` for Linux is built in the Steam Linux Runtime "sniper" container (glibc 2.31, libstdc++
linked in; `scripts/build-sniper.sh`, docs/BUILDING.md), and CI runs it there, so a Linux export runs in the runtime Steam
gives Linux games, on the Deck included (pick "Steam Linux Runtime 3.0 (sniper)" in the Steamworks partner site); the
Windows build through Proton is the alternative.

**Steam Deck detection.** The Steam plugin answers `game.device.steamDeck` (and `handheld`) from `IsSteamRunningOnSteamDeck`, which is
certain; when the game runs without Steam the `SteamDeck=1` environment variable decides, and `SteamDeck=0` turns it off.

**Gamepad ids.** `input.gamepad(i).id` and `game.on("gamepadConnected")` give each pad a stable id: Windows XInput has none, so it
is "an Xbox pad in XInput slot N"; Linux uses vendor, product, name and the kernel `uniq` serial, and the slot is the `jsN`
number; macOS, iOS and the web (Gamepad.id) use the name, the web also vendor and product; Android adds the InputDevice
descriptor. See docs/SCRIPTING.md, "Pads plugged in and out".

**Steam Deck keyboard.** On a Steam Deck, and in Big Picture on any computer (`IsSteamRunningOnSteamDeck` or
`IsSteamInBigPictureMode`), a `TextField` that takes the focus while the last input came from a gamepad gets Steam's own
keyboard (plugin API 3, [section 5](#5-writing-a-backend-plugin)). The plugin first tries the **floating** keyboard
(`ShowFloatingGamepadTextInput`): Steam draws it over the game next to the field, whose rectangle the plugin passes in window
pixels, and types into the window as key presses, so the field fills as with a real keyboard and sends `ui.change` as usual.
Where Steam does not offer it, the plugin opens the **full-screen** one (`ShowGamepadTextInput`, with the field's text and
`maxLength`); when the player confirms, the text comes back (`GamepadTextInputDismissed_t`, `GetEnteredGamepadTextInput`) and
replaces the field's text (cut to `maxLength`, `ui.change` sent); cancelling changes nothing. The floating keyboard is taken
down when the field loses the focus, and pressing A on the focused field opens it again. While Steam's keyboard has the
field, `input.platformKeyboard` is true and the menu kit's on-screen keyboard stays closed; a game's own keyboard can read
the same flag. On a desktop Steam nothing changes: the player has a keyboard, and a pad uses the kit's on-screen keyboard.
Steam's keyboard is single line and not a password field because `TextField` has neither yet. If Steam refuses both
keyboards the plugin logs one warning and the game's own keyboard is used.

**Troubleshooting.** The plugin's messages say what to do; the usual ones:

| The log says | Do |
|---|---|
| `The Steamworks library ... was not found` | Copy Valve's library next to the plugin (`add_backend` with `sdk` does it). |
| `Steam is not running, or the game has no app id` | Start the Steam client and sign in; check `steam_appid.txt` is in the project folder and holds a number. |
| `The Steam client is older than the Steamworks library` | Update Steam (Steam menu > Check for Steam Client Updates), or use an older SDK's library. |
| `has none of the interface accessors this plugin can use` | The library is from an SDK older than 1.58, or one that changed the interfaces by more than five versions: the message lists what was tried; use an SDK between 1.58 and 1.64, or update the plugin. |
| `... newer than the SDKs this plugin was checked against` | A warning, not an error: the library is from a newer SDK (1.65 or later) and the plugin uses it. If a call misbehaves, use the SDK 1.64 library, or update the plugin. |
| `does not export SteamAPI_...` | A function the plugin calls is not in the library: a later SDK renamed or removed it. Use the SDK 1.64 library, or update the plugin. |
| `The Steamworks library ... cannot be loaded` | It is not the 64-bit library of this OS (or it is damaged). On macOS a library that came through a browser may be quarantined: `xattr -d com.apple.quarantine <file>`. |
| `Steam Cloud is not enabled for app N` | Enable it in the partner site (App Admin > Cloud) and publish; for 480 it may simply be off. |
| `The Steam overlay is not available` | In Steam: Settings > In Game > Enable the Steam Overlay. It loads a few seconds after start and needs the game to draw with a graphics API Steam hooks. |

**Manual check with Valve's test app 480.** The tests of the plugin run against a mock of Steam's library (`ctest`:
`steam_plugin_*`); this is the check against the real Steam, which needs a Steam client and a free account. Do it on each
desktop OS you ship.

1. Install Steam, sign in, leave it running. (The Deck: switch to Desktop Mode, or run it from a terminal with Steam open.)
2. `factoria new steamcheck && cd steamcheck`, then download the Steamworks SDK zip and run
   `factoria call platform.add_backend '{"backend": "steam", "sdk": "<the zip>"}'`. `steam_appid.txt` now holds `480`.
3. In `factoria.json` add the catalog (Spacewar's names):
   ```json
   "platform": {
     "achievements": [{ "id": "first_win", "name": "First win", "ids": { "steam": "ACH_WIN_ONE_GAME" } }],
     "stats": [{ "id": "wins", "type": "int", "ids": { "steam": "NumWins" } }, { "id": "feet", "type": "float", "ids": { "steam": "FeetTraveled" } }],
     "leaderboards": [{ "id": "feet_board", "name": "Feet", "ids": { "steam": "Feet Traveled" } }],
     "backend": "steam"
   }
   ```
4. `factoria call steam.status`: it prints `"appId": 480`, `"appIdFrom": "steam_appid.txt in ..."`, your Steam name, and
   `"statsLoaded": true`. (If it fails, the log says why, see Troubleshooting.)
5. Add `scripts/check.js` and an entity with `"Script": { "path": "scripts/check.js" }` to `scenes/main.scene.json`:
   ```js
   import { Behaviour, platform } from "factoria";
   export default class Check extends Behaviour {
     async onStart() {
       console.log("backend", platform.backend);                                       // steam
       console.log("player", JSON.stringify(await platform.signIn()));
       console.log("unlock", JSON.stringify(await platform.achievements.unlock("first_win")));
       console.log("wins", await platform.stats.add("wins", 1));
       console.log("board", JSON.stringify(await platform.leaderboards.submit("feet_board", 1000)));
       console.log("top", JSON.stringify(await platform.leaderboards.entries("feet_board", { count: 3 })));
       console.log("save", JSON.stringify(await platform.cloud.save("check", { n: 1 })));
       await platform.presence.set("Checking Steam", { score: "1" });
     }
   }
   ```
6. `factoria run`. In the log: `steam: Steam is ready: app 480`, `backend steam`, your player, `unlock {"id":"first_win","unlocked":true,"newly":true}`
   (`newly` is false on a second run: reset it with `platform.achievements.reset()`), `wins` one higher each run, your score in
   `board`. A `cloud.save` may answer `unavailable` for app 480 if Valve has Cloud off for it; that message is the correct answer.
   When Cloud works, `platform.cloud.stat("check")` answers `{ exists: true, size, modified }` with Steam's time for the file
   (not yet tried against real Steam, see "Tested against a mock only"); with a guest on Remote Play Together
   `platform.remotePlay.sessions()` lists it and the `remotePlay` event arrives when it connects and leaves.
7. Open Steam's overlay in the game window (Shift+Tab): with the window focused it must open, and the game receives the
   `overlay` event. Call `platform.overlay.open("achievements")` from the script: it opens the overlay's achievements page.
   (The engine draws with Direct3D 11 on Windows, Metal on macOS and OpenGL on Linux: note in ENGINE_FEEDBACK.json on which of
   them the overlay does not appear.)
8. In Steam, your friends list shows "Checking Steam" under your name while the game runs.
9. In Steam's own page for the achievement (Library > Spacewar > Achievements, or `steamcommunity.com/stats/480/achievements`),
   "Win a game" shows unlocked.
10. **Deck keyboard (on a real Steam Deck, or a desktop in Big Picture mode).** The tests run against a mock; this is
    the check against the real keyboard. Add a scene with a `TextField` (`factoria call scene.add_entity`, or the menu kit's
    `name` scene) and run the game from Steam as a non-Steam game, or from Desktop Mode with Steam open.
    a. With the pad (do not touch the keyboard or the touch screen), move the focus to the field with the d-pad: Steam's
       floating keyboard appears next to the field, over the game, and the kit's own on-screen keyboard does not.
       `input.platformKeyboard` is true (log it from `onUpdate`).
    b. Type with the Deck's touch keyboard: the characters appear in the field, `ui.change` arrives for each, and `maxLength` is
       respected. Press Enter on it: `ui.submit` arrives.
    c. Move the focus to a button: the keyboard goes away and `input.platformKeyboard` is false. Come back to the field and
       press A: it comes up again.
    d. If the floating keyboard does not appear (older SteamOS), the full-screen one must: type "hello", confirm, and the field
       holds "hello". Cancel instead: the text is unchanged.
    e. Plug in a keyboard and press a key: nothing breaks, the field takes the typing. On a desktop Steam (not Big Picture)
       steps a to d do not apply: the pad opens the kit's keyboard.
    Note in `ENGINE_FEEDBACK.json` anything that differs (a keyboard in the wrong place means the window rectangle is off).
11. Export: `factoria export --platform <this OS>`; the exported folder holds the plugin and Valve's library, **no**
    `steam_appid.txt`. Start the exported game from a terminal with Steam running: without an app id Steam refuses to start
    it, the log says so, and the game runs with no platform services (`platform.backend` is `none`). For the final check, a
    game started by the Steam client gets its app id from Steam: upload a build to your own app with SteamPipe (app 480 takes no
    uploads) and start it from the Steam library.

## 5. Writing a backend plugin

A [native plugin](EXTENDING.md#g-native-plugins-cc-for-one-game) becomes a backend with the **plugin API version 2**:
`add_backend`, and `resolve`, `reject` and `emit` to answer. (`factoria call project.new_plugin` copies `fa_plugin.h`;
a version 1 plugin keeps working, and one built for version 2 checks `api->version >= 2`.) **Version 3** adds
`add_text_input` and `submit_text`, for a platform keyboard that a gamepad player gets for a `TextField` (the Steam Deck's;
[EXTENDING.md](EXTENDING.md#g-native-plugins-cc-for-one-game)); a plugin built for version 2 keeps working, and
one that wants the hook checks `api->version >= 3` before it reads the new members.

```c
#include <string.h>
#include "fa_plugin.h"

static const FaPluginApi* g_api;

// Called for every request of the game, on the game's thread. Answer once with resolve() or reject(): now, or later
// from any thread (a store SDK's callback). The engine has checked the ids and filled in "storeId".
static void on_request(FaRequest* req, const char* method, const char* args_json, void* user) {
    if (strcmp(method, "achievements.unlock") == 0) {
        // args_json: {"id":"first_win","storeId":"ACH_WIN_ONE_GAME"} -> call the SDK with storeId...
        g_api->resolve(req, "{\"id\":\"first_win\",\"unlocked\":true,\"newly\":true}");
    } else {
        g_api->reject(req, "unavailable", "this backend does not do that", "Check platform.has(service) first.");
    }
}

static void on_frame(void* user) { /* once per frame, before scripts: SteamAPI_RunCallbacks() */ }

FA_PLUGIN_INIT(mystore) {
    g_api = api;
    FaBackendDesc backend = {"mystore", "[\"achievements\"]", on_request, on_frame, NULL};
    return api->add_backend(api, &backend);   // 0 = done; one backend per plugin
}
```

- `name` is what the catalog's `ids` are keyed by (`"ids": {"mystore": "..."}`); `services` is a JSON array of the
  services the backend offers. A request for another service is answered `unavailable` by the engine: the backend never
  sees it.
- A `FaRequest*` is a token: answer it **exactly once**. A second answer, or one for a game that has ended, is ignored
  (and logged once). `resolve`, `reject` and `emit` may be called from any thread; the game gets the answer at the
  start of its next frame.
- `resolve` takes JSON text; text that is not JSON fails the request with `failed`. `reject` takes one of the codes of
  section 2 (`unavailable`, `notSignedIn`, `notAllowed`, `unknownId`, `network`, `failed`; anything else becomes
  `failed`), a message that says what went wrong and a hint that says how to fix it.
- `emit(api, "purchase" | "overlay" | "player" | "remotePlay", data_json)` reaches `platform.on` in the running game.
  A `remotePlay` event is `{ status: "connected" | "disconnected", session }` (the table below says what a session is).
- Strings passed to the engine are copied. A handler never lets an exception leave.

**The contract.** The backend gets `(method, args)` and answers with the result below. `id` is the catalog id,
`storeId` the id that store uses (`ids` of the catalog, else `id`). A purchase result names its product in `productId`
(`id` or `storeId` work too); the engine turns the store's id back into the catalog's before the game sees it, and
the `id`s in an `achievements.list` or `purchases.products` answer the same way.

| Method | The backend gets | It answers |
|---|---|---|
| `player.signIn` | `{}` | `{ id, name, signedIn }` |
| `achievements.unlock` | `{ id, storeId }` | `{ id, unlocked: true, newly }` |
| `achievements.progress` | `{ id, storeId, progress }` | `{ id, progress, unlocked }` |
| `achievements.list` | `{ achievements: [{ id, storeId }] }` | `[{ id, unlocked, progress }]` |
| `achievements.reset` | `{ achievements: [{ id, storeId }] }` | `{}` |
| `stats.get` | `{ id, storeId, type }` | `{ id, value }` |
| `stats.set` | `{ id, storeId, type, value }` | `{ id, value }` |
| `leaderboards.submit` | `{ id, storeId, name, order, period, periodKey, date, score }` | `{ id, score, best, periodStart?, periodEnd? }` |
| `leaderboards.entries` | `{ id, storeId, name, order, period, periodKey, date, range, count }` | `[{ rank, name, score, playerId, isPlayer }]`, or `{ entries: [...], periodStart, periodEnd }` when the store says when the period runs |
| `cloud.save` | `{ key, data }` (`data` is JSON text) | `{ key, bytes }` |
| `cloud.load` | `{ key }` | `{ key, data }`, or `null` when there is no such key |
| `cloud.list` | `{}` | `["key", ...]` |
| `cloud.remove` | `{ key }` | `{}` |
| `cloud.stat` | `{ key }` | `{ exists: false }`, or `{ exists: true, size, modified }` (`modified` in Unix seconds, or `null` when the store keeps no time) |
| `remotePlay.sessions` | `{}` | `[{ id, guestName, guestId, deviceName, formFactor, resolution }]` (`formFactor`: `"phone"`, `"tablet"`, `"computer"`, `"tv"`, `"vr"` or `"unknown"`; `resolution`: `{ width, height }` or `null`) |
| `purchases.products` | `{ products: [{ id, storeId, type }] }` | `[{ id, title, description, price, priceValue, currency, type }]` |
| `purchases.buy` | `{ id, storeId, type }` | `{ status, productId, transactionId, receipt }` |
| `purchases.finish` | `{ transactionId, id, storeId, type }` | `{}` |
| `purchases.restore` | `{ products: [{ id, storeId, type }] }` | `[{ productId, transactionId, receipt }]` |
| `overlay.open` | `{ page, id?, storeId? }` | `{}` |
| `presence.set` | `{ text, data }` | `{}` |
| `ads.available` | `{ placement, adUnitId, type }` | `{ available }` |
| `ads.showRewarded` | `{ placement, adUnitId, type }` | `{ rewarded, reason? }` |
| `ads.consent` | `{}` | `{ gdpr, tracking, canShowAds }` |
| `integrity.token` | `{ challenge }` | `{ token }` (`token` is a string; the engine has checked `challenge` is 16 to 500 characters of URL-safe Base64) |

The C++ side is `fa/services/platform.h` (`PlatformBackend`, `PlatformServices`, `platform_methods()` with this table)
and `fa/runtime/platform_backend.h` (the plugin adapter and the choice of backend). The fake backend
(`fa/services/fake_platform.h`) is the reference implementation of every row.

## 6. Apple: StoreKit 2, Game Center and iCloud

The backend `"apple"` is a Swift plugin (`platforms/plugins/apple`, written into the game by `platform.add_backend`) for **iOS
16.3+ and macOS 12+**. It answers `platform` with:

| Service | Apple's API | Notes |
|---|---|---|
| `purchases` | StoreKit 2 | consumables, non-consumables and subscriptions; Ask to Buy; refunds. |
| `achievements`, `leaderboards` | Game Center | the sign-in sheet, the banners, global / around the player / friends boards. |
| `overlay` | Game Center | `"achievements"`, `"leaderboards"` and `"friends"` through the Game Center access point. `"store"` is `unavailable`: `purchases.buy` shows the purchase sheet. |
| `cloudSave` | iCloud key-value store | 1 MB and 1024 keys for the whole game. |

Game Center has no stats and no presence: `platform.has("stats")` and `platform.has("presence")` are false and the engine
answers those calls `unavailable`. Keep the numbers you need in `cloud.save` or on a leaderboard.

### Setup, in one command

On a Mac with Xcode:

```bash
factoria call platform.add_backend '{"backend": "apple"}'
```

It writes the plugin to `plugins/apple` from its template and declares it for iOS and macOS in factoria.json (unless it is
declared already), then builds its three libraries with the Xcode toolchain (`xcrun swiftc`, driven by CMake):
`macos/libapple.dylib`, `ios/iphoneos/libapple.a` and `ios/iphonesimulator/libapple.a`. Arguments: `appleSlices` (any of
`"macos"`, `"iphoneos"`, `"iphonesimulator"`; default all three) and `appleBuild: false` (only write and declare, to build
later on a Mac). A computer that is not a Mac cannot build Swift against StoreKit: the command says so and offers
`appleBuild: false`. Its `nextSteps` list what only a person can do, with the ids of your catalog filled in:

1. **Apple Developer portal**: the App ID of `factoria.json`'s `id` needs the capabilities **Game Center**, **In-App
   Purchase** and **iCloud** (key-value storage only, no iCloud Drive or CloudKit).
2. **App Store Connect**: add the app with that bundle id, accept the **Paid Apps Agreement**, turn **Game Center** on, and
   create the products, achievements and leaderboards. Each gets **exactly** the id of the catalog (`ids.apple`, else `id`).
3. A **sandbox tester** (Users and Access > Sandbox), signed in under Settings > Developer > Sandbox Apple Account.

Then export with `factoria export --platform ios` (or `macos`). The exports read the plugin's `plugin.json` (frameworks,
the Swift runtime, entitlements: [MOBILE.md](MOBILE.md#native-plugins-ios), [EXTENDING.md](EXTENDING.md#g2-the-declaration)).
**iOS**: the Xcode project links StoreKit, GameKit and the Swift runtime and is signed with the entitlements
(`factoria_player.entitlements`; set `export.ios.teamId` or `FA_IOS_DEVELOPMENT_TEAM` so Xcode can sign for a device).
**macOS**: Game Center and iCloud are *restricted* entitlements, which macOS only honours in an app signed with your Apple
Developer certificate and a provisioning profile. The export is signed ad hoc, so it runs, and those services answer
`unavailable` with a hint; the export also writes `<game>.entitlements`, and `sign.macos` with `provisioningProfile` (the profile
of the App ID, from the Apple Developer portal) signs the app with them ([EXPORTING.md](EXPORTING.md#signing-and-notarizing-for-macos)). An ad hoc app also gets no answers from the App Store: try purchases from Xcode (below) or after that signing step.

### What each call does

| Call | On Apple |
|---|---|
| `platform.signIn()` | Starts Game Center's authentication: a sheet the first time, a welcome banner after. Resolves `{ id, name, signedIn }` (`id` is the `gamePlayerID`, stable for this game). A player who is not signed in gets `notSignedIn` with a hint (sign in under Settings > Game Center). With no sheet and no answer it ends after 20 s; a sheet on screen waits for the player. |
| `achievements.unlock(id)`, `.progress(id, fraction)` | Reports to Game Center (`newly` is false when it was unlocked already). An id that App Store Connect does not have is `unknownId`, listing the ids it has. |
| `achievements.list()` | The catalog's achievements with what the player reached. |
| `achievements.reset()` | Resets *every* achievement of the player (development). |
| `leaderboards.submit(id, score)`, `.entries(id, {range, count})` | The all-time board, or the period's ("Leaderboard periods": a recurring board at its current occurrence, with `periodStart` and `periodEnd`; a classic one with the `.today` / `.week` scope). `range`: `"top"`, `"around"` (empty until the player has a score) or `"friends"`. `best` is the player's best including this score. |
| `cloud.save/load/list/remove` | One iCloud key-value key per cloud key; the value is stored as JSON text. Over 1 MB or 1024 keys: `failed`. No iCloud account or no entitlement: `unavailable`. Syncing between devices is iCloud's (seconds to minutes); `load` reads what this device has. |
| `cloud.stat(key)` | `{ exists, size }` of the key's JSON text; `modified` is always `null` because the iCloud key-value store keeps no time for a key: keep a revision counter in the saved value to tell which save is newer ("Which save is newer"). |
| `purchases.products(ids?)` | The product's `displayName`, `description`, `displayPrice` (the player's storefront), price value, currency and type. A product the store does not know is left out, with a warning in the log that says how to create it. |
| `purchases.buy(id)` | Shows the purchase sheet. `purchased` (with `transactionId` and the JWS `receipt`), `cancelled`, or `pending` (Ask to Buy). `notAllowed` when Screen Time forbids purchases. The call waits as long as the player takes with the sheet, but gives up after 30 s when the App Store never shows it. |
| `purchases.finish(transactionId)` | `Transaction.finish()`. The id must come from a `buy()` result, a `purchase` event or a `restore()` entry of this run. |
| `purchases.restore()` | Syncs with the App Store (it may ask for the Apple Account password) and returns the verified entitlements: non-consumables and active subscriptions. |
| `overlay.open(page, id?)` | Opens the Game Center dashboard on the page (an `id` goes straight to that achievement or leaderboard on iOS 18 / macOS 15). Needs a signed-in player. |

**Events.** `purchase` for a transaction that did not come from `buy()`: an Ask to Buy approval, a purchase made on another
device, a subscription renewal, or a purchase the last run did not finish. Those arrive right after the game starts, before a
script could listen, so the engine keeps the ones nobody listens for (up to 100) and hands them to the first
`platform.on("purchase", ...)`: register it in `onStart`, grant, then `finish`. `overlay` `{open}` when the Game Center
dashboard opens and closes. `player` when the Game Center sign-in changes (also when the player signs out in Settings while
the game runs).

**Refunds, expired subscriptions and unverified transactions.** A revoked (refunded) or expired transaction is finished and
never delivered. A transaction whose signature does not verify on the device is *not* delivered and not finished (the log
says so): a modified device or a missing StoreKit test certificate, never a purchase to grant.

### Receipts are JWS documents

The `receipt` of a purchase is the transaction as a **JWS** (the compact text `header.payload.signature`), signed by Apple.
The device has verified it (StoreKit 2 delivers only verified transactions to the game). A game with real money at stake
(server-side goods, an online economy) must verify it again **on its server** before granting: check the signature against
the certificate chain in the header (`x5c`, ending at Apple's root CA), then read `productId`, `transactionId`,
`originalTransactionId`, `bundleId` and `environment` (`"Sandbox"`, `"Xcode"` or `"Production"`) from the payload. Apple's
App Store Server Library (Swift, Java, Node and Python) does the verification, and the App Store Server API looks a
transaction up by its `transactionId` and sends refund notifications. A single-player game that trusts the device can ignore
the receipt.

### Testing purchases without App Store Connect

`factoria export --platform ios` writes **`Products.storekit`** next to the Xcode project whenever the catalog has products (the
Apple plugin does not have to be declared or built): a
StoreKit configuration file made from `platform.products` (consumables and non-consumables as such; a subscription as a
monthly auto-renewable product in one subscription group; the prices and titles of the catalog; ids = `ids.apple`, else
`id`). Every product gets one localization per language of the game (`localization.languages`): its name and description come
from the product's `titleKey` / `descriptionKey` in `locales/<language>.json` (a key a language lacks falls back to the default
language, then to the catalog's plain `title` / `description`; a plural entry gives its `other` form), so the sheet Xcode shows
follows the simulator's language. `build_ios.sh` wires it into the project's scheme, so **running the project from Xcode** sells exactly those products,
with no App Store Connect, sandbox account, network or provisioning, and `Debug > StoreKit > Manage Transactions` approves or
fails purchases and simulates Ask to Buy, refunds and renewals. If the scheme shows "StoreKit Configuration: None", pick the
file under Product > Scheme > Edit Scheme > Run > Options. The file is rewritten at every export: edit the catalog, not the
file. Launching the app any other way (`build_ios.sh --run`, `simctl launch`, the home screen of a device) does not use it;
products then come from the App Store (sandbox for development-signed builds, TestFlight for TestFlight builds). Game Center
has no such file: a sign-in needs a real or sandbox Apple Account (on the simulator: Settings > Game Center).

### When something does not work: `apple.status`

The plugin registers the command **`apple.status`** (from a script: `fa.call("apple.status", {})`): whether a Game Center
player is signed in, whether this device may make payments, whether iCloud is signed in and, on macOS, whether the app
carries the entitlements, with a `problems` list of sentences that say what to fix. When StoreKit or Game Center cannot talk to
Apple at all (an app that is not signed with a development team, or run outside Xcode without a StoreKit file), the calls
reject `unavailable` with a hint that points here.

| Situation | What the game gets |
|---|---|
| Not signed in to Game Center | `notSignedIn` ("Sign in under Settings > Game Center..."). |
| Achievement or leaderboard missing in App Store Connect | `unknownId`, with the ids that exist. |
| Product missing in App Store Connect | `unknownId` from `buy`; `products()` leaves it out and logs the steps (Paid Apps Agreement, product id). |
| Purchases restricted by Screen Time | `notAllowed`. |
| No answer from Apple in 30 s (restore: 120 s) | `network`. |
| iCloud signed out, or the entitlement missing | `unavailable` (cloud saves), naming the entitlement. |
| Apple's servers cannot be reached | `network`. |

### Manual checks

These need App Store Connect, a development-signed build and a sandbox account, so no automated test runs them. The tests
cover what needs none of that: the plugin registers in a real engine and answers every request once, in time, with a
teaching error; the exports write the frameworks, entitlements and `Products.storekit`; the iOS Simulator job builds and
launches an app with the plugin linked. Before a release, on a device with a sandbox account:

1. `platform.signIn()` shows the sheet once; `platform.player` and the `player` event follow it; `platform.backend` is `"apple"`.
2. An achievement unlocks (banner on screen), a half-way `progress` is kept, `list()` shows both, `reset()` clears them.
3. A score reaches the board (`submit`), and `entries` returns it for `"top"`, `"around"` and `"friends"`.
4. `overlay.open` opens the dashboard for each page, with `overlay` events at open and close.
5. A consumable: `buy`, grant, `finish`, buy again. A non-consumable: `buy`, then `restore()` on a second device or after
   reinstalling. A subscription: `buy`, then `restore()`. Ask to Buy: `pending`, then the approval arrives as a `purchase`
   event.
6. Kill the app after a `buy` and before `finish`: the next run delivers the purchase as a `purchase` event.
7. `cloud.save` on one device, `cloud.load` on another with the same iCloud account.

Record what a real check finds in `ENGINE_FEEDBACK.json`.

## 7. Google Play: Billing, Play Games Services and Play Integrity

The backend `"googleplay"` is a plugin with a C bridge and a Java Gradle module (`platforms/plugins/googleplay`, written into
the game by `platform.add_backend`) for **Android on a device with Google Play** (the game's `minSdk`, 26 by default). It answers `platform` with:

| Service | Google's API | Notes |
|---|---|---|
| `purchases` | Play Billing 9.1 | consumables, non-consumables and subscriptions; pending payments; refunds. Always on. |
| `overlay` | Play Games / Play Store | `"achievements"` and `"leaderboards"` (Play Games screens) and `"store"` (the game's Play Store page). Always on; `"friends"` is `unavailable`. |
| `integrity` | Play Integrity 1.6 | a token that vouches for the app and the device: the generic service, this is its Android backend. Always on. |
| `achievements`, `leaderboards` | Play Games Services v2 22.1 | the sign-in prompt, Google's banners, all-time, daily and weekly public / around the player / friends boards. **Only with a Play Games project id** (below). |
| `cloudSave` | Play Games Saved Games | one snapshot per cloud key. **Only with a Play Games project id.** |

Play Games has no stats and no presence: `platform.has("stats")` and `platform.has("presence")` are false and the engine
answers those calls `unavailable`. Keep the numbers you need in `cloud.save` or on a leaderboard. Without a project id,
`platform.has("achievements")`, `"leaderboards"` and `"cloudSave"` are false too, and `platform.signIn()` answers signed out.

### Setup, in one command

```bash
factoria call platform.add_backend '{"backend": "googleplay", "playGamesId": "123456789012"}'
```

It writes the plugin to `plugins/googleplay` from its template and declares it for Android in factoria.json (unless it is
declared already), writes the Play Games project id to the plugin's `android/src/main/res/values/games-ids.xml`, and builds the
C bridge for `arm64-v8a` and `x86_64` with the **Android SDK's NDK, CMake and Ninja** (the SDK that
[the export](EXPORTING.md#android) uses: `ANDROID_HOME` / `ANDROID_SDK_ROOT`, else Android Studio's default folder). It uses
NDK `27.2.12479018` and CMake `3.31.6` when installed, else the newest installed with a note in `done`, and builds against
the game's `minSdk` (`export.android.minSdk`, 26 by default). The libraries land in `android/src/main/jniLibs/<abi>/`. Without
an SDK or an NDK the command stops before writing anything, says which is missing and how to install it (`sdkmanager
"ndk;27.2.12479018"`), and offers `googleplayBuild: false`.

| Argument | Meaning |
|---|---|
| `playGamesId` | The Play Games Services project id (digits: Play Console > Play Games Services > Setup and management > Configuration). Kept as it is when not passed; `""` turns Play Games off. A build without it offers `purchases`, `overlay` and `integrity` only. Export again after changing it. |
| `googleplayBuild` | `false` only writes and declares the plugin, to build later where the NDK is installed (the plugin's README has the commands). |

The result lists the built `libraries` and `nextSteps`, with the ids of your catalog filled in. What only a person can do:

1. **Play Console**: create the app with the package name of factoria.json's `id`, upload a signed build to a testing track
   (`factoria export --platform android --format aab`; internal testing is enough) and add your Google account under
   Settings > License testing. Billing and Play Integrity answer only for an app Play knows, and the app must be installed
   from the track's opt-in link, not with `adb`.
2. **Products** (Monetize with Play > Products): one-time products and subscriptions (with a base plan), each with
   **exactly** the id of the catalog (`ids.googleplay`, else `id`) and active. Google's rule for product ids: lowercase
   letters, digits, `_` and `.`, starting with a letter or digit, at most 40 characters; the command lists the ones that break it.
3. **Play Games Services** (only for achievements, leaderboards and cloud saves): create the project, add an Android credential
   for the package name with the SHA-1 of the key the build is signed with (the upload key for `adb` installs, the Play App
   Signing key for builds from Play), turn **Saved Games** on for cloud saves, and add yourself as a tester while the project is
   unpublished. Then pass its id as `playGamesId`.
4. **Achievements and leaderboards**: create them in that project. Play generates their ids (they start with `CgkI`): copy each
   into `ids.googleplay` of the catalog entry. A leaderboard's sort order must match the catalog's `order` (Play fixes it at creation).
5. **Play Integrity**: link a Google Cloud project in Play Console > Test and release > App integrity. A token is decoded
   **on your server** with Google's `decodeIntegrityToken`, never on the device.

Then export with `factoria export --platform android`: the exported Gradle project builds the plugin's module, which pulls
Billing, Play Games and Play Integrity from Google's Maven repository, and merges its manifest ([MOBILE.md](MOBILE.md#native-plugins-on-android)).
The plugin's manifest removes Play Games' automatic initializer: the plugin starts the SDK itself, and only when a project id is
set.

### What each call does

Google answers with its own ids: the engine maps the catalog ids to the `ids.googleplay` (else `id`) of each entry, and back.

| Call | On Google Play |
|---|---|
| `platform.signIn()` | Play Games signs the player in by itself when the app starts (a `player` event follows when it does). `signIn()` shows Google's sign-in prompt if the player is not signed in, and resolves `{ id, name, signedIn }` (`id` is the Play Games player id). A player who declines gets `notSignedIn`. Without a project id it resolves signed out, without any prompt. |
| `achievements.unlock(id)`, `.progress(id, fraction)` | Reports to Play Games (`newly` is false when it was unlocked already). `progress` needs an **incremental** achievement (else `failed`, saying how to make it one); 1 unlocks it. An id that Play Console does not have is `unknownId`, listing the ids it has. |
| `achievements.list()` | The catalog's achievements with what the player reached (an achievement Play does not have is reported locked, with a warning in the log). |
| `achievements.reset()` | `unavailable`: a game cannot reset achievements on Google Play. Use a fresh test account, or the Play Games management API from your own tooling. |
| `leaderboards.submit(id, score)` | The all-time board, or the daily or weekly one for a board with a `period` ("Leaderboard periods"). `best` is the player's best in that table including this score. |
| `leaderboards.entries(id, {range, count})` | `range`: `"top"`, `"around"` or `"friends"` (the player must allow friends in the Play Games app, else `notAllowed`). **At most 25 rows** per call: a larger `count` is cut to 25. The board's sort order is the one set in Play Console; the catalog's `order` is not sent. |
| `cloud.save(key, data)`, `cloud.load(key)`, `cloud.list()`, `cloud.remove(key)` | One Saved Games snapshot per cloud key, named after it (Play allows letters, digits and `- . _ ~`, up to 100 characters: every key the engine accepts fits). The value is stored as JSON text. `load` of a key that does not exist is `null` (a script gets `undefined`). When two devices saved the same key, the most recently modified save wins. Saved Games not turned on in Play Console: `unavailable`. |
| `cloud.stat(key)` | `{ exists, size, modified }`: the snapshot's last-modified time (`getLastModifiedTimestamp`, in Unix seconds) and the size of its data. Play has no call for the size alone, so `stat` **opens the snapshot and reads its bytes to count them** (it does not return them to the game, and closes it without saving); it costs about as much as `cloud.load`. A key with no snapshot is `{ exists: false }`. The last-modified time is the clock of the device that saved ("Which save is newer"). |
| `purchases.products(ids?)` | The product's title, description, price text (the player's currency), price value, currency and type. A product Google does not know is left out, with a warning in the log that says how to create it. A subscription shows the price of its base plan's renewing phase. |
| `purchases.buy(id)` | Shows Google's purchase sheet. `purchased` (with `transactionId` and `receipt`), `cancelled`, or `pending` (a payment that needs time: cash, a parent's approval). The call waits as long as the player takes with the sheet, but gives up after 30 s when Google answers nothing. |
| `purchases.finish(transactionId)` | A consumable is **consumed** (it can be bought again), a non-consumable or a subscription is **acknowledged**. Google **refunds a purchase that is not acknowledged within three days**: grant, then finish. The id must come from a `buy()` result, a `purchase` event or a `restore()` entry of this run. |
| `purchases.restore()` | Returns what the player owns: non-consumables and active subscriptions of the catalog (consumables are used up). Waits up to 120 s. |
| `overlay.open(page, id?)` | `"achievements"`: Google's achievements screen. `"leaderboards"`: all boards, or the one of `id`. `"store"`: the game's page in the Play Store app (a browser when there is none). The first two need Play Games on. |
| `integrity.token(...)` | Asks Google for an integrity token for the challenge your server made (the Play Integrity nonce: URL-safe Base64, 16 to 500 characters, as section 2 says). Needs Google Play services and a Play Store; for an app that Play did not install it answers `unavailable` (`APP_NOT_INSTALLED`). |

**Events.** `purchase` for a purchase that did not come from `buy()`: a pending payment that completed, a purchase made on
another device, a subscription renewal, or a purchase the last run did not finish. The plugin looks for them when the game
starts and **every time the game comes back to the front** (Google gives no push for them), once per purchase and state;
the engine keeps the ones nobody listens for (up to 100) and hands them to the first `platform.on("purchase", ...)`:
register it in `onStart`, grant, then `finish`. `overlay` `{open}` when a Google screen opens (Play Games or the Play Store)
and when the game is back in front. `player` when the Play Games player is known at start or changes.

**Refunds.** A refunded or cancelled purchase is no longer reported by Google, so it is not delivered or restored; a game
that must take goods back tracks refunds on its server (the Google Play Developer API's voided purchases).

### Receipts

The `transactionId` of a purchase is Google's **purchase token**. The `receipt` is the JSON text
`{"signedData": "<the purchase as Google signed it>", "signature": "<base64>"}`: `signedData` holds `packageName`,
`productId`, `purchaseToken`, `orderId` and the purchase time, and `signature` is checked with the licence key of the app
(Play Console > Monetize with Play > Monetization setup). A game with real money at stake (server-side goods, an online
economy) must verify the receipt **on its server** before granting: either verify the signature with the licence key, or
send the `purchaseToken` and `productId` to the Google Play Developer API (`purchases.products.get`, or
`purchases.subscriptionsv2.get`), which answers with the purchase state and whether it was acknowledged. A single-player game
that trusts the device can ignore the receipt.

### Testing purchases

Billing answers only for an app that Play knows, so a purchase needs a Play Console app, a build on a testing track, a license
tester account, and the app installed from Play. `adb install` builds and emulators without the Play Store cannot buy:
the calls then reject `unavailable` with a hint that names what is missing. A license tester pays nothing (the sheet says
"test card, always approves"), and Play Console lists the test orders. For everything but buying, a debug build installed with
`adb` is enough: Play Games works once the project knows the debug key's SHA-1 (add it as a second credential).

### When something does not work: `googleplay.status`

The plugin registers the command **`googleplay.status`** (from a script: `fa.call("googleplay.status", {})`): the package and
who installed it, Google Play services and Play Store versions and whether they are usable, the Billing connection, whether
Play Games is on (with the project id) and who is signed in, the services on offer, and a `problems` list of sentences that
say what to fix. Run it first.

| Situation | What the game gets |
|---|---|
| No Google Play services (an emulator image without the Play icon, a device without Google) | `unavailable`, naming Google Play services and how to get a device or image that has it. Purchases and Integrity are `unavailable` too. |
| Player not signed in to Play Games | `notSignedIn` from `signIn()` (the player declined), and from the calls that need a player. The hint explains the tester rule of an unpublished project. |
| Play Games project not set up (wrong id, missing credential or SHA-1) | `failed`, with a hint that lists the three things to check. |
| Achievement or leaderboard missing in Play Console | `unknownId` for an achievement (the message lists the ids Play has). A leaderboard id that Play does not know often comes back as an internal error of Play Games: the hint says to check `ids.googleplay` against Play Console. |
| Product missing in Play Console, or the app unknown to Play | `unknownId` from `buy`; `products()` leaves it out and logs the steps. `DEVELOPER_ERROR` is `failed`, listing the usual causes (no test track, another signing key, product inactive). |
| Billing not available (no Play Store, no Google account, an unsupported country) | `unavailable`. |
| The player already owns a non-consumable | `failed`, pointing at `restore()`. |
| No answer from Google in 30 s (restore: 120 s) | `network`. |
| Google's servers cannot be reached | `network`. |
| `reset()`, a `"friends"` overlay, stats, presence | `unavailable`. |

### CI and manual checks

CI builds the C bridge for both ABIs, exports the plugin and checks that the APK carries both libraries, the plugin's classes
(with Billing, Play Games and Play Integrity linked into the dex) and the merged manifest; the emulator job (an Android image
with **no** Google Play) then starts that APK and checks that the plugin registered the backend in a real engine, that
`googleplay.status` answers and that `signIn()` and `integrity.token` are answered through the C bridge and the Java code
with a teaching `unavailable` (the table at the top of [MOBILE.md](MOBILE.md)). The tests of the tooling cover the setup command (the NDK lookup, the project id, the `nextSteps`).
What needs a Play Console app, a signed build and Google accounts is checked by hand before a release, on a phone with Google
Play, the build installed from the internal testing track:

1. `platform.backend` is `"googleplay"`; `googleplay.status` has an empty `problems` list.
2. `platform.signIn()` shows the prompt once; `platform.player` and the `player` event follow it.
3. An achievement unlocks (Google's banner on screen); a half-way `progress` of an incremental one is kept, `list()` shows
   both. `overlay.open("achievements")` shows them, with `overlay` events at open and close.
4. A score reaches the board (`submit`), and `entries` returns it for `"top"`, `"around"` and `"friends"`.
5. A consumable: `buy`, grant, `finish`, buy again. A non-consumable: `buy`, then `restore()` after reinstalling. A subscription:
   `buy`, then `restore()`. A slow payment method: `pending`, then the completion arrives as a `purchase` event.
6. Kill the app after a `buy` and before `finish`: the next run delivers the purchase as a `purchase` event.
7. `cloud.save` on one phone, `cloud.load` on another with the same Google account.
8. `integrity.token` returns a token that your server can decode.

Record what a real check finds in `ENGINE_FEEDBACK.json`.

## 8. Ads: Google AdMob and consent on Android and iOS

The backend `"admob"` is a plugin (`platforms/plugins/admob`, written into the game by `platform.add_backend`) for **Android**
(a C bridge and a Java Gradle module) and **iOS** (Swift, [Ads on iOS](#ads-on-ios)). It is an **ads backend**: it offers only
the `"ads"` service and works next to the game's store backend ([section 4](#4-which-backend-runs)), so a game with Google Play
or App Store purchases and AdMob ads has both. Both platforms behave and answer the same; what differs is the setup, and Apple's
tracking sheet. **macOS has no AdMob SDK**: the plugin offers no ads there and `platform.has("ads")` is false (so it is on
Windows and Linux).

| Call | On AdMob |
|---|---|
| `platform.ads.consent()` | Google's User Messaging Platform (UMP). `gdpr` is `"notRequired"` (the player is outside the regions that need the form), `"granted"`, `"denied"` or `"unknown"` (the flow has not ended, or the game has not told the age of a `"mixed"` audience); `tracking` is `"notRequired"` on Android, and on iOS unless the game asks for the tracking sheet ([Ads on iOS](#ads-on-ios)); `canShowAds` is UMP's `canRequestAds`; `privacyOptions` is `"required"` when the player must be able to change their choices. |
| `platform.ads.available(placement)` | Loads one rewarded ad for the placement and keeps it. `true` when one is ready; `false` when there is none (no fill, no consent, no network, or 30 s without an answer). A kept ad older than 55 minutes is thrown away and loaded again (Google expires rewarded ads after an hour). |
| `platform.ads.showRewarded(placement)` | Shows the kept ad. `{ rewarded: true }` **only from the SDK's reward callback**; closing the ad early is `{ rewarded: false, reason: "closedEarly" }`, no ad is `reason: "noFill"` and a player who refused the consent is `reason: "consentRefused"`. The next ad of that placement loads in the background. |
| `platform.ads.setUnderAge(bool)`, `platform.ads.privacyOptions()` | [Children and consent](#children-and-consent). |

### Setup, in one command

```bash
factoria call platform.add_backend '{"backend": "admob"}'                                                         # Android
factoria call platform.add_backend '{"backend": "admob", "sdk": "~/Downloads/GoogleMobileAdsSdkiOS-13.11.0.zip"}'  # + iOS, on a Mac
```

It writes the plugin to `plugins/admob` from its template and declares it in factoria.json (unless it is declared already) for
Android and iOS (`"admobPlatforms": ["android"]` or `["ios"]` picks one). The repository holds no Google code:

- **Android**: it builds the C bridge for `arm64-v8a` and `x86_64` with the **Android SDK's NDK, CMake and Ninja**, the way
  [section 7](#7-google-play-billing-play-games-services-and-play-integrity) does for Google Play. When the game is exported,
  Gradle fetches the Mobile Ads SDK and Google's consent library from Google's Maven repository and merges the plugin's manifest
  ([MOBILE.md](MOBILE.md#native-plugins-on-android)).
- **iOS**: Google's SDK is a download (developers.google.com/admob/ios/quick-start, "Download the SDK"). `"sdk"` is the zip or
  the unpacked folder: the command copies `GoogleMobileAds.xcframework` and `UserMessagingPlatform.xcframework` into
  `plugins/admob/ios/frameworks/` (the plugin's `.gitignore` keeps them out of git: each clone runs the command again with its
  own download) and builds the Swift side with Xcode for the device and the simulator. On a computer without Xcode, or without
  `"sdk"`, the command still writes and declares the plugin, and `nextSteps` says what is missing. An iOS export whose plugin
  lacks the frameworks fails and says where to put them.

`"admobBuild": false` only writes and declares the plugin (and copies the frameworks when `"sdk"` is given).

The result lists `nextSteps`, with the ids of your catalog filled in. What only a person can do:

1. **Nothing, to see ads at all.** A development export (`factoria export --platform android` or `ios`, without `--release`)
   uses Google's test ads, below.
2. **AdMob console** (admob.google.com): add the app (the package name of factoria.json's `id`; the iOS app is another app of
   the console) and copy its **app id** (`ca-app-pub-1234567890123456~1234567890`, with a tilde) into
   `"platform": { "ads": { "appIds": { "android": "...", "ios": "..." } } }`.
3. **Ad units**: create a rewarded ad unit for each placement in each app and copy its id (`ca-app-pub-1234567890123456/1234567890`,
   with a slash) into the placement: `"ids": { "admob": "...", "admob_ios": "..." }` (`admob` is the Android unit, `admob_ios` the
   iOS one). An app id in a unit field, or the other way round, is an error that says so.
4. **Consent**: in AdMob > Privacy & messaging, create and publish the GDPR message (and the US states message if you sell
   there). Without a published message the consent library has no form to show.
5. **Audience**: `platform.ads.audience` for a game for children or for children and adults ([below](#children-and-consent)).
6. **iOS only, if the ads need the advertising id**: `trackingPrompt`, below.

### Ads on iOS

An iOS export of a game with the plugin links Google's two XCFrameworks (static libraries in the current SDK, so nothing is embedded; a dynamic one would be),
the plugin's Swift library, `AdSupport`, `AppTrackingTransparency` and `WebKit`, and writes into the Info.plist:
`GADApplicationIdentifier` (the app id), Google's list of `SKAdNetworkItems` (without it AdMob cannot attribute installs), and
the engine's `FactoriaAds*` keys that tell the plugin the audience and whether this is a test build. The plugin declares those in
its `ios/plugin.json` (`xcframeworks`, `infoPlist`, [MOBILE.md](MOBILE.md#native-plugins-ios)).

The start order is the same as on Android, with Apple's sheet added:

1. **Google's consent form (UMP)**, for the players who need it (the EEA, the UK, Switzerland, some US states).
2. **Apple's "Allow tracking" sheet (App Tracking Transparency)**, only when `platform.ads.trackingPrompt` is `true` in the
   catalog, only after the form closed with consent to request ads, only while the status is `notDetermined`, and never for a
   player counted as under age. A game that does not ask never sees the sheet and `consent().tracking` is `"notRequired"`;
   otherwise it is Apple's status: `"authorized"`, `"denied"`, `"restricted"` or `"notDetermined"` (a player who was never
   asked).
3. **The Mobile Ads SDK starts**; a refused tracking sheet does not stop ads (they are not personalized then).

```json
"ads": {
  "appIds": { "ios": "ca-app-pub-1234567890123456~0987654321" },
  "trackingPrompt": true,
  "trackingDescriptionKey": "ads.tracking",
  "placements": [ { "id": "more_time", "type": "rewarded", "ids": { "admob": "ca-app-pub-1234567890123456/1234567890",
                                                                    "admob_ios": "ca-app-pub-1234567890123456/0987654321" } } ]
}
```

- `trackingDescription` is the sentence of the sheet (`NSUserTrackingUsageDescription`); without it the export writes "This
  identifier will be used to deliver personalized ads to you." Apple reviews the sentence: say what the identifier is for.
  `trackingDescriptionKey` names a key of the string tables instead: the export writes one `InfoPlist.strings` per language of
  the game (`localization.languages`, [LOCALIZATION.md](LOCALIZATION.md)), so iOS shows the sheet in the player's language.
- An app that asks to track must say so in its privacy manifest: set `export.ios.privacy.tracking` (and the tracking domains)
  to match. The iOS export warns when `trackingPrompt` is true and it is not, and `factoria validate` warns when `trackingPrompt`
  is true and the game has no ads plugin for iOS ([MOBILE.md](MOBILE.md#store-privacy-forms)).
- In AdMob > Privacy & messaging, create the IDFA explainer message too if you ask for tracking.
- A `children` audience never asks for tracking, whatever `trackingPrompt` says.

### Test ads and real ads

| Export | App id in the manifest | Ad unit loaded |
|---|---|---|
| `factoria export --platform android` (development) | Google's sample app id `ca-app-pub-3940256099942544~3347511713`, whatever the catalog says | Google's sample rewarded unit `ca-app-pub-3940256099942544/5224354917` for every placement |
| `factoria export --platform android --release` | `platform.ads.appIds.android` (the sample id when it is not set, with a warning) | the placement's `ids.admob`; a placement without a valid one rejects with `unknownId` and says how to add it |
| `factoria export --platform ios` (development) | Google's iOS sample app id `ca-app-pub-3940256099942544~1458002511` (`GADApplicationIdentifier`), whatever the catalog says | Google's iOS sample rewarded unit `ca-app-pub-3940256099942544/1712485313` for every placement |
| `factoria export --platform ios --release` | `platform.ads.appIds.ios` (the sample id when it is not set, with a warning) | the placement's `ids.admob_ios`; a placement without a valid one rejects with `unknownId` |

Test ads are labelled as such, earn nothing, and cannot get your account flagged for clicking your own ads. The mode comes
from the manifest (`factoria.ads.test`, written by the export; on iOS the Info.plist's `FactoriaAdsTest`), not from `platform.release`: an exported game always runs without
a fallback store, so `platform.release` is true in every APK, test ads or not. `factoria validate` and a release export warn when
the game has the admob plugin for Android (iOS) and `platform.ads.appIds.android` (`.ios`) is missing or Google's sample id, when a
placement has no `ids.admob` (`ids.admob_ios`) or has the sample unit, and when the audience is `"mixed"` and no script calls
`setUnderAge`. An export for one platform reports only that platform's problems.

### Children and consent

The start order is Google's, and the plugin keeps it: the consent form (a player in the EEA, the UK or Switzerland answers it
once; Google keeps the answer) comes first, and the Mobile Ads SDK starts only when the player's choices allow requesting ads.
Nothing runs before the game's activity is in front. `ads.available` and `ads.showRewarded` wait for that to finish, and answer
"no ad" if it ends without the player's consent or if the SDK start takes more than 120 s after the form. While the consent form is still open the wait
goes on: the player may take minutes to read it, and the flow ends by itself with an error if the network fails.

`platform.ads.audience` in factoria.json says who plays:

| Audience | What the engine does |
|---|---|
| `"general"` (default) | Nothing special: consent as UMP decides. A game that told the age with `setUnderAge` has it passed on. |
| `"children"` | The game is made for children. Every player counts as under age: UMP and every ad request are tagged for child-directed treatment and the under age of consent, with the maximum content rating G. `setUnderAge(false)` is ignored. Check Google's families policies before you ship ads in a children's game. |
| `"mixed"` | Children and adults play. **Until the game calls `platform.ads.setUnderAge(bool)`, nothing is requested**: no consent form, no SDK start, no ad (`available` is false, `showRewarded` is `consentRefused`, `consent().gdpr` is `"unknown"`), so a child is never shown the form untagged. The answer tags UMP and every ad request the way `"children"` does for a child (`true`), or as not child-directed (`false`). |

For `"mixed"`, add the menu kit's age gate: `factoria call project.add_menu_kit '{"parts": ["main-menu", "ageGate"]}'`
(the main menu opens it; the `ageGate` part alone adds the panel and `openAgeGate()` for your own first scene; [MENUS.md](MENUS.md#age-gate)). It asks the year of birth, keeps only whether the player is under age (never the year; a player
who prefers not to say counts as a child), and calls `platform.ads.setUnderAge`; later runs read the stored answer and call it
again. The engine keeps the answer for the run and sends it to the backend with every ads request. `platform.reset()` (tests)
forgets it.

`platform.ads.privacyOptions()` opens UMP's form where the player changes their choices or takes consent back. Google requires a
button for it whenever `platform.ads.consent().privacyOptions` is `"required"`; show it **only then** (the menu kit's options screen
does). It resolves `{ shown }`; if the player took consent back, the ads kept in memory are discarded and no new one loads.

The **fake backend** answers all of it for development and tests: `game.platform.ad("watched", { gdpr: "granted", privacyOptions:
"required" })` sets what `consent()` answers, both calls appear in `state().fake.calls`, and `state().fake.ads.privacyShown` counts the forms.

### When something does not work: `admob.status`

The plugin registers the command **`admob.status`** (from a script: `fa.call("admob.status", {})`): the manifest's (iOS: the
Info.plist's) app id, whether this is a test build, the audience, the age the game told, the consent answer (on iOS also
`trackingPrompt`), whether the SDK started, each placement's unit, whether its ad is ready and its last error, and a `problems`
list of sentences that say what to fix. Run it first.

| Situation | What the game gets |
|---|---|
| The audience is `"mixed"` and the game never told the age | No consent form and no ads, as above. `problems` says so. |
| The player refused the consent | `available` false, `showRewarded` `{ rewarded: false, reason: "consentRefused" }`. |
| No ad to show (no fill, no network, a new app that AdMob still reviews) | `available` false; `showRewarded` `reason: "noFill"`. The log has Google's error code. |
| Release build with no valid `ids.admob` (iOS: `ids.admob_ios`) for the placement | `unknownId`, naming the placement and the catalog key to add. |
| iOS, `trackingPrompt` true and the Info.plist has no `NSUserTrackingUsageDescription` (an old export) | iOS ends the app when the sheet is requested; the log warns before. Export again. |
| iOS, the player refused the tracking sheet | Ads still load (not personalized); `consent().tracking` is `"denied"`. |
| The ad failed to show | `failed`, with Google's code and message. |
| No AdMob app id in the manifest (Info.plist on iOS) | AdMob stops the app at start; `factoria validate` warns before. |

### CI and manual checks

**Android.** CI exports the game with the plugin, checks that the APK carries both libraries, the plugin's classes (with the Mobile Ads SDK
and UMP linked into the dex) and the manifest with the app id, and starts it on the emulator to see that the plugin registered the
**ads** backend and answers `admob.status` through the C bridge. It does not load an ad: that needs Google's network and an
image with Google Play. The tooling tests cover the setup command, the manifest of an export (the app id, the test flag, the
audience) and the validate warnings. By hand, on an emulator with Google Play (for instance the AVD `Pixel7_API35`), with the
development export of a game that has the plugin:

1. `adb install -r game.apk`, start it and read `adb logcat -s FactorIA.admob`: `AdMob: development export, Google's test ads`,
   then `ads: consent {...}` (a European test device shows UMP's form first; elsewhere the status is `notRequired`) and
   `ads: the Mobile Ads SDK is ready`.
2. Open the screen that offers the ad: `ads: a rewarded ad is ready for '<placement>'`. Show it: Google's test ad, then
   `ads: the player earned the reward of '<placement>' (...)` and `ads: the rewarded ad of '<placement>' was closed, rewarded: true`.
3. Close a second ad before the reward: `rewarded: false`, `reason: "closedEarly"`, and the game grants nothing.
4. With `consent().privacyOptions` `"required"` (a test device in UMP's debug geography), the options button shows UMP's form.
5. In a `"mixed"` game, check that nothing is requested before the age gate is answered (`admob.status` says
   `consentFlowStarted: false`).

**iOS.** No CI job loads Google's iOS SDK (it is a download that the repository never holds): the tooling tests export a game
with a stub XCFramework made by the test and check that it is linked, that the Info.plist has the app id, the `SKAdNetworkItems`
and the tracking sentence, and that the catalog and validate errors teach; they also cover the setup command with a stub SDK zip.
By hand, on the iOS Simulator (an iPhone runtime of Xcode; the simulator needs the network), with the development export of a
game that has the plugin (`factoria export --platform ios`, then the `nextSteps` it prints to build and install the app; read
the app's console with `xcrun simctl launch --console-pty <device> <bundle id>`):

1. The log shows `AdMob backend ready: service ads on ios`, `AdMob: development export, Google's test ads, audience general,
   tracking prompt on|off`, `ads: consent {...}` and `ads: the Mobile Ads SDK is ready`.
2. A rewarded ad: `ads: a rewarded ad is ready for '<placement>'`, Google's test ad, `ads: the player earned the reward...`, then
   `...was closed, rewarded: true`. Closing it early gives `rewarded: false`, `reason: "closedEarly"`.
3. The consent form: a development export reads Google's debug settings, which a release build ignores. Launch with
   `SIMCTL_CHILD_FA_ADS_DEBUG_GEOGRAPHY=EEA xcrun simctl launch --console-pty <device> <bundle id>` (or `regulatedUSState`,
   `other`; the launch argument `-FactoriaAdsDebugGeography EEA` does the same) to see UMP's form on a simulator, and
   `SIMCTL_CHILD_FA_ADS_RESET_CONSENT=1` to forget the stored answer (UMP keeps it between runs). `simctl` cannot tap: answer the
   form by hand in the Simulator app, or with an XCUITest (`platforms/ios/touch-test` shows how).
4. With `trackingPrompt` true: after the form is answered, the "Allow tracking" sheet appears with your sentence, and the log
   says `ads: tracking authorized` (or `denied`). It comes after the form and not before. iOS keeps the answer per app: change it in the simulator's Settings > Privacy & Security > Tracking, or use a fresh simulator to be asked again.
5. In a `"mixed"` game, nothing is requested before the age gate is answered (`admob.status` says `consentFlowStarted: false`).
6. A release export shows no test ad: it carries your `appIds.ios` and the `ids.admob_ios` of each placement. A new AdMob app
   may get "no fill" for a day or two while Google reviews it.

Record what a real check finds in `ENGINE_FEEDBACK.json`.
