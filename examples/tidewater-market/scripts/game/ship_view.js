// @ts-check
// ShipView: draws the ships of the trade (scripts/game/trade.js) as sprites on the water, one per ship, from a small pool.
//
// A ship is drawn between its last two clock steps by the clock's `alpha` (like WalkerView), so it glides at any speed and stands
// still when the clock is paused. It is on the object layer of the map: inside a layer the lower y draws on top, so a ship
// berthed behind the pier is covered by it and one in front covers it, with no extra sorting.
import { world } from "factoria";
import { cellToWorld } from "./iso.js";
import { LAYER } from "./map_view.js";

export class ShipView {
  /** @param {import("./state.js").GameState} state */
  constructor(state) {
    this.state = state;
    this.atlas = state.data.atlas;
    /** @type {any[]} */
    this.pool = [];
    /** @type {string[]} */
    this.frames = [];
    this.active = 0;
    /** The entity of each ship drawn now, by ship id (for tests and for the board to point at). */
    this.byShip = new Map();
  }

  /** Place every ship. Call once per frame, after the clock advanced. */
  update() {
    const trade = this.state.trade;
    const alpha = this.state.clock.alpha;
    let used = 0;
    this.byShip.clear();
    for (const ship of trade.ships) {
      let e = this.pool[used];
      const first = this.atlas.frames[`ship.${ship.cls}.0`];
      if (!e) {
        e = world.spawn({
          components: { Transform: { position: [0, 0, 0] }, Sprite: { texture: this.atlas.texture, region: first.rect, pivot: first.pivot, layer: LAYER.object, pixelArt: false } },
        });
        this.pool.push(e);
        this.frames.push(`ship.${ship.cls}.0`);
      }
      const p = trade.position(ship, alpha);
      const frame = `ship.${ship.cls}.${p.heading}`;
      if (this.frames[used] !== frame) {
        this.frames[used] = frame;
        const sprite = e.get("Sprite");
        const f = this.atlas.frames[frame];
        sprite.region = f.rect;
        sprite.pivot = f.pivot;
      }
      const [wx, wy] = cellToWorld(p.x, p.y);
      e.position = [wx, wy, 0];
      if (used >= this.active) e.active = true;
      this.byShip.set(ship.id, e);
      used++;
    }
    for (let i = used; i < this.active; i++) this.pool[i].active = false;
    this.active = used;
  }

  /** Ships drawn now. */
  get count() {
    return this.active;
  }

  destroy() {
    for (const e of this.pool) e.destroy();
    this.pool = [];
    this.frames = [];
    this.active = 0;
    this.byShip.clear();
  }
}
