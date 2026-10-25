// Couch co-op (P3): the join screen, a whole shift for four pads, reviving, the camera, per-player controls and a pad that is
// unplugged mid-shift. Everything goes through the test API's keys and pads, like a player would.
import { test, describe, expect, game } from "factoria:test";
import { scene, ui, world } from "factoria";
import { cleanBeforeEach, plugPads, playRows, miners, miner, teleport, record } from "./helpers/world.js";
import { botsForAll, playFloor } from "./helpers/bot.js";
import { run } from "../scripts/game/run_state.js";
import * as players from "../scripts/game/players.js";
import * as controls from "../scripts/game/controls.js";
import * as revive from "../scripts/game/revive.js";
import * as views from "../scripts/game/camera_views.js";
import * as events from "../scripts/game/events.js";

const JOIN = "scenes/join.scene.json";
const SHIFT = "scenes/shift.scene.json";
const pad = (i) => game.gamepad(i);

function openJoin() {
  players.clear();
  events.clear();
  game.load(JOIN);
  game.step(20); // past the grace in which presses are ignored
}

function tapKey(name) {
  game.keyDown(name);
  game.step(1);
  game.keyUp(name);
  game.step(1);
}

const devices = () => players.all().map((p) => p.device);

describe("the join screen", () => {
  cleanBeforeEach();

  test("four pads join with A, each gets a slot, a colour and a name, and the first one starts the shift with Start", () => {
    openJoin();
    for (let i = 0; i < 4; i++) pad(i).connect();
    game.step(2);
    for (let i = 0; i < 4; i++) pad(i).tap("A");
    expect(players.count()).toBe(4);
    expect(devices()).toEqual([0, 1, 2, 3].map((index) => ({ kind: "pad", index })));
    expect(new Set(players.all().map((p) => p.color.join())).size).toBe(4);
    expect(players.all().map((p) => p.name)).toEqual(["P1", "P2", "P3", "P4"]);
    pad(1).tap("Start"); // only the first player starts
    expect(scene.current).toBe(JOIN);
    pad(0).tap("Start");
    game.step(40);
    expect(scene.current).toBe(SHIFT);
    game.step(3);
    expect(game.world.findByTag("miner").length).toBe(4);
  });

  test("one keyboard and three pads: Enter joins the keyboard, the fifth device does not fit", () => {
    openJoin();
    for (let i = 0; i < 4; i++) pad(i).connect();
    game.step(2);
    tapKey("Enter");
    pad(0).tap("A");
    pad(1).tap("A");
    pad(2).tap("A");
    pad(3).tap("A"); // a fifth device: the lobby is full
    expect(players.count()).toBe(4);
    expect(devices()[0]).toEqual({ kind: "keys", scheme: "keyboard" });
    expect(devices().slice(1)).toEqual([0, 1, 2].map((index) => ({ kind: "pad", index })));
    tapKey("Enter"); // the keyboard player is the host
    game.step(40);
    expect(scene.current).toBe(SHIFT);
    game.step(3);
    expect(miners().length).toBe(4);
  });

  test("keyboard only: Enter joins, Escape leaves, Escape again goes back to the title, Enter twice starts", () => {
    openJoin();
    tapKey("Enter");
    expect(devices()).toEqual([{ kind: "keys", scheme: "keyboard" }]);
    tapKey("Escape");
    expect(players.count()).toBe(0);
    tapKey("Enter");
    tapKey("Enter");
    game.step(40);
    expect(scene.current).toBe(SHIFT);
  });

  test("keyboard only: Escape with nobody joined goes back to the title", () => {
    openJoin();
    tapKey("Escape");
    game.step(2);
    expect(scene.current).toBe("scenes/menu.scene.json");
  });

  test("gamepad only: A joins, B leaves, B with nobody in goes back to the title", () => {
    openJoin();
    pad(0).connect();
    game.step(2);
    pad(0).tap("A");
    expect(players.count()).toBe(1);
    pad(0).tap("B");
    expect(players.count()).toBe(0);
    pad(0).tap("B");
    game.step(2);
    expect(scene.current).toBe("scenes/menu.scene.json");
  });

  test("a leaving player frees the slot, and the next one takes the colour back", () => {
    openJoin();
    pad(0).connect();
    pad(1).connect();
    game.step(2);
    pad(0).tap("A");
    pad(1).tap("A");
    pad(0).tap("B");
    expect(devices()).toEqual([{ kind: "pad", index: 1 }]);
    pad(1).tap("Start"); // P2's pad is now the host
    game.step(40);
    expect(scene.current).toBe(SHIFT);
  });

  test("a pad unplugged in the lobby leaves; a pad plugged in later (a Remote Play guest) joins like any other", () => {
    openJoin();
    pad(0).connect();
    game.step(2);
    pad(0).tap("A");
    expect(players.count()).toBe(1);
    pad(0).disconnect();
    game.step(2);
    expect(players.count()).toBe(0);
    pad(2).connect(); // the guest's controller shows up as one more pad, in any slot
    game.step(2);
    pad(2).tap("A");
    expect(devices()).toEqual([{ kind: "pad", index: 2 }]);
  });

  test("the press that clicked Play on the title does not also join", () => {
    players.clear();
    pad(0).connect();
    game.load("scenes/menu.scene.json");
    game.step(5);
    game.click("play"); // the three save slots
    game.step(2);
    game.click("slot_1"); // the slot is the press that leaves the title
    game.step(30);
    expect(scene.current).toBe(JOIN);
    expect(players.count()).toBe(0);
  });
});

const HALL = ["BBBBBBBBBBBBBBBBBBBB", "B.S..............E.B", "BBBBBBBBBBBBBBBBBBBB"];

describe("a whole shift with four pads", () => {
  cleanBeforeEach();

  test("four pads join, the bot plays the shift through their sticks, and the shift ends on the lift", () => {
    openJoin();
    for (let i = 0; i < 4; i++) pad(i).connect();
    game.step(2);
    for (let i = 0; i < 4; i++) pad(i).tap("A");
    pad(0).tap("Start");
    game.step(40);
    expect(scene.current).toBe(SHIFT);
    game.step(3);
    expect(run.inShift).toBe(true);
    expect(game.world.findByTag("miner").length).toBe(4);
    const result = playFloor(botsForAll(), { frames: 9000 });
    expect(result.outcome).toBe("lift");
  });
});

describe("reviving", () => {
  cleanBeforeEach();

  function downOne() {
    playRows(HALL, { players: 4 });
    // the pads are the devices of players 3 and 4; players 1 and 2 stay put
    teleport(miners()[2], 5, 1);
    teleport(miners()[3], 5, 1);
    players.setState(3, "down", "test");
    game.step(2);
  }

  test("a friend holding the dig button next to a downed miner fills a bar, then the miner gets up with one heart and a grace", () => {
    downOne();
    const log = record("playerRevived");
    pad(0).press("A");
    game.step(60);
    expect(revive.progressOf(3)).toBeGreaterThan(0.2);
    expect(revive.progressOf(3)).toBeLessThan(1);
    expect(players.get(3).state).toBe("down");
    game.step(130);
    pad(0).release("A");
    expect(players.get(3).state).toBe("active");
    expect(players.get(3).hp).toBe(players.REVIVE_HP);
    expect(players.get(3).invulnerable).toBeGreaterThan(0);
    expect(log.length).toBe(1);
    expect(log[0].data.by).toBe(2);
    expect(log[0].data.player.id).toBe(3);
  });

  test("letting go empties the bar again, and a friend out of reach does nothing", () => {
    downOne();
    pad(0).press("A");
    game.step(90);
    pad(0).release("A");
    const held = revive.progressOf(3);
    expect(held).toBeGreaterThan(0.3);
    game.step(120);
    expect(revive.progressOf(3)).toBe(0);
    teleport(miners()[2], 15, 1); // far away
    pad(0).press("A");
    game.step(240);
    pad(0).release("A");
    expect(players.get(3).state).toBe("down");
  });

  test("a downed miner does not bleed out, and the shift ends with allDown only when everybody is down", () => {
    downOne();
    game.step(60 * 40);
    expect(players.get(3).state).toBe("down");
    expect(run.inShift).toBe(true);
    const log = record("shiftEnded");
    for (const p of players.all()) players.setState(p.id, "down", "test");
    game.step(60 * 6);
    expect(log.length).toBe(1);
    expect(run.lastShift.outcome).toBe("allDown");
    expect(run.inShift).toBe(false);
  });
});

describe("per-player controls", () => {
  cleanBeforeEach();

  test("rebinding is for one seat only: P2 swaps dig to Space on the keyboard family and the others keep their defaults", () => {
    controls.resetAll();
    const before = controls.bindingsFor(0, "keys", { kind: "keys", scheme: "keyboard" }).dig;
    controls.rebind(1, "keys", "dig", ["Q"]);
    expect(controls.bindingsFor(1, "keys", { kind: "keys", scheme: "keyboard" }).dig).toEqual(["Q"]);
    expect(controls.bindingsFor(0, "keys", { kind: "keys", scheme: "keyboard" }).dig).toEqual(before);
    controls.reset(1);
    expect(controls.bindingsFor(1, "keys", { kind: "keys", scheme: "keyboard" }).dig).toEqual(before);
  });

  test("a rebound key drives the miner of that seat, and the old key no longer digs", () => {
    controls.resetAll();
    players.clear();
    players.add({ device: { kind: "keys", scheme: "keyboard" } });
    controls.rebind(0, "keys", "right", ["L"]);
    playRows(HALL);
    const m = miner();
    teleport(m, 3, 1);
    const x0 = m.position.x;
    game.keyDown("L");
    game.step(20);
    game.keyUp("L");
    expect(m.position.x).toBeGreaterThan(x0 + 5);
    const x1 = m.position.x;
    game.keyDown("D");
    game.step(20);
    game.keyUp("D");
    expect(m.position.x).toBeLessThan(x1 + 1);
    controls.resetAll();
  });

  test("a rebound pad button is per seat: P2's A becomes X, P1 keeps A", () => {
    controls.resetAll();
    controls.rebind(1, "pad", "dig", ["GamepadY"]);
    expect(controls.bindingsFor(1, "pad", { kind: "pad", index: 1 }).dig).toEqual(["GamepadY"]);
    expect(controls.bindingsFor(0, "pad", { kind: "pad", index: 0 }).dig).not.toContain("GamepadY");
    controls.resetAll();
  });

  test("a binding of the wrong family is an error that says what to do", () => {
    expect(() => controls.rebind(0, "keys", "dig", ["GamepadA"])).toThrow(/key names like/);
    expect(() => controls.rebind(0, "pad", "dig", ["Space"])).toThrow(/Gamepad/);
  });

  test("the Options Controls page rebinds a seat with a key press and saves it", () => {
    controls.resetAll();
    game.load("scenes/menu.scene.json");
    game.step(3);
    game.click("options_button");
    game.step(3);
    game.click("tab_controls");
    game.step(2);
    game.click("controls_player"); // Player 2
    game.step(2);
    game.click("bind_dig");
    game.step(2);
    game.keyDown("Q");
    game.step(2);
    game.keyUp("Q");
    game.step(3);
    expect(controls.bindingsFor(1, "keys", { kind: "keys", scheme: "keyboard" }).dig).toEqual(["Q"]);
    expect(controls.bindingsFor(0, "keys", { kind: "keys", scheme: "keyboard" }).dig).not.toEqual(["Q"]);
    game.click("reset_controls");
    game.step(2);
    expect(controls.bindingsFor(1, "keys", { kind: "keys", scheme: "keyboard" }).dig).not.toEqual(["Q"]);
    controls.resetAll();
  });
});

describe("the camera", () => {
  cleanBeforeEach();
  const WIDE = ["B".repeat(80), "B.S" + ".".repeat(74) + "E.B", "B".repeat(80)];

  test("the view zooms out as the miners spread, up to the limit, and back in", () => {
    playRows(WIDE, { players: 2 });
    game.step(60);
    const near = world.find("camera").get("Camera").orthoSize;
    teleport(miners()[1], 35, 1);
    game.step(90);
    const far = world.find("camera").get("Camera").orthoSize;
    expect(far).toBeGreaterThan(near + 5);
    expect(far).toBeLessThanOrEqual(views.MAX_ORTHO + 0.5);
    teleport(miners()[1], 4, 1);
    game.step(120);
    expect(world.find("camera").get("Camera").orthoSize).toBeLessThan(far - 5);
  });

  test("the leash stops a miner from walking farther than the largest view shows", () => {
    playRows(WIDE, { players: 2 });
    teleport(miners()[1], 3, 1);
    game.step(2);
    const other = miners()[0];
    teleport(other, 3, 1);
    const m = miners()[1];
    game.keyDown("D"); // player 2 is on the arrows block
    game.step(1);
    game.keyUp("D");
    const span = views.maxSpan();
    game.keyDown("Right");
    game.step(400);
    game.keyUp("Right");
    expect(Math.abs(m.position.x - other.position.x)).toBeLessThanOrEqual(span.x + 1);
  });

  test("without the leash the planner splits the screen into two views and merges them again with hysteresis", () => {
    const planner = new views.ViewPlanner();
    const near = [{ id: 0, x: 0, y: 0 }, { id: 1, x: 100, y: 0 }];
    const far = [{ id: 0, x: 0, y: 0 }, { id: 1, x: 2000, y: 0 }];
    expect(planner.plan(near).mode).toBe("shared");
    const split = planner.plan(far);
    expect(split.mode).toBe("split");
    expect(split.views.length).toBe(2);
    expect(split.views.map((v) => v.viewport)).toEqual([[0, 0, 0.5, 1], [0.5, 0, 0.5, 1]]);
    // just inside the shared limit is not enough to merge: they have to come closer than MERGE_AT of it
    const edge = views.maxSpan().x;
    expect(planner.plan([{ id: 0, x: 0, y: 0 }, { id: 1, x: edge * 0.95, y: 0 }]).mode).toBe("split");
    expect(planner.plan([{ id: 0, x: 0, y: 0 }, { id: 1, x: edge * 0.5, y: 0 }]).mode).toBe("shared");
  });

  test("four miners in four corners make four views; three clusters make three", () => {
    const planner = new views.ViewPlanner();
    const four = planner.plan([{ id: 0, x: 0, y: 0 }, { id: 1, x: 3000, y: 0 }, { id: 2, x: 0, y: 3000 }, { id: 3, x: 3000, y: 3000 }]);
    expect(four.views.length).toBe(4);
    expect(four.views.map((v) => v.players.length)).toEqual([1, 1, 1, 1]);
    const three = new views.ViewPlanner().plan([{ id: 0, x: 0, y: 0 }, { id: 1, x: 20, y: 0 }, { id: 2, x: 3000, y: 0 }, { id: 3, x: 6000, y: 0 }]);
    expect(three.views.length).toBe(3);
  });

  test("with the tether off, miners can part and the shift reports a split view; the fog and 16-light cap still hold", () => {
    views.config.tether = false;
    try {
      const shift = playRows(WIDE, { players: 2, stratum: 1 });
      teleport(miners()[1], 70, 1);
      game.step(90);
      expect(views.current.mode).toBe("split");
      expect(views.current.views.length).toBe(2);
      expect(shift.lights.pool.length).toBeLessThanOrEqual(16);
    } finally {
      views.config.tether = true;
    }
  });
});

describe("a pad unplugged mid-shift", () => {
  cleanBeforeEach();

  test("the game pauses with a prompt, and goes on when the pad is back", () => {
    playRows(HALL, { players: 4, padWatch: true });
    const log = record("controllerLost", "controllerRestored");
    pad(1).disconnect(); // player 4
    game.step(5);
    expect(game.paused).toBe(true);
    expect(log[0].name).toBe("controllerLost");
    expect(log[0].data.player.id).toBe(3);
    const x = miners()[0].position.x;
    game.step(30);
    expect(miners()[0].position.x).toBe(x);
    pad(1).connect();
    game.step(5);
    expect(game.paused).toBe(false);
    expect(log[log.length - 1].data.how).toBe("reconnected");
  });

  test("a free controller takes the miner over with A; a pad another player uses cannot", () => {
    playRows(HALL, { players: 4, padWatch: true }); // devices: any, arrows, pad 0, pad 1
    pad(1).disconnect();
    game.step(5);
    expect(game.paused).toBe(true);
    pad(0).tap("A"); // pad 0 is player 3's
    expect(game.paused).toBe(true);
    pad(2).connect();
    game.step(2);
    pad(2).tap("A");
    expect(game.paused).toBe(false);
    expect(players.get(3).device).toEqual({ kind: "pad", index: 2 });
  });

  test("the keyboard takes over a miner whose pad is gone when no other player uses it", () => {
    players.clear();
    players.add({ device: { kind: "pad", index: 0 } });
    players.add({ device: { kind: "pad", index: 1 } });
    plugPads();
    playRows(HALL, { padWatch: true });
    pad(1).disconnect();
    game.step(5);
    expect(game.paused).toBe(true);
    tapKey("Enter");
    expect(game.paused).toBe(false);
    expect(players.get(1).device).toEqual({ kind: "keys", scheme: "keyboard" });
  });

  test("another player drops the missing one with Y: the miner leaves the mine and the shift goes on", () => {
    playRows(HALL, { players: 4, padWatch: true });
    pad(1).disconnect();
    game.step(5);
    expect(game.paused).toBe(true);
    pad(0).tap("Y");
    game.step(3);
    expect(game.paused).toBe(false);
    expect(players.count()).toBe(3);
    expect(game.world.findByTag("miner").length).toBe(3);
  });
});
