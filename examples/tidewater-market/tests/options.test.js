// P6 options and accessibility: saved and applied after a restart, rebinding with a conflict, reduced motion, hold-free
// controls, and the notice that shows the number as it is now.
import { test, expect, game } from "factoria:test";
import { audio, input, scene, session, storage, ui } from "factoria";
import * as settings from "../scripts/settings.js";
import { cellToWorld } from "../scripts/game/iso.js";
import { Notices } from "../scripts/game/ui_model.js";
import { townScene, textOf, shown, cellAt } from "./ui_helper.js";

/** What a new run of the game does to the engine: a new `session`, default volumes and sizes, then the first menu applies the saved settings. */
function restart() {
  delete session.settingsApplied;
  delete session.liveOptions;
  for (const bus of settings.BUSES) audio.setVolume(bus, 1);
  ui.textScale = 1;
  input.resetBindings();
  game.load("scenes/menu.scene.json");
  game.step(3);
  expect(scene.current).toBe("scenes/menu.scene.json");
}

function openOptions() {
  game.load("scenes/menu.scene.json");
  game.step(3);
  game.click("options_button");
  game.step(3);
}

test("options: what the player chose is saved and in effect after a restart", () => {
  storage.clear();
  openOptions();
  // the Access tab: text size, interface size and the three switches, by clicking
  game.click("tab_access");
  game.step(2);
  game.click("text_scale"); // 100 % -> 125 %
  game.click("ui_scale"); // 100 % -> 125 %
  game.click("safe_colors");
  game.click("reduced_motion");
  game.click("hold_free");
  game.step(2);
  expect(textOf("text_scale")).toContain("125");
  expect(textOf("ui_scale")).toContain("125");
  expect(ui.textScale).toBeCloseTo(1.25);
  // a volume of each kind, written the way the Audio tab writes it
  const s = settings.load();
  s.volume = { master: 0.8, music: 0.35, ambience: 0.45, sfx: 0.7, ui: 0.55 };
  settings.save(s);
  const saved = storage.get("settings");
  expect(saved.textScale).toBeCloseTo(1.25);
  expect(saved.uiScale).toBeCloseTo(1.25);
  expect(saved.safeColors).toBe(true);
  expect(saved.reducedMotion).toBe(true);
  expect(saved.holdFree).toBe(true);

  // the restart: the engine and the module state forget everything, the storage keeps the file
  restart();
  expect(audio.getVolume("master")).toBeCloseTo(0.8);
  expect(audio.getVolume("music")).toBeCloseTo(0.35);
  expect(audio.getVolume("sfx")).toBeCloseTo(0.7);
  expect(audio.getVolume("ui")).toBeCloseTo(0.55);
  expect(audio.getVolume("ambience")).toBeCloseTo(0.45);
  expect(ui.textScale).toBeCloseTo(1.25);
  expect(ui.scale).toBeCloseTo(1.25);
  const live = settings.live();
  expect(live.safeColors).toBe(true);
  expect(live.reducedMotion).toBe(true);
  expect(live.holdFree).toBe(true);
  // and the options screen shows them
  game.click("options_button");
  game.step(3);
  game.click("tab_access");
  game.step(2);
  expect(game.find("safe_colors").get("Toggle").value).toBe(true);
  expect(textOf("ui_scale")).toContain("125");
  // put the defaults back for the tests after this one
  storage.clear();
  settings.apply(settings.load());
});

test("options: rebinding refuses a button another action has, says which, and keeps the old binding", () => {
  storage.clear();
  input.resetBindings();
  openOptions();
  game.click("tab_controls");
  game.step(2);
  expect(input.bindings("tool_next")).toContain("E");
  expect(input.bindings("tool_prev")).toContain("C");
  const bind = (action, byMouse) => {
    ui.focus(`bind_${action}`); // a row scrolled out of view scrolls in when it is focused
    game.step(2);
    if (byMouse) game.click(`bind_${action}`);
    else game.tapKey("Enter");
    game.step(2);
    expect(textOf(`bind_${action}`)).toContain("press a key"); // waiting for a button
  };
  bind("tool_next");
  game.tapKey("C"); // the button of tool_prev
  game.step(2);
  expect(input.bindings("tool_next")).toContain("E");
  expect(input.bindings("tool_next")).not.toContain("C");
  expect(input.bindings("tool_prev")).toContain("C");
  const note = textOf("controls_note");
  expect(note).toContain("already does");
  expect(note).toContain(input.buttonName("C")); // it names the button
  expect(storage.get("settings", {}).bindings?.tool_next).toBe(undefined);
  // a free button is taken, saved and kept by a restart
  bind("tool_next"); // a second time by keyboard: the button keeps working after a refusal
  game.tapKey("J");
  game.step(2);
  expect(input.bindings("tool_next")).toEqual(["J"]);
  expect(storage.get("settings").bindings.tool_next).toEqual(["J"]);
  expect(textOf("controls_note")).toBe("");
  restart();
  expect(input.bindings("tool_next")).toEqual(["J"]);
  // reset puts the defaults back
  game.click("options_button");
  game.step(3);
  game.click("tab_controls");
  game.step(2);
  game.click("reset_controls");
  expect(input.bindings("tool_next")).toContain("E");
  storage.clear();
});

test("reduced motion: the camera does not ease and notices do not fade", () => {
  const { rig, hud } = townScene({ trade: true });
  const [x, y] = cellToWorld(3, 4);
  settings.apply({ ...settings.load(), reducedMotion: false });
  rig.moveTo(x, y);
  expect(rig.ease).not.toBe(null); // eased: not there yet
  expect(Math.hypot(rig.view.x - x, rig.view.y - y)).toBeGreaterThan(20);
  game.step(30);
  expect(rig.ease).toBe(null);
  expect(rig.view.x).toBeCloseTo(x, 0);
  expect(rig.view.y).toBeCloseTo(y, 0);
  // the same move with the option on is one step
  const [x2, y2] = cellToWorld(7, 6);
  settings.apply({ ...settings.load(), reducedMotion: true });
  rig.moveTo(x2, y2);
  expect(rig.ease).toBe(null);
  expect(rig.view.x).toBeCloseTo(x2, 0);
  expect(rig.view.y).toBeCloseTo(y2, 0);
  // a notice that has just appeared is fully there and does not fade out either
  expect(Notices.opacity({ age: 0, ttl: 6 }, false)).toBe(0);
  expect(Notices.opacity({ age: 0, ttl: 6 }, true)).toBe(1);
  expect(Notices.opacity({ age: 5.5, ttl: 0.5 }, false)).toBeLessThan(1);
  expect(Notices.opacity({ age: 5.5, ttl: 0.5 }, true)).toBe(1);
  hud.notices.push("broke", {}, null, 0, "bad");
  game.step(1);
  expect(hud.notices.items.length).toBeGreaterThan(0);
  settings.apply({ ...settings.load(), reducedMotion: false });
});

test("reduced motion: the title picture stands still", () => {
  settings.apply({ ...settings.load(), reducedMotion: false });
  game.load("scenes/menu.scene.json");
  game.step(30);
  const cam = game.find("camera");
  const moving = cam.position.x;
  game.step(60);
  expect(cam.position.x).not.toBe(moving);
  settings.apply({ ...settings.load(), reducedMotion: true });
  game.step(2);
  const still = cam.position.x;
  game.step(60);
  expect(cam.position.x).toBe(still);
  settings.apply({ ...settings.load(), reducedMotion: false });
});

test("notices: a repeated notice shows the number as it is now, not the number of the day it was first pushed", () => {
  const { hud } = townScene({ trade: true });
  let hungry = 3;
  const live = () => (hungry > 0 ? { count: hungry } : null);
  hud.notices.push("hungry", { count: hungry }, null, 0, "bad", live);
  game.step(20);
  const slot = [0, 1, 2, 3, 4].find((i) => shown(`notice_${i}`) && textOf(`notice_${i}`).includes("villagers are hungry"));
  expect(slot).not.toBe(undefined);
  expect(textOf(`notice_${slot}`)).toContain("3");
  hungry = 17;
  hud.notices.push("hungry", { count: 4 }, null, 0, "bad", live); // pushed again with an old number: the live count wins
  game.step(30);
  const text = textOf(`notice_${slot}`);
  expect(text).toContain("17");
  expect(text).not.toContain(" 4 ");
  hungry = 0; // nobody is hungry: the notice goes
  game.step(40);
  expect([0, 1, 2, 3, 4].some((i) => shown(`notice_${i}`) && textOf(`notice_${i}`).includes("villagers are hungry"))).toBe(false);
});

test("hold-free: a road takes two clicks, the shoulders step the build tabs", () => {
  storage.clear();
  const s = settings.load();
  s.holdFree = true;
  settings.save(s);
  settings.apply();
  expect(settings.live().holdFree).toBe(true);
  game.load("scenes/game.scene.json", { testMap: true, music: false, speed: 0 });
  game.step(3);
  const ctl = game.find("controller").behaviour;
  const rig = game.find("camera").behaviour;
  const { state, hud } = ctl;
  const [x, y] = cellToWorld(5, 5);
  rig.setView(x, y, 1.5);
  game.step(3);
  let run = null;
  for (let r = 1; r < 9 && !run; r++) {
    for (let c = 1; c < 8 && !run; c++) {
      if ([0, 1, 2, 3].every((i) => state.check("road", c + i, r).ok)) run = { c, r };
    }
  }
  expect(run).not.toBe(null);
  const roads = state.list("road").length;
  game.click("btn_build");
  game.click("tool_road");
  expect(ctl.tool.kind).toBe("build");
  game.click(cellAt(rig, run.c, run.r)); // the first end: no button is held afterwards
  game.step(2);
  expect(state.list("road").length).toBe(roads); // nothing yet: the second click ends the road
  game.click(cellAt(rig, run.c + 3, run.r));
  game.step(2);
  expect(state.list("road").length).toBeGreaterThanOrEqual(roads + 4);

  const first = hud.cat;
  hud.stepCategory(1);
  expect(hud.cat).not.toBe(first);
  hud.stepCategory(-1);
  expect(hud.cat).toBe(first);
  s.holdFree = false;
  settings.save(s);
  settings.apply();
  expect(settings.live().holdFree).toBe(false);
});
