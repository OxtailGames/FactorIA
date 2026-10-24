// @ts-check
// Numbers for the player's eyes, in the language's own form: the engine's i18n.number / i18n.duration know the decimal
// and group separators (FB-0039 asked for them), these two helpers only fix the digits the game shows.
//
//   decimal(12.34)       "12.3" in en and ja, "12,3" in es
//   decimal(12.34, 2)    "12.34" / "12,34"
//   clock(75.2)          "1:15.2" / "1:15,2" (m:ss.s, the leaderboards)
import { i18n } from "factoria";

/**
 * @param {number} value
 * @param {number} [digits] digits after the separator
 */
export function decimal(value, digits = 1) {
  return i18n.number(value, { decimals: digits });
}

/** @param {number} seconds minutes and seconds with one decimal: m:ss.s */
export function clock(seconds) {
  return i18n.duration(seconds);
}
