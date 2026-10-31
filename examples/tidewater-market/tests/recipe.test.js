// The test that ships with the menu kit (project.add_menu_kit): it opens the kit's main menu itself, so it passes whatever the
// game's mainScene is, and drives the menus with a gamepad only.
import { test, expect, game } from "factoria:test";
import { ui, storage, audio, scene, analytics } from "factoria";

// Each test file starts on the project's mainScene with empty storage.
test("gamepad only: main menu -> options -> music volume -> back, and the volume is saved", () => {
  if (analytics.configured) analytics.setConsent(true); // a game with analytics: the question of the first run is answered (tests/analytics_consent.test.js)
  scene.load("scenes/menu.scene.json");
  const pad = game.gamepad(0);
  game.step(2);
  pad.tap("DpadDown"); // Options
  pad.tap("A");
  pad.tap("DpadRight"); // the Audio tab
  pad.tap("A");
  pad.tap("DpadDown"); // Master
  pad.tap("DpadDown"); // Music
  pad.tap("DpadRight"); // 0.6 -> 0.7
  pad.tap("B"); // back to the main menu
  expect(ui.focused.id).toBe("options_button");
  expect(audio.getVolume("music")).toBeCloseTo(0.7);
  expect(storage.get("settings").volume.music).toBeCloseTo(0.7);
});
