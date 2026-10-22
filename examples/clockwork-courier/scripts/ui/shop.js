// @ts-check
// The paint shop (panel "shop" of scenes/main.scene.json): choose a robot paint with the arrows, Equip it, or buy it; Remove
// ads, the Oil can tip and Restore purchases are below. The title robot turns while the shop is open and wears the paint being
// looked at. All the buying goes through scripts/store.js; this file only shows state and sends clicks.
//
// What a paint can be (scripts/paints.js, `paintView()` below):
//   equipped   the robot wears it now
//   owned      free, or unlocked by stars, or bought: Equip
//   stars      still locked by total stars: "Needs 8 stars (you have 5)"; the button is greyed out
//   buy        a purchase of the store (priced): Buy
// The buttons that show a price or a state have no `key` in the scene (it would overwrite the text each frame, FB-0027).
// Messages of the last action (thanks, cancelled, pending, unreachable) show in "shop_status".
import { Behaviour, world, ui, i18n, platform } from "factoria";
import { PAINTS } from "../paints.js";
import * as paints from "../paints.js";
import * as store from "../store.js";
import * as progress from "../progress.js";
import { EVENTS, emit } from "../events.js";

/**
 * What the shop shows for one paint.
 * @param {import("../paints.js").Paint} paint
 * @returns {{ state: "equipped" | "owned" | "stars" | "buy", stars?: number, have?: number, product?: string }}
 */
export function paintView(paint) {
  if (store.paintUnlocked(paint)) return { state: store.equippedPaint() === paint.id ? "equipped" : "owned" };
  if (paint.unlock.type === "stars") return { state: "stars", stars: paint.unlock.stars, have: progress.totalStars() };
  return { state: "buy", product: paint.unlock.type === "product" ? paint.unlock.product : "" };
}

export default class Shop extends Behaviour {
  /** Degrees per second the title robot turns while the shop is open. */
  turnSpeed = 40;
  /** Id of the title robot entity. */
  robotId = "title_robot";

  onStart() {
    this.setup();
  }

  onEnable() {
    this.setup();
    this.status = "";
    this.index = Math.max(0, PAINTS.findIndex((p) => p.id === store.equippedPaint()));
    this.loadProducts();
    this.refresh();
  }

  onDisable() {
    // Back to the paint worn: the preview of a paint not chosen does not stay on the robot.
    this.paintRobot(store.equippedPaint());
  }

  onDestroy() {
    for (const off of this.offs ?? []) off();
  }

  /** Registers the handlers once (onStart and the first onEnable both call it). */
  setup() {
    if (this.ready) return;
    this.ready = true;
    this.busy = false;
    this.dirty = false;
    this.status = "";
    this.index = 0;
    /** @type {Record<string, { price: string, title: string }>} */
    this.products = {};
    this.offs = [
      ui.on("click", "shop_prev", () => this.step(-1)),
      ui.on("click", "shop_next", () => this.step(1)),
      ui.on("click", "shop_paint_action", () => this.paintAction()),
      ui.on("click", "shop_remove_ads", () => this.purchase("remove_ads")),
      ui.on("click", "shop_tip", () => this.purchase("tip_jar")),
      ui.on("click", "shop_restore", () => this.restore()),
      // A purchase that arrives later (Ask to Buy approved): services grants it, the next frame shows it.
      platform.on("purchase", () => (this.dirty = true)),
    ];
  }

  onUpdate(dt) {
    if (!this.entity.active) return;
    const robot = world.find(this.robotId);
    if (robot) {
      const t = robot.get("Transform");
      t.rotation = [0, (t.rotation[1] + this.turnSpeed * dt) % 360, 0];
    }
    if (this.dirty) {
      this.dirty = false;
      this.refresh();
    }
  }

  /** Reads the store's titles and prices (async); the buttons show them once they are there. */
  loadProducts() {
    platform.purchases
      .products()
      .then((list) => {
        for (const p of list) this.products[p.id] = { price: p.price, title: p.title };
        this.dirty = true;
      })
      .catch(() => {
        this.dirty = true; // no prices: the buttons show only the name
      });
  }

  price(id) {
    return this.products[id]?.price ?? "";
  }

  step(delta) {
    this.index = (this.index + delta + PAINTS.length) % PAINTS.length;
    this.status = "";
    this.refresh();
  }

  get paint() {
    return PAINTS[this.index];
  }

  paintAction() {
    if (this.busy) return;
    const paint = this.paint;
    const view = paintView(paint);
    if (view.state === "owned") {
      if (store.equip(paint.id)) emit(EVENTS.paintEquipped, { paint: paint.id });
      this.status = "";
      this.refresh();
    } else if (view.state === "buy" && view.product) {
      this.purchase(view.product);
    }
  }

  /** @param {string} productId */
  async purchase(productId) {
    if (this.busy) return;
    this.busy = true;
    this.status = i18n.t("shop.working");
    this.refresh(); // the buttons go off while the store answers
    const r = await store.buy(productId);
    this.busy = false;
    this.status = i18n.t(r.key, r.args);
    this.refresh();
  }

  async restore() {
    if (this.busy) return;
    this.busy = true;
    this.status = i18n.t("shop.working");
    this.refresh(); // the buttons go off while the store answers
    const r = await store.restore();
    this.busy = false;
    this.status = i18n.t(r.key, r.args);
    this.refresh();
  }

  setText(id, text) {
    const e = world.find(id);
    if (e) e.get("Text").text = text;
  }

  setButton(id, text, interactable = true) {
    const e = world.find(id);
    if (!e) return;
    const b = e.get("Button");
    b.text = text;
    b.interactable = interactable;
  }

  setStatus(text) {
    this.setText("shop_status", text);
  }

  paintRobot(id) {
    const robot = world.find(this.robotId);
    if (robot) paints.apply(robot, id);
  }

  /** Redraws every text and button from the state of the store. */
  refresh() {
    const paint = this.paint;
    const view = paintView(paint);
    this.paintRobot(paint.id);
    this.setText("shop_paint_name", i18n.t(paint.nameKey));
    let state = "";
    let label = "";
    let can = true;
    if (view.state === "equipped") {
      state = i18n.t("shop.state.equipped");
      label = i18n.t("shop.equipped");
      can = false;
    } else if (view.state === "owned") {
      state = i18n.t(paint.unlock.type === "free" ? "shop.state.free" : "shop.state.owned");
      label = i18n.t("shop.equip");
    } else if (view.state === "stars") {
      state = i18n.t("shop.state.stars", { stars: view.stars, have: view.have });
      label = i18n.t("shop.locked");
      can = false;
    } else {
      state = i18n.t("shop.state.buy");
      label = i18n.t("shop.buy", { price: this.price(view.product ?? "") });
    }
    this.setText("shop_paint_state", state);
    this.setButton("shop_paint_action", label, can && !this.busy);
    const noAds = store.noAds();
    this.setButton("shop_remove_ads", noAds ? i18n.t("shop.adsRemoved") : i18n.t("shop.removeAds", { price: this.price("remove_ads") }), !noAds && !this.busy);
    this.setButton("shop_tip", i18n.t("shop.tip", { price: this.price("tip_jar"), count: store.load().tips }), !this.busy);
    this.setButton("shop_restore", i18n.t("shop.restore"), !this.busy);
    this.setStatus(this.status);
  }
}
