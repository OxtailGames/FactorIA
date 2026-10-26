// The bars at 1280x720 (P3): the top bar, the date, the speed buttons, the right column, the status line and the inspector never overlap
// and stay on screen, with huge numbers and with larger text. The stress town is the busy case.
import { test, expect, game } from "factoria:test";
import { ui } from "factoria";
import { townScene, overlaps, cellAt, shown } from "./ui_helper.js";
import * as settings from "../scripts/settings.js";

// hud_bar is the full-width strip; the date and the speed buttons sit on it, so it is checked through its items instead
const BARS = ["hud_date", "speed_bar", "palette", "status_bar", "btn_orders"];

/** The numbers of the top bar (coins, villagers, goods) must end before the date starts, and not run into each other. */
function expectBarItems(state) {
  const items = ["coins_text", "pop_text", "rep_text", ...state.data.goodIds.map((g) => `good_${g}_text`)].filter((id) => shown(id)); // goods that did not fit are hidden (ui_hud fitTopBar), the goods table has them
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
  const { state, hud, rig, ids } = townScene({ trade: true });
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
  const { state } = townScene({ trade: true });
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

/** Put the accessibility sizes into effect, run `body`, and put the defaults back (the settings live in `session`, past a test). */
function withSizes(text, scale, body) {
  const before = settings.load();
  settings.apply({ ...before, textScale: text, uiScale: scale });
  try {
    body();
  } finally {
    settings.apply({ ...before, textScale: 1, uiScale: 1 });
  }
}

test("150 % text with the inspector and the build menu open: nothing overlaps and the inspector stays off the right-hand column", () => {
  const { state, hud, rig, ids } = townScene({ trade: true });
  state.economy.apply(Object.fromEntries([["coins", 987000000], ...state.data.goodIds.map((g) => [g, 99999])]), "test");
  withSizes(1.5, 1, () => {
    game.click(cellAt(rig, 5, 3));
    game.click("btn_build");
    game.step(30);
    expect(hud.sel.id).toBe(ids.farm);
    expectClear([...BARS, "inspector", "build_bar"]);
    expectBarItems(state);
  });
});

// The text size and the interface size multiply (ui.scale is the layout, ui.textScale the fonts on top): the biggest of both at once
// is more than a 1280 x 720 screen holds with this much information, so the interface size stops at 125 % (settings.UI_SCALES) and is tested with up to 125 % text; the text alone is tested up to 150 % above.
for (const [text, scale] of [[1.25, 1.25], [1, 1.25]]) test(`interface size ${scale * 100} % with ${text * 100} % text: the inspector, the build menu and the goods table`, () => {
  const { state, hud, rig, ids } = townScene({ trade: true });
  state.economy.apply(Object.fromEntries([["coins", 987000000], ...state.data.goodIds.map((g) => [g, 99999])]), "test");
  withSizes(text, scale, () => {
    game.click(cellAt(rig, 5, 3));
    game.click("btn_build");
    game.step(30);
    expect(hud.sel.id).toBe(ids.farm);
    expectClear([...BARS, "inspector", "build_bar"]);
    expectBarItems(state);
    // every button of the inspector is on screen
    for (const id of ["insp_rotate", "insp_demolish", "insp_close"]) expect(shown(id)).toBe(true);
    game.click("btn_goods");
    game.step(10);
    expectClear([...BARS, "build_bar", "goods_panel"]);
  });
});
