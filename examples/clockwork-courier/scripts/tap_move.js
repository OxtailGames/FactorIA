// @ts-check
// Tap-to-move: tap (or click) the ground and the courier walks there around obstacles. OFF by default: it is the
// `tapToMove` setting of scripts/settings.js (the options menu of a later package turns it on). One entity ("tap_move")
// per level scene.
//
// A tap becomes a ray through the camera (camera.screenToWorld at two depths), the ray hits the world, and the hit point
// goes to the path finder (scripts/nav.js: a grid A*), whose waypoints Courier.walkTo() follows. Moving with the stick or
// the keys, or jumping, cancels the walk. Taps on the UI (the pause button) and on the on-screen stick or buttons do not
// count: those fingers never reach input.touches / the mouse.
import { Behaviour, input, camera, physics, ui, world } from "factoria";
import { NavGrid } from "./nav.js";
import * as settings from "./settings.js";

export default class TapMove extends Behaviour {
  /** Height above the courier's feet from which the path finder looks down for ground, metres. */
  navUp = 3;
  /** Farthest a tap is followed, metres (a tap beyond it is ignored). */
  maxDistance = 45;
  courierId = "courier";

  onStart() {
    this.courier = world.find(this.courierId);
    /** Where the last tap went ([x, y, z]) and the path found for it; tests read them. */
    this.lastTarget = null;
    this.lastPath = null;
    this.lastComplete = false;
    this.taps = 0;
  }

  onUpdate() {
    if (!input.mouse.pressed("left")) return;
    if (!settings.load().tapToMove) return;
    if (ui.hovered) return;
    const cb = this.courier ? this.courier.behaviour : null;
    if (!cb || cb.locked || cb.isCaught) return;
    this.tapAt(input.mouse.position);
  }

  /** Sends the courier to the ground under the screen point (what a tap does). Returns true when a walk started. */
  tapAt(screen) {
    const cb = this.courier.behaviour;
    const near = camera.screenToWorld(screen, 1);
    const far = camera.screenToWorld(screen, 80);
    const d = [far.x - near.x, far.y - near.y, far.z - near.z];
    const len = Math.hypot(d[0], d[1], d[2]);
    if (len < 1e-6) return false;
    const hit = physics.raycast3d([near.x, near.y, near.z], [d[0] / len, d[1] / len, d[2] / len], 200, { ignore: this.courier });
    if (!hit) return false;
    this.taps++;
    const from = this.courier.position;
    const to = hit.point;
    if (Math.hypot(to.x - from.x, to.z - from.z) > this.maxDistance) return false;
    this.lastTarget = [to.x, to.y, to.z];
    // A fresh grid per tap: crates and gates move, and a tap is rare.
    const nav = new NavGrid({ ceilY: from.y + this.navUp, radius: 0.32, clearance: 0.5, depth: this.navUp + 1.5 });
    const r = nav.findPath([from.x, from.z], [to.x, to.z]);
    if (!r || r.path.length === 0) return false;
    this.lastPath = r.path;
    this.lastComplete = r.complete;
    cb.walkTo(r.path.map((p) => [p[0], p[1]]));
    return true;
  }
}
