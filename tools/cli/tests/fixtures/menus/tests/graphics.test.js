// The graphics tab of the options (scripts/ui/options.js, scripts/settings.js): the quality button and the effect switches change
// the PostProcess fields of the scene and are saved in storage. The scene's PostProcess is added here, so the test passes in any game.
import { test, expect, game } from "factoria:test";
import { world, storage, scene, i18n, window, game as engine, fa } from "factoria";
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

test("graphics tab: the three notes show together when none of them is avoided (2D scene, no PostProcess, no GI, no HDR)", () => {
  storage.set("settings", { volume: { music: 0.3 } });
  settings.overrideRenderSupports(() => false);
  try {
    const pad = openGraphics();
    world.find("screen_fx").destroy(); // no PostProcess
    world.spawn({ id: "a_sprite", components: { Sprite: {} } });
    pad.tap("DpadDown"); // Effects quality
    pad.tap("A");
    const text = world.find("graphics_note").get("Text").text;
    for (const key of ["note", "lightNote", "hdrNote"]) expect(text).toContain(i18n.t(`options.gfx.${key}`));
  } finally {
    settings.overrideRenderSupports(null);
  }
});

test("graphics tab: no Sprite but a saved lighting choice still shows the lighting note", () => {
  storage.set("settings", { graphics: { lighting2d: "low" } });
  const pad = openGraphics();
  expect(settings.lightingRelevant()).toBe(true);
  pad.tap("DpadDown"); // Effects quality
  pad.tap("A");
  expect(world.find("graphics_note").get("Text").text).toContain(i18n.t("options.gfx.lightNote"));
});

test("graphics settings: a scene's own High shows as Medium where High is not offered", () => {
  storage.set("settings", { volume: { music: 0.3 } });
  world.spawn({ id: "gi_light", components: { GlobalIllumination2D: { enabled: true, quality: "high" } } });
  for (const p of ["ios", "android", "web"]) expect(settings.lightingShown(settings.load(), p)).toBe("medium");
  for (const p of ["windows", "macos", "linux"]) expect(settings.lightingShown(settings.load(), p)).toBe("high");
});

// ---------------------------------------------------------------------------------------------- the second page: preset and upscaling

/** The graphics tab with a renderer that draws every upscaler mode (settings.overrideRenderSupports), on its second page. Call restore() at the end. */
function openQuality(supports = () => true) {
  settings.overrideRenderSupports(supports);
  const pad = openGraphics();
  game.click("gfx_page");
  return pad;
}
// The third page: the low-latency rows.
function openLatency(supports = () => true) {
  const pad = openQuality(supports);
  game.click("gfx_latency_page");
  return pad;
}
// The fourth page: the frame-generation rows (from the third).
function openFrameGen(supports = () => true) {
  const pad = openLatency(supports);
  game.click("gfx_fg_page");
  return pad;
}
// The fifth page: the ray tracing rows (from the fourth).
function openRayTracing(supports = () => true) {
  const pad = openFrameGen(supports);
  game.click("gfx_rt_page");
  return pad;
}
const rayTracing = () => fa.call("render.ray_tracing");
const restore = () => {
  settings.overrideRenderSupports(null);
  fa.call("render.ray_tracing", { enabled: false, shadows: "off", ao: false, reflections: false, translucency: false, gi: "off" });
  window.upscaler = { mode: "stretch", quality: "native", sharpness: 0.5 };
  window.renderScale = 1;
  window.dynamicResolution = { enabled: false, targetMs: 0, minScale: 0.5, maxScale: 1 };
  engine.graphics.preset("custom");
  settings.setLatency({ mode: "off", boost: false });
  settings.setFrameGeneration({ mode: "off", minBaseFps: 60 });
};
const frameGen = () => fa.call("render.frame_generation");
const latency = () => fa.call("render.latency");
const saved = () => storage.get("settings").graphics;
const button = (id) => world.find(id).get("Button");

test("graphics page: the second page opens from the first and goes back, and the tab always opens on the first", () => {
  openQuality();
  try {
    expect(world.find("graphics_section").active).toBe(false);
    expect(world.find("quality_section").active).toBe(true);
    game.click("gfx_page_back");
    expect(world.find("graphics_section").active).toBe(true);
    expect(world.find("quality_section").active).toBe(false);
    game.click("gfx_page");
    game.click("gfx_latency_page"); // the third page: the low-latency rows, and back to the second
    expect(world.find("quality_section").active).toBe(false);
    expect(world.find("latency_section").active).toBe(true);
    game.click("gfx_latency_back");
    expect(world.find("quality_section").active).toBe(true);
    expect(world.find("latency_section").active).toBe(false);
    game.click("gfx_latency_page");
    game.click("gfx_fg_page"); // the fourth page: the frame-generation rows, and back to the third
    expect(world.find("latency_section").active).toBe(false);
    expect(world.find("framegen_section").active).toBe(true);
    game.click("gfx_fg_back");
    expect(world.find("latency_section").active).toBe(true);
    expect(world.find("framegen_section").active).toBe(false);
    game.click("gfx_fg_page");
    game.click("tab_video");
    game.click("tab_graphics");
    expect(world.find("graphics_section").active).toBe(true);
    expect(world.find("quality_section").active).toBe(false);
    expect(world.find("latency_section").active).toBe(false);
    expect(world.find("framegen_section").active).toBe(false);
  } finally {
    restore();
  }
});

test("graphics page: a preset applies, is saved, and drives the effects quality and the upscaler", () => {
  storage.set("settings", { graphics: { effects: { bloom: false } } });
  openQuality();
  try {
    game.click("gfx_preset_low");
    expect(engine.graphics.preset().preset).toBe("low");
    expect(saved().preset).toBe("low");
    expect(saved().quality).toBe("low"); // the preset drives the effects quality row
    expect(saved().effects).toEqual({}); // and clears the switches the player touched
    expect(fx().ssaoEnabled).toBe(false);
    expect(window.upscaler.mode).toBe("auto"); // the preset's own upscaler
    expect(window.upscaler.quality).toBe("performance");
    game.click("gfx_preset_ultra"); // the game's own look: no upscaler, the best effects quality
    expect(engine.graphics.preset().preset).toBe("ultra");
    expect(saved().quality).toBe("high");
    expect(fx().ssaoEnabled).toBe(true);
    expect(window.upscaler.mode).toBe("stretch");
    game.click("gfx_preset_medium");
    game.click("gfx_preset_custom");
    expect(engine.graphics.preset().preset).toBe("custom");
    expect(saved().preset).toBe("custom");
    expect(saved().quality).toBe("medium"); // custom leaves the effects quality alone
    expect(window.upscaler.mode).toBe("stretch"); // the game's own upscaler is back
    expect(button("gfx_preset_custom").color).toEqual(button("tab_graphics").color); // the chosen one is highlighted
  } finally {
    restore();
  }
});

test("graphics page: Auto detects once, keeps its pick, and shows it next to the button", () => {
  storage.set("settings", { volume: { music: 0.3 } });
  openQuality();
  try {
    expect(saved()?.detected ?? null).toBe(null);
    game.click("gfx_preset_auto");
    const pick = saved().detected;
    expect(["low", "medium", "high", "ultra"]).toContain(pick);
    expect(saved().preset).toBe("auto");
    expect(engine.graphics.preset().preset).toBe(pick);
    expect(button("gfx_preset_auto").text).toContain(i18n.t(`options.gfx.p.${pick}`));
    game.click("gfx_preset_custom");
    game.click("gfx_preset_auto"); // the second time reads the pick
    expect(saved().detected).toBe(pick);
    // The pick is the one used from now on: a saved pick that is not what this GPU detects shows that no detection ran.
    const other = pick === "low" ? "medium" : "low";
    storage.set("settings", { graphics: { preset: "auto", detected: other } });
    engine.graphics.preset("custom");
    settings.apply();
    expect(engine.graphics.preset().preset).toBe(other);
    expect(settings.detectPreset(settings.load())).toBe(other);
  } finally {
    restore();
  }
});

test("graphics page: the upscaling modes this GPU cannot draw are greyed out with the reason", () => {
  openQuality((feature) => feature === "spatialUpscaler");
  try {
    expect(button("gfx_mode_auto").interactable).toBe(true);
    expect(button("gfx_mode_stretch").interactable).toBe(true);
    expect(button("gfx_mode_spatial").interactable).toBe(true);
    expect(button("gfx_mode_temporal").interactable).toBe(false);
    expect(button("gfx_mode_metalfx").interactable).toBe(false);
    for (const vendor of ["dlss", "xess", "fsr"]) expect(button(`gfx_mode_${vendor}`).interactable).toBe(false); // the vendor SDK modes: this fake GPU lists none
    const note = world.find("quality_note");
    expect(note.active).toBe(true);
    expect(note.get("Text").text).toContain(i18n.t("options.gfx.um.temporal"));
    expect(note.get("Text").text).toContain(i18n.t("options.gfx.unsup.metalfx"));
    expect(note.get("Text").text).toContain(i18n.t("options.gfx.unsup.dlss"));
    expect(note.get("Text").text).not.toContain(i18n.t("options.gfx.unsup.spatial"));
    game.click("gfx_mode_temporal"); // greyed out: nothing happens
    expect(window.upscaler.mode).not.toBe("temporal");
    expect(saved().upscaler ?? {}).toEqual({});
  } finally {
    restore();
  }
});

test("graphics page: the mode, quality, render scale and sharpness apply at once and are saved", () => {
  openQuality();
  try {
    game.click("gfx_mode_spatial");
    expect(window.upscaler.mode).toBe("spatial");
    expect(saved().upscaler.mode).toBe("spatial");
    game.click("gfx_uq"); // native -> quality
    game.click("gfx_uq"); // -> balanced
    expect(window.upscaler.quality).toBe("balanced");
    expect(saved().upscaler.quality).toBe("balanced");
    expect(world.find("gfx_sharpness").active).toBe(true); // spatial sharpens
    game.setSlider("gfx_sharpness", 0.8);
    game.step(1); // the change reaches the page at the next step
    expect(window.upscaler.sharpness).toBeCloseTo(0.8, 2);
    expect(saved().upscaler.sharpness).toBeCloseTo(0.8, 2);
    game.setSlider("gfx_render_scale", 0.5);
    game.step(1);
    expect(window.renderScale).toBeCloseTo(0.5, 2);
    expect(saved().renderScale).toBeCloseTo(0.5, 2);
    expect(world.find("gfx_render_scale").get("Slider").label).toContain("50");
    game.setSlider("gfx_render_scale", 0); // the slider is clamped to the range window.renderScale accepts
    game.step(1);
    expect(window.renderScale).toBeCloseTo(0.33, 2);
    game.click("gfx_mode_stretch"); // the plain stretch has no sharpen stage
    expect(world.find("gfx_sharpness").active).toBe(false);
    expect(saved().upscaler.mode).toBe("stretch");
  } finally {
    restore();
  }
});

test("graphics page: a manual upscaler choice wins over the preset's, and picking a preset again clears it", () => {
  openQuality();
  try {
    game.click("gfx_preset_high");
    expect(window.upscaler.quality).toBe("quality");
    for (let i = 0; i < 3; i++) game.click("gfx_uq"); // quality -> balanced -> performance -> ultraPerformance
    expect(window.upscaler.quality).toBe("ultraPerformance");
    expect(engine.graphics.preset().preset).toBe("high"); // the preset row does not move
    game.click("gfx_preset_high");
    expect(saved().upscaler).toEqual({});
    expect(window.upscaler.quality).toBe("quality");
  } finally {
    restore();
  }
});

test("graphics page: the dynamic resolution row cycles off, 30 fps, 60 fps and the display's refresh, applies at once and is saved", () => {
  openQuality();
  try {
    expect(world.find("gfx_dynamic_slot").active).toBe(true);
    expect(window.dynamicResolution.enabled).toBe(false);
    expect(button("gfx_dynamic").text).toContain(i18n.t("options.gfx.dyn.off"));
    expect(saved().dynamicResolution).toBe(null); // nothing chosen yet
    game.click("gfx_dynamic");
    expect(window.dynamicResolution.enabled).toBe(true);
    expect(window.dynamicResolution.targetMs).toBeCloseTo(1000 / 30, 2);
    expect(saved().dynamicResolution).toBe("30");
    expect(button("gfx_dynamic").text).toContain(i18n.t("options.gfx.dyn.30"));
    game.click("gfx_dynamic");
    expect(window.dynamicResolution.targetMs).toBeCloseTo(1000 / 60, 2);
    expect(saved().dynamicResolution).toBe("60");
    game.click("gfx_dynamic");
    expect(window.dynamicResolution.enabled).toBe(true);
    expect(window.dynamicResolution.targetMs).toBe(0); // follows the display
    expect(saved().dynamicResolution).toBe("display");
    expect(window.dynamicResolution.minScale).toBe(0.5); // the game's own range is kept
    game.click("gfx_dynamic");
    expect(window.dynamicResolution.enabled).toBe(false);
    expect(saved().dynamicResolution).toBe("off");
    expect(button("gfx_dynamic").text).toContain(i18n.t("options.gfx.dyn.off"));
  } finally {
    restore();
  }
});

test("graphics page: a game that turned dynamic resolution on itself shows it, and a row is hidden where the renderer cannot do it", () => {
  storage.set("settings", {}); // the player chose nothing
  window.dynamicResolution = { enabled: true, targetMs: 25 };
  openQuality();
  try {
    expect(button("gfx_dynamic").text).toContain(i18n.t("options.gfx.dyn.custom"));
    game.click("gfx_dynamic"); // custom -> the first choice, off
    expect(window.dynamicResolution.enabled).toBe(false);
    expect(saved().dynamicResolution).toBe("off");
  } finally {
    restore();
  }
  openQuality((feature) => feature !== "dynamicResolution");
  try {
    expect(world.find("gfx_dynamic_slot").active).toBe(false);
  } finally {
    restore();
  }
});

test("graphics settings: the saved dynamic resolution applies at the start, and an old save changes nothing", () => {
  try {
    storage.set("settings", { graphics: { quality: "low" } }); // a save of an older kit
    expect(settings.load().graphics.dynamicResolution).toBe(null);
    window.dynamicResolution = { enabled: true, targetMs: 25 }; // what the game set
    settings.apply();
    expect(window.dynamicResolution.enabled).toBe(true);
    expect(window.dynamicResolution.targetMs).toBe(25); // untouched
    storage.set("settings", { graphics: { dynamicResolution: "60" } });
    settings.apply();
    expect(window.dynamicResolution.enabled).toBe(true);
    expect(window.dynamicResolution.targetMs).toBeCloseTo(1000 / 60, 2);
    storage.set("settings", { graphics: { dynamicResolution: "off" } });
    settings.apply();
    expect(window.dynamicResolution.enabled).toBe(false);
    storage.set("settings", { graphics: { dynamicResolution: "bogus" } }); // a save this kit does not know: ignored
    window.dynamicResolution = { enabled: true, targetMs: 25 };
    settings.apply();
    expect(window.dynamicResolution.targetMs).toBe(25);
  } finally {
    restore();
  }
});

test("graphics page: manual -> preset -> custom saves the upscaler the engine puts back, and the next start draws it", () => {
  openQuality();
  try {
    game.click("gfx_mode_spatial");
    expect(saved().upscaler.mode).toBe("spatial");
    game.click("gfx_preset_low");
    expect(saved().upscaler).toEqual({});
    game.click("gfx_preset_custom");
    expect(window.upscaler.mode).toBe("spatial"); // the engine restored the game's own setting
    expect(saved().upscaler.mode).toBe("spatial"); // ...and the save says the same
    // The next start: the engine begins from the project's upscaler and the kit applies the save.
    window.upscaler = { mode: "stretch", quality: "native", sharpness: 0.5 };
    engine.graphics.preset("custom");
    settings.apply();
    expect(window.upscaler.mode).toBe("spatial");
    expect(engine.graphics.preset().preset).toBe("custom");
  } finally {
    restore();
  }
});

test("graphics settings: the saved preset, upscaler and render scale apply at the start, and an old save changes nothing", () => {
  storage.set("settings", { graphics: { preset: "medium", upscaler: { mode: "spatial", sharpness: 0.3 }, renderScale: 0.75 } });
  try {
    expect(settings.load().graphics.detected).toBe(null);
    settings.apply();
    expect(engine.graphics.preset().preset).toBe("medium");
    expect(window.upscaler.mode).toBe("spatial"); // the player's own key wins over the preset's "auto"
    expect(window.upscaler.quality).toBe("balanced"); // the preset's
    expect(window.upscaler.sharpness).toBeCloseTo(0.3, 2);
    expect(window.renderScale).toBeCloseTo(0.75, 2);
    // A save of an older kit has none of the keys: nothing is touched.
    window.upscaler = { mode: "stretch", quality: "native", sharpness: 0.5 };
    window.renderScale = 1;
    engine.graphics.preset("custom");
    storage.set("settings", { volume: { music: 0.3 }, graphics: { quality: "low", effects: {} } });
    const g = settings.load().graphics;
    expect([g.preset, g.detected, g.renderScale]).toEqual([null, null, null]);
    expect(g.upscaler).toEqual({});
    settings.apply();
    expect(engine.graphics.preset().preset).toBe("custom");
    expect(window.upscaler.mode).toBe("stretch");
    expect(window.renderScale).toBe(1);
  } finally {
    restore();
  }
});

test("graphics page: the texts are in the game's language", () => {
  if (!i18n.languages.includes("es")) return; // a game with one language: nothing to check
  openQuality();
  try {
    i18n.setLanguage("es");
    game.step(2);
    expect(world.find("gfx_preset_label").get("Text").text).toContain("Preset");
    expect(button("gfx_preset_low").text).toBe("Bajo");
    expect(button("gfx_page_back").text).toBe("Efectos de pantalla");
    expect(button("gfx_latency_page").text).toBe("Baja latencia");
    expect(button("gfx_uq").text).toContain("Calidad del escalado");
    expect(world.find("gfx_latency_label").get("Text").text).toContain("Baja latencia");
    expect(button("gfx_latency_off").text).toBe("No");
    game.click("gfx_latency_page");
    expect(button("gfx_fg_page").text).toBe("Generación de fotogramas");
    game.click("gfx_fg_page");
    expect(world.find("gfx_fg_label").get("Text").text).toContain("Generación de fotogramas");
    expect(button("gfx_fg_off").text).toBe("No");
  } finally {
    i18n.setLanguage("en");
    restore();
  }
});

// ---------------------------------------------------------------------------------------------- the low-latency rows (render.latency)

test("graphics page: the low-latency modes this machine cannot run are greyed out with the reason, the others apply at once and are saved", () => {
  openLatency((feature) => feature === "xell"); // this fake machine can run XeLL only
  try {
    expect(latency().mode).toBe("off");
    expect(world.find("gfx_latency_boost").active).toBe(false); // off has no boost
    expect(button("gfx_latency_off").interactable).toBe(true);
    expect(button("gfx_latency_auto").interactable).toBe(true);
    expect(button("gfx_latency_xell").interactable).toBe(true);
    expect(button("gfx_latency_reflex").interactable).toBe(false);
    expect(button("gfx_latency_antilag2").interactable).toBe(false);
    const note = world.find("latency_note").get("Text").text;
    expect(note).toContain(i18n.t("options.gfx.latm.reflex"));
    expect(note).toContain(i18n.t("options.gfx.latunsup.antilag2"));
    expect(note).not.toContain(i18n.t("options.gfx.latm.xell"));
    game.click("gfx_latency_reflex"); // greyed out: nothing happens
    expect(latency().mode).toBe("off");
    expect(saved().latency ?? {}).toEqual({});
    game.click("gfx_latency_xell");
    expect(latency().mode).toBe("xell");
    expect(saved().latency).toEqual({ mode: "xell" });
    expect(world.find("gfx_latency_boost").active).toBe(true);
    expect(button("gfx_latency_xell").color).toEqual(button("tab_graphics").color); // the chosen one is highlighted
    expect(world.find("gfx_latency_label").get("Text").text).toContain(i18n.t("options.gfx.latm.xell"));
    game.click("gfx_latency_boost");
    expect(latency().boost).toBe(true);
    expect(saved().latency).toEqual({ mode: "xell", boost: true });
    game.click("gfx_latency_auto");
    expect(latency().mode).toBe("auto");
    expect(latency().boost).toBe(true); // auto may pick an SDK that has a boost: it keeps the choice
    game.click("gfx_latency_off");
    expect(latency().mode).toBe("off");
    expect(latency().boost).toBe(false); // off has no boost switch: it is dropped
    expect(saved().latency).toEqual({ mode: "off", boost: false });
    expect(world.find("gfx_latency_boost").active).toBe(false);
  } finally {
    restore();
  }
});

test("graphics page: where no renderer can be asked the SDK modes are greyed out and auto and off still work", () => {
  openLatency(() => false);
  try {
    for (const mode of ["reflex", "antilag2", "xell"]) expect(button(`gfx_latency_${mode}`).interactable).toBe(false);
    game.click("gfx_latency_auto");
    expect(latency().mode).toBe("auto");
    expect(saved().latency.mode).toBe("auto");
    // This run has no game window to pace, so the page says the mode runs as nothing (render.latency's driver).
    expect(world.find("gfx_latency_label").get("Text").text).toContain(i18n.t(`options.gfx.latd.${latency().driver}`));
  } finally {
    restore();
  }
});

test("graphics settings: the saved low-latency mode applies at the start, and an old save changes nothing", () => {
  storage.set("settings", { graphics: { latency: { mode: "auto", boost: true } } });
  try {
    expect(settings.load().graphics.latency).toEqual({ mode: "auto", boost: true });
    settings.apply();
    expect(latency().mode).toBe("auto");
    expect(latency().boost).toBe(true);
    // A save of an older kit has no latency key: the game's own setting stays.
    settings.setLatency({ mode: "antilag2", boost: false });
    storage.set("settings", { volume: { music: 0.3 }, graphics: { quality: "low", effects: {} } });
    expect(settings.load().graphics.latency).toEqual({});
    settings.apply();
    expect(latency().mode).toBe("antilag2");
  } finally {
    restore();
  }
});

// ---------------------------------------------------------------------------------------------- the frame-generation rows (render.frameGeneration)

test("graphics page: the frame-generation SDKs this machine cannot run are greyed out with the reason, the others apply at once and are saved", () => {
  openFrameGen((feature) => feature === "fsrFrameGen"); // this fake machine can run FSR 3 frame generation only
  try {
    expect(frameGen().mode).toBe("off");
    expect(world.find("gfx_fg_minfps").active).toBe(false); // nothing to switch off
    expect(world.find("framegen_note").get("Text").text).not.toContain(i18n.t("options.gfx.fgHint")); // off: no advice
    expect(button("gfx_fg_off").interactable).toBe(true);
    expect(button("gfx_fg_auto").interactable).toBe(true);
    expect(button("gfx_fg_fsr").interactable).toBe(true);
    expect(button("gfx_fg_dlss").interactable).toBe(false);
    expect(button("gfx_fg_xess").interactable).toBe(false);
    const note = world.find("framegen_note").get("Text").text;
    expect(note).toContain(i18n.t("options.gfx.fgm.dlss"));
    expect(note).toContain(i18n.t("options.gfx.fgunsup.xess"));
    expect(note).not.toContain(i18n.t("options.gfx.fgunsup.fsr"));
    game.click("gfx_fg_dlss"); // greyed out: nothing happens
    expect(frameGen().mode).toBe("off");
    expect(saved().frameGeneration ?? {}).toEqual({});
    game.click("gfx_fg_fsr");
    expect(frameGen().mode).toBe("fsr");
    expect(saved().frameGeneration).toEqual({ mode: "fsr" });
    expect(world.find("gfx_fg_minfps").active).toBe(true);
    expect(button("gfx_fg_fsr").color).toEqual(button("tab_graphics").color); // the chosen one is highlighted
    expect(world.find("gfx_fg_label").get("Text").text).toContain(i18n.t("options.gfx.fgm.fsr"));
    // This run has no game window, so nothing is generated and the note says it, and that a low-latency mode is recommended.
    const running = world.find("framegen_note").get("Text").text;
    expect(running).toContain(i18n.t("options.gfx.fgRefused"));
    expect(running).toContain(i18n.t("options.gfx.fgHint"));
    game.click("gfx_fg_off");
    expect(frameGen().mode).toBe("off");
    expect(saved().frameGeneration).toEqual({ mode: "off" });
  } finally {
    restore();
  }
});

test("graphics page: the minimum base frame rate is saved, 0 never switches off, and a low-latency mode takes the advice away", () => {
  openFrameGen();
  try {
    game.click("gfx_fg_auto");
    expect(frameGen().minBaseFps).toBe(60);
    expect(world.find("gfx_fg_minfps").get("Slider").label).toBe(i18n.t("options.gfx.fgMinFps", { fps: 60 }));
    game.setSlider("gfx_fg_minfps", 45);
    game.step(1); // the change reaches the page at the next step
    expect(frameGen().minBaseFps).toBe(45);
    expect(saved().frameGeneration).toEqual({ mode: "auto", minBaseFps: 45 });
    game.setSlider("gfx_fg_minfps", 0);
    game.step(1); // the change reaches the page at the next step
    expect(frameGen().minBaseFps).toBe(0);
    expect(world.find("gfx_fg_minfps").get("Slider").label).toBe(i18n.t("options.gfx.fgMinFpsNever"));
    expect(world.find("framegen_note").get("Text").text).toContain(i18n.t("options.gfx.fgHint"));
    settings.setLatency({ mode: "auto" }); // a low-latency mode is on
    game.click("gfx_fg_dlss"); // any change refreshes the page
    expect(world.find("framegen_note").get("Text").text).not.toContain(i18n.t("options.gfx.fgHint"));
    settings.setLatency({ mode: "off" });
    game.click("gfx_fg_dlss");
    expect(world.find("framegen_note").get("Text").text).toContain(i18n.t("options.gfx.fgHintDlss")); // DLSS turns Reflex on itself, and says so
  } finally {
    restore();
  }
});

test("graphics settings: the saved frame generation applies at the start, and an old save changes nothing", () => {
  storage.set("settings", { graphics: { frameGeneration: { mode: "auto", minBaseFps: 90 } } });
  try {
    expect(settings.load().graphics.frameGeneration).toEqual({ mode: "auto", minBaseFps: 90 });
    settings.apply();
    expect(frameGen().mode).toBe("auto");
    expect(frameGen().minBaseFps).toBe(90);
    // A save of an older kit has no frameGeneration key: the game's own setting stays.
    settings.setFrameGeneration({ mode: "fsr", minBaseFps: 30 });
    storage.set("settings", { volume: { music: 0.3 }, graphics: { quality: "low", effects: {} } });
    expect(settings.load().graphics.frameGeneration).toEqual({});
    settings.apply();
    expect(frameGen().mode).toBe("fsr");
    expect(frameGen().minBaseFps).toBe(30);
  } finally {
    restore();
  }
});

// ---------------------------------------------------------------------------------------------- the ray tracing rows (render.rayTracing)

test("graphics page: the ray tracing page opens from the frame generation page and goes back", () => {
  openFrameGen();
  try {
    game.click("gfx_rt_page");
    expect(world.find("framegen_section").active).toBe(false);
    expect(world.find("raytracing_section").active).toBe(true);
    game.click("gfx_rt_back");
    expect(world.find("framegen_section").active).toBe(true);
    expect(world.find("raytracing_section").active).toBe(false);
    game.click("gfx_rt_page");
    game.click("tab_video");
    game.click("tab_graphics");
    expect(world.find("graphics_section").active).toBe(true);
    expect(world.find("raytracing_section").active).toBe(false);
  } finally {
    restore();
  }
});

test("graphics page: ray tracing turns on at the preset's tier, the quality cycles high and ultra, and both are saved", () => {
  storage.set("settings", {}); // no choice saved by an earlier test
  openRayTracing((feature) => feature === "raytracing");
  try {
    expect(rayTracing().enabled).toBe(false);
    expect(world.find("gfx_rt_enabled").get("Toggle").interactable).toBe(true);
    expect(button("gfx_rt_quality").interactable).toBe(false); // nothing to choose while it is off
    expect(world.find("raytracing_note").active).toBe(false);
    game.click("gfx_rt_enabled");
    // engine.graphics.preset("custom") in force: no limit, so the default quality is ultra and its effects are on
    expect(rayTracing().enabled).toBe(true);
    expect(rayTracing().shadows).toBe("soft");
    expect(rayTracing().reflections).toBe(true);
    expect(rayTracing().gi).toBe("probes");
    expect(saved().rayTracing).toEqual({ enabled: true, quality: "ultra" });
    expect(button("gfx_rt_quality").interactable).toBe(true);
    expect(button("gfx_rt_quality").text).toContain(i18n.t("options.gfx.rtq.ultra"));
    expect(world.find("raytracing_note").get("Text").text).toContain(i18n.t("options.gfx.rtTier.ultra"));
    game.click("gfx_rt_quality");
    expect(rayTracing().shadows).toBe("hard");
    expect(rayTracing().ao).toBe(true);
    expect(rayTracing().reflections).toBe(false);
    expect(rayTracing().translucency).toBe(false);
    expect(rayTracing().gi).toBe("off");
    expect(saved().rayTracing).toEqual({ enabled: true, quality: "high" });
    expect(world.find("raytracing_note").get("Text").text).toContain(i18n.t("options.gfx.rtTier.high"));
    game.click("gfx_rt_quality");
    expect(rayTracing().shadows).toBe("soft");
    game.click("gfx_rt_enabled");
    expect(rayTracing().enabled).toBe(false);
    expect(saved().rayTracing.enabled).toBe(false);
    expect(world.find("gfx_rt_label").get("Text").text).toContain(i18n.t("options.gfx.rtOff"));
  } finally {
    restore();
  }
});

test("graphics page: the graphics preset caps ray tracing and the page says so", () => {
  storage.set("settings", {}); // no choice saved by an earlier test
  openRayTracing((feature) => feature === "raytracing");
  try {
    engine.graphics.preset("high");
    game.click("gfx_rt_enabled"); // the High preset's tier is the default
    expect(saved().rayTracing).toEqual({ enabled: true, quality: "high" });
    game.click("gfx_rt_quality"); // the player asks for ultra: the preset keeps hard shadows and ambient occlusion
    expect(rayTracing().shadows).toBe("soft");
    expect(rayTracing().presetCap.capped).toBe(true);
    expect(rayTracing().presetCap.effective.shadows).toBe("hard");
    expect(rayTracing().presetCap.effective.reflections).toBe(false);
    expect(world.find("raytracing_note").get("Text").text).toContain(i18n.t("options.gfx.rtCap.high", { preset: i18n.t("options.gfx.p.high") }));
    engine.graphics.preset("low"); // low traces nothing
    game.click("gfx_rt_quality");
    expect(world.find("raytracing_note").get("Text").text).toContain(i18n.t("options.gfx.rtCap.none", { preset: i18n.t("options.gfx.p.low") }));
    engine.graphics.preset("ultra"); // a preset never turns ray tracing on, and ultra caps nothing
    game.click("gfx_rt_quality");
    expect(rayTracing().presetCap.capped).toBe(false);
    expect(world.find("raytracing_note").get("Text").text).not.toContain(i18n.t("options.gfx.rtCap.high", { preset: i18n.t("options.gfx.p.ultra") }));
  } finally {
    restore();
  }
});

test("graphics page: a device that cannot trace rays greys the rows out and says why", () => {
  storage.set("settings", {}); // no choice saved by an earlier test
  openRayTracing(() => false);
  try {
    expect(world.find("gfx_rt_enabled").get("Toggle").interactable).toBe(false);
    expect(button("gfx_rt_quality").interactable).toBe(false);
    const note = world.find("raytracing_note").get("Text").text;
    expect(note).toContain(i18n.t("options.gfx.rtUnsupported"));
    expect(note).toContain("graphics.backend");
    game.click("gfx_rt_enabled"); // greyed out: nothing happens
    expect(rayTracing().enabled).toBe(false);
    expect(saved()?.rayTracing ?? {}).toEqual({});
  } finally {
    restore();
  }
});

test("graphics settings: the saved ray tracing applies at the start, and an old save changes nothing", () => {
  storage.set("settings", { graphics: { rayTracing: { enabled: true, quality: "high" } } });
  try {
    expect(settings.load().graphics.rayTracing).toEqual({ enabled: true, quality: "high" });
    settings.apply();
    expect(rayTracing().enabled).toBe(true);
    expect(rayTracing().shadows).toBe("hard");
    expect(rayTracing().reflections).toBe(false);
    // A save of an older kit has no rayTracing key: the game's own setting stays.
    fa.call("render.ray_tracing", { enabled: false, shadows: "soft" });
    storage.set("settings", { volume: { music: 0.3 }, graphics: { quality: "low", effects: {} } });
    expect(settings.load().graphics.rayTracing).toEqual({});
    settings.apply();
    expect(rayTracing().enabled).toBe(false);
    expect(rayTracing().shadows).toBe("soft");
  } finally {
    restore();
  }
});
