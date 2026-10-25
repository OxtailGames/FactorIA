// @ts-check
// The save stub: what is written, where, and the version field that lets a later build read an older file. P1 writes it when
// a shift ends; nothing reads it back at the title yet (P2 adds "Continue"), but `load` and `apply` are tested here so the
// format cannot drift unnoticed. Stored in `storage` (the player's save folder), never in the project.
import { storage } from "factoria";
import * as state from "./run_state.js";

/** Version of the save data. Raise it when a field changes meaning, and teach `migrate` the old one. */
export const SAVE_FORMAT = 1;
const KEY = "burrow.save";

/** The data a save holds. */
export function toSave() {
  return { format: SAVE_FORMAT, ...state.snapshot() };
}

/** Writes the run to the player's save. */
export function save() {
  storage.set(KEY, toSave());
}

/**
 * Brings data of an older format up to SAVE_FORMAT. P1 knows only format 1, so this only checks the field and says how to
 * fix a file it cannot read.
 * @param {any} data
 * @returns {{ok: true, data: any} | {ok: false, message: string, hint: string}}
 */
export function migrate(data) {
  if (!data || typeof data !== "object" || !Number.isInteger(data.format)) {
    return { ok: false, message: "the save has no 'format' number", hint: "delete the save (erase()) and start a new run" };
  }
  if (data.format > SAVE_FORMAT) {
    return { ok: false, message: `the save was written by a newer version (format ${data.format})`, hint: `this build reads formats up to ${SAVE_FORMAT}: update the game` };
  }
  if (data.format < 1) return { ok: false, message: `unknown save format ${data.format}`, hint: "delete the save and start a new run" };
  return { ok: true, data };
}

/** Reads the saved run: `{ ok: true, data }`, `{ ok: false, message, hint }`, or null when nothing was saved. */
export function load() {
  const raw = storage.get(KEY, null);
  return raw === null ? null : migrate(raw);
}

/** Puts a saved run into the run state; returns false (and changes nothing) when the save cannot be read. */
export function apply() {
  const found = load();
  if (!found || !found.ok) return false;
  state.restore(found.data);
  return true;
}

/** Deletes the save. */
export function erase() {
  storage.remove(KEY);
}
