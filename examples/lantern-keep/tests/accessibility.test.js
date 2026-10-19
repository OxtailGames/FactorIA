import { test, expect, game } from "factoria:test";
import { ui, scene, storage, i18n, time, session, fa } from "factoria";
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
  expect(time.scale).toBe(0);
  const t1 = level().time;
  game.step(20);
  expect(level().time).toBe(t1);
  pad().tap("A"); // Resume
  game.step(3);
  expect(game.find("pause_panel").active).toBe(false);
  expect(time.scale).toBeCloseTo(0.6, 5);
  // a speed changed in the options while paused is taken on resume
  pad().tap("Start");
  storage.set("settings", { assist: { speed: 0.8 } });
  pad().tap("A");
  game.step(3);
  expect(time.scale).toBeCloseTo(0.8, 5);
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
  expect(invincible.assisted).toBe(true);
  expect(invincible.deaths).toBe(0);
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

// ------------------------------------------------------------------------------------------------ text at 200%

/** Every visible widget is inside the screen and its label inside the widget (measured like the engine lays text out). */
function expectWidgetsFit(where) {
  const problems = [];
  for (const w of fa.call("ui.state").widgets) {
    if (!w.visible) continue;
    const [x, y, width, height] = w.rect;
    if (x < 0 || y < 0 || x + width > 1280 || y + height > 720) problems.push(`${where}: "${w.id}" is outside the screen: ${w.rect.map(Math.round)}`);
    const entity = game.find(w.id);
    const kind = ["Button", "Toggle"].find((k) => entity && entity.has(k));
    if (kind && w.text) {
      const fontSize = entity.get(kind).fontSize;
      const m = ui.measureText(w.text, { fontSize });
      const room = width - (kind === "Toggle" ? fontSize * ui.textScale * 1.2 : 0);
      if (m.width > room || m.height > height) problems.push(`${where}: the label of "${w.id}" (${Math.round(m.width)} x ${Math.round(m.height)}) does not fit its ${Math.round(width)} x ${Math.round(height)} rectangle`);
    }
  }
  expect(problems).toEqual([]);
}

for (const language of ["en", "es"]) {
  test(`at 200% every menu fits the screen (${language})`, () => {
    startWith({ textScale: 2, language }, "scenes/menu.scene.json");
    game.step(2);
    expect(ui.textScale).toBe(2);
    expectWidgetsFit("main menu");
    pad().tap("DpadDown");
    pad().tap("A"); // Options
    game.step(2);
    for (const tab of ["video", "audio", "controls", "language", "access"]) {
      ui.focus(game.find(`tab_${tab}`)); // (DpadRight from Controls can reach the wide rebinding buttons first)
      pad().tap("A");
      game.step(2);
      expect([tab, game.find(`${tab}_section`).active]).toEqual([tab, true]);
      expectWidgetsFit(`options ${tab}`);
    }
    pad().tap("B");
    game.step(2);
    expect(ui.focused.id).toBe("options_button");
    pad().tap("DpadDown"); // Options -> Credits
    pad().tap("A");
    game.step(3);
    expect(game.find("credits").active).toBe(true);
    expectWidgetsFit("credits");
    const list = fa.call("ui.state").widgets.find((w) => w.id === "credits_list");
    expect(list.rect[0] + list.rect[2]).toBeLessThanOrEqual(1280);
  });

  test(`at 200% the HUD, the pause menu and the level end panel of every level fit (${language})`, () => {
    for (const info of LEVELS) {
      startWith({ textScale: 2, language }, info.scene);
      game.step(3);
      // HUD: the name and the embers share the first row; the timer is on it too (centred) only when they do not touch
      const text = (id) => game.find(id).get("Text");
      const width = (id, s = text(id).text) => ui.measureText(s, { fontSize: text(id).fontSize }).width;
      const half = width("hud_timer", i18n.t("hud.time", { time: "0:00.00" })) / 2;
      expect(24 + width("hud_level") + 24 + 24 + width("hud_embers") + 24).toBeLessThanOrEqual(1280);
      expect(half * 2).toBeLessThanOrEqual(1280 - 48);
      const sideBySide = 48 + width("hud_level") <= 640 - half && 48 + width("hud_embers") <= 640 - half;
      const rows = game.find("hud_timer").position.y > 20 ? 2 : 1; // y is 10 on the first row
      expect(rows).toBe(sideBySide ? 1 : 2);
      pad().tap("Start");
      expectWidgetsFit(`pause ${info.id}`);
      pad().tap("Start");
      game.step(3);
      teleportOnto(game.find("player"), game.world.findByTag("exit")[0], 3); // the level end panel
      expect(game.find("level_end").active).toBe(true);
      expectWidgetsFit(`level end ${info.id}`);
    }
  });
}
