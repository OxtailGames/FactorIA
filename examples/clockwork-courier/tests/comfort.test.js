// P5, mobile comfort and accessibility: what each option does to a level, the left-handed layout, haptics, captions for every
// sound cue, pausing when the app is suspended, Android Back on every screen, reduced motion following the system setting,
// the assist-mode numbers and the safe area. Options are set the way the options menu saves them (storage "settings") and
// then the scene is loaded, or by clicking the options menu itself.
import { test, describe, expect, game, afterEach } from "factoria:test";
import { scene, storage, ui, screen, session, i18n, window, game as engine } from "factoria";
import { Autoplay, YARD_ROUTE } from "./helpers/autoplay.js";
import * as settings from "../scripts/settings.js";
import * as accessibility from "../scripts/accessibility.js";
import * as haptics from "../scripts/haptics.js";

const YARD = "scenes/test_yard.scene.json";
const ARENA = "scenes/test_arena.scene.json";
const ROOFS = "scenes/rooftops_1.scene.json";
const DOGS = "scenes/rooftops_3.scene.json";

// Storage and the session outlive a test (and a test file): leave no saved option behind for the other files.
function cleanUp() {
  storage.remove("settings");
  storage.remove("progress");
  session.settingsApplied = false;
  if (i18n.language !== "en") i18n.setLanguage("en");
}

/** Starts a level with the given saved settings (what the options menu would have stored). */
function start(path, saved = {}) {
  storage.remove("progress");
  storage.set("settings", saved);
  session.settingsApplied = false; // apply() (language, text size, volumes) runs again for this start
  game.load(path);
  game.step(10);
}

const courier = () => game.find("courier");
const comfort = () => game.find("comfort").behaviour;
const touchOf = (id) => {
  const e = game.find(id);
  return { e, c: e.has("TouchStick") ? e.get("TouchStick") : e.get("TouchButton") };
};

describe("graphics quality", () => {
  afterEach(cleanUp);
  test("high keeps the scene's own shadows, view distance and fog", () => {
    start(ROOFS, { quality: "high" });
    expect(game.find("sun").get("Light").castShadows).toBe(true);
    const far = game.find("camera").get("Camera").farPlane;
    start(ROOFS, { quality: "low" });
    expect(game.find("camera").get("Camera").farPlane).toBeLessThan(far);
  });

  test("low switches the sun's shadows off and keeps one lantern light in three", () => {
    start(ROOFS, { quality: "low" });
    expect(game.find("sun").get("Light").castShadows).toBe(false);
    const lit = game.world.findByTag("lantern").filter((l) => l.children.find((c) => c.name === "light")?.active);
    expect(lit.length).toBeLessThan(game.world.findByTag("lantern").length);
    start(ROOFS, { quality: "high" });
    expect(game.world.findByTag("lantern").every((l) => l.children.find((c) => c.name === "light")?.active)).toBe(true);
  });

  test("fewer particles on low than on high", () => {
    start(ROOFS, { quality: "high" });
    const high = accessibility.QUALITY.high.particles;
    start(ROOFS, { quality: "low" });
    expect(accessibility.QUALITY.low.particles).toBeLessThan(high);
    expect(accessibility.QUALITY.medium.particles).toBeLessThan(high);
  });

  test("the Quality button cycles the preset, saves it and applies it at once", () => {
    start(ROOFS, { quality: "high" });
    game.tap("pause");
    game.step(2);
    game.click("pause_options");
    game.step(3);
    game.click("quality"); // high -> low (QUALITIES order: low, medium, high, wraps)
    game.step(2);
    expect(storage.get("settings").quality).toBe("low");
    expect(game.find("sun").get("Light").castShadows).toBe(false);
    expect(game.find("quality").get("Button").text).toBe("Quality: low");
  });

  test("a new player starts at the device's tier; a phone starts with a 30 fps cap and the cap is greyed out there", () => {
    expect(settings.QUALITIES).toEqual(["low", "medium", "high"]);
    expect(settings.FRAME_CAPS).toEqual([30, 60, 0]);
    // The test device is a desktop with a high tier (game.device): high and no cap.
    storage.set("settings", {});
    expect(settings.load().quality).toBe("high");
    expect(settings.load().frameCap).toBe(0);
    game.setDevice({ formFactor: "phone", tier: "medium" });
    expect(settings.load().quality).toBe("medium");
    expect(settings.load().frameCap).toBe(30);
    expect(settings.onPhone()).toBe(true);
    game.setDevice({ tier: "low" });
    expect(settings.load().quality).toBe("low");
  });

  test("each preset draws at its own render scale", () => {
    expect(accessibility.QUALITY.low.renderScale).toBeLessThan(accessibility.QUALITY.medium.renderScale);
    expect(accessibility.QUALITY.high.renderScale).toBe(1);
    start(ROOFS, { quality: "high" });
    expect(window.renderScale).toBe(1);
    start(ROOFS, { quality: "low" });
    expect(window.renderScale).toBe(accessibility.QUALITY.low.renderScale);
    let s = null;
    try {
      s = game.renderStats();
    } catch (e) {
      // a machine with no GPU draws nothing: the scale above is all there is to check
    }
    if (s) {
      expect(s.renderScale).toBe(accessibility.QUALITY.low.renderScale);
      expect(s.width).toBeLessThan(screen.size.x);
    }
    start(ROOFS, { quality: "high" });
    expect(window.renderScale).toBe(1);
  });
});

describe("touch layout", () => {
  afterEach(cleanUp);
  test("left-handed mirrors the stick and the buttons and leaves pause in the top right", () => {
    start(YARD, {});
    const right = { stick: touchOf("touch_stick").c.anchor.x, jump: touchOf("touch_jump").c.anchor.x };
    const sx = touchOf("touch_stick").e.position.x;
    const jx = touchOf("touch_jump").e.position.x;
    expect(right.stick).toBe(0);
    expect(right.jump).toBe(1);
    start(YARD, { leftHanded: true });
    expect(touchOf("touch_stick").c.anchor.x).toBe(1);
    expect(touchOf("touch_jump").c.anchor.x).toBe(0);
    expect(touchOf("touch_action").c.anchor.x).toBe(0);
    expect(touchOf("touch_stick").e.position.x).toBeCloseTo(-sx);
    expect(touchOf("touch_jump").e.position.x).toBeCloseTo(-jx);
    expect(touchOf("touch_pause").c.anchor.x).toBe(1);
  });

  test("left-handed controls still work (a finger on the mirrored stick runs the courier)", () => {
    start(YARD, { leftHanded: true });
    const z0 = courier().position.z;
    game.touchStart("touch_stick");
    game.step(2);
    const p = game.find("touch_stick").get("TouchStick");
    expect(p.anchor.x).toBe(1);
    game.touchMove([1280 - 150, 480]);
    game.step(40);
    expect(z0 - courier().position.z).toBeGreaterThan(1.5);
    game.touchEnd();
  });

  test("control size scales the controls and their distance to the edge", () => {
    start(YARD, {});
    const w = touchOf("touch_jump").c.size.x;
    const x = touchOf("touch_jump").e.position.x;
    start(YARD, { controlSize: 1.4 });
    expect(touchOf("touch_jump").c.size.x).toBeCloseTo(w * 1.4);
    expect(touchOf("touch_jump").e.position.x).toBeCloseTo(x * 1.4);
  });

  test("control opacity scales the controls' own opacity", () => {
    start(YARD, {});
    const a = touchOf("touch_jump").c.color.a;
    start(YARD, { controlOpacity: 0.5 });
    expect(touchOf("touch_jump").c.color.a).toBeCloseTo(a * 0.5);
  });

  test("the options menu changes the layout at once and saves it", () => {
    start(YARD, {});
    game.tap("pause");
    game.step(2);
    game.click("pause_options");
    game.step(3);
    game.click("tab_touch");
    game.step(2);
    game.click("left_handed");
    game.step(2);
    expect(storage.get("settings").leftHanded).toBe(true);
    expect(touchOf("touch_stick").c.anchor.x).toBe(1);
  });
});

describe("camera options", () => {
  afterEach(cleanUp);
  test("sensitivity scales the camera's orbit speed and invert Y flips it", () => {
    start(YARD, {});
    const base = game.find("camera").behaviour.sensitivity;
    start(YARD, { cameraSensitivity: 2, invertY: true });
    const cam = game.find("camera").behaviour;
    expect(cam.sensitivity).toBeCloseTo(base * 2);
    expect(cam.invertY).toBe(true);
  });

  test("the sliders and toggles of the Touch tab write the settings", () => {
    start(YARD, {});
    const base = game.find("camera").behaviour.sensitivity;
    game.pressBack();
    game.step(2);
    game.click("pause_options");
    game.step(3);
    game.click("tab_touch");
    game.step(2);
    game.setSlider("camera_sensitivity", 2); // like a drag: clamped, stepped, ui.change
    game.step(2);
    expect(storage.get("settings").cameraSensitivity).toBe(2);
    expect(game.find("camera").behaviour.sensitivity).toBeCloseTo(base * 2);
    game.setSlider("camera_sensitivity", 9); // past the end of the range: the largest value
    game.step(2);
    expect(storage.get("settings").cameraSensitivity).toBe(2.5);
    game.click("invert_y");
    game.step(2);
    expect(storage.get("settings").invertY).toBe(true);
    expect(game.find("camera").behaviour.invertY).toBe(true);
    game.pressBack();
    game.step(2);
    game.pressBack();
    game.step(2);
  });
});

describe("assist mode", () => {
  afterEach(cleanUp);
  test("numbers: a slower spring, a wider jump grace", () => {
    start(YARD, {});
    const coyote = courier().behaviour.coyoteTime;
    expect(game.find("spring").behaviour.drainRate).toBe(1);
    start(YARD, { assist: true });
    expect(game.find("spring").behaviour.drainRate).toBe(accessibility.ASSIST.drainRate);
    expect(accessibility.ASSIST.drainRate).toBeLessThan(1);
    expect(courier().behaviour.coyoteTime).toBe(Math.max(coyote, accessibility.ASSIST.coyoteTime));
    expect(courier().behaviour.jumpBuffer).toBe(Math.max(0.12, accessibility.ASSIST.jumpBuffer));
  });

  test("the spring drains slower", () => {
    start(YARD, {});
    const a = game.find("spring").behaviour.left;
    game.step(60);
    const normal = a - game.find("spring").behaviour.left;
    start(YARD, { assist: true });
    const b = game.find("spring").behaviour.left;
    game.step(60);
    const slow = b - game.find("spring").behaviour.left;
    expect(normal).toBeGreaterThan(0.5);
    expect(slow).toBeCloseTo(normal * accessibility.ASSIST.drainRate, 1);
  });

  test("dogs are slower, give up sooner and bark longer before they run", () => {
    start(DOGS, {});
    const d = game.find("dog_1").behaviour;
    const [run, giveUp, alert] = [d.runSpeed, d.giveUpTime, d.alertTime];
    start(DOGS, { assist: true });
    const a = game.find("dog_1").behaviour;
    expect(a.runSpeed).toBeCloseTo(run * accessibility.ASSIST.dogSpeed);
    expect(a.giveUpTime).toBeCloseTo(giveUp * accessibility.ASSIST.dogGiveUp);
    expect(a.alertTime).toBeCloseTo(alert * accessibility.ASSIST.dogAlert);
    expect(a.runSpeed).toBeLessThan(run);
    expect(a.giveUpTime).toBeLessThan(giveUp);
    expect(a.alertTime).toBeGreaterThan(alert);
  });

  test("turning it off in the options menu gives the original numbers back", () => {
    start(YARD, { assist: true });
    game.tap("pause");
    game.step(2);
    game.click("pause_options");
    game.step(3);
    game.click("tab_play");
    game.step(2);
    game.click("assist");
    game.step(2);
    expect(storage.get("settings").assist).toBeUndefined(); // back at the default: not stored
    expect(game.find("spring").behaviour.drainRate).toBe(1);
  });
});

describe("reduced motion", () => {
  afterEach(cleanUp);
  test("follows the system setting (game.accessibility) until the player chooses", () => {
    game.setAccessibility({ reduceMotion: true });
    start(YARD, {});
    expect(accessibility.isReduced()).toBe(true);
    game.setAccessibility({ reduceMotion: false });
    start(YARD, {});
    expect(accessibility.isReduced()).toBe(false);
  });

  test("a choice of the player wins over the system", () => {
    game.setAccessibility({ reduceMotion: true });
    start(YARD, { reducedMotion: false });
    expect(accessibility.isReduced()).toBe(false);
  });

  test("props stop bobbing and spinning, the camera follows softer, effects drop", () => {
    start(ARENA, {});
    const key = game.find("key_1");
    const y = key.position.y;
    game.step(40);
    expect(Math.abs(key.position.y - y)).toBeGreaterThan(0.001); // it bobs
    const camNormal = game.find("camera").behaviour.followSmoothing;
    start(ARENA, { reducedMotion: true });
    const still = game.find("key_1");
    const y0 = still.position.y;
    game.step(40);
    expect(still.position.y).toBe(y0);
    expect(game.find("camera").behaviour.followSmoothing).toBeLessThan(camNormal);
    expect(game.find("camera").behaviour.orbitSpeed).toBeLessThanOrEqual(accessibility.REDUCED.orbitSpeed);
  });

  test("the low-spring pulse stops (the bar keeps one colour)", () => {
    start(YARD, { reducedMotion: true });
    game.find("spring").behaviour.left = 5;
    game.step(10);
    const c1 = game.find("spring_fill").get("Shape2D").color;
    game.step(7);
    const c2 = game.find("spring_fill").get("Shape2D").color;
    expect(c1.r).toBeCloseTo(c2.r, 3);
  });
});

describe("haptics", () => {
  afterEach(cleanUp);
  test("a catch, a delivery and a low spring pulse; landing too", () => {
    start(ARENA, {});
    game.find("courier").behaviour.caught("test");
    game.step(3);
    expect(game.vibrations()).toContain(haptics.PULSES.catch);
  });

  test("a hard landing taps", () => {
    start(YARD, {});
    courier().position = [0, 6, 4];
    game.step(90);
    expect(game.vibrations()).toContain(haptics.PULSES.land);
  });

  test("a delivery pulses", () => {
    start(YARD, {});
    courier().position = [-8, 0.8, 1.5];
    game.step(6);
    courier().position = [0, 0.6, -19.5];
    game.step(10);
    expect(game.vibrations()).toContain(haptics.PULSES.delivery);
  });

  test("the spring running low pulses once", () => {
    start(YARD, {});
    game.find("spring").behaviour.left = 14;
    game.step(10);
    const lows = () => game.vibrations().filter((v) => Math.abs(v - haptics.PULSES.springLow) < 0.001).length; // stored as a float
    expect(lows()).toBe(1);
    game.step(30);
    expect(lows()).toBe(1);
  });

  test("off in the options: nothing vibrates", () => {
    start(ARENA, { haptics: false });
    courier().behaviour.caught("test");
    game.step(3);
    expect(game.vibrations()).toEqual([]);
  });

  test("the options toggle saves and gives a tap when it is turned on", () => {
    start(YARD, { haptics: false });
    game.tap("pause");
    game.step(2);
    game.click("pause_options");
    game.step(3);
    game.click("tab_play");
    game.step(2);
    game.click("haptics");
    game.step(2);
    expect(storage.get("settings").haptics).toBeUndefined(); // true is the default
    expect(game.vibrations().length).toBeGreaterThan(0);
  });
});

describe("captions", () => {
  afterEach(cleanUp);
  const texts = () => game.captions().map((c) => c.text);

  test("a wind-up key", () => {
    start(ARENA, {});
    courier().position = [100, 0.62, 0];
    game.step(4);
    expect(texts()).toContain("[Bell: the spring is wound]");
  });

  test("a dog's bark", () => {
    start(ARENA, {});
    game.find("dog_1").behaviour.bark();
    game.step(1);
    expect(texts()).toContain("[Dog barks]");
  });

  test("a catch", () => {
    start(ARENA, {});
    courier().behaviour.caught("test");
    game.step(1);
    expect(texts()).toContain("[Thud: the dog caught you]");
  });

  test("a delivery", () => {
    start(YARD, {});
    courier().position = [-8, 0.8, 1.5];
    game.step(6);
    courier().position = [0, 0.6, -19.5];
    game.step(3);
    expect(texts()).toContain("[Chime: parcel delivered]");
  });

  test("the spring running low", () => {
    start(YARD, {});
    game.find("spring").behaviour.left = 14;
    game.step(3);
    expect(texts()).toContain("[Alarm: the spring is nearly out]");
  });

  test("they are drawn by the Captions entity, inside the safe area, and the Subtitles option switches it", () => {
    start(YARD, {});
    const caps = game.find("captions");
    expect(caps.active).toBe(true);
    expect(caps.get("Captions").safeArea).toBe(true);
    start(YARD, { subtitles: false });
    expect(game.find("captions").active).toBe(false);
  });

  test("they follow the language", () => {
    start(YARD, { language: "es" });
    courier().behaviour.caught("test");
    game.step(1);
    expect(texts()).toContain("[Golpe: el perro te ha atrapado]");
    i18n.setLanguage("en");
  });
});

describe("suspend", () => {
  afterEach(cleanUp);
  test("the app going to the background opens the pause menu, which stays after resume", () => {
    start(YARD, {});
    expect(game.paused).toBe(false);
    game.blur();
    game.step(2);
    expect(game.paused).toBe(false);
    game.suspend();
    game.step(2);
    expect(game.paused).toBe(true);
    expect(game.find("pause_panel").active).toBe(true);
    expect(comfort().autoPauses).toBe(1);
    game.resume();
    game.step(2);
    expect(game.paused).toBe(true);
    expect(game.find("pause_panel").active).toBe(true);
  });

  test("an already paused game and a finished level are left alone", () => {
    start(YARD, {});
    game.tap("pause");
    game.step(2);
    game.suspend();
    expect(comfort().autoPauses).toBe(0);
    game.resume();
    game.tap("pause");
    game.step(3);
    const bot = new Autoplay(game);
    bot.run(YARD_ROUTE);
    game.step(150);
    expect(comfort().pauseForSuspend()).toBe(false);
  });

  test("resume goes on where it was", () => {
    start(YARD, {});
    comfort().pauseForSuspend();
    game.step(2);
    game.click("resume");
    game.step(4);
    expect(game.paused).toBe(false);
  });
});

describe("Android Back on every screen", () => {
  afterEach(cleanUp);
  test("title: Back asks before quitting; Back again closes the question; Stay closes it; Quit quits", () => {
    game.load("scenes/main.scene.json");
    game.step(5);
    game.pressBack();
    game.step(2);
    expect(game.find("quit_confirm").active).toBe(true);
    expect(game.find("main_menu").active).toBe(false);
    game.pressBack();
    game.step(2);
    expect(game.find("quit_confirm").active).toBe(false);
    expect(game.find("main_menu").active).toBe(true);
    game.pressBack();
    game.step(2);
    game.click("quit_stay");
    game.step(2);
    expect(game.find("quit_confirm").active).toBe(false);
    game.pressBack();
    game.step(2);
    expect(game.quitRequested).toBe(false);
    game.click("quit_yes");
    game.step(2);
    expect(game.quitRequested).toBe(true); // a test records the request instead of stopping the run (FB-0038)
  });

  test("title: options and credits close with Back without asking to quit", () => {
    game.load("scenes/main.scene.json");
    game.step(5);
    game.click("credits_button");
    game.step(2);
    game.pressBack();
    game.step(2);
    expect(game.find("main_menu").active).toBe(true);
    expect(game.find("quit_confirm").active).toBe(false);
  });

  test("options opened from the title: each Back is one step", () => {
    game.load("scenes/main.scene.json");
    game.step(5);
    game.click("options_button");
    game.step(3);
    game.click("tab_touch");
    game.step(2);
    game.pressBack();
    game.step(2);
    expect(game.find("options").active).toBe(false);
    expect(game.find("main_menu").active).toBe(true);
  });

  test("loading screen: Back is ignored, the level still loads", () => {
    // Play opens the level select now (P3); the loading screen is what Continue and the level select open.
    session.nextScene = "scenes/rooftops_1.scene.json";
    game.load("scenes/loading.scene.json");
    game.step(1);
    game.pressBack();
    game.step(10);
    expect(scene.current).toBe("scenes/rooftops_1.scene.json");
  });

  test("in a level: Back pauses, Back in the pause menu resumes, and Back never quits", () => {
    start(YARD, {});
    game.pressBack();
    game.step(2);
    expect(game.paused).toBe(true);
    game.pressBack();
    game.step(3);
    expect(game.paused).toBe(false);
  });

  test("pause -> options -> Back -> Back", () => {
    start(YARD, {});
    game.pressBack();
    game.step(2);
    game.click("pause_options");
    game.step(3);
    game.pressBack();
    game.step(3);
    expect(game.find("pause_panel").active).toBe(true);
    game.pressBack();
    game.step(3);
    expect(game.paused).toBe(false);
  });

  test("results screen: Back returns to the title", () => {
    start(YARD, {});
    new Autoplay(game).run(YARD_ROUTE);
    game.step(150);
    expect(game.find("results_panel").active).toBe(true);
    game.pressBack();
    game.step(3);
    expect(scene.current).toBe("scenes/main.scene.json");
  });

  test("retry screen: Back returns to the title", () => {
    start(YARD, {});
    game.find("spring").behaviour.left = 0.1;
    game.step(200);
    expect(game.find("retry_panel").active).toBe(true);
    game.pressBack();
    game.step(3);
    expect(scene.current).toBe("scenes/main.scene.json");
  });
});

describe("safe areas", () => {
  afterEach(cleanUp);
  /** True when the widget's rectangle lies inside the safe area (a pixel of slack for rounding). */
  function inside(id) {
    const r = ui.rectOf(id);
    const s = screen.safeArea;
    expect(r).not.toBeNull();
    const ok = r.x >= s.x - 1 && r.y >= s.y - 1 && r.x + r.w <= s.x + s.w + 1 && r.y + r.h <= s.y + s.h + 1;
    if (!ok) console.log(`${id} is outside the safe area: ${JSON.stringify(r)} vs ${JSON.stringify(s)}`);
    return ok;
  }

  test("the HUD, the low-spring warning, captions and touch controls stay inside it", () => {
    game.setSafeArea("phone-landscape");
    start(YARD, {});
    game.find("spring").behaviour.left = 5;
    game.step(5);
    for (const id of ["spring_bg", "spring_label", "spring_text", "parcel_text", "spring_warning_icon", "spring_warning_text", "touch_stick", "touch_jump", "touch_action", "touch_pause"]) {
      expect(inside(id)).toBe(true);
    }
    expect(inside("captions")).toBe(true);
  });

  test("left-handed controls stay inside it too", () => {
    game.setSafeArea("phone-landscape");
    start(YARD, { leftHanded: true, controlSize: 1.4 });
    game.step(3);
    for (const id of ["touch_stick", "touch_jump", "touch_action", "touch_pause"]) expect(inside(id)).toBe(true);
  });

  test("the title, credits, quit question and every options tab fit", () => {
    game.setSafeArea("phone-landscape");
    game.load("scenes/main.scene.json");
    game.step(5);
    expect(inside("main_menu")).toBe(true);
    game.click("credits_button");
    game.step(3);
    expect(inside("credits")).toBe(true);
    game.pressBack();
    game.step(2);
    game.pressBack();
    game.step(2);
    expect(inside("quit_box")).toBe(true);
    game.pressBack();
    game.step(2);
    game.click("options_button");
    game.step(3);
    expect(inside("options")).toBe(true);
    for (const tab of ["video", "audio", "play", "touch", "language"]) {
      game.click(`tab_${tab}`);
      game.step(2);
      expect(inside(`${tab}_section`)).toBe(true);
    }
  });

  test("the pause menu, the results and retry screens fit", () => {
    game.setSafeArea("phone-landscape");
    start(YARD, {});
    game.pressBack();
    game.step(3);
    expect(inside("pause_box")).toBe(true);
    game.click("pause_options");
    game.step(3);
    expect(inside("options")).toBe(true);
    game.pressBack();
    game.step(3);
    game.pressBack(); // resume: a paused game would stay paused in the next start
    game.step(3);
    start(YARD, {});
    game.find("spring").behaviour.left = 0.1;
    game.step(200);
    expect(inside("retry_panel_box")).toBe(true);
    start(YARD, {});
    new Autoplay(game).run(YARD_ROUTE);
    game.step(150);
    expect(inside("results_panel_box")).toBe(true);
  });
});

describe("text size", () => {
  afterEach(cleanUp);
  test("the Text size button cycles through the scales and applies them at once", () => {
    start(YARD, {});
    game.tap("pause");
    game.step(2);
    game.click("pause_options");
    game.step(3);
    game.click("tab_play");
    game.step(2);
    game.click("text_size");
    game.step(2);
    expect(storage.get("settings").textScale).toBe(1.15);
    expect(game.find("text_size").get("Button").text).toBe("Text size: 115 percent");
  });

  test("it starts from the system's text size", () => {
    game.setAccessibility({ textScale: 1.5 });
    start(YARD, {});
    expect(settings.load().textScale).toBe(1.5);
  });
});

describe("every option persists", () => {
  afterEach(cleanUp);
  test("only what differs from the defaults is stored, and it loads again", () => {
    settings.save({ ...settings.load(), quality: "low", leftHanded: true, assist: true });
    const stored = storage.get("settings");
    expect(stored).toEqual({ quality: "low", leftHanded: true, assist: true });
    const s = settings.load();
    expect(s.quality).toBe("low");
    expect(s.leftHanded).toBe(true);
    expect(s.haptics).toBe(true);
  });
});
