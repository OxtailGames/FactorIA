// @ts-check
// The keep's great lantern: touching it ends the level.
import { Behaviour, world } from "factoria";

export default class Exit extends Behaviour {
  onTriggerEnter(other) {
    if (other.hasTag("player")) world.find("level")?.behaviour?.complete();
  }
}
