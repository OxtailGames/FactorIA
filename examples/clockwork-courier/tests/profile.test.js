// P3: the name screen (scenes/profile.scene.json): typing on a keyboard, the on-screen keyboard of the menu kit with a
// gamepad, the name limit, an empty name, renaming, and where Done and Back lead.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { scene, session, storage, ui } from "factoria";
import * as progress from "../scripts/progress.js";
import { NAME_MAX } from "../scripts/save_data.js";

const SELECT = "scenes/level_select.scene.json";
const text = () => game.find("profile_field").get("TextField").text;
const keyboardOpen = () => game.find("keyboard").active;
const focusedId = () => ui.focused?.id ?? null;
/** The pad opens the on-screen keyboard: A on the focused field. */
function openKeyboard(pad) {
  pad.tap("A");
  game.step(2);
  expect(keyboardOpen()).toBe(true);
}
/** Walks the focus with the d-pad to the widget `id`: down to the bottom row first, then sideways. */
function walkTo(pad, id) {
  const bottom = ["osk_shift", "osk_space", "osk_delete", "osk_done"];
  for (let i = 0; i < 12 && !bottom.includes(focusedId()); i++) {
    pad.tap("DpadDown");
    game.step(1);
  }
  for (let i = 0; i < 6 && focusedId() !== id; i++) {
    pad.tap("DpadRight");
    game.step(1);
  }
  expect(focusedId()).toBe(id);
}

function open(returnTo = SELECT) {
  session.profileReturn = returnTo;
  game.load("scenes/profile.scene.json");
  game.step(5);
}

describe("name screen", () => {
  beforeEach(() => {
    game.setStorageText(null);
    storage.remove("progress");
    session.nextScene = null;
  });

  test("the screen has the text field, the Done and Back buttons and the on-screen keyboard (closed)", () => {
    open();
    expect(game.find("profile_field")).not.toBeNull();
    expect(game.find("profile_ok")).not.toBeNull();
    expect(game.find("profile_back")).not.toBeNull();
    expect(game.find("keyboard_host")).not.toBeNull();
    expect(keyboardOpen()).toBe(false); // a player with a keyboard or a mouse never sees it
    expect(game.find("profile_field").get("TextField").focused).toBe(true); // the keyboard types at once
  });

  test("keyboard: typing fills the field and Enter saves the name and goes to the level select", () => {
    open();
    game.typeText("Ana");
    game.step(2);
    expect(text()).toBe("Ana");
    game.keyDown("Return");
    game.step(1);
    game.keyUp("Return");
    game.step(3);
    expect(progress.name()).toBe("Ana");
    expect(scene.current).toBe(SELECT);
  });

  test("gamepad: A opens the on-screen keyboard, A types, Delete removes, Done saves", () => {
    open();
    const pad = game.gamepad(0);
    openKeyboard(pad);
    pad.tap("A"); // the first key, "a"
    game.step(1);
    pad.tap("DpadRight");
    game.step(1);
    pad.tap("A"); // "b"
    game.step(1);
    pad.tap("DpadRight");
    game.step(1);
    pad.tap("A"); // "c"
    game.step(1);
    expect(text()).toBe("abc");
    walkTo(pad, "osk_delete");
    pad.tap("A");
    game.step(1);
    expect(text()).toBe("ab");
    game.screenshot(".factoria/tmp/profile_typed.png");
    walkTo(pad, "osk_done");
    pad.tap("A");
    game.step(3);
    expect(progress.name()).toBe("ab");
    expect(scene.current).toBe(SELECT);
  });

  test("gamepad: B closes the on-screen keyboard and keeps the screen; a second B goes back", () => {
    progress.setName("Ana");
    open();
    const pad = game.gamepad(0);
    openKeyboard(pad);
    pad.tap("B");
    game.step(3);
    expect(keyboardOpen()).toBe(false);
    expect(scene.current).toBe("scenes/profile.scene.json");
    expect(text()).toBe("Ana");
    pad.tap("B");
    game.step(3);
    expect(scene.current).toBe(SELECT);
  });

  test("the name is cut at the limit", () => {
    open();
    game.typeText("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
    game.step(2);
    expect(text().length).toBeLessThanOrEqual(NAME_MAX);
    const pad = game.gamepad(0);
    openKeyboard(pad);
    pad.tap("A");
    game.step(1);
    expect(text().length).toBeLessThanOrEqual(NAME_MAX); // the keyboard types nothing past maxLength
  });

  test("an empty name is refused with a hint and nothing is saved", () => {
    open();
    game.typeText("   ");
    game.step(1);
    game.touch("profile_ok");
    game.step(3);
    expect(scene.current).toBe("scenes/profile.scene.json");
    expect(game.find("profile_error").get("Text").text).toContain("at least one");
    expect(progress.hasName()).toBe(false);
  });

  test("renaming starts from the current name and returns where it came from", () => {
    progress.setName("Ana");
    open();
    expect(text()).toBe("Ana");
    game.keyDown("Backspace");
    game.step(1);
    game.keyUp("Backspace");
    game.step(1);
    game.keyDown("Backspace");
    game.step(1);
    game.keyUp("Backspace");
    game.step(1);
    game.keyDown("Backspace");
    game.step(1);
    game.keyUp("Backspace");
    game.step(1);
    game.typeText("B");
    game.step(1);
    game.touch("profile_ok");
    game.step(3);
    expect(progress.name()).toBe("B");
    expect(scene.current).toBe(SELECT);
  });

  test("Back without a name goes to the title; with a name it goes back without changing it", () => {
    open();
    game.touch("profile_back");
    game.step(3);
    expect(scene.current).toBe("scenes/main.scene.json");
    progress.setName("Ana");
    open();
    game.typeText("zz");
    game.step(2);
    game.touch("profile_back");
    game.step(3);
    expect(scene.current).toBe(SELECT);
    expect(progress.name()).toBe("Ana");
  });

  test("the name shows on the HUD of a level", () => {
    progress.setName("Ana");
    game.load("scenes/rooftops_1.scene.json");
    game.step(5);
    expect(game.find("name_text").get("Text").text).toBe("Ana");
  });
});
