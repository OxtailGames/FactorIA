// The data tables (data/items.json) and their validation: the shipped table is sound, and every kind of mistake is named.
import { test, describe, expect } from "factoria:test";
import { fa } from "factoria";
import table from "../data/items.json";
import strings from "../locales/en.json";
import ground from "../scenes/ground.scene.json";
import upstairs from "../scenes/upstairs.scene.json";
import cellar from "../scenes/cellar.scene.json";
import testRoom from "../scenes/test_room.scene.json";
import { validateItems } from "../scripts/items.js";
import * as items from "../scripts/items.js";

const scenes = {
  "scenes/ground.scene.json": ground,
  "scenes/upstairs.scene.json": upstairs,
  "scenes/cellar.scene.json": cellar,
  "scenes/test_room.scene.json": testRoom,
};
const clone = (v) => JSON.parse(JSON.stringify(v));
const ctx = { strings, scenes };

describe("the shipped table", () => {
  test("is sound against the strings and the scenes", () => {
    expect(validateItems(table, ctx)).toEqual([]);
  });

  test("project.validate_data says so", () => {
    const r = fa.call("project.validate_data", {});
    expect(r.ok).toBe(true);
    expect(r.counts.items).toBe(Object.keys(table.items).length);
  });

  test("every key door of the scenes is opened by exactly the key that names it", () => {
    for (const [id, item] of Object.entries(table.items)) {
      for (const door of item.opens) {
        const entity = Object.values(scenes).flatMap((s) => s.entities).find((e) => e.id === door);
        expect(entity?.components.Script.props.requiresItem).toBe(id);
      }
    }
  });
});

describe("mistakes are named, with a place and a fix", () => {
  const pointers = (t, c = ctx) => validateItems(t, c).map((p) => p.pointer);

  test("an unknown kind gets a suggestion", () => {
    const t = clone(table);
    t.items.library_key.kind = "kee";
    const [p] = validateItems(t, ctx);
    expect(p.pointer).toBe("/items/library_key/kind");
    expect(p.hint).toContain("Did you mean 'key'");
  });

  test("a missing locale string is reported with the key", () => {
    const t = clone(table);
    t.items.lamp_oil.nameKey = "item.lamp_oil.nom";
    const [p] = validateItems(t, ctx);
    expect(p.pointer).toBe("/items/lamp_oil/nameKey");
    expect(p.message).toContain("item.lamp_oil.nom");
  });

  test("a colour out of range, a bad id and a wrong format are all found at once", () => {
    const t = clone(table);
    t.format = "larkspur.items/2";
    t.items.lamp_oil.color = [2, 0, 0, 1];
    t.items.BadId = clone(t.items.lamp_oil);
    t.items.BadId.color = [1, 1, 1, 1];
    const found = pointers(t);
    expect(found).toContain("/format");
    expect(found).toContain("/items/lamp_oil/color");
    expect(found).toContain("/items/BadId");
  });

  test("a key that opens a door that does not exist, or that needs another key", () => {
    const t = clone(table);
    t.items.library_key.opens = ["librery_door"];
    t.items.room_c_key.opens = ["library_door"];
    const found = validateItems(t, ctx);
    const missing = found.find((p) => p.pointer === "/items/library_key/opens/0");
    expect(missing.hint).toContain("Did you mean 'library_door'");
    expect(found.find((p) => p.pointer === "/items/room_c_key/opens/0").message).toContain("needs 'library_key'");
  });

  test("a door or an item box that names an item the table does not have", () => {
    const t = clone(table);
    delete t.items.library_key;
    delete t.items.lamp_oil;
    const messages = validateItems(t, ctx).map((p) => p.message);
    expect(messages.some((m) => m.includes("'library_door'") && m.includes("library_key"))).toBe(true);
    expect(messages.some((m) => m.includes("p_kitchen_box") && m.includes("lamp_oil"))).toBe(true);
  });

  test("a file that is not a table at all", () => {
    expect(validateItems({ items: [] }, ctx)[0].pointer).toBe("");
    expect(validateItems(null, ctx).length).toBe(1);
  });
});

describe("the item API", () => {
  test("add is idempotent, remove forgets, and an unknown id is refused with a suggestion", () => {
    items.reset();
    expect(items.has("lamp_oil")).toBe(false);
    items.add("lamp_oil", "test");
    items.add("lamp_oil", "test");
    expect(items.list().filter((id) => id === "lamp_oil").length).toBe(1);
    items.remove("lamp_oil");
    expect(items.has("lamp_oil")).toBe(false);
    expect(() => items.add("lamp_oyl", "test")).toThrow(/lamp_oil/);
  });
});
