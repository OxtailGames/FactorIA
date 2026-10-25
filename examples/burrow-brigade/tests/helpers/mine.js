// Helpers shared by the tests: load the handmade mine of scenes/test_mine.scene.json and find the pieces of it.
//
//   B B B B B B B B B B B B B B B B B B B B B B B B     row 0
//   B . S . # c . . . . . . . . o . . . . E . . . B     row 1  S entry lift (2,1), dirt (4,1), copper (5,1), oil (14,1), E exit lift (19,1)
//   B # # # R # # # H # # # g # # # G # # s # # # B     row 2  rock (4,2), hard rock (8,2), gold (12,2), gem (16,2), silver (19,2)
//   B . . . . . . . . . . . . . . . . . m . . . . B     row 3  a trapped mole at (18,3), sealed in by row 2
//   B B B B B B B B B B B B B B B B B B B B B B B B     row 4
import { game, beforeEach } from "factoria:test";
import * as players from "../../scripts/game/players.js";
import * as events from "../../scripts/game/events.js";
import { startRun } from "../../scripts/game/run_state.js";

export const TEST_MINE = "scenes/test_mine.scene.json";

/** Every test starts a fresh run with one player (call once at the top of a test file). */
export function freshRunBeforeEach() {
  beforeEach(() => {
    players.clear();
    events.clear();
    startRun({ seed: 7 });
  });
}

/** Loads the handmade mine and lets the scene start. */
export function loadMine(frames = 2) {
  game.load(TEST_MINE);
  game.step(frames);
  return game.find("shift").behaviour;
}

/** The miner entities, by player id order. */
export function miners() {
  return game.world.findByTag("miner").sort((a, b) => a.behaviour.playerId - b.behaviour.playerId);
}

export function miner(i = 0) {
  return miners()[i];
}

/** Puts a miner in the middle of a tile. */
export function teleport(entity, map, tx, ty) {
  const c = map.tileCenter(tx, ty);
  entity.position = [c.x, c.y, 0];
}
