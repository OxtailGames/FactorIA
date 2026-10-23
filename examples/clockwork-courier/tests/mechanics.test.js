// The level objects and physics props of P2, one at a time in scenes/test_arena.scene.json (a row of stations: crates, a
// lever gate, a seesaw, a rope bridge, a moving platform, a guard dog, a key, a checkpoint and the delivery door).
// The levels themselves are played end to end by tests/levels.test.js.
import { test, describe, expect, game } from "factoria:test";
import { scene, session, audio, storage } from "factoria";
import { Autoplay } from "./helpers/autoplay.js";
import { ROUTES } from "./helpers/routes.js";
import * as settings from "../scripts/settings.js";
import * as levels from "../scripts/levels.js";
import * as stars from "../scripts/stars.js";
import * as progress from "../scripts/progress.js";
import { NavGrid } from "../scripts/nav.js";

const ARENA = "scenes/test_arena.scene.json";

function arena() {
  storage.remove("progress");
  game.load(ARENA);
  game.step(10);
  return game.find("courier");
}

function record(names) {
  const log = [];
  for (const n of names) game.world.on(n, (d) => log.push({ name: n, data: d }));
  return log;
}

describe("wind-up keys and checkpoints", () => {
  test("a key winds the spring, sparks fly and the key is gone", () => {
    const c = arena();
    const spring = game.find("spring").behaviour;
    spring.drain(30);
    const before = spring.left;
    const log = record(["spring_wound"]);
    c.position = [100, 0.62, 0];
    game.step(6);
    expect(spring.left).toBeGreaterThan(before + 10);
    expect(log.length).toBe(1);
    expect(game.find("key_1")).toBeNull();
    expect(game.audioLog()).toContainPlayed("impactBell_heavy_000.ogg");
  });

  test("the key never winds past the spring's maximum", () => {
    const c = arena();
    const spring = game.find("spring").behaviour;
    c.position = [100, 0.62, 0];
    game.step(6);
    expect(spring.left).toBeLessThanOrEqual(spring.max + 0.001);
  });

  test("a checkpoint is reached once and becomes the respawn point", () => {
    const c = arena();
    const log = record(["checkpoint_reached"]);
    c.position = [104, 0.62, 0];
    game.step(6);
    expect(log.length).toBe(1);
    expect(log[0].data.checkpoint).toBe("checkpoint_1");
    c.position = [104.1, 0.62, 0.1];
    game.step(6);
    expect(log.length).toBe(1);
    c.position = [30, -40, 0];
    game.step(6);
    expect(Math.abs(c.position.x - 104)).toBeLessThan(1.5);
    expect(c.position.y).toBeGreaterThan(-1);
  });
});

describe("guard dogs", () => {
  // dog_1 patrols x 80..88 at z = -14 with a wall at z = -6 (see the arena).
  function dogScene() {
    const c = arena();
    const log = [];
    for (const n of ["dog_alerted", "dog_gave_up", "courier_caught"]) game.world.on(n, (d) => log.push({ frame: game.time.frame, name: n, data: d }));
    return { c, dog: game.find("dog_1"), log };
  }

  test("it patrols until it sees nothing", () => {
    const { c, dog, log } = dogScene();
    c.position = [0, 0.62, 10];
    game.step(240);
    expect(dog.behaviour.state).toBe("patrol");
    expect(log.length).toBe(0);
  });

  test("it sees the courier in its view cone, barks, chases and catches it", () => {
    const { c, dog, log } = dogScene();
    c.position = [84, 0.62, -17];
    game.step(20);
    expect(dog.behaviour.state).toBe("alert");
    expect(dog.behaviour.sees).toBe(true);
    expect(log.map((e) => e.name)).toEqual(["dog_alerted"]);
    expect(game.audioLog()).toContainPlayed("dog_bark.wav");
    game.step(30);
    expect(dog.behaviour.state).toBe("chase");
    game.step(120);
    const names = log.map((e) => e.name);
    expect(names).toContain("courier_caught");
    expect(log.find((e) => e.name === "courier_caught").data.by).toBe("dog");
  });

  test("a catch sends the courier to the last checkpoint, costs spring and is not the end of the level", () => {
    const { c, log } = dogScene();
    const cp = record(["level_failed"]);
    c.position = [104, 0.62, 0];
    game.step(6);
    const spring = game.find("spring").behaviour;
    const before = spring.left;
    c.behaviour.caught("dog");
    game.step(120);
    expect(c.behaviour.isCaught).toBe(false);
    expect(Math.abs(c.position.x - 104)).toBeLessThan(1.5);
    expect(spring.left).toBeLessThan(before - 4);
    expect(c.behaviour.grace).toBeGreaterThan(0);
    expect(cp.length).toBe(0);
    expect(log.some((e) => e.name === "courier_caught")).toBe(true);
  });

  test("it ignores a courier that is not in its view cone or behind the wall", () => {
    const { c, dog, log } = dogScene();
    c.position = [80, 0.62, 2]; // behind dog_wall: the sight ray is blocked
    game.step(240);
    expect(log.length).toBe(0);
    expect(dog.behaviour.sees).toBe(false);
  });

  test("it gives up when it loses the trail, walks home and patrols again", () => {
    const { c, dog, log } = dogScene();
    c.position = [84, 0.62, -17];
    game.step(60);
    expect(["alert", "chase"]).toContain(dog.behaviour.state);
    c.behaviour.grace = 30; // the dog cannot see a courier in its grace period: as if it hid
    game.step(60);
    expect(dog.behaviour.state).toBe("search");
    game.step(300);
    expect(log.some((e) => e.name === "dog_gave_up")).toBe(true);
    game.step(240);
    expect(dog.behaviour.state).toBe("patrol");
    expect(log.some((e) => e.name === "courier_caught")).toBe(false);
  });

  test("sneaking: a walking courier is not noticed from as far away", () => {
    const { c, dog, log } = dogScene();
    // 8 m in front of the dog at its patrol line: inside the 10 m run sight, outside the 6 m sneak sight.
    const bot = new Autoplay(game, { maxFrames: 600 });
    c.position = [84, 0.62, -22.2];
    game.step(2);
    bot.goTo({ x: 84, z: -22.0, walk: true, radius: 0.3 });
    bot.stop();
    expect(game.find("courier").behaviour.speed).toBeLessThan(2.3);
    game.step(120);
    expect(log.some((e) => e.name === "dog_alerted")).toBe(false);
    expect(dog.behaviour.state).toBe("patrol");
  });
});

describe("path finding (no navmesh in the engine: scripts/nav.js)", () => {
  test("a path goes round the wall, never through it", () => {
    arena();
    const nav = new NavGrid({ ceilY: 3, radius: 0.32, clearance: 0.5 });
    const r = nav.findPath([80, -14], [80, 2]);
    expect(r).not.toBeNull();
    expect(r.complete).toBe(true);
    const len = r.path.reduce((s, p, i) => (i === 0 ? 0 : s + Math.hypot(p[0] - r.path[i - 1][0], p[1] - r.path[i - 1][1])), 0);
    expect(len).toBeGreaterThan(16.5); // the straight line is 16 m: the wall forces a detour
    expect(r.path.some((p) => Math.abs(p[0] - 80) > 2)).toBe(true);
  });

  test("a clear straight line is one segment", () => {
    arena();
    const nav = new NavGrid({ ceilY: 3, radius: 0.32, clearance: 0.5 });
    const r = nav.findPath([-2, 10], [2, 10]);
    expect(r.complete).toBe(true);
    expect(r.path.length).toBeLessThanOrEqual(3);
  });
});

describe("tap to move", () => {
  test("off by default", () => {
    expect(settings.load().tapToMove).toBe(false);
  });

  test("a tap on the ground walks the courier there when the setting is on", () => {
    const c = arena();
    settings.save({ ...settings.load(), tapToMove: true });
    const t = game.find("tap_move").behaviour;
    expect(t.tapAt([640, 420])).toBe(true);
    const target = t.lastTarget;
    expect(t.lastComplete).toBe(true);
    game.step(400);
    expect(Math.hypot(c.position.x - target[0], c.position.z - target[2])).toBeLessThan(0.7);
  });

  test("the stick cancels a walk in progress", () => {
    const c = arena();
    settings.save({ ...settings.load(), tapToMove: true });
    const t = game.find("tap_move").behaviour;
    t.tapAt([640, 420]);
    game.step(10);
    const bot = new Autoplay(game);
    bot.steer(30, 10);
    game.step(30);
    bot.stop();
    expect(c.behaviour.autoPath).toBeFalsy();
  });
});

describe("hinge gate and lever", () => {
  test("the courier cannot push the shut gate open", () => {
    const c = arena();
    const g = game.find("gate_1").behaviour;
    const bot = new Autoplay(game, { maxFrames: 400 });
    c.position = [0, 0.62, -1];
    bot.goTo({ x: 0, z: -9, radius: 0.3 });
    bot.stop();
    expect(g.angle).toBeLessThan(3);
    expect(c.position.z).toBeGreaterThan(-6);
  });

  test("pulling the lever swings the gate open, pulling again shuts it", () => {
    const c = arena();
    const g = game.find("gate_1").behaviour;
    c.position = [3, 0.62, -3];
    game.step(10);
    game.tap("action");
    game.step(90);
    expect(g.isOpen).toBe(true);
    expect(g.angle).toBeGreaterThan(90);
    expect(game.find("lever_1").behaviour.pulled).toBe(true);
    game.step(10);
    game.tap("action");
    game.step(90);
    expect(g.isOpen).toBe(false);
    expect(g.angle).toBeLessThan(10);
  });

  test("the lever does nothing from far away", () => {
    const c = arena();
    c.position = [-8, 0.62, 5];
    game.step(10);
    game.tap("action");
    game.step(30);
    expect(game.find("gate_1").behaviour.isOpen).toBe(false);
  });

  test("with the gate open the courier walks through", () => {
    const c = arena();
    c.position = [3, 0.62, -3];
    game.step(10);
    game.tap("action");
    game.step(90);
    const bot = new Autoplay(game, { maxFrames: 400 });
    // the doorway is the 2 m between the walls (x -1.2..1.1), the lever is beside it
    expect(bot.goTo({ x: 0, z: -2, radius: 0.4 })).toBe(true);
    expect(bot.goTo({ x: 0, z: -10, radius: 0.5 })).toBe(true);
    bot.stop();
    expect(c.position.z).toBeLessThan(-8);
  });
});

describe("seesaw", () => {
  test("it rests with the +x end down", () => {
    arena();
    game.step(60);
    expect(game.find("seesaw_1").behaviour.downSide).toBe(1);
  });

  test("the end the courier stands on goes down", () => {
    const c = arena();
    const s = game.find("seesaw_1").behaviour;
    game.step(60);
    c.position = [-16.5, 2, -14];
    game.step(120);
    expect(s.downSide).toBe(-1);
    expect(Math.abs(s.angle)).toBeGreaterThan(10);
  });

  test("it tips back under the courier when it crosses the pivot", () => {
    const c = arena();
    const s = game.find("seesaw_1").behaviour;
    game.step(60);
    c.position = [-16.5, 2, -14];
    game.step(120);
    expect(s.downSide).toBe(-1);
    const bot = new Autoplay(game, { maxFrames: 300 });
    bot.goTo({ x: -11.8, z: -14, radius: 0.5 });
    game.step(120);
    bot.stop();
    expect(s.downSide).toBe(1);
  });

  test("the courier pushing at the plank does not slide it off its pivot", () => {
    const c = arena();
    const s = game.find("seesaw_1");
    const p0 = s.position;
    c.position = [-18, 0.62, -14];
    const bot = new Autoplay(game, { maxFrames: 300 });
    bot.goTo({ x: -10, z: -14, radius: 0.5 });
    bot.stop();
    expect(Math.hypot(s.position.x - p0.x, s.position.z - p0.z)).toBeLessThan(0.15);
  });
});

describe("rope bridge", () => {
  test("it builds its planks when the scene starts, chained from end to end", () => {
    arena();
    for (let i = 0; i < 9; i++) expect(game.find(`bridge_1_plank_${i}`)).not.toBeNull();
    expect(game.find("bridge_1_plank_9")).toBeNull();
    const a = game.find("bridge_1_plank_0").position;
    const b = game.find("bridge_1_plank_8").position;
    expect(a.z).toBeGreaterThan(b.z);
    expect(Math.abs(a.y - 3)).toBeLessThan(1);
  });

  test("the courier crosses it and it holds", () => {
    const c = arena();
    const bot = new Autoplay(game, { maxFrames: 900 });
    c.position = [20, 3.2, -26];
    game.step(30);
    expect(bot.goTo({ x: 20, z: -34, radius: 0.5 })).toBe(true);
    expect(bot.goTo({ x: 20, z: -44, radius: 0.5 })).toBe(true);
    bot.stop();
    expect(c.position.y).toBeGreaterThan(1.5);
  });

  test("the planks hang in a calm curve below their ends", () => {
    arena();
    game.step(400);
    const mid = game.find("bridge_1_plank_4");
    // A chain of hinges rings for a long while with little damping (it swung +-1 m before the damping was raised).
    for (let i = 0; i < 6; i++) {
      game.step(60);
      expect(mid.position.y).toBeLessThan(2.9);
      expect(mid.position.y).toBeGreaterThan(2.3);
    }
  });
});

describe("moving platform and crates", () => {
  test("the platform carries the courier along", () => {
    const c = arena();
    const m = game.find("mover_1");
    c.position = [50, 1, -60];
    game.step(30);
    const z0 = c.position.z;
    const mz0 = m.position.z;
    game.step(90);
    const moved = mz0 - m.position.z;
    expect(moved).toBeGreaterThan(2);
    expect(Math.abs(z0 - c.position.z - moved)).toBeLessThan(0.6);
    expect(c.position.y).toBeGreaterThan(0.3);
  });

  test("the platform goes to its end, waits and comes back (it is a function of the fixed steps)", () => {
    arena();
    const m = game.find("mover_1");
    let minZ = 0;
    let back = false;
    for (let i = 0; i < 12; i++) {
      game.step(30);
      minZ = Math.min(minZ, m.position.z);
      if (m.position.z > minZ + 1) back = true;
    }
    expect(minZ).toBeCloseTo(-68, 1);
    expect(back).toBe(true);
  });

  test("a crate is pushed by walking into it, and a thud is heard when it lands", () => {
    const c = arena();
    const k = game.find("crate_2");
    const z0 = k.position.z;
    const bot = new Autoplay(game, { maxFrames: 300 });
    c.position = [0, 0.62, 4];
    game.step(5);
    bot.goTo({ x: 0, z: -1, radius: 0.4 });
    bot.stop();
    expect(z0 - k.position.z).toBeGreaterThan(0.5);
    expect(Math.abs(k.position.x)).toBeLessThan(0.5);
  });

  test("a crate does not tip over", () => {
    arena();
    game.step(60);
    const rot = game.find("crate_0").get("Transform").rotation;
    expect(Math.abs(rot.x)).toBeLessThan(1);
    expect(Math.abs(rot.z)).toBeLessThan(1);
  });
});

describe("particles", () => {
  test("the key's sparks are a one-shot 3D burst that removes itself", () => {
    const c = arena();
    c.position = [100, 0.62, 0];
    game.step(2);
    const sparks = game.world.findByName ? game.world.findByName("fx_sparks") : null;
    if (sparks) expect(sparks.get("ParticleEmitter").is3D).toBe(true);
    game.step(120);
    const gone = game.world.findByName ? game.world.findByName("fx_sparks") : null;
    expect(gone ?? null).toBeNull();
  });

  test("chimney steam and market fireflies are ambient emitters of their level", () => {
    game.load("scenes/rooftops_1.scene.json");
    game.step(5);
    expect(game.find("chimney_1_steam").get("ParticleEmitter").emitting).toBe(true);
    game.load("scenes/market_1.scene.json");
    game.step(5);
    expect(game.find("fireflies_1")?.get("ParticleEmitter").emitting ?? true).toBe(true);
  });

  test("reduced effects switch the ambient ones off", async () => {
    const fx = await import("../scripts/fx.js");
    settings.save({ ...settings.load(), reducedEffects: true });
    game.load(ARENA);
    game.step(2);
    expect(fx.ambient("steam", [0, 5, 0])).toBeNull();
    expect(fx.burst("dust", [0, 0.1, 0])).not.toBeNull();
  });
});

describe("stars", () => {
  test("one star for delivering, two for one bonus goal, three for two", () => {
    const L = levels.byId("rooftops_1");
    const base = { time: 999, springLeft: 0, springMax: L.spring, optionalDelivered: 0, optionalTotal: 1 };
    expect(stars.evaluate(L, base).stars).toBe(1);
    expect(stars.evaluate(L, { ...base, time: L.parTime - 1 }).stars).toBe(2);
    expect(stars.evaluate(L, { ...base, time: L.parTime - 1, optionalDelivered: 1 }).stars).toBe(3);
  });
});

describe("music", () => {
  const music = () => game.find("music").behaviour;

  test("the title plays its own theme; each district has its track", () => {
    game.load("scenes/main.scene.json");
    game.step(5);
    expect(music().track).toBe(levels.MUSIC.title);
    game.load("scenes/rooftops_2.scene.json");
    game.step(5);
    expect(music().track).toBe(levels.MUSIC.rooftops);
    game.load("scenes/market_2.scene.json");
    game.step(5);
    expect(music().track).toBe(levels.MUSIC.market);
    expect(levels.MUSIC.rooftops).not.toBe(levels.MUSIC.market);
  });

  test("it is streamed on the music bus and keeps playing across a reload of the same district", () => {
    game.load("scenes/rooftops_1.scene.json");
    game.step(5);
    expect(game.audioLog()).toContainPlayed(levels.MUSIC.rooftops.split("/").pop(), { bus: "music" });
    game.clearAudioLog();
    game.load("scenes/rooftops_2.scene.json");
    game.step(5);
    const again = game.audioLog().filter((e) => e.music);
    expect(again.length).toBe(0);
  });

  test("the pause menu ducks the music and resuming brings it back", () => {
    game.load("scenes/rooftops_1.scene.json");
    game.step(5);
    expect(music().duck).toBe(1);
    game.tap("pause");
    game.step(40);
    expect(music().duckTarget).toBeLessThan(0.5);
    expect(music().duck).toBeLessThan(0.5);
    expect(audio.getVolume("music")).toBeLessThan(0.5);
    game.tap("pause");
    game.step(60);
    expect(music().duck).toBe(1);
  });

  test("a delivery and the end of the level play jingles and duck the music", () => {
    game.load("scenes/rooftops_1.scene.json");
    game.step(5);
    game.world.emit("parcel_delivered", { delivered: 1, optional: 0 });
    game.step(10);
    expect(game.audioLog()).toContainPlayed("jingles_HIT03.ogg", { bus: "sfx" });
    expect(music().duckTarget).toBeLessThan(1);
    game.step(150);
    expect(music().duckTarget).toBe(1);
    game.world.emit("level_completed", { level: "rooftops_1", stars: 3 });
    game.step(10);
    expect(game.audioLog()).toContainPlayed("jingles_SAX05.ogg");
  });

  test("the music volume of the options is the user value times the duck", () => {
    game.load("scenes/rooftops_1.scene.json");
    game.step(5);
    settings.save({ ...settings.load(), volume: { ...settings.load().volume, music: 0.5 } });
    game.step(5);
    expect(audio.getVolume("music")).toBeCloseTo(0.5, 1);
    game.world.emit("level_completed", { level: "rooftops_1", stars: 1 });
    game.step(40);
    expect(audio.getVolume("music")).toBeCloseTo(0.5 * music().duckGain, 1);
  });
});

describe("loading screen", () => {
  test("Play shows a bar that follows the level's files being read ahead, then loads it", () => {
    game.load("scenes/main.scene.json");
    game.step(5);
    progress.setName("Ana"); // P3: Play opens the level select, a card starts the level
    game.click("play");
    game.step(5);
    game.click("card_rooftops_1");
    expect(scene.current).toBe("scenes/loading.scene.json");
    expect(session.nextScene).toBe(levels.first().scene);
    const seen = [];
    let guard = 0;
    while (scene.current === "scenes/loading.scene.json" && guard++ < 20) {
      game.step(1);
      const l = game.find("loading");
      if (l) seen.push(l.behaviour.progress);
    }
    // The level's files are read a few every frame: the scene runs (and draws) on several frames and the bar only grows.
    expect(seen.length).toBeGreaterThan(2);
    expect(seen).toEqual([...seen].sort((a, b) => a - b));
    expect(seen.some((p) => p > 0 && p < 1)).toBe(true);
    expect(seen[seen.length - 1]).toBeGreaterThan(0.5);  // the frame that finishes the job also loads the level
    expect(scene.current).toBe(levels.first().scene);
  });

  test("the level is read ahead: scene.load reads no file of its own", () => {
    const job = scene.preload(levels.first().scene);
    let guard = 0;
    while (!job.done && guard++ < 40) game.step(1);
    expect(job.done).toBe(true);
    expect(job.files).toBeGreaterThan(5);
    const before = game.fileReads();
    scene.load(levels.first().scene);
    game.step(1);
    expect(scene.current).toBe(levels.first().scene);
    expect(game.fileReads()).toBe(before);
  });

  test("it shows the name of the level it loads", () => {
    game.load("scenes/main.scene.json");
    game.step(5);
    session.nextScene = levels.byId("market_2").scene;
    scene.load("scenes/loading.scene.json");
    game.step(2); // a scene.load from a test takes effect in the next frame
    expect(scene.current).toBe("scenes/loading.scene.json");
    expect(game.find("loading_level").get("Text").text).toBe("Stall Street");
  });

  test("Next level on the results screen goes through it too", () => {
    storage.remove("progress");
    game.load(levels.byId("rooftops_1").scene);
    game.step(10);
    new Autoplay(game, { maxFrames: 1500 }).run(ROUTES.rooftops_1.main);
    game.step(120);
    expect(game.find("results_next").active).toBe(true);
    game.click("results_next");
    expect(scene.current).toBe("scenes/loading.scene.json");
    expect(session.nextScene).toBe(levels.byId("rooftops_2").scene);
    game.step(10);
    expect(scene.current).toBe(levels.byId("rooftops_2").scene);
  });
});
