// @ts-check
// The daily route: once a calendar day the game offers one open level with its parcels laid out differently, the same
// for every player and every run of that date. Everything is picked from the date, never from the world RNG:
//
//   seed   = FNV-1a hash of "YYYY-MM-DD"
//   level  = one of the levels the player has open (r.pick), r = rng.create(seed), so it does not touch the game's RNG
//   order  = a shuffle of the level's parcel slots (r.shuffle); never the identity, so the parcels always move.
//            The level has parcels + optionalParcels parcel entities; sorted by id, entity i takes the place where entity
//            order[i] normally lies. Required and bonus parcels trade places, and a bonus parcel becomes a "must".
//
// The pick is saved with the profile the first time it is asked for that day (progress.setDailyRoute), so unlocking a level
// at noon does not change the route the player already started. Finishing it records a time for the date (its own best,
// no stars) and sends daily_route_finished { date, level, time } (scripts/events.js) for the leaderboards and
// achievements of P4.
//
//   routeFor(date, levelIds)   the pure pick (tests call it for any date)
//   current()                  today's route, saved on first use
//   start(route) / active()    session.daily: the level scene reads it (level_flow.js) when it starts
//   place(route, entities)     moves the parcel entities of the running level to the route's layout
//   finish(time)               records a finished run of the active route
import { rng, session, world } from "factoria";
import { LEVELS } from "./levels.js";
import * as clock from "./clock.js";
import * as progress from "./progress.js";
import { EVENTS, emit } from "./events.js";

/** Ids of the parcel entities of the level scenes: parcel_1, parcel_bonus_1 (not the HUD's parcel_text). */
const PARCEL_ID = /^parcel(_bonus)?_\d+$/;

/** FNV-1a, 32 bits, of a string: the seed of a date. */
export function seedOf(text) {
  let h = 0x811c9dc5;
  for (let i = 0; i < text.length; i++) {
    h ^= text.charCodeAt(i);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return h >>> 0;
}

/** @returns {import("./save_data.js").DailyRoute} the route of `date` among the given open levels (never empty: the first level is always open) */
export function routeFor(date, levelIds) {
  const r = rng.create(seedOf(date));
  const ids = levelIds.length ? levelIds : [LEVELS[0].id];
  const level = r.pick(ids);
  const entry = LEVELS.find((l) => l.id === level) ?? LEVELS[0];
  const slots = entry.parcels + entry.optionalParcels;
  let order = r.shuffle(Array.from({ length: slots }, (_, i) => i));
  if (order.every((v, i) => v === i) && slots > 1) order = order.slice(1).concat(order[0]); // rotate: never the normal layout
  return { date, level, order };
}

/** Ids of the levels the player has open (the pool of the daily pick). */
export function openLevels() {
  return LEVELS.filter((l) => progress.isUnlocked(l.id)).map((l) => l.id);
}

/** Today's route; picked and saved the first time it is asked for on a date. */
export function current() {
  const date = clock.today();
  const saved = progress.dailyRoute();
  if (saved && saved.date === date) return saved;
  const route = routeFor(date, openLevels());
  progress.setDailyRoute(route);
  return route;
}

/** The player's best finished time of today's route, or null. */
export function todaysTime() {
  return progress.dailyTime(clock.today())?.time ?? null;
}

/** Marks `route` as the run in progress (the level scene loaded next plays it). */
export function start(route) {
  session.daily = { ...route, active: true };
}

/** The route being played in this scene, or null (a normal run). Starting a normal level calls clear(). */
export function active() {
  const d = session.daily;
  return d && d.active ? d : null;
}

export function clear() {
  session.daily = null;
}

/**
 * Lays the parcels of the running level out as the route says. The parcel entities are the ones with an id like
 * parcel_1 or parcel_bonus_1: sorted by id, entity i goes to the place of entity route.order[i]. Returns false when the level does not have
 * as many parcels as the route expects (the route is then ignored).
 */
export function place(route) {
  const parcels = world.entities().filter((e) => PARCEL_ID.test(e.id));
  parcels.sort((a, b) => (a.id < b.id ? -1 : 1));
  if (parcels.length !== route.order.length) return false;
  const spots = parcels.map((p) => [p.position.x, p.position.y, p.position.z]);
  parcels.forEach((p, i) => {
    const s = spots[route.order[i]];
    p.position = s;
    if (p.behaviour) p.behaviour.baseY = s[1]; // the parcel bobs around the height it started at
  });
  return true;
}

/** A finished run of the active route: saves the time, sends the event. Returns { date, level, time, best }. */
export function finish(time) {
  const route = active();
  if (!route) return null;
  const best = progress.recordDaily(route.date, route.level, time);
  emit(EVENTS.dailyRouteFinished, { date: route.date, level: route.level, time });
  return { date: route.date, level: route.level, time, best };
}
