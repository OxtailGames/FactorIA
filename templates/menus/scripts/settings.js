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
    graphics: { quality: "high", effects: {}, hdr: null, lighting2d: null },
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
    graphics: { ...base.graphics, ...saved.graphics, effects: { ...saved.graphics?.effects } },
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

/** Puts `s` into effect: bus volumes, colour filter, screen effects, game feel, subtitles, text size, interface size, language, rebound controls and, when the game has a real window, the video settings. */
export function apply(s = load()) {
  for (const bus of BUSES) audio.setVolume(bus, s.volume[bus]);
  applyScene(s);
  applyFeel(s);
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
