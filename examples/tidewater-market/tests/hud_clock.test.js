// The clock in the game scene: the speed buttons and keys, Space, the population readout, the harbour at the start and the music
// of the season. (The clock and the simulation themselves are in clock.test.js and sim.test.js.)
import { test, expect, game } from "factoria:test";
import { DESIGN } from "../scripts/game/camera_math.js";
import { cellToWorld } from "../scripts/game/iso.js";
import { harbourCell } from "../scripts/game/harbour.js";

function open(props = {}) {
  game.load("scenes/game.scene.json", { testMap: true, ...props });
  game.step(2);
  return game.find("controller").behaviour;
}

test("the game starts at x1 and the speed buttons set 0, x1, x2 and x4", () => {
  const ctl = open();
  const clock = ctl.state.clock;
  expect(clock.speed).toBe(1);
  for (const [id, speed] of [["speed_0", 0], ["speed_2", 2], ["speed_3", 3], ["speed_1", 1]]) {
    game.click(id);
    game.step(1);
    expect(clock.speed).toBe(speed);
  }
});

test("x1, x2 and x4 run 1, 2 and 4 game seconds per real second in the scene, pause stops the clock", () => {
  const ctl = open();
  const clock = ctl.state.clock;
  const measure = (id, frames) => {
    game.click(id);
    game.step(1);
    const before = clock.ticks;
    game.step(frames);
    return (clock.ticks - before) * clock.step;
  };
  const fps = 60;
  const x1 = measure("speed_1", fps * 5);
  const x2 = measure("speed_2", fps * 5);
  const x4 = measure("speed_3", fps * 5);
  expect(x1).toBeGreaterThan(4.6);
  expect(x1).toBeLessThan(5.4);
  expect(x2 / x1).toBeGreaterThan(1.8);
  expect(x2 / x1).toBeLessThan(2.2);
  expect(x4 / x1).toBeGreaterThan(3.6);
  expect(x4 / x1).toBeLessThan(4.4);
  expect(measure("speed_0", 30)).toBe(0);
});

test("the keys 1-4 set the speed and Space pauses and resumes at the speed it had", () => {
  const ctl = open();
  const clock = ctl.state.clock;
  const tap = (action) => {
    game.press(action);
    game.step(1);
    game.release(action);
    game.step(1);
  };
  tap("speed_3");
  expect(clock.speed).toBe(3);
  tap("pause_toggle");
  expect(clock.speed).toBe(0);
  tap("pause_toggle");
  expect(clock.speed).toBe(3);
  tap("speed_pause");
  expect(clock.speed).toBe(0);
  tap("speed_1");
  expect(clock.speed).toBe(1);
});

test("the HUD shows the population against the housing", () => {
  const ctl = open();
  expect(game.find("pop_text").get("Text").text).toBe("0 / 0");
  expect(ctl.state.place("house", 3, 3, 0, "test")).toBeTruthy();
  game.step(2);
  expect(game.find("pop_text").get("Text").text).toBe("0 / 4");
});

test("the camera starts on the harbour with water in view", () => {
  const ctl = open({ seed: 20261026, testMap: false });
  const map = ctl.state.map;
  const [hc, hr] = harbourCell(map);
  expect(map.touchesWater(hc, hr)).toBe(true);
  const view = ctl.rig.view;
  const [hx, hy] = cellToWorld(hc, hr);
  expect(Math.abs(view.x - hx)).toBeLessThan(2);
  expect(Math.abs(view.y - hy)).toBeLessThan(2);
  const halfW = DESIGN.width / 2 / view.zoom;
  const halfH = DESIGN.height / 2 / view.zoom;
  let water = 0;
  for (let r = 0; r < map.height; r++) {
    for (let c = 0; c < map.width; c++) {
      if (map.terrainAt(c, r) !== "water") continue;
      const [x, y] = cellToWorld(c, r);
      if (Math.abs(x - view.x) < halfW && Math.abs(y - view.y) < halfH) water++;
    }
  }
  expect(water).toBeGreaterThan(20);
});

test("the music follows the season: spring at the start, the next loop on every new season", () => {
  const ctl = open({ testMap: false, seed: 3, music: true });
  expect(game.audioLog()).toContainPlayed("spring.wav");
  game.clearAudioLog();
  const clock = ctl.state.clock;
  clock.setSpeed(0);
  clock.setDay(9);
  for (let i = 0; i < clock.ticksPerDay + 2; i++) clock.tick(clock.step);
  expect(clock.date().season).toBe("summer");
  expect(game.audioLog()).toContainPlayed("summer.wav");
});

test("the test map plays no music unless the scene asks for it", () => {
  open();
  // the ambience beds of P6 play in every game (tests/soundscape.test.js); music is what the scene asks for
  expect(game.audioLog().filter((e) => e.bus === "music" || /music/.test(e.path || e.clip || ""))).toHaveLength(0);
  expect(game.audioLog().some((e) => /ambience\//.test(e.path || e.clip || ""))).toBe(true);
});
