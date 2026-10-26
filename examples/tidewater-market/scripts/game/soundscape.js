// @ts-check
// Soundscape: what the town sounds like from where the camera is. Engine-facing (it plays sounds); the maths is soundmix.js.
//
//   beds          three loops always playing, their volume following the screen: the sea near the coast, the market bustle near
//                 markets, houses and busy roads, wind when zoomed out or in winter
//   work sounds   a building in view that finishes a batch (`production.done`) makes its sound, panned by where it is and quieter
//                 the farther from the middle of the screen and the more zoomed out; at most `voices.work` at once, the nearest win
//   walkers       a few footsteps and cart creaks from the walkers nearest to the middle of the screen (`voices.walkers` at once)
//
// The engine's own spatial audio (AudioSource) falls off with world distance only and ignores the zoom of a strategy camera, so
// this does it from screen positions (ENGINE_FEEDBACK FB-0040). Everything here reads the simulation and never changes it, so the
// sound options and the camera cannot alter a game (the bot's state hash is the same with the sound on or off).
// The beds play on the "ambience" bus (factoria.json "audio"."buses", under "sfx"), whose volume is the options' ambience slider.
import { audio } from "factoria";
import { soundData } from "./sound_data.js";
import { VoiceBook, ambienceLevels, onScreen, sourceMix, SCREEN } from "./soundmix.js";
import { cellToWorld } from "./iso.js";
import { centreOf } from "./ui_model.js";

/** Rows of the grid of screen points that decides how much of the screen is sea (the columns are mix.seaSamples). */
const SEA_ROWS = 8;
/** Seconds between two footsteps / two cart creaks while walkers are in view. */
const STEP_EVERY = 0.5;
const CART_EVERY = 1.1;

export class Soundscape {
  /**
   * @param {import("./state.js").GameState} state
   * @param {import("./camera_rig.js").default} rig the camera rig (view, screenToCell, worldToScreen)
   */
  constructor(state, rig) {
    this.state = state;
    this.rig = rig;
    this.data = soundData();
    this.mix = this.data.mix;
    /** Real seconds since the soundscape started (sounds are presentation: this is not the game clock). */
    this.now = 0;
    this.sinceSample = 0;
    /** The volume each bed is at now, and where it is going (0..1, before the bus volumes). */
    this.levels = { sea: 0, market: 0, wind: 0 };
    this.target = { sea: 0, market: 0, wind: 0 };
    /** @type {Record<string, number>} the voice of each bed */
    this.beds = {};
    /** @type {Record<string, number>} the last volume sent to each bed's voice */
    this.sent = {};
    this.work = new VoiceBook(this.data.voices.work);
    this.walk = new VoiceBook(this.data.voices.walkers);
    /** @type {Map<number, number>} the time each building last made a sound */
    this.lastWork = new Map();
    this.stepClock = 0;
    this.cartClock = 0;
    /** The sounds started and dropped, by kind (tests, the stress town). */
    this.stats = { work: 0, steps: 0, carts: 0 };
    this.off = [this.state.events.on("production.done", (e) => this.onWork(e))];
    for (const name of Object.keys(this.data.ambience)) {
      const bed = this.data.ambience[name];
      this.beds[name] = audio.play(bed.clip, { volume: 0, loop: true, bus: "ambience" });
      this.sent[name] = 0;
    }
    this.refresh(true);
  }

  destroy() {
    for (const off of this.off) off();
    this.off = [];
    for (const voice of Object.values(this.beds)) audio.stop(voice);
    this.beds = {};
  }

  /** One frame: ease the beds towards the screen's mix, look at the walkers now and then. @param {number} dt real seconds */
  update(dt) {
    this.now += dt;
    this.sinceSample += dt;
    if (this.sinceSample >= this.mix.every) {
      this.sinceSample = 0;
      this.refresh(false, this.mix.every);
    }
  }

  /** Voices of the soundscape playing now: the beds and the one-shots counted by the books (which ask the engine). */
  get voices() {
    return Object.keys(this.beds).length + this.work.count + this.walk.count;
  }

  /**
   * Look at the screen and set the beds. `instant` puts them at their level at once (the start of the scene, tests); otherwise
   * they ease there over `mix.ease` seconds so a pan never jumps.
   */
  refresh(instant = false, dt = 0) {
    const view = this.sampleView();
    this.target = ambienceLevels(view, this.mix);
    const k = instant || dt <= 0 ? 1 : Math.min(1, dt / this.mix.ease);
    for (const name of Object.keys(this.beds)) {
      this.levels[name] += (this.target[name] - this.levels[name]) * k;
      const volume = this.levels[name] * this.data.ambience[name].volume;
      if (instant || Math.abs(volume - this.sent[name]) > 0.01 || (volume === 0) !== (this.sent[name] === 0)) {
        this.sent[name] = volume;
        audio.setVoiceVolume(this.beds[name], volume, instant ? 0 : this.mix.every * 1.5);
      }
    }
    this.walkerSounds(view, dt);
  }

  /** What the screen holds: the share of sea, the "busy" weight and the nearest walkers. */
  sampleView() {
    const { state, rig, mix } = this;
    const zoom = rig.view.zoom;
    const map = state.map;
    let water = 0;
    const cols = mix.seaSamples;
    for (let gx = 0; gx < cols; gx++) {
      for (let gy = 0; gy < SEA_ROWS; gy++) {
        const [c, r] = rig.screenToCell(((gx + 0.5) / cols) * SCREEN.width, ((gy + 0.5) / SEA_ROWS) * SCREEN.height);
        if (map.inBounds(c, r) && map.terrainAt(c, r) === "water") water++;
      }
    }
    let busy = 0;
    for (const b of state.buildings.values()) {
      const weight = b.type === "market" ? mix.marketWeight : b.type === "house" ? mix.houseWeight : 0;
      if (!weight) continue;
      const [c, r] = centreOf(b);
      const [wx, wy] = cellToWorld(c, r);
      const [sx, sy] = rig.worldToScreen(wx, wy);
      if (onScreen(sx, sy, mix.margin)) busy += weight;
    }
    /** @type {Record<string, { volume: number, pan: number }>} */
    const nearest = {};
    for (const w of state.sim.walkers.list.values()) {
      const [wx, wy] = cellToWorld(w.x, w.y);
      const [sx, sy] = rig.worldToScreen(wx, wy);
      if (!onScreen(sx, sy, 0)) continue;
      busy += mix.walkerWeight;
      const m = sourceMix(sx, sy, zoom, mix);
      if (!nearest[w.kind] || m.volume > nearest[w.kind].volume) nearest[w.kind] = m;
    }
    return { seaShare: water / (cols * SEA_ROWS), busy, zoom, winter: state.clock.date().season === "winter", nearest };
  }

  /** Footsteps and cart creaks from the nearest walkers, while the game runs. */
  walkerSounds(view, dt) {
    if (dt <= 0 || this.state.clock.speed === 0) return;
    this.stepClock += dt;
    this.cartClock += dt;
    if (this.stepClock >= STEP_EVERY && view.nearest.villager) {
      this.stepClock = 0;
      if (this.oneShot(this.walk, this.data.walkers.step, view.nearest.villager)) this.stats.steps++;
    }
    if (this.cartClock >= CART_EVERY && view.nearest.carrier) {
      this.cartClock = 0;
      if (this.oneShot(this.walk, this.data.walkers.cart, view.nearest.carrier)) this.stats.carts++;
    }
  }

  /** A building that finished a batch makes its sound, if it is in view and the cap allows. */
  onWork(e) {
    const b = this.state.buildings.get(e.building);
    if (!b) return;
    const sound = this.data.work[b.type];
    if (!sound) return;
    if (this.now - (this.lastWork.get(b.id) ?? -10) < this.data.voices.cooldown) return;
    const [c, r] = centreOf(b);
    const [wx, wy] = cellToWorld(c, r);
    const [sx, sy] = this.rig.worldToScreen(wx, wy);
    const m = sourceMix(sx, sy, this.rig.view.zoom, this.mix);
    if (m.volume < 0.05) return;
    this.lastWork.set(b.id, this.now);
    if (this.oneShot(this.work, sound, m)) this.stats.work++;
  }

  /** Play a one-shot through a book (the cap). @returns {boolean} it was started */
  oneShot(book, sound, m) {
    const offer = book.offer(m.volume);
    if (!offer.play) return false;
    if (offer.evict !== null) audio.stop(offer.evict);
    const voice = audio.play(sound.clip, { volume: sound.volume * m.volume, pan: m.pan, bus: "sfx" });
    book.add(voice, m.volume, offer.evict);
    return true;
  }
}
