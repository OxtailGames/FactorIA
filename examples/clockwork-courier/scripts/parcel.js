// @ts-check
// A parcel lying in the level: a trigger box that bobs and spins until the courier walks into it. The courier's
// pickParcel() counts it, shows it on the robot's back and sends parcel_picked. An `optional` parcel lies off the main
// route: delivering it is not needed to win, only for the `thorough` goal of scripts/stars.js.
import { Behaviour } from "factoria";

export default class Parcel extends Behaviour {
  /** True for a bonus parcel (not needed to win the level). */
  optional = false;
  /** Bob amplitude in metres. */
  bobHeight = 0.12;
  /** Spin speed in degrees per second. */
  spin = 90;

  onStart() {
    this.baseY = this.entity.position.y;
    this.taken = false;
    this.t = 0;
  }

  onUpdate(dt) {
    this.t += dt;
    const tr = this.entity.get("Transform");
    tr.position = [tr.position.x, this.baseY + Math.sin(this.t * 3) * this.bobHeight, tr.position.z];
    tr.rotation = [0, (this.t * this.spin) % 360, 0];
  }

  onTriggerEnter(other) {
    if (this.taken || !other.hasTag("courier")) return;
    this.taken = true;
    other.behaviour.pickParcel(this.entity.id, this.optional);
    this.entity.destroy();
  }
}
