// @ts-check
// Smoothly follows the entity with id `target` horizontally; vertical position stays fixed.
import { Behaviour, math } from "factoria";

export default class FollowCamera extends Behaviour {
  /** Id of the entity to follow. */
  target = "player";
  /** Higher = snappier. */
  smoothing = 8;

  onLateUpdate(dt) {
    const t = this.world.find(this.target);
    if (!t) return;
    const p = this.entity.position;
    p.x = math.damp(p.x, t.position.x, this.smoothing, dt);
  }
}
