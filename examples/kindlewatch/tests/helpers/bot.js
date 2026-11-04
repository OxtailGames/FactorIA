// A deterministic bot for the tests: it plays like a person with a gamepad. It tilts the left stick toward a point (the
// move_* actions are bound to the stick in factoria.json, exactly what the on-screen TouchStick drives) and taps the
// attack action. It never moves the warden or touches a wolf directly.
export class Bot {
  /** @param {any} game the "factoria:test" game */
  constructor(game) {
    this.game = game;
    this.pad = game.gamepad(0);
  }

  get warden() {
    return this.game.find("warden");
  }

  /** Tilts the stick toward (x, z); the screen's "up" is -Z. */
  steer(x, z) {
    const p = this.warden.position;
    const dx = x - p.x;
    const dz = z - p.z;
    const len = Math.hypot(dx, dz) || 1;
    this.pad.axis("LeftX", dx / len);
    this.pad.axis("LeftY", -dz / len);
  }

  stop() {
    this.pad.axis("LeftX", 0);
    this.pad.axis("LeftY", 0);
  }

  /** Walks to (x, z) within `radius` metres; returns the frames it took, or -1 when it did not arrive. */
  walkTo(x, z, radius = 0.8, maxFrames = 900) {
    for (let f = 0; f < maxFrames; f++) {
      const p = this.warden.position;
      if (Math.hypot(p.x - x, p.z - z) <= radius) {
        this.stop();
        return f;
      }
      this.steer(x, z);
      this.game.step(1);
    }
    this.stop();
    return -1;
  }

  /** Taps the attack action (the swing). */
  swing() {
    this.game.press("attack");
    this.game.step(1);
    this.game.release("attack");
  }
}
