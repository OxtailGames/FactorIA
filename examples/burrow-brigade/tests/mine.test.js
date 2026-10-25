// Digging, ore, oil, the dark and the lift, on the handmade mine of scenes/test_mine.scene.json (layout in helpers/mine.js).
import { test, describe, expect, game } from "factoria:test";
import { scene } from "factoria";
import { freshRunBeforeEach, loadMine, miner, teleport } from "./helpers/mine.js";
import { live } from "../scripts/game/mine_map.js";
import { run, lampOf } from "../scripts/game/run_state.js";
import * as events from "../scripts/game/events.js";
import * as players from "../scripts/game/players.js";
import { K, tileIndex } from "../scripts/game/tiles.js";
import { mineHash } from "../scripts/game/generator.js";

describe("the mine on the map", () => {
  freshRunBeforeEach();
  test("the shift scene builds the mine, the map and one miner next to the entry lift", () => {
    const shift = loadMine();
    expect(live.map).toBe(shift.map);
    expect(live.mine.width).toBe(24);
    expect(live.map.kindAt(2, 1)).toBe(K.LIFT_START);
    expect(live.map.kindAt(19, 1)).toBe(K.LIFT_EXIT);
    const tile = live.map.tileAt(miner().position.x, miner().position.y);
    expect(tile).toEqual({ tx: 1, ty: 1 });
    expect(run.inShift).toBe(true);
    expect(run.molesTotal).toBe(1);
    const tiles = game.find("mine").get("Tilemap").tiles;
    expect(tiles.length).toBe(24 * 5);
  });

  test("the map answers solid and walkable and refuses to dig bedrock", () => {
    loadMine();
    const map = live.map;
    expect(map.isSolid(4, 1)).toBe(true);
    expect(map.isWalkable(3, 1)).toBe(true);
    expect(map.isSolid(-1, 0)).toBe(true); // off the map counts as bedrock
    expect(map.canDig(4, 1, 0)).toEqual({ ok: true });
    expect(map.canDig(0, 1, 5).reason).toBe("bedrock");
    expect(map.canDig(3, 1, 0).reason).toBe("air");
    expect(map.dig(0, 1, { tier: 5 }).ok).toBe(false);
  });
});

describe("digging", () => {
  freshRunBeforeEach();
  test("holding dig on dirt turns it to floor, tells the bus, and redraws the Tilemap", () => {
    loadMine();
    const dug = [];
    const off = events.on("dug", (e) => dug.push(e));
    const changed = [];
    live.map.onChange((c) => changed.push(c));
    teleport(miner(), live.map, 3, 1);
    game.keyDown("D"); // walk into the dirt at (4,1): face it
    game.step(5);
    game.keyDown("Space");
    game.step(15);
    expect(live.map.kindAt(4, 1)).toBe(K.DIRT); // dirt takes 0.5 s: not done yet
    expect(game.find("mine").get("Tilemap").tiles[1 * 24 + 4]).toBe(tileIndex(K.DIRT, 4, 1));
    game.step(20);
    expect(live.map.kindAt(4, 1)).toBe(K.FLOOR);
    expect(game.find("mine").get("Tilemap").tiles[1 * 24 + 4]).toBe(tileIndex(K.FLOOR, 4, 1)); // redrawn
    expect(dug.length).toBe(1);
    expect(dug[0]).toEqual({ tx: 4, ty: 1, from: K.DIRT, by: 0 });
    expect(changed.some((c) => c.tx === 4 && c.ty === 1 && c.to === K.FLOOR)).toBe(true);
    off();
  });

  test("a dug tile changes the mine hash", () => {
    loadMine();
    const before = mineHash(live.mine);
    live.map.dig(4, 1, { tier: 0 });
    expect(mineHash(live.mine)).not.toBe(before);
  });

  test("rock takes longer than dirt", () => {
    loadMine();
    live.map.setKind(4, 1, K.FLOOR, "test");
    teleport(miner(), live.map, 4, 1);
    game.keyDown("S"); // blocked by the rock at (4,2): the miner faces down
    game.keyDown("Space");
    game.step(60);
    expect(live.map.kindAt(4, 2)).toBe(K.ROCK); // 1 s: dirt would be done in 0.5 s
    game.step(40);
    expect(live.map.kindAt(4, 2)).toBe(K.FLOOR); // rock takes 1.4 s
  });

  test("hard rock and gold need the better pick", () => {
    loadMine();
    const blocked = [];
    events.on("digBlocked", (e) => blocked.push(e));
    live.map.setKind(8, 1, K.FLOOR, "test");
    teleport(miner(), live.map, 8, 1);
    game.keyDown("S");
    game.keyDown("Space");
    game.step(200);
    expect(live.map.kindAt(8, 2)).toBe(K.HARD);
    expect(blocked.length).toBe(1); // told once, not every frame
    expect(blocked[0].reason).toBe("tier");
    run.upgrades.pickTier = 1;
    game.keyUp("Space");
    game.step(2);
    game.keyDown("Space");
    game.step(150); // 2.2 s
    expect(live.map.kindAt(8, 2)).toBe(K.FLOOR);
  });

  test("bedrock never breaks", () => {
    loadMine();
    teleport(miner(), live.map, 1, 1);
    game.keyDown("W"); // the bedrock at (1,0)
    game.keyDown("Space");
    game.step(300);
    expect(live.map.kindAt(1, 0)).toBe(K.BEDROCK);
  });

  test("the miner cannot walk through dirt", () => {
    loadMine();
    teleport(miner(), live.map, 3, 1);
    game.keyDown("D");
    game.step(60);
    expect(live.map.tileAt(miner().position.x, miner().position.y).tx).toBe(3);
  });
});

describe("ore", () => {
  freshRunBeforeEach();
  test("digging copper puts it in the pockets and tells the bus", () => {
    loadMine();
    const picked = [];
    events.on("orePicked", (e) => picked.push(e));
    live.map.setKind(4, 1, K.FLOOR, "test");
    teleport(miner(), live.map, 4, 1);
    game.keyDown("D");
    game.keyDown("Space");
    game.step(50); // copper 0.6 s
    expect(live.map.kindAt(5, 1)).toBe(K.FLOOR);
    expect(run.ore.copper).toBe(1);
    expect(picked.length).toBe(1);
    expect(picked[0].ore).toBe("copper");
    expect(picked[0].value).toBe(1);
    expect(picked[0].total).toBe(1);
    expect(game.audioLog().length).toBeGreaterThan(0);
  });

  test("gold and gems are worth more (with the better pick)", () => {
    loadMine();
    run.upgrades.pickTier = 1;
    live.map.setKind(12, 1, K.FLOOR, "test");
    teleport(miner(), live.map, 12, 1);
    game.keyDown("S");
    game.keyDown("Space");
    game.step(160); // gold 2.4 s
    expect(run.ore.gold).toBe(1);
    expect(events.emitted("orePicked").pop().value).toBe(8);
  });
});

describe("the lamp", () => {
  freshRunBeforeEach();
  test("oil drains one second per second, the light shrinks, and the lamp warns once when it runs low", () => {
    loadMine();
    const lamp = lampOf(0);
    const light = miner().behaviour.lampLight.get("Light2D");
    expect(lamp.oil).toBeCloseTo(120, 0);
    const radius0 = light.radius;
    game.step(60);
    expect(lamp.oil).toBeCloseTo(119, 1);
    lamp.oil = 31;
    game.step(120);
    expect(lamp.oil).toBeCloseTo(29, 1);
    expect(lamp.low).toBe(true);
    expect(events.count("lampLow")).toBe(1);
    expect(light.radius).toBeLessThan(radius0 * 0.8);
  });

  test("a dry lamp gives no light, tells the bus, and the shift ends in the dark after a few seconds", () => {
    loadMine();
    live.map.setKind(4, 1, K.FLOOR, "test");
    run.ore.copper = 5; // carried ore is lost in the dark
    const lamp = lampOf(0);
    lamp.oil = 1;
    game.step(70);
    expect(lamp.out).toBe(true);
    expect(events.count("lampOut")).toBe(1);
    expect(miner().behaviour.lampLight.get("Light2D").intensity).toBe(0);
    expect(run.inShift).toBe(true); // a grace period: an oil can may still be near
    game.step(130);
    expect(run.inShift).toBe(false);
    expect(run.lastShift.outcome).toBe("dark");
    expect(run.lastShift.banked).toBe(0);
    expect(run.cash).toBe(0);
    expect(events.count("shiftEnded")).toBe(1);
  });

  test("an oil can refills the lamp and is used up", () => {
    loadMine();
    const lamp = lampOf(0);
    lamp.oil = 20;
    teleport(miner(), live.map, 14, 1);
    game.step(2);
    expect(lamp.oil).toBeCloseTo(20 + 48 - 0.03, 1); // 40 percent of 120 seconds
    expect(live.map.kindAt(14, 1)).toBe(K.FLOOR);
    expect(events.count("oilPicked")).toBe(1);
  });

  test("the oil can brings a dry lamp back before the shift ends", () => {
    loadMine();
    const lamp = lampOf(0);
    lamp.oil = 0.5;
    game.step(60);
    expect(lamp.out).toBe(true);
    teleport(miner(), live.map, 14, 1);
    game.step(5);
    expect(lamp.out).toBe(false);
    game.step(200);
    expect(run.inShift).toBe(true);
  });
});

describe("the lift and the moles", () => {
  freshRunBeforeEach();
  test("stepping on the exit lift ends the shift, banks the ore, and shows the results", () => {
    loadMine();
    run.ore.copper = 3;
    run.ore.silver = 1;
    teleport(miner(), live.map, 19, 1);
    game.step(3);
    expect(players.get(0).state).toBe("lift");
    expect(events.count("liftReached")).toBe(1);
    expect(run.inShift).toBe(false);
    expect(run.lastShift.outcome).toBe("lift");
    expect(run.lastShift.value).toBe(6);
    expect(run.cash).toBe(6);
    const start = scene.current;
    game.step(60);
    expect(scene.current).toBe(start); // the delay is still running
    game.step(60);
    expect(scene.current).toBe("scenes/results.scene.json");
  });

  test("with two miners the shift waits until both are on the lift", () => {
    players.clear();
    players.add({ device: { kind: "keys", scheme: "wasd" } });
    players.add({ device: { kind: "keys", scheme: "arrows" } });
    loadMine();
    expect(game.world.findByTag("miner").length).toBe(2);
    teleport(miner(0), live.map, 19, 1);
    game.step(3);
    expect(run.inShift).toBe(true);
    teleport(miner(1), live.map, 20, 1);
    game.step(1);
    teleport(miner(1), live.map, 19, 1);
    game.step(3);
    expect(run.inShift).toBe(false);
  });

  test("a trapped mole is rescued when a miner comes close, once", () => {
    loadMine();
    const log = [];
    events.on("moleRescued", (e) => log.push(e));
    teleport(miner(), live.map, 10, 3);
    game.step(10);
    expect(run.molesRescued).toBe(0);
    teleport(miner(), live.map, 17, 3);
    game.step(10);
    expect(run.molesRescued).toBe(1);
    expect(log.length).toBe(1);
    expect(log[0].rescued).toBe(1);
    game.step(10);
    expect(run.molesRescued).toBe(1);
    teleport(miner(), live.map, 19, 1);
    game.step(3);
    expect(run.lastShift.molesRescued).toBe(1);
    expect(run.lastShift.molesTotal).toBe(1);
  });
});
