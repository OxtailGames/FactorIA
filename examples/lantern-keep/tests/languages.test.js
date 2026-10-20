import { test, expect, game } from "factoria:test";
import { ui, i18n, storage, fa } from "factoria";
import en from "../locales/en.json";
import es from "../locales/es.json";
import de from "../locales/de.json";
import ar from "../locales/ar.json";
import { LEVELS } from "../scripts/levels.js";

// The four languages: every string is there with the same placeholders, the options cycle through them, and Arabic is laid out
// from the right (the engine orders and joins the letters; `align`, the HUD corners and the glyphs are the game's job).
const TABLES = { en, es, de, ar };

/** `{ "menu.play": "Play", ... }` from a nested string table (keys that start with $ are metadata). */
function flat(table, prefix = "") {
  const out = {};
  for (const [key, value] of Object.entries(table)) {
    if (key.startsWith("$")) continue;
    if (typeof value === "object") Object.assign(out, flat(value, `${prefix}${key}.`));
    else out[prefix + key] = value;
  }
  return out;
}
const placeholders = (s) => (s.match(/\{\w+\}/g) ?? []).sort().join(",");

test("every language has every string, none empty, with the placeholders of the English text", () => {
  const source = flat(en);
  expect(Object.keys(source).length).toBeGreaterThan(140);
  for (const [tag, table] of Object.entries(TABLES)) {
    const strings = flat(table);
    expect([tag, Object.keys(strings).filter((k) => !(k in source))]).toEqual([tag, []]);
    for (const [key, text] of Object.entries(source)) {
      expect([tag, key, key in strings]).toEqual([tag, key, true]);
      expect([tag, key, strings[key].trim() === ""]).toEqual([tag, key, false]);
      expect([tag, key, placeholders(strings[key])]).toEqual([tag, key, placeholders(text)]);
    }
  }
  for (const language of fa.call("i18n.state").languages) expect([language.code, language.loaded, language.missing]).toEqual([language.code, true, 0]);
  expect(i18n.languages).toEqual(["en", "es", "de", "ar"]);
});

test("the language button of the options cycles through the four languages and each one is named in itself", () => {
  storage.remove("settings");
  i18n.setLanguage("en");
  game.load("scenes/menu.scene.json");
  game.step(3);
  const pad = game.gamepad(0);
  pad.tap("DpadDown");
  pad.tap("A"); // Options
  ui.focus(game.find("tab_language"));
  pad.tap("A");
  game.step(2);
  const seen = [];
  for (let i = 0; i < 4; i++) {
    ui.focus(game.find("language"));
    pad.tap("A");
    game.step(2);
    seen.push([i18n.language, game.find("language").get("Button").text]);
  }
  expect(seen).toEqual([
    ["es", "Idioma: Español"],
    ["de", "Sprache: Deutsch"],
    ["ar", "اللغة: العربية"],
    ["en", "Language: English"],
  ]);
});

test("in Arabic the HUD is mirrored and rows run right to left and wrapped texts start on the right; in the other languages neither", () => {
  for (const language of ["en", "ar"]) {
    i18n.setLanguage(language);
    game.load(LEVELS[0].scene);
    game.step(5);
    const rtl = language === "ar";
    expect(game.find("hud_level").get("Text").anchor.x).toBe(rtl ? 1 : 0);
    expect(game.find("hud_embers").get("Text").anchor.x).toBe(rtl ? 0 : 1);
    expect(game.find("hud_level").get("Text").align).toBe("start");
    expect(game.find("hud_embers").get("Text").align).toBe("end");
  }
  i18n.setLanguage("ar");
  game.load("scenes/menu.scene.json");
  game.step(3);
  ui.focus(game.find("shop_button"));
  game.gamepad(0).tap("A");
  game.step(3);
  expect(game.find("shop_note").get("Text").align).toBe("start"); // the right edge in Arabic (i18n.direction)
  expect(ui.rectOf("shop_note").x + ui.rectOf("shop_note").w).toBeLessThanOrEqual(1280);
  expect(game.find("shop_note").get("Text").text).toBe(ar.shop.note);
  i18n.setLanguage("en");
});
