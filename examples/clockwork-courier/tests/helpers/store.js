// Helpers of the store tests (services, shop, leaderboards, ads): a clean save and a clean fake store, events sent by hand,
// and short readers of what the platform and the save hold. `storage` keeps its data across the tests of a run and the fake
// store keeps its state until it is reset (FB-0021), so every test starts with fresh().
import { game } from "factoria:test";
import { storage } from "factoria";

export const SAVE_KEYS = ["progress", "store", "services"];

/** Forgets the saves of the game and resets the fake store (signed in again by the services at the next scene). */
export function fresh() {
  for (const k of SAVE_KEYS) storage.remove(k);
  game.platform.reset();
}

/** Sends a game event by hand (events.js has the names and payloads) and lets the listeners and the platform answer. */
export function send(name, data = {}, frames = 3) {
  game.world.emit(name, data);
  game.step(frames);
}

/** The services behaviour of the running scene. */
export function services() {
  return game.find("store_services").behaviour;
}

/** The platform calls of one method, oldest first: [{ args, ok, result }]. */
export function calls(method) {
  return game.platform.calls().filter((c) => c.method === method);
}

/** What the fake store holds for the player: { achievements, stats, leaderboards, owned, unfinished }. */
export function fake() {
  return game.platform.state().fake;
}

/** Records the names of the given events; returns the log. */
export function record(names) {
  const log = [];
  for (const n of names) game.world.on(n, (d) => log.push({ name: n, data: d }));
  return log;
}

/** Loads the title screen and steps until the services have signed in. */
export function loadTitle() {
  game.load("scenes/main.scene.json");
  game.step(10);
}

/** Loads the test yard (a level scene with the flow, the courier and the retry screen) and steps a little. */
export function loadYard() {
  game.load("scenes/test_yard.scene.json");
  game.step(10);
}

/** Lets the spring run down and steps until the retry screen is up. */
export function runDown() {
  game.find("spring").behaviour.left = 0.05;
  game.step(140);
}

/** For afterEach: leaves nothing of the test behind (saves, the fake store) for the files that run next. */
export function cleanup() {
  for (const k of SAVE_KEYS) storage.remove(k);
  game.platform.reset();
}
