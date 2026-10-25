// @ts-check
// The music of the mine, in one place: every stratum has a looping track (STRATA[n].music in generator.js), and the shift
// asks for the one of its stratum. Loading a scene stops the audio (docs/AI_GUIDE.md, "loading a scene stops the audio"), so
// EVERY shift starts its track again, fading it in; the track is the same from floor to floor of a stratum and changes when the
// run goes down to the next stratum. P6 adds layers (a fight layer, a danger layer) here, so nothing else calls
// `audio.music` directly.
//
//   play(stratum)   starts the stratum's track (call it when a scene starts); returns true when the track differs from the last one
//   current()       the path of the track started last, or "" before the first
//   forStratum(n)   the path for a stratum number
//   reset()         forgets what played (startRun calls it)
import { audio } from "factoria";
import { stratumInfo } from "./generator.js";

/** Volume of the track on the "music" bus (the options menu scales the bus). */
export const VOLUME = 0.8;
/** Seconds the track fades in. */
export const FADE = 1.5;

let playing = "";

/** Path of the track of a stratum. */
export function forStratum(stratum) {
  return stratumInfo(stratum).music;
}

/** The track started last ("" when none). */
export function current() {
  return playing;
}

/**
 * Starts the track of a stratum (a scene load stopped whatever played before, so it always starts). Returns true when the
 * track is a different one from the track of the last call (the stratum changed), false when it is the same one again.
 * @param {number} stratum
 */
export function play(stratum) {
  const path = forStratum(stratum);
  const changed = path !== playing;
  playing = path;
  audio.music(path, { volume: VOLUME, fade: FADE });
  return changed;
}

/** Forgets the current track (the next `play` starts it again). */
export function reset() {
  playing = "";
}
