// @ts-check
// Trailer director (store/trailer/). make_trailer.py copies a level scene into store/trailer/scenes/shot_N.scene.json and
// adds an entity with this script, the caption texts and a black cover. The script drives the camera (pitch and distance
// only: the courier steers relative to the camera's yaw, and the recorded input must still work), fades the captions and
// the cover by the clock, and loads the next shot at `endFrame` (frames counted from the shot's own start; the input replay that
// is recorded with the trailer is indexed by frames of the whole run).
import { Behaviour, scene, world } from "factoria";

/** 0..1 ramp of `t` between `a` and `b`. */
function ramp(t, a, b) {
  return Math.min(1, Math.max(0, (t - a) / (b - a)));
}

/** Linear value of keyframes [[seconds, value], ...] at `t`. */
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
  /** Frame of this shot at which the next shot is loaded (0 = this is the last shot). */
  endFrame = 0;
  /** Scene loaded at endFrame. */
  next = "";
  /** Camera keyframes [seconds, pitch in degrees]. */
  pitchKeys = [];
  /** Camera keyframes [seconds, distance in metres]. */
  distanceKeys = [];
  /** Captions: {id, t0, t1} seconds in which the Text entity `id` is visible (0.4 s fades). */
  cards = [];
  /** Seconds of fade from black at the start, and the shot frame at which the fade to black begins (0 = none). */
  fadeIn = 0.5;
  fadeOutFrame = 0;
  fadeOutSeconds = 0.6;

  onStart() {
    /** Frames of this shot so far (time.frame restarts with every scene load). */
    this.n = 0;
  }

  onUpdate() {
    this.n++;
    const t = this.n / 60;
    const cam = world.find("camera")?.behaviour;
    if (cam) {
      const p = keys(this.pitchKeys, t);
      const d = keys(this.distanceKeys, t);
      if (p !== null) cam.pitch = p;
      if (d !== null) cam.distance = d;
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
      if (this.fadeOutFrame) a = Math.max(a, ramp(this.n - this.fadeOutFrame, 0, this.fadeOutSeconds * 60));
      cover.color = [0, 0, 0, a];
    }
    if (this.endFrame && this.n >= this.endFrame) {
      this.endFrame = 0;
      scene.load(this.next);
    }
  }
}
