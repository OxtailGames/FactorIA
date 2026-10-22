// P6, release checks that need no GPU: the render budget of every level (what the scene asks the renderer to draw) and
// the exact pixel size of the store and icon files (assets.textureSize answers 32x32 for a missing file, so a missing
// file fails here too). The real draw-call budget is perf.json, checked by `factoria call perf.check`.
import { test, describe, expect, game } from "factoria:test";
import { assets } from "factoria";
import { LEVELS } from "../scripts/levels.js";

// Workaround for FB-0042 (no render stats in the test API): counts what the scene asks for, not what the GPU draws.
// Measured at P6 with the scene running (max over the levels: 416 entities in market_3, 264 meshes in market_3, 20 lights in
// market_2, 12 particle emitters in rooftops_2). About 25% room: a level past it needs a look at the phone first.
const BUDGET = { entities: 520, meshes: 330, lights: 26, emitters: 16 };

function stats() {
  const all = game.world.entities();
  const count = (c) => all.filter((e) => e.has(c)).length;
  return { entities: all.length, meshes: count("MeshRenderer"), lights: count("Light"), emitters: count("ParticleEmitter") };
}

describe("render budget", () => {
  for (const level of LEVELS) {
    test(`${level.id} stays inside the budget`, () => {
      game.load(level.scene);
      game.step(10);
      const s = stats();
      expect(s.entities <= BUDGET.entities).toBe(true);
      expect(s.meshes <= BUDGET.meshes).toBe(true);
      expect(s.lights >= 1 && s.lights <= BUDGET.lights).toBe(true);
      expect(s.emitters <= BUDGET.emitters).toBe(true);
    });
  }
});

const SHOTS = ["01_rooftops_1", "02_rooftops_3", "03_market_2", "04_market_2", "05_rooftops_1"];
const SIZES = [
  ["assets/icon.png", 1024, 1024],
  ["assets/icon_fg.png", 432, 432],
  ["store/keyart.png", 2880, 1620],
];
for (const [dir, w, h] of [["phone", 2868, 1320], ["tablet", 2752, 2064], ["desktop", 1920, 1080]]) {
  for (const shot of SHOTS) SIZES.push([`store/screenshots/${dir}/${shot}.png`, w, h]);
}
for (const [store, w, h] of [
  ["googleplay", 512, 512], ["googleplay", 1024, 500], ["itch", 630, 500],
  ["steam", 748, 896], ["steam", 920, 430], ["steam", 1438, 810], ["steam", 1280, 720],
  ["steam", 600, 900], ["steam", 462, 174], ["steam", 3840, 1240], ["steam", 1232, 706],
]) SIZES.push([`store/capsules/${store}/clockwork-courier_${w}x${h}.png`, w, h]);

describe("icon and store files", () => {
  for (const [path, w, h] of SIZES) {
    test(`${path} is ${w}x${h}`, () => {
      const t = assets.textureSize(path);
      expect(t.width).toBe(w);
      expect(t.height).toBe(h);
    });
  }
});
