// @ts-check
import { Behaviour, audio, scene } from "factoria";
import { state } from "scripts/game_state.js";

export default class Goal extends Behaviour {
  next = "scenes/win.scene.json";
  done = false;

  onTriggerEnter(other) {
    if (this.done || !other.hasTag("player")) return;
    this.done = true;
    audio.play("assets/sfx/win.wav", { volume: 0.7 });
    state.level += 1;
    this.after(0.7, () => scene.load(this.next));
  }
}
