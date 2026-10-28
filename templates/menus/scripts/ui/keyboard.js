// @ts-check
// An on-screen keyboard for players with only a gamepad. Put this behaviour on one entity of every scene that has a
// TextField. When a TextField takes the focus because the player used the pad (input.lastDevice is "gamepad"), or when
// the player presses A on a focused TextField, the keyboard (prefabs/ui/keyboard.prefab.json) opens over the game: the
// d-pad walks the keys, A types one, "Delete" removes the last character (the last jamo of a Korean syllable), "Done" closes it and sends ui.submit for the
// field (what Enter does), B closes it and keeps the text. Typing goes through the same events a real keyboard sends
// (ui.change), so the game's code does not know the difference. Phones and keyboards use their own keyboard: the engine
// raises the phone's when a TextField gets the focus, and this one stays closed unless the last input was a pad. A
// platform that has a keyboard for pads (the Steam Deck, through a native plugin) shows its own: while
// input.platformKeyboard is true this one stays closed too.
//
// The keys follow the language (i18n.language): see LAYOUTS. A language whose script is not listed gets the Latin keys.
// A language whose letters are made of parts (Korean: jamo make syllables) has an input method in IME: a pair of functions
// that say what the text becomes when a key is typed and when Delete is pressed. Korean's is built in (hangulIme).
import { Behaviour, ui, input, world, i18n } from "factoria";

/** Lowercase letters of each script, then the digits are added. A game can add its own: LAYOUTS.ja = "...". */
export const LAYOUTS = {
  latin: "abcdefghijklmnopqrstuvwxyz",
  cyrillic: "абвгдежзийклмнопрстуфхцчшщъыьэюя",
  greek: "αβγδεζηθικλμνξοπρστυφχψω",
  // Hangul jamo (the two-set layout's letters): the consonants, then the vowels. Shift gives the doubled ones: SHIFTED.
  korean: "ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎㅏㅑㅓㅕㅗㅛㅜㅠㅡㅣㅐㅔ",
};
/** What Shift shows on a key whose upper case is not the letter's own (Hangul: the doubled consonants and vowels). */
export const SHIFTED = { "ㄱ": "ㄲ", "ㄷ": "ㄸ", "ㅂ": "ㅃ", "ㅅ": "ㅆ", "ㅈ": "ㅉ", "ㅐ": "ㅒ", "ㅔ": "ㅖ" };
/** Language code -> script of LAYOUTS (languages not listed use "latin"). */
export const SCRIPT_OF = { ru: "cyrillic", uk: "cyrillic", bg: "cyrillic", sr: "cyrillic", mk: "cyrillic", el: "greek", ko: "korean" };
/** Extra letters a Latin language needs, after the digits. */
export const EXTRA = {
  es: "ñáéíóúü", fr: "àâçèéêëîïôùûœ", de: "äöüß", pt: "ãõçáéíóúâê", it: "àèéìòù", pl: "ąćęłńóśźż",
  tr: "çğıişöü", sv: "åäö", da: "åæø", nb: "åæø", no: "åæø", cs: "áčďéěíňóřšťúůýž",
};
const DIGITS = "0123456789";

// ---- Input methods -------------------------------------------------------------------------------------------------
// An input method is { compose(text, ch) -> string, decompose(text) -> string }: compose returns the field's text after
// the key `ch` is typed (it may change the last character: a vowel after a consonant makes a syllable), decompose the
// text after Delete (it may take a part of the last character away instead of all of it). Both look only at the text,
// so they need no state. A game adds one for another language: IME.ja = { compose, decompose }.

const LEADS = "ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ";
const VOWELS = "ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ";
const TAILS = [
  "", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ",
  "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ",
];
const COMPOUND_VOWEL = { ㅗㅏ: "ㅘ", ㅗㅐ: "ㅙ", ㅗㅣ: "ㅚ", ㅜㅓ: "ㅝ", ㅜㅔ: "ㅞ", ㅜㅣ: "ㅟ", ㅡㅣ: "ㅢ" };
const COMPOUND_TAIL = {
  ㄱㅅ: "ㄳ", ㄴㅈ: "ㄵ", ㄴㅎ: "ㄶ", ㄹㄱ: "ㄺ", ㄹㅁ: "ㄻ", ㄹㅂ: "ㄼ", ㄹㅅ: "ㄽ", ㄹㅌ: "ㄾ", ㄹㅍ: "ㄿ", ㄹㅎ: "ㅀ", ㅂㅅ: "ㅄ",
};
const split = (table) => Object.fromEntries(Object.entries(table).map(([pair, whole]) => [whole, Array.from(pair)]));
const VOWEL_PARTS = split(COMPOUND_VOWEL);
const TAIL_PARTS = split(COMPOUND_TAIL);
const SYLLABLE_FIRST = 0xac00;
const SYLLABLE_LAST = 0xd7a3;
const isSyllable = (c) => !!c && c.codePointAt(0) >= SYLLABLE_FIRST && c.codePointAt(0) <= SYLLABLE_LAST;
const isVowel = (c) => !!c && VOWELS.includes(c);
const isConsonant = (c) => !!c && (LEADS.includes(c) || TAILS.includes(c));
const syllable = (lead, vowel, tail = "") =>
  String.fromCodePoint(SYLLABLE_FIRST + (LEADS.indexOf(lead) * VOWELS.length + VOWELS.indexOf(vowel)) * TAILS.length + TAILS.indexOf(tail));
/** [lead, vowel, tail] of a syllable character. */
function parts(c) {
  const n = c.codePointAt(0) - SYLLABLE_FIRST;
  return [LEADS[Math.floor(n / (VOWELS.length * TAILS.length))], VOWELS[Math.floor(n / TAILS.length) % VOWELS.length], TAILS[n % TAILS.length]];
}

/** Hangul: jamo make syllables (ㄱ + ㅏ = 가, 가 + ㄴ = 간, 간 + ㅏ = 가나), and Delete takes the last jamo away (간 -> 가 -> ㄱ). */
export const hangulIme = {
  compose(text, ch) {
    const chars = Array.from(text);
    const last = chars[chars.length - 1];
    const head = chars.slice(0, -1).join("");
    if (!isVowel(ch) && !isConsonant(ch)) return text + ch;
    if (isSyllable(last)) {
      const [lead, vowel, tail] = parts(last);
      if (isVowel(ch)) {
        if (tail === "") {
          const both = COMPOUND_VOWEL[vowel + ch];
          return both ? head + syllable(lead, both) : text + ch;
        }
        // The last consonant of the syllable starts the next one: 각 + ㅏ = 가가, 닭 + ㅏ = 달가.
        const pair = TAIL_PARTS[tail];
        const keep = pair ? pair[0] : "";
        const move = pair ? pair[1] : tail;
        return head + syllable(lead, vowel, keep) + syllable(move, ch);
      }
      if (tail === "") return TAILS.includes(ch) ? head + syllable(lead, vowel, ch) : text + ch;
      const both = COMPOUND_TAIL[tail + ch];
      return both ? head + syllable(lead, vowel, both) : text + ch;
    }
    if (isVowel(ch) && last && LEADS.includes(last)) return head + syllable(last, ch);
    return text + ch;
  },
  decompose(text) {
    const chars = Array.from(text);
    const last = chars.pop();
    if (last === undefined) return "";
    const head = chars.join("");
    if (!isSyllable(last)) return head;
    const [lead, vowel, tail] = parts(last);
    if (tail) return head + syllable(lead, vowel, TAIL_PARTS[tail]?.[0] ?? "");
    if (VOWEL_PARTS[vowel]) return head + syllable(lead, VOWEL_PARTS[vowel][0]);
    return head + lead;
  },
};
/** Language code -> input method (languages not listed type one character per key). */
export const IME = { ko: hangulIme };
const plainIme = { compose: (text, ch) => text + ch, decompose: (text) => Array.from(text).slice(0, -1).join("") };

/** The input method of a language such as "ko" or "ko-KR". */
export function imeFor(language) {
  const base = String(language || "en").toLowerCase().split(/[-_]/)[0];
  return IME[base] ?? plainIme;
}

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
    this.ime = imeFor(i18n.language);
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
      const shifted = SHIFTED[ch] ?? (Array.from(up).length === 1 ? up : ch);
      world.find("osk_key_" + i).get("Button").text = this.shift ? shifted : ch;
    });
  }

  onClick(entity) {
    if (!this.field) return;
    const text = this.field.get("TextField").text;
    switch (entity.id) {
      case "osk_done": return this.close(true);
      case "osk_space": return this.type(" ");
      case "osk_delete": return this.set(this.ime.decompose(text));
      case "osk_shift":
        this.shift = !this.shift;
        return this.relabel();
      default:
        if (entity.id.startsWith("osk_key_")) this.type(entity.get("Button").text);
    }
  }

  /** Types one key through the language's input method, within the field's maxLength. */
  type(ch) {
    const f = this.field.get("TextField");
    const text = this.ime.compose(f.text, ch);
    if (f.maxLength > 0 && Array.from(text).length > f.maxLength) return;
    this.set(text);
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
