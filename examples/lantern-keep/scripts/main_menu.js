// @ts-check
// The title screen (scenes/menu.scene.json): Play, Options, Credits, Quit. Panels open over each other with
// MenuStack; a button tagged "back" or ui_cancel (Escape, gamepad B) returns to the previous panel.
import { Behaviour, ui, game, session, i18n } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";
import * as saves from "./saves.js";
import { openSlots } from "./ui/slots.js";
import { refreshSelect } from "./ui/level_select.js";
import { fitWidgets } from "./ui/text_fit.js";

export default class MainMenu extends Behaviour {
  onStart() {
    applyOnce();
    this.menus = new MenuStack("main_menu");
    const menu = this.world.find("main_menu");
    fitWidgets(menu); // buttons as big as their label at the player's text size
    i18n.on("change", () => fitWidgets(menu));
    if (game.platform === "ios" || game.platform === "android") this.world.find("quit").active = false; // mobile apps do not quit themselves
    MenuStack.main = this.menus;
    // Play: the save slots (scripts/ui/slots.js), then the level select. Continue: the last used slot's level select.
    ui.on("click", "play", () => this.showSlots());
    ui.on("click", "continue", () => saves.choose(saves.lastUsed()) && this.openSelect(false));
    this.world.find("continue").active = saves.lastUsed() > 0;
    // Back from a level: the level select of the slot being played (flow.js openMenu).
    if (session.menuTarget === "level_select" && session.slot) this.openSelect(true);
    session.menuTarget = null;
    ui.on("click", "options_button", () => this.menus.show("options"));
    ui.on("click", "credits_button", () => this.menus.show("credits"));
    // The store screens (scripts/ui/store_ui.js says why when there is no store). A hidden panel's script does not run: tell it it was opened.
    for (const id of ["achievements", "leaderboards", "shop"]) ui.on("click", `${id}_button`, () => (this.menus.show(id), this.world.find(id).behaviour?.opened()));
    ui.on("click", "quit", () => game.quit());
    ui.on("click", (e) => e.entity.hasTag("back") && this.menus.back());
    ui.on("cancel", () => this.menus.back());
  }

  showSlots() {
    this.menus.show("slots");
    openSlots();
  }

  /** Shows the level select over the slot screen (`viaSlots`) or over the main menu, so Back returns where it came from. */
  openSelect(viaSlots) {
    if (viaSlots) this.menus.show("slots");
    this.menus.show("level_select");
    refreshSelect();
  }
}
