// @ts-check
// What the player owns and wears, and the purchase flows of the shop. One module, no behaviour: the shop panel
// (scripts/ui/shop.js), the retry screen (scripts/ads.js: "Remove ads" keeps "more time" free) and the tests call it.
//
// Saved in `storage` under "store" as { version: 1, owned: [product ids], seen: [granted transaction ids], paint, tips }.
// `owned` is a local copy of the non-consumables the store says the player owns, so the game works offline; the store
// stays the authority: `reconcile()` (a start-up restore) adds what the store has and, on a real store, takes away what it
// no longer lists (a refund).
//
//   buy(productId)         the purchase flow, resolves { status: "purchased" | "pending" | "cancelled" | "failed", key, args }
//   restore()              the "Restore purchases" button, resolves { status: "restored" | "nothing" | "failed", key, args }
//   reconcile({authoritative})  start-up sync; the number of products added and revoked
//   listen(onChange)       grants purchases that arrive outside buy() (Ask to Buy approved, an unfinished one of the last run)
//   owns(product), noAds(), paintUnlocked(paint), equippedPaint(), equip(id)
//
// Grant first, finish after (docs: platform): the purchase is written to the save before the store is told it is done, and
// `seen` keeps the transaction ids so a purchase the store hands over twice never pays twice.
import { platform, storage } from "factoria";
import * as progress from "./progress.js";
import { DEFAULT_PAINT, byId } from "./paints.js";

const KEY = "store";

/** Product ids of factoria.json platform.products that the code treats specially. */
export const PRODUCTS = Object.freeze({ removeAds: "remove_ads", tipJar: "tip_jar" });

/** @returns {{ version: number, owned: string[], seen: string[], paint: string, tips: number }} */
export function load() {
  const saved = storage.get(KEY, null);
  const s = saved && typeof saved === "object" ? saved : {};
  return {
    version: 1,
    owned: Array.isArray(s.owned) ? s.owned.filter((x) => typeof x === "string") : [],
    seen: Array.isArray(s.seen) ? s.seen.filter((x) => typeof x === "string") : [],
    paint: typeof s.paint === "string" ? s.paint : DEFAULT_PAINT,
    tips: Number.isInteger(s.tips) ? s.tips : 0,
  };
}

function save(w) {
  w.seen = w.seen.slice(-200); // transaction ids only need to outlive the store's "unfinished" window
  storage.set(KEY, w);
}

/** Forgets everything (a "delete save" button, and the tests). */
export function reset() {
  storage.remove(KEY);
}

/** The kind of every product of factoria.json platform.products (the script API does not expose the catalog: FB-0029). */
const TYPES = { remove_ads: "nonConsumable", paint_copper: "nonConsumable", paint_neon: "nonConsumable", tip_jar: "consumable" };

/** The catalog entry of a product, or null. */
function catalogProduct(id) {
  return TYPES[id] ? { id, type: TYPES[id] } : null;
}

/** True when the player owns this non-consumable product. */
export function owns(product) {
  return load().owned.includes(product);
}

/** True when the player bought "Remove ads". */
export function noAds() {
  return owns(PRODUCTS.removeAds);
}

/** @param {import("./paints.js").Paint} paint */
export function paintUnlocked(paint) {
  const u = paint.unlock;
  if (u.type === "free") return true;
  if (u.type === "stars") return progress.totalStars() >= u.stars;
  return owns(u.product);
}

/** The paint the robot wears now: the saved one, or the default when it is not available any more (a refund). */
export function equippedPaint() {
  const paint = byId(load().paint);
  return paint && paintUnlocked(paint) ? paint.id : DEFAULT_PAINT;
}

/** Puts on a paint; false when it does not exist or is still locked. */
export function equip(id) {
  const paint = byId(id);
  if (!paint || !paintUnlocked(paint)) return false;
  const w = load();
  w.paint = id;
  save(w);
  return true;
}

/**
 * Writes what a purchase gave to the save. Returns true the first time the transaction is seen.
 * @param {{ productId: string, transactionId?: string }} purchase
 */
function grantLocal(purchase) {
  const w = load();
  const txn = purchase.transactionId ?? "";
  if (txn && w.seen.includes(txn)) return false;
  const product = catalogProduct(purchase.productId);
  if (product?.type === "consumable") {
    if (purchase.productId === PRODUCTS.tipJar) w.tips += 1;
  } else if (!w.owned.includes(purchase.productId)) {
    w.owned.push(purchase.productId);
  }
  if (txn) w.seen.push(txn);
  save(w);
  return true;
}

/**
 * Grants a purchase (once per transaction), then tells the store the game did. A finish that fails is not an error: the
 * store hands the transaction over again at the next start and `seen` makes it a no-op.
 * @param {{ productId: string, transactionId?: string }} purchase
 */
export async function grant(purchase) {
  const first = grantLocal(purchase);
  if (purchase.transactionId) {
    try {
      // try/await, not .catch(): finish() throws at the call for an unknown id (FB-0025)
      await platform.purchases.finish(purchase.transactionId);
    } catch (e) {
      /* the store hands it over again at the next start */
    }
  }
  return first;
}

/** The message of a failed store call: what the player can read and the code for the log. */
function failure(e) {
  return { status: "failed", key: "shop.unreachable", args: { code: e?.code ?? "error", detail: e?.hint ?? e?.message ?? "" } };
}

/**
 * The purchase flow of one product.
 * @param {string} productId
 * @returns {Promise<{ status: "purchased" | "pending" | "cancelled" | "failed", key: string, args?: any }>}
 */
export async function buy(productId) {
  try {
    const r = await platform.purchases.buy(productId);
    if (r.status === "purchased") {
      await grant(r);
      return { status: "purchased", key: "shop.thanks" };
    }
    if (r.status === "pending") return { status: "pending", key: "shop.pending" }; // the "purchase" event grants it later
    return { status: "cancelled", key: "shop.cancelled" };
  } catch (e) {
    return failure(e);
  }
}

/**
 * Adds what the store lists (non-consumables) to the save. With `authoritative` it also removes the products the store no
 * longer lists: a refund or a revoked purchase. The fake store keeps nothing between runs while the save does, so
 * revoking is off for it by default (a development run would lose every purchase at each start; the fake cannot refund, FB-0024).
 * @param {{ authoritative?: boolean }} [options]
 * @returns {Promise<{ ok: boolean, added: string[], revoked: string[], error?: any }>}
 */
export async function reconcile(options = {}) {
  const authoritative = options.authoritative ?? platform.backend !== "fake";
  let listed;
  try {
    listed = await platform.purchases.restore();
  } catch (e) {
    return { ok: false, added: [], revoked: [], error: e };
  }
  const w = load();
  const ids = new Set(listed.map((p) => p.productId));
  const added = [];
  const revoked = [];
  for (const id of ids) {
    if (catalogProduct(id)?.type !== "consumable" && !w.owned.includes(id)) {
      w.owned.push(id);
      added.push(id);
    }
  }
  if (authoritative) {
    for (const id of [...w.owned]) {
      if (!ids.has(id)) {
        w.owned.splice(w.owned.indexOf(id), 1);
        revoked.push(id);
      }
    }
  }
  if (added.length || revoked.length) save(w);
  return { ok: true, added, revoked };
}

/**
 * The "Restore purchases" button.
 * @returns {Promise<{ status: "restored" | "nothing" | "failed", key: string, args?: any }>}
 */
export async function restore() {
  const r = await reconcile({ authoritative: false });
  if (!r.ok) return failure(r.error);
  return r.added.length || owns(PRODUCTS.removeAds) || load().owned.length ? { status: "restored", key: "shop.restored" } : { status: "nothing", key: "shop.nothingToRestore" };
}

/**
 * Grants the purchases that arrive outside buy(): Ask to Buy approved, a purchase made in the store, an unfinished one from the
 * last run (the engine keeps those until the first listener exists). Call it in onStart: listeners end with the scene.
 * @param {(purchase: any) => void} [onChange] called after each new grant
 * @returns {() => void} stops listening
 */
export function listen(onChange) {
  return platform.on("purchase", (p) => {
    if (p.status !== "purchased") return;
    grant(p).then((first) => first && onChange?.(p));
  });
}
