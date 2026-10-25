// @ts-check
// The title screen (scenes/menu.scene.json): Play, Options, Credits, Quit. Panels open over each other with
// MenuStack; a button tagged "back" or ui_cancel (Escape, gamepad B) returns to the previous panel.
import { Behaviour, ui, game, scene, session } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";
import { readMenusAloud } from "./ui/read_aloud.js";
import { startRun } from "./game/run_state.js";
import * as analytics from "./game/analytics.js";

export default class MainMenu extends Behaviour {
  /** Scene the Play button starts, through the loading screen. */
  firstScene = "scenes/shift.scene.json";

  onStart() {
    applyOnce();
    readMenusAloud();
    this.menus = new MenuStack("main_menu");
    if (game.platform === "ios" || game.platform === "android") this.world.find("quit").active = false; // mobile apps do not quit themselves
    ui.on("click", "play", () => {
      startRun(); // a new run: a fresh seed, no cash, base upgrades (P4 adds "Continue" from the save)
      session.nextScene = this.firstScene; // scenes/loading.scene.json shows the progress of reading it, then loads it
      scene.load("scenes/loading.scene.json");
    });
    ui.on("click", "options_button", () => this.menus.show("options"));
    ui.on("click", "credits_button", () => this.menus.show("credits"));
    ui.on("click", "boards_button", () => this.menus.show("boards")); // P5: scripts/ui/boards.js
    ui.on("click", "quit", () => this.quit());
    ui.on("click", (e) => e.entity.hasTag("back") && this.menus.back());
    ui.on("cancel", () => this.menus.back());
  }

  /** Quit. With the player's consent the analytics "quit" event is sent first (P5; the engine has no event for closing the window). */
  quit() {
    if (!analytics.enabled()) return game.quit();
    let done = false;
    const go = () => !done && ((done = true), game.quit());
    analytics.quit().then(go, go);
    this.after(1.5, go); // a server that does not answer must not keep the player from quitting
  }
}
