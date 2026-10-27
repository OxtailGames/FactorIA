// The story bot's hands: a player that walks to things, uses them with the real use key, talks by picking choices from a list of
// preferred ids, and waits for the screen to settle (area changes, chapter cards). Used by tests/story_bot.test.js. It uses no
// randomness: the same list of picks always plays the same night.
import { game } from "factoria:test";
import { scene } from "factoria";
import { porter, stand } from "./lodge.js";
import * as dialogue from "../../scripts/dialogue.js";
import * as story from "../../scripts/story.js";
import * as items from "../../scripts/items.js";
import * as chapters from "../../scripts/chapters.js";
import * as cutscene from "../../scripts/cutscene.js";
import { AREAS } from "../../scripts/area.js";

/** Where to stand relative to a thing's spot, and the yaw that looks at it (yaw 0 faces -Z, 90 faces -X, 180 faces +Z, 270 faces +X). */
const SIDES = [
  [0, 1.2, 0],
  [0, -1.2, 180],
  [1.2, 0, 90],
  [-1.2, 0, 270],
];

/** The ways between areas: [from][to] = the interactable to use. */
const WAYS = {
  ground: { upstairs: "stairs_up", cellar: "cellar_door" },
  upstairs: { ground: "stairs_down" },
  cellar: { ground: "stairs_up" },
};

export class Bot {
  constructor() {
    /** What happened, in order: "talk mara [promise]", "use p_letter_box"... (shown when a step fails). */
    this.trail = [];
  }

  fail(message) {
    throw new Error(`${message}\n  so far: ${this.trail.join(" > ")}`);
  }

  /** The area of the scene now ("ground", "upstairs", "cellar"). */
  area() {
    return Object.keys(AREAS).find((k) => AREAS[k] === scene.current) ?? "";
  }

  /** Steps until nothing is changing: no area change, no chapter fade, the porter free. Fails after `max` frames. */
  settle(max = 900) {
    game.step(4);
    for (let i = 0; i < max; i += 4) {
      this.skipCutscene();
      const ch = game.find("chapters")?.behaviour;
      const area = game.find("area")?.behaviour;
      const p = porter();
      const busy = !ch || !area || !p || ch.stage !== "" || area.leaving !== "" || p.behaviour.locked || game.find("hud")?.behaviour.fading;
      if (!busy) return;
      if (ch && ch.stage === "ending" && ch.endingShown) return;
      game.step(4);
    }
    this.fail(`the screen did not settle in ${max} frames (scene ${scene.current})`);
  }

  /** A cut-scene is playing: the bot skips it with the real skip key (after the moments in which the key is ignored). */
  skipCutscene() {
    const c = cutscene.current();
    if (!c) return;
    this.trail.push(`skip ${c.id}`);
    if (c.time < 0.4) game.step(Math.ceil((0.4 - c.time) * 60));
    game.tapKey("Space");
    game.step(2);
  }

  /** The title screen -> Play -> loading -> the hall, chapter 1. */
  play() {
    game.resetState();
    scene.load("scenes/menu.scene.json");
    game.step(3);
    game.click(game.find("play"));
    for (let i = 0; i < 600 && scene.current !== AREAS.ground; i++) game.step(1);
    if (scene.current !== AREAS.ground) this.fail("Play did not reach the hall");
    this.trail.push("play");
    this.settle();
  }

  /** Walks (a jump) to a thing's spot and uses it with the use key. The thing must be the porter's target there, as for a player. */
  use(id) {
    const e = game.find(id);
    if (!e || !e.behaviour) this.fail(`there is no '${id}' in ${scene.current}`);
    const [sx, sz] = e.behaviour.spot;
    let found = false;
    for (const [dx, dz, yaw] of SIDES) {
      stand(sx + dx, sz + dz, yaw);
      game.step(3);
      if (porter().behaviour.target?.entity.id === id) {
        found = true;
        break;
      }
    }
    if (!found) this.fail(`'${id}' is not the porter's target from any side (the target is '${porter().behaviour.target?.entity.id}')`);
    this.trail.push(`use ${id}`);
    game.tapKey("F");
    game.step(2);
  }

  /** Goes to another area through its stairs and doors, and waits to arrive. */
  go(target) {
    const from = this.area();
    if (from === target) return;
    if (from !== "ground" && target !== "ground") {
      this.go("ground");
      return this.go(target);
    }
    const way = from === "ground" ? WAYS.ground[target] : WAYS[from].ground;
    this.use(way);
    for (let i = 0; i < 600 && scene.current !== AREAS[target]; i++) game.step(1);
    if (scene.current !== AREAS[target]) this.fail(`did not arrive in ${target}`);
    this.settle();
  }

  /**
   * Talks to character `who` and plays the conversation to its end. At every choice it picks the first of `prefs` that is on
   * offer, else the first choice. Returns the ids picked.
   */
  talk(who, prefs = []) {
    const npc = game.find(`npc_${who}`);
    if (!npc) this.fail(`${who} is not in ${scene.current} in chapter ${chapters.current()}`);
    this.use(`npc_${who}`);
    if (!dialogue.active()) this.fail(`talking to ${who} started no conversation`);
    const picked = [];
    for (let guard = 0; dialogue.active() && guard < 120; guard++) {
      const line = dialogue.current().line;
      if (line.choices.length) {
        let i = line.choices.findIndex((c) => prefs.includes(c.id));
        if (i < 0) i = 0;
        picked.push(line.choices[i].id);
        dialogue.choose(i);
      } else {
        dialogue.advance();
      }
      game.step(1);
    }
    if (dialogue.active()) this.fail(`the conversation with ${who} did not end`);
    this.trail.push(`talk ${who} [${picked}]`);
    this.settle();
    return picked;
  }

  /** The state of the story as a stable string, and its hash: flags and counters sorted, the items sorted, the conversations in order. */
  state() {
    const s = story.snapshot();
    const sorted = (o) => Object.fromEntries(Object.keys(o).sort().map((k) => [k, o[k]]));
    return JSON.stringify({ flags: sorted(s.flags), counters: sorted(s.counters), items: [...items.list()].sort(), history: dialogue.history() });
  }
}

/** FNV-1a, 32 bits, as 8 hex digits. */
export function fnv1a(text) {
  let h = 0x811c9dc5;
  for (let i = 0; i < text.length; i++) {
    h ^= text.charCodeAt(i);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return h.toString(16).padStart(8, "0");
}
