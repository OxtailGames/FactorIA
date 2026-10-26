// Helpers the simulation tests share (not a test file): a small working town on the hand-made test map, and ways to run the
// clock without a frame loop. The test map (data/test_map.json) is 12 x 10, water around, rock at columns 9-10, rows 4-5.
import { createGame } from "../scripts/game/state.js";

/** Run the simulation for game seconds, in fixed steps (the clock is driven directly: no frames, no speed). */
export function runSeconds(game, seconds) {
  const clock = game.clock;
  const steps = Math.round(seconds / clock.step);
  for (let i = 0; i < steps; i++) clock.tick(clock.step);
}

/** Run to a time of day: fraction 0..1 of the day, today or (when already past) tomorrow. */
export function runToDayFraction(game, fraction) {
  const clock = game.clock;
  let guard = 0;
  const target = Math.round(fraction * clock.ticksPerDay);
  while (clock.dayTick !== target && guard++ < clock.ticksPerDay * 2) clock.tick(clock.step);
}

/** Run whole days. */
export function runDays(game, days) {
  const clock = game.clock;
  const steps = days * clock.ticksPerDay;
  for (let i = 0; i < steps; i++) clock.tick(clock.step);
}

/** Give the town the money and goods to build anything. */
export function rich(game) {
  game.economy.apply({ coins: 20000, wood: 200, planks: 100, stone: 50 }, "test");
}

/** Place and check that it worked (a test layout that does not fit is a broken test, not a game result). */
export function put(game, type, x, y, rot = 0) {
  const res = game.place(type, x, y, rot);
  if (!res.ok) throw new Error(`test layout: ${type} at ${x},${y} rot ${rot} refused: ${JSON.stringify(res.reasons)}`);
  return res.building;
}

export function roadRow(game, r, c0, c1) {
  const cells = [];
  for (let c = c0; c <= c1; c++) cells.push([c, r]);
  const res = game.placeRoads(cells);
  if (res.skipped.length) throw new Error(`test layout: road row ${r} skipped ${JSON.stringify(res.skipped)}`);
}

export function roadCol(game, c, r0, r1) {
  const cells = [];
  for (let r = r0; r <= r1; r++) cells.push([c, r]);
  const res = game.placeRoads(cells);
  if (res.skipped.length) throw new Error(`test layout: road column ${c} skipped ${JSON.stringify(res.skipped)}`);
}

/**
 * The town most tests use. Road along row 5 (columns 1-8) and down column 2 (rows 6-7):
 *
 *   c:   0 1 2 3 4 5 6 7 8 9 10 11
 *   r3   w s g g g F F S S f f  w         F farm (5,3)   S smokehouse (7,3)   H houses on row 4, columns 1-4
 *   r4   w H H H H F F S S r r  w
 *   r5   w = = = = = = = = r r  w         = road
 *   r6   H = M M B B W W g g g  w         M market (3,6)   B bakery (5,6)   W warehouse (7,6)   H house (1,6)
 *   r7   H = M M B B W W g g g  w
 *   r8   w D D M . . W W s s    w         D fisher dock (1,8)
 *
 * `parts` picks what is built: roads and houses always; "farm", "dock", "smokehouse", "bakery", "market", "warehouse".
 * @param {{ parts?: string[], seed?: number }} [options]
 */
export function smallTown(options = {}) {
  const parts = options.parts || ["farm", "dock", "smokehouse", "bakery", "market", "warehouse"];
  const game = createGame({ testMap: true });
  rich(game);
  roadRow(game, 5, 1, 8);
  roadCol(game, 2, 6, 7);
  const ids = { houses: [] };
  for (const [c, r] of [[1, 4], [2, 4], [3, 4], [4, 4], [1, 6], [1, 7]]) ids.houses.push(put(game, "house", c, r).id);
  if (parts.includes("farm")) ids.farm = put(game, "farm", 5, 3).id;
  if (parts.includes("smokehouse")) ids.smokehouse = put(game, "smokehouse", 7, 3).id;
  if (parts.includes("dock")) ids.dock = put(game, "fisher_dock", 1, 8).id;
  if (parts.includes("market")) ids.market = put(game, "market", 3, 6, 3).id;
  if (parts.includes("bakery")) ids.bakery = put(game, "bakery", 5, 6).id;
  if (parts.includes("warehouse")) ids.warehouse = put(game, "warehouse", 7, 6, 3).id;
  return { game, ids };
}

/** Move villagers in until every house is full (what growth would do over time). */
export function fillHouses(game) {
  const people = game.sim.people;
  for (const rt of game.sim.ofType("house")) {
    while (people.moveIn(rt.id));
  }
}

/** Units of every good in the town (stock, buildings, shelves, carried cargo). */
export function inventory(game) {
  return Object.fromEntries(game.data.goodIds.map((g) => [g, game.sim.inventory(g)]));
}
