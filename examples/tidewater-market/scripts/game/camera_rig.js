// @ts-check
// The strategy camera: right/middle-drag pans, the wheel zooms towards the cursor, the screen edges and WASD/arrows scroll,
// PageUp/PageDown zoom around the screen centre, and the view never leaves the map (plus a margin). Put this behaviour on the
// camera entity. The maths is scripts/game/camera_math.js (pure, unit tested); this class only reads the input and writes the
// camera entity's Transform and Camera.orthoSize.
//
// P6: the pointer is scripts/game/pointer.js (the mouse, or the gamepad's virtual cursor); the right stick pans like WASD. A move to
// another place (`moveTo`: a click on a notice) is eased over a third of a second, or instant with the "reduced motion" option.
// "Hold-free" (option, or a gamepad in use): the middle button latches the drag (press to start, press again to stop) and a click
// in the strip along a screen edge moves the view a step that way, so nothing needs a button held down.
import { Behaviour, input, game, ui } from "factoria";
import { worldToCell } from "./iso.js";
import { pointer } from "./pointer.js";
import { live } from "../settings.js";
import {
  DESIGN, clampView, orthoSizeFor, screenToWorld, worldToScreen, zoomAt, zoomStep, ZOOM_MIN, ZOOM_MAX,
} from "./camera_math.js";

export default class CameraRig extends Behaviour {
  /** Scroll speed in screen pixels per second (so it feels the same at every zoom). */
  panSpeed = 900;
  /** Width in pixels of the screen-edge zone that scrolls the map; 0 turns edge scrolling off. */
  edgeSize = 8;
  /** Zoom factor per second for PageUp / PageDown. */
  keyZoomRate = 1.8;
  /** How far past the map's edge the view may go, in world units. */
  margin = 200;
  /** The view at the start; the controller sets the real one with setBounds / setView. */
  startZoom = 1;
  /** When true the camera ignores input (a title-screen backdrop drives it from a script). */
  frozen = false;
  /** Seconds an eased move takes (`moveTo`). */
  easeSeconds = 0.35;
  /** Width in pixels of the strip along a screen edge where a click moves the view (hold-free controls). */
  edgeClickSize = 14;
  /** How far an edge click moves the view, in screen pixels. */
  edgeClickStep = 280;

  onStart() {
    const p = this.entity.position;
    this.view = { x: p.x, y: p.y, zoom: this.startZoom };
    this.bounds = null;
    this.mouseSeen = false;
    this.dragging = false;
    /** @type {{ from: import("./camera_math.js").View, to: import("./camera_math.js").View, t: number } | null} the eased move in progress */
    this.ease = null;
    this.latched = false;
    this.apply();
  }

  /**
   * Go to a view: eased over `easeSeconds`, or at once when the player asked for reduced motion. Any input from the player stops it.
   * @param {number} x @param {number} y @param {number} [zoom] default: keep the zoom
   */
  moveTo(x, y, zoom = this.view.zoom) {
    if (live().reducedMotion) return this.setView(x, y, zoom);
    this.ease = { from: { ...this.view }, to: { x, y, zoom }, t: 0 };
  }

  /** The world rectangle the view must stay in ({ minX, maxX, minY, maxY }), or null for no limit. */
  setBounds(bounds) {
    this.bounds = bounds;
    this.apply();
  }

  /** Jump to a view. */
  setView(x, y, zoom) {
    this.ease = null;
    this.view = { x, y, zoom };
    this.apply();
  }

  /** The world point under a screen pixel. */
  screenToWorld(sx, sy) {
    return screenToWorld(this.view, sx, sy);
  }

  /** The map cell under a screen pixel, as [c, r]. */
  screenToCell(sx, sy) {
    const [x, y] = this.screenToWorld(sx, sy);
    return worldToCell(x, y);
  }

  worldToScreen(wx, wy) {
    return worldToScreen(this.view, wx, wy);
  }

  /** Keep the view legal and write it to the camera entity. */
  apply() {
    if (this.bounds) this.view = clampView(this.view, this.bounds, this.margin);
    this.entity.position = [this.view.x, this.view.y, 0];
    this.entity.get("Camera").orthoSize = orthoSizeFor(this.view.zoom);
  }

  onUpdate(dt) {
    if (this.frozen) return;
    const v = this.view;
    const mouse = input.mouse;
    const m = pointer.position();
    const free = live().holdFree || pointer.pad;
    if (!this.mouseSeen && (mouse.delta.x !== 0 || mouse.delta.y !== 0 || input.mouse.down("left") || input.mouse.down("right"))) this.mouseSeen = true;

    // zoom towards the cursor with the wheel
    const wheel = mouse.wheel;
    // (a ScrollList under the pointer keeps the wheel: it reads 0 here then; ui.pointerOverUi keeps every other panel off the map)
    const overUi = ui.pointerOverUi || this.wheelBlocked; // wheelBlocked: only an open event card (modal), set by the Hud
    if (wheel !== 0 && !overUi) this.ease = null;
    if (wheel !== 0 && !overUi) this.view = zoomAt(v, zoomStep(v.zoom, wheel), m.x, m.y);
    // zoom around the centre with the keys
    const keyZoom = input.axis("zoom_out", "zoom_in");
    if (keyZoom !== 0) this.view = zoomAt(this.view, this.view.zoom * Math.pow(this.keyZoomRate, keyZoom * dt), DESIGN.width / 2, DESIGN.height / 2);

    // pan: drag, keys, screen edges (screen pixels per second, converted to world units by the zoom)
    let dx = 0;
    let dy = 0;
    if (free && input.pressed("pan_latch")) this.latched = !this.latched;
    if (!free || input.pressed("tool_cancel") || input.pressed("escape")) this.latched = false;
    this.dragging = input.down("pan_drag") || (free ? this.latched : input.down("pan_latch"));
    if (this.dragging) {
      dx -= mouse.delta.x;
      dy += mouse.delta.y;
    }
    const keys = input.vector("pan_left", "pan_right", "pan_down", "pan_up");
    dx += keys.x * this.panSpeed * dt;
    dy += keys.y * this.panSpeed * dt;
    if (free && this.mouseSeen && !pointer.pad && input.pressed("primary") && !ui.hovered) this.edgeClick(m);
    if (this.edgeSize > 0 && this.mouseSeen && !pointer.pad && !free && game.focused && !this.dragging) {
      const e = this.edgeSize;
      if (m.x >= 0 && m.x < e) dx -= this.panSpeed * dt;
      else if (m.x <= DESIGN.width && m.x > DESIGN.width - e) dx += this.panSpeed * dt;
      if (m.y >= 0 && m.y < e) dy += this.panSpeed * dt;
      else if (m.y <= DESIGN.height && m.y > DESIGN.height - e) dy -= this.panSpeed * dt;
    }
    if (dx !== 0 || dy !== 0 || keyZoom !== 0) this.ease = null;
    this.view = { x: this.view.x + dx / this.view.zoom, y: this.view.y + dy / this.view.zoom, zoom: this.view.zoom };
    this.stepEase(dt);
    this.apply();
  }

  /** A click in the strip along an edge of the screen moves the view one step that way (hold-free replacement of the edge scroll). */
  edgeClick(m) {
    const e = this.edgeClickSize;
    const sx = m.x < e ? -1 : m.x > DESIGN.width - e ? 1 : 0;
    const sy = m.y < e ? 1 : m.y > DESIGN.height - e ? -1 : 0;
    if (sx === 0 && sy === 0) return;
    const to = this.ease ? this.ease.to : this.view;
    this.moveTo(to.x + (sx * this.edgeClickStep) / this.view.zoom, to.y + (sy * this.edgeClickStep) / this.view.zoom);
  }

  /** Is the point in the strip where a click moves the view (hold-free controls)? The controller keeps such a click off the map. */
  inEdgeStrip(m) {
    if (!live().holdFree || pointer.pad) return false;
    const e = this.edgeClickSize;
    return m.x < e || m.x > DESIGN.width - e || m.y < e || m.y > DESIGN.height - e;
  }

  stepEase(dt) {
    const ease = this.ease;
    if (!ease) return;
    ease.t = Math.min(1, ease.t + dt / this.easeSeconds);
    const k = ease.t * ease.t * (3 - 2 * ease.t); // smoothstep
    this.view = {
      x: ease.from.x + (ease.to.x - ease.from.x) * k,
      y: ease.from.y + (ease.to.y - ease.from.y) * k,
      zoom: ease.from.zoom + (ease.to.zoom - ease.from.zoom) * k,
    };
    if (ease.t >= 1) this.ease = null;
  }
}

export { ZOOM_MIN, ZOOM_MAX };
