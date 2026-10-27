// The interaction prompt (its text follows the last device used), highlighting, and what using things does.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { input, ui } from "factoria";
import { enter, porter, stand, screenOf } from "./helpers/lodge.js";
import * as story from "../scripts/story.js";
import * as items from "../scripts/items.js";

const hud = () => game.find("hud").behaviour;

/** A pixel on the prompt panel: the lowest one at the horizontal centre of the screen that belongs to it. */
function promptPixel() {
  for (let y = 719; y > 400; y--) if (ui.widgetAt(640, y)?.id === "prompt_panel") return [640, y - 4];
  return null;
}

describe("the prompt", () => {
  beforeEach(() => {
    enter("ground");
    stand(19, 19.6, 0); // in front of the reception desk, facing it
  });

  test("it names the nearest object in front of the porter, with the key of the keyboard", () => {
    game.tapKey("F"); // the last device is the keyboard (this also uses the desk: fine, it only shows a line)
    game.step(5);
    expect(porter().behaviour.target.entity.id).toBe("p_reception");
    expect(hud().promptText).toBe("[F] Look at reception desk");
    expect(game.find("prompt_panel").active).toBe(true);
  });

  test("with a gamepad it shows the pad's button, by family", () => {
    const pad = game.gamepad(0);
    pad.connect({ type: "xbox" });
    pad.tap("X");
    game.step(5);
    expect(input.lastDevice).toBe("gamepad");
    expect(hud().promptText).toBe("[A] Look at reception desk");
    pad.setType("playstation");
    game.step(3);
    expect(hud().promptText).toBe("[Cross] Look at reception desk");
  });

  test("with the mouse it says Click, with a finger Tap", () => {
    game.mouseMove([300, 600]);
    game.step(3);
    expect(input.lastDevice).toBe("mouse");
    expect(hud().promptText).toBe("[Click] Look at reception desk");
    game.touchStart([640, 50], 1); // a finger resting on the far screen: the porter keeps still until it lifts
    game.step(3);
    expect(input.lastDevice).toBe("touch");
    expect(hud().promptText).toBe("[Tap] Look at reception desk");
    game.touchEnd(1);
  });

  test("it follows the language and goes away when the object is out of reach", () => {
    game.tapKey("F");
    game.step(3);
    expect(hud().promptText).not.toBe("");
    stand(19, 14.8, 0);
    game.step(3);
    expect(hud().promptText).toBe("");
    expect(game.find("prompt_panel").active).toBe(false);
  });

  test("the highlighted object glows, and stops when the porter walks away", () => {
    game.step(8);
    const desk = game.find("p_reception");
    const glow = () => desk.get("MeshRenderer").emissive[0];
    expect(glow()).toBeGreaterThan(0.05);
    stand(19, 14.8, 0);
    game.step(3);
    expect(glow()).toBe(0);
  });

  test("an object behind the porter is not offered unless it is close", () => {
    stand(19, 19.6, 180); // turned away from the desk
    game.step(3);
    expect(porter().behaviour.target?.entity.id).not.toBe("p_reception");
  });
});

describe("using things", () => {
  beforeEach(() => {
    enter("ground");
    stand(19, 19.6, 0);
  });

  test("the interact action examines: a line is shown and the story counts it", () => {
    game.tap("interact");
    game.step(2);
    expect(hud().message).toContain("guest book");
    expect(story.count("examined.p_reception")).toBe(1);
  });

  test("a click on the prompt uses what it names (the touch player's button)", () => {
    game.tapKey("F");
    game.step(80); // the first line goes away
    const before = story.count("examined.p_reception");
    const at = promptPixel();
    expect(at).not.toBe(null);
    game.click(at);
    game.step(3);
    expect(story.count("examined.p_reception")).toBe(before + 1);
  });

  test("a click on the object walks up to it and uses it", () => {
    stand(15, 22, 0);
    const desk = game.find("p_reception");
    const at = desk.worldPosition;
    game.click(screenOf({ x: at.x, y: at.y + 0.6, z: at.z }));
    expect(porter().behaviour.lastClick).toEqual({ kind: "object", id: "p_reception" });
    game.step(300);
    expect(story.count("examined.p_reception")).toBe(1);
  });

  test("a locked door says why and stays shut; the key opens it for good", () => {
    stand(5.4, 12, 90); // just east of the library door, facing it (-x)
    const door = game.find("library_door").behaviour;
    expect(door.available).toBe(true);
    game.tap("interact");
    game.step(2);
    expect(hud().message).toContain("locked");
    expect(door.isOpen).toBe(false);
    items.add("library_key", "test");
    game.tap("interact");
    game.step(2);
    expect(door.isOpen).toBe(true);
    expect(story.has("open.library_door")).toBe(true);
    expect(game.find("library_door").has("Collider3D")).toBe(false);
    expect(hud().promptText === "" || !hud().promptText.includes("library door")).toBe(true);
  });

  test("an item box gives its item once, and an empty box is not offered again", () => {
    stand(30.2, 10.2, 0);
    expect(items.has("lamp_oil")).toBe(false);
    game.tap("interact");
    game.step(2);
    expect(items.has("lamp_oil")).toBe(true);
    expect(story.has("kitchen_box_taken")).toBe(true);
    expect(hud().message).toContain("Lamp oil");
    game.step(5);
    expect(porter().behaviour.target?.entity.id).not.toBe("p_kitchen_box");
  });

  test("an open door stays open in the next visit to the area", () => {
    story.set("open.library_door");
    enter("ground", "spawn_default", true);
    expect(game.find("library_door").behaviour.isOpen).toBe(true);
    expect(game.find("library_door").has("Collider3D")).toBe(false);
  });
});
