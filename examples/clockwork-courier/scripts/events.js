// @ts-check
// The game events of Clockwork Courier: the names sent with world.emit, and what each one carries. Scripts import
// EVENTS instead of writing the strings, so a typo is a load error and not a silent no-op. Events are dropped on a
// scene load (world.on listeners die with the scene), which is what a level restart wants.
//
//   emit(EVENTS.parcelPicked, { parcel: "parcel_1", carrying: 1 });
//   world.on(EVENTS.springEmpty, () => ...);
import { world } from "factoria";

export const EVENTS = Object.freeze({
  /** The level is ready and the spring runs: { level: id, spring: seconds, parcels: n }. */
  levelStarted: "level_started",
  /** The courier picked up a parcel: { parcel: entity id, carrying: parcels now held }. */
  parcelPicked: "parcel_picked",
  /** A parcel was handed in at a delivery door: { door: entity id, delivered: n, total: n, optional: n bonus parcels so far }. */
  parcelDelivered: "parcel_delivered",
  /** The spring was wound (a wind-up key, scripts/wind_key.js): { seconds: added, left: seconds now }. */
  springWound: "spring_wound",
  /** The spring ran out (the courier winds down): { time: seconds since the level started }. */
  springEmpty: "spring_empty",
  /** An enemy or hazard caught the courier: { by: string }. The courier lies down for a moment, then is back at the last
   *  checkpoint (the level goes on, the spring pays a small penalty): see Courier.caught(). */
  courierCaught: "courier_caught",
  /** A checkpoint was touched: { checkpoint: entity id, position: [x, y, z] }. */
  checkpointReached: "checkpoint_reached",
  /** The level was won: { level: id, time, springLeft, stars: 1..3, goals: { fast, springy, thorough }, best: bool }. */
  levelCompleted: "level_completed",
  /** The level was lost: { level: id, reason: "spring_empty" } (a catch is not a loss: see courierCaught). */
  levelFailed: "level_failed",
  /** A guard dog noticed the courier and starts barking and chasing: { dog: entity id, position: [x, y, z] of the dog }. */
  dogAlerted: "dog_alerted",
  /** A guard dog lost the courier for good and goes back to its route: { dog: entity id }. */
  dogGaveUp: "dog_gave_up",
  /** The pause menu opened. */
  gamePaused: "game_paused",
  /** The pause menu closed. */
  gameResumed: "game_resumed",
});

/** Sends an event to every listener of the scene (world.emit with a name from EVENTS). */
export function emit(name, data = {}) {
  world.emit(name, data);
}
