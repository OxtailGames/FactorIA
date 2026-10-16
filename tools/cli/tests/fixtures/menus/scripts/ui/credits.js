// @ts-check
// The credits panel: the game's own lines, then the software inside the FactorIA runtime (game.notices(), the
// parts whose licenses FACTORIA_NOTICES.txt holds next to the exported game). ui_up/ui_down scroll the list.
import { Behaviour, game, input } from "factoria";

export default class Credits extends Behaviour {
  /** Lines shown after the game's name (factoria.json "name") and before the engine's notices. */
  lines = ["Made with FactorIA"];
  /** Scroll speed of ui_up/ui_down in pixels per second. */
  scrollSpeed = 500;

  onStart() {
    this.list = this.world.find("credits_list");
    const text = (s, fontSize = 22, color = [1, 1, 1, 1]) =>
      this.world.spawn({ components: { Text: { text: s, fontSize, color, space: "screen", maxWidth: 680, layer: 302 } } }, { parent: this.list });
    text(game.project.name, 34);
    for (const l of this.lines) text(l, 26);
    text("This game uses the following software:", 22, [0.75, 0.8, 0.9, 1]);
    for (const n of game.notices()) text(`${n.name}  (${n.license})\n${n.usedFor}\n${n.url}`, 20);
    text("The full license texts are in FACTORIA_NOTICES.txt, shipped with the game.", 18, [0.75, 0.8, 0.9, 1]);
  }

  onUpdate(dt) {
    if (!this.entity.active) return;
    this.list.get("ScrollList").scroll += input.axis("ui_up", "ui_down") * this.scrollSpeed * dt;
  }
}
