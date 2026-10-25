// P8 languages: English, Russian and Thai. The three string tables have the same keys, the Russian plurals pick the right form for
// real counts, Thai text has a place to break every few letters (the engine cannot find word boundaries), and the language is
// chosen from Options by the mouse, the keyboard and a gamepad, saved, and applied on every screen at once.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { ui, i18n, storage } from "factoria";
import en from "../locales/en.json";
import ru from "../locales/ru.json";
import th from "../locales/th.json";
import { freshOnline } from "./helpers/online.js";
import * as settings from "../scripts/settings.js";

const PLURAL = new Set(["zero", "one", "two", "few", "many", "other"]);
const isPlural = (v) => v && typeof v === "object" && Object.keys(v).every((k) => PLURAL.has(k)) && "other" in v;

/** Every leaf of a nested table as `dotted.key` -> text (a plural entry is one leaf holding its forms). */
function flatten(table, prefix = "", out = {}) {
  for (const [k, v] of Object.entries(table)) {
    const path = prefix ? `${prefix}.${k}` : k;
    if (typeof v === "string" || isPlural(v)) out[path] = v;
    else flatten(v, path, out);
  }
  return out;
}
const placeholders = (v) => {
  const text = typeof v === "string" ? v : v.other;
  return [...text.matchAll(/\{(\w+)\}/g)].map((m) => m[1]).sort().join(",");
};
const BASE = /[ก-ฮะาำเ-ๆ]/; // Thai letters that start a syllable or stand alone
const MARK = /[ัิ-ฺ็-๎]/; // vowel signs, tone marks: they never begin a word

const E = flatten(en);
const R = flatten(ru);
const T = flatten(th);

describe("string tables", () => {
  test("Russian and Thai have every English key and no extra one", () => {
    expect(Object.keys(R).sort()).toEqual(Object.keys(E).sort());
    expect(Object.keys(T).sort()).toEqual(Object.keys(E).sort());
  });

  test("each text keeps the {placeholders} of the English one, and a plural stays a plural", () => {
    for (const [name, table] of [["ru", R], ["th", T]]) {
      for (const key of Object.keys(E)) {
        expect(`${name}:${key}:${isPlural(table[key])}`).toBe(`${name}:${key}:${isPlural(E[key])}`);
        const forms = (v) => (typeof v === "string" ? [v] : Object.values(v));
        for (const f of forms(table[key])) {
          expect(`${name}:${key}:${placeholders(f)}`).toBe(`${name}:${key}:${placeholders(E[key])}`);
        }
      }
    }
  });

  test("Russian plural entries have the four forms Russian uses", () => {
    for (const [key, v] of Object.entries(R)) {
      if (!isPlural(v)) continue;
      expect(`${key}:${Object.keys(v).sort().join(",")}`).toBe(`${key}:few,many,one,other`);
    }
  });

  test("no table keeps an untranslated English sentence", () => {
    for (const key of ["menu.play", "options.title", "pause.title", "camp.descend", "results.toTitle"]) {
      expect(R[key]).not.toBe(E[key]);
      expect(T[key]).not.toBe(E[key]);
    }
  });
});

describe("Russian plural forms on real counts", () => {
  const form = (key, n, extra = {}) => {
    i18n.setLanguage("ru");
    return i18n.t(key, { count: n, ...extra });
  };
  test("tries of the daily dig: 1 попытка, 2 попытки, 5 попыток, 11 попыток, 21 попытка, 22 попытки", () => {
    const want = { 1: "попытка", 2: "попытки", 5: "попыток", 11: "попыток", 21: "попытка", 22: "попытки", 25: "попыток" };
    for (const [n, word] of Object.entries(want)) {
      const text = form("menu.dailyInfo", Number(n), { key: "k", tries: Number(n), depth: 40 });
      expect(text).toContain(`${n} ${word}`);
    }
  });
  test("coins of a slot and miners of the presence line", () => {
    const slot = { slot: 1, stratum: "S", floor: 2, time: "1:00", best: 10 };
    expect(form("slots.filled", 1, { ...slot, cash: 1 })).toContain("1 монета");
    expect(form("slots.filled", 3, { ...slot, cash: 3 })).toContain("3 монеты");
    expect(form("slots.filled", 12, { ...slot, cash: 12 })).toContain("12 монет");
    expect(form("slots.filled", 101, { ...slot, cash: 101 })).toContain("101 монета");
    const crew = { stratum: "S", floor: 1 };
    expect(form("presence.shift", 1, crew)).toContain("1 шахтёр)");
    expect(form("presence.shift", 2, crew)).toContain("2 шахтёра)");
    expect(form("presence.shift", 4, crew)).toContain("4 шахтёра)");
  });
  test("percent of the volume sliders", () => {
    expect(form("options.percent", 1, { value: 1 })).toBe("1 процент");
    expect(form("options.percent", 50, { value: 50 })).toBe("50 процентов");
    expect(form("options.percent", 23, { value: 23 })).toBe("23 процента");
  });
});

describe("Thai line breaks", () => {
  // The engine breaks a line only at a space (or between CJK characters), and finds no Thai word boundaries: every Thai text has a
  // real space at least every 16 letters (tools/thai_spaces.py puts them in and checks them).
  const longest = (text) => {
    let best = 0;
    for (const run of text.split(/[\s　]+/)) {
      const letters = [...run].filter((c) => BASE.test(c) && !MARK.test(c)).length;
      best = Math.max(best, letters);
    }
    return best;
  };
  const texts = Object.entries(T).flatMap(([k, v]) => (typeof v === "string" ? [[k, v]] : Object.entries(v).map(([f, s]) => [`${k}#${f}`, s])));

  test("no Thai text has a run of more than 16 letters without a space", () => {
    for (const [key, text] of texts) expect(`${key}:${longest(text)}`).toBe(`${key}:${Math.min(longest(text), 16)}`);
  });

  test("no space-free run begins with a vowel sign or a tone mark (a break never strands one)", () => {
    for (const [key, text] of texts) for (const run of text.split(/\s+/)) if (run) expect(`${key}:${MARK.test(run[0])}`).toBe(`${key}:false`);
  });

  test("a long Thai sentence wraps inside its maxWidth", () => {
    i18n.setLanguage("th");
    const text = i18n.t("online.consentBody");
    const wide = ui.measureText(text, { fontSize: 20 });
    const wrapped = ui.measureText(text, { fontSize: 20, maxWidth: 330 });
    expect(wrapped.width).toBeLessThanOrEqual(330);
    expect(wrapped.height).toBeGreaterThan(wide.height);
  });
});

describe("the language option", () => {
  freshOnline();
  beforeEach(() => i18n.setLanguage("en"));

  const open = () => {
    game.load("scenes/menu.scene.json");
    game.step(5);
    game.click("options_button");
    game.step(3);
    game.click("tab_language");
    game.step(2);
  };
  const saved = () => storage.get("settings", {});

  test("the game offers English, Russian and Thai", () => {
    expect(i18n.languages).toEqual(["en", "ru", "th"]);
  });

  test("mouse: each click moves to the next language, applies it at once everywhere and saves it", () => {
    open();
    expect(i18n.language).toBe("en");
    game.click("language");
    game.step(3);
    expect(i18n.language).toBe("ru");
    expect(saved().language).toBe("ru");
    expect(game.find("language").get("Button").text).toContain("Русский");
    expect(game.find("tab_language").get("Button").text).toBe(ru.options.tab.language);
    game.click("language");
    game.step(3);
    expect(i18n.language).toBe("th");
    expect(saved().language).toBe("th");
    expect(game.find("language").get("Button").text).toContain("ไทย");
    game.click("language");
    game.step(3);
    expect(i18n.language).toBe("en");
    expect(saved().language).toBe("en");
  });

  test("the new language reaches the other tabs, the title and scripts' own texts", () => {
    open();
    game.click("language");
    game.step(3);
    game.click("tab_access");
    game.step(2);
    expect(game.find("game_speed").get("Button").text).toContain("Скорость игры");
    game.click("options_back");
    game.step(3);
    expect(game.find("play").get("Button").text).toBe(ru.menu.play);
  });

  test("keyboard only: reach the Language tab, press the row, the language changes", () => {
    game.load("scenes/menu.scene.json");
    game.step(2);
    for (let i = 0; i < 3; i++) game.tap("ui_down");
    game.tap("ui_submit");
    for (let i = 0; i < 4; i++) game.tap("ui_right");
    game.tap("ui_submit");
    expect(game.find("language_section").active).toBe(true);
    let guard = 0;
    while (ui.focused?.id !== "language" && guard++ < 10) game.tap("ui_down");
    expect(ui.focused.id).toBe("language");
    game.tap("ui_submit");
    game.step(2);
    expect(i18n.language).toBe("ru");
    expect(saved().language).toBe("ru");
  });

  test("gamepad only: reach the Language tab, press the row, the language changes", () => {
    game.load("scenes/menu.scene.json");
    const pad = game.gamepad(0);
    pad.connect();
    game.step(2);
    for (let i = 0; i < 3; i++) pad.tap("DpadDown");
    pad.tap("A");
    for (let i = 0; i < 4; i++) pad.tap("DpadRight");
    pad.tap("A");
    expect(game.find("language_section").active).toBe(true);
    let guard = 0;
    while (ui.focused?.id !== "language" && guard++ < 10) pad.tap("DpadDown");
    expect(ui.focused.id).toBe("language");
    pad.tap("A");
    pad.tap("A");
    game.step(2);
    expect(i18n.language).toBe("th");
    expect(saved().language).toBe("th");
  });

  test("a saved language wins over the one the game started in", () => {
    const s = settings.load();
    s.language = "th";
    settings.save(s);
    settings.apply(settings.load());
    game.step(2);
    expect(i18n.language).toBe("th");
  });

  test("with no saved language the language the game started in (the system's, else English) stays", () => {
    const s = settings.load();
    expect(s.language).toBe(null);
    i18n.setLanguage("ru"); // as if the player's system language had been Russian
    settings.apply(s);
    game.step(2);
    expect(i18n.language).toBe("ru");
  });

  test("a saved language the game no longer has is ignored, not fatal", () => {
    const s = settings.load();
    s.language = "xx";
    settings.save(s);
    settings.apply(settings.load());
    expect(i18n.languages).toContain(i18n.language);
  });
});
