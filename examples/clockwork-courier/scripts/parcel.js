// @ts-check
// A parcel lying in the level: a trigger box that bobs and spins until the courier walks into it. The courier's
// pickParcel() counts it, shows it on the robot's back and sends parcel_picked.
import { Behaviour } from "factoria";

export default class Parcel extends Behaviour {
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
    other.behaviour.pickParcel(this.entity.id);
    this.entity.destroy();
  }
}
