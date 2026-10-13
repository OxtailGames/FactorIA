// @ts-check
// Trigger zone: remembers the position the ball respawns at after a fall.
import { Behaviour } from "factoria";

export default class Checkpoint extends Behaviour {
  onTriggerEnter(other) {
    if (!other.hasTag("player")) return;
    const p = this.entity.worldPosition;
    other.send("setCheckpoint", [p.x, p.y, p.z], this.entity.id);
  }
}
