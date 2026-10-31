// The story bot: plays the whole night, from the title screen to an ending, once for each of the three endings. It does what a
// player does: clicks Play, uses stairs and doors with the use key where the porter's prompt would name them, talks to people and
// picks answers from a fixed list. Every run must reach the chapter changes in order, finish on the right ending screen, and leave
// exactly the state pinned below (a hash of the flags, counters, items and the conversations held). Nothing random is used: if a
// hash changes, the story or the data changed - read the printed state, check it is meant, and update the hash.
import { test, expect, game } from "factoria:test";
import { scene } from "factoria";
import { Bot, fnv1a } from "./helpers/bot.js";
import * as chapters from "../scripts/chapters.js";
import * as dialogue from "../scripts/dialogue.js";
import * as story from "../scripts/story.js";
import * as items from "../scripts/items.js";
import * as cutscene from "../scripts/cutscene.js";
import strings from "../locales/en.json";

/** Gets the porter through chapter 1 (Hedda tells him Dr. Vale is missing) after Mara's welcome. */
function chapter1(bot, mara, hedda) {
  expect(chapters.current()).toBe(1);
  bot.talk("mara", mara);
  bot.talk("hedda", hedda);
  expect(chapters.current()).toBe(2);
  expect(bot.area()).toBe("ground");
}

/** The ending screen is up and says what the story reached. */
function expectEnding(bot, id) {
  const ch = game.find("chapters").behaviour;
  for (let i = 0; i < 600 && !ch.endingShown; i += 10) {
    bot.skipCutscene(); // the ending is told by its cut-scene first; the bot skips it with the skip key
    game.step(10);
  }
  expect(ch.endingShown, `the ending screen after ${bot.trail.join(" > ")}`).toBe(true);
  expect(chapters.ending()).toBe(id);
  expect(game.find("ending_ui").active).toBe(true);
  // Every cut-scene of the night played and was skipped by the bot: the intro, a lead-in per chapter, the adit, the ending's.
  const told = cutscene.seen();
  for (const want of ["intro", "chapter_2", "chapter_3", "chapter_4", "chapter_5", "adit_descent", "adit_rescue", `ending_${id}`]) {
    expect(told.find((e) => e.id === want), `cut-scene ${want} after ${bot.trail.join(" > ")}`).toBeTruthy();
  }
  expect(told.every((e) => e.skipped)).toBe(true);
  expect(game.find("ending_title").get("Text").text).toBe(strings.ending[id].title);
  game.screenshot(`.factoria/screenshots/bot_ending_${id}.png`);
}

/** Chapter 4 from wherever the porter is: the lantern from the cellar, the oil from the kitchen, then Haas opens the adit. */
function chapter4(bot, haas) {
  expect(chapters.current()).toBe(4);
  bot.go("cellar");
  bot.use("p_lantern_box");
  expect(items.has("cellar_lantern")).toBe(true);
  bot.go("ground");
  bot.use("p_kitchen_box");
  expect(items.has("lamp_oil")).toBe(true);
  // The storm cut the power: the latch of the adit needs the cellar circuit, so the puzzles come first (they end the storm).
  expect(story.has("power_out")).toBe(true);
  expect(story.has("storm_over")).toBe(false);
  bot.fixTheFuse();
  expect(story.has("storm_over")).toBe(true);
  bot.go("cellar");
  bot.talk("haas", haas);
  // vale_found ends chapter 4: the screen goes dark and the last chapter starts in the hall (a scene change from the cellar).
  bot.settle();
  expect(story.has("adit_open")).toBe(true);
  expect(story.has("vale_found")).toBe(true);
  expect(chapters.current()).toBe(5);
  expect(bot.area()).toBe("ground");
}

/** Chapter 3 upstairs: the key from `who`, the door of room C opens. */
function chapter3Door(bot) {
  bot.go("upstairs");
  bot.use("guest_door_c");
  expect(story.has("open.guest_door_c")).toBe(true);
  bot.settle();
  expect(chapters.current()).toBe(4);
}

function report(name, bot) {
  const state = bot.state();
  const hash = fnv1a(state);
  console.log(`${name}: ${hash}  ${state.length} chars  ${bot.trail.length} steps`);
  return hash;
}

test("the dawn ending: trust earned, the survey understood, the truth told", () => {
  const bot = new Bot();
  bot.play();
  expect(scene.current).toBe("scenes/ground.scene.json");
  expect(chapters.current()).toBe(1);
  chapter1(bot, ["promise"], ["asleep"]);

  // Chapter 2: three interviews end it (Tobias, Haas, Lucian); Haas trusts the porter who listens.
  bot.talk("tobias", ["why"]);
  bot.talk("haas", ["trust"]);
  expect(chapters.current()).toBe(2);
  bot.talk("lucian", ["why"]);
  expect(chapters.current()).toBe(3);
  expect(story.get("trust")).toBe(2);

  // Chapter 3: Hedda gives the room C key when shown her torn letter; Lucian, in room B, explains the survey.
  bot.go("upstairs");
  bot.use("p_letter_box");
  expect(items.has("torn_letter")).toBe(true);
  bot.talk("hedda", ["letter"]);
  expect(items.has("room_c_key")).toBe(true);
  expect(story.has("hedda_letter")).toBe(true);
  bot.talk("lucian", ["print"]);
  expect(story.has("survey_known")).toBe(true);
  chapter3Door(bot);

  chapter4(bot, ["calm", "open"]);
  expect(story.get("trust")).toBe(3);

  // Chapter 5: Dr. Vale is back; the porter tells the truth.
  bot.talk("vale", ["truth"]);
  expect(story.get("ending")).toBe("dawn");
  expectEnding(bot, "dawn");
  expect(report("dawn", bot)).toBe("764bcd5e");
});

test("the quiet ending: the evidence is burned for the sake of the household", () => {
  const bot = new Bot();
  bot.play();
  chapter1(bot, ["promise"], ["key"]);

  // Chapter 2: Tobias, Haas and Mara; kind answers earn the trust the quiet ending needs.
  bot.talk("tobias", ["gave"]);
  bot.talk("haas", ["trust"]);
  bot.talk("mara", ["kind"]);
  expect(chapters.current()).toBe(3);
  expect(story.get("trust")).toBe(3);

  // Chapter 3: the library (key from the cellar crate) gives the ledger; Tobias gives the room C key.
  bot.go("cellar");
  bot.use("p_cellar_box");
  expect(items.has("library_key")).toBe(true);
  bot.go("ground");
  bot.use("library_door");
  bot.use("p_ledger_box");
  expect(items.has("guest_ledger")).toBe(true);
  bot.talk("tobias", ["oil"]); // he knows the porter heard about the lamp oil
  expect(items.has("room_c_key")).toBe(true);
  bot.go("upstairs");
  bot.use("p_letter_box");
  chapter3Door(bot);

  chapter4(bot, ["reason", "open"]);

  // Chapter 5: both pieces of evidence go in the stove.
  bot.talk("vale", ["bury", "burn"]);
  expect(items.has("guest_ledger")).toBe(false);
  expect(items.has("torn_letter")).toBe(false);
  expect(story.get("ending")).toBe("quiet");
  expectEnding(bot, "quiet");
  expect(report("quiet", bot)).toBe("7b2010b5");
});

test("the long night: nobody trusted, the culprit named in front of everyone", () => {
  const bot = new Bot();
  bot.play();
  chapter1(bot, ["start"], ["seen"]);

  bot.talk("tobias", ["afraid"]);
  bot.talk("lucian", ["you"]);
  bot.talk("mara", ["accuse"]);
  expect(chapters.current()).toBe(3);
  expect(story.get("trust", 0)).toBe(0);
  expect(story.has("mara_hurt")).toBe(true);

  bot.talk("tobias", ["idea"]);
  expect(items.has("room_c_key")).toBe(true);
  chapter3Door(bot);

  chapter4(bot, ["angry", "open"]);

  // Haas refuses the room key without trust, but nothing stops the accusation.
  bot.talk("vale", ["accuse"]);
  expect(story.get("ending")).toBe("long");
  expectEnding(bot, "long");
  expect(report("long", bot)).toBe("8388b733");
});

test("the choices decide the ending: the quiet way is closed to a porter nobody trusts", () => {
  const bot = new Bot();
  bot.play();
  chapter1(bot, ["start"], ["asleep"]);
  bot.talk("tobias", ["why"]);
  bot.talk("lucian", ["why"]);
  bot.talk("mara", ["blunt"]);
  bot.talk("tobias", ["owed"]); // the porter says the lodge owes him the key: Tobias sends him away
  expect(items.has("room_c_key")).toBe(false);
  bot.talk("tobias", ["idea"]); // asked again, kindly, he gives it
  expect(items.has("room_c_key")).toBe(true);
  chapter3Door(bot);
  chapter4(bot, ["angry", "open"]);
  // Chapter 5 offers only "accuse" and "wait" to a porter with no trust and no survey: no "bury", no "truth".
  bot.use("npc_vale");
  for (let i = 0; i < 20 && dialogue.active() && dialogue.current().line.choices.length === 0; i++) dialogue.advance();
  expect(dialogue.current().line.node).toBe("dlg.ch5_vale.ask");
  expect(dialogue.current().line.choices.map((c) => c.id)).toEqual(["accuse", "wait"]);
  dialogue.abort();
});

test("the adit stays shut while the storm has the power: Haas points at the fuse box, and the puzzles open it", () => {
  const bot = new Bot();
  bot.play();
  chapter1(bot, ["start"], ["asleep"]);
  bot.talk("tobias", ["why"]);
  bot.talk("lucian", ["why"]);
  bot.talk("mara", ["blunt"]);
  bot.talk("tobias", ["idea"]);
  chapter3Door(bot);
  bot.go("cellar");
  bot.use("p_lantern_box");
  bot.go("ground");
  bot.use("p_kitchen_box");
  expect(story.has("power_out")).toBe(true);
  bot.go("cellar");
  expect(bot.talk("haas", ["nopower"])).toContain("nopower");
  expect(story.has("adit_open")).toBe(false);
  expect(chapters.current()).toBe(4);
  bot.fixTheFuse();
  bot.go("cellar");
  expect(bot.talk("haas", ["open"])).toContain("open");
  bot.settle();
  expect(story.has("adit_open")).toBe(true);
  expect(chapters.current()).toBe(5);
});
