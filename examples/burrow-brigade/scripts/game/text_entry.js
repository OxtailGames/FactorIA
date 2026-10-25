// @ts-check
// Typing a short code (the title's seed-code panel) with a keyboard, a pad or a Steam Deck. The helper keeps what is typed clean and tells
// the player how to type; the TextField itself works the same everywhere (docs/PLATFORM.md, "Steam Deck keyboard"): a pad that focuses
// it gets Steam's own keyboard on a Deck, the menu kit's on-screen keyboard elsewhere (docs/MENUS.md), a phone its system keyboard.
//
//   normalize(text, opts?)        cleans a typed text: upper case, only the alphabet, cut at maxLength. Defaults: CODE_ALPHABET, 12.
//   bind(fieldId, opts)           keeps the TextField `fieldId` clean while it is typed into and calls opts.onChange(clean) on each
//                                 edit and opts.onSubmit(clean) on Enter. Returns the function that stops. Call it where the scene
//                                 starts (ui.on ends with the scene).
//   hint(action = "ui_submit")    the localized line that says how to start typing: { key, args, text, kind }.
//   focus(fieldId)                gives the field the focus (a pad player on a Deck then gets Steam's keyboard).
//
// CODE_ALPHABET leaves out 0 O 1 I, which look alike when read aloud or off a screen. P4's seed codes are not cleaned with it: they
// have their own alphabet, which keeps 0 and 1 and maps the look-alikes to them (seed_code.js, normalize and decode), so the title's
// code panel (ui/title_flow.js) only uses hint(); bind and normalize are for a field whose code uses CODE_ALPHABET.
import { ui, world, i18n } from "factoria";
import * as deck from "./deck.js";
import * as glyphs from "./glyphs.js";

export const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
export const DEFAULT_MAX = 12;

/**
 * @param {string} text
 * @param {{maxLength?: number, alphabet?: string}} [opts]
 */
export function normalize(text, opts = {}) {
  const alphabet = opts.alphabet ?? CODE_ALPHABET;
  const max = opts.maxLength ?? DEFAULT_MAX;
  let out = "";
  for (const ch of String(text ?? "").toUpperCase()) {
    if (alphabet.includes(ch)) out += ch;
    if (out.length >= max) break;
  }
  return out;
}

/**
 * @param {string} fieldId
 * @param {{maxLength?: number, alphabet?: string, onChange?: (code: string) => void, onSubmit?: (code: string) => void}} [opts]
 */
export function bind(fieldId, opts = {}) {
  const field = world.find(fieldId);
  if (!field || !field.has("TextField")) throw new Error(`text_entry.bind: '${fieldId}' is not a TextField entity in this scene.`);
  const offChange = ui.on("change", fieldId, (e) => {
    const clean = normalize(String(e.value ?? ""), opts);
    const tf = field.get("TextField");
    if (tf.text !== clean) tf.text = clean;
    opts.onChange?.(clean);
  });
  const offSubmit = ui.on("submit", fieldId, (e) => opts.onSubmit?.(normalize(String(e.value ?? ""), opts)));
  return () => {
    offChange();
    offSubmit();
  };
}

/** @param {string} fieldId */
export function focus(fieldId) {
  ui.focus(fieldId);
}

/**
 * @param {string} [action]  the action that starts typing on the focused field (the pad's A: "ui_submit")
 */
export function hint(action = "ui_submit") {
  const kind = deck.keyboardKind();
  if (kind === "keyboard" || kind === "touch") return { kind, key: "textEntry.keyboard", args: {}, text: i18n.t("textEntry.keyboard") };
  const key = deck.isDeck() ? "textEntry.deck" : "textEntry.pad";
  const args = { button: glyphs.promptText(action) };
  return { kind, key, args, text: i18n.t(key, args) };
}
