// The on-screen controls: the TouchStick walks the courier, the TouchButtons jump and pause, nothing sits in the notch.
import { test, describe, expect, game, beforeEach } from "factoria:test";

const courier = () => game.find("courier");

function setup() {
  game.load("scenes/test_yard.scene.json");
  game.step(20);
}

describe("touch controls", () => {
  beforeEach(setup);

  test("a finger pushed up on the stick runs the courier forward", () => {
    const z0 = courier().position.z;
    game.touchStart("touch_stick");
    game.step(2);
    game.touchMove([150, 480]); // 90 px above the stick's centre (150, 570)
    game.step(40);
    expect(z0 - courier().position.z).toBeGreaterThan(2);
    expect(courier().behaviour.speed).toBeGreaterThan(3);
    game.touchEnd();
    game.step(30);
    expect(courier().behaviour.speed).toBeCloseTo(0, 1);
  });

  test("a small push on the stick walks slowly (analog)", () => {
    game.touchStart("touch_stick");
    game.step(2);
    game.touchMove([150, 535]); // 35 px: a third of the radius, past the deadzone
    game.step(40);
    const s = courier().behaviour.speed;
    expect(s).toBeGreaterThan(0.5);
    expect(s).toBeLessThan(3.2);
    game.touchEnd();
  });

  test("the stick to the right turns and moves the courier right (camera-relative)", () => {
    const x0 = courier().position.x;
    game.touchStart("touch_stick");
    game.step(2);
    game.touchMove([240, 570]);
    game.step(30);
    expect(courier().position.x - x0).toBeGreaterThan(1.5);
    game.touchEnd();
  });

  test("the jump button jumps", () => {
    const y0 = courier().position.y;
    game.touchStart("touch_jump");
    game.step(6);
    expect(courier().position.y).toBeGreaterThan(y0 + 0.2);
    expect(game.find("touch_jump").get("TouchButton").pressed).toBe(true);
    game.touchEnd();
  });

  test("stick and jump button work at the same time (two fingers)", () => {
    game.touchStart("touch_stick", 0);
    game.step(2);
    game.touchMove([150, 480], 0);
    game.touchStart("touch_jump", 1);
    game.step(12);
    expect(courier().position.y).toBeGreaterThan(1);
    expect(courier().position.z).toBeLessThan(16);
    game.touchEnd(0);
    game.touchEnd(1);
  });

  test("the pause button opens the pause menu", () => {
    game.touchStart("touch_pause");
    game.step(4);
    game.touchEnd();
    game.step(2);
    expect(game.paused).toBe(true);
    expect(game.find("pause_panel").active).toBe(true);
  });

  test("the controls only show once the player touches (hidden for keyboard and gamepad players)", () => {
    expect(game.find("touch_stick").get("TouchStick").shown).toBe(false);
    game.touch([640, 300], 3);
    game.step(2);
    expect(game.find("touch_stick").get("TouchStick").shown).toBe(true);
    expect(game.find("touch_jump").get("TouchButton").shown).toBe(true);
    game.keyDown("Space");
    game.step(2);
    game.keyUp("Space");
    game.step(2);
    expect(game.find("touch_stick").get("TouchStick").shown).toBe(false);
  });

  test("the controls stay out of a phone's notch and rounded corners (safe area)", () => {
    game.setSafeArea("phone-landscape");
    game.step(3);
    const stick = game.find("touch_stick").get("TouchStick");
    expect(stick.safeArea).toBe(true);
    expect(game.find("touch_jump").get("TouchButton").safeArea).toBe(true);
    expect(game.find("touch_pause").get("TouchButton").safeArea).toBe(true);
    expect(game.find("spring_bg").get("Shape2D").safeArea).toBe(true);
  });
});
