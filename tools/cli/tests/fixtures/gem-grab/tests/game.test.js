import { test, expect, game } from "factoria:test";
import { scene } from "factoria";

test("the player walks right", () => {
  game.load("scenes/main.scene.json");
  const player = game.find("player");
  const x0 = player.position.x;
  game.press("move_right");
  game.step(30); // half a second
  game.release("move_right");
  expect(player.position.x).toBeGreaterThan(x0 + 100);
});

test("touching a gem collects it and counts it", () => {
  game.load("scenes/main.scene.json");
  game.press("move_right");
  game.step(60); // the first gem is 300 pixels to the right of the start
  game.release("move_right");
  expect(game.world.findByTag("gem").length).toBe(3);
  expect(game.find("score").get("Text").text).toBe("Gems: 1 / 4");
});

test("the last gem opens the win screen, and Space plays again", () => {
  game.load("scenes/main.scene.json");
  const player = game.find("player");
  for (const gem of game.world.findByTag("gem")) {
    player.position = gem.position; // jump onto the gem
    game.step(2);
  }
  expect(scene.current).toBe("scenes/win.scene.json");
  game.tap("action");
  game.step(2);
  expect(scene.current).toBe("scenes/main.scene.json");
});
