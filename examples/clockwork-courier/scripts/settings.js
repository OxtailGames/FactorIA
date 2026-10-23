// @ts-check
// The player's settings (volumes, video, colour filter, controls, language), kept in storage under "settings" and applied once per run.
// scripts/ui/options.js edits them; main_menu.js and pause_menu.js call applyOnce() when their scene starts.
import * as accessibility from "./accessibility.js";
import { storage, audio, window, input, session, i18n, world, ui, game } from "factoria";

/** Audio buses the options menu shows, in order. */
export const BUSES = ["master", "music", "sfx", "ui"];

/** Graphics presets the options menu cycles through (scripts/accessibility.js applies them to the level). */
export const QUALITIES = ["low", "medium", "high"];

/** Frame caps of the options menu (0 = unlimited). A phone cannot cap (window.supports("frameCap")): the option is greyed out there. */
export const FRAME_CAPS = [30, 60, 0];

/** Text sizes of the options menu (ui.textScale): 85 to 200 percent. */
export const TEXT_SCALES = [0.85, 1, 1.15, 1.3, 1.5, 2];

/** Values of Camera.colorFilter the options menu cycles through (accessibility: the last post-process of the frame). */
export const COLOR_FILTERS = ["none", "greyscale", "highContrast", "protanopia", "deuteranopia", "tritanopia"];

/** True on a phone or tablet (a touch screen, an always-full-screen display, no window to resize): game.device.formFactor. */
export function onPhone() {
  return game.device.formFactor !== "desktop";
}

/**
 * What a player who never chose gets. The accessibility ones start from the system's settings (game.accessibility): they
 * follow the system on every run until the player saves their own choice (save() stores all the settings), which then wins.
 */
function defaults() {
  const system = game.accessibility;
  return {
    volume: { master: 1, music: 0.6, sfx: 1, ui: 1 },
    fullscreen: null, // null: keep factoria.json display.fullscreen
    resolution: null, // [width, height] of the window, or null: the factoria.json size
    vsync: null, // null: keep factoria.json display.vsync
    quality: game.device.tier, // graphics preset, one of QUALITIES: game.device.tier is "low", "medium" or "high" from the GPU backend and the memory
    frameCap: onPhone() ? 30 : 0, // 0 = no cap; a phone starts at 30 to spare the battery (where the platform lets the game set it)
    haptics: true, // input.vibrate on landing, a catch, a delivery and a low spring (scripts/haptics.js)
    leftHanded: false, // mirrors the on-screen stick and buttons (scripts/accessibility.js)
    controlSize: 1, // size of the on-screen controls, 0.8..1.4
    controlOpacity: 1, // opacity of the on-screen controls, 0.3..1 times their own
    cameraSensitivity: 1, // orbit speed, 0.4..2.5
    invertY: false, // flip the vertical orbit
    assist: false, // assist mode: slower spring, slower dogs that give up sooner, a wider jump grace
    colorFilter: "none", // one of COLOR_FILTERS
    bindings: {}, // action -> binding names, only for actions the player rebound
    language: null, // null: the language the game started in (the player's system language, else the default one)
    readAloud: system.screenReader, // say the focused menu widget with text to speech (scripts/ui/read_aloud.js)
    textScale: system.textScale, // the text size, 1 = 100 % (ui.textScale)
    reducedMotion: system.reduceMotion, // no bobbing or spinning props, a softer camera, fewer particles (scripts/accessibility.js, fx.js)
    reducedEffects: false, // fewer particles only (the older switch: fx.js honours both)
    tapToMove: false, // tap the ground and the courier walks there around obstacles (scripts/tap_move.js); off by default
    subtitles: true, // show captions (the "captions" entity, a Captions component); off = that entity is inactive
  };
}

/** The saved settings merged over the defaults (a fresh object each call). */
export function load() {
  const saved = storage.get("settings", {});
  const base = defaults();
  return { ...base, ...saved, volume: { ...base.volume, ...saved.volume }, bindings: { ...saved.bindings } };
}

/**
 * Saves what differs from the defaults. What the player never changed keeps following the system (game.accessibility) and the
 * device, so turning "reduce motion" on in the phone's settings reaches a player who never picked their own value.
 */
export function save(s) {
  const base = defaults();
  const out = {};
  for (const [key, value] of Object.entries(s)) {
    if (JSON.stringify(value) !== JSON.stringify(base[key])) out[key] = value;
  }
  storage.set("settings", out);
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
  accessibility.applyToScene(s);
}

/**
 * The language a first run starts in: the first of the system's languages (best first, tags like "es-MX" or "ja_JP") the game
 * has, matching the whole tag or its first part; else `fallback`. The engine does the same when a window opens
 * (i18n.systemLanguages); this is the same rule written down so a test can feed it any list (a headless run has no system language).
 * @param {string[]} systemLanguages @param {string[]} supported @param {string} fallback
 */
export function pickLanguage(systemLanguages, supported, fallback) {
  const lower = supported.map((l) => l.toLowerCase());
  for (const tag of systemLanguages) {
    const clean = tag.toLowerCase().replace("_", "-");
    let i = lower.indexOf(clean);
    if (i < 0) i = lower.indexOf(clean.split("-")[0]);
    if (i >= 0) return supported[i];
  }
  return fallback;
}

/** Puts `s` into effect: bus volumes, colour filter, subtitles, text size, language, rebound controls and, when the game has a real window, the video settings. */
export function apply(s = load()) {
  for (const bus of BUSES) audio.setVolume(bus, s.volume[bus]);
  applyScene(s);
  ui.textScale = s.textScale;
  const wanted = s.language || (i18n.systemLanguages.length > 0 ? pickLanguage(i18n.systemLanguages, i18n.languages, i18n.language) : null);
  if (wanted && wanted !== i18n.language) {
    try {
      i18n.setLanguage(wanted); // rewrites every Text and widget with a key at once
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
  if (!window.available) return; // headless runs and tests have no window
  const tryApply = (what, fn) => {
    try {
      fn();
    } catch (e) {
      console.warn(`settings: ${what} was not applied: ${e.message}`);
    }
  };
  if (s.fullscreen !== null) tryApply("full screen", () => window.setFullscreen(s.fullscreen));
  if (s.resolution && !window.fullscreen) tryApply("window size", () => window.setSize(s.resolution[0], s.resolution[1]));
  if (s.vsync !== null) tryApply("vsync", () => window.setVsync(s.vsync));
  if (window.supports("frameCap")) tryApply("frame cap", () => (window.frameCap = s.frameCap)); // a phone cannot cap
}

/** apply() the first time it is called in a run: session values outlive scene loads (and each test starts afresh). */
export function applyOnce() {
  if (session.settingsApplied) return applyScene(); // a new scene has a new camera and new captions
  session.settingsApplied = true;
  apply();
}
