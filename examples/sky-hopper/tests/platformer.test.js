import { test, expect, game } from "factoria:test";
import { state, resetState } from "scripts/game_state.js";

function load(path = "scenes/level1.scene.json") {
  resetState();
  game.load(path);
  game.step(30); // settle onto the ground
  return game.find("player");
}

test("player lands on the ground", () => {
  const p = load();
  expect(p.position.y).toBeGreaterThan(110);
  expect(p.position.y).toBeLessThan(125);
});

test("player runs right and left", () => {
  const p = load();
  const x0 = p.position.x;
  game.press("move_right");
  game.step(30);
  game.release("move_right");
  expect(p.position.x).toBeGreaterThan(x0 + 100);
  const x1 = p.position.x;
  game.press("move_left");
  game.step(20);
  game.release("move_left");
  expect(p.position.x).toBeLessThan(x1 - 40);
});

test("player jumps from the ground and lands again", () => {
  const p = load();
  const y0 = p.position.y;
  game.clearAudioLog();
  game.press("jump");
  game.step(12);
  game.release("jump");
  expect(p.position.y).toBeGreaterThan(y0 + 30);
  expect(game.audioLog()).toContainPlayed("assets/sfx/jump.wav", { times: 1 });
  game.step(90);
  expect(Math.abs(p.position.y - y0)).toBeLessThan(3);
});

test("holding jump jumps higher than tapping", () => {
  let p = load();
  const y0 = p.position.y;
  game.press("jump"); game.step(2); game.release("jump");
  let tap = 0;
  for (let i = 0; i < 40; i++) { game.step(1); tap = Math.max(tap, p.position.y - y0); }
  p = load();
  game.press("jump");
  let hold = 0;
  for (let i = 0; i < 42; i++) { game.step(1); hold = Math.max(hold, p.position.y - y0); }
  game.release("jump");
  expect(hold).toBeGreaterThan(tap + 20);
});

test("jump buffering: pressing jump just before landing still jumps", () => {
  const p = load();
  game.press("jump"); game.step(2); game.release("jump");
  // wait until nearly landed, then press again
  for (let i = 0; i < 90 && p.position.y > 128; i++) game.step(1);
  game.step(0);
  const before = p.position.y;
  game.press("jump"); game.step(1); game.release("jump");
  game.step(6);
  expect(p.position.y).toBeGreaterThan(before + 5);
});

test("coyote time: can jump shortly after leaving a ledge", () => {
  const p = load();
  // ground ends at x=256; walk off the ledge
  game.press("move_right");
  for (let i = 0; i < 200 && p.position.x < 262; i++) game.step(1);
  game.step(3);
  game.press("jump");
  game.step(1);
  game.release("jump");
  game.release("move_right");
  expect(p.position.y).toBeGreaterThan(0);
  const vy = game.world.find("player").get("RigidBody2D").velocity.y;
  expect(vy).toBeGreaterThan(300);
});

test("collecting a coin removes it, counts it and bursts particles", () => {
  const p = load();
  const coin = game.find("coin_1");
  expect(coin).not.toBeNull();
  p.position.x = coin.position.x;
  p.position.y = coin.position.y;
  game.step(3);
  expect(game.find("coin_1")).toBeNull();
  expect(state.coins).toBe(1);
  expect(game.audioLog()).toContainPlayed("coin.wav", { times: 1 });
  expect(game.world.findByTag("fx").length).toBeGreaterThan(0);
});

test("stomping an enemy kills it and bounces the player", () => {
  const p = load();
  const e = game.find("enemy_1");
  p.position.x = e.position.x;
  p.position.y = e.position.y + 80;
  game.world.find("player").get("RigidBody2D").velocity.y = -100;
  game.step(20);
  expect(game.find("enemy_1")).toBeNull();
  expect(state.lives).toBe(3);
  expect(game.audioLog()).toContainPlayed("stomp.wav");
  expect(game.audioLog()).not.toContainPlayed("hurt.wav");
});

test("side contact with an enemy costs a life and respawns at level start", () => {
  const p = load();
  const e = game.find("enemy_1");
  const sx = p.position.x;
  p.position.x = e.position.x - 60;
  p.position.y = e.position.y;
  game.press("move_right");
  for (let i = 0; i < 60 && state.lives === 3; i++) game.step(1);
  game.release("move_right");
  expect(state.lives).toBe(2);
  expect(game.audioLog()).toContainPlayed("hurt.wav");
  expect(Math.abs(p.position.x - sx)).toBeLessThan(10);
});

test("falling into a pit costs a life", () => {
  const p = load();
  p.position.x = 288;
  p.position.y = 100;
  game.step(120);
  expect(state.lives).toBe(2);
  expect(p.position.y).toBeGreaterThan(0);
});

test("enemies patrol", () => {
  load();
  const e = game.find("enemy_1");
  const x0 = e.position.x;
  game.step(60);
  expect(Math.abs(e.position.x - x0)).toBeGreaterThan(20);
});

test("reaching the goal loads the next level", () => {
  const p = load();
  const goal = game.find("goal");
  p.position.x = goal.position.x;
  p.position.y = goal.position.y;
  game.step(90);
  expect(game.audioLog()).toContainPlayed("win.wav", { times: 1 });
  expect(state.level).toBe(2);
  expect(game.find("goal")).not.toBeNull();
  expect(game.find("enemy_1")).not.toBeNull();
});

test("losing all lives shows game over, confirm restarts", () => {
  const p = load();
  state.lives = 1;
  p.position.y = -500;
  game.step(60);
  expect(game.find("title")).not.toBeNull();
  game.tap("confirm");
  game.step(5);
  expect(game.find("player")).not.toBeNull();
  expect(state.lives).toBe(3);
});

test("camera follows the player but stays inside level bounds", () => {
  const p = load();
  const cam = game.find("camera");
  expect(cam.position.x).toBeCloseTo(640, 0);
  p.position.x = 1120; p.position.y = 130;
  game.step(120);
  expect(cam.position.x).toBeGreaterThan(900);
  p.position.x = 1900; 
  game.step(120);
  expect(cam.position.x).toBeLessThan(1281);
});

test("project.generate_level is deterministic and has the required entities", async () => {
  const { fa } = await import("factoria");
  const args = { width: 60, seed: 5, difficulty: 2, dryRun: true };
  const a = fa.call("project.generate_level", args);
  const b = fa.call("project.generate_level", args);
  expect(JSON.stringify(a.scene)).toBe(JSON.stringify(b.scene));
  const c = fa.call("project.generate_level", { ...args, seed: 6 });
  expect(JSON.stringify(c.scene)).not.toBe(JSON.stringify(a.scene));
  const ids = a.scene.entities.map((e) => e.id);
  expect(ids).toContain("player");
  expect(ids).toContain("goal");
  expect(ids).toContain("map");
});

test("the committed generated level (scenes/generated.scene.json) loads and runs", () => {
  const p = load("scenes/generated.scene.json");
  expect(p.position.y).toBeGreaterThan(100);
  expect(game.find("goal")).not.toBeNull();
  const goal = game.find("goal");
  p.position.x = goal.position.x; p.position.y = goal.position.y;
  game.step(90);
  expect(game.find("title")).not.toBeNull(); // win screen
});
