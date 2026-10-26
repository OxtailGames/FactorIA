// Every screen in every language at 100 % and 200 % text: nothing cut, nothing off screen, nothing on top of anything else (P8).
// The screens are opened the way a player opens them (clicks and keys), then layoutProblems() asks the questions of ui.check_layout.
// Each check switches the language while the screen is open, so it also proves the screen redraws in the new language.
import { test, expect, game } from "factoria:test";
import { scene, storage, session } from "factoria";
import { townScene, cellAt } from "./ui_helper.js";
import { layoutProblems, inLanguage, LANGUAGES } from "./layout_helper.js";
import { growTown } from "../scripts/game/bot.js";
import { getData } from "../scripts/game/data.js";
import { newScenarioGame, GoalTracker } from "../scripts/game/scenarios.js";
import { writeEntry } from "../scripts/game/save_store.js";
import { rich, put } from "./town_helper.js";

const MENU = "scenes/menu.scene.json";
const GAME = "scenes/game.scene.json";
const SCALES = [1, 2];

/** Run `open()` (which leaves one screen open), check it in every language and scale, and fail with every problem found. */
function checkScreen(name, open, { languages = LANGUAGES, scales = SCALES, ignore = [], only = "" } = {}) {
  const found = [];
  for (const language of languages) {
    for (const scale of scales) {
      inLanguage(language, scale, () => {
        open();
        game.step(3);
        for (const line of layoutProblems({ ignore: ["tooltip_", ...ignore], only })) found.push(`[${language} ${scale * 100}%] ${line}`);
      });
    }
  }
  if (found.length) throw new Error(`${name}: ${found.length} layout problem(s):\n  ${found.join("\n  ")}`);
}

const click = (id) => {
  game.click(id);
  game.step(2);
};
const isOpen = (id) => !!game.find(id) && game.find(id).activeInHierarchy;

function openTitle() {
  storage.clear();
  game.platform.reset();
  game.load(MENU);
  game.step(3);
  expect(scene.current).toBe(MENU);
}

function seedSlots() {
  const first = newScenarioGame("first_harbour", getData());
  const tracker = new GoalTracker(first.state, "first_harbour", first.def).attach();
  growTown({ state: first.state, days: 20 });
  const info = { scenario: "first_harbour", extra: tracker.saveFields(), progress: tracker.metaFields() };
  writeEntry(1, "manual", first.state, { ...info, name: "Old harbour", playSeconds: 7540 });
  writeEntry(1, "auto", first.state, { ...info, playSeconds: 7600 });
  const river = newScenarioGame("river_mills", getData());
  growTown({ state: river.state, days: 10 });
  writeEntry(3, "manual", river.state, { scenario: "river_mills", name: "Mill town", playSeconds: 120 });
}

/** The game scene with the working town, big numbers and the trade on. */
function bigTown() {
  const t = townScene({ trade: true });
  t.state.economy.apply(Object.fromEntries([["coins", 987000000], ...t.state.data.goodIds.map((g) => [g, 99999])]), "test");
  return t;
}

test("title screen and credits", () => {
  openTitle();
  checkScreen("title", () => {});
  click("credits_button");
  checkScreen("credits", () => {});
});

test("save slots: filled slots, an empty one, the scenario list", () => {
  openTitle();
  seedSlots();
  click("play");
  checkScreen("slots", () => {});
  click("slot_2_main"); // the empty slot: which scenario?
  expect(isOpen("scenario_panel")).toBe(true);
  checkScreen("scenario list", () => {});
});

test("options: every tab", () => {
  openTitle();
  click("options_button");
  for (const tab of ["video", "audio", "controls", "access", "language"]) {
    click(`tab_${tab}`);
    checkScreen(`options ${tab}`, () => {});
  }
});

test("game screen: top bar, build menu and inspector open", () => {
  const { rig, hud, ids } = bigTown();
  game.click(cellAt(rig, 5, 3));
  click("btn_build");
  game.step(20);
  expect(hud.sel.id).toBe(ids.farm);
  checkScreen("hud", () => {});
});

test("game screen: goods table, charts and help", () => {
  bigTown();
  for (const [button, panel] of [["btn_goods", "goods_panel"], ["btn_charts", "charts_panel"], ["btn_help", "help_panel"]]) {
    click(button);
    expect(isOpen(panel)).toBe(true);
    checkScreen(panel, () => {});
    click(button);
  }
});

test("game screen: notifications", () => {
  const { hud } = bigTown();
  hud.notices.push("noRoad", { name: "Sawmill" }, null, 0, "warn");
  hud.notices.push("noInput", { name: "Bakery", goodName: "smoked fish" }, null, 0, "warn");
  hud.notices.push("storageFull", { goodName: "planks" }, null, 0, "warn");
  hud.notices.push("hungry", { count: 123456 }, null, 0, "bad");
  hud.notices.push("broke", {}, null, 0, "bad");
  checkScreen("notices", () => game.step(1));
});

test("order board and event/story cards", () => {
  const { state } = townScene({ trade: true });
  rich(state);
  put(state, "pier", 4, 1);
  const trade = state.trade;
  let guard = 0;
  while (!trade.ships.some((s) => s.state === "docked") && guard++ < 20 * state.clock.ticksPerDay) state.clock.tick(state.clock.step);
  while (trade.card) {
    // a card of the season may wait: answer it before the board
    trade.choose(trade.cardDef(trade.card).def.choices[0].id);
    trade.dismiss();
  }
  game.step(3);
  click("btn_orders");
  expect(isOpen("board_close")).toBe(true);
  checkScreen("order board", () => {}, { ignore: ["notice_"] });
  click("board_close");

  const data = trade.data;
  const refs = [
    ...Object.keys(data.events.events).map((id) => ({ kind: "event", id })),
    ...Object.entries(data.story.scenarios).flatMap(([sc, list]) => list.map((c) => ({ kind: "story", id: c.id, scenario: sc }))),
  ];
  expect(refs.length).toBeGreaterThan(10);
  for (const ref of refs) {
    if (ref.scenario) {
      trade.scenario = ref.scenario;
      trade.cards = data.story.scenarios[ref.scenario];
    }
    trade.enqueue({ kind: ref.kind, id: ref.id });
    game.step(3);
    if (!trade.card || trade.card.id !== ref.id) continue;
    checkScreen(`card ${ref.id} (choose)`, () => {}, { ignore: ["notice_"] });
    const { def } = trade.cardDef(trade.card);
    trade.choose(def.choices[0].id);
    game.step(3);
    checkScreen(`card ${ref.id} (result)`, () => {}, { ignore: ["notice_"] });
    trade.dismiss();
    game.step(2);
  }
});

function scenarioGame(boot) {
  storage.clear();
  game.platform.reset();
  session.boot = boot;
  game.load(GAME);
  game.step(3);
  expect(scene.current).toBe(GAME);
  return game.find("controller").behaviour;
}

test("goal panel and win screen", () => {
  const ctl = scenarioGame({ slot: 1, scenario: "first_harbour", name: "First Harbour" });
  expect(isOpen("goal_panel")).toBe(true);
  checkScreen("goal panel", () => game.step(1));
  const tracker = ctl.run.tracker;
  tracker.goals = tracker.goals.map((g) => ({ ...g, target: 0 }));
  ctl.state.clock.setSpeed(2);
  tracker.check();
  game.step(3);
  expect(isOpen("win_screen")).toBe(true);
  checkScreen("win screen", () => {}, { only: "win_screen" });
});

test("pause menu", () => {
  bigTown();
  game.press("pause");
  game.step(1);
  game.release("pause");
  game.step(2);
  expect(isOpen("pause_panel")).toBe(true);
  checkScreen("pause", () => {}, { only: "pause_panel" });
});

