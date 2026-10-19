// @ts-check
// A gloom that patrols: walks until it meets a wall or the end of its ledge, then turns round (guide 9.14). It kills
// the player on touch; nothing hurts it, the player goes over it.
import { Behaviour, physics, vec2 } from "factoria";

export default class Enemy extends Behaviour {
  speed = 70;
  /** -1 walks left first, 1 right. */
  dir = -1;
  /** Half the width and height of the body, for the ledge probe. */
  halfW = 20;
  halfH = 15;
  ticks = 0;

  onFixedUpdate() {
    const body = this.entity.get("RigidBody2D");
    if (!body) return;
    if (this.ticks < 2) {
      // Bodies are created by the first physics step: probing before that finds nothing and would turn it round.
      this.ticks += 1;
      body.velocity.x = this.dir * this.speed;
      return;
    }
    if (this.entity.isTouching([this.dir, 0])) this.dir = -this.dir;
    const p = this.entity.position;
    const ahead = vec2(p.x + this.dir * (this.halfW + 4), p.y - this.halfH + 2);
    if (!physics.raycast(ahead, vec2(ahead.x, ahead.y - 10), { ignore: this.entity })) this.dir = -this.dir;
    body.velocity.x = this.dir * this.speed;
    this.entity.get("Sprite").flipX = this.dir > 0;
  }

  onCollisionEnter(other) {
    if (other.hasTag("player")) other.send("die", "enemy");
  }
}
