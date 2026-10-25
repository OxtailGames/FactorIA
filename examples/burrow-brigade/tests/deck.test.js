// P5: Steam Deck: detection, the keyboard, the 1280x800 fit, suspend and resume, and the text-entry helper.
import { test, describe, expect, game } from "factoria:test";
import { i18n, world, ui } from "factoria";
import * as deck from "../scripts/game/deck.js";
import * as presence from "../scripts/game/presence.js";
import * as analytics from "../scripts/game/analytics.js";
import * as text_entry from "../scripts/game/text_entry.js";
import { freshOnline, fakeServer, shift } from "./helpers/online.js";

/** POSTs to the analytics path (the title scene also reads the news and the balance when a test starts). */
const posted = (server) => server.calls.filter((c) => c.method === "POST").length;

describe("deck", () => {
  freshOnline();

  test("isDeck is true only for a connected Steam Deck pad", () => {
    game.gamepad(0).setType("xbox");
    expect(deck.isDeck()).toBe(false);
    game.gamepad(0).setType("steamdeck");
    expect(deck.isDeck()).toBe(true);
    game.gamepad(0).setType("xbox");
  });

  test("fit: 1280x800 keeps scale 1 with bars of 40 above and below; 1280x720 has none", () => {
    expect(deck.fit(1280, 800)).toEqual({ scale: 1, offsetX: 0, offsetY: 40 });
    expect(deck.fit(1280, 720)).toEqual({ scale: 1, offsetX: 0, offsetY: 0 });
    expect(deck.fit(deck.DECK_SCREEN.width, deck.DECK_SCREEN.height).scale).toBe(1);
  });

  test("the on-screen keyboard text: pad and Deck", () => {
    game.gamepad(0).setType("steamdeck");
    const h = text_entry.hint();
    expect(h.key === "textEntry.deck" || h.kind === "keyboard" || h.kind === "touch").toBe(true);
    game.gamepad(0).setType("xbox");
  });

  test("suspend pauses, flushes analytics and sends nothing without consent; resume sends the presence again", async () => {
    const server = fakeServer({ "/v1/events": { ok: true } });
    let paused = 0;
    let resumed = 0;
    const off = deck.watchLife({ pause: () => paused++, resumed: () => resumed++ });
    presence.set({ kind: "menu" });
    await presence.idle();
    game.suspend();
    expect(paused).toBe(1);
    expect(posted(server)).toBe(0);
    game.resume();
    await presence.idle();
    expect(resumed).toBe(1);
    expect(game.platform.calls().filter((c) => c.method === "presence.set").length).toBe(2);
    off();
    server.restore();
  });

  test("suspend flushes the analytics queue when there is consent", async () => {
    analytics.setConsent(true);
    shift({ banked: 10 }); // fails offline, stays queued
    await Promise.resolve();
    await Promise.resolve();
    const server = fakeServer({ "/v1/events": { ok: true } });
    const off = deck.watchLife();
    game.suspend();
    await Promise.resolve();
    expect(posted(server)).toBe(1);
    game.resume();
    off();
    server.restore();
  });
});

describe("text_entry", () => {
  test("normalize uppercases, drops letters a person confuses (0 O 1 I) and cuts at the length", () => {
    expect(text_entry.normalize("ab-c0o1i d")).toBe("ABCD");
    expect(text_entry.normalize("abcdefghjkmn23456", { maxLength: 5 })).toBe("ABCDE");
    expect(text_entry.normalize(null)).toBe("");
    expect(i18n.language).toBe("en");
  });
});

describe("text_entry.bind", () => {
  test("typing in the field is cleaned to the code alphabet and onChange gets the clean code", () => {
    game.load("scenes/menu.scene.json");
    game.step(3);
    const field = world.spawn({ id: "code_field", components: { TextField: { text: "", placeholder: "Code", size: [300, 44] } } });
    let seen = "";
    const off = text_entry.bind("code_field", { maxLength: 6, onChange: (c) => (seen = c) });
    ui.focus("code_field");
    game.step(1);
    game.typeText("ab-0o1xyz789");
    game.step(2);
    expect(field.get("TextField").text).toBe("ABXYZ7");
    expect(seen).toBe("ABXYZ7");
    off();
  });
});
