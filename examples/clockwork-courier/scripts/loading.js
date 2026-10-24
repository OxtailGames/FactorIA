// @ts-check
// scenes/loading.scene.json. The next level is read ahead with scene.preload (a few files every frame), so the bar shows
// the real share of the level's files that is read and the scene keeps running (and drawing) the whole time. When the
// last file is in, the scene.load that follows reads nothing from the disk. `progress` (0..1) is what the bar and the
// tests read.
//
// The level comes from session.nextScene (set by the main menu and by the results panel's "Next level"). Without one (the
// scene opened by itself, as ui.check_layout and the editor do) the screen goes back to the level select.
import { Behaviour, scene, session, world, input, i18n } from "factoria";
import * as levels from "./levels.js";

export default class Loading extends Behaviour {
  /** Bar entity id; its width goes from 0 to `barWidth`. */
  bar = "loading_bar";
  /** Level name text entity id. */
  title = "loading_level";
  /** Width of a full bar, design pixels. */
  barWidth = 480;

  onStart() {
    this.progress = 0;
    this.loaded = false;
    this.job = null;
    if (!session.nextScene) {
      this.gone = true;
      scene.load("scenes/level_select.scene.json");
      return;
    }
    const lvl = levels.byScene(session.nextScene);
    const t = world.find(this.title);
    if (t && lvl) t.get("Text").text = i18n.t(lvl.nameKey);
    this.show();
    // Android Back while the level loads: ignored, so it cannot close the app in the middle of the load.
    this.offBack = input.onBack(() => true);
    this.job = scene.preload(session.nextScene);
    // A level that could not be read ahead still loads (scene.load reports what is wrong with it).
    const go = () => {
      if (this.gone) return;  // the scene was left while the files were being read
      this.loaded = true;
      scene.load(session.nextScene);
    };
    this.job.promise.then(go, (e) => {
      if (this.gone) return;
      console.warn(`loading: ${e.message}`);
      go();
    });
  }

  onDestroy() {
    this.gone = true;
    if (!this.loaded) this.job?.release();  // left early: give the files back
    this.offBack?.();
  }

  show() {
    const b = world.find(this.bar);
    if (b) b.get("Shape2D").size = [Math.max(1, this.barWidth * this.progress), 16];
  }

  onUpdate() {
    if (!this.job || this.progress === this.job.progress) return;
    this.progress = this.job.progress;
    this.show();
  }
}
