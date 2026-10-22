// @ts-check
// The spring: the courier's time. Seconds left drain in game time (so pausing stops it) and at zero the spring_empty
// event fires once. P2 adds wind-up keys that call wind(). level_flow.js sets `left` from the level list.
//
//   left         seconds left        max       the most the spring can hold (wind() never goes past it)
//   fraction     left / max, 0..1    running   false stops the drain (level over)
//   wind(s)      adds seconds, sends spring_wound (a wind-up key, scripts/wind_key.js)
//   drain(s)     takes seconds away at once (the price of a catch); at zero spring_empty follows
import { Behaviour } from "factoria";
import { EVENTS, emit } from "./events.js";

export default class Spring extends Behaviour {
  /** Seconds the spring holds when full (the level list overrides it through fill()). */
  max = 60;
  /** Seconds left when the scene starts, 0 = full. */
  left = 0;
  /** Seconds that drain per second of game time (1 = real time; an easy mode could lower it). */
  drainRate = 1;

  onStart() {
    if (this.left <= 0) this.left = this.max;
    this.running = false;
    this.empty = false;
    /** Game seconds since fill() (what the results screen shows as the time). */
    this.elapsed = 0;
  }

  /** Fills the spring with `seconds` and starts draining. */
  fill(seconds) {
    this.max = seconds;
    this.left = seconds;
    this.empty = false;
    this.elapsed = 0;
    this.running = true;
  }

  stop() {
    this.running = false;
  }

  /** Starts the drain again with `seconds` left after the spring ran down (the rewarded "more time", scripts/more_time.js). */
  resume(seconds) {
    this.left = Math.min(this.max, seconds);
    this.empty = false;
    this.running = true;
  }

  get fraction() {
    return this.max > 0 ? Math.max(0, Math.min(1, this.left / this.max)) : 0;
  }

  /** Adds seconds of spring (up to max). */
  wind(seconds) {
    const before = this.left;
    this.left = Math.min(this.max, this.left + seconds);
    emit(EVENTS.springWound, { seconds: this.left - before, left: this.left });
  }

  /** Takes `seconds` away at once. */
  drain(seconds) {
    this.left = Math.max(0, this.left - seconds);
  }

  onFixedUpdate(dt) {
    if (!this.running || this.empty) return;
    this.elapsed += dt;
    this.left = Math.max(0, this.left - dt * this.drainRate);
    if (this.left <= 0) {
      this.empty = true;
      this.running = false;
      emit(EVENTS.springEmpty, { time: this.elapsed });
    }
  }
}
