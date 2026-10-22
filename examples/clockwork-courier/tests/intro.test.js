// P6, the studio intro (scenes/intro.scene.json, scripts/intro.js): plays on the first launch, ends by itself, ends early with a
// key, a click, a tap, a pad button, the Skip button and Android Back, and is not shown again on a later launch.
import { test, describe, expect, game, afterEach } from "factoria:test";
import { scene, storage } from "factoria";
import { SEEN_KEY, LENGTH, NEXT } from "../scripts/intro.js";
import config from "../factoria.json";

const INTRO = "scenes/intro.scene.json";

function launch() {
  game.load(INTRO);
  game.step(8); // a few frames in: the intro is on screen
}

describe("studio intro", () => {
  afterEach(() => storage.remove(SEEN_KEY));

  test("is the first scene of the game", () => {
    expect(config.mainScene).toBe(INTRO);
  });

  test("plays on the first launch and ends by itself at the title", () => {
    storage.remove(SEEN_KEY);
    launch();
    expect(scene.current).toBe(INTRO);
    game.step(Math.round(LENGTH * 60 * 0.8));
    expect(scene.current).toBe(INTRO);
    game.step(Math.round(LENGTH * 60 * 0.4));
    expect(scene.current).toBe(NEXT);
  });

  test("remembers that it was shown, apart from the options", () => {
    launch();
    expect(storage.get(SEEN_KEY, false)).toBe(true);
    expect(storage.get("settings", null)).toBe(null);
  });

  test("a later launch goes straight to the title", () => {
    storage.set(SEEN_KEY, true);
    game.load(INTRO);
    game.step(3);
    expect(scene.current).toBe(NEXT);
  });

  test("a key skips it", () => {
    launch();
    game.keyDown("Space");
    game.step(2);
    game.keyUp("Space");
    expect(scene.current).toBe(NEXT);
  });

  test("a mouse click skips it", () => {
    launch();
    game.click([300, 300]);
    expect(scene.current).toBe(NEXT);
  });

  test("a tap on the screen skips it", () => {
    launch();
    game.touch([300, 300], 3);
    game.step(2);
    expect(scene.current).toBe(NEXT);
  });

  test("a gamepad button skips it", () => {
    launch();
    game.gamepad().press("A");
    game.step(2);
    game.gamepad().release("A");
    expect(scene.current).toBe(NEXT);
  });

  test("the Skip button skips it", () => {
    launch();
    game.click("intro_skip");
    game.step(2);
    expect(scene.current).toBe(NEXT);
  });

  test("Android Back skips it and does not quit the game", () => {
    launch();
    game.pressBack();
    game.step(2);
    expect(scene.current).toBe(NEXT);
  });

  test("the title and studio texts come from the locale files", () => {
    launch();
    expect(game.find("intro_studio").get("Text").key).toBe("intro.studio");
    expect(game.find("intro_title").get("Text").key).toBe("intro.title");
    expect(game.find("intro_skip").get("Button").key).toBe("intro.skip");
  });
});
