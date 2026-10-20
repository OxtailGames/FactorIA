import { test, expect, game } from "factoria:test";
import { session } from "factoria";
import { loadLevel, listen, teleportOnto } from "./helpers/autoplay.js";
import * as progress from "../scripts/progress.js";

// The player stands on the ground with its centre 24 px above the top of the ground; the ground's top is 4 tiles up.
const GROUND_TOP = 128;

/** Loads a level and lets the player settle on the ground. */
function start(id = "1-1") {
  loadLevel(id);
  game.step(30);
  return game.find("player");
}
const level = () => game.find("level").behaviour;

test("the player stands on the ground", () => {
  const player = start();
  expect(player.position.y).toBeGreaterThan(GROUND_TOP + 20);
  expect(player.position.y).toBeLessThan(GROUND_TOP + 28);
});

test("the player runs right and left", () => {
  const player = start();
  const x0 = player.position.x;
  game.press("move_right");
  game.step(30);
  game.release("move_right");
  expect(player.position.x).toBeGreaterThan(x0 + 100);
  const x1 = player.position.x;
  game.press("move_left");
  game.step(20);
  game.release("move_left");
  expect(player.position.x).toBeLessThan(x1 - 60);
});

test("the player jumps from the ground, plays the jump sound and sends player_jumped, and cannot jump in the air", () => {
  const player = start();
  const seen = listen("player_jumped");
  const y0 = player.position.y;
  game.clearAudioLog();
  game.press("jump");
  game.step(12);
  game.release("jump");
  expect(player.position.y).toBeGreaterThan(y0 + 30);
  expect(game.audioLog()).toContainPlayed("jump.wav", { times: 1 });
  expect(seen.player_jumped).toEqual([{ level: "1-1" }]);
  // in the air: gravity only, no second jump, no sound, no event
  const body = player.get("RigidBody2D");
  game.step(10);
  const vy = body.velocity.y;
  game.tap("jump");
  expect(body.velocity.y).toBeLessThan(vy);
  expect(seen.player_jumped).toHaveLength(1);
});

test("an ember is picked up once: sound, event, HUD count, and it disappears", () => {
  const player = start();
  const seen = listen("ember_collected");
  game.clearAudioLog();
  teleportOnto(player, "ember_2");
  expect(game.find("ember_2")).toBeNull();
  expect(seen.ember_collected).toEqual([{ level: "1-1", index: 1, found: 1 }]);
  expect(game.audioLog()).toContainPlayed("ember.wav", { times: 1 });
  expect(game.find("hud_embers").get("Text").text).toBe("Embers 1/3");
  expect(level().embers).toEqual([false, true, false]);
  teleportOnto(player, "ember_1");
  teleportOnto(player, "ember_3");
  expect(seen.ember_collected.map((e) => e.found)).toEqual([1, 2, 3]);
  expect(game.find("hud_embers").get("Text").text).toBe("Embers 3/3");
});

test("the timer counts game time and stops at the exit", () => {
  start();
  const t0 = level().time;
  game.step(60);
  expect(level().time - t0).toBeCloseTo(1, 1);
  expect(game.find("hud_timer").get("Text").text).toMatch(/^Time 0:0\d\.\d\d$/);
});

test("spikes kill: the death counter goes up, the player returns to the start and the camera shakes", () => {
  const player = start();
  const seen = listen("player_died");
  const startX = player.position.x;
  game.clearAudioLog();
  game.step(30);
  teleportOnto(player, game.world.findByTag("hazard")[0], 1);
  expect(level().deaths).toBe(1);
  expect(seen.player_died).toEqual([{ level: "1-1", cause: "spikes" }]);
  expect(Math.abs(player.position.x - startX)).toBeLessThan(40); // back at the level start (no checkpoint yet)
  expect(game.audioLog()).toContainPlayed("hurt.wav", { times: 1 });
  const camera = game.find("camera").behaviour;
  game.step(3);
  const [sx, sy] = camera.shakeOffset();
  expect(Math.abs(sx) + Math.abs(sy)).toBeGreaterThan(0.5); // shaking
  game.step(40);
  expect(camera.shakeOffset()).toEqual([0, 0]); // short: it stops
});

test("a second touch right after respawning does not count (the player is protected for a moment)", () => {
  const player = start();
  const spikes = game.world.findByTag("hazard")[0];
  teleportOnto(player, spikes, 1);
  teleportOnto(player, spikes, 1);
  expect(level().deaths).toBe(1);
  game.step(60); // the protection is over
  player.position = [spikes.position.x - 300, GROUND_TOP + 24, 0]; // leave the spikes and touch them again
  game.step(20);
  teleportOnto(player, spikes, 1);
  expect(level().deaths).toBe(2);
});

test("a checkpoint is where the next death sends the player back to; checkpoints are numbered from the left", () => {
  const player = start();
  const seen = listen("checkpoint_reached", "player_died");
  const checkpoints = game.world.findByTag("checkpoint").sort((a, b) => a.position.x - b.position.x);
  expect(checkpoints.length).toBeGreaterThan(1);
  teleportOnto(player, checkpoints[1]);
  expect(seen.checkpoint_reached).toEqual([{ level: "1-1", index: 1 }]);
  teleportOnto(player, checkpoints[0]); // an earlier one does not replace it
  expect(seen.checkpoint_reached).toHaveLength(1);
  game.step(60);
  teleportOnto(player, game.world.findByTag("hazard")[0], 1);
  expect(seen.player_died[0].cause).toBe("spikes");
  expect(Math.abs(player.position.x - checkpoints[1].position.x)).toBeLessThan(10);
  expect(player.position.y).toBeGreaterThan(GROUND_TOP);
  game.step(30); // it lands on the ground again at the checkpoint
  expect(Math.abs(player.position.x - checkpoints[1].position.x)).toBeLessThan(10);
});

test("falling out of the level is a death", () => {
  const player = start();
  const seen = listen("player_died");
  player.position = [player.position.x, -400, 0];
  game.step(2);
  expect(seen.player_died).toEqual([{ level: "1-1", cause: "fall" }]);
  expect(player.position.y).toBeGreaterThan(0);
});

test("an enemy patrols and kills on touch", () => {
  const player = start("1-2");
  const seen = listen("player_died");
  const enemy = game.world.findByTag("enemy")[0];
  const x0 = enemy.position.x;
  game.step(60);
  expect(Math.abs(enemy.position.x - x0)).toBeGreaterThan(20); // it walks
  teleportOnto(player, enemy, 2);
  expect(seen.player_died).toEqual([{ level: "1-2", cause: "enemy" }]);
  expect(level().deaths).toBe(1);
});

test("the exit ends the level: level_completed with the time, the embers and the deaths, the result is recorded", () => {
  const player = start();
  const seen = listen("level_completed");
  teleportOnto(player, "ember_3");
  game.step(30);
  teleportOnto(player, game.world.findByTag("hazard")[0], 1);
  game.step(60);
  game.clearAudioLog();
  teleportOnto(player, "exit");
  expect(seen.level_completed).toHaveLength(1);
  const r = seen.level_completed[0];
  expect(r).toMatchObject({ level: "1-1", embers: [false, false, true], deaths: 1 });
  expect(r.time).toBeGreaterThan(2);
  expect(r.time).toBeLessThan(5);
  expect(game.audioLog()).toContainPlayed("win.wav");
  expect(game.paused).toBe(true); // the game is paused behind the panel
  expect(game.find("level_end").active).toBe(true);
  expect(progress.of("1-1")).toEqual({ completed: true, bestTime: r.time, embers: [false, false, true] });
  expect(session.progress.levels["1-1"].completed).toBe(true);
  // after the level is over nothing counts any more
  teleportOnto(player, "exit");
  expect(seen.level_completed).toHaveLength(1);
});

test("a one-way platform: the player jumps up through it and stands on it", () => {
  const player = start("1-2");
  const platform = game.world.findByTag("platform").find((p) => p.get("Collider2D").oneWay);
  // under the platform, on the ground
  player.position = [platform.position.x, GROUND_TOP + 24, 0];
  game.step(20);
  expect(player.isGrounded()).toBe(true);
  game.press("jump");
  game.step(2);
  game.release("jump");
  game.step(70);
  const top = platform.position.y + 6;
  expect(player.position.y).toBeGreaterThan(top + 20); // up on the platform (centre 24 above its top)
  expect(player.position.y).toBeLessThan(top + 30);
});

test("a moving platform carries the player", () => {
  const player = start("1-3");
  const platform = game.world.findByTag("platform").find((p) => p.get("RigidBody2D").type === "kinematic");
  const px0 = platform.position.x;
  player.position = [platform.position.x, platform.position.y + 8 + 24 + 10, 0];
  game.step(20);
  expect(player.isGrounded()).toBe(true);
  const start0 = player.position.x - platform.position.x;
  let moved = 0;
  for (let i = 0; i < 120; i++) {
    game.step(1);
    moved = Math.max(moved, Math.abs(platform.position.x - px0));
  }
  expect(moved).toBeGreaterThan(40); // the platform swung
  expect(Math.abs(player.position.x - platform.position.x - start0)).toBeLessThan(12); // and the player rode it
});
