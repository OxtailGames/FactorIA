// @ts-check
// Patrols back and forth; turns at walls and ledges. Its art is a baked sheet (assets/crawler_sheet.png, made from
// prefabs/crawler_rig.prefab.json by assets.bake_sheet, recipe in assets.json): "crawl" while patrolling, "alert" (eyes
// wide) while the player is close.
import { Behaviour, physics, world, vec2 } from "factoria";

export default class Enemy extends Behaviour {
  speed = 60;
  dir = 1;  // start walking right (older engines flipped it on the first frame: no bodies existed yet)

  onStart() {
    this.body = this.entity.get("RigidBody2D");
    this.sprite = this.entity.get("Sprite");
    this.anim = this.entity.spriteAnimator;
    this.alert = false;
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
    this.sprite.flipX = this.dir < 0;  // the sheet faces right
    const player = world.find("player");
    const near = !!player && Math.abs(player.position.x - px) < 130 && Math.abs(player.position.y - py) < 60;
    if (near !== this.alert) {
      this.alert = near;
      this.anim.play(near ? "alert" : "crawl");
    }
  }
}
