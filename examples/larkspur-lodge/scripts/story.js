// @ts-check
// The story flags: named facts the whole game agrees on ("the library door is open", "the storm is over"). They live in
// `session.story`, so they survive the scene loads between the lodge's areas, and snapshot()/restore() are the part of the
// save that is the story (scripts/save_data.js). Every change sends EVENTS.flagChanged.
//
// A flag is a name -> boolean | number | string. Reading one that was never set gives the fallback (false). Names are the
// ones of FLAGS (the flags the engine-side packages agree on) or a dotted name a script makes up for itself:
// "open.<door id>" (a door that has been opened), "taken.<item box id>", "examined.<object id>".
import { session } from "factoria";
import { EVENTS, emit } from "./events.js";

/** The flags a package of the game reads or writes by name. Add new ones here with a line that says who sets and who reads. */
export const FLAGS = Object.freeze({
  /** Set by P3's puzzle chain when the storm stops and the front door can be opened; the front door reads it. */
  stormOver: "storm_over",
  /** Set by the cut-scene player (P4) when the opening scene has played, so it is not shown again. */
  introSeen: "intro_seen",
});

/** @returns {{ flags: Record<string, any>, counters: Record<string, number> }} */
function store() {
  if (!session.story) session.story = { flags: {}, counters: {} };
  return session.story;
}

/** The value of a flag, or `fallback` (default false) when it was never set. */
export function get(flag, fallback = false) {
  const flags = store().flags;
  return Object.prototype.hasOwnProperty.call(flags, flag) ? flags[flag] : fallback;
}

/** True when the flag is set to something other than false, 0 or "". */
export function has(flag) {
  return !!get(flag, false);
}

/** Sets a flag (true by default). Sends flagChanged only when the value really changes; returns true then. */
export function set(flag, value = true) {
  const flags = store().flags;
  const previous = Object.prototype.hasOwnProperty.call(flags, flag) ? flags[flag] : false;
  if (previous === value) return false;
  flags[flag] = value;
  emit(EVENTS.flagChanged, { flag, value, previous });
  return true;
}

/** Adds `by` to a counter (a number that starts at 0) and returns the new value. Counters send no event. */
export function inc(counter, by = 1) {
  const counters = store().counters;
  counters[counter] = (counters[counter] ?? 0) + by;
  return counters[counter];
}

/** The value of a counter (0 when it was never incremented). */
export function count(counter) {
  return store().counters[counter] ?? 0;
}

/** A plain copy of the story, ready to be saved as JSON: { flags, counters }. */
export function snapshot() {
  return JSON.parse(JSON.stringify(store()));
}

/** Replaces the story with a snapshot() (a loaded save). Sends no events: scenes read the flags when they start. */
export function restore(data) {
  session.story = { flags: { ...(data?.flags ?? {}) }, counters: { ...(data?.counters ?? {}) } };
}

/** Forgets everything (a new game). */
export function reset() {
  session.story = { flags: {}, counters: {} };
}
