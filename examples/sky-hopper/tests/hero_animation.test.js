// The hero is built in parts and animated by clips (anim/hero_*.anim.json) through the Animator state machine of
// prefabs/player.prefab.json; scripts/player.js feeds it and puts the IK feet on the ground. The crawler is a baked sheet.
import { test, expect, game } from "factoria:test";
import { fa } from "factoria";
import { resetState } from "scripts/game_state.js";

function load() {
  resetState();
  game.load("scenes/level1.scene.json");
  game.step(30);
  return game.find("player");
}

function part(root, name) {
  for (const c of root.children) {
    if (c.name === name) return c;
    const d = part(c, name);
    if (d) return d;
  }
  return null;
}

function pose(p) {
  return ["thigh_f", "shin_f", "arm_f", "head"].map((n) => {
    const e = part(p, n);
    return [e.worldPosition.x, e.worldPosition.y];
  });
}

const state = (p) => fa.call("scene.get_entity", { id: "player" }).components.Animator.state;

test("the hero's parts move while it idles and while it walks", () => {
  const p = load();
  expect(state(p)).toBe("idle");
  const a = JSON.stringify(pose(p));
  game.step(20);
  expect(JSON.stringify(pose(p))).not.toBe(a); // breathing
  const b = JSON.stringify(pose(p));
  game.press("move_right");
  game.step(20);
  expect(state(p)).toBe("walk");
  expect(JSON.stringify(pose(p))).not.toBe(b);
  game.release("move_right");
});

test("the Animator goes idle -> walk -> jump -> idle with the movement", () => {
  const p = load();
  game.press("move_right"); game.step(10);
  expect(state(p)).toBe("walk");
  game.press("jump"); game.step(6);
  expect(state(p)).toBe("jump");
  game.release("jump"); game.release("move_right");
  game.step(120);
  expect(state(p)).toBe("idle");
});

test("the mirror: the rig turns with the direction and keeps the knees forward", () => {
  const p = load();
  const rig = part(p, "rig");
  game.press("move_left"); game.step(6);
  expect(rig.transform.scale.x).toBe(-1);
  game.release("move_left");
  game.press("move_right"); game.step(6);
  expect(rig.transform.scale.x).toBe(1);
  game.release("move_right");
});

test("the IK feet reach the ground while the hero stands and walks", () => {
  const p = load();
  const sole = () => ["f", "b"].map((s) => part(p, "ik_" + s).worldPosition.y);
  const check = () => {
    for (const s of ["f", "b"]) {
      const t = part(p, "ik_" + s).worldPosition;
      const shin = part(p, "shin_" + s);
      expect(shin.worldPosition.y).toBeGreaterThan(t.y); // the knee-ankle chain ends at the target, above the sole
    }
  };
  check();
  // planted foot: at rest the ankle is a few units above the top of the ground, which is the collider's bottom edge
  const ground = game.find("player").position.y - 23;
  for (const y of sole()) expect(Math.abs(y - (ground + 2.5))).toBeLessThan(3);
  game.press("move_right");
  for (let i = 0; i < 30; i++) { game.step(2); check(); }
  game.release("move_right");
});

test("hero animation is deterministic", () => {
  const run = () => {
    const p = load();
    game.press("move_right"); game.step(25);
    game.press("jump"); game.step(5); game.release("jump");
    game.step(15);
    const out = JSON.stringify({ pose: pose(p), x: p.position.x, y: p.position.y, s: state(p) });
    game.release("move_right");
    return out;
  };
  expect(run()).toBe(run());
});

test("the crawler is drawn from a baked sheet whose recipe is in assets.json", () => {
  const sheet = JSON.parse(fa.call("fs.read", { path: "assets.json" }).content).assets["assets/crawler_sheet.png"];
  expect(sheet.sheet.clips.map((c) => c.name)).toEqual(["crawl", "alert"]);
  const text = JSON.stringify(sheet.provenance.recipe);
  expect(text).toContain("assets.bake_sheet");
  expect(text).toContain("crawler_rig");
  expect(text).toContain('"clip":"crawl"');
  expect(text).toContain('"clip":"alert"');
  load();
  const e = game.find("enemy_1");
  expect(e.get("Sprite").texture).toBe("assets/crawler_sheet.png");
  expect(e.get("SpriteAnimator").clip).toBe("crawl");
});
