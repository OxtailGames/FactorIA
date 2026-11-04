// @ts-check
// The heads-up display: hearts, logs carried, the fire's fuel bar, the night and a dawn bar, the banner that announces
// a night or the dawn, and the hint on the first night. It reads the other scripts' fields every frame and writes
// Sprite sizes, tints and Text key arguments; nothing in the game depends on it.
import { Behaviour, world } from "factoria";
import { behaviourOf } from "./common.js";

const BAR = 410; // width of the full fuel bar, pixels
const DAWN_BAR = 204;

export default class Hud extends Behaviour {
  onStart() {
    this.hearts = [1, 2, 3].map((i) => world.find(`heart_${i}`));
    this.fuelFill = world.find("fuel_fill");
    this.dawnFill = world.find("dawn_fill");
    this.fireIcon = world.find("fire_icon");
    this.logText = world.find("log_text");
    this.nightText = world.find("night_text");
    this.banner = world.find("banner");
    this.tip = world.find("tip");
    this.bannerTime = 0;
    this.bannerTotal = 1;
    this.tipTime = 0;
    this.lastLogs = -1;
    this.lastNight = -1;
    this.unsubscribes = [
      world.on("banner", (d) => this.showBanner(d.key, d.args, d.seconds)),
      world.on("end_panel_shown", () => this.hideAll()),
    ];
    this.setAlpha(this.banner, 0);
    this.setAlpha(this.tip, 0);
  }

  onDestroy() {
    for (const off of this.unsubscribes ?? []) off();
  }

  setAlpha(entity, a) {
    if (!entity) return;
    const t = entity.get("Text");
    const c = t.color;
    t.color = [c[0], c[1], c[2], a];
  }

  showBanner(key, args, seconds) {
    if (!this.banner) return;
    const t = this.banner.get("Text");
    t.key = key;
    t.keyArgs = args ?? {};
    this.bannerTime = seconds;
    this.bannerTotal = Math.max(seconds, 0.1);
    // The very first banner of the game also shows how to play.
    if (key === "game.night" && args?.n === 1 && this.tipTime <= 0) this.tipTime = 7;
  }

  hideAll() {
    this.bannerTime = 0;
    this.tipTime = 0;
  }

  onUpdate(dt) {
    const warden = behaviourOf("warden");
    const fire = behaviourOf("campfire");
    const game = behaviourOf("game");
    if (warden) {
      this.hearts.forEach((h, i) => {
        if (!h) return;
        h.get("Sprite").color = i < warden.hearts ? [1, 1, 1, 1] : [0.18, 0.18, 0.24, 0.8];
      });
      if (warden.logs !== this.lastLogs && this.logText) {
        this.lastLogs = warden.logs;
        this.logText.get("Text").keyArgs = { count: warden.logs, max: warden.maxLogs };
      }
    }
    if (fire) {
      const f = fire.fraction;
      if (this.fuelFill) {
        this.fuelFill.get("Sprite").size = [Math.max(4, BAR * f), 20];
        // Green-gold when full, ember red when low: the bar is read at a glance.
        this.fuelFill.get("Sprite").color = f > 0.35 ? [1, 0.72, 0.28, 1] : [1, 0.28 + 0.4 * (f / 0.35), 0.18, 1];
      }
    }
    if (game) {
      if (game.night !== this.lastNight && this.nightText) {
        this.lastNight = game.night;
        this.nightText.get("Text").keyArgs = { n: game.night, total: game.nights.length };
      }
      if (this.dawnFill) {
        const cfg = game.config;
        const f = game.state === "night" ? game.timer / cfg.length : game.state === "dawn" || game.state === "won" ? 1 : 0;
        this.dawnFill.get("Sprite").size = [Math.max(2, DAWN_BAR * f), 8];
      }
    }
    if (this.bannerTime > 0) {
      this.bannerTime -= dt;
      const t = this.bannerTime;
      const a = Math.min(1, t / 0.5, (this.bannerTotal - t) / 0.35);
      this.setAlpha(this.banner, Math.max(0, a));
    } else this.setAlpha(this.banner, 0);
    if (this.tipTime > 0) {
      this.tipTime -= dt;
      this.setAlpha(this.tip, Math.max(0, Math.min(1, this.tipTime / 0.6, (7 - this.tipTime) / 0.6)) * 0.9);
    } else this.setAlpha(this.tip, 0);
  }
}
