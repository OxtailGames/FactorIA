// @ts-check
// The news panel of the title screen: a few short items from the game's server ("Daily dig is live", "Patch 0.2"). The server is
// reached through online.js (offline in the shipped game today, a fake in tests). The answer is untrusted: it is checked, cut to
// fit the panel and kept in storage, so the last good news still shows when the game starts offline.
//
//   file    { "version": 1, "items": [ { "id": "patch-2", "date": "2026-10-20", "title": "Patch 0.2", "body": "..." } ] }
//           title and body are text, or an object by language ({ "en": "...", "ru": "..." }; the game's language, else "en").
//   refresh()   asks the server; resolves { source: "server"|"cache"|"none", items }. A bad file keeps the cache.
//   cached()    the items kept from the last good answer ([] when none).
//   line(item)  the one-line text the title shows for an item.
import { storage, i18n } from "factoria";
import * as online from "./online.js";

export const KEY = "burrow.news";
/** Items kept and shown (the newest first), and the longest title / body. */
export const MAX_ITEMS = 3;
export const MAX_TITLE = 48;
export const MAX_BODY = 160;

/** @param {any} v @returns {string} */
function textOf(v) {
  if (typeof v === "string") return v;
  if (v && typeof v === "object") {
    const t = v[i18n.language] ?? v.en;
    if (typeof t === "string") return t;
  }
  return "";
}

/** @param {string} s @param {number} max */
function cut(s, max) {
  const clean = s.replace(/[\u0000-\u001f]+/g, " ").trim();
  return clean.length > max ? `${clean.slice(0, max - 1).trimEnd()}…` : clean;
}

/**
 * Checks a news file. Items without an id or a title are dropped; only the newest MAX_ITEMS are kept.
 * @param {any} data
 * @returns {Array<{id: string, date: string, title: string, body: string}> | null}  null when the file is not a news file
 */
export function parse(data) {
  if (!data || typeof data !== "object" || data.version !== 1 || !Array.isArray(data.items)) return null;
  const items = [];
  for (const it of data.items) {
    if (!it || typeof it !== "object" || typeof it.id !== "string" || !it.id) continue;
    const title = cut(textOf(it.title), MAX_TITLE);
    if (!title) continue;
    const date = typeof it.date === "string" && /^\d{4}-\d{2}-\d{2}$/.test(it.date) ? it.date : "";
    items.push({ id: it.id, date, title, body: cut(textOf(it.body), MAX_BODY) });
  }
  items.sort((a, b) => (a.date < b.date ? 1 : a.date > b.date ? -1 : 0));
  return items.slice(0, MAX_ITEMS);
}

export function cached() {
  const saved = storage.get(KEY, null);
  const items = saved && Array.isArray(saved.items) ? parse({ version: 1, items: saved.items }) : null;
  return items ?? [];
}

/** @returns {Promise<{source: "server"|"cache"|"none", items: Array<{id: string, date: string, title: string, body: string}>}>} */
export async function refresh() {
  const r = await online.request("GET", online.PATHS.news);
  const items = r.ok ? parse(r.data) : null;
  if (items) {
    storage.set(KEY, { items });
    return { source: "server", items };
  }
  const old = cached();
  return { source: old.length ? "cache" : "none", items: old };
}

/** The one-line text of an item for the title: "Patch 0.2: ..." (the body is for the boards/news screen). */
export function line(item) {
  return item.body ? `${item.title} - ${item.body}` : item.title;
}
