// Helpers for the P5 tests: a fake game server behind the engine's http.fetch (no test touches a network), a clean store layer and
// the services started the way a scene starts them.
import { game, beforeEach, afterEach } from "factoria:test";
import * as services from "../../scripts/game/services.js";
import * as balance from "../../scripts/game/balance.js";
import * as events from "../../scripts/game/events.js";
import { storage } from "factoria";
import { startRun, run } from "../../scripts/game/run_state.js";
import * as players from "../../scripts/game/players.js";

/** Where factoria.json sends the statistics and where it reads the config file (placeholders: README, "Server addresses"). */
export const EVENTS_URL = "https://burrow-brigade.example/v1/events";
export const CONFIG_URL = "https://burrow-brigade.example/v1/config.json";

/**
 * The server's answer to the config fetch, the first `http.fetch` of a run: a file (an object), or null for a server that is
 * down. Call it BEFORE anything fetches (the title does at its first frame); the answers go out first in, first out.
 * @param {any} file
 */
export function serveConfig(file) {
  game.platform.respond("http.fetch", file === null ? { error: "network", message: "the server is down" } : { json: file });
}

/** The server accepts the statistics batches that follow: `status` for the next `times` requests. */
export function serveEvents(status = 204, times = 50) {
  game.platform.respond("http.fetch", { status }, times);
}

/** The requests the game made to its server: `{ method, url, body }` (the body parsed when it is JSON). */
export function requests() {
  return game.platform.calls().filter((c) => c.method === "http.fetch").map((c) => ({
    method: c.args.method ?? "GET",
    url: c.args.url,
    body: typeof c.args.body === "string" && c.args.body ? JSON.parse(c.args.body) : null,
  }));
}

/** The batches of statistics posted so far. */
export const posts = () => requests().filter((r) => r.url === EVENTS_URL);

/**
 * Each test starts with a clean bus, no players, an offline server (nothing scripted), the shipped balance numbers, a fresh fake store and the
 * services started. Returns nothing: import what the test needs.
 */
export function freshOnline() {
  beforeEach(() => {
    players.clear();
    events.clear();
    services.stop();
    storage.clear();
    game.setDate("2026-10-25"); // the first one starts the title scene, which asks the server for its config
    game.platform.reset();
    game.analytics.restart();
    game.remoteConfig.restart();
    startRun({ seed: 7, stratum: 0, floor: 1 });
    /** @type {any} */ (run).mode = "normal";
    /** @type {any} */ (run).dailyKey = null;
    services.start();
  });
  afterEach(() => {
    services.stop();
    balance.reset();
  });
}

/** One shift's worth of events: the shift starts, `body` happens, the shift ends. */
export function shift({ stratum = 0, floor = 1, players: n = 1, outcome = "lift", banked = 100, speed = 1 } = {}, body = () => {}) {
  run.shiftNumber += 1; // what beginShift does before the shift scene says shiftStarted
  const shiftNumber = run.shiftNumber;
  events.emit("shiftStarted", { seed: 7, stratum, floor, hash: "x", players: n, speed });
  body();
  events.emit("shiftEnded", { outcome, ore: {}, oreCount: 0, value: banked, banked, time: 90, molesRescued: 0, molesTotal: 0, shiftNumber, stratum, floor });
}
