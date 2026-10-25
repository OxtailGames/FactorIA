// The bot (tests/helpers/bot.js) plays whole floors through the keys and sticks, using the game's own pathfinding: one floor of
// every stratum, the Mole King's included, alone and with four players, from fixed seeds. A floor that is cleared proves that
// the generator's mines can be finished, that the hazards and enemies can be got past, and that the input paths of every
// device kind work together.
import { test, describe, expect, game } from "factoria:test";
import { cleanBeforeEach, addPlayers, playGenerated, record, enemyList } from "./helpers/world.js";
import { botsForAll, playFloor } from "./helpers/bot.js";
import { live } from "../scripts/game/mine_map.js";
import { run } from "../scripts/game/run_state.js";
import * as players from "../scripts/game/players.js";

/** [stratum, floor, seed] of the floors the bot must clear. */
const FLOORS = [
  [0, 1, 1234],
  [1, 1, 1234],
  [2, 1, 1234],
  [2, 3, 1234],
];
/** The longest a floor may take (frames at 60 per second: 150 s of game time). */
const CAP = 9000;

function clear(stratum, floor, seed, nPlayers) {
  playGenerated(stratum, floor, seed, nPlayers);
  const log = record("playerDown", "bossStarted", "bossDefeated", "oreStolen", "thiefEscaped", "enemyDefeated");
  const result = playFloor(botsForAll(), { frames: CAP });
  return { result, log, names: log.map((l) => l.name) };
}

describe("the bot alone", () => {
  cleanBeforeEach();
  for (const [stratum, floor, seed] of FLOORS) {
    test(`clears stratum ${stratum} floor ${floor} (seed ${seed}) and rides the lift up`, () => {
      const { result, names } = clear(stratum, floor, seed, 1);
      expect(result.outcome).toBe("lift");
      expect(result.frames).toBeLessThan(CAP);
      expect(run.lastShift.outcome).toBe("lift");
      expect(run.lastShift.stratum).toBe(stratum);
      if (floor === 3 && stratum === 2) {
        expect(names).toContain("bossStarted");
        expect(names).toContain("bossDefeated");
        expect(run.exitLocked).toBe(false);
        expect(enemyList("king").length).toBe(0);
      }
    });
  }

  test("it plays the same floor the same way twice (nothing in the run depends on the clock)", () => {
    const a = clear(1, 1, 1234, 1);
    const b = clear(1, 1, 1234, 1);
    expect(b.result).toEqual(a.result);
    expect(b.names).toEqual(a.names);
  });

  test("other seeds and floors also finish", () => {
    for (const [s, f, seed] of [[0, 2, 7], [1, 3, 42], [2, 2, 5], [0, 3, 99]]) {
      const { result } = clear(s, f, seed, 1);
      expect(result.outcome).toBe("lift");
    }
  });
});

describe("the bot with four players", () => {
  cleanBeforeEach();
  for (const [stratum, floor, seed] of FLOORS) {
    test(`four miners (any keys, arrows, pad 0, pad 1) clear stratum ${stratum} floor ${floor}`, () => {
      const { result, names } = clear(stratum, floor, seed, 4);
      expect(players.count()).toBe(4);
      expect(result.outcome).toBe("lift");
      expect(run.lastShift.outcome).toBe("lift");
      if (floor === 3 && stratum === 2) expect(names).toContain("bossDefeated");
    });
  }

  test("every one of the four devices moved its miner (the registry's own keys and pads all work)", () => {
    addPlayers(4);
    playGenerated(0, 1, 1234, 4);
    const start = game.world.findByTag("miner").map((e) => ({ x: e.position.x, y: e.position.y }));
    playFloor(botsForAll(), { frames: 240 });
    const now = game.world.findByTag("miner");
    now.forEach((e, i) => {
      const d = Math.hypot(e.position.x - start[i].x, e.position.y - start[i].y);
      expect(d).toBeGreaterThan(8);
    });
    expect(live.map).not.toBe(null);
  });
});
