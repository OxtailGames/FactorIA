// @ts-check
// When the game saves by itself, and how long the player has played. Pure logic around save_store.js; scripts/save_controller.js
// connects it to the engine (frames, window focus, closing the window) and to the game scene.
//
// The run: what the game screen knows about where this game came from (session.run, set by the slot screen and by the Continue button).
//   { slot, scenario, name, playSeconds, tracker? }    slot 0 / missing: a game that belongs to no slot is never autosaved
//
// Autosave triggers (all write the AUTOSAVE entry of the run's slot, never the manual save):
//   "season"   a season ended: asked by the clock event, written at the end of the frame (never inside a clock step)
//   "timer"    every `intervalSeconds` of play, when the town changed since the last save
//   "leave"    the window lost the focus, the app was suspended, or the window is closing (the tab or app may be gone next)
// The web raises suspend when a tab is hidden and quit when it closes (pagehide), so "leave" saves there too; the timer and the
// season are the net for a browser that gives no signal at all.
// "season" and "timer" write off the frame (storage.setAsync: a worker thread, the save compressed); "leave" writes at once, because
// the app may be gone before an asynchronous write runs.
import { writeEntry } from "./save_store.js";

export const AUTOSAVE_SECONDS = 120;
/** One frame counts at most this many real seconds of play (a stall in a debugger must not add minutes). */
const MAX_FRAME_SECONDS = 1;

export class Autosaver {
  /**
   * @param {import("./state.js").GameState} state
   * @param {{ slot: number, scenario: string, name?: string, playSeconds: number, tracker?: any }} run
   * @param {{ intervalSeconds?: number }} [options]
   */
  constructor(state, run, options = {}) {
    this.state = state;
    this.run = run;
    this.intervalSeconds = options.intervalSeconds ?? AUTOSAVE_SECONDS;
    this.sinceSave = 0;
    this.pending = /** @type {string | null} */ (null);
    this.focused = true;
    this.lastSignature = this.signature();
    /** What happened: the reason of each autosave written, newest last (tests and the diagnostics line read it). @type {string[]} */
    this.log = [];
    /** The last failure of a save, or null (the screen shows a toast once). */
    this.lastError = /** @type {any} */ (null);
    /** Called with (slot, kind) after every entry written: the save controller pushes it to the cloud. @type {((slot: number, kind: "manual" | "auto") => void) | null} */
    this.onWritten = null;
  }

  /** Does this game belong to a slot (so it can be autosaved)? */
  get active() {
    return Number.isInteger(this.run.slot) && this.run.slot >= 1;
  }

  /** A cheap fingerprint of "did anything change since the last save": the clock, the money, the buildings and the goals reached. */
  signature() {
    const s = this.state;
    const goals = this.run.tracker ? Object.keys(this.run.tracker.done).length + (this.run.tracker.won ? 1 : 0) : 0;
    return `${s.clock.ticks}|${s.economy.coins}|${s.buildings.size}|${s.nextId}|${goals}`;
  }

  /** Real seconds passed (not game time: the clock's speed does not count). Call once a frame. */
  update(realDt) {
    if (this.focused) {
      const dt = Math.min(Math.max(realDt, 0), MAX_FRAME_SECONDS);
      this.run.playSeconds += dt;
      this.sinceSave += dt;
    }
    if (!this.active) return;
    if (this.pending) {
      const reason = this.pending;
      this.pending = null;
      this.autosave(reason);
    } else if (this.sinceSave >= this.intervalSeconds) {
      this.autosave("timer");
    }
  }

  /** A season ended. The save waits for the end of the frame. */
  onSeason() {
    this.pending = "season";
  }

  /** The window lost the focus, the app was suspended or the window is closing: save now. */
  onLeave(reason) {
    if (reason === "blur" || reason === "suspend") this.focused = false;
    if (this.active) this.autosave(reason);
  }

  /** The window has the focus again. */
  onReturn() {
    this.focused = true;
  }

  /**
   * Write the autosave entry. Skipped (returns null) when the town is as it was at the last save.
   * @returns {import("./save_store.js").SlotMeta | null}
   */
  autosave(reason) {
    this.sinceSave = 0;
    const sig = this.signature();
    if (sig === this.lastSignature && reason !== "season") return null;
    const res = this.write("auto", undefined, reason === "season" || reason === "timer");
    if (!res.ok) return null;
    this.lastSignature = sig;
    this.log.push(reason);
    return res.meta;
  }

  /** The player's own save into a slot (the slot becomes the run's slot). */
  saveManual(slot, name) {
    const run = this.run;
    const previous = run.slot;
    run.slot = slot;
    const res = this.write("manual", name);
    if (!res.ok) run.slot = previous;
    else this.lastSignature = this.signature();
    return res;
  }

  write(kind, name, offFrame = false) {
    const run = this.run;
    const tracker = run.tracker;
    const res = writeEntry(run.slot, kind, this.state, {
      name,
      scenario: run.scenario,
      playSeconds: run.playSeconds,
      extra: tracker ? tracker.saveFields() : undefined,
      progress: tracker ? tracker.metaFields() : undefined,
      async: offFrame,
    });
    this.lastError = res.ok ? null : res.error;
    if (res.ok && res.written) {
      res.written.catch((e) => {
        this.lastError = { code: "storage", message: `the game could not be saved (${e && e.message})`, hint: "free some disk space and try again" };
      });
    }
    if (res.ok && this.onWritten) this.onWritten(run.slot, kind);
    return res;
  }
}
