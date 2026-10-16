// @ts-check
// Pauses the game with the "pause" action (Escape, P, gamepad Start): game.paused freezes physics, animations and
// gameplay scripts, and this behaviour keeps running (runWhilePaused) to show the pause menu and its options panel.
import { Behaviour, ui, input, game, scene, world } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";

export default class PauseMenu extends Behaviour {
  runWhilePaused = true;

  onStart() {
    applyOnce();
    this.menus = new MenuStack(null);
    // The options panel is the main menu's (one prefab for both). Spawned here rather than written into the scene,
    // which scene.import_ascii rebuilds from levels/level1.json.
    const options = world.spawnPrefab("prefabs/ui/options.prefab.json");
    options.id = "options"; // MenuStack shows panels by id
    options.active = false;
    ui.on("click", "resume", () => this.resume());
    ui.on("click", "pause_options", () => this.menus.show("options"));
    ui.on("click", "to_main_menu", () => {
      game.paused = false; // time.scale outlives scene loads
      scene.load("scenes/menu.scene.json");
    });
    ui.on("click", (e) => e.entity.hasTag("back") && this.back());
    // ui_cancel (Escape, gamepad B) goes back one panel. Escape is also "pause": onUpdate handles that press.
    ui.on("cancel", () => !input.pressed("pause") && this.back());
  }

  onUpdate() {
    if (this.resuming) {
      // Unpaused here, after this frame's gameplay was skipped: the A or Space press that clicked "Resume" must not
      // also reach the player as a jump.
      this.resuming = false;
      game.paused = false;
      return;
    }
    // The pause key opens the menu, and inside it goes back one panel like ui_cancel (from the pause panel: resume).
    if (input.pressed("pause") && !MenuStack.busy) game.paused ? this.back() : this.pause();
  }

  pause() {
    game.paused = true;
    this.menus.show("pause_panel");
  }

  resume() {
    this.menus.closeAll();
    this.resuming = true;
  }

  back() {
    if (this.menus.top === "pause_panel") this.resume();
    else this.menus.back();
  }
}
