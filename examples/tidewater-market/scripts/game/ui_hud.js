// @ts-check
// The in-game interface (P3): the build menu, the inspector, the goods table, the charts, the help, the notifications, the
// tooltips, the overlays and the drag of a worker. The GameController owns one Hud (`controller.hud`) and calls it once a frame.
//
// How a later package adds something (README, "Interface (P3)"):
//   a panel          hud.addPanel("name", { root, refresh, every? })  then hud.open("name") / hud.toggle("name")
//                    (Esc closes the open panels, newest first; a panel is a Panel entity you spawn with ui_kit.js)
//   a tooltip        hud.tooltips.add(entity, () => ({ title, lines: [{ text, color? }] }))   (return null for "none now")
//   a notification   hud.notices.push("key", args, cell, buildingId, "warn" | "bad")  with the text in locales ui.notice.<key>
//   an overlay       hud.addOverlay("id", { color: [r, g, b], field(state, hud) -> { values: Float32Array, cells: number[] } })
//                    the name and hint are the locale strings ui.overlay.<id> and ui.overlay.hint.<id>
//   a shortcut       an action in factoria.json, then hud.onKey("action", () => ...)
// P6: the pointer is scripts/game/pointer.js (mouse or gamepad cursor); the options of settings.live() change how the HUD looks and
// behaves (safeColors: marks besides colours, reducedMotion: no fading, holdFree: click to carry a worker instead of dragging it).
import { world, ui, input, i18n } from "factoria";
import { pointer } from "./pointer.js";
import { live } from "../settings.js";
import { cellToWorld } from "./iso.js";
import { COLORS as MAP_COLORS, LAYER as MAP_LAYER } from "./map_view.js";
import { footprintCells } from "./rules.js";
import { amountText, buildingName, compactText, coinsText, dateText, goodsBagText, listText, numberText, villagersText } from "./format.js";
import { DESIGN } from "./camera_math.js";
import {
  COLORS, FONT, LAYER, Tooltips, button, icon, inside, isActive, label, panel, rule, setActive, setIcon,
} from "./ui_kit.js";
import {
  COVERAGE, GOODS_COLUMNS, Notices, Recorder, SHORTCUTS, Traffic, canDropWorker, categories, centreOf, describeBuilding,
  describeVillager, goodsRows, overlayField, rotatable, walkerNear,
} from "./ui_model.js";

const t = (key, args) => i18n.t(`ui.${key}`, args);
const CLEAR = [0, 0, 0, 0];
const ICON_BOX = 44;
/** The pool sizes (the inspector shows at most this many worker chips, the notices stack this many). */
const CHIPS = 4;
const NOTICE_SLOTS = 5;
const CHART_POINTS = 40;
/** A press that moves more than this many pixels before the release is a drag. */
const DRAG_SLOP = 6;
/** The most shapes an overlay draws in one frame (the cells in view; the map has 100 x 100 cells; a safe-colours cell takes three). */
const OVERLAY_BUDGET = 1500;
const COLUMN_WIDTHS = { name: 200, stock: 100, made: 100, used: 100, price: 90 };
const ROW_H = 28; // a row of the goods table: the text may grow to 120 % (TABLE_CAP) of its size and still fit
const TABLE_CAP = 1.2;
const ROWS_SHOWN = 7;
/** The pip an overlay cell gets in the colour-blind safe mode: a white mark on a dark plate, so it reads on any tint and any roof. */
const PIP = [1, 1, 1, 1];
const PIP_PLATE = [0.04, 0.05, 0.1, 0.9];
/** Pixels between the bottom of the inspector and the bottom of the screen (the status line sits there). */
const INSPECTOR_BOTTOM = 38;
const SEV_COLORS = { warn: [0.62, 0.45, 0.12, 1], bad: [0.6, 0.2, 0.18, 1] };

export class Hud {
  /** @param {import("./game_controller.js").default} ctl */
  constructor(ctl) {
    this.ctl = ctl;
    this.state = ctl.state;
    this.data = ctl.data;
    this.rig = ctl.rig;
    this.recorder = new Recorder(this.state);
    this.notices = new Notices(this.state);
    this.traffic = new Traffic(this.state);
    this.tooltips = new Tooltips();
    /** @type {{ kind: "building" | "villager", id: number } | null} */
    this.sel = null;
    this.cats = categories(this.data);
    this.cat = this.cats[0].id;
    this.buildOpen = false;
    /** @type {Map<string, { root: any, refresh: () => void, every: number, since: number }>} */
    this.panels = new Map();
    /** Open panels in the order they were opened (Esc closes the last). */
    this.openOrder = [];
    this.sort = { column: "name", dir: 1 };
    this.chartGood = this.data.goodIds.includes("grain") ? "grain" : this.data.goodIds[0];
    /** @type {Map<string, { label: string, color: number[], field: (state: any, hud: Hud) => any }>} */
    this.overlays = new Map();
    this.overlay = null;
    this.overlayCache = null;
    this.overlayDirty = true;
    this.overlayClock = 0;
    this.keyHandlers = new Map();
    this.mouse = { x: 0, y: 0 };
    /** The drag of a worker chip: { villager, startX, startY, active, over } or null. */
    this.chipDrag = null;
    this.shown = {};
    this.chipVillagers = [];
    this.chipDragged = false;
    this.noticeSlots = [];

    this.buildRightColumn();
    this.buildBar();
    this.buildInspector();
    this.buildGoodsPanel();
    this.buildChartsPanel();
    this.buildHelpPanel();
    this.buildNoticeStack();
    this.buildOverlayLegend();
    this.buildDragChip();
    this.registerTooltips();
    this.addOverlay("desirability", { label: "desirability", color: [0.45, 0.9, 0.35], field: (s) => overlayField(s, "desirability") });
    this.addOverlay("market", { label: "market", color: [1, 0.8, 0.25], field: (s) => overlayField(s, "market") });
    this.addOverlay("warehouse", { label: "warehouse", color: [0.4, 0.7, 1], field: (s) => overlayField(s, "warehouse") });
    this.addOverlay("traffic", { label: "traffic", color: [1, 0.45, 0.25], field: (s) => overlayField(s, "traffic", this.traffic) });
    const ev = this.state.events;
    this.off = [
      ev.on("building.placed", () => (this.overlayDirty = true)),
      ev.on("building.removed", () => (this.overlayDirty = true)),
      ev.on("roads.changed", () => (this.overlayDirty = true)),
      ev.on("economy.changed", () => (this.shown.affordKey = "")),
      i18n.on("change", () => this.relabel()),
    ];
    this.relabel();
  }

  destroy() {
    for (const off of this.off) off();
    this.recorder.destroy();
    this.notices.destroy();
    this.traffic.destroy();
  }

  // ---- registries for the later packages ------------------------------------------------------------------------------------

  /** Register a panel: root = its Panel entity (hidden until opened), refresh() redraws it (called when it opens and every `every` seconds). */
  addPanel(name, { root, refresh = () => {}, every = 0.5 }) {
    setActive(root, false);
    this.panels.set(name, { root, refresh, every, since: 0 });
  }

  isOpen(name) {
    const p = this.panels.get(name);
    return !!p && isActive(p.root);
  }

  open(name) {
    const p = this.panels.get(name);
    if (!p || this.isOpen(name)) return;
    setActive(p.root, true);
    this.openOrder.push(name);
    p.since = 0;
    p.refresh();
  }

  close(name) {
    const p = this.panels.get(name);
    if (!p || !this.isOpen(name)) return;
    setActive(p.root, false);
    this.openOrder = this.openOrder.filter((n) => n !== name);
  }

  toggle(name) {
    if (this.isOpen(name)) this.close(name);
    else this.open(name);
  }

  /** Register an overlay the HUD button cycles through. field(state, hud) -> { values: Float32Array (0..1 per cell), cells: number[] (indexes worth drawing) }. */
  addOverlay(id, spec) {
    this.overlays.set(id, spec);
  }

  /** Run `fn` when the action is pressed (an input action of factoria.json). */
  onKey(action, fn) {
    this.keyHandlers.set(action, fn);
  }

  // ---- building the panels ----------------------------------------------------------------------------------------------------

  buildRightColumn() {
    const col = this.column = world.find("palette");
    col.get("Panel").uniformSize = true;
    this.rightButtons = {};
    const make = (id) => {
      this.rightButtons[id] = button(id, col, id, { size: [138, 30], autoSize: true, fontSize: FONT.body, layer: LAYER.bar + 10 });
    };
    for (const id of ["btn_build", "tool_demolish", "btn_rotate", "btn_undo", "btn_redo", "btn_goods", "btn_charts", "btn_overlay", "btn_help"]) make(id);
  }

  buildBar() {
    this.bar = panel("build_bar", null, {
      anchor: [0, 1], pivot: [0, 0], position: [8, -38, 0], layout: "column", fit: true, spacing: 6, padding: [8, 6, 8, 8], align: "start",
    });
    this.tabs = panel("build_tabs", this.bar, { layout: "row", fit: true, spacing: 4, padding: [0, 0, 0, 0], color: CLEAR });
    /** @type {Record<string, any>} */
    this.tabButtons = {};
    /** @type {Record<string, any>} */
    this.itemRows = {};
    /** @type {Record<string, any>} */
    this.itemButtons = {};
    for (const c of this.cats) {
      this.tabButtons[c.id] = button(`cat_${c.id}`, this.tabs, c.id, { size: [112, 28], autoSize: true, fontSize: FONT.body });
      const row = panel(`build_items_${c.id}`, this.bar, { layout: "grid", columns: Math.min(c.buildings.length, 5), fit: true, spacing: 6, padding: [0, 0, 0, 0], color: CLEAR, align: "center" });
      this.itemRows[c.id] = row;
      for (const type of c.buildings) {
        const item = panel(`item_${type}`, row, { layout: "column", fit: true, spacing: 2, padding: [0, 0, 0, 0], color: CLEAR, align: "center" });
        icon(`item_icon_${type}`, item, this.data.atlas, type === "road" ? "road.road" : `building.${type}.0`, ICON_BOX);
        this.itemButtons[type] = button(`tool_${type}`, item, type, { size: [118, 44], autoSize: true, maxWidth: 90, fontSize: FONT.small });
      }
    }
    this.addPanel("build", { root: this.bar, refresh: () => this.refreshBar(), every: 0.25 });
  }

  buildInspector() {
    this.inspRoot = panel("inspector", null, {
      anchor: [1, 1], pivot: [1, 0], position: [-8, -38, 0], layout: "column", fit: true, spacing: 4, padding: [10, 8, 10, 8], align: "start",
    });
    rule("inspector_rule", this.inspRoot, 292, 2, CLEAR);
    this.inspLines = [];
    const sizes = [FONT.title, FONT.body, FONT.body, FONT.body, null, FONT.small, FONT.body, FONT.body, FONT.body, FONT.body, FONT.body, FONT.small];
    for (let i = 0; i < sizes.length; i++) {
      if (sizes[i] === null) {
        this.chipRow = panel("insp_chips", this.inspRoot, { layout: "row", fit: true, spacing: 4, padding: [0, 0, 0, 0], color: CLEAR });
        this.chips = [];
        for (let k = 0; k < CHIPS; k++) this.chips.push(button(`chip_${k}`, this.chipRow, "#0", { size: [58, 26], autoSize: true, fontSize: FONT.small }));
        this.inspLines.push(null);
      } else {
        this.inspLines.push(label(`insp_line_${i}`, this.inspRoot, "", { fontSize: sizes[i], maxWidth: 292 }));
      }
    }
    this.inspButtons = panel("insp_buttons", this.inspRoot, { layout: "row", fit: true, spacing: 4, padding: [0, 2, 0, 0], color: CLEAR });
    /** @type {Record<string, any>} */
    this.inspBtn = {};
    for (const id of ["rotate", "demolish", "home", "job", "release", "close"]) {
      this.inspBtn[id] = button(`insp_${id}`, this.inspButtons, id, { size: [64, 28], autoSize: true, fontSize: FONT.small });
    }
    this.addPanel("inspector", { root: this.inspRoot, refresh: () => this.refreshInspector(), every: 0.1 });
  }

  buildGoodsPanel() {
    const root = panel("goods_panel", null, {
      anchor: [0.5, 0.5], pivot: [0.5, 0.5], layout: "column", fit: true, spacing: 6, padding: [14, 10, 14, 12], align: "start",
    });
    const head = panel("goods_head", root, { layout: "row", fit: true, spacing: 12, padding: [0, 0, 0, 0], color: CLEAR });
    this.goodsTitle = label("goods_title", head, "", { fontSize: FONT.title, color: COLORS.gold });
    button("goods_close", head, "x", { size: [30, 26], fontSize: FONT.body });
    const widthSum = GOODS_COLUMNS.reduce((n, c) => n + COLUMN_WIDTHS[c], 0);
    const header = panel("goods_header", root, { layout: "row", fit: true, spacing: 0, padding: [0, 0, 0, 0], color: CLEAR });
    this.sortButtons = {};
    for (const c of GOODS_COLUMNS) this.sortButtons[c] = button(`gsort_${c}`, header, c, { size: [COLUMN_WIDTHS[c], 28], fontSize: FONT.small + 1, maxTextScale: TABLE_CAP });
    this.goodsList = world.spawn(
      { id: "goods_list", components: { Transform: { position: [0, 0, 0] }, ScrollList: { size: [widthSum, ROW_H * ROWS_SHOWN], pivot: [0, 1], padding: [0, 0, 0, 0], spacing: 0, color: [0, 0, 0, 0.25], layer: LAYER.panel + 2 } } },
      { parent: root },
    );
    this.goodsRows = [];
    const x = {};
    let acc = 0;
    for (const c of GOODS_COLUMNS) {
      acc += COLUMN_WIDTHS[c];
      x[c] = acc - 10;
    }
    this.data.goodIds.forEach((id, i) => {
      const row = panel(`grow_${i}`, this.goodsList, { layout: "none", size: [widthSum, ROW_H], pivot: [0, 1], color: i % 2 ? [1, 1, 1, 0.05] : CLEAR, padding: [0, 0, 0, 0], layer: LAYER.panel + 3 });
      const cells = {
        icon: icon(`grow_${i}_icon`, row, this.data.atlas, this.data.goods[id].icon, 20, { position: [16, ROW_H / 2, 0] }),
        name: label(`grow_${i}_name`, row, "", { position: [34, 3, 0], maxTextScale: TABLE_CAP }),
      };
      for (const c of ["stock", "made", "used", "price"]) cells[c] = label(`grow_${i}_${c}`, row, "", { position: [x[c], 3, 0], pivot: [1, 1], maxTextScale: TABLE_CAP });
      this.goodsRows.push({ root: row, cells, good: id });
    });
    this.addPanel("goods", { root, refresh: () => this.refreshGoods(), every: 0.5 });
  }

  buildChartsPanel() {
    const root = panel("charts_panel", null, {
      anchor: [0.5, 0.5], pivot: [0.5, 0.5], layout: "column", fit: true, spacing: 6, padding: [14, 10, 14, 12], align: "start",
    });
    const head = panel("charts_head", root, { layout: "row", fit: true, spacing: 12, padding: [0, 0, 0, 0], color: CLEAR });
    this.chartsTitle = label("charts_title", head, "", { fontSize: FONT.title, color: COLORS.gold });
    this.chartGoodButton = button("chart_good", head, "", { size: [150, 26], fontSize: FONT.small, autoSize: true });
    button("charts_close", head, "x", { size: [30, 26], fontSize: FONT.body });
    this.chartMoneyLabel = label("chart_money_label", root, "", { fontSize: FONT.small, color: COLORS.dim });
    this.moneyChart = this.makeChart("chart_money", root, "line");
    this.chartMadeLabel = label("chart_made_label", root, "", { fontSize: FONT.small, color: COLORS.dim });
    this.madeChart = this.makeChart("chart_made", root, "bars");
    this.addPanel("charts", { root, refresh: () => this.refreshCharts(), every: 1 });
  }

  /** A chart area: a dark panel with a pool of lines (a polyline) or bars, the min and max labels and a line per season boundary. */
  makeChart(id, parent, kind, w = 540, h = 110) {
    const area = panel(id, parent, { layout: "none", size: [w, h], pivot: [0, 1], color: [0, 0, 0, 0.35], padding: [0, 0, 0, 0] });
    const marks = [];
    for (let i = 0; i < 8; i++) marks.push(this.lineShape(`${id}_season_${i}`, area, [1, 1, 1, 0.16], 1));
    const items = [];
    for (let i = 0; i < CHART_POINTS; i++) {
      if (kind === "line") items.push(this.lineShape(`${id}_seg_${i}`, area, [1, 0.82, 0.38, 1], 2));
      else {
        items.push(world.spawn(
          { id: `${id}_bar_${i}`, components: { Transform: { position: [0, 0, 0] }, Shape2D: { shape: "rectangle", size: [8, 4], pivot: [0, 1], space: "screen", color: [0.55, 0.78, 1, 1], layer: LAYER.panel + 6 } } },
          { parent: area },
        ));
      }
    }
    const top = label(`${id}_max`, area, "", { position: [4, 2, 0], fontSize: FONT.small - 2, color: COLORS.dim });
    const bottom = label(`${id}_min`, area, "", { position: [4, h - 16, 0], fontSize: FONT.small - 2, color: COLORS.dim });
    const left = label(`${id}_from`, area, "", { position: [w - 4, h - 16, 0], pivot: [1, 1], fontSize: FONT.small - 2, color: COLORS.dim });
    return { id, area, kind, w, h, marks, items, top, bottom, left, points: [] };
  }

  lineShape(id, parent, color, thickness) {
    return world.spawn(
      { id, components: { Transform: { position: [0, 0, 0] }, Shape2D: { shape: "line", size: [0, 0], space: "screen", color, thickness, layer: LAYER.panel + 6 } } },
      { parent },
    );
  }

  buildHelpPanel() {
    const root = panel("help_panel", null, {
      anchor: [0.5, 0.5], pivot: [0.5, 0.5], layout: "column", fit: true, spacing: 8, padding: [18, 12, 18, 14], align: "start",
    });
    const head = panel("help_head", root, { layout: "row", fit: true, spacing: 30, padding: [0, 0, 0, 0], color: CLEAR });
    this.helpTitle = label("help_title", head, "", { fontSize: FONT.title, color: COLORS.gold });
    button("help_close", head, "x", { size: [30, 26], fontSize: FONT.body });
    const body = panel("help_body", root, { layout: "row", fit: true, spacing: 24, padding: [0, 0, 0, 0], color: CLEAR, align: "start" });
    this.helpKeys = label("help_keys", body, "", { fontSize: FONT.body, color: COLORS.gold });
    this.helpActions = label("help_actions", body, "", { fontSize: FONT.body });
    this.helpHint = label("help_hint", root, "", { fontSize: FONT.small, color: COLORS.dim, maxWidth: 480 });
    this.addPanel("help", { root, refresh: () => {} });
  }

  buildNoticeStack() {
    this.noticeRoot = panel("notices", null, {
      anchor: [0, 0], pivot: [0, 1], position: [8, 90, 0], layout: "column", fit: true, spacing: 3, padding: [0, 0, 0, 0], color: CLEAR, align: "start", layer: LAYER.notice,
    });
    this.noticeButtons = [];
    for (let i = 0; i < NOTICE_SLOTS; i++) {
      const b = button(`notice_${i}`, this.noticeRoot, "", { size: [330, 28], fontSize: FONT.small + 1, autoSize: true, maxWidth: 300, layer: LAYER.notice + 5 });
      setActive(b, false);
      this.noticeButtons.push(b);
    }
    this.noticeSlots = new Array(NOTICE_SLOTS).fill(null);
  }

  buildOverlayLegend() {
    this.legend = label("overlay_legend", null, "", { anchor: [0.5, 0], pivot: [0.5, 1], position: [0, 54, 0], fontSize: FONT.body, color: COLORS.gold, layer: LAYER.notice });
    setActive(this.legend, false);
  }

  buildDragChip() {
    this.chip = panel("drag_chip", null, { layout: "row", fit: true, padding: [8, 4, 8, 4], pivot: [0, 1], color: [0.2, 0.35, 0.55, 0.95], layer: LAYER.drag });
    this.chipText = label("drag_chip_text", this.chip, "", { fontSize: FONT.small + 1, layer: LAYER.drag + 5 });
    setActive(this.chip, false);
  }

  // ---- labels (every string the panels show; run again when the language changes) --------------------------------------------------------

  relabel() {
    const set = (id, text) => (this.rightButtons[id].get("Button").text = text);
    set("btn_build", t("btn.build"));
    set("tool_demolish", i18n.t("hud.demolish"));
    set("btn_rotate", i18n.t("hud.rotate"));
    set("btn_undo", i18n.t("hud.undo"));
    set("btn_redo", i18n.t("hud.redo"));
    set("btn_goods", t("btn.goods"));
    set("btn_charts", t("btn.charts"));
    set("btn_help", t("btn.help"));
    this.relabelOverlayButton();
    for (const c of this.cats) this.tabButtons[c.id].get("Button").text = t(`cat.${c.id}`);
    for (const c of this.cats) {
      for (const type of c.buildings) {
        const def = this.data.buildings[type];
        this.itemButtons[type].get("Button").text = `${buildingName(type)}\n${amountText(def.cost)}`;
      }
    }
    this.goodsTitle.get("Text").text = t("goods.title");
    this.chartsTitle.get("Text").text = t("charts.title");
    this.helpTitle.get("Text").text = t("help.title");
    this.helpKeys.get("Text").text = SHORTCUTS.map((s) => (i18n.has(`ui.help.keys.${s.action}`) ? t(`help.keys.${s.action}`) : s.keys)).join("\n");
    this.helpActions.get("Text").text = SHORTCUTS.map((s) => t(`help.${s.action}`)).join("\n");
    this.helpHint.get("Text").text = t("help.hint");
    this.shown = {};
    this.refreshGoodsHeader();
    // the open panels write their numbers and names again now, not at their next timer tick (up to a second later)
    for (const [name, panel] of this.panels) if (this.isOpen(name)) panel.refresh();
  }

  relabelOverlayButton() {
    const b = this.rightButtons.btn_overlay.get("Button");
    b.text = t("btn.overlay");
    b.color = this.overlay ? COLORS.buttonActive : COLORS.button;
  }

  // ---- clicks ------------------------------------------------------------------------------------------------------------------------

  /** A ui.click on a widget id. @returns {boolean} true when the Hud handled it */
  onClick(id) {
    const ctl = this.ctl;
    if (id === "btn_build") return this.toggleBuild(), true;
    if (id.startsWith("cat_")) return this.setCategory(id.slice(4)), true;
    if (id === "btn_goods") return this.toggle("goods"), true;
    if (id === "btn_charts") return this.toggle("charts"), true;
    if (id === "btn_help") return this.toggle("help"), true;
    if (id === "btn_overlay") return this.cycleOverlay(), true;
    if (id === "goods_close") return this.close("goods"), true;
    if (id === "charts_close") return this.close("charts"), true;
    if (id === "help_close") return this.close("help"), true;
    if (id === "chart_good") return this.cycleChartGood(), true;
    if (id.startsWith("gsort_")) return this.sortBy(id.slice(6)), true;
    if (id.startsWith("notice_")) return this.clickNotice(Number(id.slice(7))), true;
    if (id.startsWith("chip_")) {
      if (this.chipDragged) {
        this.chipDragged = false;
        return true;
      }
      const vid = this.chipVillagers[Number(id.slice(5))];
      if (vid) this.select("villager", vid);
      return true;
    }
    if (id.startsWith("insp_")) return this.inspectorAction(id.slice(5)), true;
    if (id === "btn_rotate") {
      ctl.rotate();
      return true;
    }
    return false;
  }

  toggleBuild() {
    this.setBuildOpen(!this.buildOpen);
  }

  setBuildOpen(on) {
    this.buildOpen = on;
    if (on) this.open("build");
    else this.close("build");
  }

  setCategory(id) {
    if (!this.itemRows[id]) return;
    this.cat = id;
    this.refreshBar();
  }

  /** The shoulder buttons: the next or the previous build category (the first press opens the build menu on the current one). */
  stepCategory(step) {
    if (!this.buildOpen) return this.setBuildOpen(true);
    const ids = this.cats.map((c) => c.id);
    this.setCategory(ids[(ids.indexOf(this.cat) + step + ids.length) % ids.length]);
  }

  sortBy(column) {
    if (!GOODS_COLUMNS.includes(column)) return;
    if (this.sort.column === column) this.sort.dir = -this.sort.dir;
    else this.sort = { column, dir: column === "name" ? 1 : -1 };
    this.refreshGoods();
  }

  cycleChartGood() {
    const ids = this.data.goodIds;
    this.chartGood = ids[(ids.indexOf(this.chartGood) + 1) % ids.length];
    this.refreshCharts();
  }

  cycleOverlay() {
    const ids = [...this.overlays.keys()];
    const at = this.overlay ? ids.indexOf(this.overlay) : -1;
    this.setOverlay(at + 1 >= ids.length ? null : ids[at + 1]);
  }

  setOverlay(id) {
    this.overlay = id && this.overlays.has(id) ? id : null;
    this.overlayDirty = true;
    this.relabelOverlayButton();
    setActive(this.legend, !!this.overlay);
    if (this.overlay) this.legend.get("Text").text = t("overlay.legend", { name: t(`overlay.${this.overlay}`), hint: t(`overlay.hint.${this.overlay}`) });
  }

  // ---- selection and the inspector -------------------------------------------------------------------------------------------------------

  select(kind, id) {
    this.sel = { kind, id };
    this.open("inspector");
    this.refreshInspector();
  }

  deselect() {
    this.sel = null;
    this.close("inspector");
  }

  /**
   * A click on the map with no tool: a villager under the pointer, else the building on the cell. Empty ground clears the
   * selection. @returns {boolean} true when something is selected now
   */
  pickAt(mouse, cell) {
    const [wx, wy] = this.rig.screenToWorld(mouse.x, mouse.y);
    const zoom = this.rig.view.zoom;
    const vid = walkerNear(this.state, wx, wy, 18 / Math.max(zoom, 0.5), cellToWorld);
    if (vid) {
      this.select("villager", vid);
      return true;
    }
    const b = cell ? this.state.buildingAt(cell[0], cell[1]) : null;
    if (b && this.state.data.buildings[b.type].kind !== "road") {
      this.select("building", b.id);
      return true;
    }
    this.deselect();
    return false;
  }

  /** The id of the selected building, or 0. */
  selectedBuilding() {
    return this.sel && this.sel.kind === "building" && this.state.buildings.has(this.sel.id) ? this.sel.id : 0;
  }

  /** Turn the selected building on the spot (R with a selection, the inspector's Rotate). @returns {boolean} done */
  rotateSelected() {
    const id = this.selectedBuilding();
    if (!id) return false;
    const res = this.state.rotateBuilding(id);
    if (res.ok) {
      this.sel = { kind: "building", id: res.building.id };
      this.ctl.toast(t("toast.rotated", { name: buildingName(res.building.type) }));
    }
    return true;
  }

  /** Demolish the selected building (Delete, the inspector's Demolish). @returns {boolean} done */
  demolishSelected() {
    const id = this.selectedBuilding();
    if (!id) return false;
    const b = this.state.buildings.get(id);
    const res = this.state.demolish(b.x, b.y);
    if (res.ok) {
      this.ctl.toast(i18n.t("toast.demolished", { name: buildingName(b.type) }));
      this.deselect();
    }
    return true;
  }

  inspectorAction(action) {
    const sel = this.sel;
    if (action === "close") return this.deselect();
    if (action === "rotate") return void this.rotateSelected();
    if (action === "demolish") return void this.demolishSelected();
    if (!sel || sel.kind !== "villager") return;
    const v = describeVillager(this.state, sel.id);
    if (!v) return;
    if (action === "home" && v.home) this.jumpTo(v.home.cell);
    if (action === "job" && v.job) this.jumpTo(v.job.cell);
    if (action === "release") {
      this.state.sim.people.release(sel.id);
      this.refreshInspector();
    }
  }

  /** Put the camera over a cell, keeping the zoom. */
  jumpTo(cell) {
    const [x, y] = cellToWorld(cell[0], cell[1]);
    this.rig.moveTo(x, y); // eased, or at once with the "reduced motion" option
  }

  /** Text lines for the inspector: [{ text, color }] (null = hidden) in the slots of `inspLines`. */
  inspectorContent() {
    const sel = this.sel;
    const none = { lines: new Array(this.inspLines.length).fill(null), chips: [], buttons: ["close"] };
    if (!sel) return none;
    const L = none.lines;
    if (sel.kind === "building") {
      const info = describeBuilding(this.state, sel.id);
      if (!info) return none;
      const name = buildingName(info.type);
      L[0] = { text: t("insp.title", { name, c: info.cell[0], r: info.cell[1] }), color: COLORS.gold };
      if (info.kind === "road") return { ...none, lines: L };
      if (!info.connected) L[2] = { text: t("insp.noRoad"), color: COLORS.red };
      const def = info.def;
      if (def.workers) {
        const running = info.stall ? i18n.t(`sim.stall.${info.stall}`) : i18n.t("sim.running");
        L[1] = { text: t("insp.status", { state: running }), color: info.stall && info.stall !== "closed" ? COLORS.red : COLORS.green };
        L[3] = { text: t("insp.workers", { present: info.workers.present, count: info.workers.staff.length, max: info.workers.max }) };
        none.chips = info.workers.staff.map((s) => s.id);
        L[5] = { text: t("insp.dragHint"), color: COLORS.dim };
      }
      if (info.residents) {
        L[1] = { text: t("insp.residents", { count: info.residents.list.length, max: info.residents.max }) };
        none.chips = info.residents.list.slice(0, CHIPS);
        L[5] = { text: t("insp.dragHint"), color: COLORS.dim };
      }
      if (info.recipe) {
        const r = info.recipe.id ? this.data.recipes[info.recipe.id] : info.recipe.all[0];
        L[6] = { text: t("insp.makes", { out: amountText(r.outputs), seconds: r.seconds, percent: Math.round(info.recipe.progress * 100) }) };
        if (Object.keys(r.inputs).length) L[7] = { text: t("insp.needs", { goods: amountText(r.inputs) }) };
      }
      const bag = goodsBagText;
      if (bag(info.inbox)) L[8] = { text: t("insp.inbox", { goods: bag(info.inbox) }) };
      if (bag(info.outbox)) L[9] = { text: t("insp.outbox", { goods: bag(info.outbox) }) };
      if (bag(info.shelf)) L[9] = { text: t("insp.shelf", { goods: bag(info.shelf) }) };
      L[10] = { text: t("insp.money", { upkeep: info.upkeep, refund: info.refund }), color: COLORS.dim };
      none.buttons = info.rotatable ? ["rotate", "demolish", "close"] : ["demolish", "close"];
    } else {
      const v = describeVillager(this.state, sel.id);
      if (!v) return none;
      L[0] = { text: t("insp.villager", { id: v.id }), color: COLORS.gold };
      L[1] = { text: v.walking ? t("insp.walking", { purpose: t(`purpose.${v.purpose || "idle"}`) }) : t("insp.at", { place: v.at ? buildingName(v.at.type) : "?" }) };
      L[2] = { text: v.home ? t("insp.home", { name: buildingName(v.home.type), c: v.home.cell[0], r: v.home.cell[1] }) : t("insp.homeless"), color: v.home ? COLORS.text : COLORS.red };
      L[3] = v.job
        ? { text: t(v.job.pinned ? "insp.jobPinned" : "insp.job", { name: buildingName(v.job.type), c: v.job.cell[0], r: v.job.cell[1] }) }
        : { text: t("insp.noJob"), color: COLORS.red };
      L[6] = v.carrying
        ? { text: t("insp.carrying", { goods: goodsBagText(v.cargo) }) }
        : v.carrier ? { text: t("insp.carrierEmpty") } : null;
      L[7] = { text: v.hungry ? t("insp.hungry") : t("insp.fed", { food: numberText(v.food, 1) }), color: v.hungry ? COLORS.red : COLORS.text };
      none.buttons = ["home", ...(v.job ? ["job"] : []), ...(v.job && v.job.pinned ? ["release"] : []), "close"];
    }
    return none;
  }

  refreshInspector() {
    if (this.sel && ((this.sel.kind === "building" && !this.state.buildings.has(this.sel.id)) || (this.sel.kind === "villager" && !this.state.sim.people.villagers.has(this.sel.id)))) {
      this.sel = null;
      this.close("inspector");
      return;
    }
    const c = this.inspectorContent();
    this.chipVillagers = c.chips;
    c.lines.forEach((line, i) => {
      const e = this.inspLines[i];
      if (!e) return;
      const text = line ? line.text : "";
      setActive(e, !!line);
      if (!line) return;
      const tx = e.get("Text");
      if (tx.text !== text) tx.text = text;
      tx.color = line.color || COLORS.text;
    });
    this.chips.forEach((b, i) => {
      const vid = c.chips[i];
      setActive(b, !!vid);
      if (!vid) return;
      const v = this.state.sim.people.villagers.get(vid);
      const text = `#${vid}${v && v.pin ? "*" : ""}`;
      const bt = b.get("Button");
      if (bt.text !== text) bt.text = text;
      bt.color = this.sel && this.sel.kind === "villager" && this.sel.id === vid ? COLORS.buttonActive : COLORS.button;
    });
    setActive(this.chipRow, c.chips.length > 0);
    for (const [id, e] of Object.entries(this.inspBtn)) {
      const on = c.buttons.includes(id);
      setActive(e, on);
      if (on) e.get("Button").text = t(`insp.btn.${id}`);
    }
  }

  // ---- the build bar -----------------------------------------------------------------------------------------------------------------------

  refreshBar() {
    const ctl = this.ctl;
    // the tab follows the tool when it changes (E / C), not on every refresh: the player may look at another tab
    const toolKey = ctl.tool.kind === "build" ? ctl.tool.type : "";
    if (toolKey !== this.lastTool) {
      this.lastTool = toolKey;
      if (toolKey) this.cat = this.data.buildings[toolKey].category;
    }
    for (const c of this.cats) {
      setActive(this.itemRows[c.id], c.id === this.cat);
      this.tabButtons[c.id].get("Button").color = c.id === this.cat ? COLORS.buttonActive : COLORS.button;
    }
    const eco = this.state.economy;
    for (const [type, b] of Object.entries(this.itemButtons)) {
      const def = this.data.buildings[type];
      const bt = b.get("Button");
      bt.color = ctl.tool.kind === "build" && ctl.tool.type === type ? COLORS.buttonActive : COLORS.button;
      bt.textColor = eco.canAfford(def.cost).ok ? COLORS.text : COLORS.red;
    }
  }

  /** What a building needs and gives, for its tooltip. */
  buildingTip(type) {
    const def = this.data.buildings[type];
    const lines = [{ text: i18n.t(`building.${type}.desc`) }, { text: t("tip.cost", { cost: amountText(def.cost) }), color: COLORS.gold }];
    const needs = [];
    if (def.terrain) needs.push(t("tip.terrain", { terrain: listText(def.terrain.map((x) => i18n.t(`terrain.${x}`))) }));
    if (def.nearWater) needs.push(t("tip.nearWater"));
    if (def.kind !== "road") needs.push(t("tip.road"));
    lines.push({ text: t("tip.needs", { needs: needs.join("; ") }), color: COLORS.blue });
    if (def.housing) lines.push({ text: t("tip.housing", { count: def.housing }), color: COLORS.green });
    if (def.workers) lines.push({ text: t("tip.workers", { count: def.workers, upkeep: coinsText(def.upkeep || 0) }) });
    for (const id of def.recipes || []) {
      const r = this.data.recipes[id];
      const inputs = Object.keys(r.inputs).length ? amountText(r.inputs) : t("tip.nothing");
      lines.push({ text: t("tip.recipe", { inputs, outputs: amountText(r.outputs), seconds: r.seconds }), color: COLORS.green });
    }
    if (def.storage) lines.push({ text: t("tip.storage", { count: def.storage }), color: COLORS.green });
    return { title: buildingName(type), lines };
  }

  // ---- the goods table -----------------------------------------------------------------------------------------------------------------------

  refreshGoodsHeader() {
    for (const c of GOODS_COLUMNS) {
      const arrow = this.sort.column === c ? (this.sort.dir > 0 ? " ^" : " v") : "";
      this.sortButtons[c].get("Button").text = t(`goods.col.${c}`) + arrow;
      this.sortButtons[c].get("Button").color = this.sort.column === c ? COLORS.buttonActive : COLORS.button;
    }
  }

  refreshGoods() {
    this.refreshGoodsHeader();
    const rows = goodsRows(this.state, this.recorder, this.sort, (id) => i18n.t(`good.${id}`));
    rows.forEach((r, i) => {
      const row = this.goodsRows[i];
      row.good = r.id;
      setIcon(row.cells.icon, this.data.atlas, this.data.goods[r.id].icon, 20);
      const set = (cell, text, color = COLORS.text) => {
        const tx = row.cells[cell].get("Text");
        if (tx.text !== text) tx.text = text;
        tx.color = color;
      };
      set("name", r.name);
      set("stock", compactText(r.stock));
      set("made", r.made >= 0.05 ? numberText(r.made, 1) : "-", r.made >= 0.05 ? COLORS.green : COLORS.dim);
      set("used", r.used >= 0.05 ? numberText(r.used, 1) : "-", r.used >= 0.05 ? COLORS.red : COLORS.dim);
      set("price", numberText(r.price), r.price > r.base ? COLORS.green : r.price < r.base ? COLORS.red : COLORS.text);
    });
  }

  /** The row tooltip: what makes and uses a good. */
  goodTip(id) {
    const makers = new Set();
    const users = new Set();
    for (const r of Object.values(this.data.recipes)) {
      if (r.outputs[id]) makers.add(buildingName(r.building));
      if (r.inputs[id]) users.add(buildingName(r.building));
    }
    const g = this.data.goods[id];
    const lines = [];
    lines.push({ text: t("tip.madeIn", { list: makers.size ? listText([...makers]) : t("tip.nowhere") }), color: COLORS.green });
    lines.push({ text: t("tip.usedIn", { list: users.size ? listText([...users]) : t("tip.nowhere") }), color: COLORS.red });
    if (g.nutrition) lines.push({ text: t("tip.eaten", { n: g.nutrition }), color: COLORS.blue });
    lines.push({ text: t("tip.basePrice", { price: coinsText(g.basePrice) }), color: COLORS.dim });
    return { title: i18n.t(`good.${id}`), lines };
  }

  // ---- the charts -------------------------------------------------------------------------------------------------------------------------

  refreshCharts() {
    this.chartGoodButton.get("Button").text = t("charts.good", { name: i18n.t(`good.${this.chartGood}`) });
    this.chartMoneyLabel.get("Text").text = t("charts.money");
    this.chartMadeLabel.get("Text").text = t("charts.made", { name: i18n.t(`good.${this.chartGood}`) });
    this.fillChart(this.moneyChart, this.recorder.money(CHART_POINTS), false);
    this.fillChart(this.madeChart, this.recorder.madePerDay(this.chartGood, CHART_POINTS), true);
  }

  fillChart(chart, pts, zeroBased) {
    chart.points = pts;
    const { w, h } = chart;
    const pad = 16;
    const n = pts.length;
    let lo = Math.min(...pts.map((p) => p.value), zeroBased ? 0 : Infinity);
    let hi = Math.max(...pts.map((p) => p.value), zeroBased ? 1 : -Infinity);
    if (!isFinite(lo)) lo = 0;
    if (!isFinite(hi) || hi <= lo) hi = lo + 1;
    chart.top.get("Text").text = compactText(hi);
    chart.bottom.get("Text").text = compactText(lo);
    const step = n > 1 ? (w - 2 * pad) / (CHART_POINTS - 1) : 0;
    const y = (v) => pad / 2 + (1 - (v - lo) / (hi - lo)) * (h - pad - 6);
    const x = (i) => w - pad - (n - 1 - i) * step;
    chart.left.get("Text").text = n ? t("charts.since", { count: n }) : "";
    if (chart.kind === "line") {
      chart.items.forEach((seg, i) => {
        const on = i < n - 1;
        setActive(seg, on);
        if (!on) return;
        seg.position = [x(i), y(pts[i].value), 0];
        seg.get("Shape2D").size = [x(i + 1) - x(i), -(y(pts[i + 1].value) - y(pts[i].value))];
      });
    } else {
      chart.items.forEach((bar, i) => {
        const on = i < n;
        setActive(bar, on);
        if (!on) return;
        const top = y(pts[i].value);
        const base = y(Math.max(lo, 0));
        bar.position = [x(i) - step / 2 + 1, Math.min(top, base - 1), 0];
        bar.get("Shape2D").size = [Math.max(2, step - 2), Math.max(1, base - top)];
      });
    }
    const perSeason = this.data.economy.calendar.daysPerSeason;
    chart.marks.forEach((m, k) => {
      const first = n ? pts[0].day : 0;
      let boundary = -1;
      let count = 0;
      for (let i = 0; i < n; i++) {
        if (pts[i].day % perSeason === 0 && pts[i].day > first) {
          if (count === k) boundary = i;
          count++;
        }
      }
      setActive(m, boundary >= 0);
      if (boundary >= 0) {
        m.position = [x(boundary), h - 2, 0];
        m.get("Shape2D").size = [0, h - 4];
      }
    });
  }

  /** The tooltip of a chart: the day and the value under the pointer. */
  chartTip(chart) {
    const r = ui.rectOf(chart.area);
    if (!r || !chart.points.length) return null;
    const n = chart.points.length;
    const pad = 16;
    const step = (r.w - 2 * pad) / (CHART_POINTS - 1);
    const i = Math.round(n - 1 - (r.x + r.w - pad - this.mouse.x) / step);
    const p = chart.points[Math.max(0, Math.min(n - 1, i))];
    return { title: t("charts.dayTip", { day: p.day + 1 }), lines: [{ text: chart.kind === "line" ? coinsText(p.value) : t("charts.madeTip", { n: numberText(p.value) }) }] };
  }

  // ---- notifications -------------------------------------------------------------------------------------------------------------------------

  noticeText(n) {
    const a = { ...n.args };
    if (a.type) a.name = buildingName(a.type);
    if (a.good) a.goodName = i18n.t(`good.${a.good}`);
    if (a.reason) a.reasonText = i18n.t(`sim.leftReason.${a.reason}`);
    // colour-blind safe: the severity is also a mark in the text, not only the colour of the button
    const mark = live().safeColors && (n.sev === "bad" || n.sev === "warn") ? `${t(`notice.mark.${n.sev}`)} ` : "";
    return mark + t(`notice.${n.key}`, a) + (n.count > 1 ? ` (x${n.count})` : "");
  }

  refreshNotices() {
    const items = this.notices.items;
    this.noticeSlots = items.slice(0, NOTICE_SLOTS);
    this.noticeButtons.forEach((b, i) => {
      const n = this.noticeSlots[i];
      setActive(b, !!n);
      if (!n) return;
      const bt = b.get("Button");
      const text = this.noticeText(n);
      if (bt.text !== text) bt.text = text;
      const a = Notices.opacity(n, live().reducedMotion);
      const base = SEV_COLORS[n.sev] || SEV_COLORS.warn;
      bt.color = [base[0], base[1], base[2], 0.92 * a];
      bt.textColor = [1, 1, 1, a];
    });
  }

  clickNotice(slot) {
    const n = this.noticeSlots[slot];
    if (!n) return;
    this.focusNotice(n);
  }

  /** Jump the camera to what a notice is about and select it. */
  focusNotice(n) {
    if (n.cell) this.jumpTo(n.cell);
    if (n.building && this.state.buildings.has(n.building)) this.select("building", n.building);
    this.notices.dismiss(n.id);
    this.refreshNotices();
  }

  /** N: jump to the newest notice that has a place. */
  nextNotice() {
    const n = this.notices.items.find((m) => m.cell);
    if (n) this.focusNotice(n);
  }

  // ---- tooltips ---------------------------------------------------------------------------------------------------------------------------------

  registerTooltips() {
    const tips = this.tooltips;
    const ctl = this.ctl;
    const plain = (title, lines = []) => () => ({ title, lines: lines.map((text) => (typeof text === "string" ? { text } : text)) });
    const key = (name) => t(`key.${name}`);
    const rb = this.rightButtons;
    tips.add(rb.btn_build, () => ({ title: t("btn.build"), lines: [{ text: t("tip.build") }, { text: key("B"), color: COLORS.gold }] }));
    tips.add(rb.tool_demolish, () => ({ title: i18n.t("hud.demolish"), lines: [{ text: t("tip.demolish") }, { text: key("Del"), color: COLORS.gold }] }));
    tips.add(rb.btn_rotate, () => ({ title: i18n.t("hud.rotate"), lines: [{ text: t("tip.rotate") }, { text: key("R"), color: COLORS.gold }] }));
    tips.add(rb.btn_undo, () => ({ title: i18n.t("hud.undo"), lines: [{ text: t("tip.undo") }, { text: key("Z"), color: COLORS.gold }] }));
    tips.add(rb.btn_redo, () => ({ title: i18n.t("hud.redo"), lines: [{ text: t("tip.redo") }, { text: key("Y"), color: COLORS.gold }] }));
    tips.add(rb.btn_goods, () => ({ title: t("btn.goods"), lines: [{ text: t("tip.goods") }, { text: key("G"), color: COLORS.gold }] }));
    tips.add(rb.btn_charts, () => ({ title: t("btn.charts"), lines: [{ text: t("tip.charts") }, { text: key("T"), color: COLORS.gold }] }));
    tips.add(rb.btn_overlay, () => ({ title: t("btn.overlayTitle"), lines: [{ text: t("tip.overlay") }, { text: key("M"), color: COLORS.gold }] }));
    tips.add(rb.btn_help, () => ({ title: t("btn.help"), lines: [{ text: t("tip.help") }, { text: key("F1"), color: COLORS.gold }] }));
    for (const c of this.cats) tips.add(this.tabButtons[c.id], () => ({ title: t(`cat.${c.id}`), lines: [{ text: t(`cat.hint.${c.id}`) }] }));
    for (const type of Object.keys(this.itemButtons)) {
      const e = world.find(`item_${type}`);
      tips.add(e, () => (this.isOpen("build") ? this.buildingTip(type) : null));
    }
    // the top bar: coins, goods, population
    const coins = world.find("coins_text");
    tips.add(coins, () => {
      const sim = this.state.sim;
      const l = sim.ledger;
      return { title: t("tip.coinsTitle"), lines: [{ text: t("tip.coins", { money: coinsText(this.state.economy.coins) }) }, { text: t("tip.coinsFlow", { sales: numberText(l.sales), wages: numberText(l.wages + l.upkeep) }), color: COLORS.dim }] };
    });
    for (const id of this.data.goodIds) {
      const text = world.find(`good_${id}_text`);
      if (!text) continue;
      tips.add(text, () => {
        const r = this.recorder.rates(id);
        const lines = [
          { text: t("tip.stock", { n: numberText(Math.floor(this.state.economy.get(id))), cap: numberText(this.state.sim.capacity()) }) },
          { text: t("tip.rates", { made: numberText(r.made, 1), used: numberText(r.used, 1) }), color: COLORS.dim },
          { text: t("tip.price", { price: coinsText(this.state.sim.priceOf(id)), base: numberText(this.data.goods[id].basePrice) }), color: COLORS.gold },
        ];
        return { title: i18n.t(`good.${id}`), lines };
      });
    }
    const pop = world.find("pop_text");
    if (pop) {
      tips.add(pop, () => {
        const s = this.state.sim.summary();
        return { title: t("tip.popTitle"), lines: [{ text: t("tip.pop", { population: villagersText(s.population), housing: numberText(s.housing), employed: s.employed, jobs: s.jobs }) }, { text: t("tip.popHungry", { n: s.hungry }), color: s.hungry ? COLORS.red : COLORS.dim }] };
      });
    }
    for (let i = 0; i < 4; i++) {
      const sb = world.find(`speed_${i}`);
      if (sb) tips.add(sb, plain(t(`tip.speed${i}`), [{ text: key(`speed${i}`), color: COLORS.gold }]));
    }
    // goods table
    for (const c of GOODS_COLUMNS) tips.add(this.sortButtons[c], () => ({ title: t(`goods.col.${c}`), lines: [{ text: t(`goods.colHint.${c}`) }, { text: t("goods.sortHint"), color: COLORS.dim }] }));
    this.goodsRows.forEach((row) => tips.add(row.root, () => (this.isOpen("goods") ? this.goodTip(row.good) : null)));
    tips.add(this.chartGoodButton, () => ({ title: t("charts.pick"), lines: [{ text: t("charts.pickHint") }] }));
    tips.add(this.moneyChart.area, () => (this.isOpen("charts") ? this.chartTip(this.moneyChart) : null));
    tips.add(this.madeChart.area, () => (this.isOpen("charts") ? this.chartTip(this.madeChart) : null));
    // notices
    this.noticeButtons.forEach((b, i) => tips.add(b, () => (this.noticeSlots[i] ? { title: t("tip.noticeTitle"), lines: [{ text: t("tip.notice") }] } : null)));
    // inspector
    this.chips.forEach((b, i) => tips.add(b, () => (this.chipVillagers[i] ? { title: t("tip.chipTitle", { id: this.chipVillagers[i] }), lines: [{ text: t("tip.chip") }] } : null)));
    for (const id of Object.keys(this.inspBtn)) tips.add(this.inspBtn[id], () => ({ title: t(`insp.btn.${id}`), lines: [{ text: t(`insp.btnHint.${id}`) }] }));
    // the map: a building under the pointer when nothing is being built
    tips.fallback = (x, y) => (this.over({ x, y }) ? null : this.mapTip());
  }

  /** The tooltip of the building under the pointer (no tool, no drag), or null. */
  mapTip() {
    const ctl = this.ctl;
    if (ctl.tool.kind !== "none" || !ctl.hover || ctl.drag || (this.chipDrag && this.chipDrag.active)) return null;
    const b = this.state.buildingAt(ctl.hover[0], ctl.hover[1]);
    if (!b || this.data.buildings[b.type].kind === "road") return null;
    const info = describeBuilding(this.state, b.id);
    if (!info) return null;
    const lines = [];
    if (!info.connected) lines.push({ text: t("insp.noRoad"), color: COLORS.red });
    if (info.workers) {
      lines.push({ text: t("insp.workers", { present: info.workers.present, count: info.workers.staff.length, max: info.workers.max }) });
      lines.push({ text: t("insp.status", { state: info.stall ? i18n.t(`sim.stall.${info.stall}`) : i18n.t("sim.running") }), color: info.stall && info.stall !== "closed" ? COLORS.red : COLORS.green });
    }
    if (info.residents) lines.push({ text: t("insp.residents", { count: info.residents.list.length, max: info.residents.max }) });
    lines.push({ text: t("tip.clickInspect"), color: COLORS.dim });
    return { title: buildingName(b.type), lines };
  }

  // ---- the frame ------------------------------------------------------------------------------------------------------------------------------------

  /** Is the point over one of the Hud's panels? (the controller adds the scene's bars) */
  over(m) {
    const roots = [this.column];
    for (const [name, p] of this.panels) if (this.isOpen(name)) roots.push(p.root);
    if (this.noticeSlots.some(Boolean)) roots.push(this.noticeRoot);
    return roots.some((e) => inside(e, m.x, m.y));
  }

  /** Called every frame by the controller after the clock advanced. */
  update(dt, m) {
    this.mouse = m;
    const ctl = this.ctl;
    this.notices.update(dt);
    this.refreshNotices();
    this.overlayClock += dt;
    for (const [name, p] of this.panels) {
      if (!this.isOpen(name)) continue;
      p.since += dt;
      if (p.since >= p.every) {
        p.since = 0;
        p.refresh();
      }
    }
    if (this.overlay === "traffic" && this.overlayClock > 1) this.overlayDirty = true;
    // the camera's wheel does not zoom the map under a panel (the engine: ui.pointerOverUi, and a ScrollList keeps the wheel it
    // scrolls with), nor behind the modal event card, which covers only part of the screen
    this.rig.wheelBlocked = this.cardOpen();
    this.updateChipDrag(m);
    this.placeInspector();
    this.placeCentred();
    this.tooltips.update(dt, m, !!(this.chipDrag && this.chipDrag.active) || input.down("primary") || this.cardOpen());
  }

  /**
   * Hold-free (option, or a gamepad in use): a click on a worker chip picks the worker up and the next click puts it down (on a
   * building: it works there; anywhere else: nothing happens), instead of dragging it with the button held. `carry` marks that mode.
   */
  /**
   * The inspector hangs from the bottom-right corner; when it is taller than the room under the right-hand column (large text or a
   * large UI scale make both bigger) it stands left of the column instead of over it. Uses last frame's rectangles.
   */
  placeInspector() {
    if (!this.isOpen("inspector")) return;
    const r = ui.rectOf(this.inspRoot);
    const c = ui.rectOf(this.column);
    if (!r || !c) return;
    const room = DESIGN.height - INSPECTOR_BOTTOM - (c.y + c.h) - 6;
    const x = r.h > room ? -(c.w + 16) : -8;
    // Over the build bar's width it stands on the bar instead of over it (the bar is wide at large text and interface sizes).
    let y = -INSPECTOR_BOTTOM;
    const b = this.isOpen("build") ? ui.rectOf(this.bar) : null;
    if (b && r.x < b.x + b.w + 4) y = -(DESIGN.height - b.y + 6);
    const pos = this.inspRoot.position;
    if (pos.x !== x || pos.y !== y) this.inspRoot.position = [x, y, pos.z];
  }

  /**
   * The goods table, the charts and the help are centred on the screen; when the interface size makes one wider than the room left
   * of the right-hand column, it is moved left until it clears the column (it keeps 8 px from the screen's edge).
   */
  placeCentred() {
    const c = ui.rectOf(this.column);
    if (!c) return;
    for (const name of ["goods", "charts", "help"]) {
      if (!this.isOpen(name)) continue;
      const root = this.panels.get(name).root;
      const r = ui.rectOf(root);
      if (!r) continue;
      const room = c.x - 8;
      const x = DESIGN.width / 2 + r.w / 2 <= room ? 0 : Math.max(room - r.w / 2 - DESIGN.width / 2, 8 + r.w / 2 - DESIGN.width / 2);
      // and up, off the build menu (which is wide and tall at large sizes) when it would cover it
      let y = 0;
      const bar = this.isOpen("build") ? ui.rectOf(this.bar) : null;
      if (bar) {
        const flat = r.y + r.h - root.position.y; // the bottom edge with no offset (position y is down)
        y = Math.min(0, bar.y - 6 - flat);
      }
      const pos = root.position;
      if (Math.abs(pos.x - x) > 0.5 || Math.abs(pos.y - y) > 0.5) root.position = [x, y, pos.z];
    }
  }

  updateChipDrag(m) {
    const hovered = pointer.hovered();
    const free = live().holdFree || pointer.pad;
    if (input.pressed("primary")) this.chipDragged = false; // a drop elsewhere than on the chip never clicks it; do not swallow the next click
    let picked = false;
    if (input.pressed("primary") && hovered && hovered.id && hovered.id.startsWith("chip_")) {
      const vid = this.chipVillagers[Number(hovered.id.slice(5))];
      if (vid) {
        this.chipDrag = { villager: vid, startX: m.x, startY: m.y, active: free, over: 0, carry: free };
        picked = true;
      }
    }
    const d = this.chipDrag;
    if (!d) return;
    if (!d.active && Math.hypot(m.x - d.startX, m.y - d.startY) > DRAG_SLOP && input.down("primary")) d.active = true;
    if (d.active) {
      const cell = this.ctl.hover;
      const b = cell ? this.state.buildingAt(cell[0], cell[1]) : null;
      d.over = b ? b.id : 0;
      d.verdict = b ? canDropWorker(this.state, d.villager, b.id) : { ok: false, code: "none" };
      setActive(this.chip, true);
      this.chip.position = [m.x + 12, m.y + 28, 0];
      this.chipText.get("Text").text = d.over && !d.verdict.ok ? t("drag.no", { reason: t(`drag.reason.${d.verdict.code}`) }) : t("drag.villager", { id: d.villager });
      this.chip.get("Panel").color = d.over && !d.verdict.ok ? [0.55, 0.2, 0.18, 0.95] : d.over ? [0.2, 0.5, 0.3, 0.95] : [0.2, 0.35, 0.55, 0.95];
    }
    if (d.carry ? input.pressed("primary") && !picked : input.released("primary")) {
      if (d.active) {
        this.chipDragged = true;
        if (d.over && d.verdict && d.verdict.ok) {
          const res = this.state.sim.people.reassign(d.villager, d.over);
          if (res.ok) this.ctl.toast(t("drag.done", { id: d.villager, name: buildingName(this.state.buildings.get(d.over).type) }));
          if (this.sel) this.refreshInspector();
        } else if (d.over && d.verdict) {
          this.ctl.toast(t("drag.no", { reason: t(`drag.reason.${d.verdict.code}`) }));
        }
      }
      this.chipDrag = null;
      setActive(this.chip, false);
    }
  }

  /** Does a press that started on the UI belong to a worker drag (the map must not treat the release as a click)? */
  dragging() {
    return !!(this.chipDrag && this.chipDrag.active);
  }

  /** Is a worker being carried (hold-free)? The click that puts it down is not a click on the map. */
  carrying() {
    return !!(this.chipDrag && this.chipDrag.carry && this.chipDrag.active);
  }

  // ---- keys -----------------------------------------------------------------------------------------------------------------------------------------

  /** An event card is modal (the trade UI): the interface keys, tooltips and the wheel wait until it is answered. */
  cardOpen() {
    return !!(this.state.trade && this.state.trade.card);
  }

  keys() {
    const ctl = this.ctl;
    if (this.cardOpen()) return;
    if (input.pressed("build_menu")) this.toggleBuild();
    if (input.pressed("cat_next")) this.stepCategory(1);
    if (input.pressed("cat_prev")) this.stepCategory(-1);
    if (input.pressed("goods_table")) this.toggle("goods");
    if (input.pressed("charts")) this.toggle("charts");
    if (input.pressed("overlay")) this.cycleOverlay();
    if (input.pressed("notice_jump")) this.nextNotice();
    if (input.pressed("help")) this.toggle("help");
    if (input.pressed("delete") && !this.demolishSelected()) ctl.selectDemolish();
    for (const [action, fn] of this.keyHandlers) if (input.pressed(action)) fn();
  }

  /**
   * Esc: put away the newest thing the player opened: a worker drag, an open panel, the tool, the selection, the build menu.
   * @returns {boolean} true when something was put away (the pause menu then stays closed)
   */
  escape() {
    const ctl = this.ctl;
    if (this.chipDrag && this.chipDrag.active) {
      this.chipDrag = null;
      setActive(this.chip, false);
      return true;
    }
    const modal = [...this.openOrder].reverse().find((n) => n !== "build" && n !== "inspector");
    if (modal) {
      this.close(modal);
      return true;
    }
    if (ctl.drag) {
      ctl.drag = null;
      return true;
    }
    if (ctl.tool.kind !== "none") {
      ctl.clearTool();
      return true;
    }
    if (this.sel) {
      this.deselect();
      return true;
    }
    if (this.buildOpen) {
      this.setBuildOpen(false);
      return true;
    }
    if (this.overlay) {
      this.setOverlay(null);
      return true;
    }
    return false;
  }

  // ---- drawing over the map ----------------------------------------------------------------------------------------------------------------------------

  /** Add the selection, the drag target and the overlay to this frame's diamonds (between beginOverlay and endOverlay). */
  drawOverlay(view) {
    if (this.overlay) this.drawField(view);
    const sel = this.sel;
    if (sel && sel.kind === "building") {
      const b = this.state.buildings.get(sel.id);
      if (b) for (const [c, r] of footprintCells(this.data.buildings[b.type], b.x, b.y, b.rot)) view.diamond(c, r, MAP_COLORS.selected || [1, 0.9, 0.4, 0.9], true);
    } else if (sel && sel.kind === "villager") {
      const w = this.state.sim.walkers.list.get(sel.id);
      const v = this.state.sim.people.villagers.get(sel.id);
      const cell = w ? [Math.round(w.x), Math.round(w.y)] : v && this.state.buildings.get(v.at) ? centreOf(this.state.buildings.get(v.at)) : null;
      if (cell) view.diamond(cell[0], cell[1], [1, 0.9, 0.4, 0.9], true);
    }
    const d = this.chipDrag;
    if (d && d.active && d.over) {
      const b = this.state.buildings.get(d.over);
      if (b) for (const [c, r] of footprintCells(this.data.buildings[b.type], b.x, b.y, b.rot)) view.diamond(c, r, d.verdict && d.verdict.ok ? MAP_COLORS.valid : MAP_COLORS.invalid);
    }
  }

  /** The overlay's cells in view, tinted by their value. */
  drawField(view) {
    const spec = this.overlays.get(this.overlay);
    if (!spec) return;
    if (this.overlayDirty || !this.overlayCache) {
      this.overlayCache = spec.field(this.state, this);
      this.overlayDirty = false;
      this.overlayClock = 0;
    }
    const { values, cells } = this.overlayCache;
    const width = this.state.map.width;
    const [c0, r0, c1, r1] = this.visibleCells();
    let used = 0;
    const col = spec.color;
    // The field is drawn OVER the buildings and the walkers (MAP_LAYER.field): under them a dense town hides it. The tint grows
    // with the value. Colour-blind safe: the value is also a PATTERN, a white pip on a dark plate that grows by tier (low: dot,
    // middle: small diamond, high: big diamond), so the overlays read in greyscale and over any roof; a safe cell is three shapes.
    const pips = live().safeColors;
    const budget = pips ? Math.floor(OVERLAY_BUDGET / 3) : OVERLAY_BUDGET;
    for (const i of cells) {
      const c = i % width;
      const r = (i - c) / width;
      if (c < c0 || c > c1 || r < r0 || r > r1) continue;
      if (used++ >= budget) break;
      const v = values[i];
      // dark for a low value, the full colour for a high one: the brightness carries the value where the hue cannot be told
      const shade = 0.12 + 0.88 * v;
      view.diamond(c, r, [col[0] * shade, col[1] * shade, col[2] * shade, 0.38 + 0.4 * v], false, 1, MAP_LAYER.field);
      if (pips) {
        const size = v >= 0.67 ? 0.52 : v >= 0.34 ? 0.3 : 0.14;
        view.diamond(c, r, PIP_PLATE, false, size + 0.1, MAP_LAYER.fieldPlate);
        view.diamond(c, r, PIP, v >= 0.67, size, MAP_LAYER.fieldMark);
      }
    }
  }

  /** The cell rectangle in view: [c0, r0, c1, r1], a cell wider than the screen. */
  visibleCells() {
    const corners = [[0, 0], [DESIGN.width, 0], [0, DESIGN.height], [DESIGN.width, DESIGN.height]].map(([x, y]) => this.rig.screenToCell(x, y));
    const cs = corners.map((p) => p[0]);
    const rs = corners.map((p) => p[1]);
    return [Math.min(...cs) - 1, Math.min(...rs) - 1, Math.max(...cs) + 1, Math.max(...rs) + 1];
  }

  /** The overlay's value under a cell as text for the status line, or "". */
  overlayStatus(c, r) {
    if (!this.overlay || !this.overlayCache) return "";
    const v = this.overlayCache.values[r * this.state.map.width + c] || 0;
    return t("overlay.value", { name: t(`overlay.${this.overlay}`), percent: Math.round(v * 100) });
  }

  /** The value 0..1 an overlay has on a cell (tests, the status line). */
  overlayValue(c, r) {
    return this.overlayCache ? this.overlayCache.values[r * this.state.map.width + c] || 0 : 0;
  }
}

export { COVERAGE, rotatable, dateText };
