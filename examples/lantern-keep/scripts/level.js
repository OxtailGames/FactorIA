// @ts-check
// The level's rules, on one entity (id "level") of every level scene: the timer, the embers found, deaths and
// checkpoints, the exit, and the game events other features listen to (world.emit, see README "Game events").
import { Behaviour, audio, game, vec2 } from "factoria";
import * as progress from "./progress.js";
import { EMBERS_PER_LEVEL } from "./levels.js";
import { deathShake } from "./effects.js";
import * as assist from "./assist.js";

export default class Level extends Behaviour {
  /** Id of this level in scripts/levels.js (set by the level's map file, `edits`). */
  levelId = "";
  /** Pixels below the bottom of the map where a fall counts as a death. */
  killDepth = 200;
  /** Seconds after a respawn in which nothing can kill the player again. */
  grace = 0.8;

  onStart() {
    this.time = 0; // seconds since the level started: the timer of the HUD and the level end panel
    this.clock = 0;
    this.deaths = 0;
    this.finished = false;
    /** @type {boolean[]} */
    this.embers = Array(EMBERS_PER_LEVEL).fill(false);
    this.protectedUntil = 0;
    this.player = this.world.find("player");
    this.mapBounds = this.world.find("map")?.bounds() ?? null;
    const p = this.player.position;
    this.spawn = vec2(p.x, p.y); // where a death sends the player: the level start until a checkpoint is reached
    this.checkpointIndex = -1;
    // Checkpoints are numbered from the left, whatever order the map placed them in.
    this.checkpoints = this.world.findByTag("checkpoint").sort((a, b) => a.position.x - b.position.x);
    this.checkpoints.forEach((c, i) => (c.behaviour.index = i));
    // The panel the exit shows: spawned here (like the pause menu) so any level only needs this one entity.
    this.endPanel = this.world.spawnPrefab("prefabs/ui/level_end.prefab.json");
    this.endPanel.id = "level_end";
    this.endPanel.active = false;
    this.announced = false;
    this.assisted = false; // true once any assist option was on during this level: the result says so
    assist.applySpeed();
    this.refreshAssist();
  }

  /** Remembers that assist was used. Called at the start and after every resume (the options may have changed while paused). */
  refreshAssist() {
    if (assist.active()) this.assisted = true;
  }

  /** Embers found so far. */
  get found() {
    return this.embers.filter(Boolean).length;
  }

  onUpdate(dt) {
    if (!this.announced) {
      // On the first frame, not in onStart: by now every other script of the scene has started and is listening.
      this.announced = true;
      this.world.emit("level_started", { level: this.levelId });
    }
    this.clock += dt;
    if (!this.finished) this.time += dt;
  }

  onFixedUpdate() {
    const area = this.mapBounds;
    if (area && !this.finished && this.player.position.y < area.y - this.killDepth) this.die("fall");
  }

  /** Puts the player back at the last checkpoint, standing still. */
  respawn() {
    this.player.position = vec2(this.spawn.x, this.spawn.y);
    const body = this.player.get("RigidBody2D");
    body.velocity.x = 0;
    body.velocity.y = 0;
  }

  /** The player died: count it, send them back to the last checkpoint, shake the camera. Returns false when it did not count. */
  die(cause) {
    if (this.finished || this.clock < this.protectedUntil) return false;
    if (assist.current().invincible) {
      // Assist: spikes and enemies do nothing; a fall puts the player back at the checkpoint without counting a death.
      this.assisted = true;
      if (cause === "fall") this.respawn();
      return false;
    }
    this.deaths += 1;
    this.protectedUntil = this.clock + this.grace;
    this.respawn();
    audio.play("assets/sfx/hurt.wav", { volume: 0.7 });
    deathShake();
    this.world.emit("player_died", { level: this.levelId, cause });
    return true;
  }

  /** The player touched ember `index` (0..2). Returns false when it was already found. */
  collectEmber(index) {
    if (this.embers[index]) return false;
    this.embers[index] = true;
    audio.play("assets/sfx/ember.wav", { volume: 0.7 });
    this.world.emit("ember_collected", { level: this.levelId, index, found: this.found });
    return true;
  }

  /** The player touched a checkpoint (an entity tagged "checkpoint", numbered from the left). Later ones replace earlier ones. */
  reachCheckpoint(checkpoint) {
    const index = checkpoint.behaviour.index;
    if (index <= this.checkpointIndex) return false;
    this.checkpointIndex = index;
    this.spawn = vec2(checkpoint.position.x, checkpoint.position.y);
    audio.play("assets/sfx/checkpoint.wav", { volume: 0.7 });
    this.world.emit("checkpoint_reached", { level: this.levelId, index });
    return true;
  }

  /** The player touched the exit: stop the clock, record the result and show the level end panel. */
  complete() {
    if (this.finished) return false;
    this.finished = true;
    const result = { level: this.levelId, time: Math.round(this.time * 1000) / 1000, embers: [...this.embers], deaths: this.deaths, assisted: this.assisted };
    const info = progress.record(result);
    audio.play("assets/sfx/win.wav", { volume: 0.7 });
    this.world.emit("level_completed", result);
    const pause = this.world.find("pause_menu")?.behaviour;
    if (pause) pause.enabled = false; // the end panel is not a pause: Escape does nothing now
    game.paused = true;
    const panel = this.endPanel.behaviour; // a panel spawned inactive already has its behaviour
    panel.result = result;
    panel.info = info;
    this.endPanel.active = true; // its onEnable fills the texts before the frame is drawn
    return true;
  }
}
