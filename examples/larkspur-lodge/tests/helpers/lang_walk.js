// The walk of P8 languages (tests/lang_<tag>.test.js, one file per language so each has its own glyph atlas, see ENGINE_FEEDBACK
// LL/FB-0901): a language walks the key screens at 100 % and 200 % text. Nothing may show a missing key or a placeholder,
// and a screenshot of each screen goes to .factoria/screenshots/lang/<lang>_<scale>_<screen>.png.
import { test, describe, expect, game } from "factoria:test";
import { scene, ui, i18n, storage, session } from "factoria";
import { enter, stand } from "./lodge.js";
import * as story from "../../scripts/story.js";
import * as items from "../../scripts/items.js";
import * as chapters from "../../scripts/chapters.js";
import * as cutscene from "../../scripts/cutscene.js";
import * as dialogue from "../../scripts/dialogue.js";
import * as saves from "../../scripts/saves.js";
import * as save_data from "../../scripts/save_data.js";
import * as progress from "../../scripts/progress.js";
import { MenuStack } from "../../scripts/ui/menu_stack.js";
import * as settings from "../../scripts/settings.js";
import locales from "./locales.js";

const TABS = ["video", "audio", "access", "controls", "language"];
const screens = () => game.find("screens").behaviour;
/** The picture of a screen, in .factoria/screenshots/lang/. */
function shot(lang, scale, name) {
  game.screenshot(`.factoria/screenshots/lang/${lang}_${scale * 100}_${name}.png`);
}

/** Every widget under `root` that is active: its text must not be a missing key or leftover placeholder, and must fit. */
function audit(root, where) {
  const bad = [];
  const walk = (e) => {
    if (!e.active) return;
    for (const comp of ["Text", "Button"]) {
      if (!e.has(comp)) continue;
      const t = e.get(comp).text ?? "";
      if (/^[a-z][A-Za-z0-9]*(\.[A-Za-z0-9_]+)+$/.test(t) || /\{[a-zA-Z]+\}/.test(t)) bad.push(`${e.id}: "${t}"`);
    }
    if (e.id && ui.overflowed(e)) bad.push(`${e.id} overflows`);
    e.children.forEach(walk);
  };
  walk(root);
  if (bad.length) throw new Error(`${where}: ${bad.join("; ")}`);
}

function clean(lang, scale) {
  game.resetState();
  MenuStack.busy = false;
  for (const id of saves.ALL) storage.remove(saves.key(id));
  for (const k of ["lastSlot", "saveCounter", "settings"]) storage.remove(k);
  progress.reset();
  story.reset();
  items.reset();
  save_data.resetAll();
  session.autosavedChapter = 0;
  i18n.setLanguage(lang);
  ui.textScale = scale;
}

export function walkLanguage(lang) {
  describe(`language ${lang}`, () => {
    test("every locale key used by the screens exists in this language", () => {
      const en = locales.en;
      const mine = locales[lang];
      const missing = Object.keys(en).filter((k) => !(k in mine));
      expect(missing).toEqual([]);
      const extra = Object.keys(mine).filter((k) => !(k in en));
      expect(extra).toEqual([]);
      // the engine answers for the keys the screens use, in this language
      i18n.setLanguage(lang);
      for (const k of ["menu.play", "options.tab.audio", "options.reducedMotion"]) {
        expect(i18n.has(k)).toBe(true);
        expect(i18n.t(k)).toBe(mine[k]);
      }
      for (const k of Object.keys(mine)) expect(String(mine[k]).trim().length).toBeGreaterThan(0);
    });

    for (const scale of [1, 2]) {
      test(`screens at text scale ${scale * 100} %`, () => {
        clean(lang, scale);
        // the title and the options tabs
        scene.load("scenes/menu.scene.json");
        game.step(5);
        shot(lang, scale, "title");
        game.click(game.find("options_button"));
        game.step(3);
        for (const tab of TABS) {
          game.click(game.find(`tab_${tab}`));
          game.step(3);
          audit(game.find(`${tab}_section`), `options ${tab}`);
          shot(lang, scale, `options_${tab}`);
        }
        // the notebook and the board
        enter("ground");
        game.step(200);
        for (const f of ["know_oil", "know_cellar", "adit_known", "know_page"]) story.set(f);
        screens().open("notebook");
        game.step(3);
        audit(screens().root, "notebook");
        shot(lang, scale, "notebook");
        screens().open("board");
        game.step(3);
        audit(screens().root, "board");
        shot(lang, scale, "board");
        for (const id of ["library_key", "lamp_oil", "torn_letter"]) items.add(id);
        screens().open("items");
        game.step(3);
        game.click(game.find(screens().id("item_torn_letter")));
        game.step(30);
        audit(screens().root, "items");
        shot(lang, scale, "items");
        screens().close();
        game.step(3);
        // the dialogue
        chapters.begin();
        game.load("scenes/ground.scene.json", { arrive: "spawn_default" });
        game.step(300);
        stand(15, 20.9, 0);
        dialogue.start("ch1_mara", { speaker: "npc_mara" });
        game.step(150);
        game.tapKey("Space");
        game.step(30);
        audit(game.find("dlg_box"), "dialogue");
        shot(lang, scale, "dialogue");
        dialogue.abort();
        game.step(30);
        // the save slots
        game.tap("pause");
        game.step(3);
        game.click(game.find("pause_load"));
        game.step(3);
        audit(game.find("slots_list"), "slots");
        shot(lang, scale, "slots");
      });
    }

    test("the language option switches the open screen live, and read-aloud speaks it", () => {
      clean("en", 1);
      scene.load("scenes/menu.scene.json");
      game.step(5);
      game.click(game.find("options_button"));
      game.step(3);
      game.click(game.find("tab_language"));
      game.step(3);
      for (let i = 0; i < 6 && i18n.language !== lang; i++) {
        game.click(game.find("language"));
        game.step(3);
      }
      expect(i18n.language).toBe(lang);
      expect(game.find("tab_audio").get("Button").text).toBe(locales[lang]["options.tab.audio"]);
      expect(game.find("language").get("Button").text).toBe(
        locales[lang]["options.language"].replace("{language}", i18n.name(lang)),
      );
      audit(game.find("language_section"), "options language, live");
      // read-aloud: the focused toggle is said in the language
      game.click(game.find("tab_access"));
      game.step(3);
      settings.save({ ...settings.load(), readAloud: true });
      game.step(2);
      game.clearSpoken();
      ui.focus("reduced_motion");
      game.step(2);
      const said = game.spoken().map((l) => l.text).join(" ");
      expect(said).toContain(locales[lang]["options.reducedMotion"]);
      expect(said).toContain(locales[lang]["options.off"]);
      settings.save({ ...settings.load(), readAloud: false });
    });

    test("a dialogue line that is open when the language changes is said again in it", () => {
      clean("en", 1);
      chapters.begin();
      game.load("scenes/ground.scene.json", { arrive: "spawn_default" });
      game.step(300);
      stand(15, 20.9, 0);
      dialogue.start("ch1_mara", { speaker: "npc_mara" });
      game.step(300);
      const said = () => game.find("dlg_text").get("Text").text.replace(/\s+/g, "");
      const before = said();
      expect(before.length).toBeGreaterThan(5);
      i18n.setLanguage(lang);
      game.step(3);
      if (lang !== "en") expect(said()).not.toBe(before);
      const mine = new Set(Object.values(locales[lang]).map((v) => String(v).replace(/\s+/g, "")));
      expect(mine.has(said())).toBe(true);
      expect(scene.current).toBe("scenes/ground.scene.json");
      dialogue.abort();
      game.step(10);
    });

    test("a cut-scene caption", () => {
      clean(lang, 1);
      chapters.begin();
      game.load("scenes/ground.scene.json", { arrive: "spawn_default" });
      game.step(10);
      expect(cutscene.play("intro").played).toBe(true);
      game.step(9 * 60);
      expect(game.captions().length).toBe(1);
      shot(lang, 1, "caption");
      ui.textScale = 2;
      game.step(2);
      shot(lang, 2, "caption");
      ui.textScale = 1;
      for (let i = 0; i < 4 && cutscene.active(); i++) {
        cutscene.skip();
        game.step(60);
      }
    });
  });
}
