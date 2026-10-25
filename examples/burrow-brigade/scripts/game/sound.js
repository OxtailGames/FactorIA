// @ts-check
// Every sound effect of a shift goes through here: `play(path, opts, cue)` is audio.play with the sfx bus, plus the CAPTION of
// the sound when it is one a player must notice (a beetle, a rumble, a lamp running dry). The captions are always put on the
// caption list (game.captions() in a test lists them); the scene's "sound_captions" entity draws them, and the Options >
// Accessibility "Sound captions" switch turns that entity on or off (settings.applySubtitles).
//
// A cue says where the sound is: `{ key, x, y }` (world position) or `{ key, tx, ty }` (tile). The caption then ends with a
// direction word from the nearest miner ("left", "right", "above", "below", or "here" when it is next to it), so a player who
// cannot hear the room can tell where to look.
//
//   play(path, opts, cue?)   plays the sound; returns the voice id. A cue with `duck` seconds also ducks the music (mix.js)
//   direction(x, y)          "left" | "right" | "up" | "down" | "here" | "" (no miner in play), seen from the nearest miner
//   captionFor(cue)          the text a cue shows now
import { audio, i18n } from "factoria";
import { nearestMiner } from "./actors.js";
import { live } from "./mine_map.js";
import * as mix from "./mix.js";

/** World units: nearer than this to the nearest miner counts as "here". */
export const HERE = 20;
/** Seconds a caption stays. */
export const SECONDS = 2.5;

/** The direction of a world point seen from the nearest miner. */
export function direction(x, y) {
  const near = nearestMiner(x, y);
  if (!near) return "";
  const dx = x - near.miner.x;
  const dy = y - near.miner.y;
  if (Math.hypot(dx, dy) < HERE) return "here";
  // world +y points up on screen (the camera is orthographic, y up)
  if (Math.abs(dx) >= Math.abs(dy)) return dx < 0 ? "left" : "right";
  return dy > 0 ? "up" : "down";
}

/** @typedef {{key: string, x?: number, y?: number, tx?: number, ty?: number, duck?: number, depth?: number}} Cue */

/** Where a cue is, in world units (null: no position given). */
function where(cue) {
  if (cue.x !== undefined && cue.y !== undefined) return { x: cue.x, y: cue.y };
  if (cue.tx !== undefined && cue.ty !== undefined && live.map) return live.map.tileCenter(cue.tx, cue.ty);
  return null;
}

/** @param {Cue} cue */
export function captionFor(cue) {
  const text = i18n.t(cue.key);
  const at = where(cue);
  if (!at) return text;
  const dir = direction(at.x, at.y);
  return dir ? i18n.t("caption.where", { text, dir: i18n.t(`caption.dir.${dir}`) }) : text;
}

/**
 * Plays a sound effect on the sfx bus, with a caption when `cue` is given.
 * @param {string} path
 * @param {{volume?: number, pitch?: number, loop?: boolean}} [opts]
 * @param {Cue} [cue]
 */
export function play(path, opts = {}, cue) {
  /** @type {any} */
  const o = { bus: "sfx", ...opts };
  if (cue && cue.duck) mix.duck(cue.duck, cue.depth ?? 0.4); // an alarm: the music steps back while it lasts
  if (cue && cue.key) {
    o.caption = captionFor(cue);
    o.captionKey = undefined;
    o.captionSeconds = SECONDS;
  }
  const voice = audio.play(path, o);
  if (cue && mix.snapshotName() === "cavern") {
    const echo = { ...o, volume: (o.volume ?? 1) * ECHO_GAIN, caption: undefined, captionKey: undefined, captionSeconds: undefined };
    echoes.push({ left: ECHO_DELAY, path, opts: echo });
  }
  return voice;
}

// ---- echo -------------------------------------------------------------------------------------------------------------
// In a big cavern (mix snapshot "cavern") a cued sound comes back once, quieter: the engine has no reverb (FB-0026), so the
// echo is the same clip played again after ECHO_DELAY seconds at ECHO_GAIN of the volume.

/** Seconds before the echo. */
export const ECHO_DELAY = 0.22;
/** Volume of the echo relative to the sound. */
export const ECHO_GAIN = 0.3;

/** @type {Array<{left: number, path: string, opts: any}>} */
let echoes = [];

/** Plays the echoes that are due (the music driver calls it with real seconds). */
export function tick(dt) {
  if (echoes.length === 0) return;
  for (const e of echoes) e.left -= dt;
  const due = echoes.filter((e) => e.left <= 0);
  echoes = echoes.filter((e) => e.left > 0);
  for (const e of due) audio.play(e.path, e.opts);
}

/** The echoes waiting to sound (tests read it). */
export function pendingEchoes() {
  return echoes.length;
}

/** Forgets the echoes that wait (the shift ended). */
export function reset() {
  echoes = [];
}
