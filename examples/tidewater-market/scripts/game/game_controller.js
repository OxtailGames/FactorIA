// @ts-check
// The game screen (scenes/game.scene.json): turns the mouse and keys into actions on the GameState and keeps the HUD in step.
//
// Who owns what:
//   GameState  (state.js)   all rules and all state; never touches the engine.
//   MapView    (map_view.js) sprites for the state; this controller asks it for the highlight diamonds and the ghost.
//   CameraRig  (camera_rig.js) the strategy camera on the "camera" entity; this controller asks it which cell is under the mouse.
//   Hud        (ui_hud.js)  the panels: build menu, inspector, goods table, charts, help, notifications, tooltips, overlays.
//   this file               tools (build / road / demolish), hover, drag, hotkeys, top bar, status line, toasts.
//
// Later packages: `controller.state` is the state, `controller.state.events` is the event bus (README, "Contracts"). Add new
// HUD items to the bar with `controller.addHudItem`; new build-menu items come from data/buildings.json (its `category`);
// new panels, tooltips, notifications and overlays go through `controller.hud` (README, "Interface (P3)").
import { Behaviour, ui, input, i18n, game, world } from "factoria";
import { getData } from "./data.js";
import { createGame } from "./state.js";
import { takeBoot } from "./boot.js";
import { Autosaver } from "./autosave.js";
import { GoalPanel } from "../ui/goal_panel.js";
import { MapView, COLORS } from "./map_view.js";
import { WalkerView } from "./walker_view.js";
import { MusicDirector } from "./music_director.js";
import { Soundscape } from "./soundscape.js";
import { GameSfx } from "./sfx.js";
import { pointer } from "./pointer.js";
import { live, preview } from "../settings.js";
import { harbourCell } from "./harbour.js";
import { stressRows, stressTownSteps } from "./stress_town.js";
import { Bot } from "./bot.js";
import { SPEEDS } from "./clock.js";
import { footprintCells, roadPath } from "./rules.js";
import { cellToWorld, mapBounds } from "./iso.js";
import { amountText, buildingName, compactText, dateText, reasonText, stepText } from "./format.js";
import { Hud } from "./ui_hud.js";
import { DESIGN } from "./camera_math.js";

const COLOR_BUTTON = [0.17, 0.21, 0.28, 1];
const COLOR_BUTTON_ACTIVE = [0.33, 0.52, 0.72, 1];
const BAR_COLOR = [0.05, 0.07, 0.1, 0.88];
/** Most clock steps one frame may run (a slow frame drops the rest of its time instead of spiralling). */
const MAX_STEPS_PER_FRAME = 12;
const SPEED_LABELS = ["hud.speedPause", "hud.speed1", "hud.speed2", "hud.speed4"];
/** A frame longer than this many real seconds counts as this long (a window drag must not fast-forward the town). */
const MAX_FRAME = 0.1;
/** Presses closer together than this many pixels are a click, not a drag (right-click cancels the tool). */
const CLICK_SLOP = 6;

export default class GameController extends Behaviour {
  /** Map seed; 0 = the default seed of data/map.json. A scene prop `seed` overrides it. */
  seed = 0;
  /** Use the small hand-made map of data/test_map.json (tests). A scene prop `testMap` overrides it. */
  testMap = false;
  /** Seconds a toast stays on screen. */
  toastSeconds = 3;
  /** The clock speed the game starts at: 0 paused, 1 normal, 2 fast, 3 fastest (a scene prop `speed` overrides it). */
  startSpeed = 1;
  /** Play the music of the season. A scene prop `music` overrides it; the test map plays none unless the prop says so. */
  music = true;
  /** Stress mode (scenes/stress.scene.json): a flat map with a dense town of this many villagers, see stress_town.js. 0 = a normal game. */
  stress = 0;

  onStart() {
    const props = game.sceneProps();
    if (props.options) preview(props.options); // tooling: show the game with some options on, saving nothing
    const seed = props.seed !== undefined ? props.seed : this.seed;
    const testMap = props.testMap !== undefined ? props.testMap : this.testMap;
    this.data = getData();
    const stress = props.stress !== undefined ? props.stress : this.stress;
    // P4: a game from a save slot or a scenario (session.boot, scripts/game/boot.js) replaces the scene's own game
    const boot = takeBoot(this.data);
    this.run = boot.run;
    this.state = boot.state || createGame({ data: this.data, seed: seed || undefined, testMap, rows: stress ? stressRows() : undefined });
    this.autosaver = new Autosaver(this.state, this.run);
    this.world.spawn({ id: "save_controller", components: { Script: { path: "scripts/save_controller.js" } } });
    /** The stress town is laid out one step per frame (a callback may not run over 2 s), the clock waits for it. */
    this.stressSteps = stress ? stressTownSteps(this.state, { villagers: stress }).steps : [];
    // store renders (store/make_store_images.py): scene prop `grow` = days the bot plays before the first frame, one day a frame
    this.photo = !!props.photo; // scene prop `photo`: no interface at all, the world alone (key art and capsules)
    /** Scene prop `timelapse` = frames per game day while the bot's days run (0 = all before the first frame): the trailer shows the town growing. */
    this.timelapse = props.timelapse || 0;
    this.lapse = 0;
    const grow = props.grow || 0;
    if (grow && !boot.state) this.stressSteps.push(...this.growSteps(grow));
    this.view = new MapView(this.state);
    this.cameraEntity = this.world.find("camera");
    /** @type {import("./camera_rig.js").default} */
    this.rig = this.cameraEntity.behaviour;
    const map = this.state.map;
    this.rig.setBounds(mapBounds(map.width, map.height));
    // the camera starts on the harbour, so the shore and the water are in view
    const [hc, hr] = harbourCell(map);
    const [cx, cy] = cellToWorld(hc, hr);
    this.rig.setView(cx, cy, props.zoom !== undefined ? props.zoom : this.rig.startZoom); // a scene prop `zoom`: store renders
    this.walkerView = new WalkerView(this.state);
    if (!boot.state) this.state.clock.setSpeed(props.speed !== undefined ? props.speed : this.startSpeed); // a loaded game keeps its saved speed

    /** The current tool: kind "none" | "build" | "demolish"; type = the building to build; rot = its rotation. */
    this.tool = { kind: "none", type: null, rot: 0 };
    /** The cell under the mouse as [c, r], or null (mouse over the HUD, outside the map, or dragging the camera). */
    this.hover = null;
    /** The drag in progress: { kind: "road", from: [c, r] } or { kind: "demolish", cells: [[c, r]] }, or null. */
    this.drag = null;
    this.toastTimer = 0;
    this.rightPress = null;
    this.rightConsumed = false;
    this.pressOnMap = false;
    this.shown = { coins: "", date: "", goods: {}, status: "", pop: "", speed: -1 };

    this.hudBar = this.world.find("hud_bar");
    this.palette = this.world.find("palette");
    this.statusBar = this.world.find("status_bar");
    this.statusText = this.world.find("status_text");
    this.toastText = this.world.find("toast");
    this.coinsText = this.world.find("coins_text");
    this.dateTextEntity = this.world.find("hud_date");
    this.speedBar = this.world.find("speed_bar");
    this.uiPanels = [this.hudBar, this.palette, this.statusBar, this.dateTextEntity, this.speedBar];
    this.world.find("coin_icon").get("Sprite").region = this.data.atlas.frames["icon.coin"].rect;
    this.buildHud();
    this.buildSpeedBar();
    /** The panels (ui_hud.js). It owns the right-hand column, the build menu and the inspector. */
    this.hud = new Hud(this);
    this.buttons = this.hud.rightButtons;

    const ev = this.state.events;
    this.off = [
      ev.on("action.rejected", (e) => this.onRejected(e)),
      ev.on("history.changed", () => this.refreshButtons()),
      ev.on("clock.season", (e) => this.toast(i18n.t("toast.season", { season: i18n.t(`season.${e.date.season}`) }))),
      ev.on("villager.left", (e) => this.toast(i18n.t("toast.left", { reason: i18n.t(`sim.leftReason.${e.reason}`) }))),
      ev.on("payday", (e) => e.broke && this.toast(i18n.t("toast.broke"))),
      i18n.on("change", () => this.buildSpeedLabels()),
      ui.on("click", (e) => this.onClick(e.id)),
      ui.on("scale", () => this.spanBars()), // the interface size changed: the two bars must still reach both edges of the screen
    ];
    this.spanBars();
    this.refreshButtons();
    this.refreshHud(true);
    if (this.run.tracker) this.goalPanel = new GoalPanel(this); // P4: the goals of a scenario game (scripts/ui/goal_panel.js)
    if (props.music !== undefined ? props.music : this.music && !testMap) this.musicDirector = new MusicDirector(this.state);
    // P6: the ambience beds and building sounds follow the camera; the interface sounds follow the events (sound only reads the game)
    this.soundscape = new Soundscape(this.state, this.rig);
    this.sfx = new GameSfx(this.state, this.hud.notices);
  }

  onDestroy() {
    for (const off of this.off || []) off();
    this.off = [];
    if (this.hud) this.hud.destroy();
    if (this.musicDirector) this.musicDirector.destroy();
    if (this.soundscape) this.soundscape.destroy();
    if (this.sfx) this.sfx.destroy();
    if (this.view) this.view.destroy();
    if (this.goalPanel) this.goalPanel.destroy();
  }

  // ---- HUD ---------------------------------------------------------------------------------------------------------

  /** The top bar: the coin icon and amount (scene), then one icon + amount per good flagged `hud` in data/goods.json. */
  buildHud() {
    this.goodTexts = {};
    for (const id of this.data.goodIds) {
      const good = this.data.goods[id];
      if (!good.hud) continue;
      this.goodTexts[id] = this.addHudItem(`good_${id}`, good.icon, "");
    }
    this.popText = this.addHudItem("pop", "icon.pop", "");
  }

  /** The speed buttons (right of the date): pause, x1, x2, x4. Keys 1-4 and Space do the same. */
  buildSpeedBar() {
    this.speedButtons = [];
    SPEED_LABELS.forEach((label, i) => {
      const e = this.world.spawn(
        { id: `speed_${i}`, components: { Button: { text: i18n.t(label), size: [50, 30], fontSize: 16, layer: 210, color: COLOR_BUTTON, autoShrink: true, minFontSize: 8, maxTextScale: 1.5 } } },
        { parent: this.speedBar },
      );
      this.speedButtons.push(e);
    });
  }

  buildSpeedLabels() {
    this.speedButtons.forEach((e, i) => (e.get("Button").text = i18n.t(SPEED_LABELS[i])));
  }

  /**
   * Add an icon + text pair to the top bar (after the items that are there). Returns the Text entity, so the caller can
   * set its text. This is where later packages add their numbers (population, happiness, the clock speed).
   * @param {string} id @param {string} frame an atlas frame name (data/atlas.json)
   */
  addHudItem(id, frame, text) {
    const f = this.data.atlas.frames[frame];
    this.world.spawn(
      {
        id: `${id}_icon`,
        components: {
          Sprite: { texture: this.data.atlas.texture, region: f.rect, size: [24, 24], space: "screen", layer: 210, pixelArt: false },
        },
      },
      { parent: this.hudBar },
    );
    return this.world.spawn(
      { id: `${id}_text`, components: { Text: { text, fontSize: 18, space: "screen", layer: 210 } } },
      { parent: this.hudBar },
    );
  }

  /** Highlight the active tool's buttons (build menu, Demolish); grey Undo / Redo out when there is nothing to undo / redo. */
  refreshButtons() {
    this.hud.refreshBar();
    this.buttons.tool_demolish.get("Button").color = this.tool.kind === "demolish" ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON;
    this.buttons.btn_undo.get("Button").interactable = this.state.canUndo();
    this.buttons.btn_redo.get("Button").interactable = this.state.canRedo();
  }

  /** Write the numbers into the bar; a Text is only touched when its string changed. */
  refreshHud(force = false) {
    const eco = this.state.economy;
    const coins = compactText(eco.coins);
    if (force || coins !== this.shown.coins) {
      this.shown.coins = coins;
      this.coinsText.get("Text").text = coins;
    }
    for (const id of Object.keys(this.goodTexts)) {
      const n = compactText(Math.floor(eco.get(id)));
      if (force || n !== this.shown.goods[id]) {
        this.shown.goods[id] = n;
        this.goodTexts[id].get("Text").text = n;
      }
    }
    const date = dateText(this.state.clock.date());
    if (force || date !== this.shown.date) {
      this.shown.date = date;
      this.dateTextEntity.get("Text").text = date;
    }
    const sum = this.state.sim.summary();
    let pop = i18n.t("hud.popItem", { count: compactText(sum.population), housing: compactText(sum.housing) });
    this.popBase = pop; // fitTopBar falls back to this when the hungry count does not fit beside the date
    if (sum.hungry > 0) pop += `  ${i18n.t("ui.hungryShort", { count: sum.hungry, shown: compactText(sum.hungry) })}`;
    if (force || pop !== this.shown.pop) {
      this.shown.pop = pop;
      this.popText.get("Text").text = pop;
    }
    this.fitTopBar(force);
    const speed = this.state.clock.speed;
    if (force || speed !== this.shown.speed) {
      this.shown.speed = speed;
      this.speedButtons.forEach((e, i) => (e.get("Button").color = i === speed ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON));
    }
  }

  /**
   * Keep the numbers of the top bar clear of the date. Large numbers or a larger text size (ui.textScale) can make the row longer than
   * the room left of the date: then the goods at the end of the list are hidden (the goods table, key G, always has them all), one by one,
   * until the row fits. Only redone when a text or the text size changed.
   */
  fitTopBar(force = false) {
    const rep = this.world.find("rep_text");
    const sig = `${ui.textScale}|${this.shown.coins}|${this.shown.pop}|${rep ? rep.get("Text").text : ""}|${Object.values(this.shown.goods).join(",")}`;
    if (!force && sig === this.fitSignature) return;
    this.fitSignature = sig;
    const ids = Object.keys(this.goodTexts);
    const show = (id, on) => {
      for (const part of ["icon", "text"]) {
        const e = this.world.find(`good_${id}_${part}`);
        if (e && e.active !== on) e.active = on;
      }
    };
    ids.forEach((id) => show(id, true));
    if (this.shown.pop && this.popText.get("Text").text !== this.shown.pop) this.popText.get("Text").text = this.shown.pop;
    ui.layout();
    const date = ui.rectOf(this.dateTextEntity);
    // the last item of the row: items other packages add after the villagers (reputation) come last
    const lastItem = this.world.find("rep_text") || this.popText;
    if (!date || !ui.rectOf(lastItem)) return;
    const limit = date.x - 12;
    const right = () => ui.rectOf(lastItem).x + ui.rectOf(lastItem).w;
    for (let n = ids.length - 1; n >= 0 && right() > limit; n--) {
      show(ids[n], false);
      ui.layout();
    }
    // with every good hidden the row can still be too long (a long language, a large text size, hundreds hungry): drop the hungry count
    if (right() > limit && this.popBase && this.popText.get("Text").text !== this.popBase) {
      this.popText.get("Text").text = this.popBase;
      ui.layout();
    }
  }

  /** The top bar and the status bar are as wide as the screen: the scene writes 1280 UI units, which ui.scale would make wider. */
  spanBars() {
    for (const bar of [this.hudBar, this.statusBar]) {
      const panel = bar.get("Panel");
      panel.size = [DESIGN.width / ui.scale, panel.size.y];
    }
  }

  /** Select a clock speed (0 pause, 1, 2, 3 = x1, x2, x4). */
  setSpeed(speed) {
    this.state.clock.setSpeed(speed);
    this.refreshHud();
  }

  /** Space: pause, or go on at the speed from before the pause (normal speed when there was none). */
  togglePause() {
    const clock = this.state.clock;
    if (clock.speed === 0) this.setSpeed(this.speedBeforePause || 1);
    else {
      this.speedBeforePause = clock.speed;
      this.setSpeed(0);
    }
  }

  toast(text) {
    this.toastText.get("Text").text = text;
    this.toastTimer = this.toastSeconds;
  }

  onRejected(e) {
    // Only what the player did: the road drag and the ghost ask first (previewRoads / checkAt), so this fires for real attempts.
    const reason = e.reasons && e.reasons[0];
    if (reason) this.toast(reasonText(reason));
  }

  // ---- tools -------------------------------------------------------------------------------------------------------

  /** Pick a building to build (the road included); picking the active one again puts the tool away. */
  selectBuilding(type) {
    if (this.tool.kind === "build" && this.tool.type === type) return this.clearTool();
    this.tool = { kind: "build", type, rot: this.tool.rot };
    this.drag = null;
    this.refreshButtons();
  }

  selectDemolish() {
    if (this.tool.kind === "demolish") return this.clearTool();
    this.tool = { kind: "demolish", type: null, rot: this.tool.rot };
    this.drag = null;
    this.refreshButtons();
  }

  clearTool() {
    this.tool = { kind: "none", type: null, rot: this.tool.rot };
    this.drag = null;
    this.refreshButtons();
  }

  /** R: turn the selected building when one is selected and no tool is held, else the building about to be placed. */
  rotate() {
    if (this.tool.kind === "none" && this.hud.rotateSelected()) return;
    this.tool.rot = (this.tool.rot + 1) % 4;
  }

  /** Esc, Q and a right-click: put away the newest thing the player opened. @returns {boolean} something was put away */
  escape() {
    return this.hud.escape();
  }

  /** The pause menu opens (scripts/pause_menu.js): this script stops updating, so put away the tooltip it would leave drawn. */
  onPauseMenu() {
    this.hud.tooltips.hide();
  }

  undo() {
    const tx = this.state.undoStack[this.state.undoStack.length - 1];
    if (!tx) return this.toast(i18n.t("toast.nothingToUndo"));
    const label = stepText(tx);
    if (this.state.undo().ok) this.toast(i18n.t("toast.undone", { label }));
  }

  redo() {
    const tx = this.state.redoStack[this.state.redoStack.length - 1];
    if (!tx) return this.toast(i18n.t("toast.nothingToRedo"));
    const label = stepText(tx);
    if (this.state.redo().ok) this.toast(i18n.t("toast.redone", { label }));
  }

  onClick(id) {
    if (this.hud.onClick(id)) return;
    if (id.startsWith("tool_") && id !== "tool_demolish") this.selectBuilding(id.slice(5));
    else if (id === "tool_demolish") this.selectDemolish();
    else if (id === "btn_rotate") this.rotate();
    else if (id === "btn_undo") this.undo();
    else if (id === "btn_redo") this.redo();
    else if (id.startsWith("speed_")) this.setSpeed(Number(id.slice(6)));
  }

  // ---- the frame ---------------------------------------------------------------------------------------------------

  /** Is the point over the HUD (a widget or a bar)? Then a click is not meant for the map. */
  overUi(m) {
    if (pointer.hovered() || this.hud.over(m)) return true;
    for (const e of this.uiPanels) {
      const r = ui.rectOf(e);
      if (r && m.x >= r.x && m.x < r.x + r.w && m.y >= r.y && m.y < r.y + r.h) return true;
    }
    return false;
  }

  /** The bot's days as one step per game day (a callback may not run over 2 s); the last step stops the bot. */
  growSteps(days) {
    const clock = this.state.clock;
    const bot = new Bot(this.state);
    const steps = [() => bot.act()];
    for (let d = 0; d < days; d++) {
      steps.push(() => {
        for (let i = 0; i < clock.ticksPerDay; i++) clock.tick(clock.step);
        this.answerCards();
        if (d === days - 1) {
          bot.stop();
          this.hud.notices.items = []; // the bot's complaints are not the player's
          this.toastTimer = 0;
          this.toastText.get("Text").text = "";
          if (!this.timelapse) this.frameTown();
        }
      });
    }
    return steps;
  }

  /** The camera on the middle of the buildings (a grown town for a store render), at the zoom of the scene prop `zoom`. */
  frameTown() {
    let c = 0, r = 0, n = 0;
    for (const b of this.state.buildings.values()) {
      c += b.x;
      r += b.y;
      n++;
    }
    if (!n) return;
    const [x, y] = cellToWorld(c / n, r / n);
    this.rig.setView(x, y, this.rig.view.zoom);
  }

  /** Photo mode: the frame is drawn without the interface (every top-level screen-space entity is switched off after the HUD's update). */
  onLateUpdate() {
    if (!this.photo || (this.stressSteps.length && !this.timelapse)) return;
    for (const e of world.entities()) {
      if (e.parent || e.hasTag("caption")) continue; // a trailer caption stays
      const t = e.get("Text");
      if (e.get("Panel") || e.get("Button") || (t && t.space === "screen") || e.get("Sprite") && e.get("Sprite").space === "screen") e.active = false;
    }
  }

  /** The bot answers the event cards the town draws (the first choice it can pay, else the last one) so no card is open. */
  answerCards() {
    const trade = this.state.trade;
    for (let guard = 0; guard < 8 && trade.card; guard++) {
      if (trade.card.stage === "choose") {
        const { def } = trade.cardDef(trade.card);
        const pick = def.choices.find((c) => trade.canChoose(c).ok) || def.choices[def.choices.length - 1];
        trade.choose(pick.id);
      }
      trade.dismiss();
    }
  }

  onUpdate(dt) {
    if (this.stressSteps.length) {
      this.sfx.muted = true; // the town being laid out is not a player building 300 houses
      if (!this.timelapse || this.lapse++ % this.timelapse === 0) this.stressSteps.shift()();
      if (this.timelapse) this.walkerView.update();
      return;
    }
    this.sfx.muted = false;
    const m = pointer.position();
    this.state.clock.advance(Math.min(dt, MAX_FRAME), MAX_STEPS_PER_FRAME);
    this.walkerView.update();
    this.soundscape.update(dt);
    if (this.goalPanel) this.goalPanel.place();

    this.keys();
    const onUi = this.overUi(m);
    this.hover = null;
    if (!onUi && !this.rig.dragging && !this.rig.inEdgeStrip(m)) {
      const [c, r] = this.rig.screenToCell(m.x, m.y);
      if (this.state.map.inBounds(c, r)) this.hover = [c, r];
    }
    this.mouse(m, onUi);
    this.draw();
    this.refreshHud();
    this.hud.update(dt, m);
    this.refreshStatus(onUi);
    if (this.toastTimer > 0) {
      this.toastTimer -= dt;
      if (this.toastTimer <= 0) this.toastText.get("Text").text = "";
    }
  }

  keys() {
    if (input.pressed("undo")) this.undo();
    if (input.pressed("redo")) this.redo();
    if (input.pressed("rotate")) this.rotate();
    if (input.pressed("tool_demolish")) this.selectDemolish();
    if (input.pressed("tool_cancel")) this.escape();
    this.hud.keys();
    if (input.pressed("tool_next")) this.cycleTool(1);
    if (input.pressed("tool_prev")) this.cycleTool(-1);
    ["speed_pause", "speed_1", "speed_2", "speed_3"].forEach((action, i) => input.pressed(action) && this.setSpeed(i));
    if (input.pressed("pause_toggle")) this.togglePause();
  }

  /** E / C: the next or the previous building in the palette (from none, the first or the last). */
  cycleTool(step) {
    const ids = this.data.buildingIds;
    const at = this.tool.kind === "build" ? ids.indexOf(this.tool.type) : step > 0 ? -1 : 0;
    this.tool = { kind: "build", type: ids[(at + step + ids.length) % ids.length], rot: this.tool.rot };
    this.drag = null;
    this.refreshButtons();
  }

  mouse(m, onUi) {
    // Right button: a drag pans the camera (CameraRig); a plain click puts the tool away (or cancels a drag in progress).
    if (input.pressed("pan_drag")) {
      this.rightPress = { x: m.x, y: m.y };
      this.rightConsumed = false;
      if (this.drag) {
        this.drag = null;
        this.rightConsumed = true;
      }
    }
    if (input.released("pan_drag") && this.rightPress) {
      const moved = Math.hypot(m.x - this.rightPress.x, m.y - this.rightPress.y);
      if (moved < CLICK_SLOP && !this.rightConsumed) this.escape();
      this.rightPress = null;
    }

    // Hold-free (option, or a gamepad in use): a road or a demolish takes two clicks, first end then second end, not a press held down.
    const twoClicks = live().holdFree || pointer.pad;
    if (input.pressed("primary")) {
      this.pressOnMap = !onUi && !!this.hover && !this.hud.carrying();
      if (twoClicks && this.drag && this.drag.twoClicks) {
        if (this.hover) this.continueDrag();
        this.finishDrag();
        this.pressOnMap = false;
      } else if (this.pressOnMap) {
        this.beginPress();
        if (this.drag && twoClicks) this.drag.twoClicks = true;
      } else if (this.drag && this.drag.twoClicks) {
        this.drag = null; // a click on a panel gives the two-click drag up
      }
    }
    if (this.drag && this.hover) this.continueDrag();
    if (input.released("primary") && this.drag && !this.drag.twoClicks) {
      this.finishDrag();
      this.pressOnMap = false;
    }
    if (input.released("primary")) this.pressOnMap = false;
    if (this.drag && !this.drag.twoClicks && !input.down("primary")) this.drag = null; // lost the release (focus change)
  }

  beginPress() {
    const [c, r] = this.hover;
    const tool = this.tool;
    if (tool.kind === "build" && this.data.buildings[tool.type].kind === "road") {
      this.drag = { kind: "road", from: [c, r], to: [c, r] };
    } else if (tool.kind === "build") {
      const res = this.state.placeAt(tool.type, c, r, tool.rot);
      if (res.ok) this.toast(i18n.t("toast.built", { name: buildingName(tool.type) }));
    } else if (tool.kind === "demolish") {
      this.drag = { kind: "demolish", cells: [[c, r]], last: [c, r], from: [c, r] };
    } else {
      this.hud.pickAt(pointer.position(), [c, r]);
    }
  }

  continueDrag() {
    const [c, r] = this.hover;
    const drag = this.drag;
    if (drag.kind === "road") drag.to = [c, r];
    else if (drag.kind === "demolish" && drag.twoClicks) {
      // two clicks: the cells from the first click to the pointer in a straight run, not the trail the pointer left
      drag.cells = roadPath(drag.from, [c, r]);
      drag.last = [c, r];
    } else if (drag.kind === "demolish" && (c !== drag.last[0] || r !== drag.last[1])) {
      for (const cell of roadPath(drag.last, [c, r]).slice(1)) drag.cells.push(cell);
      drag.last = [c, r];
    }
  }

  finishDrag() {
    const drag = this.drag;
    this.drag = null;
    if (drag.kind === "road") {
      const cells = roadPath(drag.from, drag.to).filter(([c, r]) => this.state.map.inBounds(c, r));
      const res = this.state.placeRoads(cells);
      if (res.ok) this.toast(i18n.t("toast.roads", { count: res.placed.length }));
    } else {
      const res = this.state.demolishCells(drag.cells.filter(([c, r]) => this.state.map.inBounds(c, r)));
      if (res.ok) {
        this.toast(
          res.removed.length === 1
            ? i18n.t("toast.demolished", { name: buildingName(res.removed[0].type) })
            : i18n.t("toast.demolishedMany", { count: res.removed.length }),
        );
      }
    }
  }

  // ---- drawing the overlay -----------------------------------------------------------------------------------------

  draw() {
    const view = this.view;
    const tool = this.tool;
    view.beginOverlay();
    let ghost = null;
    if (this.drag && this.drag.kind === "road") {
      const cells = roadPath(this.drag.from, this.drag.to).filter(([c, r]) => this.state.map.inBounds(c, r));
      this.dragPreview = this.state.previewRoads(cells);
      for (const p of this.dragPreview) view.diamond(p.cell[0], p.cell[1], p.status === "new" ? COLORS.valid : p.status === "existing" ? COLORS.existing : COLORS.invalid);
    } else if (this.drag && this.drag.kind === "demolish") {
      this.dragPreview = null;
      for (const [c, r] of this.drag.cells) this.markDemolish(c, r);
    } else if (this.hover) {
      this.dragPreview = null;
      const [c, r] = this.hover;
      if (tool.kind === "none") {
        view.diamond(c, r, COLORS.hover, true);
      } else if (tool.kind === "demolish") {
        if (this.state.buildingAt(c, r)) this.markDemolish(c, r);
        else view.diamond(c, r, COLORS.hover, true);
      } else if (this.data.buildings[tool.type].kind === "road") {
        const p = this.state.previewRoads([[c, r]])[0];
        view.diamond(c, r, p.status === "new" ? COLORS.valid : p.status === "existing" ? COLORS.existing : COLORS.invalid);
      } else {
        const chk = this.state.checkAt(tool.type, c, r, tool.rot);
        this.check = chk;
        for (const [cc, rr] of chk.cells) if (this.state.map.inBounds(cc, rr)) view.diamond(cc, rr, chk.ok ? COLORS.valid : COLORS.invalid);
        ghost = chk;
      }
    }
    if (ghost) view.setGhost(tool.type, ghost.x, ghost.y, tool.rot, ghost.ok);
    else view.setGhost(null);
    this.hud.drawOverlay(view);
    view.endOverlay();
  }

  /** Colour the whole footprint of the building on a cell as "will be demolished". */
  markDemolish(c, r) {
    const b = this.state.buildingAt(c, r);
    if (!b) return;
    for (const [cc, rr] of footprintCells(this.data.buildings[b.type], b.x, b.y, b.rot)) this.view.diamond(cc, rr, COLORS.demolish);
  }

  // ---- the status line ---------------------------------------------------------------------------------------------

  refreshStatus(onUi) {
    const text = this.statusFor(onUi);
    if (text !== this.shown.status) {
      this.shown.status = text;
      this.statusText.get("Text").text = text;
    }
  }

  statusFor(onUi) {
    const tool = this.tool;
    const hovered = pointer.hovered();
    if (hovered && hovered.id && hovered.id.startsWith("tool_") && hovered.id !== "tool_demolish") {
      const type = hovered.id.slice(5);
      return i18n.t("status.palette", { name: buildingName(type), desc: i18n.t(`building.${type}.desc`), cost: amountText(this.data.buildings[type].cost) });
    }
    if (this.drag && this.drag.kind === "road") {
      const fresh = (this.dragPreview || []).filter((p) => p.status === "new").length;
      const cost = {};
      for (const [k, v] of Object.entries(this.data.buildings.road.cost)) cost[k] = v * fresh;
      return i18n.t("status.roadDrag", { count: fresh, cost: amountText(cost) });
    }
    if (tool.kind === "build" && this.hover && this.data.buildings[tool.type].kind !== "road") {
      const chk = this.check;
      if (chk && !chk.ok) return reasonText(chk.reasons[0]);
    }
    if (tool.kind === "build") {
      const def = this.data.buildings[tool.type];
      const cost = amountText(def.cost);
      return def.kind === "road" ? i18n.t("status.placingRoad", { cost }) : i18n.t("status.placing", { name: buildingName(tool.type), cost });
    }
    if (tool.kind === "demolish") {
      const b = this.hover && this.state.buildingAt(this.hover[0], this.hover[1]);
      if (b) {
        const cost = this.data.buildings[b.type].cost;
        const refund = {};
        for (const [k, v] of Object.entries(cost)) refund[k] = Math.floor(v * this.data.economy.refund);
        return i18n.t("status.demolishHover", { name: buildingName(b.type), refund: amountText(refund) });
      }
      return i18n.t("status.demolish");
    }
    if (this.hover && !onUi) {
      const [c, r] = this.hover;
      const b = this.state.buildingAt(c, r);
      if (b) return this.buildingStatus(b, c, r);
      return i18n.t("status.terrain", { terrain: i18n.t(`terrain.${this.state.map.terrainAt(c, r)}`), c, r });
    }
    return this.state.clock.speed === 0 ? i18n.t("status.paused") : i18n.t("status.idle");
  }

  /** What the player sees when the mouse rests on a building: the villagers of a house, the workers and the state of a workplace. */
  buildingStatus(b, c, r) {
    const def = this.data.buildings[b.type];
    const rt = this.state.sim.rt.get(b.id);
    const name = buildingName(b.type);
    if (rt && def.housing) return i18n.t("status.house", { name, c, r, n: rt.residents.length, count: def.housing, cap: def.housing });
    if (rt && def.workers) {
      const state = rt.stall && def.recipes && def.recipes.length ? i18n.t(`sim.stall.${rt.stall}`) : i18n.t("sim.running");
      return i18n.t("status.work", { name, c, r, present: rt.present, workers: def.workers, state });
    }
    return i18n.t("status.building", { name, c, r });
  }
}
