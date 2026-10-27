// @ts-check
// The names of keys and buttons in prompts ("[F] Open the door", "[A] Open the door", "[Tap] ..."), by device.
// The option "Prompt glyphs" (settings.glyphs) is "auto" (the device the player used last: input.lastDevice) or one of
// "keyboard", "gamepad", "touch", for a player who plays with a pad but wants the keys shown, or the reverse.
//
//   device()        "keyboard" | "mouse" | "gamepad" | "touch" the prompts are written for
//   label(action)   the key or button of `action` on that device, as the player's own bindings say (rebound keys included); "" when it has none
//   prompt(action)  label(), or "Click" for the mouse and "Tap" for touch: what the prompt line puts in the brackets
import { input, i18n } from "factoria";
import { load } from "./settings.js";

/** The device the prompts are written for. */
export function device() {
  const mode = load().glyphs;
  return mode === "auto" ? input.lastDevice : mode;
}

/** The key or pad button of `action` on the device in use (the first of the player's bindings of that kind). */
export function label(action) {
  const d = device();
  const names = input.bindings(action);
  if (d === "gamepad") {
    const pad = names.find((n) => n.startsWith("Gamepad"));
    return pad ? input.buttonName(pad, 0) : "";
  }
  const key = names.find((n) => !n.startsWith("Gamepad") && !n.startsWith("Mouse") && !n.startsWith("Touch"));
  return key ? input.buttonName(key) : "";
}

/** What a prompt puts in its brackets for `action`: "Click" with the mouse, "Tap" on a phone, else the key or button. */
export function prompt(action) {
  const d = device();
  if (d === "touch") return i18n.t("prompt.tap");
  if (d === "mouse") return i18n.t("prompt.click");
  return label(action);
}
