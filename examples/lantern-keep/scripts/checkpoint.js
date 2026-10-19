// @ts-check
// A lantern post: touching it makes it the place a death sends the player back to. level.js numbers them from the left.
import { Behaviour, world } from "factoria";

export default class Checkpoint extends Behaviour {
  /** Set by level.js (0 = the leftmost checkpoint of the level). */
  index = 0;

  onTriggerEnter(other) {
    if (!other.hasTag("player")) return;
    if (world.find("level")?.behaviour?.reachCheckpoint(this.entity)) {
      const flame = this.entity.children.find((c) => c.name === "Flame");
      if (flame) Object.assign(flame.get("Shape2D"), { filled: true, color: [1, 0.75, 0.25, 1] }); // lit = solid, not lit = hollow ring: no colour needed
    }
  }
}
