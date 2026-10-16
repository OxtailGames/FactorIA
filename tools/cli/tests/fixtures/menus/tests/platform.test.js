import { test, expect, game } from "factoria:test";
import { ui, input, storage, session, platform, game as running } from "factoria";

// The shop of the main menu (scripts/ui/shop.js) and the store hooks of a level, run against the fake backend that every
// test run uses (docs/PLATFORM.md). The menu is driven with the gamepad, like tests/menus.test.js; `game.platform` plays
// the store: it makes the next answer a cancel or a network error, delays answers, and sends events.
const pad = game.gamepad(0);
const focused = () => (ui.focused ? ui.focused.id : null);
const text = (id) => game.find(id).get("Text").text;
const wallet = () => storage.get("wallet", { gems: 0, noAds: false });
const methods = () => game.platform.calls().map((c) => c.method);

// Opens the main menu (with empty storage and a fresh fake store unless `keep`), then the Shop panel.
function openShop(keep = false) {
  if (!keep) {
    storage.clear();
    game.platform.reset();
  }
  delete session.settingsApplied;
  input.resetBindings();
  game.load("scenes/menu.scene.json");
  game.step(2);
  expect(focused()).toBe("play");
  for (let i = 0; i < 3; i++) pad.tap("DpadDown"); // Options, Credits, Shop
  expect(focused()).toBe("shop_button");
  pad.tap("A");
  game.step(1);
  expect(game.find("shop").activeInHierarchy).toBe(true);
  expect(focused()).toBe("buy_gems");
}

test("the shop appears in the main menu because the run has a store", () => {
  expect(platform.has("purchases")).toBe(true);
  openShop();
  // The store's own titles and prices replace the button texts.
  expect(game.find("buy_gems").get("Button").text).toBe("100 gems - $0.99");
  expect(game.find("buy_remove_ads").get("Button").text).toBe("Remove ads - $2.99");
  pad.tap("B");
  expect(focused()).toBe("shop_button");
});

test("buying gems adds them and finishes the transaction", () => {
  openShop();
  pad.tap("A");
  game.step(1);
  expect(text("shop_status")).toBe("Thank you!");
  expect(text("gems_label")).toBe("Gems: 100");
  expect(wallet().gems).toBe(100);
  expect(methods().filter((m) => m === "purchases.buy" || m === "purchases.finish")).toEqual(["purchases.buy", "purchases.finish"]);
  expect(game.platform.state().fake.unfinished).toEqual([]);
  pad.tap("A"); // a second pack
  game.step(1);
  expect(wallet().gems).toBe(200);
  expect(wallet().seen.length).toBe(2);
});

test("a cancelled purchase says so and grants nothing", () => {
  openShop();
  game.platform.respond("purchases.buy", { status: "cancelled" });
  pad.tap("A");
  game.step(1);
  expect(text("shop_status")).toContain("cancelled");
  expect(text("gems_label")).toBe("Gems: 0");
  expect(wallet().gems).toBe(0);
  expect(methods()).not.toContain("purchases.finish");
});

test("a network failure shows the store's hint, grants nothing and lets the player try again", () => {
  openShop();
  game.platform.respond("purchases.buy", { error: "network", message: "no route to the store", hint: "Check the connection." });
  pad.tap("A");
  game.step(1);
  expect(text("shop_status")).toContain("network");
  expect(text("shop_status")).toContain("Check the connection.");
  expect(wallet().gems).toBe(0);
  expect(game.platform.state().fake.owned).toEqual([]);
  pad.tap("A"); // the scripted failure was used once: the next try goes through
  game.step(1);
  expect(text("shop_status")).toBe("Thank you!");
  expect(wallet().gems).toBe(100);
});

test("a delayed answer shows waiting until the frames pass, and a second press waits for the first", () => {
  openShop();
  game.platform.set({ delayFrames: 10 });
  pad.tap("A");
  expect(text("shop_status")).toBe("Waiting for the store...");
  pad.tap("A"); // ignored: one purchase at a time
  game.step(3);
  expect(text("shop_status")).toBe("Waiting for the store...");
  expect(wallet().gems).toBe(0);
  game.step(12);
  expect(text("shop_status")).toBe("Thank you!");
  expect(wallet().gems).toBe(100);
  expect(methods().filter((m) => m === "purchases.buy").length).toBe(1);
  // finish() is delayed like every call: the gems are granted first, the store hears about it later.
  expect(game.platform.state().fake.unfinished.length).toBe(1);
  game.step(12);
  expect(game.platform.state().fake.unfinished).toEqual([]);
});

test("restore gives back the non-consumable and not the consumable", () => {
  openShop();
  pad.tap("A"); // 100 gems
  pad.tap("DpadDown");
  pad.tap("A"); // Remove ads
  game.step(1);
  expect(wallet().noAds).toBe(true);
  // A new install: the wallet is gone, the store remembers what the player bought.
  storage.clear();
  openShop(true);
  expect(text("gems_label")).toBe("Gems: 0");
  pad.tap("DpadDown");
  pad.tap("DpadDown");
  expect(focused()).toBe("restore");
  pad.tap("A");
  game.step(1);
  expect(text("shop_status")).toBe("Your purchases were restored.");
  expect(text("gems_label")).toBe("Gems: 0   (ads removed)");
  expect(wallet().noAds).toBe(true);
  expect(wallet().gems).toBe(0);
});

test("a purchase that waits for approval is granted when the store sends it", () => {
  openShop();
  game.platform.respond("purchases.buy", { status: "pending" });
  pad.tap("A");
  game.step(1);
  expect(text("shop_status")).toContain("approval");
  expect(wallet().gems).toBe(0);
  game.platform.emit("purchase", { status: "purchased", productId: "gems_100", transactionId: "ask-1" });
  game.step(2);
  expect(text("shop_status")).toBe("Your purchase arrived.");
  expect(wallet().gems).toBe(100);
  expect(wallet().seen).toEqual(["ask-1"]);
  // The store delivers the same transaction again (it was not finished in time): the player is not paid twice.
  game.platform.emit("purchase", { status: "purchased", productId: "gems_100", transactionId: "ask-1" });
  game.step(2);
  expect(wallet().gems).toBe(100);
});

test("an achievement unlocks during play, and the fake store shows it", () => {
  storage.clear();
  game.platform.reset();
  game.load("scenes/level.scene.json");
  game.step(60);
  expect(game.platform.state().fake.achievements.first_jump).toBeUndefined();
  game.tap("jump");
  game.step(2);
  const state = game.platform.state().fake;
  expect(state.achievements.first_jump.unlocked).toBe(true);
  expect(state.stats.jumps).toBe(1);
});

test("the store overlay pauses the game and closing it resumes", () => {
  storage.clear();
  game.platform.reset();
  game.load("scenes/level.scene.json");
  game.step(2);
  expect(running.paused).toBe(false);
  game.platform.emit("overlay", { open: true });
  game.step(1);
  expect(running.paused).toBe(true);
  game.platform.emit("overlay", { open: false });
  game.step(1);
  expect(running.paused).toBe(false);
});

test("a game the player paused stays paused when the overlay closes", () => {
  storage.clear();
  game.platform.reset();
  game.load("scenes/level.scene.json");
  game.step(2);
  game.tap("pause");
  expect(running.paused).toBe(true);
  game.platform.emit("overlay", { open: true });
  game.step(1);
  game.platform.emit("overlay", { open: false });
  game.step(1);
  expect(running.paused).toBe(true);
});
