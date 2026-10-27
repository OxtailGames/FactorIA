// The cast (six characters placed by chapter and area), talking to them, and the chapters (a flag ends one, the screen goes through
// a card, the cast changes, the ending screen). The story bot (story_bot.test.js) plays the whole thing; this file checks the parts.
import { test, describe, expect, game } from "factoria:test";
import { scene, world } from "factoria";
import { enter, porter, stand, distance } from "./helpers/lodge.js";
import { EVENTS } from "../scripts/events.js";
import { cast, story as storyData } from "../scripts/dialogue_data.js";
import * as dialogue from "../scripts/dialogue.js";
import * as story from "../scripts/story.js";
import * as items from "../scripts/items.js";
import * as chapters from "../scripts/chapters.js";
import * as cutscene from "../scripts/cutscene.js";
import strings from "../locales/en.json";

/** Steps `n` frames and skips every cut-scene on the way: these tests are about the chapters, not the films (cutscene.test.js). */
function step(n) {
  for (let i = 0; i < n; i++) {
    if (cutscene.active()) cutscene.skip();
    game.step(1);
  }
}

const hud = () => game.find("hud").behaviour;
const castOf = () => game.find("cast").behaviour;
const chaptersOf = () => game.find("chapters").behaviour;

/** Starts a new game at chapter `n` in `area`: the story data of earlier chapters is not replayed, only the flags given. */
function at(n, area = "ground", flags = {}) {
  game.resetState();
  story.reset();
  items.reset();
  chapters.begin();
  for (let i = 2; i <= n; i++) {
    story.set("chapter", i);
    for (const fx of storyData.chapters[i - 1].enter ?? []) if (fx.set) story.set(fx.set, true);
  }
  for (const [k, v] of Object.entries(flags)) story.set(k, v);
  game.load(`scenes/${area}.scene.json`, { arrive: "spawn_default" });
  game.step(40);
}

/** The characters scheduled in `area` for chapter `n`, from data/cast.json and data/story.json. */
function expected(n, area) {
  return Object.entries(cast.characters)
    .filter(([, c]) => c.schedule[String(n)] && storyData.places[c.schedule[String(n)]].area === area)
    .map(([id]) => id)
    .sort();
}

describe("the cast", () => {
  test("a game that has not begun (chapter 0) has nobody in the lodge", () => {
    enter("ground");
    expect(castOf().present()).toEqual([]);
    expect(world.findAll("npc").length).toBe(0);
  });

  test("each chapter puts each character where data/cast.json says, in the area of that place", () => {
    for (let n = 1; n <= 5; n++) {
      for (const area of ["ground", "upstairs", "cellar"]) {
        at(n, area);
        expect(castOf().present().sort(), `chapter ${n} in ${area}`).toEqual(expected(n, area));
      }
    }
  });

  test("a character stands on the spot of their place, faces its way and is a person you can talk to", () => {
    at(1, "ground");
    const mara = castOf().npc("mara");
    const spot = storyData.places[cast.characters.mara.schedule["1"]];
    expect(mara.id).toBe("npc_mara");
    expect(mara.position.x).toBeCloseTo(spot.x, 3);
    expect(mara.position.z).toBeCloseTo(spot.z, 3);
    expect(mara.tags).toContain("npc");
    expect(mara.tags).toContain("interactable");
    expect(mara.get("MeshRenderer").mesh).toContain("characters/");
    const script = mara.get("Script");
    expect(script.props.dialogue).toBe("ch1_mara");
    expect(script.props.kind).toBe("talk");
  });

  test("the six look different: three bodies are shared in pairs, and the tint tells a pair apart", () => {
    at(5, "ground");
    const looks = new Set();
    for (const id of castOf().present()) {
      const m = castOf().npc(id).get("MeshRenderer");
      looks.add(`${m.mesh} ${JSON.stringify(m.color)}`);
    }
    expect(castOf().present().length).toBe(6);
    expect(looks.size).toBe(6);
  });

  test("the prompt names the person and a press of the use key starts their conversation", () => {
    at(1, "ground");
    stand(15, 20.9, 0); // Mara is at the hall centre, ahead
    game.tapKey("F");
    game.step(3);
    expect(dialogue.active()).toBe(true);
    expect(dialogue.current().id).toBe("ch1_mara");
    expect(dialogue.current().speaker).toBe("npc_mara");
  });

  test("the prompt says who: 'Talk to Mara Lindqvist'", () => {
    at(1, "ground");
    stand(15, 20.9, 0);
    game.step(5);
    expect(hud().promptText).toContain("Talk to Mara Lindqvist");
  });

  test("a person turns to the porter while they talk and back after", () => {
    at(1, "ground");
    stand(16.2, 19.2, 270);
    const mara = castOf().npc("mara");
    const before = mara.get("Transform").rotation[1];
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(2);
    const during = mara.get("Transform").rotation[1];
    expect(during).not.toBeCloseTo(before, 0);
    dialogue.abort();
    game.step(2);
    expect(mara.get("Transform").rotation[1]).toBeCloseTo(before, 1);
  });

  test("a person is in the way: the porter cannot walk through them", () => {
    at(1, "ground");
    const mara = castOf().npc("mara");
    stand(mara.position.x, mara.position.z + 3, 0);
    game.press("move_forward");
    game.step(120);
    game.release("move_forward");
    expect(distance(porter(), mara)).toBeGreaterThan(0.4);
  });
});

describe("the chapters", () => {
  test("begin() is chapter 1, due() waits for its flag, advance() applies the next chapter's entry", () => {
    story.reset();
    items.reset();
    chapters.begin();
    expect(chapters.current()).toBe(1);
    expect(chapters.due()).toBe(false);
    expect(chapters.advance()).toBe(0);
    story.set("vale_missing");
    expect(chapters.due()).toBe(true);
    expect(chapters.advance()).toBe(2);
    expect(chapters.current()).toBe(2);
    chapters.begin();
    expect(chapters.current()).toBe(1);
    story.set("chapter", 4);
    story.set("vale_found");
    expect(chapters.advance()).toBe(5);
    expect(story.get("storm_over")).toBe(true);
    expect(chapters.isFinal()).toBe(true);
    expect(chapters.due()).toBe(false); // the last chapter ends with an ending, not a flag
  });

  test("the first area of a chapter shows its card; a flag that ends the chapter fades out, changes the cast, fades in", () => {
    at(1, "ground");
    expect(chaptersOf().cardShown).toBe(1);
    expect(hud().message).toBe(strings.chapter["1"].intro);
    expect(castOf().present().length).toBe(5);
    const seen = [];
    world.on(EVENTS.chapterChanged, (d) => seen.push(d));
    story.set("vale_missing");
    step(5);
    expect(chaptersOf().stage).toBe("out");
    expect(porter().behaviour.locked).toBe(true); // nobody walks while the screen goes dark
    step(60);
    expect(chapters.current()).toBe(2);
    expect(seen).toEqual([{ chapter: 2, previous: 1 }]);
    expect(castOf().present().sort()).toEqual(expected(2, "ground"));
    expect(castOf().npc("hedda")).toBeNull(); // she went up
    step(120);
    expect(chaptersOf().cardShown).toBe(2);
    expect(hud().message).toBe(strings.chapter["2"].intro);
    step(60);
    expect(chaptersOf().stage).toBe("");
    expect(porter().behaviour.locked).toBe(false);
  });

  test("a chapter does not change in the middle of a conversation: it waits for the end", () => {
    at(1, "ground");
    dialogue.start("ch1_hedda", { speaker: "npc_hedda" });
    let guard = 0;
    while (dialogue.active() && guard++ < 40) {
      if (dialogue.current().line.choices.length) dialogue.choose(0);
      else dialogue.advance();
      game.step(2);
      expect(chapters.current()).toBe(dialogue.active() ? 1 : chapters.current());
    }
    expect(story.has("vale_missing")).toBe(true);
    game.step(200);
    expect(chapters.current()).toBe(2);
  });

  test("a chapter that starts elsewhere takes the porter there and shows its card in the new scene", () => {
    at(4, "cellar", { vale_missing: true });
    expect(scene.current).toBe("scenes/cellar.scene.json");
    story.set("vale_found");
    step(60);
    const arrived = () => scene.current === "scenes/ground.scene.json";
    for (let i = 0; i < 400 && !arrived(); i++) step(1);
    expect(arrived()).toBe(true);
    step(30);
    expect(chapters.current()).toBe(5);
    expect(chaptersOf().cardShown).toBe(5);
    expect(castOf().present().sort()).toEqual(expected(5, "ground"));
    expect(castOf().present()).toContain("vale");
  });

  test("an ending shows the ending screen once, tells the game and leads back to the title", () => {
    at(5, "ground");
    const ended = [];
    world.on(EVENTS.storyEnded, (d) => ended.push(d.ending));
    expect(game.find("ending_ui").active).toBe(false);
    story.set("ending", "quiet");
    step(240);
    expect(chaptersOf().endingShown).toBe(true);
    expect(game.find("ending_ui").active).toBe(true);
    expect(game.find("ending_title").get("Text").text).toBe(strings.ending.quiet.title);
    expect(ended).toEqual(["quiet"]);
    expect(porter().behaviour.locked).toBe(true);
    game.screenshot(".factoria/screenshots/ending_quiet.png");
    game.click(game.find("ending_menu"));
    step(10);
    expect(scene.current).toBe("scenes/menu.scene.json");
  });

  test("an unknown ending id shows nothing (the story data names three)", () => {
    at(5, "ground");
    story.set("ending", "grim");
    game.step(240);
    expect(chaptersOf().endingShown).toBe(false);
    expect(chapters.ending()).toBe("");
  });
});
