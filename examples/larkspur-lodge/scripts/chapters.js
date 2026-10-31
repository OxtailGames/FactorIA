// @ts-check
// The five chapters of the night and its end. The chapter is the story flag "chapter" (1 to 5; 0 = a game that has not begun, e.g. a
// bare test scene). data/story.json "chapters" says, for each one, the conditions that end it ("advance"), what changes when it
// begins ("enter") and where the porter is taken ("start"); the last chapter is "final": the story ends when ch5_vale sets the flag
// "ending" (dawn, quiet or long).
//
// Plain functions (no scene needed; tests and the story bot use them):
//   chapters.begin()      a new game: forgets the conversations, chapter 1
//   chapters.current()    the chapter number (0 before begin())
//   chapters.due()        whether the conditions to leave the chapter hold now
//   chapters.advance()    moves to the next chapter when due(): applies its "enter" effects, sends EVENTS.chapterChanged; returns the new number or 0
//   chapters.ending()     the ending id once the story reached one, else ""
//
// The Chapters behaviour (one entity "chapters" in each area scene) does it on screen. When a flag or the inventory changes, or a
// conversation ends, and the chapter is due, it waits for no conversation to run, locks the porter, fades to black, advances,
// takes the porter to the chapter's start spot if it has one (a scene change when that is another area), shows the chapter card and
// the intro line, and fades back in. When the ending flag is set it fades to black, shows prefabs/ui/ending.prefab.json (title, text,
// Main menu) and sends EVENTS.storyEnded; the porter takes no input then.
//
// Cut-scenes (scripts/cutscene.js): a new game from the title menu opens with "intro" (once: the flag intro_seen); a chapter from the
// second on opens with "chapter_<n>" on the black screen, before its card; the ending is told by "ending_<id>" before the ending screen.
// A chapter that is due waits for a cut-scene to end, as it waits for a conversation.
//
// Fields tests read: `stage` ("" | "out" | "hold" | "cut" | "in" | "leaving" | "ending"), `endingShown`, `cardShown`.
import { Behaviour, world, scene, session, ui, i18n } from "factoria";
import { EVENTS, emit } from "./events.js";
import * as story from "./story.js";
import * as items from "./items.js";
import * as dialogue from "./dialogue.js";
import * as cutscene from "./cutscene.js";
import { holds, parseEffect } from "./conditions.js";
import { story as data } from "./dialogue_data.js";

const env = { get: (flag, fallback = false) => story.get(flag, fallback), hasItem: (id) => items.has(id) };

/** The chapter number (1 to 5), or 0 when the game has not begun. */
export function current() {
  return Number(story.get("chapter", 0)) || 0;
}

/** The entry of data/story.json for chapter `n`, or null. */
export function info(n = current()) {
  return data.chapters[n - 1] ?? null;
}

/** True for the last chapter. */
export function isFinal(n = current()) {
  return !!info(n)?.final;
}

/**
 * A new game: no conversation history, chapter 1 (call it after story.reset() and items.reset()). `intro: true` (the title menu's
 * Play) makes the first area play the opening cut-scene once; the bare begin() of a test does not.
 */
export function begin({ intro = false } = {}) {
  dialogue.reset();
  session.chapterShown = 0;
  session.leadInShown = 0;
  session.cutscenesSeen = [];
  session.introPending = intro;
  story.set("chapter", 1);
  applyEffects(info(1)?.enter);
}

/** Whether the conditions that end the current chapter hold. The final chapter, and a game that has not begun, are never due. */
export function due() {
  const c = info();
  return !!c && !c.final && holds(c.advance, env);
}

/** Goes to the next chapter if the current one is due. Returns the new chapter number, or 0 when nothing changed. */
export function advance() {
  if (!due()) return 0;
  const previous = current();
  const next = previous + 1;
  story.set("chapter", next);
  applyEffects(info(next)?.enter);
  emit(EVENTS.chapterChanged, { chapter: next, previous });
  return next;
}

/** The ending the story reached ("dawn", "quiet", "long"), or "". */
export function ending() {
  const e = story.get("ending", "");
  return typeof e === "string" && data.endings[e] ? e : "";
}

/** Applies a list of effects of data/story.json (the same language as the dialogue tables). */
function applyEffects(list) {
  for (const fx of list ?? []) {
    const e = parseEffect(fx);
    if (!e.ok) throw new Error(`data/story.json: effect ${JSON.stringify(fx)}: ${e.message}. ${e.hint}`);
    if (e.kind === "set") story.set(e.target, e.value);
    else if (e.kind === "add") story.set(e.target, (Number(story.get(e.target, 0)) || 0) + e.value);
    else if (e.kind === "give") items.add(e.target, "chapter");
    else if (e.kind === "take") items.remove(e.target);
    else if (e.kind === "cutscene") cutscene.play(e.target);
  }
}

/** Seconds the screen takes to go black, stays black while the cast changes, and clears. */
const OUT = 0.7;
const HOLD = 0.5;
const IN = 0.9;
/** Seconds of the chapter card on screen and of the intro line under it. */
const CARD = 4.5;
const INTRO = 8;

export default class Chapters extends Behaviour {
  onStart() {
    /** The scene this belongs to: a result for another scene is dropped. */
    this.scenePath = scene.current;
    this.stage = "";
    this.stageTime = 0;
    /** What to do when the cut-scene that plays ends: "announce" (the chapter card), "ending" (the ending screen) or "". */
    this.after = "";
    this.opening = false;
    this.endingCut = false;
    this.endingShown = false;
    this.cardShown = 0;
    this.holdLeft = 0;
    this.hud = world.find("hud")?.behaviour ?? null;
    const root = world.spawnPrefab("prefabs/ui/ending.prefab.json");
    root.id = "ending_ui";
    root.active = false;
    this.endingRoot = root;
    world.on(EVENTS.flagChanged, () => this.check());
    world.on(EVENTS.inventoryChanged, () => this.check());
    world.on(EVENTS.dialogueEnded, () => this.check());
    world.on(EVENTS.cutsceneEnded, () => this.onCutsceneEnded());
    ui.on("click", "ending_menu", () => scene.current === this.scenePath && scene.load("scenes/menu.scene.json"));
    // The first area of a chapter shows its card (a scene change inside a chapter does not).
    // The opening waits for the first update: every behaviour of the scene (the cut-scene view, the cast) has started by then.
    this.opening = current() > 0 && session.chapterShown !== current();
  }

  /** The first update of a scene in a chapter whose card has not shown: chapter 1 of a new game opens with the intro, a later chapter with its lead-in. */
  open() {
    const n = current();
    if (n === 1 && session.introPending && !story.get("intro_seen", false)) {
      session.introPending = false;
      session.chapterShown = n;
      this.after = "announce";
      this.stage = "cut";
      if (!this.play("intro")) this.onCutsceneEnded();
    } else if (n > 1 && this.leadIn(n)) {
      this.stage = "cut";
    } else this.announce(n);
  }

  /** Plays a cut-scene. False when it does not play (nothing waits for it then: the caller goes on). */
  play(id) {
    return cutscene.play(id).played;
  }

  /** Starts the cut-scene that opens chapter `n` (data/cutscenes/chapter_<n>.cutscene.json), once per chapter. Returns whether one plays. */
  leadIn(n) {
    if (session.leadInShown === n) return false;
    session.leadInShown = n;
    this.after = "announce";
    const played = this.play(`chapter_${n}`);
    if (!played) this.after = "";
    return played;
  }

  /** A cut-scene is over: the chapter goes on (its card and the clear screen), the ending screen shows, or a due change is looked at. */
  onCutsceneEnded() {
    if (scene.current !== this.scenePath || cutscene.active()) return;
    const after = this.after;
    this.after = "";
    if (after === "announce") {
      this.stage = "in";
      this.stageTime = 0;
      this.announce(current());
      this.hud?.fadeTo(0, IN);
    } else if (after === "ending") this.showEnding();
    this.check();
  }

  /** The chapter card (its number and name) and the intro line. */
  announce(n) {
    const c = info(n);
    if (!c || !this.hud) return;
    session.chapterShown = n;
    this.cardShown = n;
    this.hud.showTitleText(`${i18n.t("chapter.label", { n })}\n${i18n.t(c.titleKey)}`, CARD);
    this.hud.say(c.introKey, {}, INTRO);
  }

  /** Looks at the story: the ending was reached, or the chapter is over. Waits while a conversation runs or a change is under way. */
  check() {
    if (scene.current !== this.scenePath || this.stage !== "" || dialogue.active() || cutscene.active()) return;
    if (isFinal() && ending()) this.startStage("ending");
    else if (due()) this.startStage("out");
  }

  startStage(stage) {
    this.stage = stage;
    this.stageTime = 0;
    world.find("porter")?.behaviour?.lock(stage === "ending" ? "ending" : "chapter");
    this.hud?.fadeTo(1, stage === "ending" ? 1.2 : OUT);
  }

  onUpdate(dt) {
    if (this.opening) {
      this.opening = false;
      this.open();
    }
    if (this.stage === "") {
      // A flag set by a script that ran before this behaviour started, or a lock released late, is caught here too.
      if (this.stageTime >= 0.25) {
        this.stageTime = 0;
        this.check();
      } else this.stageTime += dt;
      return;
    }
    this.stageTime += dt;
    if (this.stage === "out" && !this.hud?.fading) this.change();
    else if (this.stage === "hold" && this.stageTime >= HOLD) {
      if (this.leadIn(current())) {
        this.stage = "cut";
        return;
      }
      this.stage = "in";
      this.stageTime = 0;
      this.announce(current());
      this.hud?.fadeTo(0, IN);
    } else if (this.stage === "in" && this.stageTime >= IN) {
      world.find("porter")?.behaviour?.unlock("chapter");
      this.stage = "";
      this.stageTime = 0;
      this.check(); // the new chapter may already be due
    } else if (this.stage === "ending" && !this.endingShown && !this.endingCut && !this.hud?.fading) {
      this.endingCut = true;
      this.after = "ending";
      if (!this.play(`ending_${ending()}`)) this.showEnding();
    }
  }

  /** The screen is black: move to the next chapter and take the porter to where it starts. */
  change() {
    const n = advance();
    if (n === 0) {
      // Nothing to do after all (the flag went back): clear the screen again.
      this.hud?.fadeTo(0, IN);
      world.find("porter")?.behaviour?.unlock("chapter");
      this.stage = "";
      return;
    }
    const start = info(n)?.start;
    const areaCtl = world.find("area")?.behaviour;
    if (start && areaCtl && start.area !== areaCtl.area) {
      // Another area: the chapter card shows there (session.chapterShown is behind), this scene is about to go.
      this.stage = "leaving";
      areaCtl.goTo(start.area, start.spawn);
      return;
    }
    if (start) this.moveTo(start.spawn);
    this.stage = "hold";
    this.stageTime = 0;
  }

  /** Puts the porter on the spawn entity `id` of this scene and aims the camera behind it. */
  moveTo(id) {
    const spawn = world.find(id);
    const porter = world.find("porter");
    if (!spawn || !porter) return;
    const p = spawn.worldPosition;
    porter.position = [p.x, p.y, p.z];
    const yaw = spawn.get("Transform").rotation[1];
    porter.behaviour?.faceYaw(yaw);
    world.find("camera")?.behaviour?.snapBehind(yaw);
  }

  showEnding() {
    const id = ending();
    const e = data.endings[id];
    this.endingShown = true;
    this.after = "";
    this.endingRoot.active = true;
    world.find("ending_title").get("Text").text = i18n.t(e.titleKey);
    world.find("ending_text").get("Text").text = i18n.t(e.textKey);
    ui.focus(world.find("ending_menu"));
    emit(EVENTS.storyEnded, { ending: id });
  }
}
