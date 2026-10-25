// The keyboard and a gamepad each drive the miner: walking, facing and digging. Up to four players share the code through the
// players registry (their devices are tested here too, so co-op only has to add players).
import { test, describe, expect, game } from "factoria:test";
import { freshRunBeforeEach, loadMine, miner, teleport } from "./helpers/mine.js";
import { live } from "../scripts/game/mine_map.js";
import { run } from "../scripts/game/run_state.js";
import * as players from "../scripts/game/players.js";
import { K } from "../scripts/game/tiles.js";

/** Tile of a miner. */
const at = (m) => live.map.tileAt(m.position.x, m.position.y);

describe("keyboard", () => {
  freshRunBeforeEach();

  test("WASD and the arrows walk the miner", () => {
    loadMine();
    live.map.setKind(4, 1, K.FLOOR, "test");
    const m = miner();
    const x0 = m.position.x;
    game.keyDown("D");
    game.step(20);
    game.keyUp("D");
    expect(m.position.x).toBeGreaterThan(x0 + 10);
    const x1 = m.position.x;
    game.keyDown("Left");
    game.step(20);
    game.keyUp("Left");
    expect(m.position.x).toBeLessThan(x1 - 10);
  });

  test("up and down walk through a dug shaft, and the miner stops at walls", () => {
    loadMine();
    live.map.setKind(5, 1, K.FLOOR, "test");
    live.map.setKind(5, 2, K.FLOOR, "test");
    teleport(miner(), live.map, 5, 1);
    game.keyDown("S");
    game.step(40);
    game.keyUp("S");
    expect(at(miner())).toEqual({ tx: 5, ty: 3 }); // stopped by the bedrock below row 3
    game.keyDown("Up");
    game.step(40);
    game.keyUp("Up");
    expect(at(miner())).toEqual({ tx: 5, ty: 1 });
  });

  test("Space and J dig", () => {
    loadMine();
    teleport(miner(), live.map, 3, 1);
    game.keyDown("D");
    game.keyDown("J");
    game.step(40);
    expect(live.map.kindAt(4, 1)).toBe(K.FLOOR);
  });

  test("two keys at once are not faster than one", () => {
    loadMine();
    live.map.setKind(5, 1, K.FLOOR, "test");
    live.map.setKind(5, 2, K.FLOOR, "test");
    teleport(miner(), live.map, 5, 2);
    const p0 = { x: miner().position.x, y: miner().position.y };
    game.keyDown("D");
    game.keyDown("W");
    game.step(1);
    const dx = miner().position.x - p0.x, dy = miner().position.y - p0.y;
    expect(Math.hypot(dx, dy)).toBeLessThan(72 / 60 + 0.01);
  });
});

describe("gamepad", () => {
  freshRunBeforeEach();

  test("the left stick walks the miner", () => {
    loadMine();
    live.map.setKind(4, 1, K.FLOOR, "test");
    const m = miner();
    const x0 = m.position.x;
    game.gamepad(0).axis("LeftX", 1);
    game.step(20);
    expect(m.position.x).toBeGreaterThan(x0 + 10);
    game.gamepad(0).axis("LeftX", 0);
  });

  test("a half-tilted stick walks slower than a full one", () => {
    loadMine();
    const m = miner();
    live.map.setKind(4, 1, K.FLOOR, "test");
    const x0 = m.position.x;
    game.gamepad(0).axis("LeftX", 0.5);
    game.step(10);
    const half = m.position.x - x0;
    game.gamepad(0).axis("LeftX", 0);
    game.step(2);
    const x1 = m.position.x;
    game.gamepad(0).axis("LeftX", 1);
    game.step(10);
    expect(m.position.x - x1).toBeGreaterThan(half * 1.4);
    game.gamepad(0).axis("LeftX", 0);
  });

  test("the d-pad walks and A digs", () => {
    loadMine();
    teleport(miner(), live.map, 3, 1);
    game.gamepad(0).press("DpadRight");
    game.step(3);
    game.gamepad(0).press("A");
    game.step(40);
    expect(live.map.kindAt(4, 1)).toBe(K.FLOOR);
    game.gamepad(0).release("A");
    game.gamepad(0).release("DpadRight");
    expect(run.ore.copper).toBe(0);
  });

  test("X digs too", () => {
    loadMine();
    teleport(miner(), live.map, 3, 1);
    game.gamepad(0).axis("LeftX", 1);
    game.gamepad(0).press("X");
    game.step(40);
    expect(live.map.kindAt(4, 1)).toBe(K.FLOOR);
  });
});

describe("players on their own devices", () => {
  freshRunBeforeEach();

  test("two keyboard players and a gamepad player each move only their own miner", () => {
    players.clear();
    players.add({ device: { kind: "keys", scheme: "wasd" } });
    players.add({ device: { kind: "keys", scheme: "arrows" } });
    players.add({ device: { kind: "pad", index: 1 } });
    loadMine();
    expect(game.world.findByTag("miner").length).toBe(3);
    for (let i = 0; i < 3; i++) {
      live.map.setKind(5 + i, 1, K.FLOOR, "test");
      teleport(miner(i), live.map, 8 + i * 3, 1);
    }
    game.step(1);
    const x = [0, 1, 2].map((i) => miner(i).position.x);
    game.keyDown("D"); // player 0 only
    game.step(10);
    expect(miner(0).position.x).toBeGreaterThan(x[0] + 5);
    expect(miner(1).position.x).toBe(x[1]);
    expect(miner(2).position.x).toBe(x[2]);
    game.keyUp("D");
    game.keyDown("Right"); // player 1 only
    game.step(10);
    expect(miner(1).position.x).toBeGreaterThan(x[1] + 5);
    expect(miner(2).position.x).toBe(x[2]);
    game.keyUp("Right");
    game.gamepad(1).axis("LeftX", 1); // the second pad: player 2 only
    game.step(10);
    expect(miner(2).position.x).toBeGreaterThan(x[2] + 5);
    game.gamepad(1).axis("LeftX", 0);
  });

  test("the registry holds four players, no more, each with its own colour", () => {
    players.clear();
    for (let i = 0; i < 4; i++) players.add({ device: { kind: "pad", index: i } });
    expect(players.count()).toBe(4);
    expect(() => players.add({ device: { kind: "pad", index: 0 } })).toThrow("room for 4");
    const colors = new Set(players.all().map((p) => p.color.join(",")));
    expect(colors.size).toBe(4);
    players.remove(1);
    expect(players.add({ device: { kind: "keys", scheme: "ijkl" } }).id).toBe(1); // the lowest free slot
    players.remove(2);
    expect(() => players.add({ device: { kind: "keys", scheme: "dvorak" } })).toThrow("wasd");
  });
});
