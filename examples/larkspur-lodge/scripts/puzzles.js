// @ts-check
// The four puzzles of the lodge as plain logic, with no UI: the drawer lock, the railway timetable, the torn letter and the
// cellar fuse box. scripts/screens.js draws them; tests and the story bot call these functions directly. data/puzzles.json
// holds the answers and the starting positions.
//
// What a puzzle is, and what it changes:
//   drawer     four wheels; the code is a date the player deduces on the board. Opens: gives the fuse wire, sets switch_card_found.
//   timetable  put four services in the order they run, using three notes. Sets timetable_solved.
//   letter     four strips in the wrong order; swap two at a time. Sets letter_pieced.
//   fuse       needs the mended fuse (items) and the power cut (power_out); throw four breakers in the order of the timetable.
//              Sets fuse_fixed and storm_over.
// A solved puzzle is a story flag (its `solvedFlag`), so it survives saves and scene loads with the story. The state in
// progress is a plain object in `session.puzzles`:
//   { drawer: { dials: [0,0,0,0], tries: 0 }, timetable: { order: ["coach", ...] }, letter: { order: [2,0,3,1] },
//     fuse: { fitted: false, thrown: ["mail", ...], trips: 0 } }
// Every action returns { ok, key, ... }: `key` is the locale key of the line to show.
import { session } from "factoria";
import table from "../data/puzzles.json";
import * as story from "./story.js";
import * as items from "./items.js";
import { EVENTS, emit } from "./events.js";

/** The puzzle ids, in the order of the chain. */
export const IDS = Object.freeze(["letter", "drawer", "timetable", "fuse"]);

/** The parsed data/puzzles.json. */
export const data = table;

/** @returns {Record<string, any>} */
function store() {
  if (!session.puzzles) session.puzzles = {};
  return session.puzzles;
}

/** The state in progress of a puzzle (created from the starting position on first use). */
export function state(id) {
  const s = store();
  if (!s[id]) {
    if (id === "drawer") s[id] = { dials: [...table.drawer.start], tries: 0 };
    else if (id === "timetable") s[id] = { order: [...table.timetable.start] };
    else if (id === "letter") s[id] = { order: [...table.letter.start] };
    else if (id === "fuse") s[id] = { fitted: false, thrown: [], trips: 0 };
    else throw new Error(`puzzles.state: there is no puzzle '${id}'. Puzzles: ${IDS.join(", ")}.`);
  }
  return s[id];
}

/** True when the puzzle is solved (its story flag is set). */
export function solved(id) {
  return story.has(table[id].solvedFlag);
}

/** The flag a puzzle needs before it can be tried, "" when none. */
function blocked(id) {
  if (id === "fuse" && !story.has(table.fuse.requiresFlag)) return "puzzle.fuse.noPower";
  if (id === "letter" && !items.has(table.letter.item) && !solved("letter")) return "puzzle.letter.noItem";
  return "";
}

/** Whether the puzzle can be used now: { ok, key } where key is the line to show when it cannot. */
export function availability(id) {
  const key = blocked(id);
  return key ? { ok: false, key } : { ok: true, key: "" };
}

function finish(id) {
  const t = table[id];
  story.set(t.solvedFlag);
  for (const f of t.sets ?? []) story.set(f);
  emit(EVENTS.puzzleSolved, { id });
}

// ------------------------------------------------------------------------------------------------------------ drawer
/** Turns wheel `i` by `by` (+1 / -1) and wraps at 0 and 9. Returns the new digit. */
export function turnDial(i, by) {
  const s = state("drawer");
  if (i < 0 || i >= s.dials.length) return -1;
  s.dials[i] = (((s.dials[i] + by) % 10) + 10) % 10;
  return s.dials[i];
}

/** The four digits shown, as a string like "0403". */
export function dialsText() {
  return state("drawer").dials.join("");
}

/** Tries the lock. Right: the drawer opens (fuse wire into the inventory, the card is found). */
export function tryCode() {
  if (solved("drawer")) return { ok: false, key: "puzzle.drawer.done" };
  const s = state("drawer");
  s.tries++;
  if (dialsText() !== table.drawer.code) return { ok: false, key: "puzzle.drawer.wrong" };
  for (const id of table.drawer.gives) items.add(id, "drawer");
  for (const f of table.drawer.sets) story.set(f);
  finish("drawer");
  return { ok: true, key: "puzzle.drawer.open" };
}

// -------------------------------------------------------------------------------------------------------- timetable
/** The service ids in the order they really run (by time). */
export function timetableSolution() {
  return [...table.timetable.services].sort((a, b) => a.time.localeCompare(b.time)).map((s) => s.id);
}

/** The service ids as the player has put them, top to bottom (the solved order once it is solved). */
export function timetableOrder() {
  return solved("timetable") ? timetableSolution() : [...state("timetable").order];
}

/** Moves the row at `i` one place up (`by` -1) or down (+1). Returns false when it cannot move. */
export function moveService(i, by) {
  if (solved("timetable")) return false;
  const o = state("timetable").order;
  const j = i + by;
  if (i < 0 || j < 0 || i >= o.length || j >= o.length) return false;
  [o[i], o[j]] = [o[j], o[i]];
  return true;
}

/** Checks the order. Right: the timetable is solved. */
export function checkTimetable() {
  if (solved("timetable")) return { ok: true, key: "puzzle.timetable.done" };
  const o = state("timetable").order;
  if (o.join() !== timetableSolution().join()) return { ok: false, key: "puzzle.timetable.wrong" };
  finish("timetable");
  return { ok: true, key: "puzzle.timetable.solved" };
}

// ------------------------------------------------------------------------------------------------------------ letter
/** The strips as laid out now: indexes into the letter's strips, left to right (top to bottom). */
export function letterOrder() {
  return solved("letter") ? table.letter.strips.map((_, i) => i) : [...state("letter").order];
}

/** The locale keys of the strips as laid out now. */
export function letterKeys() {
  return letterOrder().map((i) => table.letter.strips[i]);
}

/** Swaps the strips at positions `i` and `j`; the letter is solved when they read in order. */
export function swapStrips(i, j) {
  if (solved("letter")) return { ok: false, key: "puzzle.letter.done" };
  if (!items.has(table.letter.item)) return { ok: false, key: "puzzle.letter.noItem" };
  const o = state("letter").order;
  if (i === j || i < 0 || j < 0 || i >= o.length || j >= o.length) return { ok: false, key: "puzzle.letter.wrong" };
  [o[i], o[j]] = [o[j], o[i]];
  if (o.every((v, k) => v === k)) {
    finish("letter");
    return { ok: true, key: "puzzle.letter.solved" };
  }
  return { ok: false, key: "puzzle.letter.wrong", swapped: true };
}

// -------------------------------------------------------------------------------------------------------------- fuse
/** The breakers as they stand in the box, left to right: service ids. */
export function breakers() {
  return [...table.fuse.layout];
}

/** The order the breakers must be thrown in: the order the services run. */
export function breakerOrder() {
  return timetableSolution();
}

/** Fits the mended fuse into the box (it is used up). */
export function fitFuse() {
  const b = blocked("fuse");
  if (b) return { ok: false, key: b };
  if (solved("fuse")) return { ok: false, key: "puzzle.fuse.done" };
  const s = state("fuse");
  if (s.fitted) return { ok: false, key: "puzzle.fuse.fitted" };
  if (!items.has(table.fuse.item)) return { ok: false, key: "puzzle.fuse.noFuse" };
  items.remove(table.fuse.item);
  s.fitted = true;
  return { ok: true, key: "puzzle.fuse.fitted" };
}

/**
 * Throws a breaker (a service id). The right breaker in turn stays down; a wrong one makes all of them fall back
 * (`trips` counts how often); the fourth right one mends the box.
 */
export function throwBreaker(id) {
  const b = blocked("fuse");
  if (b) return { ok: false, key: b };
  if (solved("fuse")) return { ok: false, key: "puzzle.fuse.done" };
  const s = state("fuse");
  if (!s.fitted) return { ok: false, key: "puzzle.fuse.needFuse" };
  if (s.thrown.includes(id)) return { ok: false, key: "puzzle.fuse.thrown" };
  const want = breakerOrder();
  if (want[s.thrown.length] !== id) {
    s.thrown = [];
    s.trips++;
    return { ok: false, key: "puzzle.fuse.trip", tripped: true };
  }
  s.thrown.push(id);
  if (s.thrown.length === want.length) {
    finish("fuse");
    return { ok: true, key: "puzzle.fuse.fixed" };
  }
  return { ok: true, key: "puzzle.fuse.thrown" };
}

// --------------------------------------------------------------------------------------------------------- the save
/** A plain copy of the puzzles in progress, for a save. */
export function snapshot() {
  return JSON.parse(JSON.stringify(store()));
}

/** Puts a snapshot() back (a loaded save); pieces that do not have the shape are dropped and start again. */
export function restore(data) {
  session.puzzles = {};
  if (!data || typeof data !== "object") return;
  const d = data.drawer;
  if (d && Array.isArray(d.dials) && d.dials.length === 4) session.puzzles.drawer = { dials: d.dials.map((n) => ((Number(n) % 10) + 10) % 10), tries: Number(d.tries) || 0 };
  const t = data.timetable;
  const ids = table.timetable.services.map((s) => s.id);
  if (t && Array.isArray(t.order) && [...t.order].sort().join() === [...ids].sort().join()) session.puzzles.timetable = { order: [...t.order] };
  const l = data.letter;
  if (l && Array.isArray(l.order) && [...l.order].sort().join() === "0,1,2,3") session.puzzles.letter = { order: [...l.order] };
  const f = data.fuse;
  if (f && typeof f === "object") session.puzzles.fuse = { fitted: !!f.fitted, thrown: Array.isArray(f.thrown) ? f.thrown.filter((x) => ids.includes(x)) : [], trips: Number(f.trips) || 0 };
}

/** Forgets every puzzle in progress (a new game). */
export function reset() {
  session.puzzles = {};
}

/**
 * Checks data/puzzles.json against the locale strings, the items and the story flags. Pure.
 * @param {any} puzzles the parsed file
 * @param {{ strings?: any, items?: any, flags?: string[] }} [ctx]
 * @returns {{ file: string, pointer: string, message: string, hint: string }[]}
 */
export function validatePuzzles(puzzles, ctx = {}) {
  const file = "data/puzzles.json";
  const problems = [];
  const problem = (pointer, message, hint) => problems.push({ file, pointer, message, hint });
  const hasKey = (key) => {
    let node = ctx.strings;
    for (const part of String(key).split(".")) {
      if (node === null || typeof node !== "object" || !(part in node)) return false;
      node = node[part];
    }
    return typeof node === "string";
  };
  const checkKey = (pointer, key) => {
    if (ctx.strings && !hasKey(key)) problem(pointer, `the string '${key}' is not in locales/en.json`, "Add it to locales/en.json.");
  };
  const checkItem = (pointer, id) => {
    if (ctx.items && !Object.prototype.hasOwnProperty.call(ctx.items.items, id)) problem(pointer, `the item '${id}' is not in data/items.json`, `Items: ${Object.keys(ctx.items.items).join(", ")}.`);
  };
  const checkFlag = (pointer, flag) => {
    if (ctx.flags && !ctx.flags.includes(flag)) problem(pointer, `the flag '${flag}' is not in data/story.json`, "Add it to FLAGS in assets/src/build_story.py and run it.");
  };
  if (!puzzles || puzzles.format !== "larkspur.puzzles/1") {
    problem("/format", `format is '${puzzles?.format}'`, 'Set "format": "larkspur.puzzles/1".');
    return problems;
  }
  for (const id of IDS) {
    if (!puzzles[id] || typeof puzzles[id] !== "object") {
      problem(`/${id}`, `there is no '${id}' puzzle`, `Add one; the puzzles are ${IDS.join(", ")}.`);
      continue;
    }
    if (typeof puzzles[id].solvedFlag !== "string") problem(`/${id}/solvedFlag`, `puzzle '${id}' has no solvedFlag`, "Name the story flag that marks it solved.");
    else checkFlag(`/${id}/solvedFlag`, puzzles[id].solvedFlag);
    for (const [i, f] of (puzzles[id].sets ?? []).entries()) checkFlag(`/${id}/sets/${i}`, f);
  }
  const d = puzzles.drawer;
  if (d) {
    if (!/^\d{4}$/.test(String(d.code))) problem("/drawer/code", `the code is '${d.code}'`, 'The code is a string of four digits, like "0403".');
    if (!Array.isArray(d.start) || d.start.length !== 4 || d.start.join("") === String(d.code)) problem("/drawer/start", "the wheels start on a list of four digits that is not the code", "Use four digits that differ from the code.");
    (d.gives ?? []).forEach((id, i) => checkItem(`/drawer/gives/${i}`, id));
  }
  const t = puzzles.timetable;
  if (t) {
    const ids = (t.services ?? []).map((s) => s.id);
    if (ids.length < 3) problem("/timetable/services", "a timetable needs at least three services", "List them with an id, a nameKey and a time like 05:40.");
    (t.services ?? []).forEach((s, i) => {
      if (!/^\d\d:\d\d$/.test(String(s.time))) problem(`/timetable/services/${i}/time`, `time '${s.time}' is not HH:MM`, 'Use a time like "06:10".');
      checkKey(`/timetable/services/${i}/nameKey`, s.nameKey);
    });
    if (new Set((t.services ?? []).map((s) => s.time)).size !== ids.length) problem("/timetable/services", "two services run at the same time", "Give each service its own time: the order has to be unique.");
    if ([...(t.start ?? [])].sort().join() !== [...ids].sort().join()) problem("/timetable/start", "start is not a permutation of the services", `Use each of ${ids.join(", ")} once.`);
    else if ((t.start ?? []).join() === [...(t.services ?? [])].sort((a, b) => a.time.localeCompare(b.time)).map((s) => s.id).join()) problem("/timetable/start", "the timetable starts already solved", "Shuffle the start.");
    (t.noteKeys ?? []).forEach((k, i) => checkKey(`/timetable/noteKeys/${i}`, k));
  }
  const l = puzzles.letter;
  if (l) {
    checkItem("/letter/item", l.item);
    (l.strips ?? []).forEach((k, i) => checkKey(`/letter/strips/${i}`, k));
    if (!Array.isArray(l.start) || [...l.start].sort().join() !== [...(l.strips ?? []).keys()].join() || l.start.every((v, i) => v === i)) problem("/letter/start", "start must be a shuffled permutation of the strip numbers", "For four strips use something like [2, 0, 3, 1].");
  }
  const f = puzzles.fuse;
  if (f) {
    checkItem("/fuse/item", f.item);
    checkFlag("/fuse/requiresFlag", f.requiresFlag);
    const ids = (t?.services ?? []).map((s) => s.id);
    if ([...(f.layout ?? [])].sort().join() !== [...ids].sort().join()) problem("/fuse/layout", "layout is not a permutation of the timetable services", `Use each of ${ids.join(", ")} once.`);
  }
  return problems;
}
