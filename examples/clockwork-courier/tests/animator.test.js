// The courier's animator state machine (idle, walk, run, jump, fall, land, celebrate, caught, wound down) and the
// footstep sounds the walk and run clips trigger.
import { test, describe, expect, game, beforeEach } from "factoria:test";

const courier = () => game.find("courier");
const state = () => game.find("model").animator.state;

function setup() {
  game.load("scenes/test_yard.scene.json");
  game.step(5);
  game.clearAudioLog();
}

const footsteps = () => game.audioLog().filter((p) => /footstep_/.test(p.path));

describe("states", () => {
  beforeEach(setup);

  test("starts idle", () => {
    expect(state()).toBe("idle");
  });

  test("walks, runs and goes back to idle with the speed", () => {
    game.press("walk");
    game.press("move_forward");
    game.step(30);
    expect(state()).toBe("walk");
    game.release("walk");
    game.step(30);
    expect(state()).toBe("run");
    game.release("move_forward");
    game.step(30);
    expect(state()).toBe("idle");
  });

  test("a jump plays the jump state and lands through the land state", () => {
    game.tap("jump");
    game.step(10);
    expect(state()).toBe("jump");
    const seen = new Set();
    for (let i = 0; i < 60; i++) {
      game.step(1);
      seen.add(state());
    }
    expect(seen.has("land")).toBe(true);
    expect(state()).toBe("idle");
  });

  test("walking off a ledge plays the fall state", () => {
    courier().position = [8, 3.0, 1.5];
    game.step(6);
    game.press("move_left");
    let fell = false;
    for (let i = 0; i < 90 && !fell; i++) {
      game.step(1);
      fell = state() === "fall";
    }
    expect(fell).toBe(true);
  });

  test("the animator parameters follow the courier", () => {
    game.press("move_forward");
    game.step(30);
    const v = game.find("model").get("Animator").values;
    expect(v.speed).toBeGreaterThan(4);
    expect(v.grounded).toBe(true);
  });

  test("delivering plays the celebrate dance and locks the controls", () => {
    courier().behaviour.celebrate();
    game.step(10);
    expect(state()).toBe("celebrate");
    const z0 = courier().position.z;
    game.press("move_forward");
    game.step(30);
    expect(courier().position.z).toBeCloseTo(z0, 1);
  });

  test("being caught plays Death and stays down", () => {
    courier().behaviour.caught("test");
    game.step(80);
    expect(state()).toBe("caught");
  });

  test("a wound down spring sits the courier down", () => {
    courier().behaviour.windDown();
    game.step(30);
    expect(state()).toBe("wound_down");
  });
});

describe("footsteps", () => {
  beforeEach(setup);

  test("running makes concrete footsteps from the clip events", () => {
    game.press("move_forward");
    game.step(90);
    const steps = footsteps();
    expect(steps.length).toBeGreaterThanOrEqual(3);
    for (const s of steps) expect(s.path).toMatch(/footstep_concrete_00[0-3]\.ogg$/);
  });

  test("the variants alternate: never the same sound twice in a row", () => {
    game.press("move_forward");
    game.step(180);
    const steps = footsteps();
    expect(steps.length).toBeGreaterThanOrEqual(6);
    for (let i = 1; i < steps.length; i++) expect(steps[i].path).not.toBe(steps[i - 1].path);
  });

  test("the steps come at the pace of the run cycle (two per 0.96 s)", () => {
    game.press("move_forward");
    game.step(120);
    const n = footsteps().length;
    expect(n).toBeGreaterThanOrEqual(3);
    expect(n).toBeLessThanOrEqual(6);
  });

  test("walking is quieter than running", () => {
    game.press("walk");
    game.press("move_forward");
    game.step(120);
    const walkVol = Math.max(...footsteps().map((p) => p.volume));
    game.release("walk");
    game.clearAudioLog();
    game.step(120);
    const runVol = Math.max(...footsteps().map((p) => p.volume));
    expect(walkVol).toBeLessThan(runVol);
  });

  test("the wooden walkway makes wood footsteps", () => {
    courier().position = [-8, 0.8, 13];
    game.step(6);
    game.clearAudioLog();
    game.press("move_forward");
    game.step(60);
    const steps = footsteps();
    expect(steps.length).toBeGreaterThanOrEqual(2);
    for (const s of steps) expect(s.path).toMatch(/footstep_wood_00[0-3]\.ogg$/);
  });

  test("no footsteps in the air or standing still", () => {
    game.step(60);
    expect(footsteps().length).toBe(0);
  });

  test("the footstep sounds play on the sfx bus", () => {
    game.press("move_forward");
    game.step(60);
    expect(game.audioLog()).toContainPlayed(/footstep_concrete/, { bus: "sfx" });
  });
});
