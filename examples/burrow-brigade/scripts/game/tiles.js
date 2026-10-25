// @ts-check
// The tile kinds of the mine, their rules (solid, how long to dig, which pick tier) and where each one is drawn in the
// stratum's tileset (assets/tiles_topsoil.png, tiles_crystal.png, tiles_magma.png: the same indices, other colours;
// `tilesetOf` picks the file). Everything that knows what a tile "is" reads this table: the generator writes kinds, the map and the
// miner ask it for rules, and only `tileIndex` knows the picture.

/** Size of one tile in world units (the tileset's tile size too: one world unit is one tileset pixel). */
export const TILE = 16;

/** The tile kinds, as the numbers stored in `mine.kinds`. Never renumber them: saves and the mine hash use them. */
export const K = Object.freeze({
  FLOOR: 0,
  DIRT: 1,
  ROCK: 2,
  HARD: 3,
  BEDROCK: 4,
  COPPER: 5,
  SILVER: 6,
  GOLD: 7,
  GEM: 8,
  LIFT_START: 9,
  LIFT_EXIT: 10,
  OIL: 11,
  /** Water of a flood (P2): walkable, slows a miner down and drowns one who stays in it. */
  WATER: 12,
  /** Magma (P2): walkable, and burns a miner who steps on it. */
  MAGMA: 13,
  /** Cracked floor (P2): a miner who steps on it brings the roof down on the tiles around it (see hazards.js). */
  SHAKY: 14,
  /** Crystal wall (P2): a wall that glows (see lights.js) and is dug like rock. */
  CRYSTAL: 15,
});

/**
 * @typedef {object} KindInfo
 * @property {string} name        Short id, also the key of "kind.<name>" strings.
 * @property {boolean} solid      Blocks walking. Everything solid except bedrock can be dug.
 * @property {number} digTime     Seconds to dig it with a pick of speed 1 (Infinity = cannot be dug).
 * @property {number} tier        Lowest pick tier that can dig it (0 = the starting pick).
 * @property {string|null} ore    Ore name this tile gives when dug, or null.
 * @property {number} value       Cash value of one piece of that ore.
 * @property {number} base        First atlas index of the kind in the stratum tilesets (they share one index table).
 * @property {number} variants    How many atlas pictures it has in a row (the tile picks one from its position).
 */

/** @type {Record<number, KindInfo>} */
export const KINDS = Object.freeze({
  [K.FLOOR]: { name: "floor", solid: false, digTime: 0, tier: 0, ore: null, value: 0, base: 0, variants: 4 },
  [K.DIRT]: { name: "dirt", solid: true, digTime: 0.5, tier: 0, ore: null, value: 0, base: 4, variants: 4 },
  [K.ROCK]: { name: "rock", solid: true, digTime: 1.4, tier: 0, ore: null, value: 0, base: 8, variants: 4 },
  [K.HARD]: { name: "hard", solid: true, digTime: 2.2, tier: 1, ore: null, value: 0, base: 12, variants: 4 },
  [K.BEDROCK]: { name: "bedrock", solid: true, digTime: Infinity, tier: 99, ore: null, value: 0, base: 16, variants: 1 },
  [K.COPPER]: { name: "copper", solid: true, digTime: 0.6, tier: 0, ore: "copper", value: 1, base: 17, variants: 1 },
  [K.SILVER]: { name: "silver", solid: true, digTime: 1.5, tier: 0, ore: "silver", value: 3, base: 18, variants: 1 },
  [K.GOLD]: { name: "gold", solid: true, digTime: 2.4, tier: 1, ore: "gold", value: 8, base: 19, variants: 1 },
  [K.GEM]: { name: "gem", solid: true, digTime: 2.6, tier: 1, ore: "gem", value: 20, base: 20, variants: 1 },
  [K.LIFT_START]: { name: "liftStart", solid: false, digTime: 0, tier: 0, ore: null, value: 0, base: 21, variants: 1 },
  [K.LIFT_EXIT]: { name: "liftExit", solid: false, digTime: 0, tier: 0, ore: null, value: 0, base: 22, variants: 1 },
  [K.OIL]: { name: "oil", solid: false, digTime: 0, tier: 0, ore: null, value: 0, base: 23, variants: 1 },
  [K.WATER]: { name: "water", solid: false, digTime: 0, tier: 0, ore: null, value: 0, base: 24, variants: 2 },
  [K.MAGMA]: { name: "magma", solid: false, digTime: 0, tier: 0, ore: null, value: 0, base: 26, variants: 2 },
  [K.SHAKY]: { name: "shaky", solid: false, digTime: 0, tier: 0, ore: null, value: 0, base: 28, variants: 1 },
  [K.CRYSTAL]: { name: "crystal", solid: true, digTime: 1, tier: 0, ore: null, value: 0, base: 29, variants: 2 },
});

/** Kinds a miner must not walk through when it has a choice: the fluids and the cracked floor (the bot and the enemies avoid them). */
export const DANGER_KINDS = Object.freeze([K.WATER, K.MAGMA, K.SHAKY]);

/** True when the kind hurts a miner who stands on it (water, magma, cracked floor). */
export function isDangerKind(kind) {
  return kind === K.WATER || kind === K.MAGMA || kind === K.SHAKY;
}

/** The tileset file of a stratum's tile pictures. */
export const TILESETS = Object.freeze(["assets/tiles_topsoil.png", "assets/tiles_crystal.png", "assets/tiles_magma.png"]);

/** Path of the tileset for a stratum number (a number past the end uses the last one). */
export function tilesetOf(stratum) {
  return TILESETS[Math.max(0, Math.min(TILESETS.length - 1, Math.floor(stratum)))];
}

/** The ores, cheapest first: the keys of `run.ore`, the HUD rows and the results rows. */
export const ORES = Object.freeze(["copper", "silver", "gold", "gem"]);

/** Cash value of one piece of each ore. */
export const ORE_VALUE = Object.freeze({ copper: 1, silver: 3, gold: 8, gem: 20 });

/** Kind of the tile that holds each ore. */
export const ORE_KIND = Object.freeze({ copper: K.COPPER, silver: K.SILVER, gold: K.GOLD, gem: K.GEM });

/**
 * Rules of a kind. An unknown number is a bug in the caller: it throws with the valid range.
 * @param {number} kind
 * @returns {KindInfo}
 */
export function kindInfo(kind) {
  const info = KINDS[kind];
  if (!info) throw new Error(`unknown tile kind ${kind}: kinds are 0..${Object.keys(KINDS).length - 1} (see K in scripts/game/tiles.js)`);
  return info;
}

/** True when the kind blocks walking. */
export function isSolidKind(kind) {
  return kindInfo(kind).solid;
}

/** Hash of a tile position, for picking a picture variant without any random state (the same tile always looks the same). */
function spot(tx, ty) {
  let h = Math.imul(tx + 1013, 0x9e3779b1) ^ Math.imul(ty + 7919, 0x85ebca6b);
  h = Math.imul(h ^ (h >>> 15), 0x2c1b3c6d);
  return (h ^ (h >>> 12)) >>> 0;
}

/**
 * Index in the stratum tileset (the value written into `Tilemap.tiles`) of a tile of this kind at this place.
 * @param {number} kind
 * @param {number} tx
 * @param {number} ty
 */
export function tileIndex(kind, tx, ty) {
  const info = kindInfo(kind);
  return info.base + (info.variants > 1 ? spot(tx, ty) % info.variants : 0);
}

/** Region [x, y, w, h] of a sprite of assets/sprites.png (16 px cells, 8 per row). */
export function spriteRegion(index) {
  return [(index % 8) * TILE, Math.floor(index / 8) * TILE, TILE, TILE];
}

/** Indices in assets/sprites.png. */
export const SPRITE = Object.freeze({
  MINER: [0, 1, 2, 3],
  MOLE_TRAPPED: 4,
  MOLE_FREE: 5,
  CURSOR: 6,
  OIL_ICON: 7,
  ORE_ICON: { copper: 8, silver: 9, gold: 10, gem: 11 },
  CRACK: [12, 13, 14],
  TORCH: 15,
  BEETLE: 16,
  THIEF: 17,
  KING: 18,
  WARNING: 19,
  ROCK: 20,
});
