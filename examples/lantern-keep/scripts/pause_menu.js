// @ts-check
// Put this behaviour on one entity of every level: the "pause" action (Escape, P, gamepad Start) pauses the game and
// opens the pause menu. game.paused freezes physics, animations and the other scripts; this one keeps running
// (runWhilePaused) to drive the menu and its options panel.
import { Behaviour, ui, input, game, world } from "factoria";
import { openMenu } from "./flow.js";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";

export default class PauseMenu extends Behaviour {
  runWhilePaused = true;

  onStart() {
    applyOnce();
    this.menus = new MenuStack(null);
    // Spawned, not written into the level: any level works with this one entity, even one scene.import_ascii rebuilds.
    for (const [id, prefab] of [["pause_panel", "pause"], ["options", "options"]]) {
      const panel = world.spawnPrefab(`prefabs/ui/${prefab}.prefab.json`);
      panel.id = id; // MenuStack shows panels by id
      panel.active = false;
    }
    ui.on("click", "resume", () => this.resume());
    ui.on("click", "pause_options", () => this.menus.show("options"));
    ui.on("click", "to_main_menu", () => {
      openMenu();
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
      world.find("level")?.behaviour?.refreshAssist(); // assist may have been turned on in Options while paused: the run counts as assisted
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
