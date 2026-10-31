// @ts-check
// StoreBridge: sends the achievements and the counts of the trade (scripts/game/trade.js) to the store through `platform`.
//
// The game's own state is the truth (`trade.unlocked`, `trade.stats`, saved with the game); the store is told about it, best
// effort and one request after the other: a store that is down, a player who is not signed in or an exported game with no
// store plugin (backend "none") never stops the game. The ids are declared in factoria.json "platform" (the catalogue: names and
// descriptions come from locales/en.json, keys `achievement.<id>.name` / `.desc`).
//
// Nothing here waits for an answer that the game then acts on, so a result that arrives after the scene changed changes nothing;
// `destroy()` drops the listeners and later answers are ignored.
import { platform } from "factoria";

/** The stats of the catalogue and the bus event that raises each one: [stat id, event, amount from the payload]. */
export const STAT_EVENTS = [
  ["ships_docked", "trade.ship.docked", () => 1],
  ["orders_filled", "trade.order.filled", () => 1],
  ["orders_missed", "trade.order.missed", () => 1],
  ["events_resolved", "trade.choice", () => 1],
  ["coins_earned", "trade.order.filled", (e) => e.reward],
  ["stories_finished", "trade.story.finished", () => 1],
];

export class StoreBridge {
  /** @param {import("./state.js").GameState} state */
  constructor(state) {
    this.state = state;
    this.alive = true;
    this.chain = Promise.resolve();
    /** Requests sent so far (ids), for tests and the debug line. */
    this.sent = [];
    const ev = state.events;
    this.off = [ev.on("trade.achievement", (e) => this.unlock(e.id))];
    for (const [stat, event, amount] of STAT_EVENTS) this.off.push(ev.on(event, (e) => this.add(stat, amount(e))));
    // an achievement already unlocked in a restored game is told again: the store keeps the first time and ignores the rest
    this.off.push(ev.on("trade.restored", () => state.trade.unlocked.forEach((id) => this.unlock(id))));
  }

  unlock(id) {
    if (this.alive && platform.has("achievements")) this.run(`achievement:${id}`, () => platform.achievements.unlock(id));
  }

  add(stat, n) {
    if (this.alive && n > 0 && platform.has("stats")) this.run(`stat:${stat}`, () => platform.stats.add(stat, n));
  }

  run(label, fn) {
    this.sent.push(label);
    this.chain = this.chain.then(() => (this.alive ? fn() : undefined)).catch(() => {});
    return this.chain;
  }

  destroy() {
    this.alive = false;
    for (const off of this.off) off();
    this.off = [];
  }
}
