// @ts-check
// The markup strings of the trade screens (pure: `t` is i18n.t, passed in, so tests need no engine). Numbers and colours of an
// effect, an order or a shortfall are written the same way everywhere: "+12" in green or "-40" in red next to the picture of the
// good, so a card, a button and the order board never disagree.

/** A signed amount with the picture of its good: "[c:good]+12[/c][icon:wood]". @param {string} key a good id or "coins" */
export function signedMarkup(key, n) {
  const icon = key === "coins" ? "coin" : key;
  return `[c:${n < 0 ? "bad" : "good"}]${n > 0 ? "+" : "-"}${Math.abs(n)}[/c][icon:${icon}]`;
}

/** A plain amount with the picture: "12[icon:wood]". */
export function amountMarkup(key, n) {
  return `${n}[icon:${key === "coins" ? "coin" : key}]`;
}

/**
 * What a choice does, as one line of markup: the goods and coins, the reputation (a star) and the effect on the next ship.
 * Empty when it does nothing. @param {any} effects { delta, reputation, shipDelay } @param {(key: string, args?: any) => string} t
 */
export function effectsMarkup(effects, t) {
  const parts = [];
  const delta = (effects && effects.delta) || {};
  for (const [k, n] of Object.entries(delta)) if (n) parts.push(signedMarkup(k, n));
  if (effects && effects.reputation) {
    const r = effects.reputation;
    parts.push(`[c:${r < 0 ? "bad" : "good"}]${r > 0 ? "+" : "-"}${Math.abs(r)}[/c][icon:star]`);
  }
  if (effects && effects.shipDelay) {
    const d = effects.shipDelay;
    parts.push(`[c:muted]${d > 0 ? t("trade.card.later", { n: d }) : t("trade.card.sooner", { n: -d })}[/c]`);
  }
  return parts.join("  ");
}

/** The goods of an order: "12[icon:fish]  8[icon:wood]". */
export function orderGoodsMarkup(goods) {
  return Object.entries(goods)
    .map(([g, n]) => amountMarkup(g, n))
    .join("  ");
}

/** "Skiff Gull" for a ship. @param {{ cls: string, name: number }} ship */
export function shipName(ship, t) {
  return t("trade.ship", { class: t(`ship.class.${ship.cls}`), name: t(`ship.name.${ship.name}`) });
}

/** "Missing: 4 wood, 2 fish" with the pictures, for an order or a choice the town cannot pay. */
export function missingMarkup(missing, t) {
  const list = Object.entries(missing)
    .map(([k, n]) => amountMarkup(k, n))
    .join("  ");
  return `[c:bad]${t("trade.board.missing", { list: "" }).trim()}[/c] ${list}`;
}
