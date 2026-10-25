// @ts-check
// The "busiest floor" set-up: a scene that needs no input and no menu. It registers four miners on four keyboard blocks (no pad
// has to be plugged in; `devices: "pads"` gives them four gamepads instead, for the store replays), starts a run on a fixed stratum, floor and seed, and lets the Shift script of the same scene build the
// mine. Then it puts the whole team in the part of the mine with the most glowing crystal or magma and puts the team's torches
// down around them, so the renderer has everything it will ever have to draw on one floor: four lamps, the torches, the
// crystals or magma, the enemies, the fog of war and the HUD. Used by perf.json, by the ctest perf file and by the render
// budget test; the store screenshots start from it too.
//
// It must sit BEFORE the `shift` entity in the scene: the Shift script reads the run state in its own onStart.
import { Behaviour, world } from "factoria";
import * as players from "./players.js";
import { startRun, run } from "./run_state.js";
import { live } from "./mine_map.js";
import { K } from "./tiles.js";

/** The four seats, each on its own device so nothing needs a gamepad. */
const KEY_DEVICES = [{ kind: "any" }, { kind: "keys", scheme: "arrows" }, { kind: "keys", scheme: "wasd" }, { kind: "keys", scheme: "ijkl" }];
const PAD_DEVICES = [0, 1, 2, 3].map((index) => ({ kind: "pad", index }));

/** Floor tiles within `radius` tiles of (tx, ty) that count as light: crystal walls and magma. */
function glow(map, tx, ty, radius) {
  let n = 0;
  for (let y = ty - radius; y <= ty + radius; y++) {
    for (let x = tx - radius; x <= tx + radius; x++) {
      const k = map.kindAt(x, y);
      if (k === K.CRYSTAL || k === K.MAGMA) n++;
    }
  }
  return n;
}

/**
 * Props a test or a script sets before the scene loads (they win over the scene's own props): `override.stratum = 2`.
 * @type {{stratum?: number, floor?: number, seed?: number, miners?: number, devices?: string, staged?: boolean}}
 */
export const override = {};

export default class Busiest extends Behaviour {
  /** Depth band: 0 Topsoil, 1 Crystal Caves, 2 Magma Deep. */
  stratum = 1;
  /** Floor within the stratum (1 to 3). */
  floor = 3;
  /** Run seed: the same seed gives the same mine on every machine. */
  seed = 1234;
  /** Miners (1 to 4). */
  miners = 4;
  /** "keys": the four keyboard blocks (nothing to plug in); "pads": gamepads 0 to 3. */
  devices = "keys";
  /** True: gather the team where the light is and put the torches down (the busiest floor). False: only start the run, the miners stay at the lift (the store replays play from there). */
  staged = true;
  /** Seconds the set-up takes after the shift began (the torches go down one every few frames). */
  frames = 0;

  onStart() {
    Object.assign(this, override);
    players.clear();
    const devices = this.devices === "pads" ? PAD_DEVICES : KEY_DEVICES;
    for (let i = 0; i < Math.min(4, Math.max(1, this.miners)); i++) players.add({ device: /** @type {any} */ (devices[i]) });
    startRun({ seed: this.seed, stratum: this.stratum, floor: this.floor });
    this.step = 0;
    this.ready = false;
    this.spots = [];
  }

  onUpdate() {
    const map = live.map;
    if (!map || !live.lights) return;
    this.frames++;
    if (!this.staged) return;
    if (this.step === 0) {
      // the best place: the floor tile with the most light sources around it, then the floor tiles nearest to it
      let best = { tx: live.mine.start.tx, ty: live.mine.start.ty, n: -1 };
      for (let ty = 1; ty < map.height - 1; ty++) {
        for (let tx = 1; tx < map.width - 1; tx++) {
          if (map.kindAt(tx, ty) !== K.FLOOR) continue;
          const n = glow(map, tx, ty, 5);
          if (n > best.n) best = { tx, ty, n };
        }
      }
      const floorTiles = [];
      for (let ty = best.ty - 6; ty <= best.ty + 6; ty++) {
        for (let tx = best.tx - 6; tx <= best.tx + 6; tx++) if (map.kindAt(tx, ty) === K.FLOOR) floorTiles.push({ tx, ty, d: Math.hypot(tx - best.tx, ty - best.ty) });
      }
      floorTiles.sort((a, b) => a.d - b.d || a.ty - b.ty || a.tx - b.tx);
      this.spots = floorTiles;
      this.step = 1;
      return;
    }
    if (this.step >= 1 && this.step <= 2 * run.upgrades.torches) {
      // one torch every second frame: a miner stands on the next spot (every other tile, so the torches spread), the torch goes down
      const idx = this.step;
      if (idx % 2 === 1) {
        const k = (idx - 1) / 2;
        const spot = this.spots[Math.min(this.spots.length - 1, k * 3 + 1)];
        const id = k % players.count();
        const miner = players.get(id);
        const ent = miner ? this.minerEntity(id) : null;
        if (ent && spot) {
          const c = map.tileCenter(spot.tx, spot.ty);
          ent.position = [c.x, c.y, 0];
        }
      } else {
        live.lights.placeTorch((((idx / 2) - 1) % players.count()));
      }
      this.step++;
      return;
    }
    if (this.step === 2 * run.upgrades.torches + 1) {
      // the team gathers around the middle of the spot
      for (let i = 0; i < players.count(); i++) {
        const ent = this.minerEntity(i);
        const spot = this.spots[Math.min(this.spots.length - 1, i * 2)];
        if (ent && spot) {
          const c = map.tileCenter(spot.tx, spot.ty);
          ent.position = [c.x, c.y, 0];
        }
      }
      this.step++;
      this.ready = true;
    }
  }

  minerEntity(playerId) {
    return world.findByTag("miner").find((e) => e.behaviour && e.behaviour.playerId === playerId) ?? null;
  }
}
