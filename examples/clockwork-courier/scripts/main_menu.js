// @ts-check
// The title screen (scenes/main.scene.json): Play, Options, Credits, Quit. Panels open over each other with MenuStack;
// a button tagged "back" or ui_cancel (Escape, gamepad B) returns to the previous panel. Play starts the first level
// of scripts/levels.js through the loading screen. Android Back closes the top panel; at the title it asks before quitting.
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
    // Android Back at the title asks before leaving (the quit confirmation is spawned here, like the pause menu's panels).
    const confirm = this.world.spawnPrefab("prefabs/ui/quit_confirm.prefab.json");
    confirm.id = "quit_confirm";
    confirm.active = false;
    ui.on("click", "quit_yes", () => game.quit());
    if (game.platform === "ios" || game.platform === "android") this.world.find("quit").active = false; // mobile apps do not quit themselves
    ui.on("click", "play", () => {
      session.nextScene = levels.first().scene; // scenes/loading.scene.json shows a step bar for three frames, then loads it
      scene.load("scenes/loading.scene.json");
    });
    ui.on("click", "options_button", () => this.menus.show("options"));
    ui.on("click", "credits_button", () => this.menus.show("credits"));
    ui.on("click", "quit", () => game.quit());
    ui.on("click", (e) => e.entity.hasTag("back") && this.menus.back());
    ui.on("cancel", () => this.menus.back());
    // Back closes the top panel; at the title itself it asks "Quit the game?" (Back again, or Stay, closes the question).
    this.offBack = input.onBack(() => {
      if (!this.menus.back() && !MenuStack.busy) this.menus.show("quit_confirm");
      return true;
    });
  }

  onDestroy() {
    this.offBack?.();
  }
}
