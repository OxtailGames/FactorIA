// Pictures to look at (written to .factoria/tmp/, git-ignored): road pieces in every shape, and every building facing every way.
// The asserts only check that the state is what the picture should show; the eyes check the rest.
import { test, expect, game } from "factoria:test";
import { cellToWorld } from "../scripts/game/iso.js";
import { roadPath } from "../scripts/game/rules.js";
import { growTown } from "../scripts/game/bot.js";
import { harbourCell } from "../scripts/game/harbour.js";

function open(zoom, cell) {
  game.load("scenes/game.scene.json", { testMap: true });
  game.step(2);
  const ctl = game.find("controller").behaviour;
  const rig = game.find("camera").behaviour;
  const [x, y] = cellToWorld(cell[0], cell[1]);
  rig.setView(x, y, zoom);
  game.step(2);
  return { ctl, rig, state: ctl.state };
}

test("road pieces: straight, corner, T, crossing, dead end and a lone cell", () => {
  const { state } = open(1.6, [5, 5]);
  state.placeRoads(roadPath([2, 3], [8, 3])); // a long straight row
  state.placeRoads(roadPath([5, 3], [5, 7])); // a branch down: T and crossing with the next
  state.placeRoads(roadPath([3, 5], [7, 5])); // crossing with the branch
  state.placeRoads([[2, 7]]); // lone cell
  state.placeRoads(roadPath([8, 5], [8, 7])); // a corner is made by (7,5)-(8,5) and the new column
  expect(state.list("road").length).toBeGreaterThan(15);
  game.step(2);
  game.screenshot(".factoria/tmp/roads.png");
});

test("every building in every rotation (placed straight on the map, rules aside)", () => {
  for (const [name, types] of [["buildings_a", ["house", "farm", "lumber_camp", "quarry", "sawmill"]], ["buildings_b", ["bakery", "workshop", "warehouse", "market", "fisher_dock"]]]) {
    game.load("scenes/game.scene.json", { seed: 3 });
    game.step(2);
    const ctl = game.find("controller").behaviour;
    const rig = game.find("camera").behaviour;
    const state = ctl.state;
    types.forEach((type, row) => {
      for (let rot = 0; rot < 4; rot++) state.addBuilding(type, 14 + rot * 4, 14 + row * 4, rot, "test");
    });
    const [x, y] = cellToWorld(17, 18);
    rig.setView(x, y, 0.7);
    game.step(2);
    game.screenshot(`.factoria/tmp/${name}.png`);
    expect(state.list()).toHaveLength(20);
  }
});

test("the start: the camera is on the harbour, water in view, the speed buttons in the bar", () => {
  game.load("scenes/game.scene.json");
  game.step(3);
  game.screenshot(".factoria/tmp/start.png");
  expect(game.find("speed_bar")).not.toBe(null);
});

test("a town the bot grew, at midday in the second season and in winter, with villagers walking", () => {
  game.load("scenes/game.scene.json");
  game.step(2);
  const state = game.find("controller").behaviour.state;
  const rig = game.find("camera").behaviour;
  growTown({ state, days: 16 });
  for (let i = 0; i < state.clock.ticksPerDay * 0.4; i++) state.clock.tick(state.clock.step);
  const [x, y] = cellToWorld(...harbourCell(state.map));
  rig.setView(x + 120, y + 30, 1.1);
  game.step(3);
  expect(state.sim.walkers.count).toBeGreaterThan(0);
  game.screenshot(".factoria/tmp/town_summer.png");
  growTown({ state, days: 16 });
  for (let i = 0; i < state.clock.ticksPerDay * 0.4; i++) state.clock.tick(state.clock.step);
  game.step(3);
  game.screenshot(".factoria/tmp/town_winter.png");
});

test("the stress scene: hundreds of walkers", () => {
  game.load("scenes/stress.scene.json");
  game.step(20);
  const state = game.find("controller").behaviour.state;
  for (let i = 0; i < 80; i++) game.step(1);
  expect(state.sim.walkers.count).toBeGreaterThan(100);
  game.screenshot(".factoria/tmp/stress.png");
});
