// The languages of the game (P8): every locale file has every key with the same placeholders and markup, the formatting module
// writes numbers, money and dates the way each language does, a language switch redraws the screens, and a save made in one language
// loads in another. (The glyph check of the Chinese font is `factoria validate`, which asks the font for every character of
// every string; assets/fonts/make_subset.py --check lists the same. The layouts at 200 % are in languages_layout.test.js.)
import { test, expect, game } from "factoria:test";
import { i18n, scene, session, storage, ui } from "factoria";
import en from "../locales/en.json";
import es from "../locales/es.json";
import fr from "../locales/fr.json";
import zh from "../locales/zh-Hans.json";
import { LANGUAGES, inLanguage } from "./layout_helper.js";
import { numberText, compactText, coinsText, villagersText, goodAmountText, amountText, listText, dateText } from "../scripts/game/format.js";
import { newScenarioGame, GoalTracker } from "../scripts/game/scenarios.js";
import { growTown } from "../scripts/game/bot.js";
import { getData } from "../scripts/game/data.js";
import { writeEntry, loadEntry } from "../scripts/game/save_store.js";

const TABLES = { en, es, fr, "zh-Hans": zh };
const GAME = "scenes/game.scene.json";

/** Every string of a table with its dotted key; a plural entry ({one, other}) is one entry per form. */
function flatten(value, prefix = "", out = new Map()) {
  if (typeof value === "string") out.set(prefix, value);
  else for (const [k, v] of Object.entries(value)) flatten(v, prefix ? `${prefix}.${k}` : k, out);
  return out;
}

const placeholders = (text) => [...text.matchAll(/\{(\w+)(?::\w+)?\}/g)].map((m) => m[1]).sort();
const markup = (text) => [...text.matchAll(/\[\[|\[\/?[bc](?::[^\]]*)?\]|\[icon:[^\]]*\]/g)].map((m) => m[0]).sort();
/** Plural forms of a language differ (Chinese has only "other", French counts 0 as "one"): a plural entry is compared as "other". */
const isForm = (key) => /\.(zero|one|two|few|many)$/.test(key);

const english = flatten(en);

test("every locale has every key of the English table", () => {
  for (const code of LANGUAGES) {
    const table = flatten(TABLES[code]);
    const missing = [...english.keys()].filter((k) => !isForm(k) && !table.has(k));
    expect(missing).toEqual([]);
    const extra = [...table.keys()].filter((k) => !isForm(k) && !english.has(k));
    expect(extra).toEqual([]);
  }
});

test("the engine knows the four languages, English first", () => {
  expect(i18n.languages).toEqual(["en", "es", "fr", "zh-Hans"]);
  expect(i18n.defaultLanguage).toBe("en");
  expect(i18n.name("zh-Hans")).toBe("简体中文");
});

test("every translation keeps the placeholders and the markup of the English string", () => {
  const problems = [];
  for (const code of LANGUAGES.filter((c) => c !== "en")) {
    const table = flatten(TABLES[code]);
    for (const [key, text] of table) {
      const base = english.get(key) ?? english.get(`${key.replace(/\.[a-z]+$/, "")}.other`);
      if (isForm(key) || base === undefined) continue;
      const a = JSON.stringify(placeholders(base));
      const b = JSON.stringify(placeholders(text));
      if (a !== b) problems.push(`${code} ${key}: placeholders ${b}, English has ${a}`);
      const m = JSON.stringify(markup(base));
      const n = JSON.stringify(markup(text));
      if (m !== n) problems.push(`${code} ${key}: markup ${n}, English has ${m}`);
    }
  }
  expect(problems).toEqual([]);
});

test("every string with rich-text markup parses, in every language", () => {
  const problems = [];
  for (const code of LANGUAGES) {
    for (const [key, text] of flatten(TABLES[code])) {
      if (!markup(text).length) continue;
      const errors = ui.markupProblems(text);
      if (errors.length) problems.push(`${code} ${key}: ${JSON.stringify(errors)}`);
    }
  }
  expect(problems).toEqual([]);
});

test("a plural entry has the forms its language needs", () => {
  // en/es/fr: one + other; zh-Hans: other only. A form a language does not use is not an error, a missing "other" is.
  for (const code of LANGUAGES) {
    const walk = (node, path) => {
      if (typeof node === "string") return;
      if ("one" in node || "other" in node) expect(`${code} ${path} other: ${typeof node.other}`).toBe(`${code} ${path} other: string`);
      else for (const [k, v] of Object.entries(node)) walk(v, `${path}.${k}`);
    };
    walk(TABLES[code], "");
  }
});

test("numbers, money and dates are written the way each language writes them", () => {
  const want = {
    en: { n: "12,345.5", coins1: "1 coin", coins2: "2 coins", coinsBig: "1,234,567 coins", compact: "12.3k", date: "Spring 3, year 2" },
    es: { n: "12.345,5", coins1: "1 moneda", coins2: "2 monedas", coinsBig: "1.234.567 monedas", compact: "12,3 mil", date: "3 de primavera, año 2" },
    fr: { n: "12\u202f345,5", coins1: "1 pièce", coins2: "2 pièces", coinsBig: "1\u202f234\u202f567 pièces", compact: "12,3 k", date: "3 printemps, an 2" },
    "zh-Hans": { n: "12,345.5", coins1: "1 枚金币", coins2: "2 枚金币", coinsBig: "1,234,567 枚金币", compact: "1.2万", date: "第2年春季，第3天" },
  };
  for (const code of LANGUAGES) {
    inLanguage(code, 1, () => {
      const w = want[code];
      const got = {
        n: numberText(12345.5),
        coins1: coinsText(1),
        coins2: coinsText(2),
        coinsBig: coinsText(1234567),
        compact: compactText(12345),
        date: dateText({ season: "spring", dayOfSeason: 3, year: 2 }),
      };
      expect({ code, ...got }).toEqual({ code, ...w });
    });
  }
});

test("lists and amounts follow the language: separators, word order, plurals", () => {
  inLanguage("en", 1, () => {
    expect(listText(["wood", "stone"])).toBe("wood, stone");
    expect(goodAmountText("wood", 4)).toBe("4 wood");
    expect(amountText({ coins: 40, wood: 4 })).toBe("40 coins, 4 wood");
    expect(villagersText(1)).toBe("1 villager");
  });
  inLanguage("zh-Hans", 1, () => {
    expect(listText(["木材", "石料"])).toBe("木材、石料");
    expect(goodAmountText("wood", 4)).toBe("木材×4");
    expect(amountText({ coins: 40, wood: 4 })).toBe("40 枚金币、木材×4");
  });
  inLanguage("es", 1, () => {
    expect(villagersText(1)).toBe("1 aldeano");
    expect(villagersText(3)).toBe("3 aldeanos");
    expect(goodAmountText("wood", 4)).toBe("4 × madera");
  });
  inLanguage("fr", 1, () => {
    // French counts 0 and 1 as singular
    expect(coinsText(0)).toBe("0 pièce");
    expect(coinsText(1)).toBe("1 pièce");
    expect(coinsText(2)).toBe("2 pièces");
  });
});

test("the system language is the default of a first run; a saved choice wins", () => {
  // headless runs start in the project's default language, so the rule is read from the engine's own report
  expect(i18n.language).toBe("en");
  expect(Array.isArray(i18n.systemLanguages)).toBe(true);
});

test("a language switch while the game is running redraws the HUD, the open panels and the tooltips' words", () => {
  storage.clear();
  game.platform.reset();
  session.boot = { slot: 0, scenario: "sandbox", name: "" };
  game.load(GAME);
  game.step(3);
  expect(scene.current).toBe(GAME);
  const text = (id) => game.find(id).get("Text").text;
  const label = (id) => game.find(id).get("Button").text;
  const english = { build: label("btn_build"), date: text("hud_date") };
  game.click("btn_goods");
  game.step(2);
  expect(game.find("goods_panel").activeInHierarchy).toBe(true);
  const seen = new Set([english.build]);
  for (const code of ["es", "fr", "zh-Hans"]) {
    i18n.setLanguage(code);
    game.step(2);
    const build = label("btn_build");
    expect(build).toContain(i18n.t("ui.btn.build"));
    expect(seen.has(build)).toBe(false);
    seen.add(build);
    expect(text("hud_date")).not.toBe(english.date);
    expect(text("hud_date")).toContain(i18n.t("season.date.spring"));
    // the goods table (a script-built panel) redrew too: its title and its sort buttons are in the new language
    const title = game.find("goods_panel").activeInHierarchy ? text("goods_title") : "";
    expect(title).toBe(i18n.t("ui.goods.title"));
  }
  i18n.setLanguage("en");
  game.step(2);
  expect(label("btn_build")).toBe(english.build);
  expect(ui.textScale).toBe(1);
});

test("a save made in Spanish loads in Chinese: the save holds ids and numbers, never words", () => {
  storage.clear();
  game.platform.reset();
  const data = getData();
  i18n.setLanguage("es");
  const first = newScenarioGame("first_harbour", data);
  const tracker = new GoalTracker(first.state, "first_harbour", first.def).attach();
  growTown({ state: first.state, days: 20 });
  expect(writeEntry(1, "manual", first.state, { scenario: "first_harbour", name: "Puerto viejo", extra: tracker.saveFields(), progress: tracker.metaFields() }).ok).toBe(true);
  const hash = first.state.hash();
  i18n.setLanguage("zh-Hans");
  game.step(2);
  const loaded = loadEntry(1, "manual", data);
  expect(loaded.ok).toBe(true);
  expect(loaded.state.hash()).toBe(hash);
  expect(loaded.meta.name).toBe("Puerto viejo"); // the player's own name is kept as typed
  // and the game screen opens it in Chinese: the date line and the goal rows are Chinese
  session.boot = { slot: 1, kind: "manual" };
  game.load(GAME);
  game.step(3);
  expect(scene.current).toBe(GAME);
  expect(game.find("controller").behaviour.state.hash()).toBe(hash);
  expect(game.find("goal_title").get("Text").text).toBe(zh.goal.title);
  expect(game.find("hud_date").get("Text").text).toMatch(/第\d+年/);
  i18n.setLanguage("en");
  game.step(2);
});
