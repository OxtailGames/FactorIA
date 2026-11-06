import { test, expect, game } from "factoria:test";
import { ui, input, storage, session, feel, game as running } from "factoria";
import * as settings from "../scripts/settings.js";

// The operating system's accessibility settings (game.accessibility) are only the first-run defaults of the options; the
// player's saved choice wins. Tests pretend to be a system with game.setAccessibility() (reset before every test).

function start(saved) {
  storage.clear();
  if (saved) storage.set("settings", saved);
  delete session.settingsApplied;
  input.resetBindings();
  game.load("scenes/menu.scene.json");
  game.step(2);
}

test("a headless run has no accessibility settings", () => {
  expect(running.accessibility).toEqual({ textScale: 1, reduceMotion: false, highContrast: false, screenReader: false });
  expect(Object.isFrozen(running.accessibility)).toBe(true);
  expect(() => game.setAccessibility({ textscale: 2 })).toThrow("did you mean 'textScale'");
  expect(() => game.setAccessibility({ reduceMotion: "yes" })).toThrow("must be true or false");
  expect(() => game.setAccessibility({ textScale: 0 })).toThrow("above 0");
});

test("the test API sets what the system says, and 100 as a text scale is clamped", () => {
  game.setAccessibility({ textScale: 1.5, highContrast: true });
  expect(running.accessibility).toEqual({ textScale: 1.5, reduceMotion: false, highContrast: true, screenReader: false });
  game.setAccessibility({ textScale: 100 });
  expect(running.accessibility.textScale).toBe(4);
});

test("the previous test's settings are gone", () => {
  expect(running.accessibility.textScale).toBe(1);
  expect(running.accessibility.highContrast).toBe(false);
});

test("first run: text size, reduced effects and reading aloud start from the system", () => {
  game.setAccessibility({ textScale: 1.5, reduceMotion: true, screenReader: true });
  start();
  expect(ui.textScale).toBeCloseTo(1.5);
  const s = settings.load();
  expect(s.textScale).toBeCloseTo(1.5);
  expect(s.reducedEffects).toBe(null); // nothing chosen: it follows the system, now and on every later run
  expect(settings.reducedEffects(s)).toBe(true);
  expect(feel.reduceMotion).toBe(true);
  expect(feel.reducedEffects).toBe(true);
  expect(s.readAloud).toBe(true);
  ui.textScale = 1;
});

test("a system without any of them keeps the plain defaults", () => {
  start();
  expect(ui.textScale).toBe(1);
  expect(settings.load()).toMatchObject({ textScale: 1, reducedEffects: null, readAloud: false });
  expect(settings.reducedEffects()).toBe(false);
});

test("a player who never chose still follows the system after a save", () => {
  start();
  settings.save(settings.load()); // what the options menu does when any other row changes
  game.setAccessibility({ reduceMotion: true });
  expect(settings.load().reducedEffects).toBe(null);
  expect(settings.reducedEffects()).toBe(true);
  settings.applyFeel();
  expect(feel.reduceMotion).toBe(true);
  game.setAccessibility({ reduceMotion: false });
});

test("a saved choice wins over the system", () => {
  game.setAccessibility({ textScale: 2, reduceMotion: true, screenReader: true });
  start({ textScale: 1, reducedEffects: false, readAloud: false });
  expect(ui.textScale).toBe(1);
  expect(settings.load()).toMatchObject({ textScale: 1, reducedEffects: false, readAloud: false });
  expect(feel.reduceMotion).toBe(false); // the player said no, whatever the system says
  ui.textScale = 1;
});
