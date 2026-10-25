// @ts-check
// The title's ways into a game, apart from the menu plumbing (scripts/main_menu.js): Continue, the three save slots (new, continue,
// delete with a confirmation, cloud sync), the daily dig and the seed code panel. Every click and every answer that arrives later
// (the cloud) checks that the title is still the scene on screen, and the panel still open, before it writes a text.
import { ui, world, scene, session, i18n } from "factoria";
import * as saveFile from "../game/save.js";
import * as cloud from "../game/cloud.js";
import * as daily from "../game/daily.js";
import * as codes from "../game/seed_code.js";
import * as clipboard from "../game/clipboard.js";
import { startRun } from "../game/run_state.js";
import { stratumInfo } from "../game/generator.js";
import { clock } from "../game/hud.js";
import { SHIFT_SCENE, CAMP_SCENE, LOADING_SCENE } from "../game/progression.js";

/** Starts the scene through the loading screen. */
function enter(sceneFile) {
  session.nextScene = sceneFile; // scenes/loading.scene.json shows the progress of reading it, then loads it
  scene.load(LOADING_SCENE);
}

export class TitleFlow {
  /** @param {import("./menu_stack.js").MenuStack} menus */
  constructor(menus) {
    this.menus = menus;
    this.target = scene.current;
    /** Slot the delete confirmation is about. */
    this.deleting = 0;
    /** What the title line says now: [key, args] or null. Kept so a language change rewrites it. */
    this.line = null;
    this.synced = false;
  }

  /** Still the title, and the panel `id` (when given) still open? */
  live(panel) {
    return scene.current === this.target && (!panel || this.menus.top === panel);
  }

  text(id, key, args = {}) {
    const e = /** @type {any} */ (world.find(id));
    if (!e) throw new Error(`title: the scene has no entity '${id}' (see scenes/menu.scene.json).`);
    if (key) e.set("Text", { key, keyArgs: args });
    else e.set("Text", { key: "", text: "" });
  }

  /** Called once when the title opens: imports the old save, shows Continue and a first line. */
  start() {
    const imported = saveFile.importLegacy();
    this.refreshContinue();
    if (saveFile.storageDamaged()) this.title("slots.storageDamaged");
    else if (imported.imported) this.title("slots.imported", { slot: imported.slot });
    else if (imported.message) this.title("slots.legacy", { message: imported.message, hint: imported.hint });
    else this.dailyLine();
    ui.on("click", "continue", () => this.continueLast());
    ui.on("click", "play", () => this.openSlots());
    ui.on("click", "daily", () => this.startDaily());
    ui.on("click", "code_button", () => this.openCode());
    for (let n = 1; n <= saveFile.SLOT_COUNT; n++) {
      ui.on("click", `slot_${n}`, () => this.pickSlot(n));
      ui.on("click", `delete_${n}`, () => this.askDelete(n));
    }
    ui.on("click", "confirm_yes", () => this.confirmDelete());
    ui.on("click", "sync_slots", () => this.syncSlots());
    ui.on("click", "paste_code", () => this.pasteCode());
    ui.on("click", "play_code", () => this.playCode());
    ui.on("submit", "code_field", () => this.playCode());
    i18n.on("change", () => {
      if (this.line) this.title(this.line[0], this.line[1]);
      if (this.menus.top === "slots") this.fillSlots();
    });
  }

  /** The line under the title menu. */
  title(key, args = {}) {
    this.line = [key, args];
    this.text("menu_message", key, args);
  }

  dailyLine() {
    const s = daily.status();
    this.title("menu.dailyInfo", { key: s.key, tries: s.tries, depth: s.bestDepth });
  }

  /** Continue exists (and takes the focus) when some slot holds a save that can be read. */
  refreshContinue() {
    const button = /** @type {any} */ (world.find("continue"));
    const has = saveFile.lastSlot() !== null;
    button.active = has;
    if (has && this.menus.top === "main_menu") ui.focus(button);
  }

  /** Takes a loaded run into the scene it resumes at, or says why not. @param {number} n @param {(key: string, args?: any) => void} say */
  resume(n, say) {
    const result = saveFile.continueSlot(n);
    if (!result.ok) {
      say("slots.problem", { message: result.message, hint: result.hint });
      return;
    }
    enter(result.resume === "camp" ? CAMP_SCENE : SHIFT_SCENE);
  }

  continueLast() {
    if (!this.live()) return;
    const n = saveFile.lastSlot();
    if (n === null) {
      this.title("slots.problem", { message: "no slot holds a save", hint: "press Play and start a new run" });
      this.refreshContinue();
      return;
    }
    this.resume(n, (k, a) => this.title(k, a));
  }

  // ---- slots

  openSlots() {
    if (!this.live()) return;
    this.menus.show("slots");
    this.fillSlots();
    this.text("slots_message", "");
    if (cloud.available()) this.syncSlots(); // opening the screen settles the slots with the cloud
  }

  fillSlots() {
    for (const s of saveFile.slots()) {
      const button = /** @type {any} */ (world.find(`slot_${s.slot}`));
      const del = /** @type {any} */ (world.find(`delete_${s.slot}`));
      if (s.status === "empty") button.set("Button", { key: "slots.empty", keyArgs: { slot: s.slot } });
      else if (s.status === "error") button.set("Button", { key: "slots.broken", keyArgs: { slot: s.slot } });
      else {
        const m = s.summary;
        button.set("Button", { key: "slots.filled", keyArgs: { slot: s.slot, stratum: i18n.t(stratumInfo(m.stratum).name), floor: m.floor, cash: m.cash, time: clock(m.playTime), best: m.bestDepth } });
      }
      del.set("Button", { interactable: s.status !== "empty" });
    }
  }

  /** @param {number} n */
  pickSlot(n) {
    if (!this.live("slots")) return;
    const found = saveFile.readSlot(n);
    if (found.status === "error") {
      this.text("slots_message", "slots.problem", { message: found.message, hint: found.hint });
      return;
    }
    if (found.status === "empty") {
      saveFile.newRun(n);
      enter(SHIFT_SCENE);
      return;
    }
    this.resume(n, (k, a) => this.text("slots_message", k, a));
  }

  /** @param {number} n */
  askDelete(n) {
    if (!this.live("slots")) return;
    this.deleting = n;
    this.menus.show("confirm_delete");
    this.text("confirm_text", "slots.confirm", { slot: n });
  }

  confirmDelete() {
    if (!this.live("confirm_delete")) return;
    const n = this.deleting;
    saveFile.erase(n);
    cloud.removeSlot(n); // or the cloud copy would come back at the next sync
    this.menus.back();
    this.fillSlots();
    this.refreshContinue();
    this.text("slots_message", "slots.deleted", { slot: n });
  }

  async syncSlots() {
    if (!this.live("slots")) return;
    this.text("slots_message", "slots.syncing");
    const answers = await cloud.syncAll();
    if (!this.live("slots")) return; // the player left the slot screen, or the title, while the cloud answered
    this.fillSlots();
    this.refreshContinue();
    const notable = answers.find((a) => ["conflict", "blocked", "error", "downloaded", "uploaded"].includes(a.action)) ?? answers[0];
    const key = `slots.synced.${notable.action}`;
    this.text("slots_message", key, { slot: notable.slot, winner: notable.winner ?? "", message: notable.message ?? "", hint: notable.hint ?? "" });
  }

  // ---- the daily dig

  startDaily() {
    if (!this.live()) return;
    daily.start();
    enter(SHIFT_SCENE);
  }

  // ---- seed codes

  openCode() {
    if (!this.live()) return;
    this.menus.show("code_panel");
    this.text("code_message", "");
  }

  pasteCode() {
    if (!this.live("code_panel")) return;
    const text = clipboard.paste();
    if (!text) {
      this.text("code_message", "code.pasteEmpty");
      return;
    }
    /** @type {any} */ (world.find("code_field")).set("TextField", { text });
    this.text("code_message", "");
  }

  playCode() {
    if (!this.live("code_panel")) return;
    const typed = /** @type {any} */ (world.find("code_field")).get("TextField").text;
    const found = codes.decode(typed);
    if (!found.ok) {
      this.text("code_message", "code.invalid", { message: found.message, hint: found.hint });
      return;
    }
    startRun({ seed: found.seed, stratum: found.stratum, floor: found.floor });
    enter(SHIFT_SCENE);
  }
}
