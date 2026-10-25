// project.mine_preview: what the generator makes for a seed, as numbers and text, without loading a scene.
import { generate, mineHash, stratumInfo } from "../scripts/game/generator.js";
import { toRows } from "../scripts/game/mine_ascii.js";

export default {
  name: "mine_preview",
  summary: "Generate a mine from a seed and show its hash, its numbers and its map as text.",
  description:
    "Runs the same generator the shift scene runs (scripts/game/generator.js) and returns the mine hash, the size, the ore counts, " +
    "whether the exit can be reached with the starting pick, and the map as rows of text (one character per tile: " +
    "# dirt, R rock, H hard rock, B bedrock, c s g G copper silver gold gem, S entry lift, E exit lift, o oil can, m trapped mole, . floor, w water, M magma, x cracked floor, * crystal, b t k where a beetle, a thief or the Mole King starts). " +
    "Example: {\"seed\": 1234, \"stratum\": 0, \"floor\": 1}. Add \"rows\": false to leave the map out.",
  input: {
    type: "object",
    properties: {
      seed: { type: "integer", default: 1234, description: "Seed of the mine. The same seed, stratum and floor always give the same mine." },
      stratum: { type: "integer", minimum: 0, default: 0, description: "Depth band: 0 Topsoil, 1 Crystal Caves, 2 Magma Deep." },
      floor: { type: "integer", minimum: 1, default: 1, description: "Floor within the stratum." },
      rows: { type: "boolean", default: true, description: "Include the map as rows of text." },
    },
  },
  readOnly: true,
  run({ seed = 1234, stratum = 0, floor = 1, rows = true }) {
    const mine = generate(seed, stratum, floor);
    return {
      hash: mineHash(mine),
      stratum: stratumInfo(stratum).id,
      width: mine.width,
      height: mine.height,
      oreCounts: mine.oreCounts,
      oilCount: mine.oilCount,
      moles: mine.moles.length,
      hazards: mine.hazards.map((h) => h.kind).reduce((n, k) => ({ ...n, [k]: (n[k] ?? 0) + 1 }), {}),
      enemies: mine.enemies.map((e) => e.kind).reduce((n, k) => ({ ...n, [k]: (n[k] ?? 0) + 1 }), {}),
      boss: mine.boss,
      rooms: mine.rooms.length,
      plugs: mine.plugs.length,
      solvable: mine.solvable,
      start: mine.start,
      exit: mine.exit,
      ...(rows ? { rows: toRows(mine) } : {}),
    };
  },
};
