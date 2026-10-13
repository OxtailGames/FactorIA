// @ts-check
// Moves the entity with the move_* input actions (declared in factoria.json).
import { Behaviour, input, vec2 } from "factoria";

export default class Player extends Behaviour {
  /** World units (pixels) per second. Override in the scene via Script.props. */
  speed = 300;

  onUpdate(dt) {
    const dir = input.vector("move_left", "move_right", "move_down", "move_up");
    this.entity.position = this.entity.position.add(vec2(dir.x, dir.y).scale(this.speed * dt));
  }
}
