// The game flow: title screen, pause (key, gamepad, touch button, Android Back), restart, the spring running out, and
// the bot delivering the parcel to reach the results screen.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { scene, storage, ui } from "factoria";
import { Autoplay, YARD_ROUTE } from "./helpers/autoplay.js";
import * as progress from "../scripts/progress.js";

const YARD = "scenes/test_yard.scene.json";
const courier = () => game.find("courier");
const spring = () => game.find("spring").behaviour;

function loadYard() {
  game.load(YARD);
  game.step(10);
}

/** Records the names of the given world events. */
function record(names) {
  const log = [];
  for (const n of names) game.world.on(n, (d) => log.push({ name: n, data: d }));
  return log;
}

describe("title screen", () => {
  test("Play goes through the loading screen into the first level", () => {
    game.load("scenes/main.scene.json");
    game.step(5);
    expect(game.find("play")).not.toBeNull();
    progress.setName("Ana"); // P3: Play opens the level select (the name screen first for a new player)
    game.click("play");
    game.step(5);
    expect(scene.current).toBe("scenes/level_select.scene.json");
    game.click("card_rooftops_1");
    game.step(10);
    expect(scene.current).toBe("scenes/rooftops_1.scene.json"); // P2: the first level of the list
  });

  test("has Play, Options and Credits, and Quit on desktop", () => {
    game.load("scenes/main.scene.json");
    game.step(5);
    for (const id of ["play", "options_button", "credits_button", "quit"]) expect(game.find(id).active).toBe(true);
    game.click("options_button");
    game.step(3);
    expect(game.find("options").active).toBe(true);
    expect(game.find("main_menu").active).toBe(false);
  });

  test("Back (Android) closes the options panel", () => {
    game.load("scenes/main.scene.json");
    game.step(5);
    game.click("options_button");
    game.step(3);
    game.pressBack();
    game.step(2);
    expect(game.find("options").active).toBe(false);
    expect(game.find("main_menu").active).toBe(true);
  });

  test("menu clicks make interface sounds on the ui bus", () => {
    game.load("scenes/main.scene.json");
    game.step(5);
    game.clearAudioLog();
    game.click("options_button");
    game.step(2);
    expect(game.audioLog()).toContainPlayed("click_001.ogg", { bus: "ui" });
  });
});

describe("pause", () => {
  beforeEach(loadYard);

  test("the pause key opens the menu, pressing it again resumes", () => {
    game.tap("pause");
    game.step(2);
    expect(game.paused).toBe(true);
    expect(game.find("pause_panel").active).toBe(true);
    game.tap("pause");
    game.step(3);
    expect(game.paused).toBe(false);
    expect(game.find("pause_panel").active).toBe(false);
  });

  test("gamepad Start pauses", () => {
    game.gamepad(0).tap("Start");
    game.step(2);
    expect(game.paused).toBe(true);
  });

  test("the Android Back button pauses, and pressing it again resumes", () => {
    game.pressBack();
    game.step(2);
    expect(game.paused).toBe(true);
    game.pressBack();
    game.step(3);
    expect(game.paused).toBe(false);
  });

  test("Back inside the options panel returns to the pause menu first", () => {
    game.pressBack();
    game.step(2);
    game.click("pause_options");
    game.step(3);
    expect(game.find("options").active).toBe(true);
    game.pressBack();
    game.step(3);
    expect(game.find("options").active).toBe(false);
    expect(game.find("pause_panel").active).toBe(true);
    expect(game.paused).toBe(true);
  });

  test("the Resume button resumes", () => {
    game.tap("pause");
    game.step(2);
    game.click("resume");
    game.step(4);
    expect(game.paused).toBe(false);
  });

  test("the world is frozen while paused: no movement, the spring does not drain", () => {
    game.tap("pause");
    game.step(2);
    const left = spring().left;
    game.press("move_forward");
    const z0 = courier().position.z;
    game.step(60);
    expect(spring().left).toBeCloseTo(left, 3);
    expect(courier().position.z).toBeCloseTo(z0, 3);
  });

  test("the press that clicks Resume does not also make the courier jump", () => {
    game.tap("pause");
    game.step(2);
    game.click("resume");
    game.step(6);
    expect(courier().behaviour.grounded).toBe(true);
    expect(courier().position.y).toBeLessThan(0.7);
  });

  test("pause and resume are announced as events", () => {
    const log = record(["game_paused", "game_resumed"]);
    game.tap("pause");
    game.step(2);
    game.tap("pause");
    game.step(3);
    expect(log.map((e) => e.name)).toEqual(["game_paused", "game_resumed"]);
  });

  test("Restart reloads the level", () => {
    courier().position = [3, 0.6, 3];
    game.step(3);
    game.tap("pause");
    game.step(2);
    game.click("pause_restart");
    game.step(6);
    expect(game.paused).toBe(false);
    expect(scene.current).toBe(YARD);
    expect(courier().position.z).toBeGreaterThan(14);
    expect(spring().left).toBeGreaterThan(58);
  });

  test("Quit to title loads the title screen", () => {
    game.tap("pause");
    game.step(2);
    game.click("to_main_menu");
    game.step(5);
    expect(scene.current).toBe("scenes/main.scene.json");
    expect(game.paused).toBe(false);
  });

  test("the menu opens and closes with its interface sounds", () => {
    game.clearAudioLog();
    game.tap("pause");
    game.step(2);
    expect(game.audioLog()).toContainPlayed("open_001.ogg", { bus: "ui" });
  });
});

describe("the spring", () => {
  beforeEach(loadYard);

  test("drains one second per second", () => {
    const left = spring().left;
    game.step(60);
    expect(left - spring().left).toBeCloseTo(1, 1);
  });

  test("the level lists 60 s of spring for the yard", () => {
    expect(spring().max).toBe(60);
  });

  test("running out winds the courier down and fails the level with the retry screen", () => {
    const log = record(["spring_empty", "level_failed", "level_completed"]);
    spring().left = 0.1;
    game.step(10);
    expect(log.map((e) => e.name)).toEqual(["spring_empty", "level_failed"]);
    expect(log[1].data.reason).toBe("spring_empty");
    expect(game.find("model").animator.state).toBe("wound_down");
    expect(game.find("retry_panel").active).toBe(false);
    game.step(120);
    expect(game.find("retry_panel").active).toBe(true);
    expect(game.find("results_panel").active).toBe(false);
  });

  test("spring_empty fires once", () => {
    const log = record(["spring_empty"]);
    spring().left = 0.05;
    game.step(200);
    expect(log.length).toBe(1);
  });

  test("a wound down courier cannot move", () => {
    spring().left = 0.05;
    game.step(10);
    const z0 = courier().position.z;
    game.press("move_forward");
    game.step(40);
    expect(courier().position.z).toBeCloseTo(z0, 1);
  });

  test("Try again on the retry screen restarts the level with a full spring", () => {
    spring().left = 0.05;
    game.step(150);
    game.click("retry_retry");
    game.step(6);
    expect(scene.current).toBe(YARD);
    expect(spring().left).toBeGreaterThan(58);
    expect(courier().position.z).toBeGreaterThan(14);
  });

  test("the pause menu stays closed on the retry screen", () => {
    spring().left = 0.05;
    game.step(150);
    game.tap("pause");
    game.step(3);
    expect(game.paused).toBe(false);
  });

  test("the HUD bar shrinks with the spring and the number counts down", () => {
    const full = game.find("spring_fill").get("Shape2D").size.x;
    spring().left = 30;
    game.step(2);
    const half = game.find("spring_fill").get("Shape2D").size.x;
    expect(half).toBeCloseTo(full / 2, -1);
    expect(game.find("spring_text").get("Text").text).toBe("30");
  });

  test("winding the spring adds seconds and sends spring_wound", () => {
    const log = record(["spring_wound"]);
    spring().left = 10;
    spring().wind(15);
    game.step(1);
    expect(spring().left).toBeCloseTo(24.98, 1);
    expect(log.length).toBe(1);
    spring().wind(1000);
    expect(spring().left).toBe(60);
  });
});

describe("parcel and door", () => {
  beforeEach(loadYard);

  test("walking into the parcel picks it up", () => {
    const log = record(["parcel_picked"]);
    courier().position = [-8, 0.8, 1.5];
    game.step(6);
    expect(log.length).toBe(1);
    expect(courier().behaviour.carrying).toBe(1);
    expect(game.find("parcel_1")).toBeNull();
    expect(game.find("carried_parcel").active).toBe(true);
    expect(game.find("parcel_text").get("Text").text).toMatch(/carrying/);
  });

  test("the door does nothing without a parcel", () => {
    const log = record(["parcel_delivered", "level_completed"]);
    courier().position = [0, 0.6, -19.5];
    game.step(30);
    expect(log.length).toBe(0);
    expect(courier().behaviour.locked).toBe(false);
  });

  test("the bot delivers the parcel and reaches the results screen", () => {
    const log = record(["level_started", "parcel_picked", "parcel_delivered", "level_completed", "level_failed", "spring_wound"]);
    storage.remove("progress");
    const bot = new Autoplay(game);
    const r = bot.run(YARD_ROUTE);
    expect(r.reached).toBe(true);
    game.step(180);
    expect(log.map((e) => e.name)).toEqual(["parcel_picked", "parcel_delivered", "level_completed"]);
    expect(log[1].data).toMatchObject({ delivered: 1, total: 1 });
    expect(game.find("model").animator.state).toBe("celebrate");
    expect(game.find("results_panel").active).toBe(true);
    expect(game.find("retry_panel").active).toBe(false);
    expect(game.find("results_time").get("Text").text).toMatch(/^Time: \d+\.\d s   /); // P3: the best time follows
    expect(game.find("results_spring").get("Text").text).toMatch(/^Spring left: \d+ s\n/);
    expect(game.find("results_stars").get("Text").text).toMatch(/^\u2605+\u2606*$/);
    // saved
    const saved = progress.resultFor("test_yard");
    expect(saved).not.toBeNull();
    expect(saved.stars).toBeGreaterThanOrEqual(1);
    expect(saved.time).toBeGreaterThan(5);
    expect(saved.time).toBeLessThan(40);
    expect(log[2].data.level).toBe("test_yard");
  });

  test("the bot earns three stars: fast and with spring to spare", () => {
    storage.remove("progress");
    const bot = new Autoplay(game);
    bot.run(YARD_ROUTE);
    game.step(10);
    expect(progress.resultFor("test_yard").stars).toBe(3);
  });

  test("the results screen has no Next button while the yard is the only level", () => {
    const bot = new Autoplay(game);
    bot.run(YARD_ROUTE);
    game.step(150);
    expect(game.find("results_next").active).toBe(false);
    expect(ui.focused.id).toBe("results_retry"); // a gamepad or keyboard player can act at once
  });

  test("Play again on the results screen restarts the level", () => {
    const bot = new Autoplay(game);
    bot.run(YARD_ROUTE);
    game.step(150);
    game.click("results_retry");
    game.step(6);
    expect(scene.current).toBe(YARD);
    expect(courier().behaviour.carrying).toBe(0);
    expect(game.find("parcel_1")).not.toBeNull();
  });

  test("the pause menu stays closed on the results screen and Back returns to the title", () => {
    const bot = new Autoplay(game);
    bot.run(YARD_ROUTE);
    game.step(150);
    game.tap("pause");
    game.step(3);
    expect(game.paused).toBe(false);
    game.pressBack();
    game.step(3);
    expect(scene.current).toBe("scenes/main.scene.json");
  });

  test("running out of spring while carrying fails the level", () => {
    courier().position = [-8, 0.8, 1.5];
    game.step(6);
    spring().left = 0.1;
    game.step(150);
    expect(game.find("retry_panel").active).toBe(true);
  });
});
