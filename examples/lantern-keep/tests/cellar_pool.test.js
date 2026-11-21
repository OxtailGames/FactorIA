import { test, expect, game } from "factoria:test";
import { fa, scene } from "factoria";

// The cellar pool scene (M74.4): a Water2D that reflects two emissive lanterns, and a DistortionZone2D heat haze over a brazier.
// It is not part of the game's flow (the menu and the levels never load it); it shows the 2D lighting and water of the engine.
const POOL = "scenes/cellar_pool.scene.json";

test("the cellar pool scene loads and has its water, its haze and its lights", () => {
  game.load(POOL);
  game.step(3);
  expect(scene.current).toBe(POOL);

  const water = game.find("pool").get("Water2D");
  expect(water.size[0]).toBe(760);
  expect(water.reflection).toBeGreaterThan(0.5);
  expect(water.refraction).toBeGreaterThan(0);
  expect(water.layer).toBe(10);

  const haze = game.find("heat_haze").get("DistortionZone2D");
  expect(haze.strength).toBeGreaterThan(0);
  // The haze reads the picture after the water and everything under it: a higher layer than the water.
  expect(haze.layer).toBeGreaterThan(water.layer);

  // The lanterns glow (emissive) and light the pool's surroundings; the pillar and the brazier cast shadows.
  for (const id of ["lantern_left", "lantern_right"]) {
    expect(game.find(id).get("Sprite").emissiveIntensity).toBeGreaterThan(1);
    expect(game.find(id).get("Light2D").castShadows).toBe(true);
  }
  expect(game.find("pillar").get("ShadowCaster2D").enabled).toBe(true);
  expect(game.find("brazier").get("ShadowCaster2D").enabled).toBe(true);
});

test("the pool is not the start scene, and the water is above the pool's floor and below the haze in the draw order", () => {
  const project = JSON.parse(fa.call("fs.read", { path: "factoria.json" }).content);
  expect(project.mainScene).not.toBe(POOL);
  game.load(POOL);
  game.step(2);
  const water = game.find("pool").get("Water2D");
  // What is drawn on a lower layer than the water is seen refracted and reflected by it: the floor of the pool and the fish are.
  expect(game.find("basin_floor").get("Sprite").layer).toBeLessThan(water.layer);
  expect(game.find("fish").get("Sprite").layer).toBeLessThan(water.layer);
  expect(game.find("lantern_left").get("Sprite").layer).toBeLessThan(water.layer);
});
