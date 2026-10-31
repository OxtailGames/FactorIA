// @ts-check
// The player's settings (volumes, video, interface size, colour filter, controls, language), kept in storage under "settings" and applied once per run.
// scripts/ui/options.js edits them; main_menu.js and pause_menu.js call applyOnce() when their scene starts.
import { storage, audio, window, input, session, i18n, world, ui, game } from "factoria";
import { EVENTS, emit } from "./events.js";

/** Audio buses the options menu shows, in order (`ambience` and `voiceover` are declared in factoria.json "audio.buses"). */
export const BUSES = ["master", "music", "sfx", "ambience", "voiceover", "ui"];

/** The text sizes the options menu cycles through (ui.textScale): 100 %, 125 %, 150 %, 200 %. */
export const TEXT_SCALES = [1, 1.25, 1.5, 2];

/** How dark the box behind captions and dialogue is: the alpha of its colour, and the locale name `options.captionBg.<name>`. */
export const CAPTION_BACKGROUNDS = [
  { name: "clear", alpha: 0 },
  { name: "dark", alpha: 0.7 },
  { name: "solid", alpha: 1 },
];

/** Dialogue auto-advance: words per minute the player reads at (0 = off, the player presses to go on). */
export const AUTO_ADVANCE = [
  { name: "off", wpm: 0 },
  { name: "slow", wpm: 120 },
  { name: "normal", wpm: 200 },
  { name: "fast", wpm: 320 },
];

/** Which device the prompts' key names come from: the one used last, or always one of the others (scripts/glyphs.js). */
export const GLYPH_MODES = ["auto", "keyboard", "gamepad", "touch"];

/** Camera sensitivity slider range (a multiplier of lodge_camera.js's orbit speeds). */
export const SENSITIVITY = { min: 0.25, max: 2, step: 0.05 };

/** Values of Camera.colorFilter the options menu cycles through (accessibility: the last post-process of the frame). */
export const COLOR_FILTERS = ["none", "greyscale", "highContrast", "protanopia", "deuteranopia", "tritanopia"];

/** The dialogue text speeds the options menu cycles through: characters per second (0 = a whole line at once) and the locale name `options.speed.<name>`. */
export const TEXT_SPEEDS = [
  { name: "slow", cps: 20 },
  { name: "normal", cps: 45 },
  { name: "fast", cps: 90 },
  { name: "instant", cps: 0 },
];

/**
 * What a player who never chose gets. The accessibility ones start from the system's settings (game.accessibility): they
 * follow the system on every run until the player saves their own choice (save() stores all the settings), which then wins.
 */
function defaults() {
  const system = game.accessibility;
  return {
    volume: { master: 1, music: 0.6, sfx: 1, ambience: 0.8, voiceover: 1, ui: 1 },
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
    reducedMotion: system.reduceMotion, // no head bob, cut-scenes cut instead of moving the camera (scripts/lodge_camera.js, scripts/cutscene.js)
    captionBackground: "dark", // one of CAPTION_BACKGROUNDS: the box behind captions and the dialogue
    captionSpeakers: true, // show the speaker's name before a caption and a dialogue line
    autoAdvance: "off", // one of AUTO_ADVANCE: dialogue goes on by itself after the time to read the line
    cameraSensitivity: 1, // multiplies every camera orbit input (SENSITIVITY)
    cameraInvertX: false,
    cameraInvertY: false,
    glyphs: "auto", // one of GLYPH_MODES
    textSpeed: system.reduceMotion ? 0 : 45, // dialogue text reveal in characters per second, 0 = a whole line at once (scripts/dialogue_view.js)
    subtitles: true, // show captions (the "captions" entity, a Captions component); off = that entity is inactive
  };
}

/** The saved settings merged over the defaults (a fresh object each call). */
export function load() {
  const saved = storage.get("settings", {});
  if (saved.windowMode === undefined && typeof saved.fullscreen === "boolean") saved.windowMode = saved.fullscreen ? "fullscreen" : "windowed"; // saved by an older kit
  const base = defaults();
  return { ...base, ...saved, volume: { ...base.volume, ...saved.volume }, bindings: { ...saved.bindings }, playerBindings: { ...saved.playerBindings } };
}

/** Stores the settings and tells the scene (EVENTS.settingsChanged) so the camera, the dialogue box and the sound read them at once. */
export function save(s) {
  storage.set("settings", s);
  applyCaptionBackground(s);
  emit(EVENTS.settingsChanged, { settings: s });
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

/** The box behind the captions follows "Caption background" (the Captions component draws it with its `color`). */
export function applyCaptionBackground(s = load()) {
  const captions = world.find("captions");
  if (!captions) return;
  const c = captions.get("Captions");
  const alpha = (CAPTION_BACKGROUNDS.find((b) => b.name === s.captionBackground) ?? CAPTION_BACKGROUNDS[1]).alpha;
  c.color = [c.color[0], c.color[1], c.color[2], alpha];
}

/** What belongs to the scene's own entities (camera, captions): every scene has new ones, so each scene sets them again. */
export function applyScene(s = load()) {
  applyColorFilter(s);
  applySubtitles(s);
  applyCaptionBackground(s);
}

/** Puts `s` into effect: bus volumes, colour filter, subtitles, text size, interface size, language, rebound controls and, when the game has a real window, the video settings. */
export function apply(s = load()) {
  for (const bus of BUSES) audio.setVolume(bus, s.volume[bus]);
  applyScene(s);
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
