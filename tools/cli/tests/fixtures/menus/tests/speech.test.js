import { test, expect, game } from "factoria:test";
import { ui, i18n, storage } from "factoria";

// Headless runs speak nothing: ui.speak records its lines, and game.spoken() returns them (cleared before each test).
const said = () => game.spoken().map((line) => line.text);

test("read menus aloud is off by default: moving the focus says nothing", () => {
  game.load("scenes/menu.scene.json"); // the tests of a file share the game: start from a fresh menu
  const pad = game.gamepad(0);
  game.step(2);
  pad.tap("DpadDown"); // Options
  pad.tap("DpadDown"); // Credits
  expect(ui.focused.id).toBe("credits_button");
  expect(game.spoken()).toEqual([]);
  expect(ui.speechAvailable).toBe(true);
});

test("turning the option on, then moving the focus through the menu, reads each widget in the current language", () => {
  game.load("scenes/menu.scene.json"); // the tests of a file share the game: start from a fresh menu
  const pad = game.gamepad(0);
  game.step(2);
  pad.tap("DpadDown"); // Options
  pad.tap("A");
  pad.tap("DpadRight"); // the Audio tab
  pad.tap("A");
  for (let i = 0; i < 5; i++) pad.tap("DpadDown"); // Master, Music, Effects, Interface, Read menus aloud
  expect(ui.focused.id).toBe("read_aloud");
  pad.tap("A"); // on: the label is said so the player hears that it works
  expect(storage.get("settings").readAloud).toBe(true);
  expect(said()).toEqual(["Read menus aloud"]);

  game.clearSpoken();
  pad.tap("DpadUp"); // Interface: label and value
  expect(said()).toEqual(["Interface, 100 percent"]);

  game.clearSpoken();
  pad.tap("B"); // back to the main menu: the Options button has the focus again
  expect(said()).toEqual(["Options"]);
  pad.tap("DpadDown");
  pad.tap("DpadDown");
  expect(said()).toEqual(["Options", "Credits", "Shop"]);
  expect(game.spoken().every((line) => line.interrupt && line.language === "en")).toBe(true);

  game.clearSpoken();
  i18n.setLanguage("es");
  pad.tap("DpadUp"); // from Shop up to Credits
  expect(said()).toEqual(["Créditos"]);
  expect(game.spoken()[0].language).toBe("es");
});

test("ui.speak: queueing, stopping and bad arguments", () => {
  ui.speak("one");
  ui.speak("two", { interrupt: false });
  ui.stopSpeaking();
  expect(game.spoken().map((l) => [l.text, l.interrupt])).toEqual([["one", true], ["two", false]]);
  game.clearSpoken();
  expect(game.spoken()).toEqual([]);
  expect(() => ui.speak(42)).toThrow("expects the text as a string");
  expect(() => ui.speak("x", { interrupt: "yes" })).toThrow("interrupt must be true");
});
