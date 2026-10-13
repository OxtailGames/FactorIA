// @ts-check
// Free-fly camera driven by the move_* actions, moving along world axes relative to the camera yaw.
import { Behaviour, input, math } from "factoria";

export default class FlyCamera extends Behaviour {
  /** Meters per second. */
  speed = 6;

  onUpdate(dt) {
    const yaw = math.degToRad(this.entity.transform.rotation.y);
    const forward = input.axis("move_back", "move_forward");
    const strafe = input.axis("move_left", "move_right");
    const lift = input.axis("move_down", "move_up");
    const p = this.entity.position;
    // Camera looks along -Z rotated by yaw around +Y.
    p.x += (strafe * Math.cos(yaw) - forward * Math.sin(yaw)) * this.speed * dt;
    p.z += (-strafe * Math.sin(yaw) - forward * Math.cos(yaw)) * this.speed * dt;
    p.y += lift * this.speed * dt;
  }
}
