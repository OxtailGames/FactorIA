// @ts-check
// The maths of the soundscape (pure: no engine calls, so tests/sound_mix.test.js checks it without a window). The engine's
// spatial audio is linear in world distance and knows nothing about the zoom of a strategy camera, so the game works out for
// itself what is heard from where the camera is (README, "Sound, options and accessibility"; ENGINE_FEEDBACK FB-0040).
//
//   zoomGain      1 when the camera is as close as `fullZoom`, falling to 0.2 at `farZoom` and below: from high up a town is quiet
//   ambienceLevels the volume of each bed (sea, market, wind) from what the screen holds
//   sourceMix     volume and pan of one sound that comes from a place on the screen
//   VoiceBook     a cap on how many one-shots play at once: the nearest to the middle of the screen win

/** @typedef {{ fullZoom: number, farZoom: number, margin: number, seaCells: number, marketWeight: number, walkerWeight: number, houseWeight: number, busyAt: number, windFar: number, windWinter: number, ease: number, every: number }} Mix */

export const SCREEN = { width: 1280, height: 720 };

const clamp = (v, lo, hi) => (v < lo ? lo : v > hi ? hi : v);

/** 1 at `fullZoom` or closer, 0.2 at `farZoom` or farther, a straight line between. */
export function zoomGain(zoom, mix) {
  const t = clamp((zoom - mix.farZoom) / (mix.fullZoom - mix.farZoom), 0, 1);
  return 0.2 + 0.8 * t;
}

/**
 * What the screen holds, as the volume (0..1) of each bed.
 *   sea     the share of the screen that is water (0..1) and how close the camera is: a coast filling the screen is the loudest
 *   market  the "busy" weight in view (markets, houses, walkers, see Mix) against `busyAt`, louder when close
 *   wind    from high up (zoomed out) and in winter
 * @param {{ seaShare: number, busy: number, zoom: number, winter: boolean }} view @param {Mix} mix
 */
export function ambienceLevels(view, mix) {
  const near = zoomGain(view.zoom, mix);
  const sea = clamp(view.seaShare * 2.5, 0, 1) * (0.35 + 0.65 * near);
  const market = Math.pow(clamp(view.busy / mix.busyAt, 0, 1), 0.8) * near;
  const far = clamp((mix.windFar - view.zoom) / (mix.windFar - mix.farZoom), 0, 1) * 0.9;
  const wind = clamp(far + (view.winter ? mix.windWinter : 0), 0, 1);
  return { sea, market, wind };
}

/** Is a screen point inside the screen grown by `margin` pixels? */
export function onScreen(sx, sy, margin = 0) {
  return sx >= -margin && sx <= SCREEN.width + margin && sy >= -margin && sy <= SCREEN.height + margin;
}

/**
 * Volume and stereo pan of a sound that comes from the screen point (sx, sy): quieter far from the middle of the screen and
 * when zoomed out, panned left to right by where it is. A sound outside the screen (plus the margin) has volume 0.
 * @param {number} sx @param {number} sy @param {number} zoom @param {Mix} mix @returns {{ volume: number, pan: number }}
 */
export function sourceMix(sx, sy, zoom, mix) {
  if (!onScreen(sx, sy, mix.margin)) return { volume: 0, pan: 0 };
  const dx = (sx - SCREEN.width / 2) / (SCREEN.width / 2);
  const dy = (sy - SCREEN.height / 2) / (SCREEN.height / 2);
  const far = clamp(Math.hypot(dx, dy) / Math.SQRT2, 0, 1.2);
  return { volume: clamp((1 - 0.6 * far) * zoomGain(zoom, mix), 0, 1), pan: clamp(dx * 0.8, -0.8, 0.8) };
}

/**
 * A cap on the one-shots playing at once. The caller knows how long a sound lasts (the engine does not say when a voice ends),
 * so each entry has an end time. `offer` says what to do with a new sound: play it, play it instead of the weakest one, or drop it.
 */
export class VoiceBook {
  /** @param {number} cap */
  constructor(cap) {
    this.cap = cap;
    /** @type {{ voice: number, until: number, score: number }[]} */
    this.entries = [];
    /** Most voices at once so far, and how many sounds were started and dropped. */
    this.peak = 0;
    this.started = 0;
    this.dropped = 0;
  }

  /** Forget the sounds that ended by `now` (seconds). */
  prune(now) {
    this.entries = this.entries.filter((e) => e.until > now);
  }

  get count() {
    return this.entries.length;
  }

  /**
   * @param {number} now @param {number} score how much this sound matters (louder = more)
   * @returns {{ play: boolean, evict: number | null }} evict = the voice to stop first, or null
   */
  offer(now, score) {
    this.prune(now);
    if (this.entries.length < this.cap) return { play: true, evict: null };
    let weakest = this.entries[0];
    for (const e of this.entries) if (e.score < weakest.score) weakest = e;
    if (score > weakest.score * 1.25) return { play: true, evict: weakest.voice };
    this.dropped++;
    return { play: false, evict: null };
  }

  /** Record a sound that was started (after `offer` said yes; an evicted voice leaves the book). */
  add(voice, now, seconds, score, evicted = null) {
    if (evicted !== null) this.entries = this.entries.filter((e) => e.voice !== evicted);
    this.entries.push({ voice, until: now + seconds, score });
    this.started++;
    if (this.entries.length > this.peak) this.peak = this.entries.length;
  }
}
