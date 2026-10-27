// @ts-check
// The dialogue runner. P1 ships only the CONTRACT (this file is a stub): the interaction system already asks for a
// conversation through it, so P2 fills in the body and nothing else changes.
//
//   import * as dialogue from "./dialogue.js";
//   const result = dialogue.start("innkeeper_greeting", { speaker: "innkeeper" });
//
// start(id, { speaker }) -> { id, started, completed, stub }
//   id        the dialogue id (a file dialogues/<id>.dialogue.json in P2: lines with a speaker key, a text key, choices that set
//             story flags and give items)
//   speaker   the entity id of whoever talks (the camera and the porter turn to it)
//   started   whether a conversation really began; P1: always false
//   completed whether it ran to its end; P1: always false
//   stub      true while the runner is not written (P2 removes it)
// While a conversation runs, dialogue.active() is true and the porter does not walk (Porter.lock("dialogue")).
// start() always sends EVENTS.dialogueRequested, even in P1, so a test or a later system can see the request.
import { EVENTS, emit } from "./events.js";

/** True while a conversation is on screen (P1: never). */
export function active() {
  return false;
}

/** Starts the dialogue `id`. P1: only sends EVENTS.dialogueRequested and answers { started: false, stub: true }. */
export function start(id, opts = {}) {
  emit(EVENTS.dialogueRequested, { id, speaker: opts.speaker ?? "" });
  return { id, started: false, completed: false, stub: true };
}
