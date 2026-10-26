// Helpers for the tests that play through the interface (the build menu, the panels), not through the state.
import { game } from "factoria:test";
import { ui } from "factoria";
import { getData } from "../scripts/game/data.js";
import { cellToWorld } from "../scripts/game/iso.js";
import { smallTown, fillHouses, runSeconds } from "./town_helper.js";

/** Open the build menu (when it is closed), open the tab of the building and click its item, like a player. */
export function pickFromMenu(type) {
  const data = getData();
  if (!game.find("build_bar").active) game.click("btn_build");
  game.click(`cat_${data.buildings[type].category}`);
  game.click(`tool_${type}`);
}

/** The text of a Text or Button entity. */
export function textOf(id) {
  const e = typeof id === "string" ? game.find(id) : id;
  return e.has("Text") ? e.get("Text").text : e.get("Button").text;
}

/** Is a widget shown (active) and does it have a rectangle on screen? */
export function shown(id) {
  const e = game.find(id);
  return !!e && e.activeInHierarchy !== false && !!ui.rectOf(e);
}

/** Do two widget rectangles overlap? */
export function overlaps(a, b) {
  const ra = ui.rectOf(a);
  const rb = ui.rectOf(b);
  return !!ra && !!rb && ra.x < rb.x + rb.w && rb.x < ra.x + ra.w && ra.y < rb.y + rb.h && rb.y < ra.y + ra.h;
}

/** The screen point of a map cell's centre, for clicks and mouse moves. */
export function cellAt(rig, c, r) {
  const [x, y] = cellToWorld(c, r);
  const [sx, sy] = rig.worldToScreen(x, y);
  return { x: sx, y: sy };
}

/** The middle of a widget, as a point. */
export function centreOf(id) {
  const r = ui.rectOf(typeof id === "string" ? game.find(id) : id);
  return { x: r.x + r.w / 2, y: r.y + r.h / 2 };
}

/**
 * The game scene on the small test map with the working town of town_helper.js built in it, the houses full and the clock run for
 * `seconds` game seconds; the camera looks at the middle of the town. The clock is paused so the numbers stay put while a test
 * clicks around (a test that needs time to pass sets the speed again or runs the clock itself).
 */
export function townScene({ seconds = 30, parts } = {}) {
  game.load("scenes/game.scene.json", { testMap: true });
  game.step(3);
  const ctl = game.find("controller").behaviour;
  const rig = game.find("camera").behaviour;
  const { ids } = smallTown({ game: ctl.state, parts });
  fillHouses(ctl.state);
  runSeconds(ctl.state, seconds);
  ctl.state.clock.setSpeed(0);
  const [x, y] = cellToWorld(5, 5);
  rig.setView(x, y, 1);
  game.step(3);
  return { ctl, rig, hud: ctl.hud, state: ctl.state, ids };
}
