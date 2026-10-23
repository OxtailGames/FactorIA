// @ts-check
// The store services of the game: achievements, stats and leaderboards fed by the game events, the purchases that arrive by
// themselves and the paint on the robot. One entity "store_services" with this script lives in every scene that needs it; the
// level flow (scripts/level_flow.js) and the title screen (scripts/main_menu.js) spawn it, so no scene file has to list it.
// Nothing here changes how a level plays: it only listens (events: scripts/events.js).
//
// What counts for what (the catalog is factoria.json "platform"; texts are the keys ach.<id>.name / ach.<id>.desc):
//   events                                       stat (+1)             achievements
//   parcel_delivered                             parcels_delivered     first_delivery, extra_mile (a bonus parcel)
//   level_completed                              levels_won            rooftops_done, market_done, star_collector (9 stars),
//                                                                      all_stars (18), clean_run (no catch), last_second (<5 s left),
//                                                                      quick_courier (par time); leaderboards time_<level>, total_stars
//   courier_caught / level_failed / dog_gave_up  times_caught / springs_run_down / dogs_shaken   dog_whisperer (5 dogs)
//   spring_wound                                 keys_wound
//   shortcut_found (zones: scripts/shortcuts.js) shortcuts_found       first_shortcut, all_shortcuts (every zone, any attempt)
//   daily_route_finished (P3)                    -                     daily_courier; leaderboard daily_route (period "daily":
//                                                                      the engine keeps one board per calendar day)
//   paint_equipped (the shop)                    -                     fresh_paint (any paint but the factory one)
//   more_time_granted (scripts/more_time.js)     more_time_used
//
// The save (storage "services") is the source of truth: { version, ach: {id: true}, stats: {id: n}, shortcuts: [zone ids],
// outbox: [call...] }. Every unlock, stat and score is also sent to the platform; a call that fails (signed out, network)
// stays in the outbox and is sent again when the player signs in or at the next start. So the game never loses an unlock
// because the store was away, and the achievements screen can always show the local state.
import { Behaviour, world, platform, storage, session, i18n } from "factoria";
import { EVENTS, emit } from "./events.js";
import * as levels from "./levels.js";
import * as progress from "./progress.js";
import * as shortcuts from "./shortcuts.js";
import * as store from "./store.js";
import * as paints from "./paints.js";
import { Toasts } from "./ui/toast.js";

const KEY = "services";

/** Ids of the achievements of factoria.json platform.achievements, in the order of the achievements screen. */
export const ACHIEVEMENTS = [
  "first_delivery", "rooftops_done", "market_done", "star_collector", "all_stars", "clean_run", "last_second", "quick_courier",
  "extra_mile", "first_shortcut", "all_shortcuts", "dog_whisperer", "daily_courier", "fresh_paint",
];
export const STATS = ["levels_won", "parcels_delivered", "times_caught", "springs_run_down", "dogs_shaken", "keys_wound", "shortcuts_found", "more_time_used"];
/** Dogs that must give up the chase for "Dog Whisperer". */
export const DOGS_FOR_WHISPERER = 5;
/** Stars of the two star achievements. */
export const STARS_COLLECTOR = 9;
export const STARS_ALL = 18;

/** @returns {{ version: number, ach: Record<string, boolean>, stats: Record<string, number>, shortcuts: string[], outbox: any[] }} */
export function load() {
  const s = storage.get(KEY, null);
  const o = s && typeof s === "object" ? s : {};
  return {
    version: 1,
    ach: o.ach && typeof o.ach === "object" ? { ...o.ach } : {},
    stats: o.stats && typeof o.stats === "object" ? { ...o.stats } : {},
    shortcuts: Array.isArray(o.shortcuts) ? [...o.shortcuts] : [],
    outbox: Array.isArray(o.outbox) ? [...o.outbox] : [],
  };
}

export function reset() {
  storage.remove(KEY);
}

/** True when the achievement is unlocked in the local save. */
export function isUnlocked(id) {
  return load().ach[id] === true;
}

/** The local value of a stat. */
export function stat(id) {
  return load().stats[id] ?? 0;
}

/** The leaderboard id of a level's best time. */
export function timeBoard(levelId) {
  return `time_${levelId}`;
}

/** The service entity of the running scene, or null. */
export function current() {
  return world.find("store_services")?.behaviour ?? null;
}

/** Spawns the service entity when the scene has none (called by the level flow and the title screen). */
export function ensure() {
  if (world.find("store_services")) return;
  world.spawn({ id: "store_services", components: { Script: { path: "scripts/services.js" } } });
}

export default class StoreServices extends Behaviour {
  onStart() {
    this.toasts = new Toasts();
    /** The attempt in progress: reset by level_started. */
    this.attempt = { level: session.currentLevel ?? "", caught: false, delivered: 0, found: new Set(), continued: false };
    /** @type {Promise<any>} */
    this.flushing = Promise.resolve();
    this.offs = [
      world.on(EVENTS.levelStarted, (d) => this.onLevelStarted(d)),
      world.on(EVENTS.courierCaught, () => {
        this.attempt.caught = true;
        this.bump("times_caught");
      }),
      world.on(EVENTS.parcelDelivered, (d) => this.onDelivered(d)),
      world.on(EVENTS.springWound, () => this.bump("keys_wound")),
      world.on(EVENTS.levelFailed, () => this.bump("springs_run_down")),
      world.on(EVENTS.dogGaveUp, () => this.onDogGaveUp()),
      world.on(EVENTS.levelCompleted, (d) => this.onCompleted(d)),
      world.on(EVENTS.shortcutFound, (d) => this.onShortcut(d)),
      world.on(EVENTS.dailyRouteFinished, (d) => this.onDaily(d)),
      world.on(EVENTS.paintEquipped, (d) => {
        if (d.paint !== paints.DEFAULT_PAINT) this.unlock("fresh_paint");
        this.paintCourier();
      }),
      world.on(EVENTS.moreTimeGranted, () => {
        this.attempt.continued = true;
        this.bump("more_time_used");
      }),
      store.listen((p) => this.toasts.show(i18n.t("shop.granted", { name: i18n.has(`shop.product.${p.productId}`) ? i18n.t(`shop.product.${p.productId}`) : p.productId }))),
      platform.on("player", (p) => p.signedIn && this.flush()),
    ];
    this.paintCourier();
    // Sign in (the fake store starts signed out), grant the purchases the store lists, send what could not be sent before.
    this.boot();
  }

  onDestroy() {
    for (const off of this.offs ?? []) off();
  }

  async boot() {
    try {
      await platform.signIn();
    } catch (e) {
      /* signed out: the game plays on, the outbox waits */
    }
    await store.reconcile().catch(() => {});
    await this.flush();
  }

  onUpdate(dt) {
    this.toasts.update(dt);
    const a = this.attempt;
    if (!a.level || !shortcuts.ZONES[a.level]) return;
    const courier = world.find("courier");
    if (!courier) return;
    const zone = shortcuts.inside(a.level, courier.position);
    if (zone && !a.found.has(zone.id)) {
      a.found.add(zone.id);
      emit(EVENTS.shortcutFound, { level: a.level, shortcut: zone.id });
    }
  }

  // ------------------------------------------------------------------------------------------------------ the robot
  /** Puts the equipped paint on the courier's model (levels) . The title robot does it in scripts/ui/shop.js. */
  paintCourier() {
    const model = world.find("courier")?.children?.find((c) => c.id === "model") ?? world.find("model");
    if (model) paints.apply(model, store.equippedPaint());
    const title = world.find("title_robot"); // the title screen's robot wears it too
    if (title) paints.apply(title, store.equippedPaint());
  }

  // ------------------------------------------------------------------------------------------------- the event handlers
  onLevelStarted(d) {
    this.attempt = { level: d.level, caught: false, delivered: 0, found: new Set(), continued: false };
    this.paintCourier();
  }

  onDelivered(d) {
    const count = d.delivered + (d.optional ?? 0);
    const n = Math.max(1, count - this.attempt.delivered);
    this.attempt.delivered = count;
    this.bump("parcels_delivered", n);
    this.unlock("first_delivery");
    if ((d.optional ?? 0) > 0) this.unlock("extra_mile");
  }

  onDogGaveUp() {
    this.bump("dogs_shaken");
    if (stat("dogs_shaken") >= DOGS_FOR_WHISPERER) this.unlock("dog_whisperer");
  }

  onCompleted(d) {
    this.bump("levels_won");
    const level = levels.byId(d.level);
    const done = (district) => levels.inDistrict(district).every((l) => progress.resultFor(l.id) !== null);
    if (done("rooftops")) this.unlock("rooftops_done");
    if (done("market")) this.unlock("market_done");
    const total = progress.totalStars();
    if (total >= STARS_COLLECTOR) this.unlock("star_collector");
    if (total >= STARS_ALL) this.unlock("all_stars");
    if (!this.attempt.caught) this.unlock("clean_run");
    if (d.springLeft > 0 && d.springLeft < 5) this.unlock("last_second");
    if (level && d.time <= level.parTime) this.unlock("quick_courier");
    // A run that was extended by a rewarded ad does not go on the leaderboard: the time would not be comparable.
    if (levels.LEVELS.some((l) => l.id === d.level) && !d.continued && !this.attempt.continued) {
      this.submit(timeBoard(d.level), d.time);
    }
    this.submit("total_stars", total, true);
  }

  onShortcut(d) {
    this.bump("shortcuts_found");
    this.unlock("first_shortcut");
    const s = load();
    if (!s.shortcuts.includes(d.shortcut)) {
      s.shortcuts.push(d.shortcut);
      this.save(s);
    }
    if (shortcuts.all().every((id) => s.shortcuts.includes(id))) this.unlock("all_shortcuts");
  }

  onDaily(d) {
    this.unlock("daily_courier");
    this.submit("daily_route", d.time);
  }

  // ----------------------------------------------------------------------------------------- local save and platform calls
  save(s) {
    storage.set(KEY, s);
  }

  /** Adds to a local stat and mirrors its value to the platform (set, not add: a repeated call changes nothing). */
  bump(id, n = 1) {
    const s = load();
    s.stats[id] = (s.stats[id] ?? 0) + n;
    this.save(s);
    this.send({ op: "stat", id, value: s.stats[id] });
  }

  /** Unlocks an achievement (once), shows the toast and mirrors it to the platform. */
  unlock(id) {
    const s = load();
    if (s.ach[id]) return false;
    s.ach[id] = true;
    this.save(s);
    this.toasts.show(i18n.t("ach.toast", { name: i18n.t(`ach.${id}.name`) }));
    this.send({ op: "unlock", id });
    return true;
  }

  /** Submits a score: seconds become whole milliseconds, stars stay whole numbers. */
  submit(board, value, whole = false) {
    this.send({ op: "score", id: board, score: whole ? Math.round(value) : Math.round(value * 1000) });
  }

  /** One platform call; when it fails for a reason that may pass (signed out, network), it goes to the outbox. */
  async send(call) {
    if (!(await this.perform(call))) {
      const s = load();
      s.outbox.push(call);
      s.outbox = s.outbox.slice(-200);
      this.save(s);
    }
  }

  /** Runs one call. True when done or pointless to retry (an id the catalog does not know), false to retry later. */
  async perform(call) {
    try {
      if (call.op === "unlock") await platform.achievements.unlock(call.id);
      else if (call.op === "stat") await platform.stats.set(call.id, call.value);
      else if (call.op === "score") await platform.leaderboards.submit(call.id, call.score);
      return true;
    } catch (e) {
      // signed out and network errors pass: retry later. An unknown id, a store without the service or a refusal never will.
      return e?.code === "unknownId" || e?.code === "unavailable" || e?.code === "notAllowed";
    }
  }

  /** Sends the calls that were kept in the outbox. Resolves when it is done. */
  flush() {
    this.flushing = this.flushing.then(async () => {
      const s = load();
      if (s.outbox.length === 0) return;
      const keep = [];
      for (const call of s.outbox) if (!(await this.perform(call))) keep.push(call);
      const now = load();
      // calls queued while we were sending stay; the ones we sent are gone (compared by value: load() copies)
      const sent = s.outbox.map((c) => JSON.stringify(c));
      const added = now.outbox.slice(s.outbox.length).filter((c) => !sent.includes(JSON.stringify(c)));
      now.outbox = [...keep, ...added].slice(-200);
      this.save(now);
    });
    return this.flushing;
  }
}
