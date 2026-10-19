// @ts-check
// The credits panel: the game's own lines, then the software inside the FactorIA runtime (game.notices(), the
// parts whose licenses FACTORIA_NOTICES.txt holds next to the exported game). ui_up/ui_down scroll the list.
import { Behaviour, game, input, ui, i18n } from "factoria";
import { fitWidgets } from "./text_fit.js";

export default class Credits extends Behaviour {
  /** String-table keys of the lines shown after the game's name (factoria.json "name") and before the engine's notices. */
  lines = ["credits.lanternKeep", "credits.madeWith"];
  /** Scroll speed of ui_up/ui_down in pixels per second. */
  scrollSpeed = 500;

  onStart() {
    this.list = this.world.find("credits_list");
    this.texts = [];
    const text = (s, fontSize = 22, color = [1, 1, 1, 1], key = "") => {
      const entity = this.world.spawn({ components: { Text: { text: s, key, fontSize, color, space: "screen", maxWidth: 680, layer: 302 } } }, { parent: this.list });
      this.texts.push(entity.get("Text"));
      return entity;
    };
    // A Text with a key is translated by the engine, also when the player changes the language while the credits are open.
    const keyed = (key, fontSize, color) => text(key, fontSize, color, key);
    text(game.project.name, 34);
    for (const key of this.lines) keyed(key, 26);
    keyed("credits.software", 22, [0.75, 0.8, 0.9, 1]);
    for (const n of game.notices()) text(`${n.name}  (${n.license})\n${n.usedFor}\n${n.url}`, 20);
    keyed("credits.licenses", 18, [0.75, 0.8, 0.9, 1]);
    this.layout();
    i18n.on("change", () => fitWidgets(this.entity));
  }

  /** At a big text size the panel is wider (like Options), so a long line such as a URL still fits the list. */
  layout() {
    this.scale = ui.textScale;
    const width = Math.min(1240, Math.round(760 + (this.scale - 1) * 480));
    this.entity.get("Panel").size = [width, 620];
    this.list.get("ScrollList").size = [width - 48, 476];
    for (const t of this.texts) t.maxWidth = width - 48 - 32 - 24; // list padding and the scroll bar
    fitWidgets(this.entity);
  }

  onUpdate(dt) {
    if (!this.entity.active) return;
    if (this.scale !== ui.textScale) this.layout();
    this.list.get("ScrollList").scroll += input.axis("ui_up", "ui_down") * this.scrollSpeed * dt;
  }
}
