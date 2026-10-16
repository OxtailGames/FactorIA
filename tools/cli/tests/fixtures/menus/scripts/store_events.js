// @ts-check
// Put this behaviour on one entity of every level: while the store's overlay (Steam, the App Store sheet) is open the
// game pauses, and it resumes when the overlay closes. A game the player paused itself stays paused.
import { Behaviour, game, platform } from "factoria";

export default class StoreEvents extends Behaviour {
  onStart() {
    this.pausedByOverlay = false;
    platform.on("overlay", (e) => {
      if (e.open && !game.paused) {
        game.paused = true;
        this.pausedByOverlay = true;
      } else if (!e.open && this.pausedByOverlay) {
        game.paused = false;
        this.pausedByOverlay = false;
      }
    });
  }
}
