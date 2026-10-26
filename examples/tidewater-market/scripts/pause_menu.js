// @ts-check
// Put this behaviour on one entity of every level: the "pause" action (Escape, P, gamepad Start) pauses the game and
// opens the pause menu. game.paused freezes physics, animations and the other scripts; this one keeps running
// (runWhilePaused) to drive the menu and its options panel.
import { Behaviour, ui, input, game, scene, world, i18n } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";
import { readMenusAloud } from "./ui/read_aloud.js";
import { SlotsScreen } from "./ui/slots_screen.js";
import { readMeta } from "./game/save_store.js";

export default class PauseMenu extends Behaviour {
  runWhilePaused = true;

  onStart() {
    applyOnce();
    readMenusAloud();
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
      game.paused = false; // time.scale outlives scene loads
      scene.load("scenes/menu.scene.json");
    });
    ui.on("click", (e) => e.entity.hasTag("back") && this.back());
    // ui_cancel (Escape, gamepad B) goes back one panel. Escape is also "pause": onUpdate handles that press.
    ui.on("cancel", () => !input.pressed("pause") && this.back());
  }

  /**
   * "Save game" (P4): when the level has a game controller with an autosaver (scripts/game/game_controller.js), a button joins the
   * pause panel and opens the slots in "save" mode. A level without one has no save button.
   */
  addSave() {
    const holder = world.find("controller");
    const controller = holder && holder.behaviour;
    if (!controller || !controller.autosaver) return;
    const here = scene.current;
    world.spawn(
      { id: "pause_save", components: { Button: { text: i18n.t("pause.save"), key: "pause.save", autoSize: true, layer: 302 } } },
      { parent: world.find("pause_box"), index: 2 }, // under Resume
    );
    this.slots = new SlotsScreen({
      mode: "save",
      menus: this.menus,
      layer: 320,
      isCurrent: () => scene.current === here,
      save: (slot) => {
        const run = controller.run;
        const previous = readMeta(slot, "manual");
        const name = previous ? previous.name : run.name || i18n.t(`scenario.${run.scenario}.name`);
        return controller.autosaver.saveManual(slot, name);
      },
    });
    ui.on("click", "pause_save", () => this.slots.open());
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
    if (!this.saveChecked) {
      this.saveChecked = true;
      this.addSave(); // the game controller starts after this script, so its autosaver is only there now
    }
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
