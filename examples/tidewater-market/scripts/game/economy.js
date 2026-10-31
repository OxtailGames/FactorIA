// @ts-check
// The economy state: coins and the stock of each good (pure). P1 only spends and refunds building costs; P2 adds
// production, P3 prices and trade. Every change goes through apply(), which refuses to go below zero and emits
// "economy.changed", so a HUD (or an achievement) can follow one event.
//
// An amount list ("delta") is a flat object: { coins: 40, wood: 4 } - the key "coins" is money, every other key is a good.
// A cost is a delta of positive numbers; paying it applies the negated delta.

/** @param {Record<string, number>} amounts */
export function negate(amounts) {
  const out = {};
  for (const [k, v] of Object.entries(amounts)) if (v) out[k] = -v;
  return out;
}

/** The share of a cost handed back on demolish, rounded down per item. */
export function refundOf(cost, share) {
  const out = {};
  for (const [k, v] of Object.entries(cost)) {
    const back = Math.floor(v * share);
    if (back > 0) out[k] = back;
  }
  return out;
}

export class Economy {
  /**
   * @param {{ economy: any, goodIds: string[] }} data
   * @param {import("./events.js").Events} events
   */
  constructor(data, events) {
    this.events = events;
    this.goodIds = data.goodIds;
    this.coins = data.economy.start.coins;
    /** @type {Record<string, number>} */
    this.stock = {};
    for (const g of data.goodIds) this.stock[g] = (data.economy.start.stock && data.economy.start.stock[g]) || 0;
  }

  /** Amount held of "coins" or of a good. */
  get(key) {
    return key === "coins" ? this.coins : this.stock[key] || 0;
  }

  /**
   * Would applying the delta keep every balance at zero or more?
   * @param {Record<string, number>} delta
   * @returns {{ ok: boolean, missing: Record<string, number> }} missing = how much of each is short
   */
  canApply(delta) {
    const missing = {};
    for (const [k, v] of Object.entries(delta)) {
      const after = this.get(k) + v;
      if (after < 0) missing[k] = -after;
    }
    return { ok: Object.keys(missing).length === 0, missing };
  }

  /** Can this cost (positive amounts) be paid? */
  canAfford(cost) {
    return this.canApply(negate(cost));
  }

  /**
   * Add a signed delta. Returns false (and changes nothing) when a balance would go below zero.
   * @param {Record<string, number>} delta @param {string} cause why: "place", "demolish", "undo", "redo", "production"...
   */
  apply(delta, cause = "") {
    if (!this.canApply(delta).ok) return false;
    for (const [k, v] of Object.entries(delta)) {
      if (k === "coins") this.coins += v;
      else this.stock[k] = (this.stock[k] || 0) + v;
    }
    this.events.emit("economy.changed", { coins: this.coins, stock: { ...this.stock }, delta, cause });
    return true;
  }

  snapshot() {
    return { coins: this.coins, stock: { ...this.stock } };
  }
}
