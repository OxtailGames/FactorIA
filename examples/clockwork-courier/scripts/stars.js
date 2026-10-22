// @ts-check
// How many stars a finished level earns. The one place with the rule: level_flow.js calls evaluate() when the last
// parcel is delivered and the results screen (P3) shows `goals` as three little checks.
//
//   1 star    always, for delivering every required parcel
//   bonus goals (each one is met or not):
//     fast      finished within the level's parTime (seconds of game time)
//     springy   finished with at least SPRING_GOAL of the spring still wound
//     thorough  every optional parcel of the level was delivered (a goal only on levels that have optional parcels)
//   2 stars   one bonus goal met        3 stars   two or more met
//
// So a level with only two possible goals needs both for 3 stars, and a level with optional parcels lets the player
// choose which two of the three to chase.
import { LEVELS } from "./levels.js";

/** Fraction of the spring that must be left for the `springy` goal. */
export const SPRING_GOAL = 0.25;

/**
 * @param {{ parTime: number, optionalParcels?: number } | null} level  the entry of scripts/levels.js (null: only 1 star)
 * @param {{ time: number, springLeft: number, springMax: number, optionalDelivered?: number }} result
 * @returns {{ stars: number, goals: { fast: boolean, springy: boolean, thorough: boolean | null }, met: number }}
 */
export function evaluate(level, result) {
  const fast = !!level && result.time <= level.parTime;
  const springy = result.springMax > 0 && result.springLeft / result.springMax >= SPRING_GOAL;
  const optional = level ? (level.optionalParcels ?? 0) : 0;
  const thorough = optional > 0 ? (result.optionalDelivered ?? 0) >= optional : null;
  const met = (fast ? 1 : 0) + (springy ? 1 : 0) + (thorough ? 1 : 0);
  return { stars: 1 + Math.min(2, met), goals: { fast, springy, thorough }, met };
}

/** Best possible stars of every level in the list, for a "total stars" counter. */
export function maxStars() {
  return LEVELS.length * 3;
}
