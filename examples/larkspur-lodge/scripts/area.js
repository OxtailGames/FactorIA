// @ts-check
// The area controller: one entity ("area") per area scene of the lodge (scenes/ground, upstairs, cellar, test_room).
//
//   - At the start it puts the porter on the spawn the previous area asked for (game.sceneProps().arrive: the id of a spawn
//     entity of this scene, "spawn_default" when the game just started), aims the camera behind it, fades the screen in from
//     black and shows the area's name.
//   - It reads the neighbouring areas ahead of time (scene.preload) so that a door or a staircase changes area without a
//     pause.
//   - goTo(area, spawn) is what a door or a staircase calls: the screen fades to black, the porter stops, and once the fade is
//     done AND the next area is read the scene changes. Nothing waits on a Promise: this behaviour dies with its scene, so a
//     scene that was left first never loads another one.
//
// Fields tests read: `area` (this scene's name), `leaving` (the area being left for, or ""), `arrivedAt` (the spawn used).
import { Behaviour, world, scene, game, session, didYouMean } from "factoria";
import { EVENTS, emit } from "./events.js";

/** The areas of the lodge: name -> scene file. A door's `area` prop is one of these names. */
export const AREAS = Object.freeze({
  ground: "scenes/ground.scene.json",
  upstairs: "scenes/upstairs.scene.json",
  cellar: "scenes/cellar.scene.json",
  test_room: "scenes/test_room.scene.json",
});

export default class Area extends Behaviour {
  /** This area's name (a key of AREAS). */
  area = "";
  /** Locale key of the name shown when the porter arrives. */
  titleKey = "";
  /** Scene files of the neighbouring areas, read ahead of time. */
  preload = [];
  /** Seconds the screen takes to go black when leaving, and to clear when arriving. */
  fadeOut = 0.35;
  fadeIn = 0.5;

  onStart() {
    /** The scene this controller belongs to: results of anything started here are for this scene only. */
    this.scenePath = scene.current;
    this.leaving = "";
    this.change = null;
    this.jobs = new Map();
    session.area = this.area;
    const props = game.sceneProps();
    const porter = world.find("porter");
    const spawnId = typeof props.arrive === "string" && props.arrive !== "" ? props.arrive : "spawn_default";
    let spawn = world.find(spawnId);
    if (!spawn) {
      const ids = world.findByTag("spawn").map((e) => e.id);
      const near = didYouMean(spawnId, ids);
      console.error(`area '${this.area}': there is no spawn '${spawnId}'. ${near ? `Did you mean '${near}'?` : `Spawns here: ${ids.join(", ")}.`} Using spawn_default.`);
      spawn = world.find("spawn_default");
    }
    /** The spawn entity id the porter started at. */
    this.arrivedAt = spawn ? spawn.id : "";
    let yaw = 0;
    let position = null;
    if (spawn) {
      const p = spawn.worldPosition;
      position = [p.x, p.y, p.z];
      yaw = spawn.get("Transform").rotation[1];
    }
    // A loaded save (scripts/save_data.js apply) names the exact place to stand.
    if (props.restore && session.restoreSpawn) {
      position = session.restoreSpawn.position;
      yaw = session.restoreSpawn.yaw;
      session.restoreSpawn = null;
    }
    if (porter && position) {
      porter.position = position;
      if (porter.behaviour) porter.behaviour.faceYaw(yaw);
    }
    const camera = world.find("camera")?.behaviour;
    if (camera) camera.snapBehind(yaw);
    const hud = world.find("hud")?.behaviour;
    if (hud) {
      hud.fadeTo(0, this.fadeIn);
      if (this.titleKey) hud.showTitle(this.titleKey);
    }
    // Read the neighbours ahead of time; a name that is not a scene is an error the author sees at once.
    for (const path of this.preload) this.startJob(path);
    emit(EVENTS.areaReady, { area: this.area, spawn: this.arrivedAt, scene: this.scenePath });
  }

  startJob(path) {
    if (this.jobs.has(path)) return this.jobs.get(path);
    const job = scene.preload(path);
    job.promise.catch(() => {}); // a job that is released first or fails is not an error here: scene.load reads the file itself
    this.jobs.set(path, job);
    return job;
  }

  onDestroy() {
    // Give the files back of the neighbours that were not the one loaded.
    for (const job of this.jobs.values()) job.release();
  }

  /**
   * Leaves for another area. `area` is a key of AREAS, `spawn` the id of the spawn entity in it. Returns false when the name is
   * not an area, or when a change is already under way.
   */
  goTo(area, spawn = "spawn_default") {
    if (this.change) return false;
    const path = AREAS[area];
    if (!path) {
      const near = didYouMean(area, Object.keys(AREAS));
      console.error(`area '${this.area}': goTo('${area}'): there is no such area. ${near ? `Did you mean '${near}'?` : `Areas: ${Object.keys(AREAS).join(", ")}.`}`);
      return false;
    }
    const porter = world.find("porter")?.behaviour;
    if (porter) porter.lock("transition");
    const hud = world.find("hud")?.behaviour;
    if (hud) hud.fadeTo(1, this.fadeOut);
    this.leaving = area;
    this.change = { path, spawn, waited: 0 };
    this.startJob(path);
    emit(EVENTS.areaLeaving, { from: this.area, to: area, spawn });
    return true;
  }

  onUpdate(dt) {
    const c = this.change;
    if (!c || c.loading) return;
    c.waited += dt;
    const job = this.jobs.get(c.path);
    if (c.waited >= this.fadeOut && (!job || job.done)) {
      c.loading = true;
      this.jobs.delete(c.path); // the loaded scene uses these files: not released on destroy
      scene.load(c.path, { arrive: c.spawn });
    }
  }
}
