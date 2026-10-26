// @ts-check
// Put this behaviour on one entity of every scene (the title, the game, the stress town): it runs the gamepad cursor of
// scripts/game/pointer.js every frame (also while the game is paused, the menus need it) and draws it, and plays the click sound
// of every button pressed, with a mouse or with A. The cursor shows only after the player used a gamepad.
import { Behaviour, world, ui } from "factoria";
import { pointer } from "../game/pointer.js";
import { playUi, resetUi } from "../game/sfx.js";

export default class PadCursor extends Behaviour {
  runWhilePaused = true;

  onStart() {
    pointer.reset();
    resetUi();
    // Shapes, not Panels: a Panel under the cursor would be what ui.widgetAt finds there
    this.reticle = world.spawn({
      id: "pad_cursor",
      components: {
        Transform: { position: [0, 0, 0] },
        Shape2D: { shape: "rectangle", size: [20, 20], color: [1, 0.82, 0.38, 1], layer: 600, space: "screen" },
      },
      children: [
        {
          id: "pad_cursor_core",
          components: {
            Transform: { position: [0, 0, 0] },
            Shape2D: { shape: "rectangle", size: [12, 12], color: [0.05, 0.07, 0.1, 1], layer: 601, space: "screen" },
          },
        },
      ],
    });
    this.reticle.active = false;
    ui.on("click", () => playUi("click"));
  }

  onUpdate() {
    const pad = pointer.pad;
    if (this.reticle.active !== pad) this.reticle.active = pad;
    if (pad) {
      const p = pointer.position();
      this.reticle.position = [p.x, p.y, 0];
    }
  }
}
