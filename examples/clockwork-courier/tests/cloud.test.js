// P3: cloud saves through `platform.cloud` on the fake store (scripts/cloud_sync.js): upload, download, a conflict that is
// joined without losing progress, a store that cannot be reached, a cloud copy that cannot be read, no backend at all,
// and the level select picking up what the cloud brought.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { platform, storage } from "factoria";
import * as progress from "../scripts/progress.js";
import * as saveData from "../scripts/save_data.js";
import * as cloudSync from "../scripts/cloud_sync.js";

const win = (id, stars, time = 40) => progress.record(id, { time, springLeft: 30, stars });
const calls = (method) => game.platform.calls().filter((c) => c.method === method);

/** A save as another device would have stored it in the cloud. */
function remoteSave(results, counter, name = "") {
  const d = saveData.empty();
  d.counter = counter;
  d.name = name;
  for (const [id, stars, time] of results) d.results[id] = { time, springLeft: 30, stars, goals: null };
  return d;
}

describe("cloud sync", () => {
  beforeEach(() => {
    game.platform.reset();
    game.setStorageText(null);
    storage.remove("progress");
  });

  test("nothing on either side: already in sync", async () => {
    expect((await cloudSync.sync()).status).toBe("synced");
    expect(calls("cloud.save").length).toBe(0);
  });

  test("a local save with no cloud copy is uploaded", async () => {
    win("rooftops_1", 2);
    game.platform.reset(); // forget the background upload that the write made
    const r = await cloudSync.sync();
    expect(r.status).toBe("uploaded");
    const remote = await platform.cloud.load("progress");
    expect(remote.results.rooftops_1.stars).toBe(2);
  });

  test("every local write also goes to the cloud in the background", async () => {
    win("rooftops_1", 2);
    expect(calls("cloud.save").length).toBe(1);
    const remote = await platform.cloud.load("progress");
    expect(remote.counter).toBe(storage.get("progress").counter);
  });

  test("a cloud copy with more progress replaces the local save", async () => {
    win("rooftops_1", 1);
    await platform.cloud.save("progress", remoteSave([["rooftops_1", 3, 38], ["rooftops_2", 2, 70]], 9, "Tablet"));
    const r = await cloudSync.sync();
    expect(r.status).toBe("downloaded");
    expect(progress.resultFor("rooftops_1").stars).toBe(3);
    expect(progress.resultFor("rooftops_2").stars).toBe(2);
    expect(progress.name()).toBe("Tablet");
  });

  test("a conflict (each side has progress the other lacks) is joined: nothing is lost on either side", async () => {
    progress.setName("Phone");
    win("rooftops_1", 3, 45);
    win("rooftops_2", 1, 80);
    await platform.cloud.save("progress", remoteSave([["rooftops_1", 2, 30], ["rooftops_3", 2, 95]], 20, "Tablet"));
    const r = await cloudSync.sync();
    expect(r.status).toBe("merged");
    for (const side of [progress.load(), await platform.cloud.load("progress")]) {
      expect(side.results.rooftops_1.stars).toBe(3); // the better result of the level
      expect(side.results.rooftops_2.stars).toBe(1); // only on this device
      expect(side.results.rooftops_3.stars).toBe(2); // only in the cloud
      expect(side.name).toBe("Tablet"); // the copy with the higher counter names the profile
    }
    expect((await cloudSync.sync()).status).toBe("synced"); // and the next sync has nothing left to do
  });

  test("a store that cannot be reached changes nothing, and the game keeps saving locally", async () => {
    win("rooftops_1", 2);
    game.platform.respond("cloud.load", { error: "network" });
    const r = await cloudSync.sync();
    expect(r.status).toBe("offline");
    expect(r.error).toBe("network");
    expect(progress.resultFor("rooftops_1").stars).toBe(2);
  });

  test("a failed background upload leaves the local save intact, and the next sync catches up", async () => {
    game.platform.respond("cloud.save", { error: "network" });
    win("rooftops_1", 2); // the upload fails; nothing throws
    await Promise.resolve();
    expect(progress.resultFor("rooftops_1").stars).toBe(2);
    expect((await cloudSync.sync()).status).toBe("uploaded");
    expect((await platform.cloud.load("progress")).results.rooftops_1.stars).toBe(2);
  });

  test("an upload that fails during a conflict merge is reported as offline, the merged local save stays", async () => {
    win("rooftops_1", 3);
    await platform.cloud.save("progress", remoteSave([["rooftops_2", 2, 70]], 4));
    game.platform.respond("cloud.save", { error: "network" });
    const r = await cloudSync.sync();
    expect(r.status).toBe("offline");
    expect(progress.resultFor("rooftops_1").stars).toBe(3);
    expect(progress.resultFor("rooftops_2").stars).toBe(2); // the merge is kept locally, the next sync uploads it
  });

  test("a cloud copy from a newer game or a damaged one is left untouched", async () => {
    win("rooftops_1", 1);
    const future = { version: 99, results: {} };
    await platform.cloud.save("progress", future);
    const r = await cloudSync.sync();
    expect(r.status).toBe("unreadable");
    expect(await platform.cloud.load("progress")).toEqual(future);
    await platform.cloud.save("progress", "garbage");
    expect((await cloudSync.sync()).status).toBe("unreadable");
    expect(progress.resultFor("rooftops_1").stars).toBe(1);
  });

  test("without a store backend there is no cloud: unavailable, and saving still works", async () => {
    game.platform.set({ backend: "none" });
    expect((await cloudSync.sync()).status).toBe("unavailable");
    expect(win("rooftops_1", 1)).toBe(true);
    game.platform.reset();
  });

  test("the level select redraws with what the cloud brought", async () => {
    progress.setName("Ana");
    win("rooftops_1", 1);
    await platform.cloud.save("progress", remoteSave([["rooftops_1", 3, 38], ["rooftops_2", 3, 60], ["rooftops_3", 3, 90]], 30, "Ana"));
    game.load("scenes/level_select.scene.json");
    game.step(5);
    expect(game.find("card_market_1").get("Button").text).not.toContain("Locked");
    expect(game.find("select_total").get("Text").text).toBe("Stars 9 / 18");
    expect(game.find("select_cloud").get("Text").text).toContain("loaded from the cloud");
  });
});
