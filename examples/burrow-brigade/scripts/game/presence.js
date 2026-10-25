// @ts-check
// Rich presence: what friends see under the player's name ("Digging in the Crystal Caves, floor 2 (3 miners)"). The words are in
// the locale (locales/<lang>.json "presence"), so a translation changes what friends see in that language; `data` carries the
// same facts as plain strings for a store that builds its own line from tokens (Steam: steam_display plus the keys below).
//
//   describe(state)   { text, data } for a state, without sending it:
//       { kind: "menu" }                                  presence.menu
//       { kind: "boards" }                                presence.boards
//       { kind: "shift", stratum, floor, players }        presence.shift (plural by the miners)
//       { kind: "boss", players }                         presence.boss  (plural)
//       { kind: "results", shift, outcome }               presence.results
//   set(state)        sends it when it differs from the last one sent. Best effort: a store without presence is skipped.
//   start() / stop()  follow the events (shift started, the Mole King woke, shift ended, a miner joined or left).
//   idle()            resolves when the sends so far are done (tests).
//   current()         the last state sent.
//
// data keys (strings): steam_display ("#Menu", "#Boards", "#Digging", "#Boss", "#Results": define them in the Steamworks rich
// presence localization file), stratum (its name in the current language), floor, miners.
import { platform, i18n } from "factoria";
import * as events from "./events.js";
import * as players from "./players.js";
import { stratumInfo } from "./generator.js";

/** @type {Array<() => void>} */
let unsubscribers = [];
let chain = Promise.resolve();
let lastText = /** @type {string|null} */ (null);
let lastState = /** @type {any} */ (null);
/** The shift being played: what a change of the miners re-describes. */
let shift = /** @type {{stratum: number, floor: number, boss: boolean}|null} */ (null);

export async function idle() {
  for (;;) {
    const c = chain;
    await c;
    if (c === chain) return;
  }
}

export function current() {
  return lastState;
}

/**
 * The text and the data of a state.
 * @param {any} state
 * @returns {{text: string, data: Record<string, string>}}
 */
export function describe(state) {
  switch (state.kind) {
    case "shift": {
      const stratum = i18n.t(stratumInfo(state.stratum).name);
      return {
        text: i18n.t("presence.shift", { stratum, floor: state.floor, count: state.players }),
        data: { steam_display: "#Digging", stratum, floor: String(state.floor), miners: String(state.players) },
      };
    }
    case "boss":
      return { text: i18n.t("presence.boss", { count: state.players }), data: { steam_display: "#Boss", miners: String(state.players) } };
    case "results":
      return { text: i18n.t(state.outcome === "lift" ? "presence.resultsLift" : "presence.resultsDown", { shift: state.shift }), data: { steam_display: "#Results" } };
    case "boards":
      return { text: i18n.t("presence.boards"), data: { steam_display: "#Boards" } };
    default:
      return { text: i18n.t("presence.menu"), data: { steam_display: "#Menu" } };
  }
}

/** Sends a state when its text changed. @param {any} state */
export function set(state) {
  const { text, data } = describe(state);
  lastState = state;
  if (text === lastText || !platform.has("presence")) return chain;
  lastText = text;
  chain = chain
    .then(() => platform.presence.set(text, data))
    .catch((e) => console.warn(`presence: not sent: ${e && e.message ? e.message : e}`));
  return chain;
}

/** Back to the unsent state (a new language changes the text, so the next `set` always goes). */
export function forget() {
  lastText = null;
}

function describeShift() {
  if (!shift) return;
  const n = Math.max(1, players.count());
  set(shift.boss ? { kind: "boss", players: n } : { kind: "shift", stratum: shift.stratum, floor: shift.floor, players: n });
}

export function start() {
  if (unsubscribers.length) return;
  unsubscribers = [
    events.keep("shiftStarted", (d) => {
      shift = { stratum: d.stratum, floor: d.floor, boss: false };
      set({ kind: "shift", stratum: d.stratum, floor: d.floor, players: d.players ?? 1 });
    }),
    events.keep("bossStarted", () => {
      if (shift) shift.boss = true;
      describeShift();
    }),
    events.keep("playerAdded", describeShift),
    events.keep("playerRemoved", describeShift),
    events.keep("shiftEnded", (d) => {
      shift = null;
      set({ kind: "results", shift: d.shiftNumber, outcome: d.outcome });
    }),
  ];
}

export function stop() {
  for (const off of unsubscribers) off();
  unsubscribers = [];
  shift = null;
  lastText = null;
  lastState = null;
}
