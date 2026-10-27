// @ts-check
// What outlives a game in progress, kept in storage under "progress" (not in a slot, not in the settings):
//   endings        the endings the player has reached ("dawn", "quiet", "long"); the first one unlocks the chapter select
//   chapterStarts  chapter number -> the save data (scripts/save_data.js) taken when that chapter began in any game, so the
//                  chapter select starts a new run of the night from there with the story the player had then
// and the store services: achievements and stats on `platform` (the fake store in tests; the declarations are in factoria.json
// "platform"). Every call is best effort: no store, a player who is not signed in or a failed request never stops the game.
import { storage, platform, world } from "factoria";
import { EVENTS } from "./events.js";
import * as story from "./story.js";
import * as save_data from "./save_data.js";

export const ENDINGS = Object.freeze(["dawn", "quiet", "long"]);
/** The clue flags of data/story.json: the achievement "all_clues" needs every one in one game. */
export const CLUES = Object.freeze(["know_oil", "know_cellar", "know_page", "know_argument", "hedda_letter", "survey_known", "adit_known", "page_recovered"]);

function read() {
  const p = storage.get("progress", {});
  return { endings: Array.isArray(p.endings) ? p.endings : [], chapterStarts: p.chapterStarts && typeof p.chapterStarts === "object" ? p.chapterStarts : {} };
}

/** The endings reached so far, in the order they were first reached. */
export function endingsSeen() {
  return read().endings.filter((e) => ENDINGS.includes(e));
}

/** True once an ending was reached: the title screen then offers the chapter select. */
export function chapterSelectUnlocked() {
  return endingsSeen().length > 0;
}

/** Remembers the save data taken at the start of chapter `n` (the last game to reach it wins). */
export function recordChapterStart(n, data) {
  const p = read();
  p.chapterStarts[String(n)] = data;
  storage.set("progress", p);
}

/** The save data the chapter select starts chapter `n` from, or null (chapter 1 is a new game and has none). */
export function chapterStart(n) {
  return read().chapterStarts[String(n)] ?? null;
}

/** Forgets everything (a test). */
export function reset() {
  storage.remove("progress");
}

/** Best-effort call of a store service. */
function store(service, fn) {
  try {
    if (platform.has(service)) fn().catch(() => {});
  } catch {
    // a store that is not there: nothing to do
  }
}

export function unlock(id) {
  store("achievements", () => platform.achievements.unlock(id));
}

export function addStat(id, by = 1) {
  store("stats", () => platform.stats.add(id, by));
}

/** The ending was reached: remember it, and tell the store. */
export function endingReached(ending, playSeconds) {
  const p = read();
  if (!p.endings.includes(ending)) p.endings.push(ending);
  storage.set("progress", p);
  unlock(`ending_${ending}`);
  if (ENDINGS.every((e) => p.endings.includes(e))) unlock("all_endings");
  store("stats", () => platform.stats.set("endings_seen", ENDINGS.filter((e) => p.endings.includes(e)).length));
  store("stats", () => platform.stats.set("play_minutes", Math.floor(playSeconds / 60)));
}

/** Listens, in the running scene, to the events that make progress: endings and clues. Call once per scene. */
export function watch() {
  world.on(EVENTS.storyEnded, (e) => endingReached(e.ending, save_data.playTime()));
  world.on(EVENTS.flagChanged, (e) => {
    if (CLUES.includes(e.flag) && CLUES.every((c) => story.has(c))) unlock("all_clues");
  });
}
