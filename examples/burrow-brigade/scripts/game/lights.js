// @ts-check
// The lights of the mine that are not a miner's lamp: torches the miners place, glowing crystal walls (Crystal Caves) and magma.
//
// Every source has its own Light2D entity, lit all the time. The engine draws the lights that reach the view (its light buffer
// holds up to 256 per frame and `renderStats().lights2d` counts them) and drops the ones off screen for free, so a mine with
// dozens of crystals and a team with six torches need no choosing of which sources shine.
//
//   const lights = new Lights(map);   // shift.js makes one per shift
//   lights.update(dt);                // every frame
//   lights.placeTorch(playerId)       // true when a torch was put down (uses one of run.torches, tells the bus)
//   lights.sources                    // every source: {kind: "torch"|"crystal"|"magma", tx, ty, entity, ...}
//   lights.lit                        // how many sources have a light on right now (all of them)
//   lights.dispose();
import { world } from "factoria";
import * as sound from "./sound.js";
import { reducedFlashing } from "../settings.js";
import * as events from "./events.js";
import { K, TILE, SPRITE, spriteRegion, isDangerKind } from "./tiles.js";
import { run } from "./run_state.js";
import { miners } from "./actors.js";

/** Look of each kind of source. */
export const LOOKS = Object.freeze({
  torch: { color: [1, 0.72, 0.35, 1], intensity: 1, radius: 72 },
  crystalBlue: { color: [0.45, 0.7, 1, 1], intensity: 0.85, radius: 56 },
  crystalViolet: { color: [0.78, 0.5, 1, 1], intensity: 0.85, radius: 56 },
  magma: { color: [1, 0.42, 0.18, 1], intensity: 0.9, radius: 52 },
});

/**
 * @typedef {object} Source
 * @property {"torch"|"crystal"|"magma"} kind
 * @property {number} tx
 * @property {number} ty
 * @property {number[]} color
 * @property {number} intensity
 * @property {number} radius
 * @property {any} [entity]   The Light2D entity of the source.
 */

export class Lights {
  /** @param {import("./mine_map.js").MineMap} map */
  constructor(map) {
    this.map = map;
    /** @type {Source[]} Every source, torches first. */
    this.sources = [];
    /** @type {{tx:number,ty:number,entity:any}[]} The torches placed. */
    this.torches = [];
    this.clock = 0;
    this.dirty = true;
    this.scan();
    this.off = map.onChange((c) => {
      if (c.from === K.CRYSTAL || c.to === K.CRYSTAL || c.from === K.MAGMA || c.to === K.MAGMA) this.dirty = true;
    });
  }

  /**
   * The Light2D entity of a source, at the centre of its tile.
   * @param {Source} s
   */
  light(s) {
    const c = this.map.tileCenter(s.tx, s.ty);
    return world.spawn({
      components: { Transform: { position: [c.x, c.y, 0] }, Light2D: { type: "point", color: s.color, intensity: s.intensity, radius: s.radius, falloff: 1.5, height: 40 } },
    });
  }

  /** Collects the crystal and magma sources from the map (magma is thinned to one light per four tiles); a source still there keeps its light. */
  scan() {
    const map = this.map;
    const fixed = this.sources.filter((s) => s.kind === "torch");
    const before = new Map(this.sources.filter((s) => s.kind !== "torch").map((s) => [`${s.kind}:${s.tx},${s.ty}`, s]));
    /** @type {Source[]} */
    const found = [];
    for (let ty = 0; ty < map.height; ty++) {
      for (let tx = 0; tx < map.width; tx++) {
        const kind = map.kindAt(tx, ty);
        /** @type {Source|null} */
        let s = null;
        if (kind === K.CRYSTAL) {
          const look = (tx + ty) % 2 === 0 ? LOOKS.crystalBlue : LOOKS.crystalViolet;
          s = { kind: "crystal", tx, ty, ...look, color: [...look.color] };
        } else if (kind === K.MAGMA && tx % 2 === 0 && ty % 2 === 0) {
          s = { kind: "magma", tx, ty, ...LOOKS.magma, color: [...LOOKS.magma.color] };
        }
        if (!s) continue;
        const key = `${s.kind}:${tx},${ty}`;
        const old = before.get(key);
        if (old) {
          before.delete(key);
          found.push(old);
        } else {
          s.entity = this.light(s);
          found.push(s);
        }
      }
    }
    for (const gone of before.values()) if (gone.entity?.alive) gone.entity.destroy();
    this.sources = [...fixed, ...found];
    this.dirty = false;
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
    /** @type {Source} */
    const source = { kind: "torch", tx: m.tx, ty: m.ty, ...LOOKS.torch, color: [...LOOKS.torch.color] };
    source.entity = this.light(source);
    this.sources.unshift(source);
    run.torches -= 1;
    events.emit("torchPlaced", { tx: m.tx, ty: m.ty, by: playerId, left: run.torches });
    sound.play("assets/audio/torch.wav", { volume: 0.7 });
    return true;
  }

  /** @param {number} dt */
  update(dt) {
    this.clock += dt;
    if (this.dirty) this.scan();
    // Magma breathes (a slow pulse, about 0.4 times a second) and torches flicker (about 2 times a second). With reduced flashing
    // (Options > Access) both are nearly steady, so nothing in the mine changes brightness quickly or strongly. Crystals are steady.
    const calm = reducedFlashing();
    for (const s of this.sources) {
      if (!s.entity?.alive) continue;
      if (s.kind === "torch") s.entity.get("Light2D").intensity = s.intensity * (1 - (calm ? 0.02 : 0.1) + (calm ? 0.02 : 0.1) * Math.sin(this.clock * 13 + s.tx * 3));
      else if (s.kind === "magma") s.entity.get("Light2D").intensity = s.intensity * (1 + (calm ? 0.04 : 0.3) * Math.sin(this.clock * 2.5 + s.tx * 0.7 + s.ty * 0.5));
    }
  }

  /** How many sources have a light on right now: every source does. */
  get lit() {
    return this.sources.filter((s) => s.entity?.alive).length;
  }

  dispose() {
    this.off();
    for (const s of this.sources) if (s.entity?.alive) s.entity.destroy();
    for (const t of this.torches) if (t.entity.alive) t.entity.destroy();
    this.sources = [];
    this.torches = [];
  }
}
