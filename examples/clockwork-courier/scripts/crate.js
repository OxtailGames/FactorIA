// @ts-check
// A pushable crate: a dynamic RigidBody3D (lockRotation, so it stays upright and slides) that the courier shoves by walking
// into it. This script only adds the sounds: a thud when it lands or hits something hard, and a scrape while it slides.
// Weight is the body's `mass`: the CharacterController pushes it by contact, so a heavy crate moves slowly.
import { Behaviour, audio } from "factoria";

export default class Crate extends Behaviour {
  /** Impact strength (CollisionInfo.impulse) above which a thud plays. */
  thudImpulse = 2;
  /** Horizontal speed (m/s) above which the crate scrapes. */
  scrapeSpeed = 0.25;
  sound = "assets/audio/impactPlank_medium_000.ogg";

  onStart() {
    this.body = this.entity.get("RigidBody3D");
    this.cool = 0;
    this.scrape = 0;
    /** Largest speed seen, m/s (tests read it). */
    this.maxSpeed = 0;
  }

  onCollisionEnter(other, info) {
    if (this.cool > 0 || other.hasTag("courier")) return;
    const k = info ? info.impulse : 0;
    if (k < this.thudImpulse) return;
    this.cool = 0.25;
    audio.play(this.sound, { bus: "sfx", volume: Math.min(0.9, 0.25 + k * 0.05), pitch: 0.85 });
  }

  onFixedUpdate(dt) {
    if (this.cool > 0) this.cool -= dt;
    if (!this.body) return;
    const v = this.body.velocity;
    const h = Math.hypot(v.x, v.z);
    if (h > this.maxSpeed) this.maxSpeed = h;
    this.scrape -= dt;
    if (h > this.scrapeSpeed && this.scrape <= 0) {
      this.scrape = 0.45;
      audio.play("assets/audio/impactPlank_medium_002.ogg", { bus: "sfx", volume: 0.25, pitch: 0.7 });
    }
  }
}
