// @ts-check
// The player's settings (volumes, video, colour filter, controls, language), kept in storage under "settings" and applied once per run.
// scripts/ui/options.js edits them; main_menu.js and pause_menu.js call applyOnce() when their scene starts.
import { storage, audio, window, input, session, i18n, world, ui, game } from "factoria";
import { setUiScale } from "./game/ui_kit.js";

/** The audio buses of the engine (audio.setVolume takes exactly these). */
export const BUSES = ["master", "music", "sfx", "ui"];
/**
 * The buses the Audio tab shows, in order. "ambience" is the game's own fifth bus: the engine has four, so the soundscape
 * (scripts/game/soundscape.js) plays its beds on "sfx" and multiplies every bed by this volume itself (ENGINE_FEEDBACK FB-0041).
 */
export const MIX_BUSES = ["master", "music", "ambience", "sfx", "ui"];
/** The choices of the UI scale option (widget sizes: icons, buttons, rules, paddings). */
export const UI_SCALES = [1, 1.25, 1.5];
/** The choices of the text size option. */
export const TEXT_SCALES = [1, 1.25, 1.5];

/** Values of Camera.colorFilter the options menu cycles through (accessibility: the last post-process of the frame). */
export const COLOR_FILTERS = ["none", "greyscale", "highContrast", "protanopia", "deuteranopia", "tritanopia"];

/**
 * What a player who never chose gets. The accessibility ones start from the system's settings (game.accessibility): they
 * follow the system on every run until the player saves their own choice (save() stores all the settings), which then wins.
 */
function defaults() {
  const system = game.accessibility;
  return {
    volume: { master: 1, music: 0.6, ambience: 0.8, sfx: 1, ui: 1 },
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
    uiScale: 1, // the size of the widgets (UI_SCALES), see ui_kit.js setUiScale
    reducedMotion: system.reduceMotion, // no eased camera moves, no notice fades, a still title picture (settings.live().reducedMotion)
    safeColors: false, // colour-blind safe signals: patterns on the overlays and the build check, a mark in front of each notice
    holdFree: false, // click alternatives for everything that needs a held button: two-click roads, click-to-carry, toggled pan
    subtitles: true, // show captions (the "captions" entity, a Captions component); off = that entity is inactive
  };
}

/** The saved settings merged over the defaults (a fresh object each call). */
export function load() {
  const saved = storage.get("settings", {});
  if (saved.windowMode === undefined && typeof saved.fullscreen === "boolean") saved.windowMode = saved.fullscreen ? "fullscreen" : "windowed"; // saved by an older kit
  if (saved.reducedMotion === undefined && typeof saved.reducedEffects === "boolean") saved.reducedMotion = saved.reducedEffects; // the name before P6
  const base = defaults();
  return { ...base, ...saved, volume: { ...base.volume, ...saved.volume }, bindings: { ...saved.bindings }, playerBindings: { ...saved.playerBindings } };
}

export function save(s) {
  storage.set("settings", s);
  publish(s);
}

/**
 * The options the game code reads every frame, kept in `session` (storage.get parses JSON each call). save() and apply() refresh
 * it, so it is always what the player last chose; before anything was applied it comes from storage once.
 * @returns {{ ambience: number, reducedMotion: boolean, safeColors: boolean, holdFree: boolean, uiScale: number }}
 */
export function live() {
  if (!session.liveOptions) publish(load());
  return session.liveOptions;
}

function publish(s) {
  session.liveOptions = { ambience: s.volume.ambience, reducedMotion: !!s.reducedMotion, safeColors: !!s.safeColors, holdFree: !!s.holdFree, uiScale: s.uiScale };
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

/** Camera.colorFilter of the scene's camera (the entity with the id "camera"): every scene has its own camera, so each scene sets it again. */
export function applyColorFilter(s = load()) {
  const camera = world.find("camera");
  if (camera) camera.get("Camera").colorFilter = s.colorFilter;
}

/** Captions follow the "Subtitles" option by switching the scene's "captions" entity on or off. The game keeps calling audio.play({ caption }) and ui.caption(): they are tracked while hidden. */
export function applySubtitles(s = load()) {
  const captions = world.find("captions");
  if (captions) captions.active = s.subtitles;
}

/** What belongs to the scene's own entities (camera, captions): every scene has new ones, so each scene sets them again. */
export function applyScene(s = load()) {
  applyColorFilter(s);
  applySubtitles(s);
}

/** Puts `s` into effect: bus volumes, colour filter, subtitles, text size, language, rebound controls and, when the game has a real window, the video settings. */
export function apply(s = load()) {
  for (const bus of BUSES) audio.setVolume(bus, s.volume[bus]);
  publish(s); // the ambience volume and the accessibility switches the game code reads
  applyScene(s);
  ui.textScale = s.textScale;
  setUiScale(s.uiScale);
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

/**
 * Put some options into effect for this run only, saving nothing (a scene prop `options` of the game scene: a screenshot of the
 * colour-blind safe overlays, `factoria run --props '{"options":{"safeColors":true}}'`). Anything not named keeps the player's choice.
 * @param {Partial<ReturnType<typeof load>>} partial
 */
export function preview(partial) {
  session.settingsApplied = true; // the saved settings are not applied over this
  apply({ ...load(), ...partial });
}

/** apply() the first time it is called in a run: session values outlive scene loads (and each test starts afresh). */
export function applyOnce() {
  if (session.settingsApplied) return applyScene(); // a new scene has a new camera and new captions
  session.settingsApplied = true;
  apply();
}
