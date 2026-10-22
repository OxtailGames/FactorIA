// @ts-check
// The calendar date, read with the engine's game.today() (never `Date`: it reads the real clock, so a run could not be
// replayed or tested). A built game gets the player's local date; `factoria test` and headless runs get a fixed one,
// and tests choose the day with game.setDate("YYYY-MM-DD") from "factoria:test".
//
//   today()          "YYYY-MM-DD" of the calendar day (game.today().iso)
//   addDays(date, n) the date n days later (n may be negative)
import { game } from "factoria";

export function today() {
  return game.today().iso;
}

/** @param {string} date "YYYY-MM-DD"  @param {number} n */
export function addDays(date, n) {
  const [y, m, d] = date.split("-").map(Number);
  const t = new Date(Date.UTC(y, m - 1, d + n));
  return `${String(t.getUTCFullYear()).padStart(4, "0")}-${String(t.getUTCMonth() + 1).padStart(2, "0")}-${String(t.getUTCDate()).padStart(2, "0")}`;
}
