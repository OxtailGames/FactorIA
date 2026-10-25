// @ts-check
// A speck of dust or ore that flies out of a dug tile, falls a little, shrinks and goes away. Spawned by miner.js.
import { Behaviour, world } from "factoria";

/**
 * Throws `count` specks out of a world point (miner.js for a dug tile, enemy.js for a hit or a defeat).
 * @param {number} x
 * @param {number} y
 * @param {number[]} color  rgba 0..1
 * @param {{count?: number, speed?: number, spin?: number}} [opts]  `spin` turns the fan of directions (so two bursts at one place differ).
 */
export function burst(x, y, color, opts = {}) {
  const count = opts.count ?? 5, speed = opts.speed ?? 44, spin = opts.spin ?? 0;
  for (let i = 0; i < count; i++) {
    const a = ((i * 360) / count + spin) * (Math.PI / 180);
    world.spawn({
      components: {
        Transform: { position: [x, y, 0] },
        Shape2D: { shape: "rectangle", size: [3, 3], color, layer: 30 },
        Script: { path: "scripts/game/puff.js", props: { vx: Math.cos(a) * speed, vy: Math.sin(a) * speed + 12 } },
      },
    });
  }
}

export default class Puff extends Behaviour {
  /** Starting velocity in world units per second. */
  vx = 0;
  vy = 0;
  /** Seconds it lives. */
  life = 0.45;

  onStart() {
    this.age = 0;
    this.baseSize = 3;
  }

  onUpdate(dt) {
    this.age += dt;
    if (this.age >= this.life) {
      this.entity.destroy();
      return;
    }
    this.vy -= 160 * dt;
    const p = this.entity.position;
    p.x += this.vx * dt;
    p.y += this.vy * dt;
    const k = 1 - this.age / this.life;
    this.entity.set("Shape2D", { size: [this.baseSize * k + 0.5, this.baseSize * k + 0.5] });
  }
}
