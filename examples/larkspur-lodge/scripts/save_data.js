// @ts-check
// The shape of a saved game. P1 ships only the shape (snapshot() and apply() work on plain objects, nothing is written to
// storage); P5 adds the slots, autosave, versioning and the cloud.
//
// { "format": "larkspur.save/1",
//   "area": "ground",                      the scene the porter stands in (a key of scripts/area.js AREAS)
//   "spawn": { "position": [x, y, z], "yaw": degrees },   where it stands
//   "story": { "flags": {...}, "counters": {...} },       scripts/story.js snapshot()
//   "inventory": ["library_key", ...] }                   scripts/items.js snapshot()
//
// apply(data) puts story and inventory back and returns { area, arrive } for the caller to scene.load: the porter is placed
// by scripts/area.js from session.restoreSpawn. A save of another format is refused with a message that says what to do.
import { session, world } from "factoria";
import * as story from "./story.js";
import * as items from "./items.js";

export const FORMAT = "larkspur.save/1";

/** The current game as a plain JSON object (what a save file holds). */
export function snapshot() {
  const porter = world.find("porter");
  const p = porter ? porter.position : { x: 0, y: 0, z: 0 };
  const yaw = porter && porter.behaviour ? porter.behaviour.yaw : 0;
  return {
    format: FORMAT,
    area: session.area ?? "ground",
    spawn: { position: [p.x, p.y, p.z], yaw },
    story: story.snapshot(),
    inventory: items.snapshot(),
  };
}

/**
 * Puts a save back: the story, the inventory and (for scripts/area.js) the place to stand. Returns { ok, area, message, hint }.
 * @param {any} data
 */
export function apply(data) {
  if (!data || data.format !== FORMAT) {
    return { ok: false, area: "", message: `the save has format '${data?.format}'`, hint: `Only '${FORMAT}' saves can be loaded. Start a new game or migrate the file.` };
  }
  story.restore(data.story);
  items.restore(data.inventory);
  session.restoreSpawn = data.spawn ?? null;
  return { ok: true, area: data.area, message: "", hint: "" };
}
