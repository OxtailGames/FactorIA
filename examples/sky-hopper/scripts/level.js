// @ts-check
// Per-level bookkeeping: the level number shown in the HUD and where "out of bounds" is.
// The player spawns where the level map (levels/*.json, glyph P) puts it; player.js remembers that spot.
import { Behaviour } from "factoria";
import { state } from "scripts/game_state.js";

export default class Level extends Behaviour {
  levelIndex = 1;
  killY = -200;

  onStart() {
    state.level = this.levelIndex;
    const p = this.world.find("player");
    if (p && p.behaviour) p.behaviour.killY = this.killY;
  }
}
