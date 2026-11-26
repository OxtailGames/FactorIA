// @ts-check
// The player's settings (volumes, video, interface size, colour filter, controls, language), kept in storage under "settings" and applied once per run.
// scripts/ui/options.js edits them; main_menu.js and pause_menu.js call applyOnce() when their scene starts.
import { storage, audio, window, input, session, i18n, world, ui, game, feel, scene, fa } from "factoria";

/** Audio buses the options menu shows, in order. */
export const BUSES = ["master", "music", "sfx", "ui"];

/**
 * Speeds of the dialogue text, in characters per second (0 = a whole line at once): the choices of the options "Text speed" row
 * (project.add_menu_kit with textSpeed: true) and the locale name `options.speed.<name>`. settings.load().textSpeed is the chosen
 * speed; the game's dialogue box reveals a line with Text.visibleCharacters = revealedCharacters(seconds).
 */
export const TEXT_SPEEDS = [
  { name: "slow", cps: 20 },
  { name: "normal", cps: 45 },
  { name: "fast", cps: 90 },
  { name: "instant", cps: 0 },
];

/** Values of PostProcess.colorFilterMode the options menu cycles through (accessibility: the last post-process of the frame). */
export const COLOR_FILTERS = ["none", "greyscale", "highContrast", "protanopia", "deuteranopia", "tritanopia"];

/** The qualities of the "Effects quality" row of the graphics tab, best first. "high" leaves the game's own screen effects as they are. */
export const GRAPHICS_QUALITIES = ["high", "medium", "low", "off"];

/** The choices of the "2D lighting" row of the graphics tab, off first: they set GlobalIllumination2D.enabled and .quality. */
export const LIGHTING_QUALITIES = ["off", "low", "medium", "high"];

/**
 * The choices of the "2D lighting" row on `platform`: the engine's budget for the GI cascades turns "high" off on a phone and in a
 * browser (docs/rendering/RENDERING_2D_GI.md), so game.platform "ios", "android" and "web" offer Off, Low and Medium only.
 */
export function lightingChoices(platform = game.platform) {
  const budgeted = platform === "ios" || platform === "android" || platform === "web";
  return budgeted ? LIGHTING_QUALITIES.filter((q) => q !== "high") : LIGHTING_QUALITIES;
}

/** The player's saved "2D lighting" choice as this platform can apply it ("high" becomes "medium" where it is not offered), or null. */
export function lightingChoice(s = load(), platform = game.platform) {
  const choice = s.graphics.lighting2d;
  if (!LIGHTING_QUALITIES.includes(choice)) return null;
  return lightingChoices(platform).includes(choice) ? choice : "medium";
}

/**
 * The choices of the "Preset" row of the graphics tab's second page (docs/UPSCALING.md, "Graphics presets"): "auto" asks game.graphics.detect()
 * once and keeps its pick (settings.graphics.detected), "custom" is no preset (the game's own look), the rest are game.graphics.preset(name).
 */
export const GRAPHICS_PRESETS = ["auto", "low", "medium", "high", "ultra", "custom"];

/** What game.graphics.detect() can pick. */
const DETECTED = ["low", "medium", "high", "ultra"];

/** The "Effects quality" a preset sets when the player picks it ("ultra" is the game's own look, like "high"); "custom" leaves the quality alone. */
export const PRESET_QUALITY = { low: "low", medium: "medium", high: "high", ultra: "high" };

/** The modes of the "Upscaling" row (window.upscaler.mode) and the choices of its quality row (window.upscaler.quality), best picture first. */
export const UPSCALER_MODES = ["auto", "stretch", "spatial", "temporal", "metalfx", "dlss", "xess", "fsr"];
export const UPSCALER_QUALITIES = ["native", "quality", "balanced", "performance", "ultraPerformance"];

/** render.supports feature that tells whether this GPU draws each upscaler mode ("auto" and "stretch" always work). */
const MODE_FEATURE = { spatial: "spatialUpscaler", temporal: "temporalUpscaler", metalfx: "metalfx", dlss: "dlss", xess: "xess", fsr: "fsr" };

/** The modes of the "Low latency" row (render.latency, docs/LATENCY.md), and the render.supports feature that tells whether this machine can run each SDK ("off" and "auto" always work: auto falls back to the engine's own pacing). */
export const LATENCY_MODES = ["off", "auto", "reflex", "antilag2", "xell"];
const LATENCY_FEATURE = { reflex: "reflex", antilag2: "antilag2", xell: "xell" };
/** The modes that have a boost switch (the SDKs that keep the GPU clocks up while the game waits; auto may pick one of them). */
const LATENCY_BOOST = ["auto", "reflex", "xell"];

/** The modes of the "Frame generation" row (render.frameGeneration, docs/FRAME_GENERATION.md), and the render.supports feature that tells whether this machine can run each SDK ("off" and "auto" always work: auto runs nothing where no SDK can). */
export const FRAMEGEN_MODES = ["off", "auto", "dlss", "fsr", "xess"];
const FRAMEGEN_FEATURE = { dlss: "dlssFrameGen", fsr: "fsrFrameGen", xess: "xessFrameGen" };
/** The range of the "Minimum base fps" slider (the engine takes 0 to 1000): the frame rate the game renders at, below which generation switches off. */
export const FRAMEGEN_MIN_FPS_MAX = 240;
export const FRAMEGEN_DEFAULT_MIN_FPS = 60;

/**
 * The "Ray tracing" row (render.rayTracing, docs/RAY_TRACING.md): off or on, and a quality that follows the graphics presets' tiers (docs/UPSCALING.md, "Graphics presets"): "high" traces hard shadows and ambient occlusion
 * (what the High preset allows), "ultra" soft shadows, ambient occlusion, reflections, glass refraction and the global illumination probes (what Ultra allows). RAYTRACING_TIERS are the keys of render.ray_tracing each one sets.
 * The graphics preset caps what is drawn and never turns an effect on (rayTracingState().capped says so); a device that cannot trace (render.supports "raytracing") draws none of it.
 */
export const RAYTRACING_QUALITIES = ["high", "ultra"];
export const RAYTRACING_TIERS = {
  high: { shadows: "hard", ao: true, reflections: false, translucency: false, gi: "off" },
  ultra: { shadows: "soft", ao: true, reflections: true, translucency: true, gi: "probes" },
};

/** The range window.renderScale accepts (a third of the window to all of it). */
export const RENDER_SCALE_MIN = 0.33;
export const RENDER_SCALE_MAX = 1;

/**
 * The dynamic resolution row's choices (window.dynamicResolution, docs/UPSCALING.md): off, or on holding a frame time of 30 fps, 60 fps or one refresh of
 * the display. The "off" row leaves the fixed render scale; "custom" is only ever shown (the game set another target itself), never saved.
 */
export const DYNAMIC_CHOICES = ["off", "30", "60", "display"];
const DYNAMIC_TARGET_MS = { 30: 1000 / 30, 60: 1000 / 60, display: 0 };

/** The choice in force: the one the player saved, else what window.dynamicResolution says ("custom": on with a target that is none of the three). */
export function dynamicChoice(s = load()) {
  const saved = s.graphics.dynamicResolution;
  if (DYNAMIC_CHOICES.includes(saved)) return saved;
  const d = window.dynamicResolution;
  if (!d.enabled) return "off";
  if (d.targetMs === 0) return "display";
  return Math.abs(d.targetMs - 1000 / 30) < 0.5 ? "30" : Math.abs(d.targetMs - 1000 / 60) < 0.5 ? "60" : "custom";
}

/** Puts a choice into the engine (it keeps the game's minScale and maxScale); the engine rejects a bad one with an error that says why. */
export function applyDynamicChoice(choice) {
  window.dynamicResolution = { enabled: choice !== "off", targetMs: DYNAMIC_TARGET_MS[choice] ?? 0 };
}

/** The main screen effects the graphics tab switches one by one: `id` is the key in settings.graphics.effects, `field` the PostProcess field. */
export const GRAPHICS_EFFECTS = [
  { id: "bloom", field: "bloomEnabled" },
  { id: "grain", field: "filmGrainEnabled" },
  { id: "vignette", field: "vignetteEnabled" },
  { id: "chromatic", field: "chromaticAberrationEnabled" },
  { id: "outline", field: "outlineEnabled" },
];

// The PostProcess switches each quality below "high" turns off (the costly ones first); the effects that shape the picture itself
// (exposure, tonemap, grading, the colour filter, fog) are never touched.
const EXPENSIVE = ["ssaoEnabled", "ssrEnabled", "depthOfFieldEnabled", "motionBlurEnabled", "sunShaftsEnabled", "radialBlurEnabled"];
const QUALITY_OFF = {
  high: [],
  medium: EXPENSIVE,
  low: [...EXPENSIVE, "bloomEnabled", "filmGrainEnabled", "lensDistortionEnabled", "sharpenEnabled"],
  off: [...EXPENSIVE, ...GRAPHICS_EFFECTS.map((e) => e.field), "lensDistortionEnabled", "sharpenEnabled", "pixelateEnabled", "posterizeEnabled"],
};
const POST_FIELDS = [...new Set(Object.values(QUALITY_OFF).flat())];

/**
 * What a player who never chose gets. The accessibility ones start from the system's settings (game.accessibility): they
 * follow the system on every run until the player saves their own choice (save() stores all the settings), which then wins.
 */
function defaults() {
  const system = game.accessibility;
  return {
    volume: { master: 1, music: 0.6, sfx: 1, ui: 1 },
    windowMode: null, // "windowed" | "borderless" | "fullscreen", or null: keep factoria.json display.fullscreen
    monitor: null, // { index, name } of the monitor the player chose (see monitorChoice), or null: where the OS opens the window
    resolution: null, // [width, height] of the window, or null: the factoria.json size
    vsync: null, // null: keep factoria.json display.vsync
    frameCap: 0, // 0 = no cap
    colorFilter: "none", // one of COLOR_FILTERS
    bindings: {}, // action -> binding names, only for actions the player rebound
    playerBindings: {}, // player ("0"."3") -> input.player(i).export(), only for a game with several local players (options.js `players`)
    language: null, // null: the language the game started in (the player's system language, else the default one)
    readAloud: system.screenReader, // say the focused menu widget with text to speech (scripts/ui/read_aloud.js)
    textScale: system.textScale, // the text size, 1 = 100 % (ui.textScale)
    uiScale: null, // the interface size (ui.scale), or null: keep the factoria.json ui.scale
    reducedEffects: null, // less screen shake, flashes and particles: null follows the system's reduce motion until the player chooses, true / false is their choice (reducedEffects(s) says which one is in force)
    subtitles: true, // show captions (the "captions" entity, a Captions component); off = that entity is inactive
    textSpeed: system.reduceMotion ? 0 : 45, // dialogue text reveal in characters per second (TEXT_SPEEDS), 0 = a whole line at once
    // Screen effects (PostProcess): quality is one of GRAPHICS_QUALITIES; effects holds only the switches the player touched
    // (GRAPHICS_EFFECTS id -> true / false, which win over the quality); hdr is null (the scene's SceneSettings.hdrOutput) or the player's choice.
    // lighting2d is null (every GlobalIllumination2D keeps the scene's own enabled and quality) or the player's choice, one of LIGHTING_QUALITIES.
    // The second page of the tab (docs/MENUS.md): preset is null (the engine keeps its own, the project's render.graphicsPreset) or one of GRAPHICS_PRESETS;
    // detected is the pick of game.graphics.detect() ("auto" asks once, here), null until it ran; upscaler holds only the keys of window.upscaler the player
    // set (mode, quality, sharpness: they win over what a preset writes); renderScale is null (full size) or window.renderScale;
    // dynamicResolution is null (the game's own: window.dynamicResolution, off by default) or one of DYNAMIC_CHOICES;
    // latency holds only the keys of render.latency the player set (mode, boost), like upscaler: {} keeps the game's own (factoria.json render.latency, off by default);
    // frameGeneration the same for render.frameGeneration (mode, minBaseFps); rayTracing for render.rayTracing, as { enabled, quality } (one of RAYTRACING_QUALITIES; the keys the player touched).
    graphics: { quality: "high", effects: {}, hdr: null, lighting2d: null, preset: null, detected: null, upscaler: {}, renderScale: null, dynamicResolution: null, latency: {}, frameGeneration: {}, rayTracing: {} },
  };
}

/** The saved settings merged over the defaults (a fresh object each call). */
export function load() {
  const saved = storage.get("settings", {});
  if (saved.windowMode === undefined && typeof saved.fullscreen === "boolean") saved.windowMode = saved.fullscreen ? "fullscreen" : "windowed"; // saved by an older kit
  const base = defaults();
  return {
    ...base,
    ...saved,
    volume: { ...base.volume, ...saved.volume },
    bindings: { ...saved.bindings },
    playerBindings: { ...saved.playerBindings },
    graphics: { ...base.graphics, ...saved.graphics, effects: { ...saved.graphics?.effects }, upscaler: { ...saved.graphics?.upscaler }, latency: { ...saved.graphics?.latency }, frameGeneration: { ...saved.graphics?.frameGeneration }, rayTracing: { ...saved.graphics?.rayTracing } },
  };
}

/** The value for Text.visibleCharacters of a dialogue line `seconds` after it appeared, at the player's text speed: -1 (everything) when the speed is 0. */
export function revealedCharacters(seconds, s = load()) {
  return s.textSpeed > 0 ? Math.floor(seconds * s.textSpeed) : -1;
}

export function save(s) {
  storage.set("settings", s);
}

/** What save() stores for the monitor `index` of window.monitors(): its name too, because the numbers change when a monitor is unplugged. */
export function monitorChoice(index) {
  return { index, name: window.monitors()[index]?.name ?? "" };
}

/** The index in window.monitors() of the monitor the player chose: the same name (the same place when several share it), or -1 when it is not connected now. */
function savedMonitorIndex(choice) {
  const same = window.monitors().filter((m) => m.name === choice.name);
  return same.length ? (same.find((m) => m.index === choice.index) ?? same[0]).index : -1;
}

/**
 * PostProcess colour filter on the scene's camera (the entity with the id "camera"): every scene has its own camera,
 * so each scene sets it again. A scene without a PostProcess on its camera gets one when the player picks a filter.
 */
export function applyColorFilter(s = load()) {
  const camera = world.find("camera");
  if (!camera || (s.colorFilter === "none" && !camera.has("PostProcess"))) return;
  camera.set("PostProcess", { colorFilterEnabled: s.colorFilter !== "none", colorFilterMode: s.colorFilter });
}

/** Captions follow the "Subtitles" option by switching the scene's "captions" entity on or off. The game keeps calling audio.play({ caption }) and ui.caption(): they are tracked while hidden. */
export function applySubtitles(s = load()) {
  const captions = world.find("captions");
  if (captions) captions.active = s.subtitles;
}

let supportsOverride = null;

/** For tests: answer renderSupports(feature) with `fn(feature)` instead of asking the renderer; null puts the renderer back. */
export function overrideRenderSupports(fn) {
  supportsOverride = fn;
}

/** Whether this renderer can do `feature` (render.supports: "hdrOutput", "bloom", ...); false when there is no renderer to ask (tests without graphics). */
export function renderSupports(feature) {
  if (supportsOverride) return supportsOverride(feature) === true;
  try {
    return fa.call("render.supports", { feature }).supported === true;
  } catch {
    return false;
  }
}

/** What the scene's PostProcess components had before this module changed them: scene generation, then per entity id { authored, forced }. */
let post = { generation: -1, entities: new Map() };

/** The entities of the scene that have a PostProcess (the camera's own stack and the volumes). */
export function postProcessEntities() {
  return world.entities().filter((e) => e.has("PostProcess"));
}

/** The PostProcess switch `field` as the player's settings `s` want it, given what the game authored (`authored`). */
function wantedSwitch(field, s, authored) {
  const effect = GRAPHICS_EFFECTS.find((e) => e.field === field);
  const chosen = effect ? s.graphics.effects[effect.id] : undefined;
  if (typeof chosen === "boolean") return chosen;
  return QUALITY_OFF[s.graphics.quality]?.includes(field) ? false : authored;
}

/**
 * Puts the graphics settings into effect on this scene's PostProcess components (component fields, the ones postprocess.set writes):
 * the quality turns the costly effects off, an effect the player switched wins over the quality, and the SceneSettings.hdrOutput the player chose
 * replaces the scene's. What the game authored is remembered per scene (scene.generation), so a better quality puts it back, and a field this
 * does not change is never written (a script of the game may change it itself).
 */
export function applyPostProcess(s = load()) {
  if (post.generation !== scene.generation) post = { generation: scene.generation, entities: new Map() };
  for (const e of postProcessEntities()) {
    const pp = e.get("PostProcess");
    let seen = post.entities.get(e.id);
    if (!seen) {
      seen = { authored: Object.fromEntries(POST_FIELDS.map((f) => [f, pp[f]])), forced: new Set() };
      post.entities.set(e.id, seen);
    }
    for (const f of POST_FIELDS) {
      const want = wantedSwitch(f, s, seen.authored[f]);
      if (want !== seen.authored[f]) {
        pp[f] = want;
        seen.forced.add(f);
      } else if (seen.forced.has(f)) {
        pp[f] = seen.authored[f];
        seen.forced.delete(f);
      }
    }
  }
  if (s.graphics.hdr !== null && world.settings) world.settings.hdrOutput = s.graphics.hdr ? "auto" : "off";
}

/** The entities of the scene that have a GlobalIllumination2D (the renderer uses the first). */
export function lightingEntities() {
  return world.entities().filter((e) => e.has("GlobalIllumination2D"));
}

/**
 * Puts the player's "2D lighting" choice (settings.graphics.lighting2d) on every GlobalIllumination2D of the scene: "off" sets enabled to false,
 * low / medium / high set enabled to true and quality. null (the player never chose) writes nothing, so the scene keeps its own values.
 * A scene without a GlobalIllumination2D gets none; the choice applies to the scenes that have one.
 */
export function applyLighting2D(s = load()) {
  const choice = lightingChoice(s);
  if (!choice) return;
  for (const e of lightingEntities()) {
    const gi = e.get("GlobalIllumination2D");
    if (choice === "off") {
      if (gi.enabled) gi.enabled = false;
    } else {
      if (!gi.enabled) gi.enabled = true;
      if (gi.quality !== choice) gi.quality = choice;
    }
  }
}

/** What the "2D lighting" row shows: the player's choice, else the scene's own GlobalIllumination2D (its quality, or "off" when disabled), else "off". */
export function lightingShown(s = load(), platform = game.platform) {
  const choice = lightingChoice(s, platform);
  if (choice) return choice;
  const gi = lightingEntities()[0]?.get("GlobalIllumination2D");
  if (!gi || !gi.enabled) return "off";
  return lightingChoices(platform).includes(gi.quality) ? gi.quality : "medium"; // "high" is not offered on a phone or in a browser
}

/** Whether the "2D lighting" row can matter in this scene: it has a Sprite, or the player's settings recorded a lighting choice. A 3D scene has neither. */
export function lightingRelevant(s = load()) {
  return s.graphics.lighting2d != null || world.entities().some((e) => e.has("Sprite"));
}

/** Whether the effect `id` of GRAPHICS_EFFECTS is on now in the scene (in any of its PostProcess components; false when the scene has none). */
export function effectOn(id) {
  const field = GRAPHICS_EFFECTS.find((e) => e.id === id)?.field;
  return postProcessEntities().some((e) => e.get("PostProcess")[field] === true);
}

/** Whether this renderer can draw the upscaler `mode`: "auto" and "stretch" always, the others by render.supports (false without a renderer to ask). */
export function upscalerModeSupported(mode) {
  return MODE_FEATURE[mode] === undefined || renderSupports(MODE_FEATURE[mode]);
}

/** Whether this renderer can run the low-latency `mode`: "off" and "auto" always, the SDKs by render.supports (false without a renderer to ask). */
export function latencyModeSupported(mode) {
  return LATENCY_FEATURE[mode] === undefined || renderSupports(LATENCY_FEATURE[mode]);
}

/** Whether the low-latency `mode` has a boost switch (Reflex and XeLL; Anti-Lag 2, the engine's own pacing and off have none). */
export function latencyHasBoost(mode) {
  return LATENCY_BOOST.includes(mode);
}

/** The low-latency setting in force and the path that runs: { mode, boost, driver } (render.latency; "off", false, "none" when the command cannot answer). */
export function latencyState() {
  try {
    const { mode, boost, driver } = fa.call("render.latency");
    return { mode, boost, driver };
  } catch {
    return { mode: "off", boost: false, driver: "none" };
  }
}

/** Sets the keys of render.latency (mode, boost) in the engine; throws what the command refuses with. */
export function setLatency(keys) {
  fa.call("render.latency", keys);
}

/** Whether this renderer can run the frame-generation `mode`: "off" and "auto" always, the SDKs by render.supports (false without a renderer to ask). */
export function frameGenModeSupported(mode) {
  return FRAMEGEN_FEATURE[mode] === undefined || renderSupports(FRAMEGEN_FEATURE[mode]);
}

/**
 * The frame-generation setting in force and what runs: { mode, minBaseFps, provider, state, baseFps, presentedFps } (render.frame_generation; state is
 * off, refused, measuring, paused or active; "off" with nothing running when the command cannot answer).
 */
export function frameGenState() {
  try {
    const r = fa.call("render.frame_generation");
    return { mode: r.mode, minBaseFps: r.minBaseFps, provider: r.provider, state: r.state, baseFps: r.report?.baseFps ?? 0, presentedFps: r.report?.presentedFps ?? 0 };
  } catch {
    return { mode: "off", minBaseFps: FRAMEGEN_DEFAULT_MIN_FPS, provider: "none", state: "off", baseFps: 0, presentedFps: 0 };
  }
}

/** Sets the keys of render.frame_generation (mode, minBaseFps) in the engine; throws what the command refuses with. A provider needs the start of the run: a game that started with frame generation off answers `refused` (state), the setting itself is kept. */
export function setFrameGeneration(keys) {
  fa.call("render.frame_generation", keys);
}

/** Whether this renderer can trace rays (render.supports "raytracing": Direct3D 12, Vulkan or Metal on a GPU that can; false without a renderer to ask). */
export function rayTracingSupported() {
  return renderSupports("raytracing");
}

/** Which of RAYTRACING_QUALITIES a render.ray_tracing setting (or its presetCap.effective) is: "ultra" when it asks for soft shadows, reflections, translucency or probes, else "high". */
function rayTracingQualityOf(r) {
  return r.shadows === "soft" || r.reflections === true || r.translucency === true || (r.gi !== undefined && r.gi !== "off") ? "ultra" : "high";
}

/** Whether a render.ray_tracing setting asks for an effect that is drawn with rays (shadows, ao, reflections, translucency or gi). */
function rayTracingAsksEffect(r) {
  return (r.shadows !== undefined && r.shadows !== "off") || r.ao === true || r.reflections === true || r.translucency === true || (r.gi !== undefined && r.gi !== "off");
}

/**
 * The ray tracing setting in force: { enabled, quality, active, reason, preset, capped, drawn } (render.ray_tracing). `quality` is the tier of what the game or the player asked for, `active` whether rays are traced now,
 * `reason` the engine's own sentence, `preset` the graphics preset, `capped` whether it lowers what is asked and `drawn` the tier that is left: "none", "high" or "ultra". Off, with nothing drawn, when the command cannot answer.
 */
export function rayTracingState() {
  try {
    const r = fa.call("render.ray_tracing");
    const eff = r.presetCap?.effective ?? r;
    return {
      enabled: r.enabled === true,
      quality: rayTracingQualityOf(r),
      asksEffect: rayTracingAsksEffect(r),
      active: r.active === true,
      reason: r.reason ?? "",
      preset: r.presetCap?.preset ?? "custom",
      capped: r.presetCap?.capped === true,
      drawn: rayTracingAsksEffect(eff) ? rayTracingQualityOf(eff) : "none",
    };
  } catch {
    return { enabled: false, quality: "high", asksEffect: false, active: false, reason: "", preset: "custom", capped: false, drawn: "none" };
  }
}

/** The quality a player who turns ray tracing on without choosing one gets: the tier of the graphics preset (ultra and custom trace everything, so "ultra"; otherwise "high"). */
export function rayTracingDefaultQuality() {
  try {
    const preset = game.graphics.preset().preset;
    return preset === "ultra" || preset === "custom" ? "ultra" : "high";
  } catch {
    return "high";
  }
}

/**
 * Sets render.ray_tracing from the page's keys { enabled, quality }: `quality` writes the effects of its RAYTRACING_TIERS tier. Turning it on while nothing is asked to be traced (the game left every effect off) also writes the
 * default quality's tier, so the switch does something. The graphics preset still caps what is drawn. Throws what the command refuses with.
 */
export function setRayTracing(keys) {
  const send = {};
  const quality = keys.quality ?? (keys.enabled === true && !rayTracingState().asksEffect ? rayTracingDefaultQuality() : undefined);
  if (RAYTRACING_TIERS[quality]) Object.assign(send, RAYTRACING_TIERS[quality]);
  if (keys.enabled !== undefined) send.enabled = keys.enabled === true;
  if (Object.keys(send).length) fa.call("render.ray_tracing", send);
}

/** The preset that is in force for the player's choice: "auto" is the pick of game.graphics.detect() (null while it has not run), null when the player never chose. */
export function presetInForce(s = load()) {
  const choice = s.graphics.preset;
  if (choice === "auto") return DETECTED.includes(s.graphics.detected) ? s.graphics.detected : null;
  return GRAPHICS_PRESETS.includes(choice) ? choice : null;
}

/**
 * Runs game.graphics.detect() the first time the player's preset is "auto" and keeps its pick in `s.graphics.detected`: later runs, scenes and
 * clicks read the pick, so the benchmark (a few hundred milliseconds that block the frame) runs once. Returns the pick, or null when the detect failed.
 */
export function detectPreset(s = load()) {
  if (DETECTED.includes(s.graphics.detected)) return s.graphics.detected;
  try {
    const pick = game.graphics.detect().preset;
    s.graphics.detected = pick;
    return pick;
  } catch (e) {
    console.warn(`settings: the graphics detection failed, Auto keeps the game's own look: ${e.message}`);
    return null;
  }
}

/**
 * Puts the graphics page's choices into the engine: the preset (game.graphics.preset), then the keys of the upscaler the player set, the low-latency mode, the frame generation, the ray tracing, then the render
 * scale and the dynamic resolution. Nothing the player never chose is touched, so a save of an older kit changes nothing; a value the engine rejects is logged and skipped.
 * Settings outlive scene loads and so does the engine's state: apply() calls this once per run, and a row of the page calls it after each change.
 */
export function applyRenderSettings(s = load()) {
  const g = s.graphics;
  const tryApply = (what, fn) => {
    try {
      fn();
    } catch (e) {
      console.warn(`settings: ${what} was not applied: ${e.message}`);
    }
  };
  if (g.preset !== null) {
    const name = g.preset === "auto" ? detectPreset(s) : g.preset;
    if (name) tryApply("the graphics preset", () => game.graphics.preset(name));
  }
  if (Object.keys(g.upscaler).length) tryApply("the upscaler", () => (window.upscaler = g.upscaler));
  if (Object.keys(g.latency).length) tryApply("the low-latency mode", () => setLatency(g.latency));
  if (Object.keys(g.frameGeneration).length) tryApply("the frame generation", () => setFrameGeneration(g.frameGeneration));
  if (Object.keys(g.rayTracing).length) tryApply("the ray tracing", () => setRayTracing(g.rayTracing));
  if (DYNAMIC_CHOICES.includes(g.dynamicResolution)) tryApply("the dynamic resolution", () => applyDynamicChoice(g.dynamicResolution));
  if (g.renderScale !== null) tryApply("the render scale", () => (window.renderScale = Math.min(RENDER_SCALE_MAX, Math.max(RENDER_SCALE_MIN, g.renderScale))));
}

/** What belongs to the scene's own entities (camera, captions, screen effects): every scene has new ones, so each scene sets them again. */
export function applyScene(s = load()) {
  applyColorFilter(s);
  applySubtitles(s);
  applyPostProcess(s);
  applyLighting2D(s);
}

/** Whether the effects are turned down now: the player's choice, else the system's "reduce motion". Your own particles and screen effects check this, not `s.reducedEffects` (null until the player chooses). */
export function reducedEffects(s = load()) {
  return s.reducedEffects ?? game.accessibility.reduceMotion;
}

/**
 * The game feel effects (docs/GAME_FEEL.md) follow the player's "reduced effects" choice: less shake and squash, shorter hit-stops, faint flashes.
 * A player who never chose (null) keeps following the system's reduce motion. Settings outlive scene loads, so once per run is enough; a row of the
 * options that changes `s.reducedEffects` calls this again with the new settings (and then settings.save(s)), as the colour filter row calls applyColorFilter.
 */
export function applyFeel(s = load()) {
  feel.reduceMotion = s.reducedEffects ?? null;
  feel.reducedEffects = s.reducedEffects ?? null;
}

/** Puts `s` into effect: bus volumes, colour filter, screen effects, graphics preset and upscaler, game feel, subtitles, text size, interface size, language, rebound controls and, when the game has a real window, the video settings. */
export function apply(s = load()) {
  for (const bus of BUSES) audio.setVolume(bus, s.volume[bus]);
  applyScene(s);
  applyFeel(s);
  const detected = s.graphics.detected;
  applyRenderSettings(s);
  if (s.graphics.detected !== detected) save(s); // "auto" ran the detection: keep the pick
  ui.textScale = s.textScale;
  if (s.uiScale !== null) ui.scale = s.uiScale;
  if (s.language && s.language !== i18n.language) {
    try {
      i18n.setLanguage(s.language); // rewrites every Text and widget with a key at once
    } catch (e) {
      console.warn(`settings: the saved language was ignored: ${e.message}`);
    }
  }
  for (const [action, list] of Object.entries(s.bindings)) {
    try {
      input.rebind(action, list);
    } catch (e) {
      console.warn(`settings: the saved controls of "${action}" were ignored: ${e.message}`);
    }
  }
  for (const [player, rebound] of Object.entries(s.playerBindings)) {
    const index = Number(player);
    if (!Number.isInteger(index) || index < 0 || index > 3) continue;
    for (const problem of input.player(index).import(rebound)) console.warn(`settings: the saved controls of player ${index + 1}: ${problem}`);
  }
  if (!window.available) return; // headless runs and tests have no window
  const tryApply = (what, fn) => {
    try {
      fn();
    } catch (e) {
      console.warn(`settings: ${what} was not applied: ${e.message}`);
    }
  };
  // The monitor first: a full screen or borderless window covers the monitor it is on when it switches.
  if (s.monitor && window.supports("monitors")) {
    const index = savedMonitorIndex(s.monitor);
    if (index >= 0 && index !== window.monitor) tryApply("monitor", () => window.setMonitor(index));
  }
  if (s.windowMode !== null) {
    const mode = s.windowMode === "borderless" && !window.supports("borderless") ? "fullscreen" : s.windowMode;
    tryApply("window mode", () => window.setMode(mode));
  }
  if (s.resolution && !window.fullscreen) tryApply("window size", () => window.setSize(s.resolution[0], s.resolution[1]));
  if (s.vsync !== null) tryApply("vsync", () => window.setVsync(s.vsync));
  if (s.frameCap) tryApply("frame cap", () => (window.frameCap = s.frameCap));
}

/** apply() the first time it is called in a run: session values outlive scene loads (and each test starts afresh). */
export function applyOnce() {
  if (session.settingsApplied) return applyScene(); // a new scene has a new camera and new captions
  session.settingsApplied = true;
  apply();
}
