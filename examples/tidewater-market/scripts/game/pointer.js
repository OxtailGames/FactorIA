// @ts-check
// The pointer: where "the mouse" is, for a mouse or for a gamepad.
//
// With a mouse nothing changes (input.mouse.position, ui.hovered). After the player touches a gamepad (input.lastDevice
// "gamepad") a virtual cursor takes over: the left stick moves it, A is the "primary" action (a click: factoria.json binds it),
// the widget under it takes the UI focus so A also presses buttons, flips toggles and so on, and a D-pad move of the focus moves
// the cursor to that widget. The cursor reaches every panel of the game and of the title. The engine has no virtual cursor and
// no way to ask which widget is under a point (ENGINE_FEEDBACK FB-0046), so this module looks for the widgets itself.
//
// The game reads `pointer.position()` and `pointer.hovered()` where it used to read the mouse; scripts/ui/pad_cursor.js (one
// entity per scene) calls `pointer.update()` every frame and draws the cursor. Nothing here touches the simulation.
import { input, ui, world, time } from "factoria";
import { DESIGN } from "./camera_math.js";

/** Cursor speed in screen pixels per second at full tilt (it grows with the square of the tilt, so small moves are precise). */
export const CURSOR_SPEED = 720;
/** Frames between two looks for the widgets of the scene (a panel that opens is found at the next look, or at once after a click). */
const SCAN_EVERY = 10;
const WIDGETS = ["Button", "Toggle", "Slider"];

const state = {
  x: DESIGN.width / 2,
  y: DESIGN.height / 2,
  pad: false,
  frame: -1,
  /** @type {any[]} */
  widgets: [],
  scanned: -1000,
  /** @type {any} the widget under the cursor (pad mode) */
  under: null,
  /** the widget the cursor itself put the focus on, and the frame it did, so its focus event does not move the cursor */
  own: { id: "", frame: -10 },
  listening: false,
  /** the stick has moved the cursor since the gamepad was taken up */
  moved: false,
  /** @type {any} the widget that holds the focus while the cursor is over nothing */
  sink: null,
};

const clamp = (v, lo, hi) => (v < lo ? lo : v > hi ? hi : v);

function rescan() {
  state.widgets = world.entities().filter((e) => WIDGETS.some((c) => e.has(c)));
  state.scanned = world.frame;
}

function layerOf(e) {
  for (const c of WIDGETS) if (e.has(c)) return e.get(c).layer ?? 0;
  return 0;
}

function interactable(e) {
  for (const c of WIDGETS) if (e.has(c)) return e.get(c).interactable !== false;
  return false;
}

/** Is the widget inside a ScrollList that does not cover the point (a row scrolled out of view)? */
function clippedAt(e, x, y) {
  for (let p = e.parent; p; p = p.parent) {
    if (!p.has("ScrollList")) continue;
    const r = ui.rectOf(p);
    if (r && (x < r.x || x >= r.x + r.w || y < r.y || y >= r.y + r.h)) return true;
  }
  return false;
}

/** The widget at a screen point (the topmost one), or null. */
function widgetAt(x, y) {
  if (world.frame - state.scanned >= SCAN_EVERY) rescan();
  let best = null;
  let bestLayer = -Infinity;
  for (const e of state.widgets) {
    if (!e.alive || e.activeInHierarchy === false || !interactable(e)) continue;
    const r = ui.rectOf(e);
    if (!r || x < r.x || x >= r.x + r.w || y < r.y || y >= r.y + r.h) continue;
    if (clippedAt(e, x, y)) continue;
    const layer = layerOf(e);
    if (layer >= bestLayer) {
      best = e;
      bestLayer = layer;
    }
  }
  return best;
}

function listen() {
  if (state.listening) return;
  state.listening = true;
  // a panel opened by a click is found at once
  ui.on("click", () => (state.scanned = -1000));
  ui.on("focus", (e) => {
    // the focus moved by the D-pad or the keyboard: the cursor goes to that widget (a focus the cursor itself set is not a move)
    if (!state.pad || !e.entity || !e.entity.alive || e.entity === state.sink) return;
    const id = e.entity.id;
    if (id === state.own.id && world.frame - state.own.frame <= 3) return;
    const r = ui.rectOf(e.entity);
    if (!r) return;
    state.x = clamp(r.x + r.w / 2, 0, DESIGN.width);
    state.y = clamp(r.y + r.h / 2, 0, DESIGN.height);
    state.under = e.entity;
  });
}

export const pointer = {
  /** Is the gamepad cursor in use (the last input came from a gamepad)? */
  get pad() {
    this.update();
    return state.pad;
  },

  /** The pointer's place in screen pixels: the virtual cursor after gamepad input, else the mouse. */
  position() {
    this.update();
    return state.pad ? { x: state.x, y: state.y } : input.mouse.position;
  },

  /** The widget under the pointer, or null (the engine's own hover for a mouse). */
  hovered() {
    this.update();
    return state.pad ? state.under : ui.hovered;
  },

  /** Put the cursor somewhere (tests, scripts that move the player's attention). */
  moveTo(x, y) {
    state.x = clamp(x, 0, DESIGN.width);
    state.y = clamp(y, 0, DESIGN.height);
    state.frame = -1;
  },

  /** Once per frame (a second call in the same frame does nothing): move the cursor, find the widget under it, give it the focus. */
  update() {
    if (state.frame === world.frame) return;
    state.frame = world.frame;
    listen();
    const mouse = input.mouse;
    const device = input.lastDevice;
    if (device === "gamepad") state.pad = true;
    else if (device === "mouse" || device === "touch" || mouse.delta.x !== 0 || mouse.delta.y !== 0) {
      state.pad = false;
      state.moved = false;
    }
    if (!state.pad) {
      state.x = mouse.position.x;
      state.y = mouse.position.y;
      state.under = null;
      return;
    }
    const stick = input.vector("cursor_left", "cursor_right", "cursor_down", "cursor_up");
    const tilt = Math.hypot(stick.x, stick.y);
    if (tilt > 0) {
      state.moved = true;
      const dt = time.unscaledDt || 1 / 60;
      state.x = clamp(state.x + stick.x * tilt * CURSOR_SPEED * dt, 0, DESIGN.width);
      state.y = clamp(state.y - stick.y * tilt * CURSOR_SPEED * dt, 0, DESIGN.height);
    }
    const under = widgetAt(state.x, state.y);
    if ((under ? under.id : "") !== (state.under ? state.under.id : "")) {
      state.under = under;
      // the widget under the cursor takes the focus (so A presses it) once the stick moved the cursor; before that the D-pad owns the focus
      if (!state.moved) return;
      if (under) {
        state.own = { id: under.id, frame: world.frame };
        ui.focus(under);
        return;
      }
    }
    // Over nothing, A must press nothing: the focus goes to the sink (a widget that does nothing, off the screen). Clearing the focus
    // would not do: the engine gives it back to the first autoFocus widget of an open panel, which would pull the cursor there.
    if (state.moved && !under && !state.under && state.sink && state.sink.alive && ui.focused !== state.sink) {
      state.own = { id: state.sink.id, frame: world.frame };
      ui.focus(state.sink);
    }
  },

  /** The widget that takes the focus while the cursor is over nothing (pad_cursor.js makes it). */
  setSink(entity) {
    state.sink = entity;
  },

  /** Forget everything (a test that starts again; the scene's widgets are new). */
  reset() {
    state.widgets = [];
    state.scanned = -1000;
    state.under = null;
    state.pad = false;
    state.moved = false;
    state.listening = false;
    state.frame = -1;
    state.x = DESIGN.width / 2;
    state.y = DESIGN.height / 2;
    state.own = { id: "", frame: -10 };
    state.sink = null;
  },
};
