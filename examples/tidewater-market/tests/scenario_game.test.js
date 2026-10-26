// A scenario on the game screen: the goal panel, the toast and the win screen, and the Save entry of the pause menu.
import { test, expect, game } from "factoria:test";
import { storage, scene, session } from "factoria";
import { readMeta, hasData } from "../scripts/game/save_store.js";

const MENU = "scenes/menu.scene.json";
const GAME = "scenes/game.scene.json";

function start(boot) {
  storage.clear();
  game.platform.reset();
  session.boot = boot;
  game.load(GAME);
  game.step(3);
  expect(scene.current).toBe(GAME);
  return game.find("controller").behaviour;
}

const tap = (action) => {
  game.press(action);
  game.step(1);
  game.release(action);
  game.step(1);
};

test("a scenario game shows its goals under the top bar, with progress", () => {
  const ctl = start({ slot: 1, scenario: "first_harbour", name: "First Harbour" });
  expect(game.find("goal_panel").active).toBe(true);
  expect(game.find("goal_title").get("Text").text).toBe("Goals");
  expect(game.find("goal_row_folk").get("Text").text).toBe("Have 25 villagers: 0 / 25");
  expect(game.find("goal_row_fishers").get("Text").text).toBe("Make 120 fish in one season: 0 / 120");
  expect(game.find("goal_row_savings").get("Text").text).toBe("Save 1000 coins: 1000 / 1000");
  expect(ctl.run.tracker.goals).toHaveLength(3);
  game.screenshot(".factoria/tmp/goal_panel.png");
});

test("a sandbox game has no goal panel; a plain scene game has none either", () => {
  start({ slot: 1, scenario: "sandbox", name: "Sandbox" });
  expect(game.find("goal_panel")).toBe(null);
  expect(game.find("win_screen").active).toBe(false);
  storage.clear();
  game.load(GAME, { testMap: true });
  game.step(3);
  expect(game.find("goal_panel")).toBe(null);
});

test("reaching every goal toasts each one, shows the win screen, stops the clock and keeps the finished game", () => {
  const ctl = start({ slot: 1, scenario: "first_harbour", name: "First Harbour" });
  const tracker = ctl.run.tracker;
  tracker.goals = tracker.goals.map((g) => ({ ...g, target: 0 })); // copies: the scenario table stays as it is
  ctl.state.clock.setSpeed(2);
  tracker.check();
  game.step(2);
  expect(tracker.won).toBe(true);
  expect(game.find("win_screen").active).toBe(true);
  expect(game.find("win_title").get("Text").text).toBe("First Harbour complete!");
  expect(game.find("win_body").get("Text").text).toContain("Every goal was reached");
  expect(ctl.state.clock.speed).toBe(0);
  expect(game.find("goal_row_folk").get("Text").text).toContain("done");
  expect(game.find("toast").get("Text").text).toContain("Goal reached");
  // the autosave of slot 1 holds the win
  expect(readMeta(1, "auto").won).toBe(true);
  expect(readMeta(1, "auto").goalsDone).toBe(3);
  game.screenshot(".factoria/tmp/win_screen.png");
  game.click("win_keep");
  game.step(2);
  expect(game.find("win_screen").active).toBe(false);
  expect(ctl.state.clock.speed).toBe(2);
  expect(scene.current).toBe(GAME);
});

test("the win screen's Main menu button returns to the title", () => {
  const ctl = start({ slot: 2, scenario: "first_harbour", name: "First Harbour" });
  const tracker = ctl.run.tracker;
  tracker.goals = tracker.goals.map((g) => ({ ...g, target: 0 }));
  tracker.check();
  game.step(2);
  game.click("win_menu");
  let guard = 0;
  while (scene.current !== MENU && guard++ < 100) game.step(1);
  expect(scene.current).toBe(MENU);
});

test("a saved game of a scenario comes back with its progress and its goal panel", () => {
  const ctl = start({ slot: 1, scenario: "first_harbour", name: "First Harbour" });
  ctl.run.tracker.goals = ctl.run.tracker.goals.map((g) => (g.id === "savings" ? { ...g, target: 0 } : g));
  ctl.run.tracker.check();
  expect(ctl.run.tracker.done.savings).toBeDefined();
  ctl.autosaver.saveManual(3, "Keep");
  const hash = ctl.state.hash();
  session.boot = { slot: 3, kind: "manual" };
  game.load(GAME);
  game.step(3);
  const back = game.find("controller").behaviour;
  expect(back.state.hash()).toBe(hash);
  expect(back.run.tracker.counts()).toEqual({ done: 1, total: 3 });
  expect(game.find("goal_row_savings").get("Text").text).toContain("done");
  expect(game.find("goal_row_folk").get("Text").text).toContain("0 / 25");
});

test("pause menu: Save game opens the slots, saves into one (asking before it replaces), and Back returns to the pause menu", () => {
  const ctl = start({ slot: 0, scenario: "sandbox", name: "" });
  tap("pause");
  expect(game.paused).toBe(true);
  expect(game.find("pause_save").get("Button").text).toBe("Save game");
  game.click("pause_save");
  game.step(2);
  expect(game.find("slots_panel").active).toBe(true);
  expect(game.find("slots_title").get("Text").text).toBe("Save the game");
  expect(game.find("slots_continue").active).toBe(false);
  expect(game.find("slot_1_main").get("Button").text).toBe("Save here");
  game.click("slot_2_main");
  game.step(2);
  expect(hasData(2, "manual")).toBe(true);
  expect(readMeta(2, "manual").name).toBe("Sandbox");
  expect(readMeta(2, "manual").scenario).toBe("sandbox");
  expect(readMeta(2, "manual").hash).toBe(ctl.state.hash());
  expect(ctl.run.slot).toBe(2); // the game belongs to the slot it was saved into: it autosaves there from now on
  expect(game.find("slots_message").get("Text").text).toBe("Saved to slot 2");
  game.screenshot(".factoria/tmp/save_slots.png");
  const first = readMeta(2, "manual").revision;
  game.click("slot_2_main"); // a slot that is taken: ask first
  game.step(2);
  expect(game.find("confirm_panel").active).toBe(true);
  expect(readMeta(2, "manual").revision).toBe(first);
  game.click("confirm_no");
  game.step(2);
  expect(readMeta(2, "manual").revision).toBe(first);
  game.click("slot_2_main");
  game.step(2);
  game.click("confirm_yes");
  game.step(2);
  expect(readMeta(2, "manual").revision).toBeGreaterThan(first);
  game.click("slots_back");
  game.step(2);
  expect(game.find("pause_panel").active).toBe(true);
  game.click("resume");
  game.step(3);
  expect(game.paused).toBe(false);
});

test("autosave in the running game: a season, losing the focus and a failing write", () => {
  const ctl = start({ slot: 1, scenario: "first_harbour", name: "First Harbour" });
  expect(hasData(1, "auto")).toBe(false);
  const clock = ctl.state.clock;
  clock.setDay(9); // the last day of spring (days count from 0)
  for (let i = 0; i < clock.ticksPerDay + 2; i++) clock.tick(clock.step);
  expect(clock.date().season).toBe("summer");
  game.step(2);
  expect(hasData(1, "auto")).toBe(true);
  expect(ctl.autosaver.log).toEqual(["season"]);
  expect(readMeta(1, "auto").hash).toBe(ctl.state.hash());
  expect(game.platform.state().fake.cloud["tm_slot_1_auto"]).toBeDefined(); // the cloud has a copy
  // losing the focus saves again, when the town changed
  ctl.state.economy.apply({ coins: 5 }, "test");
  game.blur();
  expect(ctl.autosaver.log).toEqual(["season", "blur"]);
  game.focus();
  // a refused write: one toast, the old entry stays
  const before = readMeta(1, "auto").revision;
  const real = storage.set;
  storage.set = () => {
    throw new Error("disk full");
  };
  try {
    ctl.state.economy.apply({ coins: 5 }, "test");
    game.blur();
    game.step(2);
  } finally {
    storage.set = real;
  }
  expect(readMeta(1, "auto").revision).toBe(before);
  expect(game.find("toast").get("Text").text).toContain("could not be saved");
  game.focus();
});
