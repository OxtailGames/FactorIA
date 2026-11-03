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

describe("shockwave (a sheet made with assets.animate_svg, played by clip name)", () => {
  test("a kill spawns a shockwave that plays the clip 'pop' frame by frame and removes itself when it ends", () => {
    loadGame();
    mgr().timer = 999;
    const target = world.spawnPrefab("prefabs/chaser.prefab.json", { position: vec3(300, 0, 0) });
    game.step(1);
    target.behaviour.hurt(99);
    game.step(1);
    const fx = world.find("Shockwave");
    expect(fx).not.toBeNull();
    const clips = fx.spriteAnimator.clips;
    expect(clips).toEqual(["pop", "boom"]);
    expect(fx.get("SpriteAnimator").clip).toBe("pop");
    const seen = new Set();
    for (let i = 0; i < 12; i++) {
      game.step(1);
      if (fx.alive) seen.add(fx.get("SpriteAnimator").frame);
    }
    expect(seen.size).toBeGreaterThan(3); // it animates: the frame changes (pop is frames 0..7)
    game.step(30); // pop is 8 frames at 24 fps = a third of a second
    expect(fx.alive).toBe(false); // clipEnded destroyed it
  });

  test("play() switches clip by name; a wrong name is an error that lists the clips", () => {
    loadGame();
    mgr().timer = 999;
    const fx = world.spawn({
      name: "Probe",
      components: { Transform: { position: [0, 0, 0] }, Sprite: { texture: "assets/art/shockwave.png" }, SpriteAnimator: {} },
    });
    game.step(1);
    fx.spriteAnimator.play("boom");
    game.step(1);
    expect(fx.get("SpriteAnimator").clip).toBe("boom");
    let message = "";
    try {
      fx.spriteAnimator.play("bom");
    } catch (e) {
      message = String(e.message || e);
    }
    expect(message).toContain("pop, boom");
    expect(message).toContain("boom"); // the did-you-mean
    fx.destroy();
  });
});

// The adaptive score (docs/MUSIC.md "Playing a song in a game"): the "score" entity's MusicPlayer plays assets/music/score.song.json and
// scripts/game.js drives it. On the null device the mixer moves exactly the time the game clock gives it, so these steps are exact.
describe("adaptive score", () => {
  const music = () => game.find("score").music;
  const crowd = (n) => {
    for (let i = 0; i < n; i++) world.spawnPrefab("prefabs/chaser.prefab.json", { position: vec3(520 - 30 * i, 250, 0) });
  };

  // Keeps the wave going with nothing on the field: one enemy still to spawn that never spawns.
  const hold = (m) => {
    clearEnemies();
    m.pending = ["chaser"];
    m.spawnTimer = 9999;
  };

  test("the song plays from the first frame, in its calm section, with only the base layer", () => {
    loadGame();
    mgr().timer = 999;
    game.step(30);
    const s = music().status;
    expect(s.error).toBe("");
    expect(s.playing).toBe(true);
    expect(s.section).toBe("calm");
    expect(s.sections).toEqual(["intro", "calm", "battle", "outro"]);
    expect(s.stemGains.length).toBe(3);
    expect(s.stemGains[0]).toBeGreaterThan(0.9); // pad and bass
    expect(s.stemGains[1]).toBeLessThan(0.1);    // drums
    expect(s.stemGains[2]).toBeLessThan(0.1);    // arpeggio
  });

  test("the intensity follows the danger: more on the field, more of the song; it drops when the wave is cleared", () => {
    loadGame();
    const m = mgr();
    player().behaviour.invuln = 9999; // the crowd must not kill the player while the music is measured
    m.timer = 0;
    game.step(2);
    expect(m.state).toBe("fighting");
    hold(m);
    crowd(2);
    game.step(40); // the layers follow on the next beat (0.45 s)
    const few = music().status.intensity;
    expect(few).toBeGreaterThan(0.3);
    expect(few).toBeLessThan(0.65); // the drums are in, the arpeggio is not
    game.step(120);
    expect(music().status.stemGains[1]).toBeGreaterThan(0.9);
    expect(music().status.stemGains[2]).toBeLessThan(0.1);

    crowd(12);
    game.step(2);
    expect(music().intensity).toBeGreaterThan(0.65); // what the script asked for, at once (status.intensity is the one the layers follow, a beat later)
    game.step(38);
    expect(music().status.intensity).toBeGreaterThan(0.65);
    expect(music().status.intensity).toBeGreaterThan(few);
    game.step(120);
    expect(music().status.stemGains[2]).toBeGreaterThan(0.9); // the whole song

    m.pending = [];
    clearEnemies();
    m.timer = 9999; // no next wave while the music is measured
    game.step(40);
    expect(m.state).toBe("intermission");
    expect(music().status.intensity).toBeLessThan(0.1);
    game.step(150);
    expect(music().status.stemGains[1]).toBeLessThan(0.1);
    expect(music().status.stemGains[2]).toBeLessThan(0.1);
  });

  test("a wave changes the section to battle on the bar line and the clear brings calm back", () => {
    loadGame();
    const m = mgr();
    player().behaviour.invuln = 9999;
    game.step(30);
    expect(music().status.section).toBe("calm");
    m.timer = 0;
    game.step(2);
    hold(m);
    crowd(2);
    game.step(160); // a bar of 4/4 at 132 bpm is 1.8 s
    expect(music().status.section).toBe("battle");
    m.pending = [];
    clearEnemies();
    m.timer = 9999;
    game.step(160);
    expect(m.state).toBe("intermission");
    expect(music().status.section).toBe("calm");
  });

  test("a wave and a hit are stingers over the music", () => {
    loadGame();
    const m = mgr();
    const kinds = [];
    const off = music().on("stinger", (d) => kinds.push(d.kind));
    m.timer = 0;
    game.step(60); // the wave horn lands on the next beat (0.45 s)
    expect(kinds).toEqual(["clip"]);
    player().behaviour.hurt(1); // emits player_hit
    game.step(10);
    expect(kinds.length).toBe(2);
    off();
  });

  test("dying fades the score out", () => {
    loadGame();
    mgr().timer = 999;
    game.step(30);
    expect(music().status.playing).toBe(true);
    player().behaviour.hp = 0;
    game.step(2);
    expect(mgr().state).toBe("over");
    expect(music().status.playing).toBe(false);
  });
});
