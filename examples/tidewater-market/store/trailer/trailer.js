// @ts-check
// Trailer director (store/trailer/). make_trailer.py writes store/trailer/scenes/trailer.scene.json: the game scene with scene props
// that make the bot build the town in time lapse (`grow`, `timelapse`, `photo`: no interface), this script, the caption texts
// (tagged "caption", so photo mode keeps them) and a black cover. The script moves the camera (a position between the harbour
// and the middle of the town, and the zoom), fades the captions and the cover, all by the frame count, so a recording repeats.
import { Behaviour, world } from "factoria";
import { cellToWorld } from "../../scripts/game/iso.js";

/** 0..1 ramp of `t` between `a` and `b`. */
function ramp(t, a, b) {
  return Math.min(1, Math.max(0, (t - a) / (b - a)));
}

/** Smoothed value of keyframes [[seconds, value], ...] at `t`. */
function keys(list, t) {
  if (!list.length) return null;
  if (t <= list[0][0]) return list[0][1];
  for (let i = 1; i < list.length; i++) {
    if (t <= list[i][0]) {
      const [t0, v0] = list[i - 1];
      const [t1, v1] = list[i];
      const u = (t - t0) / (t1 - t0);
      const s = u * u * (3 - 2 * u);
      return v0 + (v1 - v0) * s;
    }
  }
  return list[list.length - 1][1];
}

export default class Trailer extends Behaviour {
  /** Camera keyframes [seconds, zoom]. */
  zoomKeys = [];
  /** Camera keyframes [seconds, 0..1]: 0 is where the camera starts (the harbour), 1 the middle of the buildings. */
  focusKeys = [];
  /** Captions: {id, t0, t1} seconds in which the Text entity `id` is visible (0.4 s fades). */
  cards = [];
  /** Seconds of fade from black at the start, the second at which the fade to black begins (0 = none), and its length. */
  fadeIn = 0.6;
  fadeOutAt = 0;
  fadeOutSeconds = 0.8;

  onStart() {
    /** Frames of the run so far. */
    this.n = 0;
    this.home = null;
  }

  /** The middle of the buildings in world units, or null while there are none. */
  townCentre() {
    const state = world.find("controller")?.behaviour?.state;
    if (!state) return null;
    let c = 0, r = 0, n = 0;
    for (const b of state.buildings.values()) {
      c += b.x;
      r += b.y;
      n++;
    }
    return n ? cellToWorld(c / n, r / n) : null;
  }

  onUpdate() {
    this.n++;
    const t = this.n / 60;
    const rig = world.find("camera")?.behaviour;
    if (rig && rig.view) {
      if (!this.home) this.home = [rig.view.x, rig.view.y];
      const centre = this.townCentre() || this.home;
      const u = keys(this.focusKeys, t) ?? 0;
      const zoom = keys(this.zoomKeys, t) ?? rig.view.zoom;
      rig.setView(this.home[0] + (centre[0] - this.home[0]) * u, this.home[1] + (centre[1] - this.home[1]) * u, zoom);
    }
    for (const c of this.cards) {
      const text = world.find(c.id)?.get("Text");
      if (!text) continue;
      const a = Math.min(ramp(t, c.t0, c.t0 + 0.4), 1 - ramp(t, c.t1 - 0.4, c.t1));
      text.color = [text.color[0], text.color[1], text.color[2], a];
    }
    const cover = world.find("trailer_black")?.get("Shape2D");
    if (cover) {
      let a = 1 - ramp(t, 0, this.fadeIn);
      if (this.fadeOutAt) a = Math.max(a, ramp(t, this.fadeOutAt, this.fadeOutAt + this.fadeOutSeconds));
      cover.color = [0, 0, 0, a];
    }
  }
}
