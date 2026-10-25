// @ts-check
// Camera that follows the miners: the middle of the active miners, eased, zooming out as they drift apart (up to MAX_ORTHO in
// camera_views.js), and kept inside the mine so the view never shows the void outside it (a mine smaller than the view is
// centred). Put it on the Camera entity. It writes the plan (shared or split views) into `camera_views.current` every frame; the
// engine draws one camera only, so when the plan is split this camera shows the view of the cluster with the most miners (see
// camera_views.js for why, and for where a real split goes).
import { Behaviour, world } from "factoria";
import { live } from "./mine_map.js";
import { TILE } from "./tiles.js";
import * as players from "./players.js";
import { ViewPlanner, BASE_ORTHO, ASPECT, current } from "./camera_views.js";

export default class FollowCamera extends Behaviour {
  /** Half the visible height in world units when the miners are together: 144 shows 18 tiles top to bottom (5 screen pixels per world unit). */
  orthoSize = BASE_ORTHO;
  /** How fast the camera catches up (per second). */
  catchUp = 8;
  /** How fast the zoom follows (per second). */
  zoomSpeed = 3;

  onStart() {
    this.entity.set("Camera", { projection: "orthographic", orthoSize: this.orthoSize });
    this.snap = true;
    this.ortho = this.orthoSize;
    this.planner = new ViewPlanner();
    current.mode = "shared";
    current.views = [];
  }

  onDestroy() {
    current.mode = "shared";
    current.views = [];
  }

  /** The miners the plan is made for: the active ones, else the ones on the lift. */
  points() {
    /** @type {Record<string, import("./camera_views.js").Point[]>} */
    const by = { active: [], lift: [] };
    for (const m of world.findByTag("miner")) {
      const owner = players.get(m.behaviour ? m.behaviour.playerId : -1);
      if (!owner || owner.state === "down") continue;
      by[owner.state].push({ id: owner.id, x: m.position.x, y: m.position.y });
    }
    return by.active.length ? by.active : by.lift;
  }

  /** Where the camera wants to be and how far out: the view of the biggest cluster. */
  focus() {
    const pts = this.points();
    if (pts.length === 0) return null;
    const plan = this.planner.plan(pts);
    current.mode = plan.mode;
    current.views = plan.views;
    const main = plan.views.reduce((a, b) => (b.players.length > a.players.length ? b : a));
    return { x: main.center.x, y: main.center.y, ortho: main.ortho };
  }

  onLateUpdate(dt) {
    const f = this.focus();
    if (!f) return;
    const k = this.snap ? 1 : 1 - Math.exp(-this.catchUp * dt);
    const kz = this.snap ? 1 : 1 - Math.exp(-this.zoomSpeed * dt);
    this.snap = false;
    this.ortho += (f.ortho - this.ortho) * kz;
    this.entity.set("Camera", { orthoSize: this.ortho });
    const mine = live.mine;
    if (mine) {
      const halfH = this.ortho, halfW = this.ortho * ASPECT;
      const w = mine.width * TILE, h = mine.height * TILE;
      f.x = w <= halfW * 2 ? w / 2 : Math.max(halfW, Math.min(w - halfW, f.x));
      f.y = h <= halfH * 2 ? -h / 2 : Math.max(-h + halfH, Math.min(-halfH, f.y));
    }
    const p = this.entity.position;
    p.x += (f.x - p.x) * k;
    p.y += (f.y - p.y) * k;
  }
}
