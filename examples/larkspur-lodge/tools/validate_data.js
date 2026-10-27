// @ts-check
// project.validate_data: checks the data tables (data/items.json) against the locale strings and the scenes, and lists every
// problem at once, with the file, the JSON pointer, the fix and a "did you mean".
import { ToolError } from "factoria";
import table from "../data/items.json";
import strings from "../locales/en.json";
import ground from "../scenes/ground.scene.json";
import upstairs from "../scenes/upstairs.scene.json";
import cellar from "../scenes/cellar.scene.json";
import testRoom from "../scenes/test_room.scene.json";
import { validateItems } from "../scripts/items.js";

export default {
  name: "validate_data",
  summary: "Check the item catalogue (data/items.json) against the locale strings and the doors and item boxes of the scenes.",
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
    const problems = validateItems(table, { strings, scenes });
    if (problems.length) {
      const text = problems.map((p) => `${p.file} ${p.pointer || "(file)"}: ${p.message}. ${p.hint}`).join("\n");
      throw new ToolError(text, "fix the listed entries, then run project.validate_data again", { problems });
    }
    const kinds = {};
    for (const item of Object.values(table.items)) kinds[item.kind] = (kinds[item.kind] ?? 0) + 1;
    return { ok: true, counts: { items: Object.keys(table.items).length, kinds } };
  },
};
