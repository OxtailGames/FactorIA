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
  /** A parcel was handed in at a delivery door: { door: entity id, delivered: n, total: n }. */
  parcelDelivered: "parcel_delivered",
  /** The spring was wound (P2 wind-up keys): { seconds: added, left: seconds now }. */
  springWound: "spring_wound",
  /** The spring ran out (the courier winds down): { time: seconds since the level started }. */
  springEmpty: "spring_empty",
  /** An enemy or hazard caught the courier: { by: string }. */
  courierCaught: "courier_caught",
  /** A checkpoint was touched: { checkpoint: entity id, position: [x, y, z] }. */
  checkpointReached: "checkpoint_reached",
  /** The level was won: { level: id, time: seconds, springLeft: seconds, stars: 0..3 }. */
  levelCompleted: "level_completed",
  /** The level was lost: { level: id, reason: "spring_empty" | "caught" }. */
  levelFailed: "level_failed",
  /** The pause menu opened. */
  gamePaused: "game_paused",
  /** The pause menu closed. */
  gameResumed: "game_resumed",
});

/** Sends an event to every listener of the scene (world.emit with a name from EVENTS). */
export function emit(name, data = {}) {
  world.emit(name, data);
}
