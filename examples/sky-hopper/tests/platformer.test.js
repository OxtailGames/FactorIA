import { test, expect, game } from "factoria:test";
import { fa } from "factoria";
import { state, resetState } from "scripts/game_state.js";

function load(path = "scenes/level1.scene.json") {
  resetState();
  game.load(path);
  game.step(30); // settle onto the ground
  return game.find("player");
}

// The follow camera stops at the edge of the map. It does not keep its own copy of the map size: the clamp rectangle is
// the bounds() of the Tilemap entity named by its `bounds` prop, so it follows the map when the map changes size.
function expectCameraFitsMap() {
  const map = fa.call("scene.get_entity", { id: "map" }).components.Tilemap;
  const area = game.find("map").bounds();
  // The map is imported with anchor bottom-left at the origin: it covers (0, 0) to (columns * tile, rows * tile).
  expect([area.x, area.y, area.w, area.h]).toEqual([0, 0, map.width * map.tileSize[0], map.height * map.tileSize[1]]);
  const lim = game.find("camera").behaviour.limits();
  expect([lim.minX, lim.minY, lim.maxX, lim.maxY]).toEqual([area.x, area.y, area.x + area.w, area.y + area.h]);
}

// No level scene carries hand-set camera limits (they would drift from the map): the camera only names the Tilemap
// entity. That holds for the hand-made levels and for scenes/generated.scene.json written by project.generate_level.
function expectCameraDerivesLimitsFromMap() {
  const props = fa.call("scene.get_entity", { id: "camera" }).components.Script.props;
  expect(props.bounds).toBe("map");
  for (const key of ["minX", "maxX", "minY", "maxY"]) expect(props[key]).toBe(undefined);
}

test("player lands on the ground", () => {
  const p = load();
  expect(p.position.y).toBeGreaterThan(110);
  expect(p.position.y).toBeLessThan(125);
});

test("player runs right and left", () => {
  const p = load();
  const x0 = p.position.x;
  game.press("move_right");
  game.step(30);
  game.release("move_right");
  expect(p.position.x).toBeGreaterThan(x0 + 100);
  const x1 = p.position.x;
  game.press("move_left");
  game.step(20);
  game.release("move_left");
  expect(p.position.x).toBeLessThan(x1 - 40);
});

test("player jumps from the ground and lands again", () => {
  const p = load();
  const y0 = p.position.y;
  game.clearAudioLog();
  game.press("jump");
  game.step(12);
  game.release("jump");
  expect(p.position.y).toBeGreaterThan(y0 + 30);
  expect(game.audioLog()).toContainPlayed("assets/sfx/jump.wav", { times: 1 });
  game.step(90);
  expect(Math.abs(p.position.y - y0)).toBeLessThan(3);
});

test("holding jump jumps higher than tapping", () => {
  let p = load();
  const y0 = p.position.y;
  game.press("jump"); game.step(2); game.release("jump");
  let tap = 0;
  for (let i = 0; i < 40; i++) { game.step(1); tap = Math.max(tap, p.position.y - y0); }
  p = load();
  game.press("jump");
  let hold = 0;
  for (let i = 0; i < 42; i++) { game.step(1); hold = Math.max(hold, p.position.y - y0); }
  game.release("jump");
  expect(hold).toBeGreaterThan(tap + 20);
});

test("jump buffering: pressing jump just before landing still jumps", () => {
  const p = load();
  game.press("jump"); game.step(2); game.release("jump");
  // wait until nearly landed, then press again
  for (let i = 0; i < 90 && p.position.y > 128; i++) game.step(1);
  game.step(0);
  const before = p.position.y;
  game.press("jump"); game.step(1); game.release("jump");
  game.step(6);
  expect(p.position.y).toBeGreaterThan(before + 5);
});

test("coyote time: can jump shortly after leaving a ledge", () => {
  const p = load();
  // ground ends at x=256; walk off the ledge
  game.press("move_right");
  for (let i = 0; i < 200 && p.position.x < 262; i++) game.step(1);
  game.step(3);
  game.press("jump");
  game.step(1);
  game.release("jump");
  game.release("move_right");
  expect(p.position.y).toBeGreaterThan(0);
  const vy = game.world.find("player").get("RigidBody2D").velocity.y;
  expect(vy).toBeGreaterThan(300);
});

test("collecting a coin removes it, counts it and bursts particles", () => {
  const p = load();
  const coin = game.find("coin_1");
  expect(coin).not.toBeNull();
  p.position.x = coin.position.x;
  p.position.y = coin.position.y;
  game.step(3);
  expect(game.find("coin_1")).toBeNull();
  expect(state.coins).toBe(1);
  expect(game.audioLog()).toContainPlayed("coin.wav", { times: 1 });
  expect(game.world.findByTag("fx").length).toBeGreaterThan(0);
});

test("stomping an enemy kills it and bounces the player", () => {
  const p = load();
  const e = game.find("enemy_1");
  p.position.x = e.position.x;
  p.position.y = e.position.y + 80;
  game.world.find("player").get("RigidBody2D").velocity.y = -100;
  game.step(20);
  expect(game.find("enemy_1")).toBeNull();
  expect(state.lives).toBe(3);
  expect(game.audioLog()).toContainPlayed("stomp.wav");
  expect(game.audioLog()).not.toContainPlayed("hurt.wav");
});

test("side contact with an enemy costs a life and respawns at level start", () => {
  const p = load();
  const e = game.find("enemy_1");
  const sx = p.position.x;
  p.position.x = e.position.x - 60;
  p.position.y = e.position.y;
  game.press("move_right");
  for (let i = 0; i < 60 && state.lives === 3; i++) game.step(1);
  game.release("move_right");
  expect(state.lives).toBe(2);
  expect(game.audioLog()).toContainPlayed("hurt.wav");
  expect(Math.abs(p.position.x - sx)).toBeLessThan(10);
});

test("falling into a pit costs a life", () => {
  const p = load();
  p.position.x = 288;
  p.position.y = 100;
  game.step(120);
  expect(state.lives).toBe(2);
  expect(p.position.y).toBeGreaterThan(0);
});

test("enemies patrol", () => {
  load();
  const e = game.find("enemy_1");
  const x0 = e.position.x;
  game.step(60);
  expect(Math.abs(e.position.x - x0)).toBeGreaterThan(20);
});

test("reaching the goal loads the next level", () => {
  const p = load();
  const goal = game.find("goal");
  p.position.x = goal.position.x;
  p.position.y = goal.position.y;
  game.step(90);
  expect(game.audioLog()).toContainPlayed("win.wav", { times: 1 });
  expect(state.level).toBe(2);
  expect(game.find("goal")).not.toBeNull();
  expect(game.find("enemy_1")).not.toBeNull();
});

test("losing all lives shows game over, confirm restarts", () => {
  const p = load();
  state.lives = 1;
  p.position.y = -500;
  game.step(60);
  expect(game.find("title")).not.toBeNull();
  game.tap("confirm");
  game.step(5);
  expect(game.find("player")).not.toBeNull();
  expect(state.lives).toBe(3);
});

test("camera follows the player but stays inside level bounds", () => {
  const p = load();
  const cam = game.find("camera");
  expect(cam.position.x).toBeCloseTo(640, 0);
  p.position.x = 1120; p.position.y = 130;
  game.step(120);
  expect(cam.position.x).toBeGreaterThan(900);
  p.position.x = 1900; 
  game.step(120);
  expect(cam.position.x).toBeLessThan(1281);
});

// Whatever the map size, the camera view stays inside the Tilemap: it stops half a view from each edge, and a map lower than
// the view (512 px against 720 px) is centred.
for (const path of ["scenes/level1.scene.json", "scenes/level2.scene.json", "scenes/generated.scene.json"]) {
  test(`the camera in ${path} clamps to the edges of the Tilemap`, () => {
    load(path);
    const area = game.find("map").bounds();
    const cam = game.find("camera").behaviour;
    expect(cam.clampPos(-1e6, 0)[0]).toBe(area.x + cam.viewW / 2);
    expect(cam.clampPos(1e6, 0)[0]).toBe(area.x + area.w - cam.viewW / 2);
    expect(area.h).toBeLessThan(cam.viewH);
    expect(cam.clampPos(0, -1e6)[1]).toBe(area.y + area.h / 2);
    expect(cam.clampPos(0, 1e6)[1]).toBe(area.y + area.h / 2);
  });
}

test("project.generate_level is deterministic and has the required entities", () => {
  const args = { width: 60, seed: 5, difficulty: 2, dryRun: true };
  const a = fa.call("project.generate_level", args);
  const b = fa.call("project.generate_level", args);
  expect(JSON.stringify(a.scene)).toBe(JSON.stringify(b.scene));
  const c = fa.call("project.generate_level", { ...args, seed: 6 });
  expect(JSON.stringify(c.scene)).not.toBe(JSON.stringify(a.scene));
  const ids = a.scene.entities.map((e) => e.id);
  expect(ids).toContain("player");
  expect(ids).toContain("goal");
  expect(ids).toContain("map");
});

test("project.generate_level composes ASCII rows and scene.import_ascii builds the scene from them", () => {
  const out = fa.call("project.generate_level", { width: 30, seed: 3, difficulty: 2, dryRun: true });
  expect(out.rows).toEqual([
    "..............................",
    "..............................",
    "..............................",
    "..............................",
    "..............................",
    "..............................",
    "..............................",
    "..............................",
    "..............................",
    ".........o.o..................",
    "........o==..........o........",
    ".............o.o............F.",
    "..P...........E...........####",
    "########....#######...####%%%%",
    "%%%%%%%%....%%%%%%%...%%%%%%%%",
    "%%%%%%%%....%%%%%%%...%%%%%%%%",
  ]);
  const byId = Object.fromEntries(out.scene.entities.map((e) => [e.id, e]));
  // The tiles are the rows: # grass 0, % dirt 1, = brick 2, everything else empty.
  const tm = byId.map.components.Tilemap;
  const tile = { "#": 0, "%": 1, "=": 2 };
  expect(tm.width).toBe(30);
  expect(tm.height).toBe(16);
  expect(tm.tiles).toEqual(out.rows.join("").split("").map((ch) => (ch in tile ? tile[ch] : -1)));
  expect(tm.columns).toBeUndefined(); // derived from the tileset image
  // The objects stand in the cells of their glyphs (cell centres; the flag and the crawler have a small legend offset).
  const at = (col, row, dx = 0, dy = 0) => [col * 32 + 16 + dx, 512 - row * 32 - 16 + dy, 0];
  expect(byId.player.components.Transform.position).toEqual(at(2, 12));
  expect(byId.goal.components.Transform.position).toEqual(at(28, 11, 0, 16));
  expect(byId.enemy_1.components.Transform.position).toEqual(at(14, 12, 0, -4));
  expect(out.coins).toBe(6);
  expect(out.scene.entities.filter((e) => e.id.startsWith("coin_")).length).toBe(6);
  expect(byId.coin_1.components.Transform.position).toEqual(at(9, 9)); // ids are row-major
  expect(out.enemies).toBe(1);
  expect(byId.camera.components.Script.props.bounds).toBe("map"); // limits come from the map, not from props
  expect(byId.camera.components.Script.props.maxX).toBe(undefined);
});

// scene.import_ascii {path, from} edits the scene FILE in a scratch world: there is nothing to restore afterwards.
test("project.generate_level never touches the running game, with or without dryRun", () => {
  const p = load();
  game.press("move_right");
  game.step(12);
  const running = () => {
    const s = fa.call("game.state", { maxEntities: 100000 });
    return JSON.stringify({ entities: s.entities, physics: s.physics, audio: s.audio, scene: fa.call("project.info").currentScene });
  };
  const x = p.position.x;
  const before = running();
  const committed = fa.call("fs.read", { path: "scenes/generated.scene.json" }).content;

  fa.call("project.generate_level", { width: 40, seed: 2, dryRun: true });
  expect(running()).toBe(before);
  expect(fa.call("fs.read", { path: "scenes/generated.scene.json" }).content).toBe(committed); // dryRun writes nothing

  const path = ".factoria/tmp/generate_level.running.scene.json";
  fa.call("project.generate_level", { width: 40, seed: 2, path });
  expect(running()).toBe(before); // a real write does not reload, move or reset anything either
  expect(p.position.x).toBe(x);
  expect(fa.call("project.info").currentScene).toBe("scenes/level1.scene.json");
  expect(game.find("player")).not.toBeNull();
  expect(fa.call("fs.read", { path }).content.length).toBeGreaterThan(1000);

  // The scratch copy of the base scene is gone; delete the output with the same command that wrote it.
  const left = fa.call("fs.list", { path: ".factoria/tmp" }).entries.map((e) => e.path);
  expect(left).toContain(path);
  expect(left).not.toContain(".factoria/tmp/generate_level.base.scene.json");
  fa.call("fs.delete", { path });
  game.release("move_right");
});

test("project.generate_level writes a scene file that loads and plays", () => {
  const path = ".factoria/tmp/generate_level.scene.json";
  const out = fa.call("project.generate_level", { width: 30, seed: 3, path });
  expect(out.path).toBe(path);
  const text = fa.call("fs.read", { path }).content;
  expect(text).not.toContain('"columns"');
  const mapRows = text.split("\n").filter((l) => /^[-\d, ]+$/.test(l) && l.match(/-?\d+/g).length === 30);
  expect(mapRows.length).toBe(16); // compact layout: tiles one map row per line
  const p = load(path);
  expect(p.position.y).toBeGreaterThan(100);
  expect(game.find("goal")).not.toBeNull();
  fa.call("fs.delete", { path }); // .factoria/tmp/ is the scratch folder: files written there can be deleted again
  expect(fa.call("fs.list", { path: ".factoria/tmp" }).entries.map((e) => e.path)).not.toContain(path);
});

// The ASCII maps in levels/ are the source of truth of the hand-made levels. Importing a map into its own scene must
// change nothing: if this fails, rebuild the scene (see README.md, "Levels") or fix the map.
for (const name of ["level1", "level2"]) {
  test(`scenes/${name}.scene.json is what levels/${name}.json builds`, () => {
    const args = JSON.parse(fa.call("fs.read", { path: `levels/${name}.json` }).content);
    const scene = `scenes/${name}.scene.json`;
    expect(args.path).toBe(scene); // the map names the scene it builds
    // Rebuild into a scratch file (the same call as the README's, with another `path`) and compare the bytes.
    const rebuilt = `.factoria/tmp/${name}.rebuilt.scene.json`;
    const imported = fa.call("scene.import_ascii", { ...args, path: rebuilt, from: scene });
    expect(imported.warnings).toEqual([]);
    expect(imported.removed.length).toBe(imported.spawned.length);
    const committed = fa.call("fs.read", { path: scene }).content;
    expect(fa.call("fs.read", { path: rebuilt }).content).toBe(committed);
    fa.call("fs.delete", { path: rebuilt });
    expect(committed).not.toContain('"columns"');
    resetState();
    game.load(scene);
    expectCameraFitsMap();
    expectCameraDerivesLimitsFromMap();
  });
}

test("the committed generated level (scenes/generated.scene.json) loads and runs", () => {
  const p = load("scenes/generated.scene.json");
  expectCameraFitsMap();
  expectCameraDerivesLimitsFromMap();
  expect(p.position.y).toBeGreaterThan(100);
  expect(game.find("goal")).not.toBeNull();
  const goal = game.find("goal");
  p.position.x = goal.position.x; p.position.y = goal.position.y;
  game.step(90);
  expect(game.find("title")).not.toBeNull(); // win screen
});
