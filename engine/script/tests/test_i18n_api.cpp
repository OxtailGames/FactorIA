// The `i18n` object of the "factoria" module (docs/LOCALIZATION.md), run against the test host's I18n: the lookups, the language
// switch, the "change" event and the Text/widget pass. The tables and the plural rules have their own tests in engine/core.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

Json settings() {
    return Json::parse(R"({ "localization": { "defaultLanguage": "en", "languages": ["en", "es", "pt-BR"] } })");
}

void write_tables(TestHost& h) {
    h.file("locales/en.json", R"({ "$name": "English",
      "menu": { "play": "Play", "title": "My Game" },
      "greeting": "Hello, {name}!",
      "hud": { "score": "Score: {score}" },
      "items": { "one": "{count} item", "other": "{count} items" },
      "only_en": "Only English" })");
    h.file("locales/es.json", R"({ "$name": "Español",
      "menu": { "play": "Jugar", "title": "Mi juego" },
      "greeting": "¡Hola, {name}!",
      "hud": { "score": "Puntos: {score}" },
      "items": { "one": "{count} objeto", "other": "{count} objetos" } })");
    h.file("locales/pt-BR.json", R"json({ "$name": "Português (Brasil)", "menu": { "play": "Jogar", "title": "Meu jogo" } })json");
    h.file("scenes/main.scene.json", R"({ "format": "factoria.scene/1", "entities": [
      { "id": "title", "components": { "Text": { "text": "scene", "key": "menu.title", "space": "screen" } } },
      { "id": "play", "components": { "Button": { "text": "x", "key": "menu.play" } } },
      { "id": "plain", "components": { "Text": { "text": "no key", "space": "screen" } } } ] })");
}

}  // namespace

TEST_CASE("i18n api: t fills placeholders and plurals, has tells a string from a missing key, the rest describes the game") {
    TestHost h("i18n_read", settings());
    write_tables(h);
    h.file("tests/read.test.js", R"js(
import { test, expect } from "factoria:test";
import { i18n } from "factoria";

test("the game's languages", () => {
  expect(i18n.language).toBe("en");
  expect(i18n.defaultLanguage).toBe("en");
  expect(i18n.languages).toEqual(["en", "es", "pt-BR"]);
  expect(i18n.systemLanguages).toEqual([]); // no window: the machine does not matter
  expect(i18n.name("es")).toBe("Español");
  expect(i18n.name("pt-BR")).toBe("Português (Brasil)");
  expect(i18n.name("zz")).toBe("zz");
});

test("t: placeholders, plurals, fallbacks and a missing key", () => {
  expect(i18n.t("menu.play")).toBe("Play");
  expect(i18n.t("greeting", { name: "Ana" })).toBe("Hello, Ana!");
  expect(i18n.t("items", { count: 1 })).toBe("1 item");
  expect(i18n.t("items", { count: 5 })).toBe("5 items");
  expect(i18n.has("menu.play")).toBe(true);
  expect(i18n.has("nope")).toBe(false);
  expect(i18n.t("nope")).toBe("nope"); // never throws: the key shows where a string is missing
  i18n.setLanguage("es");
  expect(i18n.t("greeting", { name: "Ana" })).toBe("¡Hola, Ana!");
  expect(i18n.t("items", { count: 1 })).toBe("1 objeto");
  i18n.setLanguage("pt_br");
  expect(i18n.language).toBe("pt-BR");
  expect(i18n.t("menu.play")).toBe("Jogar");
  expect(i18n.t("only_en")).toBe("Only English"); // pt-BR lacks it: the default language answers
  i18n.setLanguage("es-MX"); // close enough to "es"
  expect(i18n.language).toBe("es");
  i18n.setLanguage("en");
});

test("wrong calls teach", () => {
  expect(() => i18n.t(5)).toThrow("key must be a string");
  expect(() => i18n.t("items", 3)).toThrow("args must be an object");
  expect(() => i18n.setLanguage("ess")).toThrow("Unknown language 'ess'");
  expect(() => i18n.setLanguage("ess")).toThrow("es");
  expect(i18n.language).toBe("en"); // nothing changed
  expect(() => i18n.on("chnge", () => {})).toThrow('did you mean "change"');
  expect(() => i18n.on("change")).toThrow("expects a function");
});
)js");
    // The first file ends in Spanish; the second still starts in the default language.
    h.file("tests/a_leaves_spanish.test.js", R"(
import { test, expect } from "factoria:test";
import { i18n } from "factoria";
test("leave the game in Spanish", () => { i18n.setLanguage("es"); expect(i18n.language).toBe("es"); });
)");
    h.file("tests/b_starts_in_default.test.js", R"(
import { test, expect, game } from "factoria:test";
import { i18n } from "factoria";
test("a test file starts in the default language, with the scene translated", () => {
  expect(i18n.language).toBe("en");
  expect(game.find("play").get("Button").text).toBe("Play");
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/read.test.js", "tests/a_leaves_spanish.test.js", "tests/b_starts_in_default.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 5);
}

TEST_CASE("i18n api: setLanguage rewrites Text and widgets with a key at once and sends the change event") {
    TestHost h("i18n_switch", settings());
    write_tables(h);
    h.file("tests/switch.test.js", R"(
import { test, expect, game } from "factoria:test";
import { i18n, world } from "factoria";

test("the scene is translated when it loads, an entity without a key is left alone", () => {
  expect(game.find("title").get("Text").text).toBe("My Game");
  expect(game.find("play").get("Button").text).toBe("Play");
  expect(game.find("plain").get("Text").text).toBe("no key");
});

test("setLanguage updates every keyed component immediately and tells the listeners", () => {
  const seen = [];
  const off = i18n.on("change", (e) => seen.push(e.previous + ">" + e.language));
  i18n.setLanguage("es");
  expect(game.find("title").get("Text").text).toBe("Mi juego");
  expect(game.find("play").get("Button").text).toBe("Jugar");
  expect(game.find("plain").get("Text").text).toBe("no key");
  game.step(1); // the event is delivered with the frame
  expect(seen).toEqual(["en>es"]);
  i18n.setLanguage("es"); // already there: nothing happens
  game.step(1);
  expect(seen.length).toBe(1);
  off();
  i18n.setLanguage("en");
  game.step(1);
  expect(seen.length).toBe(1); // stopped listening
  expect(game.find("play").get("Button").text).toBe("Play");
});

test("a Text edited by a script is translated again at the end of the frame", () => {
  const title = game.find("title");
  title.get("Text").text = "edited";
  game.step(1);
  expect(title.get("Text").text).toBe("My Game");
});

test("an entity a script spawns is translated before the script's next line", () => {
  i18n.setLanguage("es");
  const e = world.spawn({ name: "late", components: { Button: { text: "x", key: "menu.play" } } });
  expect(e.get("Button").text).toBe("Jugar");
  i18n.setLanguage("en");
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/switch.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 4);
}

TEST_CASE("i18n api: a game without a localization section has no languages, t returns the key and setLanguage explains") {
    TestHost h("i18n_off");
    h.file("tests/off.test.js", R"(
import { test, expect } from "factoria:test";
import { i18n } from "factoria";

test("off", () => {
  expect(i18n.languages).toEqual([]);
  expect(i18n.language).toBe("");
  expect(i18n.defaultLanguage).toBe("");
  expect(i18n.t("menu.play")).toBe("menu.play");
  expect(i18n.has("menu.play")).toBe(false);
  expect(() => i18n.setLanguage("es")).toThrow("Localization is off");
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/off.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 1);
}

TEST_CASE("i18n api: a script sets keyArgs once and the label follows the args and the language") {
    TestHost h("i18n_keyargs", settings());
    write_tables(h);
    h.file("scenes/main.scene.json", R"({ "format": "factoria.scene/1", "entities": [
      { "id": "score", "components": { "Text": { "text": "Score: 0", "key": "hud.score", "keyArgs": { "score": 0 }, "space": "screen" } } },
      { "id": "pad", "components": { "TouchButton": { "text": "x", "key": "menu.play" } } } ] })");
    h.file("tests/keyargs.test.js", R"js(
import { test, expect, game } from "factoria:test";
import { i18n, world } from "factoria";

test("keyArgs set from a script are formatted by the end of the frame and survive a language switch", () => {
  const label = game.find("score");
  expect(label.get("Text").text).toBe("Score: 0");
  label.get("Text").keyArgs = { score: 41 };
  game.step(1);
  expect(label.get("Text").text).toBe("Score: 41");
  i18n.setLanguage("es");
  expect(label.get("Text").text).toBe("Puntos: 41");
  expect(label.get("Text").keyArgs.score).toBe(41);
  label.set("Text", { keyArgs: { score: 42 } });
  game.step(1);
  expect(label.get("Text").text).toBe("Puntos: 42");
  i18n.setLanguage("en");
  expect(label.get("Text").text).toBe("Score: 42");
});

test("a TouchButton with a key follows the language, and a spawned label takes its keyArgs at once", () => {
  expect(game.find("pad").get("TouchButton").text).toBe("Play");
  i18n.setLanguage("es");
  expect(game.find("pad").get("TouchButton").text).toBe("Jugar");
  const e = world.spawn({ name: "late", components: { Text: { text: "x", key: "hud.score", keyArgs: { score: 7 } } } });
  expect(e.get("Text").text).toBe("Puntos: 7");
  i18n.setLanguage("en");
});
)js");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/keyargs.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 2);
}

TEST_CASE("i18n api: number and duration follow the language, and {v:number:1} / {t:duration} do the same in a key") {
    TestHost h("i18n_numbers", Json::parse(R"({ "localization": { "defaultLanguage": "en", "languages": ["en", "es", "de", "fr", "ar", "xx"] } })"));
    h.file("locales/en.json", R"json({ "best": "Best: {t:duration} ({v:number:1} m, {n:number})" })json");
    for (const char* lang : {"es", "fr", "ar", "xx"}) h.file(std::string("locales/") + lang + ".json", R"({ "x": "x" })");
    h.file("locales/de.json", R"json({ "best": "Beste: {t:duration} ({v:number:1} m)" })json");
    h.file("tests/numbers.test.js", R"js(
import { test, expect } from "factoria:test";
import { i18n } from "factoria";

test("1234.5 in English, Spanish, German, French and Arabic", () => {
  expect(i18n.number(1234.5)).toBe("1,234.5");
  i18n.setLanguage("es");
  expect(i18n.number(1234.5)).toBe("1234,5");
  expect(i18n.number(12345.5)).toBe("12.345,5");
  i18n.setLanguage("de");
  expect(i18n.number(1234.5)).toBe("1.234,5");
  i18n.setLanguage("fr");
  expect(i18n.number(1234.5)).toBe("1 234,5");
  i18n.setLanguage("ar");
  expect(i18n.number(1234.5)).toBe("١٬٢٣٤٫٥");
  i18n.setLanguage("xx");
  expect(i18n.number(1234.5)).toBe("1,234.5"); // unknown language: English
  i18n.setLanguage("en");
});

test("decimals", () => {
  expect(i18n.number(2, { decimals: 2 })).toBe("2.00");
  expect(i18n.number(1234.567, { decimals: 1 })).toBe("1,234.6");
  expect(i18n.number(-0.04, { decimals: 1 })).toBe("0.0");
  expect(i18n.number(1000000, { decimals: 0 })).toBe("1,000,000");
  expect(() => i18n.number("3")).toThrow("must be a number");
  expect(() => i18n.number(3, { decimals: 12 })).toThrow("0 to 9");
  expect(() => i18n.duration(3, { decimals: 5 })).toThrow("0 to 3");
});

test("a time of 83.4 seconds", () => {
  expect(i18n.duration(83.4)).toBe("1:23.4");
  expect(i18n.duration(83.4, { decimals: 0 })).toBe("1:23");
  expect(i18n.duration(59.96)).toBe("1:00.0");
  expect(i18n.duration(3723.4)).toBe("1:02:03.4");
  expect(i18n.duration(5)).toBe("0:05.0");
  i18n.setLanguage("es");
  expect(i18n.duration(83.4)).toBe("1:23,4");
  i18n.setLanguage("ar");
  expect(i18n.duration(83.4)).toBe("١:٢٣٫٤");
  i18n.setLanguage("en");
});

test("placeholders in a key", () => {
  expect(i18n.t("best", { t: 83.4, v: 1234.56, n: 1234.5 })).toBe("Best: 1:23.4 (1,234.6 m, 1,234.5)");
  i18n.setLanguage("de");
  expect(i18n.t("best", { t: 83.4, v: 1234.56, n: 1234.5 })).toBe("Beste: 1:23,4 (1.234,6 m)");
  i18n.setLanguage("en");
});
)js");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/numbers.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 4);
}
