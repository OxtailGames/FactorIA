// @ts-check
// The cut-scene player. A cut-scene is a file data/cutscenes/<id>.cutscene.json (format larkspur.cutscene/1, written by
// assets/src/build_cutscenes.py, checked by the project tool `project.validate_cutscenes` and by scripts/cutscene_check.js): a
// timeline of steps, each with the second `at` it starts. The player runs it on the engine clock (so it stops when the game is
// paused and a test with game.step() sees exactly the same), takes the camera and the actors it names and gives them back at the end.
//
//   import * as cutscene from "./cutscene.js";
//   cutscene.play("intro");                 // { id, played, queued, skippable, reason? }
//   cutscene.active();                      // true from play() until the end state is in place (a queued one counts too)
//   cutscene.seen();                        // [{ id, skipped }] that have ended since the game began
//
// Steps ("do"):
//   fade     { to: 0..1, seconds }                     the black overlay of the HUD
//   camera   { pos, look, seconds, ease }              the camera moves from where it is to pos looking at `look` (world metres)
//   caption  { key, seconds, voice?, speaker? }        a subtitle; with `voice` (a clip of data/cutscenes/voice.json) the clip plays on the
//                                                      voiceover bus and the subtitle lasts as long as the clip, else `seconds`
//   card     { key, seconds }                          a line of big text in the middle of the screen (a title card)
//   move     { actor, to: [x, z], seconds, clip, yaw } the actor walks (clip "walk" or "run" for the porter) and ends facing `yaw`
//   face     { actor, toward: actor }                  the actor turns to another
//   anim     { actor, clip }                           the actor plays a clip once
// Actors: "porter" (the player's body: it is placed by hand, `start` [x, z, yaw] moves it first, `keep` leaves it where the scene
// ends it), "npc" (a character of the cast who already stands in the area; with `start` one is made if nobody does), "extra" (a body made
// for the scene and removed at its end).
//
// The end state ("end": { fade, set: [{ set: flag }] }) is applied when the timeline runs out and when the player skips: skipping
// (the `skip_cutscene` action - Space, gamepad B - or the Skip button, a tap on a phone) finishes every move and camera move at once, stops
// the voice, clears the captions and applies it, so a skipped cut-scene and a watched one leave the game in the same state.
//
// While one runs: the porter is locked (lock("cutscene")) and puppeted, the camera is directed (scripts/lodge_camera.js direct()),
// EVENTS.cutsceneStarted / cutsceneEnded are sent, the voiceover bus gets the reverb of the cut-scene's room and the music ducks under
// the voice (scripts/mix.js). The pause menu still works: scripts/cutscene_view.js hands the pause to pause(); the timeline stops and the
// voice line that was speaking is said again from its start when the game goes on.
//
// The tick comes from scripts/cutscene_view.js (the `cutscene_ui` entity of the HUD), so a scene without a HUD cannot play one: play()
// answers { played: false, reason } and says why in the log. The player holds its state in this module and drops it when the scene it
// started in is not the current one (a result for another scene is never acted on).
import { world, scene, session, audio, ui, i18n, input, didYouMean } from "factoria";
import { EVENTS, emit } from "./events.js";
import * as story from "./story.js";
import * as mix from "./mix.js";
import { parseEffect } from "./conditions.js";
import { bodyJson } from "./cast.js";
import { cast } from "./dialogue_data.js";
import { CUTSCENES, voice as voiceFile } from "./cutscene_data.js";

const DEG = Math.PI / 180;
/** The porter's speed for the clips a move step may name, m/s (scripts/porter.js walkSpeed and runSpeed). */
const CLIP_SPEED = Object.freeze({ walk: 2.4, run: 4.6, idle: 0 });
/** Seconds the Skip button of a skipped cut-scene takes to bring the screen to the end state's fade. */
const SKIP_FADE = 0.4;
/** Seconds of a cut-scene during which the skip key is ignored. */
const SKIP_GUARD = 0.25;
const EASES = Object.freeze({
  linear: (k) => k,
  in: (k) => k * k,
  out: (k) => 1 - (1 - k) * (1 - k),
  inOut: (k) => k * k * (3 - 2 * k),
});

/** @type {any} */
let view = null;
/** The cut-scene that plays now, or null. */
let run = null;
/** Cut-scenes asked while one plays: [{ id, opts }]. */
const queue = [];
/** Voice clips added by a test or a tool on top of data/cutscenes/voice.json: id -> { path, seconds }. */
let extraClips = {};

// ---------------------------------------------------------------------------------------------------------------- state
/** Drops everything that belongs to a scene that is gone. */
function dropIfStale() {
  if (run && (run.scenePath !== scene.current || (run.porter && !run.porter.alive))) drop();
  if (view && view.scenePath !== scene.current) view = null;
}

/** Forgets a cut-scene whose scene is gone (the scene changed, or the same scene was loaded again): its entities and listeners died with it. */
function drop() {
  run = null;
  queue.length = 0;
  mix.leave();
}

/** True from play() until the end state is in place (a cut-scene waiting in the queue counts). */
export function active() {
  dropIfStale();
  return run !== null || queue.length > 0;
}

/** The same as active(): scripts that wait for the end of a cut-scene (chapters, the dialogue box) read this one. */
export function busy() {
  return active();
}

/** The cut-scenes that have ended since the game began, oldest first: [{ id, skipped }] (chapters.begin() starts the list again). */
export function seen() {
  return (session.cutscenesSeen ?? []).map((e) => ({ ...e }));
}

/** What plays now: { id, time, duration, skippable }, or null. */
export function current() {
  dropIfStale();
  return run ? { id: run.id, time: run.t, duration: run.def.duration, skippable: run.skippable } : null;
}

/** The voice clips that exist: data/cutscenes/voice.json plus the ones added with useClips(). */
export function clips() {
  return { ...voiceFile.clips, ...extraClips };
}

/** Adds voice clips ({ id: { path, seconds } }) on top of data/cutscenes/voice.json; `{}` takes them away. Tests use it. */
export function useClips(more) {
  extraClips = { ...more };
}

/** The view (scripts/cutscene_view.js) says it exists in this scene. */
export function attach(v) {
  // A view that starts is a scene that starts: a cut-scene of an earlier scene (also one loaded again from the same file) is over.
  if (run || queue.length > 0) drop();
  view = v;
  mix.setup();
}

// ------------------------------------------------------------------------------------------------------------------ play
/**
 * Plays the cut-scene `id`. Another one is already on: this one waits its turn (queued: true). Returns
 * { id, played, queued, skippable, reason? }: played is false when nothing will play (reason says why).
 */
export function play(id, opts = {}) {
  emit(EVENTS.cutsceneRequested, { id });
  dropIfStale();
  const p = prepare(id, opts);
  if (!p.def) return { id, played: false, queued: false, skippable: p.skippable, reason: p.reason };
  if (run || queue.length > 0) {
    queue.push({ id, opts });
    return { id, played: true, queued: true, skippable: p.skippable };
  }
  start(p.def, p.skippable);
  return { id, played: true, queued: false, skippable: p.skippable };
}

/** Checks that `id` can play in this scene: { def, skippable } or { reason, skippable } (and says why in the log). */
function prepare(id, opts) {
  const def = CUTSCENES[id];
  if (!def) {
    const near = didYouMean(String(id), Object.keys(CUTSCENES));
    console.error(`cutscene: there is no cut-scene '${id}' (data/cutscenes/${id}.cutscene.json). ${near ? `Did you mean '${near}'? ` : ""}Cut-scenes: ${Object.keys(CUTSCENES).join(", ")}.`);
    return { reason: "unknown", skippable: false };
  }
  const skippable = def.skippable !== false && (opts.skippable ?? true);
  if (!view) {
    console.warn(`cutscene: '${id}' was not played: this scene has no HUD with a cutscene_ui entity (prefabs/ui/hud.prefab.json).`);
    return { reason: "no_view", skippable };
  }
  if (def.area && session.area !== def.area) {
    console.warn(`cutscene: '${id}' is shot in the area '${def.area}' but the scene is '${session.area}'; it was not played.`);
    return { reason: "other_area", skippable };
  }
  return { def, skippable };
}

/** Skips the cut-scene that plays: the end state is applied at once. False when none plays or it cannot be skipped. */
export function skip() {
  dropIfStale();
  if (!run || !run.skippable) return false;
  finish(true);
  return true;
}

function start(def, skippable) {
  const hud = world.find("hud")?.behaviour ?? null;
  const porter = world.find("porter");
  run = {
    id: def.id,
    def,
    scenePath: scene.current,
    t: 0,
    next: 0,
    steps: def.timeline,
    skippable,
    paused: false,
    hud,
    camera: world.find("camera")?.behaviour ?? null,
    porter: porter ?? null,
    actors: new Map(),
    moves: new Map(),
    cam: null,
    camTrack: null,
    voiceId: 0,
    line: null,
    warned: new Set(),
  };
  porter?.behaviour?.lock("cutscene");
  if (porter?.behaviour) porter.behaviour.puppet = true;
  resolveActors(def);
  mix.enter(def.room);
  view.begin(skippable);
  emit(EVENTS.cutsceneStarted, { id: def.id, skippable });
}

// ----------------------------------------------------------------------------------------------------------------- actors
function warnOnce(key, text) {
  if (!run || run.warned.has(key)) return;
  run.warned.add(key);
  console.warn(`cutscene '${run.id}': ${text}`);
}

function resolveActors(def) {
  const castCtl = world.find("cast")?.behaviour;
  for (const [name, spec] of Object.entries(def.actors ?? {})) {
    if (spec.as === "porter") {
      if (!run.porter) continue;
      const p = run.porter.position;
      const a = { name, kind: "porter", entity: run.porter, keep: !!spec.keep, temp: false, x: p.x, z: p.z, y: p.y, yaw: run.porter.behaviour?.yaw ?? 0, home: { x: p.x, z: p.z, yaw: run.porter.behaviour?.yaw ?? 0 } };
      run.actors.set(name, a);
      if (spec.start) pose(a, spec.start[0], spec.start[1], spec.start[2] ?? a.yaw);
      continue;
    }
    let entity = spec.as === "npc" && spec.cast ? castCtl?.npc(spec.cast) ?? null : null;
    let temp = false;
    if (!entity) {
      if (!spec.start || !spec.cast) {
        warnOnce(`actor:${name}`, `${name} (${spec.cast ?? "?"}) is not in this area and the cut-scene gives no start for them; their steps are skipped.`);
        continue;
      }
      entity = world.spawn(bodyJson(spec.cast, spec.start[0], spec.start[1], spec.yaw ?? 0, `cs_${name}`));
      temp = true;
    }
    const p = entity.position;
    const rot = entity.get("Transform").rotation;
    const a = { name, kind: "body", entity, keep: !!spec.keep, temp, x: p.x, z: p.z, y: p.y, yaw: rot[1] - 180, home: { x: p.x, z: p.z, yaw: rot[1] - 180 } };
    run.actors.set(name, a);
    if (spec.start && !temp) pose(a, spec.start[0], spec.start[1], spec.yaw ?? a.yaw);
  }
}

/** Puts an actor at (x, z) looking along `yaw`. */
function pose(a, x, z, yaw) {
  a.x = x;
  a.z = z;
  a.yaw = yaw;
  if (a.kind === "porter") {
    a.entity.position = [x, a.y, z];
    if (a.entity.behaviour) a.entity.behaviour.yaw = yaw;
  } else {
    a.entity.position = [x, a.y, z];
    a.entity.get("Transform").rotation = [0, yaw + 180, 0];
  }
}

/** The clip an actor shows: the porter by its speed, a body through its Animator. */
function setClip(a, clip, fade = 0.2) {
  if (a.kind === "porter") {
    if (a.entity.behaviour) a.entity.behaviour.puppetSpeed = CLIP_SPEED[clip] ?? 0;
    return;
  }
  try {
    a.entity.animator?.play(clip, fade);
  } catch (e) {
    warnOnce(`clip:${a.name}:${clip}`, `${a.name} cannot play the clip '${clip}': ${e.message}`);
  }
}

const yawToward = (from, to) => Math.atan2(-(to.x - from.x), -(to.z - from.z)) / DEG;

// -------------------------------------------------------------------------------------------------------------- the steps
function begin(step) {
  switch (step.do) {
    case "fade":
      run.hud?.fadeTo(step.to, step.seconds);
      break;
    case "camera":
      beginCamera(step);
      break;
    case "caption":
      speak(step);
      break;
    case "card":
      view.showCard(i18n.t(step.key), step.seconds);
      break;
    case "move":
      beginMove(step);
      break;
    case "face": {
      const a = run.actors.get(step.actor);
      const b = run.actors.get(step.toward);
      if (a && b) pose(a, a.x, a.z, yawToward(a, b));
      break;
    }
    case "anim": {
      const a = run.actors.get(step.actor);
      if (a) setClip(a, step.clip, 0.15);
      break;
    }
  }
}

function beginCamera(step) {
  const from = run.cam ?? initialCamera();
  run.camTrack = { from, to: { pos: step.pos, look: step.look }, t: 0, seconds: step.seconds, ease: EASES[step.ease] ?? EASES.inOut };
  if (step.seconds <= 0) stepCamera(0);
}

/** Where the camera is when the first camera step starts: where it stands, looking 5 m ahead. */
function initialCamera() {
  const e = world.find("camera");
  const p = e.position;
  const r = e.get("Transform").rotation;
  const pitch = r[0] * DEG;
  const yaw = r[1] * DEG;
  const look = [p.x - Math.sin(yaw) * Math.cos(pitch) * 5, p.y + Math.sin(pitch) * 5, p.z - Math.cos(yaw) * Math.cos(pitch) * 5];
  return { pos: [p.x, p.y, p.z], look };
}

function stepCamera(dt) {
  const tr = run.camTrack;
  if (!tr || !run.camera) return;
  tr.t = Math.min(tr.seconds, tr.t + dt);
  const k = tr.seconds > 0 ? tr.ease(tr.t / tr.seconds) : 1;
  const mixv = (a, b) => a.map((v, i) => v + (b[i] - v) * k);
  run.cam = { pos: mixv(tr.from.pos, tr.to.pos), look: mixv(tr.from.look, tr.to.look) };
  run.camera.direct(run.cam.pos, run.cam.look);
  if (tr.t >= tr.seconds) run.camTrack = null;
}

function beginMove(step) {
  const a = run.actors.get(step.actor);
  if (!a) return;
  const clip = step.clip ?? "walk";
  const dx = step.to[0] - a.x;
  const dz = step.to[1] - a.z;
  const yaw = step.yaw ?? (Math.hypot(dx, dz) > 1e-3 ? yawToward(a, { x: step.to[0], z: step.to[1] }) : a.yaw);
  if (step.seconds <= 0) {
    pose(a, step.to[0], step.to[1], yaw);
    return;
  }
  pose(a, a.x, a.z, yaw);
  setClip(a, clip);
  run.moves.set(step.actor, { actor: a, from: [a.x, a.z], to: step.to, t: 0, seconds: step.seconds });
}

function stepMoves(dt) {
  for (const [name, m] of run.moves) {
    m.t = Math.min(m.seconds, m.t + dt);
    const k = m.t / m.seconds;
    pose(m.actor, m.from[0] + (m.to[0] - m.from[0]) * k, m.from[1] + (m.to[1] - m.from[1]) * k, m.actor.yaw);
    if (m.t >= m.seconds) {
      setClip(m.actor, "idle");
      run.moves.delete(name);
    }
  }
}

/** The speaker's name as the subtitle shows it: a character's name, nothing for the narrator. */
function speakerName(id) {
  const c = id ? cast.characters[id] : null;
  return c ? i18n.t(c.nameKey) : "";
}

/** A subtitle, and its voice clip when data/cutscenes/voice.json has one (the subtitle then lasts as long as the clip). */
function speak(step) {
  const text = i18n.t(step.key);
  const speaker = speakerName(step.speaker ?? "");
  const clip = step.voice ? clips()[step.voice] : null;
  run.line = { step, startedAt: run.t, clip: clip ?? null };
  if (clip) {
    const id = audio.play(clip.path, { bus: "voiceover", captionKey: step.key, caption: text, speaker });
    if (id) {
      run.voiceId = id;
      return;
    }
    warnOnce(`voice:${step.voice}`, `the voice clip '${clip.path}' did not start; the subtitle shows for ${step.seconds} s.`);
  }
  run.voiceId = 0;
  ui.caption(text, step.seconds, { key: step.key, speaker });
}

// ------------------------------------------------------------------------------------------------------------------ tick
/** Moves the cut-scene on by `dt` seconds of game time (scripts/cutscene_view.js calls it every frame the game is not paused). */
export function tick(dt) {
  dropIfStale();
  if (!run) return;
  // The press that closed the conversation which asked for this cut-scene is still down: the first moments do not skip.
  if (run.skippable && run.t >= SKIP_GUARD && input.pressed("skip_cutscene")) {
    finish(true);
    return;
  }
  run.t = Math.min(run.def.duration, run.t + dt);
  while (run.next < run.steps.length && run.steps[run.next].at <= run.t + 1e-9) begin(run.steps[run.next++]);
  stepCamera(dt);
  stepMoves(dt);
  if (run.t >= run.def.duration) finish(false);
}

/** The game paused or went on (scripts/cutscene_view.js): a voice line that was speaking stops and is said again from its start. */
export function pause(paused) {
  if (!run || run.paused === paused) return;
  run.paused = paused;
  if (paused) {
    if (run.voiceId) audio.stop(run.voiceId);
    run.voiceId = 0;
    ui.clearCaptions();
  } else if (run.line && run.line.clip && run.t < run.line.startedAt + run.line.clip.seconds) {
    speak(run.line.step);
  } else if (run.line && !run.line.clip && run.t < run.line.startedAt + run.line.step.seconds) {
    ui.caption(i18n.t(run.line.step.key), run.line.startedAt + run.line.step.seconds - run.t, { key: run.line.step.key, speaker: speakerName(run.line.step.speaker ?? "") });
  }
}

// ----------------------------------------------------------------------------------------------------------------- finish
/** Applies what is left of the cut-scene at once: every step not yet begun, every move and camera move to its end. */
function settle() {
  while (run.next < run.steps.length) {
    const s = run.steps[run.next++];
    if (s.do === "move" || s.do === "face") {
      begin({ ...s, seconds: 0 });
    } else if (s.do === "camera") {
      run.camTrack = { from: run.cam ?? initialCamera(), to: { pos: s.pos, look: s.look }, t: 0, seconds: 0, ease: EASES.linear };
      stepCamera(0);
    }
  }
  for (const m of run.moves.values()) pose(m.actor, m.to[0], m.to[1], m.actor.yaw);
  if (run.camTrack) {
    run.camTrack.t = run.camTrack.seconds;
    run.camTrack.from = run.camTrack.to;
    stepCamera(0);
  }
}

function finish(skipped) {
  const r = run;
  if (skipped) settle();
  if (r.voiceId) audio.stop(r.voiceId);
  ui.clearCaptions();
  // Actors: the porter stays where the scene ended it when `keep` says so, everybody else goes back; made bodies are removed.
  let yaw = r.porter?.behaviour?.yaw ?? 0;
  for (const a of r.actors.values()) {
    if (a.temp) {
      if (a.entity.alive) a.entity.destroy();
      continue;
    }
    if (a.kind === "porter") {
      if (!a.keep) pose(a, a.home.x, a.home.z, a.home.yaw);
      yaw = a.yaw;
      if (a.entity.behaviour) a.entity.behaviour.puppetSpeed = 0;
    } else if (!a.keep) {
      pose(a, a.home.x, a.home.z, a.home.yaw);
      setClip(a, "idle", 0.1);
    } else setClip(a, "idle", 0.1);
  }
  const end = r.def.end ?? {};
  for (const fx of end.set ?? []) {
    const e = parseEffect(fx);
    if (e.ok && e.kind === "set") story.set(e.target, e.value);
    else if (e.ok && e.kind === "add") story.set(e.target, (Number(story.get(e.target, 0)) || 0) + e.value);
  }
  if (typeof end.fade === "number") r.hud?.fadeTo(end.fade, skipped ? SKIP_FADE : 0);
  r.camera?.release?.(yaw);
  const pb = r.porter?.behaviour;
  if (pb) {
    pb.puppet = false;
    pb.unlock("cutscene");
  }
  mix.leave();
  view?.end();
  run = null;
  (session.cutscenesSeen ??= []).push({ id: r.id, skipped });
  const waiting = queue[0];
  emit(EVENTS.cutsceneEnded, { id: r.id, skipped });
  // The next one in line starts now (it stayed in the queue meanwhile, so active() never dropped to false between the two), unless a
  // listener of the event started another: then it keeps waiting.
  if (waiting && !run && queue[0] === waiting) {
    queue.shift();
    const p = prepare(waiting.id, waiting.opts);
    if (p.def) start(p.def, p.skippable);
    else if (queue.length > 0 && !run) {
      const next = queue.shift();
      play(next.id, next.opts);
    }
  }
}
