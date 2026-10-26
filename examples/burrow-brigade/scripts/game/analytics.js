// @ts-check
// Opt-in analytics on the engine's `analytics` service (docs/ANALYTICS.md). OFF until the player says yes: the title shows a
// consent card until it is answered (scripts/title_online.js), and Options has the same switch. Without a yes the engine keeps
// nothing and sends nothing: `analytics.event` returns false. The engine batches, retries after a failure, and sends what waits
// when the app is suspended and when the game quits, so this file only says WHAT is counted. The server address is the
// placeholder in factoria.json (see the README, "Server addresses").
//
//   consent()      "unknown" (never asked), "granted" or "denied"; kept by the engine.
//   asked()        consent() !== "unknown"
//   enabled()      consent() === "granted"
//   setConsent(b)  true / false. Saying no forgets what was waiting to be sent.
//   start()/stop() subscribe / unsubscribe to the game events (events.keep). Idempotent.
//   flush()        sends the waiting events now (one request); resolves { sent, ok }.
//   recordQuit()   queues the "quit" event; the engine's quit flush sends it.
//
// Three events, each a name and a few numbers. No player id, no name, no device, no text the player typed:
//   shift_ended   { outcome, stratum, floor, players, banked, seconds }
//   floor_reached { stratum, floor, players }
//   quit          { shifts }   how many shifts the session played
import { analytics } from "factoria";
import * as events from "./events.js";

/** The whole-session counters (not saved). */
const session = { shifts: 0, stratum: 0, floor: 0, players: 1 };
/** @type {Array<() => void>} */
let unsubscribers = [];

/** @returns {"unknown"|"granted"|"denied"} */
export function consent() {
  return analytics.consent();
}

/** Whether the player was asked already (the first-launch card shows only while this is false). */
export function asked() {
  return consent() !== "unknown";
}

export function enabled() {
  return consent() === "granted";
}

/** @param {boolean} yes */
export function setConsent(yes) {
  analytics.setConsent(yes);
}

/** Queues an event; the engine returns false (and keeps nothing) without consent. @param {string} name @param {Record<string, number|string>} props */
function record(name, props) {
  analytics.event(name, props);
}

/** Sends what waits. Resolves { sent: number, ok: boolean }; a failed send keeps the events for a later try. */
export function flush() {
  return enabled() ? analytics.flush() : Promise.resolve({ sent: 0, ok: true });
}

/** The Quit button: queue the event, then the caller quits (the engine waits up to 3 seconds for the send). */
export function recordQuit() {
  record("quit", { shifts: session.shifts });
}

export function start() {
  if (unsubscribers.length) return;
  unsubscribers = [
    events.keep("shiftStarted", (d) => {
      session.stratum = d.stratum;
      session.floor = d.floor;
      session.players = d.players ?? 1;
      record("floor_reached", { stratum: d.stratum, floor: d.floor, players: session.players });
    }),
    events.keep("shiftEnded", (d) => {
      session.shifts++;
      record("shift_ended", {
        outcome: d.outcome, stratum: d.stratum ?? session.stratum, floor: d.floor ?? session.floor,
        players: session.players, banked: d.banked ?? 0, seconds: Math.round(d.time ?? 0),
      });
      void flush();
    }),
  ];
}

export function stop() {
  for (const off of unsubscribers) off();
  unsubscribers = [];
  Object.assign(session, { shifts: 0, stratum: 0, floor: 0, players: 1 });
}
