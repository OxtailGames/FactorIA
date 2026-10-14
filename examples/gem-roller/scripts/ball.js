// @ts-check
// The player's ball: camera-relative rolling, jumping, checkpoints and respawn after a fall.
// Physics does the rest: RigidBody3D.rollWithMotion spins the mesh, and a kinematic platform carries the ball
// standing on it, so `velocity` here is always relative to the ground the ball rests on.
import { Behaviour, input, math, audio, physics } from "factoria";

export default class Ball extends Behaviour {
  cameraId = "camera";
  /** Top horizontal speed in m/s. */
  maxSpeed = 8;
  /** Acceleration toward the wanted velocity in m/s^2. */
  accel = 30;
  jumpSpeed = 8;
  /** Falling below this height counts as a fall. */
  killY = -10;
  radius = 0.5;
  enabledInput = true;

  onStart() {
    this.body = this.entity.get("RigidBody3D");
    this.cam = this.world.find(this.cameraId);
    const p = this.entity.position;
    this.checkpoint = [p.x, p.y, p.z];
    this.falls = 0;
  }

  setCheckpoint(pos, id) {
    if (this.checkpointId === id) return;
    this.checkpointId = id;
    this.checkpoint = [pos[0], pos[1] + 1.5, pos[2]];
    this.world.emit("checkpoint", { id });
  }

  /** Ray straight down from the ball center, skipping the ball's own collider. Returns the hit or null. */
  ground() {
    return physics.raycast3d(this.entity.worldPosition, [0, -1, 0], this.radius + 0.15, { ignore: this.entity });
  }

  onFixedUpdate(dt) {
    const p = this.entity.position;
    if (p.y < this.killY) { this.respawn(); return; }
    const v = this.body.velocity;
    let ix = 0, iz = 0;
    if (this.enabledInput) {
      ix = input.axis("move_left", "move_right");
      iz = input.axis("move_back", "move_forward");
    }
    const yaw = this.cam ? math.degToRad(this.cam.transform.rotation.y) : 0;
    // Camera forward on the ground plane is (-sin, -cos); right is (cos, -sin).
    let wx = ix * Math.cos(yaw) - iz * Math.sin(yaw);
    let wz = -ix * Math.sin(yaw) - iz * Math.cos(yaw);
    const len = Math.hypot(wx, wz);
    if (len > 1) { wx /= len; wz /= len; }
    v.x = math.moveTowards(v.x, wx * this.maxSpeed, this.accel * dt);
    v.z = math.moveTowards(v.z, wz * this.maxSpeed, this.accel * dt);
    if (this.enabledInput && input.pressed("jump") && this.ground()) v.y = this.jumpSpeed;
  }

  respawn() {
    const c = this.checkpoint;
    const p = this.entity.position;
    p.x = c[0]; p.y = c[1]; p.z = c[2];
    const v = this.body.velocity;
    v.x = 0; v.y = 0; v.z = 0;
    this.falls++;
    audio.play("assets/sfx/fall.wav", { volume: 0.7 });
    this.world.emit("ball_fell", { falls: this.falls });
  }
}
