// @ts-check
// Camera that follows the miners: the middle of the active miners, eased, and kept inside the mine so the view never shows
// the void outside it (a mine smaller than the view is centred). Put it on the Camera entity.
import { Behaviour, world } from "factoria";
import { live } from "./mine_map.js";
import { TILE } from "./tiles.js";
import * as players from "./players.js";

/** Width / height of the picture (the design resolution is 1280 x 720 and the game letterboxes to it). */
const ASPECT = 16 / 9;

export default class FollowCamera extends Behaviour {
  /** Half the visible height in world units: 144 shows 18 tiles top to bottom (5 screen pixels per world unit). */
  orthoSize = 144;
  /** How fast the camera catches up (per second). */
  catchUp = 8;

  onStart() {
    this.entity.set("Camera", { projection: "orthographic", orthoSize: this.orthoSize });
    this.snap = true;
  }

  /** Where the camera wants to be. */
  focus() {
    let x = 0, y = 0, n = 0;
    for (const m of world.findByTag("miner")) {
      const owner = players.get(m.behaviour ? m.behaviour.playerId : -1);
      if (!owner || owner.state === "down") continue;
      x += m.position.x;
      y += m.position.y;
      n++;
    }
    if (n === 0) return null;
    return { x: x / n, y: y / n };
  }

  onLateUpdate(dt) {
    const f = this.focus();
    if (!f) return;
    const mine = live.mine;
    if (mine) {
      const halfH = this.orthoSize, halfW = this.orthoSize * ASPECT;
      const w = mine.width * TILE, h = mine.height * TILE;
      f.x = w <= halfW * 2 ? w / 2 : Math.max(halfW, Math.min(w - halfW, f.x));
      f.y = h <= halfH * 2 ? -h / 2 : Math.max(-h + halfH, Math.min(-halfH, f.y));
    }
    const p = this.entity.position;
    const k = this.snap ? 1 : 1 - Math.exp(-this.catchUp * dt);
    this.snap = false;
    p.x += (f.x - p.x) * k;
    p.y += (f.y - p.y) * k;
  }
}
