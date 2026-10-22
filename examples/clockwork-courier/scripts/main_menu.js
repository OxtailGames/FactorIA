// @ts-check
// The title screen (scenes/main.scene.json): Play, Options, Credits, Quit. Panels open over each other with MenuStack;
// a button tagged "back" or ui_cancel (Escape, gamepad B) returns to the previous panel. Play starts the first level
// of scripts/levels.js through the loading screen. Android Back opens the previous panel (nothing to close: quits).
import { Behaviour, ui, game, scene, session, input } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";
import { readMenusAloud } from "./ui/read_aloud.js";
import { installUiSounds } from "./ui/ui_sounds.js";
import * as levels from "./levels.js";

export default class MainMenu extends Behaviour {
  onStart() {
    applyOnce();
    readMenusAloud();
    installUiSounds();
    this.menus = new MenuStack("main_menu");
    if (game.platform === "ios" || game.platform === "android") this.world.find("quit").active = false; // mobile apps do not quit themselves
    ui.on("click", "play", () => {
      session.nextScene = levels.first().scene; // scenes/loading.scene.json shows "Loading" for a frame, then loads it
      scene.load("scenes/loading.scene.json");
    });
    ui.on("click", "options_button", () => this.menus.show("options"));
    ui.on("click", "credits_button", () => this.menus.show("credits"));
    ui.on("click", "quit", () => game.quit());
    ui.on("click", (e) => e.entity.hasTag("back") && this.menus.back());
    ui.on("cancel", () => this.menus.back());
    this.offBack = input.onBack(() => this.menus.back());
  }

  onDestroy() {
    this.offBack?.();
  }
}
