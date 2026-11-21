// The graphics tab of the options (scripts/ui/options.js, scripts/settings.js): the quality button and the effect switches change
// the PostProcess fields of the scene and are saved in storage. The scene's PostProcess is added here, so the test passes in any game.
import { test, expect, game } from "factoria:test";
import { world, storage, scene, i18n } from "factoria";
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
  pad.tap("DpadDown"); // 2D lighting
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

const gi = () => world.find("gi_light").get("GlobalIllumination2D");

test("graphics tab: 2D lighting shows the scene's own value, then writes enabled and quality and is saved", () => {
  const pad = openGraphics();
  world.spawn({ id: "gi_light", components: { GlobalIllumination2D: { enabled: true, quality: "medium" } } });
  settings.applyScene(); // nothing chosen yet: the scene keeps its own values
  expect(gi().quality).toBe("medium");
  expect(gi().enabled).toBe(true);
  expect(settings.lightingShown()).toBe("medium");
  pad.tap("DpadDown"); // Effects quality
  pad.tap("DpadDown"); // 2D lighting: medium -> high
  pad.tap("A");
  expect(gi().quality).toBe("high");
  expect(storage.get("settings").graphics.lighting2d).toBe("high");
  pad.tap("A"); // high -> off
  expect(gi().enabled).toBe(false);
  expect(storage.get("settings").graphics.lighting2d).toBe("off");
  pad.tap("A"); // off -> low: on again
  expect(gi().enabled).toBe(true);
  expect(gi().quality).toBe("low");
});

test("graphics settings: the 2D lighting choice reaches the next scene, and a player who never chose changes nothing", () => {
  storage.set("settings", { graphics: { lighting2d: "low" } });
  scene.load("scenes/menu.scene.json");
  game.step(1);
  world.spawn({ id: "gi_light", components: { GlobalIllumination2D: { enabled: false, quality: "high" } } });
  settings.applyScene();
  expect(gi().enabled).toBe(true);
  expect(gi().quality).toBe("low");
  storage.set("settings", { volume: { music: 0.3 } });
  expect(settings.load().graphics.lighting2d).toBe(null);
  gi().enabled = false;
  gi().quality = "high";
  settings.applyScene();
  expect(gi().enabled).toBe(false); // the scene's own value stands
  expect(gi().quality).toBe("high");
  expect(settings.lightingShown()).toBe("off");
});

test("graphics settings: a phone or a browser offers Off, Low and Medium, and a saved High becomes Medium there", () => {
  expect(settings.lightingChoices("windows")).toEqual(["off", "low", "medium", "high"]);
  for (const p of ["ios", "android", "web"]) expect(settings.lightingChoices(p)).toEqual(["off", "low", "medium"]);
  const s = settings.load();
  s.graphics.lighting2d = "high";
  expect(settings.lightingChoice(s, "android")).toBe("medium");
  expect(settings.lightingChoice(s, "macos")).toBe("high");
  s.graphics.lighting2d = "low";
  expect(settings.lightingChoice(s, "ios")).toBe("low");
  s.graphics.lighting2d = null;
  expect(settings.lightingChoice(s, "ios")).toBe(null);
});

test("graphics tab: the cycle starts from what the scene shows (disabled shows Off, the next is Low)", () => {
  const pad = openGraphics();
  world.spawn({ id: "gi_light", components: { GlobalIllumination2D: { enabled: false, quality: "medium" } } });
  expect(settings.lightingShown()).toBe("off");
  pad.tap("DpadDown"); // Effects quality
  pad.tap("DpadDown"); // 2D lighting
  pad.tap("A");
  expect(gi().enabled).toBe(true);
  expect(gi().quality).toBe("low");
});

test("graphics tab: a scene without a GlobalIllumination2D says the lighting button has no effect there", () => {
  const pad = openGraphics();
  world.spawn({ id: "a_sprite", components: { Sprite: {} } }); // a 2D scene
  pad.tap("DpadDown"); // Effects quality
  pad.tap("A"); // a graphics change refreshes the tab
  const note = world.find("graphics_note");
  expect(note.active).toBe(true);
  expect(note.get("Text").text).toContain(i18n.t("options.gfx.lightNote"));
});

test("graphics tab: a scene with no sprites and no saved lighting choice (a 3D scene) shows no lighting note", () => {
  storage.set("settings", { volume: { music: 0.3 } });
  const pad = openGraphics();
  expect(settings.lightingRelevant()).toBe(false);
  pad.tap("DpadDown"); // Effects quality
  pad.tap("A");
  expect(world.find("graphics_note").get("Text").text).not.toContain(i18n.t("options.gfx.lightNote"));
});

test("graphics tab: the lighting note and the HDR note show together when both apply", () => {
  const pad = openGraphics();
  world.spawn({ id: "a_sprite", components: { Sprite: {} } });
  pad.tap("DpadDown"); // Effects quality
  pad.tap("A");
  const text = world.find("graphics_note").get("Text").text;
  expect(text).toContain(i18n.t("options.gfx.lightNote"));
  if (!settings.renderSupports("hdrOutput")) expect(text).toContain(i18n.t("options.gfx.hdrNote"));
});

test("graphics settings: a scene's own High shows as Medium where High is not offered", () => {
  storage.set("settings", { volume: { music: 0.3 } });
  world.spawn({ id: "gi_light", components: { GlobalIllumination2D: { enabled: true, quality: "high" } } });
  const shown = settings.lightingShown();
  expect(shown).toBe(settings.lightingChoices().includes("high") ? "high" : "medium");
  expect(settings.lightingChoices().includes(shown)).toBe(true);
});
