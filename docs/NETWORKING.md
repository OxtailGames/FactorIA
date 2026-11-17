# Networking: `http.fetch` and `websocket`

A game can ask a web server for something (a daily challenge, a leaderboard of its own, a remote configuration, a
news line) and send it a small text. One call does it on every platform:

```js
import { http } from "factoria";

const r = await http.fetch("https://api.example.com/daily");
if (r.ok) startChallenge(r.json().seed);
```

The game says **which servers it talks to** in `factoria.json`, once. The engine refuses every other address before
anything is sent, tells the privacy documents what the game does, and asks Android for the `INTERNET` permission only
for games that declare hosts. A game that declares nothing cannot use the network.

Two things built on this call have their own page, [ANALYTICS.md](ANALYTICS.md): usage events sent in batches after the
player consented, and values a server serves as JSON with a cache for offline play. Their addresses are `http.fetch`
calls, so their hosts are declared here too.

This page: [declare the hosts](#1-declare-the-hosts) | [the call](#2-the-call) | [what it never does](#3-limits-and-rules)
| [testing without a network](#4-testing-with-the-fake) | [replays](#5-replays) | [per platform](#6-per-platform)
| [privacy](#7-privacy-and-the-stores) | [WebSocket](#8-websocket).

## 1. Declare the hosts

```json
"network": {
  "hosts": ["api.example.com", "*.cdn.example.com"],
  "purpose": "Daily challenge and the game's own online leaderboard."
}
```

| Field | Meaning |
|---|---|
| `hosts` | The host names `http.fetch` may call. At least one. `"api.example.com"` is exactly that host; `"*.example.com"` is every subdomain (`a.example.com`, `a.b.example.com`) but **not** `example.com` itself (list it too if you need it). Write names only: no `https://`, no path, no port, no `*` anywhere else. At most 64. Host names ignore case. |
| `purpose` | One sentence about what the game sends and why. Optional for the engine, but `factoria validate` warns without it: the privacy policy and the store forms need it ([section 7](#7-privacy-and-the-stores)). |

`factoria validate` checks the section (every problem with its JSON pointer and a fix) and warns when a script calls
`http.fetch` while no host is declared. `platform.state` (`game.platform.state()` in tests) shows the declared hosts as
`networkHosts`.

### Which URLs

- **`https://` only.** Certificates are checked by the system; a bad certificate is a failure, never a warning.
- **Plain `http://` only to the developer's own machine:** `localhost`, `127.x.x.x` or `[::1]`, and only when that host
  is listed too. It is meant for a test server on your computer. It does not work on Android (the system blocks plain
  http there), and a browser may refuse it from a page that was loaded over https.
- **The host must be declared** (above). `https://api.example.co/` when you declared `api.example.com` throws with a
  "did you mean".
- **No user name or password in the URL** (`https://user:pw@host/`): put a token in a header instead.
- At most 2048 characters, no spaces or control characters.
- **Redirects** are followed up to 5 times (the browser and Android follow their own limit, up to 20) and **only to
  `https://`**: an answer that sends the player to plain http is a failure. The host a redirect goes to does **not** have
  to be declared: you chose to call the first one. If that matters to you, call the final address yourself.

## 2. The call

`http.fetch(url, options?)` returns a Promise.

| Option | Meaning |
|---|---|
| `method` | `"GET"` (default), `"HEAD"`, `"POST"`, `"PUT"`, `"PATCH"` or `"DELETE"`. Case does not matter. |
| `headers` | An object of strings: `{ "Authorization": "Bearer " + token }`. At most 32. Names ignore case and may not repeat. The system sets `Host`, `Content-Length`, `Connection`, `Transfer-Encoding`, `Upgrade`, `Expect`, `TE`, `Trailer`, `Keep-Alive`, `Proxy-Authorization`, `Proxy-Connection` and `Sec-*` itself and refuses them. Your object is copied, never changed. |
| `body` | A **string** is sent exactly as it is. An **object or array** is sent as JSON, with `Content-Type: application/json` unless you set a content type yourself. Not for `GET` and `HEAD`. At most 1 MB. |
| `timeout` | Seconds for the whole request, connecting included: more than 0, at most 120, default 15. |

An unknown option throws and suggests the right name (`methd` -> `method`).

It resolves with a frozen object:

| Field | Meaning |
|---|---|
| `status` | The HTTP status, a whole number (200, 404, 503...). |
| `ok` | `true` for 200 to 299. |
| `headers` | An object with the **lower-case** names (`headers["content-type"]`). A header that came several times is joined with `", "`. |
| `text` | The body as text. Bytes that are not valid UTF-8 become the replacement character. |
| `json()` | `JSON.parse(text)`. Throws an Error that shows the start of the body when it is not JSON (a server error page, for example). |

**An HTTP error status is an answer, not a failure:** a 404 or a 503 resolves with `ok: false`; check `r.ok` or
`r.status`. A request that did not complete (no connection, a timeout, an untrusted certificate, an answer over 4 MB)
**rejects** the Promise with an Error that has `code` (`"network"`) and `hint`; `platform.has("http")` is false on a
computer that cannot send requests at all (the call then rejects with `unavailable`). A **mistake** in the call (an
undeclared host, a bad option) **throws at once**, the way `platform` does, so it shows up in the test that makes it.

```js
try {
  const r = await http.fetch("https://api.example.com/scores", { method: "POST", body: { name, score }, timeout: 5 });
  if (!r.ok) showMessage("The server said " + r.status);
} catch (e) {
  showMessage(e.message); // e.code === "network", e.hint says what to try
}
```

### The answer may arrive after the player left

A request takes as long as the network takes, and a script that awaits it runs **later**: the scene may have changed,
the entity may be gone. Check before you act on the result:

```js
import { Behaviour, http, scene } from "factoria";

export default class Scores extends Behaviour {
  async onStart() {
    const here = scene.current;                              // the scene the request was made in
    const r = await http.fetch("https://api.example.com/scores").catch(() => null);
    if (!r || scene.current !== here || !this.entity.alive) return;  // left the scene, or this entity is gone
    this.entity.get("Text").text = r.json().top.join("\n");
  }
}
```

`scene.current` is the path of the scene: reloading the same scene gives the same path, so also check the entity's
`alive` (or a counter your script increments when it starts a new screen) for entities that the reload replaced. The test in
`engine/script/tests/test_http_api.cpp` runs this recipe against a delayed answer.

## 3. Limits and rules

- **Small texts, not downloads.** The response is cut off at **4 MB**: a longer answer is a failure, not half a file.
  Use `assets` and the pack for game files.
- **At most 8 requests in flight.** A ninth one is refused (`failed`) until one finishes: send them one after the
  other or in small batches.
- **No cookies, no cache and no saved credentials** are sent or kept (the browser's fetch is called with
  `credentials: "omit"`): the request carries what you put in `headers`, and a `Set-Cookie` of an answer is not stored.
- **No retries.** The engine does not repeat a request; decide in your script what a failure means.
- **The game thread is never blocked.** The request runs on a thread of its own (or the platform's own loop) and the
  answer is delivered at the start of a frame, like every `platform` answer.
- **Not deterministic.** An answer arrives when the network answers, so two runs of the real game differ. Tests use the
  fake ([below](#4-testing-with-the-fake)), which answers what you scripted, on the frame you scripted, and replays
  carry the recorded answers ([section 5](#5-replays)).
- **Secrets.** Anything in your scripts ships with the game. A key in `headers` is not secret from the player.

## 4. Testing with the fake

Tests, `factoria call`, `factoria session`, headless runs and the MCP server never touch the network: they run the
**fake** platform backend, which serves `http.fetch` only with what a test scripted. Nobody scripted an answer: the
request is rejected with code `network` and a hint that names `game.platform.respond`. The hosts are checked exactly as
in the real game, so a missing declaration fails in the test.

```js
import { test, expect, game } from "factoria:test";
import { http } from "factoria";

test("the leaderboard shows the top three", async () => {
  game.platform.reset();
  game.platform.respond("http.fetch", { status: 200, json: { top: ["Ann", "Bob", "Cy"] } });
  const r = await http.fetch("https://api.example.com/scores");
  expect(r.json().top.length).toBe(3);
  expect(game.platform.calls().slice(-1)[0].args.url).toBe("https://api.example.com/scores");
});

test("the game copes with a down server", async () => {
  game.platform.respond("http.fetch", { status: 503, text: "maintenance" });   // an answer
  game.platform.respond("http.fetch", { error: "network", message: "timed out", hint: "Try again." }); // a failure
  // ...
});
```

`game.platform.respond("http.fetch", answer, times = 1)` takes the answer for the next `times` requests, first come
first served:

| `answer` | The request |
|---|---|
| `{ status?, headers?, text?, json? }` | Resolves. Defaults: status 200, no headers, empty text. `json: value` sets `text` to the JSON of the value and adds `content-type: application/json`. Header names become lower case. |
| `{ error: "network", message?, hint? }` | Rejects, like a real failure. |
| `{ result: { status, headers, text } }` | Resolves with exactly that. |

`game.platform.set({ delayFrames: n })` holds the answer for `n` frames (`game.step(n)`), which is how to test the "loading"
state and an answer that arrives in another scene (the stale-answer test above). `game.platform.calls()` is the log
of every request with its `url`, `method`, `headers`, `body` and `timeout` as the engine would send them. `game.platform.reset()`
forgets scripted answers. `platform.state` (the same data as a command: `factoria call platform.state`) tells which
backend answers `http.fetch` (`httpBackend`), why (`httpWhy`) and the declared hosts (`networkHosts`).

The fake does not need the player to be signed in, and with `game.platform.set({ backend: "none" })` it offers no
service at all, `http` included.

To try the real thing against a server on your own machine, declare `"localhost"` and run the game windowed
(`factoria run`, the editor's Play): those runs use the system's HTTP client with the rest of the platform still faked.

## 5. Replays

An input recording (the `input.record` command, and every editor play session, docs/DEBUGGING.md) records what the
server said, so that its replay is the same run without a network. The recording puts each answer in the **`http`** field
of the frame where the request was made, in request order:

```json
{ "frames": { "120": { "http": [
    { "result": { "status": 200, "headers": { "content-type": "application/json" }, "text": "{\"seed\":7}" } },
    { "error": "network", "message": "timed out", "hint": "Try again." } ] } } }
```

`factoria run --headless --input <file>` queues the answers into the fake, and the game's
requests take them in order, whatever frame they happen in. An entry whose `http` is not an array, or an answer the
fake cannot use, is reported in the run's `problems`. A request that was still waiting when the recording ended is not
recorded, nor are the ones made after it; the replay rejects such requests with `network`. See [AI_GUIDE.md](AI_GUIDE.md) and
[CLI.md](CLI.md) for the rest of the replay format.

## 6. Per platform

| Platform | Client | Notes |
|---|---|---|
| Windows | WinHTTP | The system's certificates and proxy. |
| macOS, iOS | `NSURLSession` | The system's certificates and proxy. Plain `http://` to `localhost` works from a development run; an exported iOS app should only call `https://` (App Transport Security). |
| Linux | libcurl, loaded when first needed | The player does **not** link libcurl, so it still starts on a machine without it (the Steam Runtime included). Without `libcurl.so.4` (package `libcurl4` or `libcurl4-openssl-dev`, present on almost every desktop) `platform.has("http")` is false and `http.fetch` rejects with `unavailable` and the reason. |
| Android | `HttpURLConnection` through JNI | The export adds the `INTERNET` permission **only when `network.hosts` is declared** (or you list it in `export.android.permissions`). `PATCH` is sent as `POST` with `X-HTTP-Method-Override: PATCH` (the class refuses the verb), so the server must honour that header. Plain `http://localhost` does not work: Android blocks cleartext. |
| Web | the browser's `fetch` | **CORS applies:** the server has to answer with `Access-Control-Allow-Origin` for the page the game runs in (and handle the `OPTIONS` preflight when you set `headers` or use `PUT`/`PATCH`/`DELETE`). A CORS failure looks like any network failure: the browser gives no detail on purpose. Only headers the server lists in `Access-Control-Expose-Headers` appear in `r.headers`. |

The Windows, Android and web clients are checked by building them in CI; the macOS and libcurl clients run in this
repository's tests against a server on `127.0.0.1` (`engine/platform/tests/http_tests.cpp`), which never leaves the computer.

## 7. Privacy and the stores

A game that calls a server is no longer a game that "sends nothing". What to do:

- **Say so in your privacy policy.** [LEGAL.md](LEGAL.md) has the paragraph to add; the sentence in `network.purpose`
  is a good start. Name the server's operator, what is sent (a player name, a score, only the request itself, the IP
  address that every request reveals) and how long you keep it.
- **Answer the store forms accordingly** ([MOBILE.md](MOBILE.md), "Store privacy forms"): "data collected" is about what
  *your* server receives, the engine itself still collects nothing.
- A **children's game** should not send personal data at all; follow the platform's families rules.
- The engine adds **no analytics, no identifiers and no headers of its own** besides what the system's HTTP client sends
  (for example `User-Agent`, `Accept-Encoding`).

## 8. WebSocket

`websocket.connect(url, options?)` opens a connection that stays open: the server and the game send messages to each other
whenever they like (a chat, a lobby, a live scoreboard, turns of an online game). It lives in the same `network` section:
the host of a `ws://` or `wss://` address must be in `network.hosts`, exactly like `http.fetch` (the same wildcard rules,
the same "declares no network hosts" and "did you mean" errors), and the Android `INTERNET` permission that a declared host
adds covers it.

```js
import { websocket } from "factoria";

const ws = websocket.connect("wss://game.example.com/room/7", { reconnect: true });
ws.on("open", (e) => { if (e.reconnected) ws.send(JSON.stringify({ type: "resync" })); });
ws.on("message", (e) => { if (!e.binary) applyUpdate(JSON.parse(e.data)); });
ws.on("close", (e) => console.log("closed", e.code, e.reason));
ws.send(JSON.stringify({ type: "join", name: "Ann" }));  // false until the connection is open
```

### Which platforms can connect now

**Every player has its WebSocket client.** The shared part (the address checks, the script API, reconnects, the
protocol code, the test server) is the same everywhere; this table says what each platform connects with:

| Platform | Client | Available |
|---|---|---|
| Tests, headless runs, `factoria call`, the MCP server | a scripted in-memory server (`game.websocket`) | yes, nothing touches the network |
| Windows | WinHTTP's WebSocket API, with the system's certificates and proxy (like `http.fetch`) | yes |
| macOS, iOS | Network.framework opens the connection (TCP, TLS with the system's certificates, the system's proxy settings as Network.framework applies them); the engine's own WebSocket protocol code does the rest | yes (see "On macOS and iOS" below) |
| Linux | libcurl, loaded when first needed (like `http.fetch`), opens the connection (the proxy of the environment, TCP, TLS with the system's certificates); the engine's own WebSocket protocol code does the rest | yes, with any libcurl from 7.45 (with or without its own WebSocket support). Without `libcurl.so.4` (or the Steam Runtime's `libcurl-gnutls.so.4`) `websocket.supported` is false and `websocket.unsupportedReason` says why |
| Android | the engine's own WebSocket protocol code over a socket: `wss://` through Java's `SSLSocket` (JNI; the system's certificates, and the certificate must name the host), `ws://` (localhost only) over a plain socket | yes; built by CI, not yet run on a device. It needs the `INTERNET` permission, which the export adds when `network.hosts` is declared; without it the connection fails with an error that says so. Destroying an open `wss://` connection (a scene change) closes the socket without a close frame, so the server sees 1006 |
| Web | the browser's `WebSocket` | yes (see below) |

On every platform, a `ws.close()` that the server does not answer with its own close frame within 5 seconds ends with an
`"error"` event whose message says that the server did not answer the close (the wording differs a little between
platforms), then `"close"` with code 1006 and `wasClean` false.

**On the web** the player uses the browser's own `WebSocket`, so a few things differ. There is **no CORS** for WebSocket: the
browser always sends the page's `Origin` header and it is the *server's* policy to accept or refuse it (a refusal is a 403
the page cannot see, so it looks like any failed connection). A page loaded over `https://` may only open `wss://`
addresses (mixed content; some browsers exempt `localhost`). `headers` is an error at `connect` (the browser cannot send
any). The browser gives no reason for a failed connection, so the `"error"` event lists what to check; `httpStatus` is
always 0. A message longer than `maxMessageBytes` is checked when the whole message has arrived (the browser buffers it
first), and the server is closed with 1000 and the reason "message too big", because the browser cannot send 1009 (it only
sends 1000 and 3000 to 4999). A connection that a scene change destroys closes with no status code (the browser cannot send 1001), and `ws.close()`
without a code sends 1000. The timeout and the 5 s wait for the server's answer to `close()` are the engine's own timers.

**On macOS and iOS** Network.framework opens the connection (the name lookup, TCP and, for `wss://`, TLS with the
system's certificates) and the engine's own WebSocket protocol code does the rest, as on Linux and Android: the handshake,
the messages, the answers to the server's pings (it sends no pings of its own), the `maxMessageBytes` check as the bytes
arrive, and the closing handshake. So `ws.close()` sends a close frame with the code and reason you gave (no code at all
when you gave none) and the `"close"` event comes with the server's answer (or the 5 second error described above). A
redirect answer to the upgrade is not followed: it
ends the attempt with an `"error"` whose `httpStatus` is the redirect's. The system's proxy settings (an HTTP or SOCKS
proxy, a PAC file) are Network.framework's to apply: the engine leaves its default (proxies used) and does not set a proxy
of its own, so a network that only lets connections out through a proxy needs the proxy in System Settings.
Network.framework is not under App Transport Security, so the `ws://` addresses the address rules allow (your own
computer) work in an exported iOS app too. On iOS the system suspends a game that goes to the background, and its
connections usually break with it: the game then gets the `"error"` and `"close"` 1006 events (and `reconnect` takes
over, if you asked for it), at the latest when it comes back.

Where there is no client (a Linux machine without a libcurl from 7.45), `websocket.supported` is `false` and
`websocket.unsupportedReason` says why. `websocket.connect` still returns a connection after the usual
address checks: it fails at the next frame with an `"error"` event and a `"close"` event with code 1006, and does not
reconnect, so a game written today runs everywhere and simply stays offline. Check `websocket.supported` to show an
"online play not available" message instead.

On Windows, WinHTTP does part of the protocol itself, which shows in a few places:

- It answers the server's pings, and sends keep-alive frames of its own every 30 seconds while a connection is open.
- A server whose handshake answer has a wrong `Sec-WebSocket-Accept` may fail with a message that does not name the
  header.
- A header value that is not plain ASCII is refused by `websocket.connect` (WinHTTP would send it as 8-bit text, not as
  the UTF-8 the game wrote): percent-encode it (`encodeURIComponent`) or send it in the first message instead.
- A connection destroyed (a scene change) while it is in the middle of sending a message closes with code 1001 once
  that message has gone out. A server that stops reading gets no close frame: after 5 seconds the connection is cut.

### Addresses and options

- **`wss://` only**, plain `ws://` just for `localhost`, `127.x.x.x` and `[::1]` (a server on your own computer, which must
  be listed in `network.hosts` too). No user name or password in the URL, at most 2048 characters, no spaces. The host must
  be declared. A mistake in the call throws at once, with what to change.
- **At most 32 connections** at once.

| Option | Meaning |
|---|---|
| `protocols` | An array of subprotocol names to offer (`["chat.v1"]`); the server's choice is `ws.protocol` and `e.protocol` of `"open"`. |
| `headers` | Extra handshake headers, an object of strings, no line breaks. `Host`, `Upgrade`, `Connection` and `Sec-*` are set by the system and refused. **The browser's `WebSocket` cannot send headers**: a game for the web puts what the server needs in the URL or in the first message. |
| `timeout` | Seconds for connecting and the handshake together, above 0, at most 120, default 15. |
| `maxMessageBytes` | The longest message in either direction, default 4 MB, at most 64 MB. A longer incoming message fails the connection: `error`, then `close` with code 1006 (the server is told 1009). |
| `reconnect` | `true` or `{ maxAttempts: 10, minDelay: 1, maxDelay: 30, factor: 2, jitter: 0.25 }` (what is left out takes these). Default: never. |

### Events

The events of a connection arrive **at the start of an engine frame**, in order, never in the middle of a script and never
from another thread. `ws.on(event, fn)` returns a function that removes the handler; an unknown event name throws with a
"did you mean". A handler that throws is reported as a script error and does not stop the others.

| Event | Payload | When |
|---|---|---|
| `"open"` | `{ protocol, reconnected }` | The handshake is done. Again after every reconnect (`reconnected: true`). |
| `"message"` | `{ data, binary }` | One whole message: a string for text, an `ArrayBuffer` for binary. |
| `"error"` | `{ message, hint, httpStatus }` | It could not connect, the server refused the handshake (`httpStatus` 403, 404...), the stream broke. Always followed by `"close"`. |
| `"close"` | `{ code, reason, wasClean, willReconnect }` | The end. Code 1006 means no closing handshake happened. |
| `"reconnecting"` | `{ attempt, delay }` | After a `"close"` with `willReconnect: true`: the next attempt in `delay` seconds. |

`ws.send(data)` takes a string (a text message), an `ArrayBuffer`, a typed array or a `DataView` (a binary message; a view sends the bytes it shows, from its `byteOffset` for its `byteLength`) and returns `true`
when queued, `false` when the connection is not open (nothing is kept for later; this is how a game notices it is between
two connections). Data of another type and a message over `maxMessageBytes` throw. `ws.close(code = 1000, reason = "")`
starts the closing handshake (`code` 1000 or 3000 to 4999, `reason` at most 123 bytes); the `"close"` event follows.
`ws.readyState` is `"connecting"` (also while waiting to reconnect), `"open"`, `"closing"` or `"closed"`. `ws.close()` while
it is still `"connecting"` gives `"closing"` at once, and `"closed"` when the `"error"` (which says `close()` came before the
connection opened) and the `"close"` event (code 1006) arrive; whenever you read the `"close"` event, `readyState` is already
`"closed"`. A message of any size `maxMessageBytes` allows (up to 64 MB) arrives: the engine keeps at least twice that unread
before it ends a game that does not read its messages (`"close"` 1008).

### Reconnects

With `reconnect`, a connection that ends without you calling `close()` is opened again: the wait before attempt *n* is
`min(maxDelay, minDelay * factor^(n-1))` seconds, moved by up to `jitter` of itself so that a thousand players do not come
back in the same second. The jitter is a pseudo-random sequence seeded by the URL and the number of the connection, so a
test (and a replay) sees the same delays on every run; the wait is counted in engine time, not wall time. After
`maxAttempts` failures in a row the connection closes for good (`willReconnect: false`); the count starts again whenever a
connection opens. `ws.close()`, also inside the `"close"` handler, stops the reconnecting. A platform that has no client never
reconnects.

### The scene owns its connections

**A scene change closes every connection, with no event**: `readyState` becomes `"closed"` and nothing the old
scene's server sends is delivered, so a handler never runs for a scene that is gone. Open the connections of a scene
in that scene (or reopen them in `onStart`). The same happens when the scripts are unloaded. A game that wants one
connection for the whole run keeps the address and calls `websocket.connect` again after each scene load. Replays do not
record WebSocket traffic: a replayed run of a game that talks to a server talks to it again.

### Testing

Tests and headless runs use a scripted in-memory server: every `websocket.connect` meets it, and `game.websocket` plays the
server's side. The events of what you do arrive at the next `game.step()`.

```js
import { test, expect, game } from "factoria:test";
import { websocket } from "factoria";

test("the lobby shows the players the server lists", () => {
  game.websocket.reset();
  const ws = websocket.connect("wss://game.example.com/lobby");
  let players = [];
  ws.on("message", (e) => { players = JSON.parse(e.data).players; });
  game.step();                                                    // the connection opens
  game.websocket.send(0, JSON.stringify({ players: ["Ann", "Bob"] }));
  game.step();
  expect(players).toEqual(["Ann", "Bob"]);
  expect(game.websocket.connections()[0].received).toEqual([]);   // what the game sent
});
```

| Call | What it does |
|---|---|
| `connections()` | Every connection made, in order, reconnects included: `{ index, url, protocols, headers, open, closed, closedByGame, closeCode, closeReason, received }`. |
| `send(i, data)`, `close(i, code, reason)` | The server sends a message, or closes cleanly. |
| `drop(i)`, `refuse(i, message, httpStatus)` | The connection breaks (`"error"`, then `"close"` 1006), or the handshake is refused. |
| `autoAccept(false)`, `accept(i, protocol)` | New connections wait until you accept them. |
| `refuseNext(count)` | The next `count` attempts fail like an unreachable server: how to test a reconnect. |
| `autoCloseReply(i, false)` | The server does not answer the game's `close()`: the game stays `"closing"`. |
| `reset()` | Closes the game's connections without events and forgets the server's side. Call it at the start of a test that counts connections. |

The tests of the engine itself also run the protocol code against a real server on `127.0.0.1` (`engine/platform/tests/`);
that plain `ws://` client over a POSIX socket is a tool for those tests, and what Android opens its `ws://` addresses with.

## Troubleshooting

| Message | Fix |
|---|---|
| `declares no network hosts` | Add the `network` section of [section 1](#1-declare-the-hosts) to `factoria.json`. |
| `host ... is not declared` | Add the host (or `*.domain`) to `network.hosts`; check the "did you mean". |
| `plain http:// ... only for localhost` | Use `https://`, or declare `localhost`/`127.0.0.1` for a server on your machine. |
| `http.fetch ... failed` with code `network` in a test | Nobody scripted an answer: `game.platform.respond("http.fetch", ...)` first. |
| `declares no network hosts` for `websocket.connect` | The same section serves both: declare the host of the `wss://` address. |
| `unavailable` | The platform cannot send requests (Linux without libcurl) or the backend is `none`. Check `platform.has("http")` and let the game carry on offline. |
| Works on desktop, fails in the web build | `http.fetch`: CORS, the server must allow the page's origin. `websocket`: no CORS, but the browser sends the page's `Origin` and the server must accept it; an `https://` page needs `wss://`; the browser's `WebSocket` cannot send `headers`: put what the server needs in the URL or the first message. |
| `websocket.supported` is false | This machine has no WebSocket client: Linux without libcurl 7.45 or newer; `websocket.unsupportedReason` says why ([section 8](#8-websocket)). |
| Works on desktop, fails on Android | The `INTERNET` permission (declare `network.hosts`), or plain `http://` (Android blocks it). |
