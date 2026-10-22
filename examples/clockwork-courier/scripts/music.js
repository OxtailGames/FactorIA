// @ts-check
// The music director: one entity ("music") in every scene. It starts the scene's track (the district's loop in a level, the
// title theme elsewhere), keeps it playing across the title and loading scenes, fades between tracks, and ducks the music
// (lowers it for a moment) under the pause menu and under the jingles it plays itself:
//
//   parcel_delivered   a short jingle, music ducked 1.4 s          level_completed   a longer one, 3 s
//   level_failed       a sad one, 2.5 s                            game_paused       ducked while the pause menu is open
//
// The player's music volume (Options) is the "music" bus; ducking multiplies it, so the music bus is set every frame to
// `user volume * duck gain` (settings.js owns the user value: this never changes what is saved). It runs while the game
// is paused (runWhilePaused) so the duck can ease in and out with real time.
//
// Tests read `track` (what is playing), `duck` (the current gain, 1 = not ducked) and `duckTarget`.
import { Behaviour, audio, scene, session, world, time } from "factoria";
import { EVENTS } from "./events.js";
import * as levels from "./levels.js";
import * as settings from "./settings.js";

/** Jingles (Kenney Jingles, CC0) and how long the music stays ducked under each one, seconds. */
export const JINGLES = {
  delivery: { clip: "assets/audio/jingles_HIT03.ogg", duck: 1.4, volume: 0.8 },
  complete: { clip: "assets/audio/jingles_SAX05.ogg", duck: 3, volume: 0.9 },
  failure: { clip: "assets/audio/jingles_PIZZI02.ogg", duck: 2.5, volume: 0.9 },
};

export default class Music extends Behaviour {
  /** Gain of the music while ducked (0..1). */
  duckGain = 0.3;
  /** How fast the duck eases, gain per second (real time). */
  duckRate = 5;
  /** Seconds a track fades in. */
  fade = 1.2;
  /** Track to play; empty = the level list's track for this scene, or the title theme. */
  track = "";

  runWhilePaused = true;

  onStart() {
    this.duck = 1;
    this.duckTarget = 1;
    this.paused = false;
    this.jingleTimer = 0;
    this.track = this.track || this.trackForScene();
    if (session.musicTrack !== this.track) {
      audio.music(this.track, { volume: 1, fade: this.fade });
      session.musicTrack = this.track;
    }
    this.apply();
    this.offs = [
      world.on(EVENTS.gamePaused, () => {
        this.paused = true;
      }),
      world.on(EVENTS.gameResumed, () => {
        this.paused = false;
      }),
      world.on(EVENTS.parcelDelivered, () => this.jingle("delivery")),
      world.on(EVENTS.levelCompleted, () => this.jingle("complete")),
      world.on(EVENTS.levelFailed, () => this.jingle("failure")),
    ];
  }

  onDestroy() {
    for (const off of this.offs ?? []) off();
  }

  /** The track of the running scene. */
  trackForScene() {
    const lvl = levels.byScene(scene.current);
    return lvl && lvl.music ? lvl.music : levels.MUSIC.title;
  }

  /** Plays a jingle and ducks the music while it sounds. */
  jingle(kind) {
    const j = JINGLES[kind];
    if (!j) return;
    audio.play(j.clip, { bus: "sfx", volume: j.volume });
    this.jingleTimer = Math.max(this.jingleTimer, j.duck);
  }

  onUpdate() {
    const dt = time.unscaledDt;
    if (this.jingleTimer > 0) this.jingleTimer -= dt;
    this.duckTarget = this.paused || this.jingleTimer > 0 ? this.duckGain : 1;
    const step = this.duckRate * dt;
    if (this.duck < this.duckTarget) this.duck = Math.min(this.duckTarget, this.duck + step);
    else this.duck = Math.max(this.duckTarget, this.duck - step);
    this.apply();
  }

  /** Sets the music bus to the player's volume times the duck. */
  apply() {
    const want = settings.load().volume.music * this.duck;
    if (Math.abs(audio.getVolume("music") - want) > 0.002) audio.setVolume("music", want);
  }
}
