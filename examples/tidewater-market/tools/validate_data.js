// @ts-check
// project.validate_data: check the data tables (data/*.json) against each other and against the atlas and the locale
// strings. The game runs the same check when it starts and refuses to start on a mistake; this tool lists every problem
// at once, with the file, the JSON pointer, the fix and a "did you mean".
import { ToolError } from "factoria";
import { rawTables, validateTables, formatProblems } from "../scripts/game/data.js";

export default {
  name: "validate_data",
  summary: "Check the data tables (buildings, goods, recipes, terrain, economy, map) and report every mistake.",
  description:
    "Takes no arguments. Returns { ok: true, counts } when the tables are sound; otherwise fails with every problem " +
    "(file, JSON pointer, what is wrong, how to fix it) in the error and in error.data.problems. Run it after editing data/*.json.",
  input: { type: "object", properties: {} },
  readOnly: true,
  run() {
    const problems = validateTables(rawTables);
    if (problems.length) throw new ToolError(formatProblems(problems), "fix the listed entries in data/*.json, then run project.validate_data again", { problems });
    return {
      ok: true,
      counts: {
        terrain: Object.keys(rawTables.terrain.terrain).length,
        goods: Object.keys(rawTables.goods.goods).length,
        buildings: Object.keys(rawTables.buildings.buildings).length,
        recipes: Object.keys(rawTables.recipes.recipes).length,
        atlasFrames: Object.keys(rawTables.atlas.frames).length,
      },
    };
  },
};
