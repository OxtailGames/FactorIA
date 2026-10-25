// @ts-check
// The upgrade shop of the camp: what it sells, what each level costs and the one function that buys. The shop sells six
// things, the six fields of `run.upgrades` (BASE_UPGRADES in run_state.js), so the miner, the lamp and the lights read the
// bought values with no change: picks (tier and speed), lamps (oil and radius), boots (walk speed) and torches.
//
// An item is a ladder of levels. Level 0 is the starting value (free); level n costs `levels[n].cost` and sets the field to
// `levels[n].value`. Prices rise with every level of an item. The level an upgrade is at is read from the value in
// `run.upgrades`, so a save only stores the values.
//
//   SHOP                      the items, in the order the camp lists them
//   levelOf(id)               the level now owned (0 = the starting one)
//   offer(id)                 { level, value, cost } of the next level, or null at the maximum
//   buy(id)                   pays and applies the next level: { ok: true, level, cost, cash } or { ok: false, reason, message, hint }
//   upgradesAt(levels)        the `run.upgrades` object for a map of levels (tests, saves written by hand)
import { run, BASE_UPGRADES, addCash } from "./run_state.js";
import * as events from "./events.js";
import { didYouMean } from "./suggest.js";

/**
 * @typedef {object} Level
 * @property {number} value  What the `run.upgrades` field becomes.
 * @property {number} cost   Cash to reach this level (0 for the starting level).
 */

/**
 * @type {Readonly<Record<string, {levels: Level[], unit: string}>>}
 * `unit` names the string of the locale (`camp.unit.<unit>`) that writes a value for the player.
 */
export const SHOP = Object.freeze({
  pickTier: { unit: "tier", levels: [{ value: 0, cost: 0 }, { value: 1, cost: 60 }, { value: 2, cost: 180 }] },
  pickSpeed: { unit: "times", levels: [{ value: 1, cost: 0 }, { value: 1.25, cost: 30 }, { value: 1.5, cost: 70 }, { value: 1.8, cost: 130 }, { value: 2.2, cost: 220 }] },
  lampOil: { unit: "seconds", levels: [{ value: 120, cost: 0 }, { value: 150, cost: 25 }, { value: 185, cost: 60 }, { value: 225, cost: 110 }, { value: 270, cost: 180 }] },
  lampRadius: { unit: "times", levels: [{ value: 1, cost: 0 }, { value: 1.15, cost: 30 }, { value: 1.3, cost: 80 }, { value: 1.5, cost: 150 }] },
  walkSpeed: { unit: "times", levels: [{ value: 1, cost: 0 }, { value: 1.1, cost: 25 }, { value: 1.2, cost: 60 }, { value: 1.35, cost: 120 }] },
  torches: { unit: "count", levels: [{ value: 6, cost: 0 }, { value: 8, cost: 20 }, { value: 10, cost: 50 }, { value: 13, cost: 100 }] },
});

/** The item ids in the order of the camp's list. */
export const ITEMS = Object.freeze(Object.keys(SHOP));

/** Throws for an id the shop does not sell, with a "did you mean". */
function item(id) {
  const entry = SHOP[id];
  if (!entry) throw new Error(`the camp does not sell '${id}'.${didYouMean(id, ITEMS)} It sells: ${ITEMS.join(", ")} (scripts/game/upgrades.js).`);
  return entry;
}

/** The highest level of an item. */
export function maxLevel(id) {
  return item(id).levels.length - 1;
}

/**
 * The level an item is at, read from the value in `upgrades` (the highest level whose value is not above it).
 * @param {string} id
 * @param {Record<string, number>} [upgrades]  Default: the run's.
 */
export function levelOf(id, upgrades = run.upgrades) {
  const levels = item(id).levels;
  const value = upgrades[id] ?? BASE_UPGRADES[id];
  let level = 0;
  for (let i = 0; i < levels.length; i++) if (levels[i].value <= value) level = i;
  return level;
}

/** The next level of an item: `{ level, value, cost }`, or null when it is at the maximum. */
export function offer(id) {
  const levels = item(id).levels;
  const next = levelOf(id) + 1;
  return next < levels.length ? { level: next, value: levels[next].value, cost: levels[next].cost } : null;
}

/** The `run.upgrades` object of a map of levels, e.g. `{ pickTier: 1, torches: 2 }`; items not named stay at level 0. */
export function upgradesAt(levels = {}) {
  const out = { ...BASE_UPGRADES };
  for (const [id, level] of Object.entries(levels)) {
    const list = item(id).levels;
    if (!Number.isInteger(level) || level < 0 || level >= list.length) throw new Error(`'${id}' has levels 0 to ${list.length - 1}, not ${level}.`);
    out[id] = list[level].value;
  }
  return out;
}

/**
 * Buys the next level of an item from the banked cash. Refuses (and changes nothing) at the maximum or when the cash is
 * short; the answer says why and what to do, so the camp can show it. Emits `cashChanged` then `upgradeBought`.
 * @param {string} id
 * @returns {{ok: true, upgrade: string, level: number, cost: number, cash: number} | {ok: false, reason: "max"|"cash", message: string, hint: string, need?: number, have?: number}}
 */
export function buy(id) {
  item(id);
  const next = offer(id);
  if (!next) return { ok: false, reason: "max", message: `'${id}' is already at its maximum level (${maxLevel(id)})`, hint: "pick another upgrade" };
  if (run.cash < next.cost) {
    const need = next.cost - run.cash;
    return { ok: false, reason: "cash", message: `'${id}' level ${next.level} costs ${next.cost} and the camp holds ${run.cash}`, hint: `bring ${need} more cash up from the mine`, need, have: run.cash };
  }
  addCash(-next.cost, "upgrade");
  run.upgrades = { ...run.upgrades, [id]: next.value };
  events.emit("upgradeBought", { upgrade: id, level: next.level, cost: next.cost, cash: run.cash });
  return { ok: true, upgrade: id, level: next.level, cost: next.cost, cash: run.cash };
}
