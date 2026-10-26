// @ts-check
// The picture behind the title screen: a small hamlet built on the same map the first game is played on, seen by a camera
// that drifts slowly (not with the "reduced motion" option). It is a real GameState drawn by the real MapView (the same code as the game), on a throwaway state
// the player cannot touch. Put this behaviour on the title scene's camera entity.
import { Behaviour } from "factoria";
import { getData } from "./data.js";
import { createGame } from "./state.js";
import { MapView } from "./map_view.js";
import { cellToWorld } from "./iso.js";
import { orthoSizeFor } from "./camera_math.js";
import { live } from "../settings.js";

/** The hamlet as [type, cell column, cell row, rotation]: roads first (a market needs one at its door). */
const HAMLET = [
  ["road", [8, 14], [19, 14]],
  ["road", [12, 9], [12, 19]],
  ["house", 10, 13, 0],
  ["house", 14, 13, 0],
  ["house", 10, 15, 0],
  ["house", 14, 15, 0],
  ["house", 16, 15, 0],
  ["house", 13, 11, 0],
  ["house", 11, 17, 0],
  ["market", 14, 17, 2],
  ["farm", 16, 11, 0],
  ["farm", 9, 11, 0],
  ["warehouse", 17, 17, 3],
  ["bakery", 14, 10, 0],
];

export default class TitleBackdrop extends Behaviour {
  /** Map seed; 0 = the default seed of data/map.json (the map the first game is played on). */
  seed = 0;
  /** Zoom of the picture (the strategy camera's zoom: 1 = one design pixel per world unit). */
  zoom = 0.9;
  /** The cell the camera drifts around. */
  centre = [12, 14];
  /** How far the camera drifts, in world units, and how fast (radians per second). */
  drift = 140;
  speed = 0.08;

  onStart() {
    const data = getData();
    this.state = createGame({ data, seed: this.seed || undefined });
    this.state.economy.apply({ coins: 100000 }, "backdrop"); // decoration is free
    for (const item of HAMLET) {
      if (item[0] === "road") {
        const [, [c0, r0], [c1, r1]] = item;
        const cells = [];
        for (let r = r0; r <= r1; r++) for (let c = c0; c <= c1; c++) cells.push([c, r]);
        this.state.placeRoads(cells);
      } else {
        this.state.placeAt(item[0], item[1], item[2], item[3]);
      }
    }
    this.view = new MapView(this.state);
    this.time = 0;
    this.place();
  }

  onDestroy() {
    if (this.view) this.view.destroy();
  }

  onUpdate(dt) {
    this.time += dt;
    this.place();
  }

  place() {
    const [x, y] = cellToWorld(this.centre[0], this.centre[1]);
    if (live().reducedMotion) this.entity.position = [x, y, 0]; // reduced motion: the picture stands still
    else this.entity.position = [x + this.drift * Math.sin(this.time * this.speed), y + this.drift * 0.35 * Math.sin(this.time * this.speed * 1.7), 0];
    this.entity.get("Camera").orthoSize = orthoSizeFor(this.zoom);
  }
}
