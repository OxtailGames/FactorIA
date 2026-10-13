// Project tool "project.generate_level": builds a playable Sky Hopper level scene from parameters.
//
// The tool only decides what the level looks like, as ASCII: `rows` (one character per tile, row 0 on top) and a
// `legend` that maps characters to tiles and prefabs. The engine command scene.import_ascii (docs: ai-guide 9.8)
// builds the Tilemap and puts the coins, enemies, player and flag in the right cell, so there is no world coordinate
// in this file. The hand-made levels are built by the same command from levels/level1.json and levels/level2.json.
//
// scene.import_ascii edits the RUNNING world, so the tool works in a scratch scene and then puts the game back:
//   1. remember the scene that is loaded (project.info: currentScene)
//   2. scene.load levels/generator_base.scene.json: settings, camera, level script and HUD, no map
//   3. tune the camera and the level script, then scene.import_ascii the generated rows
//   4. scene.save to `path` (dryRun: read the entities back with game.state, nothing is written)
//   5. scene.load the remembered scene again, also when a step failed
// The remembered scene is reloaded from its file, so unsaved edits and the runtime state of the running game are lost.
import { fa, ToolError } from "factoria";

const TS = 32; // tile size in pixels (assets/tileset.png holds 32x32 tiles: 0 grass, 1 dirt, 2 brick)
const ROWS = 16;
const BASE = "levels/generator_base.scene.json";
const PREFAB = {
  coin: "prefabs/coin.prefab.json",
  enemy: "prefabs/enemy.prefab.json",
  player: "prefabs/player.prefab.json",
  goal: "prefabs/goal.prefab.json",
};

// Own PRNG instead of rng.seed(): rng.seed() reseeds the one world RNG that the running game also draws from, and
// scripts cannot read its state back to restore it, so a generator run would change the game's random sequence.
function mulberry32(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const round3 = (v) => Math.round(v * 1000) / 1000;

// The level as ASCII. `#` grass, `%` dirt, `=` brick platform, `o` coin, `E` enemy, `P` player, `F` flag, `.` empty.
function compose_rows({ width: W, seed, difficulty }) {
  const rnd = mulberry32(seed);
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

// Steps 2-4: replaces the running scene with the base scene, imports the rows, saves. Returns what the import said
// and, for dryRun, the scene JSON.
function build_scene({ rows, legend, difficulty, levelIndex, path, dryRun }) {
  const loaded = call("scene.load", { path: BASE });
  if (loaded.scheduled) {
    throw new ToolError("project.generate_level cannot run inside a frame.", "Call it from a tool, a test, `factoria call` or MCP, not from a script's update.");
  }
  if (!loaded.ok) throw new ToolError(`Cannot load ${BASE}: ${(loaded.messages ?? []).join("; ")}`, `Fix ${BASE} (project_validate lists the problems).`);

  const imported = call("scene.import_ascii", {
    rows,
    legend,
    entity: "map",
    tilemap: { tileset: "assets/tileset.png", tileSize: [TS, TS], solidTiles: [0, 1, 2], layer: -10 },
    anchor: "bottom-left",
    position: [0, 0],
  });

  // The parts of the scene that are not map: sky colour, camera limits, level number. Script props are replaced as a
  // whole, so start from what the base scene has.
  const levelW = imported.width * TS;
  const levelH = imported.height * TS;
  const cameraProps = call("scene.get_entity", { id: "camera" }).components.Script.props;
  const levelProps = call("scene.get_entity", { id: "level" }).components.Script.props;
  call("scene.set_component", {
    id: "camera",
    component: "Camera",
    fields: { clearColor: [round3(0.55 - difficulty * 0.08), round3(0.7 - difficulty * 0.08), round3(0.95 - difficulty * 0.1), 1] },
  });
  call("scene.set_component", { id: "camera", component: "Transform", fields: { position: [640, levelH / 2, 0] } });
  call("scene.set_component", { id: "camera", component: "Script", fields: { props: { ...cameraProps, minX: 0, maxX: levelW, minY: 0, maxY: levelH } } });
  call("scene.set_component", { id: "level", component: "Script", fields: { props: { ...levelProps, levelIndex } } });

  if (!dryRun) {
    call("scene.save", { path });
    return { imported };
  }
  const settings = JSON.parse(call("fs.read", { path: BASE }).content).settings;
  const entities = call("game.state", { maxEntities: 100000 }).entities;
  return { imported, scene: { format: "factoria.scene/1", settings, entities } };
}

export default {
  name: "generate_level",
  summary: "Generate a Sky Hopper level scene (tilemap, coins, enemies, flag) from width, seed and difficulty.",
  description:
    'Example: {"width": 80, "seed": 7, "difficulty": 3, "path": "scenes/generated.scene.json", "next": "scenes/win.scene.json"}. ' +
    "Overwrites `path`. Same arguments always give the same level. width is in tiles (32 px each). " +
    "Higher difficulty means wider pits, more enemies and fewer safe ground stretches. " +
    "The result lists the level as ASCII `rows`. It is built with scene.import_ascii in a scratch scene, after which the " +
    "scene that was loaded is reloaded from its file: save unsaved edits of the running scene first. Run project_validate afterwards.",
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

    const previous = call("project.info").currentScene || "";
    let built;
    let failure = null;
    try {
      built = build_scene({ rows, legend, difficulty, levelIndex, path, dryRun });
    } catch (e) {
      failure = e;
    }
    if (previous) {
      // Put the running game back, also after a failure (the first error is the one worth reporting).
      try {
        call("scene.load", { path: previous });
      } catch (e) {
        failure = failure ?? e;
      }
    }
    if (failure) throw failure;

    const { imported, scene } = built;
    const spawned = imported.spawned;
    const count = (prefab) => spawned.filter((s) => s.prefab === prefab).length;
    const result = { path, widthTiles: width, coins: count(PREFAB.coin), enemies: count(PREFAB.enemy), seed, difficulty, rows };
    if (imported.warnings.length > 0) result.warnings = imported.warnings;
    if (dryRun) result.scene = scene;
    return result;
  },
};
