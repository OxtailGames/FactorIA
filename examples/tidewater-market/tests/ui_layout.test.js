// The bars at 1280x720 (P3): the top bar, the date, the speed buttons, the right column, the status line and the inspector never overlap
// and stay on screen, with huge numbers and with larger text. The stress town is the busy case.
import { test, expect, game } from "factoria:test";
import { ui } from "factoria";
import { townScene, overlaps, cellAt, shown } from "./ui_helper.js";

// hud_bar is the full-width strip; the date and the speed buttons sit on it, so it is checked through its items instead
const BARS = ["hud_date", "speed_bar", "palette", "status_bar"];

/** The numbers of the top bar (coins, villagers, goods) must end before the date starts, and not run into each other. */
function expectBarItems(state) {
  const items = ["coins_text", "pop_text", ...state.data.goodIds.map((g) => `good_${g}_text`)].filter((id) => shown(id)); // goods that did not fit are hidden (ui_hud fitTopBar), the goods table has them
  expect(items).toContain("coins_text");
  expect(items).toContain("pop_text");
  const rects = items.map((id) => ({ id, r: ui.rectOf(id) }));
  const date = ui.rectOf("hud_date");
  for (const { id, r } of rects) {
    if (r.x + r.w > date.x) throw new Error(`${id} runs into the date: ${JSON.stringify(r)} vs ${JSON.stringify(date)}`);
  }
  for (let i = 0; i < rects.length; i++) {
    for (let j = i + 1; j < rects.length; j++) {
      if (overlaps(rects[i].id, rects[j].id)) throw new Error(`${rects[i].id} overlaps ${rects[j].id}`);
    }
  }
}

function expectClear(ids) {
  for (const id of ids) {
    const r = ui.rectOf(id);
    expect(r).toBeTruthy();
    expect(r.x).toBeGreaterThanOrEqual(0);
    expect(r.y).toBeGreaterThanOrEqual(0);
    expect(r.x + r.w).toBeLessThanOrEqual(1280);
    expect(r.y + r.h).toBeLessThanOrEqual(720);
  }
  for (let i = 0; i < ids.length; i++) {
    for (let j = i + 1; j < ids.length; j++) {
      if (overlaps(ids[i], ids[j])) throw new Error(`${ids[i]} overlaps ${ids[j]}: ${JSON.stringify(ui.rectOf(ids[i]))} ${JSON.stringify(ui.rectOf(ids[j]))}`);
    }
  }
}

test("top bar, date, speed buttons, right column and status line do not overlap with huge numbers", () => {
  const { state, hud, rig, ids } = townScene();
  state.economy.apply(Object.fromEntries([["coins", 987000000], ...state.data.goodIds.map((g) => [g, 99999])]), "test");
  game.step(30);
  expectClear(BARS);
  expectBarItems(state);
  // with the inspector, the goods table and the build menu open as well
  game.click(cellAt(rig, 5, 3));
  game.click("btn_build");
  game.step(20);
  expect(hud.sel.id).toBe(ids.farm);
  expectClear([...BARS, "inspector", "build_bar"]);
  game.click("btn_goods");
  game.step(5);
  expectClear([...BARS, "inspector", "build_bar", "goods_panel"].filter((id) => id !== "inspector"));
});

test("the same with the text size at 150 %", () => {
  const { state } = townScene();
  state.economy.apply(Object.fromEntries([["coins", 987000000], ...state.data.goodIds.map((g) => [g, 99999])]), "test");
  const before = ui.textScale;
  ui.textScale = 1.5;
  game.step(30);
  try {
    expectClear(BARS);
    expectBarItems(state);
  } finally {
    ui.textScale = before;
  }
});
