// @ts-check
// The player's settings (volumes, video, controls, language), kept in storage under "settings" and applied once per run.
// scripts/ui/options.js edits them; main_menu.js and pause_menu.js call applyOnce() when their scene starts.
import { storage, audio, window, input, session, i18n } from "factoria";

/** Audio buses the options menu shows, in order. */
export const BUSES = ["master", "music", "sfx", "ui"];

const DEFAULTS = {
  volume: { master: 1, music: 0.6, sfx: 1, ui: 1 },
  fullscreen: null, // null: keep factoria.json display.fullscreen
  resolution: null, // [width, height] of the window, or null: the factoria.json size
  vsync: null, // null: keep factoria.json display.vsync
  frameCap: 0, // 0 = no cap
  bindings: {}, // action -> binding names, only for actions the player rebound
  language: null, // null: the language the game started in (the player's system language, else the default one)
};

/** The saved settings merged over the defaults (a fresh object each call). */
export function load() {
  const saved = storage.get("settings", {});
  return { ...DEFAULTS, ...saved, volume: { ...DEFAULTS.volume, ...saved.volume }, bindings: { ...saved.bindings } };
}

export function save(s) {
  storage.set("settings", s);
}

/** Puts `s` into effect: bus volumes, language, rebound controls and, when the game has a real window, the video settings. */
export function apply(s = load()) {
  for (const bus of BUSES) audio.setVolume(bus, s.volume[bus]);
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
  if (s.frameCap) tryApply("frame cap", () => (window.frameCap = s.frameCap));
}

/** apply() the first time it is called in a run: session values outlive scene loads (and each test starts afresh). */
export function applyOnce() {
  if (session.settingsApplied) return;
  session.settingsApplied = true;
  apply();
}
