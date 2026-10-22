// @ts-check
// A seesaw: a dynamic plank on a hinge (Joint3D) that tips under the courier. Characters do not press on dynamic bodies
// in this engine (a CharacterController3D is kinematic: ENGINE_FEEDBACK FB-0011), so the courier's weight is simulated
// here: while it stands on the plank, the hinge motor drives the plank so that the side it stands on goes down; when it
// steps off, the plank keeps its tilt (a real seesaw rests on whichever end is heavier). The way across is to walk up
// the raised end, over the pivot, and the plank tips under you onto the far platform.
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
  /** Distance from the pivot (metres) at which the courier's weight counts fully; closer than that it counts less. */
  fullWeightAt = 0.7;
  rest = 1;
  /** Id of the courier entity. */
  courierId = "courier";

  onStart() {
    this.joint = this.entity.get("Joint3D");
    this.body = this.entity.get("RigidBody3D");
    this.pivot = this.entity.worldPosition;
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

  onFixedUpdate() {
    if (!this.joint) return;
    // The courier pushes dynamic bodies it walks into (a CharacterController3D): that would slide the plank off its pivot.
    if (this.body) this.body.velocity = [0, 0, 0];
    const cb = this.courier ? this.courier.behaviour : null;
    if (cb && cb.grounded && cb.ground && cb.ground.id === this.entity.id) {
      const pos = this.courier.position;
      const off = (this.along === "x" ? pos.x : pos.z) - (this.along === "x" ? this.pivot.x : this.pivot.z);
      const weight = Math.min(1, Math.abs(off) / this.fullWeightAt);
      if (weight > 0.05) this.target = this.angleFor(Math.sign(off)) * (0.35 + 0.65 * weight);
    }
    const err = this.target - this.angle;
    this.joint.motorSpeed = Math.max(-this.maxSpeed, Math.min(this.maxSpeed, err * this.gain));
  }
}
