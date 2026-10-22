// @ts-check
// The level select (scenes/level_select.scene.json): two district panels with a card per level, the stars and best time of
// each, locked levels greyed out, the total stars, the courier's name (a button: click it to rename), the daily route and a
// line about the cloud save. Everything is plain Buttons, so mouse, touch, keyboard (arrows, Enter, Esc) and gamepad (d-pad or
// stick, A, B) all work through the engine's focus rules; a locked card stays focusable (a plain grid for the d-pad) and says what opens it.
//
//   click a card      starts that level (through the loading screen); a normal run clears any daily route
//   select_daily      starts today's daily route (scripts/daily.js)
//   select_name       opens the name screen to rename (scripts/profile.js), which returns here
//   select_back / Esc / gamepad B / Android Back   the title screen
//
// Opening the screen asks the cloud to settle (cloud_sync.sync): if it brought progress in, the cards are redrawn.
import { Behaviour, ui, world, scene, session, input, i18n } from "factoria";
import * as fmt from "./fmt.js";
import * as levels from "./levels.js";
import * as progress from "./progress.js";
import * as daily from "./daily.js";
import * as cloudSync from "./cloud_sync.js";
import { starText } from "./results_view.js";
import { applyOnce } from "./settings.js";
import { installUiSounds, playUi } from "./ui/ui_sounds.js";

export default class LevelSelect extends Behaviour {
  onStart() {
    applyOnce();
    installUiSounds();
    this.alive = true;
    this.wire();
    this.refresh();
    this.offs = [i18n.on("change", () => this.refresh())];
    this.offBack = input.onBack(() => this.back());
    cloudSync.sync().then((r) => {
      if (!this.alive) return;
      if (r.status === "downloaded" || r.status === "merged") this.refresh();
      this.showCloud(r.status);
    });
  }

  onDestroy() {
    this.alive = false;
    this.offBack?.();
    for (const off of this.offs ?? []) off();
  }

  wire() {
    for (const l of levels.LEVELS) ui.on("click", "card_" + l.id, () => this.play(l.id));
    ui.on("click", "select_daily", () => this.playDaily());
    ui.on("click", "select_name", () => {
      session.profileReturn = "scenes/level_select.scene.json";
      scene.load("scenes/profile.scene.json");
    });
    ui.on("click", "select_back", () => this.back());
    ui.on("cancel", () => this.back());
  }

  back() {
    scene.load("scenes/main.scene.json");
  }

  /** Starts a level of the list as a normal run. */
  play(id) {
    const level = levels.byId(id);
    if (!level) return;
    if (!progress.isUnlocked(id)) return this.explainLock(level);
    this.setText("select_hint", "");
    daily.clear();
    session.nextScene = level.scene;
    scene.load("scenes/loading.scene.json");
  }

  /** A locked card stays focusable (so the d-pad moves over a plain grid) and a click says what opens it. */
  explainLock(level) {
    playUi("error_001", 0.6);
    const i = levels.LEVELS.findIndex((l) => l.id === level.id);
    if (!progress.isDistrictUnlocked(level.district)) {
      this.setText("select_hint", i18n.t("select.hintDistrict", { count: progress.districtStarsNeeded(level.district), have: progress.starsBefore(level.district) }));
    } else {
      this.setText("select_hint", i18n.t("select.hintLevel", { level: i18n.t(levels.LEVELS[i - 1].nameKey) }));
    }
  }

  playDaily() {
    const route = daily.current();
    const level = levels.byId(route.level);
    if (!level) return;
    daily.start(route);
    session.nextScene = level.scene;
    scene.load("scenes/loading.scene.json");
  }

  /** Redraws every card, the totals and the buttons from the saved progress. */
  refresh() {
    this.capSizes();
    for (const l of levels.LEVELS) this.drawCard(l);
    for (const d of levels.DISTRICTS) {
      this.setText("district_" + d.id + "_title", i18n.t(d.nameKey) + (progress.isDistrictUnlocked(d.id) ? "" : "  " + i18n.t("select.districtLocked", { count: d.stars, have: progress.starsBefore(d.id) })));
    }
    this.setText("select_total", i18n.t("select.total", { stars: progress.totalStars(), max: levels.LEVELS.length * 3 }));
    const nameButton = world.find("select_name");
    if (nameButton) nameButton.get("Button").text = progress.hasName() ? i18n.t("select.name", { name: progress.name() }) : i18n.t("select.noName");
    const time = daily.todaysTime();
    const dailyButton = world.find("select_daily");
    if (dailyButton) dailyButton.get("Button").text = time === null ? i18n.t("select.daily") : i18n.t("select.dailyDone", { time: fmt.decimal(time) });
    this.showCloud(session.cloudStatus?.status ?? "");
  }

  /**
   * The cards, headings and district titles sit at fixed places and fit a fixed width, so at a big text size (ui.textScale) their
   * text would be clipped or overlap. Their effective size stops at 1.15 times the design size (1.3 for the headings); the other
   * texts of the screen (buttons, hint) still follow the player's setting. (FB-0042)
   */
  capSizes() {
    const s = Math.max(ui.textScale, 0.01);
    const cap = (id, comp, base, max) => {
      const e = world.find(id);
      if (e && e.has(comp)) e.get(comp).fontSize = (base * Math.min(max, s)) / s;
    };
    cap("select_title", "Text", 44, 1.3);
    cap("select_total", "Text", 26, 1.3);
    cap("select_name", "Button", 24, 1.15);
    cap("select_cloud", "Text", 20, 1.15);
    for (const d of levels.DISTRICTS) cap("district_" + d.id + "_title", "Text", 28, 1.15);
    for (const l of levels.LEVELS) cap("card_" + l.id, "Button", 24, 1.15);
  }

  drawCard(l) {
    const card = world.find("card_" + l.id);
    if (!card) return;
    const b = card.get("Button");
    const open = progress.isUnlocked(l.id);
    const res = progress.resultFor(l.id);
    const name = i18n.t(l.nameKey);
    b.color = open ? [0.24, 0.27, 0.36, 0.95] : [0.14, 0.15, 0.2, 0.9];
    if (!open) b.text = name + "\n" + i18n.t("select.locked");
    else if (!res) b.text = name + "\n" + i18n.t("select.new");
    else b.text = name + "\n" + starText(res.stars) + "   " + i18n.t("select.cardTime", { time: fmt.decimal(res.time) });
    b.textColor = !open ? [0.6, 0.62, 0.7, 1] : res && res.stars === 3 ? [1, 0.85, 0.3, 1] : [1, 1, 1, 1];
  }

  /** The small line under the name: how the last cloud sync went (nothing when there is no cloud). */
  showCloud(status) {
    const known = ["synced", "uploaded", "downloaded", "merged", "offline", "unreadable"];
    this.setText("select_cloud", known.includes(status) ? i18n.t("select.cloud." + status) : "");
  }

  setText(id, text) {
    const e = world.find(id);
    if (!e) return;
    if (e.has("Text")) e.get("Text").text = text;
  }
}
