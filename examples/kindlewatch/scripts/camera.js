// @ts-check
// The follow camera: a fixed tilted angle (it never turns, so "up" on the stick is always away from the screen bottom),
// smoothed, with a short shake when the warden is hit or the alpha howls. Put it on the camera entity.
import { Behaviour, world, rng } from "factoria";

export default class FollowCamera extends Behaviour {
  /** Entity id followed. */
  targetId = "warden";
  /** Offset from the target, metres: up and toward the screen bottom. */
  offset = [0, 15, 10];
  /** Tilt in degrees (looking down; matches the offset so the target is centred). */
  pitch = -56;
  /** How fast it catches up, per second (1 = one second to close the gap by 63%). */
  follow = 5;
  /** The camera never leaves the clearing by more than this, so the forest wall behind the fog stays out of view. */
  limit = 17;

  onStart() {
    this.shakeTime = 0;
    this.shakeSize = 0;
    this.target = world.find(this.targetId);
    this.entity.get("Transform").rotation = [this.pitch, 0, 0];
    if (this.target) this.entity.position = this.wanted();
    this.off = world.on("camera_shake", (d) => this.shake(d?.size ?? 0.3, d?.time ?? 0.3));
  }

  onDestroy() {
    this.off?.();
  }

  /** Where the camera wants to be. */
  wanted() {
    const p = this.target.position;
    const x = Math.max(-this.limit, Math.min(this.limit, p.x));
    const z = Math.max(-this.limit, Math.min(this.limit, p.z));
    return [x + this.offset[0], this.offset[1], z + this.offset[2]];
  }

  /** A shake of `size` metres that fades out over `time` seconds. */
  shake(size, time) {
    this.shakeSize = Math.max(this.shakeSize, size);
    this.shakeTime = Math.max(this.shakeTime, time);
    this.shakeTotal = Math.max(time, 0.01);
  }

  onLateUpdate(dt) {
    if (!this.target || !this.target.alive) return;
    const want = this.wanted();
    const p = this.entity.position;
    const k = 1 - Math.exp(-this.follow * dt);
    let x = p.x + (want[0] - p.x) * k;
    let y = want[1];
    let z = p.z + (want[2] - p.z) * k;
    if (this.shakeTime > 0) {
      this.shakeTime -= dt;
      const f = Math.max(0, this.shakeTime / this.shakeTotal) * this.shakeSize;
      x += rng.range(-f, f);
      y += rng.range(-f, f);
    } else this.shakeSize = 0;
    this.entity.position = [x, y, z];
  }
}
