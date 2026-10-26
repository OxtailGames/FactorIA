// @ts-check
// The save slot screen, for the title ("play" mode: Continue, load, new game of a scenario) and for the pause menu ("save" mode:
// save the running game into a slot). Four panels, built once by the script that owns the screen (none is written into a scene,
// so any scene can have it) and shown with that script's MenuStack:
//
//   slots_panel     title, Continue, the three slots (thumbnail, text, buttons), a message line, Back
//   scenario_panel  a new game: one button per scenario (name and blurb)
//   confirm_panel   "Delete ...?" / "Replace ...?" with No focused first
//   rename_panel    a text field
//
// Everything works with the mouse alone and with the keyboard or a gamepad alone (every widget is a Button or TextField, the first
// one of each panel has autoFocus, Escape / B goes back through the owner's MenuStack).
//
// The widget ids are stable and public (tests and the tour use them):
//   slots_continue, slot_<n>_main (Load / New game / Save here), slot_<n>_auto, slot_<n>_rename, slot_<n>_delete, slots_back,
//   scenario_<id>, scenario_back, confirm_yes, confirm_no, rename_field, rename_ok, rename_cancel
import { world, ui, i18n, game } from "factoria";
import { getData } from "../game/data.js";
import { SLOTS, listSlots, latestEntry, loadEntry, renameEntry, deleteSlot, readMeta } from "../game/save_store.js";
import { scenarioIds } from "../game/scenarios.js";
import { syncCloud, removeQuietly, listConflicts } from "../game/cloud_sync.js";
import { thumbRuns, THUMB_COLORS } from "../game/thumbnail.js";
import { dateText } from "../game/format.js";

const THUMB_BOX = 104; // the thumbnail fits a square this big, in design pixels
const BOX_COLOR = [0.05, 0.07, 0.1, 0.94];
const ROW_COLOR = [0.13, 0.16, 0.22, 0.95];
const CLEAR = [0, 0, 0, 0];

/** Text of a play time in seconds: "Played 12 min" or "Played 1 h 5 min". */
export function playTimeText(seconds) {
  const minutes = Math.floor(seconds / 60);
  return minutes >= 60
    ? i18n.t("slots.playTime", { hours: Math.floor(minutes / 60), minutes: minutes % 60 })
    : i18n.t("slots.playTimeShort", { minutes });
}

/** The player's sentence for a problem of a save (savegame.js codes), from locales/en.json save.error.<code>. */
export function problemText(error) {
  const key = `save.error.${error && error.code}`;
  const text = i18n.t(key);
  return text === key ? String((error && error.message) || error) : text;
}

const button = (id, label, extra = {}) => ({
  id,
  components: { Button: { text: label, autoSize: true, fontSize: 22, layer: 0, ...extra } },
});

export class SlotsScreen {
  /**
   * @param {object} options
   * @param {"play" | "save"} options.mode
   * @param {import("./menu_stack.js").MenuStack} options.menus the owner's stack, which shows and hides the panels
   * @param {number} [options.layer] draw order of the panels (above everything else of the owner)
   * @param {(boot: { slot: number, kind?: string, scenario?: string, name?: string }) => void} [options.start] play mode: start a game
   * @param {(slot: number) => { ok: boolean, error?: any }} [options.save] save mode: write the running game into a slot (manual entry)
   * @param {() => boolean} [options.isCurrent] is the owner's scene still the current one (a cloud answer arrives later)
   */
  constructor(options) {
    this.mode = options.mode;
    this.menus = options.menus;
    this.layer = options.layer ?? 220;
    this.start = options.start || (() => {});
    this.saveInto = options.save || (() => ({ ok: false }));
    this.isCurrent = options.isCurrent || (() => true);
    this.data = getData();
    this.pendingSlot = 0;
    this.confirmAction = /** @type {null | (() => void)} */ (null);
    this.off = /** @type {Array<() => void>} */ ([]);
    this.build();
    this.bind();
  }

  // ---- building ------------------------------------------------------------------------------------------------------

  /** Give every layer in an entity tree its place above this.layer (the trees below are written with layers relative to it). */
  place(node) {
    for (const comp of Object.values(node.components || {})) if (typeof comp.layer === "number") comp.layer += this.layer;
    for (const child of node.children || []) this.place(child);
    return node;
  }

  spawnPanel(id, tree) {
    const entity = world.spawn(this.place(tree));
    entity.id = id;
    entity.active = false;
    return entity;
  }

  build() {
    const column = (id, children, extra = {}) => ({
      id,
      components: {
        Panel: { anchor: [0.5, 0.5], pivot: [0.5, 0.5], layout: "column", spacing: 10, fit: true, padding: [28, 16, 28, 16], color: BOX_COLOR, layer: 0, ...extra },
      },
      children,
    });
    const title = (id, size = 36) => ({ id, components: { Text: { text: "", fontSize: size, space: "screen", layer: 10 } } });
    const rows = [];
    for (let n = 1; n <= SLOTS; n++) rows.push(this.slotRow(n));
    this.slots = this.spawnPanel(
      "slots_panel",
      column("slots_panel", [
        title("slots_title"),
        { ...button("slots_continue", "", { layer: 10, autoFocus: this.mode === "play", size: [320, 44] }) },
        ...rows,
        { id: "slots_message", components: { Text: { text: "", fontSize: 20, space: "screen", layer: 10, maxWidth: 640, color: [1, 0.85, 0.5, 1] } } },
        button("slots_back", "", { layer: 10 }),
      ]),
    );
    this.scenarios = this.spawnPanel(
      "scenario_panel",
      column("scenario_panel", [
        title("scenario_title"),
        ...scenarioIds().map((id, i) => button(`scenario_${id}`, "", { layer: 10, autoFocus: i === 0, maxWidth: 560, fontSize: 22 })),
        button("scenario_back", "", { layer: 10 }),
      ]),
    );
    this.confirm = this.spawnPanel(
      "confirm_panel",
      column("confirm_panel", [
        { id: "confirm_text", components: { Text: { text: "", fontSize: 26, space: "screen", layer: 10, maxWidth: 520 } } },
        {
          id: "confirm_buttons",
          components: { Panel: { layout: "row", spacing: 16, fit: true, padding: [0, 0, 0, 0], color: CLEAR, layer: 1 } },
          children: [button("confirm_no", "", { layer: 10, autoFocus: true }), button("confirm_yes", "", { layer: 10 })],
        },
      ]),
    );
    this.rename = this.spawnPanel(
      "rename_panel",
      column("rename_panel", [
        title("rename_title", 30),
        { id: "rename_field", components: { TextField: { text: "", maxLength: 24, size: [420, 48], layer: 10, autoFocus: true } } },
        {
          id: "rename_buttons",
          components: { Panel: { layout: "row", spacing: 16, fit: true, padding: [0, 0, 0, 0], color: CLEAR, layer: 1 } },
          children: [button("rename_ok", "", { layer: 10 }), button("rename_cancel", "", { layer: 10 })],
        },
      ]),
    );
    this.refreshTexts();
  }

  slotRow(n) {
    const small = { size: [132, 36], autoSize: false, fontSize: 18, layer: 10 };
    return {
      id: `slot_${n}`,
      components: { Panel: { layout: "row", spacing: 14, fit: true, padding: [10, 10, 10, 10], align: "center", color: ROW_COLOR, layer: 2 } },
      children: [
        { id: `slot_${n}_thumb`, components: { Panel: { layout: "column", spacing: 0, fit: true, padding: [0, 0, 0, 0], align: "start", color: CLEAR, layer: 3 } } },
        { id: `slot_${n}_info`, components: { Text: { text: "", fontSize: 18, space: "screen", layer: 10, maxWidth: 330 } } },
        {
          id: `slot_${n}_buttons`,
          components: { Panel: { layout: "grid", columns: 2, spacing: 6, fit: true, padding: [0, 0, 0, 0], color: CLEAR, layer: 3 } },
          children: [
            button(`slot_${n}_main`, "", { ...small, autoFocus: n === 1 && this.mode === "save" }),
            button(`slot_${n}_auto`, "", small),
            button(`slot_${n}_rename`, "", small),
            button(`slot_${n}_delete`, "", small),
          ],
        },
      ],
    };
  }

  // ---- events --------------------------------------------------------------------------------------------------------

  bind() {
    const on = (id, fn) => this.off.push(ui.on("click", id, fn));
    on("slots_continue", () => {
      const latest = latestEntry();
      if (latest) this.load(latest.slot, latest.kind);
    });
    on("slots_back", () => this.menus.back());
    for (let n = 1; n <= SLOTS; n++) {
      on(`slot_${n}_main`, () => this.main(n));
      on(`slot_${n}_auto`, () => this.load(n, "auto"));
      on(`slot_${n}_rename`, () => this.askRename(n));
      on(`slot_${n}_delete`, () => this.askDelete(n));
    }
    for (const id of scenarioIds()) on(`scenario_${id}`, () => this.begin(id));
    on("scenario_back", () => this.menus.back());
    on("confirm_yes", () => {
      const action = this.confirmAction;
      this.confirmAction = null;
      this.menus.back();
      if (action) action();
    });
    on("confirm_no", () => {
      this.confirmAction = null;
      this.menus.back();
    });
    on("rename_ok", () => this.finishRename());
    on("rename_cancel", () => this.menus.back());
    this.off.push(ui.on("submit", "rename_field", () => this.finishRename()));
    this.off.push(i18n.on("change", () => this.refreshTexts()));
  }

  destroy() {
    for (const off of this.off) off();
    this.off = [];
    for (const p of [this.slots, this.scenarios, this.confirm, this.rename]) if (p && p.alive) p.destroy();
  }

  // ---- actions -------------------------------------------------------------------------------------------------------

  /** Show the slot list (call it instead of menus.show("slots_panel")). */
  open() {
    this.message("");
    this.refresh();
    this.menus.show("slots_panel");
    if (this.mode === "play") this.syncFromCloud();
  }

  main(n) {
    const entry = listSlots()[n - 1];
    if (this.mode === "save") {
      if (entry.manual) this.ask(i18n.t("slots.confirmOverwrite", { name: this.nameOf(n) }), () => this.saveNow(n));
      else this.saveNow(n);
      return;
    }
    if (entry.manual) this.load(n, "manual");
    else {
      this.pendingSlot = n;
      this.menus.show("scenario_panel");
    }
  }

  /** Check the save fully, then ask the owner to start the game (the game scene loads it again, in its own onStart). */
  load(n, kind) {
    const res = loadEntry(n, kind, this.data);
    if (!res.ok) {
      this.message(i18n.t("slots.loadFailed", { problem: problemText(res.error) }));
      return;
    }
    this.start({ slot: n, kind });
  }

  begin(scenarioId) {
    const name = i18n.t(`scenario.${scenarioId}.name`);
    this.start({ slot: this.pendingSlot, scenario: scenarioId, name });
  }

  saveNow(n) {
    const res = this.saveInto(n);
    if (res.ok) this.message(i18n.t("slots.saved", { n }));
    else this.message(problemText(res.error));
    this.refresh();
  }

  askDelete(n) {
    this.ask(i18n.t("slots.confirmDelete", { name: this.nameOf(n) }), () => {
      deleteSlot(n);
      removeQuietly(n);
      this.message(i18n.t("slots.deleted"));
      this.refresh();
    });
  }

  askRename(n) {
    const meta = readMeta(n, "manual");
    if (!meta) return;
    this.renaming = n;
    world.find("rename_field").get("TextField").text = meta.name;
    this.menus.show("rename_panel");
    ui.focus("rename_field");
  }

  finishRename() {
    const n = this.renaming;
    const text = world.find("rename_field").get("TextField").text;
    this.renaming = 0;
    if (n && text.trim() && renameEntry(n, text)) this.message(i18n.t("slots.renamed"));
    this.menus.back();
    this.refresh();
  }

  ask(text, action) {
    this.confirmAction = action;
    world.find("confirm_text").get("Text").text = text;
    this.menus.show("confirm_panel");
  }

  message(text) {
    world.find("slots_message").get("Text").text = text;
  }

  nameOf(n) {
    const meta = readMeta(n, "manual");
    return meta && meta.name ? meta.name : i18n.t("slots.slot", { n });
  }

  /** Bring this device and the cloud into line; a slot that changed is shown when the answer arrives, if the screen is still there. */
  async syncFromCloud() {
    const res = await syncCloud({ isCurrent: () => this.isCurrent() && this.slots.alive });
    if (!this.isCurrent() || !this.slots.alive || !res.ok) return;
    if (res.pulled.length || res.pushed.length) this.refresh();
    if (res.conflicts.length || listConflicts().length) this.message(i18n.t("slots.cloudConflict"));
  }

  // ---- showing the data ----------------------------------------------------------------------------------------------

  /** The fixed texts, in the current language (again when the language changes). */
  refreshTexts() {
    const t = (id, comp, text) => {
      const e = world.find(id);
      if (e) e.get(comp).text = text;
    };
    t("slots_title", "Text", i18n.t(this.mode === "save" ? "slots.titleSave" : "slots.title"));
    t("slots_continue", "Button", i18n.t("slots.continue"));
    t("slots_back", "Button", i18n.t("slots.back"));
    t("scenario_title", "Text", i18n.t("slots.pick"));
    t("scenario_back", "Button", i18n.t("slots.back"));
    for (const id of scenarioIds()) t(`scenario_${id}`, "Button", `${i18n.t(`scenario.${id}.name`)}\n${i18n.t(`scenario.${id}.blurb`)}`);
    t("confirm_yes", "Button", i18n.t("slots.yes"));
    t("confirm_no", "Button", i18n.t("slots.no"));
    t("rename_title", "Text", i18n.t("slots.renameTitle"));
    t("rename_ok", "Button", i18n.t("slots.renameOk"));
    t("rename_cancel", "Button", i18n.t("slots.back"));
    for (let n = 1; n <= SLOTS; n++) {
      t(`slot_${n}_auto`, "Button", i18n.t("slots.auto"));
      t(`slot_${n}_rename`, "Button", i18n.t("slots.rename"));
      t(`slot_${n}_delete`, "Button", i18n.t("slots.delete"));
    }
    if (this.slots) this.refresh();
  }

  /** Redraw the three slots from the storage. */
  refresh() {
    const slots = listSlots();
    const latest = latestEntry();
    const cont = world.find("slots_continue");
    cont.active = this.mode === "play";
    cont.get("Button").interactable = !!latest;
    for (const s of slots) this.showSlot(s);
  }

  showSlot({ slot: n, manual, auto }) {
    const meta = manual && manual.meta;
    const lines = [];
    if (meta) {
      lines.push(meta.name || i18n.t("slots.slot", { n }));
      lines.push(i18n.t("slots.info", { scenario: this.scenarioName(meta.scenario), date: dateText({ season: meta.season, dayOfSeason: meta.dayOfSeason, year: meta.year }) }));
      lines.push(playTimeText(meta.playSeconds));
      lines.push(i18n.t("slots.stats", { coins: meta.coins, population: meta.population }));
      if (meta.won) lines.push(i18n.t("slots.completed"));
      else if (meta.goalsTotal) lines.push(i18n.t("slots.goals", { done: meta.goalsDone || 0, total: meta.goalsTotal }));
    } else {
      lines.push(i18n.t("slots.slot", { n }));
      lines.push(manual ? i18n.t("slots.damaged") : i18n.t("slots.empty"));
    }
    if (auto && auto.meta) lines.push(i18n.t("slots.autoInfo", { date: dateText({ season: auto.meta.season, dayOfSeason: auto.meta.dayOfSeason, year: auto.meta.year }) }));
    const row = world.find(`slot_${n}`);
    world.find(`slot_${n}_info`).get("Text").text = lines.join("\n");
    const main = world.find(`slot_${n}_main`);
    const label = this.mode === "save" ? "slots.save" : manual ? "slots.load" : "slots.new";
    main.get("Button").text = i18n.t(label);
    world.find(`slot_${n}_auto`).active = this.mode === "play";
    world.find(`slot_${n}_auto`).get("Button").interactable = !!auto;
    world.find(`slot_${n}_rename`).get("Button").interactable = !!manual && !!meta;
    world.find(`slot_${n}_delete`).get("Button").interactable = !!manual || !!auto;
    this.drawThumb(world.find(`slot_${n}_thumb`), meta ? meta.thumb : null);
  }

  scenarioName(id) {
    const key = `scenario.${id}.name`;
    const text = i18n.t(key);
    return text === key ? id : text;
  }

  /** The thumbnail as rows of coloured rectangles (run-length: one rectangle per run). */
  drawThumb(panel, thumb) {
    for (const old of [...panel.children]) {
      old.active = false;
      old.destroy();
    }
    if (!thumb || !Array.isArray(thumb.rows) || !(thumb.w > 0) || !(thumb.h > 0)) {
      world.spawn({ components: { Panel: { size: [THUMB_BOX, THUMB_BOX], color: [0.08, 0.1, 0.14, 1], layer: this.layer + 4 } } }, { parent: panel });
      return;
    }
    const cell = THUMB_BOX / Math.max(thumb.w, thumb.h);
    const byRow = new Map();
    for (const run of thumbRuns(thumb)) {
      if (!byRow.has(run.row)) byRow.set(run.row, []);
      byRow.get(run.row).push(run);
    }
    for (let r = 0; r < thumb.h; r++) {
      const runs = byRow.get(r) || [];
      world.spawn(
        {
          components: { Panel: { layout: "row", spacing: 0, padding: [0, 0, 0, 0], fit: true, color: CLEAR, layer: this.layer + 4 } },
          children: runs.map((run) => ({
            components: { Panel: { size: [run.len * cell, cell], color: THUMB_COLORS[run.kind] || THUMB_COLORS.g, layer: this.layer + 5 } },
          })),
        },
        { parent: panel },
      );
    }
  }
}
