// @ts-check
// project.save_fixture: make a save of a small bot-grown town in the CURRENT save format. Used to make the files in tests/fixtures/
// (save_v1.json was made when the format was version 1 and is never regenerated; a new version adds its own file, README explains).
import { ToolError } from "factoria";
import { growTown } from "../scripts/game/bot.js";
import { serializeGame, VERSION } from "../scripts/game/savegame.js";
import { makeMeta } from "../scripts/game/save_store.js";
import { getData } from "../scripts/game/data.js";
import { GoalTracker, newScenarioGame, scenarioIds } from "../scripts/game/scenarios.js";

export default {
  name: "save_fixture",
  summary: "Grow a small town with the bot and return its save in the current save format (the source of tests/fixtures files).",
  description:
    "Runs the bot on the 12 x 10 test map for `days` game days, then returns { version, hash, meta, save } (meta: the slot record of that save, as slot 2). `hash` is the state hash of the " +
    "town, which a test compares with the hash of the loaded save. Deterministic: the same arguments give the same save.",
  input: {
    type: "object",
    properties: {
      days: { type: "integer", description: "Game days to run, 1..40 (default 14)." },
      seed: { type: "integer", description: "Map seed for a generated map; leave out for the test map." },
      scenario: { type: "string", description: "Scenario id (first_harbour, river_mills, winter_trade, sandbox): grow that scenario's town instead, with its goal progress in the save." },
    },
  },
  readOnly: true,
  run(args) {
    const days = args.days ?? 14;
    if (!Number.isInteger(days) || days < 1 || days > 40) throw new ToolError("`days` must be a whole number from 1 to 40", "pass days: 14");
    if (args.scenario !== undefined && !scenarioIds().includes(args.scenario)) throw new ToolError(`unknown scenario '${args.scenario}'`, `the scenarios are: ${scenarioIds().join(", ")}`);
    let state;
    let tracker = null;
    if (args.scenario) {
      const made = newScenarioGame(args.scenario, getData());
      tracker = new GoalTracker(made.state, args.scenario, made.def).attach();
      state = growTown({ state: made.state, days }).state;
    } else {
      state = growTown({ seed: args.seed, testMap: args.seed === undefined, days }).state;
    }
    const scenario = args.scenario || "sandbox";
    const meta = makeMeta(state, { slot: 2, kind: "manual", name: "Old harbour", scenario, playSeconds: 754, revision: 7, progress: tracker ? tracker.metaFields() : undefined });
    return { ok: true, version: VERSION, hash: state.hash(), meta, save: serializeGame(state, tracker ? tracker.saveFields() : { scenario }) };
  },
};
