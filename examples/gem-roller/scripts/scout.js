// @ts-check
// The scout: a small character walking a loop on the start platform. It stops and turns to the ball when the ball comes close.
// Its model, rig and clips are all made with the engine (assets/models/scout.model.json -> scout.rig.json -> assets/anim/scout_*.anim.json).
import { Behaviour, math } from "factoria";

export default class Scout extends Behaviour {
  /** Centre of the loop in meters (x, y, z). */
  center = [-1.8, 0.5, -1.2];
  /** Radius of the loop in meters. */
  radius = 1.8;
  /** Walking speed in meters per second: the walk clip's groundSpeed (model units per second) times the entity's scale. */
  speed = 0.83;
  /** Closer than this (meters, on the ground plane) to the ball, the scout stops and watches it. */
  watchRange = 2.6;
  /** Id of the entity to watch. */
  target = "ball";
  /** Turning speed in degrees per second. */
  turnSpeed = 240;

  onStart() {
    this.anim = this.entity.animator;
    this.angle = Math.PI; // start at the west end of the loop
    this.yaw = 0;
    this.watching = false;
    this.steps = 0;
    this.anim.on("footstep", () => { this.steps++; });
    this.place();
    this.anim.play("walk", 0);
  }

  /** Puts the scout on the loop at the current angle, facing along it. */
  place() {
    const p = this.entity.position;
    p.x = this.center[0] + Math.cos(this.angle) * this.radius;
    p.y = this.center[1];
    p.z = this.center[2] + Math.sin(this.angle) * this.radius;
    // The model faces +Z at yaw 0, so a heading (dx, dz) is yaw atan2(dx, dz); the heading along the loop is (-sin, cos).
    this.faceYaw(math.radToDeg(Math.atan2(-Math.sin(this.angle), Math.cos(this.angle))));
  }

  /** Sets the entity's yaw (degrees about +Y; the model faces +Z at yaw 0). */
  faceYaw(deg) {
    this.yaw = deg;
    this.entity.transform.rotation.y = deg;
  }

  onFixedUpdate(dt) {
    const ball = this.world.find(this.target);
    const p = this.entity.position;
    let near = false;
    if (ball) {
      const dx = ball.position.x - p.x;
      const dz = ball.position.z - p.z;
      near = Math.hypot(dx, dz) < this.watchRange;
      if (near) {
        // Turn the short way round towards the ball.
        const want = math.radToDeg(Math.atan2(dx, dz));
        let diff = ((want - this.yaw + 540) % 360) - 180;
        const step = this.turnSpeed * dt;
        diff = Math.max(-step, Math.min(step, diff));
        this.faceYaw(this.yaw + diff);
      }
    }
    if (near !== this.watching) {
      this.watching = near;
      this.anim.play(near ? "idle" : "walk", 0.3);
    }
    if (!near) {
      this.angle += (this.speed / this.radius) * dt;
      this.place();
    }
  }
}
