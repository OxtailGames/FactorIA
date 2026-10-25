// @ts-check
// One enemy: a beetle, a goblin thief or the Mole King (the `kind` prop). The thinking is a behaviour tree from
// enemy_brains.js; this script is its body and its blackboard: it senses the miners, walks along the tile paths of
// pathfinding.js (which follow every tunnel the miners dig), takes hits from the miners' picks (`hit`), and dies.
// Spawned by shift.js from `mine.enemies` with prefabs/enemy.prefab.json. Enemies are drawn only on tiles the fog shows.
import { Behaviour, world, audio, rng } from "factoria";
import * as events from "./events.js";
import * as players from "./players.js";
import { live } from "./mine_map.js";
import { navFor, PathFollower, lineOfSight } from "./pathfinding.js";
import { Tree } from "./behavior_tree.js";
import { STATS, beetleBrain, thiefBrain, kingBrain } from "./enemy_brains.js";
import { miners } from "./actors.js";
import { burst } from "./puff.js";
import { run, lampOf, totalOre } from "./run_state.js";
import { ORES, TILE, SPRITE, spriteRegion } from "./tiles.js";
import { CAVE_DAMAGE } from "./hazards.js";

/** Pick damage against an enemy: 1 plus the pick tier (a swing is miner.js). */
export function swingDamage(tier) {
  return 1 + tier;
}

const BRAINS = { beetle: beetleBrain, thief: thiefBrain, king: kingBrain };
const SPRITES = { beetle: SPRITE.BEETLE, thief: SPRITE.THIEF, king: SPRITE.KING };
const SIZES = { beetle: 16, thief: 16, king: 28 };
const BAR_W = 360;

export default class Enemy extends Behaviour {
  /** "beetle", "thief" or "king". */
  kind = "beetle";
  /** Tile it starts on. */
  tx = 0;
  ty = 0;

  onStart() {
    if (!(this.kind in STATS)) {
      console.warn(`enemy: unknown kind '${this.kind}': use beetle, thief or king (prefabs/enemy.prefab.json 'kind' prop).`);
      this.enabled = false;
      return;
    }
    this.stats = STATS[/** @type {"beetle"|"thief"|"king"} */ (this.kind)];
    const extra = this.kind === "king" ? Math.max(0, players.count() - 1) * STATS.king.hpPerExtraPlayer : 0;
    this.maxHp = this.stats.hp + extra;
    this.hp = this.maxHp;
    this.entity.set("Sprite", { region: spriteRegion(SPRITES[this.kind]), size: [SIZES[this.kind], SIZES[this.kind]] });
    this.sprite = this.entity.get("Sprite");
    this.shown = true;
    this.tint = "";
    this.map = /** @type {import("./mine_map.js").MineMap} */ (live.map);
    this.follower = new PathFollower(navFor(this.map), { maxNodes: 4000 });
    this.tree = new Tree(BRAINS[this.kind](), this);
    this.dead = false;
    // senses
    this.target = null;
    this.targetDist = Infinity;
    this.lastSeen = null;
    // state shared with the brains
    this.staggered = 0;
    this.stunLeft = 0;
    this.wanderTile = null;
    this.awake = this.kind !== "king";
    this.phase2 = false;
    this.carrying = null; // thief: {ore: {copper: n...}, count}
    this.safeFor = 0;
    this.fleeGoal = null;
    this.fleeAge = 0;
    this.dtLast = 0;
    this.flash = 0;
    this.telegraphing = null;
    this.slamClock = 0;
    this.chargeClock = 0;
    this.chargeLeft = 0;
    this.chargeVec = { x: 1, y: 0 };
    this.ring = null;
    this.bar = null;
    this.walkClock = 0;
    this.unsub = events.on("hazardTriggered", (e) => {
      if (this.dead || e.kind !== "caveIn" || e.phase !== "impact") return;
      const t = this.tile;
      if (Math.abs(t.tx - e.tx) <= 1 && Math.abs(t.ty - e.ty) <= 1) this.hit(this.kind === "king" ? CAVE_DAMAGE : 99, null);
    });
  }

  onDestroy() {
    this.unsub?.();
    this.ring?.destroy();
    this.bar?.forEach((e) => e.alive && e.destroy());
  }

  /** The tile the enemy stands on. */
  get tile() {
    const p = this.entity.position;
    return this.map.tileAt(p.x, p.y);
  }

  onUpdate(dt) {
    if (this.dead || !this.stats || !run.inShift) return;
    this.sense(dt);
    this.staggered = Math.max(0, this.staggered - dt);
    this.stunLeft = Math.max(0, this.stunLeft - dt);
    this.flash = Math.max(0, this.flash - dt);
    if (this.kind === "king" && this.awake && !this.phase2 && this.hp <= this.maxHp / 2) this.phase2 = true;
    this.tree.tick(dt);
    if (this.dead) return;
    this.draw(dt);
  }

  // ---- senses -----------------------------------------------------------------------------------------------------

  /** Finds the nearest miner in play that the enemy can see, remembers where it was, and times the thief's escape. */
  sense(dt) {
    const p = this.entity.position;
    const t = this.tile;
    let best = null, bestD = Infinity, nearest = Infinity;
    for (const m of miners()) {
      const d = Math.hypot(m.x - p.x, m.y - p.y);
      nearest = Math.min(nearest, d);
      if (d > this.stats.sight || d >= bestD) continue;
      if (!lineOfSight(this.map, t, { tx: m.tx, ty: m.ty })) continue;
      best = m;
      bestD = d;
    }
    this.target = best;
    this.targetDist = best ? bestD : Infinity;
    if (best) this.lastSeen = { tx: best.tx, ty: best.ty, age: 0 };
    else if (this.lastSeen) this.lastSeen.age += dt;
    const far = nearest > (this.stats.escapeDistance ?? Infinity);
    this.safeFor = !best && far ? this.safeFor + dt : 0;
  }

  // ---- moving -------------------------------------------------------------------------------------------------------

  /**
   * One step along the path to a tile.
   * @param {{tx:number,ty:number}} tile
   * @param {number} speed  World units per second.
   * @param {number} dt
   * @returns {"moving"|"arrived"|"blocked"}
   */
  walkTo(tile, speed, dt) {
    const here = this.tile;
    if (!this.follower.goTo(here, tile, dt)) return "blocked";
    const p = this.entity.position;
    const dir = this.follower.direction(p, 2.5);
    if (dir.done) return "arrived";
    this.step(dir.x * speed * dt, dir.y * speed * dt);
    this.walkClock += dt;
    return "moving";
  }

  /** Moves the body (stops at walls). Returns whether it moved at all. */
  step(dx, dy) {
    const p = this.entity.position;
    const half = this.stats.half;
    const moved = this.map.moveBox(p.x, p.y, half, half, dx, dy);
    const did = Math.abs(moved.x - p.x) + Math.abs(moved.y - p.y) > 1e-4;
    p.x = moved.x;
    p.y = moved.y;
    if (Math.abs(dx) > 0.01) this.sprite.flipX = dx < 0;
    return { did, hitX: moved.hitX, hitY: moved.hitY };
  }

  /** Chooses a tile to stroll to: a reachable one 2 to 6 steps away, by the world RNG. */
  pickWander() {
    const spots = navFor(this.map).reachable(this.tile, 6).filter((t) => t.d >= 2);
    this.wanderTile = spots.length > 0 ? spots[rng.int(0, spots.length - 1)] : null;
  }

  // ---- beetle -------------------------------------------------------------------------------------------------------

  /** The bite lands if the miner is still in reach: a heart, some lamp oil, and a shove. */
  bite() {
    const t = this.target;
    if (!t || this.targetDist > this.stats.biteRange + 4) return;
    if (!players.hurt(t.player.id, 1, "beetle")) return;
    const lamp = lampOf(t.player.id);
    lamp.oil = Math.max(0, lamp.oil - this.stats.biteOil);
    this.shove(t, 12);
    audio.play("assets/audio/bite.wav", { volume: 0.8, bus: "sfx" });
  }

  /** Pushes a miner away from this enemy. */
  shove(m, dist) {
    const p = this.entity.position;
    const d = Math.hypot(m.x - p.x, m.y - p.y) || 1;
    const mp = m.entity.position;
    const moved = this.map.moveBox(mp.x, mp.y, 5.5, 5.5, ((m.x - p.x) / d) * dist, ((m.y - p.y) / d) * dist);
    mp.x = moved.x;
    mp.y = moved.y;
  }

  /** Shows (or ends) the wind-up of an attack. For a beetle `on` is a boolean; for the King "slam", "charge" or null. */
  telegraph(on) {
    this.telegraphing = on || null;
    if (this.kind === "king") {
      if (on === "slam" && !this.ring) {
        this.ring = world.spawn({ components: { Transform: { position: [0, 0, 0] }, Shape2D: { shape: "circle", size: [4, 4], color: [1, 0.25, 0.2, 0.55], filled: false, thickness: 2, layer: 14 } } });
        audio.play("assets/audio/roar.wav", { volume: 0.7, bus: "sfx" });
      }
      if (on !== "slam" && this.ring) {
        this.ring.destroy();
        this.ring = null;
      }
    }
  }

  // ---- thief --------------------------------------------------------------------------------------------------------

  /** True when the team carries ore to steal. */
  canSteal() {
    return !this.carrying && totalOre() > 0;
  }

  /** Takes a quarter of the team's ore (at least one piece), piece by piece from a random kind. */
  steal() {
    const total = totalOre();
    if (total <= 0) return;
    const n = Math.max(1, Math.floor(total * this.stats.stealShare));
    /** @type {Record<string, number>} */
    const took = Object.fromEntries(ORES.map((o) => [o, 0]));
    for (let i = 0; i < n; i++) {
      const left = ORES.reduce((s, o) => s + run.ore[o], 0);
      if (left <= 0) break;
      let pick = rng.int(0, left - 1);
      for (const o of ORES) {
        if (pick < run.ore[o]) {
          run.ore[o]--;
          took[o]++;
          break;
        }
        pick -= run.ore[o];
      }
    }
    const count = ORES.reduce((s, o) => s + took[o], 0);
    this.carrying = { ore: took, count };
    const most = ORES.reduce((a, b) => (took[b] > took[a] ? b : a), ORES[0]);
    const t = this.tile;
    events.emit("oreStolen", { ore: most, count, tx: t.tx, ty: t.ty });
    audio.play("assets/audio/steal.wav", { volume: 0.8, bus: "sfx" });
    this.lastSeen = null;
  }

  /** A tile to run to: the reachable one (within 14 steps) farthest from the nearest miner. */
  fleeTile() {
    const t = this.tile;
    if (this.fleeGoal && this.fleeAge < 1 && !(t.tx === this.fleeGoal.tx && t.ty === this.fleeGoal.ty)) {
      this.fleeAge += this.dtLast;
      return this.fleeGoal;
    }
    const ms = miners();
    const spots = navFor(this.map).reachable(this.tile, 14);
    let best = null, bestScore = -Infinity;
    for (const s of spots) {
      const near = ms.length > 0 ? Math.min(...ms.map((m) => Math.abs(m.tx - s.tx) + Math.abs(m.ty - s.ty))) : 0;
      const score = near * 2 + s.d * 0.5;
      if (score > bestScore) {
        best = s;
        bestScore = score;
      }
    }
    this.fleeGoal = best;
    this.fleeAge = 0;
    return best;
  }

  /** The thief gets away with the ore: it is gone for good. */
  escape() {
    if (!this.carrying) return;
    const c = this.carrying;
    const most = ORES.reduce((a, b) => (c.ore[b] > c.ore[a] ? b : a), ORES[0]);
    events.emit("thiefEscaped", { ore: most, count: c.count });
    this.carrying = null;
    this.dead = true;
    this.entity.destroy();
  }

  // ---- the King -----------------------------------------------------------------------------------------------------

  /** True (and the fight starts) when a miner is in sight. */
  wake() {
    if (!this.target) return false;
    this.awake = true;
    const t = this.tile;
    events.emit("bossStarted", { tx: t.tx, ty: t.ty, hp: this.hp });
    audio.play("assets/audio/roar.wav", { volume: 0.9, bus: "sfx" });
    this.showBar();
    return true;
  }

  showBar() {
    if (this.bar) return;
    const back = world.spawn({ components: { Transform: { position: [0, -40, 0] }, Shape2D: { shape: "rectangle", size: [BAR_W + 6, 18], color: [0, 0, 0, 0.7], pivot: [0.5, 1], space: "screen", anchor: [0.5, 1], layer: 212 } } });
    const fill = world.spawn({ components: { Transform: { position: [-BAR_W / 2, -43, 0] }, Shape2D: { shape: "rectangle", size: [BAR_W, 12], color: [0.85, 0.2, 0.2, 1], pivot: [0, 1], space: "screen", anchor: [0.5, 1], layer: 213 } } });
    this.bar = [back, fill];
  }

  /** Everyone in the slam circle goes down. */
  slamStrike() {
    const p = this.entity.position;
    for (const m of miners()) {
      if (m.player.state !== "active") continue;
      if (Math.hypot(m.x - p.x, m.y - p.y) <= this.stats.slamRadius) players.setState(m.player.id, "down", "king");
    }
    audio.play("assets/audio/crash.wav", { volume: 0.9, bus: "sfx" });
    burst(p.x, p.y, [0.7, 0.55, 0.4, 1], { count: 12, speed: 70 });
  }

  /** Aims the charge at the target (called during the wind-up, the last call wins). */
  chargeDir() {
    if (!this.target) return;
    const p = this.entity.position;
    const d = Math.hypot(this.target.x - p.x, this.target.y - p.y) || 1;
    this.chargeVec = { x: (this.target.x - p.x) / d, y: (this.target.y - p.y) / d };
    this.chargeLeft = this.stats.chargeLength;
  }

  /** One step of the charge: "going", "blocked" (hit a wall) or "done" (ran its length). */
  chargeStep(dt) {
    const S = this.stats;
    const len = Math.min(this.chargeLeft, S.chargeSpeed * dt);
    const r = this.step(this.chargeVec.x * len, 0);
    const r2 = this.step(0, this.chargeVec.y * len);
    this.chargeLeft -= len;
    const p = this.entity.position;
    for (const m of miners()) {
      if (m.player.state !== "active") continue;
      if (Math.hypot(m.x - p.x, m.y - p.y) <= S.chargeHit && players.hurt(m.player.id, 1, "king")) this.shove(m, 16);
    }
    if ((r.hitX && Math.abs(this.chargeVec.x) > 0.3) || (r2.hitY && Math.abs(this.chargeVec.y) > 0.3)) {
      burst(p.x, p.y, [0.7, 0.7, 0.75, 1], { count: 8, speed: 60 });
      audio.play("assets/audio/crash.wav", { volume: 0.7, bus: "sfx" });
      return "blocked";
    }
    return this.chargeLeft <= 0 ? "done" : "going";
  }

  // ---- being hit ----------------------------------------------------------------------------------------------------

  /**
   * A pick (or a cave-in) hurts the enemy.
   * @param {number} damage
   * @param {{x:number,y:number,id?:number}|null} from  Where the blow came from (it shoves the enemy away), or null.
   * @param {number|null} [by]  Player id.
   */
  hit(damage, from, by = null) {
    if (this.dead) return;
    this.hp -= damage;
    this.flash = 0.15;
    const p = this.entity.position;
    if (from && this.kind !== "king") {
      const d = Math.hypot(p.x - from.x, p.y - from.y) || 1;
      this.step(((p.x - from.x) / d) * 6, ((p.y - from.y) / d) * 6);
      this.staggered = 0.25;
    }
    const t = this.tile;
    events.emit("enemyHit", { kind: this.kind, tx: t.tx, ty: t.ty, by, hp: Math.max(0, this.hp) });
    burst(p.x, p.y, this.kind === "king" ? [0.7, 0.5, 0.35, 1] : [0.45, 0.8, 0.3, 1], { count: 4, speed: 36 });
    if (this.hp <= 0) this.defeat(by);
  }

  defeat(by) {
    this.dead = true;
    const t = this.tile;
    const p = this.entity.position;
    if (this.carrying) {
      for (const o of ORES) run.ore[o] += this.carrying.ore[o];
      const most = ORES.reduce((a, b) => (this.carrying.ore[b] > this.carrying.ore[a] ? b : a), ORES[0]);
      events.emit("oreRecovered", { ore: most, count: this.carrying.count, by });
      this.carrying = null;
    }
    events.emit("enemyDefeated", { kind: this.kind, tx: t.tx, ty: t.ty, by });
    burst(p.x, p.y, [0.9, 0.85, 0.5, 1], { count: this.kind === "king" ? 16 : 8, speed: this.kind === "king" ? 80 : 50 });
    audio.play(this.kind === "king" ? "assets/audio/defeat.wav" : "assets/audio/crash.wav", { volume: 0.9, bus: "sfx" });
    if (this.kind === "king") {
      run.exitLocked = false;
      events.emit("bossDefeated", { by });
    }
    this.entity.destroy();
  }

  // ---- drawing --------------------------------------------------------------------------------------------------------

  /** Tint, visibility under the fog, the slam ring and the boss bar. */
  draw(dt) {
    const t = this.tile;
    const visible = !live.fog || live.fog.isVisible(t.tx, t.ty);
    let tint = "1,1,1,1";
    if (this.flash > 0) tint = "1,0.4,0.4,1";
    else if (this.telegraphing === true || this.telegraphing === "charge") tint = "1,0.55,0.25,1";
    else if (this.stunLeft > 0) tint = "0.65,0.7,1,1";
    else if (this.carrying) tint = "1,0.95,0.5,1";
    const key = `${visible}|${tint}`;
    if (key !== this.tint) {
      this.tint = key;
      const c = tint.split(",").map(Number);
      this.entity.set("Sprite", { color: [c[0], c[1], c[2], visible ? 1 : 0] });
    }
    if (this.ring) {
      const k = Math.min(1, this.slamClock / this.stats.slamWindup);
      this.ring.position = [this.entity.position.x, this.entity.position.y, 0];
      this.ring.set("Shape2D", { size: [this.stats.slamRadius * 2 * (0.3 + 0.7 * k), this.stats.slamRadius * 2 * (0.3 + 0.7 * k)], color: [1, 0.25, 0.2, visible ? 0.35 + 0.5 * k : 0] });
    }
    if (this.bar) {
      const f = Math.max(0, this.hp / this.maxHp);
      this.bar[1].set("Shape2D", { size: [Math.max(1, Math.round(BAR_W * f)), 12] });
    }
    this.dtLast = dt;
  }
}
