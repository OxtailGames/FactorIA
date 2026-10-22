// @ts-check
// A lever: a trigger zone around a handle. While the courier stands in it, the `action` input (F, gamepad X, the touch
// button) pulls the lever and toggles every gate in `targets` (entity ids with scripts/gate.js). The handle is the child
// entity named "handle": it tips over when pulled. `once` makes it a one-way lever.
import { Behaviour, input, world, audio } from "factoria";

export default class Lever extends Behaviour {
  /** Entity ids of the gates it works. */
  targets = [];
  /** true: can only be pulled once (the gate stays open). */
  once = false;
  /** Handle angle when pulled, degrees. */
  pulledAngle = 55;

  onStart() {
    this.near = false;
    this.pulled = false;
    this.handle = this.entity.children.find((c) => c.name === "handle") ?? null;
    this.setHandle(0);
  }

  setHandle(f) {
    if (this.handle) this.handle.get("Transform").rotation = [0, 0, -this.pulledAngle * f + this.pulledAngle * 0.5];
  }

  /** Pulls the lever (what the action input does; tests and the bot may call it). */
  pull() {
    if (this.once && this.pulled) return;
    this.pulled = !this.pulled;
    this.setHandle(this.pulled ? 1 : 0);
    audio.play("assets/audio/impactMetal_heavy_000.ogg", { bus: "sfx", volume: 0.6, pitch: 1.4 });
    for (const id of this.targets) {
      const gate = world.find(id)?.behaviour;
      if (!gate) continue;
      if (this.pulled) gate.open();
      else gate.close();
    }
  }

  onTriggerEnter(other) {
    if (other.hasTag("courier")) this.near = true;
  }

  onTriggerExit(other) {
    if (other.hasTag("courier")) this.near = false;
  }

  onUpdate() {
    if (this.near && input.pressed("action")) this.pull();
  }
}
