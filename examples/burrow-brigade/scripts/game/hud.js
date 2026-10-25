// @ts-check
// The shift's HUD: ore carried and its value, moles rescued, the stratum, floor and depth, the clock, the torches the team has
// left, one oil bar and three hearts per player (colour of the player; the bar is red when the lamp is low, grey when it is
// out; a lost heart is dark) and a banner for the news (lamp low or out, a hazard starting, a miner down, a thief, the Mole
// King, shift over). Texts come from locales/en.json (hud.*); the scene holds the Text entities (hud_ore, hud_moles,
// hud_depth, hud_stratum, hud_time, hud_torches, hud_banner) and this script fills them in.
import { Behaviour, world } from "factoria";
import * as players from "./players.js";
import * as events from "./events.js";
import { run, lampOf, totalOre, oreValue, depthOf } from "./run_state.js";
import { stratumInfo } from "./generator.js";
import { SPRITE, spriteRegion } from "./tiles.js";

/** Width in design pixels of an oil bar at full oil. */
const BAR = 168;
/** Seconds a news line stays on the banner. */
const NEWS = 3;

export { depthOf }; // the depth of a floor lives in run_state.js (the saves need it too)

/** "m:ss" of a number of seconds. */
export function clock(seconds) {
  const s = Math.max(0, Math.floor(seconds));
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
}

export default class Hud extends Behaviour {
  onStart() {
    const need = (id) => {
      const e = world.find(id);
      if (!e) throw new Error(`hud: the scene has no entity '${id}'. The HUD needs the Text entities hud_ore, hud_moles, hud_depth, hud_stratum, hud_time, hud_torches and hud_banner (see scenes/shift.scene.json).`);
      return e;
    };
    this.oreText = need("hud_ore");
    this.molesText = need("hud_moles");
    this.depthText = need("hud_depth");
    this.timeText = need("hud_time");
    this.stratumText = need("hud_stratum");
    this.torchText = need("hud_torches");
    this.stratumText.set("Text", { key: stratumInfo(run.stratum).name, text: stratumInfo(run.stratum).name });
    this.banner = need("hud_banner");
    this.shown = {};
    this.bars = [];
    const list = players.all();
    list.forEach((p, i) => this.addBar(p, i, list.length));
    this.bannerLeft = 0;
    this.final = false; // the shift-over line stays; no later news replaces it
    const flood = { flood: "hud.flood", magma: "hud.magma", caveIn: "hud.caveIn" };
    this.unsubs = [
      events.on("lampLow", (e) => this.news(e.player, "hud.lampLow", 3)),
      events.on("lampOut", (e) => this.news(e.player, "hud.lampOut", 4)),
      events.on("shiftEnded", (e) => {
        this.news(-1, e.outcome === "lift" ? "hud.shiftLift" : e.outcome === "allDown" ? "hud.shiftAllDown" : "hud.shiftDark", 99);
        this.final = true;
      }),
      events.on("playerDown", () => this.news(-1, "hud.playerDown", NEWS)),
      events.on("hazardTriggered", (e) => e.phase === "start" && flood[e.kind] && this.news(-1, flood[e.kind], NEWS)),
      events.on("oreStolen", () => this.news(-1, "hud.oreStolen", NEWS)),
      events.on("thiefEscaped", () => this.news(-1, "hud.thiefEscaped", NEWS)),
      events.on("oreRecovered", () => this.news(-1, "hud.oreRecovered", 2)),
      events.on("bossStarted", () => this.news(-1, "hud.bossStarted", NEWS)),
      events.on("bossDefeated", () => this.news(-1, "hud.bossDefeated", NEWS)),
      events.on("exitJammed", () => this.news(-1, "hud.exitJammed", NEWS)),
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
    const hearts = [0, 1, 2].map((k) => world.spawn({ components: { Transform: { position: [52 + BAR + 22 + k * 20, y - 2, 0] }, Shape2D: { shape: "circle", size: [14, 14], color: [1, 0.25, 0.3, 1], pivot: [0, 1], space: "screen", anchor: [0, 1], layer: 211 } } }));
    this.bars.push({ id: p.id, icon, back, fill, hearts, hp: -1, width: -1, state: "" });
  }

  /** Puts a news line on the banner for a few seconds (`player` -1: not about one miner). */
  news(player, key, seconds) {
    if (this.final) return;
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
    this.setArgs(this.torchText, { count: run.torches });
    for (const b of this.bars) {
      const who = players.get(b.id);
      const hp = who ? (who.state === "down" ? 0 : who.hp) : 0;
      if (hp !== b.hp) {
        b.hp = hp;
        b.hearts.forEach((h, k) => h.set("Shape2D", { color: k < hp ? [1, 0.25, 0.3, 1] : [0.25, 0.1, 0.12, 0.8] }));
      }
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
