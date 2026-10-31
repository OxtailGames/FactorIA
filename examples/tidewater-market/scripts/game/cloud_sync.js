// @ts-check
// Cloud copies of the save slots through platform.cloud (Steam Cloud, iCloud, Play Games; a deterministic fake in development and tests).
// A cloud key holds { revision, meta, save } for one slot entry: tm_slot_1, tm_slot_1_auto, tm_slot_2 ... (keys allow letters, digits, _ . -).
//
// THE CONFLICT RULE (pickWinner), when the device and the cloud both hold an entry and they are not the same game:
//   1. the higher `revision` wins. The revision counts the writes of the device (save_store.js tm.rev) and a pull raises the counter to
//      the cloud's, so a device that took the cloud copy and then saved is ahead of it. The store's own `modified` time is NOT used: it
//      comes from the clock of whichever device saved (docs/PLATFORM.md, "Which save is newer").
//   2. on equal revisions (two devices saved offline the same number of times) the greater `playSeconds` wins: more play is more progress.
//   3. still equal: the device's own copy wins (nothing is lost, nothing changes).
// The loser is never thrown away: it is kept in storage under tm.conflict.<slot>[.auto] (takeConflict swaps it back in).
// The pictures of the slot screen (save_store.js, .pic) stay on the device: a cloud copy carries none, and an entry that is replaced
// loses its picture, so the slot screen shows the map of the meta then.
import { platform, storage } from "factoria";
import { SLOTS, metaKey, dataKey, pictureKey, conflictKey, readMeta, isMeta, nextRevision, raiseRevision } from "./save_store.js";
import { readSave } from "./savegame.js";

export const cloudKey = (slot, kind) => `tm_slot_${slot}${kind === "auto" ? "_auto" : ""}`;

/**
 * Which of two copies of an entry wins. Each is { revision, playSeconds, hash }.
 * @returns {"local" | "remote" | "same"}
 */
export function pickWinner(local, remote) {
  if (local.hash && local.hash === remote.hash) return "same";
  if (local.revision !== remote.revision) return local.revision > remote.revision ? "local" : "remote";
  if (local.playSeconds !== remote.playSeconds) return local.playSeconds > remote.playSeconds ? "local" : "remote";
  return "local";
}

/** A cloud value that is an entry we can use, or null (anything else is ignored, never trusted). */
function usable(value) {
  if (!value || typeof value !== "object" || !Number.isInteger(value.revision) || !isMeta(value.meta)) return null;
  const read = readSave(value.save);
  return read.ok ? { revision: value.revision, meta: value.meta, save: value.save } : null;
}

function localEntry(slot, kind) {
  const meta = readMeta(slot, kind);
  const save = storage.get(dataKey(slot, kind), null);
  if (!meta || save == null) return null;
  return { revision: meta.revision, meta, save };
}

/** Is there an entry to sync? Cloud saves need a store that offers them (the fake does, an exported game without a plugin does not). */
export function cloudAvailable() {
  return platform.has("cloudSave");
}

/**
 * Bring this device and the cloud into line, entry by entry. Never throws; the answer says what happened.
 * Only storage is touched, so an answer that arrives after the scene changed does no harm, but a caller that shows the result checks
 * its scene is still the current one (pass `isCurrent`, and the sync stops between two cloud calls when it answers false).
 * @param {{ isCurrent?: () => boolean }} [options]
 * @returns {Promise<{ ok: true, pushed: string[], pulled: string[], conflicts: string[], skipped: string[], unavailable?: boolean, stopped?: boolean } | { ok: false, error: { code: string, message: string, hint: string } }>}
 */
export async function syncCloud(options = {}) {
  const result = { ok: /** @type {const} */ (true), pushed: [], pulled: [], conflicts: [], skipped: [] };
  if (!cloudAvailable()) return { ...result, unavailable: true };
  const current = options.isCurrent || (() => true);
  try {
    for (let slot = 1; slot <= SLOTS; slot++) {
      for (const kind of /** @type {const} */ (["manual", "auto"])) {
        if (!current()) return { ...result, stopped: true };
        const key = cloudKey(slot, kind);
        const raw = await platform.cloud.load(key);
        if (!current()) return { ...result, stopped: true };
        const remote = raw === undefined ? null : usable(raw);
        if (raw !== undefined && !remote) result.skipped.push(key); // damaged in the cloud: the device's copy (if any) replaces it below
        const local = localEntry(slot, kind);
        if (!local && !remote) continue;
        if (local && !remote) {
          await pushEntry(slot, kind, local);
          result.pushed.push(key);
          continue;
        }
        if (remote && !local) {
          pullEntry(slot, kind, remote);
          result.pulled.push(key);
          continue;
        }
        const win = pickWinner({ revision: local.revision, playSeconds: local.meta.playSeconds, hash: local.meta.hash }, { revision: remote.revision, playSeconds: remote.meta.playSeconds, hash: remote.meta.hash });
        if (win === "same") continue;
        result.conflicts.push(key);
        if (win === "remote") {
          storage.set(conflictKey(slot, kind), { from: "device", meta: local.meta, save: local.save });
          pullEntry(slot, kind, remote);
          result.pulled.push(key);
        } else {
          storage.set(conflictKey(slot, kind), { from: "cloud", meta: remote.meta, save: remote.save });
          await pushEntry(slot, kind, local);
          result.pushed.push(key);
        }
      }
    }
    return result;
  } catch (e) {
    const code = (e && e.code) || "failed";
    return { ok: false, error: { code, message: `the cloud saves could not be synced (${e && e.message})`, hint: (e && e.hint) || "the saves on this device are fine; try again later" } };
  }
}

/** Push one entry to the cloud. Rejects like platform.cloud.save does. */
export async function pushEntry(slot, kind, entry = localEntry(slot, kind)) {
  if (!entry) return false;
  await platform.cloud.save(cloudKey(slot, kind), { revision: entry.revision, meta: entry.meta, save: entry.save });
  return true;
}

/** Push an entry after it was written, when the platform has cloud saves. Never throws and never waits: the device's copy is what counts. */
export function pushQuietly(slot, kind) {
  if (!cloudAvailable()) return;
  pushEntry(slot, kind).catch(() => {});
}

/** Remove the cloud copies of a slot (the player deleted it: a later sync must not bring it back from the cloud). Never throws. */
export function removeQuietly(slot) {
  if (!cloudAvailable()) return;
  for (const kind of /** @type {const} */ (["manual", "auto"])) platform.cloud.remove(cloudKey(slot, kind)).catch(() => {});
}

function pullEntry(slot, kind, remote) {
  storage.remove(pictureKey(slot, kind)); // the cloud copy carries no picture, and the old one is of another game
  storage.set(dataKey(slot, kind), remote.save);
  storage.set(metaKey(slot, kind), { ...remote.meta, slot, kind, revision: remote.revision });
  raiseRevision(remote.revision);
}

/** The backups of lost conflicts: [{ slot, kind, from, meta }]. */
export function listConflicts() {
  const out = [];
  for (let slot = 1; slot <= SLOTS; slot++) {
    for (const kind of /** @type {const} */ (["manual", "auto"])) {
      const c = storage.get(conflictKey(slot, kind), null);
      if (c && isMeta(c.meta)) out.push({ slot, kind, from: c.from, meta: c.meta });
    }
  }
  return out;
}

/** Put a backed-up copy back as the entry (the entry it replaces becomes the backup), with a new revision so it wins from now on. */
export function takeConflict(slot, kind = "manual") {
  const c = storage.get(conflictKey(slot, kind), null);
  if (!c || !isMeta(c.meta)) return false;
  const current = localEntry(slot, kind);
  storage.remove(pictureKey(slot, kind)); // the backup keeps no picture, and the old one is of the game that becomes the backup
  storage.set(dataKey(slot, kind), c.save);
  storage.set(metaKey(slot, kind), { ...c.meta, slot, kind, revision: nextRevision() });
  if (current) storage.set(conflictKey(slot, kind), { from: "device", meta: current.meta, save: current.save });
  else storage.remove(conflictKey(slot, kind));
  return true;
}
