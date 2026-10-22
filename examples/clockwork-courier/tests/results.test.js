// P3: the results screen: the courier's name, the stars, this run's time next to the best one, and what earned each star.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { storage } from "factoria";
import * as progress from "../scripts/progress.js";
import { starText, goalLines } from "../scripts/results_view.js";

const texts = () => ({
  heading: game.find("results_heading").get("Text").text,
  stars: game.find("results_stars").get("Text").text,
  time: game.find("results_time").get("Text").text,
  spring: game.find("results_spring").get("Text").text,
});

/** Plays rooftops_1 to its results screen: waits `wait` frames, then hands in the required parcel. */
function finishRooftops1(wait) {
  game.load("scenes/rooftops_1.scene.json");
  game.step(5 + wait);
  game.find("level").behaviour.onDelivery("door", 1, 0);
  game.step(150);
}

describe("results screen", () => {
  beforeEach(() => {
    game.setStorageText(null);
    storage.remove("progress");
  });

  test("starText draws filled and empty stars", () => {
    expect(starText(0)).toBe("---");
    expect(starText(2)).toBe("**-");
    expect(starText(3)).toBe("***");
  });

  test("the heading carries the name, the first win is a new best, and the goals are listed", () => {
    progress.setName("Ana");
    finishRooftops1(10);
    const t = texts();
    expect(t.heading).toBe("Delivered, Ana!");
    expect(t.stars).toMatch(/^\*+-*$/);
    expect(t.time).toMatch(/^Time: \d+\.\d s   New best!$/);
    const lines = t.spring.split("\n");
    expect(lines[0]).toMatch(/^Spring left: \d+ s$/);
    expect(lines[1]).toBe("[x] Fast: under 50 s"); // a few frames in: well under the par time
    expect(lines[2]).toContain("Springy");
    expect(lines[3]).toBe("[ ] Thorough: every bonus parcel"); // the bonus parcel was not handed in
    game.screenshot(".factoria/tmp/results.png");
  });

  test("a slower second run shows the saved best time instead", () => {
    progress.setName("Ana");
    finishRooftops1(10);
    const best = progress.resultFor("rooftops_1");
    finishRooftops1(120);
    expect(texts().time).toContain(`Best: ${best.time.toFixed(1)} s`);
    expect(texts().time).not.toContain("New best");
  });

  test("without a name the heading is the plain one", () => {
    finishRooftops1(10);
    expect(texts().heading).toBe("Delivered!");
  });

  test("goalLines marks each goal, and leaves the thorough one out on a level without bonus parcels", () => {
    expect(goalLines("rooftops_1", { fast: true, springy: false, thorough: false })).toEqual([
      "[x] Fast: under 50 s",
      "[ ] Springy: 25 percent of the spring left",
      "[ ] Thorough: every bonus parcel",
    ]);
    expect(goalLines("rooftops_1", { fast: true, springy: true, thorough: null }).length).toBe(2);
  });
});
