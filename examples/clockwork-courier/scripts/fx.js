// @ts-check
// Particle effects of the game, in one place so their look can be tuned together. burst(kind, position) spawns a one-shot
// 3D emitter (it removes itself when its particles die); ambient(kind, position) spawns a continuous one a level keeps.
// Both honour the quality preset and the "reduced motion" setting (scripts/settings.js, accessibility.js): fewer particles, no ambient ones.
//
//   fx.burst("dust", [x, y, z])      landing dust under the courier's feet
//   fx.burst("sparks", [x, y, z])    a wind-up key or a checkpoint
//   fx.burst("confetti", [x, y, z])  a delivery
//   fx.ambient("steam", [x, y, z])   chimney steam;  fx.ambient("fireflies", [x, y, z])  market fireflies
import { world } from "factoria";
import * as settings from "./settings.js";
import * as accessibility from "./accessibility.js";

/** The look of every effect: ParticleEmitter fields (docs: `factoria api --md`, ParticleEmitter, is3D). */
export const PRESETS = {
  dust: { burst: 9, lifetime: 0.5, speed: 1.3, spread: 75, gravity: [0, 0.3, 0], startSize: 0.2, endSize: 0.55, startColor: [0.86, 0.8, 0.7, 0.6], endColor: [0.86, 0.8, 0.7, 0], blend: "alpha" },
  sparks: { burst: 22, lifetime: 0.7, speed: 3.4, spread: 180, gravity: [0, -7, 0], startSize: 0.14, endSize: 0, startColor: [1, 0.9, 0.35, 1], endColor: [1, 0.45, 0.1, 0], blend: "additive" },
  confetti: { burst: 34, lifetime: 1.1, speed: 4.2, spread: 60, gravity: [0, -6, 0], startSize: 0.16, endSize: 0.1, startColor: [0.4, 0.9, 0.5, 1], endColor: [1, 0.8, 0.3, 0], blend: "additive" },
  steam: { rate: 5, lifetime: 2.6, speed: 0.8, spread: 18, gravity: [0.25, 0.35, 0], startSize: 0.35, endSize: 1.5, startColor: [0.95, 0.95, 0.97, 0.4], endColor: [0.95, 0.95, 0.97, 0], blend: "alpha", maxParticles: 40 },
  fireflies: { rate: 3, lifetime: 4, speed: 0.35, spread: 180, gravity: [0, 0.05, 0], startSize: 0.12, endSize: 0.05, startColor: [1, 0.95, 0.4, 1], endColor: [0.8, 1, 0.3, 0], blend: "additive", maxParticles: 30 },
};

/** True when the player asked for less motion (the option follows the system setting until the player chooses). */
function reduced() {
  return accessibility.reducedMotion(settings.load());
}

/** How many particles a burst or an ambient emitter gets: the quality preset's share, and under a third with reduced motion. */
export function particleScale() {
  const s = settings.load();
  return (accessibility.QUALITY[s.quality]?.particles ?? 1) * (accessibility.reducedMotion(s) ? 0.3 : 1);
}

/** A one-shot burst of `kind` at `position` (world metres). Returns the emitter entity (or null when reduced and skipped). */
export function burst(kind, position) {
  const p = PRESETS[kind];
  if (!p) throw new Error(`fx.burst: unknown effect "${kind}". Known: ${Object.keys(PRESETS).join(", ")}`);
  const n = Math.max(1, Math.ceil(p.burst * particleScale()));
  return world.spawn(
    { name: `fx_${kind}`, components: { Transform: { position }, ParticleEmitter: { ...p, is3D: true, emitting: false, burst: n, autoDestroy: true } } },
    { position },
  );
}

/** A continuous emitter of `kind` at `position`, or null when effects are reduced. */
export function ambient(kind, position) {
  const p = PRESETS[kind];
  if (!p) throw new Error(`fx.ambient: unknown effect "${kind}". Known: ${Object.keys(PRESETS).join(", ")}`);
  if (reduced()) return null;
  return world.spawn({ name: `fx_${kind}`, components: { Transform: { position }, ParticleEmitter: { ...p, rate: p.rate * accessibility.qualityOf(settings.load()).particles, is3D: true, emitting: true } } }, { position });
}
