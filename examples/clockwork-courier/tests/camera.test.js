// The follow camera: stays behind the courier, never ends up inside geometry, orbits (touch drag, mouse, right stick,
// keys) and zooms (pinch, wheel, shoulder buttons), all clamped.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { Autoplay, YARD_ROUTE } from "./helpers/autoplay.js";

const courier = () => game.find("courier");
const cam = () => game.find("camera");
const cb = () => cam().behaviour;

function setup() {
  game.load("scenes/test_yard.scene.json");
  game.step(30);
}

/** The axis-aligned solid boxes of the yard (position and scale of the unrotated cubes). */
function solids() {
  const ids = ["ground", "wall", "hurdle", "passage_wall_l", "passage_wall_r", "passage_roof", "door_post_l", "door_post_r", "door_lintel", "ramp_platform"];
  return ids.map((id) => {
    const e = game.find(id);
    const p = e.position;
    const s = e.get("Transform").scale;
    return { id, min: [p.x - s.x / 2, p.y - s.y / 2, p.z - s.z / 2], max: [p.x + s.x / 2, p.y + s.y / 2, p.z + s.z / 2] };
  });
}

function insideAny(boxes, p, margin) {
  return boxes.find((b) => p.x > b.min[0] - margin && p.x < b.max[0] + margin && p.y > b.min[1] - margin && p.y < b.max[1] + margin && p.z > b.min[2] - margin && p.z < b.max[2] + margin);
}

describe("following", () => {
  beforeEach(setup);

  test("sits behind and above the courier, looking at it", () => {
    const c = courier().position;
    const p = cam().position;
    expect(p.z).toBeGreaterThan(c.z + 3);
    expect(p.y).toBeGreaterThan(c.y + 1);
    expect(Math.abs(p.x - c.x)).toBeLessThan(0.5);
  });

  test("keeps its distance while the courier runs", () => {
    game.press("move_forward");
    game.step(120);
    const d = Math.hypot(cam().position.x - courier().position.x, cam().position.y - courier().position.y, cam().position.z - courier().position.z);
    expect(d).toBeGreaterThan(3);
    expect(d).toBeLessThan(7);
  });

  test("is smoothed: it lags a sudden teleport for a few frames", () => {
    courier().position = [0, 0.6, 5];
    game.step(1);
    expect(cam().position.z).toBeGreaterThan(14);
    game.step(90);
    expect(cam().position.z).toBeLessThan(13);
  });
});

describe("collision", () => {
  beforeEach(setup);

  test("never ends up inside the yard's geometry along the whole bot route", () => {
    const boxes = solids();
    const bot = new Autoplay(game);
    let worst = null;
    let pulledIn = false;
    for (const wp of YARD_ROUTE) {
      const ok = bot.goTo(wp, () => {
        const hit = insideAny(boxes, cam().position, 0.05);
        if (hit && !worst) worst = hit.id;
        if (cb().actualDistance < cb().distance - 0.5) pulledIn = true;
        return false;
      });
      if (!ok) break;
    }
    bot.stop();
    expect(worst).toBeNull();
    expect(pulledIn).toBe(true);
  });

  test("orbited sideways inside the covered passage the camera is pulled in against the wall", () => {
    courier().position = [0, 0.6, -10];
    cb().yaw = 90;
    game.step(40);
    expect(cb().actualDistance).toBeLessThan(2);
    expect(insideAny(solids(), cam().position, 0.05)).toBeUndefined();
  });

  test("orbiting into the wall brings the camera in instead of through it", () => {
    courier().position = [5.5, 0.6, -1.5]; // just in front of the wall at z = -3
    game.step(20);
    cb().yaw = 180; // camera on the far side of the wall
    game.step(40);
    expect(insideAny(solids(), cam().position, 0.05)).toBeUndefined();
    expect(cb().actualDistance).toBeLessThan(cb().distance);
  });

  test("it eases back out after leaving the passage", () => {
    courier().position = [0, 0.6, -10];
    cb().yaw = 90;
    game.step(40);
    cb().yaw = 0;
    courier().position = [0, 0.6, -2];
    game.step(120);
    expect(cb().actualDistance).toBeCloseTo(cb().distance, 0);
  });
});

describe("orbit", () => {
  beforeEach(setup);

  test("the right stick turns the camera", () => {
    const y0 = cb().yaw;
    game.gamepad(0).axis("RightX", 1);
    game.step(30);
    expect(cb().yaw).not.toBeCloseTo(y0, 0);
  });

  test("the right stick up/down tilts it, clamped", () => {
    game.gamepad(0).axis("RightY", 1);
    game.step(300);
    expect(cb().pitch).toBeLessThanOrEqual(cb().maxPitch);
    expect(cb().pitch).toBeGreaterThanOrEqual(cb().minPitch);
  });

  test("invert Y flips the tilt direction", () => {
    const p0 = cb().pitch;
    game.gamepad(0).axis("RightY", 0.5);
    game.step(10);
    const up = cb().pitch - p0;
    game.gamepad(0).axis("RightY", 0);
    setup();
    cb().invertY = true;
    const p1 = cb().pitch;
    game.gamepad(0).axis("RightY", 0.5);
    game.step(10);
    const inv = cb().pitch - p1;
    expect(Math.sign(up)).toBe(-Math.sign(inv));
  });

  test("the two keyboard keys turn it left and right", () => {
    const y0 = cb().yaw;
    game.press("camera_left");
    game.step(30);
    game.release("camera_left");
    const left = cb().yaw - y0;
    game.press("camera_right");
    game.step(30);
    game.release("camera_right");
    expect(Math.sign(cb().yaw - y0 - left)).toBe(-Math.sign(left));
    expect(Math.abs(left)).toBeGreaterThan(20);
  });

  test("one finger dragging on the free screen orbits", () => {
    const y0 = cb().yaw;
    game.touchStart([640, 250]);
    game.step(2);
    game.touchMove([760, 250]);
    game.step(2);
    game.touchEnd();
    game.step(2);
    expect(Math.abs(cb().yaw - y0)).toBeGreaterThan(10);
  });

  test("a finger on the stick does not orbit the camera", () => {
    const y0 = cb().yaw;
    game.touchStart("touch_stick");
    game.step(2);
    game.touchMove([260, 600]);
    game.step(10);
    game.touchEnd();
    expect(cb().yaw).toBeCloseTo(y0, 3);
  });

  test("a mouse drag orbits (orbit() is what the drag calls)", () => {
    const y0 = cb().yaw;
    cb().orbit(100, 0);
    expect(Math.abs(cb().yaw - y0)).toBeGreaterThan(10);
  });

  test("sensitivity scales the drag", () => {
    cb().orbit(100, 0);
    const a = cb().yaw;
    setup();
    cb().sensitivity = 2;
    cb().orbit(100, 0);
    expect(Math.abs(cb().yaw)).toBeCloseTo(Math.abs(a) * 2, 3);
  });
});

describe("zoom", () => {
  beforeEach(setup);

  test("the wheel zooms (zoom() is what a wheel notch calls) and is clamped to 3..10 m", () => {
    cb().zoom(-100);
    expect(cb().distance).toBe(cb().minDistance);
    cb().zoom(100);
    expect(cb().distance).toBe(cb().maxDistance);
    expect(cb().minDistance).toBe(3);
    expect(cb().maxDistance).toBe(10);
  });

  test("the shoulder buttons zoom in and out", () => {
    const d0 = cb().distance;
    game.gamepad(0).press("RightShoulder");
    game.step(20);
    game.gamepad(0).release("RightShoulder");
    expect(cb().distance).toBeLessThan(d0);
    game.gamepad(0).press("LeftShoulder");
    game.step(60);
    expect(cb().distance).toBeGreaterThan(d0);
  });

  test("a pinch zooms: fingers moving apart zoom in, together zoom out", () => {
    const d0 = cb().distance;
    game.touchStart([500, 300], 0);
    game.touchStart([780, 300], 1);
    game.step(2);
    game.touchMove([400, 300], 0);
    game.touchMove([880, 300], 1);
    game.step(3);
    const apart = cb().distance;
    expect(apart).toBeLessThan(d0);
    game.touchMove([560, 300], 0);
    game.touchMove([720, 300], 1);
    game.step(3);
    game.touchEnd(0);
    game.touchEnd(1);
    expect(cb().distance).toBeGreaterThan(apart);
  });

  test("a pinch never leaves the 3..10 m range", () => {
    game.touchStart([500, 300], 0);
    game.touchStart([780, 300], 1);
    game.step(2);
    game.touchMove([100, 300], 0);
    game.touchMove([1180, 300], 1);
    game.step(5);
    expect(cb().distance).toBeGreaterThanOrEqual(3);
    game.touchEnd(0);
    game.touchEnd(1);
  });
});
