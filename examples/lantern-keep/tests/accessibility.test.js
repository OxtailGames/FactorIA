import { test, expect, game } from "factoria:test";
import { ui, scene, storage, i18n, time, session, platform } from "factoria";
import { screenProblems } from "./helpers/screens.js";
import * as progress from "../scripts/progress.js";
import { LEVELS } from "../scripts/levels.js";
import { listen, playLevel, teleportOnto } from "./helpers/autoplay.js";

// The Accessibility tab of the options (text size, assist mode, shake, reduced effects) and what each option does.
const pad = () => game.gamepad(0);
const saved = () => storage.get("settings", {});

/** A new run of the game with nothing saved: the settings are applied again at the next menu or level. */
function fresh() {
  progress.reset();
  storage.remove("settings");
  session.settingsApplied = false;
  i18n.setLanguage("en");
  ui.textScale = 1;
  time.scale = 1;
}

/** Starts a run with these saved settings (as if the player had set them in an earlier run) and loads `path`. */
function startWith(settings, path) {
  fresh();
  storage.set("settings", settings);
  game.load(path);
  game.step(3);
}
const level = () => game.find("level").behaviour;

/** Opens Options from the main menu with the pad and goes to the Accessibility tab. */
function openAccessTab() {
  pad().tap("DpadDown"); // Options
  pad().tap("A");
  for (let i = 0; i < 4; i++) pad().tap("DpadRight"); // Video, Audio, Controls, Language, Access
  pad().tap("A");
  expect(game.find("access_section").active).toBe(true);
}

test("the Accessibility tab saves every option, with the pad only", () => {
  startWith({}, "scenes/menu.scene.json");
  openAccessTab();
  pad().tap("DpadDown"); // Text size
  pad().tap("A");
  expect(ui.textScale).toBe(1.25);
  expect(saved().textScale).toBe(1.25);
  expect(game.find("text_size").get("Button").text).toBe("Text size: 125%");
  pad().tap("DpadDown"); // Game speed
  pad().tap("A");
  expect(saved().assist.speed).toBe(0.9);
  expect(game.find("game_speed").get("Button").text).toBe("Game speed: 90%");
  pad().tap("DpadDown"); // Invincible
  pad().tap("A");
  expect(saved().assist.invincible).toBe(true);
  pad().tap("DpadDown"); // Screen shake
  pad().tap("A");
  expect(saved().shake).toBe(false);
  pad().tap("DpadDown"); // Reduced effects
  pad().tap("A");
  expect(saved().reducedEffects).toBe(true);
});

test("the text size and the game speed step through their lists and come back to 100%", () => {
  startWith({}, "scenes/menu.scene.json");
  openAccessTab();
  pad().tap("DpadDown");
  for (let i = 0; i < 5; i++) pad().tap("A");
  expect(ui.textScale).toBe(1);
  pad().tap("DpadDown");
  for (let i = 0; i < 4; i++) pad().tap("A");
  expect(saved().assist.speed).toBe(0.6);
  pad().tap("A");
  expect(saved().assist.speed).toBe(1);
});

test("saved options are applied when the game starts again and the tab shows them", () => {
  startWith({ textScale: 1.5, assist: { speed: 0.7, invincible: true }, shake: false, reducedEffects: true }, "scenes/menu.scene.json");
  expect(ui.textScale).toBe(1.5);
  openAccessTab();
  expect(game.find("text_size").get("Button").text).toBe("Text size: 150%");
  expect(game.find("game_speed").get("Button").text).toBe("Game speed: 70%");
  expect(game.find("invincible").get("Toggle").value).toBe(true);
  expect(game.find("screen_shake").get("Toggle").value).toBe(false);
  expect(game.find("reduced_effects").get("Toggle").value).toBe(true);
  // a level starts at the saved speed
  game.load("scenes/levels/1-1.scene.json");
  game.step(3);
  expect(time.scale).toBeCloseTo(0.7, 5);
});

test("the assist speed slows the game, survives a pause and a resume, and the pause itself still freezes it", () => {
  startWith({ assist: { speed: 0.6 } }, "scenes/levels/1-1.scene.json");
  expect(time.scale).toBeCloseTo(0.6, 5);
  const t0 = level().time;
  game.step(60);
  expect(level().time - t0).toBeCloseTo(0.6, 1); // one second of frames is 60% of a second of game time
  pad().tap("Start");
  expect(game.paused).toBe(true);
  expect(time.scale).toBe(0);
  const t1 = level().time;
  game.step(20);
  expect(level().time).toBe(t1);
  pad().tap("A"); // Resume
  game.step(3);
  expect(game.find("pause_panel").active).toBe(false);
  expect(game.paused).toBe(false);
  expect(time.scale).toBeCloseTo(0.6, 5); // resuming gives back the speed the pause took
  // a speed changed in the pause menu's options stays frozen until Resume and is the speed after it
  pad().tap("Start");
  pad().tap("DpadDown"); // Options
  pad().tap("A");
  for (let i = 0; i < 4; i++) pad().tap("DpadRight"); // the tabs: Access
  pad().tap("A");
  pad().tap("DpadDown"); // Text size
  pad().tap("DpadDown"); // Game speed
  pad().tap("A"); // 100%
  pad().tap("A"); // 90%
  expect(saved().assist.speed).toBe(0.9);
  expect(game.paused).toBe(true);
  expect(time.scale).toBe(0);
  const t2 = level().time;
  game.step(20);
  expect(level().time).toBe(t2);
  pad().tap("B"); // back to the pause panel
  pad().tap("DpadUp"); // Resume
  pad().tap("A");
  game.step(3);
  expect(game.paused).toBe(false);
  expect(time.scale).toBeCloseTo(0.9, 5);
  // leaving the level puts the normal speed back
  pad().tap("Start");
  pad().tap("DpadDown");
  pad().tap("DpadDown");
  pad().tap("A"); // Main menu
  game.step(3);
  expect(scene.current).toBe("scenes/menu.scene.json");
  expect(time.scale).toBe(1);
});

test("invincible: spikes and enemies do nothing and a fall puts the player back without counting a death", () => {
  startWith({ assist: { invincible: true } }, "scenes/levels/1-2.scene.json");
  const player = game.find("player");
  const seen = listen("player_died");
  game.step(30);
  const checkpoints = game.world.findByTag("checkpoint").sort((a, b) => a.position.x - b.position.x);
  teleportOnto(player, checkpoints[0]); // a checkpoint to come back to
  game.step(30);
  teleportOnto(player, game.world.findByTag("hazard")[0], 2);
  expect(level().deaths).toBe(0);
  teleportOnto(player, game.world.findByTag("enemy")[0], 2);
  expect(level().deaths).toBe(0);
  player.position = [player.position.x, -2000, 0]; // falls out of the level
  game.step(10);
  expect(level().deaths).toBe(0);
  expect(seen.player_died).toEqual([]);
  expect(Math.abs(player.position.x - checkpoints[0].position.x)).toBeLessThan(10); // back at the checkpoint
  expect(player.position.y).toBeGreaterThan(0);
});

test("without assist, spikes still kill (the option is what saves the player)", () => {
  startWith({}, "scenes/levels/1-1.scene.json");
  game.step(30);
  teleportOnto(game.find("player"), game.world.findByTag("hazard")[0], 2);
  expect(level().deaths).toBe(1);
});

test("level_completed says assisted: true only when an assist option is on", () => {
  const run = (settings) => {
    startWith(settings, "scenes/levels/1-1.scene.json");
    return playLevel("1-1", { events: ["level_completed"] }).events.level_completed[0];
  };
  expect(run({}).assisted).toBe(false);
  expect(run({ assist: { speed: 0.8 } }).assisted).toBe(true);
  const invincible = run({ assist: { invincible: true } });
  expect(invincible).toMatchObject({ assisted: true, deaths: 0 });
  // assist turned on in the middle of a level counts, and turning it off again does not undo it
  startWith({}, "scenes/levels/1-1.scene.json");
  const seen = listen("level_completed");
  game.step(10);
  pad().tap("Start");
  storage.set("settings", { assist: { speed: 0.9 } });
  pad().tap("A");
  game.step(3);
  storage.set("settings", {});
  level().refreshAssist();
  expect(level().assisted).toBe(true);
  teleportOnto(game.find("player"), game.world.findByTag("exit")[0], 2);
  expect(seen.level_completed[0].assisted).toBe(true);
  expect(progress.of("1-1").completed).toBe(true);
});

test("screen shake off: a death does not shake the camera; on, it does", () => {
  for (const shake of [true, false]) {
    startWith({ shake }, "scenes/levels/1-1.scene.json");
    game.step(30);
    teleportOnto(game.find("player"), game.world.findByTag("hazard")[0], 1);
    expect(level().deaths).toBe(1);
    game.step(3);
    const [sx, sy] = game.find("camera").behaviour.shakeOffset();
    if (shake) expect(Math.abs(sx) + Math.abs(sy)).toBeGreaterThan(0.5);
    else expect([sx, sy]).toEqual([0, 0]);
  }
});

test("reduced effects: collecting an ember makes no sparks; otherwise it does", () => {
  const sparks = () => game.world.entities().filter((e) => e.has("ParticleEmitter")).length;
  for (const reduced of [false, true]) {
    startWith({ reducedEffects: reduced }, "scenes/levels/1-1.scene.json");
    game.step(30);
    teleportOnto(game.find("player"), game.world.findByTag("ember")[0], 2);
    expect(level().found).toBe(1); // the ember still counts
    expect(sparks()).toBe(reduced ? 0 : 1);
  }
});

// ------------------------------------------------------------------------------------------------ every screen, every language

// Every screen of the game in every language at 100% and at the biggest text size: widgets inside the screen, labels inside their
// widget, no text wider than its box, every layout panel big enough for its content (tests/helpers/screens.js).
const LANGUAGES = ["en", "es", "de", "ar"];
const SIZES = [1, 2];

/** Collects the problems of every screen of a test, so one run lists all of them instead of stopping at the first screen. */
const collector = () => {
  const all = [];
  return { check: (where) => all.push(...screenProblems(where)), done: () => (all.length && console.log(all.join(" | ")), expect(all.length).toBe(0)) };
};
const used = (counter, levels) => JSON.stringify({ version: 2, counter, levels });
const done = (bestTime, embers) => ({ completed: true, bestTime, embers });

/** Lets what a click started finish: the fake store answers at once, the script continues in the next microtasks. */
async function settle() {
  for (let i = 0; i < 4; i++) {
    game.step(1);
    await Promise.resolve();
  }
}

/** Moves the focus to a widget and presses A, like a player with the pad. */
async function press(id) {
  ui.focus(game.find(id));
  pad().tap("A");
  await settle();
}

/** Presses A on the focused widget and lets what the click started finish. */
async function pressFocused() {
  pad().tap("A");
  await settle();
}

/** A game with a used slot (so Continue, the results and Delete show), a damaged one and an empty one, in this language and size. */
function startMenu(language, textScale) {
  fresh();
  for (const n of [1, 2, 3]) storage.remove(`slot${n}`);
  storage.set("slot1", used(9, { "1-1": done(754.32, [true, true, true]), "1-2": done(61.5, [true, false, true]), "1-3": done(70, [false, false, false]) }));
  storage.set("slot2", used(5, { "2-3": done(5999.99, [true, true, true]), "1-1": done(30, [true, true, true]) }));
  storage.set("slot3", "{ not json");
  storage.set("lastSlot", 1);
  game.platform.reset();
  storage.remove("wallet");
  storage.set("settings", { textScale, language });
  game.load("scenes/menu.scene.json");
  game.step(3);
  expect([i18n.language, ui.textScale]).toEqual([language, textScale]);
}

for (const language of LANGUAGES) {
  for (const size of SIZES) {
    test(`every menu screen fits the screen (${language}, ${size * 100}%)`, async () => {
      const at = (screen) => `${screen} ${language} ${size * 100}%`;
      const screens = collector();
      const expectFits = screens.check;
      startMenu(language, size);
      expectFits(at("main menu"));
      // options: every tab, then credits
      await press("options_button");
      // the tabs are a row, and the pad walks along it with Right (Left in Arabic, where the row is mirrored) even where wide widgets sit right below it (big text)
      for (const [i, tab] of ["video", "audio", "controls", "language", "access"].entries()) {
        if (i > 0) pad().tap(i18n.direction === "rtl" ? "DpadLeft" : "DpadRight"); // the row runs right to left in Arabic
        expect([tab, ui.focused.id]).toEqual([tab, `tab_${tab}`]);
        await pressFocused();
        expect([tab, game.find(`${tab}_section`).active]).toEqual([tab, true]);
        expectFits(at(`options ${tab}`));
      }
      pad().tap("B");
      game.step(2);
      await press("credits_button");
      expectFits(at("credits"));
      pad().tap("B");
      game.step(2);
      // save slots, the delete confirmation, the level select
      await press("play");
      expect(game.find("slots").active).toBe(true);
      expectFits(at("slots"));
      await press("delete_1");
      expect(game.find("delete_confirm").active).toBe(true);
      expectFits(at("delete confirmation"));
      pad().tap("B");
      game.step(2);
      await press("slot_1");
      expect(game.find("level_select").active).toBe(true);
      expectFits(at("level select"));
      pad().tap("B");
      pad().tap("B");
      game.step(2);
      expect(game.find("main_menu").active).toBe(true);
      // the store screens, with the store working and then without a signed-in player (the longest sentences)
      await platform.achievements.unlock("first_light");
      await platform.achievements.progress("jumper", 0.4);
      await platform.leaderboards.submit("time_1-1", 754320);
      for (const [button, panel] of [["achievements_button", "achievements"], ["leaderboards_button", "leaderboards"], ["shop_button", "shop"]]) {
        for (const signedIn of [true, false]) {
          game.platform.set({ signedIn });
          await press(button);
          expect(game.find(panel).active).toBe(true);
          expectFits(at(`${panel} ${signedIn ? "" : "signed out"}`));
          pad().tap("B");
          game.step(2);
        }
      }
      game.platform.set({ signedIn: true });
      screens.done();
    });
  }

  for (const size of SIZES) {
    test(`the HUD, the pause menu and the level end panel fit (${language}, ${size * 100}%)`, () => {
      const screens = collector();
      const expectFits = screens.check;
      for (const info of LEVELS) {
        startWith({ textScale: size, language }, info.scene);
        game.step(3);
        // HUD: the name and the embers share the first row; the timer is on it too (centred) only when they do not touch
        const text = (id) => game.find(id).get("Text");
        const width = (id, s) => (s === undefined ? ui.rectOf(id).w : ui.measureText(s, { fontSize: text(id).fontSize }).width);
        const half = width("hud_timer", i18n.t("hud.time", { time: "0:00.00" })) / 2;
        expect(24 + width("hud_level") + 24 + 24 + width("hud_embers") + 24).toBeLessThanOrEqual(1280);
        expect(half * 2).toBeLessThanOrEqual(1280 - 48);
        const sideBySide = 48 + width("hud_level") <= 640 - half && 48 + width("hud_embers") <= 640 - half;
        const rows = game.find("hud_timer").position.y > 20 ? 2 : 1; // y is 10 on the first row
        expect(rows).toBe(sideBySide ? 1 : 2);
        if (info.id !== "1-1" && info.id !== "2-3") continue; // the pause menu and the end panel do not depend on the level
        pad().tap("Start");
        expectFits(`pause ${info.id} ${language} ${size * 100}%`);
        pad().tap("Start");
        game.step(3);
        teleportOnto(game.find("player"), game.world.findByTag("exit")[0], 3); // the level end panel
        expect(game.find("level_end").active).toBe(true);
        expectFits(`level end ${info.id} ${language} ${size * 100}%`);
      }
      screens.done();
    });
  }
}
