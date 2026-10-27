// @ts-check
// project.validate_dialogue: checks the dialogue tables (data/dialogue/*.json), the story registry (data/story.json) and the cast
// (data/cast.json) against the locale strings, the item catalogue, the doors of the scenes and each other, and lists every problem
// at once with the file, the JSON pointer, the fix and a "did you mean".
import { ToolError } from "factoria";
import strings from "../locales/en.json";
import es from "../locales/es.json";
import de from "../locales/de.json";
import ko from "../locales/ko.json";
import he from "../locales/he.json";
import items from "../data/items.json";
import ground from "../scenes/ground.scene.json";
import upstairs from "../scenes/upstairs.scene.json";
import cellar from "../scenes/cellar.scene.json";
import testRoom from "../scenes/test_room.scene.json";
import { TABLES, story, cast, doorIds } from "../scripts/dialogue_data.js";
import { validateDialogue, validateStory, validateCast, describe } from "../scripts/dialogue_check.js";
import { AREAS } from "../scripts/area.js";

export default {
  name: "validate_dialogue",
  summary: "Check the dialogue tables, the story registry and the cast: dangling ids, unreachable nodes, unknown flags, items and speakers, missing strings and missing translations.",
  description:
    "Takes no arguments. Reads data/dialogue/*.json, data/story.json, data/cast.json, data/items.json, locales/*.json (every line, choice, chapter, ending and name must exist in es, de, ko and he too) and the doors of the scenes. " +
    "Returns { ok: true, counts } when everything is sound; otherwise fails with every problem (file, JSON pointer, what is wrong, how to fix it, " +
    "didYouMean) in the error text and in error.data.problems. Run it after editing the story (assets/src/story/*.py, then assets/src/build_story.py).",
  input: { type: "object", properties: {} },
  readOnly: true,
  run() {
    const doors = doorIds({ ground, upstairs, cellar, testRoom });
    const ctx = { strings, translations: { es, de, ko, he }, story, cast, items, doors, areas: Object.keys(AREAS) };
    const problems = [...validateStory(story, ctx), ...validateCast(cast, ctx), ...validateDialogue(TABLES, ctx)];
    if (problems.length) {
      throw new ToolError(describe(problems), "fix the listed entries (edit assets/src/story/*.py and run build_story.py), then run project.validate_dialogue again", { problems });
    }
    let nodes = 0;
    let conversations = 0;
    for (const table of Object.values(TABLES)) {
      for (const c of Object.values(table.conversations)) {
        conversations++;
        nodes += Object.keys(c.nodes).length;
      }
    }
    return { ok: true, counts: { conversations, nodes, flags: Object.keys(story.flags).length, chapters: story.chapters.length, characters: Object.keys(cast.characters).length } };
  },
};
