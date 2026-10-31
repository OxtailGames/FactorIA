// P6 sound: the tables, the maths of the mix, the buses, the beds following the camera and the voice caps.
import { test, expect, game } from "factoria:test";
import { audio, scene } from "factoria";
import { rawSoundTables, validateSoundTables, soundData } from "../scripts/game/sound_data.js";
import { zoomGain, ambienceLevels, sourceMix, onScreen, VoiceBook } from "../scripts/game/soundmix.js";
import { playUi, resetUi } from "../scripts/game/sfx.js";
import * as settings from "../scripts/settings.js";
import { cellToWorld } from "../scripts/game/iso.js";
import { townScene } from "./ui_helper.js";

const mix = () => soundData().mix;

test("sound tables: the shipped table is sound and a mistake names the file, the pointer and the fix", () => {
  expect(validateSoundTables(rawSoundTables)).toEqual([]);
  const bad = JSON.parse(JSON.stringify(rawSoundTables));
  bad.sounds.ui.click.clip = "assets/sfx/nope.ogg";
  bad.sounds.work.farmm = { clip: "assets/sfx/work_farm.ogg", volume: 0.5, seconds: 1 };
  delete bad.sounds.ambience.wind;
  const problems = validateSoundTables(bad);
  const text = problems.map((p) => `${p.file} ${p.pointer} ${p.message} ${p.hint}`).join("\n");
  expect(text).toContain("/ui/click/clip");
  expect(text).toContain("is not in assets.json");
  expect(text).toContain("did you mean 'farm'");
  expect(text).toContain("/ambience/wind");
});

test("sound mix: the zoom, the beds and where a sound comes from", () => {
  const m = mix();
  expect(zoomGain(m.fullZoom, m)).toBeCloseTo(1);
  expect(zoomGain(m.farZoom, m)).toBeCloseTo(0.2);
  expect(zoomGain(5, m)).toBeCloseTo(1);
  // a coast filling the screen: the sea; a busy street: the market; high up or in winter: wind
  const coast = ambienceLevels({ seaShare: 0.6, busy: 0, zoom: 1, winter: false }, m);
  const street = ambienceLevels({ seaShare: 0, busy: 6, zoom: 1, winter: false }, m);
  expect(coast.sea).toBeGreaterThan(0.9);
  expect(coast.market).toBe(0);
  expect(street.market).toBeGreaterThan(0.9);
  expect(street.sea).toBe(0);
  expect(coast.wind).toBe(0);
  expect(ambienceLevels({ seaShare: 0, busy: 0, zoom: m.farZoom, winter: false }, m).wind).toBeGreaterThan(0.8);
  expect(ambienceLevels({ seaShare: 0, busy: 0, zoom: 1, winter: true }, m).wind).toBeGreaterThan(0.5);
  // closer to the middle is louder, a sound off the screen is silent, the pan follows the side
  const mid = sourceMix(640, 360, 1, m);
  const edge = sourceMix(1200, 100, 1, m);
  expect(mid.volume).toBeGreaterThan(edge.volume);
  expect(sourceMix(-500, 100, 1, m).volume).toBe(0);
  expect(sourceMix(1200, 360, 1, m).pan).toBeGreaterThan(0.5);
  expect(sourceMix(80, 360, 1, m).pan).toBeLessThan(-0.5);
  expect(onScreen(-10, 10, 20)).toBe(true);
  expect(onScreen(-30, 10, 20)).toBe(false);
});

test("sound mix: the voice book never holds more than its cap, nearer sounds win", () => {
  let alive = new Set();
  const book = new VoiceBook(3, () => alive);
  let id = 1;
  for (let i = 0; i < 10; i++) {
    const offer = book.offer(0.2 + i * 0.01);
    if (offer.play) {
      alive.add(id);
      if (offer.evict !== null) alive.delete(offer.evict);
      book.add(id++, 0.2 + i * 0.01, offer.evict);
    }
    expect(book.count).toBeLessThanOrEqual(3);
  }
  expect(book.dropped).toBeGreaterThan(0);
  // a much louder one takes the place of the weakest
  const loud = book.offer(1);
  expect(loud.play).toBe(true);
  expect(loud.evict).not.toBe(null);
  // after the engine says the sounds are gone the book is empty again
  alive = new Set();
  expect(book.count).toBe(0);
  expect(book.peak).toBe(3);
});

test("sound mix: the book follows the engine's voices (audio.activeVoices) and audio.play's onEnded", () => {
  townScene();
  const book = new VoiceBook(2);
  const scene0 = scene.current;
  const ended = [];
  const ids = [];
  for (let i = 0; i < 2; i++) {
    const offer = book.offer(1);
    expect(offer.play).toBe(true);
    const id = audio.play("assets/sfx/ui_click.ogg", { bus: "ui", onEnded: (v) => { if (scene.current === scene0) ended.push(v); } });
    ids.push(id);
    book.add(id, 1);
  }
  expect(book.offer(1).play).toBe(false); // two play, the cap is two
  expect(audio.activeVoices().filter((v) => ids.includes(v.id)).map((v) => v.bus)).toEqual(["ui", "ui"]);
  game.step(240); // longer than the clip
  expect(ended.slice().sort()).toEqual(ids.slice().sort()); // each end reported once
  expect(book.count).toBe(0);
  expect(book.offer(1).play).toBe(true);
});

test("buses: each volume of the options reaches the mixer; the ambience bus scales the beds", () => {
  const { ctl } = townScene({ trade: true });
  const s = settings.load();
  s.volume = { master: 0.9, music: 0.31, ambience: 0.5, sfx: 0.42, ui: 0.27 };
  settings.apply(s);
  for (const bus of settings.BUSES) expect(audio.getVolume(bus)).toBeCloseTo(s.volume[bus]);
  // the beds play on the ambience bus (a child of sfx) at level * bed volume: the slider is the bus volume, not a multiplier
  const sound = ctl.soundscape;
  sound.refresh(true);
  expect(audio.activeVoices().filter((v) => Object.values(sound.beds).includes(v.id)).map((v) => v.bus)).toEqual(["ambience", "ambience", "ambience"]);
  const full = { ...sound.sent };
  s.volume.ambience = 0.25;
  settings.apply(s);
  sound.refresh(true);
  expect(audio.getVolume("ambience")).toBeCloseTo(0.25);
  for (const name of Object.keys(full)) expect(sound.sent[name]).toBeCloseTo(full[name], 3); // the voices do not change
  expect(audio.bus("ambience").state().volume).toBeCloseTo(0.25);
});

test("buses: the interface sounds play on the ui bus, with a gap after the same sound", () => {
  townScene();
  resetUi();
  game.clearAudioLog();
  expect(playUi("click")).toBe(true);
  expect(playUi("click")).toBe(false); // the same frame: not twice
  expect(playUi("nope")).toBe(false);
  expect(game.audioLog()).toContainPlayed("ui_click.ogg", { times: 1, bus: "ui" });
});

test("ambience follows the camera: the sea at the coast, the market in the streets, wind from high up", () => {
  const { ctl, rig } = townScene({ trade: true });
  const sound = ctl.soundscape;
  settings.apply({ ...settings.load(), volume: { ...settings.load().volume, ambience: 0.8 } }); // an earlier test may have muted it
  const look = (c, r, zoom) => {
    const [x, y] = cellToWorld(c, r);
    rig.setView(x, y, zoom);
    sound.refresh(true);
    return { ...sound.target };
  };
  const town = look(5, 5, 3);
  const coast = look(0, 0, 3);
  expect(town.market).toBeGreaterThan(coast.market);
  expect(coast.sea).toBeGreaterThan(town.sea);
  const high = look(5, 5, 0.45);
  expect(high.wind).toBeGreaterThan(town.wind);
  // the volume sent to the engine moves with it, and the audio log shows each change
  game.clearAudioLog();
  look(5, 5, 3);
  const marketSent = sound.sent.market;
  look(0, 0, 3);
  expect(sound.sent.market).toBeLessThan(marketSent);
  const changes = game.audioLog().filter((e) => e.kind === "setVoiceVolume" && e.voice === sound.beds.market);
  expect(changes.length).toBeGreaterThan(0);
  expect(changes[changes.length - 1].volume).toBeCloseTo(sound.sent.market);
});

test("voice cap: the stress town never plays more voices than its caps", () => {
  game.load("scenes/stress.scene.json");
  game.step(20);
  const ctl = game.find("controller").behaviour;
  expect(scene.current).toBe("scenes/stress.scene.json");
  const sound = ctl.soundscape;
  const caps = soundData().voices;
  ctl.state.clock.setSpeed(3);
  let worst = 0;
  for (let i = 0; i < 600; i++) {
    game.step(1);
    worst = Math.max(worst, sound.voices);
  }
  console.log("voice cap: peak voices", worst, "work", sound.work.peak, "walkers", sound.walk.peak, "dropped", sound.work.dropped + sound.walk.dropped);
  expect(sound.work.peak).toBeLessThanOrEqual(caps.work);
  expect(sound.walk.peak).toBeLessThanOrEqual(caps.walkers);
  expect(worst).toBeLessThanOrEqual(caps.work + caps.walkers + 3);
  expect(worst).toBeLessThan(40); // the engine's own limit is 64
  expect(sound.walk.started).toBeGreaterThan(0); // the cap is tested against sounds that did play
  // every workplace finishes a batch in the same moment, in view: no more than `work` of them are heard
  const view = ctl.rig.view;
  ctl.rig.setView(view.x, view.y, 1);
  const before = sound.work.started;
  for (const b of ctl.state.buildings.values()) ctl.state.events.emit("production.done", { building: b.id, recipe: "x", outputs: {} });
  expect(sound.work.count).toBeLessThanOrEqual(caps.work);
  expect(sound.work.peak).toBeLessThanOrEqual(caps.work);
  expect(sound.voices).toBeLessThan(40);
  console.log("voice cap: batch started", sound.work.started - before, "dropped", sound.work.dropped);
});
