// @ts-check
// The hazards of the mine: spreading water, magma and cave-ins. They are read off the MAP, not off `mine.hazards`, so a
// handmade mine (mine_ascii.js: w water, M magma, x cracked floor) behaves exactly like a generated one.
//
//   const hazards = new Hazards(map);      // shift.js makes one per shift
//   hazards.update(dt);                    // every frame
//   hazards.speedFactor(tile)              // 0.5 on water, else 1 (miner.js walks slower in water)
//   hazards.dispose();
//
// Water and magma: a group is a set of connected fluid tiles. A sealed pocket does nothing until a miner digs the wall in
// front of it. Once a group touches open floor it spreads, a few tiles every `WATER_WAVE` / `MAGMA_WAVE` seconds, over floor
// tiles only (never into a wall, the lifts, an oil can), until its budget (the pocket's `volume`, or 12 water / 8 magma
// tiles for a pocket the generator did not describe) is used up. A pool of magma has no budget: it never spreads.
//  - A miner in water drowns after `DROWN_TIME` seconds there (the clock runs back at half speed out of it), so water is a
//    delay, not a wall. A miner on magma burns after `BURN_TIME` seconds: a single tile can be crossed at a run, two cannot.
// Cave-ins: stepping on a cracked tile (K.SHAKY) starts one. `CAVE_WARNING` seconds later (warning signs on the 3 x 3 tiles
// around it, then rocks falling) every floor tile of that 3 x 3 becomes rock, a miner inside it goes down, an enemy inside
// is hurt. A miner on the exit lift is safe.
// Every step tells the bus (`hazardTriggered`, and `playerDown` with the cause "drowned", "burned" or "caveIn").
import { world, audio } from "factoria";
import * as events from "./events.js";
import * as players from "./players.js";
import { K, TILE, SPRITE, spriteRegion } from "./tiles.js";
import { run } from "./run_state.js";
import { miners } from "./actors.js";

/** Seconds between two waves of spreading water / magma. */
export const WATER_WAVE = 1.2;
export const MAGMA_WAVE = 2.2;
/** Most tiles one wave takes. */
export const WAVE_TILES = 3;
/** Seconds in water before a miner drowns, and on magma before one burns. */
export const DROWN_TIME = 3.5;
export const BURN_TIME = 0.5;
/** Speed multiplier in water. */
export const WATER_SLOW = 0.5;
/** Seconds from stepping on a cracked tile to the rocks falling. */
export const CAVE_WARNING = 1.4;
/**
 * The numbers the hazards use while a shift runs. They start as the constants above; balance.js (remote balance values) may change
 * them between shifts, so read `TUNING.x` and not the constant.
 */
export const TUNING = {
  waterWave: WATER_WAVE, magmaWave: MAGMA_WAVE, waveTiles: WAVE_TILES, drownTime: DROWN_TIME,
  burnTime: BURN_TIME, waterSlow: WATER_SLOW, caveWarning: CAVE_WARNING,
};
/** Tiles a pocket without a generator description can spread over. */
export const DEFAULT_VOLUME = { water: 12, magma: 8 };
/** Damage a cave-in does to an enemy under it. */
export const CAVE_DAMAGE = 3;

const STEPS = [[1, 0], [-1, 0], [0, 1], [0, -1]];
/** Kinds a fluid may spread over. */
const SPREADABLE = new Set([K.FLOOR]);

/**
 * @typedef {object} FluidGroup
 * @property {"flood"|"magma"} kind
 * @property {number} tileKind     K.WATER or K.MAGMA.
 * @property {Set<number>} tiles   Tile ids (ty * width + tx) of the group.
 * @property {number} budget       Tiles it may still take.
 * @property {number} timer        Seconds to the next wave.
 * @property {boolean} open        True once it touched open floor (it started to spread).
 * @property {{tx:number,ty:number}} origin
 */

export class Hazards {
  /**
   * @param {import("./mine_map.js").MineMap} map
   */
  constructor(map) {
    this.map = map;
    /** @type {FluidGroup[]} */
    this.groups = [];
    /** @type {Array<{tx:number,ty:number,t:number,signs:any[],rocks:any[],fell:boolean,by:number}>} */
    this.caveIns = [];
    /** @type {Map<number, {water:number, magma:number}>} Exposure of each miner, by player id. */
    this.exposure = new Map();
    /** Seconds the hazards have run. */
    this.clock = 0;
    this.scan();
    this.off = map.onChange((c) => {
      // a fluid tile that was dug out, picked up or replaced by something else leaves its group; new fluid belongs to the one that made it
      if (c.from === K.WATER || c.from === K.MAGMA) for (const g of this.groups) g.tiles.delete(c.ty * map.width + c.tx);
    });
  }

  /** Finds the fluid groups on the map (a flood fill over connected tiles of the same fluid). */
  scan() {
    const map = this.map;
    const seen = new Set();
    const hazards = map.mine.hazards ?? [];
    for (let ty = 0; ty < map.height; ty++) {
      for (let tx = 0; tx < map.width; tx++) {
        const kind = map.kindAt(tx, ty);
        const id = ty * map.width + tx;
        if ((kind !== K.WATER && kind !== K.MAGMA) || seen.has(id)) continue;
        const tiles = new Set([id]);
        seen.add(id);
        const stack = [[tx, ty]];
        while (stack.length) {
          const [x, y] = /** @type {number[]} */ (stack.pop());
          for (const [dx, dy] of STEPS) {
            const n = (y + dy) * map.width + (x + dx);
            if (!map.inBounds(x + dx, y + dy) || seen.has(n) || map.kindAt(x + dx, y + dy) !== kind) continue;
            seen.add(n);
            tiles.add(n);
            stack.push([x + dx, y + dy]);
          }
        }
        const described = hazards.find((h) => h.tiles && h.tiles.some((t) => tiles.has(t.ty * map.width + t.tx)));
        const water = kind === K.WATER;
        const budget = described && typeof described.volume === "number" ? described.volume : water ? DEFAULT_VOLUME.water : DEFAULT_VOLUME.magma;
        this.groups.push({ kind: water ? "flood" : "magma", tileKind: kind, tiles, budget, timer: water ? TUNING.waterWave : TUNING.magmaWave, open: false, origin: { tx, ty } });
      }
    }
  }

  /** Stops listening and removes the warning signs and falling rocks. */
  dispose() {
    this.off();
    for (const c of this.caveIns) this.clearCave(c);
    this.caveIns = [];
  }

  /** Speed multiplier for a miner on this tile: slower in water. */
  speedFactor(tx, ty) {
    return this.map.kindAt(tx, ty) === K.WATER ? TUNING.waterSlow : 1;
  }

  /** Seconds of exposure of a player: `{water, magma}` (a test and HUD helper). */
  exposureOf(id) {
    return this.exposure.get(id) ?? { water: 0, magma: 0 };
  }

  /** True when a cave-in is counting down. */
  get collapsing() {
    return this.caveIns.length > 0;
  }

  /** @param {number} dt */
  update(dt) {
    if (!run.inShift) return;
    this.clock += dt;
    const here = miners();
    this.spread(dt);
    this.exposeMiners(here, dt);
    this.triggerCaveIns(here);
    this.tickCaveIns(dt, here);
  }

  // ---- water and magma ----------------------------------------------------------------------------------------------

  /** The floor tiles a group could spread to now, nearest to where it started first. */
  frontier(g) {
    const map = this.map;
    /** @type {{tx:number,ty:number,d:number}[]} */
    const out = [];
    const seen = new Set();
    for (const id of g.tiles) {
      const x = id % map.width, y = (id - x) / map.width;
      for (const [dx, dy] of STEPS) {
        const nx = x + dx, ny = y + dy, n = ny * map.width + nx;
        if (seen.has(n) || !map.inBounds(nx, ny) || g.tiles.has(n) || !SPREADABLE.has(map.kindAt(nx, ny))) continue;
        seen.add(n);
        out.push({ tx: nx, ty: ny, d: Math.abs(nx - g.origin.tx) + Math.abs(ny - g.origin.ty) });
      }
    }
    return out.sort((a, b) => a.d - b.d || a.ty - b.ty || a.tx - b.tx);
  }

  spread(dt) {
    const map = this.map;
    for (const g of this.groups) {
      if (g.budget <= 0 || g.tiles.size === 0) continue;
      const front = this.frontier(g);
      if (front.length === 0) continue; // sealed (or boxed in)
      if (!g.open) {
        g.open = true;
        g.timer = 0.35; // the first trickle comes quickly, then the waves
        const t = front[0];
        events.emit("hazardTriggered", { kind: g.kind, tx: t.tx, ty: t.ty, phase: "start" });
        audio.play(g.kind === "flood" ? "assets/audio/splash.wav" : "assets/audio/sizzle.wav", { volume: 0.7, bus: "sfx" });
      }
      g.timer -= dt;
      if (g.timer > 0) continue;
      g.timer = g.kind === "flood" ? TUNING.waterWave : TUNING.magmaWave;
      const take = Math.min(TUNING.waveTiles, g.budget, front.length);
      for (let i = 0; i < take; i++) {
        const t = front[i];
        map.setKind(t.tx, t.ty, g.tileKind, g.kind);
        g.tiles.add(t.ty * map.width + t.tx);
        g.budget--;
      }
      events.emit("hazardTriggered", { kind: g.kind, tx: front[0].tx, ty: front[0].ty, phase: "spread", tiles: take });
    }
  }

  /** Counts the seconds each miner has stood in water or on magma and puts down the ones who stayed too long. */
  exposeMiners(here, dt) {
    const map = this.map;
    for (const m of here) {
      if (m.player.state !== "active") continue;
      const e = this.exposure.get(m.player.id) ?? { water: 0, magma: 0 };
      this.exposure.set(m.player.id, e);
      const kind = map.kindAt(m.tx, m.ty);
      e.water = kind === K.WATER ? e.water + dt : Math.max(0, e.water - dt * 0.5);
      e.magma = kind === K.MAGMA ? e.magma + dt : Math.max(0, e.magma - dt * 2);
      if (e.water >= TUNING.drownTime) this.putDown(m, "flood", "drowned");
      else if (e.magma >= TUNING.burnTime) this.putDown(m, "magma", "burned");
    }
  }

  putDown(m, kind, cause) {
    this.exposure.delete(m.player.id);
    events.emit("hazardTriggered", { kind, tx: m.tx, ty: m.ty, phase: "hit", player: m.player.id });
    players.setState(m.player.id, "down", cause);
    audio.play(kind === "magma" ? "assets/audio/sizzle.wav" : "assets/audio/splash.wav", { volume: 0.8, bus: "sfx" });
  }

  // ---- cave-ins -------------------------------------------------------------------------------------------------------

  /** A miner on a cracked tile starts its cave-in (once per tile). */
  triggerCaveIns(here) {
    const map = this.map;
    for (const m of here) {
      if (m.player.state !== "active" || map.kindAt(m.tx, m.ty) !== K.SHAKY) continue;
      if (this.caveIns.some((c) => c.tx === m.tx && c.ty === m.ty)) continue;
      const cave = { tx: m.tx, ty: m.ty, t: 0, signs: /** @type {any[]} */ ([]), rocks: /** @type {any[]} */ ([]), fell: false, by: m.player.id };
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          if (map.isSolid(m.tx + dx, m.ty + dy)) continue;
          const c = map.tileCenter(m.tx + dx, m.ty + dy);
          cave.signs.push(world.spawn({ components: { Transform: { position: [c.x, c.y, 0] }, Sprite: { texture: "assets/sprites.png", region: spriteRegion(SPRITE.WARNING), size: [TILE, TILE], layer: 16, color: [1, 1, 1, 0.9] } } }));
        }
      }
      this.caveIns.push(cave);
      events.emit("hazardTriggered", { kind: "caveIn", tx: m.tx, ty: m.ty, phase: "start", player: m.player.id });
      audio.play("assets/audio/rumble.wav", { volume: 0.8, bus: "sfx" });
    }
  }

  tickCaveIns(dt, here) {
    for (const cave of [...this.caveIns]) {
      cave.t += dt;
      const blink = Math.floor(cave.t * 6) % 2 === 0;
      for (const s of cave.signs) if (s.alive) s.get("Sprite").color = [1, 1, 1, blink ? 0.95 : 0.4];
      // the rocks drop in the last third of a second
      const fall = Math.max(0, Math.min(1, (cave.t - (TUNING.caveWarning - 0.3)) / 0.3));
      if (fall > 0 && cave.rocks.length === 0) {
        for (const s of cave.signs) {
          if (!s.alive) continue;
          cave.rocks.push(world.spawn({ components: { Transform: { position: [s.position.x, s.position.y + 40, 0] }, Sprite: { texture: "assets/sprites.png", region: spriteRegion(SPRITE.ROCK), size: [TILE, TILE], layer: 22 } } }));
        }
      }
      cave.rocks.forEach((r, i) => {
        if (r.alive) r.position.y = cave.signs[i].position.y + 40 * (1 - fall);
      });
      if (cave.t >= TUNING.caveWarning) this.collapse(cave, here);
    }
  }

  /** The rocks land. */
  collapse(cave, here) {
    const map = this.map;
    const tiles = [];
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        const tx = cave.tx + dx, ty = cave.ty + dy;
        if (!map.inBounds(tx, ty)) continue;
        tiles.push({ tx, ty });
      }
    }
    for (const m of miners()) {
      if (m.player.state !== "active") continue; // a miner on the lift is safe
      if (Math.abs(m.tx - cave.tx) <= 1 && Math.abs(m.ty - cave.ty) <= 1) this.putDown(m, "caveIn", "caveIn");
    }
    for (const t of tiles) {
      const kind = map.kindAt(t.tx, t.ty);
      if (kind === K.FLOOR || kind === K.SHAKY || kind === K.WATER || kind === K.MAGMA) map.setKind(t.tx, t.ty, K.ROCK, "caveIn");
    }
    events.emit("hazardTriggered", { kind: "caveIn", tx: cave.tx, ty: cave.ty, phase: "impact", tiles: tiles.length });
    audio.play("assets/audio/crash.wav", { volume: 0.9, bus: "sfx" });
    this.clearCave(cave);
    this.caveIns = this.caveIns.filter((c) => c !== cave);
  }

  clearCave(cave) {
    for (const e of [...cave.signs, ...cave.rocks]) if (e.alive) e.destroy();
    cave.signs = [];
    cave.rocks = [];
  }
}
