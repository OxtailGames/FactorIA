// @ts-check
// Button prompts that match the player's controller. `prompt("dig")` says what to show for an action right now: the picture and
// the text of the pad's button when the last input came from a pad (Xbox, PlayStation, Switch or Steam Deck art), the key or the
// mouse button otherwise (text only). The pictures are assets/glyphs/<family>/<slug>.png (assets/src/make_online_art.py).
//
//   family(pad = 0)                  "xbox" | "playstation" | "nintendo" | "steamdeck" (a generic pad uses the Xbox art)
//   glyph(binding, pad = 0)          { family, label, icon } for a pad binding such as "GamepadA"; icon is null for what has no
//                                    picture (the d-pad, the sticks)
//   prompt(action, pad = 0, device?) { device, binding, label, icon, family } for an action; device defaults to input.lastDevice
//   promptText(action, pad = 0)      the label only, e.g. "Cross", "A", "Space"
//
// Labels come from input.buttonName(); SLUGS maps each family's labels to the picture files (the Deck says L1 R1 L2 R2 and
// Menu/View, like the device prints them).
import { input } from "factoria";

export const FAMILIES = Object.freeze(["xbox", "playstation", "nintendo", "steamdeck"]);

/** The file name of each button's picture, by family and by the label input.buttonName() gives. */
export const SLUGS = Object.freeze({
  xbox: { A: "a", B: "b", X: "x", Y: "y", LB: "lb", RB: "rb", LT: "lt", RT: "rt", Menu: "menu", View: "view" },
  steamdeck: { A: "a", B: "b", X: "x", Y: "y", L1: "l1", R1: "r1", L2: "l2", R2: "r2", Menu: "menu", View: "view" },
  playstation: { Cross: "cross", Circle: "circle", Square: "square", Triangle: "triangle", L1: "l1", R1: "r1", L2: "l2", R2: "r2", Options: "options", Create: "create" },
  nintendo: { B: "b", A: "a", Y: "y", X: "x", L: "l", R: "r", ZL: "zl", ZR: "zr", "+": "plus", "-": "minus" },
});

/** @param {number} [pad] @returns {"xbox"|"playstation"|"nintendo"|"steamdeck"} */
export function family(pad = 0) {
  const t = input.gamepad(pad).type;
  return t === "generic" ? "xbox" : t;
}

/**
 * The picture and the label of a pad binding on a pad.
 * @param {string} binding  "GamepadA", "GamepadStart"...
 * @param {number} [pad]
 */
export function glyph(binding, pad = 0) {
  const fam = family(pad);
  const label = input.buttonName(binding, pad);
  const slug = /** @type {Record<string, string>} */ (SLUGS[fam])[label];
  return { family: fam, label, icon: slug ? `assets/glyphs/${fam}/${slug}.png` : null };
}

/**
 * What to show for an action now.
 * @param {string} action
 * @param {number} [pad]
 * @param {"keyboard"|"mouse"|"gamepad"|"touch"} [device]  default: input.lastDevice
 * @returns {{device: string, binding: string, label: string, icon: string|null, family: string|null}}
 */
export function prompt(action, pad = 0, device = /** @type {any} */ (input.lastDevice)) {
  const all = input.bindings(action);
  const padB = all.find((b) => b.startsWith("Gamepad"));
  const mouseB = all.find((b) => b.startsWith("Mouse"));
  const keyB = all.find((b) => !b.startsWith("Gamepad") && !b.startsWith("Mouse"));
  if (device === "gamepad" && padB) return { device, binding: padB, ...glyph(padB, pad) };
  const b = device === "mouse" ? mouseB ?? keyB : keyB ?? mouseB ?? padB;
  if (!b) return { device, binding: "", label: "", icon: null, family: null };
  if (b.startsWith("Gamepad")) return { device: "gamepad", binding: b, ...glyph(b, pad) };
  return { device: b.startsWith("Mouse") ? "mouse" : "keyboard", binding: b, label: input.buttonName(b, pad), icon: null, family: null };
}

export function promptText(action, pad = 0) {
  return prompt(action, pad).label;
}
