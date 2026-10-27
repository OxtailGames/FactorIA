// Saved games: the versioned format and its migration, the five slots and the autosave, the save / load screen (mouse, gamepad,
// touch), naming a save, the cloud, the chapter select and the store's achievements and stats.
import { test, describe, expect, game } from "factoria:test";
import { scene, session, storage, platform, ui, i18n, time } from "factoria";
import OnScreenKeyboard from "../scripts/ui/keyboard.js";
import { MenuStack } from "../scripts/ui/menu_stack.js";
import { enter, porter } from "./helpers/lodge.js";
import * as save_data from "../scripts/save_data.js";
import * as saves from "../scripts/saves.js";
import * as progress from "../scripts/progress.js";
import * as story from "../scripts/story.js";
import * as items from "../scripts/items.js";
import * as chapters from "../scripts/chapters.js";
import * as dialogue from "../scripts/dialogue.js";
import * as cutscene from "../scripts/cutscene.js";
import v1 from "./fixtures/save_v1.json";
import v2 from "./fixtures/save_v2.json";

// A 1x1 PNG: a picture that is certainly valid, whatever the headless renderer captures.
const PNG = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==";
const pad = () => game.gamepad(0);
const text = (id) => game.find(id).get("Text").text;
const label = (id) => game.find(id).get("Button").text;

function waitForScene(path, max = 400) {
  for (let i = 0; i < max && scene.current !== path; i++) game.step(1);
  expect(scene.current).toBe(path);
  game.step(30);
}

/** A clean run of the game: no slots, no progress, English, a signed-in fake store. */
function clean() {
  game.resetState();
  MenuStack.busy = false;
  for (const id of saves.ALL) storage.remove(saves.key(id));
  for (const k of ["lastSlot", "saveCounter", "settings"]) storage.remove(k);
  progress.reset();
  story.reset();
  items.reset();
  save_data.resetAll();
  session.autosavedChapter = 0;
  session.loadRestore = false;
  session.restoreSpawn = null;
  i18n.setLanguage("en");
  time.scale = 1;
  game.platform.reset();
}

/** Starts a game in chapter 1 in `area` and plays until the chapter start is settled (and autosaved). */
function play(area = "ground") {
  clean();
  chapters.begin();
  game.load(`scenes/${area}.scene.json`, { arrive: "spawn_default" });
  game.step(120);
}

/** Lets the store's answers through (they are Promises). */
async function settle() {
  for (let i = 0; i < 6; i++) await Promise.resolve();
  game.step(2); // a request made during a frame is answered by the next ones
  for (let i = 0; i < 6; i++) await Promise.resolve();
}

function openPause() {
  game.tap("pause");
  game.step(3);
  expect(game.paused).toBe(true);
}

describe("the format", () => {
  test("a v1 save loads in the v2 game: migrated, every part restored, the same place", () => {
    clean();
    const up = save_data.upgrade(JSON.parse(JSON.stringify(v1)));
    expect(up.ok).toBe(true);
    expect(up.data.format).toBe("larkspur.save/2");
    expect(up.data.place).toEqual({ area: "upstairs", position: [1.5, 0.95, -2], yaw: 90 });
    expect(up.data.playTime).toBe(0);
    expect(up.data.state.inventory).toEqual(["library_key"]);
    expect(up.data.state.story.counters.trust_hedda).toBe(2);
    storage.set("slot1", JSON.stringify(v1)); // a slot holding a bare v1 file
    const p = saves.peek(1);
    expect(p.status).toBe("used");
    expect(p.record.chapter).toBe(2);
    expect(p.record.name).toBe("");
    game.load("scenes/menu.scene.json");
    game.step(3);
    expect(saves.load(1).ok).toBe(true);
    waitForScene("scenes/upstairs.scene.json");
    expect(story.get("chapter")).toBe(2);
    expect(story.has("know_oil")).toBe(true);
    expect(items.has("library_key")).toBe(true);
    expect(session.area).toBe("upstairs");
    expect(porter().position.x).toBeCloseTo(1.5, 0);
    expect(porter().position.z).toBeCloseTo(-2, 0);
  });

  test("a v2 fixture loads, with its play time, and snapshot() writes the same shape", () => {
    clean();
    game.load("scenes/menu.scene.json");
    game.step(3);
    expect(save_data.apply(JSON.parse(JSON.stringify(v2))).ok).toBe(true);
    expect(save_data.playTime()).toBe(3725.5);
    const again = save_data.snapshot();
    expect(Object.keys(again).sort()).toEqual(Object.keys(v2).sort());
    expect(again.state.story).toEqual(v2.state.story);
    expect(again.state.inventory).toEqual(v2.state.inventory);
    expect(again.playTime).toBe(3725.5);
  });

  test("a damaged, foreign or newer save is refused with a message that says what to do", () => {
    expect(save_data.upgrade(null).ok).toBe(false);
    const newer = save_data.upgrade({ ...v2, format: "larkspur.save/9" });
    expect(newer.ok).toBe(false);
    expect(newer.message).toContain("newer");
    expect(newer.hint).toContain("Update the game");
    const alien = save_data.upgrade({ ...v2, format: "other/1" });
    expect(alien.message).toContain("other/1");
    const area = save_data.upgrade({ ...v2, place: { ...v2.place, area: "celar" } });
    expect(area.ok).toBe(false);
    expect(area.hint).toContain("Did you mean 'cellar'");
    expect(save_data.upgrade({ ...v2, state: undefined }).ok).toBe(false);
    expect(saves.parse("{ not json").ok).toBe(false);
    storage.set("slot3", "{ not json");
    expect(saves.peek(3).status).toBe("damaged");
    expect(saves.load(3).ok).toBe(false);
  });

  test("another package's part (register) and a plain session object (registerSession) are saved and restored", () => {
    clean();
    session.diary = { entries: ["oil on the stair"] };
    save_data.register("diary", {
      snapshot: () => session.diary,
      restore: (d) => { session.diary = d; },
      reset: () => { session.diary = { entries: [] }; },
    });
    save_data.registerSession("marks", { links: [] });
    session.marks.links.push(["oil", "cellar"]);
    for (const k of ["story", "inventory", "dialogue", "diary", "marks"]) expect(save_data.partKeys().includes(k)).toBe(true);
    const data = JSON.parse(JSON.stringify(save_data.snapshot()));
    expect(data.state.diary.entries).toEqual(["oil on the stair"]);
    expect(data.state.marks.links).toEqual([["oil", "cellar"]]);
    save_data.resetAll();
    expect(session.diary.entries).toEqual([]);
    expect(session.marks.links).toEqual([]);
    expect(save_data.apply(data).ok).toBe(true);
    expect(session.diary.entries).toEqual(["oil on the stair"]);
    expect(session.marks.links).toEqual([["oil", "cellar"]]);
    // a save from before the part existed starts it fresh
    const old = JSON.parse(JSON.stringify(v2));
    expect(save_data.apply(old).ok).toBe(true);
    expect(session.diary.entries).toEqual([]);
  });

  test("a part whose module loads later still gets its data (pending hand-over)", () => {
    clean();
    const data = JSON.parse(JSON.stringify(v2));
    data.state.late_part = { n: 7 };
    expect(save_data.apply(data).ok).toBe(true);
    expect(save_data.snapshot().state.late_part).toEqual({ n: 7 }); // written back untouched meanwhile
    let got = null;
    save_data.register("late_part", { snapshot: () => got, restore: (d) => { got = d; } });
    expect(got).toEqual({ n: 7 });
  });
});

describe("slots", () => {
  test("every slot round-trips: name, chapter, play time, picture and the game inside", () => {
    play();
    story.set("know_oil");
    items.add("library_key", "test");
    session.playTime = 3725.5;
    for (const id of saves.SLOTS) {
      story.set("chapter", 1);
      const r = saves.write(id, { name: `Save number ${id}`, pic: PNG });
      expect(r).not.toBeNull();
    }
    const counters = saves.SLOTS.map((id) => saves.peek(id).record.counter);
    expect(new Set(counters).size).toBe(5); // each save has its own revision
    for (const id of saves.SLOTS) {
      const p = saves.peek(id);
      expect(p.status).toBe("used");
      expect(p.record.name).toBe(`Save number ${id}`);
      expect(p.record.pic).toBe(PNG);
      expect(p.record.playTime).toBe(3725.5);
      expect(p.record.chapter).toBe(1);
      expect(p.record.data.format).toBe("larkspur.save/2");
      expect(p.record.data.state.inventory).toEqual(["library_key"]);
      expect(saves.parse(storage.get(saves.key(id))).record.pic).toBe(PNG); // through the storage text itself
    }
    expect(storage.get("lastSlot")).toBe(5);
  });

  test("a save with no name takes the chapter's title; the time is shown as h:mm:ss", () => {
    play();
    const r = saves.write(2, { name: "   " });
    expect(r.name).toBe(i18n.t("chapter.1.title"));
    expect(saves.formatTime(3725.5)).toBe("1:02:05");
    expect(saves.formatTime(-4)).toBe("0:00:00");
  });

  test("a picture of the game can be captured as a PNG, or is null when nothing can be drawn", () => {
    play();
    const pic = saves.capturePic();
    expect(pic === null || typeof pic === "string").toBe(true);
    if (pic !== null) expect(pic.startsWith("iVBOR")).toBe(true); // PNG signature in base64
  });

  test("the game is autosaved when a chapter begins, once, and again for the next chapter", () => {
    play();
    const a = saves.peek("auto");
    expect(a.status).toBe("used");
    expect(a.record.chapter).toBe(1);
    const counter = a.record.counter;
    game.step(120);
    expect(saves.peek("auto").record.counter).toBe(counter); // not again for the same chapter
    story.set("chapter", 2);
    game.step(10);
    const b = saves.peek("auto");
    expect(b.record.chapter).toBe(2);
    expect(b.record.counter).toBeGreaterThan(counter);
    expect(progress.chapterStart(2).state.story.flags.chapter).toBe(2);
    expect(progress.chapterStart(1)).not.toBeNull();
  });

  test("it cannot be saved without a game, nor during a conversation", () => {
    clean();
    game.load("scenes/menu.scene.json");
    game.step(3);
    expect(saves.cannotSave()).toBe("slots.noGame");
    expect(saves.write(1, { name: "x" })).toBeNull();
    play();
    expect(saves.cannotSave()).toBe("");
    stand();
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(3);
    expect(saves.cannotSave()).toBe("slots.noDialogue");
    expect(saves.write(1, { name: "x" })).toBeNull();
    expect(saves.peek(1).status).toBe("empty");
    dialogue.abort();
    game.step(3);
    expect(saves.cannotSave()).toBe("");
  });

  test("the play time counts running frames only, not the pause", () => {
    play();
    const t0 = save_data.playTime();
    game.step(60);
    const t1 = save_data.playTime();
    expect(t1 - t0).toBeGreaterThan(0.8);
    expect(t1 - t0).toBeLessThan(1.2);
    openPause();
    game.step(60);
    expect(save_data.playTime()).toBeCloseTo(t1 + 0.05, 1);
  });
});

function stand() {
  porter().position = [2, 0.95, 2];
  game.step(2);
}

describe("the save / load screen", () => {
  test("pause -> Save game: a click on a slot opens the name dialog; typing a name and Save writes it", () => {
    play();
    openPause();
    expect(game.find("pause_save").get("Button").interactable).toBe(true);
    game.click(game.find("pause_save"));
    game.step(2);
    expect(game.find("slots").active).toBe(true);
    expect(text("slots_title")).toBe("Save game");
    expect(label("slot_auto")).toContain("Autosave:");
    expect(game.find("slot_auto").get("Button").interactable).toBe(false); // the autosave is never a target
    expect(label("slot_1")).toBe("Slot 1: empty");
    game.click(game.find("slot_1"));
    game.step(2);
    expect(game.find("slot_dialog").active).toBe(true);
    expect(game.paused).toBe(true);
    // The pause key and Escape belong to the text while it is typed: "P" is a letter here.
    const field = game.find("save_name").get("TextField");
    field.text = "";
    game.typeText("Pale oil");
    game.step(2);
    expect(field.text).toBe("Pale oil");
    expect(game.find("slots").active).toBe(false);
    game.click(game.find("dialog_confirm"));
    game.step(2);
    expect(saves.peek(1).record.name).toBe("Pale oil");
    expect(game.find("slot_dialog").active).toBe(false);
    expect(game.find("slots").active).toBe(true);
    expect(label("slot_1")).toContain("Pale oil");
    expect(text("slots_note")).toBe("Saved to slot 1.");
    expect(game.paused).toBe(true);
  });

  test("Escape closes the dialog first, then the screen, then resumes", () => {
    play();
    openPause();
    game.click(game.find("pause_save"));
    game.step(2);
    game.click(game.find("slot_2"));
    game.step(2);
    game.tapKey("Escape"); // Escape is the pause action too: while a name is typed it only cancels the dialog
    game.step(2);
    expect(game.find("slot_dialog").active).toBe(false);
    expect(game.find("slots").active).toBe(true);
    expect(saves.peek(2).status).toBe("empty");
    game.tap("pause");
    game.step(2);
    expect(game.find("slots").active).toBe(false);
    expect(game.find("pause_panel").active).toBe(true);
    game.tap("pause");
    game.step(5);
    expect(game.paused).toBe(false);
  });

  test("gamepad only: save to a slot with the on-screen keyboard, load it back from the title screen", () => {
    play();
    pad().tap("Start");
    game.step(3);
    expect(game.paused).toBe(true);
    pad().tap("DpadDown"); // Resume -> Save game
    pad().tap("A");
    game.step(2);
    expect(game.find("slots").active).toBe(true);
    expect(ui.focused.id).toBe("slot_1");
    pad().tap("DpadDown");
    expect(ui.focused.id).toBe("slot_2");
    pad().tap("A");
    game.step(2);
    expect(game.find("slot_dialog").active).toBe(true);
    expect(OnScreenKeyboard.isOpen).toBe(true); // a gamepad player types with the on-screen keyboard
    expect(game.find("save_name").get("TextField").text).toBe(i18n.t("chapter.1.title")); // the default name
    pad().tap("B"); // the first B only closes the keyboard
    game.step(2);
    expect(OnScreenKeyboard.isOpen).toBe(false);
    expect(game.find("slot_dialog").active).toBe(true);
    pad().tap("B"); // the second one cancels the dialog
    game.step(2);
    expect(game.find("slot_dialog").active).toBe(false);
    expect(saves.peek(2).status).toBe("empty"); // cancelled: nothing saved
    expect(ui.focused.id).toBe("slot_2"); // the dialog gave the focus back
    pad().tap("A"); // slot 2 again
    game.step(2);
    expect(game.find("slot_dialog").active).toBe(true);
    pad().tap("B"); // the keyboard covers the buttons: close it
    game.step(2);
    game.click(game.find("dialog_confirm")); // Save with the default name
    game.step(2);
    expect(saves.peek(2).record.name).toBe(i18n.t("chapter.1.title"));
    // to the title screen and load it with the pad
    game.click(game.find("slots_back"));
    game.step(2);
    game.click(game.find("to_main_menu"));
    game.step(3);
    expect(scene.current).toBe("scenes/menu.scene.json");
    expect(game.find("load_button").get("Button").interactable).toBe(true);
    game.click(game.find("load_button"));
    game.step(2);
    expect(text("slots_title")).toBe("Load game");
    expect(ui.focused.id).toBe("slot_auto"); // the first used one
    expect(game.find("slot_1").get("Button").interactable).toBe(false); // empty: nothing to load
    pad().tap("DpadDown"); // the pad skips the empty slot 1
    expect(ui.focused.id).toBe("slot_2");
    pad().tap("A");
    waitForScene("scenes/ground.scene.json");
    expect(chapters.current()).toBe(1);
    expect(game.paused).toBe(false);
  });

  test("touch: a tap saves and a tap loads, and the deleted slot is empty again", () => {
    play();
    saves.write(3, { name: "Under the stairs", pic: PNG });
    openPause();
    game.touch(game.find("pause_load"), 3);
    game.step(2);
    expect(game.find("slots").active).toBe(true);
    expect(text("slots_title")).toBe("Load game");
    game.touch(game.find("delete_3"), 3);
    game.step(2);
    expect(game.find("slot_dialog").active).toBe(true);
    expect(game.find("save_name").active).toBe(false); // a delete asks, it does not name
    game.touch(game.find("dialog_confirm"), 3);
    game.step(2);
    expect(saves.peek(3).status).toBe("empty");
    expect(label("slot_3")).toBe("Slot 3: empty");
  });

  test("the rows show name, chapter, time and the picture of every slot; a damaged slot says so", () => {
    play();
    session.playTime = 3725.5;
    for (const id of [1, 2, 4]) saves.write(id, { name: `Night ${id}`, pic: PNG });
    storage.set("slot5", "{ damaged");
    openPause();
    game.click(game.find("pause_load"));
    game.step(3);
    expect(label("slot_2")).toBe("Slot 2: Night 2\nChapter 1, 1:02:05");
    expect(label("slot_3")).toBe("Slot 3: empty");
    expect(label("slot_5")).toContain("damaged");
    expect(text("slots_note")).toContain("cannot be read");
    for (const id of [1, 2, 4, "auto"]) {
      const withPic = saves.peek(id).record.pic !== null;
      expect(game.find(`pic_${id}`).get("Panel").texture !== "").toBe(withPic);
    }
    expect(game.find("pic_1").get("Panel").texture).not.toBe("");
    expect(game.find("pic_3").get("Panel").texture).toBe("");
    game.screenshot(".factoria/screenshots/slots_load.png");
  });

  test("the screen cannot save in a conversation and says why", () => {
    play();
    stand();
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(3);
    openPause();
    expect(game.find("pause_save").get("Button").interactable).toBe(false);
  });

  test("loading a slot from the pause menu puts the game back where it was saved", () => {
    play();
    story.set("know_cellar");
    items.add("library_key", "test");
    porter().position = [3, 0.95, 4];
    game.step(5);
    saves.write(1, { name: "Before", pic: PNG });
    story.reset();
    items.reset();
    story.set("chapter", 1);
    porter().position = [-3, 0.95, -4];
    openPause();
    game.click(game.find("pause_load"));
    game.step(2);
    game.click(game.find("slot_1"));
    waitForScene("scenes/ground.scene.json");
    expect(game.paused).toBe(false);
    expect(story.has("know_cellar")).toBe(true);
    expect(items.has("library_key")).toBe(true);
    expect(porter().position.x).toBeCloseTo(3, 0);
    expect(porter().position.z).toBeCloseTo(4, 0);
    expect(saves.peek("auto").record.name).not.toBe("Before"); // loading did not autosave over anything
  });
});

describe("the cloud", () => {
  test("a saved slot is uploaded when the player is signed in; a delete removes the copy", async () => {
    play();
    saves.write(2, { name: "Cloudy", pic: null });
    await settle();
    expect(Object.keys(game.platform.state().fake.cloud)).toContain("slot2");
    expect(JSON.parse(await platform.cloud.load("slot2")).name).toBe("Cloudy");
    saves.remove(2);
    await settle();
    expect(Object.keys(game.platform.state().fake.cloud)).not.toContain("slot2");
    expect(await saves.syncCloud()).toBe(false);
    expect(saves.peek(2).status).toBe("empty");
  });

  test("the copy with the higher counter wins when the screen opens; a damaged local slot is replaced", async () => {
    play();
    const rec = (counter, name) => JSON.stringify({ counter, name, chapter: 1, playTime: 10, pic: null, data: v2 });
    storage.set("slot1", rec(2, "local old"));
    storage.set("slot2", rec(9, "local new"));
    storage.set("slot3", "{ damaged");
    await platform.cloud.save("slot1", rec(4, "cloud new"));
    await platform.cloud.save("slot2", rec(3, "cloud old"));
    await platform.cloud.save("slot3", rec(1, "cloud only"));
    expect(await saves.syncCloud()).toBe(true);
    expect(saves.peek(1).record.name).toBe("cloud new");
    expect(saves.peek(2).record.name).toBe("local new");
    expect(JSON.parse(await platform.cloud.load("slot2")).counter).toBe(9); // the better local one went up
    expect(saves.peek(3).record.name).toBe("cloud only");
  });

  test("failures never lose or block the local save", async () => {
    play();
    game.platform.respond("cloud.save", { error: "network" });
    expect(saves.write(1, { name: "Offline" })).not.toBeNull();
    await settle();
    expect(saves.peek(1).record.name).toBe("Offline");
    game.platform.set({ signedIn: false });
    expect(saves.write(1, { name: "Signed out" })).not.toBeNull();
    expect(saves.peek(1).record.name).toBe("Signed out");
    game.platform.set({ signedIn: true });
    game.platform.respond("cloud.load", { error: "network" });
    expect(await saves.syncCloud()).toBe(false);
    expect(saves.peek(1).record.name).toBe("Signed out");
    game.platform.set({ backend: "none" });
    expect(await saves.syncCloud()).toBe(false); // no store: nothing to do
    expect(saves.write(2, { name: "No store" })).not.toBeNull();
    game.platform.reset();
  });

  test("the slot screen is drawn again after the sync only while its scene is still the current one", async () => {
    play();
    const rec = JSON.stringify({ counter: 5, name: "From the cloud", chapter: 1, playTime: 10, pic: null, data: v2 });
    await platform.cloud.save("slot4", rec);
    openPause();
    game.click(game.find("pause_load"));
    game.step(5);
    await settle();
    game.step(2);
    expect(label("slot_4")).toContain("From the cloud");
  });
});

describe("chapter select, achievements and stats", () => {
  test("the title screen offers the chapter select only after an ending", () => {
    clean();
    game.load("scenes/menu.scene.json");
    game.step(3);
    expect(game.find("chapters_button").active).toBe(false);
    progress.endingReached("dawn", 600);
    game.load("scenes/menu.scene.json");
    game.step(3);
    expect(game.find("chapters_button").active).toBe(true);
    game.screenshot(".factoria/screenshots/title_after_ending.png");
  });

  test("chapters you have begun are open; choosing one starts the night again from that chapter's story", () => {
    play();
    story.set("know_oil");
    story.set("chapter", 2);
    game.step(10); // autosave of chapter 2
    progress.endingReached("quiet", 1200);
    game.load("scenes/menu.scene.json");
    game.step(3);
    game.click(game.find("chapters_button"));
    game.step(2);
    expect(game.find("chapter_select").active).toBe(true);
    expect(game.find("chapter_1").get("Button").interactable).toBe(true);
    expect(game.find("chapter_2").get("Button").interactable).toBe(true);
    expect(game.find("chapter_3").get("Button").interactable).toBe(false);
    expect(label("chapter_2")).toBe(`Chapter 2: ${i18n.t("chapter.2.title")}`);
    expect(label("chapter_3")).toBe("Chapter 3: not reached yet");
    game.screenshot(".factoria/screenshots/chapter_select.png");
    story.reset();
    game.click(game.find("chapter_2"));
    waitForScene("scenes/ground.scene.json");
    expect(chapters.current()).toBe(2);
    expect(story.has("know_oil")).toBe(true);
    game.step(120);
    expect(saves.peek("auto").record.chapter).toBe(2); // this start is autosaved like any other
  });

  test("chapter 1 of the chapter select is a new game", () => {
    play();
    story.set("know_oil");
    progress.endingReached("long", 100);
    game.load("scenes/menu.scene.json");
    game.step(3);
    game.click(game.find("chapters_button"));
    game.step(2);
    game.click(game.find("chapter_1"));
    waitForScene("scenes/ground.scene.json");
    expect(chapters.current()).toBe(1);
    expect(story.has("know_oil")).toBe(false);
  });

  test("an ending unlocks its achievement and sets the stats; all three unlock 'all_endings'", async () => {
    play();
    progress.endingReached("dawn", 600);
    await settle();
    let fake = game.platform.state().fake;
    expect(fake.achievements.ending_dawn.unlocked).toBe(true);
    expect(fake.achievements.ending_quiet?.unlocked ?? false).toBe(false);
    expect(fake.stats.endings_seen).toBe(1);
    expect(fake.stats.play_minutes).toBe(10);
    progress.endingReached("quiet", 700);
    progress.endingReached("long", 800);
    await settle();
    fake = game.platform.state().fake;
    expect(fake.achievements.all_endings.unlocked).toBe(true);
    expect(fake.stats.endings_seen).toBe(3);
    expect(progress.endingsSeen()).toEqual(["dawn", "quiet", "long"]);
  });

  test("the story's own ending event reaches the store; every clue unlocks 'all_clues'", async () => {
    play();
    for (const c of progress.CLUES.slice(0, -1)) story.set(c);
    game.step(2);
    await settle();
    expect(game.platform.state().fake.achievements.all_clues?.unlocked ?? false).toBe(false);
    story.set(progress.CLUES[progress.CLUES.length - 1]);
    game.step(2);
    await settle();
    expect(game.platform.state().fake.achievements.all_clues.unlocked).toBe(true);
    story.set("chapter", 5);
    game.step(10);
    story.set("ending", "dawn");
    for (let i = 0; i < 300; i++) {
      if (cutscene.active()) cutscene.skip(); // the ending cut-scene plays before the ending screen (and the event)
      game.step(1);
    }
    await settle();
    expect(game.platform.state().fake.achievements.ending_dawn.unlocked).toBe(true);
    expect(progress.chapterSelectUnlocked()).toBe(true);
  });

  test("saving counts in the stats; a missing store changes nothing", async () => {
    play();
    saves.write(1, { name: "a" });
    await settle();
    saves.write(2, { name: "b" }); // (the fake's stats.add reads then writes: two at once count one)
    await settle();
    expect(game.platform.state().fake.stats.saves_made).toBe(2); // the autosave does not count
    game.platform.set({ backend: "none" });
    progress.endingReached("dawn", 60);
    expect(progress.endingsSeen()).toEqual(["dawn"]);
    game.platform.reset();
  });
});
