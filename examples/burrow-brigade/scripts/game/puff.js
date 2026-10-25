// @ts-check
// A speck of dust or ore that flies out of a dug tile, falls a little, shrinks and goes away. Spawned by miner.js.
import { Behaviour } from "factoria";

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
