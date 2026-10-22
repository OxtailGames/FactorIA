// @ts-check
// A moving platform: a kinematic RigidBody3D that goes to `offset` and back at `speed`, waiting `wait` seconds at each end.
// It moves by setting the body's velocity (never the Transform), so the engine carries whatever stands on it: dynamic
// bodies and the courier (CharacterController3D.carriedByPlatforms).
//
// The velocity is clamped at each end so the platform lands exactly on its end point whatever dt is, and the whole
// motion is a function of the fixed steps only (deterministic). `phase` (0..1) starts it part-way, so two platforms
// can alternate.
import { Behaviour } from "factoria";

export default class Mover extends Behaviour {
  /** Where it goes, relative to where it starts: [dx, dy, dz] metres. */
  offset = [0, 0, 6];
  /** Speed in metres per second. */
  speed = 2;
  /** Seconds it waits at each end. */
  wait = 1;
  /** Start part-way along the trip, 0..1 (0 = at the start point). */
  phase = 0;

  onStart() {
    const p = this.entity.position;
    this.a = [p.x, p.y, p.z];
    this.b = [p.x + this.offset[0], p.y + this.offset[1], p.z + this.offset[2]];
    this.len = Math.hypot(this.offset[0], this.offset[1], this.offset[2]);
    this.body = this.entity.get("RigidBody3D");
    // pos is the distance travelled along the trip, dir +1 going out, -1 coming back.
    this.pos = this.len * Math.max(0, Math.min(1, this.phase));
    this.dir = 1;
    this.waiting = 0;
    if (this.pos > 0) this.entity.position = this.at(this.pos);
  }

  at(s) {
    const f = this.len > 0 ? s / this.len : 0;
    return [this.a[0] + (this.b[0] - this.a[0]) * f, this.a[1] + (this.b[1] - this.a[1]) * f, this.a[2] + (this.b[2] - this.a[2]) * f];
  }

  onFixedUpdate(dt) {
    if (!this.body || this.len <= 0) return;
    if (this.waiting > 0) {
      this.waiting -= dt;
      this.body.velocity = [0, 0, 0];
      return;
    }
    const room = this.dir > 0 ? this.len - this.pos : this.pos;
    const step = Math.min(this.speed * dt, room);
    const move = this.dir * step;
    this.pos += move;
    if (step >= room - 1e-9) {
      this.dir = -this.dir;
      this.waiting = this.wait;
    }
    const f = move / dt / this.len;
    this.body.velocity = [(this.b[0] - this.a[0]) * f, (this.b[1] - this.a[1]) * f, (this.b[2] - this.a[2]) * f];
  }
}
