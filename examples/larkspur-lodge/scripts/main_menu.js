// @ts-check
// The title screen (scenes/menu.scene.json): Play, Options, Credits, Quit, and Shop when the shop part is in the game.
// Panels open over each other with MenuStack; a button tagged "back" or ui_cancel (Escape, gamepad B) returns to the previous panel.
import { Behaviour, ui, game, scene, session, platform } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";
import * as story from "./story.js";
import * as items from "./items.js";
import { readMenusAloud } from "./ui/read_aloud.js";

export default class MainMenu extends Behaviour {
  /** Scene the Play button starts, through the loading screen. */
  firstScene = "scenes/ground.scene.json";

  onStart() {
    applyOnce();
    readMenusAloud();
    this.menus = new MenuStack("main_menu");
    if (game.platform === "ios" || game.platform === "android") this.world.find("quit").active = false; // mobile apps do not quit themselves
    ui.on("click", "play", () => {
      story.reset(); // a new game starts with no story flags and an empty inventory
      items.reset();
      session.nextScene = this.firstScene; // scenes/loading.scene.json shows the progress of reading it, then loads it
      scene.load("scenes/loading.scene.json");
    });
    ui.on("click", "options_button", () => this.menus.show("options"));
    ui.on("click", "credits_button", () => this.menus.show("credits"));
    ui.on("click", "quit", () => game.quit());
    ui.on("click", (e) => e.entity.hasTag("back") && this.menus.back());
    ui.on("cancel", () => this.menus.back());
  }
}
