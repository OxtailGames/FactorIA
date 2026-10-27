// @ts-check
// The notebook and the deduction board as plain logic (scripts/screens.js draws them).
//
// Clues are not stored: a clue is known when its story flag is set (data/notebook.json lists the clue ids and their flags;
// the flags are set by the conversations, the item boxes and the puzzles). The board is the part the player makes: two known
// things (clues, or deductions already made) are linked, and when data/notebook.json has a deduction for that pair it is made.
// Making one sets the story flag `ded.<id>`; undoing it clears the flag.
//
// State, plain JSON in `session` (a save keeps both):
//   session.board    = { deductions: ["d_trail", "d_date"], redo: ["d_adit"] }   made, in the order made; undone, last first
//   session.notebook = { seen: ["oil", "cellar"] }                                clues already announced on the HUD
// Locale keys: notebook.clue.<id>.title / .text and notebook.ded.<id>.title / .text.
import { session, i18n } from "factoria";
import table from "../data/notebook.json";
import * as story from "./story.js";
import { EVENTS, emit } from "./events.js";

export const clues = table.clues;
export const deductions = table.deductions;

/** The story flag a deduction sets while it stands. */
export const flagOf = (id) => `ded.${id}`;

/** @returns {{ deductions: string[], redo: string[] }} */
function board() {
  if (!session.board) session.board = { deductions: [], redo: [] };
  return session.board;
}

/** @returns {{ seen: string[] }} */
function book() {
  if (!session.notebook) session.notebook = { seen: [] };
  return session.notebook;
}

/** The definition of a clue or a deduction by id, or null. */
export function node(id) {
  return clues.find((c) => c.id === id) ?? deductions.find((d) => d.id === id) ?? null;
}

/** True for a deduction id. */
export function isDeduction(id) {
  return deductions.some((d) => d.id === id);
}

/** The locale key of a node's title. */
export function titleKey(id) {
  return `notebook.${isDeduction(id) ? "ded" : "clue"}.${id}.title`;
}

/** The locale key of a node's text. */
export function textKey(id) {
  return `notebook.${isDeduction(id) ? "ded" : "clue"}.${id}.text`;
}

/** True when the porter knows the clue (its flag is set) or has made the deduction. */
export function known(id) {
  const d = deductions.find((x) => x.id === id);
  if (d) return board().deductions.includes(id);
  const c = clues.find((x) => x.id === id);
  return !!c && story.has(c.flag);
}

/** The ids of the clues known now, in the order of the file. */
export function knownClues() {
  return clues.filter((c) => known(c.id)).map((c) => c.id);
}

/** The deductions made, in the order they were made. */
export function made() {
  return board().deductions.slice();
}

/** What can be redone: the deductions undone, the next one to come back last. */
export function redoable() {
  return board().redo.slice();
}

/** The deduction that links two nodes (in either order), or null. */
export function deductionOf(a, b) {
  return deductions.find((d) => (d.a === a && d.b === b) || (d.a === b && d.b === a)) ?? null;
}

function name(id) {
  return i18n.t(titleKey(id));
}

/**
 * Links two things. Returns { ok, key, args, made } where `key` is the locale key of the line to show: a deduction made, a pair
 * that leads nowhere, a repeat, or a thing the porter does not know yet.
 */
export function link(a, b) {
  if (a === b) return { ok: false, key: "board.same", args: {}, made: null };
  if (!known(a) || !known(b)) return { ok: false, key: "board.nothing", args: {}, made: null };
  const d = deductionOf(a, b);
  if (!d) return { ok: false, key: "board.nothing", args: {}, made: null };
  const st = board();
  if (st.deductions.includes(d.id)) return { ok: false, key: "board.already", args: {}, made: null };
  st.deductions.push(d.id);
  st.redo = [];
  story.set(flagOf(d.id));
  emit(EVENTS.boardChanged, { deductions: made(), made: d.id, undone: null });
  return { ok: true, key: "board.made", args: { name: name(d.id) }, made: d.id };
}

/** Takes back the last deduction made. It can come back with redo(). */
export function undo() {
  const st = board();
  const id = st.deductions.pop();
  if (!id) return { ok: false, key: "board.nothing", args: {}, undone: null };
  st.redo.push(id);
  story.set(flagOf(id), false);
  emit(EVENTS.boardChanged, { deductions: made(), made: null, undone: id });
  return { ok: true, key: "board.undone", args: { name: name(id) }, undone: id };
}

/** Brings back the deduction undone last, when the two things it links are still known. */
export function redo() {
  const st = board();
  const id = st.redo[st.redo.length - 1];
  if (!id) return { ok: false, key: "board.nothing", args: {}, made: null };
  const d = deductions.find((x) => x.id === id);
  if (!d || !known(d.a) || !known(d.b)) return { ok: false, key: "board.cannotRedo", args: {}, made: null };
  st.redo.pop();
  st.deductions.push(id);
  story.set(flagOf(id));
  emit(EVENTS.boardChanged, { deductions: made(), made: id, undone: null });
  return { ok: true, key: "board.redone", args: { name: name(id) }, made: id };
}

/**
 * The notebook page: the deductions made, then the clues known, each { id, deduction, titleKey, textKey, group }.
 * @returns {{ id: string, deduction: boolean, titleKey: string, textKey: string, group: string }[]}
 */
export function entries() {
  const out = [];
  for (const id of made()) out.push({ id, deduction: true, titleKey: titleKey(id), textKey: textKey(id), group: "deduction" });
  for (const c of clues) if (known(c.id)) out.push({ id: c.id, deduction: false, titleKey: titleKey(c.id), textKey: textKey(c.id), group: c.group });
  return out;
}

/** Marks every clue known now as announced (a scene starts; a save is loaded) without saying anything. */
export function markSeen() {
  const seen = book().seen;
  for (const id of knownClues()) if (!seen.includes(id)) seen.push(id);
}

/** The clues learned since the last call (and not announced yet): marks them announced. Returns their ids. */
export function takeNew() {
  const seen = book().seen;
  const fresh = knownClues().filter((id) => !seen.includes(id));
  seen.push(...fresh);
  return fresh;
}

/** A plain copy for a save: { board, notebook }. */
export function snapshot() {
  return JSON.parse(JSON.stringify({ board: board(), notebook: book() }));
}

/** Puts a snapshot() back. The deductions the file no longer has are dropped; the flags `ded.*` are in the story snapshot. */
export function restore(data) {
  const ids = deductions.map((d) => d.id);
  const keep = (list) => (Array.isArray(list) ? list.filter((x) => ids.includes(x)) : []);
  session.board = { deductions: keep(data?.board?.deductions), redo: keep(data?.board?.redo) };
  session.notebook = { seen: Array.isArray(data?.notebook?.seen) ? data.notebook.seen.filter((x) => typeof x === "string") : [] };
}

/** Forgets the board and the notebook (a new game). */
export function reset() {
  session.board = { deductions: [], redo: [] };
  session.notebook = { seen: [] };
}

/**
 * Checks data/notebook.json against the locale strings and the story flags. Pure.
 * @param {any} nb the parsed file
 * @param {{ strings?: any, flags?: string[], prefixes?: string[] }} [ctx]
 * @returns {{ file: string, pointer: string, message: string, hint: string }[]}
 */
export function validateNotebook(nb, ctx = {}) {
  const file = "data/notebook.json";
  const problems = [];
  const problem = (pointer, message, hint) => problems.push({ file, pointer, message, hint });
  const hasKey = (key) => {
    let n = ctx.strings;
    for (const part of String(key).split(".")) {
      if (n === null || typeof n !== "object" || !(part in n)) return false;
      n = n[part];
    }
    return typeof n === "string";
  };
  if (!nb || nb.format !== "larkspur.notebook/1" || !Array.isArray(nb.clues) || !Array.isArray(nb.deductions)) {
    problem("", "the file must be { format: 'larkspur.notebook/1', clues: [], deductions: [] }", "Start it with that shape.");
    return problems;
  }
  const ids = new Set();
  const checkStrings = (pointer, id, kind) => {
    for (const part of ["title", "text"]) {
      const key = `notebook.${kind}.${id}.${part}`;
      if (ctx.strings && !hasKey(key)) problem(pointer, `the string '${key}' is not in locales/en.json`, "Add it to locales/en.json.");
    }
  };
  nb.clues.forEach((c, i) => {
    const at = `/clues/${i}`;
    if (!c || typeof c.id !== "string" || !/^[a-z][a-z0-9_]*$/.test(c.id)) {
      problem(at, `clue ${i} has no snake_case id`, "Give every clue an id like 'letter_whole'.");
      return;
    }
    if (ids.has(c.id)) problem(at, `the id '${c.id}' is used twice`, "Clue and deduction ids are unique.");
    ids.add(c.id);
    if (ctx.flags && !ctx.flags.includes(c.flag)) {
      const near = ctx.flags.length ? ctx.flags.find((f) => f.startsWith(String(c.flag).slice(0, 4))) : "";
      problem(`${at}/flag`, `clue '${c.id}' reads the flag '${c.flag}', which data/story.json does not have`, near ? `Did you mean '${near}'?` : "Add the flag to FLAGS in assets/src/build_story.py.");
    }
    checkStrings(at, c.id, "clue");
  });
  const pairs = new Set();
  nb.deductions.forEach((d, i) => {
    const at = `/deductions/${i}`;
    if (!d || typeof d.id !== "string" || !d.id.startsWith("d_")) {
      problem(at, `deduction ${i} has no id starting with 'd_'`, "Name it like 'd_date'.");
      return;
    }
    if (ids.has(d.id)) problem(at, `the id '${d.id}' is used twice`, "Clue and deduction ids are unique.");
    for (const f of ["a", "b"]) {
      if (!ids.has(d[f])) problem(`${at}/${f}`, `deduction '${d.id}' links '${d[f]}', which is no clue and no earlier deduction`, `Known ids so far: ${[...ids].join(", ")}.`);
    }
    if (d.a === d.b) problem(at, `deduction '${d.id}' links '${d.a}' with itself`, "Link two different things.");
    const pair = [d.a, d.b].sort().join("+");
    if (pairs.has(pair)) problem(at, `two deductions link ${pair}`, "A pair leads to one deduction.");
    pairs.add(pair);
    ids.add(d.id);
    checkStrings(at, d.id, "ded");
    if (ctx.prefixes && !ctx.prefixes.includes("ded.")) problem(at, "the flag prefix 'ded.' is not in data/story.json flagPrefixes", "Add it to PREFIXES in assets/src/build_story.py.");
  });
  return problems;
}
