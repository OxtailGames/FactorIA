// @ts-check
// The sound of the lodge (one "sound" entity in each area scene): the ambience of the room the porter stands in, his footsteps on
// the floor under him, and the music of the chapter. data/sound.json says what each room, surface and chapter sounds like.
//
//   - Ambience: looping beds (wind, fire, clock, cellar air) on the `ambience` bus (factoria.json, a child of sfx, so the
//     voice ducks it with the sound effects). Every bed starts silent the first time a room wants it; moving to another room fades
//     each bed to the new room's level (data/sound.json "fade" seconds) and the beds the room lacks to 0. After the storm
//     (story flag storm_over) the wind is quieter.
//   - Footsteps: a Kenney impact clip of the floor surface of the room every `stride` metres walked; the three variants
//     are taken in turn by a counter (no random numbers: the story bot's hashes do not move).
//   - Music: audio.music(track, { persist: true }) for the chapter, so the track runs through the doors between areas and
//     only changes when the chapter does. The title screen's track is startTitleMusic().
//
// Fields tests read: `room`, `surface`, `bedLevels` (bed -> level now aimed at), `steps` (footsteps played), `track` (the music path).
import { Behaviour, audio, world, session } from "factoria";
import { EVENTS } from "./events.js";
import * as story from "./story.js";
import { current as chapter } from "./chapters.js";
import data from "../data/sound.json";
import * as mix from "./mix.js";

/** Music of the title screen (scripts/main_menu.js calls it). */
export function startTitleMusic() {
  if (session.musicTrack === data.music.title) return;
  session.musicTrack = data.music.title;
  audio.music(data.music.title, { persist: true, fade: data.music.fade });
}

/** Music path of chapter `n` (1..5), or "" when there is no chapter. */
export function chapterTrack(n) {
  return data.music.chapters[Math.min(n, data.music.chapters.length) - 1] ?? "";
}

export default class Sound extends Behaviour {
  onStart() {
    mix.setup();
    this.room = "";
    this.surface = "";
    this.steps = 0;
    this.track = "";
    this.stride = 0;
    this.last = null;
    this.bedVoice = {}; // bed name -> voice id
    this.bedLevels = {};
    /** @type {{ id: string, x0: number, x1: number, z0: number, z1: number }[]} */
    this.rects = [];
    for (const id of Object.keys(data.rooms)) {
      const e = world.find(`f_${id}`);
      if (!e) continue;
      const t = e.get("Transform");
      const p = t.position;
      const s = t.scale;
      const px = p.x ?? p[0];
      const pz = p.z ?? p[2];
      const sx = s.x ?? s[0];
      const sz = s.z ?? s[2];
      this.rects.push({ id, x0: px, x1: px + sx, z0: pz - sz, z1: pz });
    }
    this.unsub = world.on(EVENTS.chapterChanged, () => this.playMusic());
    this.unsubFlag = world.on(EVENTS.flagChanged, (d) => d.flag === "storm_over" && this.aim());
    this.playMusic();
  }

  onDestroy() {
    this.unsub?.();
    this.unsubFlag?.();
  }

  /** The music of the chapter; nothing before a game has begun (a bare test scene). */
  playMusic() {
    const n = chapter();
    const path = n > 0 ? chapterTrack(n) : "";
    if (!path) return;
    this.track = path;
    if (session.musicTrack === path) return; // already running (persist keeps it through the doors between areas)
    session.musicTrack = path;
    audio.music(path, { persist: true, fade: data.music.fade });
  }

  /** The room whose floor holds (x, z), or the last one when the porter is between floors (a doorway). */
  roomAt(x, z) {
    for (const r of this.rects) if (x >= r.x0 - 0.05 && x <= r.x1 + 0.05 && z >= r.z0 - 0.05 && z <= r.z1 + 0.05) return r.id;
    return this.room;
  }

  /** The beds and surface of `this.room` as data/sound.json says. */
  roomData() {
    return data.rooms[this.room] ?? data.defaultRoom;
  }

  /** Fades every bed to the level the room wants (a bed is started, silent, the first time it is wanted). */
  aim() {
    const want = this.roomData().beds;
    const storm = story.get("storm_over", false) ? data.stormOverWind : 1;
    for (const name of Object.keys(data.beds)) {
      const level = (want[name] ?? 0) * (name === "wind" ? storm : 1);
      this.bedLevels[name] = level;
      if (this.bedVoice[name] === undefined) {
        if (level === 0) continue;
        this.bedVoice[name] = audio.play(data.beds[name], { loop: true, volume: 0, bus: "ambience" });
      }
      audio.setVoiceVolume(this.bedVoice[name], level, data.fade);
    }
  }

  onUpdate(dt) {
    const porter = world.find("porter");
    if (!porter) return;
    const p = porter.position;
    const room = this.roomAt(p.x, p.z);
    if (room !== this.room || this.surface === "") {
      this.room = room;
      this.surface = this.roomData().surface;
      this.aim();
    }
    // Footsteps: metres walked on the ground (a jump or a fall does not step).
    const b = porter.behaviour;
    if (this.last && b && b.grounded !== false) {
      const d = Math.hypot(p.x - this.last.x, p.z - this.last.z);
      if (d < 2) this.stride += d; // a teleport (a door) is not a walk
    }
    this.last = { x: p.x, z: p.z };
    if (this.stride >= data.footsteps.stride) {
      this.stride -= data.footsteps.stride;
      this.step();
    }
  }

  /** One footstep on the current surface; the variants take turns. */
  step() {
    const clips = data.footsteps.surfaces[this.surface];
    if (!clips) return;
    audio.play(clips[this.steps % clips.length], { bus: "sfx", volume: data.footsteps.volume });
    this.steps++;
  }
}
