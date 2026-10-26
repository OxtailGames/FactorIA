// @ts-check
// The tables of P5 (data/ships.json, data/events.json, data/story.json) and the checks that make a mistake in them fail
// clearly: same shape of problem as scripts/game/data.js ({ file, pointer, message, hint }), run by `project.validate_data`
// and by tests/trade_data.test.js. The game itself loads them through getTradeData().
import shipsJson from "../../data/ships.json";
import eventsJson from "../../data/events.json";
import storyJson from "../../data/story.json";
import { ui } from "factoria";
import { rawTables, didYouMean, formatProblems, DataError } from "./data.js";

export const rawTradeTables = { ships: shipsJson, events: eventsJson, story: storyJson };

const FILES = { ships: "data/ships.json", events: "data/events.json", story: "data/story.json" };
/** The keys of a `when` / `requires` condition. */
export const CONDITION_KEYS = ["day", "season", "pier", "ordersFilled", "shipsFilled", "reputation", "population", "coins", "built"];
const EFFECT_KEYS = ["delta", "reputation", "shipDelay"];

const isObject = (v) => !!v && typeof v === "object" && !Array.isArray(v);

function lookup(locale, key) {
  let cur = locale;
  for (const part of key.split(".")) {
    if (!isObject(cur)) return undefined;
    cur = cur[part];
  }
  return cur;
}

/**
 * @param {typeof rawTradeTables} trade
 * @param {typeof rawTables} base the P1/P2 tables (goods, buildings, seasons, atlas, locale)
 * @returns {import("./data.js").Problem[]}
 */
export function validateTradeTables(trade, base = rawTables) {
  /** @type {import("./data.js").Problem[]} */
  const problems = [];
  const add = (table, pointer, message, hint = "") => problems.push({ file: FILES[table], pointer, message, hint });
  for (const name of Object.keys(FILES)) {
    if (!isObject(trade[name])) add(name, "", "the file is missing or is not a JSON object", `create ${FILES[name]}`);
  }
  if (problems.length) return problems;
  const goods = Object.keys(base.goods.goods);
  const buildings = Object.keys(base.buildings.buildings);
  const seasons = base.economy.calendar.seasons;
  const need = (table, pointer, key) => {
    if (typeof lookup(base.locale, key) !== "string") add(table, pointer, `the locale string '${key}' is missing`, "add it to locales/en.json");
  };
  const checkMarkup = (table, pointer, key) => {
    const text = lookup(base.locale, key);
    if (typeof text !== "string") return;
    // the engine reads the markup (Text.markup): it names a bad tag, colour or icon of the `text` section of factoria.json
    for (const e of ui.markupProblems(text)) {
      add(table, pointer, `the locale string '${key}' has bad markup: ${e}`, "tags are [b]..[/b], [c:colour]..[/c], [icon:name]; write [[ for a literal [");
    }
  };
  const goodCheck = (table, pointer, id) => {
    if (!goods.includes(id)) {
      const g = didYouMean(id, goods);
      add(table, pointer, `unknown good '${id}'`, (g ? `did you mean '${g}'? ` : "") + `goods: ${goods.join(", ")}`);
    }
  };

  // ---- ships
  const s = trade.ships;
  for (const k of ["schedule", "reputation", "classes"]) if (!isObject(s[k])) add("ships", `/${k}`, `'${k}' must be an object`);
  if (problems.length) return problems;
  const range = (table, pointer, v) => {
    if (!Array.isArray(v) || v.length !== 2 || !(v[0] <= v[1]) || !Number.isFinite(v[0])) add(table, pointer, "must be [min, max] with min <= max", "for example [4, 6]");
  };
  range("ships", "/schedule/gapDays", s.schedule.gapDays);
  range("ships", "/schedule/orderDays", s.schedule.orderDays);
  if (!(s.sailSpeed > 0)) add("ships", "/sailSpeed", "sailSpeed must be above 0", "cells per game second, for example 1.8");
  if (!(s.nameCount >= 1)) add("ships", "/nameCount", "nameCount must be at least 1");
  else for (let i = 0; i < s.nameCount; i++) need("ships", "/nameCount", `ship.name.${i}`);
  const classIds = Object.keys(s.classes);
  if (!classIds.length) add("ships", "/classes", "no ship classes", "add at least a class with minReputation 0");
  else if (!classIds.some((c) => s.classes[c].minReputation === 0)) add("ships", "/classes", "no class with minReputation 0", "the first ship has to be one the town can get with no reputation");
  for (const [id, c] of Object.entries(s.classes)) {
    const p = `/classes/${id}`;
    need("ships", p, `ship.class.${id}`);
    range("ships", `${p}/goods`, c.goods);
    if (!(c.premium > 0)) add("ships", `${p}/premium`, "premium must be above 0");
    if (!isObject(c.wants) || !Object.keys(c.wants).length) add("ships", `${p}/wants`, "wants must list at least one good");
    else {
      if (Array.isArray(c.goods) && c.goods[1] > Object.keys(c.wants).length) add("ships", `${p}/goods`, `asks for up to ${c.goods[1]} goods but wants has ${Object.keys(c.wants).length}`);
      for (const [g, r] of Object.entries(c.wants)) {
        goodCheck("ships", `${p}/wants/${g}`, g);
        range("ships", `${p}/wants/${g}`, r);
      }
    }
  }

  // ---- conditions and choices (events and story share them)
  const checkWhen = (table, pointer, w) => {
    if (!isObject(w)) return add(table, pointer, "must be an object", "for example { \"day\": 3 }");
    for (const [k, v] of Object.entries(w)) {
      if (!CONDITION_KEYS.includes(k)) {
        const g = didYouMean(k, CONDITION_KEYS);
        add(table, `${pointer}/${k}`, `unknown condition '${k}'`, (g ? `did you mean '${g}'? ` : "") + `conditions: ${CONDITION_KEYS.join(", ")}`);
      } else if (k === "season") {
        if (!seasons.includes(v)) add(table, `${pointer}/season`, `unknown season '${v}'`, `seasons: ${seasons.join(", ")}`);
      } else if (k === "built") {
        for (const t of Object.keys(isObject(v) ? v : {})) if (!buildings.includes(t)) add(table, `${pointer}/built/${t}`, `unknown building '${t}'`, `buildings: ${buildings.join(", ")}`);
      } else if (!Number.isFinite(v)) add(table, `${pointer}/${k}`, "must be a number");
    }
  };
  const checkEffects = (table, pointer, e) => {
    if (!isObject(e)) return add(table, pointer, "effects must be an object", "{ \"delta\": { \"coins\": -40 }, \"reputation\": 1 }");
    for (const [k, v] of Object.entries(e)) {
      if (!EFFECT_KEYS.includes(k)) add(table, `${pointer}/${k}`, `unknown effect '${k}'`, `effects: ${EFFECT_KEYS.join(", ")}`);
      else if (k === "delta") {
        for (const [g, n] of Object.entries(isObject(v) ? v : {})) {
          if (g !== "coins") goodCheck(table, `${pointer}/delta/${g}`, g);
          if (!Number.isInteger(n)) add(table, `${pointer}/delta/${g}`, "amounts must be whole numbers");
        }
      } else if (!Number.isInteger(v)) add(table, `${pointer}/${k}`, "must be a whole number");
    }
  };
  /** One card: an event of events.json or a story card; `base` is its locale key prefix. */
  const checkCard = (table, pointer, card, base) => {
    need(table, pointer, `${base}.title`);
    need(table, pointer, `${base}.body`);
    checkMarkup(table, pointer, `${base}.body`);
    if (!Array.isArray(card.choices) || card.choices.length < 2 || card.choices.length > 3) {
      return add(table, `${pointer}/choices`, "a card has 2 or 3 choices", "the card has room for three buttons");
    }
    let safe = false;
    card.choices.forEach((ch, i) => {
      const cp = `${pointer}/choices/${i}`;
      need(table, cp, `${base}.choice.${ch.id}`);
      if (ch.outcomes) {
        safe = true;
        if (!Array.isArray(ch.outcomes) || ch.outcomes.length < 2) add(table, `${cp}/outcomes`, "a gamble needs at least two outcomes");
        else
          ch.outcomes.forEach((o, n) => {
            if (!(o.weight > 0)) add(table, `${cp}/outcomes/${n}/weight`, "weight must be above 0");
            checkEffects(table, `${cp}/outcomes/${n}/effects`, o.effects);
            need(table, cp, `${base}.result.${ch.id}.${n}`);
            checkMarkup(table, cp, `${base}.result.${ch.id}.${n}`);
          });
      } else {
        checkEffects(table, `${cp}/effects`, ch.effects);
        need(table, cp, `${base}.result.${ch.id}`);
        checkMarkup(table, cp, `${base}.result.${ch.id}`);
        const d = (ch.effects && ch.effects.delta) || {};
        if (!Object.values(d).some((n) => n < 0)) safe = true;
      }
    });
    if (!safe) add(table, `${pointer}/choices`, "every choice costs something", "keep one choice the town can always pick (no negative delta) or a gamble");
    const ids = card.choices.map((c) => c.id);
    if (new Set(ids).size !== ids.length) add(table, `${pointer}/choices`, "two choices share an id");
  };

  // ---- events
  const ev = trade.events;
  if (!(ev.eventDay >= 1 && ev.eventDay <= base.economy.calendar.daysPerSeason)) add("events", "/eventDay", "eventDay must be a day of the season (1 to daysPerSeason)");
  for (const [id, e] of Object.entries(isObject(ev.events) ? ev.events : {})) {
    const p = `/events/${id}`;
    for (const sn of Object.keys(e.weights || {})) if (!seasons.includes(sn)) add("events", `${p}/weights/${sn}`, `unknown season '${sn}'`, `seasons: ${seasons.join(", ")}`);
    if (!Object.values(e.weights || {}).some((w) => w > 0)) add("events", `${p}/weights`, "an event with no season weight is never drawn");
    checkWhen("events", `${p}/requires`, e.requires || {});
    checkCard("events", p, e, `event.${id}`);
  }

  // ---- story
  for (const [scenario, cards] of Object.entries(isObject(trade.story.scenarios) ? trade.story.scenarios : {})) {
    need("story", `/scenarios/${scenario}`, `story.${scenario}.name`);
    if (!Array.isArray(cards) || !cards.length) {
      add("story", `/scenarios/${scenario}`, "a story is a non-empty list of cards", "remove the scenario to give it no story");
      continue;
    }
    const seen = new Set();
    cards.forEach((card, i) => {
      const p = `/scenarios/${scenario}/${i}`;
      if (seen.has(card.id)) add("story", p, `two cards share the id '${card.id}'`);
      seen.add(card.id);
      checkWhen("story", `${p}/when`, card.when || {});
      checkCard("story", p, card, `story.${scenario}.${card.id}`);
    });
  }
  return problems;
}

/** @type {null | { ships: any, events: any, story: any }} */
let cached = null;

/** The ship, event and story tables, checked once (throws a DataError listing every problem). */
export function getTradeData() {
  if (!cached) {
    const problems = validateTradeTables(rawTradeTables);
    if (problems.length) throw new DataError(problems);
    cached = { ships: shipsJson, events: eventsJson, story: storyJson };
  }
  return cached;
}

export { formatProblems };
