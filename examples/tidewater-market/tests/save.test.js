// The save format (scripts/game/savegame.js): a saved game continues exactly as the uninterrupted one, and a damaged file is refused.
import { test, expect } from "factoria:test";
import { growTown } from "../scripts/game/bot.js";
import { serializeGame, readSave, loadGame, FORMAT, VERSION } from "../scripts/game/savegame.js";
import { makeThumbnail, thumbRuns } from "../scripts/game/thumbnail.js";
import { createGame } from "../scripts/game/state.js";
import fixtureV1 from "./fixtures/save_v1.json";
import fixtureV2 from "./fixtures/save_v2.json";
import { smallTown, fillHouses, runDays } from "./town_helper.js";

/** Stringify with sorted keys: two equal states give equal text whatever order the fields were made in. */
function canonical(v) {
  if (Array.isArray(v)) return `[${v.map(canonical).join(",")}]`;
  if (v && typeof v === "object") return `{${Object.keys(v).sort().map((k) => `${JSON.stringify(k)}:${canonical(v[k])}`).join(",")}}`;
  return JSON.stringify(v);
}

function roundTrip(state) {
  const text = JSON.stringify(serializeGame(state));
  const res = loadGame(text, state.data);
  if (!res.ok) throw new Error(`load failed: ${JSON.stringify(res.error)}`);
  return res.state;
}

test("a loaded game has the same state hash and the same save", () => {
  const { game } = smallTown();
  fillHouses(game);
  runDays(game, 3);
  const loaded = roundTrip(game);
  expect(loaded.hash()).toBe(game.hash());
  expect(canonical(serializeGame(loaded))).toBe(canonical(serializeGame(game)));
});

test("a loaded game continues exactly as the uninterrupted one (small town)", () => {
  const { game } = smallTown();
  fillHouses(game);
  runDays(game, 2);
  // stop in the middle of a day, with people on the road
  for (let i = 0; i < 37; i++) game.clock.tick(game.clock.step);
  expect(game.sim.walkers.list.size).toBeGreaterThan(0);
  const loaded = roundTrip(game);
  runDays(game, 6);
  runDays(loaded, 6);
  expect(loaded.hash()).toBe(game.hash());
  expect(canonical(serializeGame(loaded))).toBe(canonical(serializeGame(game)));
});

test("a loaded game continues exactly as the uninterrupted one (a bot's town, after undo)", () => {
  const { state } = growTown({ seed: 20261026, days: 12 });
  state.undo();
  state.undo();
  const loaded = roundTrip(state);
  expect(loaded.hash()).toBe(state.hash());
  runDays(state, 5);
  runDays(loaded, 5);
  expect(loaded.hash()).toBe(state.hash());
  expect(canonical(serializeGame(loaded))).toBe(canonical(serializeGame(state)));
});

test("the save is plain JSON, tagged with format and version", () => {
  const { game } = smallTown();
  const save = serializeGame(game);
  expect(save.format).toBe(FORMAT);
  expect(save.version).toBe(VERSION);
  expect(JSON.parse(JSON.stringify(save))).toEqual(save);
});

test("damaged saves are refused with a code, a pointer and a hint, never a crash", () => {
  const { game } = smallTown();
  const good = serializeGame(game);
  const refuse = (input, code) => {
    const res = readSave(input);
    expect(res.ok).toBe(false);
    expect(res.error.code).toBe(code);
    expect(res.error.message.length).toBeGreaterThan(10);
    expect(res.error.hint.length).toBeGreaterThan(5);
    return res.error;
  };
  refuse("{ not json", "bad_json");
  refuse("42", "not_a_save");
  refuse("null", "not_a_save");
  refuse({ ...good, format: "other" }, "unknown_format");
  const future = refuse({ ...good, version: VERSION + 1 }, "future_version");
  expect(future.pointer).toBe("/version");
  refuse({ ...good, version: 0 }, "invalid");
  expect(refuse({ ...good, clock: null }, "invalid").pointer).toBe("/clock");
  expect(refuse({ ...good, map: { ...good.map, terrain: "012" } }, "invalid").pointer).toBe("/map/terrain");
  // the shape is fine, the content is not: the restore refuses it and leaves nothing behind
  const bad = (edit, code) => {
    const save = JSON.parse(JSON.stringify(good));
    edit(save);
    const res = loadGame(save, game.data);
    expect(res.ok).toBe(false);
    expect(res.error.code).toBe(code);
    return res.error;
  };
  const first = (s) => s.buildings.findIndex((b) => !Array.isArray(b));
  const at = first(good);
  expect(bad((s) => (s.buildings[first(s)].type = "hosue"), "invalid").pointer).toBe(`/buildings/${at}/type`);
  bad((s) => (s.map.hash = "deadbeef"), "map_mismatch");
  bad((s) => s.buildings.push({ ...s.buildings[first(s)] }), "invalid");
  bad((s) => (s.sim.rt[0].id = 9999), "invalid");
  bad((s) => (s.economy.stock.gold = 5), "invalid");
  bad((s) => (s.clock.dayTick = 999999), "invalid");
});

test("the version 1 fixture (made by the first commit of the format) migrates to version 2 and loads to the same town", () => {
  expect(fixtureV1.save.version).toBe(1);
  const read = readSave(fixtureV1.save);
  expect(read.ok).toBe(true);
  expect(read.migratedFrom).toBe(1);
  expect(read.save.version).toBe(VERSION);
  expect(read.save.scenario).toBe("sandbox"); // a version 1 save had no scenario
  expect(read.save.progress.won).toBe(false);
  expect(typeof fixtureV1.save.map.terrain).toBe("string"); // the old layout: one digit a cell
  expect(Array.isArray(read.save.map.terrain)).toBe(true); // the new one: runs
  expect(fixtureV1.save.version).toBe(1); // reading did not touch the caller's object
  const res = loadGame(fixtureV1.save, smallTown().game.data);
  expect(res.ok).toBe(true);
  expect(res.migratedFrom).toBe(1);
  expect(res.state.hash()).toBe(fixtureV1.hash);
  runDays(res.state, 3); // and it plays on
  expect(res.state.clock.day).toBe(fixtureV1.save.clock.day + 3);
  // saving it again writes version 2, smaller than the old file
  const again = serializeGame(res.state);
  expect(again.version).toBe(2);
  expect(JSON.stringify(again).length).toBeLessThan(JSON.stringify(fixtureV1.save).length);
});

test("the version 2 fixture loads as it is, with its scenario progress, and plays on identically", () => {
  expect(fixtureV2.save.version).toBe(2);
  const read = readSave(fixtureV2.save);
  expect(read.ok).toBe(true);
  expect(read.migratedFrom).toBe(null);
  expect(read.save.scenario).toBe("first_harbour");
  const res = loadGame(fixtureV2.save, createGame({ seed: 20261026 }).data);
  expect(res.ok).toBe(true);
  expect(res.state.hash()).toBe(fixtureV2.hash);
  const other = loadGame(JSON.stringify(fixtureV2.save), res.state.data);
  runDays(res.state, 5);
  runDays(other.state, 5);
  expect(other.state.hash()).toBe(res.state.hash());
});

test("a thumbnail is a small run-length map: terrain, roads, houses and other buildings", () => {
  const { game } = smallTown();
  const thumb = makeThumbnail(game);
  expect(thumb.w).toBe(12);
  expect(thumb.h).toBe(10);
  const runs = thumbRuns(thumb);
  const kinds = new Set(runs.map((r) => r.kind));
  for (const k of ["w", "x", "h", "b"]) expect(kinds.has(k)).toBe(true);
  for (let r = 0; r < thumb.h; r++) expect(runs.filter((u) => u.row === r).reduce((n, u) => n + u.len, 0)).toBe(thumb.w);
  // a big map is cut down to at most 48 cells a side
  const big = makeThumbnail(createGame({ seed: 20261026 }));
  expect(Math.max(big.w, big.h)).toBeLessThanOrEqual(48);
  expect(thumbRuns({ rows: 5 })).toEqual([]);
});
