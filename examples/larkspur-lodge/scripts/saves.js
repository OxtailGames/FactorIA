// @ts-check
// The save slots of the lodge: five manual slots and one autosave, kept by the menu kit's Slots (scripts/slots.js: the record
//
//   { "counter": 7, "name": "Before the cellar", "chapter": 3, "playTime": 3725.5, "pic": "<base64 PNG>" | null, "data": <save_data.js save> }
//
// in `storage` under "slot1".."slot5" / "slot_auto", the counter, the cloud copy and the merge by counter, damaged slots). The screen is
// the kit's too (scripts/ui/slot_screen.js). What is the lodge's own lives here: `data` is the versioned save (scripts/save_data.js: any
// older version is migrated when it is read), when the game may not be saved (cannotSave), the name of a save nobody named (the chapter),
// the stat of saves made, the chapter autosave and how a slot is launched (the loading screen, standing where the porter was).
// The module-level functions are what the rest of the game and its tests call.
import { session, i18n, scene, game, world } from "factoria";
import * as save_data from "./save_data.js";
import * as chapters from "./chapters.js";
import * as dialogue from "./dialogue.js";
import * as cutscene from "./cutscene.js";
import * as progress from "./progress.js";
import { AREAS } from "./area.js";
import { Slots, formatTime, capturePic as kitCapturePic, PIC } from "./slots.js";

export { formatTime, PIC };

/** The kit's records, with the lodge's save layout: `upgrade` migrates a save of an older version, `describe` reads a bare (v1) save. */
export const slots = new Slots({
  upgrade: (data) => save_data.upgrade(data),
  describe: (data) => ({ chapter: Number(data.state?.story?.flags?.chapter) || 0, playTime: data.playTime }),
});
export const SLOTS = slots.SLOTS;
export const AUTO = /** @type {string} */ (slots.AUTO);
/** Every slot the screen shows, the autosave first. */
export const ALL = slots.ALL;

/** The storage key (and cloud key) of a slot id (1..5 or "auto"). */
export const key = (id) => slots.key(id);
/** Reads the text of a slot (or a cloud copy): `{ ok: true, record }` or `{ ok: false, reason, hint }`. Never throws. */
export const parse = (text) => slots.parse(text);
/** What the slot screen shows: `{ status: "empty" | "used" | "damaged", reason?, hint?, record? }`. */
export const peek = (id) => slots.peek(id);
/** Empties slot `id` here and in the cloud. */
export const remove = (id) => slots.remove(id);
/** Compares every slot with its cloud copy (higher counter wins); true when a local slot was replaced. */
export const syncCloud = () => slots.syncCloud();
/** A picture of the game as the player sees it (base64 PNG) or null. Take it before a menu covers the game. */
export const capturePic = () => kitCapturePic();

/** Name for a save the player did not name: the chapter's title. */
export function defaultName() {
  const info = chapters.info();
  return info ? i18n.t(info.titleKey) : "";
}

/**
 * Why the game cannot be saved now, as a locale key, or "" when it can: not in a game (a bare scene), a cut-scene or a
 * conversation is running, or the porter is between areas or chapters.
 */
export function cannotSave() {
  if (chapters.current() === 0 || !world.find("porter")) return "slots.noGame";
  if (cutscene.active()) return "slots.noCutscene";
  if (dialogue.active()) return "slots.noDialogue";
  const ch = world.find("chapters")?.behaviour;
  const area = world.find("area")?.behaviour;
  if ((ch && ch.stage !== "") || (area && area.leaving !== "")) return "slots.busy";
  return "";
}

/**
 * Saves the current game into slot `id`. `name` falls back to the chapter's title; `pic` is capturePic() (null = none).
 * Returns the record, or null when the game cannot be saved now (cannotSave()).
 */
export function write(id, { name = "", pic = null } = {}) {
  if (cannotSave()) return null;
  const data = save_data.snapshot();
  const record = slots.write(id, { data, name: name.trim() || defaultName(), chapter: chapters.current(), playTime: data.playTime, pic });
  if (id !== AUTO) progress.addStat("saves_made");
  return record;
}

/**
 * The autosave of a chapter start: the autosave slot, and the data the chapter select starts from. Returns the record or null.
 */
export function autosave() {
  const record = write(AUTO, { pic: capturePic() });
  if (record) progress.recordChapterStart(record.chapter, record.data);
  return record;
}

/**
 * Starts playing from a save (a slot's data, or a chapter start): puts the state back, then loads the area through the loading
 * screen, standing where the save says. Returns { ok, message, hint } (nothing happens when not ok).
 */
export function launch(data) {
  const r = save_data.apply(data);
  if (!r.ok) return r;
  const n = chapters.current();
  session.chapterShown = n; // no chapter card for a game that is picked up again
  session.autosavedChapter = n; // and no autosave over the very slot it was loaded from
  session.nextScene = AREAS[r.area];
  session.loadRestore = true;
  game.paused = false; // time.scale and the pause outlive scene loads
  scene.load("scenes/loading.scene.json");
  return r;
}

/** Loads slot `id`. Returns { ok, message, hint }. */
export function load(id) {
  const p = peek(id);
  if (p.status !== "used") return { ok: false, message: p.status === "empty" ? "the slot is empty" : `the slot is damaged: ${p.reason}`, hint: p.hint ?? "" };
  return launch(p.record.data);
}
