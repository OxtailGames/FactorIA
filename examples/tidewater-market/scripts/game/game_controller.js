// @ts-check
// The game screen (scenes/game.scene.json): turns the mouse and keys into actions on the GameState and keeps the HUD in step.
//
// Who owns what:
//   GameState  (state.js)   all rules and all state; never touches the engine.
//   MapView    (map_view.js) sprites for the state; this controller asks it for the highlight diamonds and the ghost.
//   CameraRig  (camera_rig.js) the strategy camera on the "camera" entity; this controller asks it which cell is under the mouse.
//   this file               tools (build / road / demolish), hover, drag, hotkeys, palette buttons, top bar, status line, toasts.
//
// Later packages: `controller.state` is the state, `controller.state.events` is the event bus (README, "Contracts"). Add new
// HUD items to the bar with `controller.addHudItem`, new palette buttons by adding a building to data/buildings.json.
import { Behaviour, ui, input, i18n, game } from "factoria";
import { getData } from "./data.js";
import { createGame } from "./state.js";
import { MapView, COLORS } from "./map_view.js";
import { footprintCells, roadPath } from "./rules.js";
import { cellToWorld, mapBounds } from "./iso.js";
import { amountText, buildingName, dateText, reasonText, stepText } from "./format.js";

const COLOR_BUTTON = [0.17, 0.21, 0.28, 1];
const COLOR_BUTTON_ACTIVE = [0.33, 0.52, 0.72, 1];
const BAR_COLOR = [0.05, 0.07, 0.1, 0.88];
/** Presses closer together than this many pixels are a click, not a drag (right-click cancels the tool). */
const CLICK_SLOP = 6;

export default class GameController extends Behaviour {
  /** Map seed; 0 = the default seed of data/map.json. A scene prop `seed` overrides it. */
  seed = 0;
  /** Use the small hand-made map of data/test_map.json (tests). A scene prop `testMap` overrides it. */
  testMap = false;
  /** Seconds a toast stays on screen. */
  toastSeconds = 3;

  onStart() {
    const props = game.sceneProps();
    const seed = props.seed !== undefined ? props.seed : this.seed;
    const testMap = props.testMap !== undefined ? props.testMap : this.testMap;
    this.data = getData();
    this.state = createGame({ data: this.data, seed: seed || undefined, testMap });
    this.view = new MapView(this.state);
    this.cameraEntity = this.world.find("camera");
    /** @type {import("./camera_rig.js").default} */
    this.rig = this.cameraEntity.behaviour;
    const map = this.state.map;
    this.rig.setBounds(mapBounds(map.width, map.height));
    const [cx, cy] = cellToWorld(Math.floor(map.width / 2), Math.floor(map.height / 2));
    this.rig.setView(cx, cy, this.rig.startZoom);

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
    this.shown = { coins: "", date: "", goods: {}, status: "" };

    this.hudBar = this.world.find("hud_bar");
    this.palette = this.world.find("palette");
    this.statusBar = this.world.find("status_bar");
    this.statusText = this.world.find("status_text");
    this.toastText = this.world.find("toast");
    this.coinsText = this.world.find("coins_text");
    this.dateTextEntity = this.world.find("hud_date");
    this.uiPanels = [this.hudBar, this.palette, this.statusBar, this.dateTextEntity];
    this.buildHud();
    this.buildPalette();

    const ev = this.state.events;
    this.off = [
      ev.on("action.rejected", (e) => this.onRejected(e)),
      ev.on("history.changed", () => this.refreshButtons()),
      i18n.on("change", () => this.buildPaletteLabels()),
      ui.on("click", (e) => this.onClick(e.id)),
    ];
    this.refreshButtons();
    this.refreshHud(true);
  }

  onDestroy() {
    for (const off of this.off || []) off();
    this.off = [];
    if (this.view) this.view.destroy();
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
      { id: `${id}_text`, components: { Text: { text, fontSize: 22, space: "screen", layer: 210 } } },
      { parent: this.hudBar },
    );
  }

  /** The right-hand palette: one button per building (data/buildings.json order), then Demolish, Rotate, Undo, Redo. */
  buildPalette() {
    this.buttons = {};
    const make = (id, interactable = true) => {
      const e = this.world.spawn(
        {
          id,
          components: {
            Button: { text: id, size: [236, 34], fontSize: 20, layer: 210, color: COLOR_BUTTON, interactable },
          },
        },
        { parent: this.palette },
      );
      this.buttons[id] = e;
      return e;
    };
    for (const type of this.data.buildingIds) make(`tool_${type}`);
    make("tool_demolish");
    make("btn_rotate");
    make("btn_undo");
    make("btn_redo");
    this.buildPaletteLabels();
  }

  buildPaletteLabels() {
    for (const type of this.data.buildingIds) {
      const coins = this.data.buildings[type].cost.coins || 0;
      this.buttons[`tool_${type}`].get("Button").text = i18n.t("hud.item", { name: buildingName(type), coins });
    }
    this.buttons.tool_demolish.get("Button").text = i18n.t("hud.demolish");
    this.buttons.btn_rotate.get("Button").text = i18n.t("hud.rotate");
    this.buttons.btn_undo.get("Button").text = i18n.t("hud.undo");
    this.buttons.btn_redo.get("Button").text = i18n.t("hud.redo");
  }

  /** Highlight the active tool's button; grey Undo / Redo out when there is nothing to undo / redo. */
  refreshButtons() {
    for (const type of this.data.buildingIds) {
      this.buttons[`tool_${type}`].get("Button").color = this.tool.kind === "build" && this.tool.type === type ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON;
    }
    this.buttons.tool_demolish.get("Button").color = this.tool.kind === "demolish" ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON;
    this.buttons.btn_undo.get("Button").interactable = this.state.canUndo();
    this.buttons.btn_redo.get("Button").interactable = this.state.canRedo();
  }

  /** Write the numbers into the bar; a Text is only touched when its string changed. */
  refreshHud(force = false) {
    const eco = this.state.economy;
    const coins = String(eco.coins);
    if (force || coins !== this.shown.coins) {
      this.shown.coins = coins;
      this.coinsText.get("Text").text = coins;
    }
    for (const id of Object.keys(this.goodTexts)) {
      const n = String(eco.get(id));
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

  rotate() {
    this.tool.rot = (this.tool.rot + 1) % 4;
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
    if (id.startsWith("tool_") && id !== "tool_demolish") this.selectBuilding(id.slice(5));
    else if (id === "tool_demolish") this.selectDemolish();
    else if (id === "btn_rotate") this.rotate();
    else if (id === "btn_undo") this.undo();
    else if (id === "btn_redo") this.redo();
  }

  // ---- the frame ---------------------------------------------------------------------------------------------------

  /** Is the point over the HUD (a widget or a bar)? Then a click is not meant for the map. */
  overUi(m) {
    if (ui.hovered) return true;
    for (const e of this.uiPanels) {
      const r = ui.rectOf(e);
      if (r && m.x >= r.x && m.x < r.x + r.w && m.y >= r.y && m.y < r.y + r.h) return true;
    }
    return false;
  }

  onUpdate(dt) {
    const m = input.mouse.position;
    this.state.clock.advance(dt); // P1: the clock is paused (speed 0), so this does nothing yet; P2 sets the speed

    this.keys();
    const onUi = this.overUi(m);
    this.hover = null;
    if (!onUi && !this.rig.dragging) {
      const [c, r] = this.rig.screenToCell(m.x, m.y);
      if (this.state.map.inBounds(c, r)) this.hover = [c, r];
    }
    this.mouse(m, onUi);
    this.draw();
    this.refreshHud();
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
    if (input.pressed("tool_cancel")) this.clearTool();
    const ids = this.data.buildingIds;
    for (let i = 0; i < Math.min(9, ids.length); i++) if (input.pressed(`tool_${i + 1}`)) this.selectBuilding(ids[i]);
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
      if (moved < CLICK_SLOP && !this.rightConsumed && this.tool.kind !== "none") this.clearTool();
      this.rightPress = null;
    }

    if (input.pressed("primary")) {
      this.pressOnMap = !onUi && !!this.hover;
      if (this.pressOnMap) this.beginPress();
    }
    if (this.drag && this.hover) this.continueDrag();
    if (input.released("primary")) {
      if (this.drag) this.finishDrag();
      this.pressOnMap = false;
    }
    if (this.drag && !input.down("primary")) this.drag = null; // lost the release (focus change)
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
      this.drag = { kind: "demolish", cells: [[c, r]], last: [c, r] };
    }
  }

  continueDrag() {
    const [c, r] = this.hover;
    const drag = this.drag;
    if (drag.kind === "road") drag.to = [c, r];
    else if (drag.kind === "demolish" && (c !== drag.last[0] || r !== drag.last[1])) {
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
    const hovered = ui.hovered;
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
      if (b) return i18n.t("status.building", { name: buildingName(b.type), c, r });
      return i18n.t("status.terrain", { terrain: i18n.t(`terrain.${this.state.map.terrainAt(c, r)}`), c, r });
    }
    return i18n.t("status.idle");
  }
}
