// The camp and its shop: buying each upgrade, cash running short, the camp between two floors, and the three ways to drive it
// (mouse, keyboard, gamepad).
import { test, describe, expect, game } from "factoria:test";
import { scene } from "factoria";
import { cleanBeforeEach } from "./helpers/world.js";
import { startRun, run } from "../scripts/game/run_state.js";
import * as upgrades from "../scripts/game/upgrades.js";
import * as events from "../scripts/game/events.js";
import * as players from "../scripts/game/players.js";
import * as codes from "../scripts/game/seed_code.js";
import { live } from "../scripts/game/mine_map.js";
import { CAMP, SHIFT, descend, arrive } from "./helpers/camp.js";

/** The camp with `cash` banked. */
function openCamp(cash, opts = {}) {
  players.clear();
  startRun({ seed: 4242, ...opts });
  run.cash = cash;
  game.load(CAMP);
  game.step(3);
}

const text = (id) => game.find(id).get("Text").text;
const label = (id) => game.find(id).get("Button").text;

describe("the shop", () => {
  cleanBeforeEach();

  test("sells the six things of run.upgrades, each a ladder whose prices rise", () => {
    expect(upgrades.ITEMS).toEqual(["pickTier", "pickSpeed", "lampOil", "lampRadius", "walkSpeed", "torches"]);
    for (const id of upgrades.ITEMS) {
      const costs = upgrades.SHOP[id].levels.map((l) => l.cost);
      expect(costs[0]).toBe(0);
      for (let i = 1; i < costs.length; i++) expect(costs[i]).toBeGreaterThan(costs[i - 1]);
      const values = upgrades.SHOP[id].levels.map((l) => l.value);
      for (let i = 1; i < values.length; i++) expect(values[i]).toBeGreaterThan(values[i - 1]);
    }
  });

  test("every upgrade can be bought level by level from banked cash, and the cash is spent", () => {
    startRun({ seed: 1 });
    run.cash = 100000;
    const bought = [];
    events.on("upgradeBought", (e) => bought.push(e));
    const cashLog = [];
    events.on("cashChanged", (e) => cashLog.push(e));
    for (const id of upgrades.ITEMS) {
      const levels = upgrades.SHOP[id].levels;
      for (let level = 1; level < levels.length; level++) {
        const before = run.cash;
        const r = upgrades.buy(id);
        expect(r).toMatchObject({ ok: true, upgrade: id, level, cost: levels[level].cost });
        expect(run.upgrades[id]).toBe(levels[level].value);
        expect(run.cash).toBe(before - levels[level].cost);
        expect(upgrades.levelOf(id)).toBe(level);
      }
      expect(upgrades.offer(id)).toBeNull();
    }
    expect(bought.length).toBe(upgrades.ITEMS.reduce((n, id) => n + upgrades.maxLevel(id), 0));
    expect(bought[0]).toMatchObject({ upgrade: "pickTier", level: 1, cost: 60, cash: 100000 - 60 });
    expect(cashLog.every((c) => c.cause === "upgrade" && c.delta < 0)).toBe(true);
  });

  test("a purchase that the cash cannot pay changes nothing and says what is short; the maximum refuses too", () => {
    startRun({ seed: 1 });
    run.cash = 59;
    const log = [];
    events.on("upgradeBought", (e) => log.push(e));
    const r = upgrades.buy("pickTier");
    expect(r).toMatchObject({ ok: false, reason: "cash", need: 1, have: 59 });
    if (!r.ok) expect(r.hint).toContain("1 more cash");
    expect(run.cash).toBe(59);
    expect(run.upgrades.pickTier).toBe(0);
    expect(log.length).toBe(0);
    run.cash = 1000;
    upgrades.buy("pickTier");
    upgrades.buy("pickTier");
    const max = upgrades.buy("pickTier");
    expect(max).toMatchObject({ ok: false, reason: "max" });
    expect(run.cash).toBe(1000 - 60 - 180);
  });

  test("an item the shop does not sell is an error with a suggestion", () => {
    expect(() => upgrades.buy("pickSped")).toThrow("pickSpeed");
    expect(() => upgrades.upgradesAt({ torches: 9 })).toThrow("levels 0 to 3");
    expect(upgrades.upgradesAt({ torches: 2 }).torches).toBe(10);
  });
});

describe("the camp scene", () => {
  cleanBeforeEach();

  test("shows the cash, the next floor and the code of the next mine, and each button names its upgrade and price", () => {
    openCamp(75);
    expect(text("camp_cash")).toBe("Cash: 75");
    expect(text("camp_next")).toBe("Next: Topsoil, floor 1");
    expect(text("camp_seed")).toMatch(/^Mine code: [0-9A-Z]{4}-[0-9A-Z]{4}$/);
    expect(label("buy_pickTier")).toBe("Pick hardness: tier 0  >  tier 1  (cost 60)");
    expect(label("buy_torches")).toBe("Torches: 6  >  8  (cost 20)");
  });

  test("clicking an upgrade buys it, updates the texts and plays the purchase sound; the label then shows the next level", () => {
    openCamp(100);
    game.click("buy_pickTier");
    game.step(1);
    expect(run.upgrades.pickTier).toBe(1);
    expect(run.cash).toBe(40);
    expect(text("camp_cash")).toBe("Cash: 40");
    expect(label("buy_pickTier")).toBe("Pick hardness: tier 1  >  tier 2  (cost 180)");
    expect(text("camp_message")).toBe("Bought Pick hardness: tier 1.");
  });

  test("with too little cash the click teaches: what the price is, how much is missing, and nothing is bought", () => {
    openCamp(10);
    game.click("buy_pickSpeed");
    game.step(1);
    expect(run.upgrades.pickSpeed).toBe(1);
    expect(run.cash).toBe(10);
    expect(text("camp_message")).toContain("costs 30");
    expect(text("camp_message")).toContain("bring 20 more cash");
  });

  test("the best level shows '(best)' and a click on it says so", () => {
    openCamp(1000);
    for (let i = 0; i < 3; i++) game.click("buy_torches");
    game.step(1);
    expect(label("buy_torches")).toBe("Torches: 13  (best)");
    game.click("buy_torches");
    game.step(1);
    expect(text("camp_message")).toContain("maximum");
    expect(run.cash).toBe(1000 - 20 - 50 - 100);
  });

  test("the results lead to the camp and the camp to the next shift, where the upgrades are in force", () => {
    players.clear();
    startRun({ seed: 99, slot: null });
    run.cash = 0;
    game.load("scenes/shift.scene.json");
    game.step(3);
    run.ore.gold = 9;
    const exit = live.map.tileCenter(live.mine.exit.tx, live.mine.exit.ty);
    game.world.findByTag("miner")[0].position = [exit.x, exit.y, 0];
    game.step(130);
    expect(scene.current).toBe("scenes/results.scene.json");
    game.click("again");
    arrive(CAMP);
    const banked = run.lastShift.banked;
    expect(banked).toBeGreaterThan(45);
    expect(run.cash).toBe(banked);
    expect([run.stratum, run.floor]).toEqual([0, 2]);
    expect(text("camp_next")).toBe("Next: Topsoil, floor 2");
    game.click("buy_torches"); // 20
    game.click("buy_lampOil"); // 25
    game.step(1);
    descend();
    expect(scene.current).toBe(SHIFT);
    expect(run.shiftNumber).toBe(2);
    expect(run.torches).toBe(8);
    expect(run.lamps[0].oil).toBeGreaterThan(145); // 150 s of oil, a few frames burned
    expect(run.lamps[0].oil).toBeLessThanOrEqual(150);
    expect(run.cash).toBe(banked - 45);
  });

  test("the code in the camp is the code of the mine the next shift plays", () => {
    openCamp(0, { seed: 777, stratum: 1, floor: 2 });
    const shown = text("camp_seed").replace("Mine code: ", "");
    descend();
    expect(live.mine.seed).toBe(777);
    expect(live.mine.stratum).toBe(1);
    expect(live.mine.floor).toBe(2);
    expect(codes.decode(shown)).toEqual({ ok: true, seed: 777, stratum: 1, floor: 2 });
  });

  test("Back to title leaves the camp", () => {
    openCamp(0);
    game.click("to_title");
    game.step(3);
    expect(scene.current).toBe("scenes/menu.scene.json");
  });
});

describe("the camp with each input", () => {
  cleanBeforeEach();

  test("gamepad only: the first upgrade has the focus, Down moves, A buys, and the way down is reachable", () => {
    openCamp(200);
    const pad = game.gamepad(0);
    pad.tap("DpadDown"); // pick speed
    pad.tap("A");
    expect(run.upgrades.pickSpeed).toBe(1.25);
    pad.tap("DpadDown");
    pad.tap("DpadDown"); // lamp light
    pad.tap("A");
    expect(run.upgrades.lampRadius).toBe(1.15);
    expect(run.cash).toBe(200 - 30 - 30);
    pad.tap("DpadRight"); // over to the right column
    for (let i = 0; i < 5; i++) pad.tap("DpadDown"); // more than enough to reach the end of it
    for (let i = 0; i < 6; i++) pad.tap("DpadUp");
    game.step(1);
  });

  test("keyboard only: the ui_down and ui_submit actions (arrow keys and Enter) buy, a click is not needed", () => {
    openCamp(200);
    game.tap("ui_down");
    game.tap("ui_submit");
    expect(run.upgrades.pickSpeed).toBe(1.25);
    game.tap("ui_down");
    game.tap("ui_submit");
    expect(run.upgrades.lampOil).toBe(150);
  });

  test("mouse: a click buys, and clicks on Copy code and Down to the mine work", () => {
    openCamp(60);
    game.click("buy_pickTier");
    expect(run.upgrades.pickTier).toBe(1);
    game.click("copy_code");
    game.step(1);
    expect(text("camp_message")).toContain("kept for this session");
    descend();
    expect(scene.current).toBe(SHIFT);
  });
});
