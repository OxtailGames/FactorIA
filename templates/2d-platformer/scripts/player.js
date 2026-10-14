// @ts-check
// Platformer character: run with move_left/move_right, jump with the jump action, collect coins.
// Plays assets/sfx/jump.wav and coin.wav (tests check them with game.audioLog()).
import { Behaviour, input, audio } from "factoria";

export default class Player extends Behaviour {
  /** Horizontal speed in pixels per second. */
  speed = 300;
  /** Initial upward speed of a jump in pixels per second (gravity is scene settings.gravity2D). */
  jumpSpeed = 620;

  onStart() {
    this.body = this.entity.get("RigidBody2D");
  }

  onUpdate(dt) {
    this.body.velocity.x = input.axis("move_left", "move_right") * this.speed;
    if (input.pressed("jump") && this.entity.isGrounded()) {
      this.body.velocity.y = this.jumpSpeed;
      audio.play("assets/sfx/jump.wav", { volume: 0.6 });
    }
  }

  onTriggerEnter(other) {
    if (other.hasTag("coin")) {
      other.destroy();
      audio.play("assets/sfx/coin.wav", { volume: 0.6 });
      this.world.emit("coin_collected", { by: this.entity.id });
    }
  }
}
