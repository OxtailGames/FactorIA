// @ts-check
// Spinning, bobbing collectible gem (trigger). Plays its pickup effect (sparks, a flash and the sound) when the ball touches it.
import { Behaviour, vfx } from "factoria";

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
    // One call plays the whole pickup: the sparks, the flash of light and the sound are parts of one effect document, which
    // removes itself when its last particle has died.
    vfx.play("assets/vfx/gem_burst.vfx.json", { position: this.entity.worldPosition });
    this.world.emit("gem_collected", { id: this.entity.id });
    this.entity.destroy();
  }
}
