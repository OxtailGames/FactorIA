// @ts-check
// Rotates the entity around the Y axis.
import { Behaviour } from "factoria";

export default class Spin extends Behaviour {
  /** Rotation speed in degrees per second. */
  degreesPerSecond = 45;

  onUpdate(dt) {
    this.entity.transform.rotation.y += this.degreesPerSecond * dt;
  }
}
