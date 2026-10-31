// The three ways to move the porter: keys, a gamepad, and a click or tap on the floor (the touch scheme).
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { input } from "factoria";
import { enter, porter, cam, distance, screenOf, stand } from "./helpers/lodge.js";

describe("keyboard", () => {
  beforeEach(() => enter("ground"));

  test("the porter starts on the floor of the hall, standing still", () => {
    const p = porter();
    expect(p.behaviour.grounded).toBe(true);
    expect(p.behaviour.speed).toBeCloseTo(0, 1);
    expect(p.position.y).toBeGreaterThan(0.8);
    expect(p.position.y).toBeLessThan(1.1);
  });

  test("move_forward walks away from the camera, and he stops when it is released", () => {
    const z0 = porter().position.z;
    game.press("move_forward");
    game.step(60);
    const walked = z0 - porter().position.z;
    expect(walked).toBeGreaterThan(1.5);
    expect(walked).toBeLessThan(3.2);
    expect(porter().behaviour.speed).toBeGreaterThan(2);
    expect(porter().behaviour.speed).toBeLessThan(2.6);
    game.release("move_forward");
    game.step(20);
    expect(porter().behaviour.speed).toBeCloseTo(0, 1);
  });

  test("move_right is to the right of the camera", () => {
    const x0 = porter().position.x;
    game.press("move_right");
    game.step(40);
    expect(porter().position.x - x0).toBeGreaterThan(1);
  });

  test("movement is camera-relative: with the camera turned 90 degrees, forward is -x", () => {
    stand(15, 21, 90); // camera at +x looking along -x
    const x0 = porter().position.x;
    game.press("move_forward");
    game.step(40);
    expect(x0 - porter().position.x).toBeGreaterThan(1);
  });

  test("run is faster than walk", () => {
    game.press("move_forward");
    game.step(40);
    const walk = porter().behaviour.speed;
    game.press("run");
    game.step(40);
    expect(porter().behaviour.speed).toBeGreaterThan(walk + 1.5);
    expect(porter().behaviour.speed).toBeLessThan(4.8);
  });

  test("the animator follows the speed: idle, walk, run", () => {
    const anim = game.find("porter_model").animator;
    expect(anim.state).toBe("idle");
    game.press("move_forward");
    game.step(30);
    expect(anim.state).toBe("walk");
    game.press("run");
    game.step(30);
    expect(anim.state).toBe("run");
    game.release("run");
    game.release("move_forward");
    game.step(40);
    expect(anim.state).toBe("idle");
  });

  test("he turns to face where he walks", () => {
    game.press("move_left");
    game.step(30);
    // facing -x: yaw is 90 degrees (heading (-sin yaw, -cos yaw))
    expect(Math.abs(porter().behaviour.yaw - 90)).toBeLessThan(5);
  });

  test("a wall stops him: he cannot walk out of the hall through the front wall", () => {
    stand(15, 21, 180); // camera yaw 180: the camera is at -z and forward is +z, towards the front wall at z = 24
    game.press("move_forward");
    game.step(240);
    expect(porter().position.z).toBeLessThan(24);
    expect(porter().position.z).toBeGreaterThan(22.5);
  });
});

describe("gamepad", () => {
  beforeEach(() => enter("ground"));

  test("the left stick walks, and the prompt device becomes the pad", () => {
    const pad = game.gamepad(0);
    pad.connect({ type: "xbox" });
    const z0 = porter().position.z;
    pad.axis("LeftY", 0.55);
    game.step(50);
    expect(input.lastDevice).toBe("gamepad");
    expect(z0 - porter().position.z).toBeGreaterThan(1);
    expect(porter().behaviour.speed).toBeLessThan(2.7); // a half tilt walks
  });

  test("a full tilt runs, a half tilt walks (analog)", () => {
    const pad = game.gamepad(0);
    pad.axis("LeftY", 0.5);
    game.step(40);
    const half = porter().behaviour.speed;
    pad.axis("LeftY", 1);
    game.step(40);
    const full = porter().behaviour.speed;
    expect(half).toBeGreaterThan(0.8);
    expect(half).toBeLessThan(2.6);
    expect(full).toBeGreaterThan(4);
  });

  test("the right stick orbits the camera", () => {
    const yaw0 = cam().behaviour.yaw;
    game.gamepad(0).axis("RightX", 1);
    game.step(30);
    expect(Math.abs(cam().behaviour.yaw - yaw0)).toBeGreaterThan(20);
  });
});

describe("click and tap to walk", () => {
  beforeEach(() => enter("ground"));

  test("a click on the floor walks the porter there, round the furniture", () => {
    const target = { x: 15, y: 0, z: 18 };
    game.click(screenOf(target));
    expect(porter().behaviour.lastClick.kind).toBe("ground");
    game.step(240);
    expect(distance(porter(), target)).toBeLessThan(0.5);
    expect(porter().behaviour.speed).toBeCloseTo(0, 1);
  });

  test("a click behind the reception desk walks him round it", () => {
    stand(19, 20.8, 0);
    const target = { x: 19, y: 0, z: 15.4 }; // the desk and its chair are between him and the corridor
    game.click(screenOf(target));
    expect(porter().behaviour.autoPath.length).toBeGreaterThan(1); // waypoints: not a straight line
    game.step(420);
    expect(distance(porter(), target)).toBeLessThan(0.5);
  });

  test("a tap does the same (touch drives the pointer)", () => {
    const target = { x: 18, y: 0, z: 21 };
    game.touch(screenOf(target), 3);
    game.step(240);
    expect(input.lastDevice).toBe("touch");
    expect(distance(porter(), target)).toBeLessThan(0.5);
  });

  test("a click on the front wall does not walk him through it", () => {
    game.click(screenOf({ x: 15, y: 1.2, z: 24 }));
    game.step(240);
    expect(porter().position.z).toBeLessThan(24);
  });

  test("a direction key cancels the walk", () => {
    game.click(screenOf({ x: 15, y: 0, z: 14 }));
    game.step(20);
    const x = porter().position.x;
    game.press("move_right");
    game.step(30);
    game.release("move_right");
    game.step(10);
    expect(porter().position.x).toBeGreaterThan(x + 0.5);
    const z = porter().position.z;
    game.step(60);
    expect(Math.abs(porter().position.z - z)).toBeLessThan(0.1); // no walk left to finish
  });

  test("a drag orbits the camera and is not a click", () => {
    const yaw0 = cam().behaviour.yaw;
    const p0 = porter().position;
    game.drag([640, 300], [760, 300]);
    game.step(30);
    expect(Math.abs(cam().behaviour.yaw - yaw0)).toBeGreaterThan(5);
    expect(distance(porter(), p0)).toBeLessThan(0.3);
  });
});
