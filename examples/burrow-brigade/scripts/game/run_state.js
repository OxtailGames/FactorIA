// @ts-check
// The run state: what the player owns and what the current shift has produced. A RUN is a campaign of shifts: its seed,
// stratum and floor, the cash banked and the upgrades bought survive from shift to shift (P4's camp spends them). A SHIFT
// is one trip down the lift: ore carried, per-player lamps, the clock and the moles. It is plain data in a module
// singleton, so it survives scene loads, is reset for every test file, and `snapshot()` is what a save stores.
import { rng } from "factoria";
import { ORES, ORE_VALUE } from "./tiles.js";
import * as events from "./events.js";
import * as players from "./players.js";
import * as music from "./music.js";

/** The upgrades and their starting level; P4 raises them. */
export const BASE_UPGRADES = Object.freeze({
  pickTier: 0, // 0 digs dirt, rock and the soft ores; 1 also digs hard rock, gold and gems
  pickSpeed: 1, // multiplies the dig rate
  lampOil: 120, // seconds of light a full lamp holds
  lampRadius: 1, // multiplies the light radius
  walkSpeed: 1, // multiplies the walking speed
  torches: 6, // torches the team can place per shift (the supply is shared)
});

/**
 * @typedef {object} Lamp
 * @property {number} oil     Seconds of light left.
 * @property {number} max     Capacity (upgrades.lampOil when the shift began).
 * @property {boolean} out    True once the oil reached zero (it can come back with an oil can).
 * @property {boolean} low    True once the low-oil warning fired for this stretch.
 */

/**
 * @typedef {object} ShiftSummary
 * @property {string} outcome   "lift" (the miners rode the lift up), "dark" (every lamp went out) or "allDown" (every miner is down).
 * @property {Record<string, number>} ore   Pieces of each ore the miners carried when the shift ended.
 * @property {number} oreCount  Total pieces.
 * @property {number} value     Cash value of the ore (banked only when outcome is "lift").
 * @property {number} banked    Cash added to the run.
 * @property {number} time      Seconds the shift lasted.
 * @property {number} molesRescued
 * @property {number} molesTotal
 * @property {number} shiftNumber
 * @property {number} stratum   The stratum the shift was played in.
 * @property {number} floor     The floor within that stratum.
 */

export const run = {
  /** True between `startRun` and the end of the game. */
  active: false,
  seed: 0,
  stratum: 0,
  floor: 1,
  /** 1 for the first shift of the run. */
  shiftNumber: 0,
  cash: 0,
  upgrades: { ...BASE_UPGRADES },
  /** @type {Record<string, number>} Ore carried this shift, pieces per ore. */
  ore: Object.fromEntries(ORES.map((o) => [o, 0])),
  /** @type {Record<number, Lamp>} Lamp of each player, by player id. */
  lamps: {},
  molesRescued: 0,
  molesTotal: 0,
  /** Seconds since the shift began. */
  shiftTime: 0,
  /** Torches the team still has this shift (`lights.placeTorch` takes one). */
  torches: 0,
  /** True while the exit lift is jammed: the Mole King's floor, until the King falls (enemy.js clears it). */
  exitLocked: false,
  /** True while a shift is being played. */
  inShift: false,
  /** @type {ShiftSummary|null} The summary of the last shift (the results screen reads it). */
  lastShift: null,
};

function resetOre() {
  for (const o of ORES) run.ore[o] = 0;
}

/**
 * Starts a new run: cash 0, base upgrades, and clears the events bus and the players' states.
 * The seed defaults to a draw from the world RNG (deterministic for a given project seed, different run to run in play).
 * @param {{seed?: number, stratum?: number, floor?: number}} [opts]
 */
export function startRun(opts = {}) {
  events.clear();
  run.active = true;
  run.seed = opts.seed ?? rng.int(1, 0x7fffffff);
  run.stratum = opts.stratum ?? 0;
  run.floor = opts.floor ?? 1;
  run.shiftNumber = 0;
  run.cash = 0;
  run.upgrades = { ...BASE_UPGRADES };
  run.lastShift = null;
  run.inShift = false;
  resetOre();
  run.lamps = {};
  run.molesRescued = 0;
  run.molesTotal = 0;
  run.shiftTime = 0;
  run.torches = 0;
  run.exitLocked = false;
  music.reset();
  players.ensureOne();
  return run;
}

/**
 * Starts the next shift of the run: the ore, the lamps, the clock and the moles are reset, cash and upgrades stay. Every
 * registered player gets a full lamp and goes back to "active".
 * @param {{seed?: number, stratum?: number, floor?: number}} [opts]  A seed for this shift's mine; default: the run seed plus the shift number, so every shift is another mine and a run is repeatable.
 */
export function beginShift(opts = {}) {
  if (!run.active) startRun(opts);
  run.shiftNumber += 1;
  if (opts.stratum !== undefined) run.stratum = opts.stratum;
  if (opts.floor !== undefined) run.floor = opts.floor;
  resetOre();
  run.shiftTime = 0;
  run.molesRescued = 0;
  run.molesTotal = 0;
  run.inShift = true;
  run.torches = run.upgrades.torches;
  run.exitLocked = false; // shift.js locks it again on the boss floor
  run.lamps = {};
  players.ensureOne();
  for (const p of players.all()) {
    p.hp = players.MAX_HP;
    p.invulnerable = 0;
    run.lamps[p.id] = { oil: run.upgrades.lampOil, max: run.upgrades.lampOil, out: false, low: false };
    players.setState(p.id, "active");
  }
  return opts.seed ?? run.seed + run.shiftNumber - 1;
}

/** Light radius (world units) of a lamp that is nearly dry and of a full one. */
export const LAMP_MIN = 20;
export const LAMP_MAX = 96;

/** Light radius in world units of a lamp now: it shrinks with the oil (a dry lamp keeps a small glow of LAMP_MIN, but no light). */
export function lampRadius(lamp) {
  const f = lamp.max > 0 ? Math.max(0, Math.min(1, lamp.oil / lamp.max)) : 0;
  return (LAMP_MIN + (LAMP_MAX - LAMP_MIN) * Math.pow(f, 0.6)) * run.upgrades.lampRadius;
}

/** Lamp of a player (created full when missing, so a player who joins mid-shift has one). */
export function lampOf(id) {
  if (!run.lamps[id]) run.lamps[id] = { oil: run.upgrades.lampOil, max: run.upgrades.lampOil, out: false, low: false };
  return run.lamps[id];
}

/** Puts ore into the pockets. */
export function addOre(ore, n = 1) {
  if (!(ore in run.ore)) throw new Error(`unknown ore '${ore}': the ores are ${ORES.join(", ")}.`);
  run.ore[ore] += n;
}

/** Pieces of ore carried. */
export function totalOre() {
  return ORES.reduce((sum, o) => sum + run.ore[o], 0);
}

/** Cash value of the ore carried. */
export function oreValue() {
  return ORES.reduce((sum, o) => sum + run.ore[o] * ORE_VALUE[o], 0);
}

/**
 * Closes the shift: builds the summary, banks the ore value into `cash` when the miners came back up ("lift"), and sets
 * `run.lastShift`. Called once by the shift scene, which then emits `shiftEnded`.
 * @param {"lift"|"dark"|"allDown"} outcome
 * @returns {ShiftSummary}
 */
export function endShift(outcome) {
  const value = oreValue();
  const banked = outcome === "lift" ? value : 0;
  run.cash += banked;
  run.inShift = false;
  run.lastShift = {
    outcome, ore: { ...run.ore }, oreCount: totalOre(), value, banked, time: run.shiftTime,
    molesRescued: run.molesRescued, molesTotal: run.molesTotal, shiftNumber: run.shiftNumber, stratum: run.stratum, floor: run.floor,
  };
  return run.lastShift;
}

/** The part of the state a save stores (see save.js). */
export function snapshot() {
  return { seed: run.seed, stratum: run.stratum, floor: run.floor, shiftNumber: run.shiftNumber, cash: run.cash, upgrades: { ...run.upgrades } };
}

/** Puts a snapshot back (the save loader). */
export function restore(data) {
  run.active = true;
  run.seed = data.seed;
  run.stratum = data.stratum;
  run.floor = data.floor;
  run.shiftNumber = data.shiftNumber;
  run.cash = data.cash;
  run.upgrades = { ...BASE_UPGRADES, ...data.upgrades };
  run.inShift = false;
}
