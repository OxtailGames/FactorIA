import { test, expect } from "factoria:test";
import { session } from "factoria";
import * as progress from "../scripts/progress.js";

const result = (level, time, embers = [false, false, false], deaths = 0) => ({ level, time, embers, deaths });

test("a new game: only 1-1 is open, nothing found, Play starts 1-1", () => {
  progress.reset();
  expect(progress.get()).toEqual({ levels: {} });
  expect(progress.isUnlocked("1-1")).toBe(true);
  expect(progress.isUnlocked("1-2")).toBe(false);
  expect(progress.isUnlocked("2-3")).toBe(false);
  expect(progress.isUnlocked("nope")).toBe(false);
  expect(progress.totalEmbers()).toBe(0);
  expect(progress.of("1-1")).toEqual({ completed: false, bestTime: null, embers: [false, false, false] });
  expect(progress.nextToPlay().id).toBe("1-1");
});

test("finishing a level records it and unlocks the next one", () => {
  progress.reset();
  const info = progress.record(result("1-1", 41.2, [true, false, true]));
  expect(info).toEqual({ firstCompletion: true, newBest: true, bestTime: 41.2, previousBest: null });
  expect(progress.get()).toEqual({ levels: { "1-1": { completed: true, bestTime: 41.2, embers: [true, false, true] } } });
  expect(progress.isCompleted("1-1")).toBe(true);
  expect(progress.isUnlocked("1-2")).toBe(true);
  expect(progress.isUnlocked("1-3")).toBe(false); // only the next one
  expect(progress.totalEmbers()).toBe(2);
  expect(progress.nextToPlay().id).toBe("1-2");
});

test("the best time is kept, and so is every ember ever found", () => {
  progress.reset();
  progress.record(result("1-1", 50, [true, false, false]));
  const slower = progress.record(result("1-1", 60, [false, true, false]));
  expect(slower).toEqual({ firstCompletion: false, newBest: false, bestTime: 50, previousBest: 50 });
  expect(progress.of("1-1")).toEqual({ completed: true, bestTime: 50, embers: [true, true, false] });
  const faster = progress.record(result("1-1", 38.5, [false, false, true]));
  expect(faster).toEqual({ firstCompletion: false, newBest: true, bestTime: 38.5, previousBest: 50 });
  expect(progress.of("1-1")).toEqual({ completed: true, bestTime: 38.5, embers: [true, true, true] });
  expect(progress.totalEmbers()).toBe(3);
});

test("Play goes to the first level that is open and not finished; after the last level it goes to the last one", () => {
  progress.reset();
  for (const id of ["1-1", "1-2", "1-3", "2-1"]) progress.record(result(id, 30));
  expect(progress.nextToPlay().id).toBe("2-2");
  progress.record(result("2-2", 30));
  progress.record(result("2-3", 30));
  expect(progress.nextToPlay().id).toBe("2-3");
  expect(progress.isUnlocked("2-3")).toBe(true);
});

test("progress lives in session as plain JSON, get() is a copy, load() replaces it", () => {
  progress.reset();
  progress.record(result("1-1", 20, [true, true, true]));
  const copy = progress.get();
  copy.levels["1-1"].bestTime = 1;
  expect(progress.of("1-1").bestTime).toBe(20); // changing the copy changes nothing
  expect(JSON.parse(JSON.stringify(session.progress))).toEqual(progress.get());
  progress.load({ levels: { "1-2": { completed: true, bestTime: 9, embers: [false, false, true] } } });
  expect(progress.isCompleted("1-1")).toBe(false);
  expect(progress.isCompleted("1-2")).toBe(true);
  progress.load(null);
  expect(progress.get()).toEqual({ levels: {} });
});

test("recording an unknown level is an error that lists the levels", () => {
  progress.reset();
  expect(() => progress.record(result("9-9", 1))).toThrow(/unknown level "9-9".*1-1/);
});
