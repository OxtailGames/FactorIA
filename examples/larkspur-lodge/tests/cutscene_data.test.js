// The cut-scene data and its validator: the shipped files are sound, and every kind of mistake is named with its file, JSON pointer,
// a hint and a "did you mean". Edit the cut-scenes in assets/src/build_cutscenes.py, never the JSON.
import { test, describe, expect } from "factoria:test";
import { fa } from "factoria";
import strings from "../locales/en.json";
import broken from "./fixtures/broken_cutscene.json";
import { story, cast } from "../scripts/dialogue_data.js";
import { FILES, rooms, voice, voiceScript } from "../scripts/cutscene_data.js";
import { validateCutscenes, describe as describeProblems } from "../scripts/cutscene_check.js";
import { AREAS } from "../scripts/area.js";

const clone = (v) => JSON.parse(JSON.stringify(v));
const ctx = { strings, story, cast, rooms, voice, voiceScript, areas: Object.keys(AREAS) };
const FIXTURE = "tests/fixtures/broken_cutscene.json";
const INTRO = "data/cutscenes/intro.cutscene.json";

/** The shipped files, copied, with `edit(files)` applied. */
function mutated(edit, extra = {}) {
  const files = clone(FILES);
  edit(files);
  return validateCutscenes(files, { ...ctx, ...extra });
}
const at = (problems, pointer) => problems.find((p) => p.pointer === pointer);

describe("the shipped cut-scenes", () => {
  test("every file, the rooms and the voice manifest are sound", () => {
    expect(validateCutscenes(FILES, ctx)).toEqual([]);
  });

  test("project.validate_cutscenes says so and counts what it read", () => {
    const r = fa.call("project.validate_cutscenes", {});
    expect(r.ok).toBe(true);
    expect(r.counts.cutscenes).toBe(10);
    expect(r.counts.rooms).toBe(6);
  });

  test("the story registry and the files list the same cut-scenes", () => {
    expect(Object.keys(story.cutscenes).sort()).toEqual(Object.values(FILES).map((c) => c.id).sort());
  });

  test("the chapters and the endings each have theirs", () => {
    for (const id of ["intro", "chapter_2", "chapter_3", "chapter_4", "chapter_5", "adit_descent", "adit_rescue", "ending_dawn", "ending_quiet", "ending_long"]) {
      expect(Object.values(FILES).some((c) => c.id === id)).toBe(true);
    }
  });

  test("every voice line of the script is spoken by a caption step", () => {
    const used = new Set();
    for (const c of Object.values(FILES)) for (const s of c.timeline) if (s.voice) used.add(s.voice);
    for (const l of voiceScript.lines) expect(used.has(l.id)).toBe(true);
  });
});

describe("a broken cut-scene is named, with a place and a fix", () => {
  const problems = validateCutscenes({ [FIXTURE]: broken }, ctx);

  test("it fails, and every problem has a file, a pointer, a message and a hint", () => {
    expect(problems.length).toBeGreaterThan(8);
    for (const p of problems) {
      expect(p.message.length).toBeGreaterThan(0);
      expect(p.hint.length).toBeGreaterThan(0);
      expect(typeof p.pointer).toBe("string");
    }
    expect(describeProblems(problems)).toContain(FIXTURE);
  });

  test("a misspelt room, character, step kind, actor and flag come with a did-you-mean", () => {
    expect(at(problems, "/room").didYouMean).toBe("library");
    expect(at(problems, "/actors/mara/cast").didYouMean).toBe("mara");
    expect(at(problems, "/timeline/2/do").didYouMean).toBe("camera");
    expect(at(problems, "/timeline/4/actor").didYouMean).toBe("mara");
    expect(at(problems, "/end/set/0").didYouMean).toBe("intro_seen");
  });

  test("a missing string, a voice line out of the script, a bad range, a bad vector and an unknown field are named", () => {
    expect(at(problems, "/timeline/1/key").message).toContain("cutscene.nope");
    expect(at(problems, "/timeline/1/voice").didYouMean).toBe("intro_01");
    expect(at(problems, "/timeline/0/to").message).toContain("2");
    expect(at(problems, "/timeline/3/pos").hint).toContain("[x, y, z]");
    expect(at(problems, "/timeline/3/ease").didYouMean).toBe("inOut");
    expect(at(problems, "/timeline/5/volume").message).toContain("volume");
  });

  test("a step out of time order, one that outlasts the cut-scene, and a file name that is not the id are named", () => {
    expect(at(problems, "/timeline/2/at").message).toContain("before");
    expect(at(problems, "/timeline/5/seconds").message).toContain("after the cut-scene");
    expect(at(problems, "/id").message).toContain("file name");
  });

  test("the cut-scene is not in the story registry", () => {
    expect(problems.some((p) => p.message.includes("not listed"))).toBe(true);
  });
});

describe("single mistakes in the shipped files", () => {
  test("a duration of zero", () => {
    expect(at(mutated((f) => (f[INTRO].duration = 0)), "/duration")).toBeTruthy();
  });

  test("an unknown room names the rooms", () => {
    const p = at(mutated((f) => (f[INTRO].room = "attic")), "/room");
    expect(p.hint).toContain("hall");
  });

  test("a cut-scene whose file is missing", () => {
    const p = mutated((f) => delete f["data/cutscenes/ending_long.cutscene.json"]).find((x) => x.file === "data/story.json");
    expect(p.pointer).toBe("/cutscenes/ending_long");
  });

  test("a voice clip whose file does not exist, and one that is longer than its step", () => {
    const voiceWith = { format: "larkspur.voice/1", clips: { intro_01: { path: "assets/voice/intro_01.mp3", seconds: 30 } } };
    const p = validateCutscenes(FILES, { ...ctx, voice: voiceWith, fileExists: () => false });
    expect(p.some((x) => x.message.includes("does not exist"))).toBe(true);
    expect(p.some((x) => x.message.includes("lasts 30 s"))).toBe(true);
  });

  test("an end effect that sets an undeclared flag", () => {
    expect(at(mutated((f) => (f[INTRO].end.set = [{ set: "intro_sean" }])), "/end/set/0").didYouMean).toBe("intro_seen");
  });

  test("an actor who is not in the cast", () => {
    const p = at(mutated((f) => (f[INTRO].actors.mara.cast = "marra")), "/actors/mara/cast");
    expect(p.didYouMean).toBe("mara");
  });
});
