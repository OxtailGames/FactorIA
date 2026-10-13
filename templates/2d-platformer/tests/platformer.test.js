import { test, expect, game } from "factoria:test";
import { fa } from "factoria";

// The level (tiles, coins, player) is built from levels/level1.json by `factoria call scene.import_ascii @levels/level1.json`.
// The map's bottom-left corner is the origin: the ground's top is at y = 4 tiles * 32 = 128, and the player (48 tall) stands
// on it with its centre at y = 152.
const GROUND_TOP = 128;

function load() {
  game.load("scenes/main.scene.json");
  game.step(60); // let the player settle on the ground
  return game.find("player");
}

const coinCount = () => game.world.findByTag("coin").length;

test("player stands on the ground", () => {
  const player = load();
  expect(player.position.y).toBeGreaterThan(GROUND_TOP + 20);
  expect(player.position.y).toBeLessThan(GROUND_TOP + 28);
});

test("player runs right", () => {
  const player = load();
  const x0 = player.position.x;
  game.press("move_right");
  game.step(30);
  game.release("move_right");
  expect(player.position.x).toBeGreaterThan(x0 + 100);
});

test("player jumps from the ground and plays the jump sound once", () => {
  const player = load();
  const y0 = player.position.y;
  game.clearAudioLog(); // ignore sounds from the level start
  game.press("jump");
  game.step(12);
  game.release("jump");
  expect(player.position.y).toBeGreaterThan(y0 + 30);
  expect(game.audioLog()).toContainPlayed("jump.wav", { times: 1 });
});

test("player cannot jump again in the air", () => {
  const player = load();
  const body = player.get("RigidBody2D");
  game.tap("jump");
  game.step(30); // near the top of the jump
  const vy = body.velocity.y;
  game.clearAudioLog();
  game.tap("jump"); // still in the air: gravity only, no second jump and no sound
  expect(body.velocity.y).toBeLessThan(vy);
  expect(game.audioLog()).not.toContainPlayed("jump.wav");
});

test("collecting coins removes them, counts them and plays the coin sound", () => {
  const player = load();
  const before = coinCount();
  expect(before).toBeGreaterThan(3);
  game.clearAudioLog();
  game.press("move_right");
  game.step(45); // the three coins in a row near the start are on the way
  game.release("move_right");
  expect(coinCount()).toBe(before - 3);
  expect(game.audioLog()).toContainPlayed("coin.wav", { times: 3 });
  expect(game.find("hud").get("Text").text).toBe("Coins: 3");
  expect(player.position.x).toBeGreaterThan(300);
});

test("the camera follows the player", () => {
  const player = load();
  const camera = game.find("camera");
  expect(camera.position.x).toBeCloseTo(640, 0); // the player starts near the left edge: the camera waits at the edge
  game.press("move_right");
  game.step(150); // 2.5 s of running: past the first screen
  game.release("move_right");
  expect(player.position.x).toBeGreaterThan(800);
  expect(Math.abs(camera.position.x - player.position.x)).toBeLessThan(40);
});

// The limits are the bounds() of the Tilemap (the entity named by the camera's `bounds` prop), not numbers copied into the
// script: the camera stops half a view from each edge of the map, on both axes, and follows the map when it is edited.
test("the camera never shows anything outside the level", () => {
  load();
  const area = game.find("map").bounds(); // { x, y, w, h }: bottom-left corner and size
  const camera = game.find("camera").behaviour;
  const halfW = 640, halfH = 360; // half of the 1280x720 design size
  expect(camera.clampPos(-1e6, -1e6)).toEqual([area.x + halfW, area.y + halfH]);
  expect(camera.clampPos(1e6, 1e6)).toEqual([area.x + area.w - halfW, area.y + area.h - halfH]);
  expect(camera.clampPos(1300, 500)).toEqual([1300, 500]); // inside the limits: the camera is centred on the target
});

test("project.spawn_coin adds a coin from the prefab", () => {
  load();
  const before = coinCount();
  const { id } = fa.call("project.spawn_coin", { x: 400, y: 200 });
  expect(coinCount()).toBe(before + 1);
  expect(game.find(id).position.x).toBe(400);
  expect(game.find(id).hasTag("coin")).toBe(true);
});
