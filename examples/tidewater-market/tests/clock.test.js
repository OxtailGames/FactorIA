// The clock and the seasons (scripts/game/clock.js, data/seasons.json): fixed steps, pause and x1/x2/x4, the order of the
// events, and what a season changes (growth, prices, colour).
import { test, expect } from "factoria:test";
import { createGame } from "../scripts/game/state.js";
import { SPEEDS } from "../scripts/game/clock.js";

const fresh = () => createGame({ testMap: true });

/** Advance a clock by real seconds in frames of 1/60 s. */
function run(clock, seconds) {
  const frames = Math.round(seconds * 60);
  for (let i = 0; i < frames; i++) clock.advance(1 / 60, 50);
}

test("a new clock is paused and does not move", () => {
  const game = fresh();
  expect(game.clock.speed).toBe(0);
  run(game.clock, 10);
  expect(game.clock.ticks).toBe(0);
  expect(game.clock.date()).toEqual({ day: 0, year: 1, season: "spring", seasonIndex: 0, dayOfSeason: 1 });
});

test("x1, x2 and x4 run 1, 2 and 4 game seconds per real second, in whole fixed steps", () => {
  expect(SPEEDS).toEqual([0, 1, 2, 4]);
  for (const speed of [1, 2, 3]) {
    const game = fresh();
    game.clock.setSpeed(speed);
    run(game.clock, 10);
    const expected = (SPEEDS[speed] * 10) / game.clock.step;
    expect(Math.abs(game.clock.ticks - expected)).toBeLessThanOrEqual(1);
  }
});

test("the same game seconds give the same state at every speed and frame rate", () => {
  const hashes = [];
  for (const [speed, fps] of [[1, 60], [2, 60], [3, 60], [3, 30], [1, 144]]) {
    const game = fresh();
    game.place("road", 2, 4, 0);
    game.clock.setSpeed(speed);
    // 40 game seconds: 40 / speed real seconds
    const frames = Math.round((40 / SPEEDS[speed]) * fps);
    for (let i = 0; i < frames; i++) game.clock.advance(1 / fps, 50);
    hashes.push([game.clock.ticks, game.hash()]);
  }
  // the tick counts agree to one step (a frame boundary), and the states of equal tick counts are equal
  const first = hashes[0];
  for (const h of hashes) expect(Math.abs(h[0] - first[0])).toBeLessThanOrEqual(1);
  const byTicks = new Map();
  for (const [ticks, hash] of hashes) {
    if (byTicks.has(ticks)) expect(hash).toBe(byTicks.get(ticks));
    byTicks.set(ticks, hash);
  }
});

test("a slow frame is capped instead of running away", () => {
  const game = fresh();
  game.clock.setSpeed(3);
  game.clock.advance(100, 5);
  expect(game.clock.ticks).toBe(5);
  expect(game.clock.alpha).toBeLessThanOrEqual(1);
});

test("days, seasons and years roll over in order, and the day comes before the tick", () => {
  const game = fresh();
  const heard = [];
  game.events.on("*", (e, name) => ["clock.day", "clock.season", "clock.tick"].includes(name) && heard.push(name));
  const days = [];
  const seasons = [];
  game.events.on("clock.day", (e) => days.push(e.day));
  game.events.on("clock.season", (e) => seasons.push(e.date.season));
  game.clock.setSpeed(3);
  const perDay = game.clock.ticksPerDay;
  for (let i = 0; i < perDay * 41; i++) game.clock.tick(game.clock.step);
  expect(days.length).toBe(41);
  expect(days[0]).toBe(1);
  expect(seasons).toEqual(["summer", "autumn", "winter", "spring"]);
  expect(game.clock.date()).toEqual({ day: 41, year: 2, season: "spring", seasonIndex: 0, dayOfSeason: 2 });
  // the first events of a day rollover are clock.day then clock.tick; a season change follows its day
  const first = heard.indexOf("clock.day");
  expect(heard[first - 1]).toBe("clock.tick");
  expect(heard[first + 1]).toBe("clock.tick");
  const season = heard.indexOf("clock.season");
  expect(heard[season - 1]).toBe("clock.day");
});

test("setDay jumps to a date", () => {
  const game = fresh();
  game.clock.setDay(10);
  expect(game.clock.date().season).toBe("summer");
  game.clock.setDay(40);
  expect(game.clock.date()).toEqual({ day: 40, year: 2, season: "spring", seasonIndex: 0, dayOfSeason: 1 });
});

test("a season changes what grows: winter has no harvest, autumn a big one", () => {
  const game = fresh();
  expect(game.sim.seasonRate("harvest_grain")).toBe(0.5); // spring
  game.clock.setDay(19);
  for (let i = 0; i < game.clock.ticksPerDay; i++) game.clock.tick(game.clock.step);
  expect(game.sim.seasonId).toBe("autumn");
  expect(game.sim.seasonRate("harvest_grain")).toBe(1.8);
  game.clock.setDay(29);
  for (let i = 0; i < game.clock.ticksPerDay; i++) game.clock.tick(game.clock.step);
  expect(game.sim.seasonId).toBe("winter");
  expect(game.sim.seasonRate("harvest_grain")).toBe(0);
  expect(game.sim.seasonRate("catch_fish")).toBe(0.6);
});

test("a season changes what sells: winter fish costs more than summer fish", () => {
  const game = fresh();
  const price = (day) => {
    game.sim.season = game.data.seasons[game.data.economy.calendar.seasons[Math.floor(day / 10) % 4]];
    return game.sim.priceOf("smoked_fish");
  };
  expect(price(0)).toBe(18); // spring: base price
  expect(price(10)).toBeLessThan(price(0)); // summer demand 0.9
  expect(price(30)).toBeGreaterThan(price(0)); // winter demand 1.4
});
