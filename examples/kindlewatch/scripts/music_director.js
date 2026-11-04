// @ts-check
// Directs the adaptive score (assets/music/night.song.json, played by the MusicPlayer on this entity): the song's layers
// come in with `intensity` (base always; pulse from 0.3; tension from 0.55; voice from 0.8), and its sections change on
// the bar. Intensity follows the danger: wolves alive, how low the fire is, the alpha. At dawn the music crosses over to
// the dawn song; if the game is lost it crosses to the defeat song. The alpha's arrival is a stinger (its howl) that
// ducks the music for a moment.
import { Behaviour, world } from "factoria";
import { behaviourOf } from "./common.js";

const NIGHT = "assets/music/night.song.json";
const DAWN = "assets/music/dawn.song.json";
const DEFEAT = "assets/music/defeat.song.json";

export default class MusicDirector extends Behaviour {
  /** How fast the intensity follows the danger, per second. */
  follow = 0.5;

  onStart() {
    this.level = 0.1;
    this.section = "intro";
    this.song = NIGHT;
    this.wait = 0;
    this.over = false;
    this.player = this.entity.music;
    // A hard start of the night song: a crossfade left pending by the scene before (a retry during the dawn) must not decide it.
    this.player.play({ song: NIGHT, section: "intro", intensity: this.level });
    this.unsubscribes = [
      world.on("dawn_start", () => this.cross(DAWN, "loop")),
      world.on("night_start", (d) => d.n > 1 && this.cross(NIGHT, "intro")),
      world.on("game_end", (d) => !d.won && this.cross(DEFEAT, "loop")),
      world.on("wolf_roar", (d) => d.kind === "alpha" && this.player.playStinger({ clip: "assets/audio/alpha_howl.wav", quantize: "beat", duck: 0.45 })),
    ];
  }

  onDestroy() {
    for (const off of this.unsubscribes ?? []) off();
  }

  cross(song, section) {
    if (this.song === song) return;
    this.song = song;
    this.over = song === DEFEAT;
    this.level = song === NIGHT ? 0.1 : this.level;
    this.player.crossfadeTo(song, { quantize: "bar", bars: 2, ...(section ? { section } : {}) });
  }

  /** 0..1: how dangerous the moment is. */
  danger() {
    const game = behaviourOf("game");
    const fire = behaviourOf("campfire");
    if (!game || game.state !== "night") return 0.1;
    const wolves = world.findByTag("wolf");
    let d = 0.1 + 0.55 * Math.min(1, wolves.length / game.config.maxWolves);
    if (fire) d += 0.3 * (1 - fire.fraction);
    if (wolves.some((w) => w.behaviour?.kind === "alpha")) d += 0.25;
    // The last stretch of a night rises: the voice layer is for the last wave.
    if (game.config) d += 0.2 * (game.timer / game.config.length) ** 2;
    return Math.min(1, d);
  }

  onUpdate(dt) {
    if (this.song !== NIGHT || !this.player) return;
    const game = behaviourOf("game");
    const target = this.danger();
    this.level += Math.sign(target - this.level) * Math.min(Math.abs(target - this.level), this.follow * dt);
    this.player.setIntensity(this.level);
    // Calm while no wolf is about; the hunt section while they are.
    if (game && game.state === "night") {
      const want = world.findByTag("wolf").length > 0 ? "hunt" : "calm";
      this.wait -= dt;
      if (want !== this.section && this.wait <= 0) {
        this.section = want;
        this.wait = 6; // do not flip back and forth every time a wolf dies
        this.player.goToSection(want, { quantize: "bar" });
      }
    }
  }
}
