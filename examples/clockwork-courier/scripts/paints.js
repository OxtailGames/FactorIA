// @ts-check
// The robot's paint schemes. A paint is a tint (MeshRenderer.color multiplies the glTF's own colours, so the dark eyes and
// joints stay dark; the robot is orange, so a blue paint is a dark tint plus a glow, not a blue multiplier) and a glow
// (MeshRenderer.emissive, added on top; there is no per-material colour, FB-0031). The numbers were tuned by looking at
// screenshots of the title robot. Which paints the player may use is decided here; which one is worn is kept by
// scripts/store.js (`equippedPaint()`), and apply() below puts it on a model (scripts/services.js does it for the courier and
// the title robot).
//
//   unlock  { type: "free" }                 always there
//           { type: "stars", stars: n }      opens when progress.totalStars() reaches n
//           { type: "product", product: id } a non-consumable of factoria.json platform.products (shop, restore purchases)
//
// Adding a paint is adding one entry here and its `shop.paint.<id>` key in locales/*.json.

/** @typedef {{ type: "free" } | { type: "stars", stars: number } | { type: "product", product: string }} PaintUnlock */
/** @typedef {{ id: string, nameKey: string, color: number[], emissive: number[], unlock: PaintUnlock }} Paint */

/** @type {Paint[]} */
export const PAINTS = [
  { id: "factory", nameKey: "shop.paint.factory", color: [1, 1, 1, 1], emissive: [0, 0, 0, 1], unlock: { type: "free" } },
  { id: "rust", nameKey: "shop.paint.rust", color: [0.75, 0.4, 0.3, 1], emissive: [0, 0, 0, 1], unlock: { type: "stars", stars: 3 } },
  { id: "mint", nameKey: "shop.paint.mint", color: [0.25, 0.3, 0.3, 1], emissive: [0, 0.32, 0.34, 1], unlock: { type: "stars", stars: 8 } },
  { id: "midnight", nameKey: "shop.paint.midnight", color: [0.15, 0.15, 0.2, 1], emissive: [0.05, 0.12, 0.4, 1], unlock: { type: "stars", stars: 13 } },
  { id: "gold", nameKey: "shop.paint.gold", color: [1, 1.3, 2.2, 1], emissive: [0.12, 0.08, 0, 1], unlock: { type: "stars", stars: 18 } },
  { id: "copper", nameKey: "shop.paint.copper", color: [0.9, 0.7, 0.55, 1], emissive: [0.08, 0.03, 0, 1], unlock: { type: "product", product: "paint_copper" } },
  { id: "neon", nameKey: "shop.paint.neon", color: [0.2, 0.2, 0.2, 1], emissive: [0.05, 0.6, 0.05, 1], unlock: { type: "product", product: "paint_neon" } },
];

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
  mesh.color = paint.color;
  mesh.emissive = paint.emissive;
}
