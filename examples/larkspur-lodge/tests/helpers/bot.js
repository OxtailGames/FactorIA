// The story bot's hands: a player that walks to things, uses them with the real use key, talks by picking choices from a list of
// preferred ids, and waits for the screen to settle (area changes, chapter cards). Used by tests/story_bot.test.js. It uses no
// randomness: the same list of picks always plays the same night.
import { game } from "factoria:test";
import { scene } from "factoria";
import { porter, stand } from "./lodge.js";
import * as dialogue from "../../scripts/dialogue.js";
import * as story from "../../scripts/story.js";
import * as items from "../../scripts/items.js";
import * as chapters from "../../scripts/chapters.js";
import * as puzzles from "../../scripts/puzzles.js";
import * as notebook from "../../scripts/notebook.js";
import { AREAS } from "../../scripts/area.js";

/** Where to stand relative to a thing's spot, and the yaw that looks at it (yaw 0 faces -Z, 90 faces -X, 180 faces +Z, 270 faces +X). */
const SIDES = [
  [0, 1.2, 0],
  [0, -1.2, 180],
  [1.2, 0, 90],
  [-1.2, 0, 270],
];

/** The ways between areas: [from][to] = the interactable to use. */
const WAYS = {
  ground: { upstairs: "stairs_up", cellar: "cellar_door" },
  upstairs: { ground: "stairs_down" },
  cellar: { ground: "stairs_up" },
};

export class Bot {
  constructor() {
    /** What happened, in order: "talk mara [promise]", "use p_letter_box"... (shown when a step fails). */
    this.trail = [];
  }

  fail(message) {
    throw new Error(`${message}\n  so far: ${this.trail.join(" > ")}`);
  }

  /** The area of the scene now ("ground", "upstairs", "cellar"). */
  area() {
    return Object.keys(AREAS).find((k) => AREAS[k] === scene.current) ?? "";
  }

  /** Steps until nothing is changing: no area change, no chapter fade, the porter free. Fails after `max` frames. */
  settle(max = 900) {
    game.step(4);
    for (let i = 0; i < max; i += 4) {
      const ch = game.find("chapters")?.behaviour;
      const area = game.find("area")?.behaviour;
      const p = porter();
      const busy = !ch || !area || !p || ch.stage !== "" || area.leaving !== "" || p.behaviour.locked || game.find("hud")?.behaviour.fading;
      if (!busy) return;
      if (ch && ch.stage === "ending" && ch.endingShown) return;
      game.step(4);
    }
    this.fail(`the screen did not settle in ${max} frames (scene ${scene.current})`);
  }

  /** The title screen -> Play -> loading -> the hall, chapter 1. */
  play() {
    game.resetState();
    scene.load("scenes/menu.scene.json");
    game.step(3);
    game.click(game.find("play"));
    for (let i = 0; i < 600 && scene.current !== AREAS.ground; i++) game.step(1);
    if (scene.current !== AREAS.ground) this.fail("Play did not reach the hall");
    this.trail.push("play");
    this.settle();
  }

  /** Walks (a jump) to a thing's spot and uses it with the use key. The thing must be the porter's target there, as for a player. */
  use(id) {
    const e = game.find(id);
    if (!e || !e.behaviour) this.fail(`there is no '${id}' in ${scene.current}`);
    const [sx, sz] = e.behaviour.spot;
    let found = false;
    for (const [dx, dz, yaw] of SIDES) {
      stand(sx + dx, sz + dz, yaw);
      game.step(3);
      if (porter().behaviour.target?.entity.id === id) {
        found = true;
        break;
      }
    }
    if (!found) this.fail(`'${id}' is not the porter's target from any side (the target is '${porter().behaviour.target?.entity.id}')`);
    this.trail.push(`use ${id}`);
    game.tapKey("F");
    game.step(2);
  }

  /** Goes to another area through its stairs and doors, and waits to arrive. */
  go(target) {
    const from = this.area();
    if (from === target) return;
    if (from !== "ground" && target !== "ground") {
      this.go("ground");
      return this.go(target);
    }
    const way = from === "ground" ? WAYS.ground[target] : WAYS[from].ground;
    this.use(way);
    for (let i = 0; i < 600 && scene.current !== AREAS[target]; i++) game.step(1);
    if (scene.current !== AREAS[target]) this.fail(`did not arrive in ${target}`);
    this.settle();
  }

  /**
   * Talks to character `who` and plays the conversation to its end. At every choice it picks the first of `prefs` that is on
   * offer, else the first choice. Returns the ids picked.
   */
  talk(who, prefs = []) {
    const npc = game.find(`npc_${who}`);
    if (!npc) this.fail(`${who} is not in ${scene.current} in chapter ${chapters.current()}`);
    this.use(`npc_${who}`);
    if (!dialogue.active()) this.fail(`talking to ${who} started no conversation`);
    const picked = [];
    for (let guard = 0; dialogue.active() && guard < 120; guard++) {
      const line = dialogue.current().line;
      if (line.choices.length) {
        let i = line.choices.findIndex((c) => prefs.includes(c.id));
        if (i < 0) i = 0;
        picked.push(line.choices[i].id);
        dialogue.choose(i);
      } else {
        dialogue.advance();
      }
      game.step(1);
    }
    if (dialogue.active()) this.fail(`the conversation with ${who} did not end`);
    this.trail.push(`talk ${who} [${picked}]`);
    this.settle();
    return picked;
  }

  /** Uses a puzzle object (the use key) and checks its screen opened. Returns the screens behaviour. */
  openPuzzle(objectId, puzzle) {
    this.use(objectId);
    const screens = game.find("screens").behaviour;
    if (screens.mode !== "puzzle" || screens.puzzle !== puzzle) this.fail(`using '${objectId}' did not open the '${puzzle}' screen (mode ${screens.mode}, puzzle '${screens.puzzle}')`);
    return screens;
  }

  /** Closes the puzzle screen with its Close button and lets the porter go free. */
  closePuzzle(screens) {
    game.click(game.find(screens.id("close")));
    game.step(6);
    if (screens.mode !== null) this.fail("the puzzle screen did not close");
  }

  /**
   * The chain that ends the storm, played in chapter 4 (the power is out): the library key, the library's ledger, the torn letter
   * pieced together, the date deduced on the board, the drawer opened with it, the cartridge, the mended fuse, the timetable
   * and the fuse box in the cellar. The screens are opened by using the objects; the moves inside them go through the puzzle
   * logic (the UI itself is tested in tests/puzzles.test.js and tests/screens.test.js).
   */
  fixTheFuse() {
    if (!story.has("power_out")) this.fail("the power is not out: this is for chapter 4");
    if (!items.has("library_key") && !story.has("open.library_door")) {
      this.go("cellar");
      this.use("p_cellar_box");
    }
    this.go("ground");
    if (!story.has("open.library_door")) this.use("library_door");
    if (!story.has("ledger_taken")) this.use("p_ledger_box");
    if (!story.has("letter_taken")) {
      this.go("upstairs");
      this.use("p_letter_box");
      this.go("ground");
    }
    // The letter: swap strips into place from the items page, as a player does ("Piece together").
    const order = puzzles.state("letter").order;
    for (let pos = 0; pos < order.length; pos++) {
      const at = order.indexOf(pos);
      if (at !== pos) puzzles.swapStrips(pos, at);
    }
    if (!story.has("letter_pieced")) this.fail("the torn letter did not piece together");
    // The board: letter + ledger give the date.
    const r = notebook.link("letter_whole", "ledger");
    if (!r.ok) this.fail(`the board refused letter_whole + ledger: ${r.key}`);
    // The drawer with the date.
    let screens = this.openPuzzle("p_library_desk", "drawer");
    for (let i = 0; i < 4; i++) while (puzzles.state("drawer").dials[i] !== Number(puzzles.data.drawer.code[i])) puzzles.turnDial(i, 1);
    puzzles.tryCode();
    this.closePuzzle(screens);
    if (!items.has("fuse_wire")) this.fail("the drawer gave no fuse wire");
    this.use("p_cartridge_box");
    if (!items.combine("fuse_wire", "fuse_cartridge").ok) this.fail("the fuse did not mend");
    // The timetable: bubble sort with the earlier/later moves.
    screens = this.openPuzzle("p_reception", "timetable");
    const want = puzzles.timetableSolution();
    for (let guard = 0; guard < 20 && puzzles.timetableOrder().join() !== want.join(); guard++) {
      const o = puzzles.timetableOrder();
      for (let i = 0; i < o.length - 1; i++) if (want.indexOf(o[i]) > want.indexOf(o[i + 1])) puzzles.moveService(i, 1);
    }
    puzzles.checkTimetable();
    this.closePuzzle(screens);
    // The fuse box in the cellar.
    this.go("cellar");
    screens = this.openPuzzle("p_fuse_box", "fuse");
    puzzles.fitFuse();
    for (const id of puzzles.breakerOrder()) puzzles.throwBreaker(id);
    this.closePuzzle(screens);
    if (!story.has("fuse_fixed") || !story.has("storm_over")) this.fail("the fuse box is not mended");
  }

  /** The state of the story as a stable string, and its hash: flags and counters sorted, the items sorted, the conversations in order. */
  state() {
    const s = story.snapshot();
    const sorted = (o) => Object.fromEntries(Object.keys(o).sort().map((k) => [k, o[k]]));
    return JSON.stringify({ flags: sorted(s.flags), counters: sorted(s.counters), items: [...items.list()].sort(), history: dialogue.history() });
  }
}

/** FNV-1a, 32 bits, as 8 hex digits. */
export function fnv1a(text) {
  let h = 0x811c9dc5;
  for (let i = 0; i < text.length; i++) {
    h ^= text.charCodeAt(i);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return h.toString(16).padStart(8, "0");
}
