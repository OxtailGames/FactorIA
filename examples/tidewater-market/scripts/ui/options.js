// @ts-check
// The options panel (prefabs/ui/options.prefab.json), opened by the main menu and by the pause menu. Tabs: Video (window mode,
// monitor, size, vsync, frame cap and the colour filter, an accessibility option that works without a window),
// Audio (one slider per bus: master, music, ambience, effects, interface), Controls (rebinding every action of the game, a key
// another action already has is refused and said; with `players` above 1, for the player you pick), Access (text size, interface size,
// colour-blind safe signals, reduced motion, hold-free controls) and Language (cycles through the game's languages). Every change is applied at once and saved (scripts/settings.js), so the next run starts with it. The texts are string-table keys
// (locales/*.json): the widgets with a `key` are translated by the engine, the ones this script writes use i18n.t().
import { Behaviour, ui, input, window, audio, world, i18n, platform, analytics } from "factoria";
import * as settings from "../settings.js";
import { setUiScale } from "../game/ui_kit.js";
import { MenuStack } from "./menu_stack.js";

const TABS = ["video", "audio", "controls", "access", "language"];
/** Frame caps the "Frame cap" button cycles through (0 = off). */
const FRAME_CAPS = [0, 30, 60, 120, 144];
const TAB_COLOR = [0.16, 0.18, 0.24, 0.92];
const TAB_SELECTED = [0.3, 0.36, 0.52, 0.96];

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
    this.setupControls();
    this.setupAccess();
    this.setupLanguage();
    this.setupPrivacy();
    // The texts this script writes are not translated by the engine: write them again in the new language.
    i18n.on("change", () => {
      this.refreshVideo();
      this.refreshControls();
      this.refreshAccess();
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
    const vsync = world.find("vsync").get("Toggle");
    vsync.value = window.vsync;
    vsync.interactable = world.find("frame_cap").get("Button").interactable = world.find("window_mode").get("Button").interactable = has;
    // The monitor row only exists where the game can move between monitors and this computer has more than one.
    world.find("monitor").active = window.supports("monitors") && window.monitors().length > 1;
    this.refreshVideo();

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
    world.find("color_filter").get("Button").text = i18n.t("options.colorFilter", { filter: i18n.t(`options.filter.${this.s.colorFilter}`) });
  }

  // ------------------------------------------------------------------------------------------------------------ audio
  setupAudio() {
    for (const bus of settings.MIX_BUSES) {
      world.find(`${bus}_volume`).get("Slider").value = this.s.volume[bus];
      ui.on("change", `${bus}_volume`, (e) => {
        this.s.volume[bus] = e.value;
        // "ambience" is the game's own bus: the engine has four (master, music, sfx, ui); the soundscape reads settings.live().ambience
        if (settings.BUSES.includes(bus)) audio.setVolume(bus, e.value);
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

  // ------------------------------------------------------------------------------------------------------ access
  setupAccess() {
    const s = this.s;
    const next = (list, value) => list[(Math.max(0, list.indexOf(value)) + 1) % list.length];
    ui.on("click", "text_scale", () => {
      s.textScale = next(settings.TEXT_SCALES, s.textScale);
      ui.textScale = s.textScale;
      settings.save(s);
      this.refreshAccess();
    });
    ui.on("click", "ui_scale", () => {
      s.uiScale = next(settings.UI_SCALES, s.uiScale);
      setUiScale(s.uiScale);
      settings.save(s);
      this.refreshAccess();
    });
    for (const [id, field] of [["safe_colors", "safeColors"], ["reduced_motion", "reducedMotion"], ["hold_free", "holdFree"]]) {
      world.find(id).get("Toggle").value = !!s[field];
      ui.on("change", id, (e) => {
        s[field] = e.value;
        settings.save(s); // settings.live() is what the game reads every frame
      });
    }
    this.refreshAccess();
  }

  refreshAccess() {
    const percent = (n) => Math.round(n * 100);
    world.find("text_scale").get("Button").text = i18n.t("options.textScale", { value: percent(this.s.textScale) });
    world.find("ui_scale").get("Button").text = i18n.t("options.uiScale", { value: percent(this.s.uiScale) });
  }

  /**
   * Another action of the game (not a menu one, ui_*) that already uses `name`, or null. Keys the action has itself do not count.
   * @param {string} action @param {string} name @returns {string | null}
   */
  conflict(action, name) {
    for (const other of input.actions()) {
      if (other === action || other.startsWith("ui_")) continue;
      if (input.bindings(other).includes(name)) return other;
    }
    return null;
  }

  setNote(text) {
    const note = world.find("controls_note");
    if (note) note.get("Text").text = text;
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
      // A key replaces the keyboard list of the action for this player and a gamepad button or stick replaces its gamepad list; the
      // mouse and touch belong to every player, so they are not bindings. The engine refuses a name the player's key scheme does not have.
      const player = input.player(this.seat);
      if (!/^(Mouse|Touch)/.test(pressed)) {
        try {
          player.rebind(action, [pressed], pressed.startsWith("Gamepad") ? "pad" : "keys");
          this.s.playerBindings[String(this.seat)] = player.export();
          settings.save(this.s);
        } catch (e) {
          console.warn(`options: ${pressed} was not taken as a binding: ${e.message}`);
        }
      }
    } else if (pressed !== "Escape") {
      const clash = this.conflict(action, pressed);
      if (clash) {
        // Two actions on one key would fire together. Refuse, keep the old binding and say which action has the key.
        this.setNote(i18n.t("options.conflict", { button: input.buttonName(pressed), other: this.actionLabel(clash), action: this.actionLabel(action) }));
        this.refreshControls();
        ui.focus(button);
        return;
      }
      this.setNote("");
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
