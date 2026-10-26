// @ts-check
// The goals of a scenario on the game screen: a small panel on the right under the menu column (the left side holds the Orders button and the notices) that lists
// each goal with its progress, a toast when one is reached, and the win screen when the last one is. The game controller creates it
// when the game has a goal tracker (a game started from a scenario or loaded from a save of one; the sandbox has no goals, so no
// panel). Pure display: it reads the tracker (scripts/game/scenarios.js) and never changes the simulation.
//
// Widget ids: goal_panel, goal_title, goal_row_<goal id>; win_screen, win_title, win_body, win_keep, win_menu.
import { world, ui, i18n, scene } from "factoria";
import { amountText, coinsText, dateText } from "../game/format.js";

const TEXT_COLOR = [1, 1, 1, 1];
const DONE_COLOR = [0.55, 0.9, 0.5, 1];

/** The sentence of a goal: "Have 25 villagers", "Make 120 fish in one season". */
export function goalText(goal) {
  switch (goal.kind) {
    case "population":
      return i18n.t("goal.population", { count: goal.target });
    case "coins":
      return i18n.t("goal.coins", { coins: coinsText(goal.target) });
    case "produced_in_season":
      return i18n.t("goal.produced_in_season", { amount: amountText({ [goal.good]: goal.target }) });
    default:
      return goal.id;
  }
}

export class GoalPanel {
  /** @param {any} controller the game controller (state, run, toast, setSpeed, autosaver, speedBeforePause) */
  constructor(controller) {
    this.controller = controller;
    this.tracker = controller.run.tracker;
    this.state = controller.state;
    this.off = /** @type {Array<() => void>} */ ([]);
    this.rows = /** @type {Record<string, any>} */ ({});
    this.panel = null;
    this.winScreen = null;
    this.buildWin();
    if (this.tracker.goals.length) this.buildPanel();
    const ev = this.state.events;
    this.off.push(
      ev.on("clock.day", () => this.refresh()),
      ev.on("goal.done", (e) => {
        this.controller.toast(i18n.t("goal.toast", { goal: goalText(e.goal) }));
        this.refresh();
      }),
      ev.on("scenario.won", () => this.win()),
      i18n.on("change", () => this.refresh()),
      ui.on("click", "win_keep", () => this.keepPlaying()),
      ui.on("click", "win_menu", () => this.toMenu()),
    );
    this.refresh();
  }

  buildPanel() {
    const rows = this.tracker.goals.map((goal) => ({
      id: `goal_row_${goal.id}`,
      components: { Text: { text: "", fontSize: 18, space: "screen", layer: 152, maxWidth: 360, maxTextScale: 1.25 } },
    }));
    this.panel = world.spawn({
      id: "goal_panel",
      components: {
        Transform: { position: [-8, 414, 0] },
        Panel: { anchor: [1, 0], pivot: [1, 1], layout: "column", align: "start", spacing: 6, fit: true, padding: [12, 10, 12, 12], color: [0.05, 0.07, 0.1, 0.78], layer: 150 },
      },
      children: [{ id: "goal_title", components: { Text: { text: "", fontSize: 20, space: "screen", layer: 152, maxTextScale: 1.25 } } }, ...rows],
    });
    for (const goal of this.tracker.goals) this.rows[goal.id] = world.find(`goal_row_${goal.id}`);
    this.placedAt = -1;
  }

  /**
   * Put the panel 10 px under the right-hand menu column, whatever the column's height (the text size and the language change it).
   * Called every frame by the game controller; it only moves the panel when the column's bottom edge moved.
   */
  place() {
    if (!this.panel) return;
    const column = world.find("palette");
    const rect = column && ui.rectOf(column);
    if (!rect) return;
    const top = Math.round(rect.y + rect.h + 10);
    if (top === this.placedAt) return;
    this.placedAt = top;
    this.panel.position = [-8, top, 0];
  }

  buildWin() {
    const text = (id, size) => ({ id, components: { Text: { text: "", fontSize: size, space: "screen", layer: 411, maxWidth: 520, align: "center", maxTextScale: 1.25 } } });
    const button = (id, extra = {}) => ({ id, components: { Button: { text: "", autoSize: true, fontSize: 24, layer: 412, maxTextScale: 1.5, ...extra } } });
    this.winScreen = world.spawn({
      id: "win_screen",
      components: { Panel: { size: [1280, 720], anchor: [0.5, 0.5], layer: 400, color: [0, 0, 0, 0.55], layout: "column", justify: "center" } },
      children: [
        {
          id: "win_box",
          components: { Panel: { layout: "column", align: "center", spacing: 14, padding: [36, 28, 36, 32], fit: true, layer: 410, color: [0.05, 0.07, 0.1, 0.96] } },
          children: [
            text("win_title", 40),
            text("win_body", 22),
            button("win_keep", { autoFocus: true }),
            button("win_menu"),
          ],
        },
      ],
    });
    this.winScreen.active = false;
  }

  /** Redraw the goal lines (called every game day and when a goal is done). */
  refresh() {
    if (this.panel) {
      world.find("goal_title").get("Text").text = i18n.t("goal.title");
      for (const { goal, value, done } of this.tracker.progress()) {
        const row = this.rows[goal.id];
        const tail = done ? i18n.t("goal.done") : i18n.t("goal.progress", { value, target: goal.target });
        row.get("Text").text = `${goalText(goal)}: ${tail}`;
        row.get("Text").color = done ? DONE_COLOR : TEXT_COLOR;
      }
    }
    if (this.winScreen) {
      if (this.wonOn) {
        // the win screen is written in the language of the moment: a language change while it is open redraws it
        const name = i18n.t(`scenario.${this.tracker.id}.name`);
        world.find("win_title").get("Text").text = i18n.t("goal.won.title", { scenario: name });
        world.find("win_body").get("Text").text = i18n.t("goal.won.body", { date: dateText(this.wonOn) });
      }
      world.find("win_keep").get("Button").text = i18n.t("goal.won.keep");
      world.find("win_menu").get("Button").text = i18n.t("goal.won.menu");
    }
  }

  win() {
    const c = this.controller;
    this.wonOn = this.state.clock.date();
    this.refresh();
    c.autosaver.pending = "won"; // the finished game is kept (progress.won is in the save), written at the end of the frame
    c.speedBeforePause = this.state.clock.speed || c.speedBeforePause;
    c.setSpeed(0);
    this.winScreen.active = true;
    ui.focus("win_keep");
  }

  keepPlaying() {
    if (!this.winScreen.active) return;
    this.winScreen.active = false;
    this.controller.setSpeed(this.controller.speedBeforePause || 1);
  }

  toMenu() {
    if (!this.winScreen.active) return;
    scene.load("scenes/menu.scene.json");
  }

  destroy() {
    for (const off of this.off) off();
    this.off = [];
    for (const e of [this.panel, this.winScreen]) if (e && e.alive) e.destroy();
  }
}
