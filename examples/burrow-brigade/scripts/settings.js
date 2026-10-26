// @ts-check
// The player's settings (volumes, video, colour filter, controls, language), kept in storage under "settings" and applied once per run.
// scripts/ui/options.js edits them; main_menu.js and pause_menu.js call applyOnce() when their scene starts.
import { storage, window, input, session, i18n, world, ui, game } from "factoria";
import * as mix from "./game/mix.js";
import * as controls from "./game/controls.js"; // controls.js reads and saves the settings too: each uses the other only inside functions

/** Audio buses the options menu shows, in order. */
export const BUSES = ["master", "music", "sfx", "ui"];

/** Window modes of the Video tab. The engine has full screen and windowed only: its full screen is the window covering the monitor (borderless), and it has no exclusive mode or monitor choice to offer (FB-0027). */
export const DISPLAY_MODES = ["windowed", "fullscreen"];

/** Game speeds of the assist option (1 = normal). A slower game does not post to the boards (scripts/game/boards.js). */
export const GAME_SPEEDS = [1, 0.8, 0.6];

/** How a held action is read: "hold" (keep the button down) or "toggle" (press once to start, again to stop). */
export const HOLD_MODES = ["hold", "toggle"];

/** Values of Camera.colorFilter the options menu cycles through (accessibility: the last post-process of the frame). */
export const COLOR_FILTERS = ["none", "greyscale", "highContrast", "protanopia", "deuteranopia", "tritanopia"];

/**
 * What a player who never chose gets. The accessibility ones start from the system's settings (game.accessibility): they
 * follow the system on every run until the player saves their own choice (save() stores all the settings), which then wins.
 */
function defaults() {
  const system = game.accessibility;
  return {
    volume: { master: 1, music: 0.6, sfx: 1, ui: 1 },
    fullscreen: null, // null: keep factoria.json display.fullscreen (kept in step with displayMode)
    displayMode: null, // null, "windowed" or "fullscreen" (DISPLAY_MODES); null: keep factoria.json
    resolution: null, // [width, height] of the window, or null: the factoria.json size
    vsync: null, // null: keep factoria.json display.vsync
    frameCap: 0, // 0 = no cap
    colorFilter: "none", // one of COLOR_FILTERS
    bindings: {}, // action -> binding names, only for actions the player rebound
    playerBindings: {}, // seat ("0".."3") -> input.player(seat).export(): { keys: {project action: names}, pad: {...} }, only what each player rebound (scripts/game/controls.js)
    language: null, // null: the language the game started in (the player's system language, else the default one)
    readAloud: system.screenReader, // say the focused menu widget with text to speech (scripts/ui/read_aloud.js)
    textScale: system.textScale, // the text size, 1 = 100 % (ui.textScale)
    reducedEffects: system.reduceMotion, // reduced flashing: magma and torch light stay steady, no screen flash, the cave-in warning does not blink (lights.js, hazards.js)
    subtitles: true, // show captions (the "captions" entity, a Captions component); off = that entity is inactive
    soundCaptions: false, // short captions for important sounds in a shift (the "sound_captions" entity; scripts/game/sound.js)
    holdMode: {}, // seat ("0".."3") -> "hold" | "toggle": how the dig button is read (scripts/game/miner_input.js)
    gameSpeed: 1, // 1, 0.8 or 0.6: the speed of a shift (GAME_SPEEDS)
    splitScreen: false, // true: miners may part and the screen splits into one view each (scripts/game/camera_views.js); false: a leash keeps them together
  };
}

/** The saved settings merged over the defaults (a fresh object each call). */
export function load() {
  const saved = storage.get("settings", {});
  const base = defaults();
  return { ...base, ...saved, volume: { ...base.volume, ...saved.volume }, bindings: { ...saved.bindings }, playerBindings: { ...saved.playerBindings }, holdMode: { ...saved.holdMode } };
}

/** The saved settings, read now (the game code that asks every frame uses this; it reads the storage each time, so a test that wipes the storage is never stale). */
export function current() {
  return load();
}

export function save(s) {
  storage.set("settings", s);
  flashStamp = -1;
  splitStamp = -1;
}

let flashStamp = -1;
let flashValue = false;
let splitStamp = -1;
let splitValue = false;

/**
 * True when the player asked for reduced flashing (Options > Access; the system's "reduce motion" until they choose). Effects code
 * asks every frame, so the answer is kept for 15 frames and forgotten by `save` (a change in Options shows at once).
 */
export function reducedFlashing() {
  const frame = world.frame;
  if (flashStamp < 0 || frame < flashStamp || frame - flashStamp >= 15) {
    flashValue = !!load().reducedEffects;
    flashStamp = frame;
  }
  return flashValue;
}

/**
 * True when the player chose a split screen (Options > Video): the miners may walk apart and the camera splits (camera_views.js).
 * The miners' steps ask every frame, so this is cached like `reducedFlashing`.
 */
export function splitScreenOn() {
  const frame = world.frame;
  if (splitStamp < 0 || frame < splitStamp || frame - splitStamp >= 15) {
    splitValue = load().splitScreen === true;
    splitStamp = frame;
  }
  return splitValue;
}

/** How the dig button of a seat is read: "hold" or "toggle". */
export function holdModeOf(seat, s = current()) {
  return s.holdMode[String(seat)] === "toggle" ? "toggle" : "hold";
}

/** The window mode in force: the saved one, else what `fullscreen` says, else null (the factoria.json choice). */
export function displayModeOf(s = current()) {
  if (DISPLAY_MODES.includes(s.displayMode)) return s.displayMode;
  if (s.fullscreen === true) return "fullscreen";
  if (s.fullscreen === false) return "windowed";
  return null;
}

/** The game speed in force (a saved value that is not one of GAME_SPEEDS counts as 1). */
export function gameSpeedOf(s = current()) {
  return GAME_SPEEDS.includes(s.gameSpeed) ? s.gameSpeed : 1;
}

/** Camera.colorFilter of the scene's camera (the entity with the id "camera"): every scene has its own camera, so each scene sets it again. */
export function applyColorFilter(s = load()) {
  const camera = world.find("camera");
  if (camera) camera.get("Camera").colorFilter = s.colorFilter;
}

/** Captions follow the "Subtitles" option by switching the scene's "captions" entity on or off, and the sound captions of a shift ("sound_captions") follow their own option. The game keeps calling audio.play({ caption }) and ui.caption(): they are tracked while hidden. */
export function applySubtitles(s = load()) {
  const captions = world.find("captions");
  if (captions) captions.active = s.subtitles;
  const sound = world.find("sound_captions");
  if (sound) sound.active = s.soundCaptions;
}

/** What belongs to the scene's own entities (camera, captions): every scene has new ones, so each scene sets them again. */
export function applyScene(s = load()) {
  applyColorFilter(s);
  applySubtitles(s);
}

/** Puts `s` into effect: bus volumes, colour filter, subtitles, text size, language, rebound controls and, when the game has a real window, the video settings. */
export function apply(s = load()) {
  for (const bus of BUSES) mix.setUser(bus, s.volume[bus]); // the mix puts the snapshot and the duck of the moment on top (scripts/game/mix.js)
  applyScene(s);
  ui.textScale = s.textScale;
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
  controls.applySaved(s); // each seat's own controls, kept by the engine (input.player)
  if (!window.available) return; // headless runs and tests have no window
  const tryApply = (what, fn) => {
    try {
      fn();
    } catch (e) {
      console.warn(`settings: ${what} was not applied: ${e.message}`);
    }
  };
  const mode = displayModeOf(s);
  if (mode !== null) tryApply("window mode", () => window.setFullscreen(mode !== "windowed"));
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
