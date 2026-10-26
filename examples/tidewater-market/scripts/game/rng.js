// @ts-check
// A seeded random stream whose state can be saved (pure). The engine's `rng.create(seed)` repeats from a seed but its state
// cannot be read, so a saved game could not continue the same sequence (ENGINE_FEEDBACK FB-0031); this is the same algorithm
// (mulberry32) with the 32-bit state in a field. `state` is what a save stores; `new Rng(state)` or `rng.state = n` resumes.

export class Rng {
  /** @param {number} seed any integer; it is reduced to 32 bits */
  constructor(seed) {
    this.state = seed >>> 0;
  }

  /** A float in [0, 1). One draw. */
  float() {
    this.state = (this.state + 0x6d2b79f5) >>> 0;
    let t = this.state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }

  /** An integer in [min, max], both ends included. One draw. */
  int(min, max) {
    const f = this.float();
    return max <= min ? min : min + Math.floor(f * (max - min + 1));
  }

  /** True with probability p. One draw. */
  chance(p) {
    return this.float() < p;
  }

  /** One of the items. One draw. */
  pick(items) {
    return items.length ? items[Math.floor(this.float() * items.length)] : undefined;
  }

  /**
   * One item chosen by weight: `weights[i]` is the weight of `items[i]` (0 or less = never). One draw, whatever the weights;
   * returns undefined when every weight is 0.
   * @template T @param {T[]} items @param {number[]} weights
   */
  weighted(items, weights) {
    const f = this.float();
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
  }
}

/** A stream seed from the game seed and a name, so the streams (ships, events, outcomes) do not share draws. */
export function streamSeed(seed, name) {
  let h = 0x811c9dc5 ^ (seed >>> 0);
  for (let i = 0; i < name.length; i++) h = Math.imul(h ^ name.charCodeAt(i), 0x01000193);
  return h >>> 0;
}
