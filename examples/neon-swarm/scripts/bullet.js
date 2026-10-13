// @ts-check
// Projectile (player or enemy). Dies on walls, enemies / the player, or after its lifetime.
import { Behaviour } from "factoria";

export default class Bullet extends Behaviour {
  friendly = true;
  damage = 1;
  life = 1.6;

  onStart() {
    this.after(this.life, () => this.entity.destroy());
  }

  onTriggerEnter(other) {
    if (!this.entity.alive) return;
    if (other.hasTag("wall")) {
      this.entity.destroy();
    } else if (this.friendly && other.hasTag("enemy")) {
      other.send("hurt", this.damage);
      this.entity.destroy();
    } else if (!this.friendly && other.hasTag("player")) {
      other.send("hurt", this.damage);
      this.entity.destroy();
    }
  }
}
