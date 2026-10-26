// @ts-check
// Every number, amount, list and date the player sees goes through this file (P8). The words are always in locales/<language>.json;
// what is language-specific and not a sentence is in `format.*` and `number.*` there too, so a new language needs no code change:
//   number.units   the short form of big numbers, "1000=k;1000000=M" (en), "10000=万;100000000=亿" (zh-Hans)
//   format.list    the separator of a list of names (a comma and a space, or the ideographic comma)
//   amount.coins   a plural entry ("1 coin", "2 coins"); amount.good   "{n} {name}" / "{n} × {name}" / "{name}×{n}"
//   hud.date       "{season} {day}, year {year}" / "{day} de {season}, año {year}" / "第{year}年{season}，第{day}天"
// The digits, the thousands separator and the decimal mark come from the engine (`i18n.number`, the rules of the language of the
// table the text came from: 12,345.5 / 12.345,5 / 12 345,5).
import { i18n } from "factoria";
import { formatCompact } from "./ui_model.js";

/** A number written for the player's language (`decimals`: exactly that many, or as many as the number has). */
export function numberText(n, decimals) {
  return decimals === undefined ? i18n.number(n) : i18n.number(n, { decimals });
}

/** The big-number units of the current language: [[1000, "k"], [1000000, "M"]] from the `number.units` string. */
export function compactUnits() {
  return i18n
    .t("number.units")
    .split(";")
    .map((part) => {
      const at = part.indexOf("=");
      return [Number(part.slice(0, at)), part.slice(at + 1)];
    })
    .filter(([size]) => size > 0)
    .sort((a, b) => a[0] - b[0]);
}

/** "12.3k", "10M" in English; "12,3 mil", "10 M" in Spanish; "1,2万" in Chinese: short, for the top bar and the charts. */
export function compactText(n) {
  return formatCompact(n, { units: compactUnits(), number: (x, decimals) => numberText(Number(x.toFixed(decimals))) });
}

/** "1 coin", "12 coins" (plural rules of the language), with the thousands separator. */
export function coinsText(n) {
  return i18n.t("amount.coins", { count: n });
}

/** "1 villager", "4 villagers". */
export function villagersText(n) {
  return i18n.t("amount.villagers", { count: n });
}

/** "4 wood" / "4 × madera" / "木材×4": a count of one good. */
export function goodAmountText(good, n) {
  return i18n.t("amount.good", { n, name: i18n.t(`good.${good}`) });
}

/** The names of a list written the way the language writes lists. */
export function listText(items) {
  return items.join(i18n.t("format.list"));
}

/** "40 coins, 4 wood" for an amount list ({ coins: 40, wood: 4 }); amounts of 0 are skipped, an empty list is "free". */
export function amountText(amounts) {
  const parts = [];
  for (const [key, n] of Object.entries(amounts)) {
    if (!n) continue;
    parts.push(key === "coins" ? coinsText(n) : goodAmountText(key, n));
  }
  return parts.length ? listText(parts) : i18n.t("amount.none");
}

/** The same for the goods in a building or a carrier's hands ({ fish: 3, wood: 0 }): zero counts are skipped, "" when nothing is left. */
export function goodsBagText(bag) {
  return listText(Object.entries(bag).filter(([, n]) => n > 0).map(([good, n]) => goodAmountText(good, n)));
}

/** The sentence for a placement problem ({ code, detail }) from scripts/game/rules.js. */
export function reasonText(reason) {
  const d = reason.detail || {};
  switch (reason.code) {
    case "terrain":
      return i18n.t("reason.terrain", {
        terrain: i18n.t(`terrain.${d.terrain}`),
        allowed: listText(d.allowed.map((t) => i18n.t(`terrain.${t}`))),
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

/** "Spring 1, year 1" for a clock date (a Spanish "1 de primavera, año 1", a Chinese "第1年春季，第1天"). */
export function dateText(date) {
  return i18n.t("hud.date", { season: i18n.t(`season.date.${date.season}`), day: date.dayOfSeason, year: date.year });
}

/** The name of an undo step, for the toast ("build House"). */
export function stepText(tx) {
  return i18n.t(`history.${tx.label}`, { name: buildingName(tx.type) });
}
