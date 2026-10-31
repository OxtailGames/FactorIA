// @ts-check
// The camera plan for several miners. Pure functions plus a little state, so it can be tested without a scene.
//
//  1. ONE SHARED VIEW keeps every miner in sight: it centres on the group and zooms out (a bigger orthoSize) from BASE_ORTHO up
//     to MAX_ORTHO as the miners drift apart.
//  2. Past the largest view the plan SPLITS into 2 to 4 views, one per cluster of miners that still fit together, each with a
//     viewport (a rectangle of the screen, 0..1 from the top left, the value of Camera.viewport), the aspect that rectangle gives
//     and the players it follows; it MERGES back once the group fits a shared view again with some room to spare (MERGE_AT), so it
//     does not flicker at the border.
//
// Whether the split is drawn is the player's choice (Options > Video > "Split screen when players part", `settings.splitScreenOn()`):
//   - OFF (the default): `limitMove` is a leash that refuses a step that would make the miners drift farther than the largest view
//     shows (a step that brings them closer is always allowed), so in play the plan stays "shared" and one camera follows the group.
//   - ON: there is no leash, miners may part, and `follow_camera.js` draws `current.views` with one Camera entity per view (the
//     engine renders every primary camera into its own Camera.viewport, docs: components, Camera).
// `config.tether = false` turns the leash off whatever the option says (tests use it to see the plan split without drawing it).
import * as players from "./players.js";
import { miners } from "./actors.js";
import { splitScreenOn } from "../settings.js";

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
/** The aspect of the narrowest view a split can make (a half-width, full-height rectangle of the 16:9 screen): the clusters of a split fit that. */
export const SPLIT_ASPECT = ASPECT / 2;
/** The dark gap between two views, in design pixels (the camera's clear colour shows through): `gapped` makes it. */
export const GAP = 6;

export const config = { tether: true };

/** @typedef {{id: number, x: number, y: number}} Point */
/** @typedef {{players: number[], center: {x: number, y: number}, ortho: number, aspect: number, viewport: [number, number, number, number]}} View */
/** @typedef {{mode: "shared" | "split", views: View[]}} Plan */

/** The largest span (x and y) a shared view shows without losing a miner at its margin. */
export function maxSpan(maxOrtho = MAX_ORTHO, aspect = ASPECT) {
  return { x: 2 * (maxOrtho * aspect - MARGIN), y: 2 * (maxOrtho - MARGIN) };
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

/** The orthoSize that shows these points with the margin in a view of this aspect (width / height), between BASE_ORTHO and `maxOrtho`. */
export function orthoFor(points, maxOrtho = MAX_ORTHO, aspect = ASPECT) {
  if (points.length === 0) return BASE_ORTHO;
  const b = bounds(points);
  const need = Math.max((b.h / 2 + MARGIN), (b.w / 2 + MARGIN) / aspect);
  return Math.max(BASE_ORTHO, Math.min(maxOrtho, need));
}

function fits(points, scale = 1, maxOrtho = MAX_ORTHO, aspect = ASPECT) {
  if (points.length <= 1) return true;
  const b = bounds(points), span = maxSpan(maxOrtho, aspect);
  return b.w <= span.x * scale && b.h <= span.y * scale;
}

/**
 * Groups the points into the fewest clusters that each fit a view of this aspect: the two closest clusters that still fit are merged
 * first. A split uses SPLIT_ASPECT, so a cluster fits whichever rectangle it ends up in.
 */
export function clusters(points, maxOrtho = MAX_ORTHO, aspect = SPLIT_ASPECT) {
  /** @type {Point[][]} */
  let groups = points.map((p) => [p]);
  for (;;) {
    let best = null, bestD = Infinity;
    for (let i = 0; i < groups.length; i++) {
      for (let j = i + 1; j < groups.length; j++) {
        const union = [...groups[i], ...groups[j]];
        if (!fits(union, 1, maxOrtho, aspect)) continue;
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

/** The aspect (width / height) a viewport gives on a 16:9 screen. */
export function aspectOf(viewport) {
  return (ASPECT * viewport[2]) / viewport[3];
}

/**
 * A viewport with a GAP-pixel dark line where it touches another view (not at the screen's edge): what the Camera entity gets, so the
 * views do not run into each other. The screen is 1280 x 720 design pixels.
 * @param {[number, number, number, number]} v
 * @returns {[number, number, number, number]}
 */
export function gapped(v) {
  const gx = GAP / 1280, gy = GAP / 720;
  let [x, y] = v;
  const x1 = v[0] + v[2], y1 = v[1] + v[3];
  if (x > 1e-6) x += gx / 2;
  if (y > 1e-6) y += gy / 2;
  return [x, y, (x1 < 1 - 1e-6 ? x1 - gx / 2 : x1) - x, (y1 < 1 - 1e-6 ? y1 - gy / 2 : y1) - y];
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
      return { mode: "shared", views: [{ players: points.map((p) => p.id), center: { x: b.cx, y: b.cy }, ortho: orthoFor(points, this.maxOrtho), aspect: ASPECT, viewport: [0, 0, 1, 1] }] };
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
      views: order.map((gi, k) => {
        const viewport = /** @type {[number, number, number, number]} */ (rects[k]);
        const aspect = aspectOf(viewport);
        return { players: groups[gi].map((p) => p.id), center: { x: centers[gi].cx, y: centers[gi].cy }, ortho: orthoFor(groups[gi], this.maxOrtho, aspect), aspect, viewport };
      }),
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
 * The leash (off when the player chose a split screen, or with `config.tether = false`). A miner wants to go from `from` to `to`: on each axis the step is refused when it would spread the active miners
 * farther than the largest view shows AND the spread is not already that wide (so someone who is far away can always walk back).
 * @param {number} id
 * @param {{x: number, y: number}} from
 * @param {{x: number, y: number}} to
 * @returns {{x: number, y: number}}
 */
export function limitMove(id, from, to) {
  if (!config.tether || splitScreenOn()) return to;
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
