import { test, expect, game } from "factoria:test";
import { LEVELS, EMBERS_PER_LEVEL } from "../scripts/levels.js";
import * as progress from "../scripts/progress.js";
import { playLevel, listen } from "./helpers/autoplay.js";

// The bot of tests/helpers/autoplay.js runs right and jumps over what is ahead. Every level must be finishable by that,
// well inside a minute: the levels are gentle on purpose (later packages drive them in their own tests).
for (const level of LEVELS) {
  test(`the bot finishes level ${level.id}`, () => {
    progress.reset();
    const r = playLevel(level.id, { events: ["level_started", "level_completed", "checkpoint_reached"] });
    expect(r.completed).toBe(true);
    expect(r.seconds).toBeLessThan(60);
    expect(r.seconds).toBeGreaterThan(15); // and not a stroll of a few seconds
    expect(r.deaths).toBeLessThan(3);
    expect(r.events.level_completed).toHaveLength(1);
    const done = r.events.level_completed[0];
    expect(done.level).toBe(level.id);
    expect(done.embers).toHaveLength(EMBERS_PER_LEVEL);
    expect(done.deaths).toBe(r.deaths);
    expect(done.time).toBeCloseTo(r.seconds, 0);
    expect(progress.of(level.id).completed).toBe(true);
    expect(progress.of(level.id).bestTime).toBe(done.time);
    expect(r.events.checkpoint_reached.length).toBeGreaterThan(0);
  });
}

test("level_started is sent once, when the level starts", () => {
  game.load("scenes/levels/2-2.scene.json");
  const seen = listen("level_started");
  game.step(5);
  expect(seen.level_started).toEqual([{ level: "2-2" }]);
  game.step(60);
  expect(seen.level_started).toHaveLength(1);
});
