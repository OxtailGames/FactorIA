// @ts-check
// The courier: a wind-up robot driven by a CharacterController3D. This script owns the movement (camera-relative, analog
// speed, smooth turning, gravity, a jump with coyote time and a jump buffer, air control), the animator parameters and the
// footstep sounds. Everything a designer may want to tune is a class field; the scene overrides them with Script.props.
//
// Entity layout (scenes/test_yard.scene.json): "courier" (this script + CharacterController3D, origin = capsule centre)
//   |- "model"          the robot.glb with the Animator, turned to face the heading (the glb looks down +Z)
//   '- "carried_parcel" a small box on the back, active while a parcel is carried
//
// Other scripts talk to it through these methods: pickParcel(id, optional), deliver(), celebrate(), windDown(), caught(by),
// walkTo(path) (tap-to-move), and the fields `locked` (ignores input), `carrying`, `speed`, `grounded`, `surface`,
// `grace` (seconds of safety after a catch or a respawn: dogs ignore the courier) and `isCaught`.
//
// A catch is not the end of the level: the courier lies down for `caughtTime` seconds (the Death clip), the spring pays
// `caughtPenalty` seconds, and it gets up at the last checkpoint with `graceTime` seconds of safety.
//
// Moving platforms: a CharacterController3D is not carried by the body it stands on (ENGINE_FEEDBACK FB-0010), so the
// courier adds the velocity of the kinematic RigidBody3D under its feet to its own move.
import { Behaviour, input, physics, world, audio } from "factoria";
import { EVENTS, emit } from "./events.js";
import * as fx from "./fx.js";

const DEG = Math.PI / 180;

/** Footstep variants in the order they are played: never the same twice in a row. */
const STEP_ORDER = [0, 2, 1, 3, 2, 0, 3, 1];

export default class Courier extends Behaviour {
  /** Top speed running (keyboard, or the stick fully tilted), metres per second. */
  runSpeed = 5;
  /** Top speed while the walk key is held (Shift); a half-tilted stick lands between the two. */
  walkSpeed = 2;
  /** How fast the horizontal velocity follows the wanted one on the ground, m/s^2. */
  groundAccel = 45;
  /** Slowing down on the ground when no direction is held, m/s^2. */
  groundDecel = 40;
  /** Air control: how fast the horizontal velocity follows the wanted one in the air, m/s^2. */
  airAccel = 14;
  /** Slowing down in the air when no direction is held (low: a jump keeps its momentum), m/s^2. */
  airDecel = 4;
  /** How fast the robot turns to face where it walks, degrees per second. */
  turnSpeed = 720;
  /** Gravity on the courier, m/s^2 (stronger than the world's 9.81 for a snappy jump). */
  gravity = 24;
  /** Jump height in metres: the take-off speed is sqrt(2 * gravity * jumpHeight). */
  jumpHeight = 1.2;
  /** Longest fall speed, m/s. */
  maxFallSpeed = 30;
  /** Seconds after walking off a ledge in which a jump still works. */
  coyoteTime = 0.12;
  /** Seconds a jump press is remembered before landing, so a press just too early still jumps. */
  jumpBuffer = 0.12;
  /** Speed (m/s) above which the run animation plays instead of the walk one. */
  runAnimSpeed = 3.6;
  /** Falling faster than this (m/s) plays the fall animation. */
  fallAnimSpeed = 4;
  /** Landing at least this hard (m/s) makes a thud. */
  thudSpeed = 5;
  /** Below this height the courier fell out of the world and goes back to the last checkpoint. */
  killY = -12;
  /** Entity id of the camera whose yaw makes the movement camera-relative. */
  cameraId = "camera";
  /** Entity id of the visual child that turns. */
  modelId = "model";
  /** Entity id of the parcel box on the back. */
  parcelVisualId = "carried_parcel";
  /** Footstep volume while running (walking is 60% of it). */
  footstepVolume = 0.5;
  /** Seconds the courier lies on the ground after a catch before it is back at the last checkpoint. */
  caughtTime = 1.4;
  /** Seconds of spring a catch costs. */
  caughtPenalty = 5;
  /** Seconds after getting up (or after any respawn) in which dogs cannot catch the courier again. */
  graceTime = 1.5;
  /** Speed of an automatic walk (tap-to-move), m/s. */
  autoSpeed = 4.2;
  /** Entity id of the level flow (to know whether the level is over). */
  levelId = "level";

  onStart() {
    /** Horizontal velocity, m/s. */
    this.vx = 0;
    this.vz = 0;
    /** Vertical velocity, m/s. */
    this.vy = 0;
    /** Heading in degrees (0 = looking down -Z, like a camera). */
    this.yaw = 0;
    this.grounded = false;
    this.coyote = 0;
    this.buffer = 0;
    /** True: input is ignored (celebrating, wound down, caught, or the level is over). */
    this.locked = false;
    this.carrying = 0;
    /** How many of the parcels carried are optional ones (off the main route). */
    this.carryingOptional = 0;
    /** True from a catch until the courier gets up. */
    this.isCaught = false;
    this.caughtTimer = 0;
    /** Seconds of safety left (dogs ignore the courier while > 0). */
    this.grace = 0;
    /** Waypoints [x, z] of an automatic walk (tap-to-move), or null. */
    this.autoPath = null;
    this.autoIndex = 0;
    this.autoStuck = 0;
    /** Horizontal speed this step, m/s. */
    this.speed = 0;
    /** "concrete" or "wood": what the courier stands on. */
    this.surface = "concrete";
    /** @type {any} */
    this.ground = null;
    this.stepCount = 0;
    this.respawn = [this.entity.position.x, this.entity.position.y, this.entity.position.z];
    this.model = world.find(this.modelId);
    this.parcelVisual = world.find(this.parcelVisualId);
    if (this.parcelVisual) this.parcelVisual.active = false;
    this.anim = this.model ? this.model.animator : null;
    this.unsubscribes = [
      // The animator's "footstep" clip events (walk and run cycles) arrive here from every animator of the scene.
      world.on("footstep", (data, source) => {
        if (source && source.id === this.model?.id) this.footstep();
      }),
      world.on(EVENTS.checkpointReached, (d) => {
        if (d && d.position) this.respawn = [d.position[0], d.position[1], d.position[2]];
      }),
    ];
  }

  onDestroy() {
    for (const off of this.unsubscribes ?? []) off();
  }

  /** Yaw of the camera in degrees (0 when the scene has no follow camera). */
  cameraYaw() {
    const cam = world.find(this.cameraId);
    const b = cam ? cam.behaviour : null;
    return b && typeof b.yaw === "number" ? b.yaw : 0;
  }

  onFixedUpdate(dt) {
    if (this.grace > 0) this.grace -= dt;
    if (this.isCaught) {
      this.caughtTimer -= dt;
      if (this.caughtTimer <= 0) this.getUp();
    }
    // ------------------------------------------------------------------------------------------------- wanted motion
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
    const top = input.down("walk") ? this.walkSpeed : this.runSpeed;
    // Camera-relative: stick up = away from the camera.
    const cy = this.cameraYaw() * DEG;
    const s = Math.sin(cy);
    const c = Math.cos(cy);
    let wantX = (ix * c - iz * s) * top;
    let wantZ = (-ix * s - iz * c) * top;
    // An automatic walk (tap-to-move) steers when the player holds no direction; any direction or jump cancels it.
    if (this.autoPath) {
      if (this.locked || mag > 0.1 || input.pressed("jump")) this.autoPath = null;
      else {
        const w = this.autoSteer(dt);
        if (w) {
          wantX = w[0] * this.autoSpeed;
          wantZ = w[1] * this.autoSpeed;
          mag = 1;
        }
      }
    }

    const accel = mag > 0 ? (this.grounded ? this.groundAccel : this.airAccel) : this.grounded ? this.groundDecel : this.airDecel;
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

    // Face the way we want to go (wanted, not actual: turning starts at once and a wall does not spin the robot).
    if (mag > 0.1) {
      const target = Math.atan2(-wantX, -wantZ) / DEG;
      this.yaw = turnToward(this.yaw, target, this.turnSpeed * dt);
    }

    // -------------------------------------------------------------------------------------------------------- jump
    if (!this.locked && input.pressed("jump")) this.buffer = this.jumpBuffer;
    else this.buffer -= dt;
    this.coyote = this.grounded ? this.coyoteTime : this.coyote - dt;
    let jumped = false;
    if (this.buffer > 0 && this.coyote > 0 && !this.locked) {
      // sqrt(2 g h) is the exact take-off speed; the half step added makes up for the first gravity step of the fixed
      // update, so the apex really is jumpHeight above the take-off point.
      this.vy = Math.sqrt(2 * this.gravity * this.jumpHeight) + 0.5 * this.gravity * dt;
      this.grounded = false;
      this.coyote = 0;
      this.buffer = 0;
      jumped = true;
      audio.play("assets/audio/impactSoft_medium_000.ogg", { bus: "sfx", volume: 0.5 });
    }
    // A small downward speed on the ground keeps the capsule snapped to it (ramps, steps down).
    this.vy = this.grounded ? Math.min(this.vy, -1) : Math.max(this.vy - this.gravity * dt, -this.maxFallSpeed);

    // ---------------------------------------------------------------------------------------------------------- move
    const before = this.vy;
    const carry = this.platformCarry(dt);
    const r = physics.moveCharacter(this.entity, [this.vx * dt + carry[0], this.vy * dt + carry[1], this.vz * dt + carry[2]]);
    const wasGrounded = this.grounded;
    this.grounded = r.isGrounded && !jumped;
    this.ground = r.ground;
    this.surface = r.ground && r.ground.hasTag("wood") ? "wood" : "concrete";
    if (r.hitCeiling && this.vy > 0) this.vy = 0;
    if (r.hitWall) {
      // Slide: keep only the velocity that actually happened.
      this.vx = (r.moved.x - carry[0]) / dt;
      this.vz = (r.moved.z - carry[2]) / dt;
    }
    if (this.grounded && !wasGrounded && before < -this.thudSpeed) {
      audio.play("assets/audio/impactSoft_heavy_000.ogg", { bus: "sfx", volume: Math.min(0.8, -before / 20) });
      const p = r.position;
      fx.burst("dust", [p.x, p.y - 0.5, p.z]);
    }
    if (this.grounded && this.vy > 0) this.vy = 0;
    this.speed = Math.hypot(this.vx, this.vz);

    if (r.position.y < this.killY) this.respawnAtCheckpoint();

    // ------------------------------------------------------------------------------------------------------ visuals
    if (this.model) this.model.get("Transform").rotation = [0, this.yaw + 180, 0];
    if (this.anim) {
      this.anim.set("speed", this.speed);
      this.anim.set("grounded", this.grounded);
      this.anim.set("vy", this.vy);
      if (jumped) this.anim.trigger("jump");
    }
  }

  /** A "footstep" clip event: one variant of the surface's sound, alternating, a touch softer when walking. */
  footstep() {
    if (!this.grounded) return;
    const n = STEP_ORDER[this.stepCount % STEP_ORDER.length];
    const left = this.stepCount % 2 === 0;
    this.stepCount++;
    const run = this.speed >= this.runAnimSpeed;
    audio.play(`assets/audio/footstep_${this.surface}_00${n}.ogg`, {
      bus: "sfx",
      volume: this.footstepVolume * (run ? 1 : 0.6),
      pitch: left ? 1 : 0.94,
    });
  }

  /** How far the body under the feet moves the courier this step: the velocity of a kinematic RigidBody3D (a moving platform). */
  platformCarry(dt) {
    const g = this.ground;
    if (!g || !this.grounded) return [0, 0, 0];
    const rb = g.get("RigidBody3D");
    if (!rb || rb.type !== "kinematic") return [0, 0, 0];
    const v = rb.velocity;
    return [v.x * dt, v.y * dt, v.z * dt];
  }

  /** Puts the courier back at the last checkpoint (or where it started) after a fall. */
  respawnAtCheckpoint() {
    this.entity.position = this.respawn;
    this.vx = this.vz = this.vy = 0;
    this.grounded = false;
    this.autoPath = null;
    this.grace = Math.max(this.grace, this.graceTime);
  }

  /** Starts an automatic walk along the waypoints [[x, z], ...] (tap-to-move). Any direction input cancels it. */
  walkTo(path) {
    this.autoPath = path && path.length > 0 ? path : null;
    this.autoIndex = 0;
    this.autoStuck = 0;
  }

  /** The unit direction [x, z] of the automatic walk this step, or null when it is over. */
  autoSteer(dt) {
    const p = this.entity.position;
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
      // Blocked (a crate pushed into the way, a closed gate): give up instead of pushing on the wall forever.
      this.autoStuck = this.speed < 0.5 ? this.autoStuck + dt : 0;
      if (this.autoStuck > 0.8) break;
      return [dx / d, dz / d];
    }
    this.autoPath = null;
    return null;
  }

  /** Gets up after a catch: back at the last checkpoint, the spring paid its penalty, a moment of safety. */
  getUp() {
    this.isCaught = false;
    const flow = world.find(this.levelId)?.behaviour;
    this.entity.position = this.respawn;
    this.vx = this.vz = this.vy = 0;
    this.grounded = false;
    this.grace = this.graceTime;
    const spring = world.find("spring")?.behaviour;
    if (spring && this.caughtPenalty > 0) spring.drain(this.caughtPenalty);
    if (flow && flow.finished) return;
    this.locked = false;
    if (this.anim) this.anim.trigger("recover");
  }

  // ------------------------------------------------------------------------------------------------- called by others
  /** A parcel was picked up: shows it on the back and counts it. */
  pickParcel(id, optional = false) {
    this.carrying++;
    if (optional) this.carryingOptional++;
    if (this.parcelVisual) this.parcelVisual.active = true;
    audio.play("assets/audio/pluck_001.ogg", { bus: "sfx", volume: 0.8 });
    emit(EVENTS.parcelPicked, { parcel: id, carrying: this.carrying });
  }

  /** Hands in every parcel carried; returns how many. */
  deliver() {
    const n = this.carrying;
    /** How many of the parcels just handed in were optional (read it right after deliver()). */
    this.deliveredOptional = this.carryingOptional;
    this.carrying = 0;
    this.carryingOptional = 0;
    if (this.parcelVisual) this.parcelVisual.active = false;
    return n;
  }

  /** Delivery dance. The courier stops taking input. */
  celebrate() {
    this.locked = true;
    if (this.anim) this.anim.trigger("celebrate");
  }

  /** The spring ran out: the courier slows down and sits. */
  windDown() {
    this.locked = true;
    if (this.anim) this.anim.trigger("wind_down");
  }

  /** Something caught the courier: plays Death for `caughtTime` seconds, then it is back at the last checkpoint. */
  caught(by = "unknown") {
    if (this.isCaught || this.grace > 0 || this.locked) return;
    this.isCaught = true;
    this.caughtTimer = this.caughtTime;
    this.autoPath = null;
    this.locked = true;
    audio.play("assets/audio/impactMetal_light_000.ogg", { bus: "sfx", volume: 0.8 });
    if (this.anim) this.anim.trigger("caught");
    emit(EVENTS.courierCaught, { by });
  }
}

/** Moves angle `a` towards `b` (degrees) by at most `maxStep`, the short way round. */
function turnToward(a, b, maxStep) {
  let d = (((b - a) % 360) + 540) % 360 - 180;
  if (Math.abs(d) <= maxStep) return b;
  return a + Math.sign(d) * maxStep;
}
