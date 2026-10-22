// @ts-check
// Third-person follow camera: behind and above the courier, smoothed, orbitable and zoomable, and it never ends up
// inside geometry (a sphere is swept from the courier's head towards the wanted camera spot and the camera stops short
// of the first thing it hits).
//
// Orbit:  one finger dragging on the free screen (fingers on the TouchStick / TouchButtons are not in input.touches),
//         the mouse with the left button held, the gamepad right stick, the keys on camera_left / camera_right.
// Zoom:   two-finger pinch, mouse wheel, zoom_in / zoom_out (gamepad shoulders, R and V).
// The movement of the courier is camera-relative: it reads `yaw` from this behaviour.
import { Behaviour, input, physics, world, ui } from "factoria";

const DEG = Math.PI / 180;

export default class FollowCamera extends Behaviour {
  /** Entity id of what the camera follows. */
  targetId = "courier";
  /** Height above the target's origin that the camera looks at and sweeps from (the robot's head), metres. */
  headHeight = 0.5;
  /** Starting yaw in degrees: 0 = behind a courier that looks down -Z. */
  yaw = 0;
  /** Starting elevation of the camera above the horizon, degrees. */
  pitch = 22;
  /** Lowest and highest elevation, degrees. */
  minPitch = -5;
  maxPitch = 70;
  /** Distance from the head, metres, and its limits. */
  distance = 6;
  minDistance = 3;
  maxDistance = 10;
  /** How tightly the camera follows the courier (1/s: higher = stiffer). */
  followSmoothing = 9;
  /** Multiplies every orbit input. 1 = default; 0.5 is for people who find it twitchy. */
  sensitivity = 1;
  /** Flip vertical orbit (stick up looks down, drag up looks down). */
  invertY = false;
  /** Flip horizontal orbit. */
  invertX = false;
  /** Orbit speed of keys and the right stick at full tilt, degrees per second. */
  orbitSpeed = 140;
  /** Mouse drag, degrees per design pixel. */
  mouseDrag = 0.25;
  /** One-finger drag, degrees per design pixel. */
  touchDrag = 0.3;
  /** Zoom per wheel notch, metres. */
  wheelStep = 0.7;
  /** Zoom speed of zoom_in / zoom_out, metres per second. */
  zoomSpeed = 4;
  /** Zoom of a pinch, metres per design pixel the fingers move apart. */
  pinchZoom = 0.02;
  /** Radius of the sphere swept against the level, metres. Bigger = stays farther from walls. */
  collisionRadius = 0.25;
  /** Extra gap kept from what the sweep hits, metres. */
  collisionPadding = 0.05;
  /** The camera never gets closer to the head than this, metres (keep it below the narrowest space you want the camera to enter). */
  minClipDistance = 0.3;
  /** How fast the camera moves back out after a wall stopped it, metres per second. */
  recoverSpeed = 6;

  onStart() {
    this.target = world.find(this.targetId);
    /** Distance actually used this frame (after collision), metres. */
    this.actualDistance = this.distance;
    this.pivot = this.headPoint();
    this.touchTrack = new Map();
    this.pinchLast = 0;
    this.apply(0);
  }

  headPoint() {
    const p = this.target ? this.target.position : { x: 0, y: 0, z: 0 };
    return [p.x, p.y + this.headHeight, p.z];
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
    this.readInput(dt);
    this.apply(dt);
  }

  readInput(dt) {
    // Keys and right stick (analog: half a tilt is half the speed).
    const ax = input.axis("camera_left", "camera_right");
    const ay = input.axis("camera_up", "camera_down"); // stick up = look up, so the camera goes down: positive pitch change
    // camera_left is Q (turn the view left): axis() is +1 for camera_right, and orbit(dx>0) turns the view right.
    if (ax !== 0 || ay !== 0) this.orbit(ax * this.orbitSpeed * dt, ay * this.orbitSpeed * dt);

    // Mouse: drag with the left button, wheel to zoom. Not while the pointer is over a button.
    const touches = input.touches;
    if (touches.length === 0) {
      if (input.mouse.down("left") && !input.mouse.pressed("left") && !ui.hovered) {
        const d = input.mouse.delta;
        this.orbit(d.x * this.mouseDrag, d.y * this.mouseDrag);
      }
      if (input.mouse.wheel !== 0) this.zoom(-input.mouse.wheel * this.wheelStep);
    }

    // Digital zoom keys / shoulders.
    const z = input.axis("zoom_out", "zoom_in");
    if (z !== 0) this.zoom(-z * this.zoomSpeed * dt);

    // Fingers on the free screen: one drags (orbit), two pinch (zoom).
    this.readTouches(touches);
  }

  readTouches(touches) {
    if (touches.length === 1) {
      const t = touches[0];
      const last = this.touchTrack.get(t.id);
      if (last && !t.pressed) this.orbit((t.position.x - last.x) * this.touchDrag, (t.position.y - last.y) * this.touchDrag);
      this.touchTrack = new Map([[t.id, { x: t.position.x, y: t.position.y }]]);
      this.pinchLast = 0;
    } else if (touches.length >= 2) {
      const a = touches[0].position;
      const b = touches[1].position;
      const d = Math.hypot(a.x - b.x, a.y - b.y);
      if (this.pinchLast > 0) this.zoom(-(d - this.pinchLast) * this.pinchZoom);
      this.pinchLast = d;
      this.touchTrack.clear();
    } else {
      this.touchTrack.clear();
      this.pinchLast = 0;
    }
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
    const hit = physics.shapeCast({ shape: "sphere", radius: this.collisionRadius }, this.pivot, to, { ignore: this.target ?? undefined });
    if (hit) allowed = Math.max(this.minClipDistance, hit.distance - this.collisionPadding);
    // Pull in at once (never show the inside of a wall), ease back out.
    if (allowed < this.actualDistance || dt === 0) this.actualDistance = allowed;
    else this.actualDistance = Math.min(allowed, this.actualDistance + this.recoverSpeed * dt);

    const t = this.entity.get("Transform");
    t.position = [
      this.pivot[0] + dir[0] * this.actualDistance,
      this.pivot[1] + dir[1] * this.actualDistance,
      this.pivot[2] + dir[2] * this.actualDistance,
    ];
    t.rotation = [-this.pitch, this.yaw, 0];
  }
}

function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v));
}
