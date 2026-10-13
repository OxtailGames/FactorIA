// @ts-check
// Moves the entity with the move_* input actions (declared in factoria.json).
import { Behaviour, input } from "factoria";

export default class Player extends Behaviour {
  /** World units (pixels) per second. Override in the scene via Script.props. */
  speed = 300;

  onUpdate(dt) {
    const dir = input.vector("move_left", "move_right", "move_down", "move_up");
    const p = this.entity.position; // live view: writes go straight into the Transform
    p.x += dir.x * this.speed * dt;
    p.y += dir.y * this.speed * dt;
  }
}
