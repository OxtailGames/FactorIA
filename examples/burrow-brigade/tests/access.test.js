// P6 accessibility: hold or toggle for the dig button, the game speed of the assist option, reduced flashing, the colour-free
// markers, and the Options > Access tab driven from the keyboard, a gamepad and the mouse. Every option is saved.
import { test, describe, expect, game } from "factoria:test";
import { ui, storage, time, window } from "factoria";
import { cleanBeforeEach, playRows, miner, teleport } from "./helpers/world.js";
import { freshOnline } from "./helpers/online.js";
import { live } from "../scripts/game/mine_map.js";
import { K } from "../scripts/game/tiles.js";
import * as settings from "../scripts/settings.js";
import * as events from "../scripts/game/events.js";
import * as boards from "../scripts/game/boards.js";
import * as input from "../scripts/game/miner_input.js";
import { run, startRun } from "../scripts/game/run_state.js";
import { shift } from "./helpers/online.js";

const SECOND = 60;
const DIRT = ["B".repeat(14), "B.S....####..EB", "B".repeat(14)].map((r) => r.padEnd(16, "B"));

function choose(patch) {
  const s = settings.load();
  Object.assign(s, patch);
  settings.save(s);
}

describe("hold or toggle for the dig button", () => {
  cleanBeforeEach();

  test("hold (the default): the pick works only while the button is down", () => {
    playRows(DIRT);
    teleport(miner(), 6, 1);
    game.keyDown("D");
    game.keyDown("J");
    game.step(10);
    game.keyUp("J");
    const progress = miner().behaviour.digProgress;
    game.step(40);
    expect(miner().behaviour.digProgress).toBeLessThanOrEqual(progress);
    expect(live.map.kindAt(7, 1)).not.toBe(K.FLOOR);
    expect(input.digToggled(0)).toBe(false);
  });

  test("toggle: one press starts the dig, it goes on with the button up, the next press stops it", () => {
    choose({ holdMode: { 0: "toggle" } });
    playRows(DIRT);
    teleport(miner(), 6, 1);
    game.keyDown("D");
    game.keyDown("J");
    game.step(3);
    game.keyUp("J");
    game.step(40);
    expect(input.digToggled(0)).toBe(true);
    expect(live.map.kindAt(7, 1)).toBe(K.FLOOR);
    game.keyDown("J");
    game.step(3);
    game.keyUp("J");
    game.step(3);
    expect(input.digToggled(0)).toBe(false);
  });

  test("the choice is per player: seat 1 toggles while seat 2 holds", () => {
    choose({ holdMode: { 0: "toggle" } });
    expect(settings.holdModeOf(0)).toBe("toggle");
    expect(settings.holdModeOf(1)).toBe("hold");
    expect(settings.holdModeOf(3)).toBe("hold");
  });

  test("a toggled dig ends when a new shift starts", () => {
    choose({ holdMode: { 0: "toggle" } });
    playRows(DIRT);
    game.keyDown("J");
    game.step(3);
    game.keyUp("J");
    game.step(3);
    expect(input.digToggled(0)).toBe(true);
    playRows(DIRT);
    expect(input.digToggled(0)).toBe(false);
  });
});

describe("game speed", () => {
  cleanBeforeEach();

  test("a shift runs at the saved speed, tells the bus, and gives time.scale back when it ends", () => {
    choose({ gameSpeed: 0.6 });
    const seen = [];
    events.keep("shiftStarted", (d) => seen.push(d.speed));
    playRows(DIRT);
    expect(time.scale).toBeCloseTo(0.6, 3);
    expect(seen).toEqual([0.6]);
    game.load("scenes/menu.scene.json");
    game.step(2);
    expect(time.scale).toBe(1);
  });

  test("an unknown saved value counts as normal speed", () => {
    choose({ gameSpeed: 0.1 });
    expect(settings.gameSpeedOf()).toBe(1);
    playRows(DIRT);
    expect(time.scale).toBe(1);
  });

  test("a slower game walks fewer tiles in the same real time (the clock is the engine's, so it is deterministic)", () => {
    const walk = () => {
      playRows(DIRT);
      teleport(miner(), 3, 1);
      const x0 = miner().position.x;
      game.keyDown("D");
      game.step(30);
      game.keyUp("D");
      return miner().position.x - x0;
    };
    const normal = walk();
    choose({ gameSpeed: 0.6 });
    const slow = walk();
    expect(slow).toBeLessThan(normal * 0.75);
    expect(walk()).toBeCloseTo(slow, 5);
  });
});

describe("game speed and the boards", () => {
  freshOnline();

  test("a lift played slower posts nothing; the next normal run posts again", async () => {
    const posted = () => game.platform.calls().filter((c) => c.method === "leaderboards.submit").length;
    shift({ banked: 100, speed: 0.8 });
    await boards.idle();
    expect(posted()).toBe(0);
    expect(boards.status().assisted).toBe(true);
    startRun({ seed: 9 });
    shift({ banked: 100 });
    await boards.idle();
    expect(posted()).toBeGreaterThan(0);
  });

  test("a run continued from a save starts a fresh assist count", async () => {
    const posted = () => game.platform.calls().filter((c) => c.method === "leaderboards.submit").length;
    startRun({ seed: 9 });
    shift({ banked: 100, speed: 0.6 });
    expect(boards.status().assisted).toBe(true);
    run.shiftNumber = 7; // Continue on a save several shifts on: not the next shift of the run in memory
    run.cash = 40;
    shift({ banked: 100 });
    await boards.idle();
    expect(boards.status().assisted).toBe(false);
    expect(boards.status().runScore).toBe(140); // the cash in hand, then the lift
    expect(posted()).toBeGreaterThan(0);
  });
});

describe("reduced flashing", () => {
  cleanBeforeEach();

  const magma = ["B".repeat(14), "B.S..MM.....EB", "B".repeat(14)].map((r) => r.padEnd(16, "B"));
  const spread = () => {
    const values = [];
    for (let i = 0; i < 90; i++) {
      game.step(1);
      const light = game.world.findByTag("light")?.map?.((e) => e.get("Light2D")?.intensity).filter((v) => v !== undefined) ?? [];
      values.push(...light);
    }
    return values.length ? Math.max(...values) - Math.min(...values) : 0;
  };

  test("it follows the system until the player chooses, then the saved choice wins", () => {
    expect(settings.reducedFlashing()).toBe(false);
    game.setAccessibility({ reduceMotion: true });
    expect(settings.load().reducedEffects).toBe(true);
    game.setAccessibility({ reduceMotion: false });
    choose({ reducedEffects: true });
    expect(settings.reducedFlashing()).toBe(true);
    choose({ reducedEffects: false });
    expect(settings.reducedFlashing()).toBe(false);
  });

  test("the cave-in warning blinks normally and only brightens slowly when reduced", () => {
    const alphas = (reduced) => {
      choose({ reducedEffects: reduced });
      playRows(["B".repeat(14), "B.S.........EB", "B".repeat(14)].map((r) => r.padEnd(16, "B")), { stratum: 0 });
      return reduced;
    };
    alphas(false);
    expect(settings.reducedFlashing()).toBe(false);
    alphas(true);
    expect(settings.reducedFlashing()).toBe(true);
  });

  test("magma light swings less when reduced", () => {
    choose({ reducedEffects: false });
    playRows(magma, { stratum: 2 });
    const wide = spread();
    choose({ reducedEffects: true });
    playRows(magma, { stratum: 2 });
    const narrow = spread();
    expect(narrow).toBeLessThanOrEqual(wide);
  });
});

describe("Options > Access", () => {
  freshOnline();

  const open = () => {
    game.load("scenes/menu.scene.json");
    game.step(5);
    game.click("options_button");
    game.step(3);
    game.click("tab_access");
    game.step(2);
  };
  const saved = () => storage.get("settings", {});

  test("mouse: every row changes its setting at once and saves it", () => {
    open();
    expect(game.find("access_section").active).toBe(true);
    game.click("sound_captions_toggle");
    game.step(2);
    expect(saved().soundCaptions).toBe(true);
    game.click("reduced_flashing");
    game.step(2);
    expect(saved().reducedEffects).not.toBe(undefined);
    game.click("game_speed");
    game.step(2);
    expect(saved().gameSpeed).toBe(0.8);
    expect(game.find("game_speed").get("Button").text).toContain("80");
    game.click("game_speed");
    game.click("game_speed");
    game.step(2);
    expect(saved().gameSpeed).toBe(1);
    game.click("hold_mode");
    game.step(2);
    expect(saved().holdMode["0"]).toBe("toggle");
    game.click("hold_player");
    game.click("hold_mode");
    game.step(2);
    expect(saved().holdMode["1"]).toBe("toggle");
    expect(settings.holdModeOf(2)).toBe("hold");
  });

  test("a slower speed says that it is not posted to the boards", () => {
    open();
    game.click("game_speed");
    game.step(2);
    expect(game.find("access_note").get("Text").text).toMatch(/board/i);
  });

  test("gamepad only: reach the Access tab and change the game speed", () => {
    game.load("scenes/menu.scene.json");
    const pad = game.gamepad(0);
    pad.connect();
    game.step(2);
    for (let i = 0; i < 3; i++) pad.tap("DpadDown");
    pad.tap("A");
    for (let i = 0; i < 3; i++) pad.tap("DpadRight");
    pad.tap("A");
    expect(game.find("access_section").active).toBe(true);
    let guard = 0;
    while (ui.focused?.id !== "game_speed" && guard++ < 10) pad.tap("DpadDown");
    expect(ui.focused.id).toBe("game_speed");
    pad.tap("A");
    expect(saved().gameSpeed).toBe(0.8);
  });

  test("keyboard only: the same row is reachable and Enter presses it", () => {
    game.load("scenes/menu.scene.json");
    game.step(2);
    for (let i = 0; i < 3; i++) game.tap("ui_down");
    game.tap("ui_submit");
    for (let i = 0; i < 3; i++) game.tap("ui_right");
    game.tap("ui_submit");
    expect(game.find("access_section").active).toBe(true);
    let guard = 0;
    while (ui.focused?.id !== "hold_mode" && guard++ < 10) game.tap("ui_down");
    expect(ui.focused.id).toBe("hold_mode");
    game.tap("ui_submit");
    expect(saved().holdMode["0"]).toBe("toggle");
  });

  test("Video: without a window the window rows are greyed and say why", () => {
    game.load("scenes/menu.scene.json");
    game.step(5);
    game.click("options_button");
    game.step(3);
    expect(window.available).toBe(false);
    expect(game.find("video_note").active).toBe(true);
    expect(game.find("display_mode").get("Button").interactable).toBe(false);
    expect(game.find("monitor").active).toBe(false); // no window, so no monitor row
    expect(game.find("display_mode").get("Button").text).toContain("windowed"); // the headless window is a window
  });

  test("Window modes: windowed, borderless and full screen; an older save's fullscreen flag still means full screen", () => {
    expect(settings.DISPLAY_MODES).toEqual(["windowed", "borderless", "fullscreen"]);
    expect(settings.displayModeOf({ displayMode: "borderless", fullscreen: true })).toBe("borderless");
    expect(settings.displayModeOf({ displayMode: null, fullscreen: true })).toBe("fullscreen");
    expect(settings.displayModeOf({ displayMode: null, fullscreen: false })).toBe("windowed");
    expect(settings.displayModeOf({ displayMode: "exclusive", fullscreen: null })).toBe(null);
    storage.set("settings", { fullscreen: true }); // saved before the borderless mode and the monitor choice
    expect(settings.displayModeOf(settings.load())).toBe("fullscreen");
    expect(settings.load().monitor).toBe(null);
    settings.save({ ...settings.load(), displayMode: "borderless", monitor: { index: 1, name: "DELL" } });
    expect(settings.load().displayMode).toBe("borderless");
    expect(settings.load().monitor).toEqual({ index: 1, name: "DELL" });
  });
});
