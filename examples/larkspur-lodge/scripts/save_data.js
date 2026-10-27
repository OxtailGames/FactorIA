// @ts-check
// The shape of a saved game: a plain JSON object, versioned. scripts/saves.js puts it in the slots; this file builds it
// (snapshot), puts it back (apply) and reads older versions (migrate).
//
// VERSION 2 (current, "larkspur.save/2"):
//   { "format": "larkspur.save/2",
//     "playTime": 3725.5,                              seconds played (session.playTime, counted by scripts/pause_menu.js)
//     "place": { "area": "ground", "position": [x, y, z], "yaw": degrees },   where the porter stands
//     "state": { "story": { "flags": {}, "counters": {} },                    one entry per registered part, see register()
//                "inventory": ["library_key"],
//                "dialogue": { "history": [], "log": [] },
//                ... a part another package registered (P3: the notebook, the deduction board) } }
//
// VERSION 1 ("larkspur.save/1", P1/P2): { "format": "larkspur.save/1", "area": "ground",
//     "spawn": { "position": [x, y, z], "yaw": 0 }, "story": {...}, "inventory": [...] }
// v2 changed the layout: the place became one object, `story` and `inventory` moved under `state` (the part table), and the
// play time was added. migrate1() turns a v1 save into v2 (play time 0, no dialogue history); every save is written as v2.
// A save of a NEWER version than this game's is refused with a hint (a player who went back a version).
//
// PARTS. The state of the game that is not the place is a table of named parts. A package whose state lives in plain objects
// in `session` (P3's inventory extras, notebook and board) plugs in without editing this file:
//
//   import * as save_data from "./save_data.js";
//   save_data.register("notebook", {
//     snapshot: () => structuredCopy(session.notebook),      // a plain JSON value
//     restore: (data) => { session.notebook = data; },       // data is what snapshot() returned (null if the save had none)
//     reset: () => { session.notebook = { entries: [] }; },  // a new game, or a save that has no entry for the part
//   });
//   save_data.registerSession("board", { links: [] });       // shortcut: saves session.board as it is; reset = the fallback
//
// A part registered after a save was applied (its module is imported only by a later scene) still gets its data: apply()
// keeps the entries nobody claimed yet, register() hands them over, and snapshot() writes them back untouched meanwhile.
import { session, world, didYouMean } from "factoria";
import * as story from "./story.js";
import * as items from "./items.js";
import * as dialogue from "./dialogue.js";
import { AREAS } from "./area.js";

export const VERSION = 2;
export const FORMAT = "larkspur.save/2";
export const FORMAT_V1 = "larkspur.save/1";

/** @typedef {{ snapshot: () => any, restore: (data: any) => void, reset?: () => void }} Part */
/** @type {Map<string, Part>} */
const parts = new Map();

/**
 * Registers a part of the saved state under `key`. Registering a key again replaces it (a hot reload, a test).
 * @param {string} key snake_case name, the key under `state` in the save file
 * @param {Part} part
 */
export function register(key, part) {
  if (typeof key !== "string" || !/^[a-z][a-z0-9_]*$/.test(key)) throw new Error(`save_data.register('${key}'): the key must be snake_case (letters, digits, _), e.g. 'notebook'.`);
  if (!part || typeof part.snapshot !== "function" || typeof part.restore !== "function") {
    throw new Error(`save_data.register('${key}'): give { snapshot() -> JSON value, restore(data), reset()? }. Use registerSession('${key}', fallback) for a plain object kept in session.${key}.`);
  }
  parts.set(key, part);
  const waiting = pending();
  if (Object.prototype.hasOwnProperty.call(waiting, key)) {
    const data = waiting[key];
    delete waiting[key];
    part.restore(data);
  }
}

/**
 * Registers `session[key]` as a part: saved as it is (it must be plain JSON), restored by assigning it, reset to a copy of `fallback`.
 * @param {string} key the session key, also the key under `state`
 * @param {any} fallback the value of a new game (a plain object or array)
 */
export function registerSession(key, fallback) {
  const fresh = () => JSON.parse(JSON.stringify(fallback));
  if (session[key] === undefined) session[key] = fresh();
  register(key, {
    snapshot: () => JSON.parse(JSON.stringify(session[key] ?? fresh())),
    restore: (data) => { session[key] = data === null || data === undefined ? fresh() : JSON.parse(JSON.stringify(data)); },
    reset: () => { session[key] = fresh(); },
  });
}

/** The keys of the registered parts, in registration order. */
export function partKeys() {
  return Array.from(parts.keys());
}

/** Entries of a loaded save whose part has not registered yet. */
function pending() {
  if (!session.savePending || typeof session.savePending !== "object") session.savePending = {};
  return session.savePending;
}

// The parts of this package.
register("story", { snapshot: () => story.snapshot(), restore: (d) => story.restore(d), reset: () => story.reset() });
register("inventory", { snapshot: () => items.snapshot(), restore: (d) => items.restore(d), reset: () => items.reset() });
register("dialogue", {
  snapshot: () => JSON.parse(JSON.stringify({ history: dialogue.history(), log: dialogue.log() })),
  restore: (d) => {
    dialogue.reset();
    if (Array.isArray(d?.history)) session.dialogue_history = d.history;
    if (Array.isArray(d?.log)) session.dialogue_log = d.log;
  },
  reset: () => dialogue.reset(),
});

/** A new game: every registered part goes back to its start (the title screen's Play calls this). */
export function resetAll() {
  session.savePending = {};
  session.playTime = 0;
  for (const part of parts.values()) part.reset?.();
}

/** Seconds played in the current game (session.playTime). */
export function playTime() {
  return Number(session.playTime) || 0;
}

/** The current game as a plain JSON object (what a save file holds). */
export function snapshot() {
  const porter = world.find("porter");
  const p = porter ? porter.position : { x: 0, y: 0, z: 0 };
  const yaw = porter && porter.behaviour ? porter.behaviour.yaw : 0;
  /** @type {Record<string, any>} */
  const state = {};
  for (const [key, value] of Object.entries(pending())) state[key] = JSON.parse(JSON.stringify(value));
  for (const [key, part] of parts) state[key] = JSON.parse(JSON.stringify(part.snapshot() ?? null));
  return {
    format: FORMAT,
    playTime: Math.round(playTime() * 100) / 100,
    place: { area: session.area ?? "ground", position: [p.x, p.y, p.z], yaw },
    state,
  };
}

/** Version 1 -> 2: the place becomes one object, story and inventory move under `state`, the play time starts at 0. */
export function migrate1(old) {
  return {
    format: FORMAT,
    playTime: 0,
    place: { area: old.area, position: old.spawn?.position, yaw: old.spawn?.yaw ?? 0 },
    state: { story: old.story, inventory: old.inventory, dialogue: { history: [], log: [] } },
  };
}

/**
 * Reads a save of any version and returns the newest layout, checked: `{ ok: true, data }` or `{ ok: false, message, hint }`.
 * Never throws (the text of a slot can be anything). Unknown items are dropped later by items.restore.
 * @param {any} raw the parsed JSON
 */
export function upgrade(raw) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    return { ok: false, message: "the save is not a JSON object", hint: `A save looks like { "format": "${FORMAT}", ... }.` };
  }
  let data = raw;
  if (data.format === FORMAT_V1) data = migrate1(data);
  if (data.format !== FORMAT) {
    const m = /^larkspur\.save\/(\d+)$/.exec(String(data.format));
    if (m && Number(m[1]) > VERSION) {
      return { ok: false, message: `the save is version ${m[1]}, newer than this game's (${VERSION})`, hint: "Update the game, or start a new game in another slot." };
    }
    return { ok: false, message: `the save has format '${data.format}'`, hint: `Only '${FORMAT_V1}' and '${FORMAT}' saves can be loaded. Start a new game or fix the file.` };
  }
  const place = data.place;
  if (!place || typeof place !== "object") return bad("place", "is missing", `Expected { "area": "ground", "position": [x, y, z], "yaw": 0 }.`);
  if (typeof place.area !== "string" || !Object.prototype.hasOwnProperty.call(AREAS, place.area)) {
    const near = typeof place.area === "string" ? didYouMean(place.area, Object.keys(AREAS)) : null;
    return bad("place/area", `is ${JSON.stringify(place.area)}, not an area of the lodge`, near ? `Did you mean '${near}'?` : `Areas: ${Object.keys(AREAS).join(", ")}.`);
  }
  if (!Array.isArray(place.position) || place.position.length !== 3 || !place.position.every((n) => typeof n === "number" && Number.isFinite(n))) {
    return bad("place/position", "is not [x, y, z]", "Give three numbers in metres.");
  }
  if (typeof place.yaw !== "number" || !Number.isFinite(place.yaw)) place.yaw = 0;
  if (!data.state || typeof data.state !== "object" || Array.isArray(data.state)) return bad("state", "is missing", `Expected an object with the parts: { "story": {...}, "inventory": [...] }.`);
  if (!data.state.story || typeof data.state.story !== "object") return bad("state/story", "is missing", `Expected { "flags": {}, "counters": {} }.`);
  if (typeof data.playTime !== "number" || !(data.playTime >= 0)) data.playTime = 0;
  return { ok: true, data };

  function bad(pointer, what, hint) {
    return { ok: false, message: `the save's /${pointer} ${what}`, hint };
  }
}

/**
 * Puts a save back: every part, the play time and (for scripts/area.js) the place to stand. Returns { ok, area, message, hint }.
 * The caller then loads the area scene with `scene.load(path, { restore: true })` (scripts/saves.js launch() does).
 * @param {any} data a save of any version
 */
export function apply(data) {
  const r = upgrade(data);
  if (!r.ok) return { ok: false, area: "", message: r.message, hint: r.hint };
  const save = r.data;
  session.savePending = {};
  for (const [key, value] of Object.entries(save.state)) {
    if (!parts.has(key)) pending()[key] = value;
  }
  for (const [key, part] of parts) {
    if (Object.prototype.hasOwnProperty.call(save.state, key)) part.restore(save.state[key]);
    else part.reset?.(); // a save from before the part existed starts it fresh
  }
  session.playTime = save.playTime;
  session.restoreSpawn = { position: save.place.position, yaw: save.place.yaw };
  return { ok: true, area: save.place.area, message: "", hint: "" };
}
