// A deterministic waypoint bot for tests: it plays like a person with a gamepad. It tilts the left stick towards the next
// waypoint (the stick is bound to the move_* actions in factoria.json, exactly what a player or the on-screen
// TouchStick drives) and taps the "jump" action where a waypoint says so. It never moves the courier directly.
//
//   const bot = new Autoplay(game);
//   const r = bot.run([{ x: -8, z: 14 }, { x: 0, z: -4, jump: true }, { x: 0, z: -20 }]);
//   r.reached      true when every waypoint was reached within maxFrames
//   r.frames       frames it took
//
// A waypoint is { x, z, radius?, jump?, act?, wait?, walk? }: the courier counts as there when it is within `radius` metres
// (default 0.6); `jump: true` taps jump the moment it arrives, `act: true` taps the action button (a lever), `wait: n` then
// stands still for n frames (a gate swinging open), `hold: { id, pos: [x, y, z], radius }` stands still until that entity (a
// moving platform) is there, `walk: true` holds the walk action (slow) on the way to it.
// Coordinates are world metres on the ground plane.
const DEG = Math.PI / 180;

export class Autoplay {
  /** @param {any} game the "factoria:test" game */
  constructor(game, options = {}) {
    this.game = game;
    this.courierId = options.courierId ?? "courier";
    this.cameraId = options.cameraId ?? "camera";
    this.maxFrames = options.maxFrames ?? 3000;
    this.pad = game.gamepad(0);
    this.frames = 0;
  }

  get courier() {
    return this.game.find(this.courierId);
  }

  /** Tilts the stick so that the courier heads for (x, z) given the camera's yaw. */
  steer(x, z, walk = false) {
    const p = this.courier.position;
    let dx = x - p.x;
    let dz = z - p.z;
    const len = Math.hypot(dx, dz) || 1;
    dx /= len;
    dz /= len;
    const cam = this.game.find(this.cameraId);
    const yaw = (cam && cam.behaviour && cam.behaviour.yaw ? cam.behaviour.yaw : 0) * DEG;
    const s = Math.sin(yaw);
    const c = Math.cos(yaw);
    // Inverse of the courier's camera-relative mapping: stick (ix, iz) -> world (ix c - iz s, -ix s - iz c).
    const ix = dx * c - dz * s;
    const iz = -dx * s - dz * c;
    this.pad.axis("LeftX", ix);
    this.pad.axis("LeftY", iz);
    if (walk) this.game.press("walk");
    else this.game.release("walk");
  }

  /** Lets go of everything the bot holds. */
  stop() {
    this.pad.axis("LeftX", 0);
    this.pad.axis("LeftY", 0);
    this.game.release("walk");
  }

  /** Stands still until entity `hold.id` is within `hold.radius` metres of `hold.pos` [x, y, z] (a moving platform arriving),
   *  at most `hold.max` frames (default 1500). */
  holdUntil(hold) {
    const e = this.game.find(hold.id);
    for (let i = 0; i < (hold.max ?? 1500); i++) {
      const p = e.position;
      if (Math.hypot(p.x - hold.pos[0], p.y - hold.pos[1], p.z - hold.pos[2]) <= (hold.radius ?? 0.25)) return true;
      this.stop();
      this.game.step(1);
      this.frames++;
    }
    return false;
  }

  /** Walks to one point. Returns true when it got there. `until` is an optional () => boolean that stops the walk early. */
  goTo(wp, until) {
    const radius = wp.radius ?? 0.6;
    for (let i = 0; i < this.maxFrames; i++) {
      const p = this.courier.position;
      if (Math.hypot(wp.x - p.x, wp.z - p.z) <= radius) {
        if (wp.jump) this.game.tap("jump");
        if (wp.act) this.game.tap("action");
        if (wp.hold) this.holdUntil(wp.hold);
        if (wp.wait) {
          this.stop();
          this.game.step(wp.wait);
          this.frames += wp.wait;
        }
        return true;
      }
      if (until && until()) return false;
      this.steer(wp.x, wp.z, !!wp.walk);
      this.game.step(1);
      this.frames++;
    }
    return false;
  }

  /** Follows the waypoints in order. */
  run(waypoints, until) {
    let reached = true;
    let failedAt = -1;
    for (let i = 0; i < waypoints.length; i++) {
      if (!this.goTo(waypoints[i], until)) {
        reached = false;
        failedAt = i;
        break;
      }
    }
    this.stop();
    const p = this.courier.position;
    // `failedAt` and `at` say where a route got stuck: the index of the waypoint and where the courier stood.
    return { reached, frames: this.frames, failedAt, at: [p.x, p.y, p.z].map((n) => Math.round(n * 100) / 100) };
  }
}

/** The route through scenes/test_yard.scene.json: parcel on the wooden walkway, over the hurdle, through the covered
 *  passage, to the delivery door. */
export const YARD_ROUTE = [
  { x: -8, z: 13, radius: 0.5 },
  { x: -8, z: 1.5, radius: 0.5 },
  { x: 0, z: -2, radius: 0.5 },
  { x: 0, z: -4.05, radius: 0.15, jump: true },
  { x: 0, z: -8, radius: 0.5 },
  { x: 0, z: -19.8, radius: 0.7 }, // the door trigger starts at z = -19.3; the courier is locked once it hands the parcel in
];
