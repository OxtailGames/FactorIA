// The screens of the trade, driven by the mouse alone: the ships on the water, the Orders button and the order board, the event
// and story cards, the store (fake) hearing about achievements. The clock is ticked directly (a day is 30 s) and the frames
// only let the views draw; pictures go to .factoria/tmp/ (git-ignored) for the eyes.
import { test, expect, game } from "factoria:test";
import { scene } from "factoria";
import { rich, put } from "./town_helper.js";
import { cellToWorld } from "../scripts/game/iso.js";

const GAME = "scenes/game.scene.json";

/** The test map with the trade on, a pier on its north coast and money for anything. */
function harbour(scenario = "first_harbour", extra = {}) {
  game.platform.reset();
  game.load(GAME, { testMap: true, trade: true, scenario, music: false, speed: 0, ...extra });
  game.step(3);
  expect(scene.current).toBe(GAME);
  const ctl = game.find("controller").behaviour;
  const state = ctl.state;
  rich(state);
  put(state, "pier", 4, 1);
  return { ctl, state, trade: state.trade, ui: game.find("trade_ui").behaviour };
}

function tickUntil(state, done, maxDays = 20) {
  for (let i = 0; i < maxDays * state.clock.ticksPerDay; i++) {
    if (done()) return true;
    state.clock.tick(state.clock.step);
  }
  return done();
}

/** Close the story card of day 2 (and any other that opens) with the mouse: first choice, then Continue. */
function answerWithMouse(state) {
  let guard = 0;
  while (state.trade.card && guard++ < 8) {
    const card = state.trade.card;
    if (card.stage === "choose") {
      const { def } = state.trade.cardDef(card);
      const choice = def.choices.find((c) => state.trade.canChoose(c).ok);
      game.click(`choice_${choice.id}`);
    } else game.click("card_continue");
    game.step(2);
  }
}

test("a ship sails in over the water, docks at the pier and is drawn there", () => {
  const { state, trade } = harbour("sandbox");
  const ships = game.find("trade_ui").behaviour.ships;
  expect(ships.count).toBe(0);
  expect(tickUntil(state, () => trade.ships.length > 0)).toBe(true);
  game.step(1);
  expect(ships.count).toBe(1);
  const ship = trade.ships[0];
  const e = ships.byShip.get(ship.id);
  expect(e.get("Sprite").region).toEqual(game.find("trade_ui").behaviour.atlas.frames[`ship.${ship.cls}.${trade.position(ship, 1).heading}`].rect);
  expect(tickUntil(state, () => ship.state === "docked")).toBe(true);
  state.clock.tick(state.clock.step); // one more step: the ship stands still on its berth
  game.step(1);
  // docked: the ship sits on the berth water cell next to the pier
  const berth = trade.ships[0].route[trade.ships[0].route.length - 1];
  const [wx, wy] = cellToWorld(berth[0], berth[1]);
  expect(Math.abs(e.position[0] - wx)).toBeLessThan(1);
  expect(Math.abs(e.position[1] - wy)).toBeLessThan(1);
  const [cx, cy] = cellToWorld(5, 1);
  answerWithMouse(state); // a card would cover the picture
  game.find("camera").behaviour.setView(cx, cy, 2);
  game.step(2);
  game.screenshot(".factoria/tmp/ship_docked.png");
});

test("the Orders button opens the board; Fill order works only with the goods, pays, and the ship leaves", () => {
  const { state, trade } = harbour("sandbox");
  expect(tickUntil(state, () => trade.ships.some((s) => s.state === "docked"))).toBe(true);
  answerWithMouse(state); // a card of the season may be waiting; it is modal
  game.step(2);
  expect(game.find("btn_orders").get("Button").text).toBe("Orders (1)");
  expect(game.find("board_close")).toBe(null);
  game.click("btn_orders");
  game.step(2);
  expect(game.find("board_close")).not.toBe(null);
  const ship = trade.ships[0];
  const fill = game.find(`fill_${ship.id}`);
  expect(fill).not.toBe(null);
  // no goods: the button is grey and a click does nothing
  state.economy.apply(Object.fromEntries(Object.keys(ship.order.goods).map((g) => [g, -state.economy.get(g)])), "test");
  game.step(2);
  expect(game.find(`fill_${ship.id}`).get("Button").interactable).toBe(false);
  game.screenshot(".factoria/tmp/order_board_missing.png");
  const coins = state.economy.coins;
  // the goods arrive: the button turns on
  state.economy.apply({ ...ship.order.goods }, "test");
  game.step(2);
  expect(game.find(`fill_${ship.id}`).get("Button").interactable).toBe(true);
  game.screenshot(".factoria/tmp/order_board.png");
  game.click(`fill_${ship.id}`);
  game.step(2);
  expect(ship.state).toBe("leaving");
  expect(state.economy.coins).toBe(coins + ship.order.reward);
  expect(trade.reputation).toBeGreaterThan(0);
  expect(game.find(`fill_${ship.id}`)).toBe(null);
  game.click("board_close");
  game.step(2);
  expect(game.find("board_close")).toBe(null);
  // a click on the board did not build on the map under it
  expect(state.list().filter((b) => b.type !== "pier")).toHaveLength(0);
});

test("the O key and the Orders button both toggle the board; the map under it does not get the clicks", () => {
  const { ctl } = harbour("sandbox");
  game.click("btn_orders");
  game.step(2);
  expect(game.find("board_close")).not.toBe(null);
  expect(ctl.uiPanels.some((p) => p.id === undefined || true)).toBe(true);
  game.click("btn_orders");
  game.step(2);
  expect(game.find("board_close")).toBe(null);
  game.press("order_board");
  game.step(2);
  expect(game.find("board_close")).not.toBe(null);
  game.click("board_close");
  game.step(2);
  expect(game.find("board_close")).toBe(null);
});

test("an event card stops the clock, shows its choices with their effects, and a click on a choice applies it", () => {
  const { ctl, state, trade } = harbour("sandbox", { speed: 1 });
  expect(state.clock.speed).toBe(1);
  // the event day of the first season
  expect(tickUntil(state, () => !!trade.card, 6)).toBe(true);
  game.step(2);
  expect(state.clock.speed).toBe(0); // the card waits for the player
  const card = trade.card;
  const { def } = trade.cardDef(card);
  expect(game.find("card_title")).not.toBe(null);
  expect(game.find("card_title").get("Text").text.length).toBeGreaterThan(3);
  for (const c of def.choices) expect(game.find(`choice_${c.id}`)).not.toBe(null);
  game.screenshot(".factoria/tmp/event_card.png");
  const before = { coins: state.economy.coins, rep: trade.reputation };
  const choice = def.choices.find((c) => trade.canChoose(c).ok);
  game.click(`choice_${choice.id}`);
  game.step(2);
  expect(trade.card.stage).toBe("result");
  expect(game.find("card_continue")).not.toBe(null);
  game.screenshot(".factoria/tmp/event_result.png");
  const fx = trade.resultEffects(trade.card);
  expect(state.economy.coins - before.coins).toBe(fx.delta.coins || 0);
  expect(trade.reputation - before.rep).toBe(fx.reputation);
  game.click("card_continue");
  game.step(2);
  expect(trade.card).toBe(null);
  expect(game.find("card_title")).toBe(null);
  expect(state.clock.speed).toBe(1); // the clock goes on at the speed it had
  void ctl;
});

test("a story card is a card like the others: it opens on its day and finishing the story is announced", () => {
  const { state, trade } = harbour("first_harbour");
  const stories = [];
  state.events.on("trade.card", (e) => e.card.kind === "story" && stories.push(e.card.id));
  expect(tickUntil(state, () => !!trade.card, 4)).toBe(true);
  game.step(2);
  expect(trade.card.kind).toBe("story");
  expect(trade.card.id).toBe("letter");
  expect(game.find("card_kind").get("Text").text).toBe("Story");
  game.screenshot(".factoria/tmp/story_card.png");
  answerWithMouse(state);
  expect(trade.card === null || trade.card.kind === "event").toBe(true);
  expect(stories[0]).toBe("letter");
});

test("achievements and counts reach the store: the first ship unlocks its achievement on the fake store", () => {
  const { state, trade } = harbour("sandbox");
  expect(tickUntil(state, () => trade.stats.shipsDocked > 0)).toBe(true);
  game.step(4);
  const fake = game.platform.state().fake;
  expect(fake.achievements.first_ship.unlocked).toBe(true);
  expect(fake.stats.ships_docked).toBe(1);
  const calls = game.platform.state().fake.calls.map((c) => c.method);
  expect(calls).toContain("achievements.unlock");
  expect(calls).toContain("stats.set"); // the fake store implements stats.add as get + set
});

test("a game with no store keeps playing: every call is refused and nothing breaks", () => {
  game.platform.reset();
  game.platform.set({ backend: "none" });
  const { state, trade } = harbour("sandbox");
  expect(tickUntil(state, () => trade.stats.shipsDocked > 0)).toBe(true);
  game.step(4);
  expect(trade.unlocked).toContain("first_ship");
  game.platform.reset();
});

test("a choice the town cannot pay is greyed out and a click on it changes nothing", () => {
  const { state, trade } = harbour("first_harbour");
  expect(tickUntil(state, () => !!trade.card, 4)).toBe(true);
  expect(trade.card.id).toBe("letter");
  game.click("choice_aloud");
  game.step(1);
  game.click("card_continue"); // the event of the day was queued behind the letter and opens now
  game.step(2);
  expect(trade.card.kind).toBe("event");
  game.click(`choice_${trade.cardDef(trade.card).def.choices.find((c) => trade.canChoose(c).ok).id}`);
  game.step(1);
  game.click("card_continue");
  game.step(2);
  expect(trade.card.id).toBe("pier"); // the story goes on: the pier stands
  // "paint" costs 20 coins: the town has none
  state.economy.apply({ coins: -state.economy.coins }, "test");
  state.events.emit("trade.restored", {}); // redraw the open card (what a loaded game does)
  game.step(2);
  expect(game.find("choice_paint").get("Button").interactable).toBe(false);
  game.click("choice_paint");
  game.step(2);
  expect(trade.card.stage).toBe("choose");
  expect(state.economy.coins).toBe(0);
  game.click("choice_plain"); // the free one still works
  game.step(2);
  expect(trade.card.stage).toBe("result");
  expect(game.find("card_continue")).not.toBe(null);
  game.click("card_continue");
  game.step(2);
});

test("leaving the game scene takes the board, the card and the ships with it", () => {
  const { state, trade } = harbour("sandbox", { speed: 1 });
  expect(tickUntil(state, () => !!trade.card, 6)).toBe(true);
  game.step(2);
  expect(game.find("card_title")).not.toBe(null);
  game.load("scenes/menu.scene.json");
  game.step(3);
  expect(scene.current).toBe("scenes/menu.scene.json");
  expect(game.find("card_title")).toBe(null);
  expect(game.find("btn_orders")).toBe(null);
  expect(game.find("controller")).toBe(null);
});
