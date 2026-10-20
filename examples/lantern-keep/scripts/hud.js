// @ts-check
// The HUD of a level: its name (a string-table key, so it follows the language), the timer and the embers found.
// Reads the level's rules from the "level" entity (scripts/level.js). The timer and the ember count are built here, so
// they are written again when the language changes; the level name is a Text with a `key`, which the engine translates.
import { Behaviour, i18n, ui, game } from "factoria";
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
    this.bar = this.world.find("hud_bar").get("Shape2D");
    this.age = 0;
    this.dirty = true; // lay the HUD out again: a new text size or language changes the widths
    this.scaleSeen = ui.textScale;
    i18n.on("change", () => {
      this.shown = { time: "", found: -1 }; // write the built texts again in the new language
      this.dirty = true;
    });
  }

  /**
   * At a big text size the name, timer and embers no longer fit side by side: the timer moves to a second row. Each text
   * is measured at its own size; the bar behind them follows.
   */
  layout() {
    const measure = (text, shown = text.text) => ui.measureText(shown, { fontSize: text.fontSize }).width;
    const widestTimer = i18n.t("hud.time", { time: "0:00.00" }); // a layout that does not flip as the digits grow
    const screenW = game.screenSize.x;
    // The timer is centred: the name must end before it starts and the embers must start after it ends.
    const half = measure(this.timer, widestTimer) / 2;
    const sideBySide = 24 + measure(this.title) + 24 <= screenW / 2 - half && 24 + measure(this.embers) + 24 <= screenW / 2 - half;
    const rowHeight = Math.ceil(28 * ui.textScale * 1.3);
    this.world.find("hud_timer").position.y = 10 + (sideBySide ? 0 : rowHeight);
    this.bar.size = [screenW, 20 + rowHeight * (sideBySide ? 1 : 2)];
    this.mirror();
  }

  /** Arabic reads from the right: the level name goes to the right corner and the embers to the left one (anchors are not mirrored by the engine). */
  mirror() {
    const rtl = i18n.direction === "rtl";
    const put = (id, right, align) => {
      const entity = this.world.find(id);
      const text = entity.get("Text");
      text.anchor = [right ? 1 : 0, 0];
      text.pivot = [right ? 1 : 0, 1];
      text.align = align; // `start` is the side where the language begins, `end` the other
      entity.position.x = right ? -24 : 24;
    };
    put("hud_level", rtl, "start");
    put("hud_embers", !rtl, "end");
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
    if (++this.age === 3) this.dirty = true; // the engine has written the translated level name by now
    if (this.scaleSeen !== ui.textScale) {
      this.scaleSeen = ui.textScale;
      this.dirty = true;
    }
    if (this.dirty) {
      this.dirty = false;
      this.layout(); // after the texts above were written: the widths are the new ones
    }
  }
}
