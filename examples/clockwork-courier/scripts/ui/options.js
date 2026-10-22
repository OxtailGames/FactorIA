// @ts-check
// The options panel (prefabs/ui/options.prefab.json), opened by the main menu and by the pause menu. Tabs: Video (graphics
// quality, frame cap, colour filter and the window), Audio (one slider per bus, read aloud, subtitles), Play (assist mode,
// reduced motion, vibration, tap to move, text size), Touch (left-handed layout, control size and opacity, camera speed and
// invert Y), Keys (rebinding; hidden on a phone) and Language (cycles through the game's languages). Every change is
// applied at once and saved (scripts/settings.js), so the next run starts with it. The texts are string-table keys
// (locales/*.json): the widgets with a `key` are translated by the engine, the ones this script writes use i18n.t().
import { Behaviour, ui, input, window, audio, world, i18n } from "factoria";
import * as settings from "../settings.js";
import * as haptics from "../haptics.js";
import { MenuStack } from "./menu_stack.js";

const TABS = ["video", "audio", "play", "touch", "controls", "language"];
/** Slider ranges of the touch options: [min, max] (the slider shows the real value as a plain number, 1 = the normal size or speed: no format option, FB-0037). */
const RANGES = { controlSize: [0.8, 1.4], controlOpacity: [0.3, 1], cameraSensitivity: [0.4, 2.5] };
const TAB_COLOR = [0.16, 0.18, 0.24, 0.92];
const TAB_SELECTED = [0.3, 0.36, 0.52, 0.96];

export default class Options extends Behaviour {
  runWhilePaused = true; // the pause menu opens it while game.paused
  /** Actions the Controls tab lets the player rebind; their labels are the strings "options.action.<action>". */
  actions = ["move_forward", "move_back", "move_left", "move_right", "jump", "action", "pause"];

  onStart() {
    this.s = settings.load();
    this.waiting = null; // the action waiting for "press a key or button"
    this.release = false;
    for (const tab of TABS) ui.on("click", `tab_${tab}`, () => this.showTab(tab));
    world.find("tab_controls").active = !settings.onPhone(); // a phone has no keys to rebind
    this.showTab("video");
    this.setupVideo();
    this.setupAudio();
    this.setupPlay();
    this.setupTouch();
    this.setupControls();
    this.setupLanguage();
    // The texts this script writes are not translated by the engine: write them again in the new language.
    i18n.on("change", () => {
      this.refreshVideo();
      this.refreshPlay();
      this.refreshControls();
      this.refreshLanguage();
    });
  }

  showTab(name) {
    for (const tab of TABS) {
      world.find(`${tab}_section`).active = tab === name;
      world.find(`tab_${tab}`).get("Button").color = tab === name ? TAB_SELECTED : TAB_COLOR;
    }
  }

  // ------------------------------------------------------------------------------------------------------------ video
  setupVideo() {
    const s = this.s;
    const has = window.available; // false in headless runs and tests: the rows stay visible, greyed out
    world.find("video_note").active = !has;
    const fullscreen = world.find("fullscreen").get("Toggle");
    const vsync = world.find("vsync").get("Toggle");
    fullscreen.value = window.fullscreen;
    vsync.value = window.vsync;
    fullscreen.interactable = vsync.interactable = has;
    // A phone refuses a frame cap (the platform picks the rate): the button stays, greyed out, showing the value kept.
    world.find("frame_cap").get("Button").interactable = has && !settings.onPhone();
    this.refreshVideo();

    ui.on("click", "quality", () => {
      const all = settings.QUALITIES;
      s.quality = all[(all.indexOf(s.quality) + 1) % all.length];
      settings.save(s);
      settings.applyScene(s); // shadows, lights, view distance, particles: at once
      this.refreshVideo();
    });

    ui.on("change", "fullscreen", (e) => this.video("full screen", () => { window.setFullscreen(e.value); s.fullscreen = e.value; }));
    ui.on("change", "vsync", (e) => this.video("vsync", () => { window.setVsync(e.value); s.vsync = e.value; }));
    ui.on("click", "resolution", () => {
      const sizes = window.resolutions();
      const now = window.size;
      const i = sizes.findIndex((r) => r.width === Math.round(now.x) && r.height === Math.round(now.y));
      const next = sizes[(i + 1) % sizes.length];
      this.video("window size", () => { window.setSize(next.width, next.height); s.resolution = [next.width, next.height]; });
    });
    ui.on("click", "frame_cap", () => {
      const caps = settings.FRAME_CAPS;
      const next = caps[(caps.indexOf(s.frameCap) + 1) % caps.length];
      this.video("frame cap", () => { window.frameCap = next; s.frameCap = next; });
    });
    ui.on("click", "color_filter", () => {
      const all = settings.COLOR_FILTERS;
      s.colorFilter = all[(all.indexOf(s.colorFilter) + 1) % all.length];
      settings.applyColorFilter(s); // Camera.colorFilter: the whole frame, this panel included
      settings.save(s);
      this.refreshVideo();
    });
  }

  /** Runs a window change (which also updates this.s); saves it when it worked, shows why when it did not. */
  video(what, change) {
    try {
      change();
      settings.save(this.s);
    } catch (e) {
      console.warn(`options: ${what} could not be changed: ${e.message}`);
    }
    this.refreshVideo();
  }

  refreshVideo() {
    const size = window.size;
    const resolution = world.find("resolution").get("Button");
    resolution.text = window.fullscreen
      ? i18n.t("options.windowSizeFullscreen")
      : i18n.t("options.windowSize", { width: Math.round(size.x), height: Math.round(size.y) });
    resolution.interactable = window.available && !window.fullscreen; // full screen uses the display's size
    world.find("quality").get("Button").text = i18n.t("options.quality", { quality: i18n.t(`options.qualityLevel.${this.s.quality}`) });
    world.find("frame_cap").get("Button").text = this.s.frameCap
      ? i18n.t("options.frameCap", { fps: this.s.frameCap })
      : i18n.t("options.frameCapOff");
    world.find("color_filter").get("Button").text = i18n.t("options.colorFilter", { filter: i18n.t(`options.filter.${this.s.colorFilter}`) });
  }

  // ------------------------------------------------------------------------------------------------------------ audio
  setupAudio() {
    for (const bus of settings.BUSES) {
      world.find(`${bus}_volume`).get("Slider").value = this.s.volume[bus];
      ui.on("change", `${bus}_volume`, (e) => {
        this.s.volume[bus] = e.value;
        audio.setVolume(bus, e.value);
        settings.save(this.s);
      });
    }
    // Only where the system can speak (Linux without speech-dispatcher, Android without a speech engine: hidden).
    const readAloud = world.find("read_aloud");
    readAloud.active = ui.speechAvailable;
    readAloud.get("Toggle").value = this.s.readAloud;
    ui.on("change", "read_aloud", (e) => {
      this.s.readAloud = e.value;
      settings.save(this.s);
      if (e.value) ui.speak(readAloud.get("Toggle").label); // so the player hears that it works
      else ui.stopSpeaking();
    });
    // Subtitles: captions are drawn by the scene's "captions" entity; the option switches it (settings.applySubtitles).
    world.find("subtitles").get("Toggle").value = this.s.subtitles;
    ui.on("change", "subtitles", (e) => {
      this.s.subtitles = e.value;
      settings.applySubtitles(this.s);
      settings.save(this.s);
    });
  }

  // ------------------------------------------------------------------------------------------------------------- play
  /** A toggle that writes `key` of the settings, saves and applies it at once. */
  bind(id, key, after = () => settings.applyScene(this.s)) {
    world.find(id).get("Toggle").value = this.s[key];
    ui.on("change", id, (e) => {
      this.s[key] = e.value;
      settings.save(this.s);
      after();
    });
  }

  setupPlay() {
    this.bind("assist", "assist");
    this.bind("reduced_motion", "reducedMotion");
    this.bind("haptics", "haptics", () => haptics.pulse("catch")); // so the player feels that it works
    this.bind("tap_to_move", "tapToMove", () => {});
    ui.on("click", "text_size", () => {
      const all = settings.TEXT_SCALES;
      const i = all.findIndex((v) => Math.abs(v - this.s.textScale) < 0.01);
      this.s.textScale = all[(i + 1) % all.length];
      ui.textScale = this.s.textScale;
      settings.save(this.s);
      this.refreshPlay();
    });
    this.refreshPlay();
  }

  refreshPlay() {
    world.find("text_size").get("Button").text = i18n.t("options.textSize", { percent: Math.round(this.s.textScale * 100) });
  }

  // ----------------------------------------------------------------------------------------------------------- touch
  setupTouch() {
    this.bind("left_handed", "leftHanded");
    this.bind("invert_y", "invertY");
    for (const [key, range] of Object.entries(RANGES)) {
      const id = key.replace(/[A-Z]/g, (c) => "_" + c.toLowerCase());
      const slider = world.find(id).get("Slider");
      slider.min = range[0];
      slider.max = range[1];
      slider.value = this.s[key];
      ui.on("change", id, (e) => {
        this.s[key] = Math.round(e.value * 100) / 100;
        settings.save(this.s);
        settings.applyScene(this.s);
      });
    }
  }

  // --------------------------------------------------------------------------------------------------------- controls
  setupControls() {
    const list = world.find("bindings");
    for (const action of this.actions) {
      const button = world.spawn({ id: `bind_${action}`, components: { Button: { text: action, size: [696, 44], fontSize: 22, layer: 302 } } }, { parent: list });
      ui.on("click", button, () => {
        if (this.waiting) return; // a press while waiting is the new binding (onUpdate), not a click
        this.waiting = { action, button, since: world.frame };
        MenuStack.busy = true; // Escape cancels the rebinding instead of closing the panel
        this.refreshControls();
      });
    }
    ui.on("click", "reset_controls", () => {
      input.resetBindings();
      this.s.bindings = {};
      settings.save(this.s);
      this.refreshControls();
    });
    this.refreshControls();
  }

  refreshControls() {
    for (const action of this.actions) {
      const label = i18n.t(`options.action.${action}`);
      world.find(`bind_${action}`).get("Button").text =
        this.waiting?.action === action
          ? i18n.t("options.pressKey", { action: label })
          : i18n.t("options.binding", { action: label, button: input.buttonName(action) });
    }
  }

  // ------------------------------------------------------------------------------------------------------- language
  setupLanguage() {
    ui.on("click", "language", () => {
      const all = i18n.languages;
      const next = all[(all.indexOf(i18n.language) + 1) % all.length];
      i18n.setLanguage(next); // every Text and widget with a key changes at once; "change" listeners run next frame
      this.s.language = next;
      settings.save(this.s);
    });
    this.refreshLanguage();
  }

  refreshLanguage() {
    const button = world.find("language").get("Button");
    button.text = i18n.t("options.language", { language: i18n.name(i18n.language) });
    button.interactable = i18n.languages.length > 1; // a game with one language has nothing to choose
  }

  onUpdate() {
    if (this.release) {
      // One frame after the capture, so the menus (and the pause key) ignored the press that was captured.
      MenuStack.busy = this.release = false;
    }
    if (!this.waiting || world.frame === this.waiting.since) return; // skip the press that clicked the button
    const pressed = input.lastPressed();
    if (!pressed) return;
    const { action, button } = this.waiting;
    this.waiting = null;
    this.release = true;
    if (pressed !== "Escape") {
      // Replace the bindings of the device that was pressed and keep the other device's: rebinding the keyboard
      // does not take the gamepad's buttons away.
      const pad = (b) => b.startsWith("Gamepad");
      const keep = input.bindings(action).filter((b) => pad(b) !== pad(pressed));
      const list = [pressed, ...keep];
      input.rebind(action, list);
      this.s.bindings[action] = list;
      settings.save(this.s);
    }
    this.refreshControls();
    ui.focus(button); // the key that was pressed may also have moved the focus
  }
}
