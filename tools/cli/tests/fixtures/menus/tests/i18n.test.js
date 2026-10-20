import { test, expect, game } from "factoria:test";
import { ui, input, storage, session, i18n, world, game as running } from "factoria";

// The localization acceptance test (docs/LOCALIZATION.md): the menus in two languages, switched at run time. Texts and widgets with a
// `key` follow the language; one without a key is left alone. Driven with gamepad presses like the other menu tests.
const pad = game.gamepad(0);
const focused = () => (ui.focused ? ui.focused.id : null);
const text = (id) => game.find(id).get("Text").text;
const button = (id) => game.find(id).get("Button").text;

// Each test starts in English with no saved settings that scripts/settings.js has not applied yet.
function load(path, saved) {
  storage.clear();
  if (saved) storage.set("settings", saved);
  delete session.settingsApplied;
  input.resetBindings();
  i18n.setLanguage("en");
  game.load(path);
  game.step(2);
}

// Main menu -> Options -> the Language tab, with the focus on the language button.
function openLanguageTab() {
  pad.tap("DpadDown");
  pad.tap("A"); // Options
  pad.tap("DpadRight");
  pad.tap("DpadRight");
  pad.tap("DpadRight");
  pad.tap("A"); // the Language tab
  pad.tap("DpadDown");
  expect(focused()).toBe("language");
}

test("the game declares its languages and starts in the default one", () => {
  load("scenes/menu.scene.json");
  expect(i18n.languages).toEqual(["en", "es", "ar"]);
  expect(i18n.defaultLanguage).toBe("en");
  expect(i18n.language).toBe("en");
  expect(i18n.name("es")).toBe("Español");
  expect(text("title")).toBe("My Game");
  expect(button("play")).toBe("Play");
  expect(button("options_button")).toBe("Options");
});

test("the Language tab switches every Text and widget that has a key, at once", () => {
  load("scenes/menu.scene.json");
  openLanguageTab();
  expect(button("language")).toBe("Language: English");
  // Not translated by the engine: no key. They must not change, whatever the language.
  const withoutKey = game.find("buy_gems").get("Button").text;
  const free = world.spawn({ components: { Text: { text: "No key here", space: "screen" } } });

  pad.tap("A"); // English -> Español
  expect(i18n.language).toBe("es");
  // Texts of the menu scene.
  expect(text("title")).toBe("Mi juego");
  expect(button("play")).toBe("Jugar");
  expect(button("options_button")).toBe("Opciones");
  expect(button("credits_button")).toBe("Créditos");
  expect(button("quit")).toBe("Salir");
  // Texts and widgets of the options prefab: Text, Button, Toggle and Slider.
  expect(text("Title")).toBe("Opciones");
  expect(button("tab_audio")).toBe("Audio");
  expect(button("tab_language")).toBe("Idioma");
  expect(game.find("fullscreen").get("Toggle").label).toBe("Pantalla completa");
  expect(game.find("master_volume").get("Slider").label).toBe("General");
  expect(game.find("music_volume").get("Slider").label).toBe("Música");
  expect(button("reset_controls")).toBe("Restablecer valores");
  expect(button("options_back")).toBe("Atrás");
  expect(text("video_note")).toContain("Los ajustes de vídeo");
  // Without a key: untouched.
  expect(game.find("buy_gems").get("Button").text).toBe(withoutKey);
  expect(free.get("Text").text).toBe("No key here");

  game.step(1); // the "change" event reaches the script, which writes its own texts again
  expect(button("language")).toBe("Idioma: Español");
  expect(button("frame_cap")).toBe("Límite de fotogramas: sin límite");
  expect(button("bind_jump")).toContain("Saltar:");

  pad.tap("A"); // Español -> العربية
  expect(i18n.language).toBe("ar");
  pad.tap("A"); // العربية -> English (it wraps around)
  expect(i18n.language).toBe("en");
  expect(text("title")).toBe("My Game");
  expect(button("options_back")).toBe("Back");
  game.step(1);
  expect(button("language")).toBe("Language: English");
  expect(button("bind_jump")).toContain("Jump:");
  expect(free.get("Text").text).toBe("No key here");
});

test("the choice is saved, and the next run starts with it", () => {
  load("scenes/menu.scene.json");
  openLanguageTab();
  pad.tap("A");
  expect(storage.get("settings").language).toBe("es");

  // A new run: the language is back to the one the game starts in until settings.js applies the saved choice.
  const saved = storage.get("settings");
  load("scenes/menu.scene.json", saved);
  expect(i18n.language).toBe("es");
  expect(text("title")).toBe("Mi juego");
  expect(button("play")).toBe("Jugar");
  openLanguageTab(); // the options script starts when the panel first opens, and reads the language then
  expect(button("language")).toBe("Idioma: Español");
});

test("Arabic reads right to left: i18n.direction, and the options tabs run right to left", () => {
  load("scenes/menu.scene.json");
  expect(i18n.direction).toBe("ltr");
  i18n.setLanguage("ar");
  expect(i18n.direction).toBe("rtl");
  pad.tap("DpadDown");
  pad.tap("A"); // Options
  game.step(2);
  expect(ui.rectOf("tab_video").x).toBeGreaterThan(ui.rectOf("tab_language").x);
  i18n.setLanguage("en");
  expect(i18n.direction).toBe("ltr");
  game.step(2);
  expect(ui.rectOf("tab_video").x).toBeLessThan(ui.rectOf("tab_language").x);
});

test("a saved language the game does not have any more is ignored", () => {
  load("scenes/menu.scene.json", { language: "xx" });
  expect(i18n.language).toBe("en");
  expect(button("play")).toBe("Play");
});

test("the pause menu and the credits follow the language", () => {
  load("scenes/level.scene.json");
  pad.tap("Start");
  expect(running.paused).toBe(true);
  expect(text("pause_title")).toBe("Paused");
  i18n.setLanguage("es"); // from a script: no Language tab needed
  expect(text("pause_title")).toBe("En pausa");
  expect(button("resume")).toBe("Reanudar");
  expect(button("to_main_menu")).toBe("Menú principal");
  i18n.setLanguage("en");
  expect(button("resume")).toBe("Resume");

  load("scenes/menu.scene.json");
  i18n.setLanguage("es");
  pad.tap("DpadDown");
  pad.tap("DpadDown");
  pad.tap("A"); // Credits, opened in Spanish
  const lines = game.find("credits_list").children.map((e) => e.get("Text").text);
  expect(lines).toContain("Hecho con FactorIA");
  expect(lines).toContain("Este juego usa el siguiente software:");
  i18n.setLanguage("en"); // changed while the panel is open: the spawned Texts have keys too
  const again = game.find("credits_list").children.map((e) => e.get("Text").text);
  expect(again).toContain("Made with FactorIA");
});

test("the shop's texts follow the language", () => {
  load("scenes/menu.scene.json");
  i18n.setLanguage("es");
  for (let i = 0; i < 3; i++) pad.tap("DpadDown"); // Options, Credits, Shop
  pad.tap("A");
  game.step(1);
  expect(game.find("shop").activeInHierarchy).toBe(true);
  expect(text("shop_title")).toBe("Tienda");
  expect(text("gems_label")).toBe("Gemas: 0"); // written by shop.js with i18n.t()
  expect(button("restore")).toBe("Restaurar compras");
  i18n.setLanguage("en");
  game.step(1); // the shop script rewrites its own line when the "change" event arrives
  expect(text("shop_title")).toBe("Shop");
  expect(text("gems_label")).toBe("Gems: 0");
});
