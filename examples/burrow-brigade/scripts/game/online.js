// @ts-check
// The seam between the game and its own server. FactorIA gives a game script no way to open a connection (no HTTP, no sockets:
// ENGINE_FEEDBACK.json), so everything that wants a server (the news panel, the remote balance values, the opt-in analytics)
// talks to a TRANSPORT, an object with one method, and nothing else in the game knows how the bytes travel:
//
//   transport = { name, request(method, path, body) -> Promise<json> }       // rejects with an Error that has .code
//
// The shipped transport is `offlineTransport`: every request rejects with the code "offline", so every feature falls back to
// what it has without a server (no news, the built-in balance, no analytics). When the engine offers a network call (or a native
// plugin brings one), a new transport is the only code to write: `setTransport(...)` at startup. Tests install a fake one
// (tests/helpers/online.js) and read what the game sent, so no test touches a network.
/** The game's server: the paths below are resolved against it by a real transport. A placeholder until the shop exists (P7). */
export const SERVER = "https://burrow-brigade.example";
/** What each feature asks for. */
export const PATHS = Object.freeze({
  news: "/v1/news.json",
  balance: "/v1/balance.json",
  analytics: "/v1/events",
});

/** The transport used when none was set: always offline. */
export const offlineTransport = Object.freeze({
  name: "offline",
  request() {
    const e = /** @type {Error & {code?: string, hint?: string}} */ (new Error("the game has no network connection (FactorIA scripts cannot open one yet)"));
    e.code = "offline";
    e.hint = "Install a transport with online.setTransport() once the engine can make requests.";
    return Promise.reject(e);
  },
});

/** @type {{name: string, request: (method: string, path: string, body?: any) => Promise<any>}} */
let transport = offlineTransport;

/** Installs the transport. Returns the one it replaces (a test puts it back). */
export function setTransport(t) {
  if (!t || typeof t.request !== "function") throw new Error("online.setTransport: a transport is { name, request(method, path, body) -> Promise }.");
  const old = transport;
  transport = t;
  return old;
}

/** The transport in use. */
export function getTransport() {
  return transport;
}

/** True when the game can reach its server (the transport is not the offline one). */
export function isOnline() {
  return transport !== offlineTransport;
}

/**
 * One request to the game's server. Never throws; resolves `{ ok: true, data }` or `{ ok: false, code, message }`.
 * @param {"GET"|"POST"} method
 * @param {string} path  one of PATHS
 * @param {any} [body]
 * @returns {Promise<{ok: true, data: any} | {ok: false, code: string, message: string}>}
 */
export async function request(method, path, body) {
  try {
    const data = await transport.request(method, path, body);
    return { ok: true, data };
  } catch (e) {
    const err = /** @type {any} */ (e);
    return { ok: false, code: String(err?.code ?? "failed"), message: String(err?.message ?? err) };
  }
}
