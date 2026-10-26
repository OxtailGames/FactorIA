// @ts-check
// Each player's own controls. A player (a seat, P1 to P4) has the engine's per-player actions (`input.player(seat)`): the project's
// actions (factoria.json input.actions) read from the player's own device, with bindings of its own for its keyboard and another
// list for its gamepad. This module is the game's side of it: the six actions of a miner (left, right, up, down, dig, torch) as
// the Options page lists them, "one key does one thing" when a player rebinds, and saving what a seat rebound
// (settings.playerBindings, by seat) so it comes back at the next start.
//
// What the engine does: the defaults of every player (the key scheme's own keys from factoria.json input.schemes, or the pad's
// bindings of input.actions), which device is read (players.js hands it over when a player joins), and the rebinding. A binding
// is a key name ("Space") or a gamepad name ("GamepadA", "GamepadLeftStickLeft"), the same names `input.lastPressed()` returns.
import { input } from "factoria";
import * as settings from "../settings.js";
import { MAX_PLAYERS } from "./players.js";

/** The actions of a miner, in the order the Options page lists them. */
export const ACTIONS = Object.freeze(["left", "right", "up", "down", "dig", "torch"]);

/** The project action (factoria.json input.actions) behind each action of a miner. */
const PROJECT_ACTION = Object.freeze({ left: "move_left", right: "move_right", up: "move_up", down: "move_down", dig: "dig", torch: "torch" });

/** @typedef {"keys"|"pad"} Family */
/** @typedef {Record<string, string[]>} BindingSet */

/** The bindings of a seat for one family, by action of a miner: the player's own where it rebound, the defaults elsewhere. */
export function bindingsFor(seat, family) {
  const player = input.player(seat);
  return Object.fromEntries(ACTIONS.map((a) => [a, player.bindings(PROJECT_ACTION[a], family)]));
}

/** Saves what the engine says seat `seat` rebound (nothing saved for a seat on its defaults). */
function persist(seat) {
  const s = settings.load();
  const rebound = input.player(seat).export();
  if (Object.keys(rebound.keys ?? {}).length + Object.keys(rebound.pad ?? {}).length === 0) delete s.playerBindings[String(seat)];
  else s.playerBindings[String(seat)] = rebound;
  settings.save(s);
}

/**
 * Makes `names` the bindings of an action for a seat and a family, and saves them. The same names are taken away from the
 * seat's other actions of that family, so one key never does two things. A name the engine does not accept (a key name for
 * the pad list, a "Gamepad..." one for the keyboard list, a misspelt key) throws its error with the suggestion, and nothing changes.
 * @param {number} seat
 * @param {Family} family
 * @param {string} action  One of ACTIONS.
 * @param {string[]} names
 */
export function rebind(seat, family, action, names) {
  if (!ACTIONS.includes(action)) throw new Error(`controls.rebind: unknown action '${action}'. The actions are ${ACTIONS.join(", ")}.`);
  const player = input.player(seat);
  player.rebind(PROJECT_ACTION[action], names, family); // all or nothing: throws before anything changes
  for (const other of ACTIONS) {
    if (other === action) continue;
    const had = player.bindings(PROJECT_ACTION[other], family);
    const kept = had.filter((n) => !names.some((m) => m.toLowerCase() === n.toLowerCase()));
    if (kept.length !== had.length) player.rebind(PROJECT_ACTION[other], kept, family);
  }
  persist(seat);
}

/** Back to the defaults for one seat (both families). */
export function reset(seat) {
  input.player(seat).reset();
  persist(seat);
}

/** Back to the defaults for everybody. */
export function resetAll() {
  for (let seat = 0; seat < MAX_PLAYERS; seat++) input.player(seat).reset();
  const s = settings.load();
  s.playerBindings = {};
  settings.save(s);
}

/** The names of the actions of a miner before the engine kept the bindings: the saved controls of an older version use them. */
const OLD_ACTION = Object.freeze({ left: "move_left", right: "move_right", up: "move_up", down: "move_down" });

/**
 * Puts the saved controls of every seat into the engine (settings.apply calls it once per run). A seat saved by an older version
 * used the names left/right/up/down for its actions; they are the project's move_left... now, so those are renamed (and the
 * result saved again, with a note in the log). An entry the engine refuses (an action or key that does not exist any more) is
 * skipped with a warning; the rest applies.
 * @param {ReturnType<typeof settings.load>} [s]
 */
export function applySaved(s = settings.load()) {
  let renamed = false;
  /** @type {Record<string, any>} */
  const migrated = {};
  for (const [seat, saved] of Object.entries(s.playerBindings)) {
    const n = Number(seat);
    if (!Number.isInteger(n) || n < 0 || n >= MAX_PLAYERS || !saved || typeof saved !== "object") continue;
    /** @type {Record<string, BindingSet>} */
    const data = {};
    for (const family of /** @type {Family[]} */ (["keys", "pad"])) {
      const list = saved[family];
      if (!list || typeof list !== "object") continue;
      data[family] = {};
      for (const [action, names] of Object.entries(list)) {
        const name = OLD_ACTION[action] ?? action;
        if (name !== action) renamed = true;
        data[family][name] = names;
      }
    }
    migrated[seat] = data;
    for (const problem of input.player(n).import(data)) console.warn(`controls: the saved controls of player ${n + 1}: ${problem}`);
  }
  if (renamed) {
    console.log("controls: the saved controls of an older version were moved to the engine's per-player actions (move_left, move_right...).");
    const now = settings.load();
    now.playerBindings = migrated;
    settings.save(now);
  }
}

/** What a player sees for an action: the binding names for its family, as buttons ("Space / J", "A / X"). */
export function label(seat, family, action, padIndex = 0) {
  const names = input.player(seat).bindings(PROJECT_ACTION[action], family);
  if (!names || names.length === 0) return "-";
  return names.map((n) => input.buttonName(n, padIndex)).join(" / ");
}
