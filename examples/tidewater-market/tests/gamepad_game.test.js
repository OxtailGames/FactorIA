// P6: a short game with a gamepad alone (no mouse, no keyboard): the left stick moves the cursor, A clicks, B puts things away, the
// shoulders switch the build category. Build a house, inspect it, fill a ship's order and answer an event card. The clock is ticked
// directly between the steps (a day is 30 s) and the frames only let the interface react.
import { test, expect, game } from "factoria:test";
import { input, scene, ui } from "factoria";
import { rich, put } from "./town_helper.js";
import { cellToWorld } from "../scripts/game/iso.js";
import { pointer } from "../scripts/game/pointer.js";
import { centreOf } from "./ui_helper.js";

const GAME = "scenes/game.scene.json";

function tickUntil(state, done, maxDays = 20) {
  for (let i = 0; i < maxDays * state.clock.ticksPerDay; i++) {
    if (done()) return true;
    state.clock.tick(state.clock.step);
  }
  return done();
}

/** Push the left stick towards `target` (screen pixels) until the cursor is there, as a thumb does: harder when far, gently near. */
function cursorTo(pad, target, label = "") {
  for (let i = 0; i < 400; i++) {
    const p = pointer.position();
    const dx = target.x - p.x;
    const dy = target.y - p.y;
    const dist = Math.hypot(dx, dy);
    if (dist < 5) break;
    const tilt = Math.max(0.35, Math.min(1, dist / 60));
    pad.axis("LeftX", (dx / dist) * tilt);
    pad.axis("LeftY", (-dy / dist) * tilt); // +Y up on a stick
    game.step(1);
  }
  pad.axis("LeftX", 0);
  pad.axis("LeftY", 0);
  game.step(2);
  const p = pointer.position();
  if (Math.hypot(target.x - p.x, target.y - p.y) >= 8) throw new Error(`the cursor stopped at ${Math.round(p.x)},${Math.round(p.y)}, not at ${Math.round(target.x)},${Math.round(target.y)} (${label}); under ${pointer.hovered() && pointer.hovered().id}, focus ${ui.focused && ui.focused.id}`);
}

/** Move the cursor to a widget and press A on it. */
function press(pad, id) {
  game.step(3); // a panel that just opened is laid out over a frame or two: aim at where the widget is now
  cursorTo(pad, centreOf(id), id);
  pad.tap("A");
  game.step(2);
}

test("a short game with the gamepad alone: build, inspect, fill an order, answer an event card", () => {
  game.platform.reset();
  game.load(GAME, { testMap: true, trade: true, scenario: "sandbox", music: false, speed: 0 });
  game.step(3);
  expect(scene.current).toBe(GAME);
  const ctl = game.find("controller").behaviour;
  const rig = game.find("camera").behaviour;
  const { state, hud } = ctl;
  const trade = state.trade;
  rich(state);
  put(state, "pier", 4, 1);
  const [cx, cy] = cellToWorld(5, 4);
  rig.setView(cx, cy, 1.5);
  game.step(3);
  const pad = game.gamepad(0);
  pad.axis("LeftX", 0.6); // a first push of the stick: the game knows a pad is in use
  game.step(2);
  pad.axis("LeftX", 0);
  game.step(2);
  expect(state.clock.speed).toBe(0);

  // --- build: the shoulders open the build menu and switch to the housing tab, the cursor picks the house and a cell
  expect(input.lastDevice).toBe("gamepad");
  expect(pointer.pad).toBe(true);
  pad.tap("RightShoulder");
  game.step(2);
  expect(hud.buildOpen).toBe(true);
  pad.tap("RightShoulder");
  game.step(2);
  expect(hud.cat).toBe("housing");
  press(pad, "tool_house");
  expect(ctl.tool.kind).toBe("build");
  // a free cell the game accepts for a house, away from the panels
  let spot = null;
  for (let r = 2; r < 9 && !spot; r++) {
    for (let c = 1; c < 9 && !spot; c++) {
      if (!state.check("house", c, r).ok) continue;
      const [wx, wy] = cellToWorld(c, r);
      const [sx, sy] = rig.worldToScreen(wx, wy);
      if (sx > 200 && sx < 900 && sy > 120 && sy < 450) spot = { c, r, sx, sy };
    }
  }
  expect(spot).not.toBe(null);
  const before = state.list("house").length;
  cursorTo(pad, { x: spot.sx, y: spot.sy });
  pad.tap("A");
  game.step(2);
  expect(state.list("house").length).toBe(before + 1);
  const house = state.buildingAt(spot.c, spot.r);
  expect(house.type).toBe("house");

  // --- B puts the tool away, then A on the house inspects it
  pad.tap("B");
  game.step(2);
  expect(ctl.tool.kind).toBe("none");
  game.step(2);
  cursorTo(pad, { x: spot.sx, y: spot.sy });
  pad.tap("A");
  game.step(3);
  expect(hud.sel && hud.sel.id).toBe(house.id);
  expect(hud.isOpen("inspector")).toBe(true);
  press(pad, "insp_close");
  expect(hud.isOpen("inspector")).toBe(false);

  // --- an order: the ship docks, the cursor goes to the Orders button, then to Fill order
  expect(tickUntil(state, () => trade.ships.some((s) => s.state === "docked"))).toBe(true);
  answerCards(pad, state);
  const ship = trade.ships.find((s) => s.state === "docked");
  expect(ship).toBeTruthy();
  state.economy.apply({ ...ship.order.goods }, "test");
  game.step(3);
  const coins = state.economy.coins;
  press(pad, "btn_orders");
  expect(game.find(`fill_${ship.id}`)).not.toBe(null);
  press(pad, `fill_${ship.id}`);
  expect(ship.state).toBe("leaving");
  expect(state.economy.coins).toBe(coins + ship.order.reward);
  press(pad, "board_close");
  expect(game.find("board_close")).toBe(null);

  // --- an event card: the cursor picks a choice and Continue
  state.clock.setSpeed(1);
  expect(tickUntil(state, () => !!trade.card, 30)).toBe(true);
  game.step(3);
  expect(state.clock.speed).toBe(0);
  answerCards(pad, state);
  expect(trade.card).toBe(null);
  expect(input.lastDevice).toBe("gamepad"); // the whole game was played from the pad
});

/** Answer every card that is open with the cursor: the first choice that can be taken, then Continue. */
function answerCards(pad, state) {
  let guard = 0;
  while (state.trade.card && guard++ < 8) {
    const card = state.trade.card;
    if (card.stage === "choose") {
      const { def } = state.trade.cardDef(card);
      const choice = def.choices.find((c) => state.trade.canChoose(c).ok);
      press(pad, `choice_${choice.id}`);
    } else press(pad, "card_continue");
  }
  expect(state.trade.card).toBe(null);
}

test("the cursor over nothing leaves the focus empty, over a button it hovers and focuses it", () => {
  game.platform.reset();
  game.load(GAME, { testMap: true, trade: true, scenario: "sandbox", music: false, speed: 0 });
  game.step(3);
  const pad = game.gamepad(0);
  pad.axis("LeftX", 0.6);
  game.step(2);
  pad.axis("LeftX", 0);
  game.step(2);
  expect(pointer.pad).toBe(true);
  cursorTo(pad, centreOf("btn_build"), "btn_build");
  expect(ui.hovered && ui.hovered.id).toBe("btn_build");
  expect(ui.focused && ui.focused.id).toBe("btn_build");
  cursorTo(pad, { x: 640, y: 300 }, "the map");
  game.step(10);
  expect(ui.widgetAt(640, 300)).toBe(null);
  expect(ui.focused).toBe(null);
});
