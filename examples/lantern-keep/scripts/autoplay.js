// @ts-check
// The bot: how Lantern Keep plays itself when `factoria call play.auto` (or the editor's Play > Let the AI Play) tests it. It plays
// the level that is loaded: runs right, jumps over what is ahead (a wall, a pit, spikes, an enemy) and ends the run as "won" when
// the level's exit has been touched. The levels are built so that this simple plan finishes every one of them (README, "Tests").
// Only play.auto imports this file (a shipped game does not contain it); tests/helpers/level.js imports `decide` to drive the same
// bot a step at a time, so the bot of the tests and the bot of `play.auto` are one.
//
//   factoria call play.auto '{"scene":"scenes/levels/1-2.scene.json","bot":"hook","seconds":90}'
//
// It reads the world and answers with actions: it never moves anything itself (the run is recorded as input and must replay).
import { game, world } from "factoria";

const TILE = 32;

/** @typedef {{ time: number, step: number, scene: string, sceneTime: number, phase: string, held: readonly string[] }} BotState */

/** What the bot remembers about the level it is playing. */
let memory = { scene: "", sceneTime: 1e9, columns: 0, rows: 0, tiles: /** @type {number[]} */ ([]), solid: /** @type {Set<number>} */ (new Set()), lastX: 0, stuck: 0, cooldown: 0, menuStep: 0 };

/** Forgets the level: the next call to `decide` reads the loaded one. */
export function forget() {
  memory = { scene: "", sceneTime: 1e9, columns: 0, rows: 0, tiles: [], solid: new Set(), lastX: 0, stuck: 0, cooldown: 0, menuStep: 0 };
}

/** @param {number} x @param {number} y */
function isSolid(x, y) {
  const c = Math.floor(x / TILE);
  const r = memory.rows - 1 - Math.floor(y / TILE);
  if (c < 0 || c >= memory.columns || r < 0 || r >= memory.rows) return false;
  return memory.solid.has(memory.tiles[r * memory.columns + c] & 0x0fffffff);
}

/**
 * The bot's answer for one step: the actions to hold, or `{ end: "won", score }` when the level is finished.
 * @param {BotState} bot
 */
export function decide(bot) {
  const player = world.find("player");
  const map = world.find("map")?.get("Tilemap");
  const level = world.find("level")?.behaviour;
  if (!player || !map || !level) {
    // Not in a level (a menu, a loading screen): press the menu's default button now and then.
    memory.menuStep += 1;
    return memory.menuStep % 30 === 0 ? ["ui_submit"] : [];
  }
  if (level.finished) return { end: "won", score: level.found, note: `Level ${level.levelId}: ${level.found} embers, ${level.deaths} deaths.` };
  if (memory.scene !== bot.scene || bot.sceneTime < memory.sceneTime) {
    forget();
    memory.scene = bot.scene;
    memory.columns = map.width;
    memory.rows = map.height;
    memory.solid = new Set(map.solidTiles);
    memory.tiles = map.tiles;
    memory.lastX = player.position.x;
  }
  memory.sceneTime = bot.sceneTime;

  const p = player.position;
  let jump = false;
  if (memory.cooldown > 0) memory.cooldown -= 1;
  else if (player.isGrounded()) {
    const feet = p.y - 24;
    for (let y = feet + 4; y <= feet + 40 && !jump; y += 12) if (isSolid(p.x + 22, y)) jump = true; // a wall
    // A pit ahead (no floor for 7 tiles down): jump. A step down is just walked off.
    if (!jump && ![4, 36, 68, 100, 132, 164, 196, 228].some((d) => isSolid(p.x + 44, feet - d))) jump = true;
    for (const h of world.findByTag("hazard")) {
      const dx = h.position.x - p.x;
      if (dx > 0 && dx < 110 && Math.abs(h.position.y - p.y) < 40) jump = true; // spikes
    }
    for (const e of world.findByTag("enemy")) {
      const dx = e.position.x - p.x;
      if (dx > -60 && dx < 190 && Math.abs(e.position.y - p.y) < 56) jump = true; // an enemy
    }
    if (Math.abs(p.x - memory.lastX) < 1) memory.stuck += 1;
    else memory.stuck = 0;
    if (memory.stuck > 20) jump = true; // pressing right and not moving
  }
  memory.lastX = p.x;
  if (jump) {
    memory.cooldown = 8; // the player still touches the ground for a frame or two after the jump
    return ["move_right", "jump"];
  }
  return ["move_right"];
}

game.autoplay(decide);
