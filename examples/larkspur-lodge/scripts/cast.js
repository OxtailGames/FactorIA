// @ts-check
// The characters of the night in the area scene: one entity ("cast") of the three area scenes that have people (ground, upstairs,
// cellar) has this behaviour. It puts each character of data/cast.json where the schedule of the current chapter says
// (data/story.json "places" names the spot: an area, x, z and the way it faces) and takes them away when the chapter changes.
// The story flag "chapter" is the chapter; chapter 0 (no chapter flag: the P1 test area, a bare scene) places nobody.
//
// A character is an entity `npc_<id>` tagged "interactable" and "npc" that carries scripts/interactable.js with kind "talk": the
// porter's prompt, the highlight, F / Enter / A, a click and a tap work on it like on any object. Its `dialogue` prop is the
// conversation of the current chapter (cast.json "talk"). While that conversation runs the character turns to the porter and
// plays a gesture on every line they speak; the placeholder bodies are the CC0 Kenney characters (assets/models/characters).
//
//   const cast = world.find("cast").behaviour;
//   cast.npc("mara");        // the entity of a character who stands in this area now, or null
//   cast.present();          // ["mara", "tobias"]: who stands here now
//   cast.place();            // spawn again from the schedule (done by itself on start and on chapter_changed)
//
// Fields tests read: `area`, `chapter`.
import { Behaviour, world, scene, didYouMean } from "factoria";
import { EVENTS } from "./events.js";
import * as story from "./story.js";
import { cast, story as storyData } from "./dialogue_data.js";

const DEG = Math.PI / 180;
/** Height of the body's origin above the floor model, as for the porter (scenes/*.scene.json, "porter_model"). */
const FEET = 0.075;
/** Scale of the Kenney characters in the lodge (the porter's is the same). */
const SCALE = 0.7;
const BODIES = Object.freeze({
  a: "assets/models/characters/character-a.glb",
  b: "assets/models/characters/character-b.glb",
  e: "assets/models/characters/character-e.glb",
  f: "assets/models/characters/character-f.glb",
});
const ANIMATOR = Object.freeze({
  params: { talk: false },
  states: { idle: { clip: "idle" }, talk: { clip: "emote-yes", loop: false } },
  transitions: [
    { to: "talk", when: "talk", fade: 0.12 },
    { from: "talk", to: "idle", onFinish: true, fade: 0.2 },
  ],
  state: "idle",
});

/**
 * The entity JSON of a body for character `id` that is only to be seen, not talked to (a cut-scene's extra, scripts/cutscene.js):
 * same model, tint and Animator as a character of the cast, but no collider and no interactable. `x`, `z` metres, `yaw` degrees
 * (0 = looks down -Z).
 */
export function bodyJson(id, x, z, yaw, entityId) {
  const c = cast.characters[id];
  if (!c) throw new Error(`cast: there is no character '${id}' in data/cast.json. ${didYouMean(id, Object.keys(cast.characters)) ?? ""}`);
  return {
    id: entityId,
    name: id,
    components: {
      Transform: { position: [x, FEET, z], rotation: [0, yaw + 180, 0], scale: [SCALE, SCALE, SCALE] },
      MeshRenderer: { mesh: BODIES[c.body], color: c.tint, castShadows: true, emissive: [0.08, 0.07, 0.07] },
      Animator: ANIMATOR,
    },
  };
}

export default class Cast extends Behaviour {
  /** The area this scene is (a key of scripts/area.js AREAS); the build script writes it. */
  area = "";

  onStart() {
    /** The scene this belongs to: events of another scene are not for it. */
    this.scenePath = scene.current;
    /** character id -> entity */
    this.npcs = new Map();
    /** The yaw each character had before turning to the porter: character id -> degrees. */
    this.turned = new Map();
    this.chapter = 0;
    world.on(EVENTS.chapterChanged, () => this.place());
    world.on(EVENTS.dialogueStarted, (d) => this.onTalk(d));
    world.on(EVENTS.dialogueLine, (d) => this.onLine(d));
    world.on(EVENTS.dialogueEnded, () => this.onEnd());
    this.place();
  }

  /** The characters standing in this area now, in the order of data/cast.json. */
  present() {
    return [...this.npcs.keys()];
  }

  /** The entity of character `id` (null when they are not in this area now). */
  npc(id) {
    const e = this.npcs.get(id);
    return e && e.alive ? e : null;
  }

  /** Takes everybody away and spawns the characters whose place for the current chapter is in this area. */
  place() {
    for (const e of this.npcs.values()) if (e.alive) e.destroy();
    this.npcs.clear();
    this.turned.clear();
    this.chapter = Number(story.get("chapter", 0)) || 0;
    if (this.chapter > 0) {
      for (const [id, c] of Object.entries(cast.characters)) {
        const key = c.schedule[String(this.chapter)];
        if (!key) continue;
        const spot = storyData.places[key];
        if (!spot) {
          const near = didYouMean(key, Object.keys(storyData.places));
          console.error(`cast: ${id} is scheduled at '${key}' in chapter ${this.chapter} but data/story.json has no such place.${near ? ` Did you mean '${near}'?` : ""}`);
          continue;
        }
        if (spot.area === this.area) this.npcs.set(id, world.spawn(this.entityJson(id, c, spot)));
      }
    }
    // The porter reads the interactables once; tell it the people changed.
    world.find("porter")?.behaviour?.refreshInteractables();
  }

  entityJson(id, c, spot) {
    const talk = c.talk[String(this.chapter)] ?? "";
    return {
      id: `npc_${id}`,
      name: id,
      tags: ["interactable", "npc"],
      components: {
        Transform: { position: [spot.x, FEET, spot.z], rotation: [0, spot.yaw + 180, 0], scale: [SCALE, SCALE, SCALE] },
        MeshRenderer: { mesh: BODIES[c.body], color: c.tint, castShadows: true, emissive: [0.08, 0.07, 0.07] },
        Animator: ANIMATOR,
        // A box on layer 2 (low furniture): the porter cannot walk through a person, a click finds the person with a ray, and the NavMesh
        // routes around them.
        Collider3D: { shape: "box", size: [0.9, 2.4, 0.9], offset: [0, 1.2, 0], layer: 2, navObstacle: true },
        Script: { path: "scripts/interactable.js", props: { kind: "talk", name: c.nameKey, dialogue: talk, reach: 2.2, point: [spot.x, spot.z] } },
      },
    };
  }

  // ---------------------------------------------------------------------------------------------- during a talk
  onTalk(d) {
    if (scene.current !== this.scenePath) return;
    const id = this.idOf(d.speaker);
    const npc = id ? this.npc(id) : null;
    const porter = world.find("porter");
    if (!npc || !porter) return;
    const p = porter.position;
    const q = npc.position;
    const yaw = Math.atan2(-(p.x - q.x), -(p.z - q.z)) / DEG;
    this.turned.set(id, npc.get("Transform").rotation[1]);
    npc.get("Transform").rotation = [0, yaw + 180, 0];
  }

  onLine(d) {
    if (scene.current !== this.scenePath) return;
    const npc = d.speaker ? this.npc(d.speaker) : null;
    if (npc && npc.animator) npc.animator.trigger("talk");
  }

  onEnd() {
    for (const [id, rotationY] of this.turned) {
      const npc = this.npc(id);
      if (npc) npc.get("Transform").rotation = [0, rotationY, 0];
    }
    this.turned.clear();
  }

  /** The character id of an entity id ("npc_mara" -> "mara"), or "". */
  idOf(entityId) {
    return typeof entityId === "string" && entityId.startsWith("npc_") && cast.characters[entityId.slice(4)] ? entityId.slice(4) : "";
  }
}
