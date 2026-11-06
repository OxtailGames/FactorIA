import { test, expect } from "factoria:test";
import { planFloor, solidGlyphs } from "../scripts/floor_plan.js";

const MARKERS = { coin: "o", trap: "x" };
const WALLS = new Set(["#"]);

test("solidGlyphs reads the legend: numbers and objects with a tile", () => {
  const legend = { "#": 0, ".": 1, o: { tile: 1, prefab: "prefabs/coin.prefab.json" }, w: { tile: 0, prefab: "p.json" }, m: { prefab: "p.json" } };
  expect([...solidGlyphs(legend, [0])].sort()).toEqual(["#", "w"]);
  expect([...solidGlyphs(legend, [])]).toEqual([]);
});

test("the start is the first free cell and the stairs the farthest one by steps", () => {
  const plan = planFloor(["#####", "#...#", "#.#.#", "#...#", "#####"], WALLS, MARKERS);
  expect(plan.start).toEqual([1, 1]);
  expect(plan.stairs).toEqual([3, 3]); // (1,3) and (3,3) are both 4 steps away: the later one in reading order wins
  expect(plan.steps).toBe(4);
});

test("a trap is never on the route: the stairs are reached by walking around it", () => {
  const rows = ["#########", "#..x....#", "#.#####.#", "#.......#", "#########"];
  const plan = planFloor(rows, WALLS, MARKERS);
  expect(plan.traps).toEqual([[3, 1]]);
  expect(plan.start).toEqual([1, 1]);
  expect(plan.steps).toBe(13); // down, along the bottom corridor, up and back left to (4,1): the trap at (3,1) is not crossed
  expect(plan.stairs).toEqual([4, 1]);
});

test("a trap that seals a room puts the start and the stairs in the bigger region", () => {
  const rows = ["#######", "#.x...#", "#.#####", "#.....#", "#######"];
  const plan = planFloor(rows, WALLS, MARKERS);
  // The left part (1,1), (1,2), (1,3), (2..5,3) is 8 cells; the three cells right of the trap are cut off.
  expect(plan.start).toEqual([1, 1]);
  expect(plan.stairs).toEqual([5, 3]);
  expect(plan.reachableCoins).toBe(0);
});

test("coins and the stairs do not share a cell, and a floor without a free cell has no plan", () => {
  const plan = planFloor(["####", "#oo#", "#o.#", "####"], WALLS, MARKERS);
  expect(plan.start).toEqual([2, 2]);
  expect(plan.coins.length).toBe(3);
  expect(plan.reachableCoins).toBe(3);
  expect(planFloor(["###", "#x#", "###"], WALLS, MARKERS)).toBeNull();
});
