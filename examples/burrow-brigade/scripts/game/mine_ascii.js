// @ts-check
// A mine as rows of text: `toRows(mine)` to look at a generated mine (tools/mine_preview.js prints it), `fromRows(rows)` to write a
// small mine by hand (scenes/test_mine.scene.json and the tests do). One character per tile:
//   .  floor        #  dirt          R  rock        H  hard rock     B  bedrock (an outside wall)
//   c  copper ore   s  silver ore    g  gold ore    G  gem ore
//   S  entry lift   E  exit lift     o  oil can     m  floor with a trapped mole
import { K, ORES, kindInfo } from "./tiles.js";
import { MINE_FORMAT, exitReachable, mineHash } from "./generator.js";

/** Character of each kind (the mole `m` is a floor tile listed in `mine.moles`). */
export const CHAR_OF = Object.freeze({
  [K.FLOOR]: ".", [K.DIRT]: "#", [K.ROCK]: "R", [K.HARD]: "H", [K.BEDROCK]: "B", [K.COPPER]: "c", [K.SILVER]: "s",
  [K.GOLD]: "g", [K.GEM]: "G", [K.LIFT_START]: "S", [K.LIFT_EXIT]: "E", [K.OIL]: "o",
});

/** @type {Record<string, number>} */
const KIND_OF = Object.freeze(Object.fromEntries(Object.entries(CHAR_OF).map(([k, c]) => [c, Number(k)])));

/**
 * The mine as one string per row (its current state: dug tiles show as floor).
 * @param {import("./generator.js").Mine} mine
 */
export function toRows(mine) {
  const moles = new Set(mine.moles.map((m) => m.ty * mine.width + m.tx));
  const rows = [];
  for (let y = 0; y < mine.height; y++) {
    let line = "";
    for (let x = 0; x < mine.width; x++) {
      const i = y * mine.width + x;
      line += moles.has(i) && mine.kinds[i] === K.FLOOR ? "m" : CHAR_OF[mine.kinds[i]];
    }
    rows.push(line);
  }
  return rows;
}

/**
 * Builds a mine from rows of text. Throws, naming the row and column, on a ragged row, an unknown character, or a mine
 * without exactly one `S` and one `E`.
 * @param {string[]} rows
 * @param {{seed?: number, stratum?: number, floor?: number}} [opts]
 * @returns {import("./generator.js").Mine}
 */
export function fromRows(rows, opts = {}) {
  if (!Array.isArray(rows) || rows.length === 0) throw new Error("fromRows(rows): rows must be a non-empty array of strings. Example: [\"BBBB\", \"BSEB\", \"BBBB\"].");
  const width = rows[0].length;
  /** @type {number[]} */
  const kinds = [];
  /** @type {{tx:number,ty:number}[]} */
  const moles = [];
  /** @type {{tx:number,ty:number}|null} */
  let start = null;
  /** @type {{tx:number,ty:number}|null} */
  let exit = null;
  let starts = 0, exits = 0;
  rows.forEach((line, ty) => {
    if (line.length !== width) throw new Error(`fromRows: row ${ty} has ${line.length} characters, row 0 has ${width}: all rows need the same width.`);
    for (let tx = 0; tx < width; tx++) {
      const ch = line[tx];
      if (ch === "m") {
        moles.push({ tx, ty });
        kinds.push(K.FLOOR);
        continue;
      }
      if (!(ch in KIND_OF)) throw new Error(`fromRows: unknown character '${ch}' at row ${ty}, column ${tx}. Use one of: ${Object.values(CHAR_OF).join(" ")} m.`);
      kinds.push(KIND_OF[ch]);
      if (ch === "S") { start = { tx, ty }; starts++; }
      if (ch === "E") { exit = { tx, ty }; exits++; }
    }
  });
  if (!start || !exit || starts !== 1 || exits !== 1) throw new Error(`fromRows: a mine needs exactly one S (entry lift) and one E (exit lift); found ${starts} S and ${exits} E.`);
  const s = /** @type {{tx:number,ty:number}} */ (start);
  const at = (/** @type {number} */ tx, /** @type {number} */ ty) => (tx >= 0 && ty >= 0 && tx < width && ty < rows.length ? kinds[ty * width + tx] : K.BEDROCK);
  const spawns = [[-1, 0], [1, 0], [0, 1], [0, -1]].map(([dx, dy]) => ({ tx: s.tx + dx, ty: s.ty + dy })).filter((p) => !kindInfo(at(p.tx, p.ty)).solid);
  /** @type {Record<string, number>} */
  const oreCounts = Object.fromEntries(ORES.map((o) => [o, 0]));
  for (const k of kinds) {
    const ore = kindInfo(k).ore;
    if (ore) oreCounts[ore]++;
  }
  /** @type {import("./generator.js").Mine} */
  const mine = {
    format: MINE_FORMAT, seed: opts.seed ?? 0, stratum: opts.stratum ?? 0, floor: opts.floor ?? 1, width, height: rows.length, kinds,
    start: s, exit: /** @type {{tx:number,ty:number}} */ (exit), spawns, moles, rooms: [], plugs: [], oreCounts,
    oilCount: kinds.filter((k) => k === K.OIL).length, solvable: false, hash: "",
  };
  mine.solvable = exitReachable(mine, 0);
  mine.hash = mineHash(mine);
  return mine;
}
