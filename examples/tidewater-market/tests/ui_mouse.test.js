// The interface with the mouse alone (P3): the build menu, the inspector, the goods table, tooltips, overlays and notifications.
// No key is pressed in this file. The panels are driven through their widgets (game.click on an id), the map through the cells.
import { test, expect, game } from "factoria:test";
import { ui } from "factoria";
import { cellToWorld } from "../scripts/game/iso.js";
import { townScene, cellAt, centreOf, textOf, shown, pickFromMenu } from "./ui_helper.js";
import { put, runDays } from "./town_helper.js";

test("build menu: open it, switch tabs, read the costs, place a house from it", () => {
  game.load("scenes/game.scene.json", { testMap: true });
  game.step(3);
  const ctl = game.find("controller").behaviour;
  const rig = game.find("camera").behaviour;
  const [x, y] = cellToWorld(5, 5);
  rig.setView(x, y, 1);
  game.step(2);
  expect(game.find("build_bar").active).toBe(false);
  game.click("btn_build");
  expect(game.find("build_bar").active).toBe(true);
  expect(shown("tool_road")).toBe(true); // the first tab is open
  expect(shown("tool_house")).toBe(false);
  game.click("cat_housing");
  expect(shown("tool_house")).toBe(true);
  expect(shown("tool_road")).toBe(false);
  expect(textOf("tool_house")).toContain("40 coins");
  game.click("cat_production");
  for (const type of ["farm", "fisher_dock", "lumber_camp", "quarry", "sawmill", "mill", "bakery", "smokehouse", "workshop"]) {
    expect(shown(`tool_${type}`)).toBe(true);
  }
  // nothing is hidden off screen
  const bar = ui.rectOf("build_bar");
  expect(bar.x).toBeGreaterThanOrEqual(0);
  expect(bar.x + bar.w).toBeLessThanOrEqual(1280);
  expect(bar.y).toBeGreaterThan(0);
  expect(bar.y + bar.h).toBeLessThanOrEqual(720);
  // place a house from the menu
  pickFromMenu("house");
  expect(ctl.tool).toEqual({ kind: "build", type: "house", rot: 0 });
  game.click(cellAt(rig, 5, 5));
  expect(ctl.state.list("house")).toHaveLength(1);
  expect(ctl.state.economy.coins).toBe(1000 - 40);
  // the item goes red when it cannot be paid
  ctl.state.economy.coins = 10;
  game.step(20);
  expect(game.find("tool_house").get("Button").textColor[1]).toBeLessThan(0.6);
  ctl.state.economy.coins = 5000;
  game.step(20);
  expect(game.find("tool_house").get("Button").textColor[1]).toBeGreaterThan(0.9);
});

test("inspector: a click on a building shows it, Rotate and Demolish work, a villager chip opens the villager", () => {
  const { ctl, rig, hud, state, ids } = townScene();
  expect(game.find("inspector").active).toBe(false);
  game.click(cellAt(rig, 5, 3)); // the farm
  expect(hud.sel).toEqual({ kind: "building", id: ids.farm });
  expect(game.find("inspector").active).toBe(true);
  expect(textOf("insp_line_0")).toContain("Farm");
  expect(textOf("insp_line_3")).toContain("Workers: 2 of 2");
  expect(shown("chip_0")).toBe(true);
  expect(shown("chip_1")).toBe(true);
  expect(shown("chip_2")).toBe(false);
  // inside the screen, and clear of the buttons on the right
  const insp = ui.rectOf("inspector");
  expect(insp.x + insp.w).toBeLessThanOrEqual(1280);
  expect(insp.y).toBeGreaterThanOrEqual(ui.rectOf("palette").y + ui.rectOf("palette").h);
  // a villager from the chips
  game.step(15);
  game.click("chip_0");
  expect(hud.sel.kind).toBe("villager");
  expect(textOf("insp_line_0")).toContain("Villager #");
  expect(textOf("insp_line_2")).toContain("Home: House");
  const before = { ...rig.view };
  game.click("insp_home");
  expect(rig.view.x !== before.x || rig.view.y !== before.y).toBe(true);
  // back to the farm, then rotate: the same farm, turned (a new id), free, one undo step
  rig.setView(...cellToWorld(5, 5), 1);
  game.step(2);
  game.click(cellAt(rig, 5, 3));
  const coins = state.economy.coins;
  game.click("insp_rotate");
  const farm = state.list("farm")[0];
  expect(farm.rot).toBe(1);
  expect(state.economy.coins).toBe(coins);
  expect(hud.sel).toEqual({ kind: "building", id: farm.id });
  game.click("insp_close");
  expect(game.find("inspector").active).toBe(false);
  // demolish from the inspector
  game.click(cellAt(rig, 5, 3));
  expect(hud.sel.kind).toBe("building");
  game.click("insp_demolish");
  expect(state.list("farm")).toHaveLength(0);
  expect(game.find("inspector").active).toBe(false);
  // a click on bare ground puts the selection away; a click on a road does not select it
  game.click(cellAt(rig, 7, 3)); // smokehouse
  expect(hud.sel.kind).toBe("building");
  game.click(cellAt(rig, 11, 8)); // water
  expect(hud.sel).toBe(null);
  game.click(cellAt(rig, 4, 5)); // road
  expect(hud.sel).toBe(null);
  expect(ctl.tool.kind).toBe("none");
});

test("goods table: opens, sorts by any column both ways, scrolls with the wheel without zooming the map", () => {
  const { rig, state } = townScene();
  expect(game.find("goods_panel").active).toBe(false);
  game.click("btn_goods");
  expect(game.find("goods_panel").active).toBe(true);
  const rows = () => state.data.goodIds.map((_, i) => ({ name: textOf(`grow_${i}_name`), stock: textOf(`grow_${i}_stock`), price: Number(textOf(`grow_${i}_price`)) }));
  const byName = rows().map((r) => r.name); // opens sorted by name
  expect(byName).toEqual([...byName].sort());
  game.click("gsort_name"); // the same column again reverses
  expect(rows().map((r) => r.name)).toEqual([...byName].reverse());
  game.click("gsort_price");
  const byPrice = rows().map((r) => r.price);
  expect(byPrice).toEqual([...byPrice].sort((a, b) => b - a)); // numbers start from the biggest
  game.click("gsort_price");
  const up = rows().map((r) => r.price);
  expect(up).toEqual([...up].sort((a, b) => a - b));
  game.click("gsort_stock");
  const stocks = rows().map((r) => Number(r.stock.replace("k", "000")));
  expect(stocks).toEqual([...stocks].sort((a, b) => b - a));
  expect(textOf("gsort_stock")).toContain("v");
  // more goods than rows in view: the wheel scrolls the list and the map keeps its zoom
  const zoom = rig.view.zoom;
  const last = `grow_${state.data.goodIds.length - 1}_name`;
  const list = ui.rectOf("goods_list");
  const y0 = ui.rectOf(last).y;
  expect(y0 + 12).toBeGreaterThan(list.y + list.h - 1); // the last row starts below the visible rows
  game.mouseMove(centreOf("goods_list"));
  game.step(2);
  game.wheel(-5);
  game.step(3);
  expect(rig.view.zoom).toBe(zoom);
  expect(ui.rectOf(last).y).toBeLessThan(y0);
  game.click("goods_close");
  expect(game.find("goods_panel").active).toBe(false);
  // the wheel zooms the map again
  game.mouseMove({ x: 400, y: 400 });
  game.step(2);
  game.wheel(-2);
  game.step(3);
  expect(rig.view.zoom).not.toBe(zoom);
});

test("tooltips: they wait, say what and which key, stay on the screen and go away when the pointer moves", () => {
  const { rig, hud } = townScene();
  const tip = () => ui.rectOf("tooltip");
  const visible = () => game.find("tooltip").position[0] > -1000;
  game.mouseMove(centreOf("btn_goods"));
  game.step(10);
  expect(visible()).toBe(false); // not at once
  game.step(40);
  expect(visible()).toBe(true);
  expect(textOf("tooltip_title")).toBe("Goods  (G)");
  expect(textOf("tooltip_line_1")).toContain("Key: G");
  // the bottom button of the right column: the tooltip does not leave the screen
  game.mouseMove(centreOf("btn_help"));
  game.step(2);
  expect(visible()).toBe(false);
  game.step(40);
  expect(visible()).toBe(true);
  const r = tip();
  expect(r.x).toBeGreaterThanOrEqual(0);
  expect(r.x + r.w).toBeLessThanOrEqual(1280);
  expect(r.y + r.h).toBeLessThanOrEqual(720);
  // a click while it shows hides it, a new target restarts the wait
  game.mouseMove({ x: 20, y: 700 });
  game.step(2);
  expect(visible()).toBe(false);
  // the top bar numbers explain themselves
  game.mouseMove(centreOf("coins_text"));
  game.step(40);
  expect(textOf("tooltip_title")).toBe("Coins");
  game.mouseMove(centreOf("pop_text"));
  game.step(40);
  expect(textOf("tooltip_title")).toBe("Villagers");
  game.mouseMove(centreOf("good_fish_text"));
  game.step(40);
  expect(textOf("tooltip_title")).toBe("fish");
  expect(textOf("tooltip_line_1")).toContain("a day");
  // a building on the map, with no tool in hand
  game.mouseMove(cellAt(rig, 5, 3));
  game.step(40);
  expect(textOf("tooltip_title")).toBe("Farm");
  expect(textOf("tooltip_line_0")).toContain("Workers");
  // but not while a tool is held
  pickFromMenu("house");
  game.mouseMove(cellAt(rig, 5, 3));
  game.step(40);
  expect(visible()).toBe(false);
  expect(hud.tooltips.current).toBe(null);
  // a build menu item names what the building needs and gives
  game.click("cat_production");
  game.step(20);
  game.mouseMove(centreOf("item_bakery"));
  game.step(40);
  expect(textOf("tooltip_title")).toBe("Bakery");
  const lines = [0, 1, 2, 3, 4, 5].map((i) => textOf(`tooltip_line_${i}`)).join("\n");
  expect(lines).toContain("Cost:");
  expect(lines).toContain("Needs:");
  expect(lines).toContain("flour");
});

test("overlays: the Map button cycles through four overlays and off; each one is drawn over the map and says what it shows", () => {
  const { hud, ids, state, ctl } = townScene();
  const market = state.buildings.get(ids.market);
  expect(game.find("overlay_legend").active).toBe(false);
  const seen = [];
  for (let i = 0; i < 4; i++) {
    game.click("btn_overlay");
    game.step(2);
    seen.push(hud.overlay);
    expect(game.find("overlay_legend").active).toBe(true);
    expect(textOf("overlay_legend")).toContain("Overlay:");
  }
  expect(seen).toEqual(["desirability", "market", "warehouse", "traffic"]);
  game.click("btn_overlay");
  expect(hud.overlay).toBe(null);
  expect(game.find("overlay_legend").active).toBe(false);
  // the market overlay is strongest at the market and nothing at the far corner
  game.click("btn_overlay");
  game.click("btn_overlay");
  game.step(2);
  expect(hud.overlay).toBe("market");
  expect(hud.overlayValue(market.x, market.y)).toBeGreaterThan(0.8);
  expect(hud.overlayValue(0, 0)).toBe(0);
  // the overlay follows the town: a new building re-computes it
  game.click("btn_overlay");
  game.click("btn_overlay");
  game.click("btn_overlay"); // off
  game.click("btn_overlay"); // desirability
  game.step(2);
  const free = hud.overlayValue(10, 7);
  put(state, "house", 10, 7);
  game.step(2);
  expect(hud.overlayValue(10, 7)).toBe(0);
  expect(free).toBeGreaterThanOrEqual(0);
  expect(ctl.tool.kind).toBe("none");
});

test("notifications: a building with no road is reported, stacks without repeating, and a click takes the camera there", () => {
  const { rig, hud, state } = townScene();
  const lonely = put(state, "sawmill", 9, 6);
  runDays(state, 2);
  game.step(30);
  const texts = () => [0, 1, 2, 3, 4].filter((i) => shown(`notice_${i}`)).map((i) => textOf(`notice_${i}`));
  expect(texts().some((t) => t.includes("Sawmill has no road"))).toBe(true);
  const countBefore = hud.notices.items.length;
  runDays(state, 1);
  game.step(5);
  expect(hud.notices.items.filter((n) => n.key === "noRoad" && n.building === lonely.id)).toHaveLength(1); // no duplicates
  expect(hud.notices.items.length).toBeGreaterThanOrEqual(countBefore);
  // the stack sits in the top-left corner, clear of the bar and the right column
  const slot = [0, 1, 2, 3, 4].find((i) => shown(`notice_${i}`) && textOf(`notice_${i}`).includes("Sawmill"));
  const r = ui.rectOf(`notice_${slot}`);
  expect(r.x).toBeLessThan(40);
  expect(r.y).toBeGreaterThanOrEqual(84); // below the top bar and the Orders button
  // click: the camera goes to the building and it is selected
  const [wx, wy] = cellToWorld(9, 6);
  rig.setView(0, 0, 1);
  game.step(2);
  game.click(`notice_${slot}`);
  expect(hud.sel).toEqual({ kind: "building", id: lonely.id });
  game.step(30); // the camera eases over a third of a second (instant with the reduced motion option, tests/options.test.js)
  expect(Math.abs(rig.view.x - wx)).toBeLessThan(80);
  expect(Math.abs(rig.view.y - wy)).toBeLessThan(80);
  expect(texts().some((t) => t.includes("Sawmill"))).toBe(false); // the message is taken away
  // a message fades away by itself
  hud.notices.push("broke", {}, null, 0, "bad");
  game.step(5);
  const broke = () => texts().some((t) => t.includes("Not enough coins"));
  expect(broke()).toBe(true);
  game.step(60 * 20);
  expect(broke()).toBe(false);
});
