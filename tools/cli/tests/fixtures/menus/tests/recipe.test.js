import { test, expect, game } from "factoria:test";
import { ui, storage } from "factoria";

// Each test file starts on the project's mainScene (the main menu) with empty storage.
test("gamepad only: main menu -> options -> music volume -> back, and the volume is saved", () => {
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
  expect(storage.get("settings").volume.music).toBeCloseTo(0.7);
});
