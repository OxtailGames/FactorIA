// Light and the dark: the pool that keeps the game under FactorIA's 16 Light2D, the torches, and the fog of war
// (scripts/game/lights.js, scripts/game/fog.js).
import { test, describe, expect, game } from "factoria:test";
import { cleanBeforeEach, playRows, playGenerated, miners, miner, teleport, record, activeLights } from "./helpers/world.js";
import { live } from "../scripts/game/mine_map.js";
import { run, lampOf, lampRadius } from "../scripts/game/run_state.js";
import { ENGINE_LIGHT_CAP } from "../scripts/game/lights.js";
import { UNSEEN, SEEN, VISIBLE, SIGHT_EXTRA, TORCH_RADIUS } from "../scripts/game/fog.js";
import { K, TILE } from "../scripts/game/tiles.js";

const SECOND = 60;

// a long hall with a crystal wall full of lights above and below
function crystalHall() {
  const wall = "B" + "*".repeat(38) + "B";
  return [
    "B".repeat(40),
    wall,
    wall,
    "B.S" + ".".repeat(34) + "EB".padEnd(3, "B"),
    "B" + ".".repeat(38) + "B",
    wall,
    wall,
    "B".repeat(40),
  ].map((r) => r.slice(0, 40).padEnd(40, "B"));
}

describe("the Light2D pool", () => {
  cleanBeforeEach();
  test("a mine with many crystal walls, magma and torches never has more than 16 active Light2D (the engine's cap)", () => {
    const shift = playRows(crystalHall(), { stratum: 1, players: 4 });
    expect(shift.lights.sources.filter((s) => s.kind === "crystal").length).toBeGreaterThan(40);
    // the miners are at the start; place six torches along the hall, which adds six more sources
    run.torches = 6;
    for (let i = 0; i < 6; i++) {
      teleport(miners()[0], 5 + i * 2, 4);
      game.step(2);
      expect(shift.lights.placeTorch(0)).toBe(true);
    }
    expect(run.torches).toBe(0);
    game.step(SECOND);
    const lights = activeLights();
    expect(lights.length).toBeLessThanOrEqual(ENGINE_LIGHT_CAP);
    // the four lamps are among them, and the pool fills what is left
    expect(lights.length).toBeGreaterThanOrEqual(4 + 6);
    expect(game.renderStats().lightsDropped ?? 0).toBe(0);
  });

  test("the pool serves the sources nearest to the miners, and follows them", () => {
    const shift = playRows(crystalHall(), { stratum: 1 });
    teleport(miner(), 3, 3);
    game.step(SECOND);
    const nearStart = shift.lights.pool.filter((p) => p.source).map((p) => p.source.tx);
    expect(Math.max(...nearStart)).toBeLessThan(14);
    teleport(miner(), 33, 4);
    game.step(SECOND);
    const nearEnd = shift.lights.pool.filter((p) => p.source).map((p) => p.source.tx);
    expect(Math.min(...nearEnd)).toBeGreaterThan(20);
    expect(activeLights().length).toBeLessThanOrEqual(ENGINE_LIGHT_CAP);
  });

  test("a generated Crystal Caves floor with four players stays under the cap while they walk around", () => {
    const shift = playGenerated(1, 1, 1234, 4);
    for (const m of miners()) teleport(m, live.mine.start.tx, live.mine.start.ty);
    for (let i = 0; i < 6; i++) {
      game.step(SECOND / 2);
      expect(activeLights().length).toBeLessThanOrEqual(ENGINE_LIGHT_CAP);
    }
    expect(shift.lights.lit).toBeGreaterThan(0);
    expect(shift.lights.pool.length).toBe(ENGINE_LIGHT_CAP - 4);
  });
});

describe("torches", () => {
  cleanBeforeEach();
  const HALL = ["BBBBBBBBBBBBBBBB", "B.S..o.......EBB", "BBBBBBBBBBBBBBBB"];
  test("the torch key puts a torch on the floor under the miner and uses one of the team's supply", () => {
    playRows(HALL);
    const log = record("torchPlaced");
    const before = run.torches;
    expect(before).toBeGreaterThan(0);
    teleport(miner(), 4, 1);
    game.keyDown("T");
    game.step(3);
    game.keyUp("T");
    game.step(3);
    expect(run.torches).toBe(before - 1);
    expect(log.length).toBe(1);
    expect(log[0].data).toMatchObject({ tx: 4, ty: 1, by: 0, left: before - 1 });
    expect(live.lights.torches.length).toBe(1);
    expect(live.lights.sources[0].kind).toBe("torch");
  });

  test("a torch cannot go on a lift, an oil can or a tile that already has one, and none are left at zero", () => {
    playRows(HALL);
    teleport(miner(), 2, 1); // entry lift
    expect(live.lights.placeTorch(0)).toBe(false);
    teleport(miner(), 5, 1); // oil can
    expect(live.lights.placeTorch(0)).toBe(false);
    teleport(miner(), 7, 1);
    game.step(2);
    expect(live.lights.placeTorch(0)).toBe(true);
    expect(live.lights.placeTorch(0)).toBe(false); // already one here
    run.torches = 0;
    teleport(miner(), 9, 1);
    game.step(2);
    expect(live.lights.placeTorch(0)).toBe(false);
  });

  test("a torch lights the pool and keeps showing the mine around it after the miner leaves", () => {
    playRows(HALL);
    teleport(miner(), 8, 1);
    game.step(2);
    live.lights.placeTorch(0);
    teleport(miner(), 1, 1);
    game.step(SECOND);
    const lit = live.lights.pool.some((p) => p.source && p.source.kind === "torch" && p.source.tx === 8);
    expect(lit).toBe(true);
    expect(live.fog.isVisible(8, 1)).toBe(true);
    expect(live.fog.isVisible(11, 1)).toBe(true); // within TORCH_RADIUS of the torch
    expect(TORCH_RADIUS).toBeGreaterThan(3);
  });
});

describe("fog of war", () => {
  cleanBeforeEach();
  const CORRIDOR = [
    "B".repeat(30),
    "B.S.....#........E.....B".padEnd(30, "B"),
    "B".repeat(30),
  ];
  test("the unexplored mine is black; what the miner's lamp reaches is revealed", () => {
    playRows(CORRIDOR);
    game.step(SECOND / 2);
    const fog = live.fog;
    const r = lampRadius(lampOf(0)) / TILE + SIGHT_EXTRA;
    expect(r).toBeGreaterThan(3);
    expect(fog.isVisible(3, 1)).toBe(true);
    expect(fog.stateAt(20, 1)).toBe(UNSEEN);
    expect(fog.stateAt(25, 1)).toBe(UNSEEN);
    expect(fog.seen()).toBeGreaterThan(5);
    expect(fog.seen()).toBeLessThan(fog.width * fog.height / 2);
  });

  test("walking reveals more, and what was seen is remembered when the miner moves on", () => {
    playRows(CORRIDOR);
    game.step(SECOND / 2);
    const fog = live.fog;
    const seen0 = fog.seen();
    expect(fog.stateAt(6, 1)).toBe(VISIBLE);
    teleport(miner(), 7, 1);
    game.step(SECOND / 2);
    expect(fog.seen()).toBeGreaterThan(seen0);
    // far away on the other side of the wall at (8,1): the corridor seen before is remembered, not black, but no longer lit
    teleport(miner(), 20, 1);
    game.step(SECOND);
    expect(fog.stateAt(3, 1)).toBe(SEEN);
    expect(fog.stateAt(7, 1)).toBe(SEEN);
    expect(fog.stateAt(20, 1)).toBe(VISIBLE);
  });

  test("a wall stops the view; digging through it opens the view at once", () => {
    playRows(CORRIDOR);
    game.step(SECOND / 2);
    const fog = live.fog;
    teleport(miner(), 6, 1);
    game.step(SECOND / 2);
    expect(fog.isVisible(8, 1)).toBe(true); // the wall itself shows
    expect(fog.stateAt(10, 1)).toBe(UNSEEN); // the tunnel behind it does not
    live.map.dig(8, 1, { tier: 0, by: 0 });
    game.step(SECOND / 2);
    expect(fog.stateAt(10, 1)).not.toBe(UNSEEN);
  });

  test("the fog is drawn: a Tilemap over the mine whose tiles follow the states", () => {
    playRows(CORRIDOR);
    game.step(SECOND / 2);
    const tilemaps = game.world.entities().filter((e) => e.get("Tilemap") && e !== game.find("mine"));
    expect(tilemaps.length).toBe(1);
    const tiles = tilemaps[0].get("Tilemap").tiles;
    expect(tiles.length).toBe(live.fog.width * live.fog.height);
    expect(tiles[1 * live.fog.width + 25]).toBe(0); // black over the unexplored part
    expect(tiles[1 * live.fog.width + 3]).toBe(-1); // nothing over the lit part
  });

  test("a lamp that runs low shows less", () => {
    playRows(CORRIDOR);
    game.step(SECOND / 2);
    const full = live.fog.seen();
    lampOf(0).oil = 8; // nearly out
    teleport(miner(), 14, 1);
    const fog2 = live.fog;
    fog2.state.fill(0);
    fog2.update(0.2, { force: true });
    const small = fog2.seen();
    expect(small).toBeLessThan(full);
    expect(small).toBeGreaterThan(0);
  });
});
