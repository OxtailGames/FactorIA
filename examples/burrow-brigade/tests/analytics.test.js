// P5: opt-in analytics. Nothing leaves the game without consent.
import { test, describe, expect } from "factoria:test";
import * as analytics from "../scripts/game/analytics.js";
import { freshOnline, fakeServer, shift } from "./helpers/online.js";

describe("analytics", () => {
  freshOnline();

  test("off by default and not asked yet", () => {
    expect(analytics.consent()).toBe("unknown");
    expect(analytics.asked()).toBe(false);
    expect(analytics.enabled()).toBe(false);
  });

  test("without consent a whole shift and a quit send nothing, and queue nothing", async () => {
    const server = fakeServer({ "/v1/events": { ok: true } });
    shift({ banked: 100 });
    shift({ banked: 50, outcome: "dark" });
    await analytics.quit();
    await analytics.flush();
    expect(server.calls.length).toBe(0);
    expect(analytics.queued()).toEqual([]);
    server.restore();
  });

  test("after saying no, still nothing", async () => {
    analytics.setConsent(false);
    expect(analytics.asked()).toBe(true);
    const server = fakeServer({ "/v1/events": { ok: true } });
    shift({ banked: 100 });
    await analytics.quit();
    expect(server.calls.length).toBe(0);
    server.restore();
  });

  test("with consent the shift events are sent when a shift ends", async () => {
    analytics.setConsent(true);
    const server = fakeServer({ "/v1/events": { ok: true } });
    shift({ stratum: 1, floor: 2, players: 2, banked: 90 });
    await Promise.resolve();
    await Promise.resolve();
    expect(server.calls.length).toBe(1);
    const call = server.calls[0];
    expect(call).toMatchObject({ method: "POST", path: "/v1/events" });
    expect(call.body.events.map((e) => e.name)).toEqual(["floor_reached", "shift_ended"]);
    expect(call.body.events[0].data).toEqual({ stratum: 1, floor: 2, players: 2 });
    expect(call.body.events[1].data).toMatchObject({ outcome: "lift", stratum: 1, floor: 2, players: 2, banked: 90 });
    server.restore();
  });

  test("nothing in an event identifies the player", async () => {
    analytics.setConsent(true);
    const server = fakeServer({ "/v1/events": { ok: true } });
    shift({ banked: 90 });
    await Promise.resolve();
    const text = JSON.stringify(server.calls[0].body);
    for (const word of ["name", "id\"", "seed", "steam", "device", "email"]) {
      if (word === "name") continue; // the event names are "name" keys by design
      expect(text.includes(word)).toBe(false);
    }
    server.restore();
  });

  test("quit sends a quit event with consent", async () => {
    analytics.setConsent(true);
    const server = fakeServer({ "/v1/events": { ok: true } });
    const r = await analytics.quit();
    expect(r.sent).toBe(1);
    expect(server.calls[0].body.events[0].name).toBe("quit");
    server.restore();
  });

  test("a failed send keeps the events for the next flush; revoking consent throws them away", async () => {
    analytics.setConsent(true);
    shift({ banked: 90 }); // offline transport: the send fails
    await Promise.resolve();
    await Promise.resolve();
    expect(analytics.queued().length).toBe(2);
    analytics.setConsent(false);
    expect(analytics.queued()).toEqual([]);
    const server = fakeServer({ "/v1/events": { ok: true } });
    expect((await analytics.flush()).sent).toBe(0);
    expect(server.calls.length).toBe(0);
    server.restore();
  });

  test("the queue is capped", () => {
    analytics.setConsent(true);
    for (let i = 0; i < analytics.MAX_QUEUE + 20; i++) shift({ banked: 1 });
    expect(analytics.queued().length).toBeLessThanOrEqual(analytics.MAX_QUEUE);
  });
});
