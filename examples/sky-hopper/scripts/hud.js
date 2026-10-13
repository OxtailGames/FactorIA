// @ts-check
import { Behaviour } from "factoria";
import { state } from "scripts/game_state.js";

export default class Hud extends Behaviour {
  onUpdate() {
    this.entity.get("Text").text = `Level ${state.level}    Coins ${state.coins}    Lives ${"♥".repeat(0)}${state.lives}`;
  }
}
