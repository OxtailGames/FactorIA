// @ts-check
// The ordered list of levels: the one place that says which levels exist, in which scene and with how much spring.
// Everything else (title screen, loading, results, progress, music) asks this module; adding a level is adding one entry.
//
//   id               stable key, saved in the progress file (never rename a shipped id)
//   name             English display name; nameKey the string-table key (locales/*.json) shown in the UI
//   district         "rooftops" (by day) or "market" (night): picks the music and the look
//   scene            project path of the scene
//   spring           seconds of spring the courier starts with (the level's time limit; wind-up keys add more)
//   parTime          seconds a good run takes: the `fast` goal of scripts/stars.js
//   parcels          required parcels: delivering them all wins the level
//   optionalParcels  extra parcels off the main route: delivering them all is the `thorough` goal
//   music            the streamed track of the district (scripts/music.js plays it)
//
// LEVELS is the player's list, in play order. TEST_LEVELS are scenes that only tests and the editor load (the yard and
// the prop arena): they are not in the title screen, not in progress and `next()` never leads into them.

/** @typedef {{ id: string, name: string, nameKey: string, district: string, scene: string, spring: number, parTime: number, parcels: number, optionalParcels: number, music: string }} Level */

export const MUSIC = Object.freeze({
  title: "assets/audio/cozy_puzzle_title_bpm95_0.ogg",
  rooftops: "assets/audio/loopcity_0.ogg",
  market: "assets/audio/urban_shop_bpm92_0.ogg",
});

/** @type {Level[]} */
export const LEVELS = [
  { id: "rooftops_1", name: "First Roofs", nameKey: "levels.rooftops_1", district: "rooftops", scene: "scenes/rooftops_1.scene.json", spring: 110, parTime: 50, parcels: 1, optionalParcels: 1, music: MUSIC.rooftops },
  { id: "rooftops_2", name: "Chimney Row", nameKey: "levels.rooftops_2", district: "rooftops", scene: "scenes/rooftops_2.scene.json", spring: 140, parTime: 70, parcels: 2, optionalParcels: 1, music: MUSIC.rooftops },
  { id: "rooftops_3", name: "Clock Square", nameKey: "levels.rooftops_3", district: "rooftops", scene: "scenes/rooftops_3.scene.json", spring: 160, parTime: 100, parcels: 2, optionalParcels: 1, music: MUSIC.rooftops },
  { id: "market_1", name: "Lantern Lane", nameKey: "levels.market_1", district: "market", scene: "scenes/market_1.scene.json", spring: 140, parTime: 60, parcels: 2, optionalParcels: 1, music: MUSIC.market },
  { id: "market_2", name: "Stall Street", nameKey: "levels.market_2", district: "market", scene: "scenes/market_2.scene.json", spring: 160, parTime: 80, parcels: 2, optionalParcels: 1, music: MUSIC.market },
  { id: "market_3", name: "Midnight Rush", nameKey: "levels.market_3", district: "market", scene: "scenes/market_3.scene.json", spring: 180, parTime: 100, parcels: 3, optionalParcels: 1, music: MUSIC.market },
];

/** Scenes outside the player's list that tests (and the editor) load: the movement yard and the prop arena. */
export const TEST_LEVELS = [
  { id: "test_yard", name: "Test Yard", nameKey: "levels.test_yard", district: "test", scene: "scenes/test_yard.scene.json", spring: 60, parTime: 40, parcels: 1, optionalParcels: 0, music: "" },
  { id: "test_arena", name: "Test Arena", nameKey: "levels.test_arena", district: "test", scene: "scenes/test_arena.scene.json", spring: 90, parTime: 60, parcels: 1, optionalParcels: 1, music: "" },
];

/** The level with this id (the player's list or a test scene), or null. */
export function byId(id) {
  return LEVELS.find((l) => l.id === id) ?? TEST_LEVELS.find((l) => l.id === id) ?? null;
}

/** The level whose scene is this path (the running scene), or null. */
export function byScene(path) {
  return LEVELS.find((l) => l.scene === path) ?? TEST_LEVELS.find((l) => l.scene === path) ?? null;
}

/** The level after `id` in the player's list, or null for the last one (and for a test scene). */
export function next(id) {
  const i = LEVELS.findIndex((l) => l.id === id);
  return i >= 0 && i + 1 < LEVELS.length ? LEVELS[i + 1] : null;
}

/** The first level (what Play starts for a new player). */
export function first() {
  return LEVELS[0];
}

/** Levels of one district, in order (the player's list only). */
export function inDistrict(district) {
  return LEVELS.filter((l) => l.district === district);
}
