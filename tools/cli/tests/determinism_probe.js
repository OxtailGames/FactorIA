// @ts-check
// The cross-platform replay hashes of the simulation that scripts can reach (M91.3): the same file runs on every desktop (the
// runtime test "det probe", engine/runtime/tests/det_probe_tests.cpp), in the Android emulator, on the iOS simulator and in the
// browser (the android-emulator, ios and web jobs of .github/workflows/ci.yml add it to the game they run). It logs ONE line
//
//   FA_DET_HASH math=<h> script=<h> physics2d=<h> physics3d=<h> nav=<h> navFound=<n> y2d=<y> y3d=<y>
//
// and every platform must print the same hashes: a hash is the first 16 hex digits of a 64-bit digest of the exact bits
// of the numbers (never a rounded print). The last three fields are a rounded look at the scene (paths found, the height of one 2D and
// one 3D body: "the bodies fell and the nav search worked"), for the person reading a log; only the five hashes are compared. The line comes after kSteps fixed steps, so the number of frames a slow device needs
// does not matter. When a hash differs, the section that differs is where the platform's arithmetic parts: math is Math.* (the
// deterministic functions of fa::det::f64, docs/SCRIPTING.md "Math"), script is a seeded generator plus Math in a loop, physics2d
// is Box2D, physics3d the 3D solver, nav the NavMesh3D bake and a path search.
//
// The bodies are spawned far from the origin (x = 100000), so the game's own scene (a platformer template) never touches them.
import { Behaviour, world, nav, rng, Vec3 } from "factoria";

const kSteps = 60;
const kFar = 100000;

const f64 = new Float64Array(1);
const u32 = new Uint32Array(f64.buffer);

/** Two 32-bit lanes (FNV-1a, and the same with another prime and offset) over the 8 bytes of each number: 64 bits, only Math.imul. */
class Digest {
  constructor() {
    this.a = 0x811c9dc5;
    this.b = 0x9747b28c;
  }
  /** @param {number} byte */
  byte(byte) {
    this.a = Math.imul(this.a ^ byte, 16777619) >>> 0;
    this.b = Math.imul(this.b ^ (byte + 1), 0x9e3779b1) >>> 0;
    this.b = (this.b ^ (this.b >>> 15)) >>> 0;
  }
  /** @param {number} x */
  num(x) {
    f64[0] = x;
    for (const w of [u32[0], u32[1]]) {
      for (let i = 0; i < 4; i++) this.byte((w >>> (8 * i)) & 0xff);
    }
  }
  hex() {
    return this.a.toString(16).padStart(8, "0") + this.b.toString(16).padStart(8, "0");
  }
}

function mathHash() {
  const d = new Digest();
  const g = rng.create(20260101);
  for (let i = 0; i < 400; i++) {
    const x = (g.float() - 0.5) * 40;      // -20..20
    const p = g.float() * 0.999 + 0.0005;  // (0, 1)
    const big = 1 + g.float() * 1000;
    d.num(Math.sin(x)); d.num(Math.cos(x)); d.num(Math.tan(x));
    d.num(Math.asin(p * 2 - 1)); d.num(Math.acos(p * 2 - 1)); d.num(Math.atan(x)); d.num(Math.atan2(x, p - 0.5));
    d.num(Math.exp(x / 4)); d.num(Math.expm1(p / 10)); d.num(Math.log(big)); d.num(Math.log2(big)); d.num(Math.log10(big));
    d.num(Math.log1p(p)); d.num(Math.pow(big, p * 3 - 1.5)); d.num(big ** 0.37); d.num(Math.pow(p, x / 5));
    d.num(Math.sinh(x / 8)); d.num(Math.cosh(x / 8)); d.num(Math.tanh(x / 4));
    d.num(Math.asinh(x)); d.num(Math.acosh(big)); d.num(Math.atanh(p * 2 - 1));
    d.num(Math.cbrt(x)); d.num(Math.hypot(x, big)); d.num(Math.sqrt(big));
  }
  for (const e of [0, 1, 2, 3, 10, -1, -2, 0.5, 1.5, 2.5, 100, -100, 308, -308, 1e-5])
    for (const b of [2, 3, 10, 0.5, 1.0001, 7.25]) d.num(Math.pow(b, e));
  for (const x of [1e-300, 1e-8, 0.5, 1, Math.PI, 1e3, 1e6, 1e9, 1e12, -1e6, -0.0, 0])
    { d.num(Math.sin(x)); d.num(Math.cos(x)); d.num(Math.tan(x)); }
  return d.hex();
}

// A game-like loop: a seeded generator, Math in a motion update, hashed at every step.
function scriptHash() {
  const d = new Digest();
  const g = rng.create(77);
  let x = 0, y = 0, vx = 3, vy = 5, angle = 0;
  for (let i = 0; i < 600; i++) {
    angle += 0.05 + g.float() * 0.01;
    vx += Math.cos(angle) * 0.2 - vx * 0.01 * Math.exp(-i / 300);
    vy += Math.sin(angle * 1.7) * 0.2 - 9.8 / 60 - vy * Math.pow(0.99, 1 + g.float());
    x += vx / 60; y += vy / 60;
    if (y < 0) { y = -y; vy = -vy * 0.8; }
    d.num(x); d.num(y); d.num(Math.atan2(vy, vx)); d.num(Math.hypot(vx, vy));
  }
  return d.hex();
}

export default class DeterminismProbe extends Behaviour {
  steps = 0;
  /** @type {any[]} */ bodies2d = [];
  /** @type {any[]} */ bodies3d = [];
  reported = false;
  navHash = "none";
  navFound = 0;

  onStart() {
    // 2D: a floor, a ramp and a pile of boxes and circles (Box2D).
    world.spawn({ id: "det2dFloor", components: {
      Transform: { position: [kFar, 0, 0] }, Collider2D: { size: [800, 20] }, RigidBody2D: { type: "static" } } });
    world.spawn({ id: "det2dRamp", components: {
      Transform: { position: [kFar + 60, 40, 0], rotation: [0, 0, -20] }, Collider2D: { size: [160, 12] }, RigidBody2D: { type: "static" } } });
    for (let i = 0; i < 14; i++) {
      const round = i % 2 === 1;
      this.bodies2d.push(world.spawn({ id: `det2d${i}`, components: {
        Transform: { position: [kFar + (i % 4) * 11 - 20, 60 + 28 * i, 0], rotation: [0, 0, 13 * i] },
        Collider2D: round ? { shape: "circle", radius: 11 } : { size: [24, 18] },
        RigidBody2D: {} } }));
    }
    // 3D: a floor and tumbling boxes and spheres.
    world.spawn({ id: "det3dFloor", components: {
      Transform: { position: [kFar, -0.5, 1000] }, Collider3D: { size: [40, 1, 40] }, RigidBody3D: { type: "static" } } });
    for (let i = 0; i < 10; i++) {
      this.bodies3d.push(world.spawn({ id: `det3d${i}`, components: {
        Transform: { position: [kFar + 0.4 * (i % 3), 2 + 1.1 * i, 1000 + 0.2 * (i % 2)], rotation: [7 * i, 11 * i, 5 * i] },
        Collider3D: i % 3 === 0 ? { shape: "sphere", radius: 0.4 } : { size: [0.7, 0.5 + 0.05 * i, 0.6] },
        RigidBody3D: { angularVelocity: [90 + 13 * i, 40, -55 + 9 * i] } } }));
    }
    // Navigation: a floor with a wall in the middle; the path goes around it.
    world.spawn({ id: "detNavFloor", components: {
      Transform: { position: [kFar, -0.5, 2000] }, Collider3D: { size: [20, 1, 20] }, RigidBody3D: { type: "static" } } });
    world.spawn({ id: "detNavWall", components: {
      Transform: { position: [kFar, 1.5, 2000] }, Collider3D: { size: [0.4, 3, 8] }, RigidBody3D: { type: "static" } } });
    world.spawn({ id: "detNavMesh", components: {
      Transform: { position: [kFar, 2, 2000] }, NavMesh3D: { size: [20, 6, 20] } } });
  }

  onFixedUpdate() {
    this.steps++;
    if (this.steps === 3) {
      // The static colliders are in the physics world by now.
      try {
        nav.bake();
        const d = new Digest();
        for (const [a, b] of [[[-8, 0, -6], [8, 0, 6]], [[-8, 0, 6], [8, 0, -6]], [[-3, 0, 0], [3, 0, 1]]]) {
          const r = nav.findPath(new Vec3(kFar + a[0], a[1], 2000 + a[2]), new Vec3(kFar + b[0], b[1], 2000 + b[2]));
          d.num(r.found ? 1 : 0);
          if (r.found) this.navFound++;
          d.num(r.length);
          for (const p of r.points) { d.num(p.x - kFar); d.num(p.y); d.num(p.z - 2000); }
        }
        this.navHash = d.hex();
      } catch (e) {
        this.navHash = "error";
        console.error(`determinism probe: nav failed: ${e && e.message}`);
      }
    }
    if (this.steps === kSteps && !this.reported) {
      this.reported = true;
      const d2 = new Digest(), d3 = new Digest();
      for (const e of this.bodies2d) { const p = e.position, r = e.transform.rotation; d2.num(p.x - kFar); d2.num(p.y); d2.num(r.z); }
      for (const e of this.bodies3d) {
        const p = e.position, r = e.transform.rotation;
        d3.num(p.x - kFar); d3.num(p.y); d3.num(p.z - 1000); d3.num(r.x); d3.num(r.y); d3.num(r.z);
      }
      console.log(`FA_DET_HASH math=${mathHash()} script=${scriptHash()} physics2d=${d2.hex()} physics3d=${d3.hex()} nav=${this.navHash} navFound=${this.navFound} y2d=${this.bodies2d[0].position.y.toFixed(1)} y3d=${this.bodies3d[9].position.y.toFixed(2)}`);
    }
  }
}
