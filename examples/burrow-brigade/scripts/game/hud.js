// @ts-check
// The shift's HUD: ore carried and its value, moles rescued, floor and depth, the clock, one oil bar per player (colour of the
// player; red when the lamp is low, grey when it is out) and a banner for the news (lamp low, lamp out, shift over).
// Texts come from locales/en.json (hud.*); the scene holds the Text entities (hud_ore, hud_moles, hud_depth, hud_time,
// hud_banner) and this script fills them in.
import { Behaviour, world } from "factoria";
import * as players from "./players.js";
import * as events from "./events.js";
import { run, lampOf, totalOre, oreValue } from "./run_state.js";
import { SPRITE, spriteRegion } from "./tiles.js";

/** Width in design pixels of an oil bar at full oil. */
const BAR = 168;

/** Metres below the surface shown for a floor: 30 per stratum plus 10 per floor. */
export function depthOf(stratum, floor) {
  return stratum * 30 + floor * 10;
}

/** "m:ss" of a number of seconds. */
export function clock(seconds) {
  const s = Math.max(0, Math.floor(seconds));
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
}

export default class Hud extends Behaviour {
  onStart() {
    const need = (id) => {
      const e = world.find(id);
      if (!e) throw new Error(`hud: the scene has no entity '${id}'. The HUD needs the Text entities hud_ore, hud_moles, hud_depth, hud_time and hud_banner (see scenes/shift.scene.json).`);
      return e;
    };
    this.oreText = need("hud_ore");
    this.molesText = need("hud_moles");
    this.depthText = need("hud_depth");
    this.timeText = need("hud_time");
    this.banner = need("hud_banner");
    this.shown = {};
    this.bars = [];
    const list = players.all();
    list.forEach((p, i) => this.addBar(p, i, list.length));
    this.bannerLeft = 0;
    this.unsubs = [
      events.on("lampLow", (e) => this.news(e.player, "hud.lampLow", 3)),
      events.on("lampOut", (e) => this.news(e.player, "hud.lampOut", 4)),
      events.on("shiftEnded", (e) => this.news(-1, e.outcome === "lift" ? "hud.shiftLift" : "hud.shiftDark", 99)),
      events.on("moleRescued", () => this.news(-1, "hud.moleRescued", 2)),
      events.on("playerState", (e) => e.to === "lift" && players.alive().some((p) => p.state !== "lift") && this.news(-1, "hud.liftWait", 2)),
    ];
    this.banner.set("Text", { text: "", key: "" });
    this.refresh(true);
  }

  onDestroy() {
    for (const off of this.unsubs ?? []) off();
  }

  addBar(p, i, n) {
    const y = -44 - (n - 1 - i) * 26;
    const icon = world.spawn({ components: { Transform: { position: [22, y + 2, 0] }, Sprite: { texture: "assets/sprites.png", region: spriteRegion(SPRITE.OIL_ICON), size: [20, 20], pivot: [0, 1], space: "screen", anchor: [0, 1], layer: 210 } } });
    const back = world.spawn({ components: { Transform: { position: [50, y, 0] }, Shape2D: { shape: "rectangle", size: [BAR + 4, 16], color: [0, 0, 0, 0.6], pivot: [0, 1], space: "screen", anchor: [0, 1], layer: 210 } } });
    const fill = world.spawn({ components: { Transform: { position: [52, y - 2, 0] }, Shape2D: { shape: "rectangle", size: [BAR, 12], color: p.color, pivot: [0, 1], space: "screen", anchor: [0, 1], layer: 211 } } });
    this.bars.push({ id: p.id, icon, back, fill, width: -1, state: "" });
  }

  /** Puts a news line on the banner for a few seconds (`player` -1: not about one miner). */
  news(player, key, seconds) {
    this.banner.set("Text", { key });
    this.bannerLeft = seconds;
  }

  onUpdate(dt) {
    if (this.bannerLeft > 0) {
      this.bannerLeft -= dt;
      if (this.bannerLeft <= 0) this.banner.set("Text", { text: "", key: "" });
    }
    this.refresh(false);
  }

  /** Rewrites a text only when its numbers changed (the engine formats the translation again on every change). */
  setArgs(entity, args) {
    const key = JSON.stringify(args);
    if (this.shown[entity.id] === key) return;
    this.shown[entity.id] = key;
    entity.set("Text", { keyArgs: args });
  }

  refresh(force) {
    this.setArgs(this.oreText, { count: totalOre(), value: oreValue() });
    this.setArgs(this.molesText, { rescued: run.molesRescued, total: run.molesTotal });
    this.setArgs(this.depthText, { floor: run.floor, depth: depthOf(run.stratum, run.floor) });
    this.setArgs(this.timeText, { time: clock(run.shiftTime) });
    for (const b of this.bars) {
      const lamp = lampOf(b.id);
      const frac = lamp.max > 0 ? Math.max(0, Math.min(1, lamp.oil / lamp.max)) : 0;
      const width = Math.round(BAR * frac);
      const state = lamp.out ? "out" : lamp.low ? "low" : "ok";
      if (width !== b.width || state !== b.state || force) {
        b.width = width;
        b.state = state;
        const p = players.get(b.id);
        const color = state === "out" ? [0.3, 0.3, 0.3, 1] : state === "low" ? [1, 0.35, 0.3, 1] : p ? p.color : [1, 1, 1, 1];
        b.fill.set("Shape2D", { size: [Math.max(1, width), 12], color });
      }
    }
  }
}
