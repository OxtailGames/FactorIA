// @ts-check
// An on-screen keyboard for players with only a gamepad. Put this behaviour on one entity of every scene that has a
// TextField. When a TextField takes the focus because the player used the pad (input.lastDevice is "gamepad"), or when
// the player presses A on a focused TextField, the keyboard (prefabs/ui/keyboard.prefab.json) opens over the game: the
// d-pad walks the keys, A types one, "Delete" removes the last character, "Done" closes it and sends ui.submit for the
// field (what Enter does), B closes it and keeps the text. Typing goes through the same events a real keyboard sends
// (ui.change), so the game's code does not know the difference. Phones and keyboards use their own keyboard: the engine
// raises the phone's when a TextField gets the focus, and this one stays closed unless the last input was a pad. A
// platform that has a keyboard for pads (the Steam Deck, through a native plugin) shows its own: while
// input.platformKeyboard is true this one stays closed too.
//
// The keys follow the language (i18n.language): see LAYOUTS. A language whose script is not listed gets the Latin keys (Korean too: an on-screen keyboard cannot
// compose Hangul syllables, so a Korean pad player types Latin letters or uses the system keyboard; ENGINE_FEEDBACK FB-0905).
import { Behaviour, ui, input, world, i18n } from "factoria";

/** Lowercase letters of each script, then the digits are added. A game can add its own: LAYOUTS.ja = "...". */
export const LAYOUTS = {
  latin: "abcdefghijklmnopqrstuvwxyz",
  cyrillic: "абвгдежзийклмнопрстуфхцчшщъыьэюя",
  greek: "αβγδεζηθικλμνξοπρστυφχψω",
  hebrew: "אבגדהוזחטיכךלמםנןסעפףצץקרשת",
};
/** Language code -> script of LAYOUTS (languages not listed use "latin"). */
export const SCRIPT_OF = { ru: "cyrillic", uk: "cyrillic", bg: "cyrillic", sr: "cyrillic", mk: "cyrillic", el: "greek", he: "hebrew", iw: "hebrew" };
/** Extra letters a Latin language needs, after the digits. */
export const EXTRA = {
  es: "ñáéíóúü", fr: "àâçèéêëîïôùûœ", de: "äöüß", pt: "ãõçáéíóúâê", it: "àèéìòù", pl: "ąćęłńóśźż",
  tr: "çğıişöü", sv: "åäö", da: "åæø", nb: "åæø", no: "åæø", cs: "áčďéěíňóřšťúůýž",
};
const DIGITS = "0123456789";

/** The characters of the keyboard for a language such as "es" or "pt-BR". */
export function keysFor(language) {
  const base = String(language || "en").toLowerCase().split(/[-_]/)[0];
  const script = SCRIPT_OF[base] ?? "latin";
  return Array.from(LAYOUTS[script] + DIGITS + (script === "latin" ? (EXTRA[base] ?? "") : ""));
}

export default class OnScreenKeyboard extends Behaviour {
  runWhilePaused = true;

  /** True while a keyboard is open: a game's own ui.cancel handler should do nothing then (B closes the keyboard). */
  static isOpen = false;

  onStart() {
    OnScreenKeyboard.isOpen = false;
    input.textInputMode = false;
    this.panel = world.spawnPrefab("prefabs/ui/keyboard.prefab.json");
    this.panel.id = "keyboard";
    this.panel.active = false;
    this.field = null; // the TextField being edited while the keyboard is open
    this.shift = false;
    this.built = ""; // the characters of the keys that exist now
    this.lastKey = null;
    this.ignore = null; // the field that just got the focus back from us: it must not reopen the keyboard
    this.ignoreAge = 0;
    ui.on("focus", (e) => this.onFocus(e.entity));
    ui.on("click", (e) => e.entity.hasTag("osk") && this.onClick(e.entity));
    ui.on("cancel", () => {
      if (!this.field) return false;
      this.close(false);
      return true; // B / Escape closed the keyboard: nothing else acts on this press (ui_cancel is consumed)
    });
  }

  onDestroy() {
    OnScreenKeyboard.isOpen = false;
  }

  onUpdate() {
    if (this.ignore && ++this.ignoreAge > 2) this.ignore = null;
    if (this.field) {
      if (!this.field.alive || !this.field.activeInHierarchy) return this.close(false);
      // Somebody picked up a keyboard or touched the screen: the field takes their typing, the pad keyboard goes away.
      if (input.lastDevice === "keyboard" || input.lastDevice === "touch") this.close(false);
      return;
    }
    // A on a focused field opens the keyboard again after B closed it.
    const f = ui.focused;
    if (!this.ignore && f && f.has("TextField") && input.lastDevice === "gamepad" && !input.platformKeyboard && input.pressed("ui_submit"))
      this.open(f);
  }

  onFocus(entity) {
    if (this.field) {
      // The d-pad left the keys (the widgets behind the keyboard are still focusable): bring the focus back.
      if (!entity.hasTag("osk") && this.lastKey?.alive) ui.focus(this.lastKey);
      else if (entity.hasTag("osk")) this.lastKey = entity;
      return;
    }
    if (this.ignore === entity.id) return; // the focus we gave back ourselves (onUpdate forgets it two frames later)
    if (entity.has("TextField") && input.lastDevice === "gamepad" && !input.platformKeyboard) this.open(entity);
  }

  open(field) {
    this.field = field;
    this.shift = false;
    OnScreenKeyboard.isOpen = true;
    input.textInputMode = true; // the typed keys belong to the keyboard: game actions on letters read as up meanwhile
    this.build(keysFor(i18n.language));
    this.holdOthers();
    this.panel.active = true;
    this.showText();
    ui.layout();
    const first = world.find("osk_key_0");
    this.lastKey = first;
    ui.focus(first);
  }

  /** Closes the keyboard and gives the focus back to the field. done = the player pressed "Done": send ui.submit. */
  close(done) {
    const field = this.field;
    this.field = null;
    OnScreenKeyboard.isOpen = false;
    this.panel.active = false;
    this.releaseOthers();
    if (!field?.alive) return;
    this.ignore = field.id;
    this.ignoreAge = 0;
    if (field.activeInHierarchy && input.lastDevice === "gamepad") ui.focus(field);
    else this.ignore = null;
    if (done) world.emit("ui.submit", { id: field.id, value: field.get("TextField").text }, field);
  }

  /**
   * The d-pad picks the nearest widget in its direction, and the menu behind the keyboard has widgets too: while the
   * keyboard is open they stop taking focus (interactable = false), and close() gives them back.
   */
  holdOthers() {
    this.held = [];
    for (const e of world.entities()) {
      if (e.hasTag("osk") || !e.activeInHierarchy) continue;
      for (const kind of ["Button", "Toggle", "Slider", "TextField"]) {
        if (!e.has(kind) || !e.get(kind).interactable) continue;
        e.get(kind).interactable = false;
        this.held.push([e, kind]);
      }
    }
  }

  releaseOthers() {
    for (const [e, kind] of this.held ?? []) if (e.alive) e.get(kind).interactable = true;
    this.held = [];
  }

  /** Makes one Button per character (not again when the characters are the same as last time). */
  build(chars) {
    const key = chars.join("");
    if (key === this.built) {
      this.relabel();
      return;
    }
    const grid = world.find("keyboard_keys");
    for (const child of grid.children) child.destroy();
    chars.forEach((ch, i) => {
      world.spawn(
        { id: "osk_key_" + i, tags: ["osk"], components: { Button: { size: [64, 56], text: ch, layer: 402, fontSize: 28, color: [0.24, 0.27, 0.36, 0.95] } } },
        { parent: grid },
      );
    });
    this.built = key;
    this.base = chars;
    this.relabel();
  }

  /** Letters in upper case while shift is on. A letter with no upper-case form of one character (the German ß) stays. */
  relabel() {
    this.base.forEach((ch, i) => {
      const up = ch.toUpperCase();
      world.find("osk_key_" + i).get("Button").text = this.shift && Array.from(up).length === 1 ? up : ch;
    });
  }

  onClick(entity) {
    if (!this.field) return;
    const text = this.field.get("TextField").text;
    switch (entity.id) {
      case "osk_done": return this.close(true);
      case "osk_space": return this.type(" ");
      case "osk_delete": return this.set(Array.from(text).slice(0, -1).join(""));
      case "osk_shift":
        this.shift = !this.shift;
        return this.relabel();
      default:
        if (entity.id.startsWith("osk_key_")) this.type(entity.get("Button").text);
    }
  }

  /** Adds one character, within the field's maxLength. */
  type(ch) {
    const f = this.field.get("TextField");
    if (f.maxLength > 0 && Array.from(f.text).length >= f.maxLength) return;
    this.set(f.text + ch);
  }

  /** Writes the field's text and sends ui.change, as a real keyboard's typing does. */
  set(text) {
    this.field.get("TextField").text = text;
    world.emit("ui.change", { id: this.field.id, value: text }, this.field);
    this.showText();
  }

  showText() {
    world.find("keyboard_preview").get("Text").text = this.field.get("TextField").text + "_";
  }
}
