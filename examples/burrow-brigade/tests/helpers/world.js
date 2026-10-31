// Helpers for the P2 tests: a shift on a mine written as rows of text (scripts/game/mine_ascii.js), in any stratum, with 1 to 4
// players, and small finders for the miners and enemies in it. The scene is built here (a camera, the Tilemap and the Shift
// script), so a test names the mine it needs in the test itself instead of sharing one file.
import { game, beforeEach } from "factoria:test";
import * as players from "../../scripts/game/players.js";
import * as events from "../../scripts/game/events.js";
import { startRun } from "../../scripts/game/run_state.js";
import { live } from "../../scripts/game/mine_map.js";

/** Every test starts with an empty registry, a clean bus and no run (call once at the top of a test file). */
export function cleanBeforeEach() {
  beforeEach(() => {
    players.clear();
    events.clear();
  });
}

/** Adds `n` players (1 to 4): the first on the project's own actions, the others on the key blocks and pads of the registry. */
export function addPlayers(n) {
  players.clear();
  const devices = [{ kind: "any" }, { kind: "keys", scheme: "arrows" }, { kind: "pad", index: 0 }, { kind: "pad", index: 1 }];
  for (let i = 0; i < n; i++) {
    // like the join screen, plug the pad in first: the player then keeps the pad's id
    if (devices[i].kind === "pad") game.gamepad(devices[i].index).connect();
    players.add({ device: devices[i] });
  }
}

/** Plugs in the gamepad of every player on a pad (a test starts with every pad unplugged; scripts/game/pad_watch.js pauses a shift whose pad is not there). */
export function plugPads() {
  for (const p of players.all()) if (p.device.kind === "pad") game.gamepad(p.device.index).connect();
}

/**
 * Starts a run at a stratum and floor and loads a shift on a handmade mine; lets the scene start (2 frames).
 * @param {string[]} rows  The mine as rows of text. `S` is the entry lift: the players stand on the free tiles around it.
 * @param {{stratum?: number, floor?: number, seed?: number, players?: number, frames?: number, padWatch?: boolean, music?: boolean, captions?: boolean}} [opts]
 *   `music` adds the music driver entity of the shift scene (layers, mix), `captions` its "sound_captions" entity.
 * @returns {any} The Shift behaviour.
 */
export function playRows(rows, opts = {}) {
  if (opts.players !== undefined) addPlayers(opts.players);
  startRun({ seed: opts.seed ?? 7, stratum: opts.stratum ?? 0, floor: opts.floor ?? 1 });
  game.loadJson({
    format: "factoria.scene/1",
    entities: [
      {
        id: "camera",
        components: {
          Transform: { position: [0, 0, 0] },
          Camera: { projection: "orthographic", orthoSize: 144, clearColor: [0.02, 0.02, 0.03, 1], primary: true },
          Script: { path: "scripts/game/follow_camera.js" },
        },
      },
      { id: "mine", components: { Transform: { position: [0, 0, 0] }, Tilemap: { tileset: "assets/tiles_topsoil.png", tileSize: [16, 16], lit: true, layer: -10 } } },
      { id: "shift", components: { Script: { path: "scripts/game/shift.js", props: { rows } } } },
      ...(opts.music ? [{ id: "music", components: { Script: { path: "scripts/game/music.js" } } }] : []),
      ...(opts.captions ? [{ id: "sound_captions", components: { Transform: { position: [110, -24, 0] }, Captions: { size: [560, 100], maxLines: 2, fontSize: 24, layer: 190 } } }] : []),
      ...(opts.padWatch ? [{ id: "pad_watch", components: { Script: { path: "scripts/game/pad_watch.js" } } }] : []),
    ],
    settings: { ambientLight: [0.07, 0.07, 0.1, 1] },
  });
  game.step(opts.frames ?? 2);
  return game.find("shift").behaviour;
}

/** Loads a generated mine of a stratum and floor (the same scene the game plays). */
export function playGenerated(stratum, floor, seed = 1234, nPlayers = 1) {
  addPlayers(nPlayers);
  startRun({ seed, stratum, floor });
  game.load("scenes/shift.scene.json");
  game.step(2);
  return game.find("shift").behaviour;
}

/** The miner entities, in player id order. */
export function miners() {
  return game.world.findByTag("miner").sort((a, b) => a.behaviour.playerId - b.behaviour.playerId);
}

export function miner(i = 0) {
  return miners()[i];
}

/** The enemy behaviours alive, optionally of one kind. */
export function enemyList(kind) {
  return game.world
    .findByTag("enemy")
    .map((e) => e.behaviour)
    .filter((b) => b && !b.dead && (!kind || b.kind === kind));
}

/** Puts a miner (or any entity) in the middle of a tile. */
export function teleport(entity, tx, ty) {
  const c = live.map.tileCenter(tx, ty);
  entity.position = [c.x, c.y, 0];
}

/** The tile an entity stands on. */
export function tileOf(entity) {
  return live.map.tileAt(entity.position.x, entity.position.y);
}

/** Records the events with these names while a test runs; returns the list (each item `{name, data}`). */
export function record(...names) {
  const log = [];
  for (const name of names) events.on(name, (data) => log.push({ name, data }));
  return log;
}
