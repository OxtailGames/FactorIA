// The choice card (scripts/ui/card.js): a modal panel over the game. A click on a button under it does nothing and the
// focus stays on the card; the arrows move between its choices (a disabled one is skipped and shows why); the pad picks;
// the result stage ends with Continue; holdClock pauses the game while it is open. The scene is built here, so this test
// passes in any game that has the card part.
import { test, expect, game } from "factoria:test";
import { world, ui } from "factoria";
import { Card } from "../scripts/ui/card.js";

const pad = game.gamepad(0);

/** A scene with a button under where the card will be, then the card with three choices (the second cannot be chosen). */
function open(options = {}) {
  game.loadJson({
    format: "factoria.scene/1",
    entities: [{ id: "under", components: { Button: { text: "Under", size: [200, 60], anchor: [0.5, 0.5], layer: 10 } } }],
  });
  game.step(2);
  const clicks = [];
  ui.on("click", (e) => clicks.push(e.id));
  const chosen = [];
  const card = new Card({ onChoose: (id) => chosen.push(id), onContinue: () => chosen.push("continue"), ...options });
  card.ask({
    kind: "Event",
    title: "A stranger at the gate",
    body: "A long body of text that has to wrap onto several lines inside the card, because the card is only 640 pixels wide and this sentence is longer than that.",
    choices: [
      { id: "help", text: "Help", detail: "Costs 2 wood" },
      { id: "buy", text: "Buy the map", detail: "Never shown", disabled: "Needs 50 coins" },
      { id: "leave", text: "Leave", detail: "Nothing happens" },
    ],
  });
  game.step(3);
  return { card, clicks, chosen };
}

test("a click on a button under the card does nothing, and the focus stays on the card", () => {
  const { card, clicks } = open();
  expect(ui.focused.id).toBe("choice_help");
  game.click("under");
  game.step(2);
  expect(clicks).not.toContain("under");
  expect(ui.hovered?.id ?? null).not.toBe("under");
  expect(ui.focused.id.startsWith("choice_")).toBe(true);
  expect(ui.pointerOverUi).toBe(true);
  card.close();
  game.step(2);
  game.click("under");
  game.step(2);
  expect(clicks).toContain("under");
});

test("the arrows move between the choices and skip the disabled one", () => {
  const { chosen } = open();
  expect(ui.focused.id).toBe("choice_help");
  game.tap("ui_down");
  game.step(2);
  expect(ui.focused.id).toBe("choice_leave"); // choice_buy cannot be chosen: no focus
  game.tap("ui_down");
  game.step(2);
  expect(ui.focused.id).toBe("choice_leave"); // the last one: the focus never leaves the card
  game.tap("ui_up");
  game.step(2);
  expect(ui.focused.id).toBe("choice_help");
  game.tap("ui_up");
  game.step(2);
  expect(ui.focused.id).toBe("choice_help");
  game.tap("ui_submit");
  game.step(2);
  expect(chosen).toEqual(["help"]);
});

test("a disabled choice does nothing and shows why", () => {
  const { chosen } = open();
  const buy = world.find("choice_buy");
  expect(buy.get("Button").interactable).toBe(false);
  game.click("choice_buy");
  game.step(2);
  expect(chosen).toEqual([]);
  expect(world.find("choice_buy_detail").get("Text").text).toContain("Needs 50 coins");
  expect(world.find("choice_buy_detail").get("Text").text).not.toContain("Never shown");
  expect(world.find("choice_help_detail").get("Text").text).toBe("Costs 2 wood");
});

test("the pad picks a choice, the result stage has Continue, and closing gives the game back", () => {
  const { card, clicks, chosen } = open();
  pad.tap("DpadDown");
  game.step(2);
  expect(ui.focused.id).toBe("choice_leave");
  pad.tap("A");
  game.step(2);
  expect(chosen).toEqual(["leave"]);
  card.answer({ body: "You walk away.", effects: "[b]Nothing changed[/b]" });
  game.step(3);
  expect(world.find("choice_leave")).toBe(null);
  expect(world.find("card_continue").activeInHierarchy).toBe(true);
  expect(ui.focused.id).toBe("card_continue");
  game.click("under");
  game.step(2);
  expect(clicks).not.toContain("under");
  pad.tap("A");
  game.step(2);
  expect(chosen).toEqual(["leave", "continue"]);
  card.close();
  game.step(2);
  expect(world.find("card")).toBe(null);
});

test("holdClock pauses the game while the card is open; a game that was paused stays paused", () => {
  game.paused = false;
  const { card } = open({ holdClock: true });
  expect(game.paused).toBe(true);
  card.close();
  expect(game.paused).toBe(false);
  game.paused = true;
  const again = open({ holdClock: true });
  again.card.close();
  expect(game.paused).toBe(true);
  game.paused = false;
});

test("the card blocks the pointer by being modal, not only by its backdrop", () => {
  const { card, clicks } = open();
  world.find("card").get("Panel").color = [0, 0, 0, 0]; // a backdrop that draws nothing is not hit...
  game.step(2);
  game.click("under"); // ...but Panel.modal still keeps the pointer from every widget outside the card
  game.step(2);
  expect(clicks).not.toContain("under");
  expect(ui.focused.id.startsWith("choice_")).toBe(true);
  card.close();
});
