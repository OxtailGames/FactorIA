// @ts-check
// Trailer director (store/trailer/). make_store.py trailer copies a store play scene into store/trailer/scenes/shot_N.scene.json
// and adds an entity with this script, the caption texts and a black cover. The script fades the captions and the cover by the
// frame counter and loads the next shot at `endFrame` (frames counted from the shot's own start; the input replay recorded with
// the trailer is indexed by frames of the whole run, see make_store.py).
import { Behaviour, scene, world } from "factoria";

/** 0..1 ramp of `t` between `a` and `b`. */
function ramp(t, a, b) {
  return Math.min(1, Math.max(0, (t - a) / (b - a)));
}

export default class Trailer extends Behaviour {
  /** Frame of this shot at which the next shot is loaded (0 = this is the last shot). */
  endFrame = 0;
  /** Scene loaded at endFrame. */
  next = "";
  /** Captions: {id, t0, t1} seconds in which the Text entity `id` is visible (0.4 s fades). */
  cards = [];
  /** Seconds of fade from black at the start, and the shot frame at which the fade to black begins (0 = none). */
  fadeIn = 0.5;
  fadeOutFrame = 0;
  fadeOutSeconds = 0.6;

  onStart() {
    /** Frames of this shot so far. */
    this.n = 0;
    /** The scene this director belongs to: a load that finishes late must not act on the next one. */
    this.mine = scene.current;
  }

  onUpdate() {
    if (scene.current !== this.mine) return;
    this.n++;
    const t = this.n / 60;
    for (const c of this.cards) {
      const text = world.find(c.id)?.get("Text");
      if (!text) continue;
      const a = Math.min(ramp(t, c.t0, c.t0 + 0.4), 1 - ramp(t, c.t1 - 0.4, c.t1));
      text.color = [text.color[0], text.color[1], text.color[2], a];
    }
    const cover = world.find("trailer_black")?.get("Shape2D");
    if (cover) {
      let a = 1 - ramp(t, 0, this.fadeIn);
      if (this.fadeOutFrame) a = Math.max(a, ramp(this.n - this.fadeOutFrame, 0, this.fadeOutSeconds * 60));
      cover.color = [0, 0, 0, a];
    }
    if (this.endFrame && this.n >= this.endFrame) {
      this.endFrame = 0;
      scene.load(this.next);
    }
  }
}
