// P6 sound: the ambience of each room, the footsteps of each floor, the music of each chapter, and the voice ducking them through
// the buses (scripts/sound.js, data/sound.json).
import { test, describe, expect, beforeEach, game } from "factoria:test";
import { audio, session } from "factoria";
import * as story from "../scripts/story.js";
import * as items from "../scripts/items.js";
import * as chapters from "../scripts/chapters.js";
import * as mix from "../scripts/mix.js";
import data from "../data/sound.json";
import { enter, porter, stand } from "./helpers/lodge.js";

const sound = () => game.find("sound").behaviour;
/** The middle of the floor of `room` in the current area. */
function centre(room) {
  const r = sound().rects.find((x) => x.id === room);
  if (!r) throw new Error(`no floor f_${room} in this area (rooms: ${sound().rects.map((x) => x.id).join(", ")})`);
  return [(r.x0 + r.x1) / 2, (r.z0 + r.z1) / 2];
}
/** The porter stands in the middle of `room`; the sound has seen it. */
function goTo(room) {
  const [x, z] = centre(room);
  stand(x, z, 0);
  game.step(3);
}
/** How many times a clip (file name) was played on `bus`. */
const plays = (name, bus) => game.audioLog().filter((p) => p.kind === "play" && p.path.endsWith(name) && (!bus || p.bus === bus)).length;

describe("ambience", () => {
  beforeEach(() => enter("ground"));

  test("the hall has its clock, a little fire and the wind; the library has more fire; each bed is a looping voice on the ambience bus", () => {
    goTo("hall");
    expect(sound().room).toBe("hall");
    expect(sound().bedLevels).toMatchObject({ clock: 0.6, wind: 0.2, fire: 0.35, cellar_air: 0 });
    for (const bed of ["clock.wav", "wind.wav", "fire.wav"]) expect(game.audioLog()).toContainPlayed(bed, { bus: "ambience" });
    expect(plays("cellar_air.wav")).toBe(0); // a bed a room never wants is never started
    goTo("library");
    expect(sound().room).toBe("library");
    expect(sound().bedLevels.fire).toBe(0.7);
    expect(sound().bedLevels.clock).toBe(0.3);
    expect(plays("fire.wav")).toBe(1); // the same voice is faded, not started again
  });

  test("the ambience bus is a child of sfx, so what ducks sfx ducks it, and the options have a slider for it", () => {
    expect(audio.bus("ambience").state().volume).toBeGreaterThan(0);
    expect(mix.state().duck.sfx).toMatchObject({ by: "voiceover" });
    audio.setVolume("ambience", 0.25);
    expect(audio.getVolume("ambience")).toBeCloseTo(0.25);
  });

  test("the cellar has its own air and none of the lodge's fire and clocks", () => {
    enter("cellar");
    goTo("cellar");
    expect(sound().room).toBe("cellar");
    expect(sound().bedLevels).toMatchObject({ cellar_air: 1, wind: 0, fire: 0, clock: 0 });
    expect(game.audioLog()).toContainPlayed("cellar_air.wav", { bus: "ambience" });
  });

  test("after the storm the wind is quieter", () => {
    goTo("hall");
    const before = sound().bedLevels.wind;
    story.set("storm_over", true);
    game.step(2);
    expect(sound().bedLevels.wind).toBeCloseTo(before * data.stormOverWind);
  });
});

describe("footsteps", () => {
  beforeEach(() => enter("ground"));

  test("each stride makes a step of the floor under the porter: carpet in the hall, wood in the kitchen, concrete in the cellar", () => {
    goTo("hall");
    game.clearAudioLog();
    game.press("move_forward");
    game.step(90);
    game.release("move_forward");
    expect(sound().surface).toBe("carpet");
    expect(plays("footstep_carpet_000.ogg", "sfx")).toBeGreaterThan(0);
    expect(plays("footstep_wood_000.ogg")).toBe(0);
    goTo("kitchen");
    game.clearAudioLog();
    game.press("move_forward");
    game.step(90);
    game.release("move_forward");
    expect(sound().surface).toBe("wood");
    expect(game.audioLog()).toContainPlayed("footstep_wood_000.ogg");
    enter("cellar");
    goTo("cellar");
    game.clearAudioLog();
    game.press("move_forward");
    game.step(90);
    expect(game.audioLog()).toContainPlayed("footstep_concrete_000.ogg");
  });

  test("the three variants take turns, and standing still is silent", () => {
    goTo("hall");
    game.clearAudioLog();
    game.step(60);
    expect(game.audioLog().filter((p) => p.path.includes("footstep_")).length).toBe(0);
    const s = sound();
    for (let i = 0; i < 3; i++) s.step();
    for (const n of ["000", "001", "002"]) expect(game.audioLog()).toContainPlayed(`footstep_carpet_${n}.ogg`);
  });

  test("a walk makes about one step per stride", () => {
    goTo("hall");
    game.clearAudioLog();
    const z0 = porter().position.z;
    game.press("move_forward");
    game.step(60);
    game.release("move_forward");
    const metres = Math.abs(z0 - porter().position.z);
    const steps = game.audioLog().filter((p) => p.path.includes("footstep_")).length;
    expect(steps).toBeGreaterThanOrEqual(Math.floor(metres / data.footsteps.stride) - 1);
    expect(steps).toBeLessThanOrEqual(Math.ceil(metres / data.footsteps.stride) + 1);
  });
});

describe("music", () => {
  /** A new game in chapter `n`, the first area, as the title menu's Play does. */
  function chapter(n) {
    game.resetState();
    session.musicTrack = undefined; audio.stopMusic(); // tests share session and audio: no track is running in a new game
    story.reset();
    items.reset();
    chapters.begin({ intro: false });
    if (n > 1) story.set("chapter", n);
    game.clearAudioLog();
    game.load("scenes/ground.scene.json", { arrive: "spawn_default" });
    game.step(10);
  }

  test("each chapter has its own track, and a scene with no story (a test room) has none", () => {
    for (let n = 1; n <= 5; n++) {
      chapter(n);
      expect(game.audioLog()).toContainPlayed(`music_ch${n}.wav`);
      expect(sound().track).toBe(`assets/audio/music_ch${n}.wav`);
    }
    game.resetState();
    session.musicTrack = undefined; audio.stopMusic(); // tests share session and audio: no track is running in a new game
    story.reset();
    items.reset();
    game.clearAudioLog();
    game.load("scenes/ground.scene.json", { arrive: "spawn_default" });
    game.step(10);
    expect(game.audioLog().filter((p) => p.path.includes("music_"))).toEqual([]);
  });

  test("a new chapter changes the track; an area change in the same chapter keeps it playing", () => {
    chapter(1);
    expect(game.audioLog()).toContainPlayed("music_ch1.wav");
    game.clearAudioLog();
    game.load("scenes/upstairs.scene.json", { arrive: "spawn_default" });
    game.step(10);
    expect(game.audioLog().filter((p) => p.path.includes("music_"))).toEqual([]);
    story.set("chapter", 2);
    game.world?.emit?.("chapter_changed", { chapter: 2, previous: 1 });
    game.step(2);
    expect(game.audioLog()).toContainPlayed("music_ch2.wav");
  });

  test("the title screen has its theme on the music bus", () => {
    game.resetState();
    session.musicTrack = undefined; audio.stopMusic(); // tests share session and audio: no track is running in a new game
    game.clearAudioLog();
    game.load("scenes/menu.scene.json");
    game.step(5);
    expect(game.audioLog()).toContainPlayed("music_title.wav", { bus: "music" });
  });
});

describe("the voice over the mix", () => {
  test("sound.js sets up the ducking: the music and the effects drop under the voiceover bus", () => {
    enter("ground");
    expect(audio.bus("music").state().duck).toMatchObject({ by: "voiceover" });
    expect(audio.bus("sfx").state().duck).toMatchObject({ by: "voiceover" });
  });
});
