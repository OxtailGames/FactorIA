// @ts-check
// The in-level HUD: the spring bar (draining, amber then red), the seconds left and the parcel counter. The widgets
// are plain screen-space Shape2D / Text entities of the scene; this script only sets their size, colour and text.
import { Behaviour, ui, world, i18n } from "factoria";
import { EVENTS } from "./events.js";
import * as progress from "./progress.js";
import { isReduced } from "./accessibility.js";

export default class Hud extends Behaviour {
  /** Width of the full bar in design pixels (the fill entity shrinks from this). */
  barWidth = 300;
  /** Below this fraction of the spring the bar turns red and pulses. */
  lowFraction = 0.25;
  fullColor = [1, 0.76, 0.2, 1];
  lowColor = [1, 0.25, 0.2, 1];

  onStart() {
    this.spring = world.find("spring")?.behaviour ?? null;
    this.fill = world.find("spring_fill");
    this.label = world.find("spring_text");
    this.parcels = world.find("parcel_text");
    this.delivered = 0;
    this.total = 1;
    this.carrying = 0;
    this.offs = [
      world.on(EVENTS.levelStarted, (d) => {
        this.total = d.parcels ?? 1;
        this.refreshParcels();
      }),
      world.on(EVENTS.parcelPicked, (d) => {
        this.carrying = d.carrying;
        this.refreshParcels();
      }),
      world.on(EVENTS.parcelDelivered, (d) => {
        this.delivered = d.delivered;
        this.carrying = 0;
        this.refreshParcels();
      }),
      i18n.on("change", () => {
        this.refreshParcels();
        this.labelTouchButtons();
      }),
    ];
    this.refreshParcels();
    this.labelTouchButtons();
    this.showName();
    this.spawnWarning();
  }

  /**
   * The words on the on-screen buttons. TouchButton has no `key` field (FB-0040: TouchButton label without a localization
   * key), so the HUD writes them in the current language at start and at every language switch. The pause button keeps its "II".
   */
  labelTouchButtons() {
    for (const [id, key] of [["touch_jump", "touch.jump"], ["touch_action", "touch.action"]]) {
      const e = world.find(id);
      if (!e) continue;
      const tb = e.get("TouchButton");
      const word = i18n.t(key);
      tb.text = word;
      // The disc is 96 px wide and does not grow: size the word to fit it, and cancel ui.textScale (it would push the word out).
      let em = 0;
      for (const ch of word) em += ch.charCodeAt(0) > 0x2e80 ? 1 : 0.58;
      tb.fontSize = Math.min(32, 84 / Math.max(em, 1)) / Math.max(ui.textScale, 0.01);
    }
  }

  /** The courier's name (P3 profile) under the parcel counter; a Text spawned here so the level scenes stay as they are. */
  showName() {
    const name = progress.name();
    if (!name) return;
    world.spawn({
      id: "name_text",
      components: {
        Transform: { position: [24, 114, 0] },
        Text: { anchor: [0, 0], safeArea: true, space: "screen", text: name, fontSize: 20, color: [1, 1, 1, 0.75], layer: 100 },
      },
    });
  }

  /**
   * The low-spring warning, readable without colour: a triangle with "!" and the word "Low", beside the seconds. They are
   * spawned here (every level has the HUD script) and shown while the spring is under lowFraction.
   */
  spawnWarning() {
    const base = { anchor: [0, 0], safeArea: true, space: "screen" };
    this.warning = [
      world.spawn({ id: "spring_warning_icon", components: { Transform: { position: [404, 24, 0] }, Shape2D: { ...base, shape: "triangle", size: [34, 30], color: [1, 0.85, 0.2, 1], pivot: [0, 1], layer: 92 } } }),
      world.spawn({ id: "spring_warning_mark", components: { Transform: { position: [411, 25, 0] }, Text: { ...base, text: "!", fontSize: 24, color: [0.1, 0.05, 0, 1], layer: 101 } } }),
      world.spawn({ id: "spring_warning_text", components: { Transform: { position: [446, 24, 0] }, Text: { ...base, text: "Low", key: "hud.springLow", fontSize: 24, color: [1, 0.85, 0.2, 1], layer: 100 } } }),
    ];
    for (const e of this.warning) e.active = false;
  }

  onDestroy() {
    for (const off of this.offs ?? []) off();
  }

  refreshParcels() {
    if (!this.parcels) return;
    const key = this.carrying > 0 ? "hud.parcelsCarrying" : "hud.parcels";
    this.parcels.get("Text").text = i18n.t(key, { delivered: this.delivered, total: this.total });
  }

  /**
   * The corner texts sit at fixed places, so at a big text size (ui.textScale) they would overlap each other. Their effective size
   * stops at 1.25 times the design size and the rows below move down by what the one above grew. (FB-0042: no
   * shrink-to-fit or per-screen text-scale cap)
   */
  layoutHud() {
    const s = Math.max(ui.textScale, 0.01);
    if (s === this.hudScale) return;
    this.hudScale = s;
    const e = Math.min(s, 1.25);
    const place = (id, x, y, size) => {
      const ent = world.find(id);
      if (!ent) return;
      if (x !== null) ent.get("Transform").position = [x, y, 0];
      if (size) ent.get("Text").fontSize = (size * e) / s;
    };
    const parcelY = 56 + Math.round(28 * e);
    place("spring_label", 24, 56, 20);
    place("spring_text", Math.round(342 + (e - 1) * 20), 24, 28);
    place("parcel_text", 24, parcelY, 24);
    place("name_text", 24, parcelY + Math.round(30 * e), 20);
    const dx = Math.round((e - 1) * 60);
    const ent = world.find("spring_warning_icon");
    if (ent) ent.get("Transform").position = [404 + dx, 24, 0];
    place("spring_warning_mark", 411 + dx, 25, 24);
    place("spring_warning_text", 446 + dx, 24, 24);
  }

  onUpdate() {
    this.layoutHud();
    if (!this.spring) return;
    const f = this.spring.fraction;
    const low = f <= this.lowFraction;
    /** True while the low-spring warning (triangle, "!" and "Low") shows; tests read it. */
    this.warningShown = low;
    for (const e of this.warning ?? []) e.active = low;
    if (this.fill) {
      const shape = this.fill.get("Shape2D");
      shape.size = [Math.max(0.001, this.barWidth * f), shape.size.y];
      const pulse = low && !isReduced() ? 0.75 + 0.25 * Math.sin(this.spring.elapsed * 10) : 1;
      const c = low ? this.lowColor : this.fullColor;
      shape.color = [c[0] * pulse, c[1] * pulse, c[2] * pulse, 1];
    }
    if (this.label) this.label.get("Text").text = String(Math.ceil(this.spring.left));
  }
}
