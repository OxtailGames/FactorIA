// @ts-check
// scenes/intro.scene.json: the studio intro that plays before the title (factoria.json mainScene). It is a VIDEO: a Video
// component plays assets/video/studio_intro.mpg (MPEG-1 + MP2, 640x360, 4.8 s, half a megabyte) full screen. The film is
// recorded from an animated scene, store/intro/intro_anim.scene.json (SHIPPING.md, "Studio intro"): a copper gear and a winding
// key turn, "Oxtail Games" appears with a bell, then the game's title card.
//
// It plays ONCE: the first launch stores storage "introSeen" (separate from "settings": resetting the options must not
// bring it back) and every later launch goes straight to the title. It ends when the video ends, or early on a tap, a click,
// any key, a pad button, the Skip button or Android Back. `endedBy` ("seen", "input" or "end") is what the tests read.
import { Behaviour, scene, storage, input, ui, world } from "factoria";

/** Storage key of the "already shown" flag. */
export const SEEN_KEY = "introSeen";

/** Scene that follows the intro. */
export const NEXT = "scenes/main.scene.json";

/** Scene that plays this script. */
export const SCENE = "scenes/intro.scene.json";

/** Seconds of the video file. */
export const LENGTH = 4.8;

export default class Intro extends Behaviour {
  onStart() {
    this.frames = 0;
    this.left = false;
    /** How the intro ended: "" while it plays, "seen" (a later launch), "input" or "end". */
    this.endedBy = "";
    if (storage.get(SEEN_KEY, false)) {
      this.leave("seen");
      return;
    }
    storage.set(SEEN_KEY, true);
    // The title screen is read while the video plays, so the cut to it takes no time (a mistake here would only mean a
    // normal load at the end).
    this.titleJob = scene.preload(NEXT);
    // "ended" comes once, in this scene: the video belongs to it, and leave() runs only once.
    this.offEnded = world.find("intro_video")?.video.on("ended", () => this.leave("end"));
    ui.on("click", "intro_skip", () => this.leave("input"));
    // Android Back skips the intro (and so does not quit the game in the middle of it).
    this.offBack = input.onBack(() => {
      this.leave("input");
      return true;
    });
  }

  onDestroy() {
    this.offEnded?.();
    this.offBack?.();
  }

  /** Goes to the title screen once, and only while this intro is the scene that is playing. */
  leave(how) {
    if (this.left || (how !== "seen" && scene.current !== SCENE)) return;
    this.left = true;
    this.endedBy = how;
    scene.load(NEXT);
  }

  onUpdate() {
    if (this.left) return;
    // Any key, tap, click or pad button (the frame of the first touch included).
    if (this.frames > 0 && input.lastPressed()) {
      this.leave("input");
      return;
    }
    this.frames += 1;
  }
}
