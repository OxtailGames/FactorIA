// @ts-check
// The level end panel (prefabs/ui/level_end.prefab.json): time, best time, embers and deaths, then Next / Retry / Menu.
// level.js spawns it inactive and fills `result` (the level_completed payload) and `info` (what progress.record answered)
// before it shows it. The game is paused while it is open, hence runWhilePaused. The pad drives it: Next has the focus.
import { Behaviour, ui, i18n, world } from "factoria";
import { next, EMBERS_PER_LEVEL } from "../levels.js";
import { startLevel, openMenu } from "../flow.js";
import { formatTime } from "../time_format.js";

export default class LevelEnd extends Behaviour {
  runWhilePaused = true;
  /** The `level_completed` payload: { level, time, embers, deaths }. */
  result = null;
  /** What progress.record returned: { firstCompletion, newBest, bestTime, previousBest }. */
  info = null;

  /** Called by level.js when the exit is touched: fills the panel at once (onStart only runs a frame later) and shows it. */
  open(result, info) {
    this.result = result;
    this.info = info;
    world.find("end_next").active = next(result.level) !== null; // the last level has nothing after it
    this.refresh();
    this.entity.active = true;
  }

  onStart() {
    ui.on("click", "end_next", () => {
      const following = this.result ? next(this.result.level) : null;
      if (following) startLevel(following.id);
    });
    ui.on("click", "end_retry", () => this.result && startLevel(this.result.level));
    ui.on("click", "end_menu", () => openMenu());
    i18n.on("change", () => this.refresh()); // these lines are built here, not translated by the engine
  }

  refresh() {
    const r = this.result;
    if (!r) return;
    const text = (id, value) => (world.find(id).get("Text").text = value);
    text("end_time", i18n.t("levelEnd.time", { time: formatTime(r.time) }));
    text("end_best", i18n.t("levelEnd.best", { time: formatTime(this.info?.bestTime ?? r.time) }));
    text("end_embers", i18n.t("levelEnd.embers", { found: r.embers.filter(Boolean).length, total: EMBERS_PER_LEVEL }));
    text("end_deaths", i18n.t("levelEnd.deaths", { deaths: r.deaths }));
    world.find("end_new_best").active = !!this.info?.newBest;
  }
}
