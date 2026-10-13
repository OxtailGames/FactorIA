import { test, expect, game } from "factoria:test";

test("cube spins", () => {
  game.load("scenes/main.scene.json");
  const cube = game.find("cube");
  const y0 = cube.transform.rotation.y;
  game.step(60); // 1 s at 60 Hz, 45 deg/s
  expect(cube.transform.rotation.y).toBeCloseTo(y0 + 45, 0);
});

test("camera flies forward (-Z) while move_forward is held", () => {
  game.load("scenes/main.scene.json");
  const camera = game.find("camera");
  const z0 = camera.position.z;
  game.press("move_forward");
  game.step(30);
  game.release("move_forward");
  expect(camera.position.z).toBeLessThan(z0 - 1);
});
