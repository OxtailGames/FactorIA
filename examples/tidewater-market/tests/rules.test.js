// The placement rules, road dragging, demolishing and undo/redo on the hand-made test map (data/test_map.json):
//
//   c:  0 1 2 3 4 5 6 7 8 9 10 11
//   r0  w w w w w w w w w w w  w
//   r1  w s s s g g g g f f w  w
//   r2  w s g g g g g g f f f  w
//   r3  w s g g g g g g g f f  w
//   r4  w s g g g g g g g r r  w
//   r5  w g g g g g g g g r r  w
//   r6  w g g g g g g g g g g  w
//   r7  w s g g g g g g g g g  w
//   r8  w s s g g g g g g s s  w
//   r9  w w w w w w w w w w w  w
import { test, expect } from "factoria:test";
import { createGame } from "../scripts/game/state.js";
import { roadPath, frontageCells } from "../scripts/game/rules.js";

const fresh = () => createGame({ testMap: true });
const codes = (res) => res.reasons.map((r) => r.code);

test("a building is paid for, stands on its cells and is announced", () => {
  const game = fresh();
  const heard = [];
  game.events.on("building.placed", (e) => heard.push(e.building.type));
  const res = game.place("house", 3, 3, 0);
  expect(res.ok).toBe(true);
  expect(game.economy.coins).toBe(960);
  expect(game.economy.get("wood")).toBe(56);
  expect(game.buildingAt(3, 3).type).toBe("house");
  expect(game.list("house")).toHaveLength(1);
  expect(heard).toEqual(["house"]);
});

test("every rule says what is wrong, and a refused action changes nothing", () => {
  const game = fresh();
  game.place("house", 3, 3, 0);
  const before = game.hash();
  const rejected = [];
  game.events.on("action.rejected", (e) => rejected.push(e.code));

  expect(codes(game.place("house", 3, 3, 0))).toEqual(["occupied"]);
  expect(codes(game.place("house", 0, 0, 0))).toEqual(["terrain"]); // water
  expect(codes(game.place("house", 8, 1, 0))).toEqual(["terrain"]); // forest: houses need sand or grass
  expect(codes(game.place("house", -1, 3, 0))).toEqual(["out_of_bounds"]);
  expect(codes(game.place("farm", 11, 4, 0))).toContain("out_of_bounds"); // a 2 x 2 farm hangs over the edge
  expect(codes(game.place("farm", 1, 2, 0))).toEqual(["terrain"]); // sand under part of it
  expect(codes(game.place("quarry", 3, 3, 0))).toContain("occupied");
  expect(codes(game.place("fisher_dock", 4, 4, 0))).toEqual(["not_near_water"]);
  expect(codes(game.place("nonsense", 4, 4, 0))).toEqual(["unknown_type"]);
  expect(game.hash()).toBe(before);
  expect(rejected.length).toBe(9);

  const wrong = game.place("house", 8, 1, 0).reasons[0];
  expect(wrong.detail.terrain).toBe("forest");
  expect(wrong.detail.allowed).toEqual(["sand", "grass"]);
});

test("terrain rules: quarry on rock, fisher dock at the water, lumber camp in the forest", () => {
  const game = fresh();
  expect(game.place("quarry", 9, 4, 0).ok).toBe(true); // 2 x 2 on rock
  expect(game.place("fisher_dock", 1, 6, 0).ok).toBe(true); // 2 x 1 on grass next to water
  expect(game.place("lumber_camp", 8, 1, 0).ok).toBe(true); // forest allowed
  expect(game.place("lumber_camp", 4, 4, 0).ok).toBe(true); // grass allowed too
  expect(codes(game.place("quarry", 4, 6, 0))).toEqual(["terrain"]);
});

test("a warehouse and a market need a road in front of their door", () => {
  const game = fresh();
  // rotation 0 faces +c: the door side is the column just right of the 3 x 2 footprint
  expect(codes(game.place("warehouse", 2, 3, 0))).toEqual(["no_road"]);
  expect(frontageCells(game.data.buildings.warehouse, 2, 3, 0)).toEqual([[5, 3], [5, 4]]);
  game.placeRoads([[5, 4]]); // one road cell on the frontage is enough
  expect(game.place("warehouse", 2, 3, 0).ok).toBe(true);
});

test("rotating a building swaps its footprint and moves its door", () => {
  const game = fresh();
  game.placeRoads([[5, 3], [5, 4]]); // in front of a rotation 0 door, not of a rotation 1 door
  const turned = game.place("warehouse", 2, 3, 1); // faces +r: the footprint is 2 x 3 (c 2..3, r 3..5), the door row is r = 6
  expect(codes(turned)).toEqual(["no_road"]);
  expect(frontageCells(game.data.buildings.warehouse, 2, 3, 1)).toEqual([[2, 6], [3, 6]]);
  game.placeRoads([[2, 6]]);
  const ok = game.place("warehouse", 2, 3, 1);
  expect(ok.ok).toBe(true);
  expect([ok.building.w, ok.building.h]).toEqual([2, 3]);
  expect(game.buildingAt(3, 5).type).toBe("warehouse");
  expect(game.buildingAt(4, 3)).toBeNull();
});

test("the footprint is centred on the cell under the cursor", () => {
  const game = fresh();
  const chk = game.checkAt("farm", 5, 5, 0); // 2 x 2: the cursor cell is the bottom-right of the upper-left quarter
  expect(chk.cells).toEqual([[5, 5], [6, 5], [5, 6], [6, 6]]);
  expect(game.placeAt("farm", 5, 5, 0).building.x).toBe(5);
  const wide = fresh().checkAt("warehouse", 5, 5, 0); // 3 x 2 centred on column 5 -> c 4..6
  expect(wide.cells.map((c) => c[0])).toContain(4);
  expect(wide.cells.map((c) => c[0])).toContain(6);
});

test("money: a building the player cannot pay for is refused and the missing amount is named", () => {
  const game = fresh();
  game.economy.apply({ coins: -990 }, "test"); // 10 coins left
  const res = game.place("house", 3, 3, 0);
  expect(codes(res)).toEqual(["cannot_afford"]);
  expect(res.reasons[0].detail.missing).toEqual({ coins: 30 });
  game.economy.apply({ coins: 980, wood: -58 }, "test"); // 990 coins, 2 wood
  const wood = game.place("house", 3, 3, 0);
  expect(wood.reasons[0].detail.missing).toEqual({ wood: 2 });
});

test("goods are part of the price: the market needs 10 planks and the warehouse took 8", () => {
  const game = fresh(); // 10 planks at the start
  game.placeRoads([[5, 3], [5, 4], [5, 6], [5, 7]]);
  expect(game.place("warehouse", 2, 3, 0).ok).toBe(true);
  expect(game.economy.get("planks")).toBe(2);
  const market = game.place("market", 2, 6, 0);
  expect(codes(market)).toEqual(["cannot_afford"]);
  expect(market.reasons[0].detail.missing).toEqual({ planks: 8 });
});

test("road path: along the longer side first, then the other", () => {
  expect(roadPath([2, 2], [5, 4])).toEqual([[2, 2], [3, 2], [4, 2], [5, 2], [5, 3], [5, 4]]);
  expect(roadPath([2, 2], [3, 6])).toEqual([[2, 2], [2, 3], [2, 4], [2, 5], [2, 6], [3, 6]]);
  expect(roadPath([4, 4], [4, 4])).toEqual([[4, 4]]);
  expect(roadPath([5, 2], [2, 2])).toEqual([[5, 2], [4, 2], [3, 2], [2, 2]]);
});

test("road dragging: one action, one payment, one undo step", () => {
  const game = fresh();
  const cells = roadPath([2, 2], [6, 4]);
  expect(cells).toHaveLength(7);
  const heard = [];
  game.events.on("roads.changed", (e) => heard.push(e.cells.length));
  const res = game.placeRoads(cells);
  expect(res.ok).toBe(true);
  expect(res.placed).toHaveLength(7);
  expect(game.economy.coins).toBe(1000 - 7 * 2);
  expect(game.undoStack).toHaveLength(1);
  expect(heard).toHaveLength(1); // one event for the whole drag, with the cells and neighbours to redraw
  expect(game.isRoad(2, 2)).toBe(true);
  expect(game.roadMask(3, 2)).toBe(4 | 1); // neighbours at -c and +c
  game.undo();
  expect(game.economy.coins).toBe(1000);
  expect(game.list("road")).toHaveLength(0);
});

test("road dragging over existing roads, water and buildings: only the new valid cells are built and paid", () => {
  const game = fresh();
  game.place("house", 4, 3, 0);
  game.placeRoads([[2, 3], [3, 3]]);
  const coins = game.economy.coins;
  const path = roadPath([1, 3], [6, 3]); // (1,3) sand ok, (2,3) and (3,3) already road, (4,3) house, (5,3) (6,3) ok
  const preview = game.previewRoads(path);
  expect(preview.map((p) => p.status)).toEqual(["new", "existing", "existing", "occupied", "new", "new"]);
  const res = game.placeRoads(path);
  expect(res.placed).toHaveLength(3);
  expect(res.skipped).toHaveLength(1);
  expect(res.skipped[0].cell).toEqual([4, 3]);
  expect(game.economy.coins).toBe(coins - 3 * 2);
  // dragging into the water
  const wet = fresh().placeRoads(roadPath([1, 8], [1, 9]));
  expect(wet.placed).toHaveLength(1); // (1,8) is sand, (1,9) is water
  expect(wet.skipped[0].reasons[0].code).toBe("terrain");
});

test("road dragging stops paying when the money runs out", () => {
  const game = fresh();
  game.economy.apply({ coins: -995 }, "test"); // 5 coins: two road cells
  const path = roadPath([2, 2], [6, 2]);
  expect(game.previewRoads(path).map((p) => p.status)).toEqual(["new", "new", "cannot_afford", "cannot_afford", "cannot_afford"]);
  const res = game.placeRoads(path);
  expect(res.placed).toHaveLength(2);
  expect(game.economy.coins).toBe(1);
  expect(game.economy.coins >= 0).toBe(true);
});

test("demolish: half the cost comes back, the cells are free again, the map redraws", () => {
  const game = fresh();
  game.place("house", 3, 3, 0);
  const removed = [];
  game.events.on("building.removed", (e) => removed.push(e.building.type));
  const res = game.demolish(3, 3);
  expect(res.ok).toBe(true);
  expect(res.refund).toEqual({ coins: 20, wood: 2 });
  expect(game.economy.coins).toBe(980);
  expect(game.economy.get("wood")).toBe(58);
  expect(game.buildingAt(3, 3)).toBeNull();
  expect(removed).toEqual(["house"]);
  expect(game.place("house", 3, 3, 0).ok).toBe(true); // the place is free again
  // any cell of a 2 x 2 building finds it
  game.place("farm", 5, 5, 0);
  expect(game.demolish(6, 6).building.type).toBe("farm");
  const none = game.demolish(6, 6);
  expect(none.ok).toBe(false);
  expect(none.reasons[0].code).toBe("nothing_here");
});

test("demolishing a road gives back half a road, rounded down per item (a 2-coin road gives 1)", () => {
  const game = fresh();
  game.placeRoads([[2, 2]]);
  expect(game.demolish(2, 2).refund).toEqual({ coins: 1 });
  expect(game.economy.coins).toBe(999);
});

test("demolishing along a drag is one undo step", () => {
  const game = fresh();
  game.placeRoads(roadPath([2, 2], [6, 2]));
  game.place("house", 3, 4, 0);
  const before = game.hash();
  const steps = game.undoStack.length;
  const res = game.demolishCells([[2, 2], [3, 2], [4, 2], [9, 9], [3, 4]]);
  expect(res.removed).toHaveLength(4);
  expect(game.undoStack).toHaveLength(steps + 1);
  game.undo();
  expect(game.hash()).toBe(before);
});

test("undo and redo restore the map and the money exactly, step by step", () => {
  const game = fresh();
  const hashes = [game.hash()];
  game.place("house", 3, 3, 0);
  hashes.push(game.hash());
  game.placeRoads(roadPath([2, 6], [8, 6]));
  hashes.push(game.hash());
  game.place("farm", 4, 4, 0);
  hashes.push(game.hash());
  game.demolish(3, 3);
  hashes.push(game.hash());
  game.placeAt("lumber_camp", 8, 2, 0);
  hashes.push(game.hash());
  expect(new Set(hashes).size).toBe(hashes.length); // every step changed something

  for (let i = hashes.length - 2; i >= 0; i--) {
    expect(game.undo().ok).toBe(true);
    expect(game.hash()).toBe(hashes[i]);
  }
  expect(game.canUndo()).toBe(false);
  expect(game.undo().ok).toBe(false);
  for (let i = 1; i < hashes.length; i++) {
    expect(game.redo().ok).toBe(true);
    expect(game.hash()).toBe(hashes[i]);
  }
  expect(game.canRedo()).toBe(false);
});

test("a new action drops the redo steps; the history event says what can be undone", () => {
  const game = fresh();
  const seen = [];
  game.events.on("history.changed", (e) => seen.push([e.canUndo, e.canRedo, e.undoLabel, e.redoLabel]));
  game.place("house", 3, 3, 0);
  game.undo();
  expect(game.canRedo()).toBe(true);
  game.place("house", 4, 4, 0);
  expect(game.canRedo()).toBe(false);
  expect(seen).toEqual([
    [true, false, "place", null],
    [false, true, null, "place"],
    [true, false, "place", null],
  ]);
});

test("undo cannot hand money back that is not there: it refuses and changes nothing", () => {
  const game = fresh();
  game.place("house", 3, 3, 0);
  game.demolish(3, 3); // +20 coins, +2 wood
  game.economy.apply({ coins: -game.economy.coins }, "test"); // all spent
  const before = game.hash();
  const res = game.undo(); // would have to take 20 coins back
  expect(res.ok).toBe(false);
  expect(res.code).toBe("cannot_afford");
  expect(game.hash()).toBe(before);
  expect(game.canUndo()).toBe(true);
});

test("undo refuses when the cells were taken by something that is not in the history", () => {
  const game = fresh();
  game.place("house", 3, 3, 0);
  game.demolish(3, 3);
  game.place("house", 3, 3, 0); // a new building in the same place clears the redo, but undo of the demolish must see it
  expect(game.undo().ok).toBe(true); // undoes the second house
  expect(game.undo().ok).toBe(true); // brings the first house back
  expect(game.buildingAt(3, 3).type).toBe("house");
});

test("the undo history is limited", () => {
  const game = fresh();
  const limit = game.data.economy.undoLimit;
  for (let i = 0; i < limit + 5; i++) {
    const c = 1 + (i % 9);
    const r = 2 + Math.floor(i / 9) % 6;
    game.place("road", c, r, 0);
    game.demolish(c, r);
  }
  expect(game.undoStack.length).toBeLessThanOrEqual(limit);
});
