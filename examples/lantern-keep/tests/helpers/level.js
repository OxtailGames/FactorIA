// Helpers for the tests that load and play levels. The bot is the game's own: scripts/autoplay.js (the file `play.auto` runs).
// `playLevel("1-2")` loads a level and feeds that bot one step at a time until the exit is touched, so a test can listen to the
// game's events and read its state while the same bot that `play.auto` uses plays.
//
//   const r = playLevel("1-1");            // { completed, frames, seconds, deaths, embers, events }
//   const r = playLevel("1-1", { events: ["ember_collected"] });   // also the payloads of these game events
import { game } from "factoria:test";
import { world } from "factoria";
import { find } from "../../scripts/levels.js";
import { decide, forget } from "../../scripts/autoplay.js";

/** Loads level `id`, lets it settle for two frames and returns the level. */
export function loadLevel(id) {
  const level = find(id);
  if (!level) throw new Error(`autoplay: unknown level "${id}"`);
  game.load(level.scene);
  game.step(2);
  return level;
}

/** Plays the loaded or given level with the game's bot until the exit is touched or `maxSeconds` of game time pass. */
export function playLevel(id, { maxSeconds = 90, events = [] } = {}) {
  const level = loadLevel(id);
  forget();
  const levelBehaviour = game.find("level").behaviour;
  const seen = Object.fromEntries(events.map((e) => [e, []]));
  const offs = events.map((name) => world.on(name, (data) => seen[name].push(data)));
  const maxFrames = Math.round(maxSeconds * 60);
  let frames = 0;
  let held = [];
  while (frames < maxFrames && !levelBehaviour.finished) {
    const answer = decide({ time: frames / 60, step: frames, scene: level.scene, sceneTime: frames / 60, phase: "", held });
    const now = Array.isArray(answer) ? answer : [];
    for (const action of now) if (!held.includes(action)) game.press(action); // a press and a release only when the answer changes
    for (const action of held) if (!now.includes(action)) game.release(action);
    held = now;
    game.step(1);
    frames += 1;
  }
  for (const action of held) game.release(action);
  offs.forEach((off) => off && off());
  return {
    completed: levelBehaviour.finished,
    frames,
    seconds: frames / 60,
    deaths: levelBehaviour.deaths,
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
