// The shift flow: title -> loading -> shift -> results -> another shift or the title, and the state a run keeps between them.
import { test, describe, expect, game } from "factoria:test";
import { scene, storage, ui } from "factoria";
import { run } from "../scripts/game/run_state.js";
import { live } from "../scripts/game/mine_map.js";
import * as events from "../scripts/game/events.js";
import * as players from "../scripts/game/players.js";
import * as saveFile from "../scripts/game/save.js";
import { K } from "../scripts/game/tiles.js";
import { clearSlots, nextShift } from "./helpers/camp.js";

const SHIFT = "scenes/shift.scene.json";
const RESULTS = "scenes/results.scene.json";

/** From the title to a shift in progress. */
function startFromTitle() {
  players.clear();
  game.load("scenes/menu.scene.json");
  game.step(5);
  clearSlots();
  game.click("play"); // the three save slots
  game.step(2);
  game.click("slot_1"); // an empty slot starts a new run
  game.step(1);
  game.step(30); // the loading screen, then the join screen
  expect(scene.current).toBe("scenes/join.scene.json");
  game.gamepad(0).connect();
  game.step(10);
  game.gamepad(0).tap("a");
  game.step(5);
  game.gamepad(0).tap("start");
  game.step(1);
  expect(scene.current).toBe("scenes/loading.scene.json"); // the loading screen reads the shift scene ahead of time
  game.step(30);
  expect(scene.current).toBe(SHIFT);
  game.step(3);
}

describe("title -> shift -> results -> title", () => {
  test("Play starts a run and a shift on a generated mine", () => {
    startFromTitle();
    expect(run.active).toBe(true);
    expect(run.shiftNumber).toBe(1);
    expect(run.cash).toBe(0);
    expect(live.mine.width).toBeGreaterThan(39);
    expect(live.mine.solvable).toBe(true);
    expect(live.mine.seed).toBe(run.seed);
    expect(game.world.findByTag("miner").length).toBe(1);
    expect(game.find("hud_ore")).not.toBeNull();
  });

  test("the shift ends on the lift, the results show it, and Back to title returns to the menu", () => {
    startFromTitle();
    // walk to the exit by teleporting (the walk itself is tested in mine.test.js)
    run.ore.gold = 2;
    run.ore.copper = 4;
    const exit = live.map.tileCenter(live.mine.exit.tx, live.mine.exit.ty);
    game.world.findByTag("miner")[0].position = [exit.x, exit.y, 0];
    game.step(3);
    expect(run.lastShift.outcome).toBe("lift");
    game.step(120);
    expect(scene.current).toBe(RESULTS);
    expect(game.find("results_gold").get("Text").text).toBe("Gold: 2");
    expect(game.find("results_value").get("Text").text).toContain("20");
    expect(game.find("results_title").get("Text").text).toBe("Shift 1 done");
    expect(run.cash).toBe(20);
    game.click("to_title");
    game.step(3);
    expect(scene.current).toBe("scenes/menu.scene.json");
  });

  test("Another shift keeps the cash and builds a new mine; a shift in the dark loses its ore", () => {
    startFromTitle();
    const firstHash = live.mine.hash;
    run.ore.silver = 2;
    const exit = live.map.tileCenter(live.mine.exit.tx, live.mine.exit.ty);
    game.world.findByTag("miner")[0].position = [exit.x, exit.y, 0];
    game.step(130);
    expect(scene.current).toBe(RESULTS);
    nextShift(); // the results lead to the camp, the camp to the next shift
    expect(run.shiftNumber).toBe(2);
    expect(run.cash).toBe(6);
    expect(live.mine.hash).not.toBe(firstHash);
    expect(run.ore.silver).toBe(0); // a new shift starts with empty pockets
    run.ore.gold = 5;
    run.lamps[0].oil = 0.2;
    game.step(60 * 5);
    expect(run.lastShift.outcome).toBe("dark");
    game.step(120);
    expect(scene.current).toBe(RESULTS);
    expect(run.cash).toBe(6);
    expect(game.find("results_title").get("Text").text).toBe("Lost in the dark");
  });

  test("leaving the shift for the title does not open the results later", () => {
    startFromTitle();
    const exit = live.map.tileCenter(live.mine.exit.tx, live.mine.exit.ty);
    game.world.findByTag("miner")[0].position = [exit.x, exit.y, 0];
    game.step(3); // the shift is over: the results scene is 1.6 s away
    scene.load("scenes/menu.scene.json"); // the player was quicker (pause menu: Main menu)
    game.step(200);
    expect(scene.current).toBe("scenes/menu.scene.json");
  });

  test("the pause menu opens in a shift and Main menu leaves it", () => {
    startFromTitle();
    game.tap("pause");
    game.step(2);
    expect(game.find("pause_panel").active).toBe(true);
    game.click("to_main_menu");
    game.step(3);
    expect(scene.current).toBe("scenes/menu.scene.json");
    expect(run.inShift).toBe(false);
    expect(live.map).toBeNull();
  });
});

describe("what a shift leaves behind", () => {
  test("the run is saved with a format version when a shift ends", () => {
    startFromTitle();
    run.ore.copper = 2;
    const exit = live.map.tileCenter(live.mine.exit.tx, live.mine.exit.ty);
    game.world.findByTag("miner")[0].position = [exit.x, exit.y, 0];
    game.step(3);
    const data = storage.get("burrow.slot.1");
    expect(data.format).toBe(saveFile.SAVE_FORMAT);
    expect(data.cash).toBe(2);
    expect(data.seed).toBe(run.seed);
    expect(data.slot).toBe(1);
    expect(saveFile.apply(1)).toBe(true);
  });

  test("the save reader explains a file it cannot read", () => {
    expect(saveFile.migrate({ cash: 1 }).ok).toBe(false);
    const newer = saveFile.migrate({ format: 99 });
    expect(newer.ok).toBe(false);
    expect(newer.hint).toContain("update the game");
    expect(saveFile.migrate({ format: 1, seed: 5, stratum: 0, floor: 1, shiftNumber: 1, cash: 3, upgrades: {} }).ok).toBe(true);
    saveFile.erase(1);
    expect(saveFile.load(1)).toBeNull();
  });

  test("the events bus names its events and suggests the right one", () => {
    expect(() => events.on("diged", () => {})).toThrow("dug");
    expect(() => events.emit("nope")).toThrow("unknown game event");
    const log = [];
    const off = events.on("liftReached", (e) => log.push(e));
    events.emit("liftReached", { player: 0 });
    off();
    events.emit("liftReached", { player: 1 });
    expect(log).toEqual([{ player: 0 }]);
  });
});
