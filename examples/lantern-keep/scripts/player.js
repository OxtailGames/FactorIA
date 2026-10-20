// @ts-check
// The lantern bearer: run with move_left / move_right, jump with jump. Dying (spikes, enemies, falling) is level.js's
// die(); this script only forwards to it, so every death goes through one function.
import { Behaviour, input, audio } from "factoria";

export default class Player extends Behaviour {
  /** Horizontal speed in pixels per second. */
  speed = 300;
  /** Initial upward speed of a jump in pixels per second (gravity is scene settings.gravity2D). */
  jumpSpeed = 620;
  /** Distance of the lantern from the body, in front of the direction the player faces. */
  lanternOffset = 16;

  onStart() {
    this.body = this.entity.get("RigidBody2D");
    this.lantern = this.entity.children.find((c) => c.name === "Lantern") ?? null;
    this.facing = 1;
  }

  onUpdate() {
    const dir = input.axis("move_left", "move_right");
    const grounded = this.entity.isGrounded();
    // On a moving platform the velocity is relative to it: the engine carries the player.
    this.body.velocity.x = dir * this.speed;
    if (dir !== 0 && Math.sign(dir) !== this.facing) {
      this.facing = Math.sign(dir);
      if (this.lantern) this.lantern.position.x = this.facing * this.lanternOffset;
    }
    if (input.pressed("jump") && grounded) {
      this.body.velocity.y = this.jumpSpeed;
      audio.play("assets/sfx/jump.wav", { volume: 0.6 });
      this.world.emit("player_jumped", { level: this.levelId() });
    }
  }

  levelId() {
    return this.world.find("level")?.behaviour?.levelId ?? "";
  }

  /** Called by spikes, enemies and the kill plane. */
  die(cause) {
    this.world.find("level")?.behaviour?.die(cause);
  }
}
