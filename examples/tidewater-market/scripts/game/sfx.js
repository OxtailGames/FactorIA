// @ts-check
// The interface sounds (data/sounds.json "ui"): click, place, demolish, error, notice, order filled, event card, confirm.
// playUi(name) plays one on the "ui" bus; GameSfx plays them for what happens in a game (building placed or removed, an action
// refused, a new notice, an order filled, an event card). Every sound has a short gap after it (a road drawn cell by cell is one
// sound, not forty) and the ui bus is capped at `voices.ui`. Nothing here changes the game: it only listens.
import { audio, world } from "factoria";
import { soundData } from "./sound_data.js";
import { VoiceBook } from "./soundmix.js";

/** Frames between two plays of the same sound (60 per second). */
const GAP_FRAMES = { click: 4, place: 8, demolish: 8, error: 12, notice: 30, filled: 20, card: 20, confirm: 10 };

/** @type {Map<string, number>} the frame each sound last played */
const lastFrame = new Map();
/** @type {VoiceBook | null} */
let book = null;

/**
 * Play one UI sound. @param {string} name a key of data/sounds.json "ui"
 * @returns {boolean} it was started (false: an unknown name, too soon after the same sound, or the cap)
 */
export function playUi(name) {
  const data = soundData();
  const sound = data.ui[name];
  if (!sound) return false;
  const frame = world.frame;
  const last = lastFrame.get(name);
  if (last !== undefined && frame >= last && frame - last < (GAP_FRAMES[name] ?? 6)) return false;
  if (!book) book = new VoiceBook(data.voices.ui);
  const offer = book.offer(1);
  if (!offer.play) return false;
  if (offer.evict !== null) audio.stop(offer.evict);
  lastFrame.set(name, frame);
  book.add(audio.play(sound.clip, { volume: sound.volume, bus: "ui" }), 1, offer.evict);
  return true;
}

/** Forget the gaps and the book (a new game screen starts with none; the tests call it between scenes). */
export function resetUi() {
  lastFrame.clear();
  book = null;
}

export class GameSfx {
  /** @param {import("./state.js").GameState} state @param {import("./ui_model.js").Notices} notices */
  constructor(state, notices) {
    this.muted = false;
    const ev = state.events;
    const play = (name) => () => !this.muted && playUi(name);
    this.off = [
      ev.on("building.placed", play("place")),
      ev.on("building.removed", play("demolish")),
      ev.on("action.rejected", play("error")),
      ev.on("trade.order.filled", play("filled")),
      ev.on("trade.card", play("card")),
      notices.onNew((n) => !this.muted && n.sev !== "info" && playUi("notice")),
    ];
  }

  destroy() {
    for (const off of this.off) off();
    this.off = [];
  }
}
