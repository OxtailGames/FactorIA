// @ts-check
// A checkpoint: a flag with a trigger zone. The first time the courier touches it the flag rises and lights up and
// checkpoint_reached is sent ({ checkpoint, position }); from then on a fall or a catch brings the courier back here
// (Courier listens to the event). Touching an older checkpoint after a newer one moves the respawn back to it, so the
// last one TOUCHED is the respawn.
//
// The flag is the child entity named "flag" (a model), animated here: down when idle, raised and glowing when reached.
import { Behaviour, audio } from "factoria";
import { EVENTS, emit } from "./events.js";
import * as fx from "./fx.js";

export default class Checkpoint extends Behaviour {
  /** Height above the checkpoint's origin where the courier's centre is put when it respawns, metres. */
  spawnHeight = 0.7;
  /** Emissive colour of the flag once reached. */
  glow = [1, 0.7, 0.15, 1];

  onStart() {
    this.reached = false;
    this.t = 0;
    this.flag = this.entity.children.find((c) => c.name === "flag") ?? null;
    this.flagY = this.flag ? this.flag.get("Transform").position.y : 0;
    this.setFlag(0);
  }

  /** 0 = lowered, 1 = fully raised. */
  setFlag(f) {
    if (!this.flag) return;
    const tr = this.flag.get("Transform");
    tr.position = [tr.position.x, this.flagY - 0.7 * (1 - f), tr.position.z];
  }

  onUpdate(dt) {
    this.t += dt;
    if (!this.flag) return;
    // The raise is eased over about half a second, then the flag waves a little.
    if (this.reached) {
      this.raise = Math.min(1, (this.raise ?? 0) + dt * 2.2);
      this.setFlag(this.raise);
      const tr = this.flag.get("Transform");
      tr.rotation = [0, Math.sin(this.t * 3) * 10, 0];
    }
  }

  onTriggerEnter(other) {
    if (!other.hasTag("courier")) return;
    const first = !this.reached;
    this.reached = true;
    const p = this.entity.worldPosition;
    emit(EVENTS.checkpointReached, { checkpoint: this.entity.id, position: [p.x, p.y + this.spawnHeight, p.z] });
    if (!first) return;
    if (this.flag) {
      const m = this.flag.get("MeshRenderer");
      if (m) m.emissive = this.glow;
    }
    fx.burst("sparks", [p.x, p.y + 1, p.z]);
    audio.play("assets/audio/jingles_HIT07.ogg", { bus: "sfx", volume: 0.6 });
  }
}
