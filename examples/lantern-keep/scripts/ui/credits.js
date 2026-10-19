// @ts-check
// The credits panel: the game's own lines, then the software inside the FactorIA runtime (game.notices(), the
// parts whose licenses FACTORIA_NOTICES.txt holds next to the exported game). ui_up/ui_down scroll the list.
import { Behaviour, game, input } from "factoria";

export default class Credits extends Behaviour {
  /** String-table keys of the lines shown after the game's name (factoria.json "name") and before the engine's notices. */
  lines = ["credits.lanternKeep", "credits.madeWith"];
  /** Scroll speed of ui_up/ui_down in pixels per second. */
  scrollSpeed = 500;

  onStart() {
    this.list = this.world.find("credits_list");
    const text = (s, fontSize = 22, color = [1, 1, 1, 1], key = "") =>
      this.world.spawn({ components: { Text: { text: s, key, fontSize, color, space: "screen", maxWidth: 680, layer: 302 } } }, { parent: this.list });
    // A Text with a key is translated by the engine, also when the player changes the language while the credits are open.
    const keyed = (key, fontSize, color) => text(key, fontSize, color, key);
    text(game.project.name, 34);
    for (const key of this.lines) keyed(key, 26);
    keyed("credits.software", 22, [0.75, 0.8, 0.9, 1]);
    for (const n of game.notices()) text(`${n.name}  (${n.license})\n${n.usedFor}\n${n.url}`, 20);
    keyed("credits.licenses", 18, [0.75, 0.8, 0.9, 1]);
  }

  onUpdate(dt) {
    if (!this.entity.active) return;
    this.list.get("ScrollList").scroll += input.axis("ui_up", "ui_down") * this.scrollSpeed * dt;
  }
}
