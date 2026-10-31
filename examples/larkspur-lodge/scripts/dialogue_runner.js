// @ts-check
// The pure part of the dialogue runner: walks one conversation of a dialogue table (data/dialogue/*.json). It touches no
// scene and no module state; everything it reads or changes goes through the `env` the caller passes in, so a test can run a
// whole conversation against a plain object. scripts/dialogue.js is the glue that gives it the story, the inventory and
// the cut-scene player and shows the lines.
//
// A table: { "format": "larkspur.dialogue/1", "conversations": { "<conversation id>": { "start": "<node id>", "nodes": { ... } } } }
//
// A node is a LINE (it has a `speaker`; its id is the locale key of its text) or a ROUTE (it has `route`, silent):
//   line   { "speaker": "mara", "voice": "mara_ch1_greet", "effects": [...], "next": "<node id>" | "@end",
//            "choices": [ { "id": "thanks", "text": "<locale key>", "if": [...], "effects": [...], "next": "<node id>" | "@end" } ] }
//   route  { "route": [ { "if": [...], "to": "<node id>" | "@end" }, ... ], "effects": [...] }   the first entry that holds wins
// A line shows its text, applies its effects when it is reached, then waits: with `choices` the player picks one (the choices
// whose `if` fails are not offered; when none is left the node's `next` is followed, or the conversation ends), without them
// advance() goes to `next`. An { "end": true } effect, or "next": "@end", ends the conversation after the line.
// Conditions and effects are described in scripts/conditions.js.
import { holds, parseEffect } from "./conditions.js";

/** The target that ends a conversation. */
export const END = "@end";

/** Most nodes a single step may walk through without stopping on a line (a loop of routes is a mistake in the table). */
const MAX_ROUTE_STEPS = 64;

/**
 * @typedef {{ index: number, id: string, textKey: string }} ChoiceView
 * @typedef {{ node: string, speaker: string, textKey: string, voice: string, choices: ChoiceView[], last: boolean }} LineView
 * @typedef {{
 *   get(flag: string, fallback?: any): any,
 *   hasItem(id: string): boolean,
 *   set(flag: string, value: any): any,
 *   give(item: string): any,
 *   take(item: string): any,
 *   cutscene(id: string): any,
 *   changed?(): void,
 * }} RunnerEnv
 */

export class Conversation {
  /**
   * @param {any} table the parsed dialogue table(s): an object with `conversations` (several files merged are fine)
   * @param {string} id the conversation id
   * @param {RunnerEnv} env
   */
  constructor(table, id, env) {
    const conv = table?.conversations?.[id];
    if (!conv) throw new Error(`dialogue '${id}' does not exist`);
    this.id = id;
    this.conv = conv;
    this.env = env;
    /** The line on offer now (null once the conversation is over). @type {LineView | null} */
    this.line = null;
    this.finished = false;
    /** True when the last line carried an end effect (or `next: "@end"`): the conversation ends after it. */
    this.ending = false;
    /** The ids of the line nodes shown so far, in order. @type {string[]} */
    this.visited = [];
    /** The choice ids picked so far, in order. @type {string[]} */
    this.picked = [];
    this.enter(conv.start);
  }

  /** The choices on offer now (an empty list for a plain line). */
  get choices() {
    return this.line ? this.line.choices : [];
  }

  /** Goes on from a line that has no choices. Returns the next line, or null when the conversation ended. */
  advance() {
    if (this.finished || !this.line) return null;
    if (this.line.choices.length > 0) throw new Error(`dialogue '${this.id}': '${this.line.node}' offers choices; call choose(index)`);
    const node = this.conv.nodes[this.line.node];
    if (this.ending) return this.finish();
    return this.enter(node.next ?? END);
  }

  /**
   * Picks a choice of the current line by its position in `choices` (the visible ones). Returns the next line, or null when the
   * conversation ended.
   */
  choose(index) {
    if (this.finished || !this.line) return null;
    const view = this.line.choices[index];
    if (!view) throw new Error(`dialogue '${this.id}': '${this.line.node}' has ${this.line.choices.length} choices, there is no choice ${index}`);
    const node = this.conv.nodes[this.line.node];
    const choice = node.choices[view.index];
    this.picked.push(view.id);
    this.ending = false;
    this.apply(choice.effects);
    if (this.finished) return null;
    if (this.ending) return this.finish();
    return this.enter(choice.next ?? END);
  }

  /** Ends the conversation now, whatever is on offer. */
  abort() {
    this.finished = true;
    this.line = null;
  }

  finish() {
    this.finished = true;
    this.line = null;
    return null;
  }

  /** Applies a list of effects. A cut-scene or the end are noted; the rest goes to the env. */
  apply(effects) {
    for (const fx of effects ?? []) {
      const e = parseEffect(fx);
      if (!e.ok) throw new Error(`dialogue '${this.id}': effect ${JSON.stringify(fx)}: ${e.message}. ${e.hint}`);
      switch (e.kind) {
        case "set": this.env.set(e.target, e.value); break;
        case "add": this.env.set(e.target, Number(this.env.get(e.target, 0) || 0) + e.value); break;
        case "give": this.env.give(e.target); break;
        case "take": this.env.take(e.target); break;
        case "cutscene": this.env.cutscene(e.target); break;
        case "end": this.ending = true; break;
      }
    }
    if (this.env.changed) this.env.changed();
  }

  /** Walks into node `target`, following routes, until a line is on offer or the conversation ends. */
  enter(target) {
    this.ending = false;
    for (let steps = 0; steps < MAX_ROUTE_STEPS; steps++) {
      if (target === END) return this.finish();
      const node = this.conv.nodes[target];
      if (!node) throw new Error(`dialogue '${this.id}': there is no node '${target}'`);
      if (node.route) {
        this.apply(node.effects);
        let next = null;
        for (const r of node.route) {
          if (holds(r.if, this.env)) {
            next = r.to;
            break;
          }
        }
        if (next === null) throw new Error(`dialogue '${this.id}': no branch of the route '${target}' holds`);
        target = next;
        continue;
      }
      this.apply(node.effects);
      // An effect may have ended the conversation from inside (a cut-scene that took over): honour a finished flag.
      if (this.finished) return null;
      /** @type {ChoiceView[]} */
      const choices = [];
      (node.choices ?? []).forEach((c, index) => {
        if (holds(c.if, this.env)) choices.push({ index, id: c.id ?? String(index), textKey: c.text });
      });
      // Nothing to pick (a plain line, or every choice hidden): the line is the last one when it ends the conversation.
      if (choices.length === 0 && (node.next ?? END) === END) this.ending = true;
      this.visited.push(target);
      this.line = { node: target, speaker: node.speaker ?? "", textKey: target, voice: node.voice ?? "", choices, last: this.ending };
      return this.line;
    }
    throw new Error(`dialogue '${this.id}': more than ${MAX_ROUTE_STEPS} routes in a row from '${target}': the table loops`);
  }
}
