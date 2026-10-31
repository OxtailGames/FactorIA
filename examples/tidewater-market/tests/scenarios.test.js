// Scenarios (scripts/game/scenarios.js, data/scenarios.json): the table is valid, every scenario can be won by the bot, goals are
// sticky and counted per season, and the progress goes into a save and comes back.
import { test, expect } from "factoria:test";
import scenariosJson from "../data/scenarios.json";
import { growTown } from "../scripts/game/bot.js";
import { getData } from "../scripts/game/data.js";
import { GoalTracker, newScenarioGame, scenarioIds, validateScenarios } from "../scripts/game/scenarios.js";
import { serializeGame, loadGame } from "../scripts/game/savegame.js";
import { smallTown, runDays } from "./town_helper.js";

const IDS = ["first_harbour", "river_mills", "winter_trade", "sandbox"];

test("the scenario table is valid, and its ids are the contract other packages key by", () => {
  expect(validateScenarios(scenariosJson, getData())).toEqual([]);
  expect(scenarioIds()).toEqual(IDS);
});

test("a damaged scenario table is reported with a pointer and a hint", () => {
  const data = getData();
  const bad = JSON.parse(JSON.stringify(scenariosJson));
  bad.scenarios.first_harbour.goals[0].kind = "populaton";
  bad.scenarios.river_mills.goals[1].good = "bred";
  bad.scenarios.winter_trade.start.stock.gold = 5;
  bad.scenarios.sandbox.goals = [{ id: "x", kind: "coins", target: 5 }];
  bad.scenarios.river_mills.map.sead = 4;
  const problems = validateScenarios(bad, data);
  const pointers = problems.map((p) => p.pointer);
  expect(pointers).toContain("/scenarios/first_harbour/goals/0/kind");
  expect(pointers).toContain("/scenarios/river_mills/goals/1/good");
  expect(pointers).toContain("/scenarios/winter_trade/start/stock/gold");
  expect(pointers).toContain("/scenarios/sandbox/goals");
  expect(pointers).toContain("/scenarios/river_mills/map/sead");
  expect(problems.find((p) => p.pointer.endsWith("/kind")).hint).toContain("did you mean 'population'");
  for (const p of problems) expect(p.hint.length).toBeGreaterThan(5);
});

test("a new game of a scenario has its own map, money, goods and day", () => {
  const data = getData();
  const river = newScenarioGame("river_mills", data).state;
  expect(river.economy.coins).toBe(1000);
  expect(river.economy.stock.wood).toBeGreaterThanOrEqual(80);
  const winter = newScenarioGame("winter_trade", data).state;
  expect(winter.clock.day).toBe(20);
  expect(winter.clock.date().season).toBe("autumn");
  expect(winter.sim.seasonId).toBe("autumn");
  expect(winter.economy.coins).toBe(1200);
  const sandbox = newScenarioGame("sandbox", data).state;
  expect(sandbox.economy.coins).toBe(5000);
  // two scenarios on different seeds are different maps
  expect(river.map.hash()).not.toBe(newScenarioGame("first_harbour", data).state.map.hash());
  expect(() => newScenarioGame("nope", data)).toThrow();
});

test("each scenario is won by the bot (the targets are reachable), and the sandbox never is", () => {
  const reached = {};
  for (const id of IDS) {
    const { state, def } = newScenarioGame(id, getData());
    const tracker = new GoalTracker(state, id, def).attach();
    const events = [];
    state.events.on("goal.done", (e) => events.push(e.id));
    let won = null;
    state.events.on("scenario.won", (e) => (won = e.day));
    growTown({ state, days: id === "sandbox" ? 20 : 75 });
    reached[id] = won;
    if (id === "sandbox") {
      expect(tracker.won).toBe(false);
      expect(won).toBe(null);
      expect(events).toEqual([]);
    } else {
      expect(won).not.toBe(null);
      expect(tracker.won).toBe(true);
      expect(events.sort()).toEqual(def.goals.map((g) => g.id).sort());
    }
  }
  // each is won inside 75 game days (a year is 40 days), so the targets are within reach of a plain plan
  expect(reached.first_harbour).toBeLessThan(75);
  expect(reached.river_mills).toBeLessThan(75);
  expect(reached.winter_trade).toBeLessThan(75);
});

test("goals are sticky, announced once, and a per-season count starts again with each season", () => {
  const { game } = smallTown();
  const target = game.economy.coins + 10;
  const def = {
    goals: [
      { id: "rich", kind: "coins", target },
      { id: "fisher", kind: "produced_in_season", good: "fish", target: 5 },
    ],
  };
  const tracker = new GoalTracker(game, "test", def).attach();
  const done = [];
  game.events.on("goal.done", (e) => done.push(e.id));
  tracker.check();
  expect(done).toEqual([]);
  expect(tracker.progress().map((p) => p.value)).toEqual([game.economy.coins, 0]);
  game.economy.apply({ coins: 10 }, "test");
  game.sim.ledger.produced.fish = (game.sim.ledger.produced.fish || 0) + 4;
  tracker.check();
  expect(done).toEqual(["rich"]);
  game.economy.apply({ coins: -20 }, "test"); // spending does not undo a goal
  tracker.check();
  expect(tracker.progress()[0].done).toBe(true);
  expect(done).toEqual(["rich"]);
  // 4 fish this season, then the season ends: the count starts again from nothing
  game.events.emit("clock.season", {});
  game.sim.ledger.produced.fish += 4;
  tracker.check();
  expect(done).toEqual(["rich"]);
  expect(tracker.progress()[1].value).toBe(4);
  game.sim.ledger.produced.fish += 1;
  tracker.check();
  expect(done).toEqual(["rich", "fisher"]);
  expect(tracker.won).toBe(true);
  expect(tracker.counts()).toEqual({ done: 2, total: 2 });
  // the win is announced once
  let wins = 0;
  game.events.on("scenario.won", () => wins++);
  tracker.check();
  tracker.check();
  expect(wins).toBe(0);
  tracker.detach();
});

test("the tracker only reads the game: it does not change the state hash", () => {
  const a = newScenarioGame("first_harbour", getData());
  const b = newScenarioGame("first_harbour", getData());
  new GoalTracker(a.state, "first_harbour", a.def).attach();
  growTown({ state: a.state, days: 20 });
  growTown({ state: b.state, days: 20 });
  expect(a.state.hash()).toBe(b.state.hash());
});

test("progress is saved with the game and comes back; the loaded game plays on identically", () => {
  const { state, def } = newScenarioGame("first_harbour", getData());
  const tracker = new GoalTracker(state, "first_harbour", def).attach();
  growTown({ state, days: 30 });
  expect(Object.keys(tracker.done).length).toBeGreaterThan(0);
  const save = serializeGame(state, tracker.saveFields());
  expect(save.scenario).toBe("first_harbour");
  const loaded = loadGame(JSON.stringify(save), getData());
  expect(loaded.ok).toBe(true);
  expect(loaded.save.scenario).toBe("first_harbour");
  const back = new GoalTracker(loaded.state, loaded.save.scenario, undefined, loaded.save.progress).attach();
  expect(back.toSave()).toEqual(tracker.toSave());
  growTown({ state, days: 25 });
  growTown({ state: loaded.state, days: 25 });
  expect(loaded.state.hash()).toBe(state.hash());
  expect(back.toSave()).toEqual(tracker.toSave());
  expect(back.won).toBe(tracker.won);
});

test("the slot meta carries the goal counts the slot screen shows", () => {
  const { state, def } = newScenarioGame("river_mills", getData());
  const tracker = new GoalTracker(state, "river_mills", def).attach();
  expect(tracker.metaFields()).toEqual({ goalsDone: 0, goalsTotal: 3, won: false });
  runDays(state, 1);
});
