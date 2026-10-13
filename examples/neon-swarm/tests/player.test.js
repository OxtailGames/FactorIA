import { test, expect, game } from "factoria:test";

test("player moves right while move_right is held", () => {
  game.load("scenes/main.scene.json");
  const player = game.find("player");
  const x0 = player.position.x;
  game.press("move_right");
  game.step(30); // 0.5 s at 60 Hz
  game.release("move_right");
  expect(player.position.x).toBeGreaterThan(x0 + 100);
});

test("player stays put without input", () => {
  game.load("scenes/main.scene.json");
  const player = game.find("player");
  const x0 = player.position.x;
  game.step(30);
  expect(player.position.x).toBe(x0);
});
