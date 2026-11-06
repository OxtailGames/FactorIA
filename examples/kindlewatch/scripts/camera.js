// @ts-check
// The follow camera: a fixed tilted angle (it never turns, so "up" on the stick is always away from the screen bottom),
// smoothed. The shake when the warden is hit or the alpha howls is the engine's (camera.shake, docs/GAME_FEEL.md): it moves
// only what is drawn, so this script never sees it. Put it on the camera entity.
import { Behaviour, world } from "factoria";

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
    this.target = world.find(this.targetId);
    this.entity.get("Transform").rotation = [this.pitch, 0, 0];
    if (this.target) this.entity.position = this.wanted();
  }

  /** Where the camera wants to be. */
  wanted() {
    const p = this.target.position;
    const x = Math.max(-this.limit, Math.min(this.limit, p.x));
    const z = Math.max(-this.limit, Math.min(this.limit, p.z));
    return [x + this.offset[0], this.offset[1], z + this.offset[2]];
  }

  onLateUpdate(dt) {
    if (!this.target || !this.target.alive) return;
    const want = this.wanted();
    const p = this.entity.position;
    const k = 1 - Math.exp(-this.follow * dt);
    this.entity.position = [p.x + (want[0] - p.x) * k, want[1], p.z + (want[2] - p.z) * k];
  }
}
