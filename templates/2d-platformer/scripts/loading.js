// @ts-check
// scenes/loading.scene.json: shows "Loading" while the next scene loads. Scene loads are synchronous, so the screen
// only needs to be drawn once before scene.load: it waits two frames, then loads session.nextScene.
import { Behaviour, scene, session } from "factoria";

export default class Loading extends Behaviour {
  /** Loaded when nothing set session.nextScene (e.g. the loading scene started on its own). */
  fallback = "scenes/main.scene.json";
  frames = 0;

  onUpdate() {
    if (++this.frames === 2) scene.load(session.nextScene || this.fallback);
  }
}
