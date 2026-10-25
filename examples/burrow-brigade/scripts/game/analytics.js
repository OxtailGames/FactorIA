// @ts-check
// Opt-in analytics. OFF until the player says yes: the title shows a consent card until it is answered (scripts/title_online.js),
// and Options has the same switch. Without a yes nothing is queued and nothing is sent: `record` returns before it queues and
// `flush` returns before it builds a request. Events: floor_reached, shift_ended, quit (no id, name, device or seed in any).
//
//   consent()      "unknown" (never asked), "granted" or "denied"; kept in storage under "burrow.online".
//   setConsent(b)  true / false. Saying no forgets what was waiting to be sent.
//   enabled()      consent() === "granted"
//   start()/stop() subscribe / unsubscribe to the game events (events.keep). Idempotent.
//   flush()        sends the waiting events (one request); resolves { sent, ok }.
//   quit()         records the "quit" event and flushes (the Quit button calls it: the engine has no event for closing the window).
//   queued()       the events waiting to be sent (tests).
//
// Three events, each a name, the time of the run in whole seconds and a few numbers. No player id, no name, no device, no text the
// player typed:
//   shift_ended   { outcome, stratum, floor, players, banked, seconds }
//   floor_reached { stratum, floor, players }
//   quit          { shifts }   how many shifts the session played
import { storage } from "factoria";
import * as events from "./events.js";
import * as online from "./online.js";

export const KEY = "burrow.online";
/** Events kept while waiting for a flush; the oldest go first. */
export const MAX_QUEUE = 50;
/** The whole-session counters (not saved). */
const session = { shifts: 0, stratum: 0, floor: 0, players: 1 };
/** @type {Array<{name: string, data: Record<string, number|string>}>} */
let queue = [];
/** @type {Array<() => void>} */
let unsubscribers = [];

/** @returns {"unknown"|"granted"|"denied"} */
export function consent() {
  const v = storage.get(KEY, null);
  const c = v && typeof v === "object" ? v.analytics : null;
  return c === "granted" || c === "denied" ? c : "unknown";
}

/** Whether the player was asked already (the first-launch prompt shows only while this is false). */
export function asked() {
  return consent() !== "unknown";
}

export function enabled() {
  return consent() === "granted";
}

/** @param {boolean} yes */
export function setConsent(yes) {
  const v = storage.get(KEY, {});
  storage.set(KEY, { ...(v && typeof v === "object" ? v : {}), analytics: yes ? "granted" : "denied" });
  if (!yes) queue = [];
}

/** Adds an event to the queue, only with consent. @param {string} name @param {Record<string, number|string>} data */
function record(name, data) {
  if (!enabled()) return;
  queue.push({ name, data });
  if (queue.length > MAX_QUEUE) queue.shift();
}

export function queued() {
  return queue.map((e) => ({ name: e.name, data: { ...e.data } }));
}

/** Sends what waits. Resolves { sent: number, ok: boolean }; a failed send keeps the events for the next flush. */
export async function flush() {
  if (!enabled() || !queue.length) return { sent: 0, ok: true };
  const batch = queue;
  queue = [];
  const r = await online.request("POST", online.PATHS.analytics, { events: batch });
  if (!r.ok) {
    if (enabled()) queue = [...batch, ...queue].slice(-MAX_QUEUE);
    return { sent: 0, ok: false };
  }
  return { sent: batch.length, ok: true };
}

/** The Quit button: record and send, then the caller quits. */
export async function quit() {
  record("quit", { shifts: session.shifts });
  return flush();
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
  queue = [];
  Object.assign(session, { shifts: 0, stratum: 0, floor: 0, players: 1 });
}
