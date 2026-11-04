// @ts-check
// The campfire: the thing to keep alive. It burns fuel at a rate the night sets (game.js), takes the logs the warden
// carries when he stands next to it, loses fuel when a wolf bites it, and shows its fuel in its light, its flames and
// the crackle. Wolves slow down inside its light (inLight). When the fuel reaches 0 it sends "fire_out".
import { Behaviour, world, audio } from "factoria";
import { flatDistance, playAt } from "./common.js";

export default class Campfire extends Behaviour {
  /** The most fuel it holds. */
  maxFuel = 100;
  /** Fuel at the start of a game. */
  startFuel = 80;
  /** Fuel one log gives. */
  logFuel = 20;
  /** The warden feeds it from this far, metres. */
  feedRange = 2.6;
  /** Seconds between two logs given. */
  feedCooldown = 0.28;
  /** Radius of the safe light with a full fire and with a nearly dead one, metres. */
  fullRadius = 9;
  lowRadius = 2.5;

  onStart() {
    this.fuel = this.startFuel;
    this.burnRate = 0;
    this.cool = 0;
    this.out = false;
    this.clock = 0;
    this.flames = world.find("flames");
    this.sparks = world.find("sparks");
    this.light = world.find("fire_light");
    this.sound = world.find("fire_sound");
    this.logsFed = 0;
    this.show();
  }

  /** Fuel as 0..1. */
  get fraction() {
    return Math.max(0, Math.min(1, this.fuel / this.maxFuel));
  }

  /** The radius of the light that slows the wolves, metres. */
  lightRadius() {
    return this.lowRadius + (this.fullRadius - this.lowRadius) * this.fraction;
  }

  /** True when the point (an {x, z} or an entity) is inside the light. */
  inLight(p) {
    const q = p.position ?? p;
    return !this.out && Math.hypot(q.x, q.z) < this.lightRadius();
  }

  onFixedUpdate(dt) {
    if (this.out) return;
    this.cool -= dt;
    this.fuel -= this.burnRate * dt;
    const warden = world.find("warden");
    const wb = warden?.behaviour;
    if (wb && this.cool <= 0 && wb.logs > 0 && this.fuel < this.maxFuel - this.logFuel * 0.5 && flatDistance(warden, this.entity) <= this.feedRange) {
      if (wb.takeLog()) this.feed(this.logFuel);
    }
    if (this.fuel <= 0) {
      this.fuel = 0;
      this.out = true;
      this.show();
      world.emit("fire_out", {});
    }
  }

  onUpdate(dt) {
    this.clock += dt;
    this.show();
  }

  /** Puts fuel on the fire (a log). */
  feed(amount) {
    this.fuel = Math.min(this.maxFuel, this.fuel + amount);
    this.cool = this.feedCooldown;
    this.logsFed++;
    audio.play("assets/audio/log_feed.wav", { volume: 0.9, bus: "sfx" });
    world.spawnPrefab("prefabs/embers.prefab.json", { position: [0, 0.8, 0] });
    world.emit("fire_fed", { fuel: this.fuel });
  }

  /** A wolf bites the fire: it loses fuel. */
  bite(amount) {
    if (this.out) return;
    this.fuel = Math.max(0, this.fuel - amount);
    world.spawnPrefab("prefabs/embers.prefab.json", { position: [0, 0.6, 0] });
    world.emit("fire_bitten", { fuel: this.fuel });
  }

  /** The level of the flames, the light and the crackle follows the fuel, with a flicker. */
  show() {
    const f = this.out ? 0 : this.fraction;
    const flicker = 1 + 0.08 * Math.sin(this.clock * 17) + 0.05 * Math.sin(this.clock * 9.3 + 1);
    if (this.light) {
      const L = this.light.get("Light");
      L.intensity = (this.out ? 0.05 : 0.5 + 2.4 * f) * flicker;
      L.range = 6 + 12 * f;
    }
    if (this.flames) {
      const e = this.flames.get("ParticleEmitter");
      e.rate = this.out ? 0 : 8 + 45 * f;
      e.startSize = 0.25 + 0.35 * f;
    }
    if (this.sparks) this.sparks.get("ParticleEmitter").rate = this.out ? 0 : 2 + 10 * f;
    if (this.sound) this.sound.get("AudioSource").volume = this.out ? 0 : 0.3 + 0.6 * f;
  }
}
