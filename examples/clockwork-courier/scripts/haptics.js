// @ts-check
// Haptics: short pulses of the phone's vibration motor (input.vibrate), one per game moment, behind the "Haptics" option.
// pulse(kind) is a no-op where the option is off; on a desktop or a tablet without a motor input.vibrate does nothing,
// and a headless run records the calls (tests read game.vibrations()).
//
//   land      a hard landing (courier.js)        catch      a guard dog got the courier (comfort.js)
//   delivery  a parcel handed in (comfort.js)    springLow  the spring went under a quarter (comfort.js)
import { input } from "factoria";
import * as settings from "./settings.js";

/** Seconds of vibration per moment: a tap for small things, a buzz for a catch. iOS rounds them to a light, medium or heavy tap. */
export const PULSES = { land: 0.03, catch: 0.25, delivery: 0.08, springLow: 0.12 };

/** Vibrates for the moment `kind`. Returns true when a pulse was asked for (the option is on). */
export function pulse(kind) {
  const seconds = PULSES[kind];
  if (seconds === undefined) throw new Error(`haptics.pulse: unknown moment "${kind}". Known: ${Object.keys(PULSES).join(", ")}`);
  if (!settings.load().haptics) return false;
  input.vibrate(seconds);
  return true;
}
