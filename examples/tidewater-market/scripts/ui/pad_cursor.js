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
    this.reticle = world.spawn({
      id: "pad_cursor",
      components: {
        Transform: { position: [0, 0, 0] },
        Panel: { anchor: [0, 0], pivot: [0.5, 0.5], size: [20, 20], layout: "none", color: [1, 0.82, 0.38, 1], layer: 600 },
      },
      children: [
        {
          id: "pad_cursor_core",
          components: {
            Transform: { position: [0, 0, 0] },
            Panel: { anchor: [0.5, 0.5], pivot: [0.5, 0.5], size: [12, 12], layout: "none", color: [0.05, 0.07, 0.1, 1], layer: 601 },
          },
        },
      ],
    });
    this.reticle.active = false;
    // where the focus rests while the cursor is over nothing (pointer.js): a button of 1 px, off the screen, drawn with no colour
    this.sink = world.spawn({
        id: "pad_cursor_sink",
        components: { Transform: { position: [-30, -30, 0] }, Button: { text: "", size: [2, 2], color: [0, 0, 0, 0], layer: 0, autoSize: false } },
    });
    this.sink.active = false; // only while a pad is in use: else the engine could pick it as the first widget to focus
    pointer.setSink(this.sink);
    ui.on("click", () => playUi("click"));
  }

  onUpdate() {
    const pad = pointer.pad;
    if (this.reticle.active !== pad) this.reticle.active = pad;
    if (this.sink.active !== pad) this.sink.active = pad;
    if (pad) {
      const p = pointer.position();
      this.reticle.position = [p.x, p.y, 0];
    }
  }
}
