// @ts-check
// The strategy camera: put this behaviour on the camera entity (an orthographic Camera, not rotated). It pans with a drag
// (the camera_drag action: the middle button by default), with the keys (camera_left, camera_right, camera_up, camera_down) and
// at the screen edges; the wheel zooms towards the cursor and camera_zoom_in / camera_zoom_out zoom around the screen centre;
// the zoom stays between zoomMin and zoomMax (pixels per world unit) and the view stays inside the rectangle of the entity named
// in `boundsEntity` (entity.bounds()) grown by `margin`. A wheel turn or a drag that starts over a panel or button of the UI
// does nothing here, and a wheel that scrolled a ScrollList is not seen (ui.pointerOverUi, ui.wheelConsumed).
//
// The maths is the camera helpers of the engine (camera.zoomAt, camera.panBy, camera.clampTo, camera.setZoom); this class reads
// the input and calls them. A game that needs other controls (a gamepad cursor, a latched drag) extends the class and overrides
// pointer(), updateDrag(), edgePanAllowed() or onInput().
import { Behaviour, camera, game, input, screen, ui, world } from "factoria";

export default class CameraRig extends Behaviour {
  /** Scroll speed of the keys and the screen edges, in screen pixels per second (so it feels the same at every zoom). */
  panSpeed = 900;
  /** Width in pixels of the screen-edge zone that scrolls the view; 0 turns edge scrolling off. */
  edgeSize = 8;
  /** Zoom factor of one wheel notch (1.15 = 15 % per notch). */
  wheelStep = 1.15;
  /** Zoom factor per second for the zoom keys. */
  keyZoomRate = 1.8;
  /** Smallest zoom, in pixels per world unit (the most zoomed out). */
  zoomMin = 0.4;
  /** Largest zoom, in pixels per world unit (the most zoomed in). */
  zoomMax = 2.5;
  /** The zoom at the start, in pixels per world unit; 0 keeps the camera's own orthoSize. */
  startZoom = 0;
  /** Id of the entity whose bounds() the view must stay in (a Tilemap or a background Sprite); "" for no limit. */
  boundsEntity = "";
  /** How far past the bounds the view may go, in world units. */
  margin = 0;
  /** When true the camera ignores input (a title-screen backdrop drives it from a script). */
  frozen = false;
  /** Seconds an eased move (moveTo) takes. */
  easeSeconds = 0.35;
  /** Moves at once instead of easing (set it from the player's "reduced motion" option). */
  instantMoves = false;
  /** Set it to true while something the UI does not know about owns the pointer (a modal card): the wheel and new drags are ignored. */
  wheelBlocked = false;
  /** Input action names. Change them when the game has its own. */
  dragAction = "camera_drag";
  leftAction = "camera_left";
  rightAction = "camera_right";
  upAction = "camera_up";
  downAction = "camera_down";
  zoomInAction = "camera_zoom_in";
  zoomOutAction = "camera_zoom_out";

  onStart() {
    this.rect = null;
    this.dragging = false;
    this.mouseSeen = false;
    /** @type {{ from: { x: number, y: number, zoom: number }, to: { x: number, y: number, zoom: number }, t: number } | null} the eased move in progress */
    this.ease = null;
    if (this.startZoom > 0) camera.setZoom(this.clampZoom(this.startZoom), this.entity);
    this.refreshBounds();
  }

  clampZoom(z) {
    return Math.min(Math.max(z, this.zoomMin), this.zoomMax);
  }

  /** Where the pointer is on the screen, in design pixels. Override for a pointer that is not the mouse. */
  pointer() {
    return input.mouse.position;
  }

  /** Is the view being dragged this frame? Starts only on a press that is not over the UI. Override for another drag (a latch). */
  updateDrag() {
    if (input.pressed(this.dragAction)) this.dragging = !this.over() && !this.wheelBlocked;
    else if (!input.down(this.dragAction)) this.dragging = false;
    return this.dragging;
  }

  /** May the screen edges scroll the view this frame? */
  edgePanAllowed() {
    return this.mouseSeen && game.focused && !this.dragging;
  }

  /** Is the pointer over a panel or widget of the UI (so the wheel and a new drag belong to it)? */
  over() {
    return ui.pointerOverUi;
  }

  /** Called every frame before the rig reads the wheel, the keys and the drag, with the pointer position. Override to add a control. */
  onInput(dt, m) {}

  /** The view: the world point at the centre of the screen and the zoom in pixels per world unit. */
  get view() {
    const p = this.entity.position;
    return { x: p.x, y: p.y, zoom: camera.zoomOf(this.entity) };
  }

  /** Sets the rectangle the view must stay in ({ x, y, w, h }, (x, y) the bottom-left like entity.bounds()), or null for no limit. */
  setBounds(rect) {
    this.rect = rect ? { x: rect.x, y: rect.y, w: rect.w, h: rect.h } : null;
    this.apply();
  }

  /** Reads the bounds again from `boundsEntity` (call it after the map changed size). */
  refreshBounds() {
    const e = this.boundsEntity ? world.find(this.boundsEntity) : null;
    this.rect = e ? e.bounds() : this.rect;
    this.apply();
  }

  /** Jumps to a view at once. */
  setView(x, y, zoom = this.view.zoom) {
    this.ease = null;
    this.place(x, y, this.clampZoom(zoom));
    this.apply();
  }

  /** Goes to a view, eased over easeSeconds (at once with instantMoves). Any input from the player stops it. */
  moveTo(x, y, zoom = this.view.zoom) {
    if (this.instantMoves) return this.setView(x, y, zoom);
    this.ease = { from: this.view, to: { x, y, zoom: this.clampZoom(zoom) }, t: 0 };
  }

  place(x, y, zoom) {
    camera.setZoom(zoom, this.entity);
    this.entity.position = [x, y, this.entity.position.z];
  }

  /** The world point under a screen pixel, as [x, y]. */
  screenToWorld(sx, sy) {
    const v = this.view;
    const s = screen.size;
    return [v.x + (sx - s.x / 2) / v.zoom, v.y - (sy - s.y / 2) / v.zoom];
  }

  /** The screen pixel of a world point, as [x, y]. */
  worldToScreen(wx, wy) {
    const v = this.view;
    const s = screen.size;
    return [(wx - v.x) * v.zoom + s.x / 2, (v.y - wy) * v.zoom + s.y / 2];
  }

  /** Keeps the zoom and the position legal. */
  apply() {
    const z = this.clampZoom(camera.zoomOf(this.entity));
    if (z !== camera.zoomOf(this.entity)) camera.setZoom(z, this.entity);
    if (this.rect) camera.clampTo(this.rect, { camera: this.entity, margin: this.margin });
  }

  onUpdate(dt) {
    if (this.frozen) return;
    const mouse = input.mouse;
    const m = this.pointer();
    if (!this.mouseSeen && (mouse.delta.x !== 0 || mouse.delta.y !== 0 || mouse.down("left") || mouse.down("right"))) this.mouseSeen = true;
    this.onInput(dt, m);
    let moved = false;

    // the wheel zooms towards the cursor; over the UI (or a ScrollList that took it) it does not
    const wheel = mouse.wheel;
    if (wheel !== 0 && !this.over() && !ui.wheelConsumed && !this.wheelBlocked) {
      camera.zoomAt(m, Math.pow(this.wheelStep, wheel), { camera: this.entity, min: this.zoomMin, max: this.zoomMax });
      moved = true;
    }
    // the zoom keys zoom around the middle of the screen
    const keyZoom = input.axis(this.zoomOutAction, this.zoomInAction);
    if (keyZoom !== 0) {
      const s = screen.size;
      camera.zoomAt([s.x / 2, s.y / 2], Math.pow(this.keyZoomRate, keyZoom * dt), { camera: this.entity, min: this.zoomMin, max: this.zoomMax });
      moved = true;
    }

    // pan: the drag, the keys and the screen edges, as screen pixels (panBy converts them by the zoom)
    let dx = 0;
    let dy = 0;
    if (this.updateDrag()) {
      dx += mouse.delta.x;
      dy += mouse.delta.y;
    }
    const keys = input.vector(this.leftAction, this.rightAction, this.downAction, this.upAction);
    dx -= keys.x * this.panSpeed * dt;
    dy += keys.y * this.panSpeed * dt;
    if (this.edgeSize > 0 && this.edgePanAllowed()) {
      const e = this.edgeSize;
      const s = screen.size;
      if (m.x >= 0 && m.x < e) dx += this.panSpeed * dt;
      else if (m.x <= s.x && m.x > s.x - e) dx -= this.panSpeed * dt;
      if (m.y >= 0 && m.y < e) dy += this.panSpeed * dt;
      else if (m.y <= s.y && m.y > s.y - e) dy -= this.panSpeed * dt;
    }
    if (dx !== 0 || dy !== 0) {
      camera.panBy([dx, dy], this.entity);
      moved = true;
    }
    if (moved) this.ease = null;
    this.stepEase(dt);
    this.apply();
  }

  stepEase(dt) {
    const ease = this.ease;
    if (!ease) return;
    ease.t = Math.min(1, ease.t + dt / this.easeSeconds);
    const k = ease.t * ease.t * (3 - 2 * ease.t); // smoothstep
    this.place(
      ease.from.x + (ease.to.x - ease.from.x) * k,
      ease.from.y + (ease.to.y - ease.from.y) * k,
      ease.from.zoom + (ease.to.zoom - ease.from.zoom) * k,
    );
    if (ease.t >= 1) this.ease = null;
  }
}
