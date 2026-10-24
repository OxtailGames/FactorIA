// @ts-check
// Tap-to-move: tap (or click) the ground and the courier walks there around obstacles. OFF by default: it is the
// `tapToMove` setting of scripts/settings.js (the options menu of a later package turns it on). One entity ("tap_move")
// per level scene.
//
// A tap becomes a ray through the camera (camera.screenToWorld at two depths), the ray hits the world, and the hit point
// goes to the engine's path finder (nav.findPath over the level's NavMesh3D, docs/NAVIGATION.md: it walks round walls,
// up ramps and stairs, never up a ledge the courier cannot climb, and round gates and crates, which are navObstacles),
// whose corner points Courier.walkTo() follows. Moving with the stick or the keys, or jumping, cancels the walk. Taps on
// the UI (the pause button) and on the on-screen stick or buttons do not count: those fingers never reach input.touches /
// the mouse.
import { Behaviour, input, camera, physics, ui, world, nav } from "factoria";
import * as settings from "./settings.js";

export default class TapMove extends Behaviour {
  /** Height of the courier's centre above its feet (half the CharacterController3D height), metres: paths start at the feet. */
  feet = 0.55;
  /** Radius of the courier for path finding, metres (at most the NavMesh3D's agentRadius). */
  navRadius = 0.3;
  /** A tap this far (metres) from walkable ground, on the side of a wall, say, goes to the nearest ground instead. */
  snap = 1.5;
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
    const near = camera.screenToWorld(screen, 1);
    const far = camera.screenToWorld(screen, 80);
    const d = [far.x - near.x, far.y - near.y, far.z - near.z];
    const len = Math.hypot(d[0], d[1], d[2]);
    if (len < 1e-6) return false;
    const hit = physics.raycast3d([near.x, near.y, near.z], [d[0] / len, d[1] / len, d[2] / len], 200, { ignore: this.courier });
    if (!hit) return false;
    this.taps++;
    return this.goTo([hit.point.x, hit.point.y, hit.point.z]);
  }

  /** Sends the courier to a world point on the ground ([x, y, z]); the tap does it with the point under the finger.
   *  Returns true when a walk started. */
  goTo(to) {
    const cb = this.courier.behaviour;
    const from = this.courier.position;
    if (Math.hypot(to[0] - from.x, to[2] - from.z) > this.maxDistance) return false;
    this.lastTarget = [to[0], to[1], to[2]];
    // Gates and crates are navObstacles: the mesh knows where they are right now. `closest`: a goal that cannot be reached
    // (an island, a ledge too high) walks to the reachable point nearest to it.
    const r = nav.findPath([from.x, from.y - this.feet, from.z], to, { radius: this.navRadius, snap: this.snap, closest: true });
    if (!r.found || r.points.length === 0) return false;
    // points[0] is where the courier stands: walk to the corners after it.
    const corners = r.points.length > 1 ? r.points.slice(1) : r.points;
    this.lastPath = corners.map((p) => [p.x, p.z, p.y]);
    this.lastComplete = r.complete;
    cb.walkTo(corners.map((p) => [p.x, p.z]));
    return true;
  }
}
