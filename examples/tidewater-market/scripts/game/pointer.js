// @ts-check
// The pointer: where "the mouse" is, for a mouse or for a gamepad.
//
// With a mouse nothing changes (input.mouse.position, ui.hovered). After the player touches a gamepad (input.lastDevice
// "gamepad") a virtual cursor takes over: the left stick moves it, A is the "primary" action (a click: factoria.json binds it),
// the widget under it takes the UI focus so A also presses buttons, flips toggles and so on, and a D-pad move of the focus moves
// the cursor to that widget. The cursor reaches every panel of the game and of the title. The engine tells which widget is under a
// point (ui.widgetAt) and hovers it for the cursor (ui.setPointer, a hover only: A presses through the focus, so a click is not sent
// twice); over nothing the focus is cleared (ui.focus(null) stays empty until the next D-pad press).
//
// The game reads `pointer.position()` and `pointer.hovered()` where it used to read the mouse; scripts/ui/pad_cursor.js (one
// entity per scene) calls `pointer.update()` every frame and draws the cursor. Nothing here touches the simulation.
import { input, ui, world, time } from "factoria";
import { DESIGN } from "./design.js";

/** Cursor speed in screen pixels per second at full tilt (it grows with the square of the tilt, so small moves are precise). */
export const CURSOR_SPEED = 720;
const CONTROLS = ["Button", "Toggle", "Slider"];

const state = {
  x: DESIGN.width / 2,
  y: DESIGN.height / 2,
  pad: false,
  frame: -1,
  /** the engine's pointer is ours (ui.setPointer) */
  virtual: false,
  /** @type {any} the widget under the cursor (pad mode) */
  under: null,
  /** the widget the cursor itself put the focus on, and the frame it did, so its focus event does not move the cursor */
  own: { id: "", frame: -10 },
  listening: false,
  /** the stick has moved the cursor since the gamepad was taken up */
  moved: false,
};

const clamp = (v, lo, hi) => (v < lo ? lo : v > hi ? hi : v);

/** The widget the cursor presses: the topmost widget at the point when it is a Button, Toggle or Slider that can be used, else null. */
function controlAt(x, y) {
  const e = ui.widgetAt(x, y);
  if (!e) return null;
  for (const c of CONTROLS) if (e.has(c)) return e.get(c).interactable !== false ? e : null;
  return null;
}

function listen() {
  if (state.listening) return;
  state.listening = true;
  ui.on("focus", (e) => {
    // the focus moved by the D-pad or the keyboard: the cursor goes to that widget (a focus the cursor itself set is not a move)
    if (!state.pad || !e.entity || !e.entity.alive) return;
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
    if (!state.pad && state.virtual) {
      state.virtual = false;
      ui.setPointer(null); // the mouse is the UI's pointer again
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
    ui.setPointer(state.x, state.y); // the hover follows the cursor; A presses through the focus
    state.virtual = true;
    const under = controlAt(state.x, state.y);
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
    // Over nothing, A must press nothing: the focus rests on nothing (the engine keeps it empty until the next D-pad press).
    if (state.moved && !under && !state.under && ui.focused) ui.focus(null);
  },

  /** Forget everything (a test that starts again; the scene's widgets are new). */
  reset() {
    state.under = null;
    state.pad = false;
    state.moved = false;
    state.listening = false;
    state.frame = -1;
    state.x = DESIGN.width / 2;
    state.y = DESIGN.height / 2;
    state.own = { id: "", frame: -10 };
    state.virtual = false;
  },
};
