// @ts-check
// The mix of the game, in one place: the engine has four bus volumes (master, music, sfx, ui) and nothing else (no filters,
// no reverb, no ducking, no snapshots: ENGINE_FEEDBACK FB-0025/FB-0026), so this module EMULATES them with the bus volumes.
// The volume a bus really gets is   user volume (Options)  x  snapshot factor  x  duck factor (music only).
//
//   setUser(bus, v)          the options slider of a bus (settings.apply calls it)
//   snapshot(name)           "normal", "paused", "underwater" or "cavern": a named set of factors per bus, eased in over time
//   duck(seconds, depth)     lowers the music for a while (an alarm, a cave-in); depth 0..1 is how much is taken away
//   tick(dt)                 eases the factors toward their targets and writes the bus volumes (call it every frame, with
//                            unscaled time, from the shift and from the pause menu)
//   level(bus)               the volume last written to a bus (tests read it)
//   reset()                  back to "normal", no duck (a new scene)
import { audio } from "factoria";

const BUSES = ["master", "music", "sfx", "ui"];

/** Factor per bus of every snapshot, and the pitch of the music bus is not available (FB-0025), so a "muffled" sound is only quieter. */
export const SNAPSHOTS = {
  normal: { master: 1, music: 1, sfx: 1, ui: 1 },
  paused: { master: 1, music: 0.45, sfx: 0.35, ui: 1 },
  underwater: { master: 1, music: 0.55, sfx: 0.6, ui: 1 },
  cavern: { master: 1, music: 1, sfx: 1, ui: 1 },
};

/** Seconds a snapshot takes to settle. */
export const EASE = 0.2;

const user = { master: 1, music: 1, sfx: 1, ui: 1 };
const factor = { master: 1, music: 1, sfx: 1, ui: 1 };
let target = "normal";
let duckLeft = 0;
let duckDepth = 0;
let duckFactor = 1;
/** @type {Record<string, number>} */
const written = {};

export function setUser(bus, v) {
  user[bus] = v;
  write();
}

export function userVolume(bus) {
  return user[bus];
}

/** @param {string} name */
export function snapshot(name) {
  if (SNAPSHOTS[name]) target = name;
}

export function snapshotName() {
  return target;
}

/** Lowers the music for `seconds` (the longest ask wins). */
export function duck(seconds, depth = 0.5) {
  duckLeft = Math.max(duckLeft, seconds);
  duckDepth = Math.max(duckDepth, depth);
}

export function ducking() {
  return duckLeft > 0;
}

export function tick(dt) {
  const goal = SNAPSHOTS[target];
  const k = Math.min(1, dt / EASE);
  for (const b of BUSES) factor[b] += (goal[b] - factor[b]) * k;
  if (duckLeft > 0) duckLeft = Math.max(0, duckLeft - dt);
  else duckDepth = 0;
  const duckGoal = duckLeft > 0 ? 1 - duckDepth : 1;
  duckFactor += (duckGoal - duckFactor) * Math.min(1, dt / 0.15);
  write();
}

function write() {
  for (const b of BUSES) {
    const v = round(user[b] * factor[b] * (b === "music" ? duckFactor : 1));
    written[b] = v;
    audio.setVolume(b, v); // every time: a scene load may have put the engine's own volumes back
  }
}

function round(v) {
  return Math.round(v * 1000) / 1000;
}

/** The volume last written to a bus. */
export function level(bus) {
  return written[bus] ?? user[bus];
}

/** Back to the normal mix (a scene load; the options volumes stay). */
export function reset() {
  target = "normal";
  duckLeft = 0;
  duckDepth = 0;
  duckFactor = 1;
  for (const b of BUSES) factor[b] = 1;
  write();
}
