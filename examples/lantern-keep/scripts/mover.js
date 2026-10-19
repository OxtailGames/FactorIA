// @ts-check
// A moving platform: a kinematic body that swings back and forth around where the map put it, `range` pixels each way
// along `axis`, in `period` seconds. Smooth at both ends, so a player standing on it is not thrown off.
import { Behaviour } from "factoria";

export default class Mover extends Behaviour {
  /** Direction of the swing: [1, 0] sideways, [0, 1] up and down. */
  axis = [1, 0];
  /** Distance from the centre to each end, in pixels. */
  range = 96;
  /** Seconds for a whole swing there and back. */
  period = 5;

  onStart() {
    this.t = 0;
    this.body = this.entity.get("RigidBody2D");
  }

  onFixedUpdate(dt) {
    this.t += dt;
    const w = (2 * Math.PI) / this.period;
    const v = this.range * w * Math.cos(w * this.t); // the derivative of range * sin(w t)
    this.body.velocity.x = this.axis[0] * v;
    this.body.velocity.y = this.axis[1] * v;
  }
}
