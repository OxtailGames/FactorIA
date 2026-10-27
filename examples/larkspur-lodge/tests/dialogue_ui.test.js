// The dialogue box: reveal at the player's text speed, skip/complete, choices with the mouse, keyboard, gamepad and a finger,
// the backlog, the porter standing still, and a conversation that dies with its scene. Screenshots go to .factoria/screenshots/.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { scene, ui } from "factoria";
import { enter, porter, stand } from "./helpers/lodge.js";
import * as dialogue from "../scripts/dialogue.js";
import * as story from "../scripts/story.js";
import * as chapters from "../scripts/chapters.js";
import * as settings from "../scripts/settings.js";
import strings from "../locales/en.json";

const view = () => game.find("dialogue").behaviour;
const box = () => game.find("dialogue_ui");
const text = () => game.find("dlg_text").get("Text").text;
const speaker = () => game.find("dlg_speaker").get("Text").text;
const choiceText = (n) => game.find(`dlg_choice_${n}`).get("Button").text;
const node = () => dialogue.current()?.line.node ?? null;

/** Lets the settle time of a fresh line pass, then reveals the whole line (the press that completes it). */
function complete() {
  game.step(15);
  if (view().revealed < view().total) {
    game.tapKey("Space");
    game.step(10);
  }
}

/** Plays Mara's first conversation up to the line with the three answers. */
function toChoices() {
  dialogue.start("ch1_mara", { speaker: "npc_mara" });
  game.step(3);
  complete();
  game.step(15);
  game.tapKey("Space"); // greet -> intro
  game.step(3);
  complete();
  expect(node()).toBe("dlg.ch1_mara.intro");
  expect(view().choicesShown).toBe(true);
}

function setup() {
  enter("ground");
  settings.save({ ...settings.load(), textSpeed: 45 });
  dialogue.reset();
  stand(15, 21, 0);
}

function group(name, body) {
  describe(name, () => {
    beforeEach(setup);
    body();
  });
}

group("a line", () => {
  test("opens with the speaker's name and shows the text letter by letter", () => {
    expect(box().active).toBe(false);
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(2);
    expect(box().active).toBe(true);
    expect(speaker()).toBe("Mara Lindqvist");
    const first = view().revealed;
    expect(first).toBeLessThan(view().total);
    game.step(30);
    expect(view().revealed).toBeGreaterThan(first);
    expect(view().revealed).toBeLessThan(view().total);
    game.step(240);
    expect(view().revealed).toBe(view().total);
    expect(text()).toBe(strings.dlg.ch1_mara.greet);
    expect(game.find("dlg_text").get("Text").visibleCharacters).toBe(-1);
  });

  test("a press completes the line, the next one goes on", () => {
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(20);
    expect(view().revealed).toBeLessThan(view().total);
    game.tapKey("Space");
    game.step(2);
    expect(view().revealed).toBe(view().total);
    expect(node()).toBe("dlg.ch1_mara.greet");
    game.step(10);
    game.tapKey("Space");
    game.step(2);
    expect(node()).toBe("dlg.ch1_mara.intro");
  });

  test("a press in the first moments of a line is ignored (the one that ended the last is still down)", () => {
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(2);
    game.tapKey("Space");
    game.step(2);
    expect(view().revealed).toBeLessThan(view().total);
  });

  test("text speed 0 shows the whole line at once; the box keeps its height while it reveals", () => {
    settings.save({ ...settings.load(), textSpeed: 0 });
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(2);
    expect(view().revealed).toBe(view().total);
    dialogue.abort();
    game.step(20);
    settings.save({ ...settings.load(), textSpeed: 45 });
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(2);
    // The Text holds the whole line from its first character and only shows part of it, so the box never changes size.
    const label = () => game.find("dlg_text").get("Text");
    const rect = () => ui.rectOf("dlg_text");
    const whole = rect().h;
    expect(label().visibleCharacters).toBeLessThan(view().total);
    expect(text()).toBe(strings.dlg.ch1_mara.greet);
    game.step(60);
    expect(label().visibleCharacters).toBeGreaterThan(0);
    expect(label().visibleCharacters).toBeLessThan(view().total);
    expect(rect().h).toBe(whole);
    expect(whole).toBeGreaterThan(28 * 1.5); // it wraps: more than one line tall
  });

  test("a click on the box completes it, a click on a button is its own", () => {
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(20);
    game.click([640, 560]); // the text area of the box
    game.step(2);
    expect(view().revealed).toBe(view().total);
  });
});

group("choices", () => {
  test("they appear after the text, numbered, with the focus on the first", () => {
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    complete();
    game.step(15);
    game.tapKey("Space");
    game.step(3);
    expect(node()).toBe("dlg.ch1_mara.intro");
    expect(view().choicesShown).toBe(false);
    complete();
    expect(view().choicesShown).toBe(true);
    expect(choiceText(1)).toBe(`1.  ${strings.dlg.ch1_mara.intro_c1}`);
    expect(choiceText(3)).toBe(`3.  ${strings.dlg.ch1_mara.intro_c3}`);
    expect(game.find("dlg_choice_4").active).toBe(false);
    expect(game.find("dlg_next").active).toBe(false);
  });

  test("a number key picks", () => {
    toChoices();
    game.step(15);
    game.tapKey("3");
    game.step(2);
    expect(node()).toBe("dlg.ch1_mara.promise");
    expect(story.get("trust")).toBe(1);
  });

  test("a click picks", () => {
    toChoices();
    game.step(15);
    game.click(game.find("dlg_choice_2"));
    game.step(2);
    expect(node()).toBe("dlg.ch1_mara.worry");
  });

  test("the arrows and Enter pick, the focus starts on the first", () => {
    toChoices();
    game.step(15);
    game.tapKey("Down");
    game.step(2);
    game.tapKey("Enter");
    game.step(2);
    expect(node()).toBe("dlg.ch1_mara.worry");
  });

  test("with a gamepad: the d-pad moves, A picks, Y opens the log, B closes it", () => {
    const pad = game.gamepad(0);
    pad.connect({ type: "xbox" });
    toChoices();
    game.step(15);
    pad.tap("DpadDown");
    pad.tap("DpadDown");
    game.step(2);
    pad.tap("Y");
    game.step(3);
    expect(view().logOpen).toBe(true);
    pad.tap("B");
    game.step(3);
    expect(view().logOpen).toBe(false);
    expect(node()).toBe("dlg.ch1_mara.intro");
    pad.tap("A");
    game.step(2);
    expect(node()).toBe("dlg.ch1_mara.promise");
  });

  test("a finger picks, and a finger on the box goes on", () => {
    toChoices();
    game.step(15);
    const b = game.find("dlg_choice_1");
    game.touchStart(b, 1);
    game.step(2);
    game.touchEnd(1);
    game.step(3);
    expect(node()).toBe("dlg.ch1_mara.tip");
    game.step(20);
    expect(view().revealed).toBeLessThan(view().total);
    game.touchStart([640, 560], 1);
    game.step(2);
    game.touchEnd(1);
    game.step(3);
    expect(view().revealed).toBe(view().total);
  });

  test("a choice cannot be picked while the log is open or before the text is complete", () => {
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    complete();
    game.step(15);
    game.tapKey("Space");
    game.step(3);
    game.step(15);
    game.tapKey("1");
    game.step(2);
    expect(node()).toBe("dlg.ch1_mara.intro");
    complete();
    game.step(15);
    game.tapKey("L");
    game.step(3);
    expect(view().logOpen).toBe(true);
    game.tapKey("2");
    game.step(2);
    expect(node()).toBe("dlg.ch1_mara.intro");
  });

  test("the answers shape the story: the promise is kept for later", () => {
    toChoices();
    game.step(15);
    game.tapKey("3");
    game.step(3);
    for (let i = 0; i < 4 && dialogue.active(); i++) {
      complete();
      game.step(15);
      game.tapKey("Space");
      game.step(5);
    }
    game.step(30);
    expect(dialogue.active()).toBe(false);
    expect(box().active).toBe(false);
    expect(story.has("talked.mara.1")).toBe(true);
    expect(dialogue.history()).toEqual([{ id: "ch1_mara", picked: ["promise"] }]);
  });
});

group("the backlog", () => {
  test("it lists the lines so far and the porter's answers, and the Log button opens it", () => {
    toChoices();
    game.step(15);
    game.tapKey("1");
    game.step(3);
    game.click(game.find("dlg_log_button"));
    game.step(3);
    expect(view().logOpen).toBe(true);
    expect(game.find("dlg_log_panel").active).toBe(true);
    expect(view().logEntries.length).toBe(4); // greet, intro, the answer, tip
    game.click(game.find("dlg_log_close"));
    game.step(3);
    expect(view().logOpen).toBe(false);
    expect(view().logEntries.length).toBe(0);
  });

  test("the L key opens and closes it, and it closes with the conversation", () => {
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(20);
    game.tapKey("L");
    game.step(3);
    expect(view().logOpen).toBe(true);
    game.tapKey("L");
    game.step(3);
    expect(view().logOpen).toBe(false);
    game.tapKey("L");
    game.step(3);
    dialogue.abort();
    game.step(3);
    expect(view().logOpen).toBe(false);
    expect(game.find("dlg_log_panel").active).toBe(false);
  });

  test("Escape closes the log and does not open the pause menu with it", () => {
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(20);
    game.tapKey("L");
    game.step(3);
    expect(view().logOpen).toBe(true);
    game.tapKey("Escape");
    game.step(6);
    expect(view().logOpen).toBe(false);
    expect(game.paused).toBe(false);
    game.tapKey("Escape"); // with the log closed, Escape pauses as everywhere else
    game.step(3);
    expect(game.paused).toBe(true);
  });
});

group("the porter during and after", () => {
  test("he does not walk, turn or use things while the box is open, and the key that ends a line does not use anything", () => {
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    const x0 = porter().position.x;
    const z0 = porter().position.z;
    game.press("move_forward");
    game.step(30);
    game.release("move_forward");
    expect(Math.hypot(porter().position.x - x0, porter().position.z - z0)).toBeLessThan(0.05);
    game.press("camera_left");
    game.step(10);
    game.release("camera_left");
    complete();
    while (dialogue.active()) {
      game.step(15);
      if (dialogue.current()?.line.choices.length) game.tapKey("1");
      else game.tapKey("Enter");
      game.step(3);
      if (view().revealed < view().total) game.tapKey("Enter");
    }
    expect(box().active).toBe(false);
    expect(porter().behaviour.locks.has("dialogue_end")).toBe(true);
    game.step(30);
    expect(porter().behaviour.locked).toBe(false);
  });

  test("when the scene changes under a conversation, the box closes and nothing carries over", () => {
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(5);
    expect(box().active).toBe(true);
    game.load("scenes/upstairs.scene.json", { arrive: "spawn_default" });
    game.step(20);
    expect(scene.current).toBe("scenes/upstairs.scene.json");
    expect(dialogue.active()).toBe(false);
    expect(box().active).toBe(false);
    expect(porter().behaviour.locked).toBe(false);
  });
});

test("the options menu cycles the dialogue text speed and saves it", () => {
  game.resetState();
  scene.load("scenes/menu.scene.json");
  game.step(3);
  game.click(game.find("options_button"));
  game.step(3);
  game.click(game.find("tab_access"));
  game.step(3);
  const button = () => game.find("text_speed").get("Button").text;
  expect(button()).toBe("Dialogue text speed: normal");
  game.click(game.find("text_speed"));
  game.step(2);
  expect(button()).toBe("Dialogue text speed: fast");
  expect(settings.load().textSpeed).toBe(90);
  game.click(game.find("text_speed"));
  expect(button()).toBe("Dialogue text speed: instant");
  expect(settings.load().textSpeed).toBe(0);
  game.click(game.find("text_speed"));
  expect(button()).toBe("Dialogue text speed: slow");
  expect(settings.load().textSpeed).toBe(20);
  game.screenshot(".factoria/screenshots/options_audio.png");
});

group("a conversation in the hall", () => {
  test("screenshots: a line, then the answers", () => {
    chapters.begin();
    game.load("scenes/ground.scene.json", { arrive: "spawn_default" });
    game.step(300);
    stand(15, 20.9, 0);
    const mara = game.find("npc_mara");
    expect(mara).toBeTruthy();
    expect(dialogue.start("ch1_mara", { speaker: "npc_mara" }).started).toBe(true);
    game.step(120);
    game.screenshot(".factoria/screenshots/dialogue_line.png");
    game.tapKey("Space");
    game.step(15);
    game.tapKey("Space");
    game.step(15);
    complete();
    game.step(30);
    expect(view().choicesShown).toBe(true);
    game.screenshot(".factoria/screenshots/dialogue_choices.png");
  });
});
