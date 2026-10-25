// @ts-check
// One shift: builds the mine, puts it on the Tilemap, spawns the miners, the trapped moles and the enemies, runs the hazards,
// the lights and the fog of war, keeps the clock and ends the shift: "lift" when every miner in play stands on the exit lift,
// "dark" when every lamp has been out for a while, "allDown" when every miner is down. Then the results scene.
// The scene needs one entity with this Script and a Tilemap entity named by `mineEntity`. Leave `rows` empty for a generated
// mine (the run's seed); give it rows of text (mine_ascii.js) for a handmade one, as scenes/test_mine.scene.json does.
// The stratum decides the tileset, the ambient light and the music (generator.js STRATA); the floor decides the mine.
import { Behaviour, world, scene } from "factoria";
import * as players from "./players.js";
import * as events from "./events.js";
import { generate, stratumInfo } from "./generator.js";
import { fromRows } from "./mine_ascii.js";
import { MineMap, live } from "./mine_map.js";
import { tileIndex, tilesetOf, TILE } from "./tiles.js";
import { run, startRun, beginShift, endShift, lampOf } from "./run_state.js";
import { navFor } from "./pathfinding.js";
import { Hazards } from "./hazards.js";
import { Lights } from "./lights.js";
import { Fog } from "./fog.js";
import * as music from "./music.js";
import * as saveFile from "./save.js";
import * as revive from "./revive.js";
import * as daily from "./daily.js";
import { plan } from "./progression.js";

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
  /** Prefab of a miner, of a trapped mole and of an enemy. */
  minerPrefab = "prefabs/miner.prefab.json";
  molePrefab = "prefabs/mole.prefab.json";
  enemyPrefab = "prefabs/enemy.prefab.json";

  onStart() {
    this.sceneName = scene.current;
    this.ended = false;
    this.darkFor = 0;
    if (!run.active) startRun(); // a scene opened directly (the editor, a test) starts a run of its own
    const seed = beginShift();
    const hasRows = Array.isArray(this.rows) && this.rows.length > 0;
    this.mine = hasRows ? fromRows(this.rows, { seed, stratum: run.stratum, floor: run.floor }) : generate(seed, run.stratum, run.floor);
    revive.reset();
    this.map = new MineMap(this.mine);
    live.map = this.map;
    live.mine = this.mine;
    live.nav = navFor(this.map);
    run.molesTotal = this.mine.moles.length;
    run.exitLocked = this.mine.boss; // the Mole King jams the exit lift until it falls

    // the look of the stratum
    const stratum = stratumInfo(run.stratum);
    world.settings.ambientLight = stratum.ambient;
    music.play(run.stratum);

    this.mapEntity = world.find(this.mineEntity);
    if (!this.mapEntity) throw new Error(`shift: no entity with id '${this.mineEntity}' (the Tilemap that shows the mine). Add one to the scene, or set the Shift script's 'mineEntity' prop.`);
    this.tiles = new Array(this.mine.width * this.mine.height);
    for (let ty = 0; ty < this.mine.height; ty++) {
      for (let tx = 0; tx < this.mine.width; tx++) this.tiles[ty * this.mine.width + tx] = tileIndex(this.map.kindAt(tx, ty), tx, ty);
    }
    this.mapEntity.set("Tilemap", { tileset: tilesetOf(run.stratum), tileSize: [TILE, TILE], width: this.mine.width, height: this.mine.height, tiles: this.tiles });
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
    for (const e of this.mine.enemies) {
      const c = this.map.tileCenter(e.tx, e.ty);
      world.spawnPrefab(this.enemyPrefab, { position: [c.x, c.y, 0], props: { kind: e.kind, tx: e.tx, ty: e.ty } });
    }

    this.hazards = new Hazards(this.map);
    this.lights = new Lights(this.map);
    this.fog = new Fog(this.map);
    live.hazards = this.hazards;
    live.lights = this.lights;
    live.fog = this.fog;
    events.emit("shiftStarted", { seed, stratum: run.stratum, floor: run.floor, hash: this.mine.hash, players: list.length });
  }

  onUpdate(dt) {
    if (this.ended || !run.inShift) return;
    run.shiftTime += dt;
    this.hazards.update(dt);
    revive.update(dt);
    this.lights.update(dt);
    this.fog.update(dt, { torches: this.lights.torches });
    const alive = players.alive();
    if (alive.length === 0) {
      if (players.count() > 0) this.finish("allDown");
      return;
    }
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
   * @param {"lift"|"dark"|"allDown"} outcome
   */
  finish(outcome) {
    if (this.ended) return;
    this.ended = true;
    const summary = endShift(outcome);
    // the save keeps the NEXT floor, so Continue lands in the camp that comes before it (a victory starts over at the results)
    const next = plan(summary);
    if (next.kind !== "victory") saveFile.save({ stratum: next.stratum, floor: next.floor });
    if (run.mode === "daily") daily.noteShift(summary, next.kind === "victory");
    events.emit("shiftEnded", { ...summary });
    this.after(this.endDelay, () => {
      if (scene.current !== this.sceneName) return; // the player left (pause menu) while the delay ran
      scene.load(this.resultsScene);
    });
  }

  onDestroy() {
    this.unsubscribe?.();
    this.hazards?.dispose();
    this.lights?.dispose();
    this.fog?.dispose();
    revive.reset();
    run.inShift = false;
    live.map = null;
    live.mine = null;
    live.nav = null;
    live.hazards = null;
    live.lights = null;
    live.fog = null;
  }
}
