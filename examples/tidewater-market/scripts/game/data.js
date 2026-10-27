// @ts-check
// The data tables (data/*.json) and the checks that make a mistake in them fail clearly, at the start of the game and in
// `factoria call project.validate_data`, instead of as a strange bug three screens later.
//
// validateTables(raw) is pure: it takes the parsed files and returns a list of problems, each one naming the file, the
// JSON pointer, what is wrong and how to fix it ("did you mean" for a misspelled id). loadData(raw) returns the catalogue
// the rest of the game reads, or throws a DataError that lists every problem at once.
import terrainJson from "../../data/terrain.json";
import goodsJson from "../../data/goods.json";
import recipesJson from "../../data/recipes.json";
import buildingsJson from "../../data/buildings.json";
import economyJson from "../../data/economy.json";
import seasonsJson from "../../data/seasons.json";
import mapJson from "../../data/map.json";
import testMapJson from "../../data/test_map.json";
import atlasJson from "../../data/atlas.json";
import enLocale from "../../locales/en.json";

/** The files as they are on disk, the input of validateTables and loadData. */
export const rawTables = {
  terrain: terrainJson,
  goods: goodsJson,
  recipes: recipesJson,
  buildings: buildingsJson,
  economy: economyJson,
  seasons: seasonsJson,
  map: mapJson,
  testMap: testMapJson,
  atlas: atlasJson,
  locale: enLocale,
};

const FILES = {
  terrain: "data/terrain.json",
  goods: "data/goods.json",
  recipes: "data/recipes.json",
  buildings: "data/buildings.json",
  economy: "data/economy.json",
  seasons: "data/seasons.json",
  map: "data/map.json",
  testMap: "data/test_map.json",
  atlas: "data/atlas.json",
};

export class DataError extends Error {
  /** @param {Problem[]} problems */
  constructor(problems) {
    super(formatProblems(problems));
    this.name = "DataError";
    this.problems = problems;
  }
}

/** @typedef {{ file: string, pointer: string, message: string, hint: string }} Problem */

/** @param {Problem[]} problems */
export function formatProblems(problems) {
  const lines = problems.map((p) => `${p.file} ${p.pointer || "/"}: ${p.message}${p.hint ? " (" + p.hint + ")" : ""}`);
  return `${problems.length} problem${problems.length === 1 ? "" : "s"} in the data tables:\n  ` + lines.join("\n  ");
}

function editDistance(a, b) {
  const prev = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    let diag = prev[0];
    prev[0] = i;
    for (let j = 1; j <= b.length; j++) {
      const tmp = prev[j];
      prev[j] = Math.min(prev[j] + 1, prev[j - 1] + 1, diag + (a[i - 1] === b[j - 1] ? 0 : 1));
      diag = tmp;
    }
  }
  return prev[b.length];
}

/** The candidate closest to `word` when it is close enough to be a typo, else null. */
export function didYouMean(word, candidates) {
  let best = null;
  let bestD = Infinity;
  for (const c of candidates) {
    const d = editDistance(String(word).toLowerCase(), c.toLowerCase());
    if (d < bestD) {
      bestD = d;
      best = c;
    }
  }
  return best !== null && bestD <= Math.max(2, Math.floor(String(word).length / 3)) ? best : null;
}

const isObject = (v) => v !== null && typeof v === "object" && !Array.isArray(v);
const isInt = (v) => Number.isInteger(v);
const lookup = (obj, path) => path.split(".").reduce((o, k) => (o && typeof o === "object" ? o[k] : undefined), obj);

/**
 * Check the tables against each other. Returns every problem found (an empty array means the data is sound).
 * @param {typeof rawTables} raw
 * @returns {Problem[]}
 */
export function validateTables(raw) {
  /** @type {Problem[]} */
  const problems = [];
  const add = (table, pointer, message, hint = "") => problems.push({ file: FILES[table] || table, pointer, message, hint });
  const unknown = (table, pointer, what, word, list, where) => {
    const guess = didYouMean(word, list);
    add(
      table,
      pointer,
      `unknown ${what} '${word}'`,
      (guess ? `did you mean '${guess}'? ` : "") + `${where} has: ${list.join(", ")}`,
    );
  };

  for (const [name, file] of Object.entries(FILES)) {
    if (!isObject(raw[name])) add(name, "", "the file is missing or is not a JSON object", `create ${file} (see the other tables for the shape)`);
  }
  if (problems.length) return problems;

  const frames = isObject(raw.atlas.frames) ? raw.atlas.frames : {};
  const frameNames = Object.keys(frames);
  const needFrame = (table, pointer, frame) => {
    if (typeof frame !== "string" || !frames[frame]) {
      const guess = typeof frame === "string" ? didYouMean(frame, frameNames) : null;
      add(table, pointer, `atlas frame '${frame}' does not exist`, (guess ? `did you mean '${guess}'? ` : "") + "frames are listed in data/atlas.json (made by assets.pack_atlas from assets/src/frames)");
    }
  };
  const needLocale = (table, pointer, key) => {
    if (typeof lookup(raw.locale, key) !== "string") {
      add(table, pointer, `the locale string '${key}' is missing`, `add it to locales/en.json (every player-facing text goes through the locale files)`);
    }
  };

  // terrain
  const terrain = isObject(raw.terrain.terrain) ? raw.terrain.terrain : {};
  const terrainIds = Object.keys(terrain);
  if (!terrainIds.length) add("terrain", "/terrain", "no terrain kinds", "add at least water and grass");
  const chars = {};
  for (const id of terrainIds) {
    const t = terrain[id];
    const p = `/terrain/${id}`;
    if (typeof t.char !== "string" || t.char.length !== 1) add("terrain", `${p}/char`, "char must be one character", "it is how test_map.json writes the terrain");
    else if (chars[t.char]) add("terrain", `${p}/char`, `char '${t.char}' is also used by '${chars[t.char]}'`, "every terrain needs its own character");
    else chars[t.char] = id;
    needFrame("terrain", `${p}/frame`, t.frame);
    if (!Number.isInteger(t.tile) || t.tile < 0) add("terrain", `${p}/tile`, "tile must be a whole number, the cell's index in the terrain tilesets", "see tileset in data/terrain.json");
    for (const f of ["buildable", "roadable"]) if (typeof t[f] !== "boolean") add("terrain", `${p}/${f}`, `${f} must be true or false`);
    needLocale("terrain", p, `terrain.${id}`);
  }
  const tileset = raw.terrain.tileset;
  if (!isObject(tileset)) add("terrain", "/tileset", "the tileset table is missing", "it says how the terrain tilesets are laid out (see assets/src/make_terrain_tiles.py)");
  else {
    for (const f of ["roadTile", "treeTile", "treeVariants", "columns"]) {
      if (!Number.isInteger(tileset[f]) || tileset[f] < 0) add("terrain", `/tileset/${f}`, `${f} must be a whole number`, "see the comment of the tileset table");
    }
    if (!Array.isArray(tileset.tileSize) || tileset.tileSize.length !== 2) add("terrain", "/tileset/tileSize", "tileSize must be [width, height]", "the size of one cell of the tileset PNGs");
    for (const season of Object.keys(isObject(raw.seasons.seasons) ? raw.seasons.seasons : {})) {
      if (!isObject(tileset.seasons) || typeof tileset.seasons[season] !== "string") add("terrain", `/tileset/seasons/${season}`, `the season '${season}' has no tileset picture`, "name its PNG, made by assets/src/make_terrain_tiles.py");
    }
  }
  for (const must of ["water", "sand", "grass", "forest", "rock"]) {
    if (!terrain[must]) add("terrain", "/terrain", `the terrain '${must}' is missing`, "the map generator and the rules refer to it by id");
  }

  // goods
  const goods = isObject(raw.goods.goods) ? raw.goods.goods : {};
  const goodIds = Object.keys(goods);
  if (!goodIds.length) add("goods", "/goods", "no goods", "add at least one good");
  for (const id of goodIds) {
    const g = goods[id];
    const p = `/goods/${id}`;
    if (id === "coins") add("goods", p, "'coins' is the money and cannot also be a good", "choose another id");
    needFrame("goods", `${p}/icon`, g.icon);
    if (typeof g.basePrice !== "number" || !(g.basePrice > 0)) add("goods", `${p}/basePrice`, "basePrice must be a number above 0", "the coins one unit sells for at normal demand");
    if (g.nutrition !== undefined && (typeof g.nutrition !== "number" || !(g.nutrition > 0))) add("goods", `${p}/nutrition`, "nutrition must be a number above 0", "how far one unit lowers a villager's hunger; leave it out for a good nobody eats");
    needLocale("goods", p, `good.${id}`);
  }
  if (!goodIds.some((id) => goods[id].nutrition > 0)) add("goods", "/goods", "no good has a nutrition", "villagers need at least one food (fish, bread...) with \"nutrition\": 1");

  // costs, shared by buildings
  const checkAmounts = (table, pointer, amounts, allowCoins) => {
    if (!isObject(amounts)) return add(table, pointer, "must be an object of amounts", allowCoins ? '{"coins": 40, "wood": 4}' : '{"wood": 2}');
    for (const [k, v] of Object.entries(amounts)) {
      if (!(allowCoins && k === "coins") && !goods[k]) unknown(table, `${pointer}/${k}`, "good", k, allowCoins ? ["coins", ...goodIds] : goodIds, "data/goods.json");
      if (!isInt(v) || v < 0) add(table, `${pointer}/${k}`, `the amount must be a whole number, 0 or more (got ${JSON.stringify(v)})`);
    }
  };

  // buildings
  const buildings = isObject(raw.buildings.buildings) ? raw.buildings.buildings : {};
  const buildingIds = Object.keys(buildings);
  if (!buildings.road) add("buildings", "/buildings", "the building 'road' is missing", "roads are the one kind of building with kind \"road\"; the view and the rules refer to it by id");
  const recipes = isObject(raw.recipes.recipes) ? raw.recipes.recipes : {};
  const recipeIds = Object.keys(recipes);
  for (const id of buildingIds) {
    const b = buildings[id];
    const p = `/buildings/${id}`;
    if (b.kind !== "road" && b.kind !== "building") add("buildings", `${p}/kind`, `kind must be "road" or "building" (got ${JSON.stringify(b.kind)})`);
    if (!Array.isArray(b.size) || b.size.length !== 2 || !b.size.every((n) => isInt(n) && n >= 1 && n <= 6)) {
      add("buildings", `${p}/size`, `size must be [w, h], two whole numbers from 1 to 6 (got ${JSON.stringify(b.size)})`, "cells along c and along r at rotation 0");
    }
    checkAmounts("buildings", `${p}/cost`, b.cost, true);
    if (!Array.isArray(b.terrain) || !b.terrain.length) add("buildings", `${p}/terrain`, "terrain must list the terrain ids a footprint cell may stand on", 'for example ["sand", "grass"]');
    else b.terrain.forEach((t, i) => terrain[t] || unknown("buildings", `${p}/terrain/${i}`, "terrain", t, terrainIds, "data/terrain.json"));
    if (b.requireRoad !== undefined && b.requireRoad !== "frontage") add("buildings", `${p}/requireRoad`, `requireRoad can only be "frontage" (got ${JSON.stringify(b.requireRoad)})`, "a road cell on the side the building faces");
    if (b.nearWater !== undefined && typeof b.nearWater !== "boolean") add("buildings", `${p}/nearWater`, "nearWater must be true or false");
    for (const f of ["housing", "workers", "storage", "upkeep", "jobPriority"]) if (b[f] !== undefined && (!isInt(b[f]) || b[f] < 0)) add("buildings", `${p}/${f}`, `${f} must be a whole number, 0 or more`);
    if (b.workers > 0 && b.recipes !== undefined && !b.recipes.length) add("buildings", `${p}/recipes`, "a building with workers and an empty recipe list has nothing to do", "list a recipe or remove the key");
    if (b.recipes !== undefined) {
      if (!Array.isArray(b.recipes)) add("buildings", `${p}/recipes`, "recipes must be a list of recipe ids");
      else {
        b.recipes.forEach((r, i) => {
          if (!recipes[r]) unknown("buildings", `${p}/recipes/${i}`, "recipe", r, recipeIds, "data/recipes.json");
          else if (recipes[r].building !== id) add("buildings", `${p}/recipes/${i}`, `recipe '${r}' says it belongs to '${recipes[r].building}'`, `set its "building" to '${id}' in data/recipes.json`);
        });
      }
    }
    if (b.kind === "road") for (const piece of new Set(Object.values(raw.atlas.roadFrames || {}))) needFrame("buildings", `${p}/frames`, piece);
    else for (let rot = 0; rot < 4; rot++) needFrame("buildings", `${p}`, `building.${id}.${rot}`);
    needLocale("buildings", p, `building.${id}.name`);
    needLocale("buildings", p, `building.${id}.desc`);
  }
  // the palette needs a name for each category too
  for (const id of buildingIds) if (buildings[id].category) needLocale("buildings", `/buildings/${id}/category`, `category.${buildings[id].category}`);

  // recipes
  for (const id of recipeIds) {
    const r = recipes[id];
    const p = `/recipes/${id}`;
    if (!buildings[r.building]) unknown("recipes", `${p}/building`, "building", r.building, buildingIds, "data/buildings.json");
    else if (!(buildings[r.building].recipes || []).includes(id)) add("recipes", `${p}/building`, `'${r.building}' does not list the recipe '${id}'`, `add "${id}" to the recipes of '${r.building}' in data/buildings.json`);
    checkAmounts("recipes", `${p}/inputs`, r.inputs, false);
    checkAmounts("recipes", `${p}/outputs`, r.outputs, false);
    if (isObject(r.outputs) && !Object.keys(r.outputs).length) add("recipes", `${p}/outputs`, "a recipe must make something", "list at least one good");
    if (typeof r.seconds !== "number" || !(r.seconds > 0)) add("recipes", `${p}/seconds`, "seconds must be a number above 0", "game seconds per cycle");
  }

  // economy
  const e = raw.economy;
  if (!isObject(e.start) || !isInt(e.start.coins) || e.start.coins < 0) add("economy", "/start/coins", "start.coins must be a whole number, 0 or more");
  else checkAmounts("economy", "/start/stock", e.start.stock || {}, false);
  if (typeof e.refund !== "number" || e.refund < 0 || e.refund > 1) add("economy", "/refund", `refund must be a number from 0 to 1 (got ${JSON.stringify(e.refund)})`, "the share of the cost handed back on demolish");
  if (!isInt(e.undoLimit) || e.undoLimit < 1) add("economy", "/undoLimit", "undoLimit must be a whole number, 1 or more");
  const cal = e.calendar;
  if (!isObject(cal) || !Array.isArray(cal.seasons) || !cal.seasons.length) add("economy", "/calendar/seasons", "calendar.seasons must be a list of season ids");
  else {
    cal.seasons.forEach((s) => needLocale("economy", "/calendar/seasons", `season.${s}`));
    if (!isInt(cal.daysPerSeason) || cal.daysPerSeason < 1) add("economy", "/calendar/daysPerSeason", "daysPerSeason must be a whole number, 1 or more");
    if (typeof cal.secondsPerDay !== "number" || !(cal.secondsPerDay > 0)) add("economy", "/calendar/secondsPerDay", "secondsPerDay must be a number above 0");
    if (!isInt(cal.startYear)) add("economy", "/calendar/startYear", "startYear must be a whole number");
    if (typeof cal.tickSeconds !== "number" || !(cal.tickSeconds > 0) || (typeof cal.secondsPerDay === "number" && cal.tickSeconds > cal.secondsPerDay)) {
      add("economy", "/calendar/tickSeconds", "tickSeconds must be a number above 0 and not above secondsPerDay", "the fixed step of the simulation, for example 0.2");
    }
  }

  // the knobs of the simulation
  const sim = e.sim;
  if (!isObject(sim)) add("economy", "/sim", "the sim block is missing", "see scripts/game/sim.js for the keys it reads");
  else {
    const positive = ["productionRate", "foodPerDay", "unpaidEfficiency", "dispatchSeconds", "patienceSeconds", "growthSeconds", "firstArrivalSeconds", "foodBuffer", "shopBelow", "growthFoodDays"];
    for (const k of positive) if (typeof sim[k] !== "number" || !(sim[k] > 0)) add("economy", `/sim/${k}`, `${k} must be a number above 0 (got ${JSON.stringify(sim[k])})`);
    for (const k of ["wagePerDay", "hungerLimitDays", "unemployedLimit", "baseStorage", "carrierCapacity", "outboxCycles", "inboxCycles", "marketTarget", "founders"]) {
      if (!isInt(sim[k]) || sim[k] < 0) add("economy", `/sim/${k}`, `${k} must be a whole number, 0 or more (got ${JSON.stringify(sim[k])})`);
    }
    for (const k of ["workStartDay", "workEndDay", "marketCloseDay", "departSpreadDay"]) if (typeof sim[k] !== "number" || sim[k] < 0 || sim[k] > 1) add("economy", `/sim/${k}`, `${k} must be a fraction of a day from 0 to 1 (got ${JSON.stringify(sim[k])})`);
    if (!(sim.workStartDay < sim.workEndDay && sim.workEndDay < sim.marketCloseDay)) add("economy", "/sim", "the day must run workStartDay < workEndDay < marketCloseDay", "for example 0.05, 0.62, 0.92");
    if (typeof sim.foodBuffer === "number" && typeof sim.shopBelow === "number" && sim.shopBelow > sim.foodBuffer) add("economy", "/sim/shopBelow", "shopBelow must not be above foodBuffer", "a villager shops when its food drops below shopBelow and buys up to foodBuffer");
    if (!isObject(sim.walkSpeed) || !["villager", "carrier"].every((k) => typeof sim.walkSpeed[k] === "number" && sim.walkSpeed[k] > 0)) add("economy", "/sim/walkSpeed", "walkSpeed needs a number above 0 (cells per second) for villager and carrier");
  }

  // seasons
  const seasons = isObject(raw.seasons.seasons) ? raw.seasons.seasons : {};
  if (isObject(cal) && Array.isArray(cal.seasons)) {
    for (const id of cal.seasons) if (!seasons[id]) add("seasons", "/seasons", `the season '${id}' of the calendar has no entry`, `add "${id}" to data/seasons.json`);
  }
  for (const [id, season] of Object.entries(seasons)) {
    const p = `/seasons/${id}`;
    if (isObject(cal) && Array.isArray(cal.seasons) && !cal.seasons.includes(id)) unknown("seasons", p, "season", id, cal.seasons, "data/economy.json calendar.seasons");
    for (const [field, list, what] of [["production", recipeIds, "recipe"], ["demand", goodIds, "good"]]) {
      if (!isObject(season[field])) {
        add("seasons", `${p}/${field}`, `${field} must be an object of multipliers`);
        continue;
      }
      for (const [k, v] of Object.entries(season[field])) {
        if (!list.includes(k)) unknown("seasons", `${p}/${field}/${k}`, what, k, list, field === "production" ? "data/recipes.json" : "data/goods.json");
        if (typeof v !== "number" || v < 0) add("seasons", `${p}/${field}/${k}`, `the multiplier must be a number, 0 or more (got ${JSON.stringify(v)})`);
      }
    }
    if (!Array.isArray(season.tint) || season.tint.length !== 4 || !season.tint.every((n) => typeof n === "number")) add("seasons", `${p}/tint`, "tint must be [r, g, b, a], four numbers", "1 leaves the colour as it is");
    if (typeof season.music !== "string" || !season.music) add("seasons", `${p}/music`, "music must be the path of an audio file", 'for example "assets/music/spring.wav"');
    if (typeof season.musicVolume !== "number" || season.musicVolume < 0 || season.musicVolume > 1) add("seasons", `${p}/musicVolume`, "musicVolume must be a number from 0 to 1");
  }

  // map settings
  const m = raw.map;
  if (!Array.isArray(m.size) || m.size.length !== 2 || !m.size.every((n) => isInt(n) && n >= 8 && n <= 128)) add("map", "/size", `size must be [width, height], whole numbers from 8 to 128 (got ${JSON.stringify(m.size)})`);
  for (const f of ["scale", "moistureScale", "rockScale"]) if (typeof m[f] !== "number" || !(m[f] >= 1)) add("map", `/${f}`, `${f} must be a number, 1 or more`, "noise cell size in map cells");
  if (typeof m.falloff !== "number" || m.falloff < 0) add("map", "/falloff", "falloff must be a number, 0 or more");
  if (!isInt(m.defaultSeed)) add("map", "/defaultSeed", "defaultSeed must be a whole number");
  const th = m.thresholds;
  if (!isObject(th) || !["water", "sand", "rock", "forest"].every((k) => typeof th[k] === "number")) add("map", "/thresholds", "thresholds needs numbers for water, sand, rock and forest");
  else if (!(th.water < th.sand)) add("map", "/thresholds", `thresholds.water (${th.water}) must be below thresholds.sand (${th.sand})`, "elevation below water is water, below sand is sand");

  // the hand-made test map
  const rows = raw.testMap.rows;
  if (!Array.isArray(rows) || !rows.length || !rows.every((r) => typeof r === "string")) add("testMap", "/rows", "rows must be a list of strings, one per row of the map");
  else {
    rows.forEach((row, r) => {
      if (row.length !== rows[0].length) add("testMap", `/rows/${r}`, `this row has ${row.length} cells, row 0 has ${rows[0].length}`, "all rows need the same length");
      for (let c = 0; c < row.length; c++) {
        if (!chars[row[c]]) {
          add("testMap", `/rows/${r}`, `unknown terrain character '${row[c]}' at column ${c}`, `the characters are: ${Object.keys(chars).map((k) => `${k} = ${chars[k]}`).join(", ")}`);
          break;
        }
      }
    });
  }

  // the atlas the pictures come from
  if (typeof raw.atlas.texture !== "string") add("atlas", "/texture", "texture must be the path of the atlas picture");
  for (const [name, f] of Object.entries(frames)) {
    if (!Array.isArray(f.rect) || f.rect.length !== 4 || !Array.isArray(f.pivot)) add("atlas", `/frames/${name}`, "a frame needs rect [x, y, w, h] and pivot [x, y]", "pack again: factoria call assets.pack_atlas (README, Assets)");
  }
  return problems;
}

/**
 * The catalogue the game reads. Throws a DataError listing every problem when the tables are not sound.
 * @param {typeof rawTables} [raw]
 */
export function loadData(raw = rawTables) {
  const problems = validateTables(raw);
  if (problems.length) throw new DataError(problems);
  const terrainIds = Object.keys(raw.terrain.terrain);
  const terrain = {};
  const terrainByChar = {};
  terrainIds.forEach((id, index) => {
    terrain[id] = { id, index, ...raw.terrain.terrain[id] };
    terrainByChar[terrain[id].char] = index;
  });
  const goods = Object.fromEntries(Object.entries(raw.goods.goods).map(([id, g]) => [id, { id, ...g }]));
  const buildings = Object.fromEntries(Object.entries(raw.buildings.buildings).map(([id, b]) => [id, { id, ...b }]));
  const recipes = Object.fromEntries(Object.entries(raw.recipes.recipes).map(([id, r]) => [id, { id, ...r }]));
  return {
    terrainIds,
    terrain,
    terrainByChar,
    tileset: raw.terrain.tileset,
    goodIds: Object.keys(goods),
    goods,
    buildingIds: Object.keys(buildings),
    buildings,
    recipes,
    economy: raw.economy,
    calendar: raw.economy.calendar,
    sim: raw.economy.sim,
    seasons: raw.seasons.seasons,
    map: raw.map,
    testMap: raw.testMap,
    atlas: raw.atlas,
  };
}

/** @type {ReturnType<typeof loadData> | null} */
let cached = null;

/** The catalogue of the files on disk, checked once per run (and again after a hot reload of this module). */
export function getData() {
  if (!cached) cached = loadData(rawTables);
  return cached;
}
