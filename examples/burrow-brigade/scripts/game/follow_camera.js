// @ts-check
// Camera that follows the miners: the middle of the active miners, eased, zooming out as they drift apart (up to MAX_ORTHO in
// camera_views.js), and kept inside the mine so the view never shows the void outside it (a mine smaller than the view is
// centred). Put it on the Camera entity. It writes the plan (shared or split views) into `camera_views.current` every frame.
//
// Without the split screen option (Options > Video, settings.splitScreenOn) the one camera shows the view of the cluster with the
// most miners (a leash in camera_views.js keeps the miners close enough that this is everyone). With it, a split plan is drawn: this
// entity is the first view and one extra Camera entity ("Split Camera 2" and so on, made here, destroyed when the miners are
// together again) is each of the others, every one with its own `viewport`, so each player part sees their own corner of the mine.
// The HUD is screen space, so it is drawn once over the whole screen after the views.
import { Behaviour, world } from "factoria";
import { live } from "./mine_map.js";
import { TILE } from "./tiles.js";
import * as players from "./players.js";
import { splitScreenOn } from "../settings.js";
import { ViewPlanner, BASE_ORTHO, ASPECT, current, gapped } from "./camera_views.js";

/**
 * The state of one drawn view: where its camera is and how far out.
 * @typedef {{entity: any, x: number, y: number, ortho: number}} Slot
 */

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
    this.planner = new ViewPlanner();
    /** @type {Slot[]} Slot 0 is this entity; the others are the split cameras, in view order. */
    this.slots = [{ entity: this.entity, x: this.entity.position.x, y: this.entity.position.y, ortho: this.orthoSize }];
    current.mode = "shared";
    current.views = [];
  }

  onDestroy() {
    this.dropExtras(0);
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

  /** The plan for the miners now (published in `current`), or null when nobody is in play. */
  plan() {
    const pts = this.points();
    if (pts.length === 0) return null;
    const plan = this.planner.plan(pts);
    current.mode = plan.mode;
    current.views = plan.views;
    return plan;
  }

  /** The views that go on screen: all of a split plan when the player chose the split screen, else the one of the biggest cluster. */
  drawn(plan) {
    if (plan.mode === "split" && splitScreenOn()) return plan.views;
    return [plan.views.reduce((a, b) => (b.players.length > a.players.length ? b : a))];
  }

  /** Destroys the split cameras from slot `keep` on (slot 0 is this entity and stays). */
  dropExtras(keep) {
    if (!this.slots) return; // onStart did not run (the scene was left at once)
    const from = Math.max(keep, 1);
    for (const slot of this.slots.slice(from)) if (slot.entity.alive) slot.entity.destroy();
    if (this.slots.length > from) this.slots.length = from;
  }

  /** The slot of view `i`: slot 0 is this entity, the others are Camera entities made on demand (they snap to their first position). */
  slotFor(i, view) {
    while (this.slots.length <= i) {
      const n = this.slots.length;
      const main = this.entity.get("Camera");
      const entity = world.spawn({
        name: `Split Camera ${n + 1}`,
        components: {
          Transform: { position: [view.center.x, view.center.y, this.entity.position.z] },
          Camera: { projection: "orthographic", orthoSize: view.ortho, clearColor: Array.from(main.clearColor), primary: true, depth: n, viewport: gapped(view.viewport) },
        },
      });
      this.slots.push({ entity, x: view.center.x, y: view.center.y, ortho: view.ortho });
    }
    return this.slots[i];
  }

  onLateUpdate(dt) {
    const plan = this.plan();
    if (!plan) return;
    const views = this.drawn(plan);
    this.dropExtras(views.length);
    const k = this.snap ? 1 : 1 - Math.exp(-this.catchUp * dt);
    const kz = this.snap ? 1 : 1 - Math.exp(-this.zoomSpeed * dt);
    this.snap = false;
    const mine = live.mine;
    views.forEach((view, i) => {
      const slot = this.slotFor(i, view);
      slot.ortho += (view.ortho - slot.ortho) * kz;
      let { x, y } = view.center;
      if (mine) {
        const halfH = slot.ortho, halfW = slot.ortho * (views.length === 1 ? ASPECT : view.aspect);
        const w = mine.width * TILE, h = mine.height * TILE;
        x = w <= halfW * 2 ? w / 2 : Math.max(halfW, Math.min(w - halfW, x));
        y = h <= halfH * 2 ? -h / 2 : Math.max(-h + halfH, Math.min(-halfH, y));
      }
      slot.x += (x - slot.x) * k;
      slot.y += (y - slot.y) * k;
      const camera = { orthoSize: slot.ortho, viewport: views.length === 1 ? [0, 0, 1, 1] : gapped(view.viewport) };
      slot.entity.set("Camera", camera);
      if (i === 0) {
        const p = this.entity.position;
        p.x = slot.x;
        p.y = slot.y;
      } else {
        slot.entity.position = [slot.x, slot.y, this.entity.position.z];
      }
    });
  }
}
