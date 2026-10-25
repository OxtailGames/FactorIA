// Tile pathfinding (scripts/game/pathfinding.js) on maps built from rows of text; no scene is needed.
import { test, describe, expect } from "factoria:test";
import { fromRows } from "../scripts/game/mine_ascii.js";
import { MineMap } from "../scripts/game/mine_map.js";
import { NavGrid, navFor, lineOfSight, PathFollower, distToTile } from "../scripts/game/pathfinding.js";
import { K } from "../scripts/game/tiles.js";

const mapOf = (rows) => new MineMap(fromRows(rows));

const WALLED = [
  "BBBBBBBBBBB",
  "B.S...#..EB",
  "BBBBBBBBBBB",
];

describe("findPath", () => {
  test("walks the open floor with one step per tile, start and goal included", () => {
    const map = mapOf(["BBBBBBB", "B.S..EB", "BBBBBBB"]);
    const r = new NavGrid(map).findPath({ tx: 1, ty: 1 }, { tx: 5, ty: 1 });
    expect(r.ok).toBe(true);
    expect(r.path.length).toBe(5);
    expect(r.path[0]).toEqual({ tx: 1, ty: 1 });
    expect(r.path[4]).toEqual({ tx: 5, ty: 1 });
    expect(r.digs).toEqual([]);
  });

  test("a wall blocks the search; allowing the pick to dig lists the tiles to dig, in path order", () => {
    const map = mapOf(WALLED);
    const nav = new NavGrid(map);
    const blocked = nav.findPath({ tx: 1, ty: 1 }, { tx: 8, ty: 1 });
    expect(blocked.ok).toBe(false);
    expect(blocked.reason).toBe("blocked");
    const dig = nav.findPath({ tx: 1, ty: 1 }, { tx: 8, ty: 1 }, { dig: { tier: 0 } });
    expect(dig.ok).toBe(true);
    expect(dig.digs).toEqual([{ tx: 6, ty: 1 }]);
  });

  test("bedrock and tiles above the pick's tier are never dug", () => {
    const map = mapOf(["BBBBBBBBB", "B.S.H..EB", "BBBBBBBBB"]);
    const nav = new NavGrid(map);
    expect(nav.findPath({ tx: 1, ty: 1 }, { tx: 7, ty: 1 }, { dig: { tier: 0 } }).ok).toBe(false);
    expect(nav.findPath({ tx: 1, ty: 1 }, { tx: 7, ty: 1 }, { dig: { tier: 1 } }).ok).toBe(true);
  });

  test("water, magma and cracked floor are walls by default and cost extra when allowed", () => {
    const map = mapOf(["BBBBBBBBB", "B.S.w..EB", "BBBBBBBBB"]);
    const nav = new NavGrid(map);
    expect(nav.findPath({ tx: 1, ty: 1 }, { tx: 7, ty: 1 }).ok).toBe(false);
    const wet = nav.findPath({ tx: 1, ty: 1 }, { tx: 7, ty: 1 }, { dangerCost: 40 });
    expect(wet.ok).toBe(true);
    expect(wet.cost).toBeGreaterThan(40);
  });

  test("a path goes around a danger tile when there is a way around", () => {
    const map = mapOf(["BBBBBBBBB", "B.S.x..EB", "B.......B", "BBBBBBBBB"]);
    const r = new NavGrid(map).findPath({ tx: 1, ty: 1 }, { tx: 7, ty: 1 }, { dangerCost: 40 });
    expect(r.ok).toBe(true);
    expect(r.path.some((p) => p.tx === 4 && p.ty === 1)).toBe(false);
  });

  test("the goal tile is allowed even when it is a wall, and off-map tiles fail with a reason", () => {
    const map = mapOf(WALLED);
    const nav = new NavGrid(map);
    expect(nav.findPath({ tx: 1, ty: 1 }, { tx: 6, ty: 1 }).ok).toBe(true);
    expect(nav.findPath({ tx: 1, ty: 1 }, { tx: 99, ty: 1 }).reason).toBe("off-map");
  });

  test("a search that runs out of nodes says 'far'", () => {
    const rows = ["B".repeat(42), "B.S" + ".".repeat(37) + "EB", "B".repeat(42)];
    const map = mapOf(rows);
    expect(new NavGrid(map).findPath({ tx: 1, ty: 1 }, { tx: 40, ty: 1 }, { maxNodes: 5 }).reason).toBe("far");
  });
});

describe("it follows digging", () => {
  test("the version goes up with every tile change, and a tunnel dug a moment ago is walkable at once", () => {
    const map = mapOf(WALLED);
    const nav = navFor(map);
    expect(navFor(map)).toBe(nav); // one grid per map
    const v0 = nav.version;
    expect(nav.findPath({ tx: 1, ty: 1 }, { tx: 8, ty: 1 }).ok).toBe(false);
    map.dig(6, 1, { tier: 0 });
    expect(nav.version).toBeGreaterThan(v0);
    const r = nav.findPath({ tx: 1, ty: 1 }, { tx: 8, ty: 1 });
    expect(r.ok).toBe(true);
    expect(r.path.some((p) => p.tx === 6)).toBe(true);
    // a wall that falls back (a cave-in) closes it again
    map.setKind(6, 1, K.ROCK, "caveIn");
    expect(nav.findPath({ tx: 1, ty: 1 }, { tx: 8, ty: 1 }).ok).toBe(false);
  });

  test("a PathFollower searches again when the map changes and then heads through the new tunnel", () => {
    const map = mapOf(WALLED);
    const nav = navFor(map);
    const f = new PathFollower(nav);
    expect(f.goTo({ tx: 1, ty: 1 }, { tx: 8, ty: 1 }, 0.1)).toBe(false);
    expect(f.next).toBe(null);
    map.dig(6, 1, { tier: 0 });
    expect(f.goTo({ tx: 1, ty: 1 }, { tx: 8, ty: 1 }, 0.1)).toBe(false); // too soon after the last search
    expect(f.goTo({ tx: 1, ty: 1 }, { tx: 8, ty: 1 }, 0.5)).toBe(true);
    expect(f.next).toEqual({ tx: 2, ty: 1 });
    // the direction points at the centre of the next tile
    const c = map.tileCenter(1, 1);
    const d = f.direction(c);
    expect(d.x).toBeCloseTo(1, 3);
    expect(d.done).toBe(false);
  });

  test("a follower with dig lists the tiles it needs dug and a walker advances waypoint by waypoint", () => {
    const map = mapOf(WALLED);
    const f = new PathFollower(navFor(map), { dig: { tier: 0 } });
    expect(f.goTo({ tx: 1, ty: 1 }, { tx: 8, ty: 1 }, 1)).toBe(true);
    expect(f.digs).toEqual([{ tx: 6, ty: 1 }]);
    let pos = map.tileCenter(1, 1);
    for (let i = 0; i < 40 && !f.direction(pos).done; i++) {
      const d = f.direction(pos);
      pos = { x: pos.x + d.x * 4, y: pos.y + d.y * 4 };
    }
    expect(f.direction(pos).done).toBe(true);
    expect(distToTile(map, pos, { tx: 8, ty: 1 })).toBeLessThan(5);
  });
});

describe("reachable and line of sight", () => {
  test("reachable gives the tiles within some steps, never crossing walls or danger", () => {
    const map = mapOf(["BBBBBBBBB", "B.S.x..EB", "BBBBBBBBB"]);
    const tiles = navFor(map).reachable({ tx: 1, ty: 1 }, 10);
    expect(tiles.map((t) => t.tx).sort((a, b) => a - b)).toEqual([1, 2, 3]);
    expect(tiles.find((t) => t.tx === 3).d).toBe(2);
  });

  test("a straight line of floor is in sight; a wall in between is not", () => {
    const map = mapOf(WALLED);
    expect(lineOfSight(map, { tx: 1, ty: 1 }, { tx: 5, ty: 1 })).toBe(true);
    expect(lineOfSight(map, { tx: 1, ty: 1 }, { tx: 8, ty: 1 })).toBe(false);
    map.dig(6, 1, { tier: 0 });
    expect(lineOfSight(map, { tx: 1, ty: 1 }, { tx: 8, ty: 1 })).toBe(true);
  });
});
