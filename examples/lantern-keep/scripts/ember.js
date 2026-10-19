// @ts-check
// One of the three embers of a level (a trigger). `index` 0..2 is set by the map's legend.
import { Behaviour, world } from "factoria";

export default class Ember extends Behaviour {
  /** Which ember of the level this is: 0, 1 or 2. */
  index = 0;

  onTriggerEnter(other) {
    if (!other.hasTag("player")) return;
    if (world.find("level")?.behaviour?.collectEmber(this.index)) {
      world.spawnPrefab("prefabs/spark.prefab.json", { position: this.entity.position.clone() });
      this.entity.destroy();
    }
  }
}
