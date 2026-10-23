// P6, release checks: the render budget of every level (what game.renderStats() says the renderer drew, or what the
// scene asks for on a machine without a GPU) and the exact pixel size of the icon and store files (assets.textureSize
// answers 32x32 for a missing file). The icons and the key art are in git, so a missing one fails. The screenshots and
// capsules are not (store/make_store_images.py writes them): they are checked when they are there. The real draw-call
// budget is perf.json (`factoria call perf.check`).
import { test, describe, expect, game } from "factoria:test";
import { assets } from "factoria";
import { LEVELS } from "../scripts/levels.js";

// What the renderer really draws (game.renderStats(): triangles, lights, shadow casters, draw calls, texture memory), per
// level, with about 25% room over the measured maximum (30387 triangles and 20 lights in market_2, 126 shadow casters
// in market_3, 118 draw calls in market_3). A level past it needs a look on the phone first. On a machine without a GPU
// renderStats throws, so the test falls back to counting what the scene asks for (entities, meshes, lights, emitters).
const BUDGET = { triangles: 38000, lights: 26, shadowCasters: 160, drawCalls: 150, textureMB: 6, entities: 520, meshes: 330, emitters: 16 };

function counts() {
  const all = game.world.entities();
  const count = (c) => all.filter((e) => e.has(c)).length;
  return { entities: all.length, meshes: count("MeshRenderer"), lights: count("Light"), emitters: count("ParticleEmitter") };
}

describe("render budget", () => {
  for (const level of LEVELS) {
    test(`${level.id} stays inside the budget`, () => {
      game.load(level.scene);
      game.step(10);
      const c = counts();
      expect(c.entities <= BUDGET.entities).toBe(true);
      expect(c.meshes <= BUDGET.meshes).toBe(true);
      expect(c.emitters <= BUDGET.emitters).toBe(true);
      let s = null;
      try { s = game.renderStats(); } catch (e) { /* no GPU on this machine */ }
      const lights = s ? s.lights : c.lights;
      expect(lights >= 1 && lights <= BUDGET.lights).toBe(true);
      if (s) {
        expect(s.triangles <= BUDGET.triangles).toBe(true);
        expect(s.shadowCasters <= BUDGET.shadowCasters).toBe(true);
        expect(s.drawCalls <= BUDGET.drawCalls).toBe(true);
        expect(s.textureMB <= BUDGET.textureMB).toBe(true);
      }
    });
  }
});

const SHOTS = ["01_rooftops_1", "02_rooftops_3", "03_market_2", "04_market_2", "05_rooftops_1"];
const IN_GIT = [
  ["assets/icon.png", 1024, 1024],
  ["assets/icon_fg.png", 432, 432],
  ["store/keyart.png", 2880, 1620],
];
const GENERATED = [];
for (const [dir, w, h] of [["phone", 2868, 1320], ["tablet", 2752, 2064], ["desktop", 1920, 1080]]) {
  for (const shot of SHOTS) GENERATED.push([`store/screenshots/${dir}/${shot}.png`, w, h]);
}
for (const [store, w, h] of [
  ["googleplay", 512, 512], ["googleplay", 1024, 500], ["itch", 630, 500],
  ["steam", 748, 896], ["steam", 920, 430], ["steam", 1438, 810], ["steam", 1280, 720],
  ["steam", 600, 900], ["steam", 462, 174], ["steam", 3840, 1240], ["steam", 1232, 706],
]) GENERATED.push([`store/capsules/${store}/clockwork-courier_${w}x${h}.png`, w, h]);

const missing = (t) => t.width === 32 && t.height === 32;  // no store image is 32x32

describe("icon and store files", () => {
  for (const [path, w, h] of IN_GIT) {
    test(`${path} is ${w}x${h}`, () => {
      const t = assets.textureSize(path);
      expect(t.width).toBe(w);
      expect(t.height).toBe(h);
    });
  }
  for (const [path, w, h] of GENERATED) {
    test(`${path} is ${w}x${h} when it is there`, () => {
      const t = assets.textureSize(path);
      if (missing(t)) return;
      expect(t.width).toBe(w);
      expect(t.height).toBe(h);
    });
  }
});
