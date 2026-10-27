// The data tables of P3 (data/combos.json, puzzles.json, notebook.json) and their validation: the shipped files are sound against the
// strings, the items and the story flags, and every kind of mistake is named with a place and a fix.
import { test, describe, expect } from "factoria:test";
import itemTable from "../data/items.json";
import comboTable from "../data/combos.json";
import puzzleTable from "../data/puzzles.json";
import notebookTable from "../data/notebook.json";
import story from "../data/story.json";
import strings from "../locales/en.json";
import ground from "../scenes/ground.scene.json";
import { validateItems } from "../scripts/items.js";
import { validatePuzzles } from "../scripts/puzzles.js";
import { validateNotebook } from "../scripts/notebook.js";

const clone = (v) => JSON.parse(JSON.stringify(v));
const flags = Object.keys(story.flags);
const prefixes = Object.keys(story.flagPrefixes);
const pctx = { strings, items: itemTable, flags };
const nctx = { strings, flags, prefixes };
const ictx = { strings, scenes: { "scenes/ground.scene.json": ground }, combos: comboTable };

describe("the shipped tables are sound", () => {
  test("puzzles, notebook and combos", () => {
    expect(validatePuzzles(puzzleTable, pctx)).toEqual([]);
    expect(validateNotebook(notebookTable, nctx)).toEqual([]);
    expect(validateItems(itemTable, { strings, combos: comboTable }).filter((p) => p.file === "data/combos.json")).toEqual([]);
  });

  test("every puzzle object of the scenes names a puzzle that exists", () => {
    const objects = ground.entities.filter((e) => e.components?.Script?.props?.kind === "puzzle");
    expect(objects.length).toBeGreaterThanOrEqual(2);
    for (const e of objects) expect(Object.keys(puzzleTable)).toContain(e.components.Script.props.puzzle);
  });
});

describe("puzzles.json mistakes", () => {
  const found = (t) => validatePuzzles(t, pctx);
  const pointers = (t) => found(t).map((p) => p.pointer);

  test("a code that is not four digits, and wheels that start on the code", () => {
    const t = clone(puzzleTable);
    t.drawer.code = "403";
    expect(pointers(t)).toContain("/drawer/code");
    const u = clone(puzzleTable);
    u.drawer.start = [0, 4, 0, 3];
    expect(pointers(u)).toContain("/drawer/start");
  });

  test("a timetable that is solved already, has equal times or a start that is no permutation", () => {
    const t = clone(puzzleTable);
    t.timetable.start = ["mail", "milk", "goods", "coach"];
    expect(found(t).find((p) => p.pointer === "/timetable/start").message).toContain("already solved");
    const u = clone(puzzleTable);
    u.timetable.services[1].time = "05:40";
    expect(pointers(u)).toContain("/timetable/services");
    const v = clone(puzzleTable);
    v.timetable.start = ["mail", "milk", "goods", "goods"];
    expect(found(v).find((p) => p.pointer === "/timetable/start").hint).toContain("mail, milk, goods, coach");
  });

  test("a time that is not HH:MM and a locale key that is missing", () => {
    const t = clone(puzzleTable);
    t.timetable.services[0].time = "5h40";
    t.timetable.services[2].nameKey = "puzzle.service.goodz";
    const p = pointers(t);
    expect(p).toContain("/timetable/services/0/time");
    expect(p).toContain("/timetable/services/2/nameKey");
  });

  test("a letter whose strips are not shuffled, a fuse layout that is not the services", () => {
    const t = clone(puzzleTable);
    t.letter.start = [0, 1, 2, 3];
    t.fuse.layout = ["mail", "milk", "goods"];
    const p = pointers(t);
    expect(p).toContain("/letter/start");
    expect(p).toContain("/fuse/layout");
  });

  test("an item or a flag the project does not have is named", () => {
    const t = clone(puzzleTable);
    t.fuse.item = "fuse_mendid";
    t.drawer.solvedFlag = "drawer_opened";
    t.drawer.sets = ["no_such_flag"];
    const all = found(t);
    expect(all.find((p) => p.pointer === "/fuse/item").message).toContain("fuse_mendid");
    expect(all.find((p) => p.pointer === "/drawer/solvedFlag").message).toContain("drawer_opened");
    expect(all.map((p) => p.pointer)).toContain("/drawer/sets/0");
  });

  test("a missing puzzle and a wrong format", () => {
    const t = clone(puzzleTable);
    delete t.letter;
    expect(pointers(t)).toContain("/letter");
    expect(found({ format: "x" })[0].pointer).toBe("/format");
    expect(found(null).length).toBe(1);
  });
});

describe("notebook.json mistakes", () => {
  const found = (t) => validateNotebook(t, nctx);

  test("a clue that reads a flag the story does not have gets a suggestion", () => {
    const t = clone(notebookTable);
    t.clues[0].flag = "know_oyl";
    const p = found(t).find((x) => x.pointer === "/clues/0/flag");
    expect(p.message).toContain("know_oyl");
  });

  test("a deduction that links something unknown, itself, or a pair twice", () => {
    const t = clone(notebookTable);
    t.deductions[0].b = "ledgr";
    t.deductions[2].b = t.deductions[2].a;
    t.deductions.push({ id: "d_again", a: "argument", b: "page" });
    const all = found(t);
    expect(all.find((p) => p.pointer === "/deductions/0/b").message).toContain("ledgr");
    expect(all.some((p) => p.pointer === "/deductions/2" && p.message.includes("with itself"))).toBe(true);
    expect(all.some((p) => p.message.includes("two deductions link"))).toBe(true);
  });

  test("a deduction can only link a clue or an EARLIER deduction; ids are unique and a text is needed", () => {
    const t = clone(notebookTable);
    t.deductions.unshift({ id: "d_early", a: "d_trail", b: "adit" });
    expect(found(t).some((p) => p.pointer === "/deductions/0/a")).toBe(true);
    const u = clone(notebookTable);
    u.clues[1].id = u.clues[0].id;
    expect(found(u).some((p) => p.message.includes("used twice"))).toBe(true);
    const v = clone(notebookTable);
    v.clues.push({ id: "mystery", flag: "know_oil", group: "x" });
    expect(found(v).some((p) => p.message.includes("notebook.clue.mystery.title"))).toBe(true);
  });

  test("the prefix of the deduction flags must be declared, and the file must have its shape", () => {
    expect(validateNotebook(notebookTable, { ...nctx, prefixes: [] }).some((p) => p.message.includes("'ded.'"))).toBe(true);
    expect(found({ clues: [] })[0].pointer).toBe("");
  });
});

describe("combos.json mistakes", () => {
  const found = (t) => validateItems(itemTable, { ...ictx, combos: t }).filter((p) => p.file === "data/combos.json");

  test("an unknown item gets a suggestion; a result that is one of the inputs; a repeat; a missing string", () => {
    const t = clone(comboTable);
    t.combos[0].a = "fuse_wyre";
    t.combos.push({ id: "again", a: "fuse_cartridge", b: "fuse_wire", result: "fuse_wire", textKey: "combo.nope" });
    const all = found(t);
    expect(all.find((p) => p.pointer === "/combos/0/a").hint).toContain("fuse_wire");
    expect(all.some((p) => p.message.includes("gives back one of its own items"))).toBe(true);
    expect(all.some((p) => p.message.includes("combo.nope"))).toBe(true);
  });

  test("an item with itself and no refuse line", () => {
    const t = clone(comboTable);
    t.combos[0].b = t.combos[0].a;
    t.refuseKey = "combo.no";
    const all = found(t);
    expect(all.some((p) => p.message.includes("with itself"))).toBe(true);
    expect(all.some((p) => p.pointer === "/refuseKey")).toBe(true);
    expect(found({ format: "x" })[0].pointer).toBe("");
  });
});
