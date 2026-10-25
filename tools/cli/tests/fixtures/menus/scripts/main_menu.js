// @ts-check
// The title screen (scenes/menu.scene.json): Play, Options, Credits, Quit, and Shop when the shop part is in the game.
// Panels open over each other with MenuStack; a button tagged "back" or ui_cancel (Escape, gamepad B) returns to the previous panel.
import { Behaviour, ui, game, scene, session, platform } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";
import { readMenusAloud } from "./ui/read_aloud.js";
import { openAgeGate } from "./ui/age_gate.js"; // @kit:ageGate

export default class MainMenu extends Behaviour {
  /** Scene the Play button starts, through the loading screen. */
  firstScene = "scenes/level.scene.json";

  onStart() {
    applyOnce();
    readMenusAloud();
    this.menus = new MenuStack("main_menu");
    // The Shop button is for games with in-app purchases: it appears when this run has a store (docs/PLATFORM.md).  // @kit:shop
    if (platform.has("purchases")) this.world.find("shop_button").active = true; // @kit:shop
    if (game.platform === "ios" || game.platform === "android") this.world.find("quit").active = false; // mobile apps do not quit themselves
    // A game for children and adults (platform.ads.audience "mixed") asks the birth year once, before any ad (docs/MENUS.md).  // @kit:ageGate
    if (platform.ads.audience === "mixed") openAgeGate(this.menus); // @kit:ageGate
    ui.on("click", "play", () => {
      session.nextScene = this.firstScene; // scenes/loading.scene.json shows the progress of reading it, then loads it
      scene.load("scenes/loading.scene.json");
    });
    ui.on("click", "options_button", () => this.menus.show("options"));
    ui.on("click", "credits_button", () => this.menus.show("credits"));
    ui.on("click", "shop_button", () => this.menus.show("shop")); // @kit:shop
    ui.on("click", "quit", () => game.quit());
    ui.on("click", (e) => e.entity.hasTag("back") && this.menus.back());
    ui.on("cancel", () => this.menus.back());
  }
}
