// P5: remote balance values: applied, rejected, held during a shift, and the offline fallback.
import { test, describe, expect, game } from "factoria:test";
import fixture from "./fixtures/balance.json";
import * as balance from "../scripts/game/balance.js";
import * as events from "../scripts/game/events.js";
import { STATS } from "../scripts/game/enemy_brains.js";
import { TUNING } from "../scripts/game/hazards.js";
import { freshOnline, serveConfig } from "./helpers/online.js";

describe("balance", () => {
  freshOnline();

  test("a valid value changes STATS and the hazards", () => {
    const r = balance.apply({ "beetle.hp": 5, "hazards.drownTime": 6 });
    expect(r.rejected).toEqual([]);
    expect(STATS.beetle.hp).toBe(5);
    expect(TUNING.drownTime).toBe(6);
    expect(balance.current()["beetle.hp"]).toBe(5);
  });

  test("the fixture: valid keys apply, bad ones are rejected with a reason and a hint", () => {
    const r = balance.apply(fixture.values);
    expect(Object.keys(r.applied).sort()).toEqual(["beetle.hp", "hazards.drownTime", "hazards.waveTiles", "king.hp", "thief.stealShare"]);
    const why = Object.fromEntries(r.rejected.map((x) => [x.key, x.reason]));
    expect(why["beetle.sight"]).toBe("out of range");
    expect(why["thief.hp"]).toBe("not a whole number");
    expect(why["king.chaseSpeed"]).toBe("not a number");
    expect(why["hazards.drownTim"]).toBe("unknown key");
    expect(why["king.chargeMinDist"]).toBe("inconsistent");
    expect(why["king.chargeMaxDist"]).toBe("inconsistent");
    for (const x of r.rejected) expect(x.hint.length).toBeGreaterThan(0);
    expect(r.rejected.find((x) => x.key === "hazards.drownTim").hint).toContain("hazards.drownTime");
    // the rejected ones changed nothing
    expect(STATS.beetle.sight).toBe(balance.defaults()["beetle.sight"]);
    expect(TUNING.drownTime).toBe(6);
  });

  test("a file that is not an object is rejected whole", () => {
    expect(balance.apply([1, 2]).rejected[0].reason).toBe("not an object");
    expect(balance.apply(null).rejected[0].reason).toBe("not an object");
  });

  test("reset goes back to the shipped numbers", () => {
    const before = balance.defaults();
    balance.apply({ "beetle.hp": 5, "king.hp": 14 });
    balance.reset();
    expect(balance.current()).toEqual(before);
  });

  test("while a shift runs the values wait; the end of the shift puts them in", () => {
    const before = STATS.beetle.hp;
    events.emit("shiftStarted", { seed: 1, stratum: 0, floor: 1, hash: "x", players: 1 });
    const r = balance.apply({ "beetle.hp": 5 });
    expect(r.held).toBe(true);
    expect(STATS.beetle.hp).toBe(before);
    events.emit("shiftEnded", { outcome: "lift", banked: 0, shiftNumber: 1, stratum: 0, floor: 1 });
    expect(STATS.beetle.hp).toBe(5);
  });

  test("refresh from the server applies and reports", async () => {
    serveConfig({ balance: fixture.values });
    const r = await balance.refresh();
    expect(r.source).toBe("server");
    expect(r.applied["king.hp"]).toBe(14);
    expect(r.rejected.length).toBe(6);
  });

  test("offline: the defaults stay and the answer says so", async () => {
    serveConfig(null);
    const before = balance.current();
    const r = await balance.refresh();
    expect(r.source).toBe("offline");
    expect(balance.current()).toEqual(before);
  });

  test("a server file with no balance section, or one of another type, changes nothing", async () => {
    serveConfig({ hello: 1, balance: "fast" });
    const before = balance.current();
    const r = await balance.refresh();
    expect(r.source).toBe("server");
    expect(r.applied).toEqual({});
    expect(balance.current()).toEqual(before);
  });

  test("an offline start uses the values of the last run (the engine's cache)", async () => {
    serveConfig({ balance: { "beetle.hp": 5 } });
    await balance.refresh();
    balance.reset();
    game.remoteConfig.restart(); // the next run, offline: nothing is scripted
    const r = await balance.refresh();
    expect(r.source).toBe("cache");
    expect(STATS.beetle.hp).toBe(5);
  });

  test("every key in RANGES starts at a value inside its own range", () => {
    for (const [k, v] of Object.entries(balance.defaults())) {
      const r = balance.RANGES[k];
      expect(v >= r.min && v <= r.max).toBe(true);
    }
  });
});
