// @ts-check
// The camera plan for several miners. Pure functions plus a little state, so it can be tested without a scene.
//
//  1. ONE SHARED VIEW keeps every miner in sight: it centres on the group and zooms out (a bigger orthoSize) from BASE_ORTHO up
//     to MAX_ORTHO as the miners drift apart.
//  2. Past the largest view the plan SPLITS into 2 to 4 views, one per cluster of miners that still fit together, each with a
//     viewport (a rectangle of the screen, 0..1 from the top left) and the players it follows; it MERGES back once the group
//     fits a shared view again with some room to spare (MERGE_AT), so it does not flicker at the border.
//
// THE ENGINE DRAWS ONE CAMERA ONLY ("only one camera renders for now", docs: components, Camera: no viewport, no second
// camera, no render target), so a split cannot be put on screen yet. Until it can, the game keeps the group together instead:
// `limitMove` is a leash that refuses a step that would make the miners drift farther than the largest view shows (a step that
// brings them closer is always allowed), so in play the plan stays in "shared" mode. `config.tether = false` turns the leash off
// (the tests do, to see the split); `follow_camera.js` publishes the plan in `current` and, when it is split, shows the view of
// the biggest cluster. When the engine grows viewports, `follow_camera.js` is the one place that has to draw `current.views`.
import * as players from "./players.js";
import { miners } from "./actors.js";

/** Half the visible height in world units: 144 shows 18 tiles top to bottom. */
export const BASE_ORTHO = 144;
/** The most the shared view zooms out to: 1.5 times as far, 27 tiles top to bottom, 48 wide. */
export const MAX_ORTHO = 216;
/** Width / height of the picture. */
export const ASPECT = 16 / 9;
/** World units kept free between a miner and the edge of the view (the HUD and the lamp's light need room). */
export const MARGIN = 40;
/** The group must be this fraction of the largest view to merge back after a split. */
export const MERGE_AT = 0.85;

export const config = { tether: true };

/** @typedef {{id: number, x: number, y: number}} Point */
/** @typedef {{players: number[], center: {x: number, y: number}, ortho: number, viewport: [number, number, number, number]}} View */
/** @typedef {{mode: "shared" | "split", views: View[]}} Plan */

/** The largest span (x and y) a shared view shows without losing a miner at its margin. */
export function maxSpan(maxOrtho = MAX_ORTHO) {
  return { x: 2 * (maxOrtho * ASPECT - MARGIN), y: 2 * (maxOrtho - MARGIN) };
}

/** Bounding box of a list of points. */
export function bounds(points) {
  let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
  for (const p of points) {
    x0 = Math.min(x0, p.x);
    x1 = Math.max(x1, p.x);
    y0 = Math.min(y0, p.y);
    y1 = Math.max(y1, p.y);
  }
  return { x0, y0, x1, y1, w: x1 - x0, h: y1 - y0, cx: (x0 + x1) / 2, cy: (y0 + y1) / 2 };
}

/** The orthoSize that shows these points with the margin, between BASE_ORTHO and `maxOrtho`. */
export function orthoFor(points, maxOrtho = MAX_ORTHO) {
  if (points.length === 0) return BASE_ORTHO;
  const b = bounds(points);
  const need = Math.max((b.h / 2 + MARGIN), (b.w / 2 + MARGIN) / ASPECT);
  return Math.max(BASE_ORTHO, Math.min(maxOrtho, need));
}

function fits(points, scale = 1, maxOrtho = MAX_ORTHO) {
  if (points.length <= 1) return true;
  const b = bounds(points), span = maxSpan(maxOrtho);
  return b.w <= span.x * scale && b.h <= span.y * scale;
}

/** Groups the points into the fewest clusters that each fit a view: the two closest clusters that still fit are merged first. */
export function clusters(points, maxOrtho = MAX_ORTHO) {
  /** @type {Point[][]} */
  let groups = points.map((p) => [p]);
  for (;;) {
    let best = null, bestD = Infinity;
    for (let i = 0; i < groups.length; i++) {
      for (let j = i + 1; j < groups.length; j++) {
        const union = [...groups[i], ...groups[j]];
        if (!fits(union, 1, maxOrtho)) continue;
        const b = bounds(union);
        const d = Math.hypot(b.w, b.h);
        if (d < bestD) {
          bestD = d;
          best = [i, j];
        }
      }
    }
    if (!best) return groups;
    const [i, j] = best;
    groups = groups.filter((_, k) => k !== i && k !== j).concat([[...groups[i], ...groups[j]]]);
    groups.sort((a, b) => Math.min(...a.map((p) => p.id)) - Math.min(...b.map((p) => p.id)));
  }
}

/** The screen rectangles [x, y, w, h] (0..1, top-left origin) of 1 to 4 views; the groups are ordered left to right, then top to bottom. */
export function viewports(n, wide) {
  if (n <= 1) return [[0, 0, 1, 1]];
  if (n === 2) return wide ? [[0, 0, 0.5, 1], [0.5, 0, 0.5, 1]] : [[0, 0, 1, 0.5], [0, 0.5, 1, 0.5]];
  if (n === 3) return [[0, 0, 0.5, 0.5], [0.5, 0, 0.5, 0.5], [0, 0.5, 1, 0.5]];
  return [[0, 0, 0.5, 0.5], [0.5, 0, 0.5, 0.5], [0, 0.5, 0.5, 0.5], [0.5, 0.5, 0.5, 0.5]];
}

/** Remembers whether the screen is split, for the hysteresis. */
export class ViewPlanner {
  constructor(maxOrtho = MAX_ORTHO) {
    this.maxOrtho = maxOrtho;
    /** @type {"shared" | "split"} */
    this.mode = "shared";
  }

  /**
   * @param {Point[]} points  The miners in play.
   * @returns {Plan}
   */
  plan(points) {
    const scale = this.mode === "split" ? MERGE_AT : 1;
    if (fits(points, scale, this.maxOrtho)) {
      this.mode = "shared";
      const b = points.length ? bounds(points) : { cx: 0, cy: 0 };
      return { mode: "shared", views: [{ players: points.map((p) => p.id), center: { x: b.cx, y: b.cy }, ortho: orthoFor(points, this.maxOrtho), viewport: [0, 0, 1, 1] }] };
    }
    this.mode = "split";
    const groups = clusters(points, this.maxOrtho);
    const centers = groups.map((g) => bounds(g));
    // groups side by side when they are farther apart across than down, else one above the other
    const all = bounds(centers.map((c) => ({ id: 0, x: c.cx, y: c.cy })));
    const wide = all.w >= all.h;
    const order = groups.map((g, i) => i).sort((a, b) => (wide ? centers[a].cx - centers[b].cx : centers[b].cy - centers[a].cy));
    const rects = viewports(groups.length, wide);
    return {
      mode: "split",
      views: order.map((gi, k) => ({ players: groups[gi].map((p) => p.id), center: { x: centers[gi].cx, y: centers[gi].cy }, ortho: orthoFor(groups[gi], this.maxOrtho), viewport: /** @type {[number, number, number, number]} */ (rects[k]) })),
    };
  }
}

/** The plan the camera follows right now (follow_camera.js writes it each frame). Tests and the HUD read it. */
export const current = { /** @type {"shared" | "split"} */ mode: "shared", /** @type {View[]} */ views: [] };

/** Positions of the miners that count for the view and the leash: the ones still active (not down, not parked on the lift). */
export function points() {
  return miners().filter((m) => m.player.state === "active").map((m) => ({ id: m.player.id, x: m.x, y: m.y }));
}

/**
 * The leash. A miner wants to go from `from` to `to`: on each axis the step is refused when it would spread the active miners
 * farther than the largest view shows AND the spread is not already that wide (so someone who is far away can always walk back).
 * @param {number} id
 * @param {{x: number, y: number}} from
 * @param {{x: number, y: number}} to
 * @returns {{x: number, y: number}}
 */
export function limitMove(id, from, to) {
  if (!config.tether) return to;
  const me = players.get(id);
  if (!me || me.state !== "active") return to;
  const others = points().filter((p) => p.id !== id);
  if (others.length === 0) return to;
  const span = maxSpan();
  const out = { x: to.x, y: to.y };
  for (const axis of /** @type {const} */ (["x", "y"])) {
    const lim = axis === "x" ? span.x : span.y;
    const lo = Math.min(...others.map((p) => p[axis])), hi = Math.max(...others.map((p) => p[axis]));
    const wide = (v) => Math.max(hi, v) - Math.min(lo, v);
    if (wide(to[axis]) > lim && wide(to[axis]) > wide(from[axis])) out[axis] = from[axis];
  }
  return out;
}
