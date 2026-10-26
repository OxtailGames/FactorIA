// @ts-check
// How a game screen gets its game. The slot screen (and the Continue button) put a request in session.boot before loading
// scenes/game.scene.json; the game controller calls takeBoot() once, in onStart:
//   { slot, kind }                 load that slot entry ("manual" | "auto")
//   { slot, scenario, name }       a new game of a scenario (its map, start and goals), which belongs to that slot from now on
//   nothing                        the old way: scene props decide (tests, `factoria run`): no slot, nothing autosaved
// The request is removed when taken, so reloading the scene never repeats it.
import { session } from "factoria";
import { loadEntry } from "./save_store.js";
import { GoalTracker, newScenarioGame, scenarioTable } from "./scenarios.js";

/**
 * @param {ReturnType<typeof import("./data.js").getData>} data
 * @returns {{ state: import("./state.js").GameState | null, run: { slot: number, scenario: string, name: string, playSeconds: number, tracker?: any }, error?: any, migratedFrom?: number | null }}
 */
export function takeBoot(data) {
  const request = session.boot;
  session.boot = undefined;
  const run = { slot: 0, scenario: "sandbox", name: "", playSeconds: 0 };
  if (!request) return { state: null, run };
  if (request.scenario === undefined) {
    const res = loadEntry(request.slot, request.kind || "manual", data);
    if (res.ok) {
      run.slot = request.slot;
      run.scenario = res.save.scenario;
      run.name = res.meta ? res.meta.name : "";
      run.playSeconds = res.meta ? res.meta.playSeconds : 0;
      run.tracker = new GoalTracker(res.state, run.scenario, undefined, res.save.progress).attach();
      return { state: res.state, run, migratedFrom: res.migratedFrom };
    }
    return { state: null, run, error: res.error }; // the caller starts a fresh game and says why
  }
  run.slot = request.slot;
  run.scenario = request.scenario;
  run.name = request.name || "";
  if (!scenarioTable()[request.scenario]) return { state: null, run: { ...run, slot: 0 }, error: { code: "invalid", pointer: "", message: `unknown scenario '${request.scenario}'`, hint: "pick one from the slot screen" } };
  const { state, def } = newScenarioGame(request.scenario, data);
  run.tracker = new GoalTracker(state, request.scenario, def).attach();
  return { state, run };
}
