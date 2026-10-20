// @ts-check
// The options panel (prefabs/ui/options.prefab.json), opened by the main menu and by the pause menu. Tabs: Video,
// Audio (one slider per bus), Controls (rebinding), Language (cycles through the game's languages) and Accessibility
// (text size, assist mode, shake, reduced effects). Every change is
// applied at once and saved (scripts/settings.js), so the next run starts with it. The texts are string-table keys
// (locales/*.json): the widgets with a `key` are translated by the engine, the ones this script writes use i18n.t().
import { Behaviour, ui, input, game, window, audio, world, i18n } from "factoria";
import * as settings from "../settings.js";
import * as assist from "../assist.js";
import { MenuStack } from "./menu_stack.js";

const TABS = ["video", "audio", "controls", "language", "access"];
/** Frame caps the "Frame cap" button cycles through (0 = off). */
const FRAME_CAPS = [0, 30, 60, 120, 144];
const TAB_COLOR = [0.16, 0.18, 0.24, 0.92];
const TAB_SELECTED = [0.3, 0.36, 0.52, 0.96];

export default class Options extends Behaviour {
  runWhilePaused = true; // the pause menu opens it while game.paused
  /** Actions the Controls tab lets the player rebind; their labels are the strings "options.action.<action>". */
  actions = ["move_left", "move_right", "jump", "pause"];

  onStart() {
    this.s = settings.load();
    this.waiting = null; // the action waiting for "press a key or button"
    this.release = false;
    for (const tab of TABS) ui.on("click", `tab_${tab}`, () => this.showTab(tab));
    this.showTab("video");
    this.setupVideo();
    this.setupAudio();
    this.setupControls();
    this.setupLanguage();
    this.setupAccess();
    this.layout();
    // The texts this script writes are not translated by the engine: write them again in the new language.
    i18n.on("change", () => {
      this.refreshVideo();
      this.refreshControls();
      this.refreshLanguage();
      this.refreshAccess();
      this.layout();
    });
  }

  /** Sizes the panel for the player's text size: wider widgets, sections as tall as the tallest one, one panel that fits. */
  layout() {
    const scale = ui.textScale;
    ui.layout(); // the autoSize widgets have their size for this text size and language now
    const row = world.find("tab_video").get("Button").size[1]; // a tab and a row are both 44 px with a 22 px label, so a tab is the height of a row
    const note = Math.ceil(16 * scale * 1.3) * 2; // the video note, wrapped to two lines
    // At a big text size the gaps shrink so that the taller rows still leave the panel inside the screen.
    const gap = scale > 1.25 ? 6 : 12;
    const height = Math.max(5 * row + 4 * gap, 4 * row + 4 * gap + note) + 32;
    const panel = this.entity.get("Panel");
    panel.spacing = scale > 1.25 ? 8 : 16;
    panel.padding = scale > 1.25 ? [12, 12, 12, 12] : [24, 24, 24, 24];
    for (const tab of TABS) world.find(`${tab}_section`).get("Panel").spacing = gap;
    const width = Math.min(1240, Math.round(760 + (scale - 1) * 480));
    for (const tab of TABS) world.find(`${tab}_section`).get("Panel").size = [width - 48, height];
    this.entity.get("Panel").size = [width, 0]; // fit: the height follows the content
    const noteText = world.find("video_note").get("Text");
    noteText.maxWidth = width - 48 - 32;
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
    fullscreen.interactable = vsync.interactable = world.find("frame_cap").get("Button").interactable = has;
    this.refreshVideo();

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
      const next = FRAME_CAPS[(FRAME_CAPS.indexOf(window.frameCap) + 1) % FRAME_CAPS.length];
      this.video("frame cap", () => { window.frameCap = next; s.frameCap = next; });
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
    world.find("frame_cap").get("Button").text = window.frameCap
      ? i18n.t("options.frameCap", { fps: window.frameCap })
      : i18n.t("options.frameCapOff");
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
  }

  // --------------------------------------------------------------------------------------------------------- controls
  setupControls() {
    const list = world.find("bindings");
    for (const action of this.actions) {
      const button = world.spawn({ id: `bind_${action}`, components: { Button: { text: action, size: [560, 44], fontSize: 22, autoSize: true, layer: 302 } } }, { parent: list });
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

  // --------------------------------------------------------------------------------------------------- accessibility
  setupAccess() {
    const s = this.s;
    const step = (list, value) => list[(Math.max(0, list.findIndex((v) => Math.abs(v - value) < 1e-6)) + 1) % list.length];
    ui.on("click", "text_size", () => {
      s.textScale = step(settings.TEXT_SCALES, s.textScale);
      ui.textScale = s.textScale;
      settings.save(s);
      this.refreshAccess();
      this.layout();
    });
    ui.on("click", "game_speed", () => {
      s.assist.speed = step(settings.SPEEDS, s.assist.speed);
      settings.save(s);
      if (game.paused) assist.applySpeed(); // opened from the pause menu: the level stays frozen, resuming restores this speed
      this.refreshAccess();
    });
    const toggle = (id, set) => {
      ui.on("change", id, (e) => {
        set(e.value);
        settings.save(s);
      });
    };
    toggle("invincible", (v) => (s.assist.invincible = v));
    toggle("screen_shake", (v) => (s.shake = v));
    toggle("reduced_effects", (v) => (s.reducedEffects = v));
    world.find("invincible").get("Toggle").value = s.assist.invincible;
    world.find("screen_shake").get("Toggle").value = s.shake;
    world.find("reduced_effects").get("Toggle").value = s.reducedEffects;
    this.refreshAccess();
  }

  refreshAccess() {
    const percent = (v) => Math.round(v * 100);
    world.find("text_size").get("Button").text = i18n.t("options.accessibility.textSize", { percent: percent(this.s.textScale) });
    world.find("game_speed").get("Button").text = i18n.t("options.accessibility.speed", { percent: percent(this.s.assist.speed) });
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
