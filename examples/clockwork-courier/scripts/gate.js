// @ts-check
// A hinged gate: a dynamic RigidBody3D with a Joint3D hinge to the world (prefabs/gate.prefab.json). The hinge motor
// swings it open or shut and the hinge limits stop it, so the courier cannot push it open and a crate cannot push it
// shut. open(), close() and toggle() are called by scripts/lever.js; `closeAfter` makes it shut again by itself.
//
// The Joint3D of the entity must have useLimits and useMotor on; this script sets the limits from `openAngle` and
// `direction` and drives `motorSpeed`.
import { Behaviour, audio } from "factoria";

export default class Gate extends Behaviour {
  /** How far it opens, degrees. */
  openAngle = 100;
  /** +1 opens towards positive hinge angles, -1 the other way (which side the door swings to). */
  direction = 1;
  /** Opening and closing speed, degrees per second. */
  speed = 160;
  /** Seconds after which an open gate closes again by itself; 0 = stays open. */
  closeAfter = 0;
  /** Starts open. */
  startOpen = false;

  onStart() {
    this.joint = this.entity.get("Joint3D");
    this.isOpen = false;
    this.timer = 0;
    if (this.joint) {
      this.joint.useLimits = true;
      this.joint.lowerLimit = this.direction > 0 ? 0 : -this.openAngle;
      this.joint.upperLimit = this.direction > 0 ? this.openAngle : 0;
      this.joint.useMotor = true;
      this.joint.motorSpeed = -this.direction * this.speed;
    }
    if (this.startOpen) this.open(true);
  }

  /** Current hinge angle in degrees, 0 = shut. */
  get angle() {
    return this.joint ? this.joint.angle : 0;
  }

  open(silent = false) {
    if (this.isOpen) return;
    this.isOpen = true;
    this.timer = this.closeAfter;
    if (this.joint) this.joint.motorSpeed = this.direction * this.speed;
    if (!silent) audio.play("assets/audio/impactPlank_medium_000.ogg", { bus: "sfx", volume: 0.7, pitch: 0.8 });
  }

  close() {
    if (!this.isOpen) return;
    this.isOpen = false;
    if (this.joint) this.joint.motorSpeed = -this.direction * this.speed;
    audio.play("assets/audio/impactPlank_medium_002.ogg", { bus: "sfx", volume: 0.7, pitch: 0.8 });
  }

  toggle() {
    if (this.isOpen) this.close();
    else this.open();
  }

  onFixedUpdate(dt) {
    if (this.isOpen && this.closeAfter > 0) {
      this.timer -= dt;
      if (this.timer <= 0) this.close();
    }
  }
}
