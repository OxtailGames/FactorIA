import { test, expect, game } from "factoria:test";
import { world, storage, platform } from "factoria";
import * as progress from "../scripts/progress.js";
import { LEVELS } from "../scripts/levels.js";
import { playLevel } from "./helpers/autoplay.js";

// Stats, achievements and best times, fed by the game events (README "Contract 3") and answered by the fake store.
// The events are sent by hand here (the same payloads level.js and player.js send); one test plays a real level.

const fake = () => game.platform.state().fake;
const unlocked = (id) => fake().achievements[id]?.unlocked === true;
const calls = (method) => game.platform.calls().filter((c) => c.method === method);

/** A new run of the game: nothing finished, nothing sent to the store, level 1-1 loaded. */
function fresh() {
  progress.reset();
  storage.remove("leaderboardsSent");
  storage.remove("wallet");
  game.platform.reset();
  game.load("scenes/levels/1-1.scene.json");
  game.step(3);
}

/** Delivers the events sent so far (a `world.emit` from a test reaches listeners at the next `game.step`; see
 * `factoria docs read scripting`), then waits for every request they started. */
async function settle() {
  game.step(1);
  await game.find("store_stats").behaviour.idle();
}

/** Finishes a level the way level.js does: the result goes into progress, then the event is sent. */
async function finish(level, time, { deaths = 0, embers = [false, false, false], assisted } = {}) {
  const result = { level, time, embers, deaths };
  if (assisted !== undefined) result.assisted = assisted;
  progress.record(result);
  world.emit("level_completed", result);
  await settle();
  return result;
}

test("every level carries the store listener and the cosmetics entity", () => {
  for (const level of LEVELS) {
    game.load(level.scene);
    game.step(2);
    expect(game.find("store_stats")).not.toBeNull();
    expect(game.find("cosmetics")).not.toBeNull();
  }
});

test("stats are counted from the events: jumps in batches, deaths, levels finished, embers found", async () => {
  fresh();
  for (let i = 0; i < 25; i++) world.emit("player_jumped", { level: "1-1" });
  await settle();
  expect(fake().stats.jumps).toBe(20); // two groups of ten are sent, five wait
  world.emit("player_died", { level: "1-1", cause: "spikes" });
  world.emit("player_died", { level: "1-1", cause: "fall" });
  await settle();
  expect(fake().stats.jumps).toBe(25); // a death sends the waiting jumps
  expect(fake().stats.deaths).toBe(2);
  await finish("1-1", 31.5, { deaths: 2, embers: [true, true, false] });
  expect(fake().stats.levels_finished).toBe(1);
  expect(fake().stats.embers_found).toBe(2);
  await finish("1-2", 50, { embers: [true, false, false] });
  expect(fake().stats.levels_finished).toBe(2);
  expect(fake().stats.embers_found).toBe(3);
  await finish("1-1", 30, { embers: [true, true, true] }); // the same level again: only the new ember counts
  expect(fake().stats.embers_found).toBe(4);
});

test("First Light, the worlds and Ember Keeper", async () => {
  fresh();
  await finish("1-2", 40);
  expect(unlocked("first_light")).toBe(false); // 1-1 only
  await finish("1-1", 40, { deaths: 1 });
  expect(unlocked("first_light")).toBe(true);
  expect(unlocked("courtyard_clear")).toBe(false);
  await finish("1-3", 40, { deaths: 1 });
  expect(unlocked("courtyard_clear")).toBe(true);
  expect(unlocked("cellars_clear")).toBe(false);
  for (const id of ["2-1", "2-2"]) await finish(id, 40, { deaths: 1, embers: [true, true, true] });
  expect(unlocked("cellars_clear")).toBe(false);
  expect(fake().achievements.all_embers.progress).toBeCloseTo(6 / 18, 5);
  await finish("2-3", 40, { deaths: 1, embers: [true, true, true] });
  expect(unlocked("cellars_clear")).toBe(true);
  expect(unlocked("all_embers")).toBe(false);
  for (const id of ["1-1", "1-2", "1-3"]) await finish(id, 39, { deaths: 1, embers: [true, true, true] });
  expect(progress.totalEmbers()).toBe(18);
  expect(unlocked("all_embers")).toBe(true);
});

test("Untouched needs a level without a death; Quick Feet a fast 1-1; assisted runs earn neither", async () => {
  fresh();
  await finish("1-2", 20, { deaths: 3 });
  expect(unlocked("untouched")).toBe(false);
  await finish("1-1", 28, { deaths: 1 }); // not under 28 seconds
  expect(unlocked("quick_feet")).toBe(false);
  await finish("1-3", 20, { deaths: 0, assisted: true });
  expect(unlocked("untouched")).toBe(false);
  await finish("1-1", 20, { deaths: 1, assisted: true });
  expect(unlocked("quick_feet")).toBe(false);
  await finish("1-2", 27.9, { deaths: 0 });
  expect(unlocked("untouched")).toBe(true);
  expect(unlocked("quick_feet")).toBe(false); // fast, but not 1-1
  await finish("1-1", 27.9, { deaths: 2 });
  expect(unlocked("quick_feet")).toBe(true);
});

test("Leap of Faith and Hard Lessons grow with their stats", async () => {
  fresh();
  for (let i = 0; i < 100; i++) world.emit("player_jumped", { level: "1-1" });
  await settle();
  expect(fake().stats.jumps).toBe(100);
  expect(fake().achievements.jumper.progress).toBeCloseTo(0.2, 5);
  expect(unlocked("jumper")).toBe(false);
  for (let i = 0; i < 400; i++) world.emit("player_jumped", { level: "1-1" });
  await settle();
  expect(unlocked("jumper")).toBe(true);
  for (let i = 0; i < 24; i++) world.emit("player_died", { level: "1-1", cause: "fall" });
  await settle();
  expect(unlocked("hard_lessons")).toBe(false);
  expect(fake().achievements.hard_lessons.progress).toBeCloseTo(24 / 25, 5);
  world.emit("player_died", { level: "1-1", cause: "enemy" });
  await settle();
  expect(unlocked("hard_lessons")).toBe(true);
});

test("a best time is submitted only when it is new, in milliseconds, never when assisted", async () => {
  fresh();
  await finish("1-1", 41.234);
  expect(calls("leaderboards.submit").map((c) => [c.args.id, c.args.score])).toEqual([["time_1-1", 41234]]);
  await finish("1-1", 45); // slower
  await finish("1-1", 41.234); // the same
  expect(calls("leaderboards.submit").length).toBe(1);
  await finish("1-1", 40.9, { assisted: false });
  expect(calls("leaderboards.submit").map((c) => c.args.score)).toEqual([41234, 40900]);
  await finish("1-1", 30, { assisted: true }); // faster, but assisted: no submit
  expect(calls("leaderboards.submit").length).toBe(2);
  expect(storage.get("leaderboardsSent")["time_1-1"]).toBe(40900);
  await finish("1-2", 50, { assisted: true });
  expect(calls("leaderboards.submit").length).toBe(2); // no board for an assisted first time either
  await finish("1-2", 50); // the missing field means "not assisted"
  expect(calls("leaderboards.submit").map((c) => c.args.id)).toEqual(["time_1-1", "time_1-1", "time_1-2"]);
});

test("the total time board gets the sum once every level has a time, and only when the sum improves", async () => {
  fresh();
  for (const l of LEVELS.slice(0, 5)) await finish(l.id, 10);
  expect(calls("leaderboards.submit").some((c) => c.args.id === "time_total")).toBe(false);
  await finish("2-3", 12.5);
  expect(calls("leaderboards.submit").filter((c) => c.args.id === "time_total").map((c) => c.args.score)).toEqual([62500]);
  await finish("2-3", 12.5);
  await finish("2-3", 13);
  expect(calls("leaderboards.submit").filter((c) => c.args.id === "time_total").length).toBe(1);
  await finish("1-1", 9);
  expect(calls("leaderboards.submit").filter((c) => c.args.id === "time_total").map((c) => c.args.score)).toEqual([62500, 61500]);
  expect(fake().leaderboards["time_total"]).toBeDefined();
});

test("a real level played to its exit sends its time and stats", async () => {
  fresh();
  const r = playLevel("1-1");
  expect(r.completed).toBe(true);
  await settle();
  const sent = calls("leaderboards.submit");
  expect(sent.length).toBe(1);
  expect(sent[0].args.id).toBe("time_1-1");
  expect(fake().stats.levels_finished).toBe(1);
  expect(fake().stats.jumps).toBeGreaterThan(0);
  expect(unlocked("first_light")).toBe(true);
});

test("not signed in, or a failing store: nothing throws, nothing is marked as sent, the next time tries again", async () => {
  fresh();
  game.platform.set({ signedIn: false });
  world.emit("player_jumped", { level: "1-1" });
  world.emit("player_died", { level: "1-1", cause: "fall" });
  await finish("1-1", 20);
  expect(unlocked("first_light")).toBe(false);
  expect(storage.get("leaderboardsSent", {})).toEqual({});
  game.platform.set({ signedIn: true });
  game.platform.respond("leaderboards.submit", { error: "network" });
  await finish("1-1", 20);
  expect(storage.get("leaderboardsSent", {})).toEqual({}); // the submit failed: not marked
  await finish("1-1", 20);
  expect(storage.get("leaderboardsSent")).toEqual({ "time_1-1": 20000 });
  game.step(5); // the game goes on
});

test("without the store services (the none backend) the listener does nothing and does not fail", async () => {
  fresh();
  game.platform.set({ backend: "none" });
  try {
    world.emit("player_jumped", { level: "1-1" });
    world.emit("player_died", { level: "1-1", cause: "fall" });
    const before = game.platform.calls().length;
    await finish("1-1", 20);
    expect(game.platform.calls().length).toBe(before);
    game.step(3);
  } finally {
    game.platform.reset();
  }
});
