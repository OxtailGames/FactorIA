// @ts-check
// The game clock (pure). The controller feeds it real seconds every frame; the clock multiplies them by the speed (pause, x1,
// x2, x4), cuts the result into FIXED steps of calendar.tickSeconds game seconds and runs one "clock.tick" per step. The
// whole simulation (production, walkers, wages) advances only on "clock.tick", so x1, x2 and x4 and any frame rate give the
// same town: a speed only decides how many steps run per frame, never how long a step is. The calendar (seasons, days per
// season, game seconds per day) is data/economy.json "calendar".
//
// Events: "clock.tick" {seconds} once per fixed step, "clock.day" {day, date} when the day changes (before that step's tick),
// "clock.season" {date} when the season changes (right after clock.day), "clock.speed" {speed}.

/** Speed multipliers by speed setting: 0 = paused, then 1x, 2x, 4x. */
export const SPEEDS = [0, 1, 2, 4];

export class Clock {
  /** @param {{ seasons: string[], daysPerSeason: number, secondsPerDay: number, tickSeconds: number, startYear: number }} calendar @param {import("./events.js").Events} events */
  constructor(calendar, events) {
    this.calendar = calendar;
    this.events = events;
    /** Whole days since the start. */
    this.day = 0;
    /** Fixed steps into the current day (an integer, so the time of day never drifts). */
    this.dayTick = 0;
    /** Index into SPEEDS. A new clock is paused; the game screen starts it at 1. */
    this.speed = 0;
    /** Game seconds that did not fill a step yet (carried to the next advance). */
    this.pending = 0;
    /** Steps run since the start. */
    this.ticks = 0;
  }

  /** Game seconds into the current day. */
  get seconds() {
    return this.dayTick * this.calendar.tickSeconds;
  }

  /** Fixed steps in one day. */
  get ticksPerDay() {
    return Math.round(this.calendar.secondsPerDay / this.calendar.tickSeconds);
  }

  /** Seconds of one fixed step. */
  get step() {
    return this.calendar.tickSeconds;
  }

  /** Fraction of the current step already waited for (0..1): what a view interpolates the walkers with. */
  get alpha() {
    return Math.min(1, this.pending / this.step);
  }

  /** The current speed multiplier (0, 1, 2 or 4). */
  get multiplier() {
    return SPEEDS[this.speed];
  }

  setSpeed(speed) {
    const s = Math.max(0, Math.min(SPEEDS.length - 1, Math.round(speed)));
    if (s === this.speed) return;
    this.speed = s;
    this.events.emit("clock.speed", { speed: s });
  }

  /**
   * Move the clock by real seconds `dt` (scaled by the speed): runs as many fixed steps as fit. `maxSteps` caps the work of
   * one call (a frame that took too long drops the rest instead of spiralling).
   * @returns {number} the game seconds that passed
   */
  advance(dt, maxSteps = Infinity) {
    const gameSeconds = dt * SPEEDS[this.speed];
    if (gameSeconds <= 0) return 0;
    this.pending += gameSeconds;
    const step = this.step;
    let steps = 0;
    while (this.pending >= step - 1e-9 && steps < maxSteps) {
      this.pending -= step;
      this.tick(step);
      steps++;
    }
    if (steps >= maxSteps && this.pending > step) this.pending = step;
    return steps * step;
  }

  /** One fixed step. */
  tick(step) {
    const before = this.date();
    this.dayTick++;
    if (this.dayTick >= this.ticksPerDay) {
      this.dayTick = 0;
      this.day++;
    }
    this.ticks++;
    const now = this.date();
    if (now.day !== before.day) {
      this.events.emit("clock.day", { day: now.day, date: now });
      if (now.seasonIndex !== before.seasonIndex || now.year !== before.year) this.events.emit("clock.season", { date: now });
    }
    this.events.emit("clock.tick", { seconds: step });
  }

  /** Fraction of the current day that has passed, 0..1. */
  dayFraction() {
    return this.dayTick / this.ticksPerDay;
  }

  /** Jump to a day (tests, loading a save). */
  setDay(day) {
    this.day = Math.max(0, Math.floor(day));
    this.dayTick = 0;
    this.pending = 0;
  }

  /** @returns {{ day: number, year: number, season: string, seasonIndex: number, dayOfSeason: number }} dayOfSeason counts from 1 */
  date() {
    const { seasons, daysPerSeason, startYear } = this.calendar;
    const daysPerYear = seasons.length * daysPerSeason;
    const inYear = this.day % daysPerYear;
    const seasonIndex = Math.floor(inYear / daysPerSeason);
    return {
      day: this.day,
      year: startYear + Math.floor(this.day / daysPerYear),
      season: seasons[seasonIndex],
      seasonIndex,
      dayOfSeason: (inYear % daysPerSeason) + 1,
    };
  }
}
