import { test, expect, game } from "factoria:test";
import { fa, assets, time, input, screen } from "factoria";
import { loadLevel } from "./helpers/autoplay.js";

// The on-screen gamepad (landscape phone) and the project settings the exports rely on.
// Design size 1280x720. Control rectangles (x, y from the top-left, +Y down) from prefabs/ui/touch_controls.prefab.json:
const LEFT = [100, 620];
const RIGHT = [244, 620];
const JUMP = [1170, 610];
const PAUSE = [1224, 96];

const project = () => JSON.parse(fa.call("fs.read", { path: "factoria.json" }).content);

function start(id = "1-1") {
  time.scale = 1;
  loadLevel(id);
  game.step(30);
  return game.find("player");
}

test("a finger on the left and right buttons runs the player", () => {
  const player = start();
  const x0 = player.position.x;
  game.touchStart(RIGHT, 1);
  game.step(30);
  expect(game.find("touch_right").get("TouchButton").pressed).toBe(true);
  expect(input.value("move_right")).toBe(1);
  game.touchEnd(1);
  game.step(2);
  expect(player.position.x).toBeGreaterThan(x0 + 100);
  const x1 = player.position.x;
  game.touchStart(LEFT, 2);
  game.step(20);
  game.touchEnd(2);
  expect(player.position.x).toBeLessThan(x1 - 60);
});

test("a finger on the jump button jumps, and a second finger runs at the same time", () => {
  const player = start();
  const x0 = player.position.x;
  const y0 = player.position.y;
  game.clearAudioLog();
  game.touchStart(RIGHT, 1);
  game.touchStart(JUMP, 2);
  game.step(12);
  expect(player.position.y).toBeGreaterThan(y0 + 30);
  expect(player.position.x).toBeGreaterThan(x0 + 20);
  expect(game.audioLog()).toContainPlayed("jump.wav", { times: 1 });
  game.touchEnd(2);
  game.touchEnd(1);
});

test("the pause button opens the pause menu and the touch pad does not leak into the game", () => {
  const player = start();
  game.touchStart(PAUSE, 1);
  game.step(2);
  game.touchEnd(1);
  game.step(3);
  expect(time.scale).toBe(0);
  expect(game.find("pause_panel")).not.toBeNull();
  expect(game.find("pause_panel").active).toBe(true);
  time.scale = 1;
});

test("the touch controls stay inside the safe area of a notched phone, and still work there", () => {
  const player = start();
  game.setSafeArea("phone-landscape");
  game.step(2);
  const widgets = Object.fromEntries(fa.call("ui.state", {}).widgets.map((w) => [w.id, w.rect]));
  const safe = screen.safeArea;
  expect(safe.x).toBeGreaterThan(40);
  expect(widgets.touch_left[0]).toBeGreaterThanOrEqual(safe.x);
  expect(widgets.touch_jump[0] + widgets.touch_jump[2]).toBeLessThanOrEqual(safe.x + safe.w + 0.5);
  expect(widgets.touch_pause[0] + widgets.touch_pause[2]).toBeLessThanOrEqual(safe.x + safe.w + 0.5);
  expect(widgets.touch_jump[1] + widgets.touch_jump[3]).toBeLessThanOrEqual(safe.y + safe.h + 0.5);
  // the HUD texts are anchored to the safe area too
  for (const id of ["hud_level", "hud_timer", "hud_embers"]) expect(game.find(id).get("Text").safeArea).toBe(true);
  // a finger in the middle of the moved right button still runs the player
  const [x, y, w, h] = widgets.touch_right;
  const x0 = player.position.x;
  game.touchStart([x + w / 2, y + h / 2], 1);
  game.step(20);
  game.touchEnd(1);
  expect(player.position.x).toBeGreaterThan(x0 + 60);
});

test("every level has the touch controls", () => {
  for (const id of ["1-1", "2-3"]) {
    loadLevel(id);
    game.step(2);
    for (const c of ["touch_left", "touch_right", "touch_jump", "touch_pause"]) expect(game.find(c)).not.toBeNull();
  }
});

test("the shipping settings are in place: version, icon, platforms, landscape, store ids", () => {
  const p = project();
  expect(p.version).toMatch(/^\d+\.\d+\.\d+$/);
  expect(p.display.orientation).toBe("landscape");
  for (const platform of ["windows", "macos", "linux", "web", "android", "ios"]) expect(p.platforms).toContain(platform);
  expect(p.id).toMatch(/^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$/);
  expect(p.icon).toBe("assets/icon.png");
  expect(p.export.android.adaptiveIcon.foreground).toBe("assets/icon_fg.png");
  for (const store of ["steam", "itch", "epic", "gog", "appstore", "googleplay"]) expect(p.publish[store]).toBeTruthy();
});

test("the icon files exist and are the size the exports need", () => {
  expect(assets.textureSize("assets/icon.png")).toEqual({ width: 1024, height: 1024 });
  expect(assets.textureSize("assets/icon_fg.png")).toEqual({ width: 432, height: 432 });
});

test("the store texts and release notes exist in every language of the game, and the stores list them", () => {
  const p = project();
  const languages = p.localization.languages;
  expect(languages).toEqual(["en", "es", "de", "ar"]);
  for (const lang of languages) {
    const s = JSON.parse(fa.call("fs.read", { path: `store/store.${lang}.json` }).content);
    expect(s.name.length).toBeGreaterThan(0);
    expect(s.shortDescription.length).toBeLessThanOrEqual(80);
    expect(s.longDescription.length).toBeGreaterThan(200);
    expect(s.features.length).toBeGreaterThan(3);
    expect(s.keywords.length).toBeGreaterThan(3);
    const notes = fa.call("fs.read", { path: `store/whats-new-${lang}.txt` }).content;
    expect(notes.length).toBeGreaterThan(0);
    expect(notes.length).toBeLessThanOrEqual(500);
    expect(s.subtitle.length).toBeLessThanOrEqual(30);
  }
  // the stores that take a list of languages name each one of the game's (store tags: en-US, es-ES, de-DE, ar)
  const tags = ["en-US", "es-ES", "de-DE", "ar"];
  expect(p.publish.gog.languages).toEqual(tags);
  expect(Object.keys(p.publish.googleplay.changelogs)).toEqual(tags);
  for (const file of Object.values(p.publish.googleplay.changelogs)) expect(fa.call("fs.read", { path: file }).content.length).toBeGreaterThan(0);
});
