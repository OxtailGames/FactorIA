// @ts-check
// The flow of one level: starts the spring, counts deliveries, and ends the level with a results screen (delivered) or a
// retry screen (the spring ran out). Put it on one entity ("level") of every level scene. Events it sends are listed in
// scripts/events.js; progress is saved through scripts/progress.js.
//
//   levelId   id in scripts/levels.js (spring seconds, par time and parcel count come from there)
//   finished  true once the level is won or lost: the pause menu stays closed and the courier ignores input
import { Behaviour, world, ui, scene, session, i18n } from "factoria";
import { EVENTS, emit } from "./events.js";
import * as levels from "./levels.js";
import * as progress from "./progress.js";
import * as stars from "./stars.js";
import { installUiSounds, playUi } from "./ui/ui_sounds.js";

export default class LevelFlow extends Behaviour {
  /** Id of this level in scripts/levels.js. */
  levelId = "test_yard";
  /** Entity ids the flow talks to. */
  springId = "spring";
  courierId = "courier";
  resultsId = "results_panel";
  retryId = "retry_panel";
  /** Seconds the courier dances before the results screen appears. */
  resultsDelay = 1.6;
  /** Seconds the courier sits (spring wound down) before the retry screen appears. */
  failDelay = 1.4;

  onStart() {
    this.level = levels.byId(this.levelId);
    this.spring = world.find(this.springId)?.behaviour;
    this.courier = world.find(this.courierId)?.behaviour;
    /** Required parcels handed in (the ones that win the level) and optional ones handed in (bonus). */
    this.delivered = 0;
    this.optionalDelivered = 0;
    this.finished = false;
    this.timer = -1;
    this.pending = null;
    session.currentLevel = this.levelId;
    installUiSounds();
    if (this.spring) this.spring.fill(this.level ? this.level.spring : this.spring.max);
    this.offs = [
      // A catch does not end the level: the courier gets up at the last checkpoint (Courier.caught()).
      world.on(EVENTS.springEmpty, () => this.fail("spring_empty")),
    ];
    ui.on("click", "results_retry", () => scene.load(scene.current));
    ui.on("click", "retry_retry", () => scene.load(scene.current));
    ui.on("click", "results_next", () => {
      const nxt = levels.next(this.levelId);
      if (nxt) scene.load(nxt.scene);
    });
    ui.on("click", "results_title", () => scene.load("scenes/main.scene.json"));
    ui.on("click", "retry_title", () => scene.load("scenes/main.scene.json"));
    emit(EVENTS.levelStarted, {
      level: this.levelId,
      parcels: this.level ? this.level.parcels : 1,
      spring: this.spring ? this.spring.max : 0,
    });
  }

  onDestroy() {
    for (const off of this.offs ?? []) off();
  }

  /** Called by a delivery door when the courier handed in `n` parcels, `optional` of them bonus ones. */
  onDelivery(door, n, optional = 0) {
    if (this.finished) return;
    const total = this.level ? this.level.parcels : 1;
    this.delivered += n - optional;
    this.optionalDelivered += optional;
    emit(EVENTS.parcelDelivered, { door, delivered: this.delivered, total, optional: this.optionalDelivered });
    if (this.delivered >= total) this.win();
  }

  win() {
    this.finished = true;
    const spring = this.spring;
    spring?.stop();
    const time = spring ? spring.elapsed : 0;
    const left = spring ? spring.left : 0;
    const rating = stars.evaluate(this.level, {
      time,
      springLeft: left,
      springMax: spring ? spring.max : 0,
      optionalDelivered: this.optionalDelivered,
    });
    const best = progress.record(this.levelId, { time, springLeft: left, stars: rating.stars, goals: rating.goals });
    this.courier?.celebrate();
    emit(EVENTS.levelCompleted, { level: this.levelId, time, springLeft: left, stars: rating.stars, goals: rating.goals, best });
    this.pending = { panel: this.resultsId, time, left, stars: rating.stars, goals: rating.goals };
    this.timer = this.resultsDelay;
  }

  /** @param {"spring_empty"} reason */
  fail(reason) {
    if (this.finished) return;
    this.finished = true;
    this.spring?.stop();
    if (reason === "spring_empty") this.courier?.windDown();
    emit(EVENTS.levelFailed, { level: this.levelId, reason });
    this.pending = { panel: this.retryId, reason };
    this.timer = this.failDelay;
  }

  onUpdate(dt) {
    if (this.timer < 0) return;
    this.timer -= dt;
    if (this.timer > 0) return;
    this.timer = -1;
    const p = this.pending;
    this.pending = null;
    if (p) this.showPanel(p);
  }

  showPanel(p) {
    const panel = world.find(p.panel);
    if (!panel) return;
    if (p.panel === this.resultsId) {
      this.setText("results_time", i18n.t("results.time", { time: p.time.toFixed(1) }));
      this.setText("results_spring", i18n.t("results.spring", { seconds: Math.ceil(p.left) }));
      this.setText("results_stars", "*".repeat(p.stars) + "-".repeat(3 - p.stars));
      const nextButton = world.find("results_next");
      if (nextButton) nextButton.active = levels.next(this.levelId) !== null;
      playUi("confirmation_001", 0.8);
    } else {
      playUi("error_001", 0.7);
    }
    panel.active = true;
    // The autoFocus button (Next) is hidden on the last level: focus Play again so a gamepad or keyboard works at once.
    if (p.panel === this.resultsId && world.find("results_next")?.active === false) ui.focus(world.find("results_retry"));
  }

  setText(id, text) {
    const e = world.find(id);
    if (e) e.get("Text").text = text;
  }
}
