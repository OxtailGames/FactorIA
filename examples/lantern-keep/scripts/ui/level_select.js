// @ts-check
// The level select (prefabs/ui/level_select.prefab.json): both worlds, each level with its name, open or locked, embers
// and best time. Opened after a slot is chosen, and by the level end panel's Menu button.
import { Behaviour, ui, i18n, world } from "factoria";
import { LEVELS, EMBERS_PER_LEVEL } from "../levels.js";
import * as progress from "../progress.js";
import { startLevel } from "../flow.js";
import { formatTime } from "../time_format.js";
import { fitWidgets } from "./text_fit.js";

export default class LevelSelect extends Behaviour {
  onStart() {
    for (const level of LEVELS) ui.on("click", `lvl_${level.id}`, () => progress.isUnlocked(level.id) && startLevel(level.id));
    i18n.on("change", refreshSelect);
    refreshSelect();
  }
}

/** Writes the level buttons from progress (the screen is inactive until shown, so this is a function, not a method). */
export function refreshSelect() {
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
  layoutSelect();
}

/**
 * The six buttons are as wide as the widest text needs (the same for all). Three of them side by side while that fits the
 * screen; at a big text size or with long names the worlds stand side by side instead and each world's levels are a column.
 */
function layoutSelect() {
  const root = world.find("level_select");
  const sets = (id, layout) => (world.find(id).get("Panel").layout = layout);
  for (const id of ["select_row_1", "select_row_2"]) sets(id, "row");
  sets("select_worlds", "column");
  fitWidgets(root);
  const buttons = LEVELS.map((l) => world.find(`lvl_${l.id}`).get("Button"));
  const width = Math.max(...buttons.map((b) => b.size.x));
  const height = Math.max(...buttons.map((b) => b.size.y));
  for (const b of buttons) b.size = [width, height];
  if (3 * width + 2 * 12 + 2 * 24 > 1240) {
    for (const id of ["select_row_1", "select_row_2"]) sets(id, "column");
    sets("select_worlds", "row");
  }
}
