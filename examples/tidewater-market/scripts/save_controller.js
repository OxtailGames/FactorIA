// @ts-check
// On one entity of the game scene ("save_controller", spawned by the game controller): autosaves and play time.
// The rules are in scripts/game/autosave.js; this connects them to frames, the clock's seasons and the life of the window.
import { Behaviour, game, time } from "factoria";

export default class SaveController extends Behaviour {
  // play time keeps counting while the pause menu is open
  runWhilePaused = true;

  onStart() {
    const controller = this.world.find("controller").behaviour;
    /** @type {import("./game/autosave.js").Autosaver} */
    this.saver = controller.autosaver;
    this.off = [
      controller.state.events.on("clock.season", () => this.saver.onSeason()),
      game.on("blur", () => this.saver.onLeave("blur")),
      game.on("suspend", () => this.saver.onLeave("suspend")),
      game.on("focus", () => this.saver.onReturn()),
      game.on("resume", () => this.saver.onReturn()),
      // Desktop only: the web and phones never raise "quit". The window closes after the handler (no cancel).
      game.on("quit", () => this.saver.onLeave("quit")),
    ];
  }

  onUpdate() {
    this.saver.update(time.unscaledDt);
  }

  onDestroy() {
    for (const off of this.off || []) off();
    this.off = [];
  }
}
