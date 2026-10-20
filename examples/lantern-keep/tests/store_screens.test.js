import { test, expect, game } from "factoria:test";
import { ui, storage, i18n, platform } from "factoria";
import * as progress from "../scripts/progress.js";
import * as settings from "../scripts/settings.js";
import { owns, available, chosen, COLOURS } from "../scripts/cosmetics.js";

// The three store screens (achievements, leaderboards, shop) of the main menu, driven with the gamepad only, against the fake store.
const pad = () => game.gamepad(0);
const fake = () => game.platform.state().fake;
const calls = (method) => game.platform.calls().filter((c) => c.method === method);
const text = (id) => game.find(id).get("Text").text;
const button = (id) => game.find(id).get("Button").text;
const lastCall = (method) => calls(method).at(-1);
const rows = (list) => game.find(list).children.map((c) => c.get("Text").text);

/** Every test starts like a new run of the game: English, nothing bought, nothing finished, a fresh fake store, on the main menu. */
function fresh() {
  progress.reset();
  storage.remove("settings");
  storage.remove("wallet");
  storage.remove("leaderboardsSent");
  i18n.setLanguage("en");
  game.platform.reset();
  game.load("scenes/menu.scene.json");
  game.step(2);
}

/** Lets the requests a click started finish: the store answers at once, the script continues in the next microtasks. */
async function settle() {
  for (let i = 0; i < 4; i++) {
    game.step(1);
    await Promise.resolve();
  }
}

/** Moves the focus with the pad until it is on `id`: down, right, left and up as far as they go (the menu's layout may change). */
function focus(id) {
  for (let round = 0; round < 3; round++) {
    for (const dir of ["DpadDown", "DpadRight", "DpadLeft", "DpadUp"]) {
      for (let i = 0; i < 10 && ui.focused?.id !== id; i++) {
        const before = ui.focused?.id;
        pad().tap(dir);
        if (ui.focused?.id === before) break;
      }
    }
  }
  expect(ui.focused?.id).toBe(id);
}

/** Opens a store screen from the main menu with the pad. */
async function open(buttonId, panelId) {
  focus(buttonId);
  pad().tap("A");
  await settle();
  expect(game.find(panelId).active).toBe(true);
}

async function press(id) {
  focus(id);
  pad().tap("A");
  await settle();
}

/** A colour read from a component is array-like: compare it channel by channel with the plain array `b`. */
const near = (color, b) => b.forEach((v, i) => expect(color[i]).toBeCloseTo(v, 4));

// ---------------------------------------------------------------------------------------------------- achievements

test("the achievements screen lists the whole catalog with its state and progress, and asks again on every visit", async () => {
  fresh();
  await open("achievements_button", "achievements");
  expect(ui.focused.id).toBe("ach_back");
  expect(text("ach_summary")).toBe("0 of 8 unlocked");
  expect(text("ach_status")).toBe("");
  const list = rows("ach_list");
  expect(list.length).toBe(8);
  expect(list[0]).toBe("First Light  -  locked\nFinish level 1-1.");

  await platform.achievements.unlock("first_light");
  await platform.achievements.progress("jumper", 0.4);
  pad().tap("B"); // back to the main menu
  expect(game.find("main_menu").active).toBe(true);
  await open("achievements_button", "achievements");
  expect(text("ach_summary")).toBe("1 of 8 unlocked");
  const again = rows("ach_list");
  expect(again[0]).toBe("First Light  -  unlocked\nFinish level 1-1.");
  expect(again.find((r) => r.startsWith("Leap of Faith"))).toBe("Leap of Faith  -  40%\nJump 500 times.");
});

test("the achievements screen is in the player's language, also when it changes while open", async () => {
  fresh();
  await open("achievements_button", "achievements");
  expect(text("ach_title")).toBe("Achievements");
  i18n.setLanguage("es");
  game.step(2);
  expect(text("ach_title")).toBe("Logros");
  expect(text("ach_summary")).toBe("0 de 8 desbloqueados");
  expect(rows("ach_list")[0]).toBe("Primera luz  -  bloqueado\nTermina el nivel 1-1.");
  expect(button("ach_refresh")).toBe("Actualizar");
});

test("achievements: not signed in, a network error and no store each say so; Refresh signs in and tries again", async () => {
  fresh();
  game.platform.set({ signedIn: false });
  await open("achievements_button", "achievements");
  expect(rows("ach_list").length).toBe(0);
  expect(text("ach_status")).toContain("not signed in");
  expect(text("ach_summary")).toBe("");
  await press("ach_refresh"); // signs in, then lists
  expect(calls("player.signIn").length).toBeGreaterThan(0);
  game.platform.set({ signedIn: true });
  await press("ach_refresh");
  expect(rows("ach_list").length).toBe(8);
  expect(text("ach_status")).toBe("");

  game.platform.respond("achievements.list", { error: "network" });
  await press("ach_refresh");
  expect(text("ach_status")).toContain("could not be reached");
  expect(rows("ach_list").length).toBe(0);
  pad().tap("B");
  await open("achievements_button", "achievements"); // coming back asks again
  expect(rows("ach_list").length).toBe(8);

  game.platform.set({ backend: "none" }); // an exported game without a store plugin
  try {
    pad().tap("B");
    await open("achievements_button", "achievements");
    expect(text("ach_status")).toContain("not connected to a store");
    expect(rows("ach_list").length).toBe(0);
    await press("ach_refresh");
    expect(ui.focused.id).toBe("ach_refresh");
    pad().tap("B");
    expect(game.find("main_menu").active).toBe(true); // nothing is stuck
  } finally {
    game.platform.reset();
  }
});

// --------------------------------------------------------------------------------------------------- leaderboards

const entries = [
  { rank: 1, name: "Mira", score: 38120, playerId: "p1", isPlayer: false },
  { rank: 2, name: "Player", score: 41200, playerId: "fake-player", isPlayer: true },
  { rank: 3, name: "Odd", score: 95000, playerId: "p3", isPlayer: false },
];

test("the leaderboards screen shows the top entries and the player's own best; Board and Show change the request", async () => {
  fresh();
  game.platform.respond("leaderboards.entries", { result: entries }, 8);
  await open("leaderboards_button", "leaderboards");
  expect(button("lb_board")).toBe("Board: 1-1  First Light");
  expect(button("lb_range")).toBe("Show: Top");
  expect(rows("lb_list")).toEqual(["1. Mira   0:38.12", "2. Player   0:41.20  <", "3. Odd   1:35.00"]);
  expect(text("lb_own")).toBe("Your best: 0:41.20 (rank 2)");
  expect(lastCall("leaderboards.entries").args.id).toBe("time_1-1"); expect(lastCall("leaderboards.entries").args.range).toBe("top");

  await press("lb_board");
  expect(button("lb_board")).toBe("Board: 1-2  The Gate");
  expect(lastCall("leaderboards.entries").args.id).toBe("time_1-2");
  for (let i = 0; i < 5; i++) await press("lb_board");
  expect(button("lb_board")).toBe("Board: All six levels");
  expect(lastCall("leaderboards.entries").args.id).toBe("time_total");
  await press("lb_range");
  expect(button("lb_range")).toBe("Show: Around me");
  expect(lastCall("leaderboards.entries").args.range).toBe("around");
  await press("lb_range");
  expect(button("lb_range")).toBe("Show: Friends");
  expect(lastCall("leaderboards.entries").args.range).toBe("friends");
});

test("the leaderboards screen with no times, signed out, a network error, no store and in Spanish", async () => {
  fresh();
  game.platform.respond("leaderboards.entries", { result: [] });
  await open("leaderboards_button", "leaderboards");
  expect(text("lb_status")).toBe("No times yet. Finish a level to be the first.");
  expect(text("lb_own")).toBe("");

  game.platform.set({ signedIn: false });
  await press("lb_refresh");
  expect(text("lb_status")).toContain("not signed in");
  game.platform.set({ signedIn: true });
  game.platform.respond("leaderboards.entries", { error: "network" });
  await press("lb_refresh");
  expect(text("lb_status")).toContain("could not be reached");
  expect(rows("lb_list").length).toBe(0);

  game.platform.respond("leaderboards.entries", { result: entries });
  await press("lb_refresh");
  expect(rows("lb_list").length).toBe(3);
  i18n.setLanguage("es");
  game.step(2);
  expect(button("lb_board")).toBe("Tabla: 1-1  Primera luz");
  expect(button("lb_range")).toBe("Ver: Mejores");
  expect(text("lb_own")).toBe("Tu mejor tiempo: 0:41.20 (puesto 2)");

  game.platform.set({ backend: "none" });
  try {
    await press("lb_refresh");
    expect(text("lb_status")).toContain("no está conectada");
    expect(rows("lb_list").length).toBe(0);
    pad().tap("B");
    expect(game.find("main_menu").active).toBe(true);
  } finally {
    game.platform.reset();
  }
});

// ------------------------------------------------------------------------------------------------------------ shop

test("the shop lists both cosmetic packs with the store's prices, and nothing else", async () => {
  fresh();
  await open("shop_button", "shop");
  expect(ui.focused.id).toBe("shop_buy_colours");
  expect(game.find("shop_buy_colours").get("Button").interactable).toBe(true);
  expect(button("shop_buy_colours")).toBe("Lantern colours - $1.99");
  expect(button("shop_buy_supporter")).toBe("Supporter - $4.99");
  expect(button("shop_colour")).toBe("Lantern colour: Amber");
  expect(button("shop_restore")).toBe("Restore purchases");
  expect(owns("lantern_colours")).toBe(false);
  expect(chosen().id).toBe("amber");
  expect(available().map((c) => c.id)).toEqual(["amber"]);
  await press("shop_colour"); // only amber: nothing changes
  expect(button("shop_colour")).toBe("Lantern colour: Amber");
});

test("buying Lantern colours makes the colours available; the chosen one reaches the player in every level", async () => {
  fresh();
  await open("shop_button", "shop");
  await press("shop_buy_colours");
  expect(text("shop_status")).toBe("Thank you! It is yours.");
  expect(button("shop_buy_colours")).toBe("Lantern colours (owned)");
  expect(owns("lantern_colours")).toBe(true);
  expect(owns("supporter")).toBe(false);
  expect(fake().owned).toContain("lantern_colours");
  expect(fake().unfinished).toEqual([]); // granted first, then finished
  expect(available().map((c) => c.id)).toEqual(["amber", "rose", "azure", "jade", "violet"]);
  await press("shop_colour");
  expect(button("shop_colour")).toBe("Lantern colour: Rose");
  expect(settings.load().lanternColour).toBe("rose");
  await press("shop_buy_colours");
  expect(text("shop_status")).toBe("You already have this.");
  expect(calls("purchases.buy").length).toBe(1);

  const rose = COLOURS.find((c) => c.id === "rose");
  for (const level of ["scenes/levels/1-1.scene.json", "scenes/levels/2-2.scene.json"]) {
    game.load(level);
    game.step(3);
    const player = game.find("player");
    near(player.get("Shape2D").color, rose.body);
    const lantern = player.children.find((c) => c.name === "Lantern");
    near(lantern.get("Light2D").color, rose.light);
    near(lantern.get("Shape2D").color, rose.flame);
  }
  game.load("scenes/menu.scene.json");
  game.step(2);
  expect(chosen().id).toBe("rose"); // it is a player setting: it survives
});

test("buying Supporter unlocks the gold lantern and a line in the credits", async () => {
  fresh();
  await open("credits_button", "credits");
  expect(game.find("credits_list").children.some((c) => c.active && c.get("Text").text.includes("supporters"))).toBe(false);
  pad().tap("B");
  await open("shop_button", "shop");
  await press("shop_buy_supporter");
  expect(owns("supporter")).toBe(true);
  expect(available().map((c) => c.id)).toEqual(["amber", "gold"]);
  await press("shop_colour");
  expect(button("shop_colour")).toBe("Lantern colour: Gold");
  pad().tap("B");
  await open("credits_button", "credits");
  game.step(2);
  expect(game.find("credits_list").children.some((c) => c.active && c.get("Text").text.includes("supporters"))).toBe(true);
  game.load("scenes/levels/1-3.scene.json");
  game.step(3);
  near(game.find("player").get("Shape2D").color, COLOURS.find((c) => c.id === "gold").body);
});

test("a cancelled purchase and a store error grant nothing and say so", async () => {
  fresh();
  await open("shop_button", "shop");
  game.platform.respond("purchases.buy", { status: "cancelled" });
  await press("shop_buy_colours");
  expect(text("shop_status")).toBe("Purchase cancelled. Nothing was added.");
  expect(owns("lantern_colours")).toBe(false);
  expect(button("shop_buy_colours")).toBe("Lantern colours - $1.99");

  game.platform.respond("purchases.buy", { error: "network" });
  await press("shop_buy_colours");
  expect(text("shop_status")).toContain("could not be reached");
  expect(owns("lantern_colours")).toBe(false);

  game.platform.respond("purchases.buy", { error: "failed", message: "card declined", hint: "Try another card." });
  await press("shop_buy_supporter");
  expect(text("shop_status")).toContain("Try another card.");
  expect(owns("supporter")).toBe(false);

  game.platform.respond("purchases.buy", { status: "pending" });
  await press("shop_buy_supporter");
  expect(text("shop_status")).toContain("waits for approval");
  expect(owns("supporter")).toBe(false);
  game.platform.emit("purchase", { status: "purchased", productId: "supporter", transactionId: "fake-77", receipt: "r" }); // approved later
  await settle();
  expect(owns("supporter")).toBe(true);
  expect(text("shop_status")).toBe("A purchase arrived. Thank you!");

  expect(wallet().owned).toEqual(["supporter"]);
  await press("shop_buy_colours"); // and a retry works
  expect(owns("lantern_colours")).toBe(true);
  expect(wallet().seen.length).toBe(2);
});

const wallet = () => storage.get("wallet");

test("not signed in: the shop says so and grants nothing", async () => {
  fresh();
  game.platform.set({ signedIn: false });
  await open("shop_button", "shop");
  expect(text("shop_status")).toContain("not signed in");
  await press("shop_buy_colours");
  expect(text("shop_status")).toContain("not signed in");
  expect(owns("lantern_colours")).toBe(false);
  await press("shop_restore");
  expect(text("shop_status")).toContain("not signed in");
  game.platform.set({ signedIn: true });
  await press("shop_buy_colours");
  expect(owns("lantern_colours")).toBe(true);
});

test("Restore purchases brings back what the store says the player owns", async () => {
  fresh();
  await open("shop_button", "shop");
  await press("shop_restore");
  expect(text("shop_status")).toBe("Nothing new to restore.");
  // The player bought both on another device: the store hands them over on restore.
  game.platform.respond("purchases.restore", {
    result: [
      { productId: "lantern_colours", transactionId: "other-1", receipt: "r1" },
      { productId: "supporter", transactionId: "other-2", receipt: "r2" },
    ],
  });
  await press("shop_restore");
  expect(text("shop_status")).toBe("Purchases restored.");
  expect(owns("lantern_colours")).toBe(true);
  expect(owns("supporter")).toBe(true);
  expect(button("shop_buy_supporter")).toBe("Supporter (owned)");
  expect(available().length).toBe(COLOURS.length);
  game.platform.respond("purchases.restore", { error: "network" });
  await press("shop_restore");
  expect(text("shop_status")).toContain("could not be reached");
  expect(owns("supporter")).toBe(true); // an error takes nothing away
});

test("without a store the shop explains it, keeps what the player already owns and never blocks", async () => {
  fresh();
  await open("shop_button", "shop");
  await press("shop_buy_supporter");
  try {
    pad().tap("B");
    game.platform.set({ backend: "none" });
    game.load("scenes/menu.scene.json"); // a new run of the game, now without a store
    game.step(2);
    await open("shop_button", "shop");
    expect(text("shop_status")).toContain("not connected to a store");
    expect(button("shop_buy_colours")).toBe("Lantern colours");
    expect(owns("lantern_colours")).toBe(false); // the buy buttons are greyed out, there is nothing to click
    await press("shop_restore");
    expect(text("shop_status")).toContain("not connected to a store");
    expect(button("shop_buy_supporter")).toBe("Supporter (owned)"); // kept: it is in the wallet
    expect(button("shop_colour")).toBe("Lantern colour: Amber");
    await press("shop_colour"); // the colour choice needs no store
    expect(button("shop_colour")).toBe("Lantern colour: Gold");
    pad().tap("B");
    expect(game.find("main_menu").active).toBe(true);
  } finally {
    game.platform.reset();
  }
});

test("without a store the buy buttons are greyed out and the pad still has a focus on the shop", async () => {
  fresh();
  try {
    game.platform.set({ backend: "none" });
    game.load("scenes/menu.scene.json"); // a new run of the game, now without a store
    game.step(2);
    await open("shop_button", "shop");
    for (const id of ["shop_buy_colours", "shop_buy_supporter"]) expect(game.find(id).get("Button").interactable).toBe(false);
    for (const id of ["shop_colour", "shop_restore", "shop_back"]) expect(game.find(id).get("Button").interactable).toBe(true);
    // autoFocus is on a greyed-out button: the engine gives the focus to the first button the pad can use
    expect(ui.focused.id).toBe("shop_colour");
    pad().tap("DpadUp");
    expect(ui.focused.id).toBe("shop_colour"); // the greyed-out buttons above are skipped
    pad().tap("DpadDown");
    expect(ui.focused.id).toBe("shop_restore");
    pad().tap("DpadDown");
    expect(ui.focused.id).toBe("shop_back");
    pad().tap("A");
    expect(game.find("main_menu").active).toBe(true);
  } finally {
    game.platform.reset();
  }
});

test("the shop is in Spanish when the game is", async () => {
  fresh();
  await open("shop_button", "shop");
  i18n.setLanguage("es");
  game.step(2);
  expect(text("shop_title")).toBe("Tienda");
  expect(button("shop_buy_colours")).toBe("Colores de linterna - $1.99");
  expect(button("shop_colour")).toBe("Color de la linterna: Ámbar");
  await press("shop_buy_colours");
  expect(text("shop_status")).toBe("¡Gracias! Ya es tuyo.");
  expect(button("shop_buy_colours")).toBe("Colores de linterna (comprado)");
  expect(button("shop_restore")).toBe("Restaurar compras");
});
