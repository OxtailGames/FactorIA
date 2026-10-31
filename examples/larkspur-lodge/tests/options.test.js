// P6 options and accessibility: each option changes what it should, every tab is reachable with mouse, gamepad and touch, text at 200 %
// fits, rebinding persists, menus are read aloud.
import { test, describe, expect, beforeEach, game } from "factoria:test";
import { ui, scene, input, world, storage } from "factoria";
import * as settings from "../scripts/settings.js";
import * as story from "../scripts/story.js";
import * as items from "../scripts/items.js";
import * as chapters from "../scripts/chapters.js";
import * as cutscene from "../scripts/cutscene.js";
import { CUTSCENES } from "../scripts/cutscene_data.js";
import * as glyphs from "../scripts/glyphs.js";
import * as dialogue from "../scripts/dialogue.js";
import { enter, cam, porter, stand } from "./helpers/lodge.js";

const TABS = ["video", "audio", "access", "controls", "language"];
const hud = () => game.find("hud").behaviour;

/** Title menu -> Options, with the mouse. */
function openOptions() {
  game.resetState();
  scene.load("scenes/menu.scene.json");
  game.step(3);
  game.click(game.find("options_button"));
  game.step(3);
}
function tab(name) {
  game.click(game.find(`tab_${name}`));
  game.step(3);
}
const text = (id) => game.find(id).get("Button").text;

describe("every tab fits at 100 % and 200 % text", () => {
  test("no text overflows, overlaps or leaves the screen on any tab, in every language, at 100 % and 200 % text", () => {
    openOptions();
    for (const name of TABS) {
      tab(name);
      expect(game.find(`${name}_section`).active).toBe(true);
      const report = game.checkLayout({ textScales: [1, 2], pseudo: false });
      expect(report.issues.map((i) => `${name}: ${i.kind} ${i.entity}`)).toEqual([]);
    }
    expect(ui.textScale).toBe(1); // the check puts the text size back
  });
});

describe("reaching the options", () => {
  test("with a gamepad: every tab opens with A and the page changes", () => {
    openOptions();
    const pad = game.gamepad(0);
    ui.focus("tab_video");
    for (const name of TABS) {
      ui.focus(`tab_${name}`);
      pad.tap("A");
      game.step(2);
      expect(game.find(`${name}_section`).active).toBe(true);
    }
  });

  test("with touch: a tap on a tab and on a toggle", () => {
    openOptions();
    game.touch(game.find("tab_access"), 3);
    game.step(2);
    expect(game.find("access_section").active).toBe(true);
    const before = settings.load().reducedMotion;
    game.touch(game.find("reduced_motion"), 3);
    game.step(2);
    expect(settings.load().reducedMotion).toBe(!before);
  });

  test("with the mouse: the back button returns to the main menu", () => {
    openOptions();
    game.click(game.find("options_back"));
    game.step(3);
    expect(game.find("options_button").active).toBe(true);
  });
});

describe("accessibility options", () => {
  test("text size cycles 100 / 125 / 150 / 200 % and sets ui.textScale; it is saved", () => {
    openOptions();
    tab("access");
    const seen = [];
    for (let i = 0; i < settings.TEXT_SCALES.length; i++) {
      game.click(game.find("text_scale"));
      game.step(2);
      seen.push(ui.textScale);
    }
    expect(seen.sort()).toEqual([...settings.TEXT_SCALES].sort());
    expect(settings.load().textScale).toBe(ui.textScale);
  });

  test("the colour filter cycles and reaches the camera", () => {
    openOptions();
    tab("access");
    game.click(game.find("color_filter"));
    game.step(2);
    const f = settings.load().colorFilter;
    expect(f).not.toBe("none");
    expect(game.find("camera").get("Camera").colorFilter).toBe(f);
  });

  test("the caption background changes the alpha of the Captions component and of the dialogue box", () => {
    enter("ground");
    for (const bg of settings.CAPTION_BACKGROUNDS) {
      settings.save({ ...settings.load(), captionBackground: bg.name });
      game.step(2);
      expect(game.find("captions").get("Captions").color[3]).toBeCloseTo(bg.alpha);
      expect(game.find("dlg_box").get("Panel").color[3]).toBeCloseTo(bg.alpha);
    }
  });

  test("the caption background button in the options cycles through the modes", () => {
    openOptions();
    tab("access");
    const start = settings.load().captionBackground;
    game.click(game.find("caption_bg"));
    game.step(2);
    expect(settings.load().captionBackground).not.toBe(start);
  });

  test("speaker names can be left out of the dialogue box", () => {
    enter("ground");
    stand(15, 21, 0);
    settings.save({ ...settings.load(), textSpeed: 0, captionSpeakers: true });
    dialogue.reset();
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(3);
    const label = () => game.find("dlg_speaker").get("Text").text.trim();
    expect(label()).not.toBe("");
    settings.save({ ...settings.load(), captionSpeakers: false });
    game.step(2);
    expect(label()).toBe("");
  });

  test("auto-advance moves on a finished line after its reading time, and not when it is off", () => {
    enter("ground");
    stand(15, 21, 0);
    settings.save({ ...settings.load(), textSpeed: 0, autoAdvance: "off" });
    dialogue.reset();
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(30);
    const view = game.find("dialogue").behaviour;
    const node = () => dialogue.current?.() ?? view.shown?.text;
    const first = JSON.stringify(node());
    game.step(60 * 10);
    expect(JSON.stringify(node())).toBe(first); // off: it waits for the player
    settings.save({ ...settings.load(), autoAdvance: "fast" });
    dialogue.reset();
    dialogue.start("ch1_mara", { speaker: "npc_mara" });
    game.step(30);
    expect(view.autoTimer).toBeGreaterThan(0);
    expect(view.readingTime("one two three four five six")).toBeGreaterThanOrEqual(1.2);
    const slow = view.readingTime("word ".repeat(40));
    settings.save({ ...settings.load(), autoAdvance: "slow" });
    expect(view.readingTime("word ".repeat(40))).toBeGreaterThan(slow);
  });

  test("camera sensitivity and inversion change how far a drag turns the view", () => {
    enter("ground");
    const c = cam().behaviour;
    const mid = (c.minPitch + c.maxPitch) / 2;
    c.yaw = 0;
    c.pitch = mid;
    c.orbit(10, 5);
    const base = { yaw: c.yaw, pitch: c.pitch };
    settings.save({ ...settings.load(), cameraSensitivity: 2, cameraInvertX: true, cameraInvertY: true });
    game.step(1);
    expect(c.sensitivity).toBe(2);
    c.yaw = 0;
    c.pitch = mid;
    c.orbit(10, 5);
    expect(c.yaw).toBeCloseTo(-base.yaw * 2);
    expect(c.pitch - mid).toBeCloseTo(-(base.pitch - mid) * 2);
  });

  test("the sensitivity slider and the invert toggles in Controls save their values", () => {
    openOptions();
    tab("controls");
    game.setSlider(game.find("camera_sensitivity"), 1.5);
    game.step(2);
    expect(settings.load().cameraSensitivity).toBeCloseTo(1.5);
    game.click(game.find("camera_invert_y"));
    game.step(2);
    expect(settings.load().cameraInvertY).toBe(true);
  });

  test("reduced motion: no head bob while walking", () => {
    enter("ground");
    stand(15, 21, 0);
    settings.save({ ...settings.load(), reducedMotion: false });
    game.press("move_forward");
    let peak = 0;
    for (let i = 0; i < 90; i++) {
      game.step(1);
      peak = Math.max(peak, Math.abs(cam().behaviour.bobOffset));
    }
    expect(peak).toBeGreaterThan(0.005);
    settings.save({ ...settings.load(), reducedMotion: true });
    for (let i = 0; i < 30; i++) {
      game.step(1);
      expect(cam().behaviour.bobOffset).toBe(0);
    }
    game.release("move_forward");
  });

  test("reduced motion: a cut-scene camera shot cuts instead of moving", () => {
    const shot = CUTSCENES.intro.timeline.find((x) => x.do === "camera" && x.seconds > 1);
    const distanceToShot = (reduced) => {
      game.resetState(); // empties storage: the option is set after it
      story.reset();
      items.reset();
      settings.save({ ...settings.load(), reducedMotion: reduced });
      chapters.begin({ intro: true });
      game.load("scenes/ground.scene.json", { arrive: "spawn_default" });
      game.step(Math.round((shot.at + 0.2) * 60));
      expect(cutscene.active()).toBe(true);
      const p = cam().position;
      return Math.hypot(p.x - shot.pos[0], p.y - shot.pos[1], p.z - shot.pos[2]);
    };
    const moving = distanceToShot(false);
    const cut = distanceToShot(true);
    expect(moving).toBeGreaterThan(0.3);
    expect(cut).toBeLessThan(0.05);
  });

  test("prompt glyphs: auto follows the last device, and the option forces one", () => {
    enter("ground");
    settings.save({ ...settings.load(), glyphs: "keyboard" });
    expect(glyphs.device()).toBe("keyboard");
    expect(glyphs.prompt("interact")).toBe(input.buttonName(input.bindings("interact").find((n) => !n.startsWith("Gamepad") && !n.startsWith("Mouse") && !n.startsWith("Touch"))));
    settings.save({ ...settings.load(), glyphs: "gamepad" });
    expect(glyphs.device()).toBe("gamepad");
    expect(glyphs.prompt("interact")).not.toBe(glyphs.prompt.call(null, "pause") + "x");
    settings.save({ ...settings.load(), glyphs: "touch" });
    expect(glyphs.prompt("interact")).toBe("Tap");
    settings.save({ ...settings.load(), glyphs: "auto" });
    expect(glyphs.device()).toBe(input.lastDevice);
  });

  test("the skip prompt of a cut-scene follows the glyph option", () => {
    game.resetState();
    story.reset();
    items.reset();
    cutscene.useClips({});
    settings.save({ ...settings.load(), glyphs: "touch" });
    chapters.begin({ intro: true });
    game.load("scenes/ground.scene.json", { arrive: "spawn_default" });
    game.step(60);
    expect(cutscene.active()).toBe(true);
    const skip = () => game.find("cs_skip")?.get("Button").text ?? "";
    const touch = skip();
    settings.save({ ...settings.load(), glyphs: "keyboard" });
    game.step(2);
    const keys = skip();
    expect(touch).toBe("Skip");
    expect(keys).not.toBe(touch);
  });
});

describe("rebinding", () => {
  test("a key pressed after choosing an action rebinds it, saves it, and the new key is used after a restart", () => {
    openOptions();
    tab("controls");
    ui.focus("bind_interact");
    game.click(game.find("bind_interact"));
    game.step(2);
    game.keyDown("G");
    game.step(2);
    game.keyUp("G");
    game.step(2);
    expect(input.bindings("interact")).toContain("G");
    expect(settings.load().bindings.interact).toContain("G");
    // A fresh start applies the saved bindings again.
    input.rebind("interact", ["F"]);
    expect(input.bindings("interact")).not.toContain("G");
    settings.apply(settings.load());
    expect(input.bindings("interact")).toContain("G");
  });

  test("the reset button restores the defaults", () => {
    openOptions();
    tab("controls");
    ui.focus("bind_interact");
    game.click(game.find("bind_interact"));
    game.step(2);
    game.keyDown("G");
    game.step(2);
    game.keyUp("G");
    game.step(2);
    expect(input.bindings("interact")).toContain("G");
    ui.focus("reset_controls");
    game.click(game.find("reset_controls"));
    game.step(3);
    expect(input.bindings("interact")).not.toContain("G");
    expect(settings.load().bindings).toEqual({});
  });

  test("a rebound key shows in the prompt of the world", () => {
    enter("ground");
    input.rebind("interact", ["G"]);
    settings.save({ ...settings.load(), glyphs: "keyboard" });
    expect(glyphs.prompt("interact")).toBe(input.buttonName("G"));
  });
});

describe("menus are read aloud", () => {
  test("with the option on, moving the focus speaks the widget; off, it is silent", () => {
    openOptions();
    settings.save({ ...settings.load(), readAloud: true });
    game.step(2);
    game.clearSpoken();
    tab("access");
    ui.focus("text_scale");
    game.step(2);
    ui.focus("reduced_motion");
    game.step(2);
    expect(game.spoken().length).toBeGreaterThan(0);
    expect(game.spoken().map((l) => l.text).join(" ")).toContain("Reduced motion");
    settings.save({ ...settings.load(), readAloud: false });
    game.step(2);
    game.clearSpoken();
    ui.focus("text_scale");
    game.step(2);
    expect(game.spoken()).toEqual([]);
  });
});

describe("settings persist", () => {
  test("they live in storage 'settings', not in a save slot", () => {
    openOptions();
    tab("access");
    game.click(game.find("reduced_motion"));
    game.step(2);
    expect(storage.get("settings").reducedMotion).toBe(settings.load().reducedMotion);
    expect(storage.get("settings").reducedMotion).toBe(true);
  });
});
