// The age gate (scripts/ui/age_gate.js): it asks for the birth year, tells the ad network whether the player is under the age
// of consent, keeps only that boolean, cannot be skipped with Back, and is not asked again. The gate is spawned from its prefab
// into whatever scene the test starts in, so this test passes in any game that has the ageGate part. The fake store plays the
// ad network (docs/PLATFORM.md), driven with a gamepad like the other menu tests.
import { test, expect, game } from "factoria:test";
import { world, ui, storage, platform } from "factoria";
import { MenuStack } from "../scripts/ui/menu_stack.js";
import { openAgeGate, isUnderAge } from "../scripts/ui/age_gate.js";

const pad = game.gamepad(0);

// An empty store, then the gate over a menu stack of its own. Returns the stack.
function open() {
  storage.clear();
  game.platform.reset();
  world.find("age_gate")?.destroy(); // the panel of the test before
  game.step(1);
  const panel = world.spawnPrefab("prefabs/ui/age_gate.prefab.json");
  panel.id = "age_gate"; // MenuStack shows panels by id
  panel.active = false;
  const menus = new MenuStack(null);
  expect(openAgeGate(menus)).toBe(true);
  game.step(2);
  expect(menus.top).toBe("age_gate");
  expect(world.find("age_gate").active).toBe(true);
  return menus;
}

// Sets the year on the slider the way a drag would, then presses Continue with the gamepad.
function answer(year) {
  world.find("birth_year").get("Slider").value = year;
  ui.focus(world.find("age_continue")); // the menu under the gate has widgets of its own: do not walk to Continue
  pad.tap("A");
  game.step(2);
}

test("the year decides: born 16 years ago or less counts as a child, a year of birth alone is off by one", () => {
  expect(isUnderAge(2020, 2026)).toBe(true);
  expect(isUnderAge(2010, 2026)).toBe(true); // 15 or 16: counted as a child
  expect(isUnderAge(2009, 2026)).toBe(false); // 16 or 17
  expect(isUnderAge(1980, 2026)).toBe(false);
  expect(isUnderAge(null, 2026)).toBe(true); // "I would rather not say"
});

test("a child's birth year: the network is told under age, and only that is saved", () => {
  const menus = open();
  expect(platform.ads.underAge).toBe(null);
  answer(game.today().year - 9);
  expect(platform.ads.underAge).toBe(true);
  expect(storage.get("ageGate")).toEqual({ underAge: true }); // not the year
  expect(menus.top).toBe(null);
  expect(world.find("age_gate").active).toBe(false);
  expect(game.platform.calls().filter((c) => c.method === "ads.setUnderAge").map((c) => c.args.underAge)).toEqual([true]);
});

test("an adult's birth year", () => {
  open();
  answer(1985);
  expect(platform.ads.underAge).toBe(false);
  expect(storage.get("ageGate")).toEqual({ underAge: false });
});

test("\"I would rather not say\" counts as a child", () => {
  open();
  ui.focus(world.find("age_skip")); // I would rather not say
  pad.tap("A");
  game.step(2);
  expect(platform.ads.underAge).toBe(true);
  expect(storage.get("ageGate")).toEqual({ underAge: true });
});

test("Back does not skip the question", () => {
  const menus = open();
  pad.tap("B");
  game.step(1);
  expect(menus.top).toBe("age_gate");
  expect(world.find("age_gate").active).toBe(true);
  expect(platform.ads.underAge).toBe(null);
  expect(MenuStack.busy).toBe(true);
  answer(1990);
  expect(MenuStack.busy).toBe(false);
});

test("the next run does not ask again and tells the network the saved answer", () => {
  open();
  answer(2015);
  expect(platform.ads.underAge).toBe(true);
  // A new run: the network forgot the answer (the fake is reset), storage kept it.
  game.platform.reset();
  expect(platform.ads.underAge).toBe(null);
  const menus = new MenuStack(null);
  expect(openAgeGate(menus)).toBe(false);
  game.step(2);
  expect(menus.top).toBe(null);
  expect(platform.ads.underAge).toBe(true);
});
