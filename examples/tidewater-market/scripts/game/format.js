// @ts-check
// Text for the player, always from locales/en.json through i18n (so the other languages of P8 need no code change).
import { i18n } from "factoria";

/** "40 coins, 4 wood" for an amount list ({ coins: 40, wood: 4 }); amounts of 0 are skipped, an empty list is "free". */
export function amountText(amounts) {
  const parts = [];
  for (const [key, n] of Object.entries(amounts)) {
    if (!n) continue;
    parts.push(key === "coins" ? i18n.t("amount.coins", { n }) : i18n.t("amount.good", { n, name: i18n.t(`good.${key}`) }));
  }
  return parts.length ? parts.join(", ") : i18n.t("amount.none");
}

/** The sentence for a placement problem ({ code, detail }) from scripts/game/rules.js. */
export function reasonText(reason) {
  const d = reason.detail || {};
  switch (reason.code) {
    case "terrain":
      return i18n.t("reason.terrain", {
        terrain: i18n.t(`terrain.${d.terrain}`),
        allowed: d.allowed.map((t) => i18n.t(`terrain.${t}`)).join(", "),
      });
    case "cannot_afford":
      return i18n.t("reason.cannot_afford", { missing: amountText(d.missing || {}) });
    case "unknown_type":
      return i18n.t("reason.unknown_type", { type: d.type });
    default:
      return i18n.t(`reason.${reason.code}`);
  }
}

/** The name of a building type. */
export function buildingName(type) {
  return i18n.t(`building.${type}.name`);
}

/** "Spring 1, year 1" for a clock date. */
export function dateText(date) {
  return i18n.t("hud.date", { season: i18n.t(`season.${date.season}`), day: date.dayOfSeason, year: date.year });
}

/** The name of an undo step, for the toast ("build House"). */
export function stepText(tx) {
  return i18n.t(`history.${tx.label}`, { name: buildingName(tx.type) });
}
