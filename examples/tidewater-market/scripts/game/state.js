// @ts-check
// GameState: the whole simulation state of a game and the only way to change it (pure: it never touches the engine, so
// tests, tools and the view all use the same object). The player's actions - place, lay roads, demolish, undo, redo - are
// methods here; each one checks the rules, pays or refunds, changes the map and emits events (scripts/game/events.js).
//
//   const game = createGame({ seed: 7 });                     // or { testMap: true }
//   game.place("house", 20, 20, 0)  ->  { ok: true, building } | { ok: false, reasons: [{ code, ... }] }
//
// An undoable action is a transaction { label, ops, delta }: the buildings added or removed and the exact coins and goods
// that moved, so undo and redo restore the map AND the money to the unit.
import { getData } from "./data.js";
import { Events } from "./events.js";
import { Economy, negate, refundOf } from "./economy.js";
import { Clock } from "./clock.js";
import { Simulation } from "./sim.js";
import { Trade } from "./trade.js";
import { GameMap } from "./map.js";
import { generateMap, mapFromRows } from "./mapgen.js";
import { checkPlacement, footprintCells, isRoad, originFor, roadMask, roadPath, sizeAt } from "./rules.js";

/**
 * @typedef {{ id: number, type: string, x: number, y: number, rot: number, w: number, h: number }} Building
 *   x, y = the footprint's minimum corner; w, h = its size at this rotation. Ids are never reused and survive undo/redo.
 */

export class GameState {
  /** @param {{ seed?: number, testMap?: boolean, rows?: string[], data?: ReturnType<typeof getData> }} [options] rows = a custom map as text rows of terrain characters (data/terrain.json `char`), as the stress town does */
  constructor(options = {}) {
    this.data = options.data || getData();
    this.events = new Events();
    const raw = options.rows
      ? mapFromRows(options.rows, this.data.terrainByChar)
      : options.testMap
      ? mapFromRows(this.data.testMap.rows, this.data.terrainByChar)
      : generateMap(options.seed ?? this.data.map.defaultSeed, this.data.map, this.data.terrainIds);
    this.map = new GameMap(raw, this.data);
    this.economy = new Economy(this.data, this.events);
    this.clock = new Clock(this.data.economy.calendar, this.events);
    /** @type {Map<number, Building>} */
    this.buildings = new Map();
    this.nextId = 1;
    /** @type {any[]} */
    this.undoStack = [];
    /** @type {any[]} */
    this.redoStack = [];
    this.testMap = !!options.testMap;
    /** The town's life: villagers, walkers, production, carriers, wages (scripts/game/sim.js). It runs on clock.tick. */
    this.sim = new Simulation(this);
    /** Ships, orders, reputation, event cards, story and achievement progress (scripts/game/trade.js, P5). Off until `trade.start()`. */
    this.trade = new Trade(this);
  }

  // ---- queries -----------------------------------------------------------------------------------------------------

  /** The building on a cell, or null. */
  buildingAt(c, r) {
    const id = this.map.occupantAt(c, r);
    return id ? this.buildings.get(id) || null : null;
  }

  isRoad(c, r) {
    return isRoad(this, c, r);
  }

  /** All buildings of a type (all of them without a type), in the order they were built. */
  list(type) {
    const out = [];
    for (const b of this.buildings.values()) if (!type || b.type === type) out.push(b);
    return out;
  }

  /** Can `type` go with its footprint's minimum corner at (x, y)? Same answer a click gets. */
  check(type, x, y, rot = 0) {
    return checkPlacement(this, type, x, y, rot);
  }

  /** Placement check for a cursor on cell (c, r): the footprint is centred on the cursor. */
  checkAt(type, c, r, rot = 0) {
    const [x, y] = originFor(this.data.buildings[type], c, r, rot);
    return { ...this.check(type, x, y, rot), x, y };
  }

  /** Road bit mask of a cell (which neighbours hold a road), for choosing the picture. */
  roadMask(c, r) {
    return roadMask(this, c, r);
  }

  canUndo() {
    return this.undoStack.length > 0;
  }

  canRedo() {
    return this.redoStack.length > 0;
  }

  /** A fingerprint of everything that matters: terrain, buildings, coins, stock and the simulation (villagers, production, ledger). Equal states give equal strings. */
  hash() {
    let h = 0x811c9dc5;
    const feed = (n) => {
      h ^= n & 255;
      h = Math.imul(h, 0x01000193);
      h ^= (n >> 8) & 255;
      h = Math.imul(h, 0x01000193);
    };
    const feedText = (s) => {
      for (let i = 0; i < s.length; i++) feed(s.charCodeAt(i));
    };
    feedText(this.map.hash());
    const sorted = [...this.buildings.values()].sort((a, b) => a.id - b.id);
    for (const b of sorted) {
      feedText(b.type);
      feed(b.x);
      feed(b.y);
      feed(b.rot);
    }
    feed(this.economy.coins);
    feed(this.economy.coins >> 16);
    for (const g of this.data.goodIds) feed(this.economy.stock[g] || 0);
    this.sim.feed(feed);
    return (h >>> 0).toString(16).padStart(8, "0");
  }

  // ---- actions -----------------------------------------------------------------------------------------------------

  /**
   * Build something. Pays its cost. One undo step.
   * @returns {{ ok: true, building: Building } | { ok: false, reasons: any[] }}
   */
  place(type, x, y, rot = 0) {
    const def = this.data.buildings[type];
    if (!def) return this.reject({ action: "place", type }, [{ code: "unknown_type", detail: { type } }]);
    const rotation = def.kind === "road" ? 0 : ((rot % 4) + 4) % 4;
    const verdict = checkPlacement(this, type, x, y, rotation);
    if (!verdict.ok) return this.reject({ action: "place", type, x, y, rot: rotation }, verdict.reasons);
    const delta = negate(def.cost);
    this.economy.apply(delta, "place");
    const building = this.addBuilding(type, x, y, rotation, "place");
    this.commit({ label: "place", type, ops: [{ op: "add", building }], delta });
    this.emitRoads([building]);
    return { ok: true, building };
  }

  /** Same as place(), with the footprint centred on cell (c, r). */
  placeAt(type, c, r, rot = 0) {
    const [x, y] = originFor(this.data.buildings[type], c, r, rot);
    return this.place(type, x, y, rot);
  }

  /**
   * Lay roads on a list of cells (a drag). Cells that already hold a road are skipped for free; cells that break a rule or
   * that the player can no longer afford are skipped and reported. The roads laid are ONE undo step.
   * @param {number[][]} cells
   * @returns {{ ok: boolean, placed: Building[], skipped: Array<{ cell: number[], reasons: any[] }> }}
   */
  placeRoads(cells) {
    const placed = [];
    const skipped = [];
    let delta = {};
    const ops = [];
    for (const [c, r] of cells) {
      if (this.isRoad(c, r)) continue;
      const verdict = checkPlacement(this, "road", c, r, 0);
      if (!verdict.ok) {
        skipped.push({ cell: [c, r], reasons: verdict.reasons });
        continue;
      }
      const cost = negate(this.data.buildings.road.cost);
      this.economy.apply(cost, "place");
      for (const [k, v] of Object.entries(cost)) delta[k] = (delta[k] || 0) + v;
      const building = this.addBuilding("road", c, r, 0, "place");
      ops.push({ op: "add", building });
      placed.push(building);
    }
    if (placed.length) {
      this.commit({ label: "road", type: "road", ops, delta });
      this.emitRoads(placed);
    } else if (skipped.length) {
      this.events.emit("action.rejected", { action: "road", code: skipped[0].reasons[0].code, reasons: skipped[0].reasons });
    }
    return { ok: placed.length > 0, placed, skipped };
  }

  /**
   * Preview of placeRoads without changing anything: for each cell, "new" (would be built), "existing" (already a road) or the
   * first rule it breaks. Money is spent in order, so cells after the money runs out come back "cannot_afford".
   * @returns {Array<{ cell: number[], status: string, reasons?: any[] }>}
   */
  previewRoads(cells) {
    const budget = { ...this.economy.snapshot().stock, coins: this.economy.coins };
    const cost = this.data.buildings.road.cost;
    const out = [];
    for (const [c, r] of cells) {
      if (this.isRoad(c, r)) {
        out.push({ cell: [c, r], status: "existing" });
        continue;
      }
      const verdict = checkPlacement(this, "road", c, r, 0);
      const reasons = verdict.reasons.filter((x) => x.code !== "cannot_afford");
      if (reasons.length) {
        out.push({ cell: [c, r], status: reasons[0].code, reasons });
        continue;
      }
      let affordable = true;
      for (const [k, v] of Object.entries(cost)) if ((budget[k] || 0) < v) affordable = false;
      if (!affordable) {
        out.push({ cell: [c, r], status: "cannot_afford" });
        continue;
      }
      for (const [k, v] of Object.entries(cost)) budget[k] -= v;
      out.push({ cell: [c, r], status: "new" });
    }
    return out;
  }

  /**
   * Turn a building a quarter turn on the spot (the inspector's Rotate, key R with a building selected). Free, one undo step.
   * It is built again as a NEW building (a new id): what was inside is lost, the villagers who worked there lose their
   * place for a moment, and a house is refused (its villagers would be sent away; a house has no door to turn).
   * @returns {{ ok: true, building: Building } | { ok: false, reasons: any[] }}
   */
  rotateBuilding(id) {
    const old = this.buildings.get(id);
    if (!old) return this.reject({ action: "rotate", id }, [{ code: "nothing_here" }]);
    const def = this.data.buildings[old.type];
    if (def.kind === "road" || def.housing) return this.reject({ action: "rotate", id }, [{ code: "cannot_rotate", detail: { type: old.type } }]);
    const rot = (old.rot + 1) % 4;
    const [x, y] = originFor(def, old.x + Math.floor((old.w - 1) / 2), old.y + Math.floor((old.h - 1) / 2), rot);
    // check the new footprint with the old building out of the way (the cells are only cleared for the check)
    const own = footprintCells(def, old.x, old.y, old.rot);
    for (const [c, r] of own) this.map.setOccupant(c, r, 0);
    const verdict = checkPlacement(this, old.type, x, y, rot);
    for (const [c, r] of own) this.map.setOccupant(c, r, old.id);
    const reasons = verdict.reasons.filter((r) => r.code !== "cannot_afford"); // turning is free
    if (reasons.length) return this.reject({ action: "rotate", id, type: old.type, x, y, rot }, reasons);
    this.removeBuilding(old, "rotate");
    const building = this.addBuilding(old.type, x, y, rot, "rotate");
    this.commit({ label: "rotate", type: old.type, ops: [{ op: "remove", building: old }, { op: "add", building }], delta: {} });
    return { ok: true, building };
  }

  /**
   * Demolish the building (or road) standing on cell (c, r) and hand back part of its cost. One undo step.
   * @returns {{ ok: true, building: Building, refund: Record<string, number> } | { ok: false, reasons: any[] }}
   */
  demolish(c, r) {
    const building = this.buildingAt(c, r);
    if (!building) return this.reject({ action: "demolish", x: c, y: r }, [{ code: "nothing_here", cell: [c, r] }]);
    const refund = refundOf(this.data.buildings[building.type].cost, this.data.economy.refund);
    this.removeBuilding(building, "demolish");
    this.economy.apply(refund, "demolish");
    this.commit({ label: "demolish", type: building.type, ops: [{ op: "remove", building }], delta: refund });
    this.emitRoads([building]);
    return { ok: true, building, refund };
  }

  /**
   * Demolish everything on a list of cells as ONE undo step (a drag with the demolish tool).
   * @returns {{ ok: boolean, removed: Building[] }}
   */
  demolishCells(cells) {
    const removed = [];
    const ops = [];
    const delta = {};
    for (const [c, r] of cells) {
      const b = this.buildingAt(c, r);
      if (!b) continue;
      const refund = refundOf(this.data.buildings[b.type].cost, this.data.economy.refund);
      this.removeBuilding(b, "demolish");
      this.economy.apply(refund, "demolish");
      for (const [k, v] of Object.entries(refund)) delta[k] = (delta[k] || 0) + v;
      ops.push({ op: "remove", building: b });
      removed.push(b);
    }
    if (removed.length) {
      this.commit({ label: "demolish", type: removed[0].type, ops, delta });
      this.emitRoads(removed);
    }
    return { ok: removed.length > 0, removed };
  }

  /** Undo the last action. Refused (nothing changes) when the money to give back is no longer there. @returns {{ ok: boolean, label?: string, code?: string }} */
  undo() {
    const tx = this.undoStack[this.undoStack.length - 1];
    if (!tx) return { ok: false, code: "nothing_to_undo" };
    const delta = negate(tx.delta);
    if (!this.economy.canApply(delta).ok) {
      this.events.emit("action.rejected", { action: "undo", code: "cannot_afford", reasons: [{ code: "cannot_afford", detail: { missing: this.economy.canApply(delta).missing } }] });
      return { ok: false, code: "cannot_afford" };
    }
    // a step that swaps a building for another (rotate) may find its own new building where the old one comes back
    const added = new Set(tx.ops.filter((o) => o.op === "add").map((o) => o.building.id));
    for (const op of tx.ops) {
      if (op.op === "add" && this.map.occupantAt(op.building.x, op.building.y) !== op.building.id) return { ok: false, code: "changed" };
      if (op.op === "remove" && footprintCells(this.data.buildings[op.building.type], op.building.x, op.building.y, op.building.rot).some(([c, r]) => this.map.occupantAt(c, r) && !added.has(this.map.occupantAt(c, r)))) return { ok: false, code: "changed" };
    }
    this.undoStack.pop();
    for (const op of [...tx.ops].reverse()) {
      if (op.op === "add") this.removeBuilding(op.building, "undo");
      else this.restoreBuilding(op.building, "undo");
    }
    this.economy.apply(delta, "undo");
    this.redoStack.push(tx);
    this.emitRoads(tx.ops.map((o) => o.building));
    this.emitHistory();
    return { ok: true, label: tx.label };
  }

  /** Redo the last undone action. @returns {{ ok: boolean, label?: string, code?: string }} */
  redo() {
    const tx = this.redoStack[this.redoStack.length - 1];
    if (!tx) return { ok: false, code: "nothing_to_redo" };
    if (!this.economy.canApply(tx.delta).ok) {
      this.events.emit("action.rejected", { action: "redo", code: "cannot_afford", reasons: [{ code: "cannot_afford", detail: { missing: this.economy.canApply(tx.delta).missing } }] });
      return { ok: false, code: "cannot_afford" };
    }
    const gone = new Set(tx.ops.filter((o) => o.op === "remove").map((o) => o.building.id));
    for (const op of tx.ops) {
      if (op.op === "add" && footprintCells(this.data.buildings[op.building.type], op.building.x, op.building.y, op.building.rot).some(([c, r]) => this.map.occupantAt(c, r) && !gone.has(this.map.occupantAt(c, r)))) return { ok: false, code: "changed" };
      if (op.op === "remove" && this.map.occupantAt(op.building.x, op.building.y) !== op.building.id) return { ok: false, code: "changed" };
    }
    this.redoStack.pop();
    for (const op of tx.ops) {
      if (op.op === "add") this.restoreBuilding(op.building, "redo");
      else this.removeBuilding(op.building, "redo");
    }
    this.economy.apply(tx.delta, "redo");
    this.undoStack.push(tx);
    this.emitRoads(tx.ops.map((o) => o.building));
    this.emitHistory();
    return { ok: true, label: tx.label };
  }

  // ---- internals ---------------------------------------------------------------------------------------------------

  /** Record a finished action: it is the new top of the undo stack and the redo stack is dropped. */
  commit(tx) {
    this.undoStack.push(tx);
    const limit = this.data.economy.undoLimit;
    if (this.undoStack.length > limit) this.undoStack.splice(0, this.undoStack.length - limit);
    this.redoStack.length = 0;
    this.emitHistory();
  }

  emitHistory() {
    const top = this.undoStack[this.undoStack.length - 1];
    const next = this.redoStack[this.redoStack.length - 1];
    this.events.emit("history.changed", {
      canUndo: !!top,
      canRedo: !!next,
      undoLabel: top ? top.label : null,
      redoLabel: next ? next.label : null,
    });
  }

  reject(action, reasons) {
    this.events.emit("action.rejected", { ...action, code: reasons[0].code, reasons });
    return { ok: false, reasons };
  }

  /** Create a new building (a fresh id) and mark its cells. */
  addBuilding(type, x, y, rot, cause) {
    const def = this.data.buildings[type];
    const [w, h] = sizeAt(def, rot);
    const building = { id: this.nextId++, type, x, y, rot, w, h };
    this.restoreBuilding(building, cause);
    return building;
  }

  /** Put a building (new or the same object undo/redo brings back) on the map and announce it. */
  restoreBuilding(building, cause) {
    this.buildings.set(building.id, building);
    for (const [c, r] of footprintCells(this.data.buildings[building.type], building.x, building.y, building.rot)) this.map.setOccupant(c, r, building.id);
    this.events.emit("building.placed", { building, cause });
  }

  removeBuilding(building, cause) {
    for (const [c, r] of footprintCells(this.data.buildings[building.type], building.x, building.y, building.rot)) this.map.setOccupant(c, r, 0);
    this.buildings.delete(building.id);
    this.events.emit("building.removed", { building, cause });
  }

  /** One "roads.changed" per action that added or removed a road, with the road cells and their neighbours to redraw. */
  emitRoads(buildings) {
    const cells = [];
    const seen = new Set();
    for (const b of buildings) {
      if (this.data.buildings[b.type].kind !== "road") continue;
      for (const [dc, dr] of [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const key = (b.y + dr) * 100000 + (b.x + dc);
        if (seen.has(key) || !this.map.inBounds(b.x + dc, b.y + dr)) continue;
        seen.add(key);
        cells.push([b.x + dc, b.y + dr]);
      }
    }
    if (cells.length) this.events.emit("roads.changed", { cells });
  }
}

/** @param {ConstructorParameters<typeof GameState>[0]} [options] */
export function createGame(options) {
  return new GameState(options);
}

export { roadPath };
