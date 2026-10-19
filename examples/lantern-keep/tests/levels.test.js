import { test, expect, game } from "factoria:test";
import { fa } from "factoria";
import { LEVELS, WORLDS, EMBERS_PER_LEVEL, find, next, previous } from "../scripts/levels.js";
import en from "../locales/en.json";
import es from "../locales/es.json";

// Every level scene is built from its ASCII map (levels/<id>.json) by `factoria call scene.import_ascii @levels/<id>.json`.
// Importing the map again into a scratch file must give exactly the scene on disk: if one of these fails, rebuild the scene
// (or undo the hand edit of it).
for (const level of LEVELS) {
  test(`${level.scene} is what levels/${level.id}.json builds`, () => {
    const args = JSON.parse(fa.call("fs.read", { path: `levels/${level.id}.json` }).content);
    expect(args.path).toBe(level.scene);
    const rebuilt = `.factoria/tmp/${level.id}.rebuilt.scene.json`; // a scratch file: .factoria/tmp/ may be written and deleted
    const imported = fa.call("scene.import_ascii", { ...args, path: rebuilt });
    expect(imported.warnings).toEqual([]);
    const built = fa.call("fs.read", { path: rebuilt }).content;
    fa.call("fs.delete", { path: rebuilt });
    if (built !== fa.call("fs.read", { path: level.scene }).content)
      throw new Error(`${level.scene} is not what levels/${level.id}.json builds. Rebuild it with \`factoria call scene.import_ascii @levels/${level.id}.json\` (or undo the hand edit of the scene).`);
  });
}

test("scenes and prefabs are in the canonical layout", () => {
  // `factoria call scene.format` rewrites them; `{"check": true}` only lists the files that still need it.
  expect(fa.call("scene.format", { check: true }).notCanonical).toEqual([]);
});

test("scripts/levels.js: the ordered list, worlds and names", () => {
  expect(LEVELS.map((l) => l.id)).toEqual(["1-1", "1-2", "1-3", "2-1", "2-2", "2-3"]);
  expect(LEVELS.map((l) => l.world)).toEqual([1, 1, 1, 2, 2, 2]);
  for (const l of LEVELS) {
    expect(l.scene).toBe(`scenes/levels/${l.id}.scene.json`);
    expect(l.nameKey).toBe(`level.${l.id}`);
    for (const table of [en, es]) {
      expect(table.level[l.id]).toBeDefined();
      expect(table.level.world[String(l.world)]).toBeDefined();
    }
    expect(WORLDS[l.world].nameKey).toBe(`level.world.${l.world}`);
  }
  expect(find("2-1").world).toBe(2);
  expect(find("9-9")).toBeNull();
  expect(next("1-3").id).toBe("2-1");
  expect(next("2-3")).toBeNull();
  expect(previous("1-1")).toBeNull();
  expect(previous("2-1").id).toBe("1-3");
});

test("every level has what the game needs: start, exit, 3 embers, hazards, checkpoints, pause and store entities", () => {
  for (const level of LEVELS) {
    game.load(level.scene);
    game.step(2);
    const where = `level ${level.id}`;
    expect(game.find("player")).toBeDefined(); // the player start
    expect(game.world.findByTag("player")).toHaveLength(1);
    expect(game.world.findByTag("exit")).toHaveLength(1);
    expect(game.world.findByTag("ember")).toHaveLength(EMBERS_PER_LEVEL);
    for (let i = 1; i <= EMBERS_PER_LEVEL; i++) expect(game.find(`ember_${i}`).behaviour.index).toBe(i - 1);
    expect(game.world.findByTag("hazard").length).toBeGreaterThan(0);
    expect(game.world.findByTag("checkpoint").length).toBeGreaterThan(0);
    expect(game.find("pause_menu").behaviour).toBeDefined();
    expect(game.find("store_events").behaviour).toBeDefined();
    expect(game.find("level").behaviour.levelId).toBe(level.id);
    expect(game.find("hud_level").get("Text").text).toBe(en.level[level.id]); // the HUD names the level
    // from 1-2 on, patrolling enemies
    expect(game.world.findByTag("enemy").length > 0).toBe(level.id !== "1-1");
    // the dark world: a lit map, a lantern light and a parallax background; the daylight world has none of them
    const dark = WORLDS[level.world].dark;
    expect(game.find("map").get("Tilemap").lit).toBe(dark);
    expect(game.find("player").children.some((c) => c.has("Light2D"))).toBe(true);
    expect(game.find("bg_far") !== null).toBe(dark);
    if (dark) expect(game.find("bg_far").get("Parallax").repeatX).toBe(true);
    for (const enemy of game.world.findByTag("enemy")) expect(enemy.get("Sprite").lit).toBe(dark);
    for (const spikes of game.world.findByTag("hazard")) expect(spikes.get("Sprite").lit).toBe(dark);
  }
});

test("the game has a moving platform and a one-way platform", () => {
  const platforms = (id) => {
    game.load(find(id).scene);
    game.step(2);
    return game.world.findByTag("platform");
  };
  expect(platforms("1-3").some((p) => p.get("RigidBody2D").type === "kinematic")).toBe(true);
  expect(platforms("1-2").some((p) => p.get("Collider2D").oneWay)).toBe(true);
});

// An ember is placed where a jump reaches it: the player's jump rises about 195 px (6 tiles), so there must be something to
// jump from (a solid tile or a platform) at most 5 tiles below the ember and within 5 tiles sideways of it.
test("every ember can be reached with a jump", () => {
  for (const level of LEVELS) {
    game.load(level.scene);
    game.step(2);
    const map = game.find("map").get("Tilemap");
    const solid = new Set(map.solidTiles);
    const floors = (x, y) => {
      for (let dx = -5; dx <= 5; dx++) {
        for (let dy = 1; dy <= 5; dy++) {
          const col = Math.floor(x / 32) + dx;
          const row = map.height - 1 - Math.floor(y / 32) + dy;
          const above = map.height - 1 - Math.floor(y / 32) + dy - 1; // the tile above it must be free to stand in
          if (col >= 0 && col < map.width && row >= 0 && row < map.height && solid.has(map.tiles[row * map.width + col] & 0x0fffffff) && !solid.has(map.tiles[above * map.width + col] & 0x0fffffff)) return true;
        }
      }
      return game.world.findByTag("platform").some((p) => Math.abs(p.position.x - x) < 200 && y - p.position.y > 0 && y - p.position.y < 220);
    };
    for (let i = 1; i <= EMBERS_PER_LEVEL; i++) {
      const e = game.find(`ember_${i}`);
      if (!floors(e.position.x, e.position.y)) throw new Error(`level ${level.id}: ember_${i} at ${e.position.x},${e.position.y} has nothing to jump from within 5 tiles`);
    }
  }
});
