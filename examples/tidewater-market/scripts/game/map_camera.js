// @ts-check
// The strategy camera of the town: the menu kit's CameraRig (scripts/camera_rig.js: drag pan, keys, wheel zoom towards the cursor,
// zoom limits, the view kept inside the map) with this game's controls added on top.
//
// P6: the pointer is scripts/game/pointer.js (the mouse, or the gamepad's virtual cursor); the right stick pans like WASD. A move to
// another place (`moveTo`: a click on a notice) is eased over a third of a second, or instant with the "reduced motion" option.
// "Hold-free" (option, or a gamepad in use): the middle button latches the drag (press to start, press again to stop) and a click
// in the strip along a screen edge moves the view a step that way, so nothing needs a button held down.
import { input, ui } from "factoria";
import CameraRig from "../camera_rig.js";
import { worldToCell } from "./iso.js";
import { pointer } from "./pointer.js";
import { live } from "../settings.js";
import { DESIGN } from "./design.js";

export default class MapCamera extends CameraRig {
  // the kit's settings, for this game
  panSpeed = 900;
  edgeSize = 8;
  zoomMin = 0.35;
  zoomMax = 2.5;
  startZoom = 1;
  margin = 200;
  dragAction = "pan_drag";
  leftAction = "pan_left";
  rightAction = "pan_right";
  upAction = "pan_up";
  downAction = "pan_down";
  zoomInAction = "zoom_in";
  zoomOutAction = "zoom_out";
  /** Width in pixels of the strip along a screen edge where a click moves the view (hold-free controls). */
  edgeClickSize = 14;
  /** How far an edge click moves the view, in screen pixels. */
  edgeClickStep = 280;

  onStart() {
    super.onStart();
    this.latched = false;
  }

  /** Sets the rectangle the view must stay in, from the map's { minX, maxX, minY, maxY }. */
  setBounds(b) {
    super.setBounds(b && { x: b.minX, y: b.minY, w: b.maxX - b.minX, h: b.maxY - b.minY });
  }

  moveTo(x, y, zoom) {
    this.instantMoves = live().reducedMotion;
    super.moveTo(x, y, zoom);
  }

  /** The map cell under a screen pixel, as [c, r]. */
  screenToCell(sx, sy) {
    const [x, y] = this.screenToWorld(sx, sy);
    return worldToCell(x, y);
  }

  pointer() {
    return pointer.position();
  }

  /** Hold-free: the middle button latches the drag; else the right button drags and the middle one too. */
  updateDrag() {
    const free = live().holdFree || pointer.pad;
    if (free && input.pressed("pan_latch")) this.latched = !this.latched;
    if (!free || input.pressed("tool_cancel") || input.pressed("escape")) this.latched = false;
    this.dragging = input.down("pan_drag") || (free ? this.latched : input.down("pan_latch"));
    return this.dragging;
  }

  edgePanAllowed() {
    return super.edgePanAllowed() && !pointer.pad && !live().holdFree;
  }

  onInput(dt, m) {
    const free = live().holdFree || pointer.pad;
    if (free && this.mouseSeen && !pointer.pad && input.pressed("primary") && !ui.hovered) this.edgeClick(m);
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
}
