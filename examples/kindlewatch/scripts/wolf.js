// @ts-check
// A wolf (or the alpha: the same script with other props, prefabs/alpha_wolf.prefab.json). It runs at the fire or at the
// warden, slows down inside the light of the fire, stops to bite when in reach, staggers when hit and runs off at dawn.
// A rigged model with an Animator (idle, trot, gallop, bite, hit) moved by a CharacterController3D.
//
// Other scripts use: hurt(damage, [dx, dz]), flee(), dead, hp, kind. Events sent: wolf_down {kind}, wolf_roar {kind}.
import { Behaviour, physics, world, rng, camera, audio } from "factoria";
import { yawOf, turnToward, flatDistance, behaviourOf } from "./common.js";

/** How far from the camera (the AudioListener, 18 units above the clearing) a wolf sound is heard, in world units. */
const EARS = 48;

export default class Wolf extends Behaviour {
  /** "wolf" or "alpha". */
  kind = "wolf";
  /** Hits it takes. */
  hp = 2;
  /** Running speed, m/s. */
  speed = 3;
  /** Hearts a bite takes from the warden. */
  damage = 1;
  /** Fuel a bite takes from the fire. */
  fireBite = 6;
  /** Seconds between two bites. */
  biteCooldown = 1.3;
  /** Distance from the warden at which it bites, metres. */
  reach = 1.5;
  /** Distance from the fire's centre at which it bites the fire, metres. */
  fireReach = 2.3;
  /** Seconds it is stunned by a hit. */
  stagger = 0.3;
  /** Speed of the push a hit gives, m/s. */
  knock = 5;
  /** Radius used by the warden's swing, metres. */
  bodyRadius = 0.5;
  /** Chance (0..1) that a wolf goes for the fire rather than for the warden when the warden is not close. */
  fireLust = 0.6;
  /** Seconds the dead body takes to sink away. */
  fadeTime = 0.35;

  onStart() {
    this.dead = false;
    this.fleeing = false;
    this.mode = "run"; // run | bite | stagger
    this.timer = 0;
    this.cool = rng.range(0.2, 0.8);
    this.vx = 0;
    this.vz = 0;
    this.yaw = yawOf(-this.entity.position.x, -this.entity.position.z);
    this.stuck = 0;
    this.side = rng.chance(0.5) ? 1 : -1;
    this.wantsFire = rng.chance(this.fireLust);
    this.enraged = false;
    this.maxHp = this.hp;
    const s = this.entity.get("Transform").scale;
    this.baseScale = { x: s.x, y: s.y, z: s.z };
    this.anim = this.entity.animator;
    this.unsub = world.on("wolf_bite_hit", (_d, source) => source?.id === this.entity.id && this.biteLands());
    this.entity.get("Transform").rotation = [0, this.yaw, 0];
    audio.play("assets/audio/wolf_growl.wav", { position: this.entity.position, range: EARS, bus: "sfx", variants: 3, volume: this.kind === "alpha" ? 1 : 0.7 });
  }

  onDestroy() {
    this.unsub?.();
  }

  /** The thing it runs at: the warden when close (or when the alpha), else the fire. */
  chooseTarget() {
    const warden = world.find("warden");
    const fire = world.find("campfire");
    if (this.fleeing) return null;
    const wardenClose = warden && flatDistance(warden, this.entity) < 6.5;
    if (warden && (wardenClose || !this.wantsFire || this.kind === "alpha") && !warden.behaviour?.locked) return warden;
    return fire;
  }

  onFixedUpdate(dt) {
    if (this.dead) return;
    const p = this.entity.position;
    const fire = behaviourOf("campfire");
    if (this.cool > 0) this.cool -= dt;
    if (this.timer > 0) this.timer -= dt;

    let wantX = 0;
    let wantZ = 0;
    let speedNow = 0;

    if (this.fleeing) {
      // Away from the fire until out of the clearing, then gone.
      const d = Math.hypot(p.x, p.z) || 1;
      wantX = p.x / d;
      wantZ = p.z / d;
      speedNow = this.speed * 1.5;
      if (d > 27) return void this.entity.destroy();
    } else if (this.mode === "stagger") {
      if (this.timer <= 0) this.mode = "run";
    } else if (this.mode === "bite") {
      if (this.timer <= 0) this.mode = "run";
    } else {
      const target = this.chooseTarget();
      if (target) {
        const dx = target.position.x - p.x;
        const dz = target.position.z - p.z;
        const dist = Math.hypot(dx, dz) || 1;
        const isFire = target.id === "campfire";
        const reach = isFire ? this.fireReach : this.reach;
        if (dist <= reach) {
          if (this.cool <= 0) this.startBite(dx, dz);
          else this.yaw = turnToward(this.yaw, yawOf(dx, dz), 600 * dt);
        } else {
          wantX = dx / dist;
          wantZ = dz / dist;
          // Circle a little before closing in: wolves do not come in a straight line.
          if (dist > 7) {
            wantX += (-dz / dist) * 0.25 * this.side;
            wantZ += (dx / dist) * 0.25 * this.side;
          }
          speedNow = this.speed * (fire && fire.inLight(p) ? 0.6 : 1);
        }
      }
    }

    // Smooth velocity, a push from a hit decays here too.
    const l = Math.hypot(wantX, wantZ) || 1;
    const tx = (wantX / l) * speedNow;
    const tz = (wantZ / l) * speedNow;
    const k = Math.min(1, (this.mode === "stagger" ? 4 : 14) * dt);
    this.vx += (tx - this.vx) * k;
    this.vz += (tz - this.vz) * k;

    const r = physics.moveCharacter(this.entity, [this.vx * dt, -3 * dt, this.vz * dt]);
    // Stuck against a tree: slide sideways for a while.
    const wanted = Math.hypot(this.vx, this.vz) * dt;
    const got = Math.hypot(r.moved.x, r.moved.z);
    if (speedNow > 0 && wanted > 0.001 && got < wanted * 0.4) this.stuck += dt;
    else this.stuck = Math.max(0, this.stuck - dt);
    if (this.stuck > 0.5) {
      this.side = -this.side;
      this.stuck = 0;
      this.vx += -wantZ * 3 * this.side;
      this.vz += wantX * 3 * this.side;
    }

    const sp = Math.hypot(this.vx, this.vz);
    if (sp > 0.4 && this.mode === "run") this.yaw = turnToward(this.yaw, yawOf(this.vx, this.vz), 540 * dt);
    this.entity.get("Transform").rotation = [0, this.yaw, 0];
    this.anim?.set("speed", this.mode === "run" ? sp : 0);
  }

  onUpdate(dt) {
    if (!this.dead) return;
    // The body sinks into the ground and goes away.
    this.sink -= dt;
    const f = Math.max(0, this.sink / this.fadeTime);
    this.entity.get("Transform").scale = [this.baseScale.x * f, this.baseScale.y * f, this.baseScale.z * f];
    if (this.sink <= 0) this.entity.destroy();
  }

  startBite(dx, dz) {
    this.mode = "bite";
    this.timer = 0.6;
    this.cool = this.biteCooldown;
    this.yaw = yawOf(dx, dz);
    this.vx = this.vz = 0;
    this.anim?.trigger("bite");
  }

  /** The "wolf_bite_hit" clip event: the jaws close. Lands on the warden or on the fire, whichever is in reach. */
  biteLands() {
    if (this.dead || this.fleeing) return;
    const p = this.entity.position;
    const warden = world.find("warden");
    const wb = warden?.behaviour;
    if (wb && flatDistance(warden, p) <= this.reach + 0.7 && !wb.locked) {
      if (wb.hurt([p.x, p.z], this.damage)) {
        audio.play("assets/audio/wolf_bite.wav", { position: p, range: EARS, bus: "sfx", variants: 3, volume: 0.9 });
        return;
      }
    }
    const fire = behaviourOf("campfire");
    if (fire && Math.hypot(p.x, p.z) <= this.fireReach + 0.8) {
      fire.bite(this.fireBite);
      audio.play("assets/audio/wolf_bite.wav", { position: p, range: EARS, bus: "sfx", variants: 3, volume: 0.7 });
    }
  }

  /** The warden's torch (or anything else) hits: damage, a push away from `from` ([dx, dz] pointing at the wolf). */
  hurt(damage, from) {
    if (this.dead) return;
    this.hp -= damage;
    audio.play("assets/audio/wolf_hit.wav", { position: this.entity.position, range: EARS, bus: "sfx", variants: 4, volume: 0.9 });
    world.spawnPrefab("prefabs/puff.prefab.json", { position: [this.entity.position.x, 0.9, this.entity.position.z] });
    const d = Math.hypot(from[0], from[1]) || 1;
    this.vx = (from[0] / d) * this.knock;
    this.vz = (from[1] / d) * this.knock;
    if (this.hp <= 0) return this.die();
    this.mode = "stagger";
    this.timer = this.stagger;
    this.anim?.trigger("hurt");
    if (this.kind === "alpha" && !this.enraged && this.hp <= this.maxHp / 2) this.enrage();
  }

  /** The alpha at half its health: faster, a howl, and two wolves answer it from the forest. */
  enrage() {
    this.enraged = true;
    this.speed *= 1.3;
    this.biteCooldown *= 0.75;
    audio.play("assets/audio/alpha_howl.wav", { position: this.entity.position, bus: "sfx", volume: 1, range: 90 });
    world.emit("wolf_roar", { kind: this.kind });
    camera.shake(0.7, { duration: 0.5 }); // the engine's shake: trauma squared, smooth, off with reduce motion
    behaviourOf("game")?.callWolves(2);
  }

  die() {
    this.dead = true;
    this.entity.removeTag("wolf");
    this.entity.addTag("fallen");
    this.sink = this.fadeTime;
    this.anim?.trigger("hurt");
    // The pack loses heart when its leader falls: the warden gets a heart back.
    if (this.kind === "alpha") behaviourOf("warden")?.heal();
    world.emit("wolf_down", { kind: this.kind });
    world.spawnPrefab("prefabs/puff.prefab.json", { position: [this.entity.position.x, 0.6, this.entity.position.z] });
  }

  /** Dawn: it runs off. */
  flee() {
    this.fleeing = true;
    this.mode = "run";
  }
}
