// @ts-check
// Kinematic platform that oscillates around its start position, driven by velocity so physics sees the motion.
import { Behaviour, time } from "factoria";

export default class Mover extends Behaviour {
  /** Peak displacement per axis in meters. */
  amplitude = [4, 0, 0];
  /** Angular speed in radians per second. */
  speed = 1;
  phase = 0;

  onStart() {
    this.body = this.entity.get("RigidBody3D");
    this.t = 0;
  }

  onFixedUpdate(dt) {
    this.t += dt;
    const k = Math.cos(this.t * this.speed + this.phase) * this.speed;
    const v = this.body.velocity;
    v.x = this.amplitude[0] * k;
    v.y = this.amplitude[1] * k;
    v.z = this.amplitude[2] * k;
  }
}
