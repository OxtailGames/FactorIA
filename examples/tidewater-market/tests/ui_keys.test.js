// The interface with the keyboard alone (P3): B, Esc, G, T, O, N, F1, R, Z, Y, X and Delete. The map clicks that pick a building
// use the mouse helper only to point (a key cannot point); every action under test is a key.
import { test, expect, game } from "factoria:test";
import { townScene, cellAt, textOf } from "./ui_helper.js";
import { put, runDays } from "./town_helper.js";

const key = (k) => {
  game.tapKey(k);
  game.step(2);
};
/** Escape triggers both the pause menu's action and the interface's (see pause_menu.js putAway). */
const escape = () => {
  game.press("pause");
  game.press("escape");
  game.step(1);
  game.release("pause");
  game.release("escape");
  game.step(2);
};

test("keys open and close the panels; F1 shows the help; Esc closes the newest thing first", () => {
  const { ctl, hud } = townScene();
  key("B");
  expect(hud.buildOpen).toBe(true);
  expect(game.find("build_bar").active).toBe(true);
  key("G");
  expect(game.find("goods_panel").active).toBe(true);
  key("T");
  expect(game.find("charts_panel").active).toBe(true);
  key("F1");
  expect(game.find("help_panel").active).toBe(true);
  key("M");
  expect(hud.overlay).toBe("desirability");
  key("M");
  key("M");
  key("M");
  key("M");
  expect(hud.overlay).toBe(null);
  // Esc closes in reverse order of opening: help, charts, goods, and only then the build bar
  escape();
  expect(game.find("help_panel").active).toBe(false);
  expect(game.find("charts_panel").active).toBe(true);
  escape();
  expect(game.find("charts_panel").active).toBe(false);
  escape();
  expect(game.find("goods_panel").active).toBe(false);
  expect(hud.buildOpen).toBe(true);
  escape();
  expect(hud.buildOpen).toBe(false);
  expect(game.paused).toBe(false); // none of these Esc opened the pause menu
  expect(ctl.tool.kind).toBe("none");
  key("G");
  key("G");
  expect(game.find("goods_panel").active).toBe(false); // the same key toggles
});

test("keys: X demolish tool, R rotate, Delete removes the selected building, Z and Y undo and redo, Esc drops the tool", () => {
  const { ctl, rig, hud, state, ids } = townScene();
  key("X");
  expect(ctl.tool.kind).toBe("demolish");
  escape();
  expect(ctl.tool.kind).toBe("none");
  // select the farm and rotate it
  game.click(cellAt(rig, 5, 3));
  expect(hud.sel.id).toBe(ids.farm);
  key("R");
  expect(state.list("farm")[0].rot).toBe(1);
  expect(hud.sel.kind).toBe("building");
  key("Z");
  expect(state.list("farm")[0].rot).toBe(0);
  key("Y");
  expect(state.list("farm")[0].rot).toBe(1);
  // Delete takes the selected building away
  game.click(cellAt(rig, 5, 3));
  expect(hud.sel.kind).toBe("building");
  key("Delete");
  expect(state.list("farm")).toHaveLength(0);
  expect(hud.sel).toBe(null);
  key("Z");
  expect(state.list("farm")).toHaveLength(1);
  // Delete with nothing selected arms the demolish tool
  hud.deselect();
  key("Delete");
  expect(ctl.tool.kind).toBe("demolish");
  escape();
  // Esc on the selection puts it away
  game.click(cellAt(rig, 5, 3));
  expect(hud.sel).not.toBe(null);
  escape();
  expect(hud.sel).toBe(null);
});

test("keys: N jumps to the newest notification and selects the building it names", () => {
  const { rig, hud, state } = townScene();
  const lonely = put(state, "sawmill", 9, 6);
  runDays(state, 2);
  game.step(30);
  rig.setView(0, 0, 1);
  game.step(2);
  key("N");
  expect(hud.sel).toEqual({ kind: "building", id: lonely.id });
  expect(game.find("inspector").active).toBe(true);
});
