// P3: the level select (scenes/level_select.scene.json): what the cards show, locked levels, and navigation with the
// mouse, a touch, the keyboard and a gamepad; Back, the daily button, rename, and Continue / Play on the title screen.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { scene, session, storage } from "factoria";
import * as progress from "../scripts/progress.js";

const SELECT = "scenes/level_select.scene.json";
const card = (id) => game.find("card_" + id);
const focused = () => ["rooftops_1", "rooftops_2", "rooftops_3", "market_1", "market_2", "market_3"].find((id) => card(id).get("Button").focused);
const win = (id, stars, time = 40) => progress.record(id, { time, springLeft: 30, stars });

/** Opens the screen with the rooftops all won (9 stars): the market is open. */
function openMarket() {
  progress.setName("Ana");
  win("rooftops_1", 3, 41.5);
  win("rooftops_2", 2, 70);
  win("rooftops_3", 3, 90);
  open();
}

function open() {
  game.load(SELECT);
  game.step(5);
}

function key(name) {
  game.keyDown(name);
  game.step(1);
  game.keyUp(name);
  game.step(1);
}

const loads = (id) => session.nextScene === `scenes/${id}.scene.json`;

describe("level select", () => {
  beforeEach(() => {
    game.setStorageText(null);
    storage.remove("progress");
    session.daily = null;
    session.nextScene = null;
  });

  test("a new player sees the first level open and the rest locked, with the stars total", () => {
    progress.setName("Ana");
    open();
    expect(card("rooftops_1").get("Button").text).toContain("New");
    for (const id of ["rooftops_2", "rooftops_3", "market_1", "market_2", "market_3"]) {
      expect(card(id).get("Button").text).toContain("Locked");
    }
    expect(game.find("select_total").get("Text").text).toBe("Stars 0 / 18");
    expect(game.find("select_name").get("Button").text).toBe("Courier: Ana");
    expect(game.find("district_market_title").get("Text").text).toContain("needs 6 stars");
  });

  test("a won level shows its stars and best time; the next one opens", () => {
    progress.setName("Ana");
    win("rooftops_1", 2, 41.5);
    open();
    expect(card("rooftops_1").get("Button").text).toContain("\u2605\u2605\u2606");
    expect(card("rooftops_1").get("Button").text).toContain("41.5 s");
    expect(game.find("select_total").get("Text").text).toBe("Stars 2 / 18");
  });

  test("the market opens with the stars of the rooftops", () => {
    openMarket();
    expect(game.find("district_market_title").get("Text").text).not.toContain("needs");
    expect(game.find("select_total").get("Text").text).toBe("Stars 8 / 18");
    game.click("card_market_2"); // a locked card: the hint says what opens it
    game.screenshot(".factoria/tmp/select_market.png");
  });

  test("mouse: a click on an open card loads the level, a click on a locked one does nothing", () => {
    openMarket();
    game.click("card_market_2");
    game.step(3);
    expect(scene.current).toBe(SELECT);
    expect(session.nextScene).toBeNull();
    expect(game.find("select_hint").get("Text").text).toContain("Win Lantern Lane first");
    game.click("card_rooftops_2");
    expect(loads("rooftops_2")).toBe(true);
  });

  test("touch: tapping a card starts the level", () => {
    openMarket();
    game.touch("card_market_1");
    game.step(3);
    expect(loads("market_1")).toBe(true);
  });

  test("keyboard: arrows move the focus, Enter starts, Escape goes back to the title", () => {
    openMarket();
    expect(focused()).toBe("rooftops_1");
    key("Right");
    expect(focused()).toBe("rooftops_2");
    key("Right");
    expect(focused()).toBe("rooftops_3");
    key("Down");
    expect(focused()).toBe("market_3"); // locked cards stay on the grid: the focus moves over a plain 3 x 2 grid
    key("Left");
    key("Left");
    expect(focused()).toBe("market_1");
    key("Return");
    expect(loads("market_1")).toBe(true);
  });

  test("keyboard: Escape returns to the title", () => {
    openMarket();
    key("Escape");
    game.step(3);
    expect(scene.current).toBe("scenes/main.scene.json");
  });

  test("gamepad: the d-pad moves, A starts, B goes back", () => {
    openMarket();
    const pad = game.gamepad(0);
    pad.tap("DpadRight");
    game.step(1);
    expect(focused()).toBe("rooftops_2");
    pad.tap("DpadDown");
    game.step(1);
    expect(focused()).toBe("market_2");
    pad.tap("DpadLeft");
    game.step(1);
    expect(focused()).toBe("market_1");
    pad.tap("A");
    game.step(2);
    expect(loads("market_1")).toBe(true);
    open();
    pad.tap("B");
    game.step(3);
    expect(scene.current).toBe("scenes/main.scene.json");
  });

  test("Android Back and the Back button return to the title", () => {
    openMarket();
    game.pressBack();
    game.step(3);
    expect(scene.current).toBe("scenes/main.scene.json");
    open();
    game.click("select_back");
    game.step(3);
    expect(scene.current).toBe("scenes/main.scene.json");
  });

  test("playing a normal level clears a daily route left from before", () => {
    openMarket();
    session.daily = { date: "2026-01-01", level: "rooftops_1", order: [1, 0], active: true };
    game.click("card_rooftops_1");
    expect(session.daily).toBeNull();
  });

  test("the name button opens the name screen, which returns here", () => {
    openMarket();
    game.click("select_name");
    game.step(3);
    expect(scene.current).toBe("scenes/profile.scene.json");
    expect(session.profileReturn).toBe(SELECT);
  });

  test("the cloud line says how the last sync went", () => {
    openMarket();
    game.step(3);
    expect(game.find("select_cloud").get("Text").text).toContain("Cloud save");
  });
});

describe("title screen", () => {
  beforeEach(() => {
    game.setStorageText(null);
    storage.remove("progress");
    session.nextScene = null;
  });

  test("a new player: Play opens the name screen first, and Continue is hidden", () => {
    game.load("scenes/main.scene.json");
    game.step(5);
    expect(game.find("continue_button").active).toBe(false);
    game.click("play");
    game.step(3);
    expect(scene.current).toBe("scenes/profile.scene.json");
  });

  test("with a name, Play opens the level select", () => {
    progress.setName("Ana");
    game.load("scenes/main.scene.json");
    game.step(5);
    game.click("play");
    game.step(3);
    expect(scene.current).toBe(SELECT);
  });

  test("Continue starts the next level that was not won yet", () => {
    progress.setName("Ana");
    win("rooftops_1", 3);
    game.load("scenes/main.scene.json");
    game.step(5);
    expect(game.find("continue_button").active).toBe(true);
    game.click("continue_button");
    expect(loads("rooftops_2")).toBe(true);
  });

  test("Continue is hidden when every open level was won and none is left", () => {
    progress.setName("Ana");
    for (const id of ["rooftops_1", "rooftops_2", "rooftops_3"]) win(id, 1);
    // 3 stars only: the market is shut, so there is nothing unfinished to continue with
    game.load("scenes/main.scene.json");
    game.step(5);
    expect(game.find("continue_button").active).toBe(false);
  });
});
