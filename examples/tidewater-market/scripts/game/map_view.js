// @ts-check
// MapView: draws a GameState with sprite entities, one per tile, tree, road piece and building, and keeps them in step with
// the state by listening to its events (scripts/game/events.js). It never changes the state.
//
// Draw order (Sprite.layer, then lower y on top inside a layer, which is exactly isometric depth sorting):
//   0 terrain   1 roads   3 highlights   10 trees and buildings   12 ghost   (the HUD is UI, always above)
import { world } from "factoria";
import { cellToWorld, footprintFront } from "./iso.js";
import { hash01 } from "./mapgen.js";
import { footprintCells, sizeAt } from "./rules.js";

export const LAYER = { terrain: 0, road: 1, highlight: 3, object: 10, ghost: 12 };

/** Tint of the ghost and the highlight diamonds. */
export const COLORS = {
  valid: [0.35, 1, 0.45, 0.55],
  invalid: [1, 0.3, 0.3, 0.55],
  hover: [1, 1, 1, 0.9],
  demolish: [1, 0.35, 0.2, 0.6],
  existing: [1, 1, 1, 0.25],
};

export class MapView {
  /** @param {import("./state.js").GameState} state */
  constructor(state) {
    this.state = state;
    this.atlas = state.data.atlas;
    this.texture = this.atlas.texture;
    this.tileEntities = [];
    /** @type {Map<number, any>} */
    this.roadEntities = new Map();
    /** @type {Map<number, any>} */
    this.buildingEntities = new Map();
    /** @type {Array<any[]>} trees of each cell (index r * width + c), so a building can hide the ones it stands on. */
    this.trees = [];
    this.pool = [];
    this.poolUsed = 0;
    this.ghost = null;
    this.unsubscribe = [];
    /** @type {Array<{ entity: any, base: number[] }>} the sprites the season tint multiplies (seasonal terrain and trees) */
    this.seasonal = [];
    this.build();
    this.tintSeason(state.clock.date().season);
    const ev = state.events;
    this.unsubscribe.push(ev.on("clock.season", (e) => this.tintSeason(e.date.season)));
    this.unsubscribe.push(ev.on("roads.changed", (e) => this.refreshRoads(e.cells)));
    this.unsubscribe.push(ev.on("building.placed", (e) => this.buildingPlaced(e.building)));
    this.unsubscribe.push(ev.on("building.removed", (e) => this.buildingRemoved(e.building)));
    // a state that already has buildings (the title screen's hamlet): draw them now
    const roads = [];
    for (const b of state.buildings.values()) {
      if (state.data.buildings[b.type].kind === "road") roads.push([b.x, b.y]);
      else this.buildingPlaced(b);
    }
    this.refreshRoads(roads);
  }

  /** A sprite of an atlas frame at a world position. */
  sprite(frameName, x, y, layer, extra = {}) {
    const f = this.atlas.frames[frameName];
    return world.spawn({
      components: {
        Transform: { position: [x, y, 0] },
        Sprite: { texture: this.texture, region: f.rect, pivot: f.pivot, layer, pixelArt: false, ...extra },
      },
    });
  }

  /** Set the frame of a sprite entity made by sprite(). */
  setFrame(entity, frameName) {
    const f = this.atlas.frames[frameName];
    const s = entity.get("Sprite");
    s.region = f.rect;
    s.pivot = f.pivot;
  }

  build() {
    const { map, data } = this.state;
    for (let r = 0; r < map.height; r++) {
      for (let c = 0; c < map.width; c++) {
        const id = map.terrainAt(c, r);
        const def = data.terrain[id];
        const [x, y] = cellToWorld(c, r);
        const extra = def.tint ? { color: def.tint } : {};
        const tile = this.sprite(def.frame, x, y, LAYER.terrain, extra);
        this.tileEntities.push(tile);
        if (def.seasonal) this.seasonal.push({ entity: tile, base: def.tint || [1, 1, 1, 1] });
        if (def.decor === "trees") this.trees[map.index(c, r)] = this.makeTrees(c, r, x, y);
      }
    }
  }

  /** Three conifers on a forest cell, placed by a hash of the cell so they are the same every time. */
  makeTrees(c, r, x, y) {
    const out = [];
    for (let i = 0; i < 3; i++) {
      const a = hash01(this.state.map.seed, c, r, 40 + i);
      const b = hash01(this.state.map.seed, c, r, 50 + i);
      const kind = Math.floor(hash01(this.state.map.seed, c, r, 60 + i) * 6);
      // inside the diamond: |dx| / 50 + |dy| / 25 < 0.75
      const dx = (a * 2 - 1) * 34;
      const dy = (b * 2 - 1) * (17 - Math.abs(dx) / 2) * 0.9;
      const tree = this.sprite(`tree.${kind}`, x + dx, y + dy - 2, LAYER.object);
      this.seasonal.push({ entity: tree, base: [1, 1, 1, 1] });
      out.push(tree);
    }
    return out;
  }

  /** Multiply the colour of the seasonal terrain and the trees by the tint of a season (data/seasons.json). */
  tintSeason(season) {
    const info = this.state.data.seasons[season];
    if (!info) return;
    const t = info.tint;
    for (const { entity, base } of this.seasonal) {
      entity.get("Sprite").color = [base[0] * t[0], base[1] * t[1], base[2] * t[2], base[3] * t[3]];
    }
  }

  /** The picture of a road cell: its neighbours decide the piece. */
  refreshRoads(cells) {
    const { map } = this.state;
    for (const [c, r] of cells) {
      const key = map.index(c, r);
      const isRoad = this.state.isRoad(c, r);
      const existing = this.roadEntities.get(key);
      if (!isRoad) {
        if (existing) {
          existing.destroy();
          this.roadEntities.delete(key);
        }
        continue;
      }
      const frame = this.atlas.roadFrames[String(this.state.roadMask(c, r))];
      if (existing) this.setFrame(existing, frame);
      else {
        const [x, y] = cellToWorld(c, r);
        this.roadEntities.set(key, this.sprite(frame, x, y, LAYER.road));
      }
    }
  }

  buildingPlaced(b) {
    const def = this.state.data.buildings[b.type];
    if (def.kind === "road") return;
    const [x, y] = footprintFront(b.x, b.y, b.w, b.h);
    this.buildingEntities.set(b.id, this.sprite(`building.${b.type}.${b.rot}`, x, y, LAYER.object));
    this.setTreesActive(b, false);
  }

  buildingRemoved(b) {
    const e = this.buildingEntities.get(b.id);
    if (e) {
      e.destroy();
      this.buildingEntities.delete(b.id);
    }
    this.setTreesActive(b, true);
  }

  /** Trees on a cell a building covers are hidden; they come back when it is demolished. */
  setTreesActive(b, active) {
    const def = this.state.data.buildings[b.type];
    for (const [c, r] of footprintCells(def, b.x, b.y, b.rot)) {
      const list = this.trees[this.state.map.index(c, r)];
      if (list) for (const t of list) t.active = active;
    }
  }

  // ---- overlays: highlight diamonds and the ghost building ------------------------------------------------------------

  /** Start of a frame's overlay: every diamond is free again. */
  beginOverlay() {
    this.poolUsed = 0;
  }

  /** A diamond over a cell: filled with a colour, or an outline. */
  diamond(c, r, color, outline = false) {
    let e = this.pool[this.poolUsed];
    if (!e) {
      e = world.spawn({
        components: {
          Transform: { position: [0, 0, 0] },
          Shape2D: { shape: "diamond", size: [100, 50], layer: LAYER.highlight, filled: true, thickness: 3 },
        },
      });
      this.pool.push(e);
    }
    this.poolUsed++;
    const [x, y] = cellToWorld(c, r);
    e.active = true;
    e.position = [x, y, 0];
    const s = e.get("Shape2D");
    s.color = color;
    s.filled = !outline;
    return e;
  }

  /** End of a frame's overlay: the diamonds not used this frame are hidden. */
  endOverlay() {
    for (let i = this.poolUsed; i < this.pool.length; i++) if (this.pool[i].active) this.pool[i].active = false;
  }

  /** Show the ghost of a building (or hide it with null). */
  setGhost(type, x, y, rot, valid) {
    if (!type) {
      if (this.ghost) this.ghost.active = false;
      return;
    }
    const def = this.state.data.buildings[type];
    const [w, h] = sizeAt(def, rot);
    const [wx, wy] = footprintFront(x, y, w, h);
    const frame = `building.${type}.${rot}`;
    if (!this.ghost) this.ghost = this.sprite(frame, wx, wy, LAYER.ghost);
    this.ghost.active = true;
    this.ghost.position = [wx, wy, 0];
    this.setFrame(this.ghost, frame);
    this.ghost.get("Sprite").color = valid ? [0.75, 1, 0.75, 0.75] : [1, 0.5, 0.5, 0.7];
  }

  destroy() {
    for (const off of this.unsubscribe) off();
    this.unsubscribe = [];
  }
}
