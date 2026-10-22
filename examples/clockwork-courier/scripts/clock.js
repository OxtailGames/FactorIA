// @ts-check
// The calendar date, the one thing in the game that is not deterministic by nature. The engine has no calendar API
// (ENGINE_FEEDBACK: no `time.today` and no test hook), only the JS `Date`, which reads the real clock. So the whole game
// asks THIS module, and tests pin the day with setToday() (`session` is reset for every test).
//
//   today()          "YYYY-MM-DD" of the player's local calendar day, or the pinned one
//   setToday(date)   pin the day ("YYYY-MM-DD"); setToday(null) goes back to the real clock
//   addDays(date, n) the date n days later (n may be negative)
import { session } from "factoria";

export function today() {
  if (session.pinnedToday) return session.pinnedToday;
  const d = new Date();
  return `${String(d.getFullYear()).padStart(4, "0")}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

/** @param {string | null} date */
export function setToday(date) {
  session.pinnedToday = date;
}

/** @param {string} date "YYYY-MM-DD"  @param {number} n */
export function addDays(date, n) {
  const [y, m, d] = date.split("-").map(Number);
  const t = new Date(Date.UTC(y, m - 1, d + n));
  return `${String(t.getUTCFullYear()).padStart(4, "0")}-${String(t.getUTCMonth() + 1).padStart(2, "0")}-${String(t.getUTCDate()).padStart(2, "0")}`;
}
