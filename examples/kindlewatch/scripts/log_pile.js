// @ts-check
// A pile of logs. The warden picks one up by walking next to it (while his arms are not full); the pile holds `logs`
// logs and shrinks as they go. The dawn refills it (restock). Empty piles are hidden.
import { Behaviour, world } from "factoria";
import { flatDistance } from "./common.js";

export default class LogPile extends Behaviour {
  /** Logs in the pile at the start of the night. */
  capacity = 6;
  /** Distance at which the warden takes a log, metres. */
  pickRange = 2.4;
  /** Seconds between two logs taken. */
  cooldown = 0.35;

  onStart() {
    this.logs = this.capacity;
    this.cool = 0;
    const s = this.entity.get("Transform").scale;
    this.base = { x: s.x, y: s.y, z: s.z };
    this.draw();
  }

  onFixedUpdate(dt) {
    this.cool -= dt;
    if (this.logs <= 0 || this.cool > 0) return;
    const warden = world.find("warden");
    const wb = warden?.behaviour;
    if (!wb || wb.locked || flatDistance(warden, this.entity) > this.pickRange) return;
    if (wb.addLog()) {
      this.logs--;
      this.cool = this.cooldown;
      this.draw();
    }
  }

  /** Back to full (called at dawn). */
  restock() {
    this.logs = this.capacity;
    this.draw();
  }

  /** The pile looks as big as what is left of it. */
  draw() {
    const f = this.logs <= 0 ? 0.0001 : 0.45 + 0.55 * (this.logs / this.capacity);
    this.entity.get("Transform").scale = [this.base.x * f, this.base.y * f, this.base.z * f];
  }
}
