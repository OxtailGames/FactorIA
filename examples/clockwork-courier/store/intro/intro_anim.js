// @ts-check
// The source of the studio intro film (assets/video/studio_intro.mpg): an animated scene that is RECORDED, not shipped
// (factoria.json "export.exclude" has store/**). The game plays the recorded video (scenes/intro.scene.json, scripts/intro.js).
// Recording and converting it is in SHIPPING.md ("Studio intro"). About 4.8 s: a copper gear and a winding key fade in and turn,
// the studio name appears with a bell, then the game's title card.
//
//   0.0 - 0.6   gear and key fade in, turning            2.4 - 2.9   studio fades out
//   0.4 - 1.0   "Oxtail Games" (bell at 0.4)             2.7 - 3.3   title card in, 4.2 - 4.6 out
//   0.9 - 1.4   "presents"
import { Behaviour, audio, world, time } from "factoria";

/** Seconds of the whole film. */
export const LENGTH = 4.8;

/** 0..1 ramp of `t` between `a` and `b`. */
function ramp(t, a, b) {
  return Math.min(1, Math.max(0, (t - a) / (b - a)));
}

export default class IntroAnimation extends Behaviour {
  onStart() {
    this.t = 0;
    this.belled = false;
  }

  /** Sets the alpha of a Text or Shape2D entity. */
  fade(id, comp, alpha) {
    const c = world.find(id)?.get(comp);
    if (c) c.color = [c.color[0], c.color[1], c.color[2], alpha];
  }

  onUpdate() {
    this.t += time.dt;
    const t = this.t;
    if (!this.belled && t >= 0.4) {
      this.belled = true;
      audio.play("assets/audio/impactBell_heavy_000.ogg", { bus: "sfx", volume: 0.7 });
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
