// @ts-check
// The robot's paint schemes. A paint is the colour of the robot's body: `MeshRenderer.materialColors` replaces the base colour
// of one glTF material by name. assets/models/robot.glb has three: "Main" (the orange body, the one a paint changes), "Grey"
// (the metal joints) and "Black" (the eyes and the dark parts); the last two keep their own colour whatever the paint. The
// "factory" colour is the model's own orange. The numbers were tuned by looking at screenshots of the title robot. Which
// paints the player may use is decided here; which one is worn is kept by scripts/store.js (`equippedPaint()`), and apply()
// below puts it on a model (scripts/services.js does it for the courier and the title robot).
//
//   unlock  { type: "free" }                 always there
//           { type: "stars", stars: n }      opens when progress.totalStars() reaches n
//           { type: "product", product: id } a non-consumable of factoria.json platform.products (shop, restore purchases)
//
// Adding a paint is adding one entry here and its `shop.paint.<id>` key in locales/*.json.

/** @typedef {{ type: "free" } | { type: "stars", stars: number } | { type: "product", product: string }} PaintUnlock */
/** @typedef {{ id: string, nameKey: string, body: number[], unlock: PaintUnlock }} Paint */

/** @type {Paint[]} */
export const PAINTS = [
  { id: "factory", nameKey: "shop.paint.factory", body: [0.59, 0.29, 0.04, 1], unlock: { type: "free" } },
  { id: "rust", nameKey: "shop.paint.rust", body: [0.45, 0.16, 0.08, 1], unlock: { type: "stars", stars: 3 } },
  { id: "mint", nameKey: "shop.paint.mint", body: [0.1, 0.6, 0.5, 1], unlock: { type: "stars", stars: 8 } },
  { id: "midnight", nameKey: "shop.paint.midnight", body: [0.05, 0.1, 0.4, 1], unlock: { type: "stars", stars: 13 } },
  { id: "gold", nameKey: "shop.paint.gold", body: [0.9, 0.65, 0.1, 1], unlock: { type: "stars", stars: 18 } },
  { id: "copper", nameKey: "shop.paint.copper", body: [0.55, 0.32, 0.24, 1], unlock: { type: "product", product: "paint_copper" } },
  { id: "neon", nameKey: "shop.paint.neon", body: [0.15, 0.95, 0.15, 1], unlock: { type: "product", product: "paint_neon" } },
];

/** The glTF material of the robot's body (assets/models/robot.glb). */
export const BODY_MATERIAL = "Main";

/** The default paint: what a new player wears. */
export const DEFAULT_PAINT = "factory";

/** @param {string} id @returns {Paint | null} */
export function byId(id) {
  return PAINTS.find((p) => p.id === id) ?? null;
}

/**
 * Paints the model of `entity` (an entity with a MeshRenderer: the courier's "model", the title robot).
 * @param {any} entity @param {string} paintId
 */
export function apply(entity, paintId) {
  const paint = byId(paintId) ?? byId(DEFAULT_PAINT);
  const mesh = entity?.get("MeshRenderer");
  if (!mesh || !paint) return;
  mesh.materialColors = { [BODY_MATERIAL]: paint.body };
}
