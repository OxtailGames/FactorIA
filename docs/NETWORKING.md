# Networking: `http.fetch`

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
| [privacy](#7-privacy-and-the-stores).

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

## Troubleshooting

| Message | Fix |
|---|---|
| `declares no network hosts` | Add the `network` section of [section 1](#1-declare-the-hosts) to `factoria.json`. |
| `host ... is not declared` | Add the host (or `*.domain`) to `network.hosts`; check the "did you mean". |
| `plain http:// ... only for localhost` | Use `https://`, or declare `localhost`/`127.0.0.1` for a server on your machine. |
| `http.fetch ... failed` with code `network` in a test | Nobody scripted an answer: `game.platform.respond("http.fetch", ...)` first. |
| `unavailable` | The platform cannot send requests (Linux without libcurl) or the backend is `none`. Check `platform.has("http")` and let the game carry on offline. |
| Works on desktop, fails in the web build | CORS: the server must allow the page's origin. |
| Works on desktop, fails on Android | The `INTERNET` permission (declare `network.hosts`), or plain `http://` (Android blocks it). |
