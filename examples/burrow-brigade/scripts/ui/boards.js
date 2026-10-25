// @ts-check
// The boards screen (the `boards` panel of scenes/menu.scene.json, opened by the title's Boards button): three tabs, each a list
// in the ScrollList `boards_list`:
//   All time    the best run cash of every player (scripts/game/boards.js, board "best_run_cash")
//   Daily dig   the best of today's daily dig (board "daily_run_cash")
//   Trophies    the achievements with their icon and progress, then the player's four numbers (scripts/game/trophies.js)
// Everything works with a pad: the tabs and Back take the focus, ui_up / ui_down scroll the list, ui_cancel goes back. The data
// is asked for each time the panel opens; an answer that arrives after the panel closed (or after the scene changed) is dropped.
import { Behaviour, ui, input, world, i18n, platform, game } from "factoria";
import * as boards from "../game/boards.js";
import * as trophies from "../game/trophies.js";

export const TABS = ["alltime", "daily", "trophies"];
const TAB_COLOR = [0.16, 0.18, 0.24, 0.92];
const TAB_SELECTED = [0.3, 0.36, 0.52, 0.96];
const YOU = [1, 0.92, 0.55, 1];
const DIM = [0.62, 0.64, 0.7, 1];

export default class BoardsScreen extends Behaviour {
  runWhilePaused = true;
  /** Scroll speed of ui_up / ui_down in pixels per second. */
  scrollSpeed = 500;

  onStart() {
    this.tab = "alltime";
    this.ticket = 0;
    for (const tab of TABS) ui.on("click", `tab_${tab}`, () => this.show(tab));
    i18n.on("change", () => this.entity.alive && this.entity.active && this.show(this.tab));
  }

  onEnable() {
    this.show(this.tab);
  }

  onDisable() {
    this.ticket++; // whatever is still on its way is no longer wanted
  }

  /** What the panel shows now: [tab, number of rows] (a test reads it). */
  get shown() {
    return { tab: this.tab, rows: this.rows ?? 0, note: this.note ?? "" };
  }

  /** @param {"alltime"|"daily"|"trophies"} tab */
  show(tab) {
    this.tab = tab;
    for (const t of TABS) world.find(`tab_${t}`).get("Button").color = t === tab ? TAB_SELECTED : TAB_COLOR;
    const ticket = ++this.ticket;
    this.clear();
    this.setNote(i18n.t("boards.loading"));
    const work = tab === "trophies" ? this.loadTrophies(ticket) : this.loadBoard(tab, ticket);
    work.catch((e) => {
      if (this.current(ticket)) this.setNote(i18n.t("boards.unavailable"));
      console.warn(`boards screen: ${e && e.message ? e.message : e}`);
    });
  }

  /** True while `ticket` is the newest request and this panel is still open in its scene. */
  current(ticket) {
    return ticket === this.ticket && this.entity.alive && this.entity.active;
  }

  get list() {
    return world.find("boards_list");
  }

  clear() {
    for (const c of [...this.list.children]) c.destroy();
    this.rows = 0;
    this.list.get("ScrollList").scroll = 0;
  }

  setNote(text) {
    this.note = text;
    world.find("boards_note").get("Text").text = text;
  }

  line(text, color = [1, 1, 1, 1], fontSize = 24) {
    this.rows = (this.rows ?? 0) + 1;
    return world.spawn({ components: { Text: { text, fontSize, color, space: "screen", maxWidth: 760, layer: 302 } } }, { parent: this.list });
  }

  /** @param {"alltime"|"daily"} tab */
  async loadBoard(tab, ticket) {
    if (!platform.has("leaderboards")) return this.setNote(i18n.t("boards.unavailable"));
    const id = tab === "daily" ? boards.BOARDS.daily : boards.BOARDS.allTime;
    const rows = await boards.top(id, 10);
    if (!this.current(ticket)) return;
    for (const r of rows) {
      const name = r.isPlayer ? `${r.name} (${i18n.t("boards.you")})` : r.name;
      this.line(`${i18n.t("boards.row", { rank: r.rank, name })}   ${i18n.number(r.score)}`, r.isPlayer ? YOU : [1, 1, 1, 1]);
    }
    this.setNote(rows.length ? (tab === "daily" ? i18n.t("boards.dailyNote", { date: game.today().iso }) : "") : i18n.t("boards.empty"));
  }

  async loadTrophies(ticket) {
    const list = await trophies.list();
    const stats = await trophies.statValues();
    if (!this.current(ticket)) return;
    if (!list.length) return this.setNote(i18n.t("boards.unavailable"));
    for (const a of list) {
      this.rows = (this.rows ?? 0) + 1;
      const row = world.spawn({ components: { Panel: { size: [760, 56], layout: "row", spacing: 14, color: [0, 0, 0, 0], layer: 302, align: "center" } } }, { parent: this.list });
      world.spawn({ components: { Panel: { size: [48, 48], texture: a.icon, slice: [0, 0, 0, 0], color: a.unlocked ? [1, 1, 1, 1] : [0.35, 0.35, 0.4, 0.9], layer: 303 } } }, { parent: row });
      const progress = a.progress && !a.unlocked ? `   ${i18n.t("boards.progress", { value: a.progress.value, goal: a.progress.goal })}` : "";
      const state = a.unlocked ? "" : `   (${i18n.t("boards.locked")})`;
      world.spawn(
        { components: { Text: { text: `${a.name}${state}\n${a.description}${progress}`, fontSize: 20, color: a.unlocked ? [1, 1, 1, 1] : DIM, space: "screen", maxWidth: 680, layer: 303 } } },
        { parent: row },
      );
    }
    this.line(i18n.t("boards.numbers"), [0.75, 0.8, 0.9, 1], 22);
    for (const s of stats) this.line(`${s.label}: ${i18n.number(s.value)}`, [1, 1, 1, 1], 22);
    this.setNote("");
  }

  onUpdate(dt) {
    if (!this.entity.active) return;
    this.list.get("ScrollList").scroll += input.axis("ui_up", "ui_down") * this.scrollSpeed * dt;
  }
}
