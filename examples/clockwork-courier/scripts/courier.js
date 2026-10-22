// @ts-check
// The courier: a wind-up robot driven by a CharacterController3D. This script owns the movement (camera-relative, analog
// speed, smooth turning, gravity, a jump with coyote time and a jump buffer, air control), the animator parameters and the
// footstep sounds. Everything a designer may want to tune is a class field; the scene overrides them with Script.props.
//
// Entity layout (scenes/test_yard.scene.json): "courier" (this script + CharacterController3D, origin = capsule centre)
//   |- "model"          the robot.glb with the Animator, turned to face the heading (the glb looks down +Z)
//   '- "carried_parcel" a small box on the back, active while a parcel is carried
//
// Other scripts talk to it through these methods: pickParcel(id), deliver(), celebrate(), windDown(), caught(by),
// and the fields `locked` (ignores input), `carrying`, `speed`, `grounded`, `surface`.
import { Behaviour, input, physics, world, audio } from "factoria";
import { EVENTS, emit } from "./events.js";

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
    const wantX = (ix * c - iz * s) * top;
    const wantZ = (-ix * s - iz * c) * top;

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
    const r = physics.moveCharacter(this.entity, [this.vx * dt, this.vy * dt, this.vz * dt]);
    const wasGrounded = this.grounded;
    this.grounded = r.isGrounded && !jumped;
    this.ground = r.ground;
    this.surface = r.ground && r.ground.hasTag("wood") ? "wood" : "concrete";
    if (r.hitCeiling && this.vy > 0) this.vy = 0;
    if (r.hitWall) {
      // Slide: keep only the velocity that actually happened.
      this.vx = r.moved.x / dt;
      this.vz = r.moved.z / dt;
    }
    if (this.grounded && !wasGrounded && before < -this.thudSpeed) {
      audio.play("assets/audio/impactSoft_heavy_000.ogg", { bus: "sfx", volume: Math.min(0.8, -before / 20) });
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

  /** Puts the courier back at the last checkpoint (or where it started) after a fall. */
  respawnAtCheckpoint() {
    this.entity.position = this.respawn;
    this.vx = this.vz = this.vy = 0;
    this.grounded = false;
  }

  // ------------------------------------------------------------------------------------------------- called by others
  /** A parcel was picked up: shows it on the back and counts it. */
  pickParcel(id) {
    this.carrying++;
    if (this.parcelVisual) this.parcelVisual.active = true;
    audio.play("assets/audio/pluck_001.ogg", { bus: "sfx", volume: 0.8 });
    emit(EVENTS.parcelPicked, { parcel: id, carrying: this.carrying });
  }

  /** Hands in every parcel carried; returns how many. */
  deliver() {
    const n = this.carrying;
    this.carrying = 0;
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

  /** Something caught the courier: plays Death, ignores input. */
  caught(by = "unknown") {
    if (this.locked && this.isCaught) return;
    this.isCaught = true;
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
