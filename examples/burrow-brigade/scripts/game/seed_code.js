// @ts-check
// Seed codes: a mine (a seed, a stratum and a floor) written as a short readable code like `3K7Q-2XF9`, to read to a friend, type
// at the title or copy to the clipboard.
//
//   code = 7 base32 characters + 1 check character, shown as two groups of four.
//   The 35 bits are  floorIndex (4 bits: stratum * 3 + floor - 1, 0 to 8)  then  seed (31 bits).
//   The alphabet is Crockford's: 0-9 and A-Z without I, L, O and U, so no letter looks like a digit. Typing O, I or L is read
//   as 0, 1 and 1, U as V; case, dashes and spaces do not matter.
//   The check character is the sum of (weight x value) of the seven characters, weights 1, 3, 5, 7, 9, 11, 13, modulo 32.
//   The weights are odd, so any single mistyped character is caught.
//
//   encode({ seed, stratum, floor })  ->  "3K7Q-2XF9"
//   decode(text)                      ->  { ok: true, seed, stratum, floor }  or  { ok: false, message, hint }
//   normalize(text)                   ->  the 8 characters without dashes, upper case, look-alikes mapped
import { FLOORS_PER_STRATUM, STRATUM_COUNT } from "./floors.js";

export const ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
const WEIGHTS = [1, 3, 5, 7, 9, 11, 13];
const SEED_RANGE = 0x80000000; // 2^31
/** Characters of a code, without the dash. */
export const CODE_LENGTH = 8;
/** An example the messages show. */
export const EXAMPLE = "3K7Q-2XF9";

function checkOf(values) {
  let sum = 0;
  for (let i = 0; i < values.length; i++) sum += WEIGHTS[i] * values[i];
  return sum % 32;
}

/**
 * The code of a mine.
 * @param {{seed: number, stratum: number, floor: number}} mine
 */
export function encode(mine) {
  const { seed, stratum, floor } = mine;
  if (!Number.isInteger(seed) || seed < 0 || seed >= SEED_RANGE) throw new Error(`a seed code holds a whole seed from 0 to ${SEED_RANGE - 1}, not ${seed}.`);
  const index = stratum * FLOORS_PER_STRATUM + floor - 1;
  if (!Number.isInteger(index) || index < 0 || index >= STRATUM_COUNT * FLOORS_PER_STRATUM) throw new Error(`stratum ${stratum} floor ${floor} is not a floor of the mine.`);
  let rest = index * SEED_RANGE + seed;
  const values = [];
  for (let i = 0; i < 7; i++) {
    values.unshift(rest % 32);
    rest = Math.floor(rest / 32);
  }
  values.push(checkOf(values));
  const text = values.map((v) => ALPHABET[v]).join("");
  return `${text.slice(0, 4)}-${text.slice(4)}`;
}

/** Upper case, no dashes or spaces, O -> 0, I and L -> 1, U -> V. */
export function normalize(text) {
  return String(text ?? "").toUpperCase().replace(/[\s_-]+/g, "").replace(/O/g, "0").replace(/[IL]/g, "1").replace(/U/g, "V");
}

/**
 * Reads a code. Every refusal says what is wrong and what to do.
 * @param {string} text
 * @returns {{ok: true, seed: number, stratum: number, floor: number} | {ok: false, message: string, hint: string}}
 */
export function decode(text) {
  const shown = String(text ?? "").trim();
  if (shown === "") return { ok: false, message: "the seed code is empty", hint: `type the 8 characters of a code, like ${EXAMPLE}` };
  const chars = normalize(shown);
  const bad = [...new Set([...chars].filter((c) => !ALPHABET.includes(c)))];
  if (bad.length > 0) {
    return { ok: false, message: `'${shown}' has ${bad.length === 1 ? "a character" : "characters"} a seed code never uses: ${bad.map((c) => `'${c}'`).join(", ")}`, hint: `a code is made of digits and letters only (like ${EXAMPLE})` };
  }
  if (chars.length !== CODE_LENGTH) {
    return { ok: false, message: `'${shown}' has ${chars.length} characters and a seed code has ${CODE_LENGTH}`, hint: chars.length < CODE_LENGTH ? `a character is missing: compare it with the code on the screen (like ${EXAMPLE})` : `there are extra characters: a code looks like ${EXAMPLE}` };
  }
  const values = [...chars].map((c) => ALPHABET.indexOf(c));
  const check = values.pop();
  if (checkOf(values) !== check) {
    return { ok: false, message: `'${shown}' is not a valid seed code: its check character does not match`, hint: "one character is mistyped: compare the code with the one on the screen, one character at a time" };
  }
  let value = 0;
  for (const v of values) value = value * 32 + v;
  const index = Math.floor(value / SEED_RANGE);
  if (index >= STRATUM_COUNT * FLOORS_PER_STRATUM) {
    return { ok: false, message: `'${shown}' is not a floor of this mine (floor number ${index + 1} of ${STRATUM_COUNT * FLOORS_PER_STRATUM})`, hint: "the code comes from another game or a newer version: ask for a code from this game's results screen or camp" };
  }
  return { ok: true, seed: value % SEED_RANGE, stratum: Math.floor(index / FLOORS_PER_STRATUM), floor: (index % FLOORS_PER_STRATUM) + 1 };
}
