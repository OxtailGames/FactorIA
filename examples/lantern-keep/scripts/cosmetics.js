// @ts-check
// The cosmetics the shop sells, and the player's wallet. Cosmetics only: nothing here changes how the game plays.
//   - "lantern_colours" (non-consumable) unlocks the rose, azure, jade and violet lanterns.
//   - "supporter" (non-consumable) unlocks the gold lantern and a line in the credits.
// What the player owns is kept in storage under "wallet"; the chosen colour is a player setting (settings.js, `lanternColour`).
// A purchase is granted first and finished after (docs: platform, "Purchases: grant, then finish").
import { Behaviour, platform, storage } from "factoria";
import * as settings from "./settings.js";

/** The product ids of factoria.json "platform.products". */
export const PRODUCTS = ["lantern_colours", "supporter"];

/**
 * Every lantern colour. `product` is what unlocks it (null: the player always has it). `light` colours the lantern's light and
 * flame, `body` the bearer's coat.
 */
export const COLOURS = [
  { id: "amber", product: null, light: [1, 0.78, 0.42, 1], flame: [1, 0.85, 0.4, 1], glow: [1, 0.7, 0.25, 0.22], body: [0.28, 0.5, 0.62, 1] },
  { id: "rose", product: "lantern_colours", light: [1, 0.5, 0.62, 1], flame: [1, 0.62, 0.72, 1], glow: [1, 0.35, 0.5, 0.22], body: [0.62, 0.3, 0.4, 1] },
  { id: "azure", product: "lantern_colours", light: [0.45, 0.75, 1, 1], flame: [0.62, 0.85, 1, 1], glow: [0.3, 0.6, 1, 0.22], body: [0.22, 0.34, 0.62, 1] },
  { id: "jade", product: "lantern_colours", light: [0.45, 1, 0.7, 1], flame: [0.62, 1, 0.8, 1], glow: [0.3, 0.9, 0.55, 0.22], body: [0.2, 0.5, 0.38, 1] },
  { id: "violet", product: "lantern_colours", light: [0.75, 0.55, 1, 1], flame: [0.82, 0.68, 1, 1], glow: [0.62, 0.4, 1, 0.22], body: [0.4, 0.3, 0.62, 1] },
  { id: "gold", product: "supporter", light: [1, 0.9, 0.35, 1], flame: [1, 0.95, 0.55, 1], glow: [1, 0.85, 0.2, 0.3], body: [0.7, 0.55, 0.2, 1] },
];

/** What the player owns, from storage: `{ owned: [productId], seen: [transactionId] }` (`seen` = purchases already granted). */
export function wallet() {
  return { owned: [], seen: [], ...storage.get("wallet", {}) };
}

export function owns(productId) {
  return wallet().owned.includes(productId);
}

/** The colours the player may pick now. */
export function available() {
  return COLOURS.filter((c) => c.product === null || owns(c.product));
}

/** The colour the player chose; amber when the choice is not owned (any more) or unknown. */
export function chosen() {
  const id = settings.load().lanternColour;
  return available().find((c) => c.id === id) ?? COLOURS[0];
}

export function choose(id) {
  const colour = available().find((c) => c.id === id);
  if (!colour) throw new Error(`cosmetics.choose: "${id}" is not available. Available: ${available().map((c) => c.id).join(", ")}.`);
  settings.save({ ...settings.load(), lanternColour: id });
}

/**
 * Gives the player what `purchase` ({ productId, transactionId? }) bought, once per transaction, then tells the store it is done.
 * Without a transactionId (a restored purchase: owned already) it only adds the product and finishes nothing. Resolves true
 * when something new was granted. A store failure while finishing is not lost: the store hands the purchase over again.
 */
export async function grant(purchase) {
  const w = wallet();
  let fresh = false;
  if (purchase.transactionId !== undefined && !w.seen.includes(purchase.transactionId)) {
    w.seen.push(purchase.transactionId);
    fresh = true;
  }
  if (PRODUCTS.includes(purchase.productId) && !w.owned.includes(purchase.productId)) {
    w.owned.push(purchase.productId);
    fresh = true;
  }
  if (fresh) storage.set("wallet", w);
  if (purchase.transactionId === undefined) return fresh;
  try {
    await platform.purchases.finish(purchase.transactionId);
  } catch (e) {
    console.warn(`cosmetics: could not tell the store about ${purchase.transactionId}: ${e.message}`);
  }
  return fresh;
}

/** Puts the chosen colour on the player of a level (the body, the lantern's flame, its light and its glow). */
export default class Cosmetics extends Behaviour {
  onStart() {
    const colour = chosen();
    const player = this.world.find("player");
    if (!player) return;
    player.get("Shape2D").color = colour.body;
    const lantern = player.children.find((c) => c.name === "Lantern");
    if (!lantern) return;
    lantern.get("Shape2D").color = colour.flame;
    lantern.get("Light2D").color = colour.light;
    const glow = lantern.children.find((c) => c.name === "Glow");
    if (glow) glow.get("Shape2D").color = colour.glow;
  }
}
