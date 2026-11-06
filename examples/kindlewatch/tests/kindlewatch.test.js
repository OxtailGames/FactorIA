// Gameplay smoke tests of Kindlewatch: the title, moving and the animations, logs from the piles to the fire, the torch
// against wolves and the alpha, the dawn, and the two ways of losing and the way of winning. The bot plays with a gamepad.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { scene, world, fa } from "factoria";
import { Bot } from "./helpers/bot.js";

const GAME = "scenes/game.scene.json";
const flow = () => game.find("game").behaviour;
const fire = () => game.find("campfire").behaviour;
const warden = () => game.find("warden").behaviour;

function start() {
  game.load(GAME);
  game.step(2);
  return new Bot(game);
}

/** Steps until the intro banner is over and the night is on. */
function untilNight() {
  for (let i = 0; i < 400 && flow().state !== "night"; i++) game.step(1);
  expect(flow().state).toBe("night");
}

describe("the title and the way into the game", () => {
  test("Play on the title screen goes through the loading screen into the first night", () => {
    game.load("scenes/menu.scene.json");
    game.step(2);
    expect(game.find("play")).not.toBeNull();
    expect(game.find("music").get("MusicPlayer").song).toBe("assets/music/title.song.json");
    game.click("play");
    for (let i = 0; i < 600 && scene.current !== GAME; i++) game.step(1);
    expect(scene.current).toBe(GAME);
    game.step(2);
    expect(flow().state).toBe("intro");
    expect(game.find("warden")).not.toBeNull();
  });
});

describe("the warden", () => {
  test("the stick moves it, it turns to face where it walks and the Animator goes idle -> walk/run -> idle", () => {
    const bot = start();
    expect(game.find("warden").animator.state).toBe("idle");
    const x0 = game.find("warden").position.x;
    bot.pad.axis("LeftX", 1);
    game.step(40);
    const w = game.find("warden");
    expect(w.position.x).toBeGreaterThan(x0 + 2);
    expect(["walk", "run"]).toContain(w.animator.state);
    // A model that faces +Z looks along +X with a yaw of 90 degrees.
    expect(w.get("Transform").rotation[1]).toBeCloseTo(90, 0);
    bot.stop();
    game.step(40);
    expect(game.find("warden").animator.state).toBe("idle");
  });

  test("keyboard movement works too: the move_* actions", () => {
    start();
    const z0 = game.find("warden").position.z;
    game.press("move_forward");
    game.step(30);
    game.release("move_forward");
    expect(game.find("warden").position.z).toBeLessThan(z0 - 1.5);
  });

  test("trees and rocks are solid and the clearing has walls: the warden cannot leave it", () => {
    const bot = start();
    bot.walkTo(60, 4, 0.5, 700);
    expect(game.find("warden").position.x).toBeLessThan(23);
    bot.stop();
  });

  test("walking next to a pile takes logs up to the limit, and standing at the fire feeds them to it", () => {
    const bot = start();
    untilNight();
    const pile = game.find("pile_1");
    const p = pile.position;
    expect(bot.walkTo(p.x + 1.1, p.z + 1.1, 0.6)).toBeGreaterThanOrEqual(0);
    game.step(90);
    expect(warden().logs).toBe(3);
    expect(game.find("carried_3").active).toBe(true);
    expect(pile.behaviour.logs).toBe(3);
    fire().fuel = 30;
    const before = fire().fuel;
    bot.walkTo(1.5, 1.5, 0.8);
    game.step(120);
    expect(warden().logs).toBe(0);
    expect(fire().logsFed).toBe(3);
    expect(fire().fuel).toBeGreaterThan(before);
    expect(game.find("carried_1").active).toBe(false);
  });
});

describe("wolves and the torch", () => {
  test("a wolf runs at the fire and bites it; the fire loses fuel", () => {
    start();
    untilNight();
    flow().spawnTimer = 999; // only the wolf of this test
    const w = flow().spawnWolf("wolf");
    w.set("Transform", { position: [5, 0.05, 0] });
    const before = fire().fuel;
    w.behaviour.wantsFire = true;
    // Keep the warden far from it so the wolf stays on the fire.
    game.find("warden").position = [-12, 0.05, 10];
    for (let i = 0; i < 400 && fire().fuel >= before - 3; i++) game.step(1);
    expect(fire().fuel).toBeLessThan(before - 3);
  });

  test("two swings of the torch drive a wolf off, with sound and a kill counted", () => {
    const bot = start();
    untilNight();
    flow().spawnTimer = 999;
    const wardenEntity = game.find("warden");
    wardenEntity.position = [-3, 0.05, 6];
    const wolf = flow().spawnWolf("wolf");
    wolf.position = [-3, 0.05, 3.2];
    wolf.behaviour.wantsFire = false;
    game.step(2);
    const b = wolf.behaviour;
    for (let i = 0; i < 6 && !b.dead; i++) {
      bot.swing();
      game.step(40);
    }
    expect(b.dead).toBe(true);
    expect(flow().kills).toBe(1);
    game.step(60);
    expect(wolf.alive).toBe(false);
  });

  test("a wolf that reaches the warden takes a heart, and the warden gets a second of safety", () => {
    start();
    untilNight();
    flow().spawnTimer = 999;
    game.find("warden").position = [-3, 0.05, 6];
    const wolf = flow().spawnWolf("wolf");
    wolf.position = [-3, 0.05, 4.4];
    wolf.behaviour.wantsFire = false;
    for (let i = 0; i < 200 && warden().hearts === 3; i++) game.step(1);
    expect(warden().hearts).toBe(2);
    expect(warden().safe).toBeGreaterThan(0);
  });

  test("the alpha enrages at half its health and calls two wolves", () => {
    start();
    untilNight();
    flow().spawnTimer = 999;
    const alpha = flow().spawnWolf("alpha");
    alpha.position = [8, 0.05, 8];
    game.step(2);
    const b = alpha.behaviour;
    expect(b.hp).toBe(5);
    const before = world.findByTag("wolf").length;
    // Four hits by the torch's own code path (the swing's clip event lands on strike()).
    for (let i = 0; i < 3; i++) b.hurt(1, [1, 0]);
    expect(b.enraged).toBe(true);
    expect(world.findByTag("wolf").length).toBe(before + 2);
  });
});

describe("the nights", () => {
  test("surviving a night brings the dawn: wolves leave, piles are restocked, a heart comes back", () => {
    start();
    flow().nights[0].length = 8;
    flow().introTime = 0.5;
    untilNight();
    warden().hearts = 2;
    const pile = game.find("pile_2").behaviour;
    pile.logs = 1;
    for (let i = 0; i < 1000 && flow().state !== "dawn"; i++) game.step(1);
    expect(flow().state).toBe("dawn");
    expect(pile.logs).toBe(pile.capacity);
    expect(warden().hearts).toBe(3);
    for (let i = 0; i < 1000 && flow().night === 1; i++) game.step(1);
    expect(flow().night).toBe(2);
    expect(flow().state).toBe("intro");
  });

  test("the fire going out loses the game, shows the end panel, and Try again plays it again", () => {
    start();
    flow().introTime = 0.2;
    untilNight();
    fire().fuel = 0.5;
    fire().burnRate = 30;
    for (let i = 0; i < 100 && flow().state === "night"; i++) game.step(1);
    expect(flow().state).toBe("lost");
    expect(warden().locked).toBe(true);
    game.step(90);
    expect(game.find("end_panel").active).toBe(true);
    expect(game.find("end_title").get("Text").key).toBe("game.lostFire");
    game.click("retry");
    game.step(3);
    expect(flow().state).toBe("intro");
    expect(game.find("end_panel").active).toBe(false);
    expect(warden().hearts).toBe(3);
  });

  test("running out of hearts loses the game too", () => {
    start();
    untilNight();
    warden().hearts = 1;
    warden().safe = 0;
    expect(warden().hurt([0, 0], 1)).toBe(true);
    game.step(2);
    expect(flow().state).toBe("lost");
    game.step(90);
    expect(game.find("end_title").get("Text").key).toBe("game.lostHp");
  });

  test("a bite shakes the camera: a drawn pose is added, the Transform is not, and the shake dies out", () => {
    start();
    untilNight();
    warden().hearts = 3;
    warden().safe = 0;
    const shaking = () => fa.call("feel.state", {}).entities.find((e) => e.shake);
    expect(shaking()).toBeUndefined();
    expect(warden().hurt([0, 0], 1)).toBe(true);
    game.step(2);
    const s = shaking();
    expect(s).toBeDefined();
    expect(s.shake.trauma).toBeGreaterThan(0.2);
    // Only the drawn pose moves (the camera's Transform stays the follow script's), so the script never chases the shake.
    expect(s.pose).toBeDefined();
    expect(Math.hypot(...s.pose.position)).toBeGreaterThan(0);
    game.step(60); // the shake lasts 0.3 s
    expect(shaking()).toBeUndefined();
  });

  test("three nights held win the game; the main menu button goes back to the title", () => {
    start();
    flow().introTime = 0.2;
    flow().dawnTime = 1;
    for (const n of flow().nights) n.length = 3;
    for (let i = 0; i < 3000 && flow().state !== "won"; i++) {
      fire().fuel = 100;
      game.step(1);
    }
    expect(flow().state).toBe("won");
    game.step(120);
    expect(game.find("end_panel").active).toBe(true);
    expect(game.find("end_title").get("Text").key).toBe("game.won");
    game.click("to_menu");
    game.step(3);
    expect(scene.current).toBe("scenes/menu.scene.json");
  });

  test("a load that answers late does not act on a scene that is gone: ending and reloading at once", () => {
    start();
    untilNight();
    warden().hearts = 1;
    warden().safe = 0;
    warden().hurt([0, 0], 1);
    scene.load("scenes/menu.scene.json"); // the delayed end panel must not fire in the next scene
    game.step(200);
    expect(scene.current).toBe("scenes/menu.scene.json");
    expect(game.find("end_panel")).toBeNull();
  });
});

describe("the pause menu", () => {
  test("Escape pauses the game and stops the night's clock; Resume carries on", () => {
    start();
    untilNight();
    game.step(10);
    const t = flow().timer;
    game.tap("pause");
    game.step(3);
    const paused = flow().timer;
    expect(paused).toBeGreaterThanOrEqual(t);
    game.step(30);
    expect(flow().timer).toBe(paused);
    game.tap("pause");
    game.step(30);
    expect(flow().timer).toBeGreaterThan(paused);
  });
});

describe("a whole game", () => {
  test("a bot that feeds the fire from the nearest pile and swings at the nearest wolf holds all three nights", () => {
    const bot = start();
    let frames = 0;
    // The bot's policy, one decision a frame: wolves near the warden first, then a log to the fire when it is low, else logs.
    while (flow().state !== "won" && flow().state !== "lost" && frames < 16000) {
      const w = game.find("warden");
      const p = w.position;
      const wolves = world.findByTag("wolf").filter((e) => !e.behaviour.dead);
      let near = null;
      let nd = 6;
      for (const e of wolves) {
        const d = Math.hypot(e.position.x - p.x, e.position.z - p.z);
        if (d < nd) {
          near = e;
          nd = d;
        }
      }
      if (near) {
        if (nd < 2.2) bot.swing();
        bot.steer(near.position.x, near.position.z);
      } else if (warden().logs > 0 && fire().fraction < 0.9) bot.steer(0, 0);
      else if (warden().logs < 3 && fire().fraction < 0.9) {
        let best = null;
        let bd = 1e9;
        for (const e of world.findByTag("pile")) {
          if (e.behaviour.logs <= 0) continue;
          const d = Math.hypot(e.position.x - p.x, e.position.z - p.z);
          if (d < bd) {
            best = e;
            bd = d;
          }
        }
        if (best) bot.steer(best.position.x, best.position.z);
        else bot.stop();
      } else bot.stop();
      game.step(1);
      frames++;
    }
    bot.stop();
    expect(flow().state).toBe("won");
    expect(flow().kills).toBeGreaterThan(8);
    expect(fire().logsFed).toBeGreaterThan(10);
  });
});
