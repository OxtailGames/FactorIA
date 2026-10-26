// @ts-check
// The seam between the game and its own server: the engine's `remoteConfig` (docs/ANALYTICS.md). ONE JSON file on the server
// holds everything the game reads from it, and the engine caches the last good copy, so the news and the balance values still
// work for a player who starts the game offline:
//
//   { "balance": { "beetle.hp": 4, "hazards.drownTime": 5 },
//     "news": { "version": 1, "items": [ { "id": "patch-2", "date": "2026-10-20", "title": "Patch 0.2", "body": "..." } ] } }
//
// The address is `remoteConfig.url` in factoria.json, a placeholder until the game has a server (README, "Server addresses").
// What the file holds is untrusted: balance.js and news.js check every value before they use it. Tests script the server with
// `game.platform.respond("http.fetch", { json: {...} })` (tests/helpers/online.js).
import { remoteConfig } from "factoria";

/** Waits for the first answer of the server (at most 3 seconds); never rejects. Resolves "remote", "cache" or "default". */
export function ready() {
  return remoteConfig.ready();
}

/** One section of the file (`"balance"`, `"news"`); `fallback` when the server has none or it has another type. */
export function section(key, fallback) {
  return remoteConfig.get(key, fallback);
}

/** Where the values come from now: "remote" (this run), "cache" (an earlier run) or "default". */
export function source() {
  return remoteConfig.source();
}
