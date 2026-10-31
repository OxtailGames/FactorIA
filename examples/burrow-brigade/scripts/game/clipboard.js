// @ts-check
// The clipboard of the game, behind two functions. On Windows, macOS, Linux and the web (and in tests, where it is an in-memory
// clipboard) `copy` writes the system clipboard with the engine's `clipboard.write` and `paste` reads it with `clipboard.read`,
// so a code copied at the camp can be pasted into another program and a text copied elsewhere can be pasted here. A phone has no
// clipboard for scripts (`window.supports("clipboard")` is false): there `copy` keeps the text in the game's own buffer for the
// rest of the session and `paste` reads that buffer back. `system()` says which one is in use, so the screens never claim a copy
// they did not make.
import { clipboard, window } from "factoria";

let useEngine = true;
let buffer = "";

/** True when copy and paste go through the system clipboard; false while they only use the game's own buffer (phones). */
export function system() {
  return useEngine && window.supports("clipboard");
}

/**
 * Switches the system clipboard off (false) or back on (true). A test uses it to play a phone.
 * @param {boolean} on
 */
export function useSystem(on) {
  useEngine = on;
}

/**
 * Copies a text. Returns where it went: `system` true when another program can paste it.
 * @param {string} text
 * @returns {{ok: true, system: boolean}}
 */
export function copy(text) {
  buffer = String(text);
  if (system()) clipboard.write(buffer);
  return { ok: true, system: system() };
}

/**
 * The copied text ("" when there is none). The system clipboard answers later (a Promise): the caller checks that its scene is
 * still the current one before it uses the text.
 * @returns {Promise<string>}
 */
export async function paste() {
  if (!system()) return buffer;
  try {
    return await clipboard.read();
  } catch {
    return buffer; // the platform refused the read (the web outside a paste gesture): a code copied in this game still works
  }
}

/** Forgets the buffer and goes back to the system clipboard (tests). */
export function reset() {
  buffer = "";
  useEngine = true;
}
