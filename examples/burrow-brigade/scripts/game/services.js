// @ts-check
// Starts and stops the online services of the game as one: achievements and stats (trophies.js), the boards (boards.js), rich
// presence (presence.js), remote balance values (balance.js) and the opt-in analytics (analytics.js). Every service listens to the
// game events with events.keep, so one `start()` lasts through every run. Scenes call `start()` in onStart: it is idempotent.
//
//   start()   subscribes the services. Nothing is sent by this: balance and news are asked for by the title (title_online.js),
//             analytics sends only with the player's consent.
//   stop()    unsubscribes and forgets (tests).
//   idle()    resolves when every service has no store call left in flight.
import * as trophies from "./trophies.js";
import * as boards from "./boards.js";
import * as presence from "./presence.js";
import * as balance from "./balance.js";
import * as analytics from "./analytics.js";

let started = false;

export function start() {
  if (started) return;
  started = true;
  trophies.start();
  boards.start();
  presence.start();
  balance.start();
  analytics.start();
}

export function stop() {
  started = false;
  trophies.stop();
  boards.stop();
  presence.stop();
  balance.stop();
  analytics.stop();
}

export function isStarted() {
  return started;
}

export async function idle() {
  await Promise.all([trophies.idle(), boards.idle(), presence.idle()]);
  await Promise.all([trophies.idle(), boards.idle(), presence.idle()]);
}
