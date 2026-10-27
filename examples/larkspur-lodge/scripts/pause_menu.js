// @ts-check
// Put this behaviour on one entity of every level: the "pause" action (Escape, P, gamepad Start) pauses the game and
// opens the pause menu. game.paused freezes physics, animations and the other scripts; this one keeps running
// (runWhilePaused) to drive the menu and its options panel.
//
// It is also where the saved-game services of a level live (one entity per level, so nothing else needs wiring): it counts the play
// time (session.playTime), autosaves when a chapter has begun (scripts/saves.js autosave: once per chapter, as soon as the game is
// calm enough to be saved), keeps the picture of the game taken just before the menu covered it, opens the save / load screen
// (scripts/ui/slot_screen.js) and listens for endings and clues (scripts/progress.js).
import { Behaviour, ui, input, game, scene, session, time, world } from "factoria";
import { applyOnce } from "./settings.js";
import { MenuStack } from "./ui/menu_stack.js";
import { readMenusAloud } from "./ui/read_aloud.js";
import { SlotScreen } from "./ui/slot_screen.js";
import * as saves from "./saves.js";
import * as progress from "./progress.js";
import * as chapters from "./chapters.js";

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
    this.pic = null;
    this.slots = new SlotScreen(this.menus, { getPic: () => this.pic });
    progress.watch();
    ui.on("click", "resume", () => this.resume());
    ui.on("click", "pause_save", () => this.slots.open("save"));
    ui.on("click", "pause_load", () => this.slots.open("load"));
    ui.on("click", "pause_options", () => this.menus.show("options"));
    ui.on("click", "to_main_menu", () => {
      game.paused = false; // time.scale outlives scene loads
      this.slots.dispose();
      scene.load("scenes/menu.scene.json");
    });
    ui.on("click", (e) => e.entity.hasTag("back") && this.back());
    // ui_cancel (Escape, gamepad B) goes back one panel. Escape is also "pause": onUpdate handles that press.
    // While the save dialog is on top it takes the press itself: returning true consumes ui_cancel, so "pause" reads false
    // in onUpdate. A screen or the dialogue log that closed on the same press consumed it already: nothing to do here.
    ui.on("cancel", () => {
      if (!input.pressed("ui_cancel")) return false;
      if (this.slots.cancel()) return true;
      if (!input.pressed("pause")) this.back();
      return false;
    });
  }

  onUpdate() {
    if (this.resuming) {
      // Unpaused here, after this frame's gameplay was skipped: the A or Space press that clicked "Resume" must not
      // also reach the player as a jump.
      this.resuming = false;
      game.paused = false;
      return;
    }
    this.slots.tick();
    if (!game.paused) this.keepGame();
    // The pause key opens the menu, and inside it goes back one panel like ui_cancel (from the pause panel: resume).
    if (input.pressed("pause") && !MenuStack.busy) game.paused ? this.back() : this.pause();
  }

  /** Each running frame: counts the play time and autosaves when a new chapter has begun and the game can be saved. */
  keepGame() {
    const n = chapters.current();
    if (n === 0) return;
    session.playTime = (Number(session.playTime) || 0) + time.dt;
    if (session.autosavedChapter !== n && !saves.cannotSave()) {
      session.autosavedChapter = n;
      saves.autosave();
    }
  }

  pause() {
    this.pic = saves.capturePic(); // before the menu covers the game: the picture kept with a save
    const save = world.find("pause_save").get("Button");
    save.interactable = !saves.cannotSave();
    world.find("pause_load").get("Button").interactable = saves.ALL.some((id) => saves.peek(id).status === "used");
    game.paused = true;
    this.menus.show("pause_panel");
  }

  resume() {
    this.menus.closeAll();
    this.resuming = true;
  }

  back() {
    if (this.slots.cancel()) return;
    if (this.menus.top === "pause_panel") this.resume();
    else this.menus.back();
  }
}
