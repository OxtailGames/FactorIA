// @ts-check
// scenes/loading.scene.json: reads the scene the main menu put in session.nextScene ahead of time, a few files every
// frame, so this scene keeps running (and drawing) meanwhile; then loads it, which reads nothing from the disk.
// A full recipe with a bar: set the width of a Shape2D from `job.progress` in onUpdate, like the text below.
import { Behaviour, scene, session } from "factoria";

export default class Loading extends Behaviour {
  onStart() {
    this.job = scene.preload(session.nextScene);
    // A scene that could not be read ahead still loads: scene.load reports what is wrong with it.
    const go = () => scene.load(session.nextScene);
    this.job.promise.then(go, go);
  }

  onUpdate() {
    this.entity.get("Text").text = `Loading... ${Math.round(this.job.progress * 100)}%`;
  }
}
