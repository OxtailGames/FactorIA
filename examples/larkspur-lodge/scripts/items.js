// @ts-check
// The item catalogue (data/items.json) and the inventory (the ids of the items the porter carries, kept in `session`).
//
// The catalogue is a validated data table: validateItems() checks the shape, the locale keys and the cross references
// (project.validate_data runs it; tests/data.test.js feeds it broken tables). Items are only ever named by id.
//   { "format": "larkspur.items/1", "items": { "<id>": { kind: "key"|"clue"|"tool", nameKey, descriptionKey,
//                                                         color: [r,g,b,a], opens: [door entity ids] } } }
import { session, didYouMean } from "factoria";
import table from "../data/items.json";
import { EVENTS, emit } from "./events.js";

/** The kinds an item can have: a key opens doors, a clue is read, a tool is used on something. */
export const KINDS = Object.freeze(["key", "clue", "tool"]);

/** The catalogue: item id -> { kind, nameKey, descriptionKey, color, opens }. */
export const catalogue = table.items;

/** The entry of an item, or null when there is none with that id. */
export function get(id) {
  return Object.prototype.hasOwnProperty.call(catalogue, id) ? catalogue[id] : null;
}

/** Every item id of the catalogue, in file order. */
export function ids() {
  return Object.keys(catalogue);
}

/** @returns {string[]} */
function store() {
  if (!Array.isArray(session.inventory)) session.inventory = [];
  return session.inventory;
}

/** The ids of the items carried, in the order they were picked up (a copy). */
export function list() {
  return store().slice();
}

/** True when the item is carried. */
export function has(id) {
  return store().includes(id);
}

/** Puts an item in the inventory (once: an item carried is not added twice). Returns false for a duplicate; throws for an id the catalogue lacks. */
export function add(id, from = "") {
  if (!get(id)) {
    const near = didYouMean(id, ids());
    throw new Error(`items.add: there is no item '${id}' in data/items.json.${near ? ` Did you mean '${near}'?` : ` Items: ${ids().join(", ")}.`}`);
  }
  if (has(id)) return false;
  store().push(id);
  emit(EVENTS.itemPicked, { item: id, from });
  emit(EVENTS.inventoryChanged, { items: list() });
  return true;
}

/** Takes an item out of the inventory (a key used up, a gift given). Returns false when it was not carried. */
export function remove(id) {
  const items = store();
  const i = items.indexOf(id);
  if (i < 0) return false;
  items.splice(i, 1);
  emit(EVENTS.inventoryChanged, { items: list() });
  return true;
}

/** A plain copy of the inventory for a save: the array of ids. */
export function snapshot() {
  return list();
}

/** Replaces the inventory with a snapshot() (a loaded save); the ids the catalogue does not know are dropped. */
export function restore(data) {
  session.inventory = Array.isArray(data) ? data.filter((id) => get(id)) : [];
}

/** Empties the inventory (a new game). */
export function reset() {
  session.inventory = [];
}

/**
 * Checks an items table against itself and against the strings and scenes it names. Pure: pass the pieces in.
 * @param {any} items the parsed data/items.json
 * @param {{ strings?: any, scenes?: Record<string, any> }} [ctx] strings: the parsed locales/en.json (checks the name and
 *   description keys); scenes: scene file path -> parsed scene (checks `opens`, and that every key door and item box names an item)
 * @returns {{ file: string, pointer: string, message: string, hint: string }[]} every problem; [] when the table is sound
 */
export function validateItems(items, ctx = {}) {
  const file = "data/items.json";
  /** @type {{ file: string, pointer: string, message: string, hint: string }[]} */
  const problems = [];
  const problem = (pointer, message, hint) => problems.push({ file, pointer, message, hint });
  if (!items || typeof items !== "object" || typeof items.items !== "object" || Array.isArray(items.items)) {
    problem("", "the file must be an object with an 'items' object", 'Start it with { "format": "larkspur.items/1", "items": { "library_key": { ... } } }');
    return problems;
  }
  if (items.format !== "larkspur.items/1") problem("/format", `format is '${items.format}'`, 'Set "format": "larkspur.items/1".');
  const known = Object.keys(items.items);
  const hasKey = (strings, key) => {
    let node = strings;
    for (const part of String(key).split(".")) {
      if (node === null || typeof node !== "object" || !(part in node)) return false;
      node = node[part];
    }
    return typeof node === "string" || (node !== null && typeof node === "object" && "text" in node);
  };
  // The doors the scenes define: id -> required item.
  const doors = new Map();
  const boxes = [];
  for (const [path, scene] of Object.entries(ctx.scenes ?? {})) {
    for (const e of scene.entities ?? []) {
      const props = e.components?.Script?.props;
      if (!props) continue;
      if (props.requiresItem !== undefined) doors.set(e.id, { path, item: props.requiresItem });
      if (props.item !== undefined) boxes.push({ path, id: e.id, item: props.item });
    }
  }
  for (const [id, item] of Object.entries(items.items)) {
    const at = `/items/${id}`;
    if (!/^[a-z][a-z0-9_]*$/.test(id)) problem(at, `item id '${id}' is not snake_case`, "Use lower-case letters, digits and underscores, starting with a letter.");
    if (!item || typeof item !== "object") {
      problem(at, `item '${id}' is not an object`, '{ "kind": "key", "nameKey": "...", "descriptionKey": "...", "color": [1,1,1,1], "opens": [] }');
      continue;
    }
    if (!KINDS.includes(item.kind)) {
      const near = didYouMean(String(item.kind), [...KINDS]);
      problem(`${at}/kind`, `item '${id}' has kind '${item.kind}'`, near ? `Did you mean '${near}'?` : `Kinds: ${KINDS.join(", ")}.`);
    }
    for (const field of ["nameKey", "descriptionKey"]) {
      if (typeof item[field] !== "string" || item[field] === "") problem(`${at}/${field}`, `item '${id}' has no ${field}`, `Add "${field}": "item.${id}.${field === "nameKey" ? "name" : "description"}" and the string in locales/en.json.`);
      else if (ctx.strings && !hasKey(ctx.strings, item[field])) problem(`${at}/${field}`, `item '${id}': the string '${item[field]}' is not in locales/en.json`, `Add it to locales/en.json (and to every other language).`);
    }
    const c = item.color;
    if (!Array.isArray(c) || c.length !== 4 || c.some((v) => typeof v !== "number" || v < 0 || v > 1)) problem(`${at}/color`, `item '${id}' has color ${JSON.stringify(c)}`, "A colour is [r, g, b, a] with every number between 0 and 1.");
    if (!Array.isArray(item.opens)) problem(`${at}/opens`, `item '${id}' has no 'opens' list`, 'Use "opens": [] when it opens nothing, or the ids of the door entities it opens.');
    else
      item.opens.forEach((door, i) => {
        if (!ctx.scenes) return;
        const d = doors.get(door);
        if (!d) {
          const near = didYouMean(String(door), [...doors.keys()]);
          problem(`${at}/opens/${i}`, `item '${id}' opens '${door}', which no scene has as a door that needs an item`, near ? `Did you mean '${near}'?` : `Doors that need an item: ${[...doors.keys()].join(", ")}.`);
        } else if (d.item !== id) problem(`${at}/opens/${i}`, `item '${id}' opens '${door}', but that door in ${d.path} needs '${d.item}'`, `Set the door's requiresItem to '${id}' or change this list.`);
      });
  }
  for (const [door, d] of doors) {
    if (!known.includes(d.item)) {
      const near = didYouMean(String(d.item), known);
      problem("", `door '${door}' in ${d.path} needs the item '${d.item}', which is not in data/items.json`, near ? `Did you mean '${near}'?` : `Items: ${known.join(", ")}.`);
    }
  }
  for (const b of boxes) {
    if (!known.includes(b.item)) {
      const near = didYouMean(String(b.item), known);
      problem("", `'${b.id}' in ${b.path} gives the item '${b.item}', which is not in data/items.json`, near ? `Did you mean '${near}'?` : `Items: ${known.join(", ")}.`);
    }
  }
  return problems;
}
