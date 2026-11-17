# Store and platform services: achievements, stats, leaderboards, cloud saves, purchases, page 1 of 4

Part of [Store and platform services: achievements, stats, leaderboards, cloud saves, purchases](../PLATFORM.md) (the entry page lists every page).

## 2. The script API

`import { platform } from "factoria"`. **Every call returns a Promise.**

| Call | Resolves with |
|---|---|
| `platform.backend` | The name of the backend that runs: `"fake"`, `"none"`, `"steam"`... (the plugin's name). |
| `platform.has(service)` | Whether the backend offers the service: `"achievements"`, `"stats"`, `"leaderboards"`, `"cloudSave"`, `"purchases"`, `"overlay"`, `"presence"`, `"integrity"`, `"ads"`, `"remotePlay"`, and `"http"` (`http.fetch`, [NETWORKING.md](../NETWORKING.md): the system's HTTP client, or the fake in tests). Check it before using a service that a store may not have. |
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
| `platform.stats.add(id, delta)` | The new value. The fake store adds on the value it holds when it serves the request, so two adds made in one frame both count; another backend gets a `stats.get`, then a `stats.set` (not atomic). |
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
| `platform.ads.setUnderAge(underAge)` | Nothing. Tells the platform whether the player is under the age of consent, after the game asked the age (the menu kit's `ageGate` part does). Required for `audience: "mixed"`. [Children and consent](PLATFORM_ADS.md#children-and-consent). |
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
| Android with the `admob` plugin (`platform.add_backend {"backend": "admob"}`) | Google AdMob rewarded ads and Google's consent form (UMP): [section 8](PLATFORM_ADS.md#8-ads-google-admob-and-consent-on-android-and-ios). |
| iOS with the `admob` plugin | Google AdMob rewarded ads, Google's consent form (UMP) and, when the catalog asks, Apple's App Tracking Transparency sheet: [Ads on iOS](PLATFORM_ADS.md#ads-on-ios). |
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
| `"overlay"` | `{ open }` | The store's overlay opened or closed. Games pause while it is open (`scripts/store_events.js` in [MENUS.md](../MENUS.md)). |
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
| `network` | The store could not be reached, or did not answer before the engine's deadline (below). Offer a retry. |
| `failed` | Anything else; the message says what. |

**Deadlines.** A request whose backend never answers does not hang the game: the engine answers it itself with the
error `network` (message: `platform.<method> got no answer from the "<backend>" backend in <N> s, so the engine gave up
on it`) and tells the backend it may stop (`PlatformBackend::cancel`); an answer that arrives later is ignored, with one
exception below. The time is **30 s** for most methods; **300 s** for the ones that wait for the player
(`purchases.buy`, `purchases.restore`, `ads.showRewarded`, `ads.privacyOptions`, `player.signIn`); **600 s** for
`ads.consent`, `ads.available` and `ads.setUnderAge`, because the ads plugins wait for the consent form the player fills in
(120 s, and for as long as the player is busy with it) and then up to 30 s for an ad to load; and for `http.fetch` the
request's own `timeout` (default 15 s, at most 120 s) plus 5 s. A host can change one method's time with
`PlatformServices::set_request_timeout` (for `http.fetch` it replaces the 5 s of grace). The deadline is IO, not
simulation: it reads a monotonic clock once per frame (`PlatformServices::frame`), so the frame in which the error
arrives depends on the wall clock, never the simulation's state. The fake backend has no deadline (its answers are
scripted and counted in frames, so a test gives the same result on a slow machine); `platform.state()` shows `timedOut`,
the number of requests the engine gave up on.

**A purchase that goes through after its deadline is not lost.** The store may take the money after the game was told
`network` (a slow sheet, a bad connection that recovers). The engine remembers the last 64 `purchases.buy` and
`purchases.restore` requests it gave up on; if one of them is answered with a success later, the purchase reaches the game
as a `purchase` event (a `buy` that answers `purchased`, or each entry of a `restore`, with `status: "purchased"`), its
transaction is recorded so `purchases.finish(transactionId)` accepts it, and the log gets a warning. The game that already
showed "try again" must therefore grant what arrives in `platform.on("purchase", ...)`, as for any purchase that did not
come from a `buy()` call, and a retried `buy()` of a consumable can charge twice only if the store itself lets it. A late
failure or cancellation changes nothing.

**Queues.** The events a backend sends (`purchase`, `overlay`, `player`, `remotePlay`) wait for the game until the start of
the next frame. If more than 1024 pile up (a script layer that is not running), the **oldest** are dropped, counted in
`platform.state().droppedEvents` and reported by one warning in the log, but a `purchase` event is dropped only when
nothing else is left to drop (the overlay, player and remotePlay events go first, oldest first). The answers of requests
have a cap of 4096: the oldest are dropped.

Achievements, stats and presence are best effort: end those calls with `.catch(() => {})`. Purchases are not: show the
player what happened (`e.hint`) and grant nothing.

## 3. The fake store, and testing with it

The fake backend runs in development and in **every** headless run: `factoria test`, `factoria call`, `factoria
session`, the MCP server. It is deterministic (no clock, no random numbers), keeps everything in memory, offers every
service and `http.fetch` ([NETWORKING.md](../NETWORKING.md), "Testing with the fake"), and starts afresh in each test file. The defaults are plausible successes: the player is signed in as
`{ id: "fake-player", name: "Player", signedIn: true }`; `buy` answers `purchased` with the transaction `fake-1`,
`fake-2`... and the receipt `fake-receipt-1`...; the purchase stays unfinished until `finish`; consumables are never
"owned"; `products()` takes title and price from the catalog (`$0.99`, or `2.99 EUR`); a leaderboard shows the player's
own best; `integrity.token` answers `{ token: "fake-integrity-1" }`, then `fake-integrity-2`... (no store
can verify these: a development server has to accept them on purpose); `cloud.stat` answers a `modified` that starts at
`1767225600` (2026-01-01T00:00:00Z) and goes up one second with each `cloud.save` (no wall clock); `remotePlay.sessions`
lists the guests the test connected. `await` works in tests, and an answer is ready at
once, without `game.step()`. "At once" means: the fake serves the request inside the call (also one made from an event handler
during a frame), so `game.platform.state().fake` already shows its effect when the call returns; the Promise settles in the
next microtask, and a game that chains several steps (`await stat(...)`, then `await save(...)`) needs one microtask per step,
so a test awaits the chain (or the microtasks: `await Promise.resolve()` a few times) instead of stepping frames. Only
`delayFrames` makes an answer wait for frames. `state().fake.achievements` lists only the ids that were touched (unlocked or
given progress) since the last `reset()`, not the catalog; `platform.achievements.list()` has the whole catalog.

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
| `game.platform.calls()` | `state().fake.calls`. The log holds what the fake performed, not what the script called: `platform.stats.add(id, d)` shows as one `stats.add` (assert `state().fake.stats`, or that call). Only the fake gets `stats.add`; a real store gets a `stats.get` and a `stats.set`. |
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
