// A bare platformer character, for the pause tests: run with move_left/move_right, jump with jump. The first jump
// unlocks an achievement and every jump counts in a stat (factoria.json "platform"; docs/PLATFORM.md).
import { Behaviour, input, platform } from "factoria";

export default class Player extends Behaviour {
  onUpdate() {
    const body = this.entity.get("RigidBody2D");
    body.velocity.x = input.axis("move_left", "move_right") * 300;
    if (input.pressed("jump") && this.entity.isGrounded()) {
      body.velocity.y = 620;
      this.countJump();
    }
  }

  countJump() {
    if (!platform.has("achievements")) return; // a run without a store (the exported game before a store plugin)
    // Achievements are best effort: a store that is offline must not break the game, so failures are ignored.
    platform.achievements.unlock("first_jump").catch(() => {}); // unlocking twice is harmless
    platform.stats.add("jumps", 1).catch(() => {});
  }
}
