// The bot (scripts/game/bot.js): a player that grows a town by rules. Its year is the check that the economy numbers work:
// the town must grow from the start state without ever running dry, and the same map must give the same town.
import { test, expect } from "factoria:test";
import { growTown } from "../scripts/game/bot.js";
import { Planner } from "../scripts/game/planner.js";
import { createGame } from "../scripts/game/state.js";

const SEED = 20261026;

test("the bot's year on the default map: the town grows, never goes broke for long, and the hash is pinned", () => {
  const { state, bot, history, summary } = growTown({ seed: SEED, days: 40 });
  // the final state is pinned: a change in the map, the rules, the numbers or the bot moves it on purpose
  expect(summary.hash).toBe("6dee2f92");
  expect(summary.year).toBe(2); // a year later: the first day of year 2
  expect(summary.population).toBeGreaterThanOrEqual(24);
  expect(summary.population).toBeLessThanOrEqual(45);
  expect(summary.coins).toBeGreaterThan(0);
  expect(summary.coins).toBeLessThan(5000);
  expect(summary.employed).toBeGreaterThanOrEqual(summary.population - 3);
  // it grows through the year: more people in each season than the one before
  const at = (day) => history[day - 1];
  expect(at(10).population).toBeGreaterThan(at(1).population);
  expect(at(25).population).toBeGreaterThan(at(10).population);
  expect(at(40).population).toBeGreaterThan(at(25).population);
  // the coins never go below zero and the town is broke on at most a few days
  expect(Math.min(...history.map((h) => h.coins))).toBeGreaterThanOrEqual(0);
  expect(history.filter((h) => h.broke).length).toBeLessThanOrEqual(3);
  // hunger is a few villagers on a few days, not a famine
  expect(Math.max(...history.map((h) => h.hungry))).toBeLessThanOrEqual(8);
  // it built every link of the chain
  const types = new Set(bot.built.map((b) => b.type));
  for (const t of ["warehouse", "lumber_camp", "sawmill", "house", "fisher_dock", "farm", "market", "bakery", "smokehouse"]) expect(types.has(t)).toBe(true);
  // the ledger agrees: the town made, moved, ate and sold food
  const ledger = state.sim.ledger;
  expect(ledger.produced.fish).toBeGreaterThan(0);
  expect(ledger.produced.bread).toBeGreaterThan(0);
  expect(ledger.eaten.fish + ledger.eaten.bread).toBeGreaterThan(100);
  expect(ledger.sales).toBeGreaterThan(ledger.wages);
  expect(ledger.lost.fish + ledger.lost.bread + ledger.lost.grain).toBe(0);
});

test("the same seed gives the same town, a different seed a different one", () => {
  const a = growTown({ seed: SEED, days: 12 });
  const b = growTown({ seed: SEED, days: 12 });
  expect(a.summary.hash).toBe(b.summary.hash);
  expect(JSON.stringify(a.bot.built)).toBe(JSON.stringify(b.bot.built));
  const c = growTown({ seed: 3, days: 12 });
  expect(c.summary.hash).not.toBe(a.summary.hash);
});

test("the bot grows a town on the small test map too", () => {
  const { summary, history } = growTown({ testMap: true, days: 20 });
  expect(summary.coins).toBeGreaterThanOrEqual(0);
  expect(history.length).toBe(20);
});

test("the planner keeps every street joined to the harbour and never builds on the streets to come", () => {
  const state = createGame({ seed: SEED });
  const planner = new Planner(state);
  expect(planner.plan.length).toBeGreaterThan(60);
  // each planned cell touches an earlier one (or is the harbour): laid in order, the streets are one network
  const seen = new Set();
  const w = state.map.width;
  const [hc, hr] = planner.harbour;
  planner.plan.forEach(([c, r], i) => {
    if (i > 0) {
      const touches = [[1, 0], [0, 1], [-1, 0], [0, -1]].some(([dc, dr]) => seen.has((r + dr) * w + c + dc));
      expect(touches).toBe(true);
    } else {
      expect([c, r]).toEqual([hc, hr]);
    }
    seen.add(r * w + c);
  });
  // a building never lands on a planned street cell
  state.economy.coins = 100000;
  state.economy.apply({ planks: 500, wood: 500, stone: 100 }, "test");
  for (const type of ["house", "farm", "warehouse", "market", "bakery"]) {
    for (let i = 0; i < 4; i++) {
      const res = planner.build(type);
      if (!res.ok) continue;
      const b = res.building;
      expect(planner.planKeys.has(b.y * w + b.x)).toBe(false);
    }
  }
});
