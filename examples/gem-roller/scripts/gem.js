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
    audio.play("assets/sfx/gem.wav", { volume: 0.8 });
    // One-shot sparkle: the prefab's emitter bursts on creation and destroys itself when the last particle dies.
    this.world.spawnPrefab("prefabs/gem_burst.prefab.json", { position: this.entity.worldPosition.clone() });
    this.world.emit("gem_collected", { id: this.entity.id });
    this.entity.destroy();
  }
}
