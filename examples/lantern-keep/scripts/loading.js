// @ts-check
// scenes/loading.scene.json: scene loads are synchronous, so "Loading..." only has to be drawn once before
// scene.load. It waits two frames, then loads the scene the main menu put in session.nextScene.
import { Behaviour, scene, session } from "factoria";

export default class Loading extends Behaviour {
  frames = 0;

  onUpdate() {
    if (++this.frames === 2) scene.load(session.nextScene);
  }
}
