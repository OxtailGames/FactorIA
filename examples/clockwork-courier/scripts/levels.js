// @ts-check
// The ordered list of levels: the one place that says which levels exist, in which scene and with how much spring.
// Everything else (title screen, loading, results, progress) asks this module; adding a level is adding one entry.
//
//   id        stable key, saved in the progress file (never rename a shipped id)
//   name      English display name; nameKey the string-table key (locales/*.json) shown in the UI
//   district  group of levels ("test" for the yard; the real districts come with later packages)
//   scene     project path of the scene
//   spring    seconds of spring the courier starts with (the level's time limit; P2 lets the player wind more)
//   parTime   seconds a good run takes: finishing under it earns the third star
//   parcels   parcels that must be delivered to win

/** @typedef {{ id: string, name: string, nameKey: string, district: string, scene: string, spring: number, parTime: number, parcels: number }} Level */

/** @type {Level[]} */
export const LEVELS = [
  {
    id: "test_yard",
    name: "Test Yard",
    nameKey: "levels.test_yard",
    district: "test",
    scene: "scenes/test_yard.scene.json",
    spring: 60,
    parTime: 40,
    parcels: 1,
  },
];

/** The level with this id, or null. */
export function byId(id) {
  return LEVELS.find((l) => l.id === id) ?? null;
}

/** The level whose scene is this path (the running scene), or null. */
export function byScene(path) {
  return LEVELS.find((l) => l.scene === path) ?? null;
}

/** The level after `id` in the list, or null for the last one. */
export function next(id) {
  const i = LEVELS.findIndex((l) => l.id === id);
  return i >= 0 && i + 1 < LEVELS.length ? LEVELS[i + 1] : null;
}

/** The first level (what Play starts for a new player). */
export function first() {
  return LEVELS[0];
}

/** Levels of one district, in order. */
export function inDistrict(district) {
  return LEVELS.filter((l) => l.district === district);
}
