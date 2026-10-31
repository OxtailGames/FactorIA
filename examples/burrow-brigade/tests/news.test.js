// P5: the title's news, from a fixture served by a fake server.
import { test, describe, expect, game } from "factoria:test";
import { storage } from "factoria";
import fixture from "./fixtures/news.json";
import * as news from "../scripts/game/news.js";
import { freshOnline, serveConfig, requests, CONFIG_URL } from "./helpers/online.js";

describe("news", () => {
  freshOnline();

  test("parse keeps the newest three, newest first, and drops items without id or title", () => {
    const items = news.parse(fixture);
    expect(items.length).toBe(3);
    const dates = items.map((i) => i.date);
    expect([...dates].sort().reverse()).toEqual(dates);
    for (const i of items) {
      expect(i.id.length).toBeGreaterThan(0);
      expect(i.title.length).toBeGreaterThan(0);
      expect(i.title.length).toBeLessThanOrEqual(news.MAX_TITLE);
      expect(i.body.length).toBeLessThanOrEqual(news.MAX_BODY);
    }
  });

  test("a file that is not a news file is refused", () => {
    expect(news.parse(null)).toBe(null);
    expect(news.parse({ version: 2, items: [] })).toBe(null);
    expect(news.parse({ version: 1, items: "x" })).toBe(null);
  });

  test("a title with a language object uses English when the language has no entry", () => {
    const items = news.parse({ version: 1, items: [{ id: "a", date: "2026-01-01", title: { en: "Hello", ru: "Privet" }, body: "" }] });
    expect(items[0].title).toBe("Hello");
  });

  test("control characters go and a long text is cut with an ellipsis", () => {
    const items = news.parse({ version: 1, items: [{ id: "a", title: "x".repeat(100) + "\n", body: "b\u0007c" }] });
    expect(items[0].title.endsWith("…")).toBe(true);
    expect(items[0].title.length).toBe(news.MAX_TITLE);
    expect(items[0].body).toBe("b c");
  });

  test("refresh reads the server, remembers the news and falls back to them offline", async () => {
    serveConfig({ news: fixture });
    const a = await news.refresh();
    expect(a.source).toBe("server");
    expect(a.items.length).toBe(3);
    expect(requests()[0]).toMatchObject({ method: "GET", url: CONFIG_URL });
    game.remoteConfig.restart(); // the next run starts offline
    game.platform.reset();
    const b = await news.refresh();
    expect(b.source).toBe("cache");
    expect(b.items).toEqual(a.items);
    expect(news.cached()).toEqual(a.items);
  });

  test("offline with nothing remembered: no news, no error", async () => {
    storage.clear();
    serveConfig(null);
    const r = await news.refresh();
    expect(r).toEqual({ source: "none", items: [] });
  });

  test("a bad file from the server keeps the remembered news", async () => {
    serveConfig({ news: fixture });
    await news.refresh();
    game.remoteConfig.restart();
    game.platform.reset();
    serveConfig({ news: { version: 9 } });
    const r = await news.refresh();
    expect(r.source).toBe("cache");
  });

  test("line joins title and body", () => {
    expect(news.line({ id: "a", date: "", title: "T", body: "B" })).toBe("T - B");
    expect(news.line({ id: "a", date: "", title: "T", body: "" })).toBe("T");
  });
});
