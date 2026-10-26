// @ts-check
// Remote balance values: a small JSON file on the game's server that changes the numbers of the enemies and the hazards without
// a new build. The file is untrusted, so every value is checked against RANGES before it is used; what fails the check is
// ignored (and listed in the result), never half-applied. The values come from the "balance" section of the remote config file
// (online.js); the engine keeps the last good copy, so a player who starts offline plays with the numbers of the last run, and
// one who never was online with the numbers the game ships with.
//
//   file     { "balance": { "beetle.hp": 4, "hazards.drownTime": 5 } }
//   keys     "<group>.<name>": group is beetle, thief, king (enemy_brains.js STATS) or hazards (hazards.js TUNING); RANGES lists every key
//   apply(values)   checks and applies; returns { applied: {key: value}, rejected: [{ key, value, reason, hint }] }
//   reset()         back to the shipped numbers
//   refresh()       waits for the server's file (online.js) and applies its "balance" section; resolves { source: "server"|"cache"|"offline", applied, rejected }
//   defaults() / current()   the shipped numbers / the ones in use, as { "beetle.hp": 3, ... }
//
// A value changes the game only between shifts: `apply` while a shift runs is held back and goes in when the shift ends (`flush`).
import * as events from "./events.js";
import * as online from "./online.js";
import { STATS } from "./enemy_brains.js";
import { TUNING } from "./hazards.js";

/** @param {number} min @param {number} max @param {boolean} [int] */
const num = (min, max, int = false) => ({ min, max, int });

const SPEED = num(1, 400);
const SIGHT = num(16, 600);

/**
 * Every key a server may set: the allowed range (inclusive) and whether it has to be a whole number. Units: world units are
 * 1/16 tile, speeds are per second, times are seconds.
 */
export const RANGES = Object.freeze({
  "beetle.hp": num(1, 30, true), "beetle.sight": SIGHT, "beetle.patrolSpeed": SPEED, "beetle.chaseSpeed": SPEED,
  "beetle.biteRange": num(4, 64), "beetle.biteWindup": num(0.1, 5), "beetle.biteCooldown": num(0.2, 20), "beetle.biteOil": num(0, 100),
  "thief.hp": num(1, 30, true), "thief.sight": SIGHT, "thief.wanderSpeed": SPEED, "thief.approachSpeed": SPEED, "thief.fleeSpeed": SPEED,
  "thief.stealRange": num(4, 64), "thief.stealShare": num(0, 1), "thief.escapeAfter": num(0.5, 30), "thief.escapeDistance": num(32, 600),
  "king.hp": num(1, 200, true), "king.hpPerExtraPlayer": num(0, 50, true), "king.sight": SIGHT, "king.wakeRange": SIGHT,
  "king.chaseSpeed": SPEED, "king.slamTrigger": num(8, 200), "king.slamRadius": num(8, 200), "king.slamWindup": num(0.1, 5),
  "king.slamStun": num(0.1, 10), "king.slamCooldown": num(0.5, 30), "king.chargeMinDist": num(8, 600), "king.chargeMaxDist": num(8, 600),
  "king.chargeWindup": num(0.1, 5), "king.chargeSpeed": num(20, 400), "king.chargeLength": num(16, 600), "king.chargeStun": num(0.1, 10),
  "king.chargeCooldown": num(0.5, 30), "king.chargeHit": num(4, 64),
  "hazards.waterWave": num(0.2, 10), "hazards.magmaWave": num(0.2, 10), "hazards.waveTiles": num(1, 12, true),
  "hazards.drownTime": num(0.5, 30), "hazards.burnTime": num(0.1, 10), "hazards.waterSlow": num(0.1, 1), "hazards.caveWarning": num(0.5, 10),
});

/** The object that holds a group's numbers. */
function holder(group) {
  return group === "hazards" ? /** @type {Record<string, number>} */ (TUNING) : /** @type {Record<string, number>} */ (/** @type {any} */ (STATS)[group]);
}

/** @param {string} key */
function read(key) {
  const [group, name] = key.split(".");
  return holder(group)[name];
}

/** @param {string} key @param {number} v */
function write(key, v) {
  const [group, name] = key.split(".");
  holder(group)[name] = v;
}

/** The numbers the game shipped with (read once, when the module loads). */
const DEFAULTS = Object.freeze(Object.fromEntries(Object.keys(RANGES).map((k) => [k, read(k)])));

export function defaults() {
  return { ...DEFAULTS };
}

export function current() {
  return Object.fromEntries(Object.keys(RANGES).map((k) => [k, read(k)]));
}

function lev(a, b) {
  const row = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    let prev = row[0];
    row[0] = i;
    for (let j = 1; j <= b.length; j++) {
      const cur = row[j];
      row[j] = Math.min(row[j] + 1, row[j - 1] + 1, prev + (a[i - 1] === b[j - 1] ? 0 : 1));
      prev = cur;
    }
  }
  return row[b.length];
}

/** @param {string} key */
function didYouMean(key) {
  const near = Object.keys(RANGES).map((k) => [k, lev(k.toLowerCase(), key.toLowerCase())]).sort((a, b) => a[1] - b[1]).filter((x) => x[1] <= 4).slice(0, 2);
  return near.length ? `Did you mean ${near.map((n) => `'${n[0]}'`).join(" or ")}? ` : "";
}

/** Checks one value. Returns null when it is fine, else { reason, hint }. */
function problem(key, value) {
  const r = /** @type {Record<string, {min: number, max: number, int: boolean}>} */ (RANGES)[key];
  if (!r) return { reason: "unknown key", hint: `${didYouMean(key)}The keys are in the README, "Remote balance values".` };
  if (typeof value !== "number" || !Number.isFinite(value)) return { reason: "not a number", hint: `'${key}' is a number from ${r.min} to ${r.max}.` };
  if (r.int && !Number.isInteger(value)) return { reason: "not a whole number", hint: `'${key}' is a whole number from ${r.min} to ${r.max}.` };
  if (value < r.min || value > r.max) return { reason: "out of range", hint: `'${key}' is from ${r.min} to ${r.max}; the server sent ${value}.` };
  return null;
}

/** @type {Record<string, number> | null} */
let held = null;
let shiftRunning = false;
/** @type {Array<() => void>} */
let unsubscribers = [];

/**
 * Checks and applies values. Out-of-range, unknown or mistyped ones are rejected (the rest still apply). Pairs that make no sense
 * together (king.chargeMinDist above king.chargeMaxDist) reject the pair. While a shift runs nothing changes: the valid values wait
 * for the end of the shift (`applied` is then the list that is waiting).
 * @param {any} values  { "beetle.hp": 4, ... }
 * @returns {{applied: Record<string, number>, rejected: Array<{key: string, value: any, reason: string, hint: string}>, held: boolean}}
 */
export function apply(values) {
  /** @type {Record<string, number>} */
  const applied = {};
  /** @type {Array<{key: string, value: any, reason: string, hint: string}>} */
  const rejected = [];
  if (!values || typeof values !== "object" || Array.isArray(values)) {
    return { applied, rejected: [{ key: "values", value: values, reason: "not an object", hint: 'The file is { "version": 1, "values": { "beetle.hp": 4 } }.' }], held: false };
  }
  for (const [key, value] of Object.entries(values)) {
    const p = problem(key, value);
    if (p) rejected.push({ key, value, reason: p.reason, hint: p.hint });
    else applied[key] = value;
  }
  const min = applied["king.chargeMinDist"] ?? DEFAULTS["king.chargeMinDist"];
  const max = applied["king.chargeMaxDist"] ?? DEFAULTS["king.chargeMaxDist"];
  if (min > max) {
    for (const k of ["king.chargeMinDist", "king.chargeMaxDist"]) {
      if (k in applied) {
        rejected.push({ key: k, value: applied[k], reason: "inconsistent", hint: "king.chargeMinDist must not be above king.chargeMaxDist." });
        delete applied[k];
      }
    }
  }
  if (shiftRunning) {
    held = { ...(held ?? {}), ...applied };
    return { applied, rejected, held: true };
  }
  for (const [k, v] of Object.entries(applied)) write(k, v);
  return { applied, rejected, held: false };
}

/** Puts the held values in (the end of a shift). */
export function flush() {
  if (!held) return;
  const h = held;
  held = null;
  for (const [k, v] of Object.entries(h)) write(k, v);
}

/** Back to the shipped numbers. */
export function reset() {
  held = null;
  for (const [k, v] of Object.entries(DEFAULTS)) write(k, v);
}

/** Starts watching the shifts so values only change between them. Idempotent. */
export function start() {
  if (unsubscribers.length) return;
  unsubscribers = [
    events.keep("shiftStarted", () => { shiftRunning = true; }),
    events.keep("shiftEnded", () => { shiftRunning = false; flush(); }),
  ];
}

export function stop() {
  for (const off of unsubscribers) off();
  unsubscribers = [];
  shiftRunning = false;
  reset();
}

/**
 * Waits for the server's file and applies its "balance" section. The game works without it: with no answer ever the shipped
 * numbers stay; with an earlier run's cache those numbers apply ("cache").
 * @returns {Promise<{source: "server"|"cache"|"offline", applied: Record<string, number>, rejected: Array<{key: string, value: any, reason: string, hint: string}>}>}
 */
export async function refresh() {
  const from = await online.ready();
  if (from === "default") return { source: "offline", applied: {}, rejected: [] };
  const out = apply(online.section("balance", {}));
  return { source: from === "remote" ? "server" : "cache", applied: out.applied, rejected: out.rejected };
}
