// @ts-check
// A wind-up key: spins and bobs in the level until the courier touches it, then winds the spring (`seconds` more, never
// past its maximum) with a burst of sparks and a bell. Spring.wind() sends spring_wound.
import { Behaviour, world, audio } from "factoria";
import * as fx from "./fx.js";
import { isReduced } from "./accessibility.js";

export default class WindKey extends Behaviour {
  /** Seconds of spring the key gives. */
  seconds = 15;
  /** Spin speed in degrees per second. */
  spin = 120;
  /** Bob amplitude in metres. */
  bobHeight = 0.1;

  onStart() {
    this.baseY = this.entity.position.y;
    this.taken = false;
    this.t = 0;
  }

  onUpdate(dt) {
    // Reduced motion (scripts/accessibility.js): the key stands turned a little, so it keeps its shape but does not move.
    const calm = isReduced();
    if (!calm) this.t += dt;
    const tr = this.entity.get("Transform");
    tr.position = [tr.position.x, this.baseY + (calm ? 0 : Math.sin(this.t * 2.6) * this.bobHeight), tr.position.z];
    tr.rotation = [0, calm ? 30 : (this.t * this.spin) % 360, 0];
  }

  onTriggerEnter(other) {
    if (this.taken || !other.hasTag("courier")) return;
    this.taken = true;
    const spring = world.find("spring")?.behaviour;
    if (spring) spring.wind(this.seconds);
    const p = this.entity.worldPosition;
    fx.burst("sparks", [p.x, p.y, p.z]);
    audio.play("assets/audio/impactBell_heavy_000.ogg", { bus: "sfx", volume: 0.8, pitch: 1.3, caption: "[Bell: the spring is wound]", captionKey: "captions.key" });
    this.entity.destroy();
  }
}
