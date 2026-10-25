// @ts-check
// The title screen (scenes/menu.scene.json): Continue, Play (the three save slots), Daily dig, Seed code, Options, Credits, Quit.
// Panels open over each other with MenuStack; a button tagged "back" or ui_cancel (Escape, gamepad B) returns to the previous
// panel. The ways into a game live in ui/title_flow.js.
import { Behaviour, ui, game } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";
import { readMenusAloud } from "./ui/read_aloud.js";
import { TitleFlow } from "./ui/title_flow.js";

export default class MainMenu extends Behaviour {
  onStart() {
    applyOnce();
    readMenusAloud();
    this.menus = new MenuStack("main_menu");
    if (game.platform === "ios" || game.platform === "android") this.world.find("quit").active = false; // mobile apps do not quit themselves
    this.flow = new TitleFlow(this.menus);
    this.flow.start();
    ui.on("click", "options_button", () => this.menus.show("options"));
    ui.on("click", "credits_button", () => this.menus.show("credits"));
    ui.on("click", "quit", () => game.quit());
    ui.on("click", (e) => e.entity.hasTag("back") && this.menus.back());
    ui.on("cancel", () => this.menus.back());
  }
}
