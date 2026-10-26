// Ships, orders, reputation, event cards, story and achievements (scripts/game/trade.js, data/ships.json, events.json, story.json).
// All pure: no frames, the clock is driven directly.
import { test, expect } from "factoria:test";
import { createGame } from "../scripts/game/state.js";
import { Trade } from "../scripts/game/trade.js";
import { stream } from "../scripts/game/rng.js";
import { getTradeData, validateTradeTables, rawTradeTables } from "../scripts/game/trade_data.js";
import { rich, put, runDays, runSeconds, smallTown, fillHouses } from "./town_helper.js";

/** The test map with a pier on its north coast (4..6, 1: the water at row 0 is its berth) and the trade switched on. */
function harbour(scenario = "first_harbour", seed = 0) {
  const game = createGame({ testMap: true });
  game.map.seed = seed;
  rich(game);
  const pier = put(game, "pier", 4, 1);
  game.trade.start(scenario);
  return { game, trade: game.trade, pier };
}

/** A working town (farm, dock, bakery, sawmill-less) full of villagers, with a pier on the north coast: every kind of event can come up. */
function townHarbour(scenario, seed) {
  const { game } = smallTown();
  game.map.seed = seed;
  fillHouses(game);
  put(game, "pier", 4, 1);
  game.economy.apply({ planks: 50, wood: 100, fish: 100, grain: 100, stone: 100, bread: 100, tools: 20 }, "test");
  put(game, "sawmill", 2, 2);
  game.trade.start(scenario);
  return { game, trade: game.trade };
}

/** Answer the open card and every card queued behind it with a choice the town can pay. Returns what was answered. */
function answerAll(trade) {
  const out = [];
  for (let guard = 0; trade.card && guard < 8; guard++) {
    const { def } = trade.cardDef(trade.card);
    const choice = def.choices.find((c) => trade.canChoose(c).ok);
    out.push(`${trade.card.kind}:${trade.card.id}`);
    if (trade.card.stage === "choose") trade.choose(choice.id);
    trade.dismiss();
  }
  return out;
}

/** Run days until a ship has docked (or `max` days pass). */
function untilDocked(game, max = 14) {
  for (let i = 0; i < max * game.clock.ticksPerDay; i++) {
    game.clock.tick(game.clock.step);
    if (game.trade.ships.some((s) => s.state === "docked")) return true;
  }
  return false;
}

test("the ship, event and story tables are valid and cross-checked against goods, buildings, atlas and locale", () => {
  expect(validateTradeTables(rawTradeTables)).toEqual([]);
  expect(Object.keys(getTradeData().ships.classes)).toEqual(["skiff", "cog", "carrack"]);
});

test("a table mistake is reported with file, pointer and a did-you-mean", () => {
  const bad = JSON.parse(JSON.stringify(rawTradeTables));
  bad.ships.classes.skiff.wants.fsh = [1, 2];
  bad.events.events.storm.requires = { seasn: "winter" };
  bad.story.scenarios.first_harbour[0].choices[0].effects = { delta: { wod: -1 } };
  const problems = validateTradeTables(bad);
  const text = JSON.stringify(problems);
  expect(text).toContain("data/ships.json");
  expect(text).toContain("/classes/skiff/wants/fsh");
  expect(text).toContain("did you mean 'fish'");
  expect(text).toContain("did you mean 'season'");
  expect(text).toContain("did you mean 'wood'");
});

test("the trade is off in a plain game and a plain game's clock sends no ship", () => {
  const game = createGame({ testMap: true });
  rich(game);
  put(game, "pier", 4, 1);
  runDays(game, 12);
  expect(game.trade.enabled).toBe(false);
  expect(game.trade.ships.length).toBe(0);
  expect(game.trade.card).toBe(null);
});

test("the first ship sails in over the water, docks at the pier's berth, waits and leaves on its deadline", () => {
  const { game, trade } = harbour();
  const sent = [];
  const log = [];
  game.events.on("trade.ship.sent", (e) => sent.push(game.clock.day));
  game.events.on("trade.ship.docked", (e) => log.push(["docked", game.clock.day]));
  game.events.on("trade.ship.left", (e) => log.push(["left", game.clock.day, e.outcome]));
  expect(trade.ships.length).toBe(0);
  runDays(game, 2);
  expect(sent.length).toBe(0);
  runDays(game, 1);
  expect(sent).toEqual([3]); // data/ships.json schedule.firstShipDays
  const ship = trade.ships[0];
  expect(ship.state).toBe("arriving");
  // the route starts off the map and ends on the water cell next to the pier
  const first = ship.route[0];
  expect(game.map.inBounds(first[0], first[1])).toBe(false);
  const last = ship.route[ship.route.length - 1];
  expect(game.map.terrainAt(last[0], last[1])).toBe("water");
  for (const cell of ship.route.filter((c) => game.map.inBounds(c[0], c[1]))) expect(game.map.terrainAt(cell[0], cell[1])).toBe("water");
  // it sails at sailSpeed cells per game second
  const before = ship.t;
  runSeconds(game, 1);
  expect(ship.t - before).toBeCloseTo(getTradeData().ships.sailSpeed, 5);
  expect(untilDocked(game)).toBe(true);
  expect(log[0][0]).toBe("docked");
  expect(ship.deadline).toBe(log[0][1] + ship.wait);
  expect(ship.wait).toBeGreaterThanOrEqual(6);
  expect(ship.wait).toBeLessThanOrEqual(9);
  // nobody fills it: it leaves with the order missed
  runDays(game, ship.wait + 3);
  expect(log.some((l) => l[0] === "left" && l[2] === "missed")).toBe(true);
  expect(trade.ships.length === 0 || trade.ships[0] !== ship).toBe(true);
});

test("the next ship comes gapDays after the last, and only one ship per free berth", () => {
  const { game, trade } = harbour();
  const days = [];
  game.events.on("trade.ship.sent", () => days.push(game.clock.day));
  runDays(game, 40);
  expect(days.length).toBeGreaterThanOrEqual(3);
  const [lo, hi] = getTradeData().ships.schedule.gapDays;
  for (let i = 1; i < days.length; i++) {
    const gap = days[i] - days[i - 1];
    expect(gap >= lo || gap === getTradeData().ships.schedule.retryDays).toBe(true);
  }
  expect(trade.ships.length).toBeLessThanOrEqual(1); // one pier, one berth
});

test("filling an order takes the goods through economy.apply, pays the reward, raises the reputation and sends the ship off", () => {
  const { game, trade } = harbour();
  expect(untilDocked(game)).toBe(true);
  const ship = trade.ships[0];
  const causes = [];
  game.events.on("economy.changed", (e) => causes.push(e.cause));
  // short of goods: nothing happens
  const goods = Object.keys(ship.order.goods);
  game.economy.apply(Object.fromEntries(goods.map((g) => [g, -game.economy.get(g)])), "test");
  const coins = game.economy.coins;
  const refused = trade.fillOrder(ship.id);
  expect(refused.ok).toBe(false);
  expect(refused.code).toBe("missing_goods");
  expect(Object.keys(refused.missing).sort()).toEqual(goods.slice().sort());
  expect(game.economy.coins).toBe(coins);
  expect(ship.state).toBe("docked");
  // with the goods it works
  game.economy.apply(Object.fromEntries(goods.map((g) => [g, ship.order.goods[g] + 3])), "test");
  causes.length = 0;
  const rep = trade.reputation;
  const done = trade.fillOrder(ship.id);
  expect(done.ok).toBe(true);
  expect(done.reward).toBe(ship.order.reward);
  expect(causes).toEqual(["trade"]);
  expect(game.economy.coins).toBe(coins + ship.order.reward);
  for (const g of goods) expect(game.economy.get(g)).toBe(3);
  expect(trade.reputation).toBeGreaterThan(rep);
  expect(ship.state).toBe("leaving");
  expect(trade.stats.ordersFilled).toBe(1);
  // it sails away and is gone
  runDays(game, 1);
  expect(trade.ships.length).toBe(0);
  expect(trade.stats.shipsLeft).toBe(1);
});

test("a missed deadline costs reputation (never below 0) and a ship with no filled order stays missed", () => {
  const { game, trade } = harbour();
  trade.reputation = 5;
  expect(untilDocked(game)).toBe(true);
  const ship = trade.ships[0];
  const missed = [];
  game.events.on("trade.order.missed", (e) => missed.push(e.ship.id));
  runDays(game, ship.wait + 1);
  expect(missed).toEqual([ship.id]);
  expect(trade.reputation).toBe(5 + getTradeData().ships.reputation.missed);
  expect(trade.stats.ordersMissed).toBe(1);
  trade.reputation = 1;
  trade.addReputation(-50);
  expect(trade.reputation).toBe(0);
});

test("reputation unlocks better ships and says so", () => {
  const { game, trade } = harbour();
  expect(trade.availableClasses()).toEqual(["skiff"]);
  const unlocked = [];
  game.events.on("trade.class.unlocked", (e) => unlocked.push(e.cls));
  trade.addReputation(10);
  expect(trade.availableClasses()).toEqual(["skiff", "cog"]);
  trade.addReputation(25);
  expect(trade.availableClasses()).toEqual(["skiff", "cog", "carrack"]);
  expect(unlocked).toEqual(["cog", "carrack"]);
  // a carrack asks for more goods than a skiff, and pays by the goods' prices
  const sizes = new Set();
  for (let i = 0; i < 30; i++) {
    const ship = (trade.spawnShip(game.clock.day), trade.ships.pop());
    sizes.add(`${ship.cls}:${Object.keys(ship.order.goods).length}`);
    for (const [g, n] of Object.entries(ship.order.goods)) {
      const [lo, hi] = getTradeData().ships.classes[ship.cls].wants[g];
      expect(n).toBeGreaterThanOrEqual(lo);
      expect(n).toBeLessThanOrEqual(hi);
    }
    expect(ship.order.reward % 5).toBe(0);
  }
  expect([...sizes].some((s) => s.startsWith("carrack:") || s.startsWith("cog:"))).toBe(true);
});

test("a pier that is torn down sends its ship away", () => {
  const { game, trade, pier } = harbour();
  expect(untilDocked(game)).toBe(true);
  game.demolish(pier.x, pier.y);
  expect(trade.ships[0].state).toBe("leaving");
  expect(trade.ships[0].outcome).toBe("cancelled");
  runDays(game, 1);
  expect(trade.ships.length).toBe(0);
});

test("a pier on a lake (no way to the sea) gets no ship", () => {
  const rows = ["gggggggggg", "ggwwwwgggg", "ggwwwwgggg", "gggggggggg", "gggggggggg"];
  const game = createGame({ rows });
  rich(game);
  put(game, "pier", 2, 3); // touches the lake on row 2, but the lake is closed
  game.trade.start("sandbox");
  runDays(game, 20);
  expect(game.trade.ships.length).toBe(0);
});

test("the seeded event pick: same seed and same days, same events; another seed, other events", () => {
  const run = (seed) => {
    const { game, trade } = townHarbour("sandbox", seed);
    const seen = [];
    game.events.on("trade.card", (e) => seen.push(e.card.id));
    for (let i = 0; i < 200 * game.clock.ticksPerDay; i++) {
      game.clock.tick(game.clock.step);
      answerAll(trade);
      if (i % game.clock.ticksPerDay === 0) game.economy.apply({ coins: 500 }, "test"); // keep the town solvent: this test is about the picks
    }
    return seen;
  };
  const a = run(11);
  expect(a.length).toBeGreaterThanOrEqual(15);
  expect(run(11)).toEqual(a);
  expect(run(12)).not.toEqual(a);
  expect(run(13)).not.toEqual(a);
  expect(new Set(a).size).toBeGreaterThanOrEqual(6); // the weights favour the season but the pick is not stuck on one card
});

test("one event card is drawn per season, on the event day; requirements and the last two picks keep an event out", () => {
  const { game, trade } = harbour("sandbox", 5);
  const days = [];
  const ids = [];
  game.events.on("trade.card", (e) => {
    days.push(game.clock.day);
    ids.push(e.card.id);
  });
  for (let i = 0; i < 80 * game.clock.ticksPerDay; i++) {
    game.clock.tick(game.clock.step);
    answerAll(trade);
  }
  const { eventDay } = getTradeData().events;
  expect(days.length).toBeGreaterThanOrEqual(5);
  expect(days.length).toBeLessThanOrEqual(8);
  for (const d of days) expect((d % 10) + 1).toBe(eventDay);
  expect(new Set(days.map((d) => Math.floor(d / 10))).size).toBe(days.length); // at most one per season
  // no farm, no sawmill, nobody lives here: those events cannot be picked
  for (const id of ids) expect(["sick_herd", "good_harvest", "fish_run", "fire", "festival", "cold_snap", "pedlar", "smugglers"]).not.toContain(id);
  for (let i = 2; i < ids.length; i++) expect(ids[i] === ids[i - 1] || ids[i] === ids[i - 2]).toBe(false);
});

/** Every choice of every event and story card, played from a rich town: the effects arrive through economy.apply, exactly. */
test("every choice of every card applies its effects (plain ones exactly, gambles one of their outcomes)", () => {
  const { game, trade } = harbour("sandbox");
  const data = getTradeData();
  const cards = [];
  for (const [id, def] of Object.entries(data.events.events)) cards.push({ kind: "event", id, def });
  for (const [scenario, list] of Object.entries(data.story.scenarios)) for (const def of list) cards.push({ kind: "story", id: def.id, def, scenario });
  expect(cards.length).toBeGreaterThanOrEqual(23);
  let checked = 0;
  for (const c of cards) {
    for (const choice of c.def.choices) {
      const g = createGame({ testMap: true });
      rich(g);
      g.economy.apply({ fish: 40, wood: 40, grain: 40, planks: 40, stone: 40, bread: 40, tools: 40 }, "test");
      g.trade.start(c.scenario || "sandbox");
      g.trade.card = { kind: c.kind, id: c.id, stage: "choose" };
      g.trade.reputation = 20;
      const causes = [];
      g.events.on("economy.changed", (e) => causes.push(e.cause));
      const before = { coins: g.economy.coins, ...g.economy.stock };
      const rep = g.trade.reputation;
      const res = g.trade.choose(choice.id);
      expect(res.ok).toBe(true);
      const effects = choice.outcomes ? choice.outcomes[res.outcome].effects : choice.effects;
      for (const [k, v] of Object.entries(effects.delta || {})) {
        const now = k === "coins" ? g.economy.coins : g.economy.get(k);
        expect(now - (before[k] || 0)).toBe(v);
      }
      for (const k of Object.keys(effects.delta || {})) if (Object.keys(effects.delta).length) expect(causes).toEqual(["event"]);
      expect(g.trade.reputation - rep).toBe(effects.reputation || 0);
      expect(g.trade.card.stage).toBe("result");
      expect(g.trade.card.choice).toBe(choice.id);
      checked++;
    }
  }
  expect(checked).toBeGreaterThanOrEqual(50);
});

test("a choice the town cannot pay is refused and changes nothing; a gamble can always be picked and takes only what the town has", () => {
  const { game, trade } = harbour("sandbox");
  game.economy.apply({ fish: -game.economy.get("fish"), wood: -game.economy.get("wood"), planks: -game.economy.get("planks") }, "test");
  trade.card = { kind: "event", id: "storm", stage: "choose" };
  const before = JSON.stringify(game.economy.stock);
  const refused = trade.choose("secure"); // costs 4 planks
  expect(refused.ok).toBe(false);
  expect(refused.code).toBe("cannot_afford");
  expect(refused.missing.planks).toBe(4);
  expect(JSON.stringify(game.economy.stock)).toBe(before);
  expect(trade.card.stage).toBe("choose");
  game.economy.apply({ fish: 5 }, "test");
  // force the bad outcome of the gamble: it loses 12 fish and 8 wood, but the town has 5 fish and no wood
  trade.rngOutcomes.weighted = () => 1;
  const res = trade.choose("ride");
  expect(res.ok).toBe(true);
  expect(res.outcome).toBe(1);
  expect(game.economy.get("fish")).toBe(0);
  expect(game.economy.get("wood")).toBe(0);
});

test("the clock waits for no one but a card waits for the player: cards queue and open one at a time", () => {
  const { trade } = harbour("sandbox");
  trade.enqueue({ kind: "event", id: "merchant" });
  trade.enqueue({ kind: "event", id: "wreck" });
  expect(trade.card.id).toBe("merchant");
  expect(trade.queue.length).toBe(1);
  expect(trade.dismiss()).toBe(false); // not answered yet
  expect(trade.choose("nope").code).toBe("unknown_choice");
  expect(trade.choose("decline").ok).toBe(true);
  expect(trade.choose("decline").code).toBe("no_card"); // already answered
  expect(trade.dismiss()).toBe(true);
  expect(trade.card.id).toBe("wreck");
});

test("a scenario story shows its cards in order when their conditions hold, finishes, and unlocks its achievement", () => {
  const { game, trade } = harbour("first_harbour");
  const stories = [];
  game.events.on("trade.card", (e) => e.card.kind === "story" && stories.push(e.card.id));
  let finished = 0;
  game.events.on("trade.story.finished", () => finished++);
  // day 0 and 1: nothing yet; the first card needs day 2 and comes before that day's event card
  runDays(game, 1);
  expect(stories).toEqual([]);
  expect(trade.card).toBe(null);
  runDays(game, 1);
  expect(stories).toEqual(["letter"]);
  expect(trade.card.kind).toBe("story");
  expect(trade.choose("aloud").ok).toBe(true);
  expect(trade.dismiss()).toBe(true);
  answerAll(trade); // the event of the day, then the second card (the pier stands already)
  expect(stories).toEqual(["letter", "pier"]);
  // the third waits for the first filled order, the fourth for three
  for (let n = 0; n < 3; n++) {
    expect(untilDocked(game, 20)).toBe(true);
    answerAll(trade);
    const ship = trade.ships.find((s) => s.state === "docked");
    game.economy.apply(Object.fromEntries(Object.entries(ship.order.goods)), "test");
    expect(trade.fillOrder(ship.id).ok).toBe(true);
    answerAll(trade);
    expect(stories.length).toBe(n < 2 ? 3 : 4);
  }
  expect(stories).toEqual(["letter", "pier", "cargo", "map"]);
  expect(finished).toBe(1);
  expect(trade.unlocked).toContain("story_first_harbour");
  expect(trade.storyDone).toBe(true);
  // a finished story shows nothing more
  runDays(game, 30);
  answerAll(trade);
  expect(stories.length).toBe(4);
});

test("the sandbox has no story", () => {
  const { game, trade } = harbour("sandbox");
  runDays(game, 12);
  expect(trade.cards.length).toBe(0);
  expect(trade.storyDone).toBe(false);
});

test("achievements: first ship, ten orders, a year without debt", () => {
  const { game, trade } = harbour("sandbox");
  const got = [];
  game.events.on("trade.achievement", (e) => got.push(e.id));
  expect(untilDocked(game)).toBe(true);
  expect(got).toEqual(["first_ship"]);
  trade.stats.ordersFilled = 9;
  const ship = trade.ships[0];
  game.economy.apply(Object.fromEntries(Object.entries(ship.order.goods)), "test");
  trade.fillOrder(ship.id);
  expect(got).toContain("ten_orders");
  // a year (4 seasons of 10 days) with no broke payday
  expect(got).not.toContain("no_debt_year");
  trade.stats.lastBrokeDay = game.clock.day;
  runDays(game, 39);
  expect(got).not.toContain("no_debt_year");
  runDays(game, 1);
  expect(got).toContain("no_debt_year");
});

test("a broke payday resets the year without debt", () => {
  const { game, trade } = harbour("sandbox");
  runDays(game, 30);
  game.events.emit("payday", { wages: 0, upkeep: 5, owed: 5, broke: true });
  expect(trade.stats.lastBrokeDay).toBe(game.clock.day);
});

test("snapshot and restore: a saved game continues exactly like the one that was never saved", () => {
  const { game, trade } = harbour("first_harbour", 77);
  // play: answer cards with their first affordable choice, fill orders when the goods are there
  const play = (g, days) => {
    for (let i = 0; i < days * g.clock.ticksPerDay; i++) {
      g.clock.tick(g.clock.step);
      const t = g.trade;
      if (t.card && t.card.stage === "choose") {
        const { def } = t.cardDef(t.card);
        t.choose((def.choices.find((c) => t.canChoose(c).ok) || def.choices[0]).id);
      } else if (t.card) t.dismiss();
      for (const s of t.ships) if (s.state === "docked" && t.canFill(s.id).ok) t.fillOrder(s.id);
    }
  };
  game.economy.apply({ fish: 400, wood: 400, grain: 400, stone: 400, planks: 400, bread: 400, flour: 400, smoked_fish: 400, tools: 400 }, "test");
  play(game, 25);
  const snap = trade.snapshot();
  expect(JSON.parse(JSON.stringify(snap))).toEqual(snap); // plain JSON
  expect(snap.v).toBe(1);
  const coins = game.economy.coins;
  const stock = { ...game.economy.stock };
  const day = game.clock.day;
  const tick = game.clock.dayTick;
  play(game, 40);
  const want = trade.hash();
  const wantCoins = game.economy.coins;

  // a new game with the same town, the clock and the economy put back (P4 saves those), then the trade snapshot
  const other = createGame({ testMap: true });
  other.map.seed = 77;
  other.economy.apply({ coins: coins - other.economy.coins }, "load");
  for (const [k, v] of Object.entries(stock)) other.economy.apply({ [k]: v - other.economy.get(k) }, "load");
  put(other, "pier", 4, 1);
  other.economy.apply({ coins: coins - other.economy.coins }, "load");
  for (const [k, v] of Object.entries(stock)) other.economy.apply({ [k]: v - other.economy.get(k) }, "load");
  other.clock.setDay(day);
  other.clock.dayTick = tick;
  other.trade.restore(JSON.parse(JSON.stringify(snap)));
  expect(other.trade.hash()).toBe(hashOf(snap));
  play(other, 40);
  expect(other.trade.hash()).toBe(want);
  expect(other.economy.coins).toBe(wantCoins);
});

function hashOf(snap) {
  const g = createGame({ testMap: true });
  rich(g);
  put(g, "pier", 4, 1);
  g.trade.start(snap.scenario);
  g.trade.restore(snap);
  return g.trade.hash();
}

test("restore refuses a snapshot of another version, with a message that says what to do", () => {
  const { trade } = harbour();
  let message = "";
  try {
    trade.restore({ v: 99 });
  } catch (e) {
    message = String(e.message);
  }
  expect(message).toContain("version 99");
});

test("bus names: everything the trade announces starts with 'trade.'", () => {
  const { game, trade } = harbour("first_harbour");
  const names = new Set();
  const origEmit = game.events.emit.bind(game.events);
  game.events.emit = (name, payload) => {
    if (name.startsWith("trade.")) names.add(name);
    return origEmit(name, payload);
  };
  expect(untilDocked(game)).toBe(true);
  const ship = trade.ships[0];
  game.economy.apply(Object.fromEntries(Object.entries(ship.order.goods)), "test");
  trade.fillOrder(ship.id);
  for (const n of ["trade.ship.sent", "trade.ship.docked", "trade.order.filled", "trade.reputation", "trade.card", "trade.achievement"]) {
    expect(names.has(n)).toBe(true);
  }
  expect(Trade).toBeDefined();
});

test("the trade's random streams resume from a saved state, and a state saved before rng.create had one still works", () => {
  // 12345 -> 0.9797..., 0.3067..., 0.4842...: the numbers the game's own mulberry32 gave before the engine had `state`
  const a = stream(12345);
  expect(a.float()).toBeCloseTo(0.9797282677609473, 12);
  expect(a.state).toBe(12345 + 0x6d2b79f5); // one step per draw
  const saved = a.state;
  const next = [a.float(), a.float()];
  const b = stream(0);
  b.state = saved;
  expect([b.float(), b.float()]).toEqual(next);
  expect(next[0]).toBeCloseTo(0.3067522644996643, 12);
  expect(next[1]).toBeCloseTo(0.484205421525985, 12);
  // a snapshot stores the states, a restore puts the streams back where they were
  const { trade } = harbour("first_harbour", 7);
  trade.rngShips.float();
  trade.rngEvents.float();
  const snap = trade.snapshot();
  const after = [trade.rngShips.float(), trade.rngEvents.float(), trade.rngOutcomes.float()];
  const again = harbour("first_harbour", 7).trade;
  again.restore(snap);
  expect([again.rngShips.float(), again.rngEvents.float(), again.rngOutcomes.float()]).toEqual(after);
});
