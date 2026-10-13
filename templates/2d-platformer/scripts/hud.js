// @ts-check
// Shows the coin count. Listens to the "coin_collected" world event emitted by the player.
import { Behaviour } from "factoria";

export default class Hud extends Behaviour {
  coins = 0;

  onStart() {
    this.world.on("coin_collected", () => {
      this.coins += 1;
      this.entity.get("Text").text = `Coins: ${this.coins}`;
    });
  }
}
