// @ts-check
// Twin-stick player: WASD move, mouse aim, Space / left click shoots.
import { Behaviour, input, world, audio, time, math, vec2, vec3 } from "factoria";

export default class Player extends Behaviour {
  speed = 320;
  fireDelay = 0.13;     // seconds between shots
  maxHp = 5;
  invulnTime = 1.2;     // seconds of invulnerability after a hit
  boundsX = 575;
  boundsY = 275;
  hp = 5;
  invuln = 0;
  cooldown = 0;
  shots = 0;

  onStart() {
    this.hp = this.maxHp;
    this.shape = this.entity.get("Shape2D");
  }

  onUpdate(dt) {
    if (this.hp <= 0) return;
    const dir = input.vector("move_left", "move_right", "move_down", "move_up");
    const p = this.entity.position;
    p.x = math.clamp(p.x + dir.x * this.speed * dt, -this.boundsX, this.boundsX);
    p.y = math.clamp(p.y + dir.y * this.speed * dt, -this.boundsY, this.boundsY);

    // aim at the mouse (the Shape2D triangle points up, so subtract 90 degrees)
    const m = input.mouse.world;
    const aim = vec2(m.x - p.x, m.y - p.y);
    if (aim.length() > 1) {
      this.aim = aim.normalized();
      this.entity.transform.rotation.z = this.aim.angle() - 90;
    }
    if (!this.aim) this.aim = vec2(1, 0);

    this.cooldown -= dt;
    if (input.down("action") && this.cooldown <= 0) this.shoot();

    if (this.invuln > 0) {
      this.invuln -= dt;
      this.shape.color.a = Math.floor(time.elapsed * 14) % 2 === 0 ? 0.25 : 1;
    } else {
      this.shape.color.a = 1;
    }
  }

  shoot() {
    this.cooldown = this.fireDelay;
    this.shots++;
    const p = this.entity.position;
    const b = world.spawnPrefab("prefabs/bullet.prefab.json", {
      position: vec3(p.x + this.aim.x * 34, p.y + this.aim.y * 34, 0),   // the nose: apex is 2/3 of 50 px from the centroid pivot
    });
    const speed = 900;
    b.get("RigidBody2D").velocity = vec2(this.aim.x * speed, this.aim.y * speed);
    audio.play("assets/sfx/shoot.wav", { volume: 0.35, pitch: 0.9 + 0.2 * Math.random() });
  }

  /** Called by enemies / enemy bullets. Returns true if damage was applied. */
  hurt(n = 1) {
    if (this.invuln > 0 || this.hp <= 0) return false;
    this.hp -= n;
    this.invuln = this.invulnTime;
    world.emit("player_hit", { hp: this.hp });
    return true;
  }
}
