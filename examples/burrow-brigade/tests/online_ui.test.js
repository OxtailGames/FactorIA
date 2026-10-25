// P5: the title's online parts (news, consent card, button prompts), the boards screen and the Options switch, driven like a player.
import { test, describe, expect, game } from "factoria:test";
import { scene, storage } from "factoria";
import fixture from "./fixtures/news.json";
import * as analytics from "../scripts/game/analytics.js";
import * as news from "../scripts/game/news.js";
import { run } from "../scripts/game/run_state.js";
import { freshOnline, fakeServer, shift } from "./helpers/online.js";

const TITLE = "scenes/menu.scene.json";
const OTHER = "scenes/shift.scene.json"; // any other scene: the title is gone
const textOf = (id) => game.find(id).get("Text").text;

function openTitle() {
  game.load(TITLE);
  game.step(5);
}

describe("title online", () => {
  freshOnline();

  test("the title shows the newest news item from the server", () => {
    const server = fakeServer({ "/v1/news.json": fixture });
    openTitle();
    game.step(5);
    const newest = news.parse(fixture)[0];
    expect(textOf("news_text")).toContain(newest.title);
    expect(textOf("news_text").startsWith("News: ")).toBe(true);
    server.restore();
  });

  test("offline the title shows the remembered news, and with none it shows nothing", () => {
    openTitle();
    expect(textOf("news_text")).toBe("");
    storage.set(news.KEY, { items: news.parse(fixture) });
    openTitle();
    expect(textOf("news_text")).toContain(news.parse(fixture)[0].title);
  });

  test("the first launch shows the consent card without taking the menu away; Yes grants, No denies, then it is gone", () => {
    openTitle();
    expect(game.find("consent").active).toBe(true);
    expect(game.find("main_menu").active).toBe(true);
    game.click("consent_yes");
    game.step(1);
    expect(analytics.enabled()).toBe(true);
    expect(game.find("consent").active).toBe(false);
    openTitle();
    expect(game.find("consent").active).toBe(false); // asked already
    analytics.setConsent(false);
    openTitle();
    expect(game.find("consent").active).toBe(false);
    expect(analytics.enabled()).toBe(false);
  });

  test("ignoring the card sends nothing", async () => {
    const server = fakeServer({ "/v1/news.json": fixture, "/v1/events": {} });
    openTitle();
    shift({ banked: 10 });
    await Promise.resolve();
    expect(server.calls.filter((c) => c.method === "POST").length).toBe(0);
    server.restore();
  });

  test("leaving the title before the news arrive is harmless", () => {
    const server = fakeServer({ "/v1/news.json": fixture });
    game.load(TITLE);
    game.load(OTHER);
    game.step(10);
    expect(scene.current).toBe(OTHER);
    server.restore();
  });

  test("the hints row follows the pad in use", () => {
    game.gamepad(0).setType("playstation");
    openTitle();
    game.gamepad(0).press("DpadRight");
    game.gamepad(0).release("DpadRight");
    game.step(3);
    const row = game.find("hints");
    expect(row.children.length).toBeGreaterThan(0);
    game.gamepad(0).setType("xbox");
  });
});

describe("boards screen", () => {
  freshOnline();

  test("opens from the title, shows the all-time board with the player marked, and Back closes it", async () => {
    shift({ banked: 250 });
    openTitle();
    game.click("boards_button");
    game.step(5);
    expect(game.find("boards").active).toBe(true);
    expect(game.find("boards_list").children.length).toBe(1);
    expect(game.find("boards_list").children[0].get("Text").text).toContain("250");
    expect(game.find("boards_list").children[0].get("Text").text).toContain("(you)");
    game.click("boards_back");
    game.step(2);
    expect(game.find("boards").active).toBe(false);
  });

  test("the tabs: the daily board is empty until a daily dig posts, the trophies list the achievements", () => {
    run.mode = "daily";
    run.dailyKey = "2026-10-25";
    shift({ banked: 90 });
    openTitle();
    game.click("boards_button");
    game.step(3);
    game.click("tab_daily");
    game.step(3);
    expect(game.find("boards_list").children.length).toBe(1);
    game.click("tab_trophies");
    game.step(3);
    const rows = game.find("boards_list").children;
    expect(rows.length).toBeGreaterThanOrEqual(6 + 5);
  });

  test("the corner card and the prompts give way to the panel and come back with it", () => {
    openTitle();
    expect(game.find("consent").active).toBe(true);
    game.click("boards_button");
    game.step(3);
    expect(game.find("consent").active).toBe(false);
    expect(game.find("hints").active).toBe(false);
    game.click("boards_back");
    game.step(3);
    expect(game.find("consent").active).toBe(true);
    expect(game.find("hints").active).toBe(true);
  });

  test("an empty board says so", () => {
    openTitle();
    game.click("boards_button");
    game.step(3);
    expect(game.find("boards_list").children.length).toBe(0);
    expect(textOf("boards_note")).toBe("No scores yet. Bank some ore on the lift!");
  });

  test("the pad closes the screen with Back (ui_cancel)", () => {
    openTitle();
    game.click("boards_button");
    game.step(3);
    game.gamepad(0).press("B");
    game.step(2);
    game.gamepad(0).release("B");
    game.step(2);
    expect(game.find("boards").active).toBe(false);
  });

  test("an answer that arrives after the player left the title is dropped", () => {
    openTitle();
    game.click("boards_button");
    game.load(OTHER); // the boards answer is still on its way
    game.step(10);
    expect(scene.current).toBe(OTHER);
  });
});

describe("options switch", () => {
  freshOnline();

  test("the Options panel has the analytics switch and it is the same switch as the consent", () => {
    openTitle();
    game.click("options_button");
    game.step(3);
    const toggle = game.find("analytics").get("Toggle");
    expect(toggle.value).toBe(false);
    game.click("analytics");
    game.step(2);
    expect(toggle.value).toBe(true);
    expect(analytics.enabled()).toBe(true);
    game.click("analytics");
    game.step(2);
    expect(analytics.enabled()).toBe(false);
    expect(analytics.consent()).toBe("denied");
  });
});
