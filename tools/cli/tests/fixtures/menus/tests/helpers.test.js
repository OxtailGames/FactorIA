import { test, expect, game } from "factoria:test";
import { fa, ui, input, storage, session, platform } from "factoria";

// The test helpers of docs/SCRIPTING.md ("Tests"): the none backend, toMatchObject, tapping a widget by id under a safe
// area, and the screen rectangle of a HUD text.
function openMenu() {
  storage.clear();
  game.platform.reset();
  delete session.settingsApplied;
  input.resetBindings();
  game.load("scenes/menu.scene.json");
  game.step(2);
}

test("none backend: a game without a store hides its shop and its calls reject unavailable", async () => {
  openMenu();
  expect(game.find("shop_button").active).toBe(true);
  game.platform.set({ backend: "none" });
  expect(platform.has("purchases")).toBe(false);
  expect(platform.has("achievements")).toBe(false);
  game.load("scenes/menu.scene.json");
  game.step(2);
  expect(game.find("shop_button").active).toBe(false); // main_menu.js shows it only when platform.has("purchases")
  let code = "";
  try {
    await platform.purchases.buy("gems_100");
  } catch (e) {
    code = e.code;
  }
  expect(code).toBe("unavailable");
  const player = await platform.signIn();
  expect(player.signedIn).toBe(false);
  expect(game.platform.state().backend).toBe("none");
  game.platform.reset(); // back to the fake
  expect(platform.has("purchases")).toBe(true);
  expect(game.platform.state().backend).toBe("fake");
});

test("platform.set refuses an unknown option and suggests the right one", () => {
  expect(() => game.platform.set({ backendx: "none" })).toThrow("backend");
  expect(() => game.platform.set({ backend: "steam" })).toThrow("fake");
  expect(platform.has("purchases")).toBe(true); // nothing changed
});

test("toMatchObject checks a subset, recursively", () => {
  const value = { id: "a", pos: { x: 1, y: 2, z: 3 }, tags: [{ n: 1, extra: true }, { n: 2 }], note: "x" };
  expect(value).toMatchObject({ id: "a", pos: { y: 2 }, tags: [{ n: 1 }, { n: 2 }] });
  expect(value).not.toMatchObject({ pos: { y: 3 } });
  expect(value).not.toMatchObject({ tags: [{ n: 1 }] }); // arrays have the same length
  expect(value).not.toMatchObject({ missing: 1 });
  expect(() => expect(value).toMatchObject({ id: "b" })).toThrow("toMatchObject");
  expect(game.platform.state()).toMatchObject({ backend: "fake", fake: { signedIn: true } });
});

test("a TouchButton is tapped by id, wherever the safe area moved it", () => {
  game.platform.reset();
  game.loadJson({
    format: "factoria.scene/1",
    entities: [
      { id: "camera", components: { Transform: { position: [640, 360, 0] }, Camera: {} } },
      {
        id: "jump",
        components: {
          Transform: { position: [-40, -60, 0] },
          TouchButton: { anchor: [1, 1], pivot: [1, 0], button: "A", text: "A", touchOnly: false },
        },
      },
    ],
  });
  game.step(2);
  const flat = ui.rectOf("jump");
  game.setSafeArea("phone-landscape");
  game.step(2); // the rectangles follow the safe area one step later
  const moved = ui.rectOf("jump");
  expect(moved.x).toBeLessThan(flat.x); // the notch side pushes a right-hand control inwards
  expect(game.find("jump")).toBeDefined();
  expect([...ui.rectOf(game.find("jump"))]).toEqual([moved.x, moved.y, moved.w, moved.h]);
  const listed = fa.call("ui.state").widgets.find((w) => w.id === "jump");
  expect(listed.rect).toEqual([moved.x, moved.y, moved.w, moved.h]); // ui.state agrees with ui.rectOf
  game.touchStart("jump");
  game.step(1);
  expect(game.find("jump").get("TouchButton").pressed).toBe(true);
  game.touchEnd();
  game.step(1);
  expect(game.find("jump").get("TouchButton").pressed).toBe(false);
  // The old, fixed coordinates would have missed it.
  game.touchStart([flat.x + flat.w / 2, flat.y + flat.h / 2]);
  game.step(1);
  expect(game.find("jump").get("TouchButton").pressed).toBe(false);
  game.touchEnd();
  expect(() => game.touch("nope")).toThrow("nope");
});

test("the rectangle of a HUD Text is in ui.rectOf and ui.state", () => {
  game.platform.reset();
  game.loadJson({
    format: "factoria.scene/1",
    entities: [
      { id: "camera", components: { Transform: { position: [640, 360, 0] }, Camera: {} } },
      {
        id: "score",
        components: {
          Transform: { position: [20, 30, 0] },
          Text: { text: "Score: 0", fontSize: 24, space: "screen", anchor: [0, 0] },
        },
      },
      { id: "world_text", components: { Transform: { position: [0, 0, 0] }, Text: { text: "in the world" } } },
    ],
  });
  game.step(1);
  const r = ui.rectOf("score");
  expect(r.x).toBeCloseTo(20, 0);
  expect(r.y).toBeCloseTo(30, 0);
  expect(r.w).toBeGreaterThan(20);
  expect(r.h).toBeGreaterThan(10);
  expect(ui.rectOf("world_text")).toBeNull();
  const entry = fa.call("ui.state").widgets.find((w) => w.id === "score");
  expect(entry).toMatchObject({ kind: "Text", text: "Score: 0", interactable: false });
  expect(entry.rect).toEqual([r.x, r.y, r.w, r.h]);
  expect(fa.call("ui.state").widgets.some((w) => w.id === "world_text")).toBe(false);
});
