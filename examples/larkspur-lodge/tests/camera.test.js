// The third-person camera: it follows, orbits, stops at walls and fades what hides the porter.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { enter, porter, cam, stand } from "./helpers/lodge.js";

describe("follow and orbit", () => {
  beforeEach(() => enter("ground"));

  test("it keeps its distance behind the porter and follows him when he walks", () => {
    const c = cam();
    expect(c.behaviour.actualDistance).toBeGreaterThan(6);
    const before = { x: c.position.x, z: c.position.z };
    game.press("move_forward");
    game.step(60);
    game.release("move_forward");
    game.step(30);
    const after = c.position;
    expect(Math.hypot(after.x - before.x, after.z - before.z)).toBeGreaterThan(1.5);
    const p = porter().position;
    expect(Math.hypot(after.x - p.x, after.z - p.z)).toBeLessThan(8);
  });

  test("the zoom action brings it closer, within its limits", () => {
    const d0 = cam().behaviour.distance;
    game.press("zoom_in");
    game.step(60);
    game.release("zoom_in");
    expect(cam().behaviour.distance).toBeLessThan(d0);
    expect(cam().behaviour.distance).toBeGreaterThanOrEqual(3);
  });

  test("the mouse wheel zooms: forward is closer, back is farther, and the limits hold", () => {
    const c = cam().behaviour;
    const d0 = c.distance;
    game.wheel(2);
    game.step(2);
    expect(c.distance).toBeLessThan(d0);
    game.wheel(-4);
    game.step(2);
    expect(c.distance).toBeGreaterThan(d0);
    for (let i = 0; i < 40; i++) {
      game.wheel(5);
      game.step(1);
    }
    expect(c.distance).toBeCloseTo(c.minDistance, 3);
  });

  test("the orbit keys turn it round the porter", () => {
    const yaw0 = cam().behaviour.yaw;
    game.press("camera_right");
    game.step(30);
    game.release("camera_right");
    expect(Math.abs(cam().behaviour.yaw - yaw0)).toBeGreaterThan(20);
  });
});

describe("walls", () => {
  test("it stops at the front wall of the hall instead of going through it", () => {
    enter("ground");
    stand(15, 22.8, 0); // the camera wants to be 7.5 m behind him, on the other side of the wall at z = 24
    game.step(40);
    const c = cam();
    expect(c.position.z).toBeLessThan(24);
    expect(c.behaviour.actualDistance).toBeLessThan(c.behaviour.distance - 1);
  });

  test("a wall between the camera and the porter fades, and comes back when he steps out from behind it", () => {
    enter("test_room");
    const c = cam().behaviour;
    stand(4, 4.2, 0); // the free-standing wall at z = 6 is between him and the camera
    game.step(60);
    expect(c.fadingIds).toContain("w_screen");
    expect(c.fadeAlphaOf("w_screen")).toBeLessThan(0.4);
    const wall = game.find("w_screen");
    expect(wall.get("MeshRenderer").color[3]).toBeLessThan(0.4);
    stand(4, 8, 0); // now both are on the same side
    game.step(90);
    expect(c.fadingIds).not.toContain("w_screen");
    expect(c.fadeAlphaOf("w_screen")).toBe(1);
    expect(wall.get("MeshRenderer").color[3]).toBeCloseTo(1, 2);
  });

  test("a fading wall keeps its colour: only the alpha changes", () => {
    enter("test_room");
    const wall = game.find("w_screen");
    const c0 = wall.get("MeshRenderer").color;
    const base = [c0[0], c0[1], c0[2]];
    stand(4, 4.2, 0);
    game.step(60);
    const faded = wall.get("MeshRenderer").color;
    expect(faded[3]).toBeLessThan(0.5);
    expect(faded[0]).toBeCloseTo(base[0], 3);
    expect(faded[1]).toBeCloseTo(base[1], 3);
    expect(faded[2]).toBeCloseTo(base[2], 3);
  });
});
