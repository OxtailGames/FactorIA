// The mine generator: the same seed gives the same mine (a fixed hash pins it in each stratum and on the boss floor), another
// seed another mine, every mine can be finished with the starting pick, and each stratum puts in its own hazards and enemies.
import { test, describe, expect } from "factoria:test";
import { generate, mineHash, exitReachable, isBossFloor, stratumInfo, STRATA, TOTAL_FLOORS, MINE_FORMAT } from "../scripts/game/generator.js";
import { fromRows, toRows } from "../scripts/game/mine_ascii.js";
import { K } from "../scripts/game/tiles.js";

describe("generate(seed, stratum, floor)", () => {
  test("the same seed gives the same mine, and the hash is pinned", () => {
    const a = generate(1234, 0, 1);
    const b = generate(1234, 0, 1);
    expect(a.hash).toBe(b.hash);
    expect(toRows(a)).toEqual(toRows(b));
    // If this fails after a generator change, the mines of every saved run changed: raise MINE_FORMAT and update the hash on purpose.
    expect(a.hash).toBe("2226b82f");
    expect(mineHash(a)).toBe(a.hash);
  });

  test("the hash of a fixed seed is pinned in every stratum, the boss floor included", () => {
    expect(generate(1234, 0, 1).hash).toBe("2226b82f"); // Topsoil
    expect(generate(1234, 1, 1).hash).toBe("e4c8bb00"); // Crystal Caves
    expect(generate(1234, 2, 1).hash).toBe("1191412d"); // Magma Deep
    expect(generate(1234, 2, 3).hash).toBe("c9c03ec9"); // Magma Deep, floor 3: the Mole King
  });

  test("seed, stratum and floor each change the mine", () => {
    const base = generate(1234, 0, 1).hash;
    expect(generate(1235, 0, 1).hash).not.toBe(base);
    expect(generate(1234, 1, 1).hash).not.toBe(base);
    expect(generate(1234, 0, 2).hash).not.toBe(base);
  });

  test("the mine has a start lift, an exit lift, spawn tiles, oil and trapped moles", () => {
    const m = generate(99, 0, 1);
    expect(m.kinds[m.start.ty * m.width + m.start.tx]).toBe(K.LIFT_START);
    expect(m.kinds[m.exit.ty * m.width + m.exit.tx]).toBe(K.LIFT_EXIT);
    expect(m.spawns.length).toBeGreaterThan(3); // room for four miners
    expect(m.oilCount).toBeGreaterThan(1);
    expect(m.moles.length).toBeGreaterThan(1);
    expect(m.width * m.height).toBe(m.kinds.length);
    expect(m.format).toBe(MINE_FORMAT);
    expect(m.format).toBe(2);
  });

  test("the border is bedrock and every mine can be finished with the starting pick", () => {
    for (let seed = 1; seed <= 24; seed++) {
      for (const stratum of [0, 1, 2]) {
        const m = generate(seed, stratum, 1 + (seed % 3));
        for (let x = 0; x < m.width; x++) {
          expect(m.kinds[x]).toBe(K.BEDROCK);
          expect(m.kinds[(m.height - 1) * m.width + x]).toBe(K.BEDROCK);
        }
        for (let y = 0; y < m.height; y++) {
          expect(m.kinds[y * m.width]).toBe(K.BEDROCK);
          expect(m.kinds[y * m.width + m.width - 1]).toBe(K.BEDROCK);
        }
        expect(exitReachable(m, 0)).toBe(true);
        expect(m.solvable).toBe(true);
      }
    }
  });

  test("deeper strata hold the richer ore", () => {
    const rich = (stratum) => {
      let n = 0;
      for (let seed = 1; seed <= 6; seed++) {
        const c = generate(seed, stratum, 1).oreCounts;
        n += c.gold + c.gem;
      }
      return n;
    };
    expect(rich(2)).toBeGreaterThan(rich(0));
    expect(STRATA.length).toBe(3);
  });

  test("each stratum puts in its own hazards and enemies", () => {
    const count = (m, kind) => m.hazards.filter((h) => h.kind === kind).length;
    const enemies = (m, kind) => m.enemies.filter((e) => e.kind === kind).length;
    const total = { flood: 0, caveIn: 0, magma: 0, beetle: 0, thief: 0 };
    for (let seed = 1; seed <= 8; seed++) {
      const top = generate(seed, 0, 1);
      total.flood += count(top, "flood"); // a pocket needs room, so a single seed may have none
      total.beetle += enemies(top, "beetle");
      expect(count(top, "magma")).toBe(0);
      expect(count(top, "caveIn")).toBe(0);
      expect(top.kinds.includes(K.CRYSTAL)).toBe(false);
      const crystal = generate(seed, 1, 1);
      total.caveIn += count(crystal, "caveIn");
      total.thief += enemies(crystal, "thief");
      expect(crystal.kinds.includes(K.CRYSTAL)).toBe(true);
      expect(count(crystal, "magma")).toBe(0);
      const magma = generate(seed, 2, 1);
      total.magma += count(magma, "magma");
      expect(magma.kinds.includes(K.MAGMA)).toBe(true);
      expect(magma.boss).toBe(false);
      expect(enemies(magma, "king")).toBe(0);
    }
    for (const k of Object.keys(total)) expect(total[k]).toBeGreaterThan(0);
  });

  test("only floor 3 of the Magma Deep is the boss floor, and it holds one Mole King", () => {
    expect(TOTAL_FLOORS).toBe(9);
    let bosses = 0;
    for (let stratum = 0; stratum < STRATA.length; stratum++) {
      for (let floor = 1; floor <= stratumInfo(stratum).floors; floor++) {
        const m = generate(77, stratum, floor);
        expect(m.boss).toBe(isBossFloor(stratum, floor));
        expect(m.enemies.filter((e) => e.kind === "king").length).toBe(m.boss ? 1 : 0);
        if (m.boss) bosses++;
      }
    }
    expect(bosses).toBe(1);
  });

  test("every enemy starts on a floor tile away from the start lift", () => {
    for (let seed = 1; seed <= 12; seed++) {
      for (const stratum of [0, 1, 2]) {
        const m = generate(seed, stratum, 1 + (seed % 3));
        for (const e of m.enemies) {
          expect(m.kinds[e.ty * m.width + e.tx]).toBe(K.FLOOR);
          expect(Math.hypot(e.tx - m.start.tx, e.ty - m.start.ty)).toBeGreaterThan(8);
        }
      }
    }
  });

  test("mineHash follows what is on the map", () => {
    const m = generate(5, 0, 1);
    const before = mineHash(m);
    const i = m.kinds.findIndex((k) => k === K.DIRT);
    m.kinds[i] = K.FLOOR;
    expect(mineHash(m)).not.toBe(before);
  });
});

describe("fromRows and toRows", () => {
  test("round trip", () => {
    const rows = ["BBBBB", "BS.EB", "BBBBB"];
    const m = fromRows(rows);
    expect(toRows(m)).toEqual(rows);
    expect(m.solvable).toBe(true);
    expect(m.hash).toBe(mineHash(m));
  });

  test("a bad character or a missing exit lift is an error that says where and how to fix it", () => {
    expect(() => fromRows(["BBBBB", "BS?EB", "BBBBB"])).toThrow("row 1, column 2");
    expect(() => fromRows(["BBBBB", "BS.ZB", "BBBBB"])).toThrow("unknown character");
    expect(() => fromRows(["BBBBB", "BS..B", "BBBBB"])).toThrow("exactly one S");
    expect(() => fromRows(["BBBBB", "BS.E", "BBBBB"])).toThrow("same width");
  });
});
