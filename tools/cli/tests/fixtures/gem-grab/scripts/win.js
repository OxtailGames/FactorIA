import { Behaviour, input, scene } from "factoria";

export default class Win extends Behaviour {
  onUpdate(dt) {
    if (input.pressed("action")) scene.load("scenes/main.scene.json");
  }
}
