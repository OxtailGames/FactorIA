import { test, expect, game } from "factoria:test";

// The floors are grown by tilemap.generate; a test (like a headless run) gives the generator 500000 units of work per
// frame, so the number of frames a floor takes is the same on every machine. The tests never count those frames: they
// step until the floor is there.
const ACTIONS = { "1,0": "move_right", "-1,0": "move_left", "0,-1": "move_up", "0,1": "move_down" };

const hud = () => game.find("hud").get("Text").text;
const banner = () => game.find("banner").get("Text").text;
const dungeon = () => game.find("dungeon").behaviour;
const players = () => game.world.findByTag("player");
const floors = () => game.world.entities().filter((e) => e.id === "floor").length;

/** Steps until the current floor is placed and the player stands on it (or fails the test after `max` frames). */
function waitForFloor(max = 600) {
  for (let i = 0; i < max && !(dungeon().state === "playing" && players().length === 1); i++) game.step(1);
  expect(dungeon().state).toBe("playing");
  expect(players().length).toBe(1);
}

function start(runSeed) {
  game.load("scenes/main.scene.json");
  if (runSeed !== undefined) dungeon().runSeed = runSeed; // the behaviour exists after game.load; onStart runs on the first step
  game.step(1);
  waitForFloor();
}

/** The floor as the test sees it: solid cells from the Tilemap, coins and traps from their entities. */
function floorState() {
  const map = game.find("floor");
  const w = map.get("Tilemap").width;
  const h = map.get("Tilemap").height;
  const cellOf = (e) => {
    const c = map.tilemap.cellAt(e.position);
    return `${c.col},${c.row}`;
  };
  return {
    w,
    h,
    solid: (c, r) => c < 0 || r < 0 || c >= w || r >= h || map.get("Tilemap").solidTiles.includes(map.tilemap.getTile(c, r)),
    traps: new Set(game.world.findByTag("trap").map(cellOf)),
    coins: new Set(game.world.findByTag("coin").map(cellOf)),
    player: cellOf(players()[0]).split(",").map(Number),
    stairs: cellOf(game.world.findByTag("stairs")[0]).split(",").map(Number),
    rows: Array.from({ length: h }, (_, r) => Array.from({ length: w }, (_, c) => map.tilemap.getTile(c, r)).join(",")),
  };
}

/** Moves (as [dx, dy] steps) along a shortest walk from `from` to `to`; trap cells are only crossed when `crossTraps`. */
function route(f, from, to, crossTraps = false) {
  const key = (c, r) => `${c},${r}`;
  const prev = new Map([[key(...from), null]]);
  const queue = [from];
  for (let i = 0; i < queue.length; i++) {
    const [c, r] = queue[i];
    if (c === to[0] && r === to[1]) break;
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const n = [c + dx, r + dy];
      const k = key(...n);
      if (prev.has(k) || f.solid(...n)) continue;
      if (!crossTraps && f.traps.has(k) && !(n[0] === to[0] && n[1] === to[1])) continue;
      prev.set(k, [c, r]);
      queue.push(n);
    }
  }
  if (!prev.has(key(...to))) return null;
  const moves = [];
  for (let at = to; prev.get(key(...at)); at = prev.get(key(...at))) {
    const p = prev.get(key(...at));
    moves.unshift([at[0] - p[0], at[1] - p[1]]);
  }
  return moves;
}

function walk(moves) {
  for (const [dx, dy] of moves) game.tap(ACTIONS[`${dx},${dy}`]);
}

/** Walks the player from the start to the stairs without touching a trap. */
function descend() {
  const f = floorState();
  const moves = route(f, f.player, f.stairs);
  expect(moves).not.toBeNull();
  walk(moves);
}

test("the scene starts digging floor 1 and the HUD says so; the floor appears after some frames", () => {
  game.load("scenes/main.scene.json");
  expect(dungeon().runSeed).toBe(2026);
  game.step(1);
  expect(hud()).toContain("Floor 1 of 4");
  expect(hud()).toContain("Digging floor 1");
  expect(players().length).toBe(0);
  waitForFloor();
  expect(hud()).toBe("Floor 1 of 4   Lives 3   Coins 0   Score 0");
  expect(game.find("floor")).not.toBeNull();
  expect(game.find("banner_bg").active).toBe(false);
});

test("a floor has a border, the player and the stairs on free cells, and coins and traps from the sample", () => {
  start();
  const f = floorState();
  expect(f.w).toBe(36);
  expect(f.h).toBe(18);
  for (let c = 0; c < f.w; c++) {
    expect(f.solid(c, 0)).toBe(true);
    expect(f.solid(c, f.h - 1)).toBe(true);
  }
  for (let r = 0; r < f.h; r++) {
    expect(f.solid(0, r)).toBe(true);
    expect(f.solid(f.w - 1, r)).toBe(true);
  }
  expect(f.solid(...f.player)).toBe(false);
  expect(f.solid(...f.stairs)).toBe(false);
  expect(f.player).not.toEqual(f.stairs);
  expect(f.coins.size).toBeGreaterThanOrEqual(4);
  expect(f.coins.size).toBeLessThanOrEqual(12);
  expect(f.traps.size).toBeLessThanOrEqual(8);
  expect(f.coins.has(f.player.join(","))).toBe(false);
  expect(f.traps.has(f.player.join(","))).toBe(false);
  // The player stands at the centre of its cell.
  const centre = game.find("floor").tilemap.cellToWorld(...f.player);
  expect(players()[0].position.x).toBeCloseTo(centre.x, 3);
  expect(players()[0].position.y).toBeCloseTo(centre.y, 3);
});

test("the stairs can be reached without crossing a trap, on many run seeds", () => {
  for (const seed of [1, 2, 3, 7, 42, 2026, 99999, 2147483647]) {
    start(seed);
    const f = floorState();
    const moves = route(f, f.player, f.stairs);
    expect(moves).not.toBeNull();
    expect(moves.length).toBeGreaterThan(10);
  }
});

test("a trap-free way to the stairs is the usual case: it is counted over thirty run seeds, not promised", () => {
  // The README says the generator does not promise a way around the spikes, so this counts the floors without one (a
  // breadth-first walk from the entrance that never steps on a spike) and fails only when they stop being the exception.
  // Every run seed must reach play: a floor that will not grow within its attempts is dug again from a fresh seed.
  const trapped = [];
  const notGrown = [];
  const seeds = Array.from({ length: 30 }, (_, i) => 100 + i * 37);
  for (const seed of seeds) {
    game.load("scenes/main.scene.json");
    dungeon().runSeed = seed;
    for (let i = 0; i < 600 && !(dungeon().state === "playing" && players().length === 1) && dungeon().state !== "failed"; i++) game.step(1);
    if (dungeon().state === "failed") {
      notGrown.push(seed);
      continue;
    }
    expect(dungeon().state).toBe("playing");
    const f = floorState();
    if (route(f, f.player, f.stairs) === null) trapped.push(seed);
  }
  console.log(`of ${seeds.length} seeds: no trap-free way to the stairs ${JSON.stringify(trapped)}, floor not grown ${JSON.stringify(notGrown)}`);
  expect(trapped.length).toBeLessThanOrEqual(3);
  expect(notGrown).toEqual([]); // a floor that will not grow is dug again from a fresh seed (FLOOR_RETRIES)
});

test("constraints.place puts the stairs on the cell that is farthest from the player by walking", () => {
  for (const seed of [1, 42, 2026]) {
    start(seed);
    const f = floorState();
    const dist = new Map([[f.player.join(","), 0]]);
    const queue = [f.player];
    for (let i = 0; i < queue.length; i++) {
      const [c, r] = queue[i];
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const k = `${c + dx},${r + dy}`;
        if (dist.has(k) || f.solid(c + dx, r + dy)) continue;
        dist.set(k, dist.get(`${c},${r}`) + 1);
        queue.push([c + dx, r + dy]);
      }
    }
    // The engine measures with the same 4-way steps (no diagonals); the stairs only replace plain floor, so a coin or a
    // trap cell farther away does not count.
    const plain = [...dist].filter(([k]) => !f.coins.has(k) && !f.traps.has(k)).map(([, d]) => d);
    expect(dist.get(f.stairs.join(","))).toBe(Math.max(...plain));
  }
});

test("the same run seed is the same dungeon, another seed is another one", () => {
  start(77);
  const a = floorState();
  start(77);
  const b = floorState();
  expect(b.rows).toEqual(a.rows);
  expect(b.player).toEqual(a.player);
  expect(b.stairs).toEqual(a.stairs);
  expect([...b.coins].sort()).toEqual([...a.coins].sort());
  start(78);
  expect(floorState().rows).not.toEqual(a.rows);
});

test("a key press moves one cell; a wall stops the player", () => {
  start();
  const f = floorState();
  const [c, r] = f.player;
  const open = [[1, 0], [-1, 0], [0, 1], [0, -1]].find(([dx, dy]) => !f.solid(c + dx, r + dy) && !f.traps.has(`${c + dx},${r + dy}`));
  walk([open]);
  expect(floorState().player).toEqual([c + open[0], r + open[1]]);
  // The player stands anywhere on the floor now, so walk straight along a free line until a wall is next: the run of
  // free, trap-free cells ends at a wall in at least one of the four directions (the border is solid all round).
  const g = floorState();
  const [pc, pr] = g.player;
  const runs = [[1, 0], [-1, 0], [0, 1], [0, -1]].map(([dx, dy]) => {
    let n = 0;
    while (!g.solid(pc + (n + 1) * dx, pr + (n + 1) * dy) && !g.traps.has(`${pc + (n + 1) * dx},${pr + (n + 1) * dy}`)) n++;
    return { dx, dy, n, wall: g.solid(pc + (n + 1) * dx, pr + (n + 1) * dy) };
  });
  const line = runs.find((run) => run.wall);
  expect(line).toBeDefined();
  walk(Array.from({ length: line.n }, () => [line.dx, line.dy]));
  const at = [pc + line.n * line.dx, pr + line.n * line.dy];
  expect(floorState().player).toEqual(at);
  walk([[line.dx, line.dy]]);
  expect(floorState().player).toEqual(at); // blocked: it did not move
});

test("walking onto a coin picks it up for 10 points", () => {
  start();
  const f = floorState();
  const coin = [...f.coins].map((k) => k.split(",").map(Number)).find((c) => route(f, f.player, c) !== null);
  expect(coin).toBeDefined();
  const moves = route(f, f.player, coin);
  walk(moves);
  expect(floorState().coins.has(coin.join(","))).toBe(false);
  expect(dungeon().coins).toBeGreaterThanOrEqual(1);
  expect(dungeon().score).toBe(dungeon().coins * 10);
  expect(hud()).toContain(`Coins ${dungeon().coins}`);
});

test("a trap costs a life and is spent; the third one ends the run", () => {
  start();
  const f = floorState();
  const traps = [...f.traps].map((k) => k.split(",").map(Number));
  expect(traps.length).toBeGreaterThanOrEqual(3);
  let at = f.player;
  for (let i = 0; i < 3; i++) {
    const g = floorState();
    const moves = route(g, at, traps[i], true);
    expect(moves).not.toBeNull();
    walk(moves);
    at = traps[i];
    expect(dungeon().lives).toBe(2 - i);
    expect(game.world.findByTag("trap").length).toBe(f.traps.size - 1 - i);
  }
  expect(dungeon().state).toBe("lost");
  expect(banner()).toContain("You fell on floor 1");
  expect(game.find("banner_bg").active).toBe(true);
  // A lost run takes no more moves.
  const where = floorState().player;
  game.tap("move_left");
  game.tap("move_right");
  expect(floorState().player).toEqual(where);
});

test("the stairs lead to floor 2: a new floor is grown, the old one is gone", () => {
  start();
  const before = floorState();
  descend();
  expect(dungeon().state).toBe("generating");
  expect(hud()).toContain("Floor 2 of 4");
  expect(hud()).toContain("Digging floor 2");
  expect(players().length).toBe(0);
  expect(game.world.findByTag("stairs").length).toBe(0);
  waitForFloor();
  const after = floorState();
  expect(after.rows).not.toEqual(before.rows);
  expect(dungeon().floorNumber).toBe(2);
  expect(dungeon().score).toBeGreaterThanOrEqual(50);
  expect(game.world.findByTag("stairs").length).toBe(1);
  expect(floors()).toBe(1);
});

test("four floors win the run; Space starts a new dungeon with a new seed", () => {
  start(5);
  for (let floor = 1; floor <= 4; floor++) {
    expect(dungeon().floorNumber).toBe(floor);
    descend();
    if (floor < 4) waitForFloor();
  }
  expect(dungeon().state).toBe("won");
  expect(banner()).toContain("You reached the bottom!");
  expect(dungeon().score).toBe(200);
  game.tap("confirm");
  expect(dungeon().runSeed).not.toBe(5);
  expect(dungeon().state).toBe("generating");
  waitForFloor();
  expect(hud()).toBe("Floor 1 of 4   Lives 3   Coins 0   Score 0");
  expect(game.find("banner_bg").active).toBe(false);
});

test("R plays the same dungeon again from the start", () => {
  start(11);
  const first = floorState();
  const coin = [...first.coins].map((k) => k.split(",").map(Number)).find((c) => route(first, first.player, c) !== null);
  walk(route(first, first.player, coin));
  expect(dungeon().coins).toBeGreaterThanOrEqual(1);
  game.tap("restart");
  waitForFloor();
  expect(dungeon().runSeed).toBe(11);
  expect(dungeon().coins).toBe(0);
  const again = floorState();
  expect(again.rows).toEqual(first.rows);
  expect(again.player).toEqual(first.player);
  expect([...again.coins].sort()).toEqual([...first.coins].sort());
  expect(floors()).toBe(1);
});

test("pressing R while a floor is still growing leaves exactly one floor and one player", () => {
  game.load("scenes/main.scene.json");
  game.step(2);
  expect(dungeon().state).toBe("generating");
  game.tap("restart");
  game.tap("restart");
  waitForFloor();
  expect(floors()).toBe(1);
  expect(players().length).toBe(1);
  expect(game.world.findByTag("stairs").length).toBe(1);
});

test("reloading the scene while a floor is growing ends that generation: nothing of it is placed in the new scene", () => {
  game.load("scenes/main.scene.json");
  game.step(2);
  expect(dungeon().state).toBe("generating");
  const old = dungeon();
  game.load("scenes/main.scene.json"); // a reload: the old job belongs to the scene that is gone
  expect(dungeon()).not.toBe(old);
  expect(game.find("floor")).toBeNull();
  game.step(1);
  waitForFloor();
  expect(floors()).toBe(1);
  expect(players().length).toBe(1);
  expect(game.world.findByTag("coin").length).toBeGreaterThanOrEqual(4);
});

test("a tap beside the hero steps that way", () => {
  start();
  const f = floorState();
  const [c, r] = f.player;
  const open = [[1, 0], [-1, 0], [0, 1], [0, -1]].find(([dx, dy]) => !f.solid(c + dx, r + dy) && !f.traps.has(`${c + dx},${r + dy}`));
  const here = game.find("floor").tilemap.cellToWorld(c, r);
  // Screen pixels: the world origin is the centre of the 1280x720 screen and +Y points down on screen.
  game.click([640 + here.x + open[0] * 40, 360 - here.y + open[1] * 40]);
  expect(floorState().player).toEqual([c + open[0], r + open[1]]);
});
