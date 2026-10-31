import { test, expect, game } from "factoria:test";

test("every skinned sprite binds at the authored pose when the scene loads", () => {
  game.load("scenes/main.scene.json");
  game.step(1);
  for (let i = 0; i < 50; i++) expect(game.find(`s${i}`).get("SpriteSkin").bindPose.length).toBe(12);
});

test("bones swung by a script bend the picture: the footprint of a free limb changes", () => {
  game.load("scenes/main.scene.json");
  game.step(1);
  const limb = game.find("s1");
  const straight = limb.bounds();
  game.step(60);
  const bent = limb.bounds();
  expect(Math.abs(bent.h - straight.h) + Math.abs(bent.w - straight.w)).toBeGreaterThan(1);
});

test("IK2D brings the tip of the chain to the target, every step, while the target moves", () => {
  game.load("scenes/main.scene.json");
  for (const n of [0, 5, 45]) {
    game.step(10);
    const tip = game.find(`s${n}_tip`).worldPosition;
    const goal = game.find(`t${n}`).worldPosition;
    expect(Math.hypot(tip.x - goal.x, tip.y - goal.y)).toBeLessThan(0.5);
  }
});
