// @ts-check
// A wind-up key: spins and bobs in the level until the courier touches it, then winds the spring (`seconds` more, never
// past its maximum) with a burst of sparks and a bell. Spring.wind() sends spring_wound.
import { Behaviour, world, audio } from "factoria";
import * as fx from "./fx.js";

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
    this.t += dt;
    const tr = this.entity.get("Transform");
    tr.position = [tr.position.x, this.baseY + Math.sin(this.t * 2.6) * this.bobHeight, tr.position.z];
    tr.rotation = [0, (this.t * this.spin) % 360, 0];
  }

  onTriggerEnter(other) {
    if (this.taken || !other.hasTag("courier")) return;
    this.taken = true;
    const spring = world.find("spring")?.behaviour;
    if (spring) spring.wind(this.seconds);
    const p = this.entity.worldPosition;
    fx.burst("sparks", [p.x, p.y, p.z]);
    audio.play("assets/audio/impactBell_heavy_000.ogg", { bus: "sfx", volume: 0.8, pitch: 1.3 });
    this.entity.destroy();
  }
}
