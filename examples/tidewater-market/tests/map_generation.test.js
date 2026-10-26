// Map generation: one seed gives the same map and the same hash everywhere (no Math.random, no clock), different seeds give
// different maps, and every seed has a playable mix of terrain.
import { test, expect } from "factoria:test";
import { fa } from "factoria";
import { getData } from "../scripts/game/data.js";
import { generateMap, hashTerrain, mapToText } from "../scripts/game/mapgen.js";
import { createGame } from "../scripts/game/state.js";

const data = getData();
const gen = (seed) => generateMap(seed, data.map, data.terrainIds);

test("the same seed gives the same map, the hash is fixed", () => {
  const a = gen(20261026);
  const b = gen(20261026);
  expect(mapToText(a, data.terrain)).toBe(mapToText(b, data.terrain));
  // Pinned values: if the generator or data/map.json changes on purpose, update them here (and say so in the commit).
  expect(hashTerrain(a)).toBe("64622f7f");
  expect(hashTerrain(gen(7))).toBe("1664d8bc");
  expect(hashTerrain(gen(1))).toBe("0c8c4e03");
});

test("the hash of a map and of a whole game state follows the seed", () => {
  const one = createGame({ seed: 5 });
  const two = createGame({ seed: 5 });
  const other = createGame({ seed: 6 });
  expect(one.map.hash()).toBe(two.map.hash());
  expect(one.hash()).toBe(two.hash());
  expect(one.map.hash()).not.toBe(other.map.hash());
  expect(one.map.width).toBe(data.map.size[0]);
  expect(one.map.height).toBe(data.map.size[1]);
});

test("a seed without an explicit one uses data/map.json defaultSeed", () => {
  const game = createGame();
  expect(game.map.seed).toBe(data.map.defaultSeed);
  expect(game.map.hash()).toBe(hashTerrain(gen(data.map.defaultSeed)));
});

test("every seed has water, land, forest and rock in sensible shares", () => {
  const n = data.map.size[0] * data.map.size[1];
  for (let seed = 1; seed <= 24; seed++) {
    const map = gen(seed);
    const count = {};
    for (const t of map.terrain) count[data.terrainIds[t]] = (count[data.terrainIds[t]] || 0) + 1;
    const share = (id) => (count[id] || 0) / n;
    const where = `seed ${seed}: ${JSON.stringify(count)}`;
    expect(share("water") >= 0.15 && share("water") <= 0.55).toBeTruthy(where);
    expect(share("grass") + share("sand") >= 0.2).toBeTruthy(where);
    expect(share("forest") >= 0.05).toBeTruthy(where);
    expect(share("rock") >= 0.02).toBeTruthy(where);
  }
});

test("the middle of every map is buildable land to start on", () => {
  for (let seed = 1; seed <= 24; seed++) {
    const game = createGame({ seed });
    const cx = Math.floor(game.map.width / 2);
    const cy = Math.floor(game.map.height / 2);
    for (let r = cy - 2; r <= cy + 2; r++) for (let c = cx - 2; c <= cx + 2; c++) expect(game.map.terrainAt(c, r)).toBe("grass");
  }
});

test("the test map is the hand-made rows, with the border as water", () => {
  const game = createGame({ testMap: true });
  expect(game.map.width).toBe(12);
  expect(game.map.height).toBe(10);
  expect(game.map.terrainAt(0, 0)).toBe("water");
  expect(game.map.terrainAt(4, 4)).toBe("grass");
  expect(game.map.terrainAt(9, 4)).toBe("rock");
  expect(game.map.terrainAt(8, 1)).toBe("forest");
  expect(game.map.terrainAt(1, 1)).toBe("sand");
  expect(game.map.terrainAt(99, 99)).toBeNull();
});

test("project.map_preview answers with the same hash as the generator", () => {
  const out = fa.call("project.map_preview", { seed: 20261026 });
  expect(out.hash).toBe(hashTerrain(gen(20261026)));
  expect(out.size).toEqual(data.map.size);
});
