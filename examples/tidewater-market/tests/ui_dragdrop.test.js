// Drag and drop of workers (P3): press a villager chip in the inspector, drag it over a workplace on the map, let go.
// Uses the `game` mouse helpers only; the engine has no drag and drop (ENGINE_FEEDBACK), the chip is drawn by ui_hud.js.
import { test, expect, game } from "factoria:test";
import { townScene, cellAt, centreOf, textOf, shown } from "./ui_helper.js";

/** Press on the chip, move to the target in steps like a hand, and (optionally) let go. */
function dragChip(chip, to, release = true) {
  game.mouseMove(centreOf(chip));
  game.step(2);
  game.mouseDown("left");
  game.step(1);
  const from = centreOf(chip);
  for (let i = 1; i <= 5; i++) {
    game.mouseMove({ x: from.x + ((to.x - from.x) * i) / 5, y: from.y + ((to.y - from.y) * i) / 5 });
    game.step(1);
  }
  game.step(2);
  if (release) {
    game.mouseUp("left");
    game.step(2);
  }
}

const workersOf = (state, building) => [...state.sim.people.villagers.values()].filter((v) => v.job === building);

test("dragging a worker's chip onto a workplace with a free place moves and pins the worker", () => {
  const { rig, hud, state, ids } = townScene();
  game.click(cellAt(rig, 5, 3)); // the farm
  game.step(15);
  expect(shown("chip_0")).toBe(true);
  const vid = hud.chipVillagers[0];
  expect(state.sim.people.villagers.get(vid).job).toBe(ids.farm);
  // make room at the smokehouse
  const there = workersOf(state, ids.smokehouse);
  if (there.length) state.sim.people.release(there[0].id);
  expect(state.sim.people.canReassign(vid, ids.smokehouse).ok).toBe(true);
  // while the chip is in flight the chip follows the pointer and the target is coloured
  dragChip("chip_0", cellAt(rig, 7, 3), false);
  expect(hud.chipDrag.active).toBe(true);
  expect(game.find("drag_chip").active).toBe(true);
  expect(hud.chipDrag.over).toBe(ids.smokehouse);
  expect(hud.chipDrag.verdict.ok).toBe(true);
  expect(textOf("drag_chip_text")).toContain(`#${vid}`);
  game.mouseUp("left");
  game.step(2);
  const v = state.sim.people.villagers.get(vid);
  expect(v.job).toBe(ids.smokehouse);
  expect(v.pin).toBe(true);
  expect(game.find("drag_chip").active).toBe(false);
  expect(hud.chipDrag).toBe(null);
  // the drop was not a click on the map: the farm is still the selection
  expect(hud.sel).toEqual({ kind: "building", id: ids.farm });
  expect(textOf("insp_line_3")).toContain("Workers:"); // the farm took on another villager in the freed place
  // the pin survives the sim running on
  state.clock.setSpeed(1);
  game.step(120);
  expect(state.sim.people.villagers.get(vid).job).toBe(ids.smokehouse);
});

test("dragging onto a house, onto nothing, or Esc while dragging changes nothing", () => {
  const { ctl, rig, hud, state, ids } = townScene();
  game.click(cellAt(rig, 5, 3));
  game.step(15);
  const vid = hud.chipVillagers[0];
  const jobBefore = state.sim.people.villagers.get(vid).job;
  // a house has no jobs: red chip, a toast says why
  dragChip("chip_0", cellAt(rig, 2, 4), false);
  expect(hud.chipDrag.over).toBeGreaterThan(0);
  expect(hud.chipDrag.verdict.ok).toBe(false);
  expect(textOf("drag_chip_text")).toContain("no jobs there");
  game.mouseUp("left");
  game.step(2);
  expect(state.sim.people.villagers.get(vid).job).toBe(jobBefore);
  expect(textOf(ctl.toastText)).toContain("no jobs there");
  // dropped on bare ground
  dragChip("chip_0", cellAt(rig, 10, 2));
  expect(state.sim.people.villagers.get(vid).job).toBe(jobBefore);
  expect(state.sim.people.villagers.get(vid).pin).toBeFalsy();
  // Esc during the drag puts it away and the release then does nothing
  const there = workersOf(state, ids.smokehouse);
  if (there.length) state.sim.people.release(there[0].id);
  dragChip("chip_0", cellAt(rig, 7, 3), false);
  expect(hud.chipDrag.active).toBe(true);
  game.press("pause");
  game.press("escape");
  game.step(1);
  game.release("pause");
  game.release("escape");
  game.step(1);
  expect(hud.chipDrag).toBe(null);
  game.mouseUp("left");
  game.step(2);
  expect(state.sim.people.villagers.get(vid).job).toBe(jobBefore);
  // a plain click on a chip (no drag) selects the villager
  game.click("chip_0");
  expect(hud.sel.kind).toBe("villager");
});

test("a drop onto a workplace with no free place is refused with the reason", () => {
  const { ctl, rig, hud, state, ids } = townScene();
  game.click(cellAt(rig, 5, 3));
  game.step(15);
  const vid = hud.chipVillagers[0];
  // fill the smokehouse completely
  const people = state.sim.people;
  const def = state.data.buildings.smokehouse;
  for (const v of people.villagers.values()) {
    if (workersOf(state, ids.smokehouse).length >= def.workers) break;
    if (v.id !== vid && v.job !== ids.smokehouse && people.canReassign(v.id, ids.smokehouse).ok) people.reassign(v.id, ids.smokehouse);
  }
  expect(people.canReassign(vid, ids.smokehouse).code).toBe("full");
  dragChip("chip_0", cellAt(rig, 7, 3));
  expect(people.villagers.get(vid).job).toBe(ids.farm);
  expect(textOf(ctl.toastText)).toContain("no free place");
});
