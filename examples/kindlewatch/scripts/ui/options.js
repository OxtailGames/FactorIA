// @ts-check
// The options panel (prefabs/ui/options.prefab.json), opened by the main menu and by the pause menu. Tabs: Video (window mode,
// monitor, size, vsync, frame cap, the interface size and the colour filter, two accessibility options that work without a window),
// Audio (one slider per bus), Controls (rebinding every action of the game; with `players` above 1, for the player you pick) and Language
// (cycles through the game's languages). Every change is applied at once and saved (scripts/settings.js), so the next run starts with it. The texts are string-table keys
// (locales/*.json): the widgets with a `key` are translated by the engine, the ones this script writes use i18n.t().
import { Behaviour, ui, input, window, audio, world, i18n, platform, analytics, screen } from "factoria";
import * as settings from "../settings.js";
import { MenuStack } from "./menu_stack.js";

const TABS = ["video", "audio", "controls", "language"];
/** Frame caps the "Frame cap" button cycles through (0 = off). */
const FRAME_CAPS = [0, 30, 60, 120, 144];
/** Interface sizes (ui.scale) the "Interface size" button cycles through; only the ones this panel still fits the screen at are offered. */
const UI_SCALES = [0.75, 1, 1.25, 1.5, 2];
const TAB_COLOR = [0.16, 0.18, 0.24, 0.92];
const TAB_SELECTED = [0.3, 0.36, 0.52, 0.96];

/** @type {Array<{ section: string, id: string, text: () => string, click: () => void }>} */
const gameRows = [];

/**
 * Adds a row of the GAME to a section of the options (a Button that the panel keeps in step with the language), without editing the
 * panel's files. Call it before the panel is spawned: when the module that owns the game's setting loads, or in the host's onStart before
 * it spawns prefabs/ui/options.prefab.json. `section` is "video", "audio", "controls" or "language". `text()` returns the label (use
 * i18n.t; it is called again when the language changes and after every click), `click()` changes the setting (save it with
 * settings.save, the panel does not know it). The section grows by one row; the panel is sized for its Video tab, so a section with more
 * rows than that needs a taller prefab. A second call with the same id replaces the row.
 *   addOptionsRow("audio", { id: "screen_shake", text: () => i18n.t("options.shake", { on: s.shake }), click: () => toggleShake() });
 * @param {string} section
 * @param {{ id: string, text: () => string, click: () => void }} row
 */
export function addOptionsRow(section, row) {
  if (!TABS.includes(section)) throw new Error(`addOptionsRow: there is no options section "${section}". The sections are ${TABS.join(", ")}.`);
  const at = gameRows.findIndex((r) => r.id === row.id);
  if (at >= 0) gameRows.splice(at, 1);
  gameRows.push({ section, ...row });
}

export default class Options extends Behaviour {
  runWhilePaused = true; // the pause menu opens it while game.paused
  /**
   * Actions the Controls tab lets the player rebind, in this order. null (the default) lists every action the game has
   * except the ui_* ones. Set it in the prefab: "Script": { "path": "scripts/ui/options.js", "props": { "actions": ["move", "dig"] } }.
   * The labels are the strings "options.action.<action>"; an action without one is labelled with its name.
   */
  actions = null;
  /**
   * Local players that rebind their own controls (docs: scripting, input.player). 1 (the default) is a game with one set of
   * bindings: the Controls tab changes the global input. Above 1 the tab gets a "Player N" button on top that cycles through the
   * players, and each rebinds the keys and the gamepad buttons of input.player(i) only; what a player rebound is saved by player
   * (settings.playerBindings) and put back by settings.apply(). Set it in the prefab: "Script": { "path": "scripts/ui/options.js", "props": { "players": 2 } }.
   */
  players = 1;

  onStart() {
    this.s = settings.load();
    this.waiting = null; // the action waiting for "press a key or button"
    this.seat = 0; // the player the Controls tab shows (only when players > 1)
    this.release = false;
    for (const tab of TABS) ui.on("click", `tab_${tab}`, () => this.showTab(tab));
    this.showTab("video");
    this.setupVideo();
    this.setupAudio();
    this.setupTextSpeed();
    this.setupControls();
    this.setupLanguage();
    this.setupPrivacy();
    this.setupGameRows();
    // The texts this script writes are not translated by the engine: write them again in the new language.
    i18n.on("change", () => {
      this.refreshVideo();
      this.refreshTextSpeed();
      this.refreshControls();
      this.refreshLanguage();
      this.refreshGameRows();
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
    const vsync = world.find("vsync").get("Toggle");
    vsync.value = window.vsync;
    vsync.interactable = world.find("frame_cap").get("Button").interactable = world.find("window_mode").get("Button").interactable = has;
    // The monitor row only exists where the game can move between monitors and this computer has more than one.
    world.find("monitor").active = window.supports("monitors") && window.monitors().length > 1;
    this.refreshVideo();
    ui.on("scale", () => this.refreshVideo()); // the size changed (here, or a script): write the percentage again

    ui.on("click", "window_mode", () => {
      // windowed -> borderless -> fullscreen -> windowed (macOS cannot go from fullscreen straight to borderless); a platform without borderless skips it.
      const modes = window.supports("borderless") ? ["windowed", "borderless", "fullscreen"] : ["windowed", "fullscreen"];
      const next = modes[(modes.indexOf(window.mode) + 1) % modes.length];
      this.video("window mode", () => { window.setMode(next); s.windowMode = next; });
    });
    ui.on("click", "monitor", () => {
      const count = window.monitors().length;
      const next = (window.monitor + 1) % count;
      this.video("monitor", () => { window.setMonitor(next); s.monitor = settings.monitorChoice(next); });
    });
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
    ui.on("click", "ui_scale", () => {
      const sizes = this.uiScales();
      const next = sizes.find((k) => k > ui.scale + 1e-3) ?? sizes[0];
      ui.scale = next; // every widget of every screen, this panel included, at once (docs/TEXT.md, "Interface size")
      s.uiScale = next;
      settings.save(s);
      this.refreshVideo();
    });
    ui.on("click", "color_filter", () => {
      const all = settings.COLOR_FILTERS;
      s.colorFilter = all[(all.indexOf(s.colorFilter) + 1) % all.length];
      settings.applyColorFilter(s); // Camera.colorFilter: the whole frame, this panel included
      settings.save(s);
      this.refreshVideo();
    });
  }

  /**
   * The interface sizes to offer: the ones where this panel, drawn ui.scale times as big, still fits the screen (a bigger one
   * would leave the panel's edges and its Back button off screen), plus the size now in use, whatever it is.
   */
  uiScales() {
    const panel = this.entity.get("Panel").size; // in UI units: the size before ui.scale
    const screenSize = screen.size;
    const fits = UI_SCALES.filter((k) => panel.x * k <= screenSize.x && panel.y * k <= screenSize.y);
    if (!fits.includes(ui.scale)) fits.push(ui.scale);
    return fits.sort((a, b) => a - b);
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
    world.find("window_mode").get("Button").text = i18n.t("options.windowMode", { mode: i18n.t(`options.mode.${window.mode}`) });
    const monitors = window.monitors();
    world.find("monitor").get("Button").text = i18n.t("options.monitor", { n: window.monitor + 1, name: monitors[window.monitor]?.name ?? "" });
    const resolution = world.find("resolution").get("Button");
    resolution.text = window.fullscreen
      ? i18n.t("options.windowSizeFullscreen")
      : i18n.t("options.windowSize", { width: Math.round(size.x), height: Math.round(size.y) });
    resolution.interactable = window.available && !window.fullscreen; // full screen uses the display's size
    world.find("frame_cap").get("Button").text = window.frameCap
      ? i18n.t("options.frameCap", { fps: window.frameCap })
      : i18n.t("options.frameCapOff");
    const uiScale = world.find("ui_scale").get("Button");
    uiScale.text = i18n.t("options.uiScale", { percent: Math.round(ui.scale * 100) });
    uiScale.interactable = this.uiScales().length > 1; // nothing to choose when no other size fits
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

  // ------------------------------------------------------------------------------------------------------ text speed
  /** The "Text speed" button (the textSpeed part; without it the prefab has no such row and this does nothing). */
  setupTextSpeed() {
    const row = world.find("text_speed");
    if (!row) return;
    const panel = world.find("audio_section")?.get("Panel"); // the prefab's panel is sized without the row: grow it by one row, as addOptionsRow() does
    if (panel) panel.size = [panel.size.x, panel.size.y + 44 + panel.spacing];
    ui.on("click", "text_speed", () => {
      const all = settings.TEXT_SPEEDS;
      const at = all.findIndex((x) => x.cps === this.s.textSpeed);
      this.s.textSpeed = all[(at + 1) % all.length].cps;
      settings.save(this.s);
      this.refreshTextSpeed();
    });
    this.refreshTextSpeed();
  }

  refreshTextSpeed() {
    const row = world.find("text_speed");
    if (!row) return;
    const speed = settings.TEXT_SPEEDS.find((x) => x.cps === this.s.textSpeed);
    row.get("Button").text = i18n.t("options.textSpeed", { speed: i18n.t(`options.speed.${speed ? speed.name : "custom"}`) });
  }

  // ------------------------------------------------------------------------------------------------------- game rows
  /** Builds the buttons of addOptionsRow(). */
  setupGameRows() {
    for (const row of gameRows) {
      const section = world.find(`${row.section}_section`);
      if (!section || world.find(row.id)) continue;
      world.spawn({ id: row.id, components: { Button: { text: "", size: [560, 44], fontSize: 22, layer: 302, autoSize: true } } }, { parent: section });
      const panel = section.get("Panel");
      panel.size = [panel.size.x, panel.size.y + 44 + panel.spacing];
      ui.on("click", row.id, () => {
        row.click();
        this.refreshGameRows();
      });
    }
    this.refreshGameRows();
  }

  refreshGameRows() {
    for (const row of gameRows) {
      const entity = world.find(row.id);
      if (entity) entity.get("Button").text = row.text();
    }
  }

  // --------------------------------------------------------------------------------------------------------- controls
  setupControls() {
    const list = world.find("bindings");
    this.players = Math.max(1, Math.min(4, Math.round(Number(this.players)) || 1));
    if (this.players > 1) {
      world.spawn({ id: "controls_player", components: { Button: { text: "Player 1", size: [560, 44], fontSize: 22, layer: 302 } } }, { parent: list });
      ui.on("click", "controls_player", () => {
        if (this.waiting) return;
        this.seat = (this.seat + 1) % this.players;
        this.refreshControls();
      });
    }
    const have = input.actions();
    // An action the game does not have gets no row; without a list, every action but the menus' own ui_* ones.
    this.actions = this.actions ? this.actions.filter((action) => have.includes(action)) : have.filter((action) => !action.startsWith("ui_"));
    for (const action of this.actions) {
      const button = world.spawn({ id: `bind_${action}`, components: { Button: { text: action, size: [560, 44], fontSize: 22, layer: 302 } } }, { parent: list });
      ui.on("click", button, () => {
        if (this.waiting) return; // a press while waiting is the new binding (onUpdate), not a click
        this.waiting = { action, button, since: world.frame };
        MenuStack.busy = true; // Escape cancels the rebinding instead of closing the panel
        this.refreshControls();
      });
    }
    ui.on("click", "reset_controls", () => {
      if (this.players > 1) {
        input.player(this.seat).reset(); // this player only
        delete this.s.playerBindings[String(this.seat)];
      } else {
        input.resetBindings();
        this.s.bindings = {};
      }
      settings.save(this.s);
      this.refreshControls();
    });
    this.refreshControls();
  }

  /** The translated name of an action; the action's own name when the game has no "options.action.<action>" string. */
  actionLabel(action) {
    const key = `options.action.${action}`;
    return i18n.has(key) ? i18n.t(key) : action;
  }

  /** The buttons bound to an action for one list of a player ("keys" or "pad") as the player reads them: "Space / J", or "-" for none. */
  playerButtons(action, family) {
    const player = input.player(this.seat);
    const names = player.bindings(action, family);
    return names.length ? names.map((name) => input.buttonName(name, Math.max(0, player.pad))).join(" / ") : "-";
  }

  refreshControls() {
    if (this.players > 1) world.find("controls_player").get("Button").text = i18n.t("options.player", { n: this.seat + 1 });
    for (const action of this.actions) {
      const label = this.actionLabel(action);
      const text =
        this.players > 1
          ? i18n.t("options.playerBinding", { action: label, keys: this.playerButtons(action, "keys"), pad: this.playerButtons(action, "pad") })
          : i18n.t("options.binding", { action: label, button: input.buttonName(action) });
      world.find(`bind_${action}`).get("Button").text = this.waiting?.action === action ? i18n.t("options.pressKey", { action: label }) : text;
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

  // ------------------------------------------------------------------------------------------------------- privacy
  /** The "Ad privacy settings" button: only where ads exist and the consent sheet says the player must be able to change their choice. */
  setupPrivacy() {
    this.setupAnalytics();
    if (!platform.has("ads")) return;
    const button = world.find("privacy_options");
    platform.ads
      .consent()
      .then((consent) => {
        if (button.alive) button.active = consent.privacyOptions === "required"; // the panel may be gone by now
      })
      .catch((e) => console.warn(`options: the ad consent state could not be read: ${e.message}`));
    ui.on("click", "privacy_options", () => {
      platform.ads.privacyOptions().catch((e) => console.warn(`options: the privacy form did not open: ${e.message}`));
    });
  }

  /** The usage-data switch: only in a game whose factoria.json has an "analytics" section. It is the player's answer (analytics.setConsent); off forgets what waits to be sent. */
  setupAnalytics() {
    const row = world.find("analytics_toggle");
    row.active = analytics.configured;
    if (!analytics.configured) return;
    row.get("Toggle").value = analytics.consent() === "granted";
    ui.on("change", "analytics_toggle", (e) => row.alive && analytics.setConsent(e.value));
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
    if (pressed !== "Escape" && this.players > 1) {
      // A key or a chord (Ctrl+Z) replaces the keyboard list of the action for this player and a gamepad button or stick replaces its gamepad list; the
      // mouse and touch (also in a chord) belong to every player, so they are not bindings. The engine refuses a name the player's key scheme does not have.
      const player = input.player(this.seat);
      if (!/(^|\+)(Mouse|Touch)/.test(pressed)) {
        try {
          player.rebind(action, [pressed], pressed.startsWith("Gamepad") ? "pad" : "keys");
          this.s.playerBindings[String(this.seat)] = player.export();
          settings.save(this.s);
        } catch (e) {
          console.warn(`options: ${pressed} was not taken as a binding: ${e.message}`);
        }
      }
    } else if (pressed !== "Escape") {
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
