# Game menus: main menu, options, credits, loading screen, pause

New projects start with a camera and nothing else. When a game needs menus, the files below give it the usual set in a
few steps: a main menu, options (video, audio per bus, controls, a language slot), credits that list the software inside
the runtime, a loading screen and a pause menu. Everything works with only a keyboard, only a mouse or only a gamepad,
and the player's settings are saved between runs.

FactorIA's own tests run exactly these files, driven with gamepad presses only: copy them as they are, check that they
work, then change them. The widgets and `ui` events they use are in the AI guide (section 9.22) and in
`factoria docs read components` (`Panel`, `Button`, `Toggle`, `Slider`, `ScrollList`).

## Steps

1. **factoria.json.** Start on the menu, and add a `pause` action:
   `"mainScene": "scenes/menu.scene.json"` and, in `input.actions`, `"pause": ["Escape", "P", "GamepadStart"]`.
2. **Shared scripts.** `scripts/settings.js` keeps the player's settings in `storage` and applies them once per run;
   `scripts/ui/menu_stack.js` opens panels over each other and goes back.
3. **Main menu and credits.** `scenes/menu.scene.json`, `scripts/main_menu.js` and `scripts/ui/credits.js`. Put the
   game's name in the `title` Text and its first level in `MainMenu.firstScene`.
4. **Options.** `prefabs/ui/options.prefab.json` and `scripts/ui/options.js`. `Options.actions` lists the actions the
   player may rebind, with their labels: use your game's actions.
5. **Loading screen.** `scenes/loading.scene.json` and `scripts/loading.js`.
6. **Pause.** `prefabs/ui/pause.prefab.json`, `scripts/pause_menu.js`, and one entity in every level scene:
   `{ "id": "pause_menu", "components": { "Script": { "path": "scripts/pause_menu.js" } } }`.
7. **Check.** `factoria call scene.format` (the files below are written short; it rewrites them in the canonical
   layout), `factoria validate`, a screenshot of the menu (`factoria run --headless --frames 3 --screenshot-at 2`),
   and a test that drives the menus with the pad, such as `tests/recipe.test.js` at the end. `ui.state` lists every
   widget with its rectangle, focus and value.

## How it works, and what to change

- **Panels over panels.** `MenuStack.show(id)` hides the panel on top and shows panel `id`; its `autoFocus` widget takes
  the focus (a focused widget that becomes inactive loses it). `back()` closes the top panel and gives the focus back to
  the widget that had it. Pad B, Escape (`ui_cancel`) and any button tagged `back` call it.
- **Resume without a jump.** The A or Space press that clicks "Resume" is also `jump`. `pause_menu.js` unpauses in its
  next `onUpdate`, not in the click handler: that frame's gameplay was already skipped, so the press never reaches the
  player.
- **Pause and scene loads.** `game.paused` (`time.scale` 0) freezes physics, animations and every behaviour without
  `runWhilePaused = true`. `time.scale` outlives scene loads: set `game.paused = false` before `scene.load`.
- **One options panel in two places.** The menu scene places the prefab as an inactive entity; the pause menu spawns it,
  and the pause panel, when the level starts. A level needs only the `pause_menu` entity, even a level that
  `scene.import_ascii` rebuilds.
- **Loading screen.** Scene loads are synchronous: the loading scene is drawn once, then loads `session.nextScene`
  (`session` outlives scene loads).
- **Quit** has no place on phones and tablets, where the system closes apps: `main_menu.js` hides it when
  `game.platform` is `"ios"` or `"android"`.
- **Credits.** `game.notices()` lists the software inside the runtime with its license; the full texts ship next to the
  exported game in `FACTORIA_NOTICES.txt`. Add your own lines (people, music, fonts) to `Credits.lines`.
- **Audio.** One `Slider` per bus (`master`, `music`, `sfx`, `ui`); the defaults are `DEFAULTS.volume` in `settings.js`.
  `audio.getVolume(bus)` reads a volume back.
- **Video.** `window.setFullscreen`, `setSize` (one of `window.resolutions()`), `setVsync` and `frameCap`. They throw
  when there is no window (headless runs, tests): with `window.available` false the rows are greyed out and a note says
  why.
- **Controls.** A click on an action's button waits for the next press (`input.lastPressed()`, skipping the frame of the
  click), then `input.rebind(action, [pressed, ...the other device's bindings])` and saves the list. While it waits,
  `MenuStack.busy` keeps Escape and B from closing the panel. `input.buttonName(action)` names the button as the
  player's pad shows it (Cross on a PlayStation pad, A on an Xbox pad); "Reset to defaults" is `input.resetBindings()`.
- **Language.** A slot: the tab shows the current language, greyed out. Localization arrives with a later FactorIA
  milestone (M14); a game with translations of its own can make the button cycle through them meanwhile.
- **Add an option.** Add a widget to `options.prefab.json`, read and write its value in `options.js`, and keep it in
  `settings.js` (`DEFAULTS` and `apply`).
- **Restyle.** `color`, `textColor`, `accentColor`, or a `texture` with `slice` (9-slice) on any widget: AI guide
  section 9.22.

## The files

```js scripts/settings.js
// @ts-check
// The player's settings (volumes, video, controls), kept in storage under "settings" and applied once per run.
// scripts/ui/options.js edits them; main_menu.js and pause_menu.js call applyOnce() when their scene starts.
import { storage, audio, window, input, session } from "factoria";

/** Audio buses the options menu shows, in order. */
export const BUSES = ["master", "music", "sfx", "ui"];

const DEFAULTS = {
  volume: { master: 1, music: 0.6, sfx: 1, ui: 1 },
  fullscreen: null, // null: keep factoria.json display.fullscreen
  resolution: null, // [width, height] of the window, or null: the factoria.json size
  vsync: null, // null: keep factoria.json display.vsync
  frameCap: 0, // 0 = no cap
  bindings: {}, // action -> binding names, only for actions the player rebound
};

/** The saved settings merged over the defaults (a fresh object each call). */
export function load() {
  const saved = storage.get("settings", {});
  return { ...DEFAULTS, ...saved, volume: { ...DEFAULTS.volume, ...saved.volume }, bindings: { ...saved.bindings } };
}

export function save(s) {
  storage.set("settings", s);
}

/** Puts `s` into effect: bus volumes, rebound controls and, when the game has a real window, the video settings. */
export function apply(s = load()) {
  for (const bus of BUSES) audio.setVolume(bus, s.volume[bus]);
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
```

```js scripts/ui/menu_stack.js
// @ts-check
// A stack of menu panels. show(id) hides the current panel and shows another one over it; back() returns to the
// previous panel and gives the focus back to the widget that had it. Panels are entities shown and hidden with `active`;
// the first widget with autoFocus in a panel that appears takes the focus by itself (docs: UI focus rules).
import { world, ui } from "factoria";

export class MenuStack {
  /** True while a panel captures input for itself (options: "press a key"): back() does nothing then. */
  static busy = false;

  /** @param {string | null} root the panel that is always there (the main menu), or null (gameplay: nothing open) */
  constructor(root) {
    this.root = root;
    /** @type {Array<{ id: string, focus: any }>} */
    this.open = root ? [{ id: root, focus: null }] : [];
  }

  /** Id of the panel on top, or null when nothing is open. */
  get top() {
    return this.open.length ? this.open[this.open.length - 1].id : null;
  }

  /** Shows panel `id` over the current one. */
  show(id) {
    const below = this.open[this.open.length - 1];
    if (below) {
      below.focus = ui.focused;
      world.find(below.id).active = false;
    }
    this.open.push({ id, focus: null });
    world.find(id).active = true;
  }

  /** Closes the top panel (never the root). Returns false when there was nothing to close. */
  back() {
    if (MenuStack.busy || this.open.length === 0 || (this.root && this.open.length === 1)) return false;
    world.find(this.open.pop().id).active = false;
    const below = this.open[this.open.length - 1];
    if (below) {
      world.find(below.id).active = true;
      if (below.focus && below.focus.alive) ui.focus(below.focus);
    }
    return true;
  }

  /** Closes every panel but the root. */
  closeAll() {
    while (this.back());
  }
}
```

```json scenes/menu.scene.json
{
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "components": { "Transform": { "position": [640, 360, 0] }, "Camera": { "clearColor": [0.1, 0.12, 0.18, 1] } } },
    { "id": "main_menu",
      "components": {
        "Transform": { "position": [0, 20, 0] },
        "Panel": { "anchor": [0.5, 0.5], "color": [0, 0, 0, 0], "layout": "column", "spacing": 12, "fit": true },
        "Script": { "path": "scripts/main_menu.js" } },
      "children": [
        { "id": "title", "components": { "Text": { "text": "My Game", "fontSize": 64, "space": "screen" } } },
        { "id": "play", "components": { "Button": { "text": "Play", "autoFocus": true } } },
        { "id": "options_button", "components": { "Button": { "text": "Options" } } },
        { "id": "credits_button", "components": { "Button": { "text": "Credits" } } },
        { "id": "quit", "components": { "Button": { "text": "Quit" } } }
      ] },
    { "id": "options", "active": false, "prefab": "prefabs/ui/options.prefab.json" },
    { "id": "credits", "active": false,
      "components": {
        "Panel": { "size": [760, 620], "anchor": [0.5, 0.5], "layer": 300, "layout": "column", "spacing": 16, "padding": [24, 24, 24, 24] },
        "Script": { "path": "scripts/ui/credits.js" } },
      "children": [
        { "id": "credits_list", "components": { "ScrollList": { "size": [712, 476], "layer": 301, "color": [0, 0, 0, 0.25], "spacing": 14, "padding": [16, 16, 16, 16] } } },
        { "id": "credits_back", "tags": ["back"], "components": { "Button": { "text": "Back", "layer": 302, "autoFocus": true } } }
      ] }
  ]
}
```

```js scripts/main_menu.js
// @ts-check
// The title screen (scenes/menu.scene.json): Play, Options, Credits, Quit. Panels open over each other with MenuStack;
// a button tagged "back" or ui_cancel (Escape, gamepad B) returns to the previous panel.
import { Behaviour, ui, game, scene, session } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";

export default class MainMenu extends Behaviour {
  /** Scene the Play button starts, through the loading screen. */
  firstScene = "scenes/level.scene.json";

  onStart() {
    applyOnce();
    this.menus = new MenuStack("main_menu");
    if (game.platform === "ios" || game.platform === "android") this.world.find("quit").active = false; // mobile apps do not quit themselves
    ui.on("click", "play", () => {
      session.nextScene = this.firstScene; // scenes/loading.scene.json shows "Loading" for a frame, then loads it
      scene.load("scenes/loading.scene.json");
    });
    ui.on("click", "options_button", () => this.menus.show("options"));
    ui.on("click", "credits_button", () => this.menus.show("credits"));
    ui.on("click", "quit", () => game.quit());
    ui.on("click", (e) => e.entity.hasTag("back") && this.menus.back());
    ui.on("cancel", () => this.menus.back());
  }
}
```

```js scripts/ui/credits.js
// @ts-check
// The credits panel: the game's own lines, then the software inside the FactorIA runtime (game.notices(), the
// parts whose licenses FACTORIA_NOTICES.txt holds next to the exported game). ui_up/ui_down scroll the list.
import { Behaviour, game, input } from "factoria";

export default class Credits extends Behaviour {
  /** Lines shown after the game's name (factoria.json "name") and before the engine's notices. */
  lines = ["Made with FactorIA"];
  /** Scroll speed of ui_up/ui_down in pixels per second. */
  scrollSpeed = 500;

  onStart() {
    this.list = this.world.find("credits_list");
    const text = (s, fontSize = 22, color = [1, 1, 1, 1]) =>
      this.world.spawn({ components: { Text: { text: s, fontSize, color, space: "screen", maxWidth: 680, layer: 302 } } }, { parent: this.list });
    text(game.project.name, 34);
    for (const l of this.lines) text(l, 26);
    text("This game uses the following software:", 22, [0.75, 0.8, 0.9, 1]);
    for (const n of game.notices()) text(`${n.name}  (${n.license})\n${n.usedFor}\n${n.url}`, 20);
    text("The full license texts are in FACTORIA_NOTICES.txt, shipped with the game.", 18, [0.75, 0.8, 0.9, 1]);
  }

  onUpdate(dt) {
    if (!this.entity.active) return;
    this.list.get("ScrollList").scroll += input.axis("ui_up", "ui_down") * this.scrollSpeed * dt;
  }
}
```

```json prefabs/ui/options.prefab.json
{
  "format": "factoria.prefab/1",
  "entity": {
    "name": "Options",
    "components": {
      "Panel": { "size": [760, 620], "anchor": [0.5, 0.5], "layer": 300, "layout": "column", "spacing": 16, "padding": [24, 24, 24, 24] },
      "Script": { "path": "scripts/ui/options.js" }
    },
    "children": [
      { "name": "Title", "components": { "Text": { "text": "Options", "fontSize": 40, "space": "screen", "layer": 301 } } },
      { "name": "Tabs",
        "components": { "Panel": { "layer": 301, "color": [0, 0, 0, 0], "layout": "row", "padding": [0, 0, 0, 0], "fit": true } },
        "children": [
          { "id": "tab_video", "components": { "Button": { "text": "Video", "size": [160, 48], "layer": 302, "autoFocus": true } } },
          { "id": "tab_audio", "components": { "Button": { "text": "Audio", "size": [160, 48], "layer": 302 } } },
          { "id": "tab_controls", "components": { "Button": { "text": "Controls", "size": [160, 48], "layer": 302 } } },
          { "id": "tab_language", "components": { "Button": { "text": "Language", "size": [160, 48], "layer": 302 } } }
        ] },
      { "id": "video_section",
        "components": { "Panel": { "size": [712, 340], "layer": 301, "color": [0, 0, 0, 0.25], "layout": "column", "spacing": 12 } },
        "children": [
          { "id": "fullscreen", "components": { "Toggle": { "label": "Full screen", "size": [560, 44], "layer": 302 } } },
          { "id": "resolution", "components": { "Button": { "text": "Window size", "size": [560, 44], "layer": 302, "fontSize": 22 } } },
          { "id": "vsync", "components": { "Toggle": { "label": "VSync", "size": [560, 44], "layer": 302 } } },
          { "id": "frame_cap", "components": { "Button": { "text": "Frame cap", "size": [560, 44], "layer": 302, "fontSize": 22 } } },
          { "id": "video_note", "components": { "Text": { "text": "Video settings apply when the game runs in its own window.",
            "fontSize": 18, "color": [0.75, 0.8, 0.9, 1], "space": "screen", "layer": 302 } } }
        ] },
      { "id": "audio_section",
        "components": { "Panel": { "size": [712, 340], "layer": 301, "color": [0, 0, 0, 0.25], "layout": "column", "spacing": 12 } },
        "children": [
          { "id": "master_volume", "components": { "Slider": { "label": "Master", "size": [560, 44], "layer": 302 } } },
          { "id": "music_volume", "components": { "Slider": { "label": "Music", "size": [560, 44], "layer": 302 } } },
          { "id": "sfx_volume", "components": { "Slider": { "label": "Effects", "size": [560, 44], "layer": 302 } } },
          { "id": "ui_volume", "components": { "Slider": { "label": "Interface", "size": [560, 44], "layer": 302 } } }
        ] },
      { "id": "controls_section",
        "components": { "Panel": { "size": [712, 340], "layer": 301, "color": [0, 0, 0, 0.25], "layout": "column", "spacing": 12 } },
        "children": [
          { "id": "bindings", "components": { "Panel": { "layer": 301, "color": [0, 0, 0, 0], "layout": "column", "padding": [0, 0, 0, 0], "fit": true } } },
          { "id": "reset_controls", "components": { "Button": { "text": "Reset to defaults", "size": [560, 44], "layer": 302, "fontSize": 22 } } }
        ] },
      { "id": "language_section",
        "components": { "Panel": { "size": [712, 340], "layer": 301, "color": [0, 0, 0, 0.25], "layout": "column", "spacing": 12 } },
        "children": [
          { "id": "language", "components": { "Button": { "text": "Language: English", "size": [560, 44], "layer": 302, "interactable": false } } }
        ] },
      { "id": "options_back", "tags": ["back"], "components": { "Button": { "text": "Back", "layer": 302 } } }
    ]
  }
}
```

```js scripts/ui/options.js
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
      const button = world.spawn({ id: `bind_${action}`, components: { Button: { text: label, size: [560, 44], fontSize: 22, layer: 302 } } }, { parent: list });
      ui.on("click", button, () => {
        if (this.waiting) return; // a press while waiting is the new binding (onUpdate), not a click
        this.waiting = { action, button, since: world.frame };
        MenuStack.busy = true; // Escape cancels the rebinding instead of closing the panel
        button.get("Button").text = `${label}: press a key or button (Esc cancels)`;
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
```

```json scenes/loading.scene.json
{
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "components": { "Transform": { "position": [640, 360, 0] }, "Camera": { "clearColor": [0.1, 0.12, 0.18, 1] } } },
    { "id": "loading",
      "components": {
        "Transform": { "position": [-48, -48, 0] },
        "Text": { "text": "Loading...", "fontSize": 36, "space": "screen", "anchor": [1, 1], "pivot": [1, 0] },
        "Script": { "path": "scripts/loading.js" } } }
  ]
}
```

```js scripts/loading.js
// @ts-check
// scenes/loading.scene.json: scene loads are synchronous, so "Loading..." only has to be drawn once before
// scene.load. It waits two frames, then loads the scene the main menu put in session.nextScene.
import { Behaviour, scene, session } from "factoria";

export default class Loading extends Behaviour {
  frames = 0;

  onUpdate() {
    if (++this.frames === 2) scene.load(session.nextScene);
  }
}
```

```json prefabs/ui/pause.prefab.json
{
  "format": "factoria.prefab/1",
  "entity": {
    "name": "Pause",
    "components": {
      "Panel": { "size": [1280, 720], "anchor": [0.5, 0.5], "layer": 290, "color": [0, 0, 0, 0.55], "layout": "column", "justify": "center" }
    },
    "children": [
      { "id": "pause_box",
        "components": { "Panel": { "layer": 300, "layout": "column", "spacing": 12, "padding": [32, 24, 32, 32], "fit": true } },
        "children": [
          { "id": "pause_title", "components": { "Text": { "text": "Paused", "fontSize": 40, "layer": 301, "space": "screen" } } },
          { "id": "resume", "components": { "Button": { "text": "Resume", "layer": 302, "autoFocus": true } } },
          { "id": "pause_options", "components": { "Button": { "text": "Options", "layer": 302 } } },
          { "id": "to_main_menu", "components": { "Button": { "text": "Main menu", "layer": 302 } } }
        ] }
    ]
  }
}
```

```js scripts/pause_menu.js
// @ts-check
// Put this behaviour on one entity of every level: the "pause" action (Escape, P, gamepad Start) pauses the game and
// opens the pause menu. game.paused freezes physics, animations and the other scripts; this one keeps running
// (runWhilePaused) to drive the menu and its options panel.
import { Behaviour, ui, input, game, scene, world } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";

export default class PauseMenu extends Behaviour {
  runWhilePaused = true;

  onStart() {
    applyOnce();
    this.menus = new MenuStack(null);
    // Spawned, not written into the level: any level works with this one entity, even one scene.import_ascii rebuilds.
    for (const [id, prefab] of [["pause_panel", "pause"], ["options", "options"]]) {
      const panel = world.spawnPrefab(`prefabs/ui/${prefab}.prefab.json`);
      panel.id = id; // MenuStack shows panels by id
      panel.active = false;
    }
    ui.on("click", "resume", () => this.resume());
    ui.on("click", "pause_options", () => this.menus.show("options"));
    ui.on("click", "to_main_menu", () => {
      game.paused = false; // time.scale outlives scene loads
      scene.load("scenes/menu.scene.json");
    });
    ui.on("click", (e) => e.entity.hasTag("back") && this.back());
    // ui_cancel (Escape, gamepad B) goes back one panel. Escape is also "pause": onUpdate handles that press.
    ui.on("cancel", () => !input.pressed("pause") && this.back());
  }

  onUpdate() {
    if (this.resuming) {
      // Unpaused here, after this frame's gameplay was skipped: the A or Space press that clicked "Resume" must not
      // also reach the player as a jump.
      this.resuming = false;
      game.paused = false;
      return;
    }
    // The pause key opens the menu, and inside it goes back one panel like ui_cancel (from the pause panel: resume).
    if (input.pressed("pause") && !MenuStack.busy) game.paused ? this.back() : this.pause();
  }

  pause() {
    game.paused = true;
    this.menus.show("pause_panel");
  }

  resume() {
    this.menus.closeAll();
    this.resuming = true;
  }

  back() {
    if (this.menus.top === "pause_panel") this.resume();
    else this.menus.back();
  }
}
```

```js tests/recipe.test.js
import { test, expect, game } from "factoria:test";
import { ui, storage } from "factoria";

// Each test file starts on the project's mainScene (the main menu) with empty storage.
test("gamepad only: main menu -> options -> music volume -> back, and the volume is saved", () => {
  const pad = game.gamepad(0);
  game.step(2);
  pad.tap("DpadDown"); // Options
  pad.tap("A");
  pad.tap("DpadRight"); // the Audio tab
  pad.tap("A");
  pad.tap("DpadDown"); // Master
  pad.tap("DpadDown"); // Music
  pad.tap("DpadRight"); // 0.6 -> 0.7
  pad.tap("B"); // back to the main menu
  expect(ui.focused.id).toBe("options_button");
  expect(storage.get("settings").volume.music).toBeCloseTo(0.7);
});
```
