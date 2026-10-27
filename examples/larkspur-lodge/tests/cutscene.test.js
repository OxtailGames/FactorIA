// The cut-scene player: it plays a file of data/cutscenes to its end, skips by keyboard, gamepad and touch to the same end state, keeps
// the pause menu working, times its captions with the voice, ducks the music under speech and gives each room its reverb, and the
// story asks for it where the dialogue and the chapters say.
import { test, describe, expect, beforeEach, game } from "factoria:test";
import { scene, world, audio } from "factoria";
import strings from "../locales/en.json";
import * as story from "../scripts/story.js";
import * as items from "../scripts/items.js";
import * as chapters from "../scripts/chapters.js";
import * as cutscene from "../scripts/cutscene.js";
import * as mix from "../scripts/mix.js";
import * as saves from "../scripts/saves.js";
import * as save_data from "../scripts/save_data.js";
import * as dialogue from "../scripts/dialogue.js";
import { EVENTS } from "../scripts/events.js";
import storyData from "../data/story.json";
import { CUTSCENES } from "../scripts/cutscene_data.js";
import { porter, cam } from "./helpers/lodge.js";

const FPS = 60;
const seconds = (s) => game.step(Math.round(s * FPS));
const hud = () => game.find("hud").behaviour;
const view = () => game.find("cutscene_ui").behaviour;

/** A new game in `area`, the first area opened by the intro (as the title menu's Play does) or by `chapter`'s lead-in. */
function newGame({ area = "ground", chapter = 1, intro = false, flags = {} } = {}) {
  game.resetState();
  story.reset();
  items.reset();
  cutscene.useClips({});
  game.clearAudioLog();
  chapters.begin({ intro });
  for (let i = 2; i <= chapter; i++) {
    story.set("chapter", i);
    for (const fx of storyData.chapters[i - 1].enter ?? []) if (fx.set) story.set(fx.set, true);
  }
  for (const [k, v] of Object.entries(flags)) story.set(k, v);
  game.load(`scenes/${area}.scene.json`, { arrive: "spawn_default" });
  game.step(10);
}

/** What the game looks like when a cut-scene is over: the things a watched and a skipped one must agree on. */
function endState() {
  const p = porter();
  return JSON.stringify({
    active: cutscene.active(),
    flags: story.snapshot().flags,
    locked: p.behaviour.locked,
    puppet: p.behaviour.puppet,
    at: [p.position.x, p.position.z].map((v) => Math.round(v * 100) / 100),
    bars: view().shown,
    captions: game.captions().length,
  });
}

/** Plays the intro on a plain test scene start and returns once it is running. */
function startIntro() {
  newGame({ intro: true });
  expect(cutscene.active()).toBe(true);
}

describe("playing", () => {
  beforeEach(() => startIntro());

  test("a new game from the title opens with the intro: porter locked and puppeted, bars up, camera directed", () => {
    expect(cutscene.current().id).toBe("intro");
    expect(cutscene.current().skippable).toBe(true);
    expect(porter().behaviour.locked).toBe(true);
    expect(porter().behaviour.puppet).toBe(true);
    expect(view().shown).toBe(true);
    expect(view().skipVisible).toBe(true);
    expect(cam().behaviour.directed).toBe(true);
    expect(story.get("intro_seen", false)).toBe(false);
  });

  test("it plays to its end by itself: the flag is set, the porter free, the camera his again, then the chapter card", () => {
    const d = CUTSCENES.intro.duration;
    seconds(d - 1);
    expect(cutscene.active()).toBe(true);
    expect(cutscene.current().time).toBeGreaterThan(d - 2);
    seconds(2);
    expect(cutscene.active()).toBe(false);
    expect(cutscene.seen()).toEqual([{ id: "intro", skipped: false }]);
    expect(story.get("intro_seen", false)).toBe(true);
    expect(porter().behaviour.puppet).toBe(false);
    expect(view().shown).toBe(false);
    expect(cam().behaviour.directed).toBe(false);
    seconds(2);
    expect(porter().behaviour.locked).toBe(false);
    expect(hud().message).toBe(strings.chapter["1"].intro);
  });

  test("the captions come at the seconds of the file, with the speaker's name", () => {
    const line1 = CUTSCENES.intro.timeline.find((s) => s.do === "caption");
    seconds(line1.at - 0.3);
    expect(game.captions()).toEqual([]);
    seconds(0.6);
    expect(game.captions().map((c) => c.text)).toEqual([strings.cutscene.intro.line01]);
    seconds(line1.seconds + 0.2);
    expect(game.captions().map((c) => c.key)).not.toContain("cutscene.intro.line01");
  });

  test("the camera moves on its own and the porter walks where the file sends him", () => {
    const c0 = [cam().position.x, cam().position.z];
    const walk = CUTSCENES.intro.timeline.find((s) => s.do === "move" && s.actor === "porter");
    seconds(walk.at + walk.seconds + 0.5);
    expect(Math.hypot(cam().position.x - c0[0], cam().position.z - c0[1])).toBeGreaterThan(1);
    expect(porter().position.x).toBeCloseTo(walk.to[0], 1);
    expect(porter().position.z).toBeCloseTo(walk.to[1], 1);
  });

  test("a title card shows in the middle and fades", () => {
    newGame({ chapter: 5, area: "ground", flags: {} });
    const id = cutscene.current()?.id;
    expect(id).toBe("chapter_5");
    const card = CUTSCENES.chapter_5.timeline.find((s) => s.do === "card");
    if (!card) return;
    seconds(card.at + card.seconds / 2);
    expect(view().cardText).toBe(strings.cutscene.chapter_5[card.key.split(".").pop()] ?? view().cardText);
    expect(view().cardAlpha).toBeGreaterThan(0.9);
    seconds(card.seconds);
    expect(view().cardAlpha).toBe(0);
  });
});

describe("skipping reaches the same end state as watching", () => {
  let watched;
  beforeEach(() => {
    startIntro();
    seconds(CUTSCENES.intro.duration + 0.5);
    watched = endState();
  });

  const skipsWith = (press) => {
    startIntro();
    seconds(2);
    press();
    game.step(3);
    expect(cutscene.active()).toBe(false);
    expect(cutscene.seen()).toEqual([{ id: "intro", skipped: true }]);
    expect(endState()).toBe(watched);
  };

  test("Space", () => skipsWith(() => game.tapKey("Space")));

  test("gamepad B", () => {
    game.gamepad(0).connect({ type: "xbox" });
    skipsWith(() => game.gamepad(0).tap("B"));
  });

  test("a tap on the Skip button", () => {
    skipsWith(() => {
      const b = game.find("cs_skip");
      game.touchStart(b, 1);
      game.step(2);
      game.touchEnd(1);
    });
  });

  test("a click on the Skip button", () => skipsWith(() => game.click(game.find("cs_skip"))));

  test("the Skip button names the key of the device in use", () => {
    startIntro();
    seconds(1);
    game.tapKey("W");
    game.step(2);
    expect(game.find("cs_skip").get("Button").text).toBe(strings.cutscene.hint.replace("{key}", "Space"));
    game.gamepad(0).connect({ type: "xbox" });
    game.gamepad(0).tap("A");
    game.step(2);
    expect(game.find("cs_skip").get("Button").text).toBe(strings.cutscene.hint.replace("{key}", "B"));
  });

  test("a press in the first moments does not skip (it may be the one that closed a conversation)", () => {
    startIntro();
    game.step(2);
    game.tapKey("Space");
    seconds(0.1);
    expect(cutscene.active()).toBe(true);
    seconds(1);
    game.tapKey("Space");
    game.step(3);
    expect(cutscene.active()).toBe(false);
  });

  test("a cut-scene that is not skippable ignores the key and the button", () => {
    newGame({ intro: false });
    const r = cutscene.play("chapter_2", { skippable: false });
    expect(r.played).toBe(true);
    expect(r.skippable).toBe(false);
    expect(view().skipVisible).toBe(false);
    seconds(1);
    game.tapKey("Space");
    game.step(3);
    expect(cutscene.skip()).toBe(false);
    expect(cutscene.active()).toBe(true);
  });
});

describe("active() is reliable", () => {
  test("it is true from play() to the end, also for a queued one, and false after", () => {
    newGame({ intro: false });
    expect(cutscene.active()).toBe(false);
    const a = cutscene.play("chapter_2");
    expect(a).toMatchObject({ played: true, queued: false });
    expect(cutscene.active()).toBe(true);
    const b = cutscene.play("chapter_3");
    expect(b).toMatchObject({ played: true, queued: true });
    seconds(0.5);
    cutscene.skip();
    expect(cutscene.current().id).toBe("chapter_3");
    expect(cutscene.active()).toBe(true);
    seconds(0.5);
    cutscene.skip();
    expect(cutscene.active()).toBe(false);
    expect(cutscene.seen().map((e) => e.id)).toEqual(["chapter_2", "chapter_3"]);
  });

  test("an unknown id, and one shot in another area, do not play and say why", () => {
    newGame({ intro: false });
    expect(cutscene.play("intru")).toMatchObject({ played: false, reason: "unknown" });
    expect(cutscene.play("adit_descent")).toMatchObject({ played: false, reason: "other_area" });
    expect(cutscene.active()).toBe(false);
  });

  test("play() sends cutscene_requested, and the events bracket the cut-scene", () => {
    newGame({ intro: false });
    const log = [];
    for (const name of ["cutsceneRequested", "cutsceneStarted", "cutsceneEnded"]) world.on(EVENTS[name], (e) => log.push(`${name} ${e.id}${e.skipped ? " skipped" : ""}`));
    cutscene.play("chapter_2");
    seconds(0.5);
    cutscene.skip();
    game.step(2);
    expect(log).toEqual(["cutsceneRequested chapter_2", "cutsceneStarted chapter_2", "cutsceneEnded chapter_2 skipped"]);
  });

  test("a cut-scene that was running when its scene went away is dropped, and the next scene is free", () => {
    newGame({ intro: false });
    cutscene.play("chapter_2");
    seconds(0.5);
    expect(cutscene.active()).toBe(true);
    game.load("scenes/upstairs.scene.json", { arrive: "spawn_default" });
    game.step(5);
    expect(scene.current).toBe("scenes/upstairs.scene.json");
    expect(cutscene.active()).toBe(false);
    expect(porter().behaviour.locked).toBe(false);
  });
});

describe("the pause menu keeps working", () => {
  test("pausing stops the timeline; resuming goes on; skipping jumps to the end", () => {
    startIntro();
    seconds(2);
    game.tap("pause");
    game.step(3);
    expect(game.paused).toBe(true);
    expect(game.find("pause_panel").active).toBe(true);
    const t0 = cutscene.current().time;
    seconds(2);
    expect(cutscene.current().time).toBeCloseTo(t0, 1);
    game.click(game.find("resume"));
    game.step(5);
    expect(game.paused).toBe(false);
    seconds(1);
    expect(cutscene.current().time).toBeGreaterThan(t0 + 0.5);
    game.tapKey("Space");
    game.step(3);
    expect(cutscene.active()).toBe(false);
  });
});

describe("voice, captions and the mix", () => {
  const CLIP = { path: "tests/fixtures/test_voice.wav", seconds: 2.5 };

  test("with a voice clip the caption lasts as long as the clip, on the voiceover bus", () => {
    newGame({ intro: true });
    cutscene.useClips({ intro_01: CLIP });
    const step = CUTSCENES.intro.timeline.find((s) => s.voice === "intro_01");
    seconds(step.at + 0.1);
    expect(game.audioLog()).toContainPlayed("test_voice.wav", { bus: "voiceover" });
    expect(game.captions().map((c) => c.text)).toEqual([strings.cutscene.intro.line01]);
    expect(game.captions()[0].source).toBe("audio:tests/fixtures/test_voice.wav");
    seconds(CLIP.seconds - 0.5);
    expect(game.captions().length).toBe(1);
    seconds(1);
    expect(game.captions().length).toBe(0);
  });

  test("without a clip the caption lasts the step's seconds", () => {
    newGame({ intro: true });
    const step = CUTSCENES.intro.timeline.find((s) => s.voice === "intro_01");
    seconds(step.at + step.seconds - 0.5);
    expect(game.captions().map((c) => c.key)).toEqual([step.key]);
    expect(game.audioLog()).not.toContainPlayed("test_voice.wav");
    seconds(1);
    expect(game.captions().map((c) => c.key)).not.toContain(step.key);
  });

  test("a voice line that was speaking when the game paused is said again from its start", () => {
    newGame({ intro: true });
    cutscene.useClips({ intro_01: CLIP });
    const step = CUTSCENES.intro.timeline.find((s) => s.voice === "intro_01");
    seconds(step.at + 1);
    game.tap("pause");
    game.step(3);
    expect(game.captions().length).toBe(0);
    game.click(game.find("resume"));
    game.step(5);
    expect(game.captions().map((c) => c.text)).toEqual([strings.cutscene.intro.line01]);
  });

  test("skipping stops the voice and clears the captions", () => {
    newGame({ intro: true });
    cutscene.useClips({ intro_01: CLIP });
    const step = CUTSCENES.intro.timeline.find((s) => s.voice === "intro_01");
    seconds(step.at + 0.5);
    expect(game.captions().length).toBe(1);
    game.tapKey("Space");
    game.step(3);
    expect(game.captions().length).toBe(0);
  });

  test("music and sfx duck under the voiceover bus", () => {
    newGame({ intro: true });
    for (const name of ["music", "sfx"]) {
      const d = audio.bus(name).state().duck;
      expect(d.by).toBe("voiceover");
      expect(d.amount).toBeGreaterThan(0.3);
    }
    expect(mix.state().duck.music.by).toBe("voiceover");
  });

  test("each room gives the voice its own reverb; the cellar is dull and wet, and the bus goes dry at the end", () => {
    newGame({ area: "cellar", chapter: 4, flags: {} });
    cutscene.skip();
    seconds(0.5);
    newGame({ intro: true });
    seconds(1);
    expect(mix.state().room).toBe("hall");
    const hall = audio.bus("voiceover").state();
    expect(hall.reverb).toBeGreaterThan(0.15);
    expect(hall.lowpass).toBe(0);
    cutscene.skip();
    seconds(1);
    expect(mix.state().room).toBe("");
    expect(audio.bus("voiceover").state().reverb).toBeLessThan(0.01);
    newGame({ area: "cellar", intro: false });
    cutscene.play("adit_descent");
    seconds(1);
    expect(mix.state().room).toBe("cellar");
    const cellar = audio.bus("voiceover").state();
    expect(cellar.reverb).toBeGreaterThan(hall.reverb);
    expect(cellar.lowpass).toBeGreaterThan(1000);
  });
});

describe("the story asks for them", () => {
  test("the intro plays once: a second new game that has seen it goes straight to the card", () => {
    newGame({ intro: true, flags: { intro_seen: true } });
    expect(cutscene.active()).toBe(false);
    seconds(3);
    expect(hud().message).toBe(strings.chapter["1"].intro);
  });

  test("a game that did not come from the title (a test, a load) does not play the intro", () => {
    newGame({ intro: false });
    expect(cutscene.active()).toBe(false);
  });

  test("each later chapter opens with its own cut-scene, once, then its card", () => {
    for (const n of [2, 3, 4, 5]) {
      newGame({ chapter: n });
      expect(cutscene.current()?.id, `chapter ${n}`).toBe(`chapter_${n}`);
      seconds(CUTSCENES[`chapter_${n}`].duration + 12);
      expect(cutscene.active()).toBe(false);
      expect(cutscene.seen().map((e) => e.id)).toEqual([`chapter_${n}`]);
      expect(hud().message || chapters.current()).toBeTruthy();
      game.load("scenes/ground.scene.json", { arrive: "spawn_default" });
      game.step(30);
      expect(cutscene.active(), `chapter ${n} again`).toBe(false);
    }
  });

  test("a conversation that asks for a cut-scene is covered by it and comes back after", () => {
    newGame({ chapter: 4, area: "cellar", flags: {} });
    cutscene.skip();
    seconds(1);
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(20);
    expect(game.find("dialogue_ui").active).toBe(true);
    cutscene.play("adit_descent");
    game.step(20);
    expect(game.find("dialogue_ui").active).toBe(false);
    game.tapKey("Space");
    game.step(3);
    expect(dialogue.current().line.node).toBe("dlg.ch1_mara.greet"); // the key went to the cut-scene, not to the conversation
    cutscene.skip();
    seconds(1);
    expect(cutscene.active()).toBe(false);
    expect(game.find("dialogue_ui").active).toBe(true);
    expect(dialogue.active()).toBe(true);
  });
});

describe("saving", () => {
  const settle = () => {
    for (let i = 0; i < 4 && cutscene.active(); i++) {
      cutscene.skip();
      seconds(1);
    }
  };

  test("a game cannot be saved while a cut-scene plays, and can once it ends or is skipped", () => {
    newGame({ area: "ground", chapter: 1, intro: false });
    settle();
    expect(saves.cannotSave()).toBe("");
    expect(cutscene.play("intro").played).toBe(true);
    seconds(1);
    expect(cutscene.active()).toBe(true);
    expect(saves.cannotSave()).toBe("slots.noCutscene");
    expect(saves.write(1, { name: "During" })).toBeNull();
    cutscene.skip();
    seconds(1);
    expect(cutscene.active()).toBe(false);
    expect(saves.cannotSave()).toBe("");
    expect(saves.write(1, { name: "After the skip" })).not.toBeNull();
    // and one watched to its end
    expect(cutscene.play("intro").played).toBe(true);
    seconds(cutscene.current().duration + 2);
    expect(cutscene.active()).toBe(false);
    expect(saves.cannotSave()).toBe("");
  });

  test("a queued cut-scene counts too, and intro_seen comes back with the save", () => {
    newGame({ area: "ground", chapter: 1, intro: false });
    settle();
    cutscene.play("intro");
    cutscene.play("chapter_2");
    cutscene.skip();
    seconds(0.5);
    expect(cutscene.active()).toBe(true); // the second one is on
    expect(saves.cannotSave()).toBe("slots.noCutscene");
    settle();
    expect(story.has("intro_seen")).toBe(true);
    const data = save_data.snapshot();
    expect(data.state.story.flags.intro_seen).toBe(true);
  });
});

describe("what a cut-scene looks like", () => {
  test("a caption mid-play, a title card and a fade are drawn (screenshots in .factoria/screenshots)", () => {
    newGame({ area: "ground", chapter: 5 });
    expect(cutscene.play("intro").played).toBe(true);
    seconds(9);
    expect(game.captions().length).toBe(1);
    game.screenshot(".factoria/screenshots/cutscene_caption.png");
    for (let i = 0; i < 4 && cutscene.active(); i++) {
      cutscene.skip();
      seconds(1);
    }
    expect(cutscene.active()).toBe(false);
    expect(cutscene.play("chapter_2").played).toBe(true);
    seconds(0.5);
    game.screenshot(".factoria/screenshots/cutscene_fade.png");
    seconds(3);
    game.screenshot(".factoria/screenshots/cutscene_card.png");
    for (let i = 0; i < 4 && cutscene.active(); i++) {
      cutscene.skip();
      seconds(1);
    }
    expect(cutscene.active()).toBe(false);
  });
});
