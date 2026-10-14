// Checks the level data in levels/levels.json and reports every problem it finds.
// Command: project.check_levels. Run it after each change to the levels:
//   factoria call project.check_levels '{}' --project .
// A clean check returns the report. Bad level data throws a ToolError, so the call fails (exit 1) and the same
// report travels as error.data (`factoria call --json`, MCP and `--batch`).
import { ToolError } from "factoria";
import levels from "../levels/levels.json";

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

  if (typeof level !== "object" || level === null || Array.isArray(level)) {
    error('level must be an object like {"name": "...", "map": ["..."]}');
    return { problems, stats: null };
  }
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

/** The first few errors of a report on one line, for the ToolError message. */
function describeErrors(report) {
  const lines = [];
  for (const p of report.problems) if (p.severity === "error") lines.push(p.message);
  for (const l of report.levels) {
    for (const p of l.problems) if (p.severity === "error") lines.push(`level ${l.level} (${l.name}): ${p.message}`);
  }
  const shown = lines.slice(0, 4);
  if (lines.length > shown.length) shown.push(`and ${lines.length - shown.length} more`);
  return shown.join("; ");
}

export default {
  name: "check_levels",
  summary: "Check the level data in levels/levels.json: box and target counts, one player, closed walls.",
  description:
    "Example: {}. With no level error it returns the report {ok: true, errors: 0, warnings, problems, levels: " +
    "[{level, name, size, boxes, targets, problems}]}; warnings are advice. If any level has an error the call FAILS " +
    "(code tool_error, exit 1 from `factoria call`) and the same report, with ok false, is in error.data. " +
    "`problems` holds the checks that are not about one level (level count, duplicate names).",
  input: { type: "object", properties: {} },
  readOnly: true,
  run() {
    if (!Array.isArray(levels) || levels.length === 0) {
      throw new ToolError(
        "levels/levels.json must be a non-empty array of levels",
        'Write it as [{"name": "First push", "map": ["#####", "#.$@#", "#####"]}, ...]: one object per level, one string per map row.',
      );
    }
    const results = levels.map((level, i) => {
      const { problems, stats } = checkLevel(level);
      return {
        level: i + 1,
        name: level?.name,
        size: stats ? [stats.width, stats.height] : null,
        boxes: stats ? stats.boxes : null,
        targets: stats ? stats.targets : null,
        problems,
      };
    });
    const problems = []; // checks across the whole file
    if (levels.length < 3) problems.push({ severity: "warning", message: `only ${levels.length} level(s); the game is designed for at least 3` });
    const names = levels.map((l) => l?.name);
    if (new Set(names).size !== names.length) problems.push({ severity: "warning", message: "two levels have the same name" });

    const all = [...problems, ...results.flatMap((l) => l.problems)];
    const errors = all.filter((p) => p.severity === "error").length;
    const warnings = all.length - errors;
    const report = { ok: errors === 0, errors, warnings, problems, levels: results };
    if (errors > 0) {
      throw new ToolError(
        `${errors} error(s) in levels/levels.json: ${describeErrors(report)}`,
        "Fix the listed problems in levels/levels.json (each names the column and row), then run project.check_levels again. " +
          "error.data has the full report, level by level.",
        report,
      );
    }
    return report;
  },
};
