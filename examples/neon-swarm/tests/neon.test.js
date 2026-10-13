import { test, expect, describe, game } from "factoria:test";
import { storage, world, vec3 } from "factoria";

function loadGame() {
  storage.remove("highScore");
  storage.remove("lastScore");
  game.load("scenes/game.scene.json");
  game.step(1); // behaviours are instantiated on the first step after a load
}
function clearEnemies() {
  for (const e of world.findByTag("enemy")) e.destroy();
  game.step(1);
}
const mgr = () => game.find("manager").behaviour;
const player = () => game.find("player");

describe("shooting", () => {
  test("holding fire aimed at an enemy kills it and scores", () => {
    loadGame();
    const m = mgr();
    m.timer = 999; // no waves during this test
    const target = world.spawnPrefab("prefabs/chaser.prefab.json", { position: vec3(300, 0, 0) });
    game.mouseMove([1100, 360]); // world (460, 0): right of the player
    game.press("action");
    game.step(90);
    game.release("action");
    expect(target.alive).toBe(false);
    expect(m.score).toBeGreaterThanOrEqual(100);
    expect(m.kills).toBe(1);
    expect(player().behaviour.shots).toBeGreaterThan(1);
  });

  test("bullets die on walls", () => {
    loadGame();
    mgr().timer = 999;
    game.mouseMove([1100, 360]);
    game.press("action");
    game.step(2);
    game.release("action");
    expect(world.findByTag("bullet").length).toBeGreaterThan(0);
    game.step(90); // 1.5 s at 900 px/s is far beyond the right wall at x=600
    expect(world.findByTag("bullet").length).toBe(0);
  });
});

describe("enemy types", () => {
  test("splitter splits into three minis", () => {
    loadGame();
    mgr().timer = 999;
    const s = world.spawnPrefab("prefabs/splitter.prefab.json", { position: vec3(400, 200, 0) });
    game.step(1);
    s.behaviour.hurt(99);
    game.step(2);
    expect(s.alive).toBe(false);
    expect(world.findByTag("enemy").length).toBe(3);
  });

  test("shooter fires enemy bullets at the player", () => {
    loadGame();
    mgr().timer = 999;
    world.spawnPrefab("prefabs/shooter.prefab.json", { position: vec3(300, 0, 0) });
    game.step(150);
    expect(world.findByTag("ebullet").length + player().behaviour.maxHp - player().behaviour.hp).toBeGreaterThan(0);
  });
});

describe("damage", () => {
  test("a hit costs 1 hp and grants invulnerability", () => {
    loadGame();
    mgr().timer = 999;
    const p = player().behaviour;
    expect(p.hp).toBe(5);
    expect(p.hurt(1)).toBe(true);
    expect(p.hp).toBe(4);
    expect(p.hurt(1)).toBe(false); // invulnerable
    expect(p.hp).toBe(4);
    game.step(90); // 1.5 s > invulnTime (1.2 s)
    expect(p.invuln).toBeLessThanOrEqual(0);
    expect(p.hurt(1)).toBe(true);
    expect(p.hp).toBe(3);
  });

  test("a touching chaser hurts the player only once per invulnerability window", () => {
    loadGame();
    mgr().timer = 999;
    world.spawnPrefab("prefabs/chaser.prefab.json", { position: vec3(10, 0, 0) });
    game.step(30);
    expect(player().behaviour.hp).toBe(4);
  });
});

describe("waves", () => {
  test("clearing a wave starts a bigger one with new enemy types", () => {
    loadGame();
    const m = mgr();
    expect(m.wave).toBe(0);
    game.step(70); // initial 1 s countdown
    expect(m.wave).toBe(1);
    const budget1 = m.pending.length + world.findByTag("enemy").length;
    expect(budget1).toBeGreaterThan(0);
    m.pending = [];
    clearEnemies();
    game.step(1);
    expect(m.state).toBe("intermission");
    game.step(130); // 2 s intermission
    expect(m.wave).toBe(2);
    const total2 = m.pending.length + world.findByTag("enemy").length;
    expect(total2).toBeGreaterThan(budget1);
    expect(m.difficulty()).toBeGreaterThan(1);
  });

  test("waves 1..4 unlock shooters and splitters", () => {
    loadGame();
    const m = mgr();
    const kindsSeen = new Set();
    for (let w = 0; w < 4; w++) {
      m.timer = 0;
      game.step(2);
      m.pending.forEach((k) => kindsSeen.add(k));
      m.pending = [];
      clearEnemies();
      game.step(1);
    }
    expect(m.wave).toBe(4);
    expect(kindsSeen.has("chaser")).toBe(true);
    expect(kindsSeen.has("shooter")).toBe(true);
    expect(kindsSeen.has("splitter")).toBe(true);
  });
});

describe("score and high score", () => {
  test("combo multiplier grows with quick kills and resets on timeout", () => {
    loadGame();
    const m = mgr();
    m.timer = 999;
    for (let i = 0; i < 5; i++) {
      const e = world.spawnPrefab("prefabs/chaser.prefab.json", { position: vec3(500, 250, 0) });
      game.step(1);
      e.behaviour.hurt(99);
      game.step(1);
    }
    expect(m.combo).toBe(5);
    expect(m.multiplier).toBe(2);
    game.step(180); // 3 s > comboWindow
    expect(m.combo).toBe(0);
    expect(m.multiplier).toBe(1);
  });

  test("dying saves the high score and the game-over scene shows it", () => {
    loadGame();
    const m = mgr();
    m.timer = 999;
    m.score = 1234;
    player().behaviour.hp = 0;
    game.step(2);
    expect(m.state).toBe("over");
    expect(storage.get("highScore", 0)).toBe(1234);
    game.step(90); // game-over delay, then scene change
    expect(game.find("final")).not.toBeNull();
    // a lower score later must not overwrite it
    loadGame();
    storage.set("highScore", 1234);
    game.load("scenes/game.scene.json");
    game.step(1);
    const m2 = mgr();
    expect(m2.highScore).toBe(1234);
    m2.timer = 999;
    m2.score = 10;
    player().behaviour.hp = 0;
    game.step(2);
    expect(storage.get("highScore", 0)).toBe(1234);
  });
});

describe("flow", () => {
  test("title -> game on action, and tool reports metrics", () => {
    storage.remove("highScore");
    game.load("scenes/title.scene.json");
    game.step(40);
    expect(game.find("prompt")).not.toBeNull();
    game.tap("action");
    game.step(3);
    expect(game.find("manager")).not.toBeNull();
  });
});

describe("neon look", () => {
  test("every scene turns on camera bloom over a dark background", () => {
    for (const path of ["scenes/title.scene.json", "scenes/game.scene.json", "scenes/gameover.scene.json"]) {
      game.load(path);
      game.step(1);
      const cam = game.find("camera").get("Camera");
      expect(cam.bloom).toBe(true);
      expect(cam.bloomThreshold).toBeLessThan(1);
      expect(Math.max(cam.clearColor.r, cam.clearColor.g, cam.clearColor.b)).toBeLessThan(0.15);
    }
  });

  test("the HUD is drawn after the bloom in the game scene (crisp), the titles still glow", () => {
    game.load("scenes/game.scene.json");
    game.step(1);
    expect(game.find("camera").get("Camera").bloomScreenSpace).toBe(false);
    for (const path of ["scenes/title.scene.json", "scenes/gameover.scene.json"]) {
      game.load(path);
      game.step(1);
      expect(game.find("camera").get("Camera").bloomScreenSpace).toBe(true);
    }
  });

  test("the chaser is a spinning diamond, triangles spin about their centroid", () => {
    loadGame();
    mgr().timer = 999;
    const chaser = world.spawnPrefab("prefabs/chaser.prefab.json", { position: vec3(400, 200, 0) });
    expect(chaser.get("Shape2D").shape).toBe("diamond");
    const shooter = world.spawnPrefab("prefabs/shooter.prefab.json", { position: vec3(-400, 200, 0) });
    expect(shooter.get("Shape2D").shape).toBe("triangle");
    for (const e of [shooter, player()]) {
      expect(e.get("Shape2D").pivot.y).toBeCloseTo(1 / 3, 2);
      expect(e.get("Shape2D").pivot.x).toBeCloseTo(0.5, 2);
    }
  });

  test("the player, the enemies and the bullets are bright additive shapes", () => {
    loadGame();
    mgr().timer = 999;
    const things = [player()];
    for (const name of ["chaser", "shooter", "splitter", "mini", "bullet", "enemy_bullet"]) {
      things.push(world.spawnPrefab("prefabs/" + name + ".prefab.json", { position: vec3(400, 200, 0) }));
    }
    for (const e of things) {
      const s = e.get("Shape2D");
      expect(s).not.toBeNull();
      expect(s.blend).toBe("additive");
      expect(Math.max(s.color.r, s.color.g, s.color.b)).toBeGreaterThan(0.7); // above the bloom threshold, so it glows
      expect(e.has("Sprite")).toBe(false); // no hand-made glow sprites
    }
  });
});
