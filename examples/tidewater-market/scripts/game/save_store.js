// @ts-check
// The save slots: three of them, each with a manual save and an autosave, kept in `storage` (one file per key in the engine's save folder, IndexedDB on the web).
//
//   key                          value
//   tm.slot.<n>.meta             what the slot screen lists (SlotMeta below), small: reading the list never parses a whole save
//   tm.slot.<n>.data             the save (savegame.js)           n = 1..3
//   tm.slot.<n>.auto.meta/.data  the autosave of the slot (a season ends, the window loses the focus, the game closes, a timer)
//   tm.rev                       the revision counter: +1 for every write on this device; the cloud rule compares it (cloud_sync.js)
//   tm.conflict.<n>[.auto]       the copy that lost a cloud conflict, kept as a backup
// The data is written first and the meta second, so a crash between them leaves the old meta over the old data or new data without a
// meta (shown as a damaged slot that still loads), never a meta that promises a save that is not there.
import { storage, game } from "factoria";
import { serializeGame, readSave, restoreGame, VERSION } from "./savegame.js";
import { makeThumbnail } from "./thumbnail.js";

export const SLOTS = 3;
export const NAME_MAX = 24;

/**
 * @typedef {{ slot: number, kind: "manual" | "auto", name: string, scenario: string, day: number, year: number, season: string,
 *   dayOfSeason: number, playSeconds: number, savedOn: string, coins: number, population: number, revision: number,
 *   version: number, hash: string, thumb: { w: number, h: number, rows: string[] }, goalsDone?: number, goalsTotal?: number, won?: boolean }} SlotMeta
 */

const prefix = (slot, kind) => `tm.slot.${slot}${kind === "auto" ? ".auto" : ""}`;
export const metaKey = (slot, kind) => `${prefix(slot, kind)}.meta`;
export const dataKey = (slot, kind) => `${prefix(slot, kind)}.data`;
export const conflictKey = (slot, kind) => `tm.conflict.${slot}${kind === "auto" ? ".auto" : ""}`;

const validSlot = (slot) => Number.isInteger(slot) && slot >= 1 && slot <= SLOTS;
const isKind = (kind) => kind === "manual" || kind === "auto";

/** The next revision number (and remember it). */
export function nextRevision() {
  const rev = (Number(storage.get("tm.rev", 0)) || 0) + 1;
  storage.set("tm.rev", rev);
  return rev;
}

/** Make sure later writes get a revision above `n` (after taking a newer copy from the cloud). */
export function raiseRevision(n) {
  if ((Number(storage.get("tm.rev", 0)) || 0) < n) storage.set("tm.rev", n);
}

/** The text a player gave a slot, cleaned: trimmed, one line, at most NAME_MAX characters. */
export function cleanName(text) {
  return String(text ?? "").replace(/\s+/g, " ").trim().slice(0, NAME_MAX);
}

/** @param {any} m @returns {m is SlotMeta} does this look like slot meta (the slot screen would crash on anything else) */
export function isMeta(m) {
  return !!m && typeof m === "object" && typeof m.scenario === "string" && Number.isInteger(m.day) && Number.isInteger(m.revision) &&
    typeof m.season === "string" && typeof m.playSeconds === "number" && typeof m.name === "string";
}

/** @returns {SlotMeta | null} null: no such slot entry, or its meta is damaged */
export function readMeta(slot, kind = "manual") {
  if (!validSlot(slot) || !isKind(kind)) return null;
  const m = storage.get(metaKey(slot, kind), null);
  return isMeta(m) ? m : null;
}

/** Is there data under this slot entry (whatever state it is in)? */
export function hasData(slot, kind = "manual") {
  return storage.get(dataKey(slot, kind), null) != null;
}

/**
 * Everything the slot screen lists: for each slot, its manual entry and its autosave.
 * An entry is { meta } (fine), { damaged: true } (data without a readable meta: it can still be tried) or null (empty).
 * @returns {Array<{ slot: number, manual: any, auto: any }>}
 */
export function listSlots() {
  const entry = (slot, kind) => {
    const meta = readMeta(slot, kind);
    if (meta) return { meta, damaged: false };
    return hasData(slot, kind) ? { meta: null, damaged: true } : null;
  };
  return Array.from({ length: SLOTS }, (_, i) => ({ slot: i + 1, manual: entry(i + 1, "manual"), auto: entry(i + 1, "auto") }));
}

/** The entry with the highest revision on this device: what "Continue" loads. @returns {{ slot: number, kind: "manual" | "auto", meta: SlotMeta } | null} */
export function latestEntry() {
  let best = null;
  for (const s of listSlots()) {
    for (const kind of /** @type {const} */ (["manual", "auto"])) {
      const e = s[kind];
      if (e && e.meta && (!best || e.meta.revision > best.meta.revision)) best = { slot: s.slot, kind, meta: e.meta };
    }
  }
  return best;
}

/**
 * Build the slot meta of a game.
 * @param {import("./state.js").GameState} state
 * @param {{ slot: number, kind: "manual" | "auto", name: string, scenario: string, playSeconds: number, revision: number, progress?: any }} info
 * @returns {SlotMeta}
 */
export function makeMeta(state, info) {
  const date = state.clock.date();
  /** @type {SlotMeta} */
  const meta = {
    slot: info.slot,
    kind: info.kind,
    name: cleanName(info.name),
    scenario: info.scenario,
    day: date.day,
    year: date.year,
    season: date.season,
    dayOfSeason: date.dayOfSeason,
    playSeconds: Math.floor(info.playSeconds),
    savedOn: game.today().iso,
    coins: state.economy.coins,
    population: state.sim.people.villagers.size,
    revision: info.revision,
    version: VERSION,
    hash: state.hash(),
    thumb: makeThumbnail(state),
  };
  if (info.progress) Object.assign(meta, info.progress);
  return meta;
}

/**
 * Save a game into a slot entry.
 * @param {number} slot 1..3
 * @param {"manual" | "auto"} kind
 * @param {import("./state.js").GameState} state
 * @param {{ name?: string, scenario?: string, playSeconds?: number, extra?: Record<string, any>, progress?: any, async?: boolean }} [info]
 *   extra: more top-level fields of the save (serializeGame); progress: more fields of the slot meta;
 *   async: write the files off the frame (storage.setAsync, the save compressed): `written` settles when they are on disk.
 *   storage.get sees the new save at once either way. A save made while the window is closing is not async (the web runs
 *   an async write between frames, which a closing tab never reaches).
 * @returns {{ ok: true, meta: SlotMeta, written?: Promise<void> } | { ok: false, error: { code: string, message: string, hint: string } }}
 */
export function writeEntry(slot, kind, state, info = {}) {
  if (!validSlot(slot) || !isKind(kind)) {
    return { ok: false, error: { code: "bad_slot", message: `there is no save slot '${slot}' (${kind})`, hint: `slots are 1 to ${SLOTS}, kind "manual" or "auto"` } };
  }
  try {
    const previous = readMeta(slot, kind);
    const scenario = info.scenario || "sandbox";
    const save = serializeGame(state, { ...info.extra, scenario });
    const revision = nextRevision();
    const meta = makeMeta(state, {
      slot, kind, scenario, revision,
      name: info.name !== undefined ? info.name : previous ? previous.name : "",
      playSeconds: info.playSeconds ?? 0,
      progress: info.progress,
    });
    if (info.async) {
      // The data first, then the meta that points at it: the writer keeps this order.
      const written = Promise.all([storage.setAsync(dataKey(slot, kind), save, { compress: true }), storage.setAsync(metaKey(slot, kind), meta)]).then(() => {});
      return { ok: true, meta, written };
    }
    storage.set(dataKey(slot, kind), save);
    storage.set(metaKey(slot, kind), meta);
    return { ok: true, meta };
  } catch (e) {
    return { ok: false, error: { code: "storage", message: `the game could not be saved (${e && e.message})`, hint: "free some disk space and try again" } };
  }
}

/**
 * Read a slot entry back: the stored save checked and migrated, not yet restored (see loadEntry).
 * @returns {{ ok: true, save: any, migratedFrom: number | null } | { ok: false, error: import("./savegame.js").SaveProblem }}
 */
export function readEntry(slot, kind = "manual") {
  if (!validSlot(slot) || !isKind(kind)) return { ok: false, error: { code: "not_a_save", pointer: "", message: `there is no save slot '${slot}'`, hint: `slots are 1 to ${SLOTS}` } };
  const data = storage.get(dataKey(slot, kind), null);
  if (data == null) return { ok: false, error: { code: "not_a_save", pointer: "", message: `slot ${slot} is empty`, hint: "pick a slot that has a save" } };
  return readSave(data);
}

/**
 * Read and restore a slot entry into a new game state. The live game is never touched.
 * @param {ReturnType<typeof import("./data.js").getData>} data
 */
export function loadEntry(slot, kind, data) {
  const read = readEntry(slot, kind);
  if (!read.ok) return read;
  const res = restoreGame(read.save, data);
  return res.ok ? { ok: true, state: res.state, save: read.save, migratedFrom: read.migratedFrom, meta: readMeta(slot, kind) } : res;
}

/** Give a manual save a new name. @returns {boolean} false when the slot has no readable meta */
export function renameEntry(slot, name) {
  const meta = readMeta(slot, "manual");
  if (!meta) return false;
  storage.set(metaKey(slot, "manual"), { ...meta, name: cleanName(name) });
  return true;
}

/** Delete a slot entry (both keys). The autosave of a slot goes with "Delete" of that slot only when asked: pass kind "auto" for it. */
export function deleteEntry(slot, kind = "manual") {
  if (!validSlot(slot) || !isKind(kind)) return;
  storage.remove(metaKey(slot, kind));
  storage.remove(dataKey(slot, kind));
}

/** Delete everything of a slot: the manual save, the autosave and any backup. */
export function deleteSlot(slot) {
  deleteEntry(slot, "manual");
  deleteEntry(slot, "auto");
  storage.remove(conflictKey(slot, "manual"));
  storage.remove(conflictKey(slot, "auto"));
}

/** Size in bytes of the JSON text of a slot entry's save (a measure for tools; it stringifies the save). */
export function entryBytes(slot, kind = "manual") {
  const data = storage.get(dataKey(slot, kind), null);
  return data == null ? 0 : JSON.stringify(data).length;
}
