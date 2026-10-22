// @ts-check
// The comfort entity of a level ("comfort", spawned by pause_menu.js from prefabs/ui/comfort.prefab.json, together with the
// scene's Captions entity). It carries what a level needs besides the options themselves (scripts/accessibility.js):
//   - haptics for a catch, a delivery and a low spring (landing is in courier.js),
//   - the low-spring warning: a tick sound with its caption and a pulse, once each time the spring drops under the HUD's limit,
//   - pause when the app is suspended: game.on("suspend") opens the pause menu (the engine's pauseOnSuspend freezes time and
//     music meanwhile; the menu stays open after resume, waiting for the player).
import { Behaviour, world, audio, game } from "factoria";
import { EVENTS } from "./events.js";
import * as haptics from "./haptics.js";

export default class Comfort extends Behaviour {
  /** The spring warning fires under this share of the spring (the HUD's lowFraction) and again after the spring went over it + 0.1. */
  lowFraction = 0.25;
  pauseMenuId = "pause_menu";

  onStart() {
    this.lowArmed = true;
    /** How many times the game paused itself because the app was suspended (tests read it). */
    this.autoPauses = 0;
    this.offs = [
      world.on(EVENTS.courierCaught, () => haptics.pulse("catch")),
      world.on(EVENTS.parcelDelivered, () => haptics.pulse("delivery")),
      game.on("suspend", () => this.pauseForSuspend()),
    ];
  }

  onDestroy() {
    for (const off of this.offs ?? []) off();
  }

  onUpdate() {
    this.watchSpring();
  }

  /**
   * Pauses as the app goes to the background. Returns true when it paused. A paused game, a finished level and a pause
   * menu that is not there are left alone.
   */
  pauseForSuspend() {
    if (game.paused) return false;
    const menu = world.find(this.pauseMenuId)?.behaviour;
    if (!menu || menu.locked()) return false;
    menu.pause();
    if (!game.paused) return false;
    this.autoPauses++;
    return true;
  }

  watchSpring() {
    const spring = world.find("spring")?.behaviour;
    if (!spring || !spring.running) return;
    const f = spring.fraction;
    if (f > this.lowFraction + 0.1) this.lowArmed = true;
    else if (f <= this.lowFraction && this.lowArmed) {
      this.lowArmed = false;
      this.springLow();
    }
  }

  /** The spring went low: a tick (with its caption) and a pulse. */
  springLow() {
    audio.play("assets/audio/error_001.ogg", {
      bus: "sfx",
      volume: 0.45,
      pitch: 1.4,
      caption: "[Alarm: the spring is nearly out]",
      captionKey: "captions.springLow",
    });
    haptics.pulse("springLow");
  }
}
