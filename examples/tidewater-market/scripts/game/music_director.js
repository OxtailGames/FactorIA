// @ts-check
// MusicDirector: plays the loop of the current season (data/seasons.json `music`) and crossfades to the next one when the
// season changes. The clock decides when (state.events "clock.season"); this class only talks to the audio engine.
import { audio } from "factoria";

export class MusicDirector {
  /** @param {import("./state.js").GameState} state @param {{ fade?: number }} [options] */
  constructor(state, options = {}) {
    this.state = state;
    this.fade = options.fade ?? 3;
    /** The season whose loop plays now ("" before the first). */
    this.season = "";
    this.off = state.events.on("clock.season", (e) => this.play(e.date.season));
    this.play(state.clock.date().season);
  }

  /** Start the loop of a season (the track that is already playing is only retuned). */
  play(season) {
    const info = this.state.data.seasons[season];
    if (!info || !info.music) return;
    this.season = season;
    audio.music(info.music, { volume: info.musicVolume, fade: this.fade });
  }

  destroy() {
    this.off();
  }
}
