// @ts-check
// A seesaw: a dynamic plank on a hinge (Joint3D) that tips under the courier. The courier weighs on the plank
// (CharacterController3D.applyWeight, mass) and never shoves it, so the engine tips it by itself; this script only
// limits the tilt and, while nobody stands on it, drives the plank to `rest` with the hinge motor (a real seesaw rests on
// whichever end is heavier). The way across is to walk up the raised end, over the pivot, and the plank tips under you
// onto the far platform.
//
//   along      "x" or "z": the world axis the plank lies along (the hinge axis is the other horizontal one)
//   maxAngle   how far it tips, degrees (the Joint3D limits are set from it)
//   rest       -1, 0 or +1: which end starts down when nobody stands on it (the sign of its position along the axis)
//
// The Joint3D hinge axis must be [0,0,1] for along "x" and [1,0,0] for along "z" (prefabs/seesaw.prefab.json).
import { Behaviour, world } from "factoria";

export default class Seesaw extends Behaviour {
  along = "x";
  maxAngle = 14;
  /** Hinge motor gain: degrees/second of motor speed per degree of error. */
  gain = 8;
  /** Fastest the plank tips, degrees per second. */
  maxSpeed = 50;
  rest = 1;
  /** Id of the courier entity. */
  courierId = "courier";

  onStart() {
    this.joint = this.entity.get("Joint3D");
    this.courier = world.find(this.courierId);
    if (this.joint) {
      this.joint.useLimits = true;
      this.joint.lowerLimit = -this.maxAngle;
      this.joint.upperLimit = this.maxAngle;
      this.joint.useMotor = true;
      this.joint.maxMotorTorque = 4000;
    }
    this.target = this.angleFor(this.rest);
  }

  /** Hinge angle that puts the end on `side` (+1 or -1 along the plank) down. */
  angleFor(side) {
    // About +Z, a positive angle lifts the +x end; about +X it lowers the +z end.
    const s = this.along === "x" ? -side : side;
    return s * this.maxAngle;
  }

  /** Hinge angle now, degrees. */
  get angle() {
    return this.joint ? this.joint.angle : 0;
  }

  /** +1 / -1: the end that is down (the one with more negative height), 0 when level. */
  get downSide() {
    const a = this.angle;
    if (Math.abs(a) < 1) return 0;
    const s = a > 0 ? 1 : -1;
    return this.along === "x" ? -s : s;
  }

  onFixedUpdate(dt) {
    if (!this.joint) return;
    const cb = this.courier ? this.courier.behaviour : null;
    if (cb && cb.grounded && cb.ground && cb.ground.id === this.entity.id) {
      // The courier's weight tips the plank by itself (CharacterController3D.applyWeight): the motor lets go of it.
      this.joint.useMotor = false;
      this.alone = 0;
      const side = this.downSide;
      if (side !== 0) this.target = this.angleFor(side);
      return;
    }
    // A hop or a stumble on the plank is not leaving it: the motor waits a little before it takes the plank over.
    this.alone = (this.alone || 0) + dt;
    if (this.alone < 0.4) {
      this.joint.useMotor = false;
      return;
    }
    // Nobody on it: the motor takes the plank to the end that is down (or `rest` at the start) and holds it there.
    this.joint.useMotor = true;
    const err = this.target - this.angle;
    this.joint.motorSpeed = Math.max(-this.maxSpeed, Math.min(this.maxSpeed, err * this.gain));
  }
}
