// Doors and stairs between areas: the screen fades, the next area is read ahead (scene.preload), the scene changes, and
// the porter arrives at the spawn the door named.
import { test, describe, expect, game, beforeEach } from "factoria:test";
import { scene } from "factoria";
import { enter, porter, stand, distance } from "./helpers/lodge.js";

const area = () => game.find("area").behaviour;

describe("stairs", () => {
  beforeEach(() => enter("ground"));

  test("the staircase takes the porter upstairs, to the spawn it names", () => {
    expect(scene.current).toBe("scenes/ground.scene.json");
    stand(2.5, 19.5, 90); // beside the stairs, facing them (-x)
    game.tap("interact");
    game.step(2);
    // Under way: the screen goes black, the porter is held, and the scene has not changed yet.
    expect(area().leaving).toBe("upstairs");
    expect(porter().behaviour.locked).toBe(true);
    expect(scene.current).toBe("scenes/ground.scene.json");
    game.press("move_forward");
    const p0 = { x: porter().position.x, z: porter().position.z };
    game.step(2);
    expect(distance(porter(), p0)).toBeLessThan(0.05); // held: the keys do nothing
    game.release("move_forward");
    game.step(120);
    expect(scene.current).toBe("scenes/upstairs.scene.json");
    expect(area().arrivedAt).toBe("spawn_from_ground");
    expect(distance(porter(), game.find("spawn_from_ground").position)).toBeLessThan(0.5);
    expect(porter().behaviour.locked).toBe(false);
  });

  test("and the way back down arrives at the foot of the stairs", () => {
    enter("upstairs", "spawn_from_ground");
    expect(scene.current).toBe("scenes/upstairs.scene.json");
    stand(2.5, 15.5, 90);
    game.tap("interact");
    game.step(120);
    expect(scene.current).toBe("scenes/ground.scene.json");
    expect(area().arrivedAt).toBe("spawn_from_upstairs");
    expect(distance(porter(), game.find("spawn_from_upstairs").position)).toBeLessThan(0.5);
  });

  test("the door to the cellar is an area door too", () => {
    stand(31.5, 15, 270); // facing +x, towards the cellar door
    game.tap("interact");
    game.step(120);
    expect(scene.current).toBe("scenes/cellar.scene.json");
    expect(area().area).toBe("cellar");
  });
});

describe("a change that outlives its scene", () => {
  test("leaving through a door and loading another scene at once ends in the other scene", () => {
    enter("ground");
    stand(2.5, 19.5, 90);
    game.tap("interact");
    game.step(5); // the change to upstairs is under way
    expect(area().leaving).toBe("upstairs");
    game.load("scenes/test_room.scene.json", { arrive: "spawn_default" }); // the player is somewhere else now
    game.step(200);
    expect(scene.current).toBe("scenes/test_room.scene.json"); // the old area's change did not load upstairs on top of it
    expect(area().area).toBe("test_room");
  });

  test("an area that does not exist is refused with a suggestion, and nothing changes", () => {
    enter("ground");
    expect(area().goTo("upstair", "spawn_default")).toBe(false);
    expect(area().leaving).toBe("");
    expect(porter().behaviour.locked).toBe(false);
    game.step(60);
    expect(scene.current).toBe("scenes/ground.scene.json");
  });
});

describe("spawns", () => {
  test("a wrong spawn name falls back to spawn_default", () => {
    enter("ground", "spawn_from_nowhere");
    expect(area().arrivedAt).toBe("spawn_default");
    expect(distance(porter(), game.find("spawn_default").position)).toBeLessThan(0.5);
  });
});
