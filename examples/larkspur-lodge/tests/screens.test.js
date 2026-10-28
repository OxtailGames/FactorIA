// The journal (items with the 3D view, notebook, deduction board) and the four puzzle screens, driven the way a player drives
// them: by clicking the real buttons, with the keyboard, with a gamepad only and with touch only.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { scene, ui } from "factoria";
import { Bot } from "./helpers/bot.js";
import { enter, porter, cam } from "./helpers/lodge.js";
import * as story from "../scripts/story.js";
import * as items from "../scripts/items.js";
import * as puzzles from "../scripts/puzzles.js";
import * as notebook from "../scripts/notebook.js";
import * as save from "../scripts/save_data.js";
import { screenState } from "../scripts/ui/screen_state.js";
import { MenuStack } from "../scripts/ui/menu_stack.js";
import strings from "../locales/en.json";

const screens = () => game.find("screens").behaviour;
/** A widget of the screen built now, by its short name ("tab_board", "card_oil"). */
const w = (name) => game.find(screens().id(name));
/** The text of a label of the screen built now. */
const text = (name) => game.find(screens().id(name) + "_t").get("Text").text;
const click = (name) => {
  game.click(w(name));
  game.step(2);
};
/** The middle of the view where the item shows. */
const HOLE_MID = [630, 264];

const fresh = () => {
  enter("ground");
  game.step(200); // the area title has faded: nothing draws over the screens
};

describe("opening and closing", () => {
  beforeEach(fresh);
  test("the HUD buttons open the journal; the porter is locked and the camera and pause menu stand down", () => {
    expect(game.find("hud_items").active).toBe(true);
    game.click(game.find("hud_notebook"));
    game.step(3);
    expect(screens().mode).toBe("journal");
    expect(screens().tab).toBe("notebook");
    expect(porter().behaviour.locked).toBe(true);
    expect(screenState.open).toBe(true);
    expect(MenuStack.busy).toBe(true);
    expect(game.find("hud_items").active).toBe(false);
    const yaw = cam().behaviour.yaw;
    game.mouseMove([200, 300]);
    game.mouseDown("right");
    game.mouseMove([300, 300]);
    game.step(2);
    game.mouseUp("right");
    expect(cam().behaviour.yaw).toBe(yaw);
    game.tapKey("Escape"); // Escape is pause and cancel at once: it closes the screen, it does not pause the game
    game.step(1);
    expect(screens().mode).toBe(null);
    expect(game.find("pause_panel").active).toBe(false);
  });

  test("the porter is free again two frames after the screen closes, and the HUD buttons come back", () => {
    game.tap("inventory");
    game.step(2);
    expect(screens().mode).toBe("journal");
    expect(screens().tab).toBe("items");
    click("close");
    expect(screens().mode).toBe(null);
    screens().open("items");
    game.step(2);
    screens().close();
    expect(porter().behaviour.locked).toBe(true); // the click that closed it must not walk him
    game.step(1);
    expect(porter().behaviour.locked).toBe(true);
    game.step(4);
    expect(porter().behaviour.locked).toBe(false);
    expect(screenState.open).toBe(false);
    expect(MenuStack.busy).toBe(false);
    expect(game.find("hud_items").active).toBe(true);
  });

  test("the keys: I toggles the items page, N the notebook, Tab and PageUp change the page", () => {
    game.tap("inventory");
    game.step(2);
    game.tap("notebook");
    game.step(2);
    expect(screens().tab).toBe("notebook");
    game.tap("tab_next");
    game.step(2);
    expect(screens().tab).toBe("board");
    game.tap("tab_next");
    game.step(2);
    expect(screens().tab).toBe("items");
    game.tap("tab_prev");
    game.step(2);
    expect(screens().tab).toBe("board");
    game.tap("inventory");
    game.step(2);
    expect(screens().tab).toBe("items");
    game.tap("inventory");
    game.step(2);
    expect(screens().mode).toBe(null);
  });

  test("it does not open in the middle of a conversation", () => {
    porter().behaviour.lock("test");
    game.tap("inventory");
    game.step(2);
    expect(screens().mode).toBe(null);
    porter().behaviour.unlock("test");
  });

  test("a scene change with a screen open never leaves the lodge locked", () => {
    screens().open("items");
    game.step(3);
    expect(MenuStack.busy).toBe(true);
    game.load("scenes/cellar.scene.json", { arrive: "spawn_default" });
    game.step(30);
    expect(scene.current).toBe("scenes/cellar.scene.json");
    expect(screenState.open).toBe(false);
    expect(MenuStack.busy).toBe(false);
    expect(porter().behaviour.locked).toBe(false);
    expect(screens().mode).toBe(null);
  });
});

describe("the items page", () => {
  beforeEach(fresh);
  beforeEach(() => {
    items.add("library_key");
    items.add("lamp_oil");
    items.add("torn_letter");
  });

  test("it lists what the porter carries; picking one shows its name and description", () => {
    screens().open("items");
    game.step(3);
    expect(screens().selItem).toBe("library_key");
    click("item_lamp_oil");
    expect(screens().selItem).toBe("lamp_oil");
    expect(text("name")).toBe(strings.item.lamp_oil.name);
    game.screenshot(".factoria/screenshots/p3_items.png");
  });

  test("with nothing carried it says so", () => {
    items.reset();
    screens().open("items");
    game.step(3);
    expect(text("empty")).toBe(strings.screens.empty);
  });

  test("the item turns when it is dragged with the mouse inside the view, and only there", () => {
    screens().open("items");
    game.step(3);
    const v = screens().view;
    expect(v.item).toBe("library_key");
    const yaw = v.yaw;
    game.mouseMove([100, 300]); // outside the view
    game.mouseDown();
    game.step(1);
    game.mouseMove([200, 300]);
    game.step(2);
    game.mouseUp();
    game.step(1);
    expect(v.yaw).toBe(yaw);
    game.mouseMove(HOLE_MID);
    game.step(1);
    game.mouseDown();
    game.step(1);
    game.mouseMove([HOLE_MID[0] + 60, HOLE_MID[1] + 20]);
    game.step(2);
    game.mouseUp();
    game.step(1);
    expect(v.yaw).toBeGreaterThan(yaw + 20);
    expect(v.pitch).toBeGreaterThan(15);
    const part = game.find(screens().viewParts.id);
    expect(part.get("Transform").rotation[1]).toBeCloseTo(v.yaw, 3);
    game.screenshot(".factoria/screenshots/p3_items_turned.png");
  });

  test("the item is a CameraView on a studio-lit camera: no bands around a hole, no darkened colours", () => {
    screens().open("items");
    game.step(3);
    const view = w("view");
    expect(view).not.toBe(null);
    expect(view.has("CameraView")).toBe(true);
    expect(view.get("CameraView").camera).toBe(screens().viewCam.id);
    const cam = screens().viewCam.get("Camera");
    expect(cam.primary).toBe(false);
    expect(cam.lighting).toBe("studio");
    for (const band of ["band_top", "band_left", "band_right", "band_bottom"]) expect(w(band)).toBe(null);
    // The parts keep the colour the data gives them (the lodge lights are not in the view, so nothing needs to dim them).
    const first = items.get("library_key").view.parts[0];
    const part = game.find(screens().viewParts.id.replace(/_stage$/, "_p0"));
    expect(part).not.toBe(null);
    expect(part.get("MeshRenderer").color).toEqual(first.color ?? [1, 1, 1, 1]);
  });

  test("the wheel over the view zooms it; over the list it does not", () => {
    screens().open("items");
    game.step(3);
    const v = screens().view;
    game.mouseMove(HOLE_MID);
    game.step(1);
    game.wheel(1);
    game.step(2);
    expect(v.zoom).toBeLessThan(1);
    const z = v.zoom;
    game.mouseMove([100, 300]);
    game.step(1);
    game.wheel(1);
    game.step(2);
    expect(v.zoom).toBe(z);
  });

  test("the zoom buttons, the zoom keys, the triggers and the right stick zoom and turn it; picking another item starts it fresh", () => {
    screens().open("items");
    game.step(3);
    const v = screens().view;
    click("zoom_in");
    expect(v.zoom).toBeLessThan(1);
    click("zoom_out");
    click("zoom_out");
    expect(v.zoom).toBeGreaterThan(1);
    const z = v.zoom;
    game.keyDown("V");
    game.step(10);
    game.keyUp("V");
    expect(v.zoom).toBeGreaterThan(z);
    const yaw = v.yaw;
    const pad = game.gamepad(0);
    pad.axis("RightTrigger", 1);
    game.step(10);
    pad.axis("RightTrigger", 0);
    expect(v.zoom).toBeLessThan(z + 0.0001);
    pad.axis("RightX", 1);
    game.step(10);
    pad.axis("RightX", 0);
    expect(v.yaw).not.toBe(yaw);
    click("item_lamp_oil");
    expect(v.item).toBe("lamp_oil");
    expect(v.yaw).toBe(25);
    expect(v.zoom).toBe(1);
  });

  test("the 3D view goes away with the screen", () => {
    screens().open("items");
    game.step(3);
    const camId = screens().viewCam.id;
    expect(game.find(camId)).not.toBe(null);
    click("close");
    game.step(2);
    expect(game.find(camId)).toBe(null);
  });

  test("the torn letter is read in rich text and can be pieced together from here", () => {
    screens().open("items");
    game.step(3);
    click("item_torn_letter");
    expect(w("read")).not.toBe(null);
    game.screenshot(".factoria/screenshots/p3_items_letter.png");
    click("piece");
    expect(screens().mode).toBe("puzzle");
    expect(screens().puzzle).toBe("letter");
    click("close"); // back to the items page, not out of the screen
    expect(screens().mode).toBe("journal");
    expect(screens().tab).toBe("items");
  });

  test("combining: pick Combine, then the other item; a pair that does not fit is refused and nothing is lost", () => {
    items.add("fuse_wire");
    items.add("fuse_cartridge");
    screens().open("items");
    game.step(3);
    click("item_fuse_wire");
    click("combine");
    expect(screens().combineFrom).toBe("fuse_wire");
    click("item_lamp_oil");
    expect(screens().message).toBe(strings.combo.refuse);
    expect(items.has("fuse_wire")).toBe(true);
    expect(items.has("lamp_oil")).toBe(true);
    click("combine");
    click("item_fuse_cartridge");
    expect(items.has("fuse_mended")).toBe(true);
    expect(items.has("fuse_wire")).toBe(false);
    expect(screens().selItem).toBe("fuse_mended");
    expect(screens().message).toBe(strings.combo.fuse_mended);
  });
});

describe("the notebook and the board", () => {
  beforeEach(fresh);
  beforeEach(() => {
    for (const f of ["know_oil", "know_cellar", "adit_known", "know_page"]) story.set(f);
  });

  test("an empty notebook says so; known clues are listed in rich text", () => {
    story.reset();
    screens().open("notebook");
    game.step(3);
    expect(text("empty")).toBe(strings.screens.noClues);
    story.set("know_oil");
    screens().dirty = true;
    game.step(2);
    expect(w("note_oil")).not.toBe(null);
    game.screenshot(".factoria/screenshots/p3_notebook.png");
  });

  test("clicking an entry of the notebook finds it on the board", () => {
    screens().open("notebook");
    game.step(3);
    click("note_cellar");
    expect(screens().tab).toBe("board");
    expect(screens().sel).toBe("cellar");
    expect(w("detail")).not.toBe(null);
  });

  test("two cards linked make a deduction, draw a string and set the flag; unknown clues show an empty slot", () => {
    screens().open("board");
    game.step(3);
    expect(w("slot_argument")).not.toBe(null);
    expect(w("card_argument")).toBe(null);
    click("card_oil");
    expect(screens().sel).toBe("oil");
    click("card_cellar");
    expect(story.has("ded.d_trail")).toBe(true);
    expect(w("card_d_trail")).not.toBe(null);
    expect(w("string_d_trail_oil")).not.toBe(null);
    expect(screens().message).toBe(strings.board.made.replace("{name}", strings.notebook.ded.d_trail.title));
    game.screenshot(".factoria/screenshots/p3_board.png");
  });

  test("a pair that leads nowhere says so", () => {
    screens().open("board");
    game.step(3);
    click("card_oil");
    click("card_page");
    expect(notebook.made()).toEqual([]);
    expect(screens().message).toBe(strings.board.nothing);
  });

  test("Undo and Redo, by button and by key, take deductions back and forth", () => {
    screens().open("board");
    game.step(3);
    click("card_oil");
    click("card_cellar");
    click("card_adit"); // the new deduction stays picked: the next card links to it
    expect(notebook.made()).toEqual(["d_trail", "d_adit"]);
    click("undo");
    expect(notebook.made()).toEqual(["d_trail"]);
    expect(story.has("ded.d_adit")).toBe(false);
    expect(w("card_d_adit")).toBe(null);
    expect(w("slot_d_adit")).not.toBe(null);
    game.tap("board_undo"); // Z
    game.step(2);
    expect(notebook.made()).toEqual([]);
    expect(story.has("ded.d_trail")).toBe(false);
    expect(w("undo").get("Button").interactable).toBe(false);
    game.tap("board_redo"); // Y
    game.step(2);
    expect(notebook.made()).toEqual(["d_trail"]);
    click("redo");
    expect(notebook.made()).toEqual(["d_trail", "d_adit"]);
    expect(w("redo").get("Button").interactable).toBe(false);
  });

  test("a new clue is announced on the HUD once, and not while a screen is open", () => {
    notebook.markSeen();
    story.set("know_argument");
    game.step(2);
    expect(game.find("hud").behaviour.message).toBe(strings.notebook.new.replace("{name}", strings.notebook.clue.argument.title));
    screens().open("board");
    game.step(2);
    story.set("survey_known");
    game.step(2);
    expect(game.find("hud").behaviour.message).not.toContain(strings.notebook.clue.survey.title);
  });
});

describe("the puzzle screens", () => {
  beforeEach(fresh);
  test("the drawer: the wheels turn by button, a wrong code is refused, the right one opens it", () => {
    screens().openPuzzle("drawer");
    game.step(3);
    expect(screens().mode).toBe("puzzle");
    click("up_0");
    expect(text("dial_0")).toBe("1");
    click("down_0");
    click("down_0");
    expect(text("dial_0")).toBe("9");
    click("try");
    expect(screens().message).toBe(strings.puzzle.drawer.wrong);
    game.screenshot(".factoria/screenshots/p3_puzzle_drawer.png");
    for (let i = 0; i < 4; i++) while (puzzles.state("drawer").dials[i] !== Number("0403"[i])) click(`up_${i}`);
    click("try");
    expect(items.has("fuse_wire")).toBe(true);
    expect(story.has("switch_card_found")).toBe(true);
    expect(w("try").get("Button").interactable).toBe(false);
  });

  test("the timetable: the earlier and later buttons move rows; the check solves it", () => {
    screens().openPuzzle("timetable");
    game.step(3);
    click("check");
    expect(screens().message).toBe(strings.puzzle.timetable.wrong);
    expect(w("earlier_0").get("Button").interactable).toBe(false);
    game.screenshot(".factoria/screenshots/p3_puzzle_timetable.png");
    const want = puzzles.timetableSolution();
    for (let guard = 0; guard < 20 && puzzles.timetableOrder().join() !== want.join(); guard++) {
      const o = puzzles.timetableOrder();
      for (let i = 0; i < o.length - 1; i++) {
        if (want.indexOf(o[i]) > want.indexOf(o[i + 1])) click(`later_${i}`);
      }
    }
    click("check");
    expect(story.has("timetable_solved")).toBe(true);
    expect(screens().message).toBe(strings.puzzle.timetable.solved);
    expect(w("check").get("Button").interactable).toBe(false);
  });

  test("the letter: pick two strips to swap them; the last swap pieces the letter together", () => {
    items.add("torn_letter");
    screens().openPuzzle("letter");
    game.step(3);
    game.screenshot(".factoria/screenshots/p3_puzzle_letter.png");
    const order = puzzles.state("letter").order;
    for (let pos = 0; pos < order.length; pos++) {
      const at = order.indexOf(pos);
      if (at !== pos) {
        click(`strip_${pos}`);
        click(`strip_${at}`);
      }
    }
    expect(story.has("letter_pieced")).toBe(true);
    expect(screens().message).toBe(strings.puzzle.letter.solved);
  });

  test("the fuse box: no power, no fuse, a wrong breaker, then the right four", () => {
    screens().openPuzzle("fuse");
    game.step(3);
    click("fit");
    expect(screens().message).toBe(strings.puzzle.fuse.noPower);
    story.set("power_out");
    click("fit");
    expect(screens().message).toBe(strings.puzzle.fuse.noFuse);
    items.add("fuse_mended");
    click("fit");
    expect(items.has("fuse_mended")).toBe(false);
    expect(w("fit").get("Button").interactable).toBe(false);
    click("breaker_coach");
    expect(screens().message).toBe(strings.puzzle.fuse.trip);
    game.screenshot(".factoria/screenshots/p3_puzzle_fuse.png");
    for (const id of puzzles.breakerOrder()) click(`breaker_${id}`);
    expect(story.has("fuse_fixed")).toBe(true);
    expect(story.has("storm_over")).toBe(true);
  });

  test("Escape closes a puzzle opened from an object", () => {
    screens().openPuzzle("drawer");
    game.step(3);
    game.tapKey("Escape");
    game.step(1);
    expect(screens().mode).toBe(null);
  });

  test("using the puzzle objects in the lodge (the use key) opens their screens, and closing returns the porter", () => {
    const bot = new Bot();
    const s = bot.openPuzzle("p_reception", "timetable");
    expect(s.mode).toBe("puzzle");
    bot.closePuzzle(s);
    game.step(4);
    expect(porter().behaviour.locked).toBe(false);
    expect(bot.openPuzzle("p_library_desk", "drawer").mode).toBe("puzzle");
  });

  test("a puzzle that is not ready is a line on the screen, not a dead end: the letter without the letter", () => {
    screens().openPuzzle("letter");
    game.step(3);
    click("strip_0");
    click("strip_1");
    expect(screens().message).toBe(strings.puzzle.letter.noItem);
  });
});

describe("saves", () => {
  beforeEach(fresh);
  test("the puzzles in progress and the board are in the save snapshot and come back", () => {
    story.set("know_oil");
    story.set("know_cellar");
    notebook.link("oil", "cellar");
    puzzles.turnDial(2, 3);
    puzzles.moveService(0, 1);
    const data = JSON.parse(JSON.stringify(save.snapshot()));
    expect(data.state.puzzles.drawer.dials).toEqual([0, 0, 3, 0]);
    expect(data.state.notebook.board.deductions).toEqual(["d_trail"]);
    puzzles.reset();
    notebook.reset();
    expect(save.apply(data).ok).toBe(true);
    expect(puzzles.dialsText()).toBe("0030");
    expect(notebook.made()).toEqual(["d_trail"]);
  });
});

describe("gamepad only", () => {
  beforeEach(fresh);
  test("X opens the journal, the shoulders turn the page, the stick and A combine two items, the triggers undo, B closes", () => {
    items.add("fuse_wire");
    items.add("fuse_cartridge");
    const pad = game.gamepad(0);
    pad.connect({ type: "xbox" });
    pad.tap("X");
    game.step(2);
    expect(screens().mode).toBe("journal");
    expect(screens().tab).toBe("items");
    expect(screens().selItem).toBe("fuse_wire");
    pad.tap("DpadDown");
    pad.tap("A");
    expect(screens().selItem).toBe("fuse_cartridge");
    pad.tap("DpadUp");
    pad.tap("A");
    expect(screens().selItem).toBe("fuse_wire");
    // From the list the pad reaches the Combine button under it, picks it, goes back up and picks the other item.
    pad.tap("DpadDown");
    pad.tap("DpadDown");
    expect(ui_focused()).toBe(screens().id("combine"));
    pad.tap("A");
    expect(screens().combineFrom).toBe("fuse_wire");
    pad.tap("DpadUp");
    expect(ui_focused()).toBe(screens().id("item_fuse_cartridge"));
    pad.tap("A");
    expect(items.has("fuse_mended")).toBe(true);
    game.screenshot(".factoria/screenshots/p3_gamepad_items.png");
    // The shoulders: items -> notebook -> board; the left trigger undoes a deduction.
    story.set("know_oil");
    story.set("know_cellar");
    notebook.link("oil", "cellar");
    pad.tap("RightShoulder");
    game.step(2);
    expect(screens().tab).toBe("notebook");
    pad.tap("RightShoulder");
    game.step(2);
    expect(screens().tab).toBe("board");
    pad.axis("LeftTrigger", 1);
    game.step(2);
    pad.axis("LeftTrigger", 0);
    game.step(2);
    expect(notebook.made()).toEqual([]);
    pad.tap("B");
    game.step(1);
    expect(screens().mode).toBe(null);
    game.step(4);
    expect(porter().behaviour.locked).toBe(false);
  });

  test("a puzzle with the pad: the drawer wheels turn with A on the plus buttons", () => {
    const pad = game.gamepad(0);
    pad.connect({ type: "xbox" });
    screens().openPuzzle("drawer");
    game.step(3);
    expect(ui_focused()).toBe(screens().id("up_0"));
    pad.tap("A");
    expect(puzzles.dialsText()).toBe("1000");
    pad.tap("DpadRight");
    pad.tap("A");
    expect(puzzles.dialsText()).toBe("1100");
  });
});

describe("touch only", () => {
  beforeEach(fresh);
  test("a finger opens the journal from the HUD, picks an item, turns it, pinches to come closer and closes it", () => {
    items.add("library_key");
    items.add("lamp_oil");
    game.touch(game.find("hud_items"), 3);
    game.step(2);
    expect(screens().mode).toBe("journal");
    game.touch(w("item_lamp_oil"), 3);
    game.step(2);
    expect(screens().selItem).toBe("lamp_oil");
    const v = screens().view;
    const yaw = v.yaw;
    game.touchStart(HOLE_MID, 1);
    game.step(2);
    game.touchMove([HOLE_MID[0] + 80, HOLE_MID[1]], 1);
    game.step(3);
    game.touchEnd(1);
    game.step(2);
    expect(v.yaw).toBeGreaterThan(yaw + 20);
    // Pinch: two fingers moving apart come closer to the item.
    const z = v.zoom;
    game.touchStart([HOLE_MID[0] - 20, HOLE_MID[1]], 1);
    game.touchStart([HOLE_MID[0] + 20, HOLE_MID[1]], 2);
    game.step(2);
    game.touchMove([HOLE_MID[0] - 90, HOLE_MID[1]], 1);
    game.touchMove([HOLE_MID[0] + 90, HOLE_MID[1]], 2);
    game.step(3);
    game.touchEnd(1);
    game.touchEnd(2);
    game.step(2);
    expect(v.zoom).toBeLessThan(z);
    game.screenshot(".factoria/screenshots/p3_touch_items.png");
    game.touch(w("close"), 3);
    game.step(6);
    expect(screens().mode).toBe(null);
    expect(porter().behaviour.locked).toBe(false);
  });

  test("a finger uses the board: two taps on two cards link them", () => {
    story.set("know_oil");
    story.set("know_cellar");
    game.touch(game.find("hud_notebook"), 3);
    game.step(2);
    game.touch(w("tab_board"), 3);
    game.step(2);
    game.touch(w("card_oil"), 3);
    game.step(2);
    game.touch(w("card_cellar"), 3);
    game.step(2);
    expect(story.has("ded.d_trail")).toBe(true);
  });
});

/** The id of the widget with the focus. */
function ui_focused() {
  return ui.focused?.id ?? "";
}
