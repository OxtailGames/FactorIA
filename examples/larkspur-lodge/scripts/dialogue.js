// @ts-check
// The dialogue runner of the game: plays a conversation of data/dialogue/*.json (format and condition language: scripts/dialogue_runner.js
// and scripts/conditions.js) against the story flags, the inventory and the cut-scene player. The pure walking is in
// dialogue_runner.js; this file gives it the game's state, locks the porter and sends the events. scripts/dialogue_view.js
// shows the lines (and reads the keyboard, the mouse, the gamepad and touches); a test or the story bot drives the same functions.
//
//   import * as dialogue from "./dialogue.js";
//   const r = dialogue.start("ch1_mara", { speaker: "npc_mara" });   // { id, started, completed, stub: false }
//   dialogue.current();   // { id, speaker, line: { node, speaker, textKey, voice, choices: [{ index, id, textKey }], last } } | null
//   dialogue.advance();   // a line without choices: go on (the end of the last line ends the conversation)
//   dialogue.choose(0);   // pick the first visible choice of the line
//
// start(id, { speaker }) -> { id, started, completed, stub }
//   id         a conversation id of a table of data/dialogue (a typo gives started: false and a "did you mean" warning)
//   speaker    the entity id of whoever talks (the porter turns to it, scripts/cast.js turns the character to the porter)
//   started    whether a conversation really began; false when one is already running or the id is unknown
//   completed  whether it ran to its end before start() returned (a conversation that has no line to show)
//   stub       false (P1 had a stub that never started anything)
// While a conversation runs, active() is true and the porter does not walk (Porter.lock("dialogue")). When it ends, the porter stays
// locked ("dialogue_end") until tick() has been called for POST_LOCK seconds - the key that ended the line is also "interact".
// Every start() sends EVENTS.dialogueRequested; a real one also sends dialogueStarted, dialogueLine for each line and dialogueEnded.
import { world, scene, session, didYouMean } from "factoria";
import { EVENTS, emit } from "./events.js";
import * as story from "./story.js";
import * as items from "./items.js";
import * as cutscene from "./cutscene.js";
import { Conversation } from "./dialogue_runner.js";
import { DIALOGUE } from "./dialogue_data.js";

/** Seconds the porter stays locked after a conversation ends. */
export const POST_LOCK = 0.25;

/** Most lines the backlog remembers. */
export const LOG_LIMIT = 120;

/** @type {{ conv: Conversation, id: string, speaker: string, scene: string } | null} */
let running = null;
/** Seconds of post-conversation lock left (0 = none). */
let postLock = 0;
/** The scene the post lock belongs to. */
let postScene = "";

const porter = () => world.find("porter")?.behaviour ?? null;

/** What the conversations read and change: the story flags, the inventory and the cut-scene player. */
const env = {
  get: (flag, fallback = false) => story.get(flag, fallback),
  hasItem: (id) => items.has(id),
  set: (flag, value) => story.set(flag, value),
  give: (id) => items.add(id, running ? running.speaker : ""),
  take: (id) => items.remove(id),
  cutscene: (id) => cutscene.play(id),
};

/** A conversation is on screen. A conversation of a scene that is gone (an area change under it) is dropped. */
export function active() {
  if (running && running.scene !== scene.current) forget(false);
  return running !== null;
}

/** The running conversation as { id, speaker, line }, or null. */
export function current() {
  return active() && running && running.conv.line ? { id: running.id, speaker: running.speaker, line: running.conv.line } : null;
}

/** Every conversation id of the tables (for tools and tests). */
export function ids() {
  return Object.keys(DIALOGUE.conversations);
}

/** True when the conversation `id` exists. */
export function exists(id) {
  return Object.prototype.hasOwnProperty.call(DIALOGUE.conversations, id);
}

/** Starts the conversation `id`. See the top of this file for the answer. */
export function start(id, opts = {}) {
  const speaker = opts.speaker ?? "";
  emit(EVENTS.dialogueRequested, { id, speaker });
  const no = { id, started: false, completed: false, stub: false };
  if (!exists(id)) {
    const near = didYouMean(String(id), ids());
    console.warn(`dialogue: there is no conversation '${id}'.${near ? ` Did you mean '${near}'?` : ""} Conversations are in data/dialogue/*.json.`);
    return no;
  }
  if (active()) return no;
  const conv = new Conversation(DIALOGUE, id, env);
  running = { conv, id, speaker, scene: scene.current };
  const p = porter();
  if (p) {
    p.unlock("dialogue_end");
    p.lock("dialogue");
  }
  postLock = 0;
  emit(EVENTS.dialogueStarted, { id, speaker });
  if (conv.finished) {
    finish(true);
    return { ...no, started: true, completed: true };
  }
  announce();
  return { ...no, started: true };
}

/** Goes on from a line without choices. Returns the next line, or null when the conversation ended (or none runs). */
export function advance() {
  if (!active() || !running) return null;
  const line = running.conv.advance();
  return afterStep(line);
}

/** Picks choice `index` (a position in the visible choices of the line). Returns the next line, or null at the end. */
export function choose(index) {
  if (!active() || !running) return null;
  const view = running.conv.line?.choices[index];
  if (view) remember("porter", view.textKey);
  const line = running.conv.choose(index);
  return afterStep(line);
}

/** Ends the conversation now without finishing it (an area change, a test). The effects of lines not reached are not applied. */
export function abort() {
  if (!active() || !running) return;
  running.conv.abort();
  finish(false);
}

/** Call once per frame with the frame time: counts down the post-conversation lock and gives the porter back. */
export function tick(dt) {
  if (postLock <= 0) return;
  postLock -= dt;
  if (postLock > 0) return;
  postLock = 0;
  if (postScene === scene.current) porter()?.unlock("dialogue_end");
}

/** The backlog: [{ speaker, key }] oldest first; the porter's chosen answers have the speaker "porter". */
export function log() {
  if (!Array.isArray(session.dialogue_log)) session.dialogue_log = [];
  return session.dialogue_log;
}

/** The conversations finished so far: [{ id, picked: [choice ids] }] (a new game empties it, scripts/chapters.js begin()). */
export function history() {
  if (!Array.isArray(session.dialogue_history)) session.dialogue_history = [];
  return session.dialogue_history;
}

/** Forgets the backlog and the history (a new game). */
export function reset() {
  session.dialogue_log = [];
  session.dialogue_history = [];
  running = null;
  postLock = 0;
}

// ------------------------------------------------------------------------------------------------------------- internals
function remember(speaker, key) {
  const list = log();
  list.push({ speaker, key });
  if (list.length > LOG_LIMIT) list.splice(0, list.length - LOG_LIMIT);
}

function afterStep(line) {
  if (!running) return null;
  if (running.conv.finished) {
    finish(true);
    return null;
  }
  announce();
  return line;
}

/** A new line is on offer: it goes into the backlog and everybody is told. */
function announce() {
  if (!running || !running.conv.line) return;
  const line = running.conv.line;
  remember(line.speaker, line.textKey);
  emit(EVENTS.dialogueLine, {
    id: running.id,
    node: line.node,
    speaker: line.speaker,
    textKey: line.textKey,
    voice: line.voice,
    choices: line.choices.map((c) => ({ id: c.id, textKey: c.textKey })),
  });
}

function finish(completed) {
  if (!running) return;
  const done = running;
  history().push({ id: done.id, picked: [...done.conv.picked] });
  forget(true);
  emit(EVENTS.dialogueEnded, { id: done.id, speaker: done.speaker, completed, picked: [...done.conv.picked] });
}

/** Drops the running conversation and holds the porter for POST_LOCK more seconds (when `held`, the scene is still the same). */
function forget(held) {
  running = null;
  const p = porter();
  if (held && p) {
    p.unlock("dialogue");
    p.lock("dialogue_end");
    postLock = POST_LOCK;
    postScene = scene.current;
  } else {
    postLock = 0;
  }
}
