// @ts-check
// Spinning, bobbing collectible gem (trigger). Plays a sound and bursts particles when the ball touches it.
import { Behaviour, audio } from "factoria";

export default class Gem extends Behaviour {
  spinSpeed = 120;
  bobHeight = 0.15;

  onStart() {
    this.baseY = this.entity.position.y;
    this.t = 0;
    this.taken = false;
  }

  onUpdate(dt) {
    this.t += dt;
    this.entity.transform.rotation.y += this.spinSpeed * dt;
    this.entity.position.y = this.baseY + Math.sin(this.t * 3) * this.bobHeight;
  }

  onTriggerEnter(other) {
    if (this.taken || !other.hasTag("player")) return;
    this.taken = true;
    const p = this.entity.worldPosition;
    audio.play("assets/sfx/gem.wav", { volume: 0.8 });
    const fx = this.world.spawn({
      name: "GemBurst",
      tags: ["fx"],
      components: {
        Transform: { position: [p.x, p.y, p.z] },
        ParticleEmitter: {
          is3D: true, emitting: true, burst: 40, rate: 0, lifetime: 0.8, speed: 4, spread: 180,
          gravity: [0, -6, 0], startSize: 0.3, endSize: 0.05,
          startColor: [0.4, 0.95, 1, 1], endColor: [1, 1, 1, 0],
        },
      },
    });
    this.world.emit("gem_collected", { id: this.entity.id });
    this.entity.destroy();
    // The game manager removes the burst once it has faded (this behaviour dies with the gem).
    this.world.emit("fx_cleanup", { id: fx.id });
  }
}
