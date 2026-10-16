// A bare platformer character, for the pause tests: run with move_left/move_right, jump with jump.
import { Behaviour, input } from "factoria";

export default class Player extends Behaviour {
  onUpdate() {
    const body = this.entity.get("RigidBody2D");
    body.velocity.x = input.axis("move_left", "move_right") * 300;
    if (input.pressed("jump") && this.entity.isGrounded()) body.velocity.y = 620;
  }
}
