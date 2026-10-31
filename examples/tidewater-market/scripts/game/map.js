// @ts-check
// The map grid: the terrain of every cell and which building stands on it (pure). Cell (c, r) is column c, row r;
// the arrays are indexed r * width + c. The terrain is an index into data/terrain.json (its key order).
import { hashTerrain } from "./mapgen.js";

export class GameMap {
  /**
   * @param {import("./mapgen.js").RawMap} raw
   * @param {ReturnType<typeof import("./data.js").loadData>} data
   */
  constructor(raw, data) {
    this.data = data;
    this.width = raw.width;
    this.height = raw.height;
    this.seed = raw.seed;
    this.terrain = raw.terrain;
    /** The id of the building on each cell, 0 for none (a road is a building of kind "road"). */
    this.occ = new Int32Array(raw.width * raw.height);
  }

  inBounds(c, r) {
    return c >= 0 && r >= 0 && c < this.width && r < this.height;
  }

  index(c, r) {
    return r * this.width + c;
  }

  /** Terrain id ("grass") of a cell, or null outside the map. */
  terrainAt(c, r) {
    return this.inBounds(c, r) ? this.data.terrainIds[this.terrain[r * this.width + c]] : null;
  }

  setTerrain(c, r, id) {
    this.terrain[r * this.width + c] = this.data.terrain[id].index;
  }

  /** Id of the building on a cell, 0 when free or outside. */
  occupantAt(c, r) {
    return this.inBounds(c, r) ? this.occ[r * this.width + c] : 0;
  }

  setOccupant(c, r, id) {
    this.occ[r * this.width + c] = id;
  }

  /** Does a cell touch water (an edge neighbour is water)? */
  touchesWater(c, r) {
    return [[1, 0], [-1, 0], [0, 1], [0, -1]].some(([dc, dr]) => this.terrainAt(c + dc, r + dr) === "water");
  }

  /** The 8 hex digits that identify the terrain (tests and bug reports compare them). */
  hash() {
    return hashTerrain(this);
  }
}
