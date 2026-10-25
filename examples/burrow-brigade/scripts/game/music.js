// @ts-check
// The music of the mine, in one place: nothing else calls `audio.music`. Every stratum has a looping track (STRATA[n].music in
// generator.js), and the shift asks for the one of its stratum. Loading a scene stops the audio (docs/AI_GUIDE.md, "loading a
// scene stops the audio"), so EVERY shift starts its track again, fading it in; the track is the same from floor to floor of a
// stratum and changes when the run goes down to the next stratum.
//
// LAYERS. The engine plays one music stream and cannot change the volume of a voice that already plays (ENGINE_FEEDBACK
// FB-0025), so the layers are EMULATED: each stratum has two short loops that are exactly one bar of its track long
// (assets/music/music_<stratum>_danger.wav and _fight.wav, made by assets/src/make_music_layers.py). A layer comes in by
// starting its loop on the music bus at the next bar line of the track, and goes out by stopping it at a bar line, so it stays
// in time. The layers follow the enemies:
//   danger  an enemy sees a miner, or saw one less than CHASE_MEMORY seconds ago (the chase), or the Mole King is awake;
//           it stays HOLD seconds after the chase ends, then falls out at the next bar line
//   fight   an enemy is winding up an attack or is within FIGHT_RANGE of the miner it chases, or a miner was hurt in the last
//           HOLD seconds
// `tick` also runs the mix (mix.js: ducking, the "paused", "underwater" and "cavern" snapshots) and the sound echo, because
// the music driver is the one behaviour that runs every frame, also while the game is paused.
//
//   play(stratum)   starts the stratum's track (call it when a scene starts); returns true when the track differs from the last one
//   stop()          the shift is over: forgets the layers and puts the mix back to normal
//   current()       the path of the track started last, or "" before the first
//   forStratum(n)   the path for a stratum number;  layerPath(stratum, layer) the path of a layer's loop
//   layers()        { danger, fight } each { wanted, playing }: what the music is doing (tests read it)
//   tick(dt)        advances the music clock by REAL seconds (the default export, a Behaviour, calls it every frame)
//   reset()         forgets what played (startRun calls it)
import { Behaviour, audio, time, game } from "factoria";
import { stratumInfo } from "./generator.js";
import { miners, enemies } from "./actors.js";
import { live } from "./mine_map.js";
import { K } from "./tiles.js";
import * as events from "./events.js";
import * as mix from "./mix.js";
import * as sound from "./sound.js";

/** Volume of the track on the "music" bus (the options menu scales the bus). */
export const VOLUME = 0.8;
/** Seconds the track fades in. */
export const FADE = 1.5;
/** Volume of each layer's loop. */
export const LAYER_VOLUME = { danger: 0.55, fight: 0.6 };
/** Length in seconds of one bar of each stratum's track (the layers are one bar long). */
export const BAR = [60 / 96 * 4, 60 / 76 * 4, 60 / 112 * 4];
/** Seconds after an enemy last saw a miner that it still counts as a chase. */
export const CHASE_MEMORY = 3;
/** Seconds a layer stays after its reason ended. */
export const HOLD = 1.5;
/** World units: an enemy this near the miner it chases means a fight. */
export const FIGHT_RANGE = 56;
/** Tiles: a window this wide around the miners is looked at to tell a cavern; open tiles in it to enter and to leave the cavern. */
export const CAVERN_WINDOW = 11;
export const CAVERN_ENTER = 85;
export const CAVERN_LEAVE = 65;

const LAYER_NAMES = ["danger", "fight"];

let playing = "";
let stratumNow = 0;
let clock = 0;
let hurtLeft = 0;
let unsub = null;
/** @type {Record<string, {wanted: boolean, hold: number, voice: number|null}>} */
let state = fresh();
let inCavern = false;

function fresh() {
  return { danger: { wanted: false, hold: 0, voice: null }, fight: { wanted: false, hold: 0, voice: null } };
}

/** Path of the track of a stratum. */
export function forStratum(stratum) {
  return stratumInfo(stratum).music;
}

/** Path of the loop of a layer ("danger" or "fight") of a stratum. */
export function layerPath(stratum, layer) {
  return forStratum(stratum).replace(/\.wav$/, `_${layer}.wav`);
}

/** The track started last ("" when none). */
export function current() {
  return playing;
}

/**
 * Starts the track of a stratum (a scene load stopped whatever played before, so it always starts). Returns true when the
 * track is a different one from the track of the last call (the stratum changed), false when it is the same one again.
 * @param {number} stratum
 */
export function play(stratum) {
  const path = forStratum(stratum);
  const changed = path !== playing;
  playing = path;
  stratumNow = stratum;
  clock = 0;
  hurtLeft = 0;
  state = fresh(); // the scene load stopped the old voices
  inCavern = false;
  mix.reset();
  unsub?.();
  unsub = events.on("playerHurt", () => (hurtLeft = HOLD));
  audio.music(path, { volume: VOLUME, fade: FADE });
  return changed;
}

/** The shift is over: no layers, no echo, the mix back to normal (the volumes of the options stay). */
export function stop() {
  unsub?.();
  unsub = null;
  for (const name of LAYER_NAMES) if (state[name].voice !== null) audio.stop(state[name].voice);
  state = fresh();
  sound.reset();
  mix.reset();
}

/** Forgets the current track (the next `play` starts it again). */
export function reset() {
  playing = "";
  state = fresh();
}

/** What the layers do: `wanted` is what the fight asks for, `playing` is whether the loop sounds now (it changes on a bar line). */
export function layers() {
  return {
    danger: { wanted: state.danger.wanted, playing: state.danger.voice !== null },
    fight: { wanted: state.fight.wanted, playing: state.fight.voice !== null },
  };
}

/** Seconds into the track (real time, from `play`). */
export function position() {
  return clock;
}

/** What the enemies ask of the layers right now: { danger, fight } booleans (before the hold). */
export function want() {
  let danger = false, fight = false;
  for (const e of enemies()) {
    if (e.dead || !e.stats) continue;
    if (e.kind === "king") {
      if (e.awake) danger = true;
      if (e.awake && e.target) fight = true;
    } else if (e.target || (e.lastSeen && e.lastSeen.age < CHASE_MEMORY)) {
      danger = true;
    }
    if (e.telegraphing || (e.target && e.targetDist < FIGHT_RANGE)) fight = true;
  }
  if (hurtLeft > 0) fight = true;
  return { danger, fight: fight };
}

function openAround() {
  const map = live.map;
  const here = miners();
  if (!map || here.length === 0) return 0;
  // the window sits on the first miner in play (a co-op team fights in the cave the first miner is in)
  const c = here[0];
  const r = Math.floor(CAVERN_WINDOW / 2);
  let open = 0;
  for (let dy = -r; dy <= r; dy++) for (let dx = -r; dx <= r; dx++) if (map.isWalkable(c.tx + dx, c.ty + dy)) open++;
  return open;
}

/** The snapshot the place asks for: "underwater" when half or more of the miners stand in water, "cavern" in a wide open cave, else "normal". */
export function placeSnapshot() {
  const map = live.map;
  if (!map) return "normal";
  const here = miners();
  if (here.length > 0 && here.filter((m) => map.kindAt(m.tx, m.ty) === K.WATER).length * 2 >= here.length) return "underwater";
  const open = openAround();
  inCavern = inCavern ? open >= CAVERN_LEAVE : open >= CAVERN_ENTER;
  return inCavern ? "cavern" : "normal";
}

/**
 * Advances the music by `dt` REAL seconds: the bar clock, the layers, the mix, the echo.
 * @param {number} dt
 */
export function tick(dt) {
  const before = clock;
  clock += dt;
  hurtLeft = Math.max(0, hurtLeft - dt);
  const asked = playing && !game.paused ? want() : { danger: false, fight: false };
  for (const name of LAYER_NAMES) {
    const l = state[name];
    if (asked[name]) {
      l.wanted = true;
      l.hold = HOLD;
    } else {
      l.hold = Math.max(0, l.hold - dt);
      if (l.hold === 0) l.wanted = false;
    }
  }
  const bar = BAR[stratumNow] ?? BAR[0];
  if (playing && Math.floor(clock / bar) > Math.floor(before / bar)) {
    // a bar line: layers come in and go out here, so they stay in time with the track
    for (const name of LAYER_NAMES) {
      const l = state[name];
      if (l.wanted && l.voice === null) {
        l.voice = audio.play(layerPath(stratumNow, name), { volume: LAYER_VOLUME[name], bus: "music", loop: true });
      } else if (!l.wanted && l.voice !== null) {
        audio.stop(l.voice);
        l.voice = null;
      }
    }
  }
  mix.snapshot(game.paused ? "paused" : playing ? placeSnapshot() : "normal");
  mix.tick(dt);
  sound.tick(dt);
}

/** Put this on one entity of the shift scene: it runs every frame, also while the game is paused, on real time. */
export default class MusicDriver extends Behaviour {
  runWhilePaused = true;

  onUpdate() {
    tick(time.unscaledDt);
  }
}
