// @ts-check
// THE ordered list of levels: the only place it lives. Everything else (the main menu's Play, the level end panel's
// Next, progress, tests) asks this module. A level is its id, its world (1 = Courtyard, daylight; 2 = Cellars, dark),
// its scene file (built from levels/<id>.json by `factoria call scene.import_ascii @levels/<id>.json`) and the
// string-table key of its name.

/** Embers hidden in every level. */
export const EMBERS_PER_LEVEL = 3;

/** Worlds by number: the key of the world's name (locales/*.json) and whether it is dark (lit by the player's lantern). */
export const WORLDS = {
  1: { nameKey: "level.world.1", dark: false },
  2: { nameKey: "level.world.2", dark: true },
};

/** @type {ReadonlyArray<{ id: string, world: number, scene: string, nameKey: string }>} */
export const LEVELS = [
  { id: "1-1", world: 1, scene: "scenes/levels/1-1.scene.json", nameKey: "level.1-1" },
  { id: "1-2", world: 1, scene: "scenes/levels/1-2.scene.json", nameKey: "level.1-2" },
  { id: "1-3", world: 1, scene: "scenes/levels/1-3.scene.json", nameKey: "level.1-3" },
  { id: "2-1", world: 2, scene: "scenes/levels/2-1.scene.json", nameKey: "level.2-1" },
  { id: "2-2", world: 2, scene: "scenes/levels/2-2.scene.json", nameKey: "level.2-2" },
  { id: "2-3", world: 2, scene: "scenes/levels/2-3.scene.json", nameKey: "level.2-3" },
];

/** The level with this id, or null. */
export function find(id) {
  return LEVELS.find((l) => l.id === id) ?? null;
}

/** The level after `id`, or null after the last one (and for an unknown id). */
export function next(id) {
  const i = LEVELS.findIndex((l) => l.id === id);
  return i >= 0 ? LEVELS[i + 1] ?? null : null;
}

/** The level before `id`, or null before the first one. */
export function previous(id) {
  const i = LEVELS.findIndex((l) => l.id === id);
  return i > 0 ? LEVELS[i - 1] : null;
}
