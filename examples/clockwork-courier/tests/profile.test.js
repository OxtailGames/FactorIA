// P3: the name screen (scenes/profile.scene.json): typing on a keyboard, the on-screen letter grid with a gamepad and with
// touch, the name limit, an empty name, renaming, and where Done and Back lead.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { scene, session, storage } from "factoria";
import * as progress from "../scripts/progress.js";
import { KEY_CHARS } from "../scripts/profile.js";
import { NAME_MAX } from "../scripts/save_data.js";

const SELECT = "scenes/level_select.scene.json";
const text = () => game.find("profile_field").get("TextField").text;

const WIDGETS = [...Array.from(KEY_CHARS, (c) => "key_" + c), "key_space", "key_back", "profile_ok", "profile_back"];
/** Id of the focused button of the screen, "profile_field" for the text field, or null. */
function focused() {
  if (game.find("profile_field").get("TextField").focused) return "profile_field";
  return WIDGETS.find((id) => game.find(id)?.get("Button").focused) ?? null;
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

  test("the screen has the text field, every letter and digit, and the editing keys", () => {
    open();
    expect(game.find("profile_field")).not.toBeNull();
    for (const id of WIDGETS) expect(game.find(id)).not.toBeNull();
    expect(focused()).toBe("profile_field"); // the keyboard types at once
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

  test("touch: the on-screen keys type, Delete removes the last character, Done saves", () => {
    open();
    for (const c of "ZOE") game.touch("key_" + c);
    game.step(1);
    expect(text()).toBe("ZOE");
    game.touch("key_back");
    game.step(1);
    expect(text()).toBe("ZO");
    game.touch("key_space");
    game.touch("key_7");
    game.step(1);
    expect(text()).toBe("ZO 7");
    game.screenshot(".factoria/tmp/profile_typed.png");
    game.touch("profile_ok");
    game.step(3);
    expect(progress.name()).toBe("ZO 7");
    expect(scene.current).toBe(SELECT);
  });

  test("gamepad: the d-pad walks the letter grid, A types a letter, Done saves", () => {
    open();
    const pad = game.gamepad(0);
    pad.tap("DpadDown");
    game.step(1);
    const first = focused();
    expect(first).toMatch(/^key_[A-Z0-9]$/);
    pad.tap("A");
    game.step(1);
    expect(text()).toBe(first.slice(4));
    pad.tap("DpadRight");
    game.step(1);
    const second = focused();
    expect(second).not.toBe(first);
    pad.tap("A");
    game.step(1);
    expect(text()).toBe(first.slice(4) + second.slice(4));
    // down through the grid to the row of editing keys, right to Done
    for (let i = 0; i < 6 && !["key_space", "key_back", "profile_ok", "profile_back"].includes(focused()); i++) {
      pad.tap("DpadDown");
      game.step(1);
    }
    for (let i = 0; i < 4 && focused() !== "profile_ok"; i++) {
      pad.tap("DpadRight");
      game.step(1);
    }
    expect(focused()).toBe("profile_ok");
    pad.tap("A");
    game.step(3);
    expect(progress.name()).toBe(first.slice(4) + second.slice(4));
    expect(scene.current).toBe(SELECT);
  });

  test("the name is cut at the limit", () => {
    open();
    game.typeText("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
    game.step(2);
    expect(text().length).toBeLessThanOrEqual(NAME_MAX);
    for (const c of "XYZ") game.touch("key_" + c);
    game.step(1);
    expect(text().length).toBe(NAME_MAX);
  });

  test("an empty name is refused with a hint and nothing is saved", () => {
    open();
    game.touch("key_space");
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
    game.touch("key_back");
    game.touch("key_back");
    game.touch("key_back");
    game.touch("key_B");
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
