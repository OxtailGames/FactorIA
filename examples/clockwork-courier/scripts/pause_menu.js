// @ts-check
// Put this behaviour on one entity of every level: the "pause" action (Escape, P, gamepad Start, the on-screen pause
// button) or the Android Back button pauses the game and opens the pause menu (Resume, Options, Restart, Quit to title).
// game.paused freezes physics, animations and the other scripts; this one keeps running (runWhilePaused) to drive the
// menu. Sends game_paused / game_resumed (scripts/events.js). Stays closed once the level is won or lost.
import { Behaviour, ui, input, game, scene, world } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";
import { readMenusAloud } from "./ui/read_aloud.js";
import { installUiSounds, playUi } from "./ui/ui_sounds.js";
import { EVENTS, emit } from "./events.js";

export default class PauseMenu extends Behaviour {
  runWhilePaused = true;
  /** Entity id of the level flow (its `finished` flag keeps the menu closed on the results and retry screens). */
  levelId = "level";

  onStart() {
    // The comfort entity (haptics, low-spring warning, pause on suspend) and the Captions entity that the Subtitles option
    // switches, spawned here so every level has them without a scene edit. Before applyOnce(): it finds "captions".
    world.spawnPrefab("prefabs/ui/comfort.prefab.json").id = "comfort";
    applyOnce();
    readMenusAloud();
    installUiSounds();
    this.menus = new MenuStack(null);
    // Spawned, not written into the level: any level works with this one entity, even one scene.import_ascii rebuilds.
    for (const [id, prefab] of [["pause_panel", "pause"], ["options", "options"]]) {
      const panel = world.spawnPrefab(`prefabs/ui/${prefab}.prefab.json`);
      panel.id = id; // MenuStack shows panels by id
      panel.active = false;
    }
    ui.on("click", "resume", () => this.resume());
    ui.on("click", "pause_options", () => this.menus.show("options"));
    ui.on("click", "pause_restart", () => {
      game.paused = false; // time.scale outlives scene loads
      scene.load(scene.current);
    });
    ui.on("click", "to_main_menu", () => {
      game.paused = false;
      scene.load("scenes/main.scene.json");
    });
    ui.on("click", (e) => e.entity.hasTag("back") && this.back());
    // ui_cancel (Escape, gamepad B) goes back one panel. Escape is also "pause": onUpdate handles that press.
    ui.on("cancel", () => !input.pressed("pause") && this.back());
    // Android Back: opens the menu in a level, goes back one panel in the menu, resumes from the pause panel, and on the
    // results and retry screens (level over) returns to the title.
    this.offBack = input.onBack(() => {
      if (this.locked()) {
        scene.load("scenes/main.scene.json"); // results and retry screens: Back leaves the level
        return true;
      }
      if (game.paused) this.back();
      else this.pause();
      return true;
    });
  }

  onDestroy() {
    this.offBack?.();
  }

  locked() {
    const flow = world.find(this.levelId)?.behaviour;
    return !!(flow && flow.finished);
  }

  onUpdate() {
    if (this.resuming) {
      // Unpaused here, after this frame's gameplay was skipped: the A or Space press that clicked "Resume" must not
      // also reach the player as a jump.
      this.resuming = false;
      game.paused = false;
      emit(EVENTS.gameResumed, {});
      return;
    }
    // The pause key opens the menu, and inside it goes back one panel like ui_cancel (from the pause panel: resume).
    if (this.locked()) return;
    if (input.pressed("pause") && !MenuStack.busy) game.paused ? this.back() : this.pause();
  }

  pause() {
    if (game.paused || this.locked()) return;
    game.paused = true;
    this.menus.show("pause_panel");
    playUi("open_001", 0.6);
    emit(EVENTS.gamePaused, {});
  }

  resume() {
    this.menus.closeAll();
    this.resuming = true;
    playUi("close_001", 0.6);
  }

  back() {
    if (this.menus.top === "pause_panel") this.resume();
    else this.menus.back();
  }
}
