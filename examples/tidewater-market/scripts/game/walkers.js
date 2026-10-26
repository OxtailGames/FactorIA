// @ts-check
// Walkers (pure): every villager that is outside a building is one walker on the road network, going to a building. A walker
// follows a list of road cells at its own speed (cells per game second), and keeps checking that the road is still there:
// when a road is cut under it, it looks for another way from where it stands, waits if there is none and gives up after
// `patienceSeconds`. The owner (people.js) decides what happens when a walker arrives or gives up.
//
// `x`, `y` are the position in (fractional) cells, `px`, `py` the position one step ago: the view draws the walker at
// px + (x - px) * clock.alpha, so the motion is smooth at any speed and frame rate.

/**
 * @typedef {{
 *   id: number, kind: string, goal: number, path: number[], i: number, t: number, speed: number,
 *   version: number, wait: number, blocked: boolean,
 *   x: number, y: number, px: number, py: number, dir: number
 * }} Walker
 */

export class Walkers {
  /**
   * @param {import("./roadnet.js").RoadNet} net
   * @param {import("./state.js").GameState} state
   * @param {{ onArrive: (w: Walker) => void, onLost: (w: Walker, why: string) => void }} handlers
   */
  constructor(net, state, handlers) {
    this.net = net;
    this.state = state;
    this.handlers = handlers;
    /** @type {Map<number, Walker>} by id (a villager's id) in the order they started */
    this.list = new Map();
    /** Times a walker had to find a new way because a road was cut. */
    this.rerouted = 0;
    /** Walkers that gave up. */
    this.gaveUp = 0;
  }

  get count() {
    return this.list.size;
  }

  /**
   * Start a walker from a building's door to another building. Returns null when there is no way over the roads.
   * @param {number} id @param {string} kind "villager" | "carrier"
   * @param {{ id: number, type: string, x: number, y: number, rot: number }} from @param {{ id: number }} goal @param {number} speed
   * @param {boolean} [viaFrom] find the way with the distance field of the starting building (RoadNet.routeBuildings)
   * @returns {Walker | null}
   */
  start(id, kind, from, goal, speed, viaFrom = false) {
    const goalB = this.state.buildings.get(goal.id);
    if (!goalB) return null;
    const path = this.net.routeBuildings(from, goalB, viaFrom);
    if (!path) return null;
    return this.startPath(id, kind, path, goal.id, speed);
  }

  /** @param {number} id @param {string} kind @param {number[]} path @param {number} goal building id @param {number} speed */
  startPath(id, kind, path, goal, speed) {
    const w0 = this.net.width;
    const c = path[0] % w0;
    const r = (path[0] - c) / w0;
    /** @type {Walker} */
    const w = { id, kind, goal, path, i: 0, t: 0, speed, version: this.net.version, wait: 0, blocked: false, x: c, y: r, px: c, py: r, dir: 0 };
    this.list.set(id, w);
    return w;
  }

  remove(id) {
    this.list.delete(id);
  }

  /** Advance every walker by `dt` game seconds. */
  step(dt) {
    const net = this.net;
    const w0 = net.width;
    for (const w of [...this.list.values()]) {
      if (this.list.get(w.id) !== w) continue; // removed by a handler earlier in this step
      w.px = w.x;
      w.py = w.y;
      if (w.version !== net.version) {
        this.revalidate(w);
        if (this.list.get(w.id) !== w) continue;
      }
      if (w.blocked) {
        w.wait += dt;
        if (w.wait >= this.state.data.sim.patienceSeconds) {
          this.list.delete(w.id);
          this.gaveUp++;
          this.handlers.onLost(w, "no_route");
        }
        continue;
      }
      let move = w.speed * dt;
      const path = w.path;
      while (move > 0 && w.i < path.length - 1) {
        const left = 1 - w.t;
        if (move < left) {
          w.t += move;
          move = 0;
        } else {
          move -= left;
          w.i++;
          w.t = 0;
        }
      }
      const a = path[w.i];
      const ac = a % w0;
      const ar = (a - ac) / w0;
      if (w.i < path.length - 1 && w.t > 0) {
        const b = path[w.i + 1];
        const bc = b % w0;
        const br = (b - bc) / w0;
        w.x = ac + (bc - ac) * w.t;
        w.y = ar + (br - ar) * w.t;
        w.dir = bc > ac ? 0 : bc < ac ? 2 : br > ar ? 1 : 3;
      } else {
        w.x = ac;
        w.y = ar;
      }
      if (w.i >= path.length - 1) {
        this.list.delete(w.id);
        this.handlers.onArrive(w);
      }
    }
  }

  /** The roads changed: is the rest of the way still road? If not, look for another. */
  revalidate(w) {
    const net = this.net;
    w.version = net.version;
    const path = w.path;
    let ok = net.road[path[w.i]] === 1 || w.t > 0;
    for (let k = w.i + 1; ok && k < path.length; k++) if (!net.road[path[k]]) ok = false;
    if (ok && !w.blocked && net.road[path[w.i]]) return;
    const goal = this.state.buildings.get(w.goal);
    if (!goal) {
      this.list.delete(w.id);
      this.handlers.onLost(w, "goal_gone");
      return;
    }
    // where it stands: the cell it left, or the one it is walking to, or the nearest road
    let cur = -1;
    if (w.t > 0 && net.road[path[w.i + 1]]) cur = path[w.i + 1];
    else if (net.road[path[w.i]]) cur = path[w.i];
    else cur = net.nearestRoad(path[w.i], 3);
    if (cur < 0) {
      this.list.delete(w.id);
      this.gaveUp++;
      this.handlers.onLost(w, "road_gone");
      return;
    }
    const fresh = net.routeFrom([cur], goal);
    if (!fresh) {
      w.blocked = true;
      w.path = [cur];
      w.i = 0;
      w.t = 0;
      this.place(w);
      return;
    }
    if (w.blocked) w.wait = 0;
    w.blocked = false;
    w.path = fresh;
    w.i = 0;
    w.t = 0;
    this.rerouted++;
    this.place(w);
  }

  place(w) {
    const c = w.path[0] % this.net.width;
    const r = (w.path[0] - c) / this.net.width;
    w.x = c;
    w.y = r;
  }
}
