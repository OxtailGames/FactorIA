// @ts-check
// Platformer hero: run, variable-height jump with coyote time + jump buffering,
// stomp enemies, collect coins (particle burst + sound), lose a life on side contact.
//
// The hero is built in parts (prefabs/player.prefab.json): child Sprites on a rig, an Animator that plays the
// idle / walk / jump clips of anim/ through a state machine, and two IK2D legs. This script only feeds the animation:
// the state machine parameters, the mirror when it turns, and the ground under each foot (feet()).
import { Behaviour, input, audio, scene, world, physics, vec2 } from "factoria";
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
  /** Height of an ankle above the sole, and where the ankle sits (from the hero's centre) with the sole on the floor. */
  static ankle = 2.5;
  static ankleRest = -20.5;

  onStart() {
    this.body = this.entity.get("RigidBody2D");
    this.tint = this.entity.get("Tint");  // blinks the whole character while it is invulnerable
    this.anim = this.entity.animator;
    this.rig = this.part("rig");
    // Each leg: `goal` is a marker the clips move (where the foot would go), `target` is what the IK2D of the leg reaches.
    this.legs = ["f", "b"].map((s) => ({ goal: this.part("gait_" + s), target: this.part("ik_" + s) }));
    this.footsteps = 0;
    this.anim.on("footstep", () => { this.footsteps += 1; });
    this.coyote = 0;
    this.buffer = 0;
    this.invuln = 0;
    this.dead = false;
    this.spawn = vec2(this.entity.position.x, this.entity.position.y);
  }

  /** A descendant of the character by name (the parts have no ids of their own in the scene). */
  part(name) {
    const find = (e) => {
      for (const c of e.children) {
        if (c.name === name) return c;
        const d = find(c);
        if (d) return d;
      }
      return null;
    };
    const e = find(this.entity);
    if (!e) throw new Error(`Player has no part named '${name}'; see prefabs/player.prefab.json`);
    return e;
  }

  /** Animation inputs and feet, once per fixed step: the Animator and the IK2D solve right after it. */
  onFixedUpdate(dt) {
    if (this.dead) return;
    const grounded = this.entity.isGrounded();
    const speed = Math.abs(this.body.velocity.x);
    this.anim.set("speed", speed);
    this.anim.set("grounded", grounded);
    this.anim.speed = this.anim.state === "walk" ? Math.min(1.5, Math.max(0.6, speed / 200)) : 1;
    this.feet(grounded);
  }

  /**
   * Puts each IK target on the ground under its marker. The walk clip moves the markers (a stride along x, a lift while
   * the foot swings); a ray from the hero's centre finds the floor under the marker, so on a step or a ledge the planted
   * foot rests on the floor instead of floating or sinking. In the air the marker alone decides (the legs tuck).
   */
  feet(grounded) {
    const at = this.entity.position;
    for (const leg of this.legs) {
      const m = leg.goal.worldPosition;
      let y = m.y;
      if (grounded) {
        const hit = physics.raycast(vec2(m.x, at.y), vec2(m.x, at.y - 60), { ignore: this.entity });
        // ankleRest: where the marker sits with the sole on the floor; anything above it is the lift of a step
        if (hit) y = hit.point.y + Player.ankle + Math.max(0, m.y - (at.y + Player.ankleRest));
      }
      leg.target.worldPosition = vec2(m.x, y);
    }
  }

  onUpdate(dt) {
    if (this.dead) return;
    const v = this.body.velocity;
    const dir = input.axis("move_left", "move_right");
    // accelerate toward target speed (snappy but not instant)
    const target = dir * this.speed;
    const a = this.accel * dt;
    v.x = v.x < target ? Math.min(target, v.x + a) : Math.max(target, v.x - a);
    if (dir !== 0) this.rig.transform.scale.x = dir < 0 ? -1 : 1;  // mirrors every part (the IK keeps the knees forward)

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
      this.tint.color.a = Math.floor(this.invuln * 12) % 2 === 0 ? 0.35 : 1;
      if (this.invuln <= 0) this.tint.color.a = 1;
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
