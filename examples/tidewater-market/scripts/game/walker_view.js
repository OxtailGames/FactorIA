// @ts-check
// WalkerView: draws the walkers of a simulation (scripts/game/walkers.js) as sprites, one per walker, from a pool that grows
// to the largest crowd seen and is reused (spawning 500 sprites costs tens of milliseconds, moving them a few).
//
// A walker is drawn between its last two steps by the clock's `alpha`, so it glides at any speed and frame rate and stands
// still when the clock is paused. The sprite is on the same layer as the buildings and trees (MapView LAYER.object): inside a
// layer the lower y draws on top, so a walker in front of a building covers it and one behind is hidden, with no extra sorting.
import { world } from "factoria";
import { cellToWorld } from "./iso.js";
import { LAYER } from "./map_view.js";

/** Size of a walker sprite in world units (the atlas frames are 18 x 30 pixels). */
const SIZE = [22, 36];

export class WalkerView {
  /** @param {import("./state.js").GameState} state */
  constructor(state) {
    this.state = state;
    this.atlas = state.data.atlas;
    /** @type {any[]} */
    this.pool = [];
    /** @type {string[]} the frame each pooled sprite shows now */
    this.frames = [];
    this.active = 0;
  }

  /** Place every walker. Call once per frame, after the clock advanced. */
  update() {
    const sim = this.state.sim;
    const alpha = this.state.clock.alpha;
    let used = 0;
    for (const w of sim.walkers.list.values()) {
      let e = this.pool[used];
      if (!e) {
        e = world.spawn({
          components: {
            Transform: { position: [0, 0, 0] },
            Sprite: { texture: this.atlas.texture, region: this.atlas.frames["walker.villager.0"].rect, pivot: [0.5, 0], size: SIZE, layer: LAYER.object, pixelArt: false },
          },
        });
        this.pool.push(e);
        this.frames.push("walker.villager.0");
      }
      const frame = `walker.${w.kind}.${w.dir}`;
      if (this.frames[used] !== frame) {
        this.frames[used] = frame;
        e.get("Sprite").region = this.atlas.frames[frame].rect;
      }
      const x = w.px + (w.x - w.px) * alpha;
      const y = w.py + (w.y - w.py) * alpha;
      const [wx, wy] = cellToWorld(x, y);
      // a little sideways offset by id so a crowd on one road is a crowd, not one walker
      e.position = [wx + ((w.id % 5) - 2) * 4, wy + ((w.id % 3) - 1) * 2 - 2, 0];
      if (used >= this.active) e.active = true;
      used++;
    }
    for (let i = used; i < this.active; i++) this.pool[i].active = false;
    this.active = used;
  }

  /** Walkers shown now. */
  get count() {
    return this.active;
  }
}
