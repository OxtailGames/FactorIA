// @ts-check
// Steam Deck: telling it apart, its screen, and what happens when it goes to sleep.
//
//   isDeck()                  true when a connected pad is a Steam Deck's (input.gamepad(i).type === "steamdeck"). The engine has no
//                             "running on a Deck" flag: the built-in controls show up as pad 0 of that family.
//   keyboardKind()            who types for a focused TextField right now: "steam" (Steam's own keyboard is up:
//                             input.platformKeyboard), "onscreen" (a pad, no Steam keyboard: the menu kit's keyboard), "touch" or
//                             "keyboard". text_entry.js uses it to choose the hint.
//   fit(width, height)        where the 1280 x 720 design lands in a window ("fit" scale mode): { scale, offsetX, offsetY }.
//   DECK_SCREEN               { width: 1280, height: 800 } (the Deck's 16:10 panel). The design fits it at scale 1 with 40 px bars.
//   watchLife(hooks)          listens to suspend and resume for the current scene (the Deck's sleep; a phone's home button). On
//                             suspend: hooks.pause() (open the pause menu, so the player is not dropped into a live shift on
//                             waking), the analytics queue is sent. On resume: presence is sent again and hooks.resumed() runs.
//                             Returns the function that stops listening.
import { input, game } from "factoria";
import * as analytics from "./analytics.js";
import * as presence from "./presence.js";

export const DESIGN = Object.freeze({ width: 1280, height: 720 });
export const DECK_SCREEN = Object.freeze({ width: 1280, height: 800 });

export function isDeck() {
  for (let i = 0; i < 4; i++) {
    const pad = input.gamepad(i);
    if (pad.connected && pad.type === "steamdeck") return true;
  }
  return false;
}

/** @returns {"steam"|"onscreen"|"touch"|"keyboard"} */
export function keyboardKind() {
  if (input.platformKeyboard) return "steam";
  const d = input.lastDevice;
  if (d === "gamepad") return "onscreen";
  if (d === "touch") return "touch";
  return "keyboard";
}

/**
 * How the "fit" scale mode places the design resolution in a window: the biggest scale that fits, centred.
 * @param {number} width
 * @param {number} height
 */
export function fit(width, height) {
  const scale = Math.min(width / DESIGN.width, height / DESIGN.height);
  return { scale, offsetX: (width - DESIGN.width * scale) / 2, offsetY: (height - DESIGN.height * scale) / 2 };
}

/**
 * @param {{pause?: () => void, resumed?: () => void}} [hooks]
 * @returns {() => void}
 */
export function watchLife(hooks = {}) {
  const offSuspend = game.on("suspend", () => {
    try {
      hooks.pause?.();
    } finally {
      void analytics.flush();
    }
  });
  const offResume = game.on("resume", () => {
    presence.forget();
    const last = presence.current();
    if (last) presence.set(last);
    hooks.resumed?.();
  });
  return () => {
    offSuspend();
    offResume();
  };
}
