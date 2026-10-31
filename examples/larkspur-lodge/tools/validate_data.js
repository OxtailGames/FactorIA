// @ts-check
// project.validate_data: checks the data tables (data/items.json, combos.json, puzzles.json, notebook.json) against the locale strings and the scenes, and lists every
// problem at once, with the file, the JSON pointer, the fix and a "did you mean".
import { ToolError } from "factoria";
import table from "../data/items.json";
import strings from "../locales/en.json";
import ground from "../scenes/ground.scene.json";
import upstairs from "../scenes/upstairs.scene.json";
import cellar from "../scenes/cellar.scene.json";
import testRoom from "../scenes/test_room.scene.json";
import combos from "../data/combos.json";
import puzzleTable from "../data/puzzles.json";
import notebookTable from "../data/notebook.json";
import story from "../data/story.json";
import { validateItems } from "../scripts/items.js";
import { validatePuzzles } from "../scripts/puzzles.js";
import { validateNotebook } from "../scripts/notebook.js";

export default {
  name: "validate_data",
  summary: "Check the item catalogue (data/items.json), the combinations, the puzzles and the notebook against the locale strings, the story flags and the doors and item boxes of the scenes.",
  description:
    "Takes no arguments. Returns { ok: true, counts } when the table is sound; otherwise fails with every problem " +
    "(file, JSON pointer, what is wrong, how to fix it) in the error and in error.data.problems. Run it after editing data/items.json or a door.",
  input: { type: "object", properties: {} },
  readOnly: true,
  run() {
    const scenes = {
      "scenes/ground.scene.json": ground,
      "scenes/upstairs.scene.json": upstairs,
      "scenes/cellar.scene.json": cellar,
      "scenes/test_room.scene.json": testRoom,
    };
    const problems = [
      ...validateItems(table, { strings, scenes, combos }),
      ...validatePuzzles(puzzleTable, { strings, items: table, flags: Object.keys(story.flags) }),
      ...validateNotebook(notebookTable, { strings, flags: Object.keys(story.flags), prefixes: Object.keys(story.flagPrefixes) }),
    ];
    if (problems.length) {
      const text = problems.map((p) => `${p.file} ${p.pointer || "(file)"}: ${p.message}. ${p.hint}`).join("\n");
      throw new ToolError(text, "fix the listed entries, then run project.validate_data again", { problems });
    }
    const kinds = {};
    for (const item of Object.values(table.items)) kinds[item.kind] = (kinds[item.kind] ?? 0) + 1;
    return {
      ok: true,
      counts: { items: Object.keys(table.items).length, kinds, combos: combos.combos.length, clues: notebookTable.clues.length, deductions: notebookTable.deductions.length },
    };
  },
};
