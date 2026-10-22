// The courier's movement: speed, walking, jump height, steps, slopes and the jump forgiveness (coyote time, buffer).
import { test, describe, expect, game, beforeEach } from "factoria:test";

function courier() {
  return game.find("courier");
}

/** Puts the courier at (x, y, z) standing, facing -Z, and lets it settle. */
function place(x, y, z) {
  courier().position = [x, y, z];
  game.step(6);
}

function setup() {
  game.load("scenes/test_yard.scene.json");
  game.step(5);
}

describe("walking", () => {
  beforeEach(setup);
  test("holding forward runs away from the camera at the run speed", () => {
    const z0 = courier().position.z;
    game.press("move_forward");
    game.step(60);
    const b = courier().behaviour;
    expect(b.speed).toBeCloseTo(5, 1);
    expect(z0 - courier().position.z).toBeGreaterThan(4);
    expect(courier().position.x).toBeCloseTo(0, 1);
    expect(b.grounded).toBe(true);
  });

  test("the walk key (Shift) limits the speed", () => {
    game.press("walk");
    game.press("move_forward");
    game.step(40);
    expect(courier().behaviour.speed).toBeCloseTo(2, 1);
  });

  test("a half-tilted stick walks at an in-between speed", () => {
    game.gamepad(0).axis("LeftY", 0.55);
    game.step(40);
    const s = courier().behaviour.speed;
    expect(s).toBeGreaterThan(2);
    expect(s).toBeLessThan(4);
  });

  test("the robot turns smoothly towards where it goes", () => {
    game.press("move_right");
    game.step(2);
    const yaw1 = courier().behaviour.yaw;
    expect(Math.abs(yaw1)).toBeGreaterThan(0);
    expect(Math.abs(yaw1)).toBeLessThan(90);
    game.step(20);
    expect(Math.abs(courier().behaviour.yaw)).toBeCloseTo(90, 0);
  });

  test("stops when the input is released", () => {
    game.press("move_forward");
    game.step(30);
    game.release("move_forward");
    game.step(30);
    expect(courier().behaviour.speed).toBeCloseTo(0, 1);
  });

  test("movement is relative to the camera's yaw", () => {
    game.find("camera").behaviour.yaw = 90; // camera on the courier's +X side looking towards -X
    game.press("move_forward");
    game.step(30);
    expect(courier().position.x).toBeLessThan(-1);
    expect(Math.abs(courier().position.z - 16)).toBeLessThan(0.5);
  });
});

describe("jumping", () => {
  beforeEach(setup);
  test("a jump rises about 1.2 m", () => {
    const y0 = courier().position.y;
    game.tap("jump");
    let top = y0;
    for (let i = 0; i < 60; i++) {
      game.step(1);
      top = Math.max(top, courier().position.y);
    }
    expect(top - y0).toBeGreaterThan(1.15);
    expect(top - y0).toBeLessThan(1.25);
    expect(courier().behaviour.grounded).toBe(true);
  });

  test("the jump height is a field", () => {
    courier().behaviour.jumpHeight = 0.6;
    const y0 = courier().position.y;
    game.tap("jump");
    let top = y0;
    for (let i = 0; i < 60; i++) {
      game.step(1);
      top = Math.max(top, courier().position.y);
    }
    expect(top - y0).toBeCloseTo(0.6, 1);
  });

  test("air control steers a jump", () => {
    game.tap("jump");
    game.press("move_right");
    game.step(20);
    expect(courier().position.x).toBeGreaterThan(0.8);
  });

  test("a jump on the spot lands where it started", () => {
    game.tap("jump");
    game.step(60);
    expect(Math.abs(courier().position.x)).toBeLessThan(0.05);
    expect(Math.abs(courier().position.z - 16)).toBeLessThan(0.05);
  });

  test("no double jump", () => {
    game.tap("jump");
    game.step(15);
    const vy = courier().behaviour.vy;
    game.tap("jump");
    game.step(1);
    expect(courier().behaviour.vy).toBeLessThan(vy);
  });
});

describe("terrain", () => {
  beforeEach(setup);
  test("walks up the 0.2 m steps", () => {
    place(14, 0.6, 13.5);
    game.press("move_forward");
    game.step(36);
    // the top of the stairs is 0.6 m high: capsule centre = 0.6 + half height
    expect(courier().position.y).toBeGreaterThan(1.1);
    expect(courier().position.z).toBeLessThan(9);
  });

  test("walks up the gentle ramp", () => {
    place(8, 0.6, 13);
    game.press("move_forward");
    game.step(120);
    expect(courier().position.y).toBeGreaterThan(2.7);
  });

  test("refuses the too steep slope", () => {
    place(-14, 0.6, 13);
    game.press("move_forward");
    game.step(120);
    // the slope is 60 degrees and 3.5 m high: the courier must still be at the bottom
    expect(courier().position.y).toBeLessThan(1.2);
    expect(courier().position.z).toBeGreaterThan(9);
  });

  test("a wall stops the courier and it slides along it", () => {
    place(5.5, 0.6, 2);
    game.press("move_forward");
    game.step(60);
    expect(courier().position.z).toBeGreaterThan(-2.5);
  });

  test("the low hurdle blocks walking but not a jump", () => {
    place(0, 0.6, -2);
    game.press("move_forward");
    game.step(40);
    expect(courier().position.z).toBeGreaterThan(-5.1);
    game.release("move_forward");
    place(0, 0.6, -2);
    game.press("move_forward");
    game.step(10);
    game.tap("jump");
    game.step(60);
    expect(courier().position.z).toBeLessThan(-7);
  });

  test("falling out of the world puts the courier back at the start", () => {
    courier().position = [40, -20, 16];
    game.step(4);
    expect(courier().position.y).toBeGreaterThan(-1);
    expect(Math.abs(courier().position.x)).toBeLessThan(1);
  });
});

describe("jump forgiveness", () => {
  beforeEach(setup);
  /** Walks off the edge of the platform at the top of the ramp; returns frames after leaving the ground. */
  function walkOffPlatform() {
    place(8, 3.0, 1.5);
    expect(courier().behaviour.grounded).toBe(true);
    game.press("move_left");
    let guard = 0;
    while (courier().behaviour.grounded && guard++ < 200) game.step(1);
    expect(courier().behaviour.grounded).toBe(false);
  }

  test("coyote time: a jump just after leaving a ledge still works", () => {
    walkOffPlatform();
    game.step(4); // 0.067 s, inside the 0.12 s window
    game.tap("jump");
    game.step(1);
    expect(courier().behaviour.vy).toBeGreaterThan(0);
  });

  test("coyote time ends: a jump long after leaving a ledge does nothing", () => {
    walkOffPlatform();
    game.step(14); // 0.23 s
    game.tap("jump");
    game.step(1);
    expect(courier().behaviour.vy).toBeLessThan(0);
  });

  test("jump buffer: a press just before landing jumps on landing", () => {
    game.tap("jump");
    // wait until it is falling and close to the ground
    let guard = 0;
    while (!(courier().behaviour.vy < 0 && courier().position.y < 0.85) && guard++ < 90) game.step(1);
    game.tap("jump"); // about 0.05 s before touching down
    game.step(14);
    const b = courier().behaviour;
    expect(b.grounded).toBe(false);
    expect(courier().position.y).toBeGreaterThan(0.8);
  });

  test("a press far too early before landing is forgotten", () => {
    game.tap("jump");
    game.step(10);
    game.tap("jump"); // high in the air, ~0.5 s before landing: the buffer is only 0.12 s
    game.step(60);
    expect(courier().behaviour.grounded).toBe(true);
    expect(courier().position.y).toBeLessThan(0.6);
  });
});
