// @ts-check
// The level select (prefabs/ui/level_select.prefab.json): both worlds, each level with its name, open or locked, embers
// and best time. Opened after a slot is chosen, and by the level end panel's Menu button.
import { Behaviour, ui, i18n, world } from "factoria";
import { LEVELS, EMBERS_PER_LEVEL } from "../levels.js";
import * as progress from "../progress.js";
import { startLevel } from "../flow.js";
import { formatTime } from "../time_format.js";

export default class LevelSelect extends Behaviour {
  onStart() {
    for (const level of LEVELS) ui.on("click", `lvl_${level.id}`, () => progress.isUnlocked(level.id) && startLevel(level.id));
    i18n.on("change", refreshSelect);
  }

  onEnable() {
    refreshSelect();
  }
}

/**
 * Writes the level buttons from progress. The six buttons are as big as the widest label needs (`uniformSize` on
 * select_worlds) and the panels switch between rows and columns by themselves (`fallbackLayout`): a world's three levels
 * are a row while that fits the screen, then a column, and the worlds then stand side by side.
 */
function refreshSelect() {
  for (const level of LEVELS) {
    const r = progress.of(level.id);
    const open = progress.isUnlocked(level.id);
    const detail = !open
      ? i18n.t("select.locked")
      : r.completed
        ? i18n.t("select.result", { found: r.embers.filter(Boolean).length, total: EMBERS_PER_LEVEL, time: formatTime(r.bestTime ?? 0) })
        : i18n.t("select.open");
    const button = world.find(`lvl_${level.id}`).get("Button");
    button.text = `${i18n.t(level.nameKey)}\n${detail}`;
    button.interactable = open;
  }
}
