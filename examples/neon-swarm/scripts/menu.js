// @ts-check
// Title and game-over screens: pulse the prompt, start a new game on Space / click.
import { Behaviour, world, input, scene, storage, time } from "factoria";

export default class Menu extends Behaviour {
  mode = "title";     // title | gameover
  delay = 0.4;        // ignore input briefly so a held key does not skip the screen

  onStart() {
    const best = storage.get("highScore", 0);
    const set = (id, text) => { const e = world.find(id); if (e) e.get("Text").text = text; };
    set("best", "HIGH SCORE  " + best);
    if (this.mode === "gameover") {
      const score = storage.get("lastScore", 0);
      set("final", "SCORE  " + score + "    WAVE  " + storage.get("lastWave", 0));
      set("record", score > 0 && score >= best ? "NEW HIGH SCORE!" : "");
    }
    this.prompt = world.find("prompt").get("Text");
  }

  onUpdate(dt) {
    this.delay -= dt;
    this.prompt.color.a = 0.55 + 0.45 * Math.sin(time.elapsed * 5);
    if (this.delay <= 0 && input.pressed("action")) scene.load("scenes/game.scene.json");
  }
}
