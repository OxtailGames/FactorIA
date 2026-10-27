// @ts-check
// project.validate_cutscenes: checks the cut-scene files (data/cutscenes/*.cutscene.json), the rooms (rooms.json) and the voice
// manifest (voice.json) against the locale strings, the story registry, the cast and the voice script, and lists every problem at
// once with the file, the JSON pointer, the fix and a "did you mean".
import { ToolError } from "factoria";
import strings from "../locales/en.json";
import { story, cast } from "../scripts/dialogue_data.js";
import { FILES, rooms, voice, voiceScript } from "../scripts/cutscene_data.js";
import { validateCutscenes, describe } from "../scripts/cutscene_check.js";
import { AREAS } from "../scripts/area.js";

export default {
  name: "validate_cutscenes",
  summary: "Check the cut-scenes: format, timeline order and ranges, actors, strings, voice lines, rooms, end flags and the voice manifest.",
  description:
    "Takes no arguments. Reads data/cutscenes/*.cutscene.json, rooms.json, voice.json and voice_script.json, data/story.json, data/cast.json " +
    "and locales/en.json. Returns { ok: true, counts } when everything is sound; otherwise fails with every problem (file, JSON pointer, " +
    "what is wrong, how to fix it, didYouMean) in the error text and in error.data.problems. Run it after editing assets/src/build_cutscenes.py.",
  input: { type: "object", properties: {} },
  readOnly: true,
  run() {
    const ctx = { strings, story, cast, rooms, voice, voiceScript, areas: Object.keys(AREAS) };
    const problems = validateCutscenes(FILES, ctx);
    if (problems.length) {
      throw new ToolError(describe(problems), "fix the listed entries (edit assets/src/build_cutscenes.py and run it), then run project.validate_cutscenes again", { problems });
    }
    let steps = 0;
    for (const c of Object.values(FILES)) steps += c.timeline.length;
    return { ok: true, counts: { cutscenes: Object.keys(FILES).length, steps, rooms: Object.keys(rooms.rooms).length, voiceClips: Object.keys(voice.clips).length, voiceLines: voiceScript.lines.length } };
  },
};
