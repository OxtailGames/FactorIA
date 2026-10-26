// @ts-check
// The strategy camera: right/middle-drag pans, the wheel zooms towards the cursor, the screen edges and WASD/arrows scroll,
// PageUp/PageDown zoom around the screen centre, and the view never leaves the map (plus a margin). Put this behaviour on the
// camera entity. The maths is scripts/game/camera_math.js (pure, unit tested); this class only reads the input and writes the
// camera entity's Transform and Camera.orthoSize.
import { Behaviour, input, game } from "factoria";
import { worldToCell } from "./iso.js";
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

  onStart() {
    const p = this.entity.position;
    this.view = { x: p.x, y: p.y, zoom: this.startZoom };
    this.bounds = null;
    this.mouseSeen = false;
    this.dragging = false;
    this.apply();
  }

  /** The world rectangle the view must stay in ({ minX, maxX, minY, maxY }), or null for no limit. */
  setBounds(bounds) {
    this.bounds = bounds;
    this.apply();
  }

  /** Jump to a view. */
  setView(x, y, zoom) {
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
    const m = mouse.position;
    if (!this.mouseSeen && (mouse.delta.x !== 0 || mouse.delta.y !== 0 || input.mouse.down("left") || input.mouse.down("right"))) this.mouseSeen = true;

    // zoom towards the cursor with the wheel
    const wheel = mouse.wheel;
    // (not while the pointer is over a panel of the Hud: the wheel scrolls its lists, see ui_hud.js)
    if (wheel !== 0 && !this.wheelBlocked) this.view = zoomAt(v, zoomStep(v.zoom, wheel), m.x, m.y);
    // zoom around the centre with the keys
    const keyZoom = input.axis("zoom_out", "zoom_in");
    if (keyZoom !== 0) this.view = zoomAt(this.view, this.view.zoom * Math.pow(this.keyZoomRate, keyZoom * dt), DESIGN.width / 2, DESIGN.height / 2);

    // pan: drag, keys, screen edges (screen pixels per second, converted to world units by the zoom)
    let dx = 0;
    let dy = 0;
    this.dragging = input.down("pan_drag");
    if (this.dragging) {
      dx -= mouse.delta.x;
      dy += mouse.delta.y;
    }
    const keys = input.vector("pan_left", "pan_right", "pan_down", "pan_up");
    dx += keys.x * this.panSpeed * dt;
    dy += keys.y * this.panSpeed * dt;
    if (this.edgeSize > 0 && this.mouseSeen && game.focused && !this.dragging) {
      const e = this.edgeSize;
      if (m.x >= 0 && m.x < e) dx -= this.panSpeed * dt;
      else if (m.x <= DESIGN.width && m.x > DESIGN.width - e) dx += this.panSpeed * dt;
      if (m.y >= 0 && m.y < e) dy += this.panSpeed * dt;
      else if (m.y <= DESIGN.height && m.y > DESIGN.height - e) dy -= this.panSpeed * dt;
    }
    this.view = { x: this.view.x + dx / this.view.zoom, y: this.view.y + dy / this.view.zoom, zoom: this.view.zoom };
    this.apply();
  }
}

export { ZOOM_MIN, ZOOM_MAX };
