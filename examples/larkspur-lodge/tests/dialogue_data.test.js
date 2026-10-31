// The story data and its validator: the shipped dialogue tables, story registry and cast are sound, and every kind of mistake
// is named with its file, JSON pointer, a hint and a "did you mean". Edit the story in assets/src/story/*.py, never the JSON.
import { test, describe, expect } from "factoria:test";
import { fa } from "factoria";
import strings from "../locales/en.json";
import es from "../locales/es.json";
import de from "../locales/de.json";
import ko from "../locales/ko.json";
import he from "../locales/he.json";
import items from "../data/items.json";
import broken from "./fixtures/broken_dialogue.json";
import ground from "../scenes/ground.scene.json";
import upstairs from "../scenes/upstairs.scene.json";
import cellar from "../scenes/cellar.scene.json";
import testRoom from "../scenes/test_room.scene.json";
import { TABLES, story, cast, doorIds } from "../scripts/dialogue_data.js";
import { validateDialogue, validateStory, validateCast, describe as describeProblems } from "../scripts/dialogue_check.js";
import { AREAS } from "../scripts/area.js";

const clone = (v) => JSON.parse(JSON.stringify(v));
const doors = doorIds({ ground, upstairs, cellar, testRoom });
const translations = { es, de, ko, he };
const ctx = { strings, translations, story, cast, items, doors, areas: Object.keys(AREAS) };

/** The shipped tables, copied, with `edit(tables)` applied. */
function mutated(edit) {
  const tables = clone(TABLES);
  edit(tables);
  return validateDialogue(tables, ctx);
}
const first = (problems, pointerPart) => problems.find((p) => p.pointer.includes(pointerPart));

describe("the shipped story data", () => {
  test("the tables, the story registry and the cast are sound", () => {
    expect(validateStory(story, ctx)).toEqual([]);
    expect(validateCast(cast, ctx)).toEqual([]);
    expect(validateDialogue(TABLES, ctx)).toEqual([]);
  });

  test("every line, choice, chapter, ending and name is translated into es, de, ko and he", () => {
    expect(Object.keys(translations)).toEqual(["es", "de", "ko", "he"]);
    expect(validateStory(story, ctx).filter((p) => p.message.includes("no translation"))).toEqual([]);
    expect(validateDialogue(TABLES, ctx).filter((p) => p.message.includes("no translation"))).toEqual([]);
  });

  test("project.validate_dialogue says so and counts what it read", () => {
    const r = fa.call("project.validate_dialogue", {});
    expect(r.ok).toBe(true);
    expect(r.counts.chapters).toBe(5);
    expect(r.counts.characters).toBe(6);
    expect(r.counts.conversations).toBe(Object.values(TABLES).reduce((n, t) => n + Object.keys(t.conversations).length, 0));
    expect(r.counts.nodes).toBeGreaterThan(150);
  });

  test("every node id is the locale key of its text and every text is in the strings", () => {
    for (const table of Object.values(TABLES)) {
      for (const [cid, conv] of Object.entries(table.conversations)) {
        for (const [nodeId, node] of Object.entries(conv.nodes)) {
          expect(nodeId.startsWith(`dlg.${cid}.`)).toBe(true);
          if (node.route) continue;
          const key = nodeId.split(".");
          let leaf = strings;
          for (const part of key) leaf = leaf?.[part];
          expect(typeof leaf).toBe("string");
        }
      }
    }
  });

  test("the story has five chapters, three endings and six characters, each placed in every chapter they appear in", () => {
    expect(story.chapters.map((c) => c.id)).toEqual([1, 2, 3, 4, 5]);
    expect(Object.keys(story.endings).sort()).toEqual(["dawn", "long", "quiet"]);
    expect(Object.keys(cast.characters).sort()).toEqual(["haas", "hedda", "lucian", "mara", "tobias", "vale"]);
    for (const [id, c] of Object.entries(cast.characters)) {
      for (const [chapter, place] of Object.entries(c.schedule)) {
        expect(story.places[place], `${id} in chapter ${chapter}`).toBeTruthy();
        expect(c.talk[chapter], `${id} talks in chapter ${chapter}`).toBeTruthy();
      }
    }
  });

  test("a line may name a voice clip for P4 and none is required", () => {
    let voiced = 0;
    for (const table of Object.values(TABLES)) {
      for (const conv of Object.values(table.conversations)) for (const node of Object.values(conv.nodes)) if (node.voice) voiced++;
    }
    expect(voiced).toBeGreaterThan(100);
  });
});

describe("a broken table is named, with a place and a fix", () => {
  const smallStrings = { dlg: { broken: { hello: "Hi", menu: "Menu", menu_c1: "a", menu_c2: "b", orphan: "o" } } };
  const smallCast = { characters: { mara: { talk: { 1: "broken" } } } };
  const problems = validateDialogue({ "tests/fixtures/broken_dialogue.json": broken }, { strings: smallStrings, story, cast: smallCast, items });

  test("a line or choice missing from one language is named with that language", () => {
    const tr = {
      es: { dlg: { broken: { hello: "Hola", menu: "Menu", menu_c1: "a", menu_c2: "b", orphan: "o" } } },
      de: { dlg: { broken: { menu: "Menu", menu_c1: "a", orphan: "o" } } },
    };
    const found = validateDialogue({ "tests/fixtures/broken_dialogue.json": broken }, { strings: smallStrings, translations: tr, story, cast: smallCast, items })
      .filter((p) => p.message.includes("no translation"));
    expect(found.map((p) => p.message).sort()).toEqual([
      "the text of choice 'leave' of 'dlg.broken.menu' has no translation: no string 'dlg.broken.menu_c2' in locales/de.json",
      "the text of node 'dlg.broken.hello' has no translation: no string 'dlg.broken.hello' in locales/de.json",
    ]);
    expect(found.every((p) => p.hint.includes("locales/de.json"))).toBe(true);
  });

  test("every problem has a file, a pointer, a message and a hint", () => {
    expect(problems.length).toBeGreaterThanOrEqual(8);
    for (const p of problems) {
      expect(p.file).toBe("tests/fixtures/broken_dialogue.json");
      expect(typeof p.pointer).toBe("string");
      expect(p.message.length).toBeGreaterThan(10);
      expect(p.hint.length).toBeGreaterThan(10);
      expect(typeof p.didYouMean).toBe("string");
    }
  });

  test("a dangling id leads to the node it was probably meant to be", () => {
    const p = problems.find((x) => x.pointer === "/conversations/broken/nodes/dlg.broken.hello/next");
    expect(p.message).toContain("dlg.broken.helo");
    expect(p.didYouMean).toBe("dlg.broken.hello");
  });

  test("an unknown speaker, flag and item come with the name they look like", () => {
    expect(problems.find((p) => p.pointer.endsWith("hello/speaker")).didYouMean).toBe("mara");
    const flag = problems.find((p) => p.pointer.endsWith("/choices/0/effects/0"));
    expect(flag.message).toContain("vale_mising");
    expect(flag.didYouMean).toBe("vale_missing");
    const item = problems.find((p) => p.pointer.endsWith("/choices/2/effects/0"));
    expect(item.didYouMean).toBe("library_key");
    expect(problems.find((p) => p.pointer.endsWith("/choices/2/if/0")).didYouMean).toBe("library_key");
  });

  test("a choice without a target, a missing string and an unreachable node are found", () => {
    expect(problems.find((p) => p.pointer.endsWith("/choices/1/next")).message).toContain("no target");
    expect(problems.find((p) => p.message.includes("dlg.broken.nostring") && p.message.includes("missing"))).toBeTruthy();
    expect(problems.find((p) => p.message.includes("menu_c3"))).toBeTruthy();
    expect(problems.find((p) => p.message.includes("never be reached") && p.pointer.endsWith(".orphan"))).toBeTruthy();
    expect(problems.find((p) => p.message.includes("never be reached") && p.pointer.endsWith(".menu"))).toBeTruthy();
  });

  test("the text of describe() lists each problem with its file and pointer", () => {
    const text = describeProblems(problems);
    expect(text).toContain("tests/fixtures/broken_dialogue.json");
    expect(text).toContain("/conversations/broken/nodes/dlg.broken.hello/next");
    expect(text).toContain("Did you mean");
  });
});

describe("a mistake in the shipped tables is found at once", () => {
  test("a next that points at a node that does not exist", () => {
    const p = first(mutated((t) => (t["data/dialogue/ch1.json"].conversations.ch1_mara.nodes["dlg.ch1_mara.greet"].next = "dlg.ch1_mara.intr")), "greet/next");
    expect(p.didYouMean).toBe("dlg.ch1_mara.intro");
    expect(p.file).toBe("data/dialogue/ch1.json");
  });

  test("a line with no next, choices or end", () => {
    const p = first(mutated((t) => delete t["data/dialogue/ch1.json"].conversations.ch1_mara.nodes["dlg.ch1_mara.greet"].next), "ch1_mara/nodes/dlg.ch1_mara.greet");
    expect(p.message).toContain("leads nowhere");
  });

  test("a choice that loses its target", () => {
    const p = first(mutated((t) => delete t["data/dialogue/ch1.json"].conversations.ch1_mara.nodes["dlg.ch1_mara.intro"].choices[0].next), "choices/0/next");
    expect(p.message).toContain("no target");
  });

  test("a locale string that is gone", () => {
    const stripped = clone(strings);
    delete stripped.dlg.ch1_mara.greet;
    const p = validateDialogue(TABLES, { ...ctx, strings: stripped }).find((x) => x.pointer.endsWith("dlg.ch1_mara.greet"));
    expect(p.message).toContain("missing");
    expect(p.hint).toContain("locales/en.json");
  });

  test("a flag that the registry does not declare, with the closest one", () => {
    const p = first(mutated((t) => (t["data/dialogue/ch2.json"].conversations.ch2_tobias.nodes["dlg.ch2_tobias.start"].route[0].if = ["talked.tobias.2", "know_oyl"])), "route/0/if/1");
    expect(p.didYouMean).toBe("know_oil");
  });

  test("a door flag whose door is not in any scene", () => {
    const p = validateStory({ ...clone(story), chapters: clone(story.chapters).map((c) => (c.id === 3 ? { ...c, advance: ["open.guest_door_cc"] } : c)) }, ctx).find((x) => x.pointer.endsWith("/advance/0"));
    expect(p.didYouMean).toBe("guest_door_c");
  });

  test("a node nothing leads to", () => {
    const problems = mutated((t) => {
      t["data/dialogue/ch1.json"].conversations.ch1_mara.nodes["dlg.ch1_mara.island"] = { speaker: "mara", next: "@end" };
    });
    const p = problems.find((x) => x.pointer.endsWith("dlg.ch1_mara.island") && x.message.includes("never be reached"));
    expect(p.file).toBe("data/dialogue/ch1.json");
    expect(p.hint).toContain("Point a next");
  });

  test("a character who talks a conversation that does not exist, and a conversation nobody starts", () => {
    const c = clone(cast);
    c.characters.mara.talk["1"] = "ch1_maraa";
    const p = validateDialogue(TABLES, { ...ctx, cast: c });
    expect(p.find((x) => x.pointer === "/characters/mara/talk/1").didYouMean).toBe("ch1_mara");
    expect(p.find((x) => x.message.includes("never started")).message).toContain("ch1_mara");
  });

  test("a place that is in no area and a cast member who stands nowhere", () => {
    const s = clone(story);
    s.places.hall_center.area = "grond";
    expect(validateStory(s, ctx).find((x) => x.pointer === "/places/hall_center/area").didYouMean).toBe("ground");
    const c = clone(cast);
    c.characters.hedda.schedule["2"] = "landing_heda";
    expect(validateCast(c, ctx).find((x) => x.pointer.includes("hedda/schedule/2")).didYouMean).toBe("landing_hedda");
  });

  test("a condition that is not one, an effect with two actions", () => {
    const p = mutated((t) => {
      const node = t["data/dialogue/ch1.json"].conversations.ch1_mara.nodes["dlg.ch1_mara.start"];
      node.route[0].if = ["talked/mara"];
      t["data/dialogue/ch1.json"].conversations.ch1_mara.nodes["dlg.ch1_mara.greet"].effects = [{ set: "vale_missing", give: "library_key" }];
    });
    expect(p.find((x) => x.pointer.endsWith("route/0/if/0")).hint).toContain("flag_name");
    expect(p.find((x) => x.pointer.endsWith("greet/effects/0")).message).toContain("several actions");
  });
});
