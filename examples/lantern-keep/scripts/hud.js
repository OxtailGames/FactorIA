// @ts-check
// The HUD of a level: its name (a string-table key, so it follows the language), the timer and the embers found.
// Reads the level's rules from the "level" entity (scripts/level.js). The timer and the ember count are built here, so
// they are written again when the language changes; the level name is a Text with a `key`, which the engine translates.
import { Behaviour, i18n } from "factoria";
import { formatTime } from "./time_format.js";
import { find, EMBERS_PER_LEVEL } from "./levels.js";

export default class Hud extends Behaviour {
  onStart() {
    this.level = this.world.find("level").behaviour;
    this.title = this.world.find("hud_level").get("Text");
    this.timer = this.world.find("hud_timer").get("Text");
    this.embers = this.world.find("hud_embers").get("Text");
    const info = find(this.level.levelId);
    if (info) this.title.key = info.nameKey;
    this.shown = { time: "", found: -1 };
    i18n.on("change", () => (this.shown = { time: "", found: -1 })); // write the built texts again in the new language
  }

  onUpdate() {
    const time = formatTime(this.level.time);
    if (time !== this.shown.time) {
      this.shown.time = time;
      this.timer.text = i18n.t("hud.time", { time });
    }
    if (this.level.found !== this.shown.found) {
      this.shown.found = this.level.found;
      this.embers.text = i18n.t("hud.embers", { found: this.level.found, total: EMBERS_PER_LEVEL });
    }
  }
}
