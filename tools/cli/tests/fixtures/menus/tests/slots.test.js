// The save slots (scripts/slots.js) and their screen (scripts/ui/slot_screen.js): the record, the counter, a bare save, a damaged
// slot, the cloud merge by counter, the screen's save dialog (a name typed, the default name, cancel), loading, deleting (the cloud
// copy too) and a game that cannot be saved right now. The scene is built here, so this test passes in any game that has the slots part.
import { test, expect, game } from "factoria:test";
import { world, ui, storage, platform, scene, i18n } from "factoria";
import { MenuStack } from "../scripts/ui/menu_stack.js";
import { Slots, formatTime } from "../scripts/slots.js";
import { SlotScreen } from "../scripts/ui/slot_screen.js";
import { keysFor, hangulIme, IME, imeFor } from "../scripts/ui/keyboard.js";

// A 1x1 PNG: a picture that is certainly valid, whatever a headless renderer captures.
const PNG = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==";
const label = (id) => world.find(id).get("Button").text;

/** The slots of this test's imaginary game: its save is { level, gold } and a save with "old" in it is from a game version nobody can read. */
function makeSlots() {
  return new Slots({
    upgrade: (data) => (data.old ? { ok: false, message: "this save is from an older version", hint: "Delete the slot." } : { ok: true, data }),
    describe: (data) => ({ chapter: data.level, playTime: data.seconds }),
  });
}

/** Lets the store's answers through (they are Promises). */
async function settle() {
  for (let frame = 0; frame < 12; frame++) {
    for (let i = 0; i < 10; i++) await Promise.resolve();
    game.step(1);
  }
}

/** A clean run: empty storage, a signed-in fake store, an empty scene. */
function clean() {
  storage.clear();
  game.platform.reset();
  game.loadJson({ format: "factoria.scene/1", entities: [] });
  game.step(2);
}

/** The screen over a menu stack of its own, for a game that can always be saved except when `state.busy`. */
function openScreen(mode, state = { busy: false, level: 3, loaded: [] }, seed = () => {}) {
  clean();
  const slots = makeSlots();
  seed(slots);
  const menus = new MenuStack(null);
  const screen = new SlotScreen(menus, {
    slots,
    snapshot: () => ({ data: { level: state.level, gold: 40, seconds: 3725.5 }, chapter: state.level, playTime: 3725.5 }),
    launch: (data) => {
      state.loaded.push(data);
      return { ok: true };
    },
    cannotSave: () => (state.busy ? "slots.busy" : ""),
    defaultName: () => `Level ${state.level}`,
    getPic: () => PNG,
  });
  screen.open(mode);
  game.step(2);
  return { slots, menus, screen, state };
}

test("a record: counter, name, chapter, play time, picture and data; the counter goes up by one on every save", () => {
  clean();
  const slots = makeSlots();
  expect(slots.ALL).toEqual(["auto", 1, 2, 3, 4, 5]);
  expect(slots.key(2)).toBe("slot2");
  expect(slots.key("auto")).toBe("slot_auto");
  expect(slots.peek(1).status).toBe("empty");
  const a = slots.write(1, { data: { level: 2, gold: 5, seconds: 70 }, name: "  Before the cellar  ", chapter: 2, playTime: 70, pic: PNG });
  const b = slots.write(2, { data: { level: 3, gold: 9, seconds: 80 }, chapter: 3, playTime: 80 });
  expect([a.counter, b.counter]).toEqual([1, 2]);
  const p = slots.peek(1);
  expect(p.status).toBe("used");
  expect(p.record).toEqual({ version: 0, counter: 1, name: "Before the cellar", chapter: 2, playTime: 70, pic: PNG, data: { level: 2, gold: 5, seconds: 70 } });
  expect(slots.peek(2).record.pic).toBe(null);
  expect(slots.last()).toBe(2);
  slots.remove(2);
  expect(slots.peek(2).status).toBe("empty");
  expect(slots.last()).toBe(null);
  expect(slots.write(3, { data: { level: 1 } }).counter).toBe(3); // a removed slot's counter is not given again
  expect(formatTime(3725.5)).toBe("1:02:05");
  expect(formatTime(-4)).toBe("0:00:00");
});

test("a bare save is read as a record without a name; text that is not a save damages the slot with a reason", () => {
  clean();
  const slots = makeSlots();
  storage.set("slot1", JSON.stringify({ level: 4, gold: 1, seconds: 125 })); // no "data" field: the game's save as it is
  const bare = slots.peek(1);
  expect(bare.status).toBe("used");
  expect(bare.record).toEqual({ version: 0, counter: 0, name: "", chapter: 4, playTime: 125, pic: null, data: { level: 4, gold: 1, seconds: 125 } });
  storage.set("slot2", "{ not json");
  storage.set("slot3", "[1, 2]");
  storage.set("slot4", JSON.stringify({ counter: 3, name: "x", data: { old: true } }));
  for (const id of [2, 3, 4]) {
    const p = slots.peek(id);
    expect(p.status).toBe("damaged");
    expect(p.reason.length).toBeGreaterThan(0);
    expect(p.hint).toBeTruthy();
  }
  expect(slots.peek(4).reason).toBe("this save is from an older version");
  expect(slots.parse("{ not json").ok).toBe(false);
  expect(slots.nextCounter()).toBe(1); // counters of readable slots only: the damaged slot 4 (counter 3) does not count
});

test("the version: a record carries it, upgrade gets the version it was written with, a newer save is refused", () => {
  clean();
  const seen = [];
  const slots = new Slots({
    version: 2,
    upgrade: (data, from) => {
      seen.push(from);
      let d = data;
      if (from < 1) d = { ...d, gold: d.coins ?? 0 }; // version 0 called it "coins"
      if (from < 2) d = { ...d, items: d.items ?? [] };
      return { ok: true, data: d };
    },
  });
  expect(slots.version).toBe(2);
  const written = slots.write(1, { data: { gold: 7, items: ["key"] } });
  expect(written.version).toBe(2);
  expect(JSON.parse(storage.get("slot1")).version).toBe(2);
  expect(slots.peek(1).record.data).toEqual({ gold: 7, items: ["key"] });
  expect(seen).toEqual([2]); // the peek: the record's own version
  seen.length = 0;
  storage.set("slot2", JSON.stringify({ counter: 1, name: "old record", data: { coins: 4 } })); // before the version field: version 0
  storage.set("slot3", JSON.stringify({ coins: 9 })); // a bare save: version 0
  storage.set("slot4", JSON.stringify({ version: 1, counter: 2, data: { gold: 3 } }));
  expect(slots.peek(2).record).toMatchObject({ version: 2, data: { coins: 4, gold: 4, items: [] } });
  expect(slots.peek(3).record.data).toEqual({ coins: 9, gold: 9, items: [] });
  expect(slots.peek(4).record.data).toEqual({ gold: 3, items: [] });
  expect(seen).toEqual([0, 0, 1]);
  storage.set("slot5", JSON.stringify({ version: 3, counter: 5, data: { gold: 1 } })); // written by a build of the game that is newer than this one
  const newer = slots.peek(5);
  expect(newer.status).toBe("damaged");
  expect(newer.reason).toContain("newer version");
  expect(newer.hint).toContain("Update the game");
  storage.set("slot1", JSON.stringify({ version: "2", counter: 1, data: { gold: 1 } })); // a version that is not a number is damage, not 0
  expect(slots.peek(1).status).toBe("damaged");
  expect(slots.peek(1).reason).toContain("version");
  storage.set("slot1", JSON.stringify({ version: -1, counter: 1, data: { gold: 1 } }));
  expect(slots.peek(1).status).toBe("damaged");
  expect(() => new Slots({ version: -1 })).toThrow("version must be a whole number");
  expect(() => new Slots({ version: 1.5 })).toThrow("version must be a whole number");
  expect(() => new Slots({ encrypt: "yes" })).toThrow("encrypt must be true or false");
});

test("the version: a game without one writes 0 and upgrade still gets (data, 0)", () => {
  clean();
  const froms = [];
  const slots = new Slots({ upgrade: (data, from) => (froms.push(from), { ok: true, data }) });
  slots.write(1, { data: { a: 1 } });
  expect(slots.version).toBe(0);
  expect(JSON.parse(storage.get("slot1")).version).toBe(0);
  froms.length = 0;
  expect(slots.peek(1).status).toBe("used");
  expect(froms).toEqual([0]);
});

// Whether this project has a storage secret (the CLI fixture has one; a new game has none until `factoria call project.create_storage_secret`).
function hasSecret() {
  try {
    storage.set("probe.secret", 1, { encrypt: true });
    storage.remove("probe.secret");
    return true;
  } catch (e) {
    expect(e.message).toContain("project.create_storage_secret");
    return false;
  }
}

test("encrypt (the project has a secret): every slot is written sealed, the counters stay plain, a plain slot written before is still read", async () => {
  clean();
  if (!hasSecret()) return; // the next test covers a project without one
  const real = storage.set;
  const calls = [];
  storage.set = (key, value, options) => (calls.push({ key, options }), real.call(storage, key, value, options));
  try {
    new Slots().write(1, { data: { gold: 1 } });
    expect(calls.find((c) => c.key === "slot1").options).toBe(undefined);
    expect(storage.isEncrypted("slot1")).toBe(false);
    calls.length = 0;
    const sealed = new Slots({ encrypt: true });
    expect(sealed.encrypt).toBe(true);
    sealed.write(2, { data: { gold: 2 }, name: "Sealed" });
    expect(calls.find((c) => c.key === "slot2").options).toEqual({ encrypt: true });
    expect(calls.find((c) => c.key === "saveCounter").options).toBe(undefined);
    expect(storage.isEncrypted("slot2")).toBe(true);
    expect(storage.isEncrypted("saveCounter")).toBe(false);
    expect(sealed.peek(2).record).toMatchObject({ name: "Sealed", data: { gold: 2 } });
    // The plain slot written before encrypt was turned on is still read, and sealed the next time it is written.
    expect(sealed.peek(1).status).toBe("used");
    sealed.write(1, { data: { gold: 11 } });
    expect(storage.isEncrypted("slot1")).toBe(true);
    // A cloud copy that wins is stored sealed too.
    await platform.cloud.save("slot4", JSON.stringify({ counter: 50, name: "cloud", chapter: 1, playTime: 1, pic: null, data: { gold: 4 } }));
    calls.length = 0;
    expect(await sealed.syncCloud()).toBe(true);
    expect(calls.find((c) => c.key === "slot4").options).toEqual({ encrypt: true });
    expect(storage.isEncrypted("slot4")).toBe(true);
    expect(sealed.peek(4).record.name).toBe("cloud");
  } finally {
    storage.set = real;
  }
});

test("encrypt (a project without a secret): the write throws an error that names the command and saves nothing", () => {
  clean();
  if (hasSecret()) return; // the previous test covers a project with one
  const sealed = new Slots({ encrypt: true });
  let failure = null;
  try {
    sealed.write(2, { data: { gold: 2 }, name: "Sealed" });
  } catch (e) {
    failure = e;
  }
  expect(failure).not.toBe(null);
  expect(failure.message).toContain("project.create_storage_secret");
  expect(sealed.peek(2).status).toBe("empty");
});

test("requireEncrypted: a slot that is not sealed is damaged, a sealed one loads, and it needs encrypt", () => {
  clean();
  expect(() => new Slots({ requireEncrypted: true })).toThrow("requireEncrypted needs encrypt: true");
  expect(() => new Slots({ encrypt: true, requireEncrypted: "yes" })).toThrow("requireEncrypted must be true or false");
  if (!hasSecret()) return;
  const strict = new Slots({ encrypt: true, requireEncrypted: true });
  strict.write(1, { data: { gold: 1 } });
  expect(strict.peek(1).status).toBe("used");
  // A player replaced the sealed file by a hand-written plain one: it does not load.
  storage.set("slot2", JSON.stringify({ version: 0, counter: 9, name: "edited", data: { gold: 999999 } }));
  const p = strict.peek(2);
  expect(p.status).toBe("damaged");
  expect(p.reason).toContain("not encrypted");
  expect(p.hint).toBe("Delete the slot.");
  expect(strict.last()).toBe(1);
  // The default still reads it (a game that turns encrypt on later keeps its old saves), and delete clears the damaged row.
  expect(new Slots({ encrypt: true }).peek(2).record.data.gold).toBe(999999);
  strict.remove(2);
  expect(strict.peek(2).status).toBe("empty");
});

test("the cloud: a save is uploaded, a delete removes the copy, the higher counter wins, failures never lose the local save", async () => {
  clean();
  const slots = makeSlots();
  slots.write(2, { data: { level: 1 }, name: "Cloudy" });
  await settle();
  expect(Object.keys(game.platform.state().fake.cloud)).toContain("slot2");
  expect(JSON.parse(await platform.cloud.load("slot2")).name).toBe("Cloudy");
  slots.remove(2);
  await settle();
  expect(Object.keys(game.platform.state().fake.cloud)).not.toContain("slot2");
  expect(await slots.syncCloud()).toBe(false);
  expect(slots.peek(2).status).toBe("empty");

  const rec = (counter, name) => JSON.stringify({ counter, name, chapter: 1, playTime: 10, pic: null, data: { level: 1 } });
  storage.set("slot1", rec(2, "local old"));
  storage.set("slot2", rec(9, "local new"));
  storage.set("slot3", "{ damaged");
  await platform.cloud.save("slot1", rec(4, "cloud new"));
  await platform.cloud.save("slot2", rec(3, "cloud old"));
  await platform.cloud.save("slot3", rec(1, "cloud only"));
  expect(await slots.syncCloud()).toBe(true);
  expect(slots.peek(1).record.name).toBe("cloud new");
  expect(slots.peek(2).record.name).toBe("local new");
  expect(JSON.parse(await platform.cloud.load("slot2")).counter).toBe(9); // the better local one went up
  expect(slots.peek(3).record.name).toBe("cloud only");

  game.platform.respond("cloud.save", { error: "network" });
  expect(slots.write(1, { data: { level: 1 }, name: "Offline" })).toBeTruthy();
  await settle();
  expect(slots.peek(1).record.name).toBe("Offline");
  game.platform.set({ backend: "none" }); // no store: nothing to do
  expect(await slots.syncCloud()).toBe(false);
  expect(slots.write(2, { data: { level: 1 }, name: "No store" })).toBeTruthy();
  game.platform.reset();
});

test("the screen saves: a click on a slot asks for a name; typing one and Save writes it with the picture", () => {
  const { slots, menus } = openScreen("save");
  expect(world.find("slots").active).toBe(true);
  expect(world.find("slots_title").get("Text").text).toBe("Save game");
  expect(world.find("slot_auto").get("Button").interactable).toBe(false); // the autosave is never a target
  expect(label("slot_1")).toBe("Slot 1: empty");
  expect(ui.focused.id).toBe("slot_1");
  game.click(world.find("slot_1"));
  game.step(2);
  expect(menus.top).toBe("slot_dialog");
  const field = world.find("save_name").get("TextField");
  expect(field.text).toBe("Level 3"); // the default name
  field.text = "";
  game.typeText("Pale oil");
  game.step(2);
  game.click(world.find("dialog_confirm"));
  game.step(2);
  const r = slots.peek(1).record;
  expect([r.name, r.chapter, r.playTime, r.pic]).toEqual(["Pale oil", 3, 3725.5, PNG]);
  expect(r.data).toEqual({ level: 3, gold: 40, seconds: 3725.5 });
  expect(menus.top).toBe("slots");
  expect(label("slot_1")).toBe("Slot 1: Pale oil\nChapter 3, 1:02:05");
  expect(world.find("slots_note").get("Text").text).toBe("Saved to slot 1.");
  expect(world.find("pic_1").get("Panel").texture).not.toBe("");
  expect(world.find("pic_2").get("Panel").texture).toBe("");
});

test("an empty name saves under the default one; cancel writes nothing and Escape closes the dialog before the screen", () => {
  const { slots, menus, screen } = openScreen("save");
  game.click(world.find("slot_2"));
  game.step(2);
  world.find("save_name").get("TextField").text = "   ";
  game.click(world.find("dialog_confirm"));
  game.step(2);
  expect(slots.peek(2).record.name).toBe("Level 3");
  game.click(world.find("slot_3"));
  game.step(2);
  expect(screen.dialogOpen).toBe(true);
  expect(screen.cancel()).toBe(true); // what the host's ui.on("cancel") handler asks first
  game.step(1);
  expect(menus.top).toBe("slots");
  expect(slots.peek(3).status).toBe("empty");
  expect(screen.cancel()).toBe(false); // nothing to close: the host goes back itself
});

test("the screen loads: only used slots can be picked, and the slot's data reaches launch()", () => {
  const state = { busy: false, level: 3, loaded: [] };
  clean();
  const first = makeSlots();
  first.write(4, { data: { level: 2, gold: 7, seconds: 9 }, name: "Night 4", chapter: 2, playTime: 9 });
  storage.set("slot5", "{ damaged");
  const menus = new MenuStack(null);
  const screen = new SlotScreen(menus, { slots: makeSlots(), launch: (data) => (state.loaded.push(data), { ok: true }) });
  screen.open("load");
  game.step(2);
  expect(world.find("slots_title").get("Text").text).toBe("Load game");
  expect(ui.focused.id).toBe("slot_4"); // the first used slot
  expect(world.find("slot_1").get("Button").interactable).toBe(false);
  expect(label("slot_5")).toContain("damaged");
  expect(world.find("slots_note").get("Text").text).toContain("cannot be read");
  game.click(world.find("slot_1"));
  game.step(1);
  expect(state.loaded.length).toBe(0);
  game.click(world.find("slot_4"));
  game.step(1);
  expect(state.loaded).toEqual([{ level: 2, gold: 7, seconds: 9 }]);
  screen.dispose();
});

test("a load that fails says why on the screen", () => {
  clean();
  const slots = makeSlots();
  slots.write(1, { data: { level: 1 }, name: "Broken" });
  const screen = new SlotScreen(new MenuStack(null), { slots, launch: () => ({ ok: false, message: "the level is gone", hint: "Start again." }) });
  screen.open("load");
  game.step(2);
  game.click(world.find("slot_1"));
  game.step(1);
  expect(world.find("slots_note").get("Text").text).toBe("the level is gone. Start again.");
});

test("a delete asks first and removes the slot and its cloud copy", async () => {
  const { slots } = openScreen("load", undefined, (slots) => slots.write(3, { data: { level: 1 }, name: "Under the stairs" }));
  await settle();
  expect(Object.keys(game.platform.state().fake.cloud)).toContain("slot3");
  expect(label("slot_3")).toContain("Under the stairs");
  game.click(world.find("delete_3"));
  game.step(2);
  expect(world.find("slot_dialog").active).toBe(true);
  expect(world.find("save_name").active).toBe(false); // a delete asks, it does not name
  game.click(world.find("dialog_confirm"));
  game.step(2);
  await settle();
  expect(slots.peek(3).status).toBe("empty");
  expect(label("slot_3")).toBe("Slot 3: empty");
  expect(Object.keys(game.platform.state().fake.cloud)).not.toContain("slot3");
});

test("a game that cannot be saved right now greys the slots out and says why", () => {
  const { slots, menus } = openScreen("save", { busy: true, level: 1, loaded: [] });
  expect(world.find("slot_1").get("Button").interactable).toBe(false);
  expect(world.find("slots_note").get("Text").text).toBe("You cannot save right now.");
  game.click(world.find("slot_1"));
  game.step(1);
  expect(menus.top).toBe("slots"); // no dialog
  expect(slots.peek(1).status).toBe("empty");
});

/** A screen opened while the cloud holds a better copy of slot 4; counts how often it draws its rows. */
async function openWithCloudCopy() {
  clean();
  const slots = makeSlots();
  await platform.cloud.save("slot4", JSON.stringify({ counter: 5, name: "From the cloud", chapter: 1, playTime: 1, pic: null, data: { level: 1 } }));
  const screen = new SlotScreen(new MenuStack(null), { slots });
  const counter = { draws: 0 };
  const draw = screen.refresh.bind(screen);
  screen.refresh = () => (counter.draws++, draw());
  screen.open("load"); // draws the rows once; the store's answer comes later, not before this test lets a frame or a Promise through
  return { slots, counter };
}

test("the cloud answer redraws the screen while its scene is current", async () => {
  const { counter } = await openWithCloudCopy();
  const before = counter.draws;
  await settle();
  expect(counter.draws).toBeGreaterThan(before);
  expect(label("slot_4")).toContain("From the cloud");
});

test("the cloud answer draws nothing into a scene that replaced the screen's", async () => {
  const { slots, counter } = await openWithCloudCopy();
  const before = counter.draws;
  const generation = scene.generation;
  game.loadJson({ format: "factoria.scene/1", entities: [] });
  game.step(2);
  expect(scene.generation).not.toBe(generation);
  await settle();
  expect(counter.draws).toBe(before);
  expect(slots.peek(4).record.name).toBe("From the cloud"); // the sync still stored the copy
});

test("Hangul: jamo make syllables, a final consonant moves to the next syllable, Delete takes the last jamo away", () => {
  const type = (...keys) => keys.reduce((text, ch) => hangulIme.compose(text, ch), "");
  expect(type("ㅎ", "ㅏ", "ㄴ", "ㄱ", "ㅡ", "ㄹ")).toBe("한글");
  expect(type("ㄱ", "ㅏ", "ㄱ", "ㅏ")).toBe("가가"); // 각 + ㅏ
  expect(type("ㄷ", "ㅏ", "ㄹ", "ㄱ", "ㅏ")).toBe("달가"); // 닭 + ㅏ: the second part of a compound final moves
  expect(type("ㅇ", "ㅗ", "ㅏ")).toBe("와"); // ㅗ + ㅏ = ㅘ
  expect(type("ㄱ", "ㅏ", "ㅃ")).toBe("가ㅃ"); // ㅃ cannot end a syllable
  expect(type("ㄱ", "ㅏ", "1", "ㄴ")).toBe("가1ㄴ"); // a digit ends the composition
  expect(type("ㅏ", "ㅏ")).toBe("ㅏㅏ");
  let text = "읽";
  const steps = [];
  for (let i = 0; i < 4; i++) steps.push((text = hangulIme.decompose(text)));
  expect(steps).toEqual(["일", "이", "ㅇ", ""]);
  expect(hangulIme.decompose("과")).toBe("고");
  expect(hangulIme.decompose("한글 ")).toBe("한글");
  expect(imeFor("ko-KR")).toBe(IME.ko);
  expect(imeFor("en").compose("a", "b")).toBe("ab");
  expect(keysFor("ko")).toContain("ㅎ");
  expect(keysFor("ko")).not.toContain("a");
});

test("the save dialog takes a Korean name from the pad: jamo become syllables, Delete takes one jamo away, Done saves", () => {
  const pad = game.gamepad(0);
  const { slots, menus } = openScreen("save");
  // The keyboard follows i18n.language; this test has no Korean table, so the language is answered by hand.
  const own = Object.getOwnPropertyDescriptor(i18n, "language");
  Object.defineProperty(i18n, "language", { get: () => "ko", configurable: true });
  try {
    pad.tap("A"); // on slot 1: the dialog opens, its name field takes the focus, and the keyboard opens for a pad player
    game.step(2);
    expect(menus.top).toBe("slot_dialog");
    const field = world.find("save_name").get("TextField");
    field.text = "";
    expect(world.find("keyboard").activeInHierarchy).toBe(true);
    const chars = keysFor("ko");
    const typeKey = (ch) => {
      const target = chars.indexOf(ch);
      const at = Number(ui.focused.id.slice("osk_key_".length));
      for (let i = 0; i < Math.abs((target % 10) - (at % 10)); i++) pad.tap(target % 10 > at % 10 ? "DpadRight" : "DpadLeft");
      for (let i = 0; i < Math.abs(Math.floor(target / 10) - Math.floor(at / 10)); i++) pad.tap(Math.floor(target / 10) > Math.floor(at / 10) ? "DpadDown" : "DpadUp");
      expect(ui.focused.get("Button").text).toBe(ch);
      pad.tap("A");
    };
    for (const ch of ["ㅎ", "ㅏ", "ㄴ", "ㄱ", "ㅡ", "ㄹ"]) typeKey(ch);
    expect(field.text).toBe("한글");
    expect(world.find("keyboard_preview").get("Text").text).toBe("한글_");
    for (let i = 0; i < 8 && ui.focused.id.startsWith("osk_key_"); i++) pad.tap("DpadDown");
    while (ui.focused.id !== "osk_delete") pad.tap("DpadRight");
    pad.tap("A"); // 글 -> 그
    expect(field.text).toBe("한그");
    while (ui.focused.id !== "osk_done") pad.tap("DpadRight");
    pad.tap("A");
    game.step(3);
    expect(slots.peek(1).record.name).toBe("한그");
    expect(menus.top).toBe("slots");
  } finally {
    if (own) Object.defineProperty(i18n, "language", own);
    else delete i18n.language;
  }
});
