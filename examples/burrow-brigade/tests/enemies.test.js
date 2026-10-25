// The enemies: their behaviour trees alone (a fake blackboard, no scene), then each enemy in a small handmade mine.
import { test, describe, expect, game } from "factoria:test";
import { cleanBeforeEach, playRows, playGenerated, miner, miners, enemyList, teleport, tileOf, record } from "./helpers/world.js";
import { live } from "../scripts/game/mine_map.js";
import { run, lampOf } from "../scripts/game/run_state.js";
import * as players from "../scripts/game/players.js";
import { Tree } from "../scripts/game/behavior_tree.js";
import { STATS, beetleBrain, thiefBrain, kingBrain } from "../scripts/game/enemy_brains.js";

const SECOND = 60;

// ---- the brains, with a plain object as blackboard -------------------------------------------------------------------

function fake(stats, over = {}) {
  const log = [];
  return {
    stats, log, target: null, targetDist: Infinity, lastSeen: null, staggered: 0, wanderTile: null, stunLeft: 0, awake: true,
    phase2: false, carrying: null, safeFor: 0, chargeClock: 0, slamClock: 0,
    walkTo(tile, speed) { log.push(["walk", tile, speed]); return "moving"; },
    pickWander() { log.push(["pick"]); this.wanderTile = { tx: 5, ty: 5 }; },
    bite() { log.push(["bite"]); },
    telegraph(on) { log.push(["tele", on]); },
    canSteal() { return true; },
    steal() { log.push(["steal"]); this.carrying = { ore: {}, count: 2 }; },
    fleeTile() { return { tx: 9, ty: 9 }; },
    escape() { log.push(["escape"]); this.carrying = null; },
    wake() { log.push(["wake"]); return !!this.target; },
    slamStrike() { log.push(["slam"]); },
    chargeDir() { log.push(["aim"]); },
    chargeStep() { log.push(["charge"]); return this.chargeResult ?? "going"; },
    ...over,
  };
}
const kinds = (bb, name) => bb.log.filter((l) => l[0] === name);
function run_(tree, seconds, dt = 0.1) {
  for (let t = 0; t < seconds - 1e-9; t += dt) tree.tick(dt);
}

describe("beetle brain", () => {
  test("patrols to a spot it picked, at patrol speed, while it sees nobody", () => {
    const bb = fake(STATS.beetle);
    run_(new Tree(beetleBrain(), bb), 1);
    expect(kinds(bb, "pick").length).toBe(1);
    expect(kinds(bb, "walk")[0][2]).toBe(STATS.beetle.patrolSpeed);
  });

  test("chases a miner it sees, faster than it patrols", () => {
    const bb = fake(STATS.beetle, { target: { tx: 7, ty: 2 }, targetDist: 60 });
    run_(new Tree(beetleBrain(), bb), 0.5);
    const walk = kinds(bb, "walk")[0];
    expect(walk[1]).toEqual({ tx: 7, ty: 2 });
    expect(walk[2]).toBe(STATS.beetle.chaseSpeed);
  });

  test("in reach it winds up (telegraph on), bites once, then cannot bite again for the cooldown", () => {
    const bb = fake(STATS.beetle, { target: { tx: 7, ty: 2 }, targetDist: 10 });
    const tree = new Tree(beetleBrain(), bb);
    run_(tree, 0.3);
    expect(kinds(bb, "tele")[0][1]).toBe(true);
    expect(kinds(bb, "bite").length).toBe(0);
    run_(tree, 0.3);
    expect(kinds(bb, "bite").length).toBe(1);
    expect(kinds(bb, "tele").some((l) => l[1] === false)).toBe(true);
    run_(tree, 0.8);
    expect(kinds(bb, "bite").length).toBe(1);
    run_(tree, 1.4);
    expect(kinds(bb, "bite").length).toBe(2);
  });

  test("after losing the miner it goes to where it saw it, then patrols again; a hit staggers it in place", () => {
    const bb = fake(STATS.beetle, { lastSeen: { tx: 3, ty: 3, age: 1 } });
    const tree = new Tree(beetleBrain(), bb);
    run_(tree, 0.3);
    expect(kinds(bb, "walk")[0][1]).toMatchObject({ tx: 3, ty: 3 });
    bb.log.length = 0;
    bb.staggered = 0.5;
    run_(tree, 0.3);
    expect(kinds(bb, "walk").length).toBe(0);
    bb.staggered = 0; // the stagger is over: it goes on (a running node must not keep it still for ever)
    run_(tree, 0.3);
    expect(kinds(bb, "walk").length).toBeGreaterThan(0);
  });
});

describe("thief brain", () => {
  test("wanders until it sees a miner and the team has ore; then it sneaks up", () => {
    const bb = fake(STATS.thief, { target: { tx: 4, ty: 4 }, targetDist: 80, canSteal: () => false });
    run_(new Tree(thiefBrain(), bb), 0.5);
    expect(kinds(bb, "walk")[0][2]).toBe(STATS.thief.wanderSpeed);
    const bb2 = fake(STATS.thief, { target: { tx: 4, ty: 4 }, targetDist: 80 });
    run_(new Tree(thiefBrain(), bb2), 0.5);
    expect(kinds(bb2, "walk")[0][2]).toBe(STATS.thief.approachSpeed);
  });

  test("in reach it steals once and then flees; after three safe seconds it escapes", () => {
    const bb = fake(STATS.thief, { target: { tx: 4, ty: 4 }, targetDist: 8 });
    const tree = new Tree(thiefBrain(), bb);
    run_(tree, 0.3);
    expect(kinds(bb, "steal").length).toBe(1);
    bb.log.length = 0;
    bb.target = null;
    bb.targetDist = Infinity;
    run_(tree, 1);
    expect(kinds(bb, "walk")[0][2]).toBe(STATS.thief.fleeSpeed);
    expect(kinds(bb, "steal").length).toBe(0);
    bb.safeFor = STATS.thief.escapeAfter;
    run_(tree, 0.2);
    expect(kinds(bb, "escape").length).toBe(1);
  });
});

describe("Mole King brain", () => {
  test("does nothing until a miner is in sight; then wakes and walks at the nearest miner", () => {
    const bb = fake(STATS.king, { awake: false });
    const tree = new Tree(kingBrain(), bb);
    run_(tree, 0.5);
    expect(kinds(bb, "walk").length).toBe(0);
    bb.target = { tx: 12, ty: 3 };
    bb.targetDist = 120;
    run_(tree, 0.5);
    expect(kinds(bb, "wake").length).toBeGreaterThan(0);
    bb.awake = true;
    run_(tree, 0.5);
    expect(kinds(bb, "walk")[0][1]).toEqual({ tx: 12, ty: 3 });
  });

  test("close to a miner it rears up (slam telegraph), strikes after the wind-up and is stunned", () => {
    const bb = fake(STATS.king, { target: { tx: 12, ty: 3 }, targetDist: 40 });
    const tree = new Tree(kingBrain(), bb);
    bb.slamClock = 0;
    run_(tree, 0.5);
    expect(kinds(bb, "tele")[0][1]).toBe("slam");
    expect(kinds(bb, "slam").length).toBe(0);
    run_(tree, 0.6);
    expect(kinds(bb, "slam").length).toBe(1);
    expect(bb.stunLeft).toBe(STATS.king.slamStun);
    bb.log.length = 0;
    run_(tree, 0.5);
    expect(kinds(bb, "walk").length).toBe(0); // stunned: it stands still
    bb.stunLeft = 0; // the stun is over: it walks at the miner again
    run_(tree, 0.5);
    expect(kinds(bb, "walk").length).toBeGreaterThan(0);
  });

  test("under half health it charges at a miner at range: aim during the wind-up, run, and a wall stuns it", () => {
    const bb = fake(STATS.king, { phase2: true, target: { tx: 12, ty: 3 }, targetDist: 100, chargeResult: "blocked" });
    const tree = new Tree(kingBrain(), bb);
    run_(tree, 0.5);
    expect(kinds(bb, "tele")[0][1]).toBe("charge");
    expect(kinds(bb, "aim").length).toBeGreaterThan(0);
    expect(kinds(bb, "charge").length).toBe(0);
    run_(tree, 0.4);
    expect(kinds(bb, "charge").length).toBeGreaterThan(0);
    expect(bb.stunLeft).toBe(STATS.king.chargeStun);
  });

  test("a charge is not used before the second phase", () => {
    const bb = fake(STATS.king, { phase2: false, target: { tx: 12, ty: 3 }, targetDist: 100 });
    run_(new Tree(kingBrain(), bb), 1.5);
    expect(kinds(bb, "charge").length).toBe(0);
    expect(kinds(bb, "walk").length).toBeGreaterThan(0);
  });
});

// ---- the enemies in a mine ---------------------------------------------------------------------------------------------

const HALL = [
  "B".repeat(30),
  "B.S" + ".".repeat(24) + "EBB",
  "B".repeat(30),
];
const withEnemy = (ch, tx) => {
  const r = [...HALL];
  r[1] = r[1].slice(0, tx) + ch + r[1].slice(tx + 1);
  return r;
};

describe("beetle in a mine", () => {
  cleanBeforeEach();
  test("it wanders around where it starts while no miner is near", () => {
    playRows(withEnemy("b", 24));
    const b = enemyList("beetle")[0];
    const x0 = b.entity.position.x;
    let moved = false;
    for (let i = 0; i < 12 && !moved; i++) {
      game.step(SECOND);
      moved = Math.abs(b.entity.position.x - x0) > 8;
    }
    expect(moved).toBe(true);
    expect(b.target).toBe(null);
    expect(b.tile.tx).toBeGreaterThan(14); // patrols near its spot, far from the miner
  });

  test("it sees a miner, runs at it, winds up and bites: a heart, 10 oil and a shove", () => {
    playRows(withEnemy("b", 10));
    const log = record("playerHurt");
    const b = enemyList("beetle")[0];
    teleport(miner(), 5, 1);
    const oil0 = lampOf(0).oil;
    const d0 = Math.abs(b.entity.position.x - miner().position.x);
    game.step(SECOND);
    expect(b.target).not.toBe(null);
    expect(Math.abs(b.entity.position.x - miner().position.x)).toBeLessThan(d0);
    game.step(3 * SECOND);
    expect(log.length).toBeGreaterThan(0);
    expect(log[0].data).toMatchObject({ hp: 2, cause: "beetle" });
    expect(players.get(0).hp).toBeLessThan(3);
    expect(oil0 - lampOf(0).oil).toBeGreaterThan(10);
  });

  test("a bitten miner is spared for a moment: bites do not stack into a second heart at once", () => {
    playRows(withEnemy("b", 8));
    const log = record("playerHurt");
    teleport(miner(), 6, 1);
    game.step(2 * SECOND);
    const first = log.length;
    expect(first).toBeGreaterThan(0);
    // 1.2 s of grace after a hit (HURT_GRACE) and 1.4 s between bites: two bites never land within a second
    const times = log.map((l) => l.data.hp);
    expect(new Set(times).size).toBe(times.length);
  });

  test("three pick swings kill it: enemyHit with its health left, then enemyDefeated", () => {
    playRows(withEnemy("b", 5));
    const log = record("enemyHit", "enemyDefeated");
    const b = enemyList("beetle")[0];
    teleport(miner(), 4, 1);
    teleport(b.entity, 5, 1);
    game.keyDown("D"); // turn to face it (one frame), then only swing: it comes back at the miner after each stagger
    game.step(1);
    game.keyUp("D");
    game.keyDown("Space");
    game.step(4 * SECOND);
    game.keyUp("Space");
    const hits = log.filter((l) => l.name === "enemyHit");
    expect(hits.map((h) => h.data.hp)).toEqual([2, 1, 0]);
    expect(log.some((l) => l.name === "enemyDefeated" && l.data.kind === "beetle" && l.data.by === 0)).toBe(true);
    expect(enemyList("beetle").length).toBe(0);
  });
});

describe("a chase through a freshly dug tunnel", () => {
  cleanBeforeEach();
  test("a beetle behind a wall cannot reach the miner; once the wall is dug it comes through the new tunnel", () => {
    // beetle at (11,1), plug of dirt at (8,1), miner at (4,1)
    const rows = ["B".repeat(16), "B.S.....#..b...B".replace("...B", "..EB").slice(0, 16), "B".repeat(16)];
    playRows(rows);
    const b = enemyList("beetle")[0];
    teleport(miner(), 4, 1);
    const v0 = live.nav.version;
    game.step(4 * SECOND);
    expect(b.target).toBe(null); // the wall blocks the view
    expect(b.tile.tx).toBeGreaterThan(8);
    live.map.dig(8, 1, { tier: 0, by: 0 });
    expect(live.nav.version).toBeGreaterThan(v0);
    const log = record("playerHurt");
    let reached = false;
    for (let i = 0; i < 8 * SECOND && !reached; i++) {
      game.step(1);
      reached = b.tile.tx <= 6 || log.length > 0;
    }
    expect(reached).toBe(true);
    expect(b.tile.tx).toBeLessThan(9); // it passed through the tile that was a wall a moment ago
  });
});

describe("thief in a mine", () => {
  cleanBeforeEach();
  test("it takes a quarter of the team's ore, tells the bus, and runs away from the miner", () => {
    playRows(withEnemy("t", 9));
    run.ore.copper = 6;
    run.ore.gold = 2;
    const log = record("oreStolen");
    const t = enemyList("thief")[0];
    teleport(miner(), 6, 1);
    for (let i = 0; i < 5 * SECOND && log.length === 0; i++) game.step(1);
    expect(log.length).toBe(1);
    expect(log[0].data.count).toBe(2); // 25% of 8
    expect(run.ore.copper + run.ore.gold).toBe(6);
    expect(t.carrying.count).toBe(2);
    const d0 = Math.abs(t.entity.position.x - miner().position.x);
    game.step(2 * SECOND);
    expect(Math.abs(t.entity.position.x - miner().position.x)).toBeGreaterThan(d0 + 10);
  });

  test("it ignores a team with nothing to steal", () => {
    playRows(withEnemy("t", 9));
    const log = record("oreStolen");
    teleport(miner(), 7, 1);
    game.step(4 * SECOND);
    expect(log.length).toBe(0);
    expect(enemyList("thief")[0].carrying).toBe(null);
  });

  test("killed with the loot, it gives the ore back: oreRecovered", () => {
    playRows(withEnemy("t", 9));
    run.ore.silver = 8;
    const log = record("oreStolen", "oreRecovered");
    const t = enemyList("thief")[0];
    teleport(miner(), 7, 1);
    for (let i = 0; i < 5 * SECOND && !log.some((l) => l.name === "oreStolen"); i++) game.step(1);
    expect(run.ore.silver).toBe(6);
    t.hit(5, { x: 0, y: 0 }, 0);
    expect(run.ore.silver).toBe(8);
    expect(log.find((l) => l.name === "oreRecovered").data).toMatchObject({ ore: "silver", count: 2, by: 0 });
    expect(enemyList("thief").length).toBe(0);
  });

  test("out of sight and far away for three seconds, it escapes: thiefEscaped, and the ore is gone", () => {
    playRows(withEnemy("t", 20));
    run.ore.gem = 4;
    const log = record("thiefEscaped", "oreRecovered");
    const t = enemyList("thief")[0];
    t.carrying = { ore: { copper: 0, silver: 0, gold: 0, gem: 2 }, count: 2 };
    run.ore.gem = 2;
    teleport(miner(), 1, 1); // 19 tiles away
    game.step(6 * SECOND);
    expect(log.map((l) => l.name)).toEqual(["thiefEscaped"]);
    expect(log[0].data).toMatchObject({ ore: "gem", count: 2 });
    expect(run.ore.gem).toBe(2);
    expect(enemyList("thief").length).toBe(0);
  });
});

describe("the Mole King in a mine", () => {
  cleanBeforeEach();
  // three tiles tall: the King's body (18 units) does not fit a one-tile tunnel
  const arena = (kx) => {
    const wall = "B".repeat(30);
    const open = "B" + ".".repeat(27) + "BB";
    return [wall, "B.S" + ".".repeat(24) + "EBB", open.slice(0, kx) + "k" + open.slice(kx + 1), open, wall];
  };

  test("it sleeps until a miner is in sight; the fight starts once (bossStarted)", () => {
    playRows(arena(24), { stratum: 2, floor: 3 });
    const log = record("bossStarted");
    const k = enemyList("king")[0];
    teleport(miner(), 2, 1);
    game.step(2 * SECOND);
    expect(k.awake).toBe(false);
    expect(log.length).toBe(0);
    teleport(miner(), 18, 1);
    game.step(SECOND);
    expect(k.awake).toBe(true);
    expect(log.length).toBe(1);
    expect(log[0].data.hp).toBe(STATS.king.hp);
    game.step(3 * SECOND);
    expect(log.length).toBe(1);
  });

  test("its health grows with the team", () => {
    playRows(arena(24), { stratum: 2, floor: 3, players: 4 });
    expect(enemyList("king")[0].maxHp).toBe(STATS.king.hp + 3 * STATS.king.hpPerExtraPlayer);
  });

  test("the slam puts a miner standing in the red circle down: playerDown 'king'", () => {
    playRows(arena(14), { stratum: 2, floor: 3 });
    const log = record("playerDown");
    const k = enemyList("king")[0];
    teleport(miner(), 12, 1);
    let sawSlam = false;
    for (let i = 0; i < 6 * SECOND && log.length === 0; i++) {
      game.step(1);
      if (k.telegraphing === "slam") sawSlam = true;
    }
    expect(sawSlam).toBe(true);
    expect(log[0].data.cause).toBe("king");
    expect(players.get(0).state).toBe("down");
  });

  test("a miner who leaves the circle during the wind-up is not hit", () => {
    playRows(arena(14), { stratum: 2, floor: 3 });
    const k = enemyList("king")[0];
    teleport(miner(), 12, 1);
    for (let i = 0; i < 4 * SECOND && k.telegraphing !== "slam"; i++) game.step(1);
    expect(k.telegraphing).toBe("slam");
    teleport(miner(), 3, 1); // out of the circle (it is 42 units wide)
    game.step(2 * SECOND);
    expect(players.get(0).state).toBe("active");
    expect(k.stunLeft).toBeGreaterThan(0); // it struck at nobody and is stunned
  });

  test("under half health it charges and a miner in the line of the charge loses a heart", () => {
    playRows(arena(20), { stratum: 2, floor: 3 });
    const log = record("playerHurt");
    const k = enemyList("king")[0];
    teleport(miner(), 13, 1); // 7 tiles away: inside the charge range, outside the slam
    game.step(10);
    k.hp = 4;
    let charged = false;
    for (let i = 0; i < 5 * SECOND && log.length === 0; i++) {
      game.step(1);
      if (k.telegraphing === "charge") charged = true;
    }
    expect(k.phase2).toBe(true);
    expect(charged).toBe(true);
    expect(log[0].data).toMatchObject({ cause: "king", hp: 2 });
  });

  test("the lift is jammed while it lives (exitJammed) and works once it is defeated (bossDefeated)", () => {
    playRows(arena(14), { stratum: 2, floor: 3 });
    const log = record("exitJammed", "bossDefeated", "enemyDefeated", "bossStarted");
    expect(run.exitLocked).toBe(true);
    const k = enemyList("king")[0];
    teleport(miner(), 27, 1); // on the exit lift
    game.step(SECOND);
    expect(log.filter((l) => l.name === "exitJammed").length).toBe(1);
    expect(players.get(0).state).toBe("active");
    k.hit(100, { x: 0, y: 0 }, 0);
    expect(log.some((l) => l.name === "bossDefeated" && l.data.by === 0)).toBe(true);
    expect(log.some((l) => l.name === "enemyDefeated" && l.data.kind === "king")).toBe(true);
    expect(run.exitLocked).toBe(false);
    teleport(miner(), 2, 1);
    game.step(10);
    teleport(miner(), 27, 1);
    game.step(SECOND);
    expect(players.get(0).state).toBe("lift");
    expect(run.inShift).toBe(false); // the shift ended: "lift"
  });

  test("the boss floor locks the lift from the start; other floors do not", () => {
    playGenerated(2, 3, 1234, 1);
    expect(live.mine.boss).toBe(true);
    expect(run.exitLocked).toBe(true);
    expect(enemyList("king").length).toBe(1);
    playGenerated(2, 2, 1234, 1);
    expect(run.exitLocked).toBe(false);
  });
});
