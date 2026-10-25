// @ts-check
// The lights of the mine that are not a miner's lamp: torches the miners place, glowing crystal walls (Crystal Caves) and magma.
//
// FactorIA draws at most 16 Light2D per frame (directional first, then the point lights nearest the camera) and says so only
// in `game.renderStats().lightsDropped`. A mine has dozens of crystals and a team can place six torches, so this module keeps
// its own POOL of Light2D entities and decides which sources are lit: the pool has 16 minus one per miner (the lamps are
// Light2D too), and each tick it gives the pool to the sources nearest to the miners. The ones left out are dark, as if
// far away; the engine never has to drop a light.
//
//   const lights = new Lights(map);   // shift.js makes one per shift
//   lights.update(dt);                // every frame
//   lights.placeTorch(playerId)       // true when a torch was put down (uses one of run.torches, tells the bus)
//   lights.sources                    // every source: {kind: "torch"|"crystal"|"magma", tx, ty, ...}
//   lights.lit                        // how many pool lights are on right now
//   lights.dispose();
import { world, audio } from "factoria";
import * as events from "./events.js";
import * as players from "./players.js";
import { K, TILE, SPRITE, spriteRegion, isDangerKind } from "./tiles.js";
import { run } from "./run_state.js";
import { miners } from "./actors.js";

/** The engine's cap on Light2D per frame (renderStats().lights never exceeds it). */
export const ENGINE_LIGHT_CAP = 16;

/** Look of each kind of source. */
export const LOOKS = Object.freeze({
  torch: { color: [1, 0.72, 0.35, 1], intensity: 1, radius: 72 },
  crystalBlue: { color: [0.45, 0.7, 1, 1], intensity: 0.85, radius: 56 },
  crystalViolet: { color: [0.78, 0.5, 1, 1], intensity: 0.85, radius: 56 },
  magma: { color: [1, 0.42, 0.18, 1], intensity: 0.9, radius: 52 },
});

/** Seconds between two rankings of the sources. */
const RANK_EVERY = 0.2;

/**
 * @typedef {object} Source
 * @property {"torch"|"crystal"|"magma"} kind
 * @property {number} tx
 * @property {number} ty
 * @property {number[]} color
 * @property {number} intensity
 * @property {number} radius
 */

export class Lights {
  /** @param {import("./mine_map.js").MineMap} map */
  constructor(map) {
    this.map = map;
    /** @type {Source[]} Every source, torches first. */
    this.sources = [];
    /** @type {{tx:number,ty:number,entity:any}[]} The torches placed. */
    this.torches = [];
    /** @type {{entity:any, source: Source|null}[]} */
    this.pool = [];
    this.clock = 0;
    this.sinceRank = 99;
    this.dirty = true;
    this.lit = 0;
    this.size = Math.max(1, ENGINE_LIGHT_CAP - Math.max(1, players.count()));
    for (let i = 0; i < this.size; i++) {
      const entity = world.spawn({ components: { Transform: { position: [0, 0, 0] }, Light2D: { type: "point", color: [1, 1, 1, 1], intensity: 0, radius: 1, falloff: 1.5, height: 40 } } });
      entity.active = false;
      this.pool.push({ entity, source: null });
    }
    this.scan();
    this.off = map.onChange((c) => {
      if (c.from === K.CRYSTAL || c.to === K.CRYSTAL || c.from === K.MAGMA || c.to === K.MAGMA) this.dirty = true;
    });
  }

  /** Collects the crystal and magma sources from the map (magma is thinned to one light per four tiles). */
  scan() {
    const map = this.map;
    const fixed = this.sources.filter((s) => s.kind === "torch");
    /** @type {Source[]} */
    const found = [];
    for (let ty = 0; ty < map.height; ty++) {
      for (let tx = 0; tx < map.width; tx++) {
        const kind = map.kindAt(tx, ty);
        if (kind === K.CRYSTAL) {
          const look = (tx + ty) % 2 === 0 ? LOOKS.crystalBlue : LOOKS.crystalViolet;
          found.push({ kind: "crystal", tx, ty, ...look, color: [...look.color] });
        } else if (kind === K.MAGMA && tx % 2 === 0 && ty % 2 === 0) {
          found.push({ kind: "magma", tx, ty, ...LOOKS.magma, color: [...LOOKS.magma.color] });
        }
      }
    }
    this.sources = [...fixed, ...found];
    this.dirty = false;
    this.sinceRank = 99;
  }

  /**
   * A miner puts a torch down on the tile it stands on. Fails (false) when the team has none left, the tile is not plain
   * floor (a lift, oil, water, magma, cracked floor), or a torch is already there.
   * @param {number} playerId
   */
  placeTorch(playerId) {
    const m = miners().find((a) => a.player.id === playerId);
    if (!m || run.torches <= 0) return false;
    const kind = this.map.kindAt(m.tx, m.ty);
    if (kind !== K.FLOOR || isDangerKind(kind) || this.torches.some((t) => t.tx === m.tx && t.ty === m.ty)) return false;
    const c = this.map.tileCenter(m.tx, m.ty);
    const entity = world.spawn({ components: { Transform: { position: [c.x, c.y, 0] }, Sprite: { texture: "assets/sprites.png", region: spriteRegion(SPRITE.TORCH), size: [TILE, TILE], layer: 7, lit: false } } });
    this.torches.push({ tx: m.tx, ty: m.ty, entity });
    this.sources.unshift({ kind: "torch", tx: m.tx, ty: m.ty, ...LOOKS.torch, color: [...LOOKS.torch.color] });
    run.torches -= 1;
    this.sinceRank = 99;
    events.emit("torchPlaced", { tx: m.tx, ty: m.ty, by: playerId, left: run.torches });
    audio.play("assets/audio/torch.wav", { volume: 0.7, bus: "sfx" });
    return true;
  }

  /** @param {number} dt */
  update(dt) {
    this.clock += dt;
    this.sinceRank += dt;
    if (this.dirty) this.scan();
    if (this.sinceRank >= RANK_EVERY) {
      this.sinceRank = 0;
      this.rank();
    }
    // torches flicker a little; everything else is steady
    for (const slot of this.pool) {
      const s = slot.source;
      if (s && s.kind === "torch" && slot.entity.alive) slot.entity.get("Light2D").intensity = s.intensity * (0.9 + 0.1 * Math.sin(this.clock * 13 + s.tx * 3));
    }
  }

  /** Gives the pool to the sources nearest to the miners; a source that keeps its place keeps its light entity. */
  rank() {
    const here = miners();
    const centres = here.length > 0 ? here : miners({ includeDown: true });
    const dist = (s) => {
      const c = this.map.tileCenter(s.tx, s.ty);
      let best = Infinity;
      for (const m of centres) best = Math.min(best, Math.hypot(m.x - c.x, m.y - c.y));
      return best;
    };
    const ranked = this.sources.map((s) => ({ s, d: centres.length > 0 ? dist(s) : 0 })).sort((a, b) => a.d - b.d).slice(0, this.size).map((r) => r.s);
    const keep = new Set(ranked);
    for (const slot of this.pool) if (slot.source && !keep.has(slot.source)) slot.source = null;
    const placed = new Set(this.pool.map((p) => p.source).filter(Boolean));
    const todo = ranked.filter((s) => !placed.has(s));
    for (const slot of this.pool) {
      if (!slot.source && todo.length > 0) slot.source = /** @type {Source} */ (todo.shift());
      const e = slot.entity;
      if (!e.alive) continue;
      if (!slot.source) {
        e.active = false;
        continue;
      }
      const s = slot.source;
      const c = this.map.tileCenter(s.tx, s.ty);
      e.active = true;
      e.position = [c.x, c.y, 0];
      e.set("Light2D", { color: s.color, intensity: s.intensity, radius: s.radius });
    }
    this.lit = this.pool.filter((p) => p.source).length;
  }

  dispose() {
    this.off();
    for (const slot of this.pool) if (slot.entity.alive) slot.entity.destroy();
    for (const t of this.torches) if (t.entity.alive) t.entity.destroy();
    this.pool = [];
    this.torches = [];
  }
}
