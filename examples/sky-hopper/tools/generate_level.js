// Project tool "project.generate_level": builds a playable Sky Hopper level scene from parameters.
import { fa } from "factoria";

const TS = 32;
const ROWS = 16;

// Own PRNG: the engine's `rng` cannot be seeded from a tool argument (see ENGINE_FEEDBACK.json).
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

export default {
  name: "generate_level",
  summary: "Generate a Sky Hopper level scene (tilemap, coins, enemies, flag) from width, seed and difficulty.",
  description:
    'Example: {"width": 80, "seed": 7, "difficulty": 3, "path": "scenes/generated.scene.json", "next": "scenes/win.scene.json"}. ' +
    "Overwrites `path`. Same arguments always give the same level. width is in tiles (32 px each). " +
    "Higher difficulty means wider pits, more enemies and fewer safe ground stretches. Run project_validate afterwards.",
  input: {
    type: "object",
    properties: {
      width: { type: "integer", minimum: 30, maximum: 400, default: 80, description: "Level width in tiles." },
      seed: { type: "integer", default: 1, description: "Seed; same seed gives the same level." },
      difficulty: { type: "integer", minimum: 1, maximum: 5, default: 2, description: "1 (easy) to 5 (hard)." },
      path: { type: "string", pattern: "\\.scene\\.json$", default: "scenes/generated.scene.json", description: "Project-relative output path." },
      next: { type: "string", default: "scenes/win.scene.json", description: "Scene loaded when the flag is reached." },
      dryRun: { type: "boolean", default: false, description: "Do not write a file; return the scene JSON in `scene` (used by tests, where fs.write is unavailable)." },
      levelIndex: { type: "integer", minimum: 1, default: 3, description: "Level number shown in the HUD." },
    },
  },
  readOnly: false,
  run({ width = 80, seed = 1, difficulty = 2, path = "scenes/generated.scene.json", next = "scenes/win.scene.json", levelIndex = 3, dryRun = false }) {
    const rnd = mulberry32(seed);
    const int = (a, b) => a + Math.floor(rnd() * (b - a + 1));
    const W = width;
    const groundTop = 13; // first ground row
    const grid = Array.from({ length: ROWS }, () => Array(W).fill(" "));
    const coins = [];
    const enemies = [];
    const maxGap = Math.min(5, 2 + Math.ceil(difficulty * 0.7)); // jump clears ~6 tiles; stay safe
    const enemyChance = 0.15 + difficulty * 0.12;

    let col = 0;
    const startLen = 8;
    const fill = (c0, c1) => {
      for (let c = c0; c < c1 && c < W; c++) for (let r = groundTop; r < ROWS; r++) grid[r][c] = "#";
    };
    fill(0, startLen);
    col = startLen;
    const endLen = 8;
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

    const solid = (r, c) => r >= 0 && r < ROWS && c >= 0 && c < W && (grid[r][c] === "#" || grid[r][c] === "=");
    const tiles = [];
    for (let r = 0; r < ROWS; r++) {
      for (let c = 0; c < W; c++) {
        const ch = grid[r][c];
        if (ch === "#") tiles.push(!solid(r - 1, c) || grid[r - 1][c] === "=" ? 0 : 1);
        else if (ch === "=") tiles.push(2);
        else tiles.push(-1);
      }
    }
    const wx = (c) => c * TS + TS / 2;
    const wy = (r) => (ROWS - r) * TS - TS / 2;
    const levelH = ROWS * TS;
    const spawn = [wx(2), wy(groundTop - 1)];

    const entities = [
      {
        id: "camera", name: "Main Camera",
        components: {
          Transform: { position: [640, levelH / 2, 0] },
          Camera: { projection: "orthographic", clearColor: [0.55 - difficulty * 0.08, 0.7 - difficulty * 0.08, 0.95 - difficulty * 0.1, 1], primary: true },
          Script: { path: "scripts/follow_camera.js", props: { target: "player", smoothing: 8, minX: 0, maxX: W * TS, minY: 0, maxY: levelH } },
        },
      },
      {
        id: "map", name: "Tilemap",
        components: {
          Transform: { position: [0, levelH, 0] },
          Tilemap: { tileset: "assets/tileset.png", tileSize: [TS, TS], columns: 4, width: W, height: ROWS, tiles, solidTiles: [0, 1, 2], layer: -10 },
        },
      },
      {
        id: "player", name: "Player", tags: ["player"],
        components: {
          Transform: { position: [spawn[0], spawn[1], 0] },
          Sprite: { texture: "assets/player.png", size: [32, 48], layer: 3, pixelArt: false },
          RigidBody2D: { type: "dynamic", fixedRotation: true },
          Collider2D: { shape: "box", size: [26, 46], friction: 0 },
          Script: { path: "scripts/player.js" },
        },
      },
    ];
    coins.forEach(([c, r], i) => {
      entities.push({
        id: `coin_${i + 1}`, name: "Coin", tags: ["coin"],
        components: {
          Transform: { position: [wx(c), wy(r), 0] },
          Sprite: { texture: "assets/coin.png", size: [24, 24], layer: 1, pixelArt: false },
          RigidBody2D: { type: "static" },
          Collider2D: { shape: "circle", radius: 12, isTrigger: true },
        },
      });
    });
    enemies.forEach((c, i) => {
      entities.push({
        id: `enemy_${i + 1}`, name: "Crawler", tags: ["enemy"],
        components: {
          Transform: { position: [wx(c), wy(groundTop - 1) - 4, 0] },
          Sprite: { texture: "assets/enemy.png", size: [36, 28], layer: 2, pixelArt: false },
          RigidBody2D: { type: "dynamic", fixedRotation: true },
          Collider2D: { shape: "box", size: [34, 26], friction: 0 },
          Script: { path: "scripts/enemy.js", props: { speed: 40 + difficulty * 12 } },
        },
      });
    });
    entities.push({
      id: "goal", name: "Goal Flag", tags: ["goal"],
      components: {
        Transform: { position: [wx(W - 2), wy(groundTop - 2) + TS / 2, 0] },
        Sprite: { texture: "assets/flag.png", size: [40, 96], layer: 1, pixelArt: false },
        RigidBody2D: { type: "static" },
        Collider2D: { shape: "box", size: [30, 96], isTrigger: true },
        Script: { path: "scripts/goal.js", props: { next } },
      },
    });
    entities.push({
      id: "level", name: "Level",
      components: { Script: { path: "scripts/level.js", props: { levelIndex, spawnX: spawn[0], spawnY: spawn[1], killY: -200 } } },
    });
    entities.push({
      id: "hud", name: "HUD",
      components: {
        Transform: { position: [24, 16, 0] },
        Text: { text: "", fontSize: 30, color: [1, 1, 1, 1], pivot: [0, 1], space: "screen", layer: 100 },
        Script: { path: "scripts/hud.js" },
      },
    });
    const scene = { format: "factoria.scene/1", settings: { gravity2D: [0, -1800] }, entities };
    if (dryRun) return { path, scene, widthTiles: W, coins: coins.length, enemies: enemies.length, seed, difficulty };
    const written = fa.call("fs.write", { path, content: JSON.stringify(scene, null, 1) + "\n" });
    return { path: written.path ?? path, widthTiles: W, coins: coins.length, enemies: enemies.length, seed, difficulty };
  },
};
