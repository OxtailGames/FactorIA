// The render budget of the busiest floor: four miners, every torch down, the crystals or magma glowing, the enemies and the HUD,
// drawn by the real renderer in a headless run. The same scene (scenes/busiest.scene.json) is what perf.json and the engine's
// ctest perf file measure; the numbers here are the caps of those files (perf.json "budgets"), so a change that makes the floor
// heavier fails here first, with the floor named.
import { test, describe, expect, game } from "factoria:test";
import { cleanBeforeEach, activeLights, miners } from "./helpers/world.js";
import { override } from "../scripts/game/busiest.js";
import { live } from "../scripts/game/mine_map.js";
import { run } from "../scripts/game/run_state.js";
import { ENGINE_LIGHT_CAP } from "../scripts/game/lights.js";

/** The caps of perf.json "budgets" (keep them equal). */
const MAX_DRAW_CALLS = 24;
const MAX_ENTITIES = 200;
const MAX_TEXTURE_MB = 4;

function busiest(stratum, floor, miners = 4) {
  for (const k of Object.keys(override)) delete override[k];
  Object.assign(override, { stratum, floor, miners });
  game.load("scenes/busiest.scene.json");
  game.step(120);
}

describe("the busiest floor", () => {
  cleanBeforeEach();

  test("Crystal Caves floor 3 with four miners and every light on stays under the draw-call budget", () => {
    busiest(1, 3);
    expect(miners().length).toBe(4);
    // every light the game has: four lamps, the six torches and the crystals fill the pool up to the engine's 16
    expect(live.lights.torches.length).toBe(6);
    expect(run.torches).toBe(0);
    expect(live.lights.sources.filter((s) => s.kind === "crystal").length).toBeGreaterThan(10);
    expect(activeLights().length).toBe(ENGINE_LIGHT_CAP);
    const stats = game.renderStats();
    expect(stats.lightsDropped).toBe(0);
    expect(stats.drawCalls).toBeLessThanOrEqual(MAX_DRAW_CALLS);
    expect(stats.textureMB).toBeLessThanOrEqual(MAX_TEXTURE_MB);
    expect(game.world.entities().length).toBeLessThanOrEqual(MAX_ENTITIES);
  });

  test("so does every other floor of the descent with four miners", () => {
    for (let stratum = 0; stratum < 3; stratum++) {
      for (let floor = 1; floor <= 3; floor++) {
        busiest(stratum, floor);
        const where = `stratum ${stratum} floor ${floor}`;
        const stats = game.renderStats();
        expect(`${where}: ${stats.drawCalls} draw calls`).toBe(`${where}: ${Math.min(stats.drawCalls, MAX_DRAW_CALLS)} draw calls`);
        expect(activeLights().length).toBeLessThanOrEqual(ENGINE_LIGHT_CAP);
        expect(game.world.entities().length).toBeLessThanOrEqual(MAX_ENTITIES);
      }
    }
  });

  test("the set-up is the same every time: one seed, one mine, the same entities", () => {
    busiest(1, 3);
    const first = { hash: live.mine.hash, entities: game.world.entities().length };
    busiest(1, 3);
    expect(live.mine.hash).toBe(first.hash);
    expect(game.world.entities().length).toBe(first.entities);
  });
});
