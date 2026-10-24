// @ts-check
// The texts of the results screen (P3): the heading with the courier's name, the stars, this run's time next to the best one,
// and what earned (or missed) each star. Pure: level_flow.js asks lines() and writes the strings into the Text entities that
// every level scene already has (results_heading, results_stars, results_time, results_spring), so no scene needed new widgets.
//
//   lines(levelId, run)   { results_heading, results_stars, results_time, results_spring } for a finished run
//   starText(n, max)      a string such as "★★☆": n filled stars out of max (level select shares it)
//   goalLines(levelId, goals)  one line per goal: "[x] Fast: under 50 s"
import { i18n } from "factoria";
import * as fmt from "./fmt.js";
import * as levels from "./levels.js";
import * as progress from "./progress.js";
import * as stars from "./stars.js";

/** Filled and empty star marks: U+2605 and U+2606, both in the built-in font. */
const FULL = "\u2605";
const EMPTY = "\u2606";

export function starText(n, max = 3) {
  return FULL.repeat(Math.max(0, Math.min(max, n))) + EMPTY.repeat(Math.max(0, max - n));
}

export function goalLines(levelId, goals) {
  const level = levels.byId(levelId);
  const mark = (ok) => (ok ? "[x] " : "[ ] ");
  const out = [];
  out.push(mark(goals.fast) + i18n.t("results.goal.fast", { par: level ? level.parTime : 0 }));
  out.push(mark(goals.springy) + i18n.t("results.goal.springy", { percent: Math.round(stars.SPRING_GOAL * 100) }));
  if (goals.thorough !== null && goals.thorough !== undefined) out.push(mark(goals.thorough) + i18n.t("results.goal.thorough"));
  return out;
}

/**
 * Each line is a plain string, or `{ key, args }` for a Text the engine formats itself (Text.keyArgs, FB-0021): level_flow sets
 * the key and the args once, and a language switch needs no new call (refreshPanel only re-reads the time, whose decimal
 * separator comes from the locale).
 * @param {string} levelId
 * @param {{ time: number, left: number, stars: number, goals: any, best?: boolean, daily?: { best: boolean } | null }} run
 */
export function lines(levelId, run) {
  const name = progress.name();
  if (run.daily) {
    const saved = progress.dailyTime(run.daily.date)?.time ?? run.time;
    return {
      results_heading: { key: name ? "daily.doneNamed" : "daily.done", args: { name } },
      results_stars: "",
      results_time: { key: "daily.timeBest", args: { time: fmt.decimal(run.time), best: fmt.decimal(saved) } },
      results_spring: { key: "results.spring", args: { seconds: Math.ceil(run.left) } },
    };
  }
  const saved = progress.resultFor(levelId);
  const best = saved ? saved.time : run.time;
  return {
    results_heading: { key: name ? "results.titleNamed" : "results.title", args: { name } },
    results_stars: starText(run.stars),
    results_time: { key: run.best ? "results.timeNewBest" : "results.timeBest", args: { time: fmt.decimal(run.time), best: fmt.decimal(best) } },
    results_spring: [i18n.t("results.spring", { seconds: Math.ceil(run.left) }), ...goalLines(levelId, run.goals)].join("\n"), // several lines with marks: one string
  };
}
