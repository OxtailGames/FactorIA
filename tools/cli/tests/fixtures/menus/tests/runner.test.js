import { test, expect, game } from "factoria:test";
import { ui } from "factoria";

// The test runner's UI helpers: a click right after a panel opens, the error for a widget that cannot be clicked, tapKey.
const scene = () => game.loadJson({
  format: "factoria.scene/1",
  entities: [
    { id: "popup", active: false, components: { Panel: { size: [300, 200], anchor: [0.5, 0.5], layout: "column", spacing: 8, padding: [10, 10, 10, 10] } },
      children: [{ id: "popup_ok", components: { Button: { text: "OK", size: [120, 40] } } }] },
    { id: "plain", components: { Button: { text: "Hi", size: [100, 40], anchor: [0.2, 0.2] } } },
    { id: "empty", components: { Button: { text: "x", size: [0, 0], anchor: [0.9, 0.9] } } },
    { id: "name", components: { TextField: { text: "", size: [200, 40], anchor: [0.5, 0.1], autoFocus: true } } },
  ],
});

test("a click on a widget of a panel opened this frame needs no step", () => {
  scene();
  game.step(2);
  const clicks = [];
  ui.on("click", (e) => clicks.push(e.id));
  expect(() => game.click("popup_ok")).toThrow("inactive");
  game.find("popup").active = true;
  game.click("popup_ok"); // laid out by the click itself
  expect(clicks).toEqual(["popup_ok"]);
});

test("a click on a widget that cannot be clicked throws, naming it, and a position still works", () => {
  scene();
  game.step(2);
  expect(() => game.click("popup_ok")).toThrow(/popup_ok.*cannot be clicked.*inactive/);
  expect(() => game.click("empty")).toThrow(/empty.*cannot be clicked.*no area/);
  const clicks = [];
  ui.on("click", (e) => clicks.push(e.id));
  game.click("plain");
  expect(clicks).toEqual(["plain"]);
});

test("tapKey presses and releases a key over one frame: Enter submits a TextField", () => {
  scene();
  game.step(2);
  const submitted = [];
  ui.on("submit", "name", (e) => submitted.push(e.value));
  game.click("name");
  game.find("name").set("TextField", { text: "Mara" });
  game.tapKey("Enter");
  expect(submitted).toEqual(["Mara"]);
});
