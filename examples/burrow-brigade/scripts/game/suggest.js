// @ts-check
// "Did you mean": the closest names to a mistyped one, for the error messages of the game's own modules (the shop, the saves).

/** Levenshtein distance between two strings. */
export function editDistance(a, b) {
  const row = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    let prev = row[0];
    row[0] = i;
    for (let j = 1; j <= b.length; j++) {
      const cur = row[j];
      row[j] = Math.min(row[j] + 1, row[j - 1] + 1, prev + (a[i - 1] === b[j - 1] ? 0 : 1));
      prev = cur;
    }
  }
  return row[b.length];
}

/**
 * The options within a small distance of `input`, closest first (at most three).
 * @param {string} input
 * @param {readonly string[]} options
 */
export function closest(input, options) {
  const text = String(input).toLowerCase();
  return options
    .map((name) => ({ name, d: editDistance(text, name.toLowerCase()) }))
    .filter((c) => c.d <= Math.max(2, Math.floor(text.length / 3)))
    .sort((x, y) => x.d - y.d)
    .slice(0, 3)
    .map((c) => c.name);
}

/** " Did you mean 'a' or 'b'?" (with a leading space), or "" when nothing is close. */
export function didYouMean(input, options) {
  const near = closest(input, options);
  return near.length ? ` Did you mean ${near.map((n) => `'${n}'`).join(" or ")}?` : "";
}
