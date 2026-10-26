// The markup of the cards and the order board (scripts/game/richtext.js, trade_text.js): parsing, layout and the text of effects.
// Pure functions: the width of a string is 10 px per character here, so the numbers are easy to check.
import { test, expect } from "factoria:test";
import en from "../locales/en.json";
import { parseMarkup, layoutRich, plainText, colorOf } from "../scripts/game/richtext.js";
import { effectsMarkup, signedMarkup, orderGoodsMarkup } from "../scripts/game/trade_text.js";

const measure = (s) => s.length * 10;
const lay = (markup, maxWidth = 400) => layoutRich(parseMarkup(markup).tokens, { maxWidth, fontSize: 20, measure });

test("markup: bold, colours, pictures, a literal bracket and line breaks", () => {
  const { tokens, errors } = parseMarkup("A [b]fair[/b] [c:good]deal[/c] [icon:wood] [[ok]\nnext");
  expect(errors).toEqual([]);
  expect(tokens.filter((t) => t.kind === "icon")).toEqual([{ kind: "icon", name: "wood" }]);
  expect(tokens.find((t) => t.kind === "text" && t.text === "fair").bold).toBe(true);
  expect(tokens.find((t) => t.kind === "text" && t.text === "deal").color).toBe("good");
  expect(tokens.some((t) => t.kind === "br")).toBe(true);
  expect(plainText("A [b]fair[/b] [icon:wood] [[x")).toBe("A fair [wood] [x");
});

test("a typo in a tag is reported with its position and the text is kept visible", () => {
  const bad = parseMarkup("hello [c:gren]world[/c] [oops] [b]open");
  expect(bad.errors.join("\n")).toContain("unknown colour 'gren'");
  expect(bad.errors.join("\n")).toContain("unknown tag [oops]");
  expect(bad.errors.join("\n")).toContain("[b] is never closed");
  expect(plainText("hello [c:gren]world[/c]")).toContain("world");
  expect(colorOf("#ff0000")).toEqual([1, 0, 0, 1]);
  expect(colorOf("nope")).toBe(null);
});

test("layout: lines break at spaces, never inside a word, and a number stays glued to its picture", () => {
  const one = lay("one two three four", 120); // 12 characters per line
  expect(one.lines).toBe(2);
  expect(one.items.map((i) => i.text)).toEqual(["one two", "three four"]);
  const glued = lay("aaaaaaaa +12[icon:wood]", 120);
  // "+12" and the picture never part: they go to the next line together
  const num = glued.items.find((i) => i.kind === "text" && i.text === "+12");
  const icon = glued.items.find((i) => i.kind === "icon");
  expect(icon.y).toBe(num.y + 3); // centred on the line: (27 - 21) / 2
  expect(icon.x).toBe(num.x + num.w);
  expect(glued.lines).toBe(2);
  expect(lay("short", 400).height).toBe(27);
  expect(lay("a\nb\nc").lines).toBe(3);
});

test("layout: CJK text breaks between characters, and a closing mark never starts a line", () => {
  const cjk = lay("港口的船来了。港口的船走了。", 70); // 7 characters per line
  expect(cjk.lines).toBeGreaterThan(1);
  for (const item of cjk.items) expect("。、".includes(item.text[0])).toBe(false);
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
  for (const [key, text] of strings) expect([key, parseMarkup(text).errors]).toEqual([key, []]);
});
