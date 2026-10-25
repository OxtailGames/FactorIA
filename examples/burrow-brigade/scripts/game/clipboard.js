// @ts-check
// The clipboard of the game, behind two functions. FactorIA has no clipboard API for scripts (ENGINE_FEEDBACK: "Scripts cannot
// read or write the system clipboard"), so by default `copy` keeps the text in the game's own buffer for the rest of the session
// and `paste` reads that buffer back: a code copied at the camp can be pasted at the title (or by a second player on the same
// machine), but not into another program, and a text copied elsewhere cannot be pasted here. `system` says which one is in use,
// so the screens never claim a copy they did not make.
//
// The day the engine offers a clipboard, plug it in with `useSystem({ write, read })` from one place (the title and the camp
// need no other change).

/** @type {{write: (text: string) => void, read: () => string} | null} */
let backend = null;
let buffer = "";

/** True when copy and paste go through the system clipboard; false while they only use the game's own buffer. */
export function system() {
  return backend !== null;
}

/**
 * Plugs in a real clipboard.
 * @param {{write: (text: string) => void, read: () => string} | null} api  null goes back to the game's own buffer.
 */
export function useSystem(api) {
  backend = api;
}

/**
 * Copies a text. Returns where it went: `system` true when another program can paste it.
 * @param {string} text
 * @returns {{ok: true, system: boolean}}
 */
export function copy(text) {
  buffer = String(text);
  if (backend) backend.write(buffer);
  return { ok: true, system: backend !== null };
}

/** The copied text ("" when nothing was copied yet). */
export function paste() {
  return backend ? backend.read() : buffer;
}

/** Forgets the buffer (tests). */
export function reset() {
  buffer = "";
  backend = null;
}
