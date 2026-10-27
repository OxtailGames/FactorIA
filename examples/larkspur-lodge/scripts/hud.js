// @ts-check
// The in-game HUD (prefabs/ui/hud.prefab.json, one per area scene): the interaction prompt, the message line, the area
// title and the black overlay that fades the screen between areas. Other scripts call its methods:
//   hud.setPrompt(text | "")              the prompt at the bottom of the screen ("" hides it)
//   hud.say(key, args, seconds)           a line of text above the prompt for a few seconds (a locale key)
//   hud.fadeTo(alpha, seconds)            the overlay to alpha 0 (clear) .. 1 (black)
//   hud.showTitle(key, seconds)           the area name that fades in and out in the upper part of the screen
// Fields tests read: `promptText`, `message`, `fadeAlpha`, `fading`.
import { Behaviour, i18n, world } from "factoria";

export default class Hud extends Behaviour {
  /** Seconds a say() line stays when the caller gives none. */
  messageSeconds = 3.5;
  /** Seconds the area title takes to fade in and out (each), and the time it stays full. */
  titleFade = 0.6;
  /** Overlay alpha at the start of the scene: 1 = the scene fades in from black (scripts/area.js starts the fade). */
  startAlpha = 1;

  onStart() {
    this.promptPanel = world.find("prompt_panel");
    this.promptLabel = world.find("prompt_text");
    this.messagePanel = world.find("message_panel");
    this.messageLabel = world.find("message_text");
    this.titleLabel = world.find("area_title");
    this.fadeShape = world.find("fade");
    /** The prompt line that shows now ("" = hidden). */
    this.promptText = "";
    /** The message line that shows now ("" = none). */
    this.message = "";
    this.messageLeft = 0;
    this.fadeAlpha = this.startAlpha;
    this.fadeFrom = this.fadeAlpha;
    this.fadeTarget = this.fadeAlpha;
    this.fadeTime = 0;
    this.fadeDuration = 0;
    this.titleTime = -1;
    this.titleSeconds = 0;
    this.promptPanel.active = false;
    this.messagePanel.active = false;
    this.applyFade();
  }

  /** True while the overlay is still moving to its target. */
  get fading() {
    return this.fadeTime < this.fadeDuration;
  }

  setPrompt(text) {
    if (text === this.promptText) return;
    this.promptText = text;
    this.promptPanel.active = text !== "";
    this.promptLabel.get("Text").text = text;
  }

  /** Shows the line of the locale key `key` (args fill its {placeholders}) above the prompt for `seconds`. */
  say(key, args = {}, seconds = this.messageSeconds) {
    this.message = i18n.t(key, args);
    this.messageLeft = seconds;
    this.messageLabel.get("Text").text = this.message;
    this.messagePanel.active = true;
  }

  fadeTo(alpha, seconds = 0.4) {
    this.fadeFrom = this.fadeAlpha;
    this.fadeTarget = alpha;
    this.fadeTime = 0;
    this.fadeDuration = Math.max(seconds, 0);
    if (seconds <= 0) {
      this.fadeAlpha = alpha;
      this.applyFade();
    }
  }

  showTitle(key, seconds = 2.6) {
    this.titleLabel.get("Text").text = i18n.t(key);
    this.titleTime = 0;
    this.titleSeconds = seconds;
  }

  applyFade() {
    this.fadeShape.get("Shape2D").color = [0, 0, 0, this.fadeAlpha];
  }

  onUpdate(dt) {
    if (this.fading) {
      this.fadeTime = Math.min(this.fadeTime + dt, this.fadeDuration);
      const k = this.fadeDuration > 0 ? this.fadeTime / this.fadeDuration : 1;
      this.fadeAlpha = this.fadeFrom + (this.fadeTarget - this.fadeFrom) * k;
      this.applyFade();
    }
    if (this.messageLeft > 0) {
      this.messageLeft -= dt;
      if (this.messageLeft <= 0) {
        this.message = "";
        this.messagePanel.active = false;
      }
    }
    if (this.titleTime >= 0) {
      this.titleTime += dt;
      const t = this.titleTime;
      const f = this.titleFade;
      const a = t < f ? t / f : t > this.titleSeconds - f ? Math.max(0, (this.titleSeconds - t) / f) : 1;
      this.titleLabel.get("Text").color = [1, 0.95, 0.85, a];
      if (t >= this.titleSeconds) this.titleTime = -1;
    }
  }
}
