// @ts-check
// scenes/loading.scene.json: loads the scene the main menu put in session.nextScene in the background
// (scene.load with { async: true }): the engine reads and decodes its files off the main thread while this scene keeps
// running (and drawing), and switches to it at the end of the frame its files are ready.
// A full recipe with a bar: set the width of a Shape2D from `job.progress` in onUpdate, like the text below.
import { Behaviour, i18n, scene, session } from "factoria";

export default class Loading extends Behaviour {
  onStart() {
    this.job = scene.load(session.nextScene, null, { async: true });
    this.job.promise.catch(() => {
      // This scene was left first (a test that moved on), or another load replaced this one: nothing to do now.
      if (this.gone || this.job.cancelled) return;
      // The scene could not be loaded in the background (not valid JSON, say): the sync scene.load reports what is wrong.
      scene.load(session.nextScene);
    });
  }

  onDestroy() {
    this.gone = true;
    if (!this.job.done) this.job.cancel(); // left before the next scene was ready: stop reading it
  }

  onUpdate() {
    // No key on the Text: the line is built here, so the percentage sits inside the translated sentence.
    this.entity.get("Text").text = i18n.t("loading.progress", { percent: Math.round(this.job.progress * 100) });
  }
}
