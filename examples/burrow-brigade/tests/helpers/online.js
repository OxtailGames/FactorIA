// Helpers for the P5 tests: a fake game server behind scripts/game/online.js (no test touches a network), a clean store layer and
// the services started the way a scene starts them.
import { game, beforeEach, afterEach } from "factoria:test";
import * as online from "../../scripts/game/online.js";
import * as services from "../../scripts/game/services.js";
import * as balance from "../../scripts/game/balance.js";
import * as events from "../../scripts/game/events.js";
import { storage } from "factoria";
import { startRun, run } from "../../scripts/game/run_state.js";
import * as players from "../../scripts/game/players.js";

/**
 * Puts a fake server behind online.js. `routes` maps a path to what GET answers (an object), or to a function(method, body) that
 * returns the answer or throws. A path with no route answers like a server that is down.
 * @param {Record<string, any>} routes
 */
export function fakeServer(routes = {}) {
  /** @type {Array<{method: string, path: string, body: any}>} */
  const calls = [];
  const transport = {
    name: "fake",
    request(method, path, body) {
      calls.push({ method, path, body });
      const r = routes[path];
      if (r === undefined) {
        const e = /** @type {any} */ (new Error(`the fake server has no route ${path}`));
        e.code = "network";
        return Promise.reject(e);
      }
      try {
        return Promise.resolve(typeof r === "function" ? r(method, body) : r);
      } catch (e) {
        return Promise.reject(e);
      }
    },
  };
  const old = online.setTransport(transport);
  return { calls, restore: () => online.setTransport(old) };
}

/**
 * Each test starts with a clean bus, no players, the offline transport, the shipped balance numbers, a fresh fake store and the
 * services started. Returns nothing: import what the test needs.
 */
export function freshOnline() {
  beforeEach(() => {
    players.clear();
    events.clear();
    services.stop();
    storage.clear();
    game.platform.reset();
    game.setDate("2026-10-25");
    startRun({ seed: 7, stratum: 0, floor: 1 });
    /** @type {any} */ (run).mode = "normal";
    /** @type {any} */ (run).dailyKey = null;
    services.start();
  });
  afterEach(() => {
    services.stop();
    balance.reset();
    online.setTransport(online.offlineTransport);
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
