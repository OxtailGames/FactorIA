// @ts-check
// A trapped mole: sits in a sealed pocket until a miner digs in and comes close, then it is rescued (counted in the run,
// announced on the events bus) and scurries off. Spawned by shift.js from `mine.moles`.
import { Behaviour, world } from "factoria";
import * as sound from "./sound.js";
import * as events from "./events.js";
import * as players from "./players.js";
import { run } from "./run_state.js";
import { nearestMiner } from "./actors.js";
import { spriteRegion, SPRITE } from "./tiles.js";

/** How close (world units) a miner has to be to free a mole. */
export const RESCUE_RADIUS = 20;
/** A trapped mole calls for help every this many seconds (plus up to 4 by its tile, so two moles do not call together) while a miner is within CALL_RANGE. */
export const CALL_EVERY = 7;
export const CALL_RANGE = 150;

export default class Mole extends Behaviour {
  /** Tile of the mole. */
  tx = 0;
  ty = 0;

  onStart() {
    this.freed = false;
    this.age = 0;
    this.callIn = 2 + ((this.tx * 7 + this.ty * 13) % 5); // from the tile, not rng: the call must not change the world's random stream
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
    this.callIn -= dt;
    if (this.callIn <= 0) {
      this.callIn = CALL_EVERY + ((this.tx * 7 + this.ty * 13) % 5);
      const near = nearestMiner(me.x, me.y);
      if (near && near.dist <= CALL_RANGE) sound.play("assets/audio/mole_call.wav", { volume: 0.5 }, { key: "caption.mole", x: me.x, y: me.y });
    }
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
    sound.play("assets/audio/rescue.wav", { volume: 0.8 }, { key: "caption.rescue", x: this.entity.position.x, y: this.entity.position.y });
  }
}
