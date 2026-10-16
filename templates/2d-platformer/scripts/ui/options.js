// @ts-check
// The options panel (prefabs/ui/options.prefab.json), opened by the main menu and by the pause menu. Tabs: Video,
// Audio (one slider per bus), Controls (rebinding) and Language (a placeholder until localization). Every change is
// applied at once and saved (scripts/settings.js), so the next run starts with it.
import { Behaviour, ui, input, window, audio, world } from "factoria";
import * as settings from "../settings.js";
import { MenuStack } from "./menu_stack.js";

const TABS = ["video", "audio", "controls", "language"];
/** Frame caps the "Frame cap" button cycles through (0 = off). */
const FRAME_CAPS = [0, 30, 60, 120, 144];
const TAB_COLOR = [0.16, 0.18, 0.24, 0.92];
const TAB_SELECTED = [0.3, 0.36, 0.52, 0.96];

export default class Options extends Behaviour {
  runWhilePaused = true; // the pause menu opens it while game.paused
  /** Actions the Controls tab lets the player rebind, and their labels. */
  actions = { move_left: "Move left", move_right: "Move right", jump: "Jump", pause: "Pause" };

  onStart() {
    this.s = settings.load();
    this.waiting = null; // the action waiting for "press a key or button"
    this.release = false;
    for (const tab of TABS) ui.on("click", `tab_${tab}`, () => this.showTab(tab));
    this.showTab("video");
    this.setupVideo();
    this.setupAudio();
    this.setupControls();
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
    for (const id of ["fullscreen", "resolution", "vsync", "frame_cap"]) world.find(id).get(id === "resolution" || id === "frame_cap" ? "Button" : "Toggle").interactable = has;
    this.refreshVideo();

    ui.on("change", "fullscreen", (e) => this.video("full screen", () => window.setFullscreen(e.value), () => (s.fullscreen = e.value)));
    ui.on("change", "vsync", (e) => this.video("vsync", () => window.setVsync(e.value), () => (s.vsync = e.value)));
    ui.on("click", "resolution", () => {
      const sizes = window.resolutions();
      const now = window.size;
      const i = sizes.findIndex((r) => r.width === Math.round(now.x) && r.height === Math.round(now.y));
      const next = sizes[(i + 1) % sizes.length];
      this.video("window size", () => window.setSize(next.width, next.height), () => (s.resolution = [next.width, next.height]));
    });
    ui.on("click", "frame_cap", () => {
      const next = FRAME_CAPS[(FRAME_CAPS.indexOf(window.frameCap) + 1) % FRAME_CAPS.length];
      this.video("frame cap", () => (window.frameCap = next), () => (s.frameCap = next));
    });
  }

  /** Runs a window change; saves it when it worked, shows why when it did not. */
  video(what, change, remember) {
    try {
      change();
      remember();
      settings.save(this.s);
    } catch (e) {
      console.warn(`options: ${what} could not be changed: ${e.message}`);
    }
    this.refreshVideo();
  }

  refreshVideo() {
    const size = window.size;
    const resolution = world.find("resolution").get("Button");
    resolution.text = window.fullscreen ? "Window size: full screen" : `Window size: ${Math.round(size.x)} x ${Math.round(size.y)}`;
    resolution.interactable = window.available && !window.fullscreen; // full screen uses the display's size
    world.find("frame_cap").get("Button").text = `Frame cap: ${window.frameCap ? window.frameCap + " fps" : "off"}`;
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
    for (const [action, label] of Object.entries(this.actions)) {
      const button = world.spawn({ id: `bind_${action}`, components: { Button: { text: label, size: [480, 44], fontSize: 22 } } }, { parent: list });
      ui.on("click", button, () => {
        if (this.waiting) return; // a press while waiting is the new binding (onUpdate), not a click
        this.waiting = { action, button, since: world.frame };
        MenuStack.busy = true; // Escape cancels the rebinding instead of closing the panel
        button.get("Button").text = `${label}: press a key or button (Escape cancels)`;
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
    for (const [action, label] of Object.entries(this.actions))
      world.find(`bind_${action}`).get("Button").text = `${label}: ${input.buttonName(action)}`;
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
