// The markup of the cards and the order board: the engine reads it (Text.markup, the `text` section of factoria.json); the game
// writes it (trade_text.js) and checks it (ui.markupProblems).
import { test, expect } from "factoria:test";
import { ui } from "factoria";
import en from "../locales/en.json";
import project from "../factoria.json";
import atlas from "../data/atlas.json";
import { effectsMarkup, signedMarkup, orderGoodsMarkup } from "../scripts/game/trade_text.js";

test("markup problems are reported with how to fix them, and the project's colours and icons are known", () => {
  expect(ui.markupProblems("A [b]fair[/b] [c:good]deal[/c] [icon:wood] [[ok]")).toEqual([]);
  expect(ui.markupProblems("hello [c:gren]world[/c]").join("\n")).toContain("gren");
  expect(ui.markupProblems("[icon:wod]").join("\n")).toContain("wod");
  expect(ui.markupProblems("[oops]").join("\n")).toContain("oops");
  expect(ui.markupProblems("[b]open").join("\n")).toContain("[b]");
});

test("the icons of factoria.json are the icon frames of the atlas", () => {
  // data/atlas.json is made by assets/src/make_atlas.py; the `text.icons` of factoria.json point at the same pixels
  const frames = Object.entries(atlas.frames).filter(([name]) => name.startsWith("icon."));
  expect(frames.length).toBeGreaterThan(8);
  for (const [name, frame] of frames) {
    const icon = project.text.icons[name.slice(5)];
    expect([name, icon && icon.texture]).toEqual([name, atlas.texture]);
    expect([name, icon.region]).toEqual([name, frame.rect]);
  }
  expect(Object.keys(project.text.icons).length).toBe(frames.length);
});

test("effects text: signed amounts with the good's picture, reputation as a star, the next ship's delay", () => {
  const t = (key, args) => `${key}:${args && (args.count ?? args.n)}`;
  expect(signedMarkup("coins", -40)).toBe("[c:bad]-40[/c][icon:coin]");
  expect(signedMarkup("wood", 4)).toBe("[c:good]+4[/c][icon:wood]");
  expect(effectsMarkup({ delta: { coins: -20, fish: 5 }, reputation: 2, shipDelay: 2 }, t)).toBe(
    "[c:bad]-20[/c][icon:coin]  [c:good]+5[/c][icon:fish]  [c:good]+2[/c][icon:star]  [c:muted]trade.card.later:2[/c]",
  );
  expect(effectsMarkup({ delta: {} }, t)).toBe("");
  expect(effectsMarkup({ shipDelay: -1 }, t)).toBe("[c:muted]trade.card.sooner:1[/c]");
  expect(orderGoodsMarkup({ fish: 12, wood: 8 })).toBe("12[icon:fish]  8[icon:wood]");
});

test("every event, story and trade text of the English table parses clean", () => {
  const strings = [];
  const walk = (o, path) => {
    for (const [k, v] of Object.entries(o)) typeof v === "string" ? strings.push([`${path}.${k}`, v]) : walk(v, `${path}.${k}`);
  };
  for (const root of ["event", "story", "trade"]) walk(en[root], root);
  expect(strings.length).toBeGreaterThan(100);
  for (const [key, text] of strings) expect([key, ui.markupProblems(text)]).toEqual([key, []]);
});
