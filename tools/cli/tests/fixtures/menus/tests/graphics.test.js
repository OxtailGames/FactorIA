// The graphics tab of the options (scripts/ui/options.js, scripts/settings.js): the quality button and the effect switches change
// the PostProcess fields of the scene and are saved in storage. The scene's PostProcess is added here, so the test passes in any game.
import { test, expect, game } from "factoria:test";
import { world, storage, scene } from "factoria";
import * as settings from "../scripts/settings.js";

/** Opens the options of the menu scene on the Graphics tab with a gamepad; focus is on the tab. */
function openGraphics() {
  scene.load("scenes/menu.scene.json");
  const pad = game.gamepad(0);
  game.step(2);
  world.spawn({
    id: "screen_fx",
    components: { PostProcess: { bloomEnabled: true, vignetteEnabled: true, filmGrainEnabled: false, ssaoEnabled: true } },
  });
  settings.applyPostProcess(); // as a scene's start does
  pad.tap("DpadDown"); // Options
  pad.tap("A");
  for (let i = 0; i < 4; i++) pad.tap("DpadRight"); // Audio, Controls, Language, Graphics
  pad.tap("A");
  return pad;
}

const fx = () => world.find("screen_fx").get("PostProcess");

test("graphics tab: switching an effect changes the PostProcess and is saved", () => {
  const pad = openGraphics();
  expect(fx().bloomEnabled).toBe(true);
  pad.tap("DpadDown"); // Effects quality
  pad.tap("DpadDown"); // Bloom
  pad.tap("A");
  expect(fx().bloomEnabled).toBe(false);
  expect(fx().vignetteEnabled).toBe(true); // what was not touched stays as the game made it
  expect(storage.get("settings").graphics.effects.bloom).toBe(false);
  pad.tap("A"); // and back on
  expect(fx().bloomEnabled).toBe(true);
  expect(storage.get("settings").graphics.effects.bloom).toBe(true);
  pad.tap("DpadDown"); // Film grain
  pad.tap("A"); // the game had no grain: the player turns it on
  expect(fx().filmGrainEnabled).toBe(true);
});

test("graphics tab: the quality turns the costly effects off, then gives the game's own look back", () => {
  const pad = openGraphics();
  pad.tap("DpadDown"); // Effects quality: high -> medium
  pad.tap("A");
  expect(storage.get("settings").graphics.quality).toBe("medium");
  expect(fx().ssaoEnabled).toBe(false);
  expect(fx().bloomEnabled).toBe(true);
  pad.tap("A"); // low
  expect(fx().bloomEnabled).toBe(false);
  expect(fx().vignetteEnabled).toBe(true);
  pad.tap("A"); // off
  expect(fx().vignetteEnabled).toBe(false);
  pad.tap("A"); // high again: the game's own look
  expect(storage.get("settings").graphics.quality).toBe("high");
  expect(fx().ssaoEnabled).toBe(true);
  expect(fx().bloomEnabled).toBe(true);
  expect(fx().vignetteEnabled).toBe(true);
});

test("graphics settings apply to the next scene and old saved settings still load", () => {
  storage.set("settings", { volume: { music: 0.3 }, graphics: { quality: "low", effects: { vignette: false } } });
  const s = settings.load();
  expect(s.graphics.hdr).toBe(null);
  expect(s.graphics.effects.vignette).toBe(false);
  scene.load("scenes/menu.scene.json");
  game.step(1);
  world.spawn({ id: "screen_fx", components: { PostProcess: { bloomEnabled: true, vignetteEnabled: true } } });
  settings.applyScene();
  expect(fx().bloomEnabled).toBe(false); // low
  expect(fx().vignetteEnabled).toBe(false); // the player's own switch
  storage.set("settings", { volume: { music: 0.3 } });
  expect(settings.load().graphics.quality).toBe("high"); // a save of an older kit
});
