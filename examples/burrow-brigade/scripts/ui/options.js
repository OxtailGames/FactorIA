// @ts-check
// The options panel (prefabs/ui/options.prefab.json), opened by the main menu and by the pause menu. Tabs: Video (window mode,
// size, the monitor, vsync, frame cap, the colour filter, an accessibility option that works without a window, and the split screen for players who part),
// Audio (one slider per bus, read aloud, subtitles), Controls (rebinding, one page per player), Access (sound captions, reduced
// flashing, game speed, hold or toggle for the dig button of each player) and Language (cycles through the game's languages). Every change is
// applied at once and saved (scripts/settings.js), so the next run starts with it. The texts are string-table keys
// (locales/*.json): the widgets with a `key` are translated by the engine, the ones this script writes use i18n.t().
import { Behaviour, ui, input, window, world, i18n, platform } from "factoria";
import * as settings from "../settings.js";
import { MenuStack } from "./menu_stack.js";
import * as controls from "../game/controls.js";
import * as players from "../game/players.js";
import * as analytics from "../game/analytics.js";
import * as mix from "../game/mix.js";

const TABS = ["video", "audio", "controls", "access", "language"];
/** Frame caps the "Frame cap" button cycles through (0 = off). */
const FRAME_CAPS = [0, 30, 60, 120, 144];
const TAB_COLOR = [0.16, 0.18, 0.24, 0.92];
const TAB_SELECTED = [0.3, 0.36, 0.52, 0.96];

export default class Options extends Behaviour {
  runWhilePaused = true; // the pause menu opens it while game.paused
  onStart() {
    this.s = settings.load();
    this.waiting = null; // the action waiting for "press a key or button"
    this.release = false;
    for (const tab of TABS) ui.on("click", `tab_${tab}`, () => this.showTab(tab));
    this.showTab("video");
    this.setupVideo();
    this.setupAudio();
    this.setupControls();
    this.setupAccess();
    this.setupLanguage();
    this.setupPrivacy();
    this.setupAnalytics();
    // The texts this script writes are not translated by the engine: write them again in the new language.
    i18n.on("change", () => {
      this.refreshVideo();
      this.refreshControls();
      this.refreshAccess();
      this.refreshLanguage();
    });
  }

  /**
   * The rows sit in a scrolling list (`options_scroll`) so the panel never outgrows the screen. The list is left-aligned and its
   * width is mine: as wide as its widest visible row (at most the screen), so at a normal text size the panel is as narrow as
   * it always was and at a big one it grows with the rows.
   */
  fitList() {
    const list = world.find("options_scroll");
    if (!list?.alive || !this.entity.active) return;
    const origin = ui.rectOf(list) ?? [0, 0, 0, 0];
    let widest = 520;
    const visit = (e) => {
      for (const c of e.children) {
        if (!c.active) continue;
        if (c.has("Button") || c.has("Toggle") || c.has("Slider") || c.has("Text")) {
          const r = ui.rectOf(c);
          if (r) widest = Math.max(widest, Math.ceil(r[0] + r[2] - origin[0]));
        }
        visit(c);
      }
    };
    visit(list);
    const size = list.get("ScrollList").size;
    const width = Math.min(widest + 8, 1232);
    if (Math.abs(size[0] - width) > 0.5) list.get("ScrollList").size = [width, size[1]];
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
    vsync.interactable = has;
    this.refreshVideo();

    // The monitor row only exists where the game can move between monitors and this computer has more than one.
    world.find("monitor").active = window.supports("monitors") && window.monitors().length > 1;
    // Window mode cycles windowed, borderless and full screen (windowed and full screen where there is no borderless mode).
    ui.on("click", "display_mode", () => {
      const modes = window.supports("borderless") ? settings.DISPLAY_MODES : settings.DISPLAY_MODES.filter((m) => m !== "borderless");
      const next = modes[(modes.indexOf(window.mode) + 1) % modes.length];
      this.video("window mode", () => { window.setMode(next); s.displayMode = next; s.fullscreen = next !== "windowed"; });
    });
    ui.on("click", "monitor", () => {
      const next = (window.monitor + 1) % window.monitors().length;
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
    // Split screen: works without a window (it only decides whether miners may part and the camera splits), so it is always live.
    world.find("split_screen").get("Toggle").value = s.splitScreen === true;
    ui.on("change", "split_screen", (e) => {
      s.splitScreen = e.value;
      settings.save(s); // camera_views.js and follow_camera.js read it every frame
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
    const windowed = window.mode === "windowed";
    resolution.text = !windowed
      ? i18n.t("options.windowSizeFullscreen")
      : i18n.t("options.windowSize", { width: Math.round(size.x), height: Math.round(size.y) });
    resolution.interactable = window.supports("resize") && windowed; // full screen uses the display's size
    const mode = world.find("display_mode").get("Button");
    mode.text = i18n.t("options.displayMode", { mode: i18n.t(`options.mode.${window.mode}`) });
    mode.interactable = window.supports("fullscreen");
    const monitors = window.monitors();
    world.find("monitor").get("Button").text = i18n.t("options.monitor", { n: window.monitor + 1, name: monitors[window.monitor]?.name ?? "" });
    world.find("frame_cap").get("Button").interactable = window.supports("frameCap");
    world.find("frame_cap").get("Button").text = window.frameCap
      ? i18n.t("options.frameCap", { fps: window.frameCap })
      : i18n.t("options.frameCapOff");
    world.find("color_filter").get("Button").text = i18n.t("options.colorFilter", { filter: i18n.t(`options.filter.${this.s.colorFilter}`) });
  }

  // ------------------------------------------------------------------------------------------------------------ audio
  setupAudio() {
    for (const bus of settings.BUSES) {
      world.find(`${bus}_volume`).get("Slider").value = this.s.volume[bus];
      ui.on("change", `${bus}_volume`, (e) => {
        this.s.volume[bus] = e.value;
        mix.setUser(bus, e.value); // the mix puts the snapshot and the duck of the moment on top (scripts/game/mix.js)
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

  // ----------------------------------------------------------------------------------------------------------- access
  // Sound captions, reduced flashing, game speed, and hold or toggle for the dig button of each player. All of them work from the
  // keyboard, a gamepad or the mouse like every widget of the panel; each is applied at once and saved.
  setupAccess() {
    this.holdSeat = 0;
    world.find("sound_captions_toggle").get("Toggle").value = this.s.soundCaptions;
    ui.on("change", "sound_captions_toggle", (e) => {
      this.s.soundCaptions = e.value;
      settings.applySubtitles(this.s);
      settings.save(this.s);
    });
    world.find("reduced_flashing").get("Toggle").value = this.s.reducedEffects;
    ui.on("change", "reduced_flashing", (e) => {
      this.s.reducedEffects = e.value; // lights.js and hazards.js read it every frame
      settings.save(this.s);
    });
    ui.on("click", "game_speed", () => {
      const all = settings.GAME_SPEEDS;
      this.s.gameSpeed = all[(all.indexOf(settings.gameSpeedOf(this.s)) + 1) % all.length]; // a shift reads it when it starts
      settings.save(this.s);
      this.refreshAccess();
    });
    ui.on("click", "hold_player", () => {
      this.holdSeat = (this.holdSeat + 1) % players.MAX_PLAYERS;
      this.refreshAccess();
    });
    ui.on("click", "hold_mode", () => {
      this.s.holdMode[String(this.holdSeat)] = settings.holdModeOf(this.holdSeat, this.s) === "hold" ? "toggle" : "hold";
      settings.save(this.s);
      this.refreshAccess();
    });
    this.refreshAccess();
  }

  refreshAccess() {
    const speed = settings.gameSpeedOf(this.s);
    world.find("game_speed").get("Button").text = i18n.t("options.gameSpeed", { percent: Math.round(speed * 100) });
    world.find("hold_player").get("Button").text = i18n.t("options.player", { n: this.holdSeat + 1 });
    const mode = settings.holdModeOf(this.holdSeat, this.s);
    world.find("hold_mode").get("Button").text = i18n.t("options.holdMode", { mode: i18n.t(mode === "toggle" ? "options.holdModeToggle" : "options.holdModeHold") });
    world.find("access_note").get("Text").text = i18n.t(speed < 1 ? "options.gameSpeedNote" : "options.accessNote");
  }

  // --------------------------------------------------------------------------------------------------------- controls
  // One page per player (Player 1 to 4): each rebinds its own keyboard and gamepad (input.player(seat), scripts/game/controls.js), saved by seat. The
  // button at the top cycles the player; a row waits for a key or button and rebinds the list of the device that was pressed.
  setupControls() {
    const list = world.find("bindings");
    this.seat = 0;
    world.spawn({ id: "controls_player", components: { Button: { text: "Player 1", size: [640, 32], autoSize: true, fontSize: 20, layer: 302 } } }, { parent: list });
    ui.on("click", "controls_player", () => {
      if (this.waiting) return;
      this.seat = (this.seat + 1) % players.MAX_PLAYERS;
      this.refreshControls();
    });
    for (const action of controls.ACTIONS) {
      const button = world.spawn({ id: `bind_${action}`, components: { Button: { text: action, size: [640, 32], autoSize: true, fontSize: 20, layer: 302 } } }, { parent: list });
      ui.on("click", button, () => {
        if (this.waiting) return; // a press while waiting is the new binding (onUpdate), not a click
        this.waiting = { action, button, since: world.frame };
        MenuStack.busy = true; // Escape cancels the rebinding instead of closing the panel
        this.refreshControls();
      });
    }
    ui.on("click", "reset_controls", () => {
      controls.reset(this.seat);
      this.refreshControls();
    });
    this.refreshControls();
  }

  refreshControls() {
    world.find("controls_player").get("Button").text = i18n.t("options.player", { n: this.seat + 1 });
    for (const action of controls.ACTIONS) {
      const label = i18n.t(`options.action.${action}`);
      world.find(`bind_${action}`).get("Button").text =
        this.waiting?.action === action
          ? i18n.t("options.playerPress", { action: label })
          : i18n.t("options.playerBinding", { action: label, keys: controls.label(this.seat, "keys", action), pad: controls.label(this.seat, "pad", action) });
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

  // ----------------------------------------------------------------------------------------------------- analytics
  /** The opt-in switch for anonymous play statistics (scripts/game/analytics.js): off until the player says yes. */
  setupAnalytics() {
    world.find("analytics").get("Toggle").value = analytics.enabled();
    ui.on("change", "analytics", (e) => analytics.setConsent(!!e.value));
  }

  // ------------------------------------------------------------------------------------------------------- privacy
  /** The "Ad privacy settings" button: only where ads exist and the consent sheet says the player must be able to change their choice. */
  setupPrivacy() {
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

  onUpdate() {
    this.fitList();
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
    // Escape cancels; a mouse or touch press is not a binding. A key replaces the keyboard list of the action for this player,
    // a gamepad button or stick direction replaces its gamepad list: rebinding one does not take the other away.
    if (pressed !== "Escape" && !/^(Mouse|Touch)/.test(pressed)) {
      try {
        controls.rebind(this.seat, pressed.startsWith("Gamepad") ? "pad" : "keys", action, [pressed]);
      } catch (e) {
        console.warn(`options: ${pressed} was not taken as a binding: ${e.message}`); // the engine refuses a name the player's device cannot use
      }
    }
    this.refreshControls();
    ui.focus(button); // the key that was pressed may also have moved the focus
  }
}
