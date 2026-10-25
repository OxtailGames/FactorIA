// @ts-check
// A trapped mole: sits in a sealed pocket until a miner digs in and comes close, then it is rescued (counted in the run,
// announced on the events bus) and scurries off. Spawned by shift.js from `mine.moles`.
import { Behaviour, world, audio } from "factoria";
import * as events from "./events.js";
import * as players from "./players.js";
import { run } from "./run_state.js";
import { spriteRegion, SPRITE } from "./tiles.js";

/** How close (world units) a miner has to be to free a mole. */
export const RESCUE_RADIUS = 20;

export default class Mole extends Behaviour {
  /** Tile of the mole. */
  tx = 0;
  ty = 0;

  onStart() {
    this.freed = false;
    this.age = 0;
    this.entity.set("Sprite", { region: spriteRegion(SPRITE.MOLE_TRAPPED) });
  }

  onUpdate(dt) {
    if (this.freed) {
      this.age += dt;
      const p = this.entity.position;
      p.y += 26 * dt; // hops up, then fades
      this.entity.get("Sprite").color.a = Math.max(0, 1 - this.age / 1.2);
      if (this.age >= 1.2) this.entity.destroy();
      return;
    }
    if (!run.inShift) return;
    const me = this.entity.position;
    for (const m of world.findByTag("miner")) {
      const owner = players.get(m.behaviour ? m.behaviour.playerId : -1);
      if (!owner || owner.state === "down") continue;
      const p = m.position;
      if (Math.hypot(p.x - me.x, p.y - me.y) <= RESCUE_RADIUS) {
        this.rescue(owner.id);
        return;
      }
    }
  }

  rescue(by) {
    this.freed = true;
    this.age = 0;
    this.entity.set("Sprite", { region: spriteRegion(SPRITE.MOLE_FREE) });
    run.molesRescued += 1;
    events.emit("moleRescued", { tx: this.tx, ty: this.ty, by, rescued: run.molesRescued, total: run.molesTotal });
    audio.play("assets/audio/rescue.wav", { volume: 0.8, bus: "sfx" });
  }
}
