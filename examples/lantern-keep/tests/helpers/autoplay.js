// A bot that plays a level to its exit, for tests (this package's and the next ones'): `playLevel("1-2")` loads the
// level, runs right, jumps over what is ahead (a wall, a gap, spikes, an enemy) and returns what happened. The levels are
// built so that this simple strategy finishes every one of them (see README, "Tests").
//
//   const r = playLevel("1-1");            // { completed, frames, seconds, deaths, embers, events }
//   const r = playLevel("1-1", { events: ["ember_collected"] });   // also the payloads of these game events
import { game } from "factoria:test";
import { world } from "factoria";
import { find } from "../../scripts/levels.js";

const TILE = 32;

/** Loads level `id`, lets it settle for two frames and returns the bot's helpers. */
export function loadLevel(id) {
  const level = find(id);
  if (!level) throw new Error(`autoplay: unknown level "${id}"`);
  game.load(level.scene);
  game.step(2);
  return level;
}

/** Plays the loaded or given level until the exit is touched or `maxSeconds` of game time pass. */
export function playLevel(id, { maxSeconds = 90, events = [], hold = null } = {}) {
  loadLevel(id);
  const player = game.find("player");
  const map = game.find("map").get("Tilemap");
  const levelBehaviour = game.find("level").behaviour;
  const columns = map.width;
  const rows = map.height;
  const solid = new Set(map.solidTiles);
  const tiles = map.tiles;
  const isSolid = (x, y) => {
    const c = Math.floor(x / TILE);
    const r = rows - 1 - Math.floor(y / TILE);
    if (c < 0 || c >= columns || r < 0 || r >= rows) return false;
    return solid.has(tiles[r * columns + c] & 0x0fffffff);
  };
  const hazards = game.world.findByTag("hazard");
  const enemies = game.world.findByTag("enemy");
  const seen = Object.fromEntries(events.map((e) => [e, []]));
  
  const offs = events.map((name) => world.on(name, (data) => seen[name].push(data)));

  game.press("move_right");
  const maxFrames = Math.round(maxSeconds * 60);
  let frames = 0;
  let lastX = player.position.x;
  let stuck = 0;
  let deaths = 0;
  let cooldown = 0; // frames to wait after a jump (the player still touches the ground for a frame or two)
  const jumps = []; // [x tile column, why] of every jump the bot made, for debugging a level
  const deathSpots = []; // where the player was a frame before each death: [x tile column, height above the ground in tiles]
  while (frames < maxFrames && !levelBehaviour.finished) {
    const p = player.position;
    let jump = false;
    let why = "";
    if (cooldown > 0) cooldown -= 1;
    else if (player.isGrounded()) {
      const feet = p.y - 24;
      for (let y = feet + 4; y <= feet + 40 && !jump; y += 12) if (isSolid(p.x + 22, y)) jump = (why = "wall"); // a wall
      // A pit ahead (no floor for 7 tiles down): jump. A step down is just walked off.
      if (!jump && ![4, 36, 68, 100, 132, 164, 196, 228].some((d) => isSolid(p.x + 44, feet - d))) jump = (why = "pit");
      for (const h of hazards) {
        const dx = h.position.x - p.x;
        if (h.alive && dx > 0 && dx < 110 && Math.abs(h.position.y - p.y) < 40) jump = (why = "spikes");
      }
      for (const e of enemies) {
        const dx = e.position.x - p.x;
        if (e.alive && dx > -60 && dx < 190 && Math.abs(e.position.y - p.y) < 56) jump = (why = "enemy");
      }
      if (Math.abs(p.x - lastX) < 1) stuck += 1;
      else stuck = 0;
      if (stuck > 20) jump = (why = "stuck");
    }
    const spot = [Math.round((p.x / TILE) * 10) / 10, Math.round(((p.y - 24) / TILE) * 10) / 10];
    lastX = p.x;
    if (hold) hold(frames);
    if (jump) {
      cooldown = 8;
      jumps.push([Math.round(p.x / TILE * 10) / 10, why]);
      game.press("jump");
      game.step(1);
      game.release("jump");
    } else game.step(1);
    frames += 1;
    if (levelBehaviour.deaths !== deaths) {
      deaths = levelBehaviour.deaths;
      deathSpots.push(spot);
    }
  }
  game.release("move_right");
  offs.forEach((off) => off && off());
  return {
    completed: levelBehaviour.finished,
    frames,
    seconds: frames / 60,
    deaths: levelBehaviour.deaths,
    deathSpots,
    jumps,
    embers: [...levelBehaviour.embers],
    events: seen,
  };
}

/** Records the payloads of game events from now on: `const seen = listen("player_died"); ... seen.player_died` (a list). */
export function listen(...names) {
  const seen = Object.fromEntries(names.map((n) => [n, []]));
  for (const name of names) world.on(name, (data) => seen[name].push(data));
  return seen;
}

/** Puts the player (or any entity) in the middle of another entity and runs `frames` frames. */
export function teleportOnto(who, target, frames = 2) {
  const t = typeof target === "string" ? game.find(target) : target;
  if (!t) throw new Error(`teleportOnto: no entity "${target}" in the loaded level`);
  who.position = [t.position.x, t.position.y, 0];
  game.step(frames);
}
