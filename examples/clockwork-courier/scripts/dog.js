// @ts-check
// A guard dog (prefabs/dog.prefab.json): patrols a route, notices the courier, barks, chases it around obstacles, and
// gives up when it loses the trail. A catch sends the courier back to the last checkpoint (Courier.caught()).
//
//   patrol   walks the `route` (waypoints [x, z]; ping-pong, or a loop with `loop`), pausing at each end. No route:
//            it stands guard and turns its head left and right.
//   alert    stops, turns to the courier and barks for `alertTime` ("!" over its head, the view cone turns red)
//   chase    runs after the courier along a path found by scripts/nav.js (a grid A*: the engine has no navmesh), at
//            `runSpeed` (a little slower than the courier: running away works, for a while)
//   search   lost sight: runs to the last place it saw the courier, then sniffs around. After `giveUpTime` seconds
//            without seeing it (or when it strays more than `leash` metres from home) it gives up
//   return   walks back home (dog_gave_up is sent), then patrols again
//   caught   the courier was caught: the dog holds still for a moment, then returns
//
// What it notices: the courier inside the view cone (`sightAngle` half-angle, `sightRange` metres) with a clear line of
// sight (a ray that no wall blocks), or very close (`hearRadius`) when the courier is not sneaking. Sneaking is walking
// slowly (Shift, or a half-tilted stick): it also shortens the sight range. It ignores a courier that is on the ground
// (caught) or in its post-catch grace period.
//
// Tests and scenes read `state` ("patrol", "alert", "chase", "search", "return", "caught"), `sees`, `yaw`, `lostTime`.
import { Behaviour, physics, world, audio } from "factoria";
import { EVENTS, emit } from "./events.js";
import { NavGrid } from "./nav.js";

const DEG = Math.PI / 180;

export default class Dog extends Behaviour {
  /** Patrol waypoints [[x, z], ...] in world metres. Empty: stands guard where it is. */
  route = [];
  /** true: walks the route in a loop; false: back and forth. */
  loop = false;
  /** Seconds it waits at each waypoint. */
  pause = 1.4;
  /** Walking speed on patrol and on the way home, m/s. */
  walkSpeed = 1.6;
  /** Running speed while chasing, m/s (the courier runs at 5). */
  runSpeed = 4.6;
  /** Turn speed, degrees per second. */
  turnSpeed = 420;
  /** How far it sees along its view cone, metres. */
  sightRange = 9;
  /** Half-angle of the view cone, degrees. */
  sightAngle = 55;
  /** Within this distance it hears a courier that is not sneaking, metres. */
  hearRadius = 2.5;
  /** The courier counts as sneaking below this horizontal speed (m/s); its sight range shrinks to `sneakSight` times. */
  sneakSpeed = 2.3;
  sneakSight = 0.6;
  /** Seconds it barks before it runs. */
  alertTime = 0.7;
  /** Seconds without seeing the courier before it gives up. */
  giveUpTime = 5;
  /** Farthest it follows from its home, metres. */
  leash = 18;
  /** Distance at which it catches the courier, metres (and the largest height difference: 1 m). */
  catchRadius = 0.85;
  /** Gravity, m/s^2. */
  gravity = 24;
  /** Metres above the dog's start height from which the path finder looks down for ground (stairs up to this high). */
  navUp = 2.5;
  /** Tint of the view cone when calm and when alerted. */
  calmColor = [1, 0.95, 0.7, 1];
  alertColor = [1, 0.25, 0.2, 1];
  /** Sound of a bark (an impact clip, pitched: the kit has no bark, ENGINE_FEEDBACK). */
  barkSound = "assets/audio/impactPunch_heavy_000.ogg";
  /** Id of the courier entity. */
  courierId = "courier";

  onStart() {
    this.home = [this.entity.position.x, this.entity.position.z];
    this.baseY = this.entity.position.y;
    this.state = "patrol";
    this.stateTime = 0;
    this.yaw = this.entity.get("Transform").rotation.y;
    this.guardYaw = this.yaw;
    this.vy = 0;
    this.speed = 0;
    this.grounded = false;
    this.sees = false;
    this.lostTime = 0;
    this.lastSeen = null;
    this.routeIndex = 0;
    this.routeDir = 1;
    this.waiting = 0;
    this.barkTimer = 0;
    this.nav = null;
    this.navAge = 0;
    this.path = null;
    this.pathIndex = 0;
    this.pathCooldown = 0;
    this.dest = null;
    this.stuckTime = 0;
    this.time = 0;
    this.courier = world.find(this.courierId);
    this.model = this.entity.children.find((c) => c.name === "model") ?? null;
    this.mark = this.entity.children.find((c) => c.name === "alert") ?? null;
    this.cone = this.entity.children.find((c) => c.name === "cone") ?? null;
    this.anim = this.model ? this.model.get("Animator") : null;
    this.clip = "";
    if (this.mark) this.mark.active = false;
    this.setClip("idle");
  }

  // ----------------------------------------------------------------------------------------------------------- senses
  /** Is there a free line between two points? (The dog's own collider and triggers do not count.) */
  lineOfSight(from, to) {
    const dx = to[0] - from[0];
    const dy = to[1] - from[1];
    const dz = to[2] - from[2];
    const len = Math.hypot(dx, dy, dz);
    if (len < 0.05) return true;
    const hit = physics.raycast3d(from, [dx / len, dy / len, dz / len], len, { ignore: this.entity });
    return !hit || hit.entity.hasTag("courier");
  }

  /** Does the dog notice the courier right now? */
  notices() {
    const c = this.courier;
    const cb = c ? c.behaviour : null;
    if (!c || !cb || cb.isCaught || cb.locked || cb.grace > 0) return false;
    const p = this.entity.position;
    const q = c.position;
    const dx = q.x - p.x;
    const dz = q.z - p.z;
    const dist = Math.hypot(dx, dz);
    if (Math.abs(q.y - p.y) > 3.5) return false;
    const sneaking = cb.speed < this.sneakSpeed;
    // Hearing: running footsteps close by (no cone, no line of sight, but not through a whole wall: a short ray check).
    if (!sneaking && dist <= this.hearRadius) return true;
    const range = this.sightRange * (sneaking ? this.sneakSight : 1);
    if (dist > range) return false;
    const toYaw = Math.atan2(-dx, -dz) / DEG;
    if (Math.abs(angleDiff(toYaw, this.yaw)) > this.sightAngle) return false;
    return this.lineOfSight([p.x, p.y + 0.1, p.z], [q.x, q.y, q.z]);
  }

  // --------------------------------------------------------------------------------------------------------- movement
  setClip(name) {
    if (!this.anim || this.clip === name) return;
    this.clip = name;
    const map = { idle: "idle", walk: "walk", run: "run", bark: "gesture-positive", sniff: "eat", shake: "gesture-negative" };
    this.anim.clip = map[name] ?? name;
    this.anim.loop = name !== "shake";
  }

  /** Points the dog to a world destination and keeps a path to it (re-found when it moved or the walk is blocked). */
  setDest(x, z) {
    const old = this.dest;
    this.dest = [x, z];
    if (old && Math.hypot(old[0] - x, old[1] - z) < 0.9 && this.path) return;
    this.findPath();
  }

  findPath() {
    if (this.pathCooldown > 0) return;
    this.pathCooldown = 0.3;
    if (!this.nav || this.navAge > 5) {
      this.nav = new NavGrid({ ceilY: this.baseY + this.navUp, radius: 0.32, clearance: 0.5 });
      this.navAge = 0;
    }
    const p = this.entity.position;
    const d = this.dest;
    if (this.nav.lineClear(p.x, p.z, d[0], d[1])) {
      this.path = [[d[0], d[1]]];
    } else {
      const r = this.nav.findPath([p.x, p.z], d);
      this.path = r ? r.path : [[d[0], d[1]]];
    }
    this.pathIndex = 0;
  }

  /** Walks along the path at `speed`; false when there is nowhere left to go. */
  walk(dt, speed) {
    let want = null;
    const p = this.entity.position;
    while (this.path && this.pathIndex < this.path.length) {
      const w = this.path[this.pathIndex];
      const dx = w[0] - p.x;
      const dz = w[1] - p.z;
      const d = Math.hypot(dx, dz);
      if (d < 0.3) {
        this.pathIndex++;
        continue;
      }
      want = [dx / d, dz / d];
      break;
    }
    if (!want) {
      this.speed = 0;
      return false;
    }
    this.speed = speed;
    this.faceDir(want[0], want[1], dt);
    this.vx = want[0] * speed;
    this.vz = want[1] * speed;
    return true;
  }

  faceDir(dx, dz, dt) {
    this.yaw = turnToward(this.yaw, Math.atan2(-dx, -dz) / DEG, this.turnSpeed * dt);
  }

  faceYaw(target, dt) {
    this.yaw = turnToward(this.yaw, target, this.turnSpeed * dt);
  }

  // ---------------------------------------------------------------------------------------------------------- states
  enter(state) {
    this.state = state;
    this.stateTime = 0;
    this.path = null;
    this.dest = null;
    if (this.mark) this.mark.active = state === "alert" || state === "chase";
    this.tintCone(state === "alert" || state === "chase" ? this.alertColor : this.calmColor);
  }

  tintCone(c) {
    const light = this.cone ? this.cone.get("Light") : null;
    if (light) light.color = c;
  }

  bark(volume = 0.9) {
    audio.play(this.barkSound, { bus: "sfx", volume, pitch: 1.7 + (this.time % 0.2), caption: "[Dog barks]", captionKey: "captions.dogBark" });
    this.setClip("bark");
  }

  onFixedUpdate(dt) {
    this.time += dt;
    this.stateTime += dt;
    this.navAge += dt;
    if (this.pathCooldown > 0) this.pathCooldown -= dt;
    this.vx = 0;
    this.vz = 0;
    this.speed = 0;
    const cb = this.courier ? this.courier.behaviour : null;
    this.sees = this.notices();
    const p = this.entity.position;

    switch (this.state) {
      case "patrol":
        this.patrol(dt);
        if (this.sees) this.alert();
        break;
      case "alert":
        this.alertState(dt);
        break;
      case "chase":
      case "search":
        this.chaseOrSearch(dt, cb);
        break;
      case "return":
        this.returnHome(dt);
        if (this.sees) this.alert();
        break;
      case "caught":
        this.setClip("idle");
        if (this.stateTime > 1.6) this.goHome(false);
        break;
      default:
        break;
    }

    // ------------------------------------------------------------------------------------------------------ physics
    this.vy = this.grounded ? Math.min(this.vy, -1) : Math.max(this.vy - this.gravity * dt, -30);
    const r = physics.moveCharacter(this.entity, [this.vx * dt, this.vy * dt, this.vz * dt]);
    this.grounded = r.isGrounded;
    if (this.grounded && this.vy > 0) this.vy = 0;
    // Stuck on something (a crate, a closed gate): look for another path.
    const moved = Math.hypot(r.moved.x, r.moved.z);
    if (this.speed > 0 && moved < this.speed * dt * 0.25) this.stuckTime += dt;
    else this.stuckTime = 0;
    if (this.stuckTime > 0.5) {
      this.stuckTime = 0;
      this.nav = null;
      this.pathCooldown = 0;
      if (this.dest) this.findPath();
    }
    if (r.position.y < -30) this.entity.position = [this.home[0], this.baseY, this.home[1]];

    // ----------------------------------------------------------------------------------------------------- visuals
    if (this.model) this.model.get("Transform").rotation = [0, this.yaw + 180, 0];
    if (this.cone) this.cone.get("Transform").rotation = [-18, this.yaw, 0];
    if (this.mark && this.mark.active) {
      const t = this.mark.get("Transform");
      t.position = [0, 0.48 + Math.sin(this.time * 9) * 0.04, 0]; // just above the head
    }
    void p;
  }

  patrol(dt) {
    this.setClip(this.speed > 0 ? "walk" : "idle");
    if (this.route.length === 0) {
      // Standing guard: turn the head slowly left and right.
      this.faceYaw(this.guardYaw + Math.sin(this.time * 0.9) * 50, dt);
      this.setClip("idle");
      return;
    }
    if (this.waiting > 0) {
      this.waiting -= dt;
      this.setClip("idle");
      return;
    }
    const w = this.route[this.routeIndex];
    const p = this.entity.position;
    if (Math.hypot(w[0] - p.x, w[1] - p.z) < 0.4) {
      this.waiting = this.pause;
      if (this.loop) this.routeIndex = (this.routeIndex + 1) % this.route.length;
      else {
        if (this.routeIndex + this.routeDir < 0 || this.routeIndex + this.routeDir >= this.route.length) this.routeDir = -this.routeDir;
        this.routeIndex += this.routeDir;
      }
      return;
    }
    // The route is authored in straight, clear lines: walk straight at the waypoint.
    this.path = [[w[0], w[1]]];
    this.pathIndex = 0;
    this.walk(dt, this.walkSpeed);
    this.setClip("walk");
  }

  alert() {
    this.enter("alert");
    this.lastSeen = this.courierPos();
    this.lostTime = 0;
    const p = this.entity.position;
    emit(EVENTS.dogAlerted, { dog: this.entity.id, position: [p.x, p.y, p.z] });
    this.bark();
  }

  alertState(dt) {
    const c = this.courierPos();
    if (c) {
      const p = this.entity.position;
      this.faceDir(c[0] - p.x, c[2] - p.z, dt);
      if (this.sees) this.lastSeen = c;
    }
    if (this.stateTime >= this.alertTime) {
      this.enter("chase");
      this.barkTimer = 3;
    }
  }

  courierPos() {
    const q = this.courier ? this.courier.position : null;
    return q ? [q.x, q.y, q.z] : null;
  }

  chaseOrSearch(dt, cb) {
    const p = this.entity.position;
    if (!cb || cb.isCaught || cb.locked) {
      // Someone (maybe this dog) caught it, or the level is over.
      if (this.state !== "caught") this.enter("caught");
      return;
    }
    // Catch.
    const q = this.courier.position;
    const near = Math.hypot(q.x - p.x, q.z - p.z) <= this.catchRadius && Math.abs(q.y - p.y) <= 1;
    if (near && cb.grace <= 0) {
      cb.caught("dog");
      this.enter("caught");
      return;
    }
    if (this.sees) {
      if (this.state === "search") {
        this.enter("chase");
        this.setClip("run");
      }
      this.lastSeen = [q.x, q.y, q.z];
      this.lostTime = 0;
    } else {
      this.lostTime += dt;
    }
    if (cb.grace > 0 && !this.sees) this.lostTime += dt; // the courier just respawned: forget it twice as fast
    this.barkTimer -= dt;
    if (this.state === "chase" && this.sees && this.barkTimer <= 0) {
      this.barkTimer = 3;
      this.bark(0.6);
    }
    const farFromHome = Math.hypot(p.x - this.home[0], p.z - this.home[1]) > this.leash;
    if (this.lostTime >= this.giveUpTime || farFromHome) {
      this.goHome(true);
      return;
    }
    if (this.state === "chase") {
      const t = this.sees ? [q.x, q.z] : [this.lastSeen[0], this.lastSeen[2]];
      this.setDest(t[0], t[1]);
      this.walk(dt, this.runSpeed);
      this.setClip("run");
      if (!this.sees && Math.hypot(t[0] - p.x, t[1] - p.z) < 0.7) this.enter("search");
    } else {
      // Search: sniff and look around where the trail ended.
      this.setClip("sniff");
      this.faceYaw(this.yaw + Math.sin(this.stateTime * 2) * 90 * dt * 3, dt);
    }
  }

  goHome(gaveUp) {
    if (gaveUp) emit(EVENTS.dogGaveUp, { dog: this.entity.id });
    this.enter("return");
    this.lostTime = 0;
    this.nav = null;
  }

  returnHome(dt) {
    const p = this.entity.position;
    const d = Math.hypot(this.home[0] - p.x, this.home[1] - p.z);
    if (d < 0.5) {
      this.enter("patrol");
      this.waiting = 0.6;
      return;
    }
    this.setDest(this.home[0], this.home[1]);
    this.walk(dt, this.walkSpeed * 1.4);
    this.setClip("walk");
  }
}

/** Smallest signed difference a - b in degrees, -180..180. */
function angleDiff(a, b) {
  return (((a - b) % 360) + 540) % 360 - 180;
}

/** Moves angle `a` towards `b` (degrees) by at most `maxStep`, the short way round. */
function turnToward(a, b, maxStep) {
  const d = angleDiff(b, a);
  if (Math.abs(d) <= maxStep) return b;
  return a + Math.sign(d) * maxStep;
}
