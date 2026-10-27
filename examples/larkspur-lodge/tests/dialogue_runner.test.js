// The condition language, the conversation walker and the dialogue API (scripts/dialogue.js) that scenes, tests and the story bot call.
import { test, describe, expect, game } from "factoria:test";
import { scene, world } from "factoria";
import { EVENTS } from "../scripts/events.js";
import { parseCondition, evalCondition, holds, parseEffect } from "../scripts/conditions.js";
import { Conversation, END } from "../scripts/dialogue_runner.js";
import * as dialogue from "../scripts/dialogue.js";
import * as story from "../scripts/story.js";
import { enter, porter } from "./helpers/lodge.js";

/** A tiny fake world: flags and items in plain objects, a log of what the effects did. */
function fakeEnv(flags = {}, have = []) {
  const log = [];
  return {
    log,
    flags,
    have,
    get: (f, fb = false) => (f in flags ? flags[f] : fb),
    hasItem: (id) => have.includes(id),
    set: (f, v) => {
      flags[f] = v;
      log.push(`set ${f}=${v}`);
    },
    give: (id) => (have.push(id), log.push(`give ${id}`)),
    take: (id) => (have.splice(have.indexOf(id), 1), log.push(`take ${id}`)),
    cutscene: (id) => log.push(`cutscene ${id}`),
  };
}

const TABLE = {
  conversations: {
    t: {
      start: "dlg.t.route",
      nodes: {
        "dlg.t.route": { route: [{ if: ["met"], to: "dlg.t.again" }, { to: "dlg.t.hello" }] },
        "dlg.t.hello": { speaker: "mara", effects: [{ set: "met" }], next: "dlg.t.menu" },
        "dlg.t.again": { speaker: "mara", next: "@end" },
        "dlg.t.menu": {
          speaker: "mara",
          choices: [
            { id: "kind", text: "dlg.t.menu_c1", effects: [{ add: "trust" }], next: "dlg.t.thanks" },
            { id: "key", text: "dlg.t.menu_c2", if: ["item:library_key"], effects: [{ take: "library_key" }, { set: "gave_key" }], next: "dlg.t.thanks" },
            { id: "gift", text: "dlg.t.menu_c3", if: ["trust>=1", "!gave_key"], effects: [{ give: "lamp_oil" }], next: "dlg.t.thanks" },
            { id: "go", text: "dlg.t.menu_c4", effects: [{ cutscene: "adit_descent" }, { end: true }] },
          ],
        },
        "dlg.t.thanks": { speaker: "porter", effects: [{ end: true }] },
      },
    },
    loop: {
      start: "dlg.loop.a",
      nodes: { "dlg.loop.a": { route: [{ to: "dlg.loop.b" }] }, "dlg.loop.b": { route: [{ to: "dlg.loop.a" }] } },
    },
  },
};

describe("conditions", () => {
  test("a flag, its negation, a comparison, a word and an item", () => {
    const env = fakeEnv({ vale_missing: true, interviews: 2, ending: "dawn", storm_over: false }, ["lamp_oil"]);
    const yes = (text) => evalCondition(parseCondition(text).cond, env);
    expect(yes("vale_missing")).toBe(true);
    expect(yes("!vale_missing")).toBe(false);
    expect(yes("storm_over")).toBe(false);
    expect(yes("never_set")).toBe(false);
    expect(yes("interviews>=2")).toBe(true);
    expect(yes("interviews>=3")).toBe(false);
    expect(yes("interviews<3")).toBe(true);
    expect(yes("ending=dawn")).toBe(true);
    expect(yes("ending!=long")).toBe(true);
    expect(yes("storm_over=false")).toBe(true);
    expect(yes("item:lamp_oil")).toBe(true);
    expect(yes("!item:guest_ledger")).toBe(true);
    expect(holds(["vale_missing", "item:lamp_oil"], env)).toBe(true);
    expect(holds(["vale_missing", "interviews>=9"], env)).toBe(false);
    expect(holds([], env)).toBe(true);
  });

  test("a bad condition or effect says what is wrong and how to write it", () => {
    for (const bad of ["", "Vale Missing", "a>>b", "!x>=2", "item:k>=1", "name>=word"]) {
      const p = parseCondition(bad);
      expect(p.ok, bad).toBe(false);
      expect(p.hint.length).toBeGreaterThan(10);
    }
    expect(parseEffect({ set: "a", give: "b" }).message).toContain("several actions");
    expect(parseEffect({ sett: "a" }).message).toContain("unknown key");
    expect(parseEffect({ add: "a", by: "2" }).hint).toContain("by");
    expect(parseEffect({ end: true }).kind).toBe("end");
  });
});

describe("the conversation walker", () => {
  test("a route picks the first branch that holds, effects apply when a node is reached", () => {
    const env = fakeEnv();
    const c = new Conversation(TABLE, "t", env);
    expect(c.line.node).toBe("dlg.t.hello");
    expect(c.line.speaker).toBe("mara");
    expect(c.line.textKey).toBe("dlg.t.hello"); // the id of the node is the locale key
    expect(env.flags.met).toBe(true);
    const again = new Conversation(TABLE, "t", env);
    expect(again.line.node).toBe("dlg.t.again");
    expect(again.line.last).toBe(true);
    expect(again.advance()).toBeNull();
    expect(again.finished).toBe(true);
  });

  test("choices with a condition that fails are not offered, and the picked one applies its effects", () => {
    const env = fakeEnv();
    const c = new Conversation(TABLE, "t", env);
    c.advance();
    expect(c.line.choices.map((x) => x.id)).toEqual(["kind", "go"]);
    c.choose(0);
    expect(env.flags.trust).toBe(1);
    expect(c.line.node).toBe("dlg.t.thanks");
    expect(c.picked).toEqual(["kind"]);
    expect(c.advance()).toBeNull();
    expect(c.finished).toBe(true);

    const env2 = fakeEnv({ trust: 1 }, ["library_key"]);
    const d = new Conversation(TABLE, "t", env2);
    d.advance();
    expect(d.line.choices.map((x) => x.id)).toEqual(["kind", "key", "gift", "go"]);
    d.choose(1); // the key goes away, and "gift" needs that to be false
    expect(env2.have).toEqual([]);
    expect(env2.flags.gave_key).toBe(true);
  });

  test("a choice index counts the visible choices, not the table's", () => {
    const env = fakeEnv({ trust: 1 }, []);
    const c = new Conversation(TABLE, "t", env);
    c.advance();
    expect(c.line.choices.map((x) => x.id)).toEqual(["kind", "gift", "go"]);
    c.choose(1);
    expect(env.have).toEqual(["lamp_oil"]);
  });

  test("a cut-scene effect and the end effect finish the conversation", () => {
    const env = fakeEnv();
    const c = new Conversation(TABLE, "t", env);
    c.advance();
    expect(c.choose(1)).toBeNull();
    expect(env.log).toContain("cutscene adit_descent");
    expect(c.finished).toBe(true);
  });

  test("choosing from a line without choices, a wrong index, advancing past a choice, a loop and a missing id all explain themselves", () => {
    const env = fakeEnv();
    const c = new Conversation(TABLE, "t", env);
    expect(() => c.choose(0)).toThrow(/no choice 0/);
    c.advance();
    expect(() => c.advance()).toThrow(/offers choices/);
    expect(() => c.choose(9)).toThrow(/there is no choice 9/);
    expect(() => new Conversation(TABLE, "loop", env)).toThrow(/the table loops/);
    expect(() => new Conversation(TABLE, "nope", env)).toThrow(/does not exist/);
  });

  test("abort ends it without applying anything more", () => {
    const env = fakeEnv();
    const c = new Conversation(TABLE, "t", env);
    c.abort();
    expect(c.finished).toBe(true);
    expect(c.line).toBeNull();
    expect(c.advance()).toBeNull();
    expect(END).toBe("@end");
  });
});

describe("the dialogue API", () => {
  test("start answers { id, started, completed, stub: false }; an unknown id warns with a suggestion and starts nothing", () => {
    enter("ground");
    const r = dialogue.start("ch1_mara", { speaker: "npc_mara" });
    expect(r).toEqual({ id: "ch1_mara", started: true, completed: false, stub: false });
    expect(dialogue.active()).toBe(true);
    expect(dialogue.current().line.node).toBe("dlg.ch1_mara.greet");
    expect(dialogue.start("ch1_hedda").started).toBe(false); // one at a time
    dialogue.abort();
    expect(dialogue.active()).toBe(false);
    expect(dialogue.start("ch1_maraa")).toEqual({ id: "ch1_maraa", started: false, completed: false, stub: false });
    expect(dialogue.exists("ch1_mara")).toBe(true);
    expect(dialogue.exists("ch1_maraa")).toBe(false);
  });

  test("the porter does not walk while a conversation runs and gets control back a moment after it", () => {
    enter("ground");
    expect(porter().behaviour.locked).toBe(false);
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    expect(porter().behaviour.locked).toBe(true);
    expect(porter().behaviour.locks.has("dialogue")).toBe(true);
    const z0 = porter().position.z;
    game.press("move_forward");
    game.step(20);
    game.release("move_forward");
    expect(Math.abs(porter().position.z - z0)).toBeLessThan(0.05);
    dialogue.abort();
    expect(porter().behaviour.locks.has("dialogue")).toBe(false);
    expect(porter().behaviour.locks.has("dialogue_end")).toBe(true); // an abort holds him like a normal end
    game.step(Math.ceil(dialogue.POST_LOCK * 60) + 3);
    expect(porter().behaviour.locked).toBe(false);
  });

  test("a finished conversation holds the porter for POST_LOCK seconds (the key that ended it is also 'interact')", () => {
    enter("ground");
    dialogue.start("ch1_tobias", { speaker: "npc_tobias" });
    let guard = 0;
    while (dialogue.active() && guard++ < 40) {
      const line = dialogue.current().line;
      if (line.choices.length) dialogue.choose(0);
      else dialogue.advance();
    }
    expect(dialogue.active()).toBe(false);
    expect(porter().behaviour.locks.has("dialogue_end")).toBe(true);
    game.step(Math.ceil(dialogue.POST_LOCK * 60) + 3);
    expect(porter().behaviour.locked).toBe(false);
  });

  test("the backlog and the history keep what was said and picked", () => {
    enter("ground");
    dialogue.reset();
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    dialogue.advance(); // intro: choices
    expect(dialogue.current().line.choices.length).toBe(3);
    dialogue.choose(2); // the promise (trust)
    expect(dialogue.log().map((l) => l.speaker)).toEqual(["mara", "mara", "porter", "mara"]);
    expect(dialogue.log()[2].key).toBe("dlg.ch1_mara.intro_c3");
    expect(story.get("trust")).toBe(1);
    while (dialogue.active()) dialogue.advance();
    expect(dialogue.history()).toEqual([{ id: "ch1_mara", picked: ["promise"] }]);
    expect(story.has("talked.mara.1")).toBe(true);
  });

  test("the backlog keeps the last LOG_LIMIT lines only", () => {
    enter("ground");
    dialogue.reset();
    for (let i = 0; i < dialogue.LOG_LIMIT + 10; i++) {
      dialogue.start("ch1_mara", { speaker: "npc_mara" });
      dialogue.abort();
    }
    expect(dialogue.log().length).toBe(dialogue.LOG_LIMIT);
  });

  test("a conversation of a scene that is gone is dropped, not carried into the next area", () => {
    enter("ground");
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.load("scenes/upstairs.scene.json", { arrive: "spawn_default" });
    game.step(5);
    expect(scene.current).toBe("scenes/upstairs.scene.json");
    expect(dialogue.active()).toBe(false);
    expect(dialogue.current()).toBeNull();
    expect(porter().behaviour.locked).toBe(false);
  });

  test("the events carry the conversation, each line and the end", () => {
    enter("ground");
    dialogue.reset();
    const seen = [];
    world.on(EVENTS.dialogueRequested, (d) => seen.push(`requested ${d.id}`));
    world.on(EVENTS.dialogueStarted, (d) => seen.push(`started ${d.id} by ${d.speaker}`));
    world.on(EVENTS.dialogueLine, (d) => seen.push(`line ${d.node}${d.choices.length ? " +" + d.choices.length : ""}`));
    world.on(EVENTS.dialogueEnded, (d) => seen.push(`ended ${d.id} ${d.completed} [${d.picked}]`));
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    dialogue.advance();
    dialogue.choose(0);
    while (dialogue.active()) dialogue.advance();
    game.step(2); // events reach the listeners with the frame
    expect(seen.slice(0, 4)).toEqual([
      "requested ch1_mara",
      "started ch1_mara by npc_mara",
      "line dlg.ch1_mara.greet",
      "line dlg.ch1_mara.intro +3",
    ]);
    expect(seen[seen.length - 1]).toMatch(/^ended ch1_mara true \[/);
  });
});
