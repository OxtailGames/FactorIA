// Game feel of Sky Hopper (docs/GAME_FEEL.md): the baked coin sparkle, the shake and hit-stop of a stomp and a hurt, the
// red flash, and the jump's squash that is DATA (an event of anim/hero_jump.anim.json). Everything runs on the fixed step of
// game.step, so no assertion depends on the speed of the machine: every wait is a count of steps.
import { test, expect, game } from "factoria:test";
import { fa } from "factoria";
import assetsFile from "../assets.json";
import jumpClip from "../anim/hero_jump.anim.json";
import { state, resetState } from "scripts/game_state.js";

function load() {
  resetState();
  game.load("scenes/level1.scene.json");
  game.step(30); // settle onto the ground
  return game.find("player");
}

const feelState = () => fa.call("feel.state", {});
const entry = (id) => feelState().entities.find((e) => e.entity === id);
const sparkles = () => game.world.findByTag("fx").filter((e) => e.name === "Coin Sparkle");

test("a coin plays the sparkle: three layers in step, the light added, gone after its lifetime", () => {
  const p = load();
  const coin = game.find("coin_1");
  const at = [coin.position.x, coin.position.y];
  p.position.x = at[0];
  p.position.y = at[1];
  game.step(3);
  expect(game.find("coin_1")).toBeNull();
  expect(state.coins).toBe(1);
  const fx = sparkles();
  expect(fx.length).toBe(1);
  // where the coin was
  expect(Math.abs(fx[0].position.x - at[0])).toBeLessThan(1);
  expect(Math.abs(fx[0].position.y - at[1])).toBeLessThan(1);
  const layers = fx[0].children.map((c) => ({ name: c.name, sprite: c.get("Sprite"), anim: c.get("SpriteAnimator") }));
  expect(layers.map((l) => l.name)).toEqual(["Back", "Front", "Light"]);
  // behind the hero (layers 3..9), in front of it, and the light added on top
  expect(layers[0].sprite.layer).toBeLessThan(3);
  expect(layers[1].sprite.layer).toBeGreaterThan(9);
  expect(layers[2].sprite.blend).toBe("additive");
  // the same clip on all three, so they stay in step
  for (const l of layers) expect(l.anim.clip).toBe("coin_sparkle");
  // 0.55 s of game time is 33 steps; 60 is far past it
  game.step(60);
  expect(sparkles().length).toBe(0);
});

test("the sparkle sheets are baked from one module with a ramp and three layers", () => {
  const assets = assetsFile.assets;
  for (const layer of ["back", "front", "light"]) {
    const a = assets[`assets/fx/coin_sparkle_${layer}.png`];
    expect(a).toBeDefined();
    expect(a.provenance.recipe.command).toBe("assets.animate_svg");
    expect(a.provenance.recipe.args.layers).toEqual(["back", "front", "light"]);
    expect(a.provenance.recipe.args.ramp.length).toBe(4);
    expect(a.provenance.recipe.args.source).toBe("assets/src/anim/coin_sparkle.anim.js");
    // the clip the prefab plays, not looping: the sparkle happens once
    expect(a.sheet.clips[0].name).toBe("coin_sparkle");
    expect(a.sheet.clips[0].loop).toBe(false);
  }
});

test("a stomp shakes the camera and holds the game for a moment, then both end", () => {
  const p = load();
  const e = game.find("enemy_1");
  p.position.x = e.position.x;
  p.position.y = e.position.y + 80;
  game.world.find("player").get("RigidBody2D").velocity.y = -100;
  for (let i = 0; i < 60 && game.find("enemy_1"); i++) game.step(1);
  expect(game.find("enemy_1")).toBeNull();
  game.step(1);
  const cam = entry(game.find("camera").id);
  expect(cam && cam.shake).toBeTruthy();
  expect(cam.shake.trauma).toBeGreaterThan(0.1);
  // 0.05 s of hit-stop is three fixed steps: still running one step after the stomp, over well before 60
  expect(feelState().hitStop.remaining).toBeGreaterThan(0);
  game.step(60);
  expect(entry(game.find("camera").id)).toBeUndefined();
  expect(feelState().hitStop.remaining).toBe(0);
});

test("a hurt flashes the hero red, shakes harder than a stomp and holds the game longer", () => {
  const p = load();
  const e = game.find("enemy_1");
  p.position.x = e.position.x - 60;
  p.position.y = e.position.y;
  game.press("move_right");
  for (let i = 0; i < 90 && state.lives === 3; i++) game.step(1);
  game.release("move_right");
  expect(state.lives).toBe(2);
  const hero = entry(p.id);
  expect(hero && hero.flash).toBeTruthy();
  const cam = entry(game.find("camera").id);
  expect(cam.shake.trauma).toBeGreaterThan(0.25);
  // a flash is a drawn colour: the Tint of the hero (the invulnerability blink) is not what it reads
  game.step(60);
  expect(entry(p.id) && entry(p.id).flash).toBeFalsy();
});

test("the jump's squash is an event of the clip, so the animation file carries it", () => {
  const clip = jumpClip;
  expect(clip.events.length).toBe(1);
  expect(clip.events[0].feel[0].action).toBe("squash");
  const p = load();
  game.press("jump");
  game.step(6);
  game.release("jump");
  const hero = entry(p.id);
  expect(hero && hero.squash).toBeTruthy();
  // drawn only: the scale of the entity is what the scene says
  expect(p.transform.scale.x).toBeCloseTo(1, 5);
  expect(p.transform.scale.y).toBeCloseTo(1, 5);
  game.step(60);
  expect(entry(p.id) && entry(p.id).squash).toBeFalsy();
});

test("reduced motion: a stomp shakes a quarter as much", () => {
  const trauma = (reduce) => {
    const p = load();
    fa.call("feel.settings", { reduceMotion: reduce });
    const e = game.find("enemy_1");
    p.position.x = e.position.x;
    p.position.y = e.position.y + 80;
    game.world.find("player").get("RigidBody2D").velocity.y = -100;
    for (let i = 0; i < 60 && game.find("enemy_1"); i++) game.step(1);
    game.step(1);
    const cam = entry(game.find("camera").id);
    return cam && cam.shake ? cam.shake.trauma : 0;
  };
  let full, reduced;
  try {
    full = trauma(false);
    reduced = trauma(true);
  } finally {
    fa.call("feel.settings", { reduceMotion: null });
  }
  expect(full).toBeGreaterThan(0.1);
  expect(reduced).toBeLessThan(full * 0.5);
});
