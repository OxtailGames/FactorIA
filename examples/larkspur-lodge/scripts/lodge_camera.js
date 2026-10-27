// @ts-check
// The lodge camera: third person, behind and above the porter, smoothed, orbitable and zoomable. It does two things about
// geometry, with two different collision layers (assets/src/build_lodge.py sets them):
//   - Collision. A sphere is swept from the porter's head towards the wanted spot against layers 0 and 3 (floors and the
//     outside walls); the camera stops short of the first hit. Inside walls are not on that layer: the camera passes through
//     them and they fade instead, so the view never snaps in and out between rooms.
//   - Fade. Rays from the camera to the porter's head, chest and feet hit layer 1 (inside walls, doorways, tall furniture, door
//     leaves, stairs); whatever is between the lens and the porter fades to `fadeAlpha`, and back to solid when it no longer
//     hides him. The surfaces around the lens fade too, so the camera is never inside a wall's inner face.
//
// Orbit:  right mouse button drag, left button drag (after `dragSlop` pixels, so a click still walks), one finger dragging,
//         the gamepad right stick (camera_left/right/up/down), Q / E.
// Zoom:   mouse wheel, two-finger pinch, zoom_in / zoom_out (gamepad shoulders, R and V).
// The porter reads `yaw` (scripts/porter.js moves relative to it). area.js calls snapBehind(yaw) on arrival.
//
// A cut-scene takes the camera with direct(pos, look) and gives it back with release(yaw).
//
// Fields tests read: `yaw`, `pitch`, `actualDistance`, `directed`, `fadingIds` (entities faded right now) and fadeAlphaOf(id).
import { Behaviour, input, physics, world, ui } from "factoria";
import { screenState } from "./ui/screen_state.js";

const DEG = Math.PI / 180;
/**
 * Collision layers as bit masks (assets/src/build_lodge.py sets them): the camera stops at layer 0 (floors) and layer 3 (outside walls);
 * layer 1 (inside walls, doorways, tall furniture, door leaves, stairs) and layer 3 fade when they hide the porter.
 */
const LAYER_SOLID = (1 << 0) | (1 << 3);
const LAYER_FADE = (1 << 1) | (1 << 3);

export default class LodgeCamera extends Behaviour {
  /** Entity id of what the camera follows. */
  targetId = "porter";
  /** Height above the target's origin (the capsule centre) that the camera looks at and sweeps from, metres. */
  headHeight = 0.6;
  /** Starting yaw in degrees: 0 = behind a porter that looks down -Z. */
  yaw = 0;
  /** Starting elevation of the camera above the horizon, degrees, and its limits. */
  pitch = 42;
  minPitch = 12;
  maxPitch = 75;
  /** Distance from the head, metres, and its limits. */
  distance = 7.5;
  minDistance = 3;
  maxDistance = 12;
  /** How tightly the camera follows the porter (1/s: higher = stiffer). */
  followSmoothing = 8;
  /** Multiplies every orbit input. 1 = default. */
  sensitivity = 1;
  invertY = false;
  invertX = false;
  /** Orbit speed of keys and the right stick at full tilt, degrees per second. */
  orbitSpeed = 130;
  /** Mouse drag, degrees per design pixel; a one-finger drag uses touchDrag. */
  mouseDrag = 0.25;
  touchDrag = 0.3;
  /** A left-button drag shorter than this many design pixels is a click, not an orbit (it walks the porter). */
  dragSlop = 8;
  /** Zoom per wheel notch (metres), of zoom_in / zoom_out (metres per second) and of a pinch (metres per design pixel). */
  wheelStep = 0.7;
  zoomSpeed = 4;
  pinchZoom = 0.02;
  /** Radius of the swept sphere, metres; the gap kept from what it hits; the least distance to the head. */
  collisionRadius = 0.25;
  collisionPadding = 0.05;
  minClipDistance = 0.4;
  /** How fast the camera moves back out after a wall stopped it, metres per second. */
  recoverSpeed = 6;
  /** Alpha of something that hides the porter, how fast the alpha moves (1/s), and the radius around the lens that always fades. */
  fadeAlpha = 0.2;
  fadeSpeed = 7;
  lensRadius = 0.7;
  /** Walls this far (metres, horizontally) behind the porter, towards the lens, fade too. */
  behindReach = 2.4;
  /** Walls and furniture crossed by one ray that are still counted (more than this are ignored). */
  maxFadeHits = 8;

  onStart() {
    this.target = world.find(this.targetId);
    this.actualDistance = this.distance;
    this.pivot = this.headPoint();
    /** id -> { entity, mesh, base: the colour the scene gave it, alpha, want }. */
    this.faded = new Map();
    this.pinchLast = 0;
    this.drag = null;
    /** True while a cut-scene holds the camera (direct()). */
    this.directed = false;
    this.apply(0);
    this.updateFade(0);
  }

  headPoint() {
    const p = this.target ? this.target.position : { x: 0, y: 0, z: 0 };
    return [p.x, p.y + this.headHeight, p.z];
  }

  /**
   * A cut-scene takes the camera (scripts/cutscene.js): it stands at `pos` and looks at `look` (world points) and follows nobody,
   * reads no input and fades no walls until release(). Call it every frame it should move.
   */
  direct(pos, look) {
    if (!this.directed) {
      this.directed = true;
      this.drag = null;
      // Whatever was faded for the porter is solid again: the shot is about the room.
      for (const f of this.faded.values()) if (f.entity.alive) f.mesh.color = f.base;
      this.faded.clear();
    }
    const fx = look[0] - pos[0];
    const fy = look[1] - pos[1];
    const fz = look[2] - pos[2];
    const len = Math.hypot(fx, fy, fz) || 1;
    const t = this.entity.get("Transform");
    t.position = [pos[0], pos[1], pos[2]];
    t.rotation = [Math.asin(fy / len) / DEG, Math.atan2(-fx, -fz) / DEG, 0];
  }

  /** The cut-scene is over: the camera goes back behind the porter, looking along `yaw` (the porter's heading, degrees). */
  release(yaw = this.yaw) {
    this.directed = false;
    this.snapBehind(yaw);
  }

  /** Puts the camera behind a porter that looks along `yaw` (an area arrival), with no smoothing. */
  snapBehind(yaw) {
    this.yaw = yaw;
    this.pivot = this.headPoint();
    this.actualDistance = this.distance;
    this.apply(0);
    this.updateFade(0);
  }

  /** Orbit by degrees (positive dx turns the view to the right). */
  orbit(dx, dy) {
    const sx = this.invertX ? -1 : 1;
    const sy = this.invertY ? -1 : 1;
    this.yaw -= dx * sx * this.sensitivity;
    this.pitch = clamp(this.pitch + dy * sy * this.sensitivity, this.minPitch, this.maxPitch);
  }

  /** Zoom by metres (negative = closer). */
  zoom(dm) {
    this.distance = clamp(this.distance + dm, this.minDistance, this.maxDistance);
  }

  onLateUpdate(dt) {
    if (this.directed) return;
    this.readInput(dt);
    this.apply(dt);
    this.updateFade(dt);
  }

  readInput(dt) {
    if (screenState.open) {
      this.drag = null;
      this.pinchLast = 0;
      return; // a screen (the journal, a puzzle) is up: its drags and sticks are not for the camera
    }
    const ax = input.axis("camera_left", "camera_right");
    const ay = input.axis("camera_up", "camera_down");
    if (ax !== 0 || ay !== 0) this.orbit(ax * this.orbitSpeed * dt, ay * this.orbitSpeed * dt);

    const touches = input.touches;
    const m = input.mouse;
    if (touches.length < 2) {
      // A press that starts on a button is never an orbit. The right button orbits at once; the left only past the slop.
      // The frame a button goes down is never an orbit: the pointer may have jumped there (a tap, a click).
      if (m.pressed("left")) this.drag = { total: 0, active: false, ui: !!ui.widgetAt(m.position.x, m.position.y), scale: input.lastDevice === "touch" ? this.touchDrag : this.mouseDrag };
      else if (this.drag && m.down("left")) {
        const d = m.delta;
        if (!this.drag.ui) {
          this.drag.total += Math.hypot(d.x, d.y);
          if (this.drag.total > this.dragSlop) {
            this.drag.active = true;
            this.orbit(d.x * this.drag.scale, d.y * this.drag.scale);
          }
        }
      } else if (this.drag) this.drag = null;
      if (m.down("right") && !m.pressed("right") && !ui.hovered) this.orbit(m.delta.x * this.mouseDrag, m.delta.y * this.mouseDrag);
      if (m.wheel !== 0 && touches.length === 0) this.zoom(-m.wheel * this.wheelStep);
    } else this.drag = null;

    const z = input.axis("zoom_out", "zoom_in");
    if (z !== 0) this.zoom(-z * this.zoomSpeed * dt);

    if (touches.length >= 2) {
      const a = touches[0].position;
      const b = touches[1].position;
      const d = Math.hypot(a.x - b.x, a.y - b.y);
      if (this.pinchLast > 0) this.zoom(-(d - this.pinchLast) * this.pinchZoom);
      this.pinchLast = d;
    } else this.pinchLast = 0;
  }

  /** The camera's position this frame, [x, y, z]. */
  get position() {
    const p = this.entity.position;
    return [p.x, p.y, p.z];
  }

  /** Places the camera: smoothed pivot, then the sweep, then the transform. */
  apply(dt) {
    const want = this.headPoint();
    const k = dt > 0 ? 1 - Math.exp(-this.followSmoothing * dt) : 1;
    for (let i = 0; i < 3; i++) this.pivot[i] += (want[i] - this.pivot[i]) * k;

    const cp = Math.cos(this.pitch * DEG);
    const dir = [Math.sin(this.yaw * DEG) * cp, Math.sin(this.pitch * DEG), Math.cos(this.yaw * DEG) * cp];
    const to = [this.pivot[0] + dir[0] * this.distance, this.pivot[1] + dir[1] * this.distance, this.pivot[2] + dir[2] * this.distance];
    let allowed = this.distance;
    const hit = physics.shapeCast({ shape: "sphere", radius: this.collisionRadius }, this.pivot, to, { mask: LAYER_SOLID, ignore: this.target ?? undefined });
    if (hit) allowed = Math.max(this.minClipDistance, hit.distance - this.collisionPadding);
    // Pull in at once (never show the inside of a wall), ease back out.
    if (allowed < this.actualDistance || dt === 0) this.actualDistance = allowed;
    else this.actualDistance = Math.min(allowed, this.actualDistance + this.recoverSpeed * dt);

    const t = this.entity.get("Transform");
    t.position = [this.pivot[0] + dir[0] * this.actualDistance, this.pivot[1] + dir[1] * this.actualDistance, this.pivot[2] + dir[2] * this.actualDistance];
    t.rotation = [-this.pitch, this.yaw, 0];
  }

  // ------------------------------------------------------------------------------------------------------ fade
  /** Ids of the entities faded (alpha below 1) now. */
  get fadingIds() {
    return [...this.faded.keys()];
  }

  /** The alpha an entity is drawn with because of the fade: 1 when it is not faded. */
  fadeAlphaOf(id) {
    const f = this.faded.get(id);
    return f ? f.alpha : 1;
  }

  /** Finds what hides the porter, and moves every alpha one step towards its goal. */
  updateFade(dt) {
    const hiding = new Set();
    if (this.target) {
      const c = this.entity.position;
      const from = [c.x, c.y, c.z];
      const p = this.target.position;
      // Head, chest and knees: a prop that covers any of them fades, so the feet are not lost behind a counter.
      const points = [[p.x, p.y + this.headHeight, p.z], [p.x, p.y, p.z], [p.x, p.y - 0.6, p.z]];
      // Two more points a little way towards the lens: a wall close behind the porter takes up the lower screen without crossing a ray to him.
      const hx = c.x - p.x;
      const hz = c.z - p.z;
      const hl = Math.hypot(hx, hz);
      if (hl > 0.01) {
        const k = this.behindReach / hl;
        points.push([p.x + hx * k, p.y + 0.3, p.z + hz * k], [p.x + hx * k, p.y + 1.1, p.z + hz * k]);
      }
      for (const to of points) this.collectBetween(from, to, hiding);
      for (const e of physics.overlapSphere(from, this.lensRadius, { mask: LAYER_FADE })) hiding.add(e);
    }
    for (const e of hiding) {
      if (this.faded.has(e.id)) continue;
      const mesh = e.has("MeshRenderer") ? e.get("MeshRenderer") : null;
      if (!mesh) continue;
      this.faded.set(e.id, { entity: e, mesh, base: [...mesh.color], alpha: 1, want: this.fadeAlpha });
    }
    for (const [id, f] of this.faded) {
      if (!f.entity.alive) {
        this.faded.delete(id);
        continue;
      }
      f.want = hiding.has(f.entity) ? this.fadeAlpha : 1;
      const step = dt > 0 ? this.fadeSpeed * dt : 1;
      if (f.alpha < f.want) f.alpha = Math.min(f.want, f.alpha + step);
      else if (f.alpha > f.want) f.alpha = Math.max(f.want, f.alpha - step);
      if (f.alpha >= 1 && f.want >= 1) {
        f.mesh.color = f.base;
        this.faded.delete(id);
      } else f.mesh.color = [f.base[0], f.base[1], f.base[2], f.base[3] * f.alpha];
    }
  }

  /** Adds to `out` every fade-layer entity on the segment from -> to (the ray is restarted after each hit: raycast3d returns only the first). */
  collectBetween(from, to, out) {
    let o = from;
    const dx = to[0] - from[0];
    const dy = to[1] - from[1];
    const dz = to[2] - from[2];
    const total = Math.hypot(dx, dy, dz);
    if (total < 1e-4) return;
    const dir = [dx / total, dy / total, dz / total];
    let travelled = 0;
    for (let i = 0; i < this.maxFadeHits; i++) {
      const hit = physics.raycast3d(o, dir, total - travelled, { mask: LAYER_FADE });
      if (!hit) return;
      out.add(hit.entity);
      const step = hit.distance + 0.03;
      travelled += step;
      if (travelled >= total) return;
      o = [o[0] + dir[0] * step, o[1] + dir[1] * step, o[2] + dir[2] * step];
    }
  }
}

function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v));
}
