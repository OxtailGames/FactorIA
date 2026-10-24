import { test, expect, game } from "factoria:test";
import { input, ui } from "factoria";
import { keysFor } from "../scripts/ui/keyboard.js";

// A player with only a gamepad types a name through the on-screen keyboard (scripts/ui/keyboard.js).
const pad = game.gamepad(0);
const field = () => game.find("name_field").get("TextField");
const open = () => game.find("keyboard").activeInHierarchy;

/** Walks the d-pad to the key that shows `ch` (the keys are a grid of 10 columns) and presses A. */
function typeKey(ch, chars) {
  const target = chars.indexOf(ch);
  const at = Number(ui.focused.id.slice("osk_key_".length));
  const dx = (target % 10) - (at % 10);
  const dy = Math.floor(target / 10) - Math.floor(at / 10);
  for (let i = 0; i < Math.abs(dx); i++) pad.tap(dx > 0 ? "DpadRight" : "DpadLeft");
  for (let i = 0; i < Math.abs(dy); i++) pad.tap(dy > 0 ? "DpadDown" : "DpadUp");
  expect(ui.focused.get("Button").text).toBe(ch);
  pad.tap("A");
}

/** Moves the focus from a key down to the row of Shift, Space, Delete and Done, then along it to `id`. */
function toAction(id) {
  for (let i = 0; i < 8 && ui.focused.id.startsWith("osk_key_"); i++) pad.tap("DpadDown");
  const order = ["osk_shift", "osk_space", "osk_delete", "osk_done"];
  for (let i = 0; i < 4 && ui.focused.id !== id; i++) pad.tap(order.indexOf(id) > order.indexOf(ui.focused.id) ? "DpadRight" : "DpadLeft");
  expect(ui.focused.id).toBe(id);
}

test("the keyboard stays closed until a pad is used, then types a name with the pad alone", () => {
  game.load("scenes/name.scene.json");
  game.step(2);
  expect(ui.focused.id).toBe("name_field"); // autoFocus at the start: the last input was not a pad
  expect(open()).toBe(false);
  pad.tap("DpadDown"); // to the button ...
  pad.tap("DpadUp"); // ... and back to the field with the pad: the keyboard opens
  expect(open()).toBe(true);
  expect(ui.focused.id).toBe("osk_key_0");

  const chars = keysFor("en");
  const changes = [];
  const stop = ui.on("change", "name_field", (e) => changes.push(e.value));
  pad.tap("A"); // "a", the first key
  typeKey("m", chars);
  pad.tap("A"); // another m
  toAction("osk_shift");
  pad.tap("A"); // upper case from now on
  pad.tap("DpadUp"); // back to the keys
  typeKey("Z", chars.map((c) => c.toUpperCase()));
  expect(field().text).toBe("ammZ");
  stop();
  expect(changes).toEqual(["a", "am", "amm", "ammZ"]);

  // Done closes the keyboard, sends ui.submit like Enter, and the focus goes back to the field without reopening it.
  const submitted = [];
  ui.on("submit", "name_field", (e) => submitted.push(e.value));
  toAction("osk_done");
  pad.tap("A");
  game.step(3);
  expect(submitted).toEqual(["ammZ"]);
  expect(open()).toBe(false);
  expect(ui.focused.id).toBe("name_field");
  expect(game.find("name_next").get("Button").interactable).toBe(true); // the menu behind the keyboard is back

  // A on the field opens it again; B closes it and keeps the text.
  pad.tap("A");
  expect(open()).toBe(true);
  pad.tap("B");
  expect(open()).toBe(false);
  expect(field().text).toBe("ammZ");
});

test("the keys follow the language and the field's maxLength", () => {
  expect(keysFor("es")).toContain("ñ");
  expect(keysFor("pt-BR")).toContain("ã");
  expect(keysFor("ru")[0]).toBe("а");
  expect(keysFor("el")[0]).toBe("α");
  expect(keysFor("ar")).toEqual(keysFor("en")); // a script with no keys of its own gets the Latin ones
  game.load("scenes/name.scene.json");
  game.step(2);
  field().text = "123456789012"; // maxLength 12: full
  pad.tap("DpadDown");
  pad.tap("DpadUp");
  pad.tap("A"); // "a" does not fit
  expect(field().text).toBe("123456789012");
});

test("a platform keyboard takes the field: the on-screen keyboard stays closed", () => {
  game.load("scenes/name.scene.json");
  game.step(2);
  // The engine sets input.platformKeyboard when a native plugin (the Steam Deck's) shows its own keyboard for the focused field.
  const engineGetter = Object.getOwnPropertyDescriptor(input, "platformKeyboard");
  Object.defineProperty(input, "platformKeyboard", { get: () => true, configurable: true });
  try {
    pad.tap("DpadDown");
    pad.tap("DpadUp"); // back to the field with the pad: the platform keyboard is up, this one is not
    expect(ui.focused.id).toBe("name_field");
    expect(open()).toBe(false);
    pad.tap("A"); // A on the field asks the platform again, not this keyboard
    expect(open()).toBe(false);
  } finally {
    Object.defineProperty(input, "platformKeyboard", engineGetter);
  }
});
