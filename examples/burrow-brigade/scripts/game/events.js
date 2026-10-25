// @ts-check
// The game events bus: how the packages of Burrow Brigade tell each other what happened, without importing each other.
// A module-level bus (not `world.emit`): listeners survive a scene load until they unsubscribe or `clear()` runs, so a
// behaviour subscribes in `onStart` and unsubscribes in `onDestroy`, and `startRun` (run_state.js) clears the bus.
// Handlers run at once, in the order they subscribed, inside `emit`. A handler that throws is logged and the others
// still run. Names are checked, so a typo fails with a "did you mean".

/**
 * Every event, with the fields of its data. The ones marked (P1) and (P2) are emitted today; the "reserved" ones are names
 * that later packages emit, so a listener written today does not need changing then.
 */
export const EVENTS = Object.freeze({
  shiftStarted: "(P1) { seed, stratum, floor, hash, players }: the mine was built and the miners stand next to the start lift.",
  dug: "(P1) { tx, ty, from, by }: a tile was dug (`from` is the kind it had, `by` the player id or null).",
  digBlocked: "(P1) { tx, ty, kind, reason, by }: the pick cannot dig it; reason is \"tier\" or \"bedrock\".",
  orePicked: "(P1) { ore, value, by, total }: ore went into a miner's pocket (`total` is the pieces carried).",
  oilPicked: "(P1) { tx, ty, by, oil }: an oil can refilled a lamp.",
  lampLow: "(P1) { player, oil }: a lamp fell under a quarter of its oil.",
  lampOut: "(P1) { player }: a lamp ran dry.",
  liftReached: "(P1) { player }: a miner stepped on the exit lift.",
  moleRescued: "(P1) { tx, ty, by, rescued, total }: a trapped mole was reached and freed.",
  shiftEnded: "(P1) { outcome, ore, oreCount, value, banked, time, molesRescued, molesTotal, shiftNumber } (the ShiftSummary of run_state.js): outcome is \"lift\", \"dark\" or \"allDown\" (every miner is down).",
  playerAdded: "(P1) { player }: a player joined the registry.",
  playerRemoved: "(P1) { player }: a player left the registry.",
  playerState: "(P1) { player, from, to }: a player's state changed.",
  playerDown: "(P1, emitted by setState) { player, cause }: a player went down; `cause` is \"drowned\", \"burned\", \"caveIn\", \"beetle\", \"king\" or \"unknown\".",
  tileChanged: "(P1) { tx, ty, from, to, cause }: any tile changed; the same notice `MineMap.onChange` gives.",
  upgradeBought: "(reserved, P4) { upgrade, level, cost }",
  cashChanged: "(reserved, P4) { cash, delta }",
  hazardTriggered: "(P2) { kind, tx, ty, phase, player?, tiles? }: a hazard did something. kind is \"flood\", \"magma\" or \"caveIn\"; phase is \"start\" (a pocket was opened and began to spread, or a miner stepped on a cracked tile and the roof began to rumble), \"spread\" (water or magma took `tiles` more floor tiles), \"impact\" (the rocks of a cave-in fell on the 3 x 3 tiles around tx, ty) or \"hit\" (it put miner `player` down).",
  playerHurt: "(P2) { player, hp, cause }: a beetle bite or a charge took a heart (`hp` is what is left; at 0 `playerDown` follows).",
  thiefEscaped: "(P2) { ore, count }: a goblin thief got away with the ore it stole; that ore is gone from the shift.",
  torchPlaced: "(P2) { tx, ty, by, left }: a miner put a torch down (`left` is the team's torches still unused).",
  enemyHit: "(P2) { kind, tx, ty, by, hp }: a pick swing hurt an enemy (`hp` is what it has left).",
  enemyDefeated: "(P2) { kind, tx, ty, by }: an enemy was killed.",
  oreStolen: "(P2) { ore, count, tx, ty }: a goblin thief took ore from the team's pockets (`ore` is the kind most taken).",
  oreRecovered: "(P2) { ore, count, by }: ore came back (a thief was killed, or a miner picked up what it dropped).",
  bossStarted: "(P2) { tx, ty, hp }: a miner came within sight of the Mole King and the fight began.",
  bossDefeated: "(P2) { by }: the Mole King fell; the exit lift is free.",
  exitJammed: "(P2) { player }: a miner stepped on the exit lift while the Mole King still lives.",
  achievementUnlocked: "(P5) { id, name }: an achievement was unlocked for the first time (trophies.js); `name` is its name in the current language.",
  boardPosted: "(P5) { board, score, period }: a score went to a leaderboard (boards.js); `board` is \"best_run_cash\" or \"daily_run_cash\".",
});

/** @type {Map<string, Array<(data: any) => void>>} */
const listeners = new Map();
/** Listeners that `clear()` keeps (see `keep`).
 * @type {Map<string, Array<(data: any) => void>>} */
const kept = new Map();
/** The last events, newest last (kept for tests and for the debug overlay of later packages). */
export const history = [];
const HISTORY_MAX = 200;

function edit(a, b) {
  const row = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    let prev = row[0];
    row[0] = i;
    for (let j = 1; j <= b.length; j++) {
      const cur = row[j];
      row[j] = Math.min(row[j] + 1, row[j - 1] + 1, prev + (a[i - 1] === b[j - 1] ? 0 : 1));
      prev = cur;
    }
  }
  return row[b.length];
}

function check(name) {
  if (name in EVENTS) return;
  const names = Object.keys(EVENTS);
  const near = names.filter((n) => edit(n.toLowerCase(), String(name).toLowerCase()) <= 3).slice(0, 3);
  throw new Error(`unknown game event '${name}'. ${near.length ? `Did you mean ${near.map((n) => `'${n}'`).join(" or ")}? ` : ""}The events are: ${names.join(", ")} (scripts/game/events.js).`);
}

/**
 * Subscribes. Returns the function that unsubscribes.
 * @param {string} name
 * @param {(data: any) => void} fn
 */
export function on(name, fn) {
  check(name);
  if (!listeners.has(name)) listeners.set(name, []);
  /** @type {Array<(data: any) => void>} */ (listeners.get(name)).push(fn);
  return () => {
    const list = listeners.get(name);
    if (list && list.includes(fn)) list.splice(list.indexOf(fn), 1);
  };
}

/**
 * Tells everyone who listens, now.
 * @param {string} name
 * @param {object} [data]
 */
export function emit(name, data = {}) {
  check(name);
  history.push({ name, data });
  if (history.length > HISTORY_MAX) history.shift();
  for (const fn of [...(kept.get(name) ?? []), ...(listeners.get(name) ?? [])]) {
    try {
      fn(data);
    } catch (e) {
      console.error(`a '${name}' listener threw: ${e && e.message ? e.message : e}`);
    }
  }
}

/** How many times an event was emitted since the last `clear()` (a test helper). */
export function count(name) {
  check(name);
  return history.filter((h) => h.name === name).length;
}

/** The data of every emission of an event since the last `clear()`, oldest first. */
export function emitted(name) {
  check(name);
  return history.filter((h) => h.name === name).map((h) => h.data);
}

/**
 * Subscribes for good: unlike `on`, a `keep` listener survives `clear()` (so `startRun` does not drop it). For the services that
 * outlive runs and scenes (achievements, rich presence, analytics: P5). Returns the function that unsubscribes.
 * @param {string} name
 * @param {(data: any) => void} fn
 */
export function keep(name, fn) {
  check(name);
  if (!kept.has(name)) kept.set(name, []);
  /** @type {Array<(data: any) => void>} */ (kept.get(name)).push(fn);
  return () => {
    const list = kept.get(name);
    if (list && list.includes(fn)) list.splice(list.indexOf(fn), 1);
  };
}

/** Drops every listener (but the `keep` ones) and the history. `startRun` calls it, so a left-over listener never hears the next run. */
export function clear() {
  listeners.clear();
  history.length = 0;
}
