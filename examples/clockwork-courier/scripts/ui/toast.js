// @ts-check
// Small messages that appear at the top of the screen, stay for a moment and fade ("Achievement unlocked: ..."). One at a time:
// a second one waits in a queue. The owner (scripts/services.js) calls update(dt) every frame; the toast entity belongs to the
// scene, so a scene load removes it and a new Toasts starts empty.
//
//   const toasts = new Toasts();
//   toasts.show("Achievement unlocked: First Delivery");
//   toasts.update(dt);          // every frame
//   toasts.current              the text on screen, or ""
import { world } from "factoria";

export class Toasts {
  /** @param {{ seconds?: number, fade?: number }} [options] seconds on screen, seconds of fade in and out */
  constructor(options = {}) {
    this.seconds = options.seconds ?? 3;
    this.fade = options.fade ?? 0.3;
    /** @type {string[]} */
    this.queue = [];
    this.entity = null;
    this.age = 0;
    /** The text on screen now, "" when none. */
    this.current = "";
    /** Every text shown so far (tests read it). */
    this.shown = [];
  }

  /** Queues a message. */
  show(text) {
    this.queue.push(text);
  }

  update(dt) {
    if (this.entity && !this.entity.alive) this.entity = null; // the scene changed under us
    if (!this.entity) {
      if (this.queue.length === 0) return;
      this.current = /** @type {string} */ (this.queue.shift());
      this.shown.push(this.current);
      this.age = 0;
      this.entity = world.spawn({
        id: "toast",
        components: {
          Panel: { size: [560, 64], anchor: [0.5, 0.9], color: [0.05, 0.07, 0.12, 0], layer: 400, layout: "column", justify: "center" },
        },
        children: [
          { id: "toast_text", components: { Text: { text: this.current, fontSize: 26, space: "screen", layer: 401, color: [1, 0.85, 0.3, 0], maxWidth: 520 } } },
        ],
      });
      return;
    }
    this.age += dt;
    const a = Math.max(0, Math.min(1, this.age / this.fade, (this.seconds - this.age) / this.fade));
    if (this.age >= this.seconds) {
      this.entity.destroy();
      this.entity = null;
      this.current = "";
      return;
    }
    this.entity.get("Panel").color = [0.05, 0.07, 0.12, 0.85 * a];
    const text = world.find("toast_text");
    if (text) text.get("Text").color = [1, 0.85, 0.3, a];
  }
}
