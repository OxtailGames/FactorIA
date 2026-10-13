import { test, expect, game } from "factoria:test";
import { fa } from "factoria";

function load() {
  game.load("scenes/main.scene.json");
  game.step(30); // let the ball land on the start platform
  return { ball: game.find("ball"), mgr: game.find("game").behaviour, cam: game.find("camera") };
}

function teleportOnto(ball, pos) {
  ball.position.x = pos.x; ball.position.y = pos.y; ball.position.z = pos.z;
  ball.get("RigidBody3D").velocity.y = 0;
}

test("ball moves forward (-Z) with input", () => {
  const { ball } = load();
  const z0 = ball.position.z;
  game.press("move_forward");
  game.step(30);
  game.release("move_forward");
  expect(ball.position.z).toBeLessThan(z0 - 1);
});

test("movement is relative to the camera yaw", () => {
  const { ball, cam } = load();
  cam.behaviour.yaw = 90; // camera on the +X side looking toward -X
  game.step(2);
  const x0 = ball.position.x;
  game.press("move_forward");
  game.step(20);
  game.release("move_forward");
  expect(ball.position.x).toBeLessThan(x0 - 0.5);
});

test("jump lifts the ball only while grounded", () => {
  const { ball } = load();
  const y0 = ball.position.y;
  game.press("jump"); game.step(1); game.release("jump");
  game.step(10);
  expect(ball.position.y).toBeGreaterThan(y0 + 0.5);
});

test("chase camera follows the ball", () => {
  const { ball, cam } = load();
  game.press("move_forward");
  game.step(60);
  game.release("move_forward");
  game.step(60);
  expect(Math.abs(cam.position.z - ball.position.z - 9)).toBeLessThan(1.5);
});

test("scatter_gems is deterministic and places gems on platforms", () => {
  load();
  const a = fa.call("project.scatter_gems", { count: 6, seed: 42, clear: true });
  game.step(1);
  const b = fa.call("project.scatter_gems", { count: 6, seed: 42, clear: true });
  const c = fa.call("project.scatter_gems", { count: 6, seed: 43, clear: true });
  expect(a.placed).toBe(6);
  expect(b.gems.map((g) => g.position)).toEqual(a.gems.map((g) => g.position));
  expect(c.gems.map((g) => g.position)).not.toEqual(a.gems.map((g) => g.position));
  for (const g of a.gems) {
    const plat = game.find(g.platform);
    const top = plat.position.y + plat.transform.scale.y / 2;
    expect(g.position[1]).toBeGreaterThan(top);
    expect(Math.abs(g.position[0] - plat.position.x)).toBeLessThan(plat.transform.scale.x / 2);
    expect(Math.abs(g.position[2] - plat.position.z)).toBeLessThan(plat.transform.scale.z / 2);
  }
});

test("picking up a gem increments the counter and removes it", () => {
  const { ball, mgr } = load();
  expect(mgr.gems).toBe(0);
  const gem = game.world.findByTag("gem")[0];
  const id = gem.id;
  teleportOnto(ball, gem.position);
  game.step(3);
  expect(mgr.gems).toBe(1);
  expect(game.world.find(id)).toBeNull();
  expect(game.find("hud_gems").get("Text").text).toBe(`Gems 1/${mgr.total}`);
});

test("falling resets to the last checkpoint and costs time", () => {
  const { ball, mgr } = load();
  const t0 = mgr.timeLeft;
  ball.position.y = -20;
  game.step(3);
  expect(ball.position.y).toBeGreaterThan(0);
  expect(Math.abs(ball.position.z - 2)).toBeLessThan(1); // start platform spawn
  expect(mgr.timeLeft).toBeLessThan(t0 - 4.9);
  // touch checkpoint 1, then fall again: respawn there
  const cp = game.find("checkpoint_1");
  teleportOnto(ball, { x: cp.position.x, y: 1.2, z: cp.position.z });
  game.step(5);
  ball.position.y = -20;
  game.step(3);
  expect(Math.abs(ball.position.z - cp.position.z)).toBeLessThan(1);
});

test("timer counts down and expires into the lose screen", () => {
  const { mgr } = load();
  const t0 = mgr.timeLeft;
  game.step(60);
  expect(mgr.timeLeft).toBeCloseTo(t0 - 1, 1);
  mgr.timeLeft = 0.2;
  game.step(20);
  expect(mgr.status).toBe("lost");
  expect(game.find("hud_msg").get("Text").text).toBe("TIME'S UP");
});

test("collecting every gem wins", () => {
  const { ball, mgr } = load();
  for (const gem of game.world.findByTag("gem")) {
    teleportOnto(ball, gem.position);
    game.step(2);
  }
  expect(mgr.gems).toBe(mgr.total);
  expect(mgr.status).toBe("won");
  expect(game.find("hud_msg").get("Text").text).toBe("YOU WIN!");
});

test("restart key reloads the level", () => {
  const { ball, mgr } = load();
  teleportOnto(ball, game.world.findByTag("gem")[0].position);
  game.step(2);
  expect(mgr.gems).toBe(1);
  game.press("restart"); game.step(1); game.release("restart");
  game.step(2);
  const m2 = game.find("game").behaviour;
  expect(m2.gems).toBe(0);
  expect(m2.status).toBe("playing");
});
