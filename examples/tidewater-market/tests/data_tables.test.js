// The data tables (data/*.json) are checked against each other, the atlas and the locale strings; a mistake fails clearly:
// the file, the JSON pointer, what is wrong, how to fix it and a "did you mean".
import { test, expect } from "factoria:test";
import { fa } from "factoria";
import { rawTables, validateTables, loadData, DataError, formatProblems, didYouMean } from "../scripts/game/data.js";

const copy = () => JSON.parse(JSON.stringify(rawTables));
const find = (problems, pointer) => problems.find((p) => p.pointer === pointer);

test("the tables that ship with the game are sound", () => {
  expect(validateTables(rawTables)).toEqual([]);
  const data = loadData(rawTables);
  expect(data.buildingIds[0]).toBe("road");
  expect(data.buildingIds).toHaveLength(11);
  expect(data.terrainIds).toEqual(["water", "sand", "grass", "forest", "rock"]);
  expect(data.terrainByChar.g).toBe(2);
});

test("every building has a name, a description and all four rotations in the atlas", () => {
  const data = loadData(rawTables);
  for (const id of data.buildingIds) {
    expect(typeof rawTables.locale.building[id].name).toBe("string");
    expect(typeof rawTables.locale.building[id].desc).toBe("string");
    if (data.buildings[id].kind === "road") continue;
    for (let rot = 0; rot < 4; rot++) expect(data.atlas.frames[`building.${id}.${rot}`]).toBeDefined();
  }
});

test("a misspelled terrain id points at the file, the pointer and the likely word", () => {
  const raw = copy();
  raw.buildings.buildings.house.terrain = ["sand", "gras"];
  const problems = validateTables(raw);
  expect(problems).toHaveLength(1);
  const p = problems[0];
  expect(p.file).toBe("data/buildings.json");
  expect(p.pointer).toBe("/buildings/house/terrain/1");
  expect(p.message).toContain("gras");
  expect(p.hint).toContain("did you mean 'grass'?");
});

test("a recipe that names a good that does not exist is refused", () => {
  const raw = copy();
  raw.recipes.recipes.bake_bread.inputs = { grian: 2 };
  const problems = validateTables(raw);
  expect(problems.length).toBeGreaterThan(0);
  expect(problems.some((p) => p.file === "data/recipes.json" && p.hint.includes("grain"))).toBe(true);
});

test("a building that runs a recipe that does not exist is refused", () => {
  const raw = copy();
  raw.buildings.buildings.bakery.recipes = ["bake_bred"];
  const p = validateTables(raw).find((x) => x.file === "data/buildings.json");
  expect(p.pointer).toBe("/buildings/bakery/recipes/0");
  expect(p.hint).toContain("bake_bread");
});

test("a cost in a good that does not exist, a negative price and a bad size are all reported at once", () => {
  const raw = copy();
  raw.buildings.buildings.farm.cost = { coins: 90, wod: 6 };
  raw.buildings.buildings.house.size = [0, 1];
  raw.goods.goods.fish.basePrice = -3;
  const problems = validateTables(raw);
  expect(problems.length).toBeGreaterThanOrEqual(3);
  expect(find(problems, "/buildings/farm/cost/wod")).toBeDefined();
  expect(find(problems, "/buildings/farm/cost/wod").hint).toContain("wood");
  expect(find(problems, "/buildings/house/size")).toBeDefined();
  expect(find(problems, "/goods/fish/basePrice")).toBeDefined();
});

test("a missing translation or a missing picture is caught before the game starts", () => {
  const raw = copy();
  delete raw.locale.building.bakery.name;
  delete raw.atlas.frames["building.bakery.2"];
  delete raw.locale.good.tools;
  const problems = validateTables(raw);
  expect(problems.some((p) => p.message.includes("building.bakery.name"))).toBe(true);
  expect(problems.some((p) => p.message.includes("building.bakery.2"))).toBe(true);
  expect(problems.some((p) => p.message.includes("good.tools"))).toBe(true);
});

test("a broken test map or economy is reported with where", () => {
  const raw = copy();
  raw.testMap.rows[2] = raw.testMap.rows[2] + "g";
  raw.testMap.rows[3] = "wsgxgggggffw";
  raw.economy.refund = 3;
  const problems = validateTables(raw);
  expect(problems.some((p) => p.file === "data/test_map.json" && p.pointer === "/rows/2")).toBe(true);
  expect(problems.some((p) => p.file === "data/test_map.json" && p.pointer === "/rows/3")).toBe(true);
  expect(problems.some((p) => p.file === "data/economy.json" && p.pointer === "/refund")).toBe(true);
});

test("loadData throws a DataError that lists every problem", () => {
  const raw = copy();
  raw.buildings.buildings.house.terrain = ["gras"];
  raw.goods.goods.wood.icon = "icon.wod";
  let error = null;
  try {
    loadData(raw);
  } catch (e) {
    error = e;
  }
  expect(error instanceof DataError).toBe(true);
  expect(error.problems.length).toBeGreaterThanOrEqual(2);
  expect(error.message).toContain("data/buildings.json /buildings/house/terrain/0");
  expect(error.message).toContain("data/goods.json /goods/wood/icon");
  expect(error.message).toContain("did you mean");
});

test("formatProblems and didYouMean", () => {
  expect(didYouMean("gras", ["water", "grass"])).toBe("grass");
  expect(didYouMean("zzzzzz", ["water", "grass"])).toBeNull();
  expect(formatProblems([{ file: "a.json", pointer: "/x", message: "m", hint: "h" }])).toBe("1 problem in the data tables:\n  a.json /x: m (h)");
});

test("project.validate_data says ok for the shipped tables", () => {
  const out = fa.call("project.validate_data", {});
  expect(out.ok).toBe(true);
  expect(out.counts.buildings).toBe(11);
});
