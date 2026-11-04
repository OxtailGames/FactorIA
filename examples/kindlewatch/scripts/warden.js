// @ts-check
// The warden: walks with the stick or the keys, swings the torch, carries up to `maxLogs` logs and takes the hits.
// It is a rigged model (assets/models/warden.rig.glb) with an Animator (idle, walk, run, attack, hit) and a
// CharacterController3D; this script moves it with physics.moveCharacter and feeds the Animator its `speed` parameter.
//
// Other scripts use: logs, hearts, hurt(from), addLog(), takeLog(), swinging, locked (ignores the input), heal().
// Events it sends (world.emit): warden_hurt {hearts}, warden_swing {}, warden_down {} (no heart left).
import { Behaviour, input, physics, audio, world, rng } from "factoria";
import { DEG, yawOf, turnToward, angleDiff, flatDistance } from "./common.js";

export default class Warden extends Behaviour {
  /** Top speed, metres per second. */
  speed = 5.4;
  /** Slowest speed the stick gives (below this tilt the warden stands still). */
  deadZone = 0.15;
  /** How fast the velocity follows the wanted one, m/s^2. */
  accel = 38;
  /** Turning speed, degrees per second. */
  turnSpeed = 840;
  /** Hearts at the start (the HUD draws this many). */
  maxHearts = 3;
  /** Logs that fit in the arms. */
  maxLogs = 3;
  /** The torch reaches this far, metres. */
  reach = 2.7;
  /** Half the width of the swing, degrees from the facing. */
  halfArc = 70;
  /** Seconds between swings. */
  swingCooldown = 0.55;
  /** Seconds of safety after a hit. */
  grace = 1.5;
  /** Footstep volume. */
  stepVolume = 0.5;

  onStart() {
    this.hearts = this.maxHearts;
    this.logs = 0;
    this.locked = false;
    this.swinging = 0;
    this.cooldown = 0;
    this.safe = 0;
    this.vx = 0;
    this.vz = 0;
    this.yaw = 180;
    this.currentSpeed = 0;
    this.stepIndex = 0;
    this.anim = this.entity.animator;
    this.carriedViews = [1, 2, 3].map((i) => world.find(`carried_${i}`));
    this.drawLogs();
    this.entity.get("Transform").rotation = [0, this.yaw, 0];
    this.unsubscribes = [
      // Clip events of the Animator arrive here from every animator: keep this entity's own.
      world.on("warden_swing_hit", (_d, source) => source?.id === this.entity.id && this.strike()),
      world.on("warden_step", (_d, source) => source?.id === this.entity.id && this.footstep()),
    ];
  }

  onDestroy() {
    for (const off of this.unsubscribes ?? []) off();
  }

  onFixedUpdate(dt) {
    if (this.cooldown > 0) this.cooldown -= dt;
    if (this.safe > 0) this.safe -= dt;
    if (this.swinging > 0) this.swinging -= dt;

    // --- wanted motion from the move_* actions (keys, gamepad stick, or the TouchStick feeding the stick)
    let ix = 0;
    let iz = 0;
    if (!this.locked) {
      const v = input.vector("move_left", "move_right", "move_back", "move_forward");
      ix = v.x;
      iz = -v.y; // "forward" is -Z
    }
    let mag = Math.hypot(ix, iz);
    if (mag < this.deadZone) {
      ix = 0;
      iz = 0;
      mag = 0;
    } else if (mag > 1) {
      ix /= mag;
      iz /= mag;
      mag = 1;
    }
    // Swinging slows the warden to a crawl: the torch is a commitment.
    const top = this.speed * (this.swinging > 0 ? 0.25 : 1);
    const wantX = ix * top;
    const wantZ = iz * top;
    const dx = wantX - this.vx;
    const dz = wantZ - this.vz;
    const dl = Math.hypot(dx, dz);
    const step = this.accel * dt;
    if (dl <= step) {
      this.vx = wantX;
      this.vz = wantZ;
    } else {
      this.vx += (dx / dl) * step;
      this.vz += (dz / dl) * step;
    }

    // --- the swing (attack action: Space, J, gamepad A, left mouse button, the touch button)
    if (!this.locked && input.pressed("attack") && this.cooldown <= 0) this.swing();

    // --- facing: where we walk, or at the nearest wolf while swinging (so a thumb on a phone needs no aim)
    if (this.swinging > 0) {
      const w = this.nearestWolf(this.reach + 1.2);
      if (w) this.yaw = turnToward(this.yaw, yawOf(w.position.x - this.entity.position.x, w.position.z - this.entity.position.z), this.turnSpeed * dt);
    } else if (mag > 0) {
      this.yaw = turnToward(this.yaw, yawOf(ix, iz), this.turnSpeed * dt);
    }

    const r = physics.moveCharacter(this.entity, [this.vx * dt, -3 * dt, this.vz * dt]);
    if (r.hitWall) {
      this.vx = r.moved.x / dt;
      this.vz = r.moved.z / dt;
    }
    this.currentSpeed = Math.hypot(this.vx, this.vz);
    this.entity.get("Transform").rotation = [0, this.yaw, 0];
    if (this.anim) this.anim.set("speed", this.currentSpeed);
  }

  /** The torch swing starts: the Animator plays "attack"; the hit lands on its "warden_swing_hit" clip event. */
  swing() {
    this.cooldown = this.swingCooldown;
    this.swinging = 0.5;
    this.anim?.trigger("swing");
    audio.play("assets/audio/swing.wav", { variants: 4, volume: 0.7, bus: "sfx" });
    world.emit("warden_swing", {});
  }

  /** The moment the torch passes the wolves: every wolf in the arc in front takes a hit. */
  strike() {
    const p = this.entity.position;
    let hits = 0;
    for (const w of world.findByTag("wolf")) {
      const b = w.behaviour;
      if (!b || b.dead) continue;
      const dx = w.position.x - p.x;
      const dz = w.position.z - p.z;
      const d = Math.hypot(dx, dz);
      if (d > this.reach + (b.bodyRadius ?? 0.5)) continue;
      if (d > 0.8 && Math.abs(angleDiff(this.yaw, yawOf(dx, dz))) > this.halfArc) continue;
      b.hurt(1, [dx, dz], this.entity);
      hits++;
    }
    return hits;
  }

  nearestWolf(range) {
    const p = this.entity.position;
    let best = null;
    let bestD = range;
    for (const w of world.findByTag("wolf")) {
      if (w.behaviour?.dead) continue;
      const d = Math.hypot(w.position.x - p.x, w.position.z - p.z);
      if (d < bestD) {
        best = w;
        bestD = d;
      }
    }
    return best;
  }

  /** A wolf bites: lose a heart (unless just hit), get pushed away from it. Returns true when the bite landed. */
  hurt(from, damage = 1) {
    if (this.safe > 0 || this.hearts <= 0 || this.locked) return false;
    this.hearts = Math.max(0, this.hearts - damage);
    this.safe = this.grace;
    this.anim?.trigger("hurt");
    audio.play("assets/audio/warden_hurt.wav", { variants: 3, volume: 0.9, bus: "sfx" });
    const p = this.entity.position;
    const dx = p.x - from[0];
    const dz = p.z - from[1];
    const d = Math.hypot(dx, dz) || 1;
    this.vx = (dx / d) * 7;
    this.vz = (dz / d) * 7;
    world.emit("camera_shake", { size: 0.25, time: 0.3 });
    world.emit("warden_hurt", { hearts: this.hearts });
    if (this.hearts <= 0) world.emit("warden_down", {});
    return true;
  }

  /** One heart back (the dawn). */
  heal() {
    this.hearts = Math.min(this.maxHearts, this.hearts + 1);
  }

  /** A log picked up; false when the arms are full. */
  addLog() {
    if (this.logs >= this.maxLogs) return false;
    this.logs++;
    this.drawLogs();
    audio.play("assets/audio/log_pickup.wav", { volume: 0.8, bus: "sfx" });
    return true;
  }

  /** A log given to the fire; false when carrying none. */
  takeLog() {
    if (this.logs <= 0) return false;
    this.logs--;
    this.drawLogs();
    return true;
  }

  drawLogs() {
    this.carriedViews.forEach((v, i) => v && (v.active = i < this.logs));
  }

  /** A "warden_step" clip event of the walk and run cycles. */
  footstep() {
    if (this.currentSpeed < 0.5) return;
    this.stepIndex++;
    audio.play("assets/audio/footstep.wav", {
      variants: 6,
      volume: this.stepVolume * (this.currentSpeed > 4 ? 1 : 0.6),
      pitch: this.stepIndex % 2 ? 1 : 0.94,
      bus: "sfx",
    });
  }
}
