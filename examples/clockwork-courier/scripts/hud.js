// @ts-check
// The in-level HUD: the spring bar (draining, amber then red), the seconds left and the parcel counter. The widgets
// are plain screen-space Shape2D / Text entities of the scene; this script only sets their size, colour and text.
import { Behaviour, world, i18n } from "factoria";
import { EVENTS } from "./events.js";
import * as progress from "./progress.js";

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
      i18n.on("change", () => this.refreshParcels()),
    ];
    this.refreshParcels();
    this.showName();
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

  onDestroy() {
    for (const off of this.offs ?? []) off();
  }

  refreshParcels() {
    if (!this.parcels) return;
    const key = this.carrying > 0 ? "hud.parcelsCarrying" : "hud.parcels";
    this.parcels.get("Text").text = i18n.t(key, { delivered: this.delivered, total: this.total });
  }

  onUpdate() {
    if (!this.spring) return;
    const f = this.spring.fraction;
    const low = f <= this.lowFraction;
    if (this.fill) {
      const shape = this.fill.get("Shape2D");
      shape.size = [Math.max(0.001, this.barWidth * f), shape.size.y];
      const pulse = low ? 0.75 + 0.25 * Math.sin(this.spring.elapsed * 10) : 1;
      const c = low ? this.lowColor : this.fullColor;
      shape.color = [c[0] * pulse, c[1] * pulse, c[2] * pulse, 1];
    }
    if (this.label) this.label.get("Text").text = String(Math.ceil(this.spring.left));
  }
}
