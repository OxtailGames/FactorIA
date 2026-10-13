// Checks the level data in levels/levels.js and reports every problem it finds.
// Command: project.check_levels. Run it after each change to the levels:
//   factoria call project.check_levels '{}' --project .
import { LEVELS } from "levels/levels.js";

const KNOWN = "#.$@ ";
const STEPS = [
  [1, 0],
  [-1, 0],
  [0, 1],
  [0, -1],
];

/** Returns { problems, stats } for one level. Problems are {severity, message}. */
function checkLevel(level) {
  const problems = [];
  const error = (message) => problems.push({ severity: "error", message });
  const warning = (message) => problems.push({ severity: "warning", message });

  if (typeof level.name !== "string" || level.name.trim() === "") error("name is missing");
  const rows = level.map;
  if (!Array.isArray(rows) || rows.length === 0 || rows.some((r) => typeof r !== "string")) {
    error("map must be a non-empty array of strings, one string per row");
    return { problems, stats: null };
  }

  const widths = [...new Set(rows.map((r) => r.length))];
  if (widths.length > 1) error(`rows have different lengths (${widths.join(", ")}); pad every row to the same width`);
  const h = rows.length;
  const w = Math.max(...rows.map((r) => r.length));
  // The character at (x, y), or null when the cell is outside the row.
  const ch = (x, y) => (y >= 0 && y < h && x >= 0 && x < rows[y].length ? rows[y][x] : null);

  const players = [];
  const boxes = [];
  const targets = [];
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < rows[y].length; x++) {
      const c = rows[y][x];
      if (!KNOWN.includes(c)) error(`unknown character ${JSON.stringify(c)} at column ${x}, row ${y}`);
      if (c === "@") players.push([x, y]);
      if (c === "$") boxes.push([x, y]);
      if (c === ".") targets.push([x, y]);
    }
  }

  if (players.length !== 1) error(`expected exactly one player (@), found ${players.length}`);
  if (boxes.length === 0) error("level has no boxes ($)");
  if (boxes.length !== targets.length) {
    error(`${boxes.length} boxes ($) but ${targets.length} targets (.): the counts must match`);
  }

  // Closed walls: the outer ring of the map must be solid, so nothing can leak out of the level.
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const onEdge = x === 0 || y === 0 || x === w - 1 || y === h - 1;
      if (onEdge && ch(x, y) !== "#") error(`wall has a gap at column ${x}, row ${y}: the outer ring must be #`);
    }
  }

  // Everything that can be walked on should be reachable from the player.
  if (players.length === 1) {
    const key = (x, y) => `${x},${y}`;
    const seen = new Set([key(...players[0])]);
    const stack = [players[0]];
    while (stack.length > 0) {
      const [x, y] = stack.pop();
      for (const [dx, dy] of STEPS) {
        const nx = x + dx;
        const ny = y + dy;
        const c = ch(nx, ny);
        if (c === null || c === "#" || seen.has(key(nx, ny))) continue;
        seen.add(key(nx, ny));
        stack.push([nx, ny]);
      }
    }
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < rows[y].length; x++) {
        if (ch(x, y) !== "#" && !seen.has(key(x, y))) {
          warning(`floor at column ${x}, row ${y} cannot be reached from the player; walls around it are not closed`);
        }
      }
    }
  }

  // A box with a wall on one side of both axes is in a corner and can never move again.
  for (const [x, y] of boxes) {
    const stuckX = ch(x - 1, y) === "#" || ch(x + 1, y) === "#";
    const stuckY = ch(x, y - 1) === "#" || ch(x, y + 1) === "#";
    if (stuckX && stuckY) error(`box at column ${x}, row ${y} sits in a corner and can never move`);
  }

  const stats = { width: w, height: h, players: players.length, boxes: boxes.length, targets: targets.length };
  return { problems, stats };
}

export default {
  name: "check_levels",
  summary: "Check the level data in levels/levels.js: box and target counts, one player, closed walls.",
  description:
    'Example: {}. Returns {ok, errors, warnings, levels: [{level, name, size, boxes, targets, problems}]}. ' +
    "Errors make ok false; warnings are advice.",
  input: { type: "object", properties: {} },
  readOnly: true,
  run() {
    const levels = LEVELS.map((level, i) => {
      const { problems, stats } = checkLevel(level);
      return {
        level: i + 1,
        name: level.name,
        size: stats ? [stats.width, stats.height] : null,
        boxes: stats ? stats.boxes : null,
        targets: stats ? stats.targets : null,
        problems,
      };
    });
    const all = levels.flatMap((l) => l.problems);
    if (LEVELS.length < 3) all.push({ severity: "warning", message: `only ${LEVELS.length} level(s); the game is designed for at least 3` });
    const names = LEVELS.map((l) => l.name);
    if (new Set(names).size !== names.length) all.push({ severity: "warning", message: "two levels have the same name" });
    const errors = all.filter((p) => p.severity === "error").length;
    const warnings = all.length - errors;
    return { ok: errors === 0, errors, warnings, levels };
  },
};
