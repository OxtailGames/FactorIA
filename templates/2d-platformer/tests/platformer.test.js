import { test, expect, game } from "factoria:test";

function load() {
  game.load("scenes/main.scene.json");
  game.step(60); // let the player fall onto the ground
  return game.find("player");
}

test("player lands on the ground", () => {
  const player = load();
  // ground top is y = -280, player is 48 tall
  expect(player.position.y).toBeGreaterThan(-270);
  expect(player.position.y).toBeLessThan(-250);
});

test("player runs right", () => {
  const player = load();
  const x0 = player.position.x;
  game.press("move_right");
  game.step(30);
  game.release("move_right");
  expect(player.position.x).toBeGreaterThan(x0 + 100);
});

test("player jumps only from the ground", () => {
  const player = load();
  const y0 = player.position.y;
  game.press("jump");
  game.step(12);
  game.release("jump");
  expect(player.position.y).toBeGreaterThan(y0 + 30);
});

test("collecting a coin removes it", () => {
  const player = load();
  expect(game.find("coin_1")).not.toBeNull();
  game.press("move_right");
  game.step(90); // ~270 px, passes x = -100
  game.release("move_right");
  expect(game.find("coin_1")).toBeNull();
});
