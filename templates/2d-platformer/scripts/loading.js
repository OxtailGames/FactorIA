// @ts-check
// scenes/loading.scene.json: shows "Loading" while the next scene loads. Scene loads are synchronous, so the screen
// only needs to be drawn once before scene.load: it waits two frames, then loads session.nextScene.
import { Behaviour, scene, session } from "factoria";

export default class Loading extends Behaviour {
  frames = 0;

  onUpdate() {
    if (++this.frames === 2) scene.load(session.nextScene || "scenes/main.scene.json");
  }
}
