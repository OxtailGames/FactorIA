// @ts-check
// The game clock (pure). In P1 it is a stub: it starts paused (speed 0) and nothing sets the speed, so the date in the HUD
// stays at spring 1, year 1. P2 gives it a speed control and drives the simulation from "clock.tick". The calendar
// (seasons, days per season, game seconds per day) is data/economy.json "calendar".
//
// Events: "clock.tick" {seconds} every advance with speed > 0, "clock.day" {day, date} and "clock.season" {date} when
// the day or the season changes, "clock.speed" {speed}.

/** Speed multipliers by speed setting: 0 = paused, then 1x, 2x, 4x. */
export const SPEEDS = [0, 1, 2, 4];

export class Clock {
  /** @param {{ seasons: string[], daysPerSeason: number, secondsPerDay: number, startYear: number }} calendar @param {import("./events.js").Events} events */
  constructor(calendar, events) {
    this.calendar = calendar;
    this.events = events;
    /** Whole days since the start. */
    this.day = 0;
    /** Game seconds into the current day. */
    this.seconds = 0;
    /** Index into SPEEDS. */
    this.speed = 0;
  }

  setSpeed(speed) {
    const s = Math.max(0, Math.min(SPEEDS.length - 1, Math.round(speed)));
    if (s === this.speed) return;
    this.speed = s;
    this.events.emit("clock.speed", { speed: s });
  }

  /** Move the clock by real seconds `dt` (scaled by the speed). Returns the game seconds that passed. */
  advance(dt) {
    const gameSeconds = dt * SPEEDS[this.speed];
    if (gameSeconds <= 0) return 0;
    const before = this.date();
    this.seconds += gameSeconds;
    while (this.seconds >= this.calendar.secondsPerDay) {
      this.seconds -= this.calendar.secondsPerDay;
      this.day++;
    }
    this.events.emit("clock.tick", { seconds: gameSeconds });
    const now = this.date();
    if (now.day !== before.day) {
      this.events.emit("clock.day", { day: now.day, date: now });
      if (now.seasonIndex !== before.seasonIndex || now.year !== before.year) this.events.emit("clock.season", { date: now });
    }
    return gameSeconds;
  }

  /** Jump to a day (tests, loading a save). */
  setDay(day) {
    this.day = Math.max(0, Math.floor(day));
    this.seconds = 0;
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
