// @ts-check
// The title screen (scenes/menu.scene.json): Play, Load game (the save screen), Chapter select (after the first ending), Options,
// Credits, Quit, and Shop when the shop part is in the game.
// Panels open over each other with MenuStack; a button tagged "back" or ui_cancel (Escape, gamepad B) returns to the previous panel.
import { Behaviour, ui, game, scene, session, world, i18n } from "factoria";
import { applyOnce } from "./settings.js";
import { startTitleMusic } from "./sound.js";
import { MenuStack } from "./ui/menu_stack.js";
import * as story from "./story.js";
import * as items from "./items.js";
import * as chapters from "./chapters.js";
import { readMenusAloud } from "./ui/read_aloud.js";
import { SlotScreen } from "./ui/slot_screen.js";
import * as saves from "./saves.js";
import * as progress from "./progress.js";
import * as save_data from "./save_data.js";

export default class MainMenu extends Behaviour {
  /** Scene the Play button starts, through the loading screen. */
  firstScene = "scenes/ground.scene.json";

  onStart() {
    applyOnce();
    readMenusAloud();
    startTitleMusic();
    this.menus = new MenuStack("main_menu");
    if (game.platform === "ios" || game.platform === "android") this.world.find("quit").active = false; // mobile apps do not quit themselves
    this.slots = new SlotScreen(this.menus);
    const panel = world.spawnPrefab("prefabs/ui/chapter_select.prefab.json");
    panel.id = "chapter_select";
    panel.active = false;
    ui.on("click", "play", () => this.newGame());
    ui.on("click", "load_button", () => this.slots.open("load"));
    ui.on("click", "chapters_button", () => this.openChapters());
    for (let n = 1; n <= 5; n++) ui.on("click", `chapter_${n}`, () => this.startChapter(n));
    i18n.on("change", () => this.menus.top === "chapter_select" && this.writeChapters());
    this.refreshButtons();
    ui.on("click", "options_button", () => this.menus.show("options"));
    ui.on("click", "credits_button", () => this.menus.show("credits"));
    ui.on("click", "quit", () => game.quit());
    ui.on("click", (e) => e.entity.hasTag("back") && this.menus.back());
    ui.on("cancel", () => {
      if (!this.slots.cancel()) this.menus.back();
    });
  }

  onUpdate() {
    this.slots.tick();
  }

  /** Load game needs a slot to load; Chapter select needs an ending. */
  refreshButtons() {
    world.find("load_button").get("Button").interactable = saves.ALL.some((id) => saves.peek(id).status !== "empty");
    world.find("chapters_button").active = progress.chapterSelectUnlocked();
  }

  /** Forgets everything of the last game: story, inventory, the parts other packages registered, the play time. */
  freshState() {
    story.reset(); // a new game starts with no story flags and an empty inventory
    items.reset();
    save_data.resetAll();
    session.autosavedChapter = 0; // the chapter start of the new game is autosaved
    session.loadRestore = false;
    session.restoreSpawn = null;
  }

  newGame() {
    this.freshState();
    chapters.begin({ intro: true }); // chapter 1 of the night, opened by the intro (once); the conversation history starts empty
    session.nextScene = this.firstScene; // scenes/loading.scene.json shows the progress of reading it, then loads it
    scene.load("scenes/loading.scene.json");
  }

  openChapters() {
    this.menus.show("chapter_select");
    this.writeChapters();
  }

  /** Chapter 1 is always there; a later one once a game has begun it (scripts/progress.js keeps the save data of each chapter start). */
  writeChapters() {
    let first = "chapters_back";
    for (let n = 1; n <= 5; n++) {
      const open = n === 1 || progress.chapterStart(n) !== null;
      const button = world.find(`chapter_${n}`).get("Button");
      button.text = open ? i18n.t("chapterSelect.chapter", { n, title: i18n.t(chapters.info(n).titleKey) }) : i18n.t("chapterSelect.locked", { n });
      button.interactable = open;
      if (open && first === "chapters_back") first = `chapter_${n}`;
    }
    ui.focus(world.find(first));
  }

  startChapter(n) {
    if (n === 1) return this.newGame();
    const data = progress.chapterStart(n);
    if (!data) return;
    this.freshState();
    const r = saves.launch(data);
    if (!r.ok) {
      world.find("chapters_note").get("Text").text = `${r.message}. ${r.hint}`;
      return;
    }
    session.chapterShown = 0; // the chapter card shows, as in a night that reaches it
    session.autosavedChapter = 0; // and this start is autosaved like any other
  }
}
