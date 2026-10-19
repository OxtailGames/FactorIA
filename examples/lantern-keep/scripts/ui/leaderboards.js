// @ts-check
// The leaderboards panel of the main menu (prefabs/ui/leaderboards.prefab.json): the best times of one board at a time
// (a level, or the total of all six), the top entries, the entries around the player or among friends, and the
// player's own best. Board and Show cycle with A. Without a store, when the player is not signed in or the request fails,
// it says so.
import { Behaviour, ui, platform, i18n } from "factoria";
import { LEVELS } from "../levels.js";
import { boardOf, TOTAL_BOARD } from "../store_stats.js";
import { formatTime } from "../time_format.js";
import { explain, trySignIn } from "./store_ui.js";

/** The boards in the order Board cycles through them: each level, then the total. */
const BOARDS = [...LEVELS.map((l) => ({ id: boardOf(l.id), nameKey: l.nameKey })), { id: TOTAL_BOARD, nameKey: "leaderboards.total" }];
const RANGES = ["top", "around", "friends"];
/** Entries shown (the panel's list fits this many). */
const COUNT = 8;
const GOLD = [1, 0.85, 0.4, 1];

export default class Leaderboards extends Behaviour {
  rows = [];
  board = 0; // index in BOARDS
  range = 0; // index in RANGES
  entries = null;
  problem = null;
  loads = 0;

  onStart() {
    ui.on("click", "lb_board", () => {
      this.board = (this.board + 1) % BOARDS.length;
      this.load(false);
    });
    ui.on("click", "lb_range", () => {
      this.range = (this.range + 1) % RANGES.length;
      this.load(false);
    });
    ui.on("click", "lb_refresh", () => this.load(true));
    this.opened(); // the first time the panel is shown its script starts now; later the main menu calls opened()
    i18n.on("change", () => this.render());
  }

  /** The main menu calls this each time it shows the panel again (a hidden panel's scripts do not run): ask the store again. */
  opened() {
    this.load(false);
  }

  get list() {
    return this.world.find("lb_list");
  }

  /** Writes a line of text; an empty one is hidden (it would still take room in the column). */
  write(id, message) {
    const line = this.world.find(id);
    line.get("Text").text = message;
    line.active = message !== "";
  }

  async load(signIn) {
    const mine = ++this.loads;
    this.problem = null;
    this.entries = null;
    if (platform.has("leaderboards")) {
      this.write("lb_status", i18n.t("platform.loading"));
      try {
        if (signIn) await trySignIn();
        const entries = await platform.leaderboards.entries(BOARDS[this.board].id, { range: RANGES[this.range], count: COUNT });
        if (mine === this.loads) this.entries = entries;
      } catch (e) {
        if (mine === this.loads) this.problem = e;
      }
    }
    if (mine === this.loads) this.render();
  }

  render() {
    for (const row of this.rows) row.destroy();
    this.rows = [];
    const board = BOARDS[this.board];
    this.world.find("lb_board").get("Button").text = i18n.t("leaderboards.board", { board: i18n.t(board.nameKey) });
    this.world.find("lb_range").get("Button").text = i18n.t("leaderboards.show", { range: i18n.t(`leaderboards.range.${RANGES[this.range]}`) });
    const message = explain("leaderboards", "leaderboards.what", this.problem);
    const entries = message ? null : this.entries;
    const own = entries?.find((e) => e.isPlayer);
    this.write("lb_own", own ? i18n.t("leaderboards.yourBest", { time: formatTime(own.score / 1000), rank: own.rank }) : "");
    this.write("lb_status", message || (entries && entries.length === 0 ? i18n.t("leaderboards.empty") : ""));
    for (const e of entries ?? []) {
      const line = i18n.t("leaderboards.entry", { rank: e.rank, name: e.name, time: formatTime(e.score / 1000) });
      this.rows.push(
        this.world.spawn(
          { components: { Text: { text: e.isPlayer ? `${line}  <` : line, fontSize: 24, color: e.isPlayer ? GOLD : [1, 1, 1, 1], space: "screen", maxWidth: 700, layer: 302 } } },
          { parent: this.list },
        ),
      );
    }
  }
}
