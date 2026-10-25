// @ts-check
// The camp (scenes/camp.scene.json): between two floors the brigade sits at a fire and spends the banked cash on the shop
// (game/upgrades.js). Nothing here decides a price or a rule: this script writes the texts, forwards a click on an upgrade to
// `buy`, shows the answer (a refusal teaches: what is short and what to do), saves the run to its slot and sends it down.
//
// Arrive here from the results (game/progression.js `go`) or from Continue on the title. The run state already holds the NEXT
// floor (`run.stratum`, `run.floor`); "Down to the mine" starts that shift.
import { Behaviour, ui, world, scene, session, i18n, audio } from "factoria";
import { run } from "./game/run_state.js";
import * as upgrades from "./game/upgrades.js";
import * as saveFile from "./game/save.js";
import * as cloud from "./game/cloud.js";
import * as codes from "./game/seed_code.js";
import * as clipboard from "./game/clipboard.js";
import { mineSeed } from "./game/run_state.js";
import { stratumInfo } from "./game/generator.js";
import { SHIFT_SCENE, LOADING_SCENE, TITLE_SCENE } from "./game/progression.js";

/** The code of the mine the next shift plays. */
export function nextMineCode() {
  return codes.encode({ seed: mineSeed(run.shiftNumber + 1), stratum: run.stratum, floor: run.floor });
}

/** A value of an upgrade written for the player ("x1.25", "150 s"). */
export function valueText(id, value) {
  const unit = upgrades.SHOP[id].unit;
  return i18n.t(`camp.unit.${unit}`, { value: Number.isInteger(value) ? value : Math.round(value * 100) / 100 });
}

export default class Camp extends Behaviour {
  onStart() {
    this.target = scene.current;
    this.age = 0;
    this.flames = ["flame0", "flame1", "flame2"].map((id) => world.find(id));
    this.refresh = () => this.fill();
    i18n.on("change", this.refresh);
    this.fill();
    for (const id of upgrades.ITEMS) ui.on("click", `buy_${id}`, () => this.buy(id));
    ui.on("click", "copy_code", () => this.copyCode());
    ui.on("click", "descend", () => this.descend());
    ui.on("click", "to_title", () => {
      if (scene.current !== this.target) return;
      this.sync();
      scene.load(TITLE_SCENE);
    });
    saveFile.save(); // arriving here is a save point: Continue from the title lands in this camp
    this.sync();
  }

  onUpdate(dt) {
    this.age += dt;
    this.fitList();
    this.flames.forEach((f, i) => {
      if (!f?.alive) return;
      const flick = 1 + 0.22 * Math.sin(this.age * (7 + i * 2.3) + i) + 0.1 * Math.sin(this.age * 17 + i * 5);
      f.scale = [1, flick, 1];
    });
  }

  /**
   * The shop and the side column sit in a scrolling list (at a big text size they no longer fit the screen). The list is
   * left-aligned and its width is mine, so it is as wide as what it holds (at most the screen): at a normal size the camp
   * stays centred like before.
   */
  fitList() {
    const body = ui.rectOf("camp_body");
    const list = world.find("camp_scroll");
    if (!body || !list) return;
    const size = list.get("ScrollList").size;
    const width = Math.min(Math.ceil(body[2]) + 12, 1260);
    if (Math.abs(size[0] - width) > 0.5) list.get("ScrollList").size = [width, size[1]];
  }

  onDestroy() {
    i18n.off?.("change", this.refresh);
  }

  /** @param {string} id @param {any} args */
  text(id, key, args) {
    const e = /** @type {any} */ (world.find(id));
    if (!e) throw new Error(`camp: the scene has no entity '${id}' (see scenes/camp.scene.json).`);
    e.set("Text", { key, keyArgs: args });
  }

  /** Writes every text from the run state. */
  fill() {
    this.text("camp_cash", "camp.cash", { cash: run.cash });
    this.text("camp_next", "camp.next", { stratum: i18n.t(stratumInfo(run.stratum).name), floor: run.floor });
    this.text("camp_seed", "camp.seed", { code: nextMineCode() });
    for (const id of upgrades.ITEMS) {
      const e = /** @type {any} */ (world.find(`buy_${id}`));
      const now = valueText(id, run.upgrades[id]);
      const offer = upgrades.offer(id);
      const name = i18n.t(`camp.name.${id}`);
      if (offer) e.set("Button", { key: "camp.buy", keyArgs: { name, now, next: valueText(id, offer.value), cost: offer.cost } });
      else e.set("Button", { key: "camp.buyMax", keyArgs: { name, now } });
    }
  }

  /** Shows a line under the shop. @param {string} key @param {any} [args] */
  say(key, args = {}) {
    this.text("camp_message", key, args);
  }

  /** @param {string} id */
  buy(id) {
    if (scene.current !== this.target) return;
    const result = upgrades.buy(id);
    if (!result.ok) {
      audio.play("assets/audio/blocked.wav", { volume: 0.6, bus: "sfx" });
      this.say("camp.refused", { message: result.message, hint: result.hint });
      return;
    }
    audio.play("assets/audio/ore.wav", { volume: 0.8, bus: "sfx" });
    this.fill();
    this.say("camp.bought", { name: i18n.t(`camp.name.${id}`), now: valueText(id, run.upgrades[id]) });
    saveFile.save();
    this.sync();
  }

  copyCode() {
    if (scene.current !== this.target) return;
    const code = nextMineCode();
    const done = clipboard.copy(code);
    this.say(done.system ? "camp.copied" : "camp.copiedSession", { code });
  }

  /** Pushes the slot to the cloud (upload only: the cloud never replaces a run in progress). */
  sync() {
    if (run.slot === null || run.mode === "daily") return;
    const slot = run.slot;
    cloud.syncSlot(slot, { allowDownload: false }); // the answer needs no screen here: the slot screen reports the sync
  }

  descend() {
    if (scene.current !== this.target) return;
    saveFile.save();
    session.nextScene = SHIFT_SCENE;
    scene.load(LOADING_SCENE);
  }
}
