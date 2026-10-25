// @ts-check
// The brains of the three enemies, as behaviour trees (`bt` from "factoria"). Each `...Brain()` returns the root node; enemy.js
// gives it to a `Tree` together with a BLACKBOARD, the enemy itself. A brain only reads and calls what the blackboard offers,
// so a test can drive a brain with a plain fake object and no scene. The contract of the blackboard, per brain:
//
// Every enemy (set before each tick by enemy.js):
//   bb.target        the nearest miner in play that the enemy sees (a record of actors.js) or null
//   bb.targetDist    its distance in world units (Infinity without a target)
//   bb.lastSeen      {tx, ty, age} of the last place a miner was seen (age in seconds) or null
//   bb.stats         the entry of STATS below for this kind
//   bb.walkTo(tile, speed, dt)  one step along a path to the tile: "moving" | "arrived" | "blocked"
//   bb.pickWander()  chooses a tile to stroll to (a reachable one near the enemy), stored in bb.wanderTile
//   bb.wanderTile    {tx, ty} or null
//   bb.staggered     seconds left of the stagger after a hit (it stands still while it is above 0)
// Beetle:  bb.bite() deals the bite (hurt + lamp oil + knockback to the target if still in reach), bb.telegraph(on) shows the wind-up.
// Thief:   bb.carrying (ore taken), bb.canSteal() (the team carries ore), bb.steal(), bb.fleeTile(), bb.safeFor (seconds out of
//          sight and far away), bb.escape().
// King:    bb.awake, bb.wake() (true when a miner came within sight: starts the fight), bb.stunLeft, bb.phase2, bb.telegraph(kind|null),
//          bb.slamStrike(), bb.chargeDir(), bb.chargeStep(dt) ("going" | "blocked" | "done").
//
// A sequence that is RUNNING resumes at its running child without asking its conditions again (the engine's `bt`), so an action
// that follows a `condition(bb.target)` checks `bb.target` itself.
//
// Numbers (world units are 1/16 tile; speeds per second) live in STATS so a designer finds them in one place.
import { bt } from "factoria";

const { SUCCESS, FAILURE, RUNNING, sequence, selector, condition, action, wait, cooldown } = bt;

export const STATS = Object.freeze({
  beetle: {
    hp: 3, half: 5, sight: 112, patrolSpeed: 26, chaseSpeed: 52,
    biteRange: 15, biteWindup: 0.45, biteCooldown: 1.4, biteOil: 10, bruteHp: 1,
  },
  thief: {
    hp: 2, half: 5, sight: 128, wanderSpeed: 30, approachSpeed: 58, fleeSpeed: 62,
    stealRange: 14, stealShare: 0.25, escapeAfter: 3, escapeDistance: 176,
  },
  king: {
    hp: 10, hpPerExtraPlayer: 4, half: 9, sight: 144, wakeRange: 144, chaseSpeed: 30,
    slamTrigger: 56, slamRadius: 42, slamWindup: 0.9, slamStun: 2.2, slamCooldown: 3.5,
    chargeMinDist: 64, chargeMaxDist: 176, chargeWindup: 0.6, chargeSpeed: 170, chargeLength: 150, chargeStun: 1.2, chargeCooldown: 6, chargeHit: 14,
  },
});

/** Stays where it is while staggered by a hit. The action asks the question itself: a RUNNING sequence does not ask its condition again. */
const staggered = action((bb) => (bb.staggered > 0 ? RUNNING : FAILURE));

/** Walk to bb.wanderTile (picked on entering), then rest a moment. A tile that cannot be reached counts as done. */
function wander(speedOf) {
  return selector(
    sequence(
      action((bb, dt) => {
        if (!bb.wanderTile) return FAILURE;
        const r = bb.walkTo(bb.wanderTile, speedOf(bb), dt);
        return r === "moving" ? RUNNING : r === "arrived" ? SUCCESS : FAILURE;
      }, { onEnter: (bb) => bb.pickWander() }),
      wait(0.8),
    ),
    wait(0.5),
  );
}

/**
 * Beetle: patrols; when it sees a miner it chases; in reach it winds up (0.45 s, it flashes) and bites, then cannot bite
 * for 1.4 s; when it loses the miner it goes to the last place it saw one, then patrols again. A hit staggers it.
 */
export function beetleBrain() {
  const S = STATS.beetle;
  return selector(
    staggered,
    sequence(
      condition((bb) => bb.target && bb.targetDist <= S.biteRange),
      cooldown(S.biteCooldown, action((bb, dt) => {
        bb.biteClock = (bb.biteClock ?? 0) + dt;
        if (bb.biteClock < S.biteWindup) return RUNNING;
        bb.bite();
        return SUCCESS;
      }, { onEnter: (bb) => { bb.biteClock = 0; bb.telegraph(true); }, onExit: (bb) => bb.telegraph(false) })),
    ),
    sequence(
      condition((bb) => bb.target),
      action((bb, dt) => (!bb.target || bb.walkTo({ tx: bb.target.tx, ty: bb.target.ty }, S.chaseSpeed, dt) === "blocked" ? FAILURE : RUNNING)),
    ),
    sequence(
      condition((bb) => bb.lastSeen && bb.lastSeen.age < 5),
      action((bb, dt) => {
        if (!bb.lastSeen) return FAILURE;
        const r = bb.walkTo(bb.lastSeen, S.chaseSpeed * 0.7, dt);
        if (r === "moving") return RUNNING;
        bb.lastSeen = null;
        return SUCCESS;
      }),
    ),
    wander(() => S.patrolSpeed),
  );
}

/**
 * Goblin thief: strolls; when it sees a miner and the team carries ore it sneaks up, and in reach it takes a quarter of the
 * ore (at least one piece). Then it runs from the miners, a little slower than they walk, and escapes with the loot after
 * three seconds out of sight and far away. Killed, it drops the ore back to the team.
 */
export function thiefBrain() {
  const S = STATS.thief;
  return selector(
    staggered,
    sequence(
      condition((bb) => bb.carrying),
      selector(
        sequence(condition((bb) => bb.safeFor >= S.escapeAfter), action((bb) => { bb.escape(); return SUCCESS; })),
        action((bb, dt) => {
          const t = bb.fleeTile();
          if (t) bb.walkTo(t, S.fleeSpeed, dt);
          return RUNNING;
        }),
      ),
    ),
    sequence(
      condition((bb) => bb.target && bb.canSteal()),
      selector(
        sequence(condition((bb) => bb.targetDist <= S.stealRange), action((bb) => { bb.steal(); return SUCCESS; })),
        action((bb, dt) => (!bb.target || !bb.canSteal() || bb.walkTo({ tx: bb.target.tx, ty: bb.target.ty }, S.approachSpeed, dt) === "blocked" ? FAILURE : RUNNING)),
      ),
    ),
    wander(() => S.wanderSpeed),
  );
}

/**
 * Mole King: waits until a miner comes within sight, then walks at the nearest miner. Close to one it slams: it rears up
 * (0.9 s, a red circle grows), then every miner inside the circle is put down, and it is stunned 2.2 s. Under half its health it also
 * charges: a straight run at the miner, after a short wind-up, that hurts whoever it touches and stuns it if it hits a wall.
 */
export function kingBrain() {
  const S = STATS.king;
  return sequence(
    condition((bb) => bb.awake || bb.wake()),
    selector(
      action((bb) => (bb.stunLeft > 0 ? RUNNING : FAILURE)), // stunned: stands still (it asks itself, see the note above)
      sequence(
        condition((bb) => bb.phase2 && bb.target && bb.targetDist >= S.chargeMinDist && bb.targetDist <= S.chargeMaxDist),
        cooldown(S.chargeCooldown, action((bb, dt) => {
          bb.chargeClock += dt;
          if (bb.chargeClock < S.chargeWindup) {
            bb.chargeDir();
            return RUNNING;
          }
          const r = bb.chargeStep(dt);
          if (r === "going") return RUNNING;
          if (r === "blocked") bb.stunLeft = S.chargeStun;
          return SUCCESS;
        }, { onEnter: (bb) => { bb.chargeClock = 0; bb.telegraph("charge"); }, onExit: (bb) => bb.telegraph(null) })),
      ),
      sequence(
        condition((bb) => bb.target && bb.targetDist <= S.slamTrigger),
        cooldown(S.slamCooldown, action((bb, dt) => {
          bb.slamClock += dt;
          if (bb.slamClock < S.slamWindup) return RUNNING;
          bb.slamStrike();
          bb.stunLeft = S.slamStun;
          return SUCCESS;
        }, { onEnter: (bb) => { bb.slamClock = 0; bb.telegraph("slam"); }, onExit: (bb) => bb.telegraph(null) })),
      ),
      sequence(
        condition((bb) => bb.target),
        action((bb, dt) => {
          if (!bb.target) return FAILURE; // a running action is not asked its condition again: it must notice the miner is gone
          bb.walkTo({ tx: bb.target.tx, ty: bb.target.ty }, S.chaseSpeed, dt);
          return RUNNING;
        }),
      ),
      action(() => RUNNING),
    ),
  );
}

export { SUCCESS, FAILURE, RUNNING };
