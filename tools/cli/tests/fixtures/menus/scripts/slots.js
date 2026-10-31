// @ts-check
// Save slots: named slots and an autosave in `storage`, each a string of JSON text and, when the player is signed in to a store,
// a copy in the cloud under the same key. A slot holds a RECORD:
//
//   { "counter": 7, "name": "Before the cellar", "chapter": 3, "playTime": 3725.5, "pic": "<base64 PNG>" | null, "data": <the game's save> }
//
// `data` is whatever the game saves (any JSON); the rest is what the slot screen (scripts/ui/slot_screen.js) shows without opening
// the slot. `counter` goes up by one on every save (the wall clock is never read): when a cloud copy and a local one differ, the
// higher counter wins (syncCloud). A text that is not a record (no "data" field) is read as a bare save: a record without a
// name, picture or counter, so a game can start with plain saves and move to slots later.
//
//   const slots = new Slots({ upgrade: (data) => ({ ok: true, data }), describe: (data) => ({ chapter: data.chapter, playTime: data.playTime }) });
//   slots.write(1, { name: "Before the cellar", data: mySave, chapter: 3, playTime: 3725.5, pic: capturePic() });
//   const p = slots.peek(1);                  // { status: "used", record } | { status: "empty" } | { status: "damaged", reason, hint }
//   if (p.status === "used") load(p.record.data);
//   await slots.syncCloud();                  // when the slot screen opens, and again when the game starts
//
// The game decides WHEN it may save (a cut-scene or a loading screen may not) and what is in `data`; this file never looks inside it
// except through `upgrade` (migrates an older save when it is read) and `describe` (chapter and play time of a bare save).
import { storage, platform, render } from "factoria";

/** Size of the picture kept with a slot (16:9, a few KB as PNG). */
export const PIC = Object.freeze({ width: 192, height: 108 });

/** "h:mm:ss" for a number of seconds. */
export function formatTime(seconds) {
  const s = Math.max(0, Math.floor(Number(seconds) || 0));
  const pad = (n) => String(n).padStart(2, "0");
  return `${Math.floor(s / 3600)}:${pad(Math.floor(s / 60) % 60)}:${pad(s % 60)}`;
}

/**
 * A picture of the game as the player sees it (render.captureTexture), as base64 PNG, or null when nothing real can be drawn (a
 * headless run has no graphics). Take it before a menu covers the game.
 * @param {{ width: number, height: number }} [size]
 */
export function capturePic(size = PIC) {
  try {
    const tex = render.captureTexture({ width: size.width, height: size.height });
    const png = tex.placeholder ? null : tex.toPNG();
    tex.destroy();
    return png;
  } catch (e) {
    console.warn(`slots: no picture for the slot: ${e.message}`);
    return null;
  }
}

/**
 * @typedef {{ counter: number, name: string, chapter: number, playTime: number, pic: string | null, data: any }} SlotRecord
 * @typedef {{ ok: true, data: any } | { ok: false, message: string, hint?: string }} Upgraded
 */

export class Slots {
  /**
   * @param {object} [options]
   * @param {Array<number | string>} [options.ids] the manual slots, default 1 to 5. The slot screen's prefab has a row for each of 1..5 and "auto".
   * @param {string | null} [options.auto] id of the autosave slot ("auto"); null = no autosave
   * @param {string} [options.keyPrefix] storage (and cloud) key of slot N is `${keyPrefix}${N}`, "slot1"; the autosave is `${keyPrefix}_${auto}`
   * @param {string} [options.counterKey] storage key of the highest counter handed out
   * @param {string} [options.lastKey] storage key of the id of the slot saved last (for a "Continue" button)
   * @param {(data: any) => Upgraded} [options.upgrade] migrates the data of a slot to the newest layout when it is read; a not-ok result makes the slot "damaged" with that message
   * @param {(data: any) => { chapter?: number, playTime?: number }} [options.describe] chapter and play time of a bare save (a record's own fields win)
   */
  constructor(options = {}) {
    this.SLOTS = Object.freeze([...(options.ids ?? [1, 2, 3, 4, 5])]);
    this.AUTO = options.auto === undefined ? "auto" : options.auto;
    /** Every slot the screen shows, the autosave first. */
    this.ALL = Object.freeze(this.AUTO === null ? [...this.SLOTS] : [this.AUTO, ...this.SLOTS]);
    this.keyPrefix = options.keyPrefix ?? "slot";
    this.counterKey = options.counterKey ?? "saveCounter";
    this.lastKey = options.lastKey ?? "lastSlot";
    this.upgrade = options.upgrade ?? ((data) => ({ ok: true, data }));
    this.describe = options.describe ?? (() => ({}));
  }

  /** The storage key (and cloud key) of a slot id. */
  key(id) {
    return id === this.AUTO ? `${this.keyPrefix}_${id}` : `${this.keyPrefix}${id}`;
  }

  /**
   * Reads the text of a slot (or a cloud copy). `{ ok: true, record }` with the data in the newest layout, or `{ ok: false, reason, hint }`
   * for text that is not JSON, not an object, or refused by `upgrade`. Never throws.
   * @param {any} text
   * @returns {{ ok: true, record: SlotRecord } | { ok: false, reason: string, hint: string }}
   */
  parse(text) {
    let raw;
    try {
      raw = typeof text === "string" ? JSON.parse(text) : text;
    } catch (e) {
      return { ok: false, reason: `not valid JSON (${e.message})`, hint: "Delete the slot." };
    }
    if (!raw || typeof raw !== "object" || Array.isArray(raw)) return { ok: false, reason: "not a JSON object", hint: "Delete the slot." };
    const bare = !Object.hasOwn(raw, "data");
    let up;
    try {
      up = this.upgrade(bare ? raw : raw.data);
    } catch (e) {
      up = { ok: false, message: `the save could not be read (${e.message})` };
    }
    if (!up.ok) return { ok: false, reason: up.message, hint: up.hint ?? "Delete the slot." };
    const info = this.describe(up.data) ?? {};
    const number = (v) => (typeof v === "number" && Number.isFinite(v) ? v : undefined);
    return {
      ok: true,
      record: {
        counter: !bare && Number.isInteger(raw.counter) && raw.counter >= 0 ? raw.counter : 0,
        name: !bare && typeof raw.name === "string" ? raw.name : "",
        chapter: (bare ? undefined : number(raw.chapter)) || number(info.chapter) || 0,
        playTime: (bare ? undefined : number(raw.playTime)) ?? number(info.playTime) ?? 0,
        pic: !bare && typeof raw.pic === "string" && raw.pic !== "" ? raw.pic : null,
        data: up.data,
      },
    };
  }

  /** What the slot screen shows: `{ status: "empty" | "used" | "damaged", reason?, hint?, record? }`. */
  peek(id) {
    const text = storage.get(this.key(id), null);
    if (text === null) return { status: "empty" };
    const r = this.parse(text);
    if (!r.ok) return { status: "damaged", reason: r.reason, hint: r.hint };
    return { status: "used", record: r.record };
  }

  /** The id of the slot that was saved last, if it still exists, else null. */
  last() {
    const id = storage.get(this.lastKey, null);
    return id !== null && this.ALL.includes(id) && this.peek(id).status === "used" ? id : null;
  }

  nextCounter() {
    let top = storage.get(this.counterKey, 0);
    for (const id of this.ALL) {
      const p = this.peek(id);
      if (p.status === "used") top = Math.max(top, p.record.counter);
    }
    storage.set(this.counterKey, top + 1);
    return top + 1;
  }

  /**
   * Saves into slot `id`: the record gets the next counter, is written to storage and uploaded to the cloud when the player is signed in
   * (a failed upload never matters: the local save stands). `name` is trimmed; empty stays empty (the screen shows "Unnamed").
   * Returns the record.
   * @param {number | string} id
   * @param {{ data: any, name?: string, chapter?: number, playTime?: number, pic?: string | null }} save
   * @returns {SlotRecord}
   */
  write(id, { data, name = "", chapter = 0, playTime = 0, pic = null }) {
    const record = { counter: this.nextCounter(), name: String(name).trim(), chapter, playTime, pic, data };
    const text = JSON.stringify(record);
    storage.set(this.key(id), text);
    storage.set(this.lastKey, id);
    this.upload(id, text);
    return record;
  }

  /** Empties slot `id` here and in the cloud (otherwise the next sync would bring it back). */
  remove(id) {
    storage.remove(this.key(id));
    if (storage.get(this.lastKey, null) === id) storage.remove(this.lastKey);
    if (platform.has("cloudSave")) platform.cloud.remove(this.key(id)).catch(() => {}); // a failed delete can come back at the next sync
  }

  upload(id, text) {
    if (platform.has("cloudSave")) platform.cloud.save(this.key(id), text).catch(() => {}); // the local save stands whatever the store says
  }

  /**
   * Compares every slot with its cloud copy: the one with the higher counter wins (a cloud copy replaces the local slot, a better
   * local one is uploaded). A store that is down or a player who is not signed in changes nothing. Resolves with true when a local
   * slot was replaced. The caller checks that its scene is still the current one before it draws the result.
   */
  async syncCloud() {
    if (!platform.has("cloudSave")) return false;
    let replaced = false;
    for (const id of this.ALL) {
      try {
        const cloud = await platform.cloud.load(this.key(id));
        const local = this.peek(id);
        const remote = cloud === undefined || cloud === null ? null : this.parse(cloud);
        if (remote?.ok && (local.status !== "used" || remote.record.counter > local.record.counter)) {
          storage.set(this.key(id), JSON.stringify(remote.record));
          replaced = true;
        } else if (local.status === "used" && (!remote?.ok || local.record.counter > remote.record.counter)) {
          this.upload(id, storage.get(this.key(id)));
        }
      } catch {
        return replaced; // offline or signed out: keep what is here
      }
    }
    return replaced;
  }
}
