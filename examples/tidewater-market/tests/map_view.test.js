// The ground (scripts/game/map_view.js): one isometric Tilemap that agrees with iso.js, shows roads by their neighbours, swaps its
// picture per season and loses the trees of a forest cell a building stands on.
import { test, expect, game } from "factoria:test";
import { cellToWorld, worldToCell } from "../scripts/game/iso.js";

function open() {
  game.load("scenes/game.scene.json", { testMap: true });
  game.step(2);
  const ctl = game.find("controller").behaviour;
  return { ctl, state: ctl.state, ground: game.find("ground") };
}

test("the whole ground is one isometric Tilemap and not a sprite per cell", () => {
  const { state, ground } = open();
  const tm = ground.get("Tilemap");
  expect(tm.projection).toBe("isometric");
  expect(tm.tiles.length).toBe(state.map.height);
  expect(tm.tiles[0].length).toBe(state.map.width);
  // the sprites on screen are the few buildings and the overlay pool, not one per cell
  expect(game.renderStats().sprites).toBeLessThan(100);
});

test("tilemap.cellAt and cellToWorld agree with iso.js on every cell", () => {
  const { state, ground } = open();
  for (const [c, r] of [[0, 0], [5, 5], [10, 2], [state.map.width - 1, state.map.height - 1], [3, state.map.height - 1]]) {
    const [x, y] = cellToWorld(c, r);
    const w = ground.tilemap.cellToWorld(c, r);
    expect(w[0]).toBeCloseTo(x, 3);
    expect(w[1]).toBeCloseTo(y, 3);
    expect(ground.tilemap.cellAt([x, y])).toEqual({ col: c, row: r });
    expect(worldToCell(x, y)).toEqual([c, r]);
    // a point near the corner of the diamond is still the same cell
    expect(ground.tilemap.cellAt([x + 20, y])).toEqual({ col: c, row: r });
  }
  expect(ground.tilemap.cellAt([100000, 100000])).toBe(null);
});

test("a road draws the piece its neighbours ask for, and the terrain comes back when it is demolished", () => {
  const { state, ground } = open();
  const before = ground.tilemap.getTile(5, 5);
  state.placeRoads([[5, 5]]);
  const lone = ground.tilemap.getTile(5, 5);
  expect(lone).not.toBe(before);
  state.placeRoads([[6, 5]]);
  expect(ground.tilemap.getTile(5, 5)).not.toBe(lone);
  expect(ground.tilemap.getTile(5, 5)).toBe(state.data.tileset.roadTile + state.roadMask(5, 5));
  state.demolish(6, 5);
  state.demolish(5, 5);
  expect(ground.tilemap.getTile(5, 5)).toBe(before);
});

test("a season swaps the picture of the Tilemap", () => {
  const { ctl, state, ground } = open();
  const seasons = state.data.tileset.seasons;
  expect(ground.get("Tilemap").tileset).toBe(seasons.spring);
  const clock = ctl.state.clock;
  clock.setSpeed(0);
  clock.setDay(9);
  for (let i = 0; i < clock.ticksPerDay + 2; i++) clock.tick(clock.step);
  expect(clock.date().season).toBe("summer");
  expect(ground.get("Tilemap").tileset).toBe(seasons.summer);
});

test("a building on a forest cell cuts its trees, and they grow back when it is demolished", () => {
  const { state, ground } = open();
  const t = state.data.tileset;
  const isTree = (tile) => tile >= t.treeTile && tile < t.treeTile + t.treeVariants;
  expect(state.map.terrainAt(9, 2)).toBe("forest");
  const trees = ground.tilemap.getTile(9, 2);
  expect(isTree(trees)).toBe(true);
  state.addBuilding("house", 9, 2, 0, "test");
  game.step(1);
  expect(ground.tilemap.getTile(9, 2)).toBe(state.data.terrain.forest.tile);
  state.removeBuilding(state.buildingAt(9, 2), "test");
  game.step(1);
  expect(ground.tilemap.getTile(9, 2)).toBe(trees);
});
