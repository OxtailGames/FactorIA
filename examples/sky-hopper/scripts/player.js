// @ts-check
// Platformer hero: run, variable-height jump with coyote time + jump buffering,
// stomp enemies, collect coins (particle burst + sound), lose a life on side contact.
import { Behaviour, input, audio, scene, world, vec2 } from "factoria";
import { state } from "scripts/game_state.js";

export default class Player extends Behaviour {
  speed = 280;
  accel = 2400;
  jumpSpeed = 640;
  coyoteTime = 0.1;
  jumpBuffer = 0.12;
  stompBounce = 420;
  invulnTime = 1.5;
  /** Falling below this y costs a life (set by scenes/level.js). */
  killY = -200;

  onStart() {
    this.body = this.entity.get("RigidBody2D");
    this.sprite = this.entity.get("Sprite");
    this.coyote = 0;
    this.buffer = 0;
    this.invuln = 0;
    this.dead = false;
    this.spawn = vec2(this.entity.position.x, this.entity.position.y);
  }

  onUpdate(dt) {
    if (this.dead) return;
    const v = this.body.velocity;
    const dir = input.axis("move_left", "move_right");
    // accelerate toward target speed (snappy but not instant)
    const target = dir * this.speed;
    const a = this.accel * dt;
    v.x = v.x < target ? Math.min(target, v.x + a) : Math.max(target, v.x - a);
    if (dir !== 0) this.sprite.flipX = dir < 0;

    const grounded = this.entity.isGrounded();
    this.coyote = grounded ? this.coyoteTime : this.coyote - dt;
    this.buffer = input.pressed("jump") ? this.jumpBuffer : this.buffer - dt;
    if (this.buffer > 0 && this.coyote > 0) {
      v.y = this.jumpSpeed;
      this.buffer = 0;
      this.coyote = 0;
      audio.play("assets/sfx/jump.wav", { volume: 0.6 });
    }
    // variable jump height: releasing early cuts the jump
    if (input.released("jump") && v.y > 160) v.y = 160;

    if (this.invuln > 0) {
      this.invuln -= dt;
      this.sprite.color.a = Math.floor(this.invuln * 12) % 2 === 0 ? 0.35 : 1;
      if (this.invuln <= 0) this.sprite.color.a = 1;
    }
    if (this.entity.position.y < this.killY) this.hurt(true);
  }

  onTriggerEnter(other) {
    if (this.dead) return;
    if (other.hasTag("coin")) this.collect(other);
  }

  collect(coin) {
    const p = coin.position;
    coin.destroy();
    state.coins += 1;
    state.totalCoins += 1;
    audio.play("assets/sfx/coin.wav", { volume: 0.6 });
    this.burst(p.x, p.y, [1, 0.85, 0.2, 1], 14);
    world.emit("coin_collected", { by: this.entity.id });
  }

  burst(x, y, col, n) {
    const fx = world.spawn({
      name: "Burst",
      tags: ["fx"],
      components: {
        Transform: { position: [x, y, 0] },
        ParticleEmitter: {
          emitting: true, rate: 0, burst: n, lifetime: 0.5, speed: 220, spread: 180,
          startSize: 12, endSize: 2, startColor: col, endColor: [col[0], col[1], col[2], 0], layer: 60,
        },
      },
    });
    this.after(1, () => fx.alive && fx.destroy());
  }

  onCollisionEnter(other, info) {
    if (this.dead || !other.hasTag("enemy")) return;
    const feet = this.entity.position.y - 23;
    const top = other.position.y + 8;
    if (feet >= top && this.body.velocity.y <= 80) {
      this.burst(other.position.x, other.position.y, [0.7, 0.3, 0.8, 1], 12);
      other.destroy();
      this.body.velocity.y = input.down("jump") ? this.stompBounce * 1.4 : this.stompBounce;
      audio.play("assets/sfx/stomp.wav", { volume: 0.7 });
      world.emit("enemy_stomped", {});
    } else if (this.invuln <= 0) {
      this.hurt(false);
    }
  }

  hurt(fell) {
    if (this.dead) return;
    state.lives -= 1;
    audio.play("assets/sfx/hurt.wav", { volume: 0.7 });
    world.emit("player_hurt", { lives: state.lives });
    if (state.lives <= 0) {
      this.dead = true;
      this.body.velocity.x = 0;
      this.after(0.6, () => scene.load("scenes/gameover.scene.json"));
      return;
    }
    // respawn at level start
    this.entity.position.x = this.spawn.x;
    this.entity.position.y = this.spawn.y;
    this.body.velocity.x = 0;
    this.body.velocity.y = 0;
    this.invuln = this.invulnTime;
  }
}
