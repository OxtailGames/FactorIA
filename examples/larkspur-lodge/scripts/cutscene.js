// @ts-check
// The cut-scene player. P1 ships only the CONTRACT (this file is a stub); P4 fills in the body.
//
//   import * as cutscene from "./cutscene.js";
//   const result = cutscene.play("arrival");
//
// play(id, { skippable }) -> { id, played, skipped, stub }
//   id         the cut-scene id (a file cutscenes/<id>.cutscene.json in P4: a list of timed steps - camera moves, porter walks,
//              lines of voice and subtitle, fades - played by the engine's tween and animation)
//   skippable  whether the player may skip it (default true)
//   played     whether it ran; P1: always false
//   skipped    whether the player skipped it; P1: always false
//   stub       true while the player is not written (P4 removes it)
// While a cut-scene runs, cutscene.active() is true, the porter takes no input (Porter.lock("cutscene")) and the pause menu
// still works. play() always sends EVENTS.cutsceneRequested, even in P1.
import { EVENTS, emit } from "./events.js";

/** True while a cut-scene plays (P1: never). */
export function active() {
  return false;
}

/** Plays the cut-scene `id`. P1: only sends EVENTS.cutsceneRequested and answers { played: false, stub: true }. */
export function play(id, opts = {}) {
  emit(EVENTS.cutsceneRequested, { id });
  return { id, played: false, skipped: false, skippable: opts.skippable ?? true, stub: true };
}
