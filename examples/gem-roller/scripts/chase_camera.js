// @ts-check
// Smooth chase camera that orbits the target with cam_left / cam_right (Q / E).
import { Behaviour, input, math } from "factoria";

export default class ChaseCamera extends Behaviour {
  target = "ball";
  distance = 9;
  height = 5;
  /** Position smoothing (higher is snappier). */
  smoothing = 5;
  /** Orbit speed in degrees per second. */
  orbitSpeed = 90;
  /** Current yaw in degrees (0 = camera behind the target looking toward -Z). */
  yaw = 0;

  onStart() {
    this.t = this.world.find(this.target);
    if (this.t) this.snap();
  }

  desired() {
    const y = math.degToRad(this.yaw);
    const p = this.t.position;
    return [p.x + Math.sin(y) * this.distance, p.y + this.height, p.z + Math.cos(y) * this.distance];
  }

  snap() {
    const d = this.desired();
    const p = this.entity.position;
    p.x = d[0]; p.y = d[1]; p.z = d[2];
    this.aim();
  }

  aim() {
    const r = this.entity.transform.rotation;
    r.y = this.yaw;
    r.x = -math.radToDeg(Math.atan2(this.height - 0.5, this.distance));
  }

  onLateUpdate(dt) {
    if (!this.t) return;
    this.yaw += input.axis("cam_left", "cam_right") * this.orbitSpeed * dt;
    const d = this.desired();
    const p = this.entity.position;
    p.x = math.damp(p.x, d[0], this.smoothing, dt);
    p.y = math.damp(p.y, d[1], this.smoothing, dt);
    p.z = math.damp(p.z, d[2], this.smoothing, dt);
    this.aim();
  }
}
