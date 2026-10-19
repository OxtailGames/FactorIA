// @ts-check
// Spikes: a trigger that kills what is tagged "player". `cause` is what the player_died event reports.
import { Behaviour } from "factoria";

export default class Hazard extends Behaviour {
  cause = "spikes";

  onTriggerEnter(other) {
    if (other.hasTag("player")) other.send("die", this.cause);
  }
}
