// @ts-check
// project.map_preview: generate the map of a seed and show it as text (w water, s sand, g grass, f forest, r rock) with
// its hash and the share of each terrain, without starting the game. For tuning data/map.json and for bug reports.
import mapSettings from "../data/map.json";
import terrainTable from "../data/terrain.json";
import { generateMap, hashTerrain, mapToText } from "../scripts/game/mapgen.js";

export default {
  name: "map_preview",
  summary: "Show the map a seed generates (text, hash, terrain shares).",
  description:
    'Example: {"seed": 7}. Without a seed the default seed of data/map.json is used. Returns "text" (one character per cell, ' +
    "row r = line r, column c = character c; the characters are the `char` of data/terrain.json), \"hash\" (8 hex digits, " +
    'the map fingerprint tests compare) and "shares" (terrain id -> share of the cells).',
  input: { type: "object", properties: { seed: { type: "integer" } } },
  readOnly: true,
  run({ seed }) {
    const ids = Object.keys(terrainTable.terrain);
    const chars = ids.map((id) => terrainTable.terrain[id].char);
    const s = seed === undefined ? mapSettings.defaultSeed : seed;
    const map = generateMap(s, mapSettings, ids);
    const counts = {};
    for (const id of ids) counts[id] = 0;
    for (let i = 0; i < map.terrain.length; i++) counts[ids[map.terrain[i]]]++;
    const shares = {};
    for (const id of ids) shares[id] = Math.round((counts[id] / map.terrain.length) * 1000) / 1000;
    return { seed: s, size: [map.width, map.height], hash: hashTerrain(map), shares, text: mapToText(map, chars) };
  },
};
