// @ts-check
// "m:ss.cc" for the timer and the level end panel.

/** @param {number} seconds */
export function formatTime(seconds) {
  const cs = Math.floor(seconds * 100 + 1e-6);
  const m = Math.floor(cs / 6000);
  const s = Math.floor((cs % 6000) / 100);
  return `${m}:${String(s).padStart(2, "0")}.${String(cs % 100).padStart(2, "0")}`;
}
