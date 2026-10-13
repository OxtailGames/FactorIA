// @ts-check
// Game-over / win screen: press confirm to (re)start from level 1.
import { Behaviour, input, scene } from "factoria";
import { resetState } from "scripts/game_state.js";

export default class Menu extends Behaviour {
  onUpdate() {
    if (input.pressed("restart") || input.pressed("confirm")) {
      resetState();
      scene.load("scenes/level1.scene.json");
    }
  }
}
