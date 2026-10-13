// @ts-check
// Per-level bookkeeping: tells the player where it spawns and where "out of bounds" is.
import { Behaviour } from "factoria";
import { state } from "scripts/game_state.js";

export default class Level extends Behaviour {
  levelIndex = 1;
  killY = -200;
  spawnX = 0;
  spawnY = 0;

  onStart() {
    state.level = this.levelIndex;
    const p = this.world.find("player");
    if (p && p.behaviour) p.behaviour.killY = this.killY;
  }
}
