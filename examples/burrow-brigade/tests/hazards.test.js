// The hazards (scripts/game/hazards.js): spreading water, magma and cave-ins, what each does to a miner, and the outcome
// when every miner is down. Mines are written by hand as rows of text (tests/helpers/world.js).
import { test, describe, expect, game } from "factoria:test";
import { scene } from "factoria";
import { cleanBeforeEach, playRows, miner, miners, teleport, record, tileOf } from "./helpers/world.js";
import { live } from "../scripts/game/mine_map.js";
import { run } from "../scripts/game/run_state.js";
import * as players from "../scripts/game/players.js";
import { K } from "../scripts/game/tiles.js";
import { DROWN_TIME, WATER_SLOW, CAVE_WARNING } from "../scripts/game/hazards.js";

const SECOND = 60;

// a room on the left (3 rows), a dirt seal at (9,1), a sealed pocket of three water tiles behind it (10..12,1), a second seal
// at (13,1), then a short corridor to the exit lift
const FLOOD = [
  "BBBBBBBBBBBBBBBBBBBB",
  "B.S......#www#...EBB",
  "B.........BBBBBBB..B",
  "B.........BBBBBBB..B",
  "BBBBBBBBBBBBBBBBBBBB",
];

describe("water", () => {
  cleanBeforeEach();
  test("a sealed pocket does nothing until a miner digs the wall in front of it", () => {
    playRows(FLOOD);
    const log = record("hazardTriggered");
    game.step(5 * SECOND);
    expect(live.map.count(K.WATER)).toBe(3);
    expect(log.length).toBe(0);
    live.map.dig(9, 1, { tier: 0, by: 0 });
    game.step(SECOND);
    expect(log[0].data).toMatchObject({ kind: "flood", phase: "start" });
  });

  test("an opened pocket spreads over the floor of the tunnel, wave after wave, and stops at its volume", () => {
    playRows(FLOOD);
    live.map.dig(9, 1, { tier: 0, by: 0 });
    game.step(2 * SECOND);
    const early = live.map.count(K.WATER);
    expect(early).toBeGreaterThan(3);
    game.step(40 * SECOND);
    const late = live.map.count(K.WATER);
    expect(late).toBeGreaterThan(early);
    game.step(10 * SECOND);
    expect(live.map.count(K.WATER)).toBe(late); // the budget is used up: it does not flood the whole mine
    expect(live.map.kindAt(2, 1)).toBe(K.LIFT_START); // a lift is never flooded
    expect(live.map.kindAt(13, 1)).toBe(K.DIRT); // nor is a wall
  });

  test("spreading water tells the bus and redraws the Tilemap", () => {
    playRows(FLOOD);
    const log = record("hazardTriggered", "tileChanged");
    live.map.dig(9, 1, { tier: 0, by: 0 });
    game.step(3 * SECOND);
    expect(log.some((l) => l.name === "hazardTriggered" && l.data.phase === "spread")).toBe(true);
    expect(log.some((l) => l.name === "tileChanged" && l.data.cause === "flood")).toBe(true);
  });

  test("a miner walks at half speed in water", () => {
    playRows(FLOOD);
    expect(live.hazards.speedFactor(11, 1)).toBe(WATER_SLOW);
    expect(live.hazards.speedFactor(3, 1)).toBe(1);
    const m = miner();
    teleport(m, 3, 1);
    const x0 = m.position.x;
    game.keyDown("D");
    game.step(30);
    game.keyUp("D");
    const dry = m.position.x - x0;
    for (let tx = 4; tx <= 8; tx++) live.map.setKind(tx, 1, K.WATER, "test");
    teleport(m, 4, 1);
    const x1 = m.position.x;
    game.keyDown("D");
    game.step(30);
    game.keyUp("D");
    const wet = m.position.x - x1;
    expect(wet).toBeGreaterThan(0);
    expect(wet).toBeLessThan(dry * 0.7);
  });

  test("a miner who stays in water drowns after a few seconds: playerDown 'drowned', hazardTriggered 'hit'", () => {
    playRows(FLOOD);
    const log = record("playerDown", "hazardTriggered");
    teleport(miner(), 11, 1); // standing in the pocket
    game.step(Math.floor((DROWN_TIME - 0.5) * SECOND));
    expect(players.get(0).state).toBe("active");
    game.step(Math.ceil(1 * SECOND));
    expect(players.get(0).state).toBe("down");
    const down = log.find((l) => l.name === "playerDown");
    expect(down.data.cause).toBe("drowned");
    expect(log.some((l) => l.name === "hazardTriggered" && l.data.phase === "hit" && l.data.kind === "flood" && l.data.player === 0)).toBe(true);
  });

  test("leaving the water in time saves the miner (the clock runs back)", () => {
    playRows(FLOOD);
    teleport(miner(), 11, 1);
    game.step(2 * SECOND);
    expect(live.hazards.exposureOf(0).water).toBeGreaterThan(1.5);
    teleport(miner(), 3, 1);
    game.step(4 * SECOND);
    expect(live.hazards.exposureOf(0).water).toBeLessThan(0.1);
    expect(players.get(0).state).toBe("active");
  });
});

const MAGMA = [
  "BBBBBBBBBBBBBBBB",
  "B.S...MMM...EBBB",
  "BBBBBBBBBBBBBBBB",
];

describe("magma", () => {
  cleanBeforeEach();
  test("a miner on magma burns at once: playerDown 'burned'", () => {
    playRows(MAGMA, { stratum: 2 });
    const log = record("playerDown", "hazardTriggered");
    teleport(miner(), 7, 1);
    game.step(SECOND);
    expect(players.get(0).state).toBe("down");
    expect(log.find((l) => l.name === "playerDown").data.cause).toBe("burned");
    expect(log.some((l) => l.name === "hazardTriggered" && l.data.kind === "magma" && l.data.phase === "hit")).toBe(true);
  });

  test("a pool next to open floor spreads slowly, over floor only", () => {
    playRows(MAGMA, { stratum: 2 });
    const n0 = live.map.count(K.MAGMA);
    game.step(6 * SECOND);
    expect(live.map.count(K.MAGMA)).toBeGreaterThan(n0);
    expect(live.map.kindAt(2, 1)).toBe(K.LIFT_START);
    expect(live.map.kindAt(12, 1)).toBe(K.LIFT_EXIT);
  });
});

// a cracked tile at (5,1) in a corridor; the cave-in takes the 3 x 3 tiles around it
const CAVE = [
  "BBBBBBBBBBBBBBBB",
  "B.S..x.......EBB",
  "B....#.......BBB",
  "BBBBBBBBBBBBBBBB",
];

describe("cave-ins", () => {
  cleanBeforeEach();
  test("stepping on a cracked tile starts a warning; the rocks fall after the warning and put the miner down", () => {
    playRows(CAVE);
    const log = record("hazardTriggered", "playerDown");
    teleport(miner(), 5, 1);
    game.step(10);
    expect(log[0].data).toMatchObject({ kind: "caveIn", phase: "start", tx: 5, ty: 1 });
    expect(live.hazards.collapsing).toBe(true);
    // the warning signs are on the free tiles of the 3 x 3
    expect(game.world.entities().filter((e) => e.get("Sprite") && e.position.y === live.map.tileCenter(5, 1).y && e.active).length).toBeGreaterThan(0);
    game.step(Math.floor((CAVE_WARNING - 0.3) * SECOND));
    expect(players.get(0).state).toBe("active"); // still time to run
    game.step(Math.ceil(0.6 * SECOND));
    expect(players.get(0).state).toBe("down");
    expect(log.find((l) => l.name === "playerDown").data.cause).toBe("caveIn");
    expect(log.some((l) => l.name === "hazardTriggered" && l.data.phase === "impact")).toBe(true);
    expect(live.hazards.collapsing).toBe(false);
    // the 3 x 3 turned to rock
    expect(live.map.kindAt(5, 1)).toBe(K.ROCK);
    expect(live.map.kindAt(4, 1)).toBe(K.ROCK);
    expect(live.map.kindAt(6, 2)).toBe(K.ROCK);
    expect(live.map.kindAt(8, 1)).toBe(K.FLOOR);
  });

  test("a miner who runs out of the 3 x 3 in time is spared", () => {
    playRows(CAVE, { players: 2 });
    teleport(miners()[0], 5, 1); // triggers
    teleport(miners()[1], 10, 1); // far away
    game.step(Math.floor(0.5 * SECOND));
    teleport(miners()[0], 9, 1); // got out
    game.step(2 * SECOND);
    expect(players.get(0).state).toBe("active");
    expect(players.get(1).state).toBe("active");
    expect(live.map.kindAt(5, 1)).toBe(K.ROCK);
  });

  test("a miner on the exit lift is safe from a cave-in", () => {
    playRows(["BBBBBBBBB", "B.S.xE..B", "BBBBBBBBB"], { players: 2 });
    teleport(miners()[0], 4, 1); // on the cracked tile
    teleport(miners()[1], 5, 1); // next to it, on the exit lift
    game.step(2 * SECOND);
    expect(players.get(0).state).toBe("down");
    expect(players.get(1).state).toBe("lift");
  });
});

describe("everyone down", () => {
  cleanBeforeEach();
  test("the shift ends 'allDown' with nothing banked, and the results scene follows", () => {
    playRows(MAGMA, { stratum: 2 });
    const before = scene.current;
    const log = record("shiftEnded");
    run.ore.copper = 3; // pretend the team had mined something
    teleport(miner(), 7, 1);
    game.step(SECOND);
    expect(log.length).toBe(1);
    expect(log[0].data.outcome).toBe("allDown");
    expect(log[0].data.banked).toBe(0);
    expect(run.inShift).toBe(false);
    game.step(5 * SECOND);
    expect(scene.current).not.toBe(before);
    expect(scene.current).toBe("scenes/results.scene.json");
  });

  test("with several players the shift goes on until the last one goes down", () => {
    playRows(MAGMA, { stratum: 2, players: 3 });
    const log = record("shiftEnded", "playerDown");
    teleport(miners()[0], 7, 1);
    teleport(miners()[1], 8, 1);
    game.step(SECOND);
    expect(log.filter((l) => l.name === "playerDown").length).toBe(2);
    expect(log.some((l) => l.name === "shiftEnded")).toBe(false);
    expect(players.alive().length).toBe(1);
    teleport(miners()[2], 6, 1);
    game.step(SECOND);
    expect(log.find((l) => l.name === "shiftEnded").data.outcome).toBe("allDown");
  });

  test("a down miner lies faded and cannot walk", () => {
    playRows(MAGMA, { stratum: 2, players: 2 });
    teleport(miners()[0], 7, 1);
    game.step(SECOND);
    const m = miners()[0];
    const t = tileOf(m);
    game.keyDown("D");
    game.keyDown("ArrowRight");
    game.step(30);
    game.keyUp("D");
    game.keyUp("ArrowRight");
    expect(tileOf(m)).toEqual(t);
    expect(m.get("Sprite").color[3]).toBeLessThan(1);
  });
});
