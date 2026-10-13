// @ts-check
// Patrols back and forth; turns at walls and ledges.
import { Behaviour, physics, vec2 } from "factoria";

export default class Enemy extends Behaviour {
  speed = 60;
  dir = -1;

  onStart() {
    this.body = this.entity.get("RigidBody2D");
    this.sprite = this.entity.get("Sprite");
  }

  onFixedUpdate(dt) {
    const p = this.entity.position;
    const px = p.x, py = p.y;
    // Rays start outside our own collider (a ray starting inside reports the owner at distance 0).
    const wall = physics.raycast(vec2(px + this.dir * 19, py), vec2(px + this.dir * 28, py));
    const ground = physics.raycast(vec2(px + this.dir * 22, py), vec2(px + this.dir * 22, py - 30));
    const blocked = wall && wall.entity && wall.entity.hasTag("player") === false && wall.entity.hasTag("coin") === false;
    if (blocked || !ground) this.dir = -this.dir;
    this.body.velocity.x = this.dir * this.speed;
    this.sprite.flipX = this.dir > 0;
  }
}
