// The save slot screen of the title (scripts/ui/slots_screen.js): driven with the mouse alone and with the keyboard alone, from the
// title to the running game. Screenshots go to .factoria/tmp/ to look at.
import { test, expect, game } from "factoria:test";
import { storage, scene, ui } from "factoria";
import { growTown } from "../scripts/game/bot.js";
import { getData } from "../scripts/game/data.js";
import { newScenarioGame, GoalTracker } from "../scripts/game/scenarios.js";
import { writeEntry, readMeta, listSlots, latestEntry, dataKey, hasData } from "../scripts/game/save_store.js";
import { VERSION } from "../scripts/game/savegame.js";

const MENU = "scenes/menu.scene.json";
const GAME = "scenes/game.scene.json";

/** Two slots to list: slot 2 holds a town with an autosave, slot 3 holds another scenario; slot 1 is empty. */
function seed() {
  storage.clear();
  game.platform.reset(); // the fake cloud keeps its saves from test to test; the screen syncs with it when it opens
  const first = newScenarioGame("first_harbour", getData());
  const tracker = new GoalTracker(first.state, "first_harbour", first.def).attach();
  growTown({ state: first.state, days: 20 });
  const info = { scenario: "first_harbour", extra: tracker.saveFields(), progress: tracker.metaFields() };
  writeEntry(2, "manual", first.state, { ...info, name: "Old harbour", playSeconds: 754 });
  growTown({ state: first.state, days: 4 });
  writeEntry(2, "auto", first.state, { ...info, playSeconds: 900 });
  const river = newScenarioGame("river_mills", getData());
  growTown({ state: river.state, days: 10 });
  writeEntry(3, "manual", river.state, { scenario: "river_mills", name: "Mill town", playSeconds: 120 });
  return { first: first.state, river: river.state };
}

function openTitle() {
  game.load(MENU);
  game.step(3);
  expect(scene.current).toBe(MENU);
}

/** Wait for the loading screen to hand over to the game scene (never act on the new scene before it is the current one). */
function waitForGame() {
  let guard = 0;
  while (scene.current !== GAME && guard++ < 400) game.step(1);
  expect(scene.current).toBe(GAME);
  game.step(3);
  return game.find("controller").behaviour;
}

const tap = (action) => {
  game.press(action);
  game.step(1);
  game.release(action);
  game.step(1);
};

test("mouse only: Play, an empty slot, a scenario: a new game of that scenario that belongs to the slot", () => {
  seed();
  openTitle();
  game.click("play");
  game.step(2);
  expect(game.find("slots_panel").active).toBe(true);
  expect(game.find("main_menu").active).toBe(false);
  game.screenshot(".factoria/tmp/slots.png");
  game.click("slot_1_main");
  game.step(2);
  expect(game.find("scenario_panel").active).toBe(true);
  expect(game.find("slots_panel").active).toBe(false);
  game.screenshot(".factoria/tmp/scenarios.png");
  game.click("scenario_river_mills");
  const ctl = waitForGame();
  expect(ctl.run.slot).toBe(1);
  expect(ctl.run.scenario).toBe("river_mills");
  expect(ctl.run.name).toBe("River Mills");
  expect(ctl.state.economy.coins).toBe(1000);
  expect(ctl.run.tracker.goals).toHaveLength(3);
  expect(ctl.state.clock.date().year).toBe(1);
});

test("mouse only: a slot loads the saved town, the autosave button its autosave, Continue the latest save", () => {
  const { first } = seed();
  openTitle();
  game.click("play");
  game.step(2);
  game.click("slot_2_main");
  let ctl = waitForGame();
  expect(ctl.run.slot).toBe(2);
  expect(ctl.run.scenario).toBe("first_harbour");
  expect(ctl.run.playSeconds).toBeGreaterThanOrEqual(754);
  expect(ctl.state.hash()).toBe(readMeta(2, "manual").hash);
  expect(ctl.run.tracker.id).toBe("first_harbour");

  openTitle();
  game.click("play");
  game.step(2);
  game.click("slot_2_auto");
  ctl = waitForGame();
  expect(ctl.state.hash()).toBe(readMeta(2, "auto").hash);
  expect(ctl.state.hash()).toBe(first.hash());

  openTitle();
  game.click("play");
  game.step(2);
  expect(latestEntry()).toMatchObject({ slot: 3, kind: "manual" }); // written last
  game.click("slots_continue");
  ctl = waitForGame();
  expect(ctl.run.slot).toBe(3);
  expect(ctl.state.hash()).toBe(readMeta(3, "manual").hash);
});

test("mouse only: rename keeps the game, delete asks first and takes both entries of the slot", () => {
  seed();
  openTitle();
  game.click("play");
  game.step(2);
  game.click("slot_2_rename");
  game.step(2);
  expect(game.find("rename_panel").active).toBe(true);
  game.find("rename_field").get("TextField").text = "";
  game.typeText("Harbour Two");
  game.step(2);
  game.click("rename_ok");
  game.step(2);
  expect(game.find("slots_panel").active).toBe(true);
  expect(readMeta(2, "manual").name).toBe("Harbour Two");
  expect(game.find("slot_2_info").get("Text").text).toContain("Harbour Two");

  game.click("slot_2_delete");
  game.step(2);
  expect(game.find("confirm_panel").active).toBe(true);
  expect(game.find("confirm_text").get("Text").text).toContain("Harbour Two");
  game.click("confirm_no");
  game.step(2);
  expect(hasData(2, "manual")).toBe(true);
  game.click("slot_2_delete");
  game.step(2);
  game.click("confirm_yes");
  game.step(2);
  expect(hasData(2, "manual")).toBe(false);
  expect(hasData(2, "auto")).toBe(false);
  expect(hasData(3, "manual")).toBe(true); // the other slot is untouched
  expect(game.find("slot_2_info").get("Text").text).toContain("Empty");
  expect(game.find("slots_panel").active).toBe(true);
});

test("a damaged or newer save is refused on the screen, with a sentence, and nothing starts", () => {
  seed();
  storage.set(dataKey(3, "manual"), '{"format":"tidewater.save","version":2,"map":'); // cut off
  openTitle();
  game.click("play");
  game.step(2);
  game.click("slot_3_main");
  game.step(2);
  expect(scene.current).toBe(MENU);
  const message = game.find("slots_message").get("Text").text;
  expect(message).toContain("could not be loaded");
  expect(message.length).toBeGreaterThan(30);
  const future = JSON.parse(JSON.stringify(storage.get(dataKey(2, "manual"))));
  future.version = VERSION + 1;
  storage.set(dataKey(2, "manual"), future);
  game.click("slot_2_main");
  game.step(2);
  expect(scene.current).toBe(MENU);
  expect(game.find("slots_message").get("Text").text).toContain("newer version");
  game.screenshot(".factoria/tmp/slots_refused.png");
});

test("keyboard only: Enter on Play, arrows to a slot, Enter starts it; Escape goes back one panel", () => {
  seed();
  openTitle();
  expect(ui.focused.id).toBe("play"); // autoFocus
  tap("ui_submit");
  expect(game.find("slots_panel").active).toBe(true);
  expect(ui.focused.id).toBe("slots_continue");
  tap("ui_down");
  expect(ui.focused.id).toBe("slot_1_main");
  tap("ui_submit"); // the empty slot: pick a scenario
  expect(game.find("scenario_panel").active).toBe(true);
  expect(ui.focused.id).toBe("scenario_first_harbour");
  tap("ui_cancel");
  expect(game.find("slots_panel").active).toBe(true);
  tap("ui_cancel");
  expect(game.find("main_menu").active).toBe(true);
  tap("ui_submit");
  expect(game.find("slots_panel").active).toBe(true);

  // slot 1 again, a scenario down the list
  tap("ui_down");
  tap("ui_submit");
  tap("ui_down");
  expect(ui.focused.id).toBe("scenario_river_mills");
  tap("ui_down");
  expect(ui.focused.id).toBe("scenario_winter_trade");
  tap("ui_submit");
  const ctl = waitForGame();
  expect(ctl.run.scenario).toBe("winter_trade");
  expect(ctl.run.slot).toBe(1);
  expect(ctl.state.clock.date().season).toBe("autumn");
});

test("keyboard only: delete asks with No focused, a second Enter on Yes deletes", () => {
  seed();
  openTitle();
  tap("ui_submit");
  tap("ui_down"); // slot 1
  tap("ui_down"); // slot 2 main
  expect(ui.focused.id).toBe("slot_2_main");
  tap("ui_right");
  expect(ui.focused.id).toBe("slot_2_auto");
  tap("ui_down");
  tap("ui_left");
  expect(ui.focused.id).toBe("slot_2_rename");
  tap("ui_right");
  expect(ui.focused.id).toBe("slot_2_delete");
  tap("ui_submit");
  expect(game.find("confirm_panel").active).toBe(true);
  expect(ui.focused.id).toBe("confirm_no");
  tap("ui_submit"); // No: nothing deleted
  expect(hasData(2, "manual")).toBe(true);
  expect(game.find("slots_panel").active).toBe(true);
  tap("ui_submit"); // focus returned to Delete
  expect(game.find("confirm_panel").active).toBe(true);
  tap("ui_right");
  expect(ui.focused.id).toBe("confirm_yes");
  tap("ui_submit");
  expect(hasData(2, "manual")).toBe(false);
  expect(listSlots()[2].manual).not.toBe(null);
});

test("the first start: no saves, Continue is greyed out and every slot offers a new game", () => {
  storage.clear();
  game.platform.reset();
  openTitle();
  game.click("play");
  game.step(2);
  expect(game.find("slots_continue").get("Button").interactable).toBe(false);
  for (let n = 1; n <= 3; n++) {
    expect(game.find(`slot_${n}_info`).get("Text").text).toContain("Empty");
    expect(game.find(`slot_${n}_main`).get("Button").text).toBe("New game");
    expect(game.find(`slot_${n}_delete`).get("Button").interactable).toBe(false);
  }
  expect(ui.focused.id).toBe("slot_1_main"); // the first widget that can take the focus
  game.screenshot(".factoria/tmp/slots_empty.png");
});
