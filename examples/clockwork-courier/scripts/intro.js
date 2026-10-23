// @ts-check
// scenes/intro.scene.json: the studio intro that plays before the title (factoria.json mainScene). The engine has no video
// playback (ENGINE_FEEDBACK), so it is an animated scene: a copper gear and a winding key fade in and turn, the studio name
// appears, then the game's title card. About four seconds in all.
//
//   0.0 - 0.6   gear and key fade in, turning            2.4 - 2.9   studio fades out
//   0.4 - 1.0   "Oxtail Games"                           2.7 - 3.3   title card in, 4.2 - 4.6 out
//   0.9 - 1.4   "presents"                               then the title screen (scenes/main.scene.json)
//
// It plays ONCE: the first launch stores storage "introSeen" (separate from "settings": resetting the options must not
// bring it back) and every later launch goes straight to the title. It ends early on a tap, a click, any key, a pad
// button, the Skip button or Android Back. `skipped` and `finished` are what the tests read.
import { Behaviour, scene, storage, input, ui, world, time } from "factoria";

/** Storage key of the "already shown" flag. */
export const SEEN_KEY = "introSeen";

/** Scene that follows the intro. */
export const NEXT = "scenes/main.scene.json";

/** Seconds of the whole intro. */
export const LENGTH = 4.8;

/** 0..1 ramp of `t` between `a` and `b`. */
function ramp(t, a, b) {
  return Math.min(1, Math.max(0, (t - a) / (b - a)));
}

export default class Intro extends Behaviour {
  onStart() {
    this.t = 0;
    this.left = false;
    /** How the intro ended: "" while it plays, "seen" (a later launch), "input" or "end". */
    this.endedBy = "";
    if (storage.get(SEEN_KEY, false)) {
      this.leave("seen");
      return;
    }
    storage.set(SEEN_KEY, true);
    // The title screen is read while the intro plays, so the cut to it takes no time (a mistake here would only mean a
    // normal load at the end).
    this.titleJob = scene.preload(NEXT);
    ui.on("click", "intro_skip", () => this.leave("input"));
    // Android Back skips the intro (and so does not quit the game in the middle of it).
    this.offBack = input.onBack(() => {
      this.leave("input");
      return true;
    });
  }

  onDestroy() {
    this.offBack?.();
  }

  /** Goes to the title screen once. */
  leave(how) {
    if (this.left) return;
    this.left = true;
    this.endedBy = how;
    scene.load(NEXT);
  }

  /** Sets the alpha of a Text or Shape2D entity. */
  fade(id, comp, alpha) {
    const c = world.find(id)?.get(comp);
    if (c) c.color = [c.color[0], c.color[1], c.color[2], alpha];
  }

  onUpdate() {
    if (this.left) return;
    // Any key, tap, click or pad button (the frame of the first touch included).
    if (this.t > 0 && input.lastPressed()) {
      this.leave("input");
      return;
    }
    this.t += time.dt;
    const t = this.t;
    if (t >= LENGTH) {
      this.leave("end");
      return;
    }

    const logo = ramp(t, 0, 0.6) * (1 - ramp(t, 2.4, 2.9));
    const gear = world.find("intro_gear");
    const key = world.find("intro_key");
    if (gear) gear.get("Transform").rotation = [0, 0, t * 40];
    if (key) key.get("Transform").rotation = [0, 0, t * 40 + 45];
    this.fade("intro_gear", "Shape2D", logo);
    this.fade("intro_hub", "Shape2D", logo);
    this.fade("intro_key", "Shape2D", logo);
    this.fade("intro_studio", "Text", Math.min(ramp(t, 0.4, 1), 1 - ramp(t, 2.4, 2.9)));
    this.fade("intro_presents", "Text", Math.min(ramp(t, 0.9, 1.4), 1 - ramp(t, 2.4, 2.9)));
    this.fade("intro_title", "Text", Math.min(ramp(t, 2.7, 3.3), 1 - ramp(t, 4.2, 4.6)));
  }
}
