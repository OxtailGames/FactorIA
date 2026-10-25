// @ts-check
// One shift: builds the mine, puts it on the Tilemap, spawns the miners and the trapped moles, runs the clock and ends the shift
// when every miner stands on the exit lift ("lift") or every lamp has been out for a while ("dark"). Then the results scene.
// The scene needs one entity with this Script and a Tilemap entity named by `mineEntity`. Leave `rows` empty for a generated
// mine (the run's seed); give it rows of text (mine_ascii.js) for a handmade one, as scenes/test_mine.scene.json does.
import { Behaviour, world, scene } from "factoria";
import * as players from "./players.js";
import * as events from "./events.js";
import { generate } from "./generator.js";
import { fromRows } from "./mine_ascii.js";
import { MineMap, live } from "./mine_map.js";
import { tileIndex, TILE } from "./tiles.js";
import { run, startRun, beginShift, endShift, lampOf } from "./run_state.js";
import * as saveFile from "./save.js";

/** Seconds every lamp has to stay out before the shift ends in the dark. */
export const DARK_GRACE = 2;

export default class Shift extends Behaviour {
  /** Id of the Tilemap entity that shows the mine. */
  mineEntity = "mine";
  /** Rows of text for a handmade mine; empty = generate one from the run seed. */
  rows = [];
  /** Scene that shows the results. */
  resultsScene = "scenes/results.scene.json";
  /** Seconds between the end of the shift and the results scene. */
  endDelay = 1.6;
  /** Prefab of a miner and of a trapped mole. */
  minerPrefab = "prefabs/miner.prefab.json";
  molePrefab = "prefabs/mole.prefab.json";

  onStart() {
    this.sceneName = scene.current;
    this.ended = false;
    this.darkFor = 0;
    if (!run.active) startRun(); // a scene opened directly (the editor, a test) starts a run of its own
    const seed = beginShift();
    const hasRows = Array.isArray(this.rows) && this.rows.length > 0;
    this.mine = hasRows ? fromRows(this.rows, { seed, stratum: run.stratum, floor: run.floor }) : generate(seed, run.stratum, run.floor);
    this.map = new MineMap(this.mine);
    live.map = this.map;
    live.mine = this.mine;
    run.molesTotal = this.mine.moles.length;

    this.mapEntity = world.find(this.mineEntity);
    if (!this.mapEntity) throw new Error(`shift: no entity with id '${this.mineEntity}' (the Tilemap that shows the mine). Add one to the scene, or set the Shift script's 'mineEntity' prop.`);
    this.tiles = new Array(this.mine.width * this.mine.height);
    for (let ty = 0; ty < this.mine.height; ty++) {
      for (let tx = 0; tx < this.mine.width; tx++) this.tiles[ty * this.mine.width + tx] = tileIndex(this.map.kindAt(tx, ty), tx, ty);
    }
    this.mapEntity.set("Tilemap", { tileset: "assets/tiles.png", tileSize: [TILE, TILE], width: this.mine.width, height: this.mine.height, tiles: this.tiles });
    this.mapEntity.position = [0, 0, 0];
    this.dirty = false;
    this.unsubscribe = this.map.onChange((c) => {
      this.tiles[c.ty * this.mine.width + c.tx] = tileIndex(c.to, c.tx, c.ty);
      this.dirty = true; // several tiles may change in one frame: the Tilemap is rewritten once, in onLateUpdate
    });

    const list = players.all();
    list.forEach((p, i) => {
      const spot = this.mine.spawns.length > 0 ? this.mine.spawns[i % this.mine.spawns.length] : this.mine.start;
      const c = this.map.tileCenter(spot.tx, spot.ty);
      world.spawnPrefab(this.minerPrefab, { position: [c.x, c.y, 0], props: { playerId: p.id } });
    });
    for (const m of this.mine.moles) {
      const c = this.map.tileCenter(m.tx, m.ty);
      world.spawnPrefab(this.molePrefab, { position: [c.x, c.y, 0], props: { tx: m.tx, ty: m.ty } });
    }
    events.emit("shiftStarted", { seed, stratum: run.stratum, floor: run.floor, hash: this.mine.hash, players: list.length });
  }

  onUpdate(dt) {
    if (this.ended || !run.inShift) return;
    run.shiftTime += dt;
    const alive = players.alive();
    if (alive.length === 0) return; // nobody to wait for (P2 ends the shift when every miner is down)
    if (alive.every((p) => p.state === "lift")) {
      this.finish("lift");
      return;
    }
    if (alive.every((p) => lampOf(p.id).out)) {
      this.darkFor += dt;
      if (this.darkFor >= DARK_GRACE) this.finish("dark");
    } else {
      this.darkFor = 0;
    }
  }

  onLateUpdate() {
    if (this.dirty && this.mapEntity?.alive) {
      this.dirty = false;
      this.mapEntity.set("Tilemap", { tiles: this.tiles });
    }
  }

  /**
   * Ends the shift now (the end conditions call this; a test can too).
   * @param {"lift"|"dark"} outcome
   */
  finish(outcome) {
    if (this.ended) return;
    this.ended = true;
    const summary = endShift(outcome);
    saveFile.save();
    events.emit("shiftEnded", { ...summary });
    this.after(this.endDelay, () => {
      if (scene.current !== this.sceneName) return; // the player left (pause menu) while the delay ran
      scene.load(this.resultsScene);
    });
  }

  onDestroy() {
    this.unsubscribe?.();
    run.inShift = false;
    live.map = null;
    live.mine = null;
  }
}
