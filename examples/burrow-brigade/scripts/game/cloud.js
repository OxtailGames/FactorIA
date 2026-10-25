// @ts-check
// Cloud saves: each slot is kept in the store's cloud (`platform.cloud`, the fake store in development and tests, Steam Cloud in a
// shipped game) under the key of its local slot ("burrow.slot.1".."3"), and a conflict between the two copies is settled by a rule.
//
// THE RULE (what `syncSlot` does)
//   Every save counts its writes in `revision`. A device remembers the revision it last synced (`burrow.cloudBase.<n>`).
//   - Only one side changed since the last sync -> the changed side wins and overwrites the other (upload or download).
//   - Both changed (two devices played, or this device never synced) -> a CONFLICT: the copy with MORE PLAY TIME wins (then the
//     deeper `bestDepth`, then the higher revision, then the cloud's). The losing copy is not thrown away: it is kept as a backup
//     ("burrow.backup.<n>" in the local storage when the cloud won, in the cloud under the same key when the local copy won).
//   - A cloud copy written by a NEWER format, or a local slot that cannot be read, is never touched; the answer says why.
//   - The same progress on both sides is "inSync": nothing is written.
//   - While a run is being played (the camp) only uploads happen (`allowDownload: false`): a download or a conflict that the cloud
//     would win waits for the slot screen, so the cloud never replaces a run that is in progress.
// Nothing here throws: every answer is a plain object with an `action`.
import { platform, storage } from "factoria";
import * as saves from "./save.js";

/** The key of a slot in the cloud (the same as its local key: letters, digits and dots are allowed). */
export function cloudKey(n) {
  return saves.slotKey(n);
}
const baseKey = (n) => `burrow.cloudBase.${n}`;
/** Where the losing copy of a conflict is kept. */
export function backupKey(n) {
  return `burrow.backup.${n}`;
}

/** True when the platform offers cloud saves (the fake store and Steam do; a build with no store plugin does not). */
export function available() {
  return platform.has("cloudSave");
}

function sameProgress(a, b) {
  return a.seed === b.seed && a.stratum === b.stratum && a.floor === b.floor && a.shiftNumber === b.shiftNumber && a.cash === b.cash
    && a.playTime === b.playTime && JSON.stringify(a.upgrades) === JSON.stringify(b.upgrades);
}

/** True when `a` is further along than `b`: more play time, then deeper, then more writes. */
function ahead(a, b) {
  if (a.playTime !== b.playTime) return a.playTime > b.playTime;
  if (a.bestDepth !== b.bestDepth) return a.bestDepth > b.bestDepth;
  return a.revision > b.revision;
}

/**
 * Settles one slot with the cloud.
 * @param {number} n  1 to 3.
 * @param {{allowDownload?: boolean}} [opts]  false while a run is being played: only uploads.
 * @returns {Promise<{slot: number, action: "unavailable"|"none"|"inSync"|"uploaded"|"downloaded"|"conflict"|"waiting"|"blocked"|"error", winner?: "local"|"cloud", message?: string, hint?: string}>}
 */
export async function syncSlot(n, opts = {}) {
  const allowDownload = opts.allowDownload !== false;
  if (!available()) return { slot: n, action: "unavailable", message: "this build has no cloud saves", hint: "the store plugin (Steam) provides them" };
  try {
    const key = cloudKey(n);
    const raw = await platform.cloud.load(key);
    const local = saves.readSlot(n); // read AFTER the wait: the slot may have been played or deleted while the cloud answered
    const remote = raw === undefined || raw === null ? null : saves.migrate(raw, n);
    if (local.status === "error") return { slot: n, action: "blocked", message: local.message, hint: `${local.hint}; the cloud copy is left alone` };
    if (remote && !remote.ok && remote.kind === "newer") return { slot: n, action: "blocked", message: `the cloud copy of slot ${n} ${remote.message}`, hint: remote.hint };
    const base = Number(storage.get(baseKey(n), 0)) || 0;
    const upload = async (data) => {
      await platform.cloud.save(key, data);
      storage.set(baseKey(n), data.revision);
    };
    const download = (data) => {
      storage.set(saves.slotKey(n), data);
      storage.set(baseKey(n), data.revision);
    };

    if (remote && !remote.ok) {
      // a damaged cloud copy: keep it as the backup and replace it with the local one, if there is one
      if (local.status !== "ok") return { slot: n, action: "none" };
      await platform.cloud.save(backupKey(n), raw);
      await upload(local.data);
      return { slot: n, action: "uploaded", message: `the cloud copy of slot ${n} was damaged (${remote.message}) and was kept as ${backupKey(n)}` };
    }
    if (local.status === "empty" && !remote) return { slot: n, action: "none" };
    if (local.status === "empty" && remote) {
      if (!allowDownload) return { slot: n, action: "waiting" };
      download(remote.data);
      return { slot: n, action: "downloaded" };
    }
    if (local.status === "ok" && !remote) {
      await upload(local.data);
      return { slot: n, action: "uploaded" };
    }
    // both exist and can be read
    const l = /** @type {any} */ (local).data;
    const r = /** @type {any} */ (remote).data;
    if (sameProgress(l, r)) {
      storage.set(baseKey(n), Math.max(l.revision, r.revision));
      return { slot: n, action: "inSync" };
    }
    const localChanged = l.revision > base;
    const remoteChanged = r.revision > base;
    if (localChanged && !remoteChanged) {
      await upload(l);
      return { slot: n, action: "uploaded" };
    }
    if (remoteChanged && !localChanged) {
      if (!allowDownload) return { slot: n, action: "waiting" };
      download(r);
      return { slot: n, action: "downloaded" };
    }
    // a conflict
    const winner = ahead(l, r) ? "local" : "cloud";
    if (winner === "cloud" && !allowDownload) return { slot: n, action: "waiting", winner };
    if (winner === "local") {
      await platform.cloud.save(backupKey(n), r);
      await upload(l);
    } else {
      storage.set(backupKey(n), l);
      download(r);
    }
    return { slot: n, action: "conflict", winner };
  } catch (e) {
    const err = /** @type {any} */ (e);
    return { slot: n, action: "error", message: `cloud save of slot ${n} failed: ${err?.message ?? err}`, hint: err?.hint ?? "play on: the local save is safe, and the next sync tries again" };
  }
}

/** Settles every slot, one after the other. */
export async function syncAll(opts = {}) {
  const out = [];
  for (let n = 1; n <= saves.SLOT_COUNT; n++) out.push(await syncSlot(n, opts));
  return out;
}

/** Deletes the cloud copy of a slot (the slot screen does it with the local one, or the file would come back at the next sync). */
export async function removeSlot(n) {
  storage.remove(baseKey(n));
  if (!available()) return { slot: n, action: "unavailable" };
  try {
    await platform.cloud.remove(cloudKey(n));
    return { slot: n, action: "removed" };
  } catch (e) {
    const err = /** @type {any} */ (e);
    return { slot: n, action: "error", message: `could not delete the cloud copy of slot ${n}: ${err?.message ?? err}`, hint: err?.hint ?? "it will come back at the next sync: delete the slot again when online" };
  }
}
