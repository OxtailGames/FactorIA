// @ts-check
// The save slots: five manual slots and one autosave, in `storage` ("slot1".."slot5", "slot_auto"), each a string of JSON text and,
// when the player is signed in to a store, a copy in the cloud under the same key. A slot holds a RECORD:
//
//   { "counter": 7, "name": "Before the cellar", "chapter": 3, "playTime": 3725.5, "pic": "<base64 PNG>" | null, "data": <save_data.js save> }
//
// `data` is the versioned save (scripts/save_data.js: any older version is migrated when it is read); the rest is what the slot
// screen shows without opening it. `counter` goes up by one on every save (the wall clock is never read): the higher counter wins
// when a cloud copy and a local one differ. A slot that holds a bare save (a v1 file) is read as a record without a name or picture.
import { storage, session, platform, i18n, scene, game, render, world } from "factoria";
import * as save_data from "./save_data.js";
import * as chapters from "./chapters.js";
import * as dialogue from "./dialogue.js";
import * as cutscene from "./cutscene.js";
import * as progress from "./progress.js";
import { AREAS } from "./area.js";

export const SLOTS = Object.freeze([1, 2, 3, 4, 5]);
export const AUTO = "auto";
/** Every slot the screen shows, the autosave first. */
export const ALL = Object.freeze([AUTO, ...SLOTS]);
/** Size of the picture kept with a slot (16:9, a few KB as PNG). */
export const PIC = Object.freeze({ width: 192, height: 108 });

/** The storage key (and cloud key) of a slot id (1..5 or "auto"). */
export function key(id) {
  return id === AUTO ? "slot_auto" : `slot${id}`;
}

/** "h:mm:ss" for a number of seconds. */
export function formatTime(seconds) {
  const s = Math.max(0, Math.floor(seconds));
  const pad = (n) => String(n).padStart(2, "0");
  return `${Math.floor(s / 3600)}:${pad(Math.floor(s / 60) % 60)}:${pad(s % 60)}`;
}

/**
 * Reads the text of a slot (or a cloud copy). `{ ok: true, record }` with the data in the newest layout, or `{ ok: false, reason, hint }`
 * for text that is not JSON, not a save, or from a newer game. Never throws.
 * @param {any} text
 */
export function parse(text) {
  let raw;
  try {
    raw = typeof text === "string" ? JSON.parse(text) : text;
  } catch (e) {
    return { ok: false, reason: `not valid JSON (${e.message})`, hint: "Delete the slot." };
  }
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return { ok: false, reason: "not a JSON object", hint: "Delete the slot." };
  const bare = typeof raw.format === "string";
  const up = save_data.upgrade(bare ? raw : raw.data);
  if (!up.ok) return { ok: false, reason: up.message, hint: up.hint };
  const data = up.data;
  const chapter = bare ? Number(data.state.story?.flags?.chapter) || 0 : Number(raw.chapter) || Number(data.state.story?.flags?.chapter) || 0;
  return {
    ok: true,
    record: {
      counter: !bare && Number.isInteger(raw.counter) && raw.counter >= 0 ? raw.counter : 0,
      name: !bare && typeof raw.name === "string" ? raw.name : "",
      chapter,
      playTime: !bare && typeof raw.playTime === "number" ? raw.playTime : data.playTime,
      pic: !bare && typeof raw.pic === "string" && raw.pic !== "" ? raw.pic : null,
      data,
    },
  };
}

/** What the slot screen shows: `{ status: "empty" | "used" | "damaged", reason?, hint?, record? }`. */
export function peek(id) {
  const text = storage.get(key(id), null);
  if (text === null) return { status: "empty" };
  const r = parse(text);
  if (!r.ok) return { status: "damaged", reason: r.reason, hint: r.hint };
  return { status: "used", record: r.record };
}

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

/** A picture of the game as the player sees it, as base64 PNG, or null when nothing real can be drawn (no graphics). Take it before a menu covers the game. */
export function capturePic() {
  try {
    const tex = render.captureTexture({ width: PIC.width, height: PIC.height });
    const png = tex.placeholder ? null : tex.toPNG();
    tex.destroy();
    return png;
  } catch (e) {
    console.warn(`saves: no picture for the slot: ${e.message}`);
    return null;
  }
}

function nextCounter() {
  let top = storage.get("saveCounter", 0);
  for (const id of ALL) {
    const p = peek(id);
    if (p.status === "used") top = Math.max(top, p.record.counter);
  }
  storage.set("saveCounter", top + 1);
  return top + 1;
}

/**
 * Saves the current game into slot `id`. `name` falls back to the chapter's title; `pic` is capturePic() (null = none).
 * Returns the record, or null when the game cannot be saved now (cannotSave()).
 */
export function write(id, { name = "", pic = null } = {}) {
  if (cannotSave()) return null;
  const data = save_data.snapshot();
  const record = {
    counter: nextCounter(),
    name: name.trim() || defaultName(),
    chapter: chapters.current(),
    playTime: data.playTime,
    pic,
    data,
  };
  const text = JSON.stringify(record);
  storage.set(key(id), text);
  storage.set("lastSlot", id);
  upload(id, text);
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

/** Empties slot `id` here and in the cloud (otherwise the next sync would bring it back). */
export function remove(id) {
  storage.remove(key(id));
  if (storage.get("lastSlot", null) === id) storage.remove("lastSlot");
  if (platform.has("cloudSave")) platform.cloud.remove(key(id)).catch(() => {}); // a failed delete can come back at the next sync
}

function upload(id, text) {
  if (platform.has("cloudSave")) platform.cloud.save(key(id), text).catch(() => {}); // the local save stands whatever the store says
}

/**
 * Compares every slot with its cloud copy: the one with the higher counter wins (a cloud copy replaces the local slot, a better
 * local one is uploaded). A store that is down or a player who is not signed in changes nothing. Resolves with true when a local
 * slot was replaced. The caller checks that its scene is still the current one before it draws the result.
 */
export async function syncCloud() {
  if (!platform.has("cloudSave")) return false;
  let replaced = false;
  for (const id of ALL) {
    try {
      const cloud = await platform.cloud.load(key(id));
      const local = peek(id);
      const remote = cloud === undefined || cloud === null ? null : parse(cloud);
      if (remote?.ok && (local.status !== "used" || remote.record.counter > local.record.counter)) {
        storage.set(key(id), JSON.stringify(remote.record));
        replaced = true;
      } else if (local.status === "used" && (!remote?.ok || local.record.counter > remote.record.counter)) {
        upload(id, storage.get(key(id)));
      }
    } catch {
      return replaced; // offline or signed out: keep what is here
    }
  }
  return replaced;
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
