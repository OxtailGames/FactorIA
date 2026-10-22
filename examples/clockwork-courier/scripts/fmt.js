// @ts-check
// Numbers for the player's eyes. The engine's i18n.t() fills {placeholders} with String(value) and has no number formatting
// (FB-0039), so a decimal arrives with a point in every language. Each locale file
// states its own separator in `format.decimal` ("." en and ja, "," es) and these helpers apply it.
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
  const text = value.toFixed(digits);
  const separator = i18n.t("format.decimal");
  return separator === "." || separator === "format.decimal" ? text : text.replace(".", separator);
}

/** @param {number} seconds minutes and seconds with one decimal: m:ss.s */
export function clock(seconds) {
  const m = Math.floor(seconds / 60);
  const rest = decimal(seconds - m * 60, 1);
  return `${m}:${rest.padStart(4, "0")}`;
}
