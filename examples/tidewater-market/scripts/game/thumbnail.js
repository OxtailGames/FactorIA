// @ts-check
// The map thumbnail of a save slot. A save made in a run with a renderer has a real picture of the town (picture.js, FB-0020), which
// the slot screen shows instead; this top-down map is what a slot shows when it has none: a save made before pictures, a run with no
// graphics, or an entry that came from the cloud. At most 48 x 48 cells, one colour each, kept as run-length text in the slot meta.
//
//   const thumb = makeThumbnail(state);    // { w, h, rows: ["w12s3g5", ...] }  letter + run length, as in thumbRuns
//   thumbRuns(thumb)                       // [{ row, col, len, kind }] one per run, what the slot screen draws as quads
//   THUMB_COLORS[kind]                     // [r, g, b, a] for a kind letter
export const THUMB_MAX = 48;

/** Kind letters: terrain (w water, s sand, g grass, f forest, r rock) and what stands on it (x road, h house, b other building). */
export const THUMB_COLORS = {
  w: [0.2, 0.42, 0.62, 1],
  s: [0.85, 0.78, 0.55, 1],
  g: [0.45, 0.68, 0.35, 1],
  f: [0.22, 0.45, 0.25, 1],
  r: [0.5, 0.5, 0.52, 1],
  x: [0.62, 0.5, 0.36, 1],
  h: [0.85, 0.35, 0.3, 1],
  b: [0.95, 0.85, 0.4, 1],
};

/** @param {import("./state.js").GameState} state */
export function makeThumbnail(state) {
  const map = state.map;
  const step = Math.ceil(Math.max(map.width, map.height) / THUMB_MAX);
  const w = Math.ceil(map.width / step);
  const h = Math.ceil(map.height / step);
  const rows = [];
  for (let r = 0; r < h; r++) {
    let text = "";
    let last = "";
    let run = 0;
    for (let c = 0; c < w; c++) {
      const kind = cellKind(state, c * step, r * step, step);
      if (kind === last) run++;
      else {
        if (run) text += last + run;
        last = kind;
        run = 1;
      }
    }
    rows.push(text + last + run);
  }
  return { w, h, rows };
}

/** What a block of step x step cells shows: a building beats a road beats the terrain of its first cell. */
function cellKind(state, c0, r0, step) {
  const map = state.map;
  let road = false;
  for (let r = r0; r < Math.min(r0 + step, map.height); r++) {
    for (let c = c0; c < Math.min(c0 + step, map.width); c++) {
      const id = map.occupantAt(c, r);
      if (!id) continue;
      const b = state.buildings.get(id);
      if (!b) continue;
      if (b.type === "road") road = true;
      else return b.type === "house" ? "h" : "b";
    }
  }
  if (road) return "x";
  const id = map.terrainAt(c0, r0);
  return (id && state.data.terrain[id].char) || "g";
}

/** The runs of a thumbnail, left to right, top to bottom. Tolerates a damaged one (returns what it can read). */
export function thumbRuns(thumb) {
  const runs = [];
  if (!thumb || !Array.isArray(thumb.rows)) return runs;
  thumb.rows.forEach((text, row) => {
    if (typeof text !== "string") return;
    let col = 0;
    for (const m of text.matchAll(/([a-z])(\d+)/g)) {
      const len = Number(m[2]);
      runs.push({ row, col, len, kind: m[1] });
      col += len;
    }
  });
  return runs;
}
