// @ts-check
// The title screen (scenes/menu.scene.json): Play, Options, Credits, Quit. Panels open over each other with
// MenuStack; a button tagged "back" or ui_cancel (Escape, gamepad B) returns to the previous panel.
import { Behaviour, ui, game, i18n } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";
import { nextToPlay } from "./progress.js";
import { startLevel } from "./flow.js";
import { fitWidgets } from "./ui/text_fit.js";

export default class MainMenu extends Behaviour {
  onStart() {
    applyOnce();
    this.menus = new MenuStack("main_menu");
    const menu = this.world.find("main_menu");
    fitWidgets(menu); // buttons as big as their label at the player's text size
    i18n.on("change", () => fitWidgets(menu));
    if (game.platform === "ios" || game.platform === "android") this.world.find("quit").active = false; // mobile apps do not quit themselves
    // Play: the first unlocked level that is not finished (save slots and a level select replace this later). The level
    // loads through scenes/loading.scene.json, which shows "Loading" for a frame (flow.js).
    ui.on("click", "play", () => startLevel(nextToPlay().id));
    ui.on("click", "options_button", () => this.menus.show("options"));
    ui.on("click", "credits_button", () => this.menus.show("credits"));
    ui.on("click", "quit", () => game.quit());
    ui.on("click", (e) => e.entity.hasTag("back") && this.menus.back());
    ui.on("cancel", () => this.menus.back());
  }
}
