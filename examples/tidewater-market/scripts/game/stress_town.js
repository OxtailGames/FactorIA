// @ts-check
// The stress town (pure): a dense town with hundreds of villagers on a flat map, to see what the walkers cost. It is the scene
// scenes/stress.scene.json (`perf.measure` with `scene`, the tests/stress.test.js numbers) and a way for later packages to
// check their budgets with the same crowd.
//
//   const state = createGame({ rows: stressRows(60) });
//   buildStressTown(state, { villagers: 520 });     // houses, jobs, markets, warehouses; every villager moved in
//
// What makes a crowd: every villager that has a job walks to it in the morning and home in the evening, and every villager
// without a job (or whose pack is empty) walks to the market, so about all of them are on the roads at the same time.
import { Planner } from "./planner.js";

/** Rows of terrain characters for a flat size x size map: grass, with a strip of sand and then water along the west edge. */
export function stressRows(size = 60) {
  const rows = [];
  for (let r = 0; r < size; r++) {
    let row = "w";
    for (let c = 1; c < size; c++) row += c === 1 ? "s" : "g";
    rows.push(row);
  }
  return rows;
}

/**
 * The town as a list of steps to run in order, each small enough for one frame (a script callback may not run over 2 s, and
 * laying out 160 houses takes longer than that in a debug build). `result` is filled in as the steps run.
 * @param {import("./state.js").GameState} state
 * @param {{ villagers?: number, workplaces?: number }} [options] workplaces = how many farms and bakeries give jobs (the rest of the crowd walks to the market)
 * @returns {{ steps: (() => void)[], result: { houses: number, workplaces: number, markets: number, villagers: number } }}
 */
export function stressTownSteps(state, options = {}) {
  const want = options.villagers ?? 520;
  const jobs = options.workplaces ?? 40;
  const result = { houses: 0, workplaces: 0, markets: 0, villagers: 0 };
  /** @type {Planner} */
  let planner;
  /** @type {(() => void)[]} */
  const steps = [];
  steps.push(() => {
    const economy = state.economy;
    economy.coins = 1e7;
    const goods = {};
    for (const g of state.data.goodIds) goods[g] = 600;
    economy.apply(goods, "stress");
    planner = new Planner(state);
    result.markets = planner.buildMany("market", 4);
    planner.buildMany("warehouse", 3);
  });
  const housing = state.data.buildings.house.housing;
  const houses = Math.ceil(want / housing);
  for (let done = 0; done < houses; done += 20) {
    steps.push(() => {
      result.houses += planner.buildMany("house", Math.min(20, houses - result.houses));
    });
  }
  steps.push(() => {
    result.workplaces = planner.buildMany("farm", Math.floor(jobs / 2)) + planner.buildMany("bakery", Math.floor(jobs / 2));
  });
  steps.push(() => {
    for (const h of state.list("house")) {
      while (result.villagers < want && state.sim.people.moveIn(h.id)) result.villagers++;
    }
    // empty packs: whoever has no job (and the workers after a day) walk to the market
    for (const v of state.sim.people.villagers.values()) v.food = 0;
  });
  return { steps, result };
}

/**
 * Fill a state with a dense town and move `villagers` villagers in (the house capacity is rounded up).
 * @param {import("./state.js").GameState} state
 * @param {{ villagers?: number, workplaces?: number }} [options] see stressTownSteps
 * @returns {{ houses: number, workplaces: number, markets: number, villagers: number }}
 */
export function buildStressTown(state, options = {}) {
  const { steps, result } = stressTownSteps(state, options);
  for (const step of steps) step();
  return result;
}
