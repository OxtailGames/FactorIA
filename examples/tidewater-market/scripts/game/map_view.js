// @ts-check
// MapView: draws a GameState and keeps it in step with the state by listening to its events (scripts/game/events.js). The ground
// (terrain, trees, roads) is ONE isometric Tilemap, one batched mesh in depth order; buildings, the ghost and the highlight
// diamonds are sprites and shapes. It never changes the state.
//
// The Tilemap's picture is one PNG per season (data/terrain.json "tileset", made by assets/src/make_terrain_tiles.py): a season
// change swaps the PNG, a road or a building that clears a forest cell writes one tile with tilemap.setTile.
//
// Draw order (Sprite.layer, then lower y on top inside a layer, then creation order, which for sprites is isometric depth sorting):
//   0 the ground Tilemap   3 highlights   10 buildings and walkers   11 map overlays (over a dense town)   12 ghost   14-15 the pips of the overlays   (the HUD is UI, always above)
import { world } from "factoria";
import { cellToWorld, footprintFront } from "./iso.js";
import { hash01 } from "./mapgen.js";
import { footprintCells, sizeAt } from "./rules.js";
import { live } from "../settings.js";

export const LAYER = { terrain: 0, road: 1, highlight: 3, object: 10, field: 11, ghost: 12, fieldPlate: 14, fieldMark: 15 };

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
    this.tileset = state.data.tileset;
    /** @type {Map<number, any>} */
    this.buildingEntities = new Map();
    /** @type {Set<number>} the forest cells (index r * width + c) a building stands on: their trees are cut down. */
    this.cleared = new Set();
    this.pool = [];
    this.poolUsed = 0;
    this.ghost = null;
    this.unsubscribe = [];
    this.season = state.clock.date().season;
    this.ground = null;
    this.build();
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
    const { map } = this.state;
    const t = this.tileset;
    const rows = [];
    for (let r = 0; r < map.height; r++) {
      const row = [];
      for (let c = 0; c < map.width; c++) row.push(this.tileAt(c, r));
      rows.push(row);
    }
    // The entity sits at the top corner of the map: cell (0, 0) is the diamond centred on the world origin (iso.js cellToWorld).
    this.ground = world.spawn({
      id: "ground",
      components: {
        Transform: { position: [0, t.groundHeight / 2, 0] },
        Tilemap: {
          tileset: t.seasons[this.season],
          projection: "isometric",
          tileSize: t.tileSize,
          groundHeight: t.groundHeight,
          groundOffset: t.groundOffset,
          columns: t.columns,
          layer: LAYER.terrain,
          tiles: rows,
        },
      },
    });
  }

  /** The tile of a cell: a road piece by its neighbours, else the terrain, a forest with one of its pictures of trees unless a building cut them down. */
  tileAt(c, r) {
    const { map, data } = this.state;
    const t = this.tileset;
    if (this.state.isRoad(c, r)) return t.roadTile + this.state.roadMask(c, r);
    const def = data.terrain[map.terrainAt(c, r)];
    if (def.decor === "trees" && !this.cleared.has(map.index(c, r))) {
      return t.treeTile + Math.floor(hash01(map.seed, c, r, 40) * t.treeVariants);
    }
    return def.tile;
  }

  /** Show the tileset of a season (data/seasons.json tints: the sand, grass and trees of that PNG are already multiplied by it). */
  tintSeason(season) {
    if (!this.tileset.seasons[season] || season === this.season) return;
    this.season = season;
    this.ground.get("Tilemap").tileset = this.tileset.seasons[season];
  }

  /** The picture of a road cell: its neighbours decide the piece; a cell that stopped being road shows its terrain again. */
  refreshRoads(cells) {
    const { map } = this.state;
    for (const [c, r] of cells) {
      if (c < 0 || r < 0 || c >= map.width || r >= map.height) continue;
      this.ground.tilemap.setTile(c, r, this.tileAt(c, r));
    }
  }

  buildingPlaced(b) {
    const def = this.state.data.buildings[b.type];
    if (def.kind === "road") return;
    const [x, y] = footprintFront(b.x, b.y, b.w, b.h);
    this.buildingEntities.set(b.id, this.sprite(`building.${b.type}.${b.rot}`, x, y, LAYER.object));
    this.setTreesCut(b, true);
  }

  buildingRemoved(b) {
    const e = this.buildingEntities.get(b.id);
    if (e) {
      e.destroy();
      this.buildingEntities.delete(b.id);
    }
    this.setTreesCut(b, false);
  }

  /** The trees on the cells a building covers are cut down (the plain forest tile shows); they come back when it is demolished. */
  setTreesCut(b, cut) {
    const { map } = this.state;
    const def = this.state.data.buildings[b.type];
    for (const [c, r] of footprintCells(def, b.x, b.y, b.rot)) {
      const key = map.index(c, r);
      if (cut) this.cleared.add(key);
      else this.cleared.delete(key);
      this.ground.tilemap.setTile(c, r, this.tileAt(c, r));
    }
  }

  // ---- overlays: highlight diamonds and the ghost building ------------------------------------------------------------

  /** Start of a frame's overlay: every diamond is free again. */
  beginOverlay() {
    this.poolUsed = 0;
  }

  /**
   * A diamond over a cell: filled with a colour, or an outline; `scale` shrinks it (a pip in the middle of the cell). With the
   * colour-blind safe option the "cannot build here" and "will be demolished" colours get a mark of their own as well: a dot for
   * invalid, a ring for demolish, so red and green are never the only difference. `layer` is LAYER.highlight (on the ground,
   * under the buildings) or LAYER.field (over the buildings, for the map overlays); `thickness` is the outline's width.
   */
  diamond(c, r, color, outline = false, scale = 1, layer = LAYER.highlight, thickness = 3) {
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
    s.size = [100 * scale, 50 * scale];
    s.layer = layer;
    s.thickness = thickness;
    if (scale === 1 && (color === COLORS.invalid || color === COLORS.demolish) && live().safeColors) {
      this.diamond(c, r, [1, 1, 1, 0.95], color === COLORS.demolish, color === COLORS.demolish ? 0.62 : 0.2);
    }
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
