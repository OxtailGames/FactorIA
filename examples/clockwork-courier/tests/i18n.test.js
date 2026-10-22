// P7, English, Spanish and Japanese: the three locale files say the same things, a language switch rewrites what is on display
// (HUD, open options menu, results, retry), the choice persists, the system language picks the default, the screens fit at 200 %
// text in every language and Japanese text really draws (the font fallback has a glyph for every character the game can show).
import { test, describe, expect, game, afterEach } from "factoria:test";
import { storage, ui, screen, session, i18n } from "factoria";
import { Autoplay, YARD_ROUTE } from "./helpers/autoplay.js";
import * as settings from "../scripts/settings.js";
import * as fmt from "../scripts/fmt.js";
import en from "../locales/en.json";
import es from "../locales/es.json";
import ja from "../locales/ja.json";
import project from "../factoria.json";

const YARD = "scenes/test_yard.scene.json";
const LOCALES = { en, es, ja };
const PLURAL_FORMS = new Set(["zero", "one", "two", "few", "many", "other"]);

function cleanUp() {
  storage.remove("settings");
  storage.remove("progress");
  session.settingsApplied = false;
  if (i18n.language !== "en") i18n.setLanguage("en");
}

/** Saves settings the way the options menu does and starts the scene, as a fresh run of the game would. */
function start(path, saved = {}) {
  storage.remove("progress");
  storage.set("settings", saved);
  session.settingsApplied = false;
  if (i18n.language !== "en") i18n.setLanguage("en"); // a run starts in the default language, apply() then reads the saved one
  game.load(path);
  game.step(10);
}

/** Every key of a locale as a path ("options.tab.video"); a plural object (one, other, ...) counts as ONE key. */
function keysOf(node, prefix = "", out = new Map()) {
  for (const [k, v] of Object.entries(node)) {
    if (k.startsWith("$")) continue;
    const path = prefix ? `${prefix}.${k}` : k;
    if (typeof v === "string") out.set(path, [v]);
    else if (Object.keys(v).every((f) => PLURAL_FORMS.has(f))) out.set(path, Object.values(v));
    else keysOf(v, path, out);
  }
  return out;
}

const placeholders = (strings) => [...new Set(strings.flatMap((s) => [...s.matchAll(/\{(\w+)\}/g)].map((m) => m[1])))].sort();

describe("the locale files", () => {
  test("es and ja have exactly the keys of en, with the same placeholders", () => {
    const reference = keysOf(en);
    for (const [name, locale] of [["es", es], ["ja", ja]]) {
      const keys = keysOf(locale);
      const missing = [...reference.keys()].filter((k) => !keys.has(k));
      const extra = [...keys.keys()].filter((k) => !reference.has(k));
      expect({ name, missing, extra }).toEqual({ name, missing: [], extra: [] });
      for (const [key, strings] of reference) {
        // a plural form may drop a placeholder in a language whose form says it in words, but never add one en does not have
        const have = placeholders(keys.get(key));
        const want = placeholders(strings);
        if (JSON.stringify(have) !== JSON.stringify(want)) console.log(`${name}: ${key} has {${have}} but en has {${want}}`);
        expect(have).toEqual(want);
      }
    }
  });

  test("every locale names itself and none is empty", () => {
    for (const [tag, locale] of Object.entries(LOCALES)) {
      expect(typeof locale.$name).toBe("string");
      for (const [key, strings] of keysOf(locale)) {
        for (const s of strings) if (s.trim() === "") throw new Error(`${tag}: ${key} is empty`);
      }
    }
    expect(i18n.languages).toEqual(["en", "es", "ja"]);
    expect(i18n.name("ja")).toBe("日本語");
  });

  test("numbers and times come out the way the language writes them", () => {
    i18n.setLanguage("es");
    expect(fmt.decimal(1.5)).toBe("1,5");
    expect(fmt.clock(75)).toBe("1:15,0");
    i18n.setLanguage("en");
    expect(fmt.clock(75)).toBe("1:15.0");
    expect(fmt.decimal(1.5)).toBe("1.5");
    i18n.setLanguage("ja");
    expect(fmt.decimal(1.5)).toBe("1.5");
    // plurals go through the engine: 1 star and 3 stars read differently in English and Spanish
    i18n.setLanguage("en");
    expect(i18n.t("select.districtLocked", { count: 1, have: 0 })).not.toBe(i18n.t("select.districtLocked", { count: 3, have: 0 }));
    i18n.setLanguage("es");
    expect(i18n.t("shop.state.stars", { count: 1, have: 0 })).toContain("1 estrella ");
    expect(i18n.t("shop.state.stars", { count: 6, have: 0 })).toContain("6 estrellas");
  });
});

describe("switching the language while the game runs", () => {
  afterEach(cleanUp);

  test("the HUD of a level is rewritten at once", () => {
    start(YARD);
    const parcels = () => game.find("parcel_text").get("Text").text;
    expect(parcels()).toContain("Parcels");
    i18n.setLanguage("es");
    game.step(2);
    expect(parcels()).toContain("Paquetes");
    i18n.setLanguage("ja");
    game.step(2);
    expect(parcels()).toContain("荷物");
    expect(game.find("spring_label").get("Text").text).toBe("ぜんまい");
    expect(game.find("touch_jump").get("TouchButton").text).toBe("ジャンプ");
  });

  test("an open options menu changes its texts, and its own language buttons do it", () => {
    start(YARD);
    game.tap("pause");
    game.step(2);
    game.click("pause_options");
    game.step(3);
    game.click("tab_language");
    game.step(2);
    expect(game.find("tab_language").get("Button").text).toBe("Language");
    game.click("language_es");
    game.step(3);
    expect(i18n.language).toBe("es");
    expect(game.find("tab_language").get("Button").text).toBe("Idioma");
    expect(game.find("tab_video").get("Button").text).toBe("Vídeo");
    expect(game.find("language_es").get("Button").text).toContain("> "); // the one in use is marked
    game.click("language_ja");
    game.step(3);
    expect(game.find("tab_language").get("Button").text).toBe("言語");
    game.click("tab_play");
    game.step(2);
    expect(game.find("assist").get("Toggle").label ?? game.find("assist").get("Toggle").text).toContain("アシスト");
  });

  test("the results and the retry screens are rewritten while they show", () => {
    start(YARD);
    new Autoplay(game).run(YARD_ROUTE);
    game.step(150);
    expect(game.find("results_panel").active).toBe(true);
    const heading = () => game.find("results_heading").get("Text").text;
    const before = heading();
    i18n.setLanguage("ja");
    game.step(2);
    expect(heading()).not.toBe(before);
    expect(heading()).toContain("お届け");
    expect(game.find("results_time").get("Text").text).toContain("タイム");
    expect(game.find("results_retry").get("Button").text).toBe("もう一度あそぶ");

    start(YARD);
    game.find("spring").behaviour.left = 0.1;
    game.step(200);
    expect(game.find("retry_panel").active).toBe(true);
    i18n.setLanguage("es");
    game.step(2);
    expect(game.find("retry_title").get("Button").text).toBe("Salir al título");
  });
});

describe("the chosen language persists", () => {
  afterEach(cleanUp);

  test("picking a language in the options is saved and used by the next start", () => {
    start(YARD);
    game.tap("pause");
    game.step(2);
    game.click("pause_options");
    game.step(3);
    game.click("tab_language");
    game.step(2);
    game.click("language_ja");
    game.step(2);
    expect(storage.get("settings").language).toBe("ja");
    // a new run: the engine starts in the default language, the main menu then applies the saved settings
    session.settingsApplied = false;
    i18n.setLanguage("en");
    game.load("scenes/main.scene.json");
    game.step(5);
    expect(i18n.language).toBe("ja");
    expect(game.find("play").get("Button").text).toBe("あそぶ");
  });

  test("back to the language the game started in is saved as that language, not as 'none'", () => {
    start(YARD, { language: "es" });
    expect(i18n.language).toBe("es");
    expect(settings.load().language).toBe("es");
  });

  test("a saved language the game does not have is ignored and English stays", () => {
    start("scenes/main.scene.json", { language: "xx" });
    expect(i18n.language).toBe("en");
    expect(game.find("play").get("Button").text).toBe("Play");
  });
});

describe("the system language picks the first language", () => {
  test("a match on the whole tag or its first part, in the system's order", () => {
    const supported = ["en", "es", "ja"];
    expect(settings.pickLanguage(["ja"], supported, "en")).toBe("ja");
    expect(settings.pickLanguage(["es-MX", "en-US"], supported, "en")).toBe("es");
    expect(settings.pickLanguage(["ja_JP"], supported, "en")).toBe("ja");
    expect(settings.pickLanguage(["fr-FR", "es-ES"], supported, "en")).toBe("es"); // the first one the game has
    expect(settings.pickLanguage(["JA-jp"], supported, "en")).toBe("ja");
  });

  test("a language the game does not have falls back to English", () => {
    expect(settings.pickLanguage(["fr-FR", "de"], ["en", "es", "ja"], "en")).toBe("en");
    expect(settings.pickLanguage([], ["en", "es", "ja"], "en")).toBe("en");
  });

  test("a headless run has no system language and starts in the default one", () => {
    expect(i18n.systemLanguages).toEqual([]);
    expect(project.localization.defaultLanguage).toBe("en");
    start("scenes/main.scene.json");
    expect(i18n.language).toBe("en");
    cleanUp();
  });
});

describe("a big text size", () => {
  afterEach(cleanUp);

  /** True when the widget's rectangle lies on the screen (a pixel of slack for rounding). */
  function inside(id) {
    const r = ui.rectOf(id);
    const s = screen.safeArea;
    expect(r).not.toBeNull();
    const ok = r.x >= s.x - 1 && r.y >= s.y - 1 && r.x + r.w <= s.x + s.w + 1 && r.y + r.h <= s.y + s.h + 1;
    if (!ok) console.log(`${id} is outside the screen: ${JSON.stringify(r)} vs ${JSON.stringify(s)}`);
    return ok;
  }

  for (const tag of ["en", "es", "ja"]) {
    test(`at 200 percent every button of the menus stays on the screen in ${tag}`, () => {
      start("scenes/main.scene.json", { language: tag, textScale: 2 });
      expect(i18n.language).toBe(tag);
      expect(ui.textScale).toBe(2);
      expect(inside("main_menu")).toBe(true);
      for (const id of ["play", "shop_button", "achievements_button", "leaderboards_button", "options_button", "credits_button", "quit"]) {
        expect(inside(id)).toBe(true);
      }
      for (const [open, panel, back] of [
        ["credits_button", "credits", "credits_back"],
        ["shop_button", "shop", "shop_back"],
        ["achievements_button", "achievements", "achievements_back"],
        ["leaderboards_button", "leaderboards", "board_back"],
      ]) {
        game.click(open);
        game.step(3);
        expect(inside(panel)).toBe(true);
        expect(inside(back)).toBe(true);
        game.click(back);
        game.step(2);
      }
      game.click("options_button");
      game.step(3);
      expect(inside("options")).toBe(true);
      for (const tab of ["video", "audio", "play", "touch", "controls", "language"]) {
        expect(inside(`tab_${tab}`)).toBe(true);
        game.click(`tab_${tab}`);
        game.step(2);
        expect(inside(`${tab}_section`)).toBe(true);
      }
      expect(inside("options_back")).toBe(true);
    });

    test(`at 200 percent the pause menu, results and retry screens stay on the screen in ${tag}`, () => {
      start(YARD, { language: tag, textScale: 2 });
      game.tap("pause");
      game.step(3);
      expect(inside("pause_box")).toBe(true);
      for (const id of ["resume", "pause_options", "pause_restart", "to_main_menu"]) expect(inside(id)).toBe(true);
      game.pressBack();
      game.step(3);
      start(YARD, { language: tag, textScale: 2 });
      game.find("spring").behaviour.left = 0.1;
      game.step(200);
      expect(inside("retry_panel_box")).toBe(true);
      for (const id of ["retry_retry", "retry_title"]) expect(inside(id)).toBe(true);
      start(YARD, { language: tag, textScale: 2 });
      new Autoplay(game).run(YARD_ROUTE);
      game.step(150);
      expect(inside("results_panel_box")).toBe(true);
      for (const id of ["results_next", "results_retry", "results_title"]) expect(inside(id)).toBe(true);
    });
  }
});

describe("Japanese text", () => {
  /** The width of a text; a character no font in the chain has draws as nothing and measures narrow. */
  const width = (text) => ui.measureText(text, { fontSize: 24 }).width;

  test("the fallback font is listed in factoria.json", () => {
    expect(project.localization.fallbackFonts).toContain("assets/fonts/NotoSansJP-Regular-subset.ttf");
  });

  test("every Japanese character the game can show has a glyph", () => {
    // 魍 is in no font of the chain (a rare kanji): it measures as the missing glyph and tells apart a covered character
    const missing = width("魍") / 1;
    expect(width("日")).toBeGreaterThan(missing * 1.2);
    const chars = new Set();
    for (const strings of keysOf(ja).values()) for (const s of strings) for (const ch of s) if (ch.charCodeAt(0) > 0x2e80) chars.add(ch);
    expect(chars.size).toBeGreaterThan(100);
    const bad = [...chars].filter((ch) => width(ch) <= missing * 1.2);
    expect(bad).toEqual([]);
  });
});
