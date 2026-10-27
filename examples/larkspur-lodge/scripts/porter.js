// @ts-check
// The porter: the player's character. A CharacterController3D driven by this script, with three ways to move it, one
// interaction system, and the animator parameters.
//
// Moving (every scheme feeds the same movement; the last device that gave input decides which one shows in the prompt):
//   keyboard   move_* actions (WASD, arrows) relative to the camera; hold `run` (Left Shift) to run.
//   gamepad    the left stick, analog: half a tilt walks slowly, a full tilt runs. Right stick orbits (scripts/lodge_camera.js).
//   mouse/touch  click or tap the floor: the porter walks there round furniture and walls (nav.findPath over the area's
//              NavMesh3D). Click or tap an object: it walks up to it and uses it. A drag is not a click: it orbits the camera.
//              Any move key or stick tilt cancels the walk.
//
// Using things (scripts/interactable.js): the nearest interactable in reach and in front shows a prompt with the key, the
// button, "Click" or "Tap" of the last device used; the `interact` action (F, Enter, gamepad A), a click or tap on the object or
// on the prompt uses it.
//
// Entity layout (every area scene): "porter" (this script + CharacterController3D, origin = capsule centre) with a child
// "porter_model" (the glb and its Animator, turned to face the heading).
//
// A cut-scene may set `puppet` (it then places the porter itself and sets `yaw` and `puppetSpeed`; see scripts/cutscene.js).
//
// Other scripts use: lock(reason) / unlock(reason) (no input while a reason is held: "transition", "dialogue", "cutscene"),
// faceYaw(deg), walkTo(path), goTo(point), use(interactable), and read `yaw`, `speed`, `grounded`, `target`, `locked`.
import { Behaviour, input, physics, world, camera, nav, ui, i18n } from "factoria";
import { EVENTS, emit } from "./events.js";

const DEG = Math.PI / 180;
/** Collision layers of the lodge (set by assets/src/build_lodge.py): 0 floors, 1 inside walls, doors, stairs and tall furniture, 2 low furniture, 3 outside walls. */
const LAYER_PROPS = (1 << 1) | (1 << 2) | (1 << 3);
const LAYER_GROUND = 1 << 0;

export default class Porter extends Behaviour {
  /** Walking speed (move keys, a half-tilted stick), m/s. */
  walkSpeed = 2.4;
  /** Running speed (`run` held, a fully tilted stick), m/s. */
  runSpeed = 4.6;
  /** Speed of a click-to-walk, m/s. */
  autoSpeed = 3.3;
  /** How fast the velocity follows the wanted one, m/s^2, and slowing down with no input. */
  groundAccel = 30;
  groundDecel = 34;
  /** Turning to face the heading, degrees per second. */
  turnSpeed = 600;
  /** Gravity, m/s^2, and the longest fall speed. */
  gravity = 22;
  maxFallSpeed = 25;
  /** Speed (m/s) above which the run animation plays. */
  runAnimSpeed = 3.6;
  /** The stick tilt where walking turns into running: from `runFrom` (walkSpeed) to `runFull` (runSpeed). */
  runFrom = 0.6;
  runFull = 0.95;
  /** An interactable more than this far (m) from the porter is only picked when it is in front (dot of heading and direction above `facing`). */
  closeRange = 0.9;
  facing = 0.25;
  /** Height of the capsule centre above the feet, metres (paths start at the feet). */
  feet = 0.875;
  /** Radius used for path finding (at most the NavMesh3D's agentRadius), and how far a click may be from walkable floor (m). */
  navRadius = 0.3;
  snap = 1.5;
  /** A click that moves more than this many design pixels is a drag (orbit), not a click. */
  tapSlop = 8;
  /** Click or tap on the floor walks there (the touch scheme; a mouse player may also use it). */
  clickToWalk = true;
  cameraId = "camera";
  modelId = "porter_model";
  hudId = "hud";

  onStart() {
    this.vx = 0;
    this.vz = 0;
    this.vy = 0;
    /** Heading in degrees (0 = looking down -Z, like a camera at yaw 0). */
    this.yaw = 0;
    this.grounded = false;
    this.speed = 0;
    /** Reasons input is ignored right now (a Set of strings). */
    this.locks = new Set();
    this.autoPath = null;
    this.autoIndex = 0;
    this.autoStuck = 0;
    /** The interactable a click-to-walk goes to use on arrival, or null. */
    this.autoThen = null;
    this.arrived = false;
    /** The interactable in reach (its Behaviour), or null. */
    this.target = null;
    this.promptKey = "";
    /** The last click that was sent to the floor or an object: { kind, point } (tests read it). */
    this.lastClick = null;
    this.click = null;
    this.device = input.lastDevice;
    this.model = world.find(this.modelId);
    this.anim = this.model ? this.model.animator : null;
    /** True while a cut-scene moves the porter by hand (scripts/cutscene.js): no physics, no input; `puppetSpeed` drives the animation. */
    this.puppet = false;
    this.puppetSpeed = 0;
    /** The Interactable behaviours of the scene; read on the first update, when every script has started. */
    this.interactables = null;
  }

  // ------------------------------------------------------------------------------------------------------ locks
  /** True while any reason holds input back. */
  get locked() {
    return this.locks.size > 0;
  }

  lock(reason) {
    this.locks.add(reason);
    this.autoPath = null;
    this.autoThen = null;
  }

  unlock(reason) {
    this.locks.delete(reason);
  }

  /** Turns the porter to face `yaw` degrees at once (a spawn, an interaction). */
  faceYaw(yaw) {
    this.yaw = yaw;
    if (this.model) this.model.get("Transform").rotation = [0, yaw + 180, 0];
  }

  /** Yaw of the camera in degrees (0 when there is none). */
  cameraYaw() {
    const b = world.find(this.cameraId)?.behaviour;
    return b && typeof b.yaw === "number" ? b.yaw : 0;
  }

  // -------------------------------------------------------------------------------------------------- movement
  onFixedUpdate(dt) {
    if (this.puppet) {
      this.vx = 0;
      this.vz = 0;
      this.vy = 0;
      this.speed = this.puppetSpeed;
      if (this.model) this.model.get("Transform").rotation = [0, this.yaw + 180, 0];
      if (this.anim) this.anim.set("speed", this.speed);
      return;
    }
    let ix = 0;
    let iz = 0;
    if (!this.locked) {
      const v = input.vector("move_left", "move_right", "move_back", "move_forward");
      ix = v.x;
      iz = v.y;
    }
    let mag = Math.hypot(ix, iz);
    if (mag > 1) {
      ix /= mag;
      iz /= mag;
      mag = 1;
    }
    // Wanted speed along the input direction: a key is all-or-nothing (walk, or run with the run key), a stick is analog.
    let top = 0;
    if (mag > 0) {
      if (input.lastDevice === "gamepad") {
        top = mag < this.runFrom ? (this.walkSpeed * mag) / this.runFrom : this.walkSpeed + (this.runSpeed - this.walkSpeed) * Math.min(1, (mag - this.runFrom) / (this.runFull - this.runFrom));
      } else top = input.down("run") ? this.runSpeed : this.walkSpeed;
    }
    // Camera-relative: stick up = away from the camera.
    const cy = this.cameraYaw() * DEG;
    const s = Math.sin(cy);
    const c = Math.cos(cy);
    const dirX = mag > 0 ? (ix * c - iz * s) / mag : 0;
    const dirZ = mag > 0 ? (-ix * s - iz * c) / mag : 0;
    let wantX = dirX * top;
    let wantZ = dirZ * top;
    let steering = mag > 0.1;
    // A click-to-walk steers when the player holds no direction; any direction cancels it.
    if (this.autoPath) {
      if (this.locked || mag > 0.1) {
        this.autoPath = null;
        this.autoThen = null;
      } else {
        const w = this.autoSteer(dt);
        if (w) {
          wantX = w[0] * this.autoSpeed;
          wantZ = w[1] * this.autoSpeed;
          steering = true;
        }
      }
    }
    const accel = steering ? this.groundAccel : this.groundDecel;
    const dx = wantX - this.vx;
    const dz = wantZ - this.vz;
    const dl = Math.hypot(dx, dz);
    const step = accel * dt;
    if (dl <= step) {
      this.vx = wantX;
      this.vz = wantZ;
    } else {
      this.vx += (dx / dl) * step;
      this.vz += (dz / dl) * step;
    }
    // Face the way we want to go.
    if (steering && Math.hypot(wantX, wantZ) > 0.1) {
      const target = Math.atan2(-wantX, -wantZ) / DEG;
      this.yaw = turnToward(this.yaw, target, this.turnSpeed * dt);
    }
    // A small downward speed on the ground keeps the capsule snapped to it (stairs, steps).
    this.vy = this.grounded ? Math.min(this.vy, -1) : Math.max(this.vy - this.gravity * dt, -this.maxFallSpeed);
    const r = physics.moveCharacter(this.entity, [this.vx * dt, this.vy * dt, this.vz * dt]);
    this.grounded = r.isGrounded;
    if (r.hitCeiling && this.vy > 0) this.vy = 0;
    if (r.hitWall) {
      // Slide: keep only the velocity that really happened.
      this.vx = r.moved.x / dt;
      this.vz = r.moved.z / dt;
    }
    this.speed = Math.hypot(this.vx, this.vz);
    if (this.model) this.model.get("Transform").rotation = [0, this.yaw + 180, 0];
    if (this.anim) this.anim.set("speed", this.speed);
  }

  /** Starts a walk along the waypoints [[x, z], ...]; any direction input cancels it. */
  walkTo(path, then = null) {
    this.autoPath = path && path.length > 0 ? path : null;
    this.autoThen = this.autoPath ? then : null;
    this.autoIndex = 0;
    this.autoStuck = 0;
    this.arrived = false;
  }

  /** The unit direction [x, z] of the walk this step, or null when it is over (then `arrived` says whether it got there). */
  autoSteer(dt) {
    const p = this.entity.position;
    // Walking up to an object: stop where it can be used, not at its middle.
    if (this.autoThen) {
      const [sx, sz] = this.autoThen.spot;
      if (Math.hypot(sx - p.x, sz - p.z) <= this.autoThen.reach * 0.7) {
        this.autoPath = null;
        this.arrived = true;
        return null;
      }
    }
    while (this.autoIndex < this.autoPath.length) {
      const w = this.autoPath[this.autoIndex];
      const dx = w[0] - p.x;
      const dz = w[1] - p.z;
      const d = Math.hypot(dx, dz);
      const last = this.autoIndex === this.autoPath.length - 1;
      if (d < (last ? 0.25 : 0.4)) {
        this.autoIndex++;
        this.autoStuck = 0;
        continue;
      }
      // Blocked (a door that is shut, a chair in the way): give up instead of pushing on it for ever.
      this.autoStuck = this.speed < 0.5 ? this.autoStuck + dt : 0;
      if (this.autoStuck > 0.8) break;
      return [dx / d, dz / d];
    }
    this.arrived = this.autoStuck <= 0.8;
    this.autoPath = null;
    return null;
  }

  /** Sends the porter to a world point [x, y, z] by the NavMesh3D. Returns true when a walk started. */
  goTo(to, then = null) {
    const p = this.entity.position;
    const r = nav.findPath([p.x, p.y - this.feet, p.z], to, { radius: this.navRadius, snap: this.snap, closest: true });
    if (!r.found || r.points.length === 0) return false;
    // points[0] is where the porter stands: walk to the corners after it.
    const corners = r.points.length > 1 ? r.points.slice(1) : r.points;
    this.walkTo(corners.map((q) => [q.x, q.z]), then);
    return true;
  }

  // ----------------------------------------------------------------------------------- interaction and clicks
  onUpdate() {
    if (input.lastDevice !== this.device) {
      this.device = input.lastDevice;
      emit(EVENTS.deviceChanged, { device: this.device });
    }
    this.readClicks();
    this.updateTarget();
    if (!this.locked && this.target && input.pressed("interact")) this.use(this.target);
    // A click-to-walk that was going to use something has arrived.
    if (this.autoThen && !this.autoPath) {
      const b = this.autoThen;
      this.autoThen = null;
      const p = this.entity.position;
      const [sx, sz] = b.spot;
      if (this.arrived && !this.locked && b.available && Math.hypot(sx - p.x, sz - p.z) <= b.reach + 0.3) this.use(b);
    }
  }

  /** Forgets the list of interactables so the next update reads it again: call it after spawning or destroying one (scripts/cast.js). */
  refreshInteractables() {
    this.interactables = null;
  }

  /** Finds the nearest interactable in reach and in front, highlights it and writes the prompt. */
  updateTarget() {
    let best = null;
    if (!this.interactables) this.interactables = world.findByTag("interactable").map((e) => e.behaviour).filter((b) => b);
    if (!this.locked) {
      const p = this.entity.position;
      const fx = -Math.sin(this.yaw * DEG);
      const fz = -Math.cos(this.yaw * DEG);
      let bestD = Infinity;
      for (const b of this.interactables) {
        if (!b.entity.alive || !b.available) continue;
        const [sx, sz] = b.spot;
        const dx = sx - p.x;
        const dz = sz - p.z;
        const d = Math.hypot(dx, dz);
        if (d > b.reach || d >= bestD) continue;
        if (d > this.closeRange && (dx * fx + dz * fz) / d < this.facing) continue;
        best = b;
        bestD = d;
      }
    }
    if (best !== this.target) {
      if (this.target && this.target.entity.alive) this.target.setHighlight(false);
      this.target = best;
      if (best) best.setHighlight(true);
      emit(EVENTS.targetChanged, { id: best ? best.entity.id : null, kind: best ? best.kind : "", verb: best ? best.verbKey() : null });
    }
    // The prompt follows the target, the device and the language.
    const key = best ? `${best.entity.id}|${input.lastDevice}|${i18n.language}|${input.lastDevice === "gamepad" ? input.gamepad(0).type : ""}` : "";
    if (key !== this.promptKey) {
      this.promptKey = key;
      const hud = world.find(this.hudId)?.behaviour;
      if (hud) hud.setPrompt(best ? this.promptText(best) : "");
    }
  }

  /** The prompt line for `b`: "[F] Open the door", "[A] ...", "[Click] ...", "[Tap] ..." by the last device used. */
  promptText(b) {
    const device = input.lastDevice;
    const label = device === "touch" ? i18n.t("prompt.tap") : device === "mouse" ? i18n.t("prompt.click") : input.buttonName("interact");
    return i18n.t("prompt.format", { key: label, verb: i18n.t(b.verbKey()), name: b.displayName() });
  }

  /** Uses `b` now: turns to it, stops, plays the animation. Returns the result of interact(), or null when it cannot be used. */
  use(b) {
    if (!b.entity.alive || !b.available) return null;
    const p = this.entity.position;
    const [sx, sz] = b.spot;
    if (Math.hypot(sx - p.x, sz - p.z) > 0.2) this.faceYaw(Math.atan2(-(sx - p.x), -(sz - p.z)) / DEG);
    this.autoPath = null;
    this.autoThen = null;
    const r = b.interact();
    if (r.ok && this.anim) {
      if (r.kind === "item") this.anim.trigger("pickup");
      else if (r.kind === "door" || r.kind === "examine") this.anim.trigger("interact");
    }
    return r;
  }

  /** Reads the mouse (touches drive it): a press and release without much movement is a click. */
  readClicks() {
    const m = input.mouse;
    if (input.touches.length > 1) this.click = null; // two fingers: a pinch
    if (m.pressed("left")) {
      const pos = m.position;
      // Ask what is under the pointer now: ui.hovered still describes the frame before when a tap moves the pointer.
      // Keep the id, not the widget object: a widget read now is not safe to touch on a later frame.
      const w = ui.widgetAt(pos.x, pos.y);
      this.click = { x: pos.x, y: pos.y, drag: 0, onUi: !!w, widgetId: w ? w.id : null };
    } else if (this.click && m.down("left")) {
      this.click.drag += Math.hypot(m.delta.x, m.delta.y);
    }
    if (this.click && m.released("left")) {
      const c = this.click;
      this.click = null;
      if (c.drag <= this.tapSlop) this.onClick(c);
    }
  }

  onClick(c) {
    if (this.locked) return;
    if (c.onUi) {
      // A click on the prompt uses what it names (the touch player's button).
      if (c.widgetId === "prompt_panel" && this.target) this.use(this.target);
      return;
    }
    if (this.clickToWalk) this.clickAt([c.x, c.y]);
  }

  /** What a click does: walk to an object and use it, or walk to the floor point under the pointer. Returns true when something started. */
  clickAt(screen) {
    const near = camera.screenToWorld(screen, 1);
    const far = camera.screenToWorld(screen, 80);
    const d = [far.x - near.x, far.y - near.y, far.z - near.z];
    const len = Math.hypot(d[0], d[1], d[2]);
    if (len < 1e-6) return false;
    const o = [near.x, near.y, near.z];
    const dir = [d[0] / len, d[1] / len, d[2] / len];
    // The first thing under the pointer. Walls and tall furniture that fade when they hide the porter are looked through
    // (what is behind a faded wall can be clicked); low furniture and anything else stops the ray.
    let prop = null;
    let at = o;
    for (let i = 0; i < 6; i++) {
      prop = physics.raycast3d(at, dir, 200, { mask: LAYER_PROPS, ignore: this.entity });
      if (!prop || prop.entity.hasTag("interactable") || !prop.entity.hasTag("fade")) break;
      const s = prop.distance + 0.03;
      at = [at[0] + dir[0] * s, at[1] + dir[1] * s, at[2] + dir[2] * s];
      prop = null;
    }
    const b = prop && prop.entity.hasTag("interactable") ? prop.entity.behaviour : null;
    if (b && b.available) {
      this.lastClick = { kind: "object", id: b.entity.id };
      const p = this.entity.position;
      const [sx, sz] = b.spot;
      if (Math.hypot(sx - p.x, sz - p.z) <= b.reach) {
        this.use(b);
        return true;
      }
      return this.goTo([sx, p.y - this.feet, sz], b);
    }
    const ground = physics.raycast3d(o, dir, 200, { mask: LAYER_GROUND, ignore: this.entity });
    if (!ground) return false;
    this.lastClick = { kind: "ground", point: [ground.point.x, ground.point.y, ground.point.z] };
    return this.goTo([ground.point.x, ground.point.y, ground.point.z]);
  }
}

/** Moves angle `a` towards `b` (degrees) by at most `maxStep`, the short way round. */
function turnToward(a, b, maxStep) {
  const d = ((((b - a) % 360) + 540) % 360) - 180;
  if (Math.abs(d) <= maxStep) return b;
  return a + Math.sign(d) * maxStep;
}
