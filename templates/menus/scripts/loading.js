// @ts-check
// scenes/loading.scene.json: reads the scene the main menu put in session.nextScene ahead of time, a few files every
// frame, so this scene keeps running (and drawing) meanwhile; then loads it, which reads nothing from the disk.
// A full recipe with a bar: set the width of a Shape2D from `job.progress` in onUpdate, like the text below.
import { Behaviour, i18n, scene, session } from "factoria";

export default class Loading extends Behaviour {
  onStart() {
    this.job = scene.preload(session.nextScene);
    // A scene that could not be read ahead still loads: scene.load reports what is wrong with it.
    const go = () => {
      if (this.gone) return; // this scene was left first (a test that moved on): the Promise must not load a scene now
      this.loading = true;
      scene.load(session.nextScene);
    };
    this.job.promise.then(go, go);
  }

  onDestroy() {
    this.gone = true;
    if (!this.loading) this.job.release(); // left before the files were in: give them back
  }

  onUpdate() {
    // No key on the Text: the line is built here, so the percentage sits inside the translated sentence.
    this.entity.get("Text").text = i18n.t("loading.progress", { percent: Math.round(this.job.progress * 100) });
  }
}
