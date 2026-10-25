// A bot that plays a floor like a player: it presses the keys of a keyboard scheme or pushes a gamepad's stick, and nothing else.
// It never moves a miner, never sets a player's state and never edits the map. What it knows is what the game's own modules
// know: the live map, the pathfinding (scripts/game/pathfinding.js, which follows digging), the enemies' public fields.
//
//   const bots = botsForAll();              // one MinerBot per player in the registry
//   const r = playFloor(bots, { frames: 6000 });   // steps the game until the shift ends or the frames run out
//   r.outcome  // "lift" | "dark" | "allDown" | "timeout"
//
// What one MinerBot does every frame (update):
//   1. Dodges: leaves the circle of the King's slam while it winds up, and steps out of the line of a charge.
//   2. Fights: an enemy within reach is faced and the dig button held (the pick swings at it); the King only while it is stunned or
//      winding up nothing, and at a distance a miner can leave in time.
//   3. Refuels: when the lamp is low it goes for the nearest oil can.
//   4. Walks to the goal (the exit lift, or the King while the lift is jammed) along a path that digs what blocks it and keeps
//      out of water, magma and cracked floor. Holds the dig button while the next tile of the path is solid.
// The device decides the input: a keyboard scheme gives eight directions, a gamepad gives a free stick.
import { game } from "factoria:test";
import * as players from "../../scripts/game/players.js";
import { live } from "../../scripts/game/mine_map.js";
import { run, lampOf } from "../../scripts/game/run_state.js";
import { navFor, PathFollower } from "../../scripts/game/pathfinding.js";
import { K, TILE } from "../../scripts/game/tiles.js";
import { SWING_REACH, HALF } from "../../scripts/game/miner.js";
import { STATS } from "../../scripts/game/enemy_brains.js";

/** Keys of the project's own actions (`{ kind: "any" }`): see factoria.json. */
const ANY_KEYS = { left: "A", right: "D", up: "W", down: "S", dig: "Space", torch: "T" };

const DT = 1 / 60;

/** The 16 directions the dodge tries. */
const DIRS16 = Array.from({ length: 16 }, (_, i) => ({ x: Math.cos((i * Math.PI) / 8), y: Math.sin((i * Math.PI) / 8) }));

export class MinerBot {
  /**
   * @param {number} playerId  A player of the registry (players.js).
   */
  constructor(playerId) {
    this.id = playerId;
    this.player = /** @type {import("../../scripts/game/players.js").Player} */ (players.get(playerId));
    if (!this.player) throw new Error(`bot: no player ${playerId} in the registry (players.add first).`);
    const d = this.player.device;
    this.keys = d.kind === "keys" ? players.KEY_SCHEMES[d.scheme] : d.kind === "any" ? ANY_KEYS : null;
    this.pad = d.kind === "pad" ? d.index : -1;
    this.held = new Set();
    this.dig = false;
    this.safe = null;
    this.risky = null;
    this.stuck = 0;
    this.blockedFor = 0;
    this.lastTile = { tx: -1, ty: -1 };
    this.status = "";
  }

  /** The miner entity of this bot's player, or null. */
  get entity() {
    return game.world.findByTag("miner").find((e) => e.behaviour && e.behaviour.playerId === this.id) ?? null;
  }

  /** Lets go of every key and the stick. */
  release() {
    this.apply(0, 0, false);
  }

  /** Presses what gives the move vector (x right, y up) and the dig button. */
  apply(x, y, dig) {
    if (this.keys) {
      const want = new Set();
      if (x < -0.3) want.add(this.keys.left);
      if (x > 0.3) want.add(this.keys.right);
      if (y > 0.3) want.add(this.keys.up);
      if (y < -0.3) want.add(this.keys.down);
      if (dig) want.add(this.keys.dig);
      for (const k of this.held) if (!want.has(k)) game.keyUp(k);
      for (const k of want) if (!this.held.has(k)) game.keyDown(k);
      this.held = want;
    } else if (this.pad >= 0) {
      const pad = game.gamepad(this.pad);
      pad.axis("LeftX", x);
      pad.axis("LeftY", y);
      if (dig && !this.dig) pad.press("A");
      if (!dig && this.dig) pad.release("A");
    }
    this.dig = dig;
  }

  /** The followers' search options: dig what a pick of this tier can; the danger tiles are walls (safe) or just expensive (risky). */
  followers() {
    const nav = navFor(live.map);
    const dig = { tier: run.upgrades.pickTier, cost: 3 };
    this.safe = new PathFollower(nav, { dig, dangerCost: Infinity });
    this.risky = new PathFollower(nav, { dig, dangerCost: 40 });
  }

  /**
   * One frame of play: reads the world, presses keys. Call before `game.step(1)`.
   * @param {number} [dt]
   */
  update(dt = DT) {
    const e = this.entity;
    const map = live.map;
    if (!e || !map || !run.inShift || this.player.state === "down" || this.player.state === "lift") {
      this.release();
      return;
    }
    if (!this.safe) this.followers();
    const p = e.position;
    const here = map.tileAt(p.x, p.y);
    const lamp = lampOf(this.id);

    // 1. the King's attacks
    const king = enemies().find((b) => b.kind === "king");
    if (king) {
      const kp = king.entity.position;
      const dist = Math.hypot(kp.x - p.x, kp.y - p.y);
      if (king.telegraphing === "slam" && dist < STATS.king.slamRadius + 26) return this.go(this.dodge(p, (c) => Math.hypot(c.x - kp.x, c.y - kp.y)), false, "slam");
      if (king.telegraphing === "charge" && king.chargeClock >= STATS.king.chargeWindup) {
        const v = king.chargeVec;
        const rel = { x: p.x - kp.x, y: p.y - kp.y };
        const along = rel.x * v.x + rel.y * v.y;
        const across = rel.x * -v.y + rel.y * v.x;
        if (along > -20 && Math.abs(across) < 34) return this.go(this.dodge(p, (c) => Math.abs((c.x - kp.x) * -v.y + (c.y - kp.y) * v.x)), false, "charge");
      }
    }

    // 2. an enemy in reach: face it and swing
    const foe = this.foe(p, king);
    if (foe) {
      const fp = foe.entity.position;
      const dx = fp.x - p.x, dy = fp.y - p.y;
      const d = Math.hypot(dx, dy) || 1;
      this.stuck = 0;
      // closer than the reach is enough; at the edge of the reach keep stepping in
      const inReach = d <= SWING_REACH + (foe.kind === "king" ? 8 : 0) - 4;
      return this.go(inReach ? { x: dx / d * 0.35, y: dy / d * 0.35 } : { x: dx / d, y: dy / d }, true, "fight");
    }

    // 3 and 4. where to
    let goal = live.mine.exit;
    if (run.exitLocked && king) goal = king.tile;
    const oil = lamp.oil < lamp.max * 0.4 && !lamp.out ? this.nearestOil(here) : lamp.out ? this.nearestOil(here) : null;
    if (oil) goal = oil;
    if (this.player.state === "active" && here.tx === goal.tx && here.ty === goal.ty && goal === live.mine.exit) {
      this.release();
      return;
    }
    let f = this.safe;
    let ok = f.goTo(here, goal, dt, 0.5);
    if (!ok) {
      this.blockedFor += dt;
      if (this.blockedFor > 3) {
        f = this.risky;
        ok = f.goTo(here, goal, dt, 0.5);
      }
    } else {
      this.blockedFor = 0;
    }
    if (!ok) {
      this.release();
      this.status = "blocked";
      return;
    }
    const dir = f.direction(p, 3);
    if (dir.done) {
      // standing on the goal tile of an oil path or still walking into the lift: push toward the centre of the goal
      const c = map.tileCenter(goal.tx, goal.ty);
      const dx = c.x - p.x, dy = c.y - p.y;
      const d = Math.hypot(dx, dy);
      return this.go(d > 1.5 ? { x: dx / d, y: dy / d } : { x: 0, y: 0 }, false, "arrive");
    }
    // walk along the axis of the next step and let the other axis centre the miner in the tunnel
    const tile = /** @type {{tx:number,ty:number}} */ (dir.tile);
    const c = map.tileCenter(tile.tx, tile.ty);
    const prev = f.path[Math.max(0, f.index - 1)];
    const pc = map.tileCenter(prev.tx, prev.ty);
    let ax = Math.sign(c.x - pc.x), ay = Math.sign(c.y - pc.y);
    if (ax === 0 && ay === 0) {
      ax = Math.sign(c.x - p.x);
      ay = Math.sign(c.y - p.y);
    }
    const lateralX = ax === 0 ? clampTo((c.x - p.x) / 5) : 0;
    const lateralY = ay === 0 ? clampTo((c.y - p.y) / 5) : 0;
    const solid = map.isSolid(tile.tx, tile.ty);
    this.go({ x: ax + lateralX, y: ay + lateralY }, solid, "walk");
    // a path that does not advance for a while is searched again
    if (here.tx === this.lastTile.tx && here.ty === this.lastTile.ty && !solid) {
      this.stuck += dt;
      if (this.stuck > 2) {
        f.clear();
        this.stuck = 0;
      }
    } else {
      this.stuck = 0;
    }
    this.lastTile = here;
  }

  /** Presses the move vector and the dig button. */
  go(v, dig, status) {
    this.status = status;
    this.apply(v.x, v.y, dig);
  }

  /** The direction (of 16) that moves the miner farthest from a threat, judged by `score(point)` (more is better), among those it can walk. */
  dodge(p, score) {
    const map = live.map;
    let best = { x: 0, y: 0 };
    let bestScore = -Infinity;
    for (const d of DIRS16) {
      const r = map.moveBox(p.x, p.y, HALF, HALF, d.x * 26, d.y * 26);
      const moved = Math.hypot(r.x - p.x, r.y - p.y);
      if (moved < 18) continue;
      const kind = map.kindAt(map.tileAt(r.x, r.y).tx, map.tileAt(r.x, r.y).ty);
      if (kind === K.WATER || kind === K.MAGMA || kind === K.SHAKY) continue;
      const s = score(r) + moved * 0.1;
      if (s > bestScore) {
        bestScore = s;
        best = d;
      }
    }
    return best;
  }

  /** The enemy this bot should fight now, or null. */
  foe(p, king) {
    let best = null, bestD = Infinity;
    for (const b of enemies()) {
      const ep = b.entity.position;
      const d = Math.hypot(ep.x - p.x, ep.y - p.y);
      if (b.kind === "king") {
        // only while it cannot slam: stunned, or winding up nothing
        if (!b.awake || b.telegraphing === "slam" || b.telegraphing === "charge") continue;
        if (b.stunLeft > 0.25 ? d > 120 : d > 40) continue;
      } else if (d > 40 || !lineClear(p, ep)) continue;
      if (d < bestD) {
        best = b;
        bestD = d;
      }
    }
    return best;
  }

  /** The nearest oil can by path cost, or null. */
  nearestOil(here) {
    const mine = live.mine;
    const nav = navFor(live.map);
    let best = null, bestCost = Infinity;
    for (let ty = 0; ty < mine.height; ty++) {
      for (let tx = 0; tx < mine.width; tx++) {
        if (live.map.kindAt(tx, ty) !== K.OIL) continue;
        if (Math.abs(tx - here.tx) + Math.abs(ty - here.ty) > 60) continue;
        const r = nav.findPath(here, { tx, ty }, { dig: { tier: run.upgrades.pickTier, cost: 3 }, maxNodes: 4000 });
        if (r.ok && r.cost < bestCost) {
          best = { tx, ty };
          bestCost = r.cost;
        }
      }
    }
    return best;
  }
}

function clampTo(v) {
  return Math.max(-0.7, Math.min(0.7, v));
}

/** True when no solid tile lies on the straight line between two world points (sampled every 4 units). */
function lineClear(a, b) {
  const map = live.map;
  const n = Math.ceil(Math.hypot(b.x - a.x, b.y - a.y) / 4);
  for (let i = 1; i < n; i++) {
    const t = map.tileAt(a.x + ((b.x - a.x) * i) / n, a.y + ((b.y - a.y) * i) / n);
    if (map.isSolid(t.tx, t.ty)) return false;
  }
  return true;
}

/** The behaviours of the enemies alive now. */
export function enemies() {
  return game.world
    .findByTag("enemy")
    .map((e) => e.behaviour)
    .filter((b) => b && !b.dead && b.stats);
}

/** One bot per player of the registry. */
export function botsForAll() {
  return players.all().map((p) => new MinerBot(p.id));
}

/**
 * Plays: every frame each bot reads the world and presses its keys, then the game steps one frame. Stops when the shift ends.
 * @param {MinerBot[]} bots
 * @param {{frames?: number, onFrame?: (frame: number) => void}} [opts]
 * @returns {{outcome: string, frames: number}}
 */
export function playFloor(bots, opts = {}) {
  const max = opts.frames ?? 6000;
  for (let f = 0; f < max; f++) {
    if (!run.inShift) {
      for (const b of bots) b.release();
      return { outcome: run.lastShift ? run.lastShift.outcome : "none", frames: f };
    }
    for (const b of bots) b.update(DT);
    opts.onFrame?.(f);
    game.step(1);
  }
  for (const b of bots) b.release();
  return { outcome: "timeout", frames: max };
}
