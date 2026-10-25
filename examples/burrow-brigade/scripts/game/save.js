// @ts-check
// Saves: three slots, a versioned format and the migration of older files. Everything lives in `storage` (the player's save
// folder), never in the project.
//
//   storage "burrow.slot.1" .. "burrow.slot.3"   one save per slot (format 2)
//   storage "burrow.lastSlot"                    the slot played last (the title's Continue)
//   storage "burrow.save"                        the format 1 file of P1: imported into a slot by importLegacy(), then removed
//
// FORMAT 2 (a flat object):
//   format       2
//   slot         1 to 3, the slot it is kept in
//   revision     counts the writes of this slot; the cloud sync (cloud.js) compares it
//   savedOn      "YYYY-MM-DD" of the last write (game.today(); "" for a migrated file)
//   playTime     seconds spent in shifts since the slot began (survives a victory and a new run in the same slot)
//   bestDepth    the deepest depth in metres any run of the slot reached
//   seed, stratum, floor, shiftNumber, cash, upgrades     the run: the NEXT floor to play (the camp comes first), the cash banked
//                and the values of `run.upgrades` (run_state.js)
// FORMAT 1 (P1) was: format, seed, stratum, floor, shiftNumber, cash, upgrades.
//
// To change the format: raise SAVE_FORMAT, add `MIGRATIONS[oldFormat]` that returns the data in the next format, add a fixture
// `tests/fixtures/save_v<n>.json` and a test that loads it.
//
// A file that cannot be read never crashes: `readSlot` answers `{ status: "error", kind, message, hint }` and the slot screen
// shows it. A slot that cannot be read is never overwritten by `save()`; only the player can delete it.
import { storage, game } from "factoria";
import { run, BASE_UPGRADES, snapshot, restore, startRun, depthOf } from "./run_state.js";
import { FLOORS_PER_STRATUM, STRATUM_COUNT } from "./floors.js";

/** Version of the save data. Raise it when a field changes meaning, and teach `MIGRATIONS` the old one. */
export const SAVE_FORMAT = 2;
/** How many slots the title offers. */
export const SLOT_COUNT = 3;
const LEGACY_KEY = "burrow.save";
const LAST_KEY = "burrow.lastSlot";

/** The storage key of a slot. */
export function slotKey(n) {
  if (!Number.isInteger(n) || n < 1 || n > SLOT_COUNT) throw new Error(`there are save slots 1 to ${SLOT_COUNT}, not ${n}.`);
  return `burrow.slot.${n}`;
}

/** @typedef {{ok: true, data: any, from?: number} | {ok: false, kind: "corrupt"|"newer", message: string, hint: string}} Migrated */

/** Each entry turns a file of that format into the next one. `slot` is where the file was found. */
const MIGRATIONS = {
  /** P1's file had no slot, revision, dates or totals. */
  1: (data, slot) => ({
    ...data,
    format: 2,
    slot,
    revision: 1,
    savedOn: "",
    playTime: 0,
    bestDepth: Number.isInteger(data.stratum) && Number.isInteger(data.floor) ? depthOf(data.stratum, data.floor) : 0,
  }),
};

function corrupt(message, hint) {
  return { ok: false, kind: /** @type {const} */ ("corrupt"), message, hint };
}

const isCount = (v) => Number.isInteger(v) && v >= 0;

/**
 * Checks a file of the current format and fills the optional fields. Answers the first problem with its place, like a JSON pointer.
 * @param {any} data
 * @param {number} slot
 * @returns {Migrated}
 */
function validate(data, slot) {
  const bad = (pointer, want) => corrupt(`the save is damaged: '${pointer}' must be ${want}, found ${JSON.stringify(data[pointer.slice(2)])}`, `delete the slot and start a new run (the cloud may hold a good copy: Sync with the cloud)`);
  if (!Number.isInteger(data.seed) || data.seed < 0 || data.seed >= 0x80000000) return bad("#/seed", "a whole number from 0 to 2147483647");
  if (!Number.isInteger(data.stratum) || data.stratum < 0 || data.stratum >= STRATUM_COUNT) return bad("#/stratum", `a whole number from 0 to ${STRATUM_COUNT - 1}`);
  if (!Number.isInteger(data.floor) || data.floor < 1 || data.floor > FLOORS_PER_STRATUM) return bad("#/floor", `a whole number from 1 to ${FLOORS_PER_STRATUM}`);
  if (!isCount(data.shiftNumber)) return bad("#/shiftNumber", "a whole number, 0 or more");
  if (!isCount(data.cash)) return bad("#/cash", "a whole number, 0 or more");
  if (!data.upgrades || typeof data.upgrades !== "object" || Array.isArray(data.upgrades)) return bad("#/upgrades", "an object of upgrade values");
  for (const id of Object.keys(BASE_UPGRADES)) {
    const v = data.upgrades[id];
    if (v !== undefined && (typeof v !== "number" || !Number.isFinite(v) || v < 0)) {
      return corrupt(`the save is damaged: '#/upgrades/${id}' must be a number, 0 or more, found ${JSON.stringify(v)}`, "delete the slot and start a new run");
    }
  }
  for (const key of ["playTime", "bestDepth"]) if (data[key] !== undefined && (typeof data[key] !== "number" || !(data[key] >= 0))) return bad(`#/${key}`, "a number, 0 or more");
  if (data.revision !== undefined && !(Number.isInteger(data.revision) && data.revision >= 1)) return bad("#/revision", "a whole number, 1 or more");
  const upgrades = { ...BASE_UPGRADES };
  for (const id of Object.keys(BASE_UPGRADES)) if (data.upgrades[id] !== undefined) upgrades[id] = data.upgrades[id];
  return {
    ok: true,
    data: {
      format: SAVE_FORMAT, slot, revision: data.revision ?? 1, savedOn: typeof data.savedOn === "string" ? data.savedOn : "",
      playTime: data.playTime ?? 0, bestDepth: data.bestDepth ?? 0,
      seed: data.seed, stratum: data.stratum, floor: data.floor, shiftNumber: data.shiftNumber, cash: data.cash, upgrades,
    },
  };
}

/**
 * Brings a file of any known format up to SAVE_FORMAT and checks it. Never throws: a file it cannot read answers
 * `{ ok: false, kind, message, hint }` ("corrupt": damaged or not a save; "newer": written by a later version of the game).
 * @param {any} data  The parsed file.
 * @param {number} [slot]  The slot it was found in (format 1 files do not know theirs). Default 1.
 * @returns {Migrated}
 */
export function migrate(data, slot = 1) {
  if (!data || typeof data !== "object" || Array.isArray(data) || !Number.isInteger(data.format)) {
    return corrupt("the save has no 'format' number, so it is not a Burrow Brigade save or it is damaged", "delete the slot and start a new run");
  }
  if (data.format > SAVE_FORMAT) {
    return { ok: false, kind: "newer", message: `the save was written by a newer version of the game (format ${data.format})`, hint: `this build reads formats up to ${SAVE_FORMAT}: update the game, and leave the slot alone until then` };
  }
  if (data.format < 1) return corrupt(`unknown save format ${data.format}`, "delete the slot and start a new run");
  let current = data;
  const from = data.format;
  while (current.format < SAVE_FORMAT) {
    const step = /** @type {Record<number, (d: any, s: number) => any>} */ (MIGRATIONS)[current.format];
    if (!step) return corrupt(`no migration knows save format ${current.format}`, "delete the slot and start a new run");
    current = step(current, slot);
  }
  const checked = validate(current, slot);
  return checked.ok && from !== SAVE_FORMAT ? { ...checked, from } : checked;
}

/**
 * What a slot screen shows of a save.
 * @param {any} data  A file of the current format.
 */
export function summarize(data) {
  return {
    slot: data.slot, stratum: data.stratum, floor: data.floor, depth: depthOf(data.stratum, data.floor), cash: data.cash,
    shiftNumber: data.shiftNumber, playTime: data.playTime, bestDepth: data.bestDepth, savedOn: data.savedOn, revision: data.revision,
  };
}

/**
 * Reads a slot.
 * @param {number} n  1 to SLOT_COUNT.
 * @returns {{slot: number, status: "empty"} | {slot: number, status: "ok", data: any, summary: ReturnType<typeof summarize>, migratedFrom?: number} | {slot: number, status: "error", kind: "corrupt"|"newer", message: string, hint: string}}
 */
export function readSlot(n) {
  const raw = storage.get(slotKey(n), null);
  if (raw === null || raw === undefined) return { slot: n, status: "empty" };
  const found = migrate(raw, n);
  if (!found.ok) return { slot: n, status: "error", kind: found.kind, message: `slot ${n}: ${found.message}`, hint: found.hint };
  return { slot: n, status: "ok", data: found.data, summary: summarize(found.data), ...(found.from ? { migratedFrom: found.from } : {}) };
}

/** Every slot, 1 to SLOT_COUNT. */
export function slots() {
  return Array.from({ length: SLOT_COUNT }, (_, i) => readSlot(i + 1));
}

/** True when the engine found `storage.json` damaged at the start of this run (it keeps a copy and starts empty). */
export function storageDamaged() {
  return storage.corrupt === true;
}

/** The slot to Continue: the one played last if it can be read, else the first readable one, else null. */
export function lastSlot() {
  const last = storage.get(LAST_KEY, null);
  if (Number.isInteger(last) && last >= 1 && last <= SLOT_COUNT && readSlot(last).status === "ok") return last;
  const first = slots().find((s) => s.status === "ok");
  return first ? first.slot : null;
}

/**
 * The format 1 file of P1 (`burrow.save`) becomes a slot: slot 1 if it is free, else the first free one. A file that cannot be
 * read stays where it is and the answer says why. Call it when the title starts.
 * @returns {{imported: boolean, slot?: number, reason?: string, message?: string, hint?: string}}
 */
export function importLegacy() {
  const raw = storage.get(LEGACY_KEY, null);
  if (raw === null || raw === undefined) return { imported: false, reason: "none" };
  const free = slots().find((s) => s.status === "empty");
  if (!free) return { imported: false, reason: "full", message: "an old save (burrow.save) is waiting but the three slots are taken", hint: "delete a slot and it will be imported at the next start" };
  const found = migrate(raw, free.slot);
  if (!found.ok) return { imported: false, reason: found.kind, message: found.message, hint: found.hint };
  storage.set(slotKey(free.slot), found.data);
  storage.remove(LEGACY_KEY);
  return { imported: true, slot: free.slot };
}

/**
 * The file a save writes now: the run state (`snapshot()`) plus the slot, the revision and the date.
 * @param {{stratum?: number, floor?: number}} [over]  The floor to continue at, when the run state has not moved to it yet (a shift that just ended).
 * @param {number} [previousRevision]
 * @param {number} [previousBest]
 */
export function toSave(over = {}, previousRevision = 0, previousBest = 0) {
  const snap = snapshot();
  const data = {
    format: SAVE_FORMAT,
    slot: run.slot,
    revision: previousRevision + 1,
    savedOn: game.today().iso,
    ...snap,
    ...(over.stratum !== undefined ? { stratum: over.stratum } : {}),
    ...(over.floor !== undefined ? { floor: over.floor } : {}),
  };
  data.bestDepth = Math.max(snap.bestDepth, previousBest);
  return data;
}

/**
 * Writes the run to its slot. Does nothing (returns false) for a run without a slot (the daily dig, a seed-code run) and for a
 * slot whose file cannot be read: that one is never overwritten.
 * @param {{stratum?: number, floor?: number}} [over]  See `toSave`.
 * @returns {boolean} Whether a file was written.
 */
export function save(over = {}) {
  if (run.mode === "daily" || run.slot === null) return false;
  const prev = readSlot(run.slot);
  if (prev.status === "error") return false;
  const previous = prev.status === "ok" ? prev.data : null;
  storage.set(slotKey(run.slot), toSave(over, previous?.revision ?? 0, previous?.bestDepth ?? 0));
  storage.set(LAST_KEY, run.slot);
  return true;
}

/**
 * Starts a new run in an empty slot and writes it at once, so the slot shows up in the list. `opts` are those of `startRun`
 * (a seed, a stratum and a floor); a slot that holds a readable save is refused (delete it first).
 * @param {number} n
 * @param {{seed?: number, stratum?: number, floor?: number, playTime?: number, bestDepth?: number}} [opts]
 * @returns {{ok: true} | {ok: false, message: string, hint: string}}
 */
export function newRun(n, opts = {}) {
  const have = readSlot(n);
  if (have.status !== "empty") {
    return { ok: false, message: `slot ${n} is not empty`, hint: have.status === "ok" ? "Continue it, or delete it first" : "it holds a file this version cannot read: delete it to start over" };
  }
  startRun({ ...opts, slot: n });
  save();
  return { ok: true };
}

/**
 * Loads a slot into the run state and starts the run there. The camp comes first when at least one shift was played.
 * @param {number} n
 * @returns {{ok: true, resume: "camp"|"shift"} | {ok: false, message: string, hint: string}}
 */
export function continueSlot(n) {
  const found = readSlot(n);
  if (found.status === "empty") return { ok: false, message: `slot ${n} is empty`, hint: "start a new run in it" };
  if (found.status === "error") return { ok: false, message: found.message, hint: found.hint };
  startRun({ slot: n });
  restore(found.data);
  storage.set(LAST_KEY, n);
  return { ok: true, resume: found.data.shiftNumber > 0 ? "camp" : "shift" };
}

/**
 * The newest readable save: a slot, or the one the old API called "the save".
 * @param {number} [n]  Default: the slot of the run, else the last played.
 */
export function load(n = run.slot ?? lastSlot() ?? 1) {
  const found = readSlot(n);
  if (found.status === "empty") return null;
  if (found.status === "error") return { ok: false, message: found.message, hint: found.hint };
  return { ok: true, data: found.data };
}

/** Puts a save into the run state; returns false (and changes nothing) when it cannot be read. */
export function apply(n = run.slot ?? lastSlot() ?? 1) {
  const found = load(n);
  if (!found || !found.ok) return false;
  restore(found.data);
  return true;
}

/** Deletes a slot. */
export function erase(n = run.slot ?? 1) {
  storage.remove(slotKey(n));
  if (storage.get(LAST_KEY, null) === n) storage.remove(LAST_KEY);
}
