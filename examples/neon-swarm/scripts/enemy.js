// @ts-check
// One script for all enemy kinds: chaser, shooter, splitter, mini (spawned by splitters).
import { Behaviour, world, vec2, vec3, time, rng } from "factoria";

export default class Enemy extends Behaviour {
  kind = "chaser";
  speed = 120;
  hp = 2;
  points = 100;
  radius = 16;
  fireDelay = 1.8;       // shooters only
  bulletSpeed = 280;
  contactDamage = 1;
  dead = false;

  onStart() {
    // difficulty scaling from the manager (e.behaviour is null right after spawnPrefab, so pull it here)
    const mgr = world.find("manager");
    if (mgr && mgr.behaviour && this.kind !== "mini") {
      const k = mgr.behaviour.difficulty();
      this.speed *= k;
      this.hp += Math.floor((mgr.behaviour.wave - 1) / 4);
      this.fireDelay = Math.max(0.8, this.fireDelay / k);
    }
    this.body = this.entity.get("RigidBody2D");
    this.shape = this.entity.get("Shape2D");
    const c0 = this.shape.color; this.base = [c0.r, c0.g, c0.b];
    this.cool = this.fireDelay * rng.range(0.4, 1);
    this.flash = 0;
    this.strafe = rng.chance(0.5) ? 1 : -1;
  }

  onUpdate(dt) {
    const player = world.find("player");
    if (!player || this.dead) { this.body.velocity = vec2(0, 0); return; }
    const p = this.entity.position;
    const to = vec2(player.position.x - p.x, player.position.y - p.y);
    const d = to.length();
    const dir = d > 0.001 ? to.normalized() : vec2(0, 0);
    let v = vec2(dir.x * this.speed, dir.y * this.speed);

    if (this.kind === "shooter") {
      // keep ~300px away, strafe sideways, fire at the player
      if (d < 280) v = vec2(-dir.x * this.speed, -dir.y * this.speed);
      else if (d < 340) v = vec2(-dir.y * this.speed * this.strafe, dir.x * this.speed * this.strafe);
      this.cool -= dt;
      if (this.cool <= 0) { this.cool = this.fireDelay; this.fire(dir); }
    }
    this.body.velocity = v;
    this.entity.transform.rotation.z += (this.kind === "splitter" ? 40 : 120) * dt;

    // contact damage
    if (d < this.radius + 18) player.send("hurt", this.contactDamage);

    const col = this.shape.color;
    if (this.flash > 0) {
      this.flash -= dt;
      col.r = col.g = col.b = 1;
    } else {
      col.r = this.base[0]; col.g = this.base[1]; col.b = this.base[2];
    }
  }

  fire(dir) {
    const p = this.entity.position;
    const b = world.spawnPrefab("prefabs/enemy_bullet.prefab.json", {
      position: vec3(p.x + dir.x * 24, p.y + dir.y * 24, 0),
    });
    b.get("RigidBody2D").velocity = vec2(dir.x * this.bulletSpeed, dir.y * this.bulletSpeed);
    world.emit("enemy_fired", {});
  }

  hurt(n = 1) {
    if (this.dead) return;
    this.hp -= n;
    this.flash = 0.06;
    world.emit("enemy_hit", { x: this.entity.position.x, y: this.entity.position.y });
    if (this.hp <= 0) this.die();
  }

  die() {
    this.dead = true;
    const pos = this.entity.position;
    const c = this.shape.color;
    world.emit("enemy_killed", { kind: this.kind, points: this.points, x: pos.x, y: pos.y, color: [c.r, c.g, c.b], big: this.kind === "splitter" });
    if (this.kind === "splitter") {
      for (let i = 0; i < 3; i++) {
        const a = (i * 120 + rng.range(0, 60)) * Math.PI / 180;
        world.spawnPrefab("prefabs/mini.prefab.json", { position: vec3(pos.x + Math.cos(a) * 20, pos.y + Math.sin(a) * 20, 0) });
      }
    }
    this.entity.destroy();
  }
}
