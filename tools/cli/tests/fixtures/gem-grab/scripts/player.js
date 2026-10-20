import { Behaviour, input } from "factoria";

export default class Player extends Behaviour {
  /** Speed in pixels per second. */
  speed = 300;

  onStart() {
    this.body = this.entity.get("RigidBody2D");
  }

  onUpdate(dt) {
    // vector() gives (x, y) from -1 to 1: A/D or the arrows left and right, W/S or up and down.
    const move = input.vector("move_left", "move_right", "move_down", "move_up");
    this.body.velocity.x = move.x * this.speed;
    this.body.velocity.y = move.y * this.speed;
  }

  onTriggerEnter(other) {
    if (other.hasTag("gem")) {
      other.destroy();
      this.world.emit("gem_collected", {});
    }
  }
}
