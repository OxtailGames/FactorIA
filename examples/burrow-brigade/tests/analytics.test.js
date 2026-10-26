// P5: opt-in analytics on the engine's `analytics` service. Nothing leaves the game without consent.
import { test, describe, expect, game } from "factoria:test";
import { analytics as engine } from "factoria";
import * as analytics from "../scripts/game/analytics.js";
import { freshOnline, serveEvents, posts, shift, EVENTS_URL } from "./helpers/online.js";

describe("analytics", () => {
  freshOnline();

  test("off by default and not asked yet", () => {
    expect(analytics.consent()).toBe("unknown");
    expect(analytics.asked()).toBe(false);
    expect(analytics.enabled()).toBe(false);
  });

  test("without consent a whole shift and a quit send nothing, and queue nothing", async () => {
    serveEvents();
    shift({ banked: 100 });
    shift({ banked: 50, outcome: "dark" });
    analytics.recordQuit();
    await analytics.flush();
    game.step(5);
    expect(posts().length).toBe(0);
    expect(game.analytics.queued()).toEqual([]);
  });

  test("after saying no, still nothing", async () => {
    analytics.setConsent(false);
    expect(analytics.asked()).toBe(true);
    serveEvents();
    shift({ banked: 100 });
    analytics.recordQuit();
    game.step(5);
    expect(posts().length).toBe(0);
    expect(game.analytics.queued()).toEqual([]);
  });

  test("with consent the shift events are sent when a shift ends", () => {
    analytics.setConsent(true);
    serveEvents();
    shift({ stratum: 1, floor: 2, players: 2, banked: 90 });
    game.step(3);
    expect(posts().length).toBe(1);
    expect(posts()[0]).toMatchObject({ method: "POST", url: EVENTS_URL });
    const sent = game.analytics.sent();
    expect(sent.map((e) => e.name)).toEqual(["floor_reached", "shift_ended"]);
    expect(sent[0].props).toEqual({ stratum: 1, floor: 2, players: 2 });
    expect(sent[1].props).toMatchObject({ outcome: "lift", stratum: 1, floor: 2, players: 2, banked: 90 });
  });

  test("nothing in an event identifies the player", () => {
    analytics.setConsent(true);
    serveEvents();
    shift({ banked: 90 });
    game.step(3);
    const text = JSON.stringify(posts()[0].body.events.map((e) => e.props));
    for (const word of ["name", "id\"", "seed", "steam", "device", "email"]) expect(text.includes(word)).toBe(false);
    expect(Object.keys(posts()[0].body).sort()).toEqual(["events", "game", "sentOn", "version"]);
  });

  test("the quit sends the quit event with consent: the engine flushes when the window closes", () => {
    analytics.setConsent(true);
    serveEvents();
    analytics.recordQuit();
    expect(game.analytics.queued().map((e) => e.name)).toEqual(["quit"]);
    game.closeWindow();
    expect(game.analytics.sent().map((e) => e.name)).toEqual(["quit"]);
    expect(game.analytics.sent()[0].props).toEqual({ shifts: 0 });
  });

  test("a failed send keeps the events for a retry; revoking consent throws them away", () => {
    analytics.setConsent(true);
    shift({ banked: 90 }); // nobody answers: like an offline player
    game.step(3);
    expect(game.analytics.queued().length).toBe(2);
    analytics.setConsent(false);
    expect(game.analytics.queued()).toEqual([]);
    serveEvents();
    game.step(60 * 40);
    expect(posts().filter((p) => p.body.events.length > 0).length).toBe(1); // only the failed first try
    expect(game.analytics.sent()).toEqual([]);
  });

  test("the queue is capped by the engine", () => {
    analytics.setConsent(true);
    for (let i = 0; i < engine.limits.queue + 20; i++) shift({ banked: 1 });
    expect(game.analytics.queued().length).toBeLessThanOrEqual(engine.limits.queue);
  });
});
