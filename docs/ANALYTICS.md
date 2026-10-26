# Analytics and remote config

Two small services on top of [`http.fetch`](NETWORKING.md):

- **`analytics`** counts what players do (which level, how it ended) and sends it to **your** server in batches, **only
  after the player said yes**. There is no engine server and no identifier: the engine sends the events you queue, the
  game's id and version, and nothing else.
- **`remoteConfig`** reads a JSON file from your server (enemy speed, an event flag, a message) and keeps the last good copy
  for players who are offline.

```js
import { analytics, remoteConfig } from "factoria";

if (analytics.consent() === "unknown") askThePlayer();          // the menu kit has this screen (section 2)
analytics.event("level_done", { level: 3, won: true, seconds: 74 });
const speed = remoteConfig.get("enemySpeed", 1.5);             // 1.5 when the server has no value or the player is offline
```

This page: [configure](#1-configure) | [consent](#2-consent) | [events](#3-events) | [when a batch goes out](#4-when-a-batch-goes-out)
| [remote config](#5-remote-config) | [testing](#6-testing-without-a-server) | [privacy](#7-privacy-and-the-stores)
| [your server](#8-your-server).

## 1. Configure

Both services read their section of `factoria.json`. A game without a section has no such service: `analytics.configured` and
`remoteConfig.configured` are `false`, `remoteConfig.get` returns its fallback, and `analytics.event`, `flush` and `setConsent`
throw with what to add. The address' host must also be in [`"network"`](NETWORKING.md#1-declare-the-hosts), because the
requests are plain `http.fetch` calls.

```json
"network": { "hosts": ["stats.example.com", "cfg.example.com"], "purpose": "Anonymous level statistics the player agreed to, and balance values." },
"analytics": { "endpoint": "https://stats.example.com/events", "batch": 20, "flushSeconds": 30 },
"remoteConfig": { "url": "https://cfg.example.com/game.json" }
```

| `analytics` field | Meaning |
|---|---|
| `endpoint` | **Required.** The `https://` address that receives every batch as a POST. Its host must be in `network.hosts`. |
| `batch` | Events that make a batch go out at once, 1 to 100. Default 20. |
| `flushSeconds` | The longest an event waits in the queue, 1 to 3600 (engine seconds). Default 30. Also the first wait after a failure. |
| `timeoutSeconds` | Seconds one request may take, 0.5 to 120. Default 10. |
| `consentFromAds` | `true`: until the player answers the analytics question, [the ad consent](PLATFORM.md#children-and-consent) decides ([section 2](#2-consent)). Default `false`. |

| `remoteConfig` field | Meaning |
|---|---|
| `url` | **Required.** The `https://` address of a JSON object. Its host must be in `network.hosts`. |
| `timeoutSeconds` | Seconds the fetch may take, 0.5 to 30. Default 5. |

`factoria validate` checks both sections (each problem with its JSON pointer and a fix: a host that is not declared, a
`http://` address, a number out of range, a misspelled key with "did you mean"), and warns when a script calls
`analytics.event(` while the game has no `"analytics"` section. `factoria export ios` adds a "Product Interaction" entry
(purpose "Analytics", not linked to the user, not used for tracking) to the privacy manifest when the section exists.

## 2. Consent

Nothing is kept or sent until the player said yes. `analytics.consent()` returns `"granted"`, `"denied"` or `"unknown"`
(never asked); `analytics.setConsent(true | false)` records the answer, which `storage` keeps between runs (under the
engine's own key `factoria.analytics`: `storage.keys()` does not list it, `storage.clear()` removes it, and the player is
asked again).

- While the answer is `"unknown"` or `"denied"`, `analytics.event(...)` returns `false` and keeps **nothing**: the first
  events of a run before the question are not stored to be sent later.
- `setConsent(false)` **forgets the queue** and stops every later send. A batch already on its way when the player
  refuses is not put back if it fails.
- **The menu kit asks for you.** Add its `analyticsConsent` part ([MENUS.md](MENUS.md#analytics-question)): the main
  menu opens a screen on the first run with "Allow" and "No thanks", the options panel gets the switch "Share anonymous
  usage data", and the texts are string-table keys you edit to match what the game sends. A game of your own can call
  `analytics.setConsent` from any button.
- **A game with ads** can set `"consentFromAds": true`. Then, while the player has not answered the analytics question
  themselves, analytics counts as granted exactly when `platform.ads.consent()` says the GDPR consent is `"granted"` and
  tracking is `"authorized"` or `"notRequired"`; a missing, unknown or refused ad consent never grants it. The engine
  asks `platform.ads.consent()` once for this (the call changes nothing; it only reads). The player's own answer, yes or
  no, always wins. Leave the flag off when the ad consent says nothing about your analytics in your own privacy policy.
- A game for children has its own rules: do not collect without a lawyer's advice ([LEGAL.md](LEGAL.md)).

## 3. Events

`analytics.event(name, props?)` returns `true` when the event was queued.

| Rule | Limit (`analytics.limits`) |
|---|---|
| `name` | Starts with a letter; letters, digits, `_`, `.` and `-`; at most 64 characters. |
| `props` | A flat object of strings, numbers, booleans or `null`: at most 20 props; a prop name follows the rule of `name` (40 characters); text values at most 200 characters; at most 2048 characters of props as JSON; numbers finite. |
| queue | At most 500 events wait; over that the oldest are dropped (`analytics.status().dropped`). |

A mistake throws with the limit and what to change. Send **codes and numbers**, never what the player typed. Each event
carries `t`, the seconds since the run started, counted by the engine even while the game is paused.

## 4. When a batch goes out

One request: `POST <endpoint>`, `Content-Type: application/json`, body

```json
{ "game": "com.example.mygame", "version": "1.0.2", "sentOn": "2026-10-26",
  "events": [ { "name": "level_done", "props": { "level": 3, "won": true }, "t": 412.5 } ] }
```

`game` and `version` are `id` and `version` of `factoria.json`, `sentOn` is the UTC date of the send (`game.today().utc.iso`).
At most 100 events per request. A batch goes out:

- when `batch` events wait (immediately);
- when the oldest event waited `flushSeconds`;
- when the app is suspended (a phone sending the game to the background: the engine's `app.suspend` event);
- when the game quits: the window's close button, `game.quit()` and an unhandled Back all flush first and then wait for
  the request, **at most 3 seconds**, before the game closes (a `game.on("quit")` handler that cancels keeps the window
  open: the flush still happens at the next close);
- when you call `analytics.flush()`, which resolves `{ sent, ok }`.

A failure keeps the events and tries again later: a lost connection, a timeout, or a 408, 429 or 5xx answer, with the wait
doubling from `flushSeconds` up to 10 minutes, at most **3 attempts per event** and then it is dropped. Any other
non-2xx answer (400, 401, 404...) is a refusal: the batch is dropped at once and the log says why (a wrong endpoint is
fixed in `factoria.json`, not by retrying). Only one request is on its way at a time. `analytics.status()` returns
`{ configured, consent, queued, inFlight, dropped, failures, retryInSeconds, endpoint }` for debugging.

Nothing is kept on disk: events that were still queued when the game was killed are lost, which is why the quit and suspend
flushes exist.

## 5. Remote config

`remoteConfig.get(key, fallback)` returns the server's value, else the last cached one, else `fallback`. The first call
(or the first frame of the game) starts one `http.fetch` of the `url`; the answer is cached in `storage` (key
`factoria.remoteConfig`) and used by the next runs while the player is offline.

- `get` returns a copy and **checks the type against the fallback**: a text where you expect a number counts as missing, so a
  wrong file on your server cannot break the game. Use a fallback of the type you expect (an `Array` for a list).
- `remoteConfig.source()` is `"remote"` (this run's fetch worked), `"cache"` (an earlier run's) or `"default"`.
- A bad answer (a status that is not 2xx, text that is not a JSON object, more than 64 KB or 500 keys) is ignored **as a
  whole**: the values never come half from the new file and half from the old one.
- Values are read at the call: `get` before the answer arrives gives the cache or the default. To wait for the first answer at
  the loading screen use `ready(timeoutSeconds = 3)`, which resolves with `source()` and never rejects. `refresh()` fetches
  again.
- `remoteConfig` is a **tuning** tool, not a secret store: anyone can read the file you serve.

An answer settles at the start of a frame, maybe after the scene changed. A script that awaits `ready()` or `refresh()` checks
that its scene is still the current one before it uses the result:

```js
const here = scene.current;
remoteConfig.ready().then(() => {
  if (scene.current !== here) return;      // the player already left this scene
  enemy.speed = remoteConfig.get("enemySpeed", 1.5);
});
```

## 6. Testing without a server

Tests never touch the network. The batches and the config fetch are `http.fetch` calls, answered by the fake: script the
server with `game.platform.respond("http.fetch", ...)` ([NETWORKING.md](NETWORKING.md#4-testing-with-the-fake)); a
request nobody scripted fails like an offline player (events are kept and retried). The `game` of `factoria:test` has:

| Call | What it gives |
|---|---|
| `game.analytics.sent()` | The events the server accepted (2xx), oldest first: `{ name, props, t }`. |
| `game.analytics.requests()` | Every request: `{ endpoint, reason, ok, status?, error?, events }`; `reason` is `"batch"`, `"timer"`, `"suspend"`, `"quit"` or `"flush"`. |
| `game.analytics.queued()` | The events waiting for the next batch. |
| `game.analytics.restart()` | The next run: queue and logs are forgotten; the player's consent stays. |
| `game.remoteConfig.restart()` | The next run: memory is forgotten and the next use fetches again, starting from the cache earlier runs wrote. |

```js
test("no event before consent, a batch after it", () => {
  game.platform.reset();
  game.platform.respond("http.fetch", { status: 204 });
  expect(analytics.event("level_done")).toBe(false);          // not asked yet
  analytics.setConsent(true);
  analytics.event("level_done", { level: 1 });
  analytics.flush();
  game.step(1);
  expect(game.analytics.sent().map((e) => e.name)).toEqual(["level_done"]);
  game.closeWindow();                                           // the quit flush of a game with events waiting
});
```

Each test file starts with empty `storage`, no consent and a fresh service. The logs behind `game.analytics` exist only in test runs: a shipped game keeps none.

## 7. Privacy and the stores

The engine sends only what you queue plus `game` (the id), `version`, the send date and each event's time since the run started. It
generates **no device id, user id or session id**. The server you run does see the player's IP address and whatever the
HTTP stack sends (a user agent), like any web request; say so in the policy. If your props identify a person (a name, an
account id, an e-mail), the data is personal data and the rest of [LEGAL.md](LEGAL.md) applies in full.

- Put the analytics in your **privacy policy**: what is sent (the list of your event names and props), why, that it only
  happens after consent, who receives it, how long you keep it and how the player withdraws (the Options switch).
- The **store forms** ask what you collect: Apple's "App Privacy" (the iOS export adds a Product Interaction / Analytics
  entry, not linked to the user, not for tracking, to the manifest; the App Store Connect answers are yours to give) and
  Google Play's Data safety form ("App activity", collected, optional). [LEGAL.md](LEGAL.md) has the walk-through.
- The `network.purpose` sentence of `factoria.json` should mention it.

## 8. Your server

The engine only needs two endpoints: one that accepts the POST above (answer any 2xx; the body of the answer is ignored)
and one that serves a JSON object. Both can be static hosting plus a small function. Keep the endpoint's answer fast: a
quit waits for it for up to 3 seconds. Rate-limit and validate on your side (names, sizes), because anyone can send
anything to a public endpoint. A game's own server needs a CORS header only for the web build
([NETWORKING.md](NETWORKING.md#6-per-platform)).
