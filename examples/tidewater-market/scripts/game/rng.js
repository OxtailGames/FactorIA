// @ts-check
// Seeded random streams that a saved game can resume. The engine's `rng.create(seed)` is a mulberry32 generator whose 32-bit
// `state` can be read and set, so a stream is one: `state` is what a save stores; `stream(state)` or `gen.state = n` resumes.
// This file adds only what the engine has not: `weighted`, and `streamSeed` to derive one seed per named stream.
// (It used to hold its own mulberry32 because the state could not be read, ENGINE_FEEDBACK FB-0032; the algorithm is the
// same, so the states of old saves still resume the same streams.)
import { rng } from "factoria";

/** @typedef {ReturnType<typeof rng.create> & { weighted: <T>(items: T[], weights: number[]) => T | undefined }} Stream */

/**
 * A new stream: the engine's generator from `seed` (any integer, reduced to 32 bits) with `weighted`.
 * @param {number} seed
 * @returns {Stream}
 */
export function stream(seed) {
  const gen = rng.create(seed);
  return Object.assign(gen, {
    /**
     * One item chosen by weight: `weights[i]` is the weight of `items[i]` (0 or less = never). One draw, whatever the weights;
     * returns undefined when every weight is 0.
     * @template T @param {T[]} items @param {number[]} weights
     * @returns {T | undefined}
     */
    weighted(items, weights) {
      const f = gen.float();
      let total = 0;
      for (const w of weights) total += Math.max(0, w);
      if (total <= 0) return undefined;
      let at = f * total;
      for (let i = 0; i < items.length; i++) {
        const w = Math.max(0, weights[i]);
        if (at < w) return items[i];
        at -= w;
      }
      return items[items.length - 1];
    },
  });
}

/** A stream seed from the game seed and a name, so the streams (ships, events, outcomes) do not share draws. */
export function streamSeed(seed, name) {
  let h = 0x811c9dc5 ^ (seed >>> 0);
  for (let i = 0; i < name.length; i++) h = Math.imul(h ^ name.charCodeAt(i), 0x01000193);
  return h >>> 0;
}
