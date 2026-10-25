// @ts-check
// Fog of war: the part of the mine nobody has seen stays black, and what the miners see is revealed. FactorIA's Light2D has
// no occlusion (a lamp lights the rock behind a wall too), so the light alone cannot hide a room; this module keeps its own
// map of what each tile's state is and draws it as a second Tilemap (assets/fog.png, drawn over the mine and under the HUD):
//   0 unseen   black.
//   1 seen     a tile that was visible once: drawn half dark (the mine is remembered, enemies in it are hidden).
//   2 visible  a tile a lamp or a torch reaches in a straight line: clear.
// A tile is visible when it is within the lamp's radius of a miner in play (the lamp shrinks with the oil) and no solid tile
// is on the straight line between them; the solid tile that stops the line is visible itself, so walls show. A torch shows
// the tiles around it for good, even when no miner is near. Digging changes what blocks, so a tunnel opens the view at once.
//
//   const fog = new Fog(map);       // shift.js makes one per shift; it spawns the fog Tilemap
//   fog.update(dt);                 // every frame (it recomputes at 10 Hz, or at once after a tile changed)
//   fog.update(dt, {torches: [{tx, ty}]})
//   fog.stateAt(tx, ty)             // 0, 1 or 2
//   fog.isVisible(tx, ty)           // state 2
//   fog.seen()                      // how many tiles are not black
//   fog.dispose()
import { world } from "factoria";
import { TILE } from "./tiles.js";
import { lampOf, lampRadius } from "./run_state.js";
import { miners } from "./actors.js";

export const UNSEEN = 0;
export const SEEN = 1;
export const VISIBLE = 2;
/** How far (tiles) a torch shows the mine around it. */
export const TORCH_RADIUS = 4.5;
/** Extra tiles of sight beyond the lamp's light radius (the edge of the glow is still visible). */
export const SIGHT_EXTRA = 0.5;
/** Seconds between two recomputations when nothing changed. */
const EVERY = 0.1;

/** Fog tile (fog.png) of a state; -1 draws nothing. */
const TILE_OF = [0, 1, -1];

export class Fog {
  /** @param {import("./mine_map.js").MineMap} map */
  constructor(map) {
    this.map = map;
    this.width = map.width;
    this.height = map.height;
    /** @type {Uint8Array} */
    this.state = new Uint8Array(map.width * map.height);
    this.tiles = new Array(map.width * map.height).fill(0);
    this.sinceUpdate = 99;
    this.dirty = true;
    this.started = false;
    this.entity = world.spawn({
      components: {
        Transform: { position: [0, 0, 0] },
        Tilemap: { tileset: "assets/fog.png", tileSize: [TILE, TILE], width: map.width, height: map.height, tiles: this.tiles, lit: false, layer: 15 },
      },
    });
    this.off = map.onChange(() => {
      this.dirty = true;
    });
  }

  stateAt(tx, ty) {
    return this.map.inBounds(tx, ty) ? this.state[ty * this.width + tx] : UNSEEN;
  }

  isVisible(tx, ty) {
    return this.stateAt(tx, ty) === VISIBLE;
  }

  /** Tiles that are not black. */
  seen() {
    let n = 0;
    for (const s of this.state) if (s !== UNSEEN) n++;
    return n;
  }

  /**
   * Marks every tile within `radius` tiles of (tx, ty) that has a straight line to it as visible in `out`.
   * @param {Uint8Array} out
   */
  look(out, tx, ty, radius) {
    const map = this.map;
    const r = Math.ceil(radius);
    for (let y = ty - r; y <= ty + r; y++) {
      for (let x = tx - r; x <= tx + r; x++) {
        if (!map.inBounds(x, y) || (x - tx) ** 2 + (y - ty) ** 2 > radius * radius) continue;
        if (out[y * this.width + x] === VISIBLE) continue;
        if (this.clear(tx, ty, x, y)) out[y * this.width + x] = VISIBLE;
      }
    }
  }

  /** True when no solid tile lies strictly between the two tiles (Bresenham). */
  clear(x0, y0, x1, y1) {
    const map = this.map;
    let x = x0, y = y0;
    const dx = Math.abs(x1 - x0), dy = Math.abs(y1 - y0);
    const sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
    let err = dx - dy;
    for (let guard = 0; guard < 200; guard++) {
      if (x === x1 && y === y1) return true;
      if ((x !== x0 || y !== y0) && map.isSolid(x, y)) return false;
      const e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x += sx;
      }
      if (e2 < dx) {
        err += dx;
        y += sy;
      }
    }
    return true;
  }

  /**
   * @param {number} dt
   * @param {{torches?: {tx:number,ty:number}[], force?: boolean}} [opts]
   */
  update(dt, opts = {}) {
    this.sinceUpdate += dt;
    if (!opts.force && !this.dirty && this.sinceUpdate < EVERY) return;
    const here = miners();
    // the miners are spawned this frame and their scripts start next frame: wait until somebody can see before the first reveal
    if (here.length === 0 && !this.started && !(opts.torches && opts.torches.length > 0)) return;
    this.started = true;
    this.sinceUpdate = 0;
    this.dirty = false;
    const now = new Uint8Array(this.width * this.height);
    for (const m of here) {
      const r = lampRadius(lampOf(m.player.id)) / TILE + SIGHT_EXTRA;
      this.look(now, m.tx, m.ty, r);
    }
    for (const t of opts.torches ?? []) this.look(now, t.tx, t.ty, TORCH_RADIUS);
    let changed = false;
    for (let i = 0; i < now.length; i++) {
      const next = now[i] === VISIBLE ? VISIBLE : this.state[i] === UNSEEN ? UNSEEN : SEEN;
      if (next !== this.state[i]) {
        this.state[i] = next;
        this.tiles[i] = TILE_OF[next];
        changed = true;
      }
    }
    if (changed && this.entity.alive) this.entity.set("Tilemap", { tiles: this.tiles });
  }

  /** Shows the whole mine as seen (a debug aid and a test helper). */
  revealAll() {
    this.state.fill(SEEN);
    this.tiles.fill(TILE_OF[SEEN]);
    this.dirty = true;
    if (this.entity.alive) this.entity.set("Tilemap", { tiles: this.tiles });
  }

  dispose() {
    this.off();
    if (this.entity.alive) this.entity.destroy();
  }
}
