// P6 sound: the music layers that follow a chase, the mix (ducking, snapshots, echo) and the captions of the sound cues.
import { test, describe, expect, game } from "factoria:test";
import { audio, storage } from "factoria";
import { cleanBeforeEach, playRows, miner, enemyList, teleport } from "./helpers/world.js";
import * as music from "../scripts/game/music.js";
import * as mix from "../scripts/game/mix.js";
import * as sound from "../scripts/game/sound.js";
import * as settings from "../scripts/settings.js";

const SECOND = 60;
const BAR = music.BAR[0]; // topsoil

const HALL = ["B".repeat(30), "B.S" + ".".repeat(24) + "EBB", "B".repeat(30)];
const withEnemy = (ch, tx) => {
  const r = [...HALL];
  r[1] = r[1].slice(0, tx) + ch + r[1].slice(tx + 1);
  return r;
};
/** A wide open cave: 17 x 15 floor with the entry lift in a corner. */
const CAVE = ["B".repeat(21), ...Array.from({ length: 15 }, (_, i) => "B" + (i === 1 ? ".S" + ".".repeat(16) : ".".repeat(18)) + (i === 14 ? "EBB" : "BBB")), "B".repeat(21)]
  .map((r) => r.slice(0, 21).padEnd(21, "B"));
const POOL = ["B".repeat(14), "B.S....wwwwww.EB", "B".repeat(14)].map((r) => r.padEnd(16, "B"));

describe("music layers", () => {
  cleanBeforeEach();

  test("the track of the stratum plays on the music bus and no layer plays while nothing hunts the miners", () => {
    playRows(HALL, { music: true });
    game.step(2 * BAR * SECOND);
    expect(game.audioLog()).toContainPlayed(music.forStratum(0), { bus: "music" });
    expect(music.layers()).toEqual({ danger: { wanted: false, playing: false }, fight: { wanted: false, playing: false } });
    expect(game.audioLog()).not.toContainPlayed(music.layerPath(0, "danger"));
  });

  test("a beetle that sees a miner brings the danger layer in on the next bar line, and the fight layer joins when it is on the miner", () => {
    playRows(withEnemy("b", 12), { music: true });
    teleport(miner(), 5, 1);
    game.step(10); // the beetle sees the miner: the layer is wanted at once but sounds on a bar line
    expect(music.layers().danger.wanted).toBe(true);
    game.step(Math.ceil(BAR * SECOND));
    expect(music.layers().danger.playing).toBe(true);
    expect(game.audioLog()).toContainPlayed(music.layerPath(0, "danger"), { bus: "music" });
    // the layer starts on a bar line of the track: the clock of the music is a whole number of bars (to a frame)
    const entry = game.audioLog().find((l) => l.path === music.layerPath(0, "danger"));
    expect(entry.loop).toBe(true);
    // the beetle reaches the miner and bites: the fight layer is wanted (a telegraph, a bite) and comes in on a bar line
    let fightPlayed = false;
    for (let i = 0; i < 8 * SECOND && !fightPlayed; i++) {
      game.step(1);
      fightPlayed = music.layers().fight.playing;
    }
    expect(fightPlayed).toBe(true);
    expect(game.audioLog()).toContainPlayed(music.layerPath(0, "fight"), { bus: "music" });
  });

  test("a layer starts on a bar line: its start time is a whole number of bars after the track", () => {
    playRows(withEnemy("b", 12), { music: true });
    teleport(miner(), 5, 1);
    game.step(Math.ceil(2 * BAR * SECOND));
    const track = game.audioLog().find((l) => l.music && l.path === music.forStratum(0));
    const layer = game.audioLog().find((l) => l.path === music.layerPath(0, "danger"));
    const bars = (layer.time - track.time) / BAR;
    expect(Math.abs(bars - Math.round(bars))).toBeLessThan(0.05);
  });

  test("when the enemy is gone the layers fall out: the hold, then the next bar line", () => {
    playRows(withEnemy("b", 12), { music: true });
    teleport(miner(), 5, 1);
    game.step(Math.ceil(2 * BAR * SECOND));
    expect(music.layers().danger.playing).toBe(true);
    for (const b of enemyList("beetle")) b.entity.destroy();
    game.step(Math.ceil((music.HOLD + BAR + 0.5) * SECOND));
    expect(music.layers().danger).toEqual({ wanted: false, playing: false });
    expect(music.layers().fight).toEqual({ wanted: false, playing: false });
  });

  test("a beetle that lost the miner gives up: the danger layer falls out after the chase memory and the hold", () => {
    playRows(withEnemy("b", 12), { music: true });
    teleport(miner(), 5, 1);
    game.step(Math.ceil(2 * BAR * SECOND));
    expect(music.want().danger).toBe(true);
    teleport(miner(), 26, 1); // far past its sight
    teleport(enemyList("beetle")[0].entity, 8, 1);
    game.step(SECOND);
    expect(enemyList("beetle")[0].target).toBe(null);
    game.step(Math.ceil((music.CHASE_MEMORY + music.HOLD + BAR + 1) * SECOND));
    expect(music.layers().danger.playing).toBe(false);
  });

  test("each stratum has its own layers, made of the same bar as its track", () => {
    for (const stratum of [0, 1, 2]) {
      expect(music.layerPath(stratum, "danger")).toMatch(/music_\w+_danger\.wav$/);
      expect(music.layerPath(stratum, "fight")).toMatch(/music_\w+_fight\.wav$/);
    }
    expect(new Set([0, 1, 2].map((n) => music.layerPath(n, "danger"))).size).toBe(3);
    playRows(withEnemy("b", 12), { music: true, stratum: 2 });
    teleport(miner(), 5, 1);
    game.step(Math.ceil(2 * music.BAR[2] * SECOND) + SECOND);
    expect(game.audioLog()).toContainPlayed(music.layerPath(2, "danger"), { bus: "music" });
  });

  test("a new shift starts the music again with no layer left over", () => {
    playRows(withEnemy("b", 12), { music: true });
    teleport(miner(), 5, 1);
    game.step(Math.ceil(2 * BAR * SECOND));
    expect(music.layers().danger.playing).toBe(true);
    playRows(HALL, { music: true });
    expect(music.layers().danger).toEqual({ wanted: false, playing: false });
    expect(game.audioLog().filter((l) => l.music && l.path === music.forStratum(0)).length).toBe(2);
  });
});

describe("the mix", () => {
  cleanBeforeEach();

  test("an alarm ducks the music for as long as it sounds, then the music comes back; the options volume is the ceiling", () => {
    playRows(HALL, { music: true });
    const user = mix.userVolume("music");
    game.step(30);
    expect(audio.getVolume("music")).toBeCloseTo(user, 2);
    mix.duck(1, 0.5);
    game.step(30);
    expect(audio.getVolume("music")).toBeLessThan(user * 0.6);
    game.step(2 * SECOND);
    expect(audio.getVolume("music")).toBeCloseTo(user, 2);
  });

  test("a cue with a duck lowers the music: the cave-in rumble does", () => {
    playRows(HALL, { music: true });
    game.step(30);
    const before = audio.getVolume("music");
    sound.play("assets/audio/rumble.wav", { volume: 0.5 }, { key: "caption.rumble", duck: 1.5, depth: 0.5 });
    game.step(30);
    expect(audio.getVolume("music")).toBeLessThan(before * 0.6);
  });

  test("paused: music and effects are muffled (quieter) behind the pause menu, UI is not, and play brings them back", () => {
    playRows(HALL, { music: true });
    game.step(30);
    const music0 = audio.getVolume("music");
    const sfx0 = audio.getVolume("sfx");
    game.paused = true;
    game.step(2 * SECOND);
    expect(mix.snapshotName()).toBe("paused");
    expect(audio.getVolume("music")).toBeLessThan(music0 * 0.6);
    expect(audio.getVolume("sfx")).toBeLessThan(sfx0 * 0.5);
    expect(audio.getVolume("ui")).toBeCloseTo(1, 2);
    game.paused = false;
    game.step(2 * SECOND);
    expect(audio.getVolume("music")).toBeCloseTo(music0, 2);
    expect(audio.getVolume("sfx")).toBeCloseTo(sfx0, 2);
  });

  test("underwater: standing in water muffles the music and effects, stepping out clears it", () => {
    playRows(POOL, { music: true });
    game.step(4 * SECOND);
    const music0 = mix.userVolume("music");
    teleport(miner(), 8, 1);
    game.step(2 * SECOND);
    expect(mix.snapshotName()).toBe("underwater");
    expect(audio.getVolume("music")).toBeCloseTo(music0 * mix.SNAPSHOTS.underwater.music, 2);
    teleport(miner(), 3, 1);
    game.step(4 * SECOND);
    expect(mix.snapshotName()).toBe("normal");
    expect(audio.getVolume("music")).toBeCloseTo(music0, 2);
  });

  test("the pause does not leave the mix muffled when the shift ends (back to the title)", () => {
    playRows(HALL, { music: true });
    game.paused = true;
    game.step(60);
    expect(audio.getVolume("sfx")).toBeLessThan(0.5);
    game.paused = false;
    music.stop();
    expect(audio.getVolume("sfx")).toBeCloseTo(1, 2);
  });

  test("the options sliders are the user level of each bus; the mix puts the snapshot on top of them", () => {
    playRows(HALL, { music: true });
    const s = settings.load();
    s.volume.sfx = 0.5;
    settings.save(s);
    settings.apply(s);
    game.step(10);
    expect(audio.getVolume("sfx")).toBeCloseTo(0.5, 2);
    game.paused = true;
    game.step(60);
    expect(audio.getVolume("sfx")).toBeCloseTo(0.5 * mix.SNAPSHOTS.paused.sfx, 2);
  });

  test("a big cavern echoes a cued sound once, quieter; a corridor does not", () => {
    playRows(HALL, { music: true });
    game.step(60);
    sound.play("assets/audio/bite.wav", { volume: 0.8 }, { key: "caption.bite" });
    game.step(SECOND);
    expect(game.audioLog().filter((l) => l.path.endsWith("bite.wav")).length).toBe(1);

    playRows(CAVE, { music: true });
    teleport(miner(), 10, 8);
    game.step(2 * SECOND);
    expect(mix.snapshotName()).toBe("cavern");
    game.clearAudioLog();
    sound.play("assets/audio/bite.wav", { volume: 0.8 }, { key: "caption.bite" });
    expect(sound.pendingEchoes()).toBe(1);
    game.step(SECOND);
    const plays = game.audioLog().filter((l) => l.path.endsWith("bite.wav"));
    expect(plays.length).toBe(2);
    expect(plays[1].volume).toBeCloseTo(plays[0].volume * sound.ECHO_GAIN, 2);
    expect(plays[1].time - plays[0].time).toBeGreaterThan(sound.ECHO_DELAY - 0.05);
  });
});

describe("sound captions", () => {
  cleanBeforeEach();

  test("a cue puts a caption on the list with a direction word seen from the nearest miner", () => {
    playRows(HALL, { captions: true });
    const m = miner().position;
    sound.play("assets/audio/bite.wav", { volume: 0.5 }, { key: "caption.bite", x: m.x + 80, y: m.y });
    sound.play("assets/audio/rumble.wav", { volume: 0.5 }, { key: "caption.rumble", x: m.x - 80, y: m.y });
    sound.play("assets/audio/crash.wav", { volume: 0.5 }, { key: "caption.crash", x: m.x, y: m.y + 80 });
    sound.play("assets/audio/ore.wav", { volume: 0.5 }, { key: "caption.rescue", x: m.x + 4, y: m.y });
    const texts = game.captions().map((c) => c.text);
    expect(texts).toContain("Beetle bite! (right)");
    expect(texts).toContain("The roof rumbles (left)");
    expect(texts).toContain("Rocks crash down (above)");
    expect(texts).toContain("Mole freed (close)");
  });

  test("a beetle's bite is captioned in the shift, and so are the lamp running low and the mole's call", () => {
    playRows(withEnemy("b", 8), { captions: true });
    teleport(miner(), 6, 1);
    game.step(2 * SECOND);
    expect(game.captions().some((c) => c.text.startsWith("Beetle bite!"))).toBe(true);
    expect(game.captions().some((c) => c.text.startsWith("Beetle hisses") || c.text.startsWith("A beetle hisses"))).toBe(true);
  });

  test("the option switches the sound_captions entity: off by default, on when chosen, and it is saved", () => {
    playRows(HALL, { captions: true });
    const widget = game.find("sound_captions");
    settings.applySubtitles(settings.load());
    expect(widget.active).toBe(false);
    const s = settings.load();
    s.soundCaptions = true;
    settings.save(s);
    settings.applySubtitles(settings.load());
    expect(widget.active).toBe(true);
    expect(storage.get("settings").soundCaptions).toBe(true);
  });

  test("a caption goes after its seconds, and the shift scene keeps the widget clear of the HUD of four players", () => {
    playRows(HALL, { captions: true });
    sound.play("assets/audio/bite.wav", { volume: 0.5 }, { key: "caption.bite" });
    expect(game.captions().length).toBe(1);
    game.step(Math.ceil((sound.SECONDS + 0.5) * SECOND));
    expect(game.captions().length).toBe(0);
    // the oil bars of four players take the bottom-left corner up to 300 px; the widget sits to the right of them
    const scene = JSON.parse(JSON.stringify(game.world.find("sound_captions").get("Captions").size));
    const x = game.world.find("sound_captions").position.x;
    expect(640 + x - scene[0] / 2).toBeGreaterThan(310);
  });
});
