// @ts-check
// Cloud copy of the save, through the platform API (`platform.cloud`, docs/PLATFORM.md). The local save is always
// written first and never waits for the store; the cloud is best effort and every failure leaves both copies alone.
//
//   push(data)   after a local write: uploads the save in the background (a failed upload is retried by the next sync)
//   sync()       compares this device's save with the cloud copy and settles it, returns { status, ... }:
//                  "unavailable"  the backend has no cloud saves (`platform.has("cloudSave")` is false)
//                  "offline"      the store could not be reached (`error` = the engine's error code); nothing changed
//                  "unreadable"   the cloud copy is damaged or from a newer game; it is left untouched (`reason`)
//                  "synced"       both copies hold the same progress
//                  "uploaded"     this device had more (or the cloud had nothing): the cloud copy was replaced
//                  "downloaded"   the cloud had more: the local save was replaced
//                  "merged"       each side had progress the other lacked (a conflict): the two were joined, see
//                                 save_data.merge (best result per level, best daily time per day, the name of the newer copy)
//                                 and the joined save was stored on both sides. No question is asked: nothing is ever lost.
//
// Where it runs: scripts/level_select.js calls sync() when the screen opens, progress.js calls push() on every write.
import { storage, platform, session } from "factoria";
import * as saveData from "./save_data.js";

const KEY = saveData.KEY;

/** The cloud key of the save (same as the local one: keys take A-Z a-z 0-9 _ . - up to 64 characters). */
export const CLOUD_KEY = KEY;

/** Best-effort upload of a save. Returns nothing; failures are only remembered in session.cloudStatus. */
export function push(data) {
  if (!platform.has("cloudSave")) return;
  platform.cloud.save(CLOUD_KEY, data).catch((e) => {
    session.cloudStatus = { status: "offline", error: e?.code ?? "failed" };
  });
}

/** @returns {Promise<{ status: string, error?: string, reason?: string, from?: string }>} */
export async function sync() {
  const result = await run();
  session.cloudStatus = result;
  return result;
}

async function run() {
  if (!platform.has("cloudSave")) return { status: "unavailable" };
  const parsedLocal = saveData.parse(storage.get(KEY, null));
  const local = parsedLocal.ok ? parsedLocal.data : saveData.empty();
  let remoteRaw;
  try {
    remoteRaw = await platform.cloud.load(CLOUD_KEY);
  } catch (e) {
    return { status: "offline", error: e?.code ?? "failed" };
  }
  if (remoteRaw === undefined || remoteRaw === null) {
    if (saveData.content(local) === saveData.content(saveData.empty())) return { status: "synced", from: "same" };
    return upload(local, "uploaded");
  }
  const parsedRemote = saveData.parse(remoteRaw);
  if (!parsedRemote.ok) return { status: "unreadable", reason: parsedRemote.reason };
  const { data, from } = saveData.merge(local, parsedRemote.data);
  if (from === "same") return { status: "synced", from };
  if (from === "a") return upload(local, "uploaded");
  if (from === "b") {
    storage.set(KEY, data);
    return { status: "downloaded", from };
  }
  storage.set(KEY, data);
  const up = await upload(data, "merged");
  return up.status === "merged" ? { status: "merged", from } : { ...up, from };
}

async function upload(data, status) {
  try {
    await platform.cloud.save(CLOUD_KEY, data);
    return { status };
  } catch (e) {
    return { status: "offline", error: e?.code ?? "failed" };
  }
}
