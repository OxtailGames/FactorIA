// @ts-check
// The level select (prefabs/ui/level_select.prefab.json): both worlds, each level with its name, open or locked, embers
// and best time. Opened after a slot is chosen, and by the level end panel's Menu button.
import { Behaviour, ui, i18n, world } from "factoria";
import { LEVELS, EMBERS_PER_LEVEL } from "../levels.js";
import * as progress from "../progress.js";
import { startLevel } from "../flow.js";
import { formatTime } from "../time_format.js";

/** The design size of a level button in the prefab (autoSize makes each one at least this big). */
const design = [320, 84];

export default class LevelSelect extends Behaviour {
  onStart() {
    for (const level of LEVELS) ui.on("click", `lvl_${level.id}`, () => progress.isUnlocked(level.id) && startLevel(level.id));
    i18n.on("change", refreshSelect);
  }

  onEnable() {
    refreshSelect();
  }
}

/** Writes the level buttons from progress. */
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
  layoutSelect();
}

/**
 * The six buttons are as wide as the widest label needs (the same for all: autoSize only grows a button to its own label,
 * so the common size is written as their design size). The panels switch between rows and columns by themselves
 * (`fallbackLayout` in the prefab): a world's three levels are a row while that fits the screen, then a column, and the
 * worlds then stand side by side.
 */
function layoutSelect() {
  const buttons = LEVELS.map((l) => world.find(`lvl_${l.id}`).get("Button"));
  const labels = buttons.map((b) => ui.measureText(b.text, { fontSize: b.fontSize }));
  const width = Math.max(design[0], ...labels.map((m) => Math.ceil(m.width + 40))); // 20 px of margin on each side
  const height = Math.max(design[1], ...labels.map((m) => Math.ceil(m.height + 16)));
  for (const b of buttons) b.size = [width, height];
}
