// @ts-check
// The map and dig API: the one place that answers "what is at this tile?" and the only one that changes a tile.
// Rows count down from the top (row 0 is the top row, like Tilemap.tiles); world coordinates are the engine's (x right,
// y UP) with the Tilemap entity at (0, 0): tile (tx, ty) has its centre at ((tx + 0.5) * TILE, -(ty + 0.5) * TILE).
// Nothing here touches an entity: the shift scene listens to `onChange` and redraws the Tilemap, so the map works (and is
// tested) without a scene. Out-of-bounds tiles count as bedrock.
import { K, TILE, kindInfo, isSolidKind } from "./tiles.js";
import * as events from "./events.js";

/**
 * The shift being played, set by the shift scene when it starts and emptied when it ends. Other modules read it here instead
 * of searching the scene: `map` is the MineMap and `mine` its mine; `nav` the tile pathfinding of the map, `fog` the fog of
 * war, `hazards` the water/magma/cave-in rules and `lights` the torch and crystal lights (all null outside a shift, and `fog`,
 * `hazards` and `lights` also null in a test that builds a map without a scene).
 * @type {{map: MineMap|null, mine: import("./generator.js").Mine|null, nav: import("./pathfinding.js").NavGrid|null,
 *   fog: import("./fog.js").Fog|null, hazards: import("./hazards.js").Hazards|null, lights: import("./lights.js").Lights|null}}
 */
export const live = { map: null, mine: null, nav: null, fog: null, hazards: null, lights: null };

export class MineMap {
  /**
   * @param {import("./generator.js").Mine} mine  The mine to play. The map edits `mine.kinds` in place, so
   *   `mineHash(map.mine)` is always the hash of what is on the map now.
   */
  constructor(mine) {
    this.mine = mine;
    this.width = mine.width;
    this.height = mine.height;
    /** @type {Array<(change: {tx:number,ty:number,from:number,to:number,cause:string}) => void>} */
    this.listeners = [];
  }

  /** True when the tile is on the map. */
  inBounds(tx, ty) {
    return tx >= 0 && ty >= 0 && tx < this.width && ty < this.height;
  }

  /** Kind of a tile (`K` in tiles.js); anything off the map is bedrock. */
  kindAt(tx, ty) {
    return this.inBounds(tx, ty) ? this.mine.kinds[ty * this.width + tx] : K.BEDROCK;
  }

  /** True when the tile blocks a miner (rock, dirt, ore, bedrock, the edge of the map). */
  isSolid(tx, ty) {
    return isSolidKind(this.kindAt(tx, ty));
  }

  /** True when a miner can stand on the tile. */
  isWalkable(tx, ty) {
    return !this.isSolid(tx, ty);
  }

  /** Tile that holds a world point. */
  tileAt(x, y) {
    return { tx: Math.floor(x / TILE), ty: Math.floor(-y / TILE) };
  }

  /** World position of the centre of a tile. */
  tileCenter(tx, ty) {
    return { x: (tx + 0.5) * TILE, y: -(ty + 0.5) * TILE };
  }

  /**
   * Can a pick of this tier dig the tile now?
   * @returns {{ok: boolean, reason?: "air"|"bedrock"|"tier"}}
   */
  canDig(tx, ty, tier = 0) {
    const kind = this.kindAt(tx, ty);
    const info = kindInfo(kind);
    if (!info.solid) return { ok: false, reason: "air" };
    if (kind === K.BEDROCK || !this.inBounds(tx, ty)) return { ok: false, reason: "bedrock" };
    if (info.tier > tier) return { ok: false, reason: "tier" };
    return { ok: true };
  }

  /**
   * Digs a tile out at once (the miner calls it when the dig time is up; a bomb or a test can call it directly). The tile
   * becomes floor, `onChange` listeners and the `dug` event fire. Returns what it was, so the caller can pick the ore.
   * @param {number} tx
   * @param {number} ty
   * @param {{tier?: number, by?: number|null}} [opts]  `tier`: pick tier (default 0). `by`: player id for the events.
   * @returns {{ok: true, kind: number, ore: string|null, value: number} | {ok: false, reason: string}}
   */
  dig(tx, ty, opts = {}) {
    const can = this.canDig(tx, ty, opts.tier ?? 0);
    if (!can.ok) {
      if (can.reason !== "air") events.emit("digBlocked", { tx, ty, kind: this.kindAt(tx, ty), reason: can.reason, by: opts.by ?? null });
      return { ok: false, reason: /** @type {string} */ (can.reason) };
    }
    const kind = this.kindAt(tx, ty);
    const info = kindInfo(kind);
    this.setKind(tx, ty, K.FLOOR, "dig");
    events.emit("dug", { tx, ty, from: kind, by: opts.by ?? null });
    return { ok: true, kind, ore: info.ore, value: info.value };
  }

  /**
   * Overwrites a tile (the generator's result is never changed this way, only play does: digging, picking up oil).
   * Notifies the listeners and emits `tileChanged`.
   * @param {number} tx
   * @param {number} ty
   * @param {number} kind
   * @param {string} [cause]
   */
  setKind(tx, ty, kind, cause = "set") {
    if (!this.inBounds(tx, ty)) throw new Error(`setKind(${tx}, ${ty}): off the map (${this.width} x ${this.height} tiles)`);
    kindInfo(kind);
    const from = this.mine.kinds[ty * this.width + tx];
    if (from === kind) return;
    this.mine.kinds[ty * this.width + tx] = kind;
    const change = { tx, ty, from, to: kind, cause };
    for (const fn of [...this.listeners]) fn(change);
    events.emit("tileChanged", change);
  }

  /**
   * Subscribes to tile changes (the notification the view redraws from). Returns the function that unsubscribes.
   * @param {(change: {tx:number,ty:number,from:number,to:number,cause:string}) => void} fn
   */
  onChange(fn) {
    this.listeners.push(fn);
    return () => {
      const i = this.listeners.indexOf(fn);
      if (i >= 0) this.listeners.splice(i, 1);
    };
  }

  /**
   * True when a box (centre x, y in world units, half sizes hx, hy) overlaps a solid tile.
   */
  boxHitsSolid(x, y, hx, hy) {
    const x0 = Math.floor((x - hx) / TILE), x1 = Math.floor((x + hx - 1e-6) / TILE);
    const y0 = Math.floor(-(y + hy) / TILE), y1 = Math.floor((-(y - hy) - 1e-6) / TILE);
    for (let ty = y0; ty <= y1; ty++) for (let tx = x0; tx <= x1; tx++) if (this.isSolid(tx, ty)) return true;
    return false;
  }

  /**
   * Moves a box by (dx, dy) world units, one axis at a time, stopping flush against solid tiles. Steps must stay under
   * one tile (a miner moves about a unit per frame).
   * @returns {{x:number, y:number, hitX:boolean, hitY:boolean}}
   */
  moveBox(x, y, hx, hy, dx, dy) {
    const EPS = 0.001;
    let hitX = false, hitY = false;
    if (dx !== 0) {
      let nx = x + dx;
      if (this.boxHitsSolid(nx, y, hx, hy)) {
        hitX = true;
        nx = dx > 0 ? Math.floor((nx + hx) / TILE) * TILE - hx - EPS : (Math.floor((nx - hx) / TILE) + 1) * TILE + hx + EPS;
      }
      x = nx;
    }
    if (dy !== 0) {
      let ny = y + dy;
      if (this.boxHitsSolid(x, ny, hx, hy)) {
        hitY = true;
        // world y grows up, tile rows grow down
        ny = dy > 0 ? -(Math.floor(-(ny + hy) / TILE) + 1) * TILE - hy - EPS : -Math.floor(-(ny - hy) / TILE) * TILE + hy + EPS;
      }
      y = ny;
    }
    return { x, y, hitX, hitY };
  }

  /** How many tiles of each kind are on the map now (a test and HUD helper). */
  count(kind) {
    let n = 0;
    for (const k of this.mine.kinds) if (k === kind) n++;
    return n;
  }
}
