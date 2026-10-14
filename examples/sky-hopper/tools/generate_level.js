// Project tool "project.generate_level": builds a playable Sky Hopper level scene from parameters.
//
// The tool only decides what the level looks like, as ASCII: `rows` (one character per tile, row 0 on top) and a
// `legend` that maps characters to tiles and prefabs. The engine command scene.import_ascii (docs: ai-guide 9.8)
// builds the Tilemap and puts the coins, enemies, player and flag in the right cell, so there is no world coordinate
// in this file. The hand-made levels are built by the same command from levels/level1.json and levels/level2.json.
//
// scene.import_ascii {path, from, dryRun} edits a scene FILE in a scratch world, so the running game is never touched
// (no scene is loaded, saved or restored, audio and physics keep going):
//   1. copy levels/generator_base.scene.json (settings, camera, level script and HUD, no map) to a scratch file in
//      .factoria/tmp/ with the sky colour and the level number set for this map (the camera takes its limits from the
//      map itself: its follow_camera has "bounds": "map")
//   2. scene.import_ascii {path, from: <that copy>, dryRun} builds the Tilemap and the objects and writes `path` in the
//      canonical layout (dryRun: writes nothing and returns the scene JSON)
//   3. delete the scratch copy, also when the import failed
import { fa, ToolError, rng } from "factoria";

const TS = 32; // tile size in pixels (assets/tileset.png holds 32x32 tiles: 0 grass, 1 dirt, 2 brick)
const ROWS = 16;
const BASE = "levels/generator_base.scene.json";
const SCRATCH = ".factoria/tmp/generate_level.base.scene.json"; // the base with this level's settings (fs.write/fs.delete may use .factoria/tmp/)
const PREFAB = {
  coin: "prefabs/coin.prefab.json",
  enemy: "prefabs/enemy.prefab.json",
  player: "prefabs/player.prefab.json",
  goal: "prefabs/goal.prefab.json",
};

const round3 = (v) => Math.round(v * 1000) / 1000;

// The level as ASCII. `#` grass, `%` dirt, `=` brick platform, `o` coin, `E` enemy, `P` player, `F` flag, `.` empty.
function compose_rows({ width: W, seed, difficulty }) {
  // rng.create(seed), not rng.seed(): an independent generator, so a generator run never changes the running game's
  // random sequence, and the same seed gives the same level on every platform and engine version.
  const r = rng.create(seed);
  const rnd = () => r.float();
  const int = (a, b) => a + Math.floor(rnd() * (b - a + 1));
  const groundTop = 13; // first ground row
  const grid = Array.from({ length: ROWS }, () => Array(W).fill("."));
  const coins = []; // [col, row]
  const enemies = []; // col
  const maxGap = Math.min(5, 2 + Math.ceil(difficulty * 0.7)); // a jump clears ~6 tiles; stay safe
  const enemyChance = 0.15 + difficulty * 0.12;

  const startLen = 8;
  const endLen = 8;
  const fill = (c0, c1) => {
    for (let c = c0; c < c1 && c < W; c++) for (let r = groundTop; r < ROWS; r++) grid[r][c] = "#";
  };
  fill(0, startLen);
  let col = startLen;
  while (col < W - endLen) {
    const gap = int(2, maxGap);
    // platform stepping stones above wide pits
    if (gap >= 4 && rnd() < 0.7) {
      const pc = col + Math.floor(gap / 2) - 1;
      for (let c = pc; c < pc + 2 && c < W; c++) grid[groundTop - 3][c] = "=";
      coins.push([pc, groundTop - 4]);
    }
    for (let c = 0; c < gap; c++) if (rnd() < 0.5) coins.push([col + c, groundTop - 2 - (c % 2 === 0 ? 1 : 2)]);
    col += gap;
    const len = Math.max(4, int(4, 12 - difficulty));
    const end = Math.min(col + len, W - endLen);
    fill(col, end);
    if (end - col >= 6 && rnd() < enemyChance) enemies.push(int(col + 2, end - 3));
    if (rnd() < 0.5) {
      const pc = int(col, Math.max(col, end - 3));
      for (let c = pc; c < pc + 3 && c < end; c++) grid[groundTop - 3][c] = "=";
      for (let c = pc; c < pc + 3 && c < end; c++) coins.push([c, groundTop - 4]);
    } else {
      for (let c = col + 1; c < end - 1; c += 2) if (rnd() < 0.4) coins.push([c, groundTop - 2]);
    }
    col = end;
  }
  fill(W - endLen, W);
  // small hill before the flag
  for (let c = W - 4; c < W; c++) grid[groundTop - 1][c] = "#";

  // Dirt under anything solid, except under a brick platform (grass shows there).
  const solid = (r, c) => r >= 0 && c >= 0 && c < W && "#%=".includes(grid[r][c]);
  for (let r = 1; r < ROWS; r++)
    for (let c = 0; c < W; c++) if (grid[r][c] === "#" && solid(r - 1, c) && grid[r - 1][c] !== "=") grid[r][c] = "%";

  // Objects go into empty cells only: one character per cell, so a coin cannot sit inside a brick.
  const put = (c, r, glyph) => {
    if (r >= 0 && r < ROWS && c >= 0 && c < W && grid[r][c] === ".") grid[r][c] = glyph;
  };
  for (const [c, r] of coins) put(c, r, "o");
  for (const c of enemies) put(c, groundTop - 1, "E");
  put(2, groundTop - 1, "P");
  put(W - 2, groundTop - 2, "F");
  return grid.map((row) => row.join(""));
}

function compose_legend(rows, { difficulty, next }) {
  const used = new Set(rows.join(""));
  const legend = {
    "#": 0,
    "%": 1,
    "=": 2,
    o: { prefab: PREFAB.coin },
    // The crawler's collider is 26 px high in a 32 px cell: 4 px down puts its feet on the ground line.
    E: { prefab: PREFAB.enemy, offset: [0, -4], overrides: { Script: { props: { speed: 40 + difficulty * 12 } } } },
    P: { prefab: PREFAB.player, id: "player" },
    // The flag is 96 px high (3 cells): 16 px up from the cell centre sinks its pole 16 px into the ground.
    F: { prefab: PREFAB.goal, id: "goal", offset: [0, 16], overrides: { Script: { props: { next } } } },
  };
  for (const glyph of Object.keys(legend)) if (!used.has(glyph)) delete legend[glyph]; // no "unused glyph" warnings
  return legend;
}

// fa.call that reports a failed command as an expected tool error: the command's message and its own hint.
function call(name, args) {
  try {
    return fa.call(name, args);
  } catch (e) {
    throw new ToolError(e.message, e.hint || `See \`factoria commands ${name}\` for its arguments.`);
  }
}

// The base scene with the parts that are not map set for this level: sky colour, camera height, level number. Script
// props are replaced as a whole, so start from what the base scene has. The camera limits are not set here: the
// camera's "bounds": "map" makes follow_camera.js clamp to the Tilemap this level imports.
function base_for_level({ levelH, difficulty, levelIndex }) {
  const base = JSON.parse(call("fs.read", { path: BASE }).content);
  const entity = (id) => {
    const e = base.entities.find((x) => x.id === id);
    if (!e) throw new ToolError(`${BASE} has no entity '${id}'.`, `Restore it: project.generate_level tunes the 'camera' and 'level' entities of the base scene.`);
    return e;
  };
  const camera = entity("camera").components;
  camera.Camera = { ...camera.Camera, clearColor: [round3(0.55 - difficulty * 0.08), round3(0.7 - difficulty * 0.08), round3(0.95 - difficulty * 0.1), 1] };
  camera.Transform = { ...camera.Transform, position: [640, levelH / 2, 0] };
  const level = entity("level").components;
  level.Script = { ...level.Script, props: { ...level.Script.props, levelIndex } };
  return base;
}

// Builds the scene file `path` (or, for dryRun, only returns it). Returns what scene.import_ascii said.
function build_scene({ rows, legend, difficulty, levelIndex, path, dryRun }) {
  const base = base_for_level({ levelH: rows.length * TS, difficulty, levelIndex });
  call("fs.write", { path: SCRATCH, content: JSON.stringify(base, null, 2) + "\n" });
  try {
    return call("scene.import_ascii", {
      rows,
      legend,
      entity: "map",
      tilemap: { tileset: "assets/tileset.png", tileSize: [TS, TS], solidTiles: [0, 1, 2], layer: -10 },
      anchor: "bottom-left",
      position: [0, 0],
      path,
      from: SCRATCH,
      dryRun,
    });
  } finally {
    try {
      call("fs.delete", { path: SCRATCH });
    } catch (e) {
      // A leftover scratch file is harmless: it lives in .factoria/tmp/ and the next run overwrites it.
    }
  }
}

export default {
  name: "generate_level",
  summary: "Generate a Sky Hopper level scene (tilemap, coins, enemies, flag) from width, seed and difficulty.",
  description:
    'Example: {"width": 80, "seed": 7, "difficulty": 3, "path": "scenes/generated.scene.json", "next": "scenes/win.scene.json"}. ' +
    "Overwrites `path`. Same arguments always give the same level. width is in tiles (32 px each). " +
    "Higher difficulty means wider pits, more enemies and fewer safe ground stretches. " +
    "The result lists the level as ASCII `rows`. It is built with scene.import_ascii {path, from, dryRun}, which edits the " +
    "scene FILE and never touches the running game, so it is safe to call while playing. Run project_validate afterwards.",
  input: {
    type: "object",
    properties: {
      width: { type: "integer", minimum: 30, maximum: 400, default: 80, description: "Level width in tiles." },
      seed: { type: "integer", default: 1, description: "Seed; same seed gives the same level." },
      difficulty: { type: "integer", minimum: 1, maximum: 5, default: 2, description: "1 (easy) to 5 (hard)." },
      path: { type: "string", pattern: "\\.scene\\.json$", default: "scenes/generated.scene.json", description: "Project-relative output path." },
      next: { type: "string", default: "scenes/win.scene.json", description: "Scene loaded when the flag is reached." },
      dryRun: { type: "boolean", default: false, description: "Do not write a file; return the scene JSON in `scene` (used by tests)." },
      levelIndex: { type: "integer", minimum: 1, default: 3, description: "Level number shown in the HUD." },
    },
  },
  readOnly: false,
  run({ width = 80, seed = 1, difficulty = 2, path = "scenes/generated.scene.json", next = "scenes/win.scene.json", levelIndex = 3, dryRun = false }) {
    const rows = compose_rows({ width, seed, difficulty });
    const legend = compose_legend(rows, { difficulty, next });

    const imported = build_scene({ rows, legend, difficulty, levelIndex, path, dryRun });
    const count = (prefab) => imported.spawned.filter((s) => s.prefab === prefab).length;
    const result = { path, widthTiles: width, coins: count(PREFAB.coin), enemies: count(PREFAB.enemy), seed, difficulty, rows };
    if (imported.warnings.length > 0) result.warnings = imported.warnings;
    if (dryRun) result.scene = imported.scene;
    return result;
  },
};
