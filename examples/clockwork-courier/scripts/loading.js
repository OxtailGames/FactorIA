// @ts-check
// scenes/loading.scene.json. The engine has no asynchronous scene load and no progress API (ENGINE_FEEDBACK), so
// `scene.load` blocks the frame it is called in and nothing can be drawn while it runs. The most honest bar possible:
// it counts the STEPS this script really takes, each drawn before the next starts, and ends at 100% only when the
// load call is about to be made. `progress` (0..1) is what the bar and the tests read.
//
//   step 1  show the level's name and the empty bar        step 3  last frame drawn, then scene.load
//   step 2  bar at 2/3
//
// The level comes from session.nextScene (set by the main menu and by the results panel's "Next level").
import { Behaviour, scene, session, world, input } from "factoria";
import * as levels from "./levels.js";

/** Frames shown before the blocking load (each one is one step of the bar). */
export const STEPS = 3;

export default class Loading extends Behaviour {
  /** Bar entity id; its width goes from 0 to `barWidth`. */
  bar = "loading_bar";
  /** Level name text entity id. */
  title = "loading_level";
  /** Width of a full bar, design pixels. */
  barWidth = 480;

  onStart() {
    this.step = 0;
    this.progress = 0;
    this.loaded = false;
    const lvl = levels.byScene(session.nextScene);
    const t = world.find(this.title);
    if (t && lvl) t.get("Text").text = lvl.name;
    this.show();
    // Android Back while the level loads (three frames): ignored, so it cannot close the app in the middle of the load.
    this.offBack = input.onBack(() => true);
  }

  onDestroy() {
    this.offBack?.();
  }

  show() {
    const b = world.find(this.bar);
    if (b) b.get("Shape2D").size = [Math.max(1, this.barWidth * this.progress), 16];
  }

  onUpdate() {
    if (this.loaded) return;
    this.step++;
    this.progress = Math.min(1, this.step / STEPS);
    this.show();
    if (this.step >= STEPS) {
      this.loaded = true;
      scene.load(session.nextScene);
    }
  }
}
