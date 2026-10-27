// The four puzzles as logic (scripts/puzzles.js), combining items (scripts/items.js) and the deduction board with undo
// (scripts/notebook.js). The screens that show them are tested in tests/screens.test.js.
import { test, describe, expect, beforeEach, game } from "factoria:test";
import { session, world, scene } from "factoria";
import { EVENTS } from "../scripts/events.js";
import * as puzzles from "../scripts/puzzles.js";
import * as notebook from "../scripts/notebook.js";
import * as items from "../scripts/items.js";
import * as story from "../scripts/story.js";
import * as save_data from "../scripts/save_data.js";
import * as chapters from "../scripts/chapters.js";
import * as saves from "../scripts/saves.js";
import { enter } from "./helpers/lodge.js";
import strings from "../locales/en.json";

const fresh = () => {
  story.reset();
  items.reset();
  puzzles.reset();
  notebook.reset();
};

/** Turns the wheels of the drawer to `code`. */
function dial(code) {
  for (let i = 0; i < 4; i++) while (puzzles.state("drawer").dials[i] !== Number(code[i])) puzzles.turnDial(i, 1);
}

describe("the drawer lock", () => {
  beforeEach(fresh);
  test("the wheels wrap round at 0 and 9", () => {
    expect(puzzles.turnDial(0, -1)).toBe(9);
    expect(puzzles.turnDial(0, 1)).toBe(0);
    expect(puzzles.turnDial(3, 1)).toBe(1);
    expect(puzzles.dialsText()).toBe("0001");
    expect(puzzles.turnDial(7, 1)).toBe(-1);
  });

  test("a wrong code is refused and counted; the right one opens the drawer once", () => {
    dial("0402");
    const wrong = puzzles.tryCode();
    expect(wrong).toEqual({ ok: false, key: "puzzle.drawer.wrong" });
    expect(puzzles.state("drawer").tries).toBe(1);
    expect(items.has("fuse_wire")).toBe(false);
    dial(puzzles.data.drawer.code);
    expect(puzzles.tryCode().ok).toBe(true);
    expect(items.has("fuse_wire")).toBe(true);
    expect(story.has("drawer_open")).toBe(true);
    expect(story.has("switch_card_found")).toBe(true);
    expect(puzzles.solved("drawer")).toBe(true);
    expect(puzzles.tryCode()).toEqual({ ok: false, key: "puzzle.drawer.done" });
  });

  test("solving it says so on the event bus", () => {
    enter("ground"); // events go to the listeners of a loaded scene
    const seen = [];
    world.on(EVENTS.puzzleSolved, (e) => seen.push(e.id));
    dial(puzzles.data.drawer.code);
    puzzles.tryCode();
    game.step(2);
    expect(seen).toEqual(["drawer"]);
  });
});

describe("the timetable", () => {
  beforeEach(fresh);
  test("the services run by time: mail, milk, goods, coach", () => {
    expect(puzzles.timetableSolution()).toEqual(["mail", "milk", "goods", "coach"]);
  });

  test("it starts shuffled; moves are limited to the table", () => {
    expect(puzzles.timetableOrder()).toEqual(puzzles.data.timetable.start);
    expect(puzzles.moveService(0, -1)).toBe(false);
    expect(puzzles.moveService(3, 1)).toBe(false);
    expect(puzzles.moveService(0, 1)).toBe(true);
    expect(puzzles.timetableOrder()[1]).toBe("coach");
  });

  test("a wrong order is refused; the right one solves it for good", () => {
    expect(puzzles.checkTimetable()).toEqual({ ok: false, key: "puzzle.timetable.wrong" });
    const want = puzzles.timetableSolution();
    for (let guard = 0; guard < 20 && puzzles.timetableOrder().join() !== want.join(); guard++) {
      const o = puzzles.timetableOrder();
      for (let i = 0; i < o.length - 1; i++) if (want.indexOf(o[i]) > want.indexOf(o[i + 1])) puzzles.moveService(i, 1);
    }
    expect(puzzles.checkTimetable().ok).toBe(true);
    expect(story.has("timetable_solved")).toBe(true);
    expect(puzzles.moveService(0, 1)).toBe(false); // solved: the rows are fixed
    expect(puzzles.timetableOrder()).toEqual(want);
  });
});

describe("the torn letter", () => {
  beforeEach(fresh);
  test("it cannot be pieced together without the letter", () => {
    expect(puzzles.availability("letter")).toEqual({ ok: false, key: "puzzle.letter.noItem" });
    expect(puzzles.swapStrips(0, 1).key).toBe("puzzle.letter.noItem");
  });

  test("swaps put the strips in order; the last swap solves it", () => {
    items.add("torn_letter");
    expect(puzzles.availability("letter").ok).toBe(true);
    expect(puzzles.swapStrips(1, 1).ok).toBe(false);
    expect(puzzles.swapStrips(0, 9).ok).toBe(false);
    expect(puzzles.state("letter").order).toEqual(puzzles.data.letter.start);
    const order = puzzles.state("letter").order;
    let last = null;
    for (let pos = 0; pos < order.length; pos++) {
      const at = order.indexOf(pos);
      if (at !== pos) last = puzzles.swapStrips(pos, at);
    }
    expect(last.ok).toBe(true);
    expect(story.has("letter_pieced")).toBe(true);
    expect(puzzles.letterOrder()).toEqual([0, 1, 2, 3]);
    expect(puzzles.swapStrips(0, 1)).toEqual({ ok: false, key: "puzzle.letter.done" });
  });
});

describe("the cellar fuse box", () => {
  beforeEach(fresh);
  test("it needs the power cut, then the mended fuse, then the breakers in the order of the timetable", () => {
    expect(puzzles.availability("fuse")).toEqual({ ok: false, key: "puzzle.fuse.noPower" });
    expect(puzzles.fitFuse().key).toBe("puzzle.fuse.noPower");
    story.set("power_out");
    expect(puzzles.availability("fuse").ok).toBe(true);
    expect(puzzles.fitFuse()).toEqual({ ok: false, key: "puzzle.fuse.noFuse" });
    expect(puzzles.throwBreaker("mail")).toEqual({ ok: false, key: "puzzle.fuse.needFuse" });
    items.add("fuse_mended");
    expect(puzzles.fitFuse().ok).toBe(true);
    expect(items.has("fuse_mended")).toBe(false); // used up
    expect(puzzles.fitFuse()).toEqual({ ok: false, key: "puzzle.fuse.fitted" });
  });

  test("a wrong breaker trips all of them back; four right ones in order end the storm", () => {
    story.set("power_out");
    items.add("fuse_mended");
    puzzles.fitFuse();
    expect(puzzles.throwBreaker("mail").ok).toBe(true);
    expect(puzzles.throwBreaker("mail").key).toBe("puzzle.fuse.thrown");
    expect(puzzles.throwBreaker("coach")).toEqual({ ok: false, key: "puzzle.fuse.trip", tripped: true });
    expect(puzzles.state("fuse").thrown).toEqual([]);
    expect(puzzles.state("fuse").trips).toBe(1);
    expect(story.has("storm_over")).toBe(false);
    for (const id of puzzles.breakerOrder()) puzzles.throwBreaker(id);
    expect(story.has("fuse_fixed")).toBe(true);
    expect(story.has("storm_over")).toBe(true);
    expect(puzzles.throwBreaker("mail")).toEqual({ ok: false, key: "puzzle.fuse.done" });
  });

  test("the box has the breakers in a different order from the one they must be thrown in", () => {
    expect(puzzles.breakers()).not.toEqual(puzzles.breakerOrder());
    expect([...puzzles.breakers()].sort()).toEqual([...puzzles.breakerOrder()].sort());
  });
});

describe("progress is plain data in session, and a save keeps it", () => {
  beforeEach(fresh);
  test("snapshot and restore round-trip; a damaged piece starts again", () => {
    dial("1234");
    puzzles.moveService(0, 1);
    const snap = puzzles.snapshot();
    expect(JSON.parse(JSON.stringify(snap))).toEqual(snap);
    puzzles.reset();
    expect(session.puzzles).toEqual({});
    puzzles.restore(snap);
    expect(puzzles.dialsText()).toBe("1234");
    expect(puzzles.timetableOrder()[1]).toBe("coach");
    puzzles.restore({ drawer: { dials: [1, 2] }, letter: { order: [0, 0, 0, 0] }, timetable: { order: ["x"] }, fuse: 7 });
    expect(puzzles.dialsText()).toBe("0000");
    expect(puzzles.state("letter").order).toEqual(puzzles.data.letter.start);
    puzzles.restore(null);
    expect(puzzles.state("fuse")).toEqual({ fitted: false, thrown: [], trips: 0 });
  });

  test("an unknown puzzle id is named", () => {
    expect(() => puzzles.state("lock")).toThrow(/no puzzle 'lock'/);
  });
});

describe("combining items", () => {
  beforeEach(fresh);
  test("wire and cartridge make a mended fuse; both are used up, in either order", () => {
    items.add("fuse_wire");
    items.add("fuse_cartridge");
    const r = items.combine("fuse_cartridge", "fuse_wire");
    expect(r.ok).toBe(true);
    expect(r.result).toBe("fuse_mended");
    expect(items.list()).toEqual(["fuse_mended"]);
    expect(strings.combo.fuse_mended).toBeTruthy();
  });

  test("a pair that does not combine is refused and nothing is lost; so is an item not carried", () => {
    items.add("lamp_oil");
    items.add("library_key");
    const r = items.combine("lamp_oil", "library_key");
    expect(r).toEqual({ ok: false, result: null, textKey: "combo.refuse" });
    expect(items.list()).toEqual(["lamp_oil", "library_key"]);
    expect(items.combine("lamp_oil", "fuse_wire").ok).toBe(false);
    expect(items.combine("lamp_oil", "lamp_oil").ok).toBe(false);
  });
});

describe("the deduction board", () => {
  beforeEach(fresh);
  test("two known clues that belong together make a deduction and set its flag", () => {
    story.set("know_oil");
    story.set("know_cellar");
    expect(notebook.knownClues()).toEqual(["oil", "cellar"]);
    const r = notebook.link("oil", "cellar");
    expect(r.ok).toBe(true);
    expect(r.made).toBe("d_trail");
    expect(story.has("ded.d_trail")).toBe(true);
    expect(notebook.made()).toEqual(["d_trail"]);
    expect(notebook.link("cellar", "oil").key).toBe("board.already");
  });

  test("a pair that leads nowhere, the same card twice, and a clue not known yet are refused", () => {
    story.set("know_oil");
    story.set("know_cellar");
    story.set("know_page");
    expect(notebook.link("oil", "page")).toMatchObject({ ok: false, key: "board.nothing" });
    expect(notebook.link("oil", "oil")).toMatchObject({ ok: false, key: "board.same" });
    expect(notebook.link("oil", "adit")).toMatchObject({ ok: false, key: "board.nothing" });
    expect(notebook.made()).toEqual([]);
  });

  test("a deduction can link to a deduction: the trail and the adit", () => {
    story.set("know_oil");
    story.set("know_cellar");
    story.set("adit_known");
    notebook.link("oil", "cellar");
    expect(notebook.link("d_trail", "adit").made).toBe("d_adit");
    expect(notebook.made()).toEqual(["d_trail", "d_adit"]);
  });

  test("undo takes the last one back and clears its flag; redo brings it back; a new deduction clears the redo list", () => {
    story.set("know_oil");
    story.set("know_cellar");
    story.set("know_page");
    story.set("know_argument");
    notebook.link("oil", "cellar");
    notebook.link("page", "argument");
    expect(notebook.undo()).toMatchObject({ ok: true, undone: "d_motive" });
    expect(story.has("ded.d_motive")).toBe(false);
    expect(story.has("ded.d_trail")).toBe(true);
    expect(notebook.redoable()).toEqual(["d_motive"]);
    expect(notebook.redo()).toMatchObject({ ok: true, made: "d_motive" });
    expect(story.has("ded.d_motive")).toBe(true);
    notebook.undo();
    notebook.undo();
    expect(notebook.made()).toEqual([]);
    expect(notebook.undo()).toMatchObject({ ok: false, key: "board.nothing" });
    expect(notebook.redoable()).toEqual(["d_motive", "d_trail"]);
    notebook.link("oil", "cellar");
    expect(notebook.redoable()).toEqual([]);
    expect(notebook.redo()).toMatchObject({ ok: false, key: "board.nothing" });
  });

  test("redo refuses a deduction whose clue is no longer known", () => {
    story.set("know_oil");
    story.set("know_cellar");
    notebook.link("oil", "cellar");
    notebook.undo();
    story.set("know_oil", false);
    expect(notebook.redo()).toMatchObject({ ok: false, key: "board.cannotRedo" });
  });

  test("the date is deduced from the whole letter and the ledger", () => {
    story.set("letter_pieced");
    story.set("ledger_taken");
    expect(notebook.link("letter_whole", "ledger").made).toBe("d_date");
  });

  test("new clues are announced once; the entries list deductions first", () => {
    story.set("know_oil");
    expect(notebook.takeNew()).toEqual(["oil"]);
    expect(notebook.takeNew()).toEqual([]);
    story.set("know_cellar");
    notebook.link("oil", "cellar");
    expect(notebook.entries().map((e) => e.id)).toEqual(["d_trail", "oil", "cellar"]);
  });

  test("snapshot and restore keep the board; ids the file no longer has are dropped", () => {
    story.set("know_oil");
    story.set("know_cellar");
    notebook.link("oil", "cellar");
    const snap = notebook.snapshot();
    notebook.reset();
    expect(notebook.made()).toEqual([]);
    notebook.restore(snap);
    expect(notebook.made()).toEqual(["d_trail"]);
    notebook.restore({ board: { deductions: ["d_trail", "d_gone"], redo: [7] }, notebook: { seen: ["oil", 3] } });
    expect(notebook.made()).toEqual(["d_trail"]);
    expect(notebook.redoable()).toEqual([]);
    expect(session.notebook.seen).toEqual(["oil"]);
  });
});

/** A running game in chapter 1 (the game can only be saved in one), with nothing solved yet. */
function startGame() {
  enter("ground");
  chapters.begin();
  game.step(120);
  puzzles.reset();
  notebook.reset();
}

describe("saving and loading (P5's save_data parts)", () => {
  beforeEach(fresh);

  test("the puzzles, the notebook and the board with its undo history are in the save, and a new game forgets them", () => {
    expect(save_data.partKeys()).toContain("puzzles");
    expect(save_data.partKeys()).toContain("notebook");
    startGame();
    story.set("know_oil");
    story.set("know_cellar");
    story.set("know_page");
    items.add("torn_letter");
    dial("0402");
    puzzles.tryCode(); // wrong: counted
    puzzles.swapStrips(0, puzzles.state("letter").order.indexOf(0)); // a letter in progress
    expect(notebook.link("oil", "cellar").made).toBe("d_trail");
    notebook.markSeen();
    notebook.undo(); // the deduction is on the redo stack
    expect(notebook.redoable()).toEqual(["d_trail"]);
    const wasDials = puzzles.dialsText();
    const wasLetter = puzzles.letterOrder();
    const wasSeen = notebook.snapshot().notebook.seen;
    expect(saves.write(1, { name: "p3" })).not.toBeNull();

    // a new game: every registered part goes back to its start
    save_data.resetAll();
    story.reset();
    items.reset();
    expect(puzzles.state("drawer").tries).toBe(0);
    expect(notebook.made()).toEqual([]);
    expect(notebook.redoable()).toEqual([]);
    expect(notebook.snapshot().notebook.seen).toEqual([]);

    // loading the slot brings everything back
    expect(saves.load(1).ok).toBe(true);
    for (let i = 0; i < 400 && scene.current !== "scenes/ground.scene.json"; i++) game.step(1);
    game.step(30);
    expect(scene.current).toBe("scenes/ground.scene.json");
    expect(puzzles.dialsText()).toBe(wasDials);
    expect(puzzles.state("drawer").tries).toBe(1);
    expect(puzzles.letterOrder()).toEqual(wasLetter);
    expect(notebook.snapshot().notebook.seen).toEqual(wasSeen);
    expect(notebook.made()).toEqual([]);
    expect(notebook.redoable()).toEqual(["d_trail"]);
    // the history still works: redo brings the deduction back, undo takes it away again
    expect(notebook.redo().ok).toBe(true);
    expect(notebook.made()).toEqual(["d_trail"]);
    expect(story.has("ded.d_trail")).toBe(true);
    expect(notebook.undo().ok).toBe(true);
    expect(notebook.made()).toEqual([]);
    expect(story.has("ded.d_trail")).toBe(false);
  });

  test("a solved puzzle stays solved after a load (its flag and the used-up item are in the save)", () => {
    startGame();
    dial("0403");
    expect(puzzles.tryCode().ok).toBe(true);
    expect(story.has(puzzles.data.drawer.solvedFlag)).toBe(true);
    expect(saves.write(2, { name: "p3 solved" })).not.toBeNull();
    save_data.resetAll();
    story.reset();
    items.reset();
    expect(story.has(puzzles.data.drawer.solvedFlag)).toBe(false);
    expect(saves.load(2).ok).toBe(true);
    for (let i = 0; i < 400 && scene.current !== "scenes/ground.scene.json"; i++) game.step(1);
    game.step(10);
    expect(puzzles.solved("drawer")).toBe(true);
    expect(items.has("fuse_wire")).toBe(true);
    expect(puzzles.tryCode()).toMatchObject({ ok: false });
  });
});
