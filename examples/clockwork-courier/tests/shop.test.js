// The paint shop and the purchases (scripts/ui/shop.js, scripts/store.js, scripts/paints.js) on the fake store: paints that
// unlock with stars, paints and "Remove ads" that are bought (success, cancel, failure, pending, restore, refund, the same
// transaction twice) and the robot that wears the result.
import { test, describe, expect, game, beforeEach, afterEach } from "factoria:test";
import * as progress from "../scripts/progress.js";
import * as store from "../scripts/store.js";
import * as paints from "../scripts/paints.js";
import * as svc from "../scripts/services.js";
import { paintView } from "../scripts/ui/shop.js";
import { fresh, cleanup, send, calls, fake, record, loadTitle, loadYard } from "./helpers/store.js";

const shop = () => game.find("shop").behaviour;
const open = () => {
  game.click("shop_button");
  game.step(5);
};
const status = () => game.find("shop_status").get("Text").text;
const action = () => game.find("shop_paint_action").get("Button");
/** The colour the title robot's body wears (the glTF material the paints replace). */
const robotColor = () => game.find("title_robot").get("MeshRenderer").materialColors[paints.BODY_MATERIAL];
/** Looks at the paint with this id: clicks Next until the shop shows it. */
const look = (id) => {
  for (let i = 0; i < paints.PAINTS.length && shop().paint.id !== id; i++) {
    game.click("shop_next");
    game.step(2);
  }
  expect(shop().paint.id).toBe(id);
};
const stars = (n) => {
  // three levels' worth of stars at most per call; spreads n stars over the six levels
  const ids = ["rooftops_1", "rooftops_2", "rooftops_3", "market_1", "market_2", "market_3"];
  let left = n;
  for (const id of ids) {
    const s = Math.min(3, left);
    left -= s;
    if (s > 0) progress.record(id, { time: 50, springLeft: 20, stars: s, goals: {} });
  }
};
const txn = (productId, id) => ({ status: "purchased", productId, transactionId: id });
const setup = () => {
  fresh();
  loadTitle();
};

describe("paints and their unlocks", () => {
  beforeEach(setup);
  afterEach(cleanup);

  test("the factory paint is free and worn; the others are locked by stars or priced", () => {
    expect(store.equippedPaint()).toBe("factory");
    const state = Object.fromEntries(paints.PAINTS.map((p) => [p.id, paintView(p).state]));
    expect(state).toEqual({ factory: "equipped", rust: "stars", mint: "stars", midnight: "stars", gold: "stars", copper: "buy", neon: "buy" });
  });

  test("stars unlock rust at 3, mint at 8, midnight at 13 and gold at 18", () => {
    for (const [paint, need] of [["rust", 3], ["mint", 8], ["midnight", 13], ["gold", 18]]) {
      fresh();
      stars(need - 1);
      expect(store.paintUnlocked(paints.byId(paint))).toBe(false);
      stars(need);
      expect(store.paintUnlocked(paints.byId(paint))).toBe(true);
    }
  });

  test("a locked paint says how many stars it needs and the button is greyed out", () => {
    stars(5);
    open();
    look("mint");
    expect(game.find("shop_paint_state").get("Text").text).toContain("8");
    expect(game.find("shop_paint_state").get("Text").text).toContain("5");
    expect(action().interactable).toBe(false);
    expect(store.equip("mint")).toBe(false);
  });

  test("Equip puts the paint on the robot, saves it, announces it and unlocks the achievement", () => {
    stars(3);
    open();
    const log = record(["paint_equipped"]);
    look("rust");
    expect(action().interactable).toBe(true);
    game.click("shop_paint_action");
    game.step(5);
    expect(store.equippedPaint()).toBe("rust");
    expect(log.map((e) => e.data.paint)).toEqual(["rust"]);
    expect(svc.isUnlocked("fresh_paint")).toBe(true);
    expect(paintView(paints.byId("rust")).state).toBe("equipped");
    expect(action().interactable).toBe(false);
    expect(robotColor()).toEqual(paints.byId("rust").body);
  });

  test("the robot shows the paint being looked at and goes back to the worn one when the shop closes", () => {
    open();
    look("neon");
    expect(robotColor()).toEqual(paints.byId("neon").body);
    game.click("shop_back");
    game.step(3);
    expect(robotColor()).toEqual(paints.byId("factory").body);
  });

  test("the title robot turns while the shop is open and stays still when it is closed", () => {
    const y = () => game.find("title_robot").get("Transform").rotation[1];
    open();
    const a = y();
    game.step(30);
    expect(y()).not.toBe(a);
    game.click("shop_back");
    game.step(3);
    const b = y();
    game.step(30);
    expect(y()).toBe(b);
  });

  test("the paint worn is on the courier of a level, and a refunded one falls back to the factory paint", () => {
    stars(3);
    store.equip("rust");
    loadYard();
    const model = game.find("courier").children.find((c) => c.id === "model");
    expect(model.get("MeshRenderer").materialColors[paints.BODY_MATERIAL]).toEqual(paints.byId("rust").body);
    fresh();
    expect(store.equippedPaint()).toBe("factory");
  });
});

describe("buying", () => {
  beforeEach(setup);
  afterEach(cleanup);

  test("the shop lists the prices of the store", () => {
    open();
    look("copper");
    expect(action().text).toContain("$0.99");
    expect(game.find("shop_remove_ads").get("Button").text).toContain("$2.99");
  });

  test("success: owned, saved, finished and the paint can be worn", () => {
    open();
    look("copper");
    game.click("shop_paint_action");
    game.step(10);
    expect(status()).toContain("Thank");
    expect(store.owns("paint_copper")).toBe(true);
    expect(fake().owned).toContain("paint_copper");
    expect(fake().unfinished.length).toBe(0);
    expect(paintView(paints.byId("copper")).state).toBe("owned");
    expect(action().text).toBe("Put on");
    expect(store.load().seen.length).toBe(1);
  });

  test("cancel: nothing is owned and the shop says so", () => {
    game.platform.respond("purchases.buy", { status: "cancelled" });
    open();
    look("neon");
    game.click("shop_paint_action");
    game.step(10);
    expect(status()).toContain("ancel");
    expect(store.owns("paint_neon")).toBe(false);
    expect(paintView(paints.byId("neon")).state).toBe("buy");
  });

  test("failure: the shop shows the reason and the button works again", () => {
    game.platform.respond("purchases.buy", { error: "network" });
    open();
    look("neon");
    game.click("shop_paint_action");
    game.step(10);
    expect(status()).toContain("network");
    expect(store.owns("paint_neon")).toBe(false);
    expect(action().interactable).toBe(true);
    game.click("shop_paint_action");
    game.step(10);
    expect(store.owns("paint_neon")).toBe(true);
  });

  test("while the store answers the buttons are off, so a double click buys once", () => {
    game.platform.set({ delayFrames: 10 });
    open();
    look("copper");
    game.click("shop_paint_action");
    game.step(2);
    expect(action().interactable).toBe(false);
    expect(status()).toBe("Talking to the store...");
    game.click("shop_paint_action");
    game.step(30);
    expect(calls("purchases.buy").length).toBe(1);
    expect(store.owns("paint_copper")).toBe(true);
  });

  test("pending (Ask to Buy): nothing yet; the approval arrives later and is granted with a toast", () => {
    game.platform.respond("purchases.buy", { status: "pending" });
    open();
    look("copper");
    game.click("shop_paint_action");
    game.step(10);
    expect(status()).toContain("approval");
    expect(store.owns("paint_copper")).toBe(false);
    game.platform.emit("purchase", txn("paint_copper", "txn-ask-1"));
    game.step(10);
    expect(store.owns("paint_copper")).toBe(true);
    expect(action().text).toBe("Put on"); // the open shop refreshed
    expect(svc.current().toasts.shown.some((t) => t.includes("paint_copper") || t.includes("Copper"))).toBe(true);
    expect(fake().unfinished.length).toBe(0);
  });

  test("the same transaction handed over twice is granted once (a tip counts once)", async () => {
    game.platform.emit("purchase", txn("tip_jar", "txn-tip-1"));
    game.step(5);
    game.platform.emit("purchase", txn("tip_jar", "txn-tip-1"));
    game.step(5);
    expect(store.load().tips).toBe(1);
  });

  test("the Oil can tip is a consumable: it can be bought again and never owned", () => {
    open();
    game.click("shop_tip");
    game.step(10);
    game.click("shop_tip");
    game.step(10);
    expect(store.load().tips).toBe(2);
    expect(store.owns("tip_jar")).toBe(false);
    expect(game.find("shop_tip").get("Button").text).toContain("2");
    expect(fake().unfinished.length).toBe(0);
  });

  test("Remove ads is bought once and the button says so", () => {
    open();
    game.click("shop_remove_ads");
    game.step(10);
    expect(store.noAds()).toBe(true);
    const b = game.find("shop_remove_ads").get("Button");
    expect(b.interactable).toBe(false);
    expect(b.text).toContain("removed");
  });
});

describe("restore and refund", () => {
  beforeEach(setup);
  afterEach(cleanup);

  test("Restore purchases brings back what the store lists after the local save is lost", () => {
    open();
    game.click("shop_remove_ads");
    game.step(10);
    look("copper");
    game.click("shop_paint_action");
    game.step(10);
    store.reset(); // a new phone: the save is gone, the store still has the purchases
    expect(store.noAds()).toBe(false);
    game.click("shop_restore");
    game.step(10);
    expect(status()).toContain("restored");
    expect(store.noAds()).toBe(true);
    expect(store.owns("paint_copper")).toBe(true);
    expect(store.owns("tip_jar")).toBe(false);
  });

  test("Restore with nothing bought says so", () => {
    open();
    game.click("shop_restore");
    game.step(10);
    expect(status()).toContain("Nothing");
  });

  test("Restore with the store down says why", () => {
    game.platform.respond("purchases.restore", { error: "network" });
    open();
    game.click("shop_restore");
    game.step(10);
    expect(status()).toContain("network");
  });

  test("the purchases of the store are granted at the start of the game without pressing anything", () => {
    open();
    game.click("shop_remove_ads");
    game.step(10);
    store.reset();
    loadTitle(); // a new run: the services reconcile with the store
    game.step(10);
    expect(store.noAds()).toBe(true);
  });

  test("a refund: a store that stops listing the product takes it away and the worn paint falls back", async () => {
    stars(0);
    open();
    look("copper");
    game.click("shop_paint_action");
    game.step(10);
    store.equip("copper");
    expect(store.equippedPaint()).toBe("copper");
    game.platform.revoke("paint_copper"); // a refund: the store stops listing it and sends the "revoked" event
    game.step(2);
    expect(store.owns("paint_copper")).toBe(false); // the listener took it away at once
    // a start-up check agrees with the store (it runs in a promise: step until it is done)
    let result = null;
    store.reconcile({ authoritative: true }).then((r) => (result = r));
    game.step(5);
    expect(result.revoked).toEqual([]);
    expect(store.owns("paint_copper")).toBe(false);
    expect(store.equippedPaint()).toBe("factory");
  });

  test("the fake store never revokes by itself: a development run keeps its purchases", () => {
    open();
    game.click("shop_remove_ads");
    game.step(10);
    game.platform.reset();
    loadTitle();
    game.step(10);
    expect(store.noAds()).toBe(true); // reconcile() is not authoritative on the fake backend
  });
});
